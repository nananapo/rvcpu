module ExecuteStage
(
    input wire          clk,

    input wire          exe_valid,
    input wire [31:0]   exe_reg_pc,
    input wire [31:0]   exe_inst,
    input wire [63:0]   exe_inst_id,
    input wire ctrltype exe_ctrl,

    output wire             exe_mem_valid,
    output wire [31:0]      exe_mem_reg_pc,
    output wire [31:0]      exe_mem_inst,
    output wire [63:0]      exe_mem_inst_id,
    output wire ctrltype    exe_mem_ctrl,
    output wire [31:0]      exe_mem_alu_out,
    
    output wire         branch_hazard,
    output wire [31:0]  branch_target,

    input wire          pipeline_flush,
    output wire         calc_stall_flg
);

`include "include/core.sv"

wire [31:0] reg_pc      = exe_reg_pc;
wire [31:0] inst        = exe_inst;
wire [63:0] inst_id     = exe_inst_id;
wire ctrltype ctrl      = exe_ctrl;

wire [4:0]  exe_fun     = exe_ctrl.exe_fun;
wire [31:0] op1_data    = exe_ctrl.op1_data;
wire [31:0] op2_data    = exe_ctrl.op2_data;
wire [31:0] rs2_data    = exe_ctrl.rs2_data;
wire [31:0] imm_b_sext  = exe_ctrl.imm_b_sext;

`ifndef EXCLUDE_RV32M
DivNbit #(
    .SIZE(33) // オーバーフロー対策
) divnbitm(
    .clk(clk),
    .start(divm_start),
    .ready(divm_ready),
    .valid(divm_valid),
    .error(divm_error),
    .is_signed(divm_signed),
    .dividend(divm_dividend),
    .divisor(divm_divisor),
    .quotient(divm_quotient),
    .remainder(divm_remainder)
);
MultNbit #(
    .SIZE(33) // s * u用
) m (
    .clk(clk),
    .start(multm_start),
    .ready(multm_ready),
    .valid(multm_valid),
    .is_signed(multm_signed),
    .multiplicand(multm_multiplicand),
    .multiplier(multm_multiplier),
    .product(multm_product)
);
`endif

wire        is_div              = exe_fun == ALU_DIV || exe_fun == ALU_DIVU || exe_fun == ALU_REM || exe_fun == ALU_REMU;
wire        is_mul              = exe_fun == ALU_MUL || exe_fun == ALU_MULH || exe_fun == ALU_MULHU || exe_fun == ALU_MULHSU;

reg         calc_started        = 0; // 複数サイクルかかる計算を開始済みか
reg         is_calculated       = 0; // 複数サイクルかかる計算が終了しているか

reg [63:0]  saved_inst_id       = 0;
wire        may_start_m         = !is_calculated || saved_inst_id != inst_id; // 複数サイクルかかる計算を始める可能性があるか

wire        divm_start          = exe_valid && is_div && may_start_m && divm_ready;
wire        divm_signed         = exe_fun == ALU_DIV || exe_fun == ALU_REM;
wire        divm_ready;
wire        divm_valid;
wire        divm_error;
wire [32:0] divm_dividend       = divm_signed ? {op1_data[31], op1_data} : {1'b0, op1_data};
wire [32:0] divm_divisor        = divm_signed ? {op2_data[31], op2_data} : {1'b0, op2_data};
wire [32:0] divm_quotient;
wire [32:0] divm_remainder;

wire        multm_start         = exe_valid && is_mul && may_start_m && multm_ready;
wire        multm_signed        = exe_fun == ALU_MUL || exe_fun == ALU_MULH || exe_fun == ALU_MULHSU;
wire        multm_ready;
wire        multm_valid;
wire [32:0] multm_multiplicand  = multm_signed ? {op1_data[31], op1_data} : {1'b0, op1_data};
wire [32:0] multm_multiplier    = multm_signed && exe_fun != ALU_MULHSU ? {op2_data[31], op2_data} : {1'b0, op2_data};
wire [65:0] multm_product;

reg [31:0]  saved_result        = 0; // 複数サイクルかかる計算の結果
wire        calc_valid          = (is_div && divm_valid) || (is_mul && multm_valid); // 複数サイクルかかる計算が今クロックで終了したか
wire        is_multicycle_exe   = is_div || is_mul; // 現在のexe_funが複数サイクルかかる計算かどうか

assign calc_stall_flg   = exe_valid && is_multicycle_exe && 
                          (divm_start || multm_start || !is_calculated); // モジュールで計算を始める = 未計算

function [31:0] gen_alu_out(
    input [4:0 ] exe_fun,
    input [31:0] op1_data,
    input [31:0] op2_data,
    input [31:0] saved_result
);
    case (exe_fun) 
    ALU_ADD     : gen_alu_out = op1_data + op2_data;
    ALU_SUB     : gen_alu_out = op1_data - op2_data;
    ALU_AND     : gen_alu_out = op1_data & op2_data;
    ALU_OR      : gen_alu_out = op1_data | op2_data;
    ALU_XOR     : gen_alu_out = op1_data ^ op2_data;
    ALU_SLL     : gen_alu_out = op1_data << op2_data[4:0];
    ALU_SRL     : gen_alu_out = op1_data >> op2_data[4:0];
    ALU_SRA     : gen_alu_out = $signed($signed(op1_data) >>> op2_data[4:0]);
    ALU_SLT     : gen_alu_out = {31'b0, ($signed(op1_data) < $signed(op2_data))};
    ALU_SLTU    : gen_alu_out = {31'b0, op1_data < op2_data};
    ALU_JALR    : gen_alu_out = (op1_data + op2_data) & (~1);
    ALU_COPY1   : gen_alu_out = op1_data;
    default     : gen_alu_out = saved_result;
    endcase
endfunction

function gen_br_flg(
    input [4:0 ] exe_fun,
    input [31:0] op1_data,
    input [31:0] op2_data
);
    case(exe_fun) 
    BR_BEQ  : gen_br_flg = (op1_data == op2_data);
    BR_BNE  : gen_br_flg = !(op1_data == op2_data);
    BR_BLT  : gen_br_flg = ($signed(op1_data) < $signed(op2_data));
    BR_BGE  : gen_br_flg = !($signed(op1_data) < $signed(op2_data));
    BR_BLTU : gen_br_flg = (op1_data < op2_data);
    BR_BGEU : gen_br_flg = !(op1_data < op2_data);
    default : gen_br_flg = 0;
    endcase
endfunction

assign exe_mem_valid    = exe_valid && !calc_stall_flg;
assign exe_mem_reg_pc   = exe_reg_pc;
assign exe_mem_inst     = exe_inst;
assign exe_mem_inst_id  = exe_inst;
assign exe_mem_ctrl     = exe_ctrl;

assign exe_mem_alu_out  = gen_alu_out(exe_fun, op1_data, op2_data, saved_result);

assign branch_hazard    = gen_br_flg(exe_fun, op1_data, op2_data);
assign branch_target    = reg_pc + imm_b_sext;


always @(posedge clk)
    saved_inst_id <= inst_id;

always @(posedge clk) begin
    // EX STAGE
    if (pipeline_flush || !exe_valid || !is_multicycle_exe) begin
        // TODO kill muldiv
        calc_started    <= 0;
        is_calculated   <= 0;
    end else if (may_start_m) begin
        // 計算を始める
        if (!calc_started) begin
            is_calculated   <= 0;
            calc_started    <= divm_start || multm_start;
        // 結果を待つ
        end else if (calc_started && calc_valid) begin
            is_calculated   <= 1;
            calc_started    <= 0;
            case (exe_fun) 
                ALU_DIV     : saved_result <= divm_quotient[31:0];
                ALU_DIVU    : saved_result <= divm_quotient[31:0];
                ALU_REM     : saved_result <= divm_remainder[31:0];
                ALU_REMU    : saved_result <= divm_remainder[31:0];
                ALU_MUL     : saved_result <= multm_product[31:0];
                ALU_MULH    : saved_result <= multm_product[63:32];
                ALU_MULHU   : saved_result <= multm_product[63:32];
                ALU_MULHSU  : saved_result <= multm_product[63:32];
                default     : saved_result <= 0;
            endcase
        end else begin
            is_calculated   <= 0;
        end
    end
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,exestage.valid,%b", exe_valid);
    $display("data,exestage.reg_pc,%b", exe_reg_pc);
    $display("data,exestage.inst_id,%b", exe_inst_id);
    $display("data,exestage.exe_fun,%b", exe_fun);
    $display("data,exestage.op1_data,%b", op1_data);
    $display("data,exestage.op2_data,%b", op2_data);
    $display("data,exestage.calc_stall,%b", calc_stall_flg);
    $display("data,exestage.ismulticyc,%b", is_multicycle_exe);
end
`endif

endmodule