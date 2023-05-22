module ExecuteStage
(
    input wire          clk,

    input wire          wb_branch_hazard,

    input wire [31:0]   input_reg_pc,
    input wire [31:0]   input_inst,
    input wire [63:0]   input_inst_id,
    input wire [4:0]    input_exe_fun,
    input wire [31:0]   input_op1_data,
    input wire [31:0]   input_op2_data,
    input wire [31:0]   input_rs2_data,
    input wire [3:0]    input_mem_wen,
    input wire          input_rf_wen,
    input wire [3:0]    input_wb_sel,
    input wire [4:0]    input_wb_addr,
    input wire [2:0]    input_csr_cmd,
    input wire          input_jmp_flg,
    input wire [31:0]   input_imm_i_sext,
    input wire [31:0]   input_imm_b_sext,

    output reg [31:0]   alu_out,
    output reg          br_flg,
    output reg [31:0]   br_target,
    
    output reg [31:0]   output_reg_pc,
    output reg [31:0]   output_inst,
    output reg [63:0]   output_inst_id,
    output reg [3:0]    output_mem_wen,
    output reg          output_rf_wen,
    output reg [31:0]   output_rs2_data,
    output reg [31:0]   output_op1_data,
    output reg [3:0]    output_wb_sel,
    output reg [4:0]    output_wb_addr,
    output reg [2:0]    output_csr_cmd,
    output reg          output_jmp_flg,
    output reg [31:0]   output_imm_i,
    
    input  wire         memory_stage_stall_flg,
    output wire         output_stall_flg,

    output wire         output_datahazard_rf_wen,
    output wire [4:0]   output_datahazard_wb_addr,
    output wire         output_trappable,
    output wire [3:0]   output_zifencei_mem_wen
);

`include "include/core.sv"

initial begin
    alu_out         = 0;
    br_flg          = 0;
    br_target       = 0;

    output_reg_pc   = REGPC_NOP;
    output_inst     = INST_NOP;
    output_inst_id  = INST_ID_NOP;

    output_mem_wen  = 0;
    output_rf_wen   = 0;
    output_rs2_data = 0;
    output_op1_data = 0;
    output_wb_sel   = 0;
    output_wb_addr  = 0;
    output_csr_cmd  = 0;
    output_jmp_flg  = 0;
    output_imm_i    = 0;
end

reg [31:0] save_reg_pc      = 0;
reg [31:0] save_inst        = 0;
reg [63:0] save_inst_id     = INST_ID_NOP;
reg [4:0]  save_exe_fun     = 0;
reg [31:0] save_op1_data    = 0;
reg [31:0] save_op2_data    = 0;
reg [31:0] save_rs2_data    = 0;
reg [3:0]  save_mem_wen     = 0;
reg        save_rf_wen      = 0;
reg [3:0]  save_wb_sel      = 0;
reg [4:0]  save_wb_addr     = 0;
reg [2:0]  save_csr_cmd     = 0;
reg        save_jmp_flg     = 0;
reg [31:0] save_imm_i_sext  = 0;
reg [31:0] save_imm_b_sext  = 0;

// 複数サイクルかかる計算を実行していて、前回からの続きからか
// つまり、複数サイクルかかる計算を行って、結果が次に流れたら0になる
reg         last_cycle_is_multicycle_exe = 0;
// 前回のクロックでメモリステージでストールしていたかどうか
reg         last_is_memstage_stall = 0;

// 今回のサイクルで前回のサイクルのデータを使うかどうか
wire use_saved_data     = last_cycle_is_multicycle_exe || last_is_memstage_stall;

wire [31:0] reg_pc      = use_saved_data ? save_reg_pc : input_reg_pc;
wire [31:0] inst        = use_saved_data ? save_inst : input_inst;
wire [63:0] inst_id     = use_saved_data ? save_inst_id : input_inst_id;
wire [4:0]  exe_fun     = use_saved_data ? save_exe_fun : input_exe_fun;
wire [31:0] op1_data    = use_saved_data ? save_op1_data : input_op1_data;
wire [31:0] op2_data    = use_saved_data ? save_op2_data : input_op2_data;
wire [31:0] rs2_data    = use_saved_data ? save_rs2_data : input_rs2_data;
wire [3:0]  mem_wen     = use_saved_data ? save_mem_wen : input_mem_wen;
wire        rf_wen      = use_saved_data ? save_rf_wen : input_rf_wen;
wire [3:0]  wb_sel      = use_saved_data ? save_wb_sel : input_wb_sel;
wire [4:0]  wb_addr     = use_saved_data ? save_wb_addr : input_wb_addr;
wire [2:0]  csr_cmd     = use_saved_data ? save_csr_cmd : input_csr_cmd;
wire        jmp_flg     = use_saved_data ? save_jmp_flg : input_jmp_flg;
wire [31:0] imm_i_sext  = use_saved_data ? save_imm_i_sext : input_imm_i_sext;
wire [31:0] imm_b_sext  = use_saved_data ? save_imm_b_sext : input_imm_b_sext;

`ifndef EXCLUDE_RV32M
reg  divm_start     = 0;
reg  divm_is_signed = 0;
wire divm_ready;
wire divm_valid;
wire divm_error;
reg  [32:0] divm_dividend   = 0;
reg  [32:0] divm_divisor    = 0;
wire [32:0] divm_quotient;
wire [32:0] divm_remainder;

DivNbit #(
    .SIZE(33) // オーバーフロー対策
) divnbitm(
    .clk(clk),

    .start(divm_start),
    .is_signed(divm_is_signed),
    .ready(divm_ready),
    .valid(divm_valid),
    .error(divm_error),
    .dividend(divm_dividend),
    .divisor(divm_divisor),
    .quotient(divm_quotient),
    .remainder(divm_remainder)
);

reg         multm_start;
reg         multm_is_signed;
wire        multm_ready;
wire        multm_valid;
wire [65:0] multm_product;
reg  [32:0] multm_multiplicand;
reg  [32:0] multm_multiplier;

MultNbit #(
    .SIZE(33) // s * u用
) m (
    .clk(clk),

    .start(multm_start),
    .is_signed(multm_is_signed),
    .ready(multm_ready),
    .valid(multm_valid),
    .multiplicand(multm_multiplicand),
    .multiplier(multm_multiplier),
    .product(multm_product)
);

// rv32mのdiv, rem命令かどうか
wire        is_rv32m_div_exe    = exe_fun == ALU_DIV || exe_fun == ALU_DIVU || exe_fun == ALU_REM || exe_fun == ALU_REMU;
// rv32mのdiv, remをsignedとして実行すべきかどうか
wire        is_rv32m_div_signed = exe_fun == ALU_DIV || exe_fun == ALU_REM;
// rv32mのmul命令かどうか
wire        is_rv32m_mul_exe    = exe_fun == ALU_MUL || exe_fun == ALU_MULH || exe_fun == ALU_MULHU || exe_fun == ALU_MULHSU;
// rv32mのmul命令をsignedとして実行すべきかどうか
wire        is_rv32m_mul_signed = exe_fun == ALU_MUL || exe_fun == ALU_MULH || exe_fun == ALU_MULHSU;

`endif

// 複数サイクルかかる計算を始めたかどうか
reg         is_calc_started = 0;
// 複数サイクルかかる計算が済んだかどうか
reg         is_calculated   = 0;
// 複数サイクルかかる計算の結果
reg [31:0]  save_calculated = 0;
// 複数サイクルかかる計算が今クロックで終了したか
wire        calc_valid      = 
`ifndef EXCLUDE_RV32M
    divm_valid || 
    multm_valid || 
`endif
    0;
// 現在のexeが複数サイクルかかる計算かどうか
wire        is_multicycle_exe = 
`ifndef EXCLUDE_RV32M
    is_rv32m_div_exe || 
    is_rv32m_mul_exe || 
`endif
    0;


function func_stall_flg(
    input [4:0]     exe_fun,
    input           is_calculated
`ifndef EXCLUDE_RV32M
    ,input          divm_valid
    ,input          multm_valid
`endif
);
case (exe_fun)
`ifndef EXCLUDE_RV32M
    ALU_DIV     : func_stall_flg = !(is_calculated || (divm_valid && is_calc_started));
    ALU_DIVU    : func_stall_flg = !(is_calculated || (divm_valid && is_calc_started));
    ALU_REM     : func_stall_flg = !(is_calculated || (divm_valid && is_calc_started));
    ALU_REMU    : func_stall_flg = !(is_calculated || (divm_valid && is_calc_started));
    ALU_MUL     : func_stall_flg = !(is_calculated || (multm_valid && is_calc_started));
    ALU_MULH    : func_stall_flg = !(is_calculated || (multm_valid && is_calc_started));
    ALU_MULHU   : func_stall_flg = !(is_calculated || (multm_valid && is_calc_started));
    ALU_MULHSU  : func_stall_flg = !(is_calculated || (multm_valid && is_calc_started));
    default     : func_stall_flg = 0;
`endif
endcase  
endfunction

// ストール判定
assign output_stall_flg = func_stall_flg(
    exe_fun, 
    is_calculated
`ifndef EXCLUDE_RV32M
    , divm_valid
    , multm_valid
`endif
);

assign output_datahazard_rf_wen  = wb_branch_hazard ? 0 : rf_wen;
assign output_datahazard_wb_addr = wb_branch_hazard ? 0 : wb_addr;
assign output_trappable          = wb_branch_hazard ? 1 : inst == INST_NOP;
assign output_zifencei_mem_wen   = wb_branch_hazard ? WB_X : mem_wen;

always @(posedge clk) begin
    // EX STAGE
    if (wb_branch_hazard) begin
        last_is_memstage_stall          <= 0;

        // calc
        is_calc_started <= 0;
        is_calculated   <= 0;
        save_calculated <= 32'hffffffff;
        last_cycle_is_multicycle_exe    <= 0;

        // alu_out
        alu_out         <= 32'hffffffff;
        br_flg          <= 0; 
        br_target       <= 32'hffffffff;
        
`ifndef EXCLUDE_RV32M
        divm_start  <= 0;
        multm_start <= 0;
`endif
    end else begin
        last_is_memstage_stall <= memory_stage_stall_flg;

        // calc
        if (is_calc_started && calc_valid) begin
            is_calc_started                 <= 0;
            last_cycle_is_multicycle_exe    <= 0;
            // メモリがストールしてなかったらそのまま進める
            is_calculated                   <= memory_stage_stall_flg;

            case (exe_fun) 
`ifndef EXCLUDE_RV32M 
                ALU_DIV     : save_calculated <= divm_quotient[31:0];
                ALU_DIVU    : save_calculated <= divm_quotient[31:0];
                ALU_REM     : save_calculated <= divm_remainder[31:0];
                ALU_REMU    : save_calculated <= divm_remainder[31:0];
                ALU_MUL     : save_calculated <= multm_product[31:0];
                ALU_MULH    : save_calculated <= multm_product[63:32];
                ALU_MULHU   : save_calculated <= multm_product[63:32];
                ALU_MULHSU  : save_calculated <= multm_product[63:32];
`endif
                default     : save_calculated <= 0;
            endcase
        end
`ifndef EXCLUDE_RV32M
        else if (!is_calc_started && !is_calculated && is_rv32m_div_exe) begin
            last_cycle_is_multicycle_exe <= 1;
            if (divm_ready) begin
                // 複数サイクルかかる計算を開始する
                is_calc_started <= 1;

                divm_start      <= 1;
                divm_is_signed  <= is_rv32m_div_signed;
                divm_dividend   <= is_rv32m_div_signed ? {op1_data[31], op1_data} : {1'b0, op1_data};
                divm_divisor    <= is_rv32m_div_signed ? {op2_data[31], op2_data} : {1'b0, op2_data};
            end
        end else if (!is_calc_started && !is_calculated && is_rv32m_mul_exe) begin
            last_cycle_is_multicycle_exe <= 1;
            if (multm_ready) begin
                // 複数サイクルかかる計算を開始する
                is_calc_started <= 1;

                multm_start         <= 1;
                multm_is_signed     <= is_rv32m_mul_signed;
                multm_multiplicand  <= is_rv32m_mul_signed ? {op1_data[31], op1_data} : {1'b0, op1_data};
                multm_multiplier    <= is_rv32m_mul_signed && exe_fun != ALU_MULHSU ? {op2_data[31], op2_data} : {1'b0, op2_data};
            end
        end else if (is_calc_started) begin
            divm_start  <= 0;
            multm_start <= 0;
        end
`endif

        // alu_out
        case (exe_fun) 
            ALU_ADD     : alu_out <= op1_data + op2_data;
            ALU_SUB     : alu_out <= op1_data - op2_data;
            ALU_AND     : alu_out <= op1_data & op2_data;
            ALU_OR      : alu_out <= op1_data | op2_data;
            ALU_XOR     : alu_out <= op1_data ^ op2_data;
            ALU_SLL     : alu_out <= op1_data << op2_data[4:0];
            ALU_SRL     : alu_out <= op1_data >> op2_data[4:0];
            ALU_SRA     : alu_out <= $signed($signed(op1_data) >>> op2_data[4:0]);
            ALU_SLT     : alu_out <= {31'b0, ($signed(op1_data) < $signed(op2_data))};
            ALU_SLTU    : alu_out <= {31'b0, op1_data < op2_data};
            ALU_JALR    : alu_out <= (op1_data + op2_data) & (~1);
            ALU_COPY1   : alu_out <= op1_data;

`ifndef EXCLUDE_RV32M 
            ALU_MUL     : alu_out <= is_calculated ? save_calculated : multm_product[31:0];
            ALU_MULH    : alu_out <= is_calculated ? save_calculated : multm_product[63:32];
            ALU_MULHSU  : alu_out <= is_calculated ? save_calculated : multm_product[63:32];
            ALU_MULHU   : alu_out <= is_calculated ? save_calculated : multm_product[63:32];
            ALU_DIV     : alu_out <= is_calculated ? save_calculated : divm_quotient[31:0];
            ALU_DIVU    : alu_out <= is_calculated ? save_calculated : divm_quotient[31:0];
            ALU_REM     : alu_out <= is_calculated ? save_calculated : divm_remainder[31:0];
            ALU_REMU    : alu_out <= is_calculated ? save_calculated : divm_remainder[31:0];
`endif

            default     : alu_out <= 0;
        endcase
        // br_flg
        case(exe_fun) 
            BR_BEQ  : br_flg <= (op1_data == op2_data);
            BR_BNE  : br_flg <= !(op1_data == op2_data);
            BR_BLT  : br_flg <= ($signed(op1_data) < $signed(op2_data));
            BR_BGE  : br_flg <= !($signed(op1_data) < $signed(op2_data));
            BR_BLTU : br_flg <= (op1_data < op2_data);
            BR_BGEU : br_flg <= !(op1_data < op2_data);
            default : br_flg <= 0;
        endcase
        br_target <= reg_pc + imm_b_sext;
    end

    // output
    if (wb_branch_hazard || memory_stage_stall_flg || output_stall_flg) begin
        output_reg_pc   <= REGPC_NOP;
        output_inst     <= INST_NOP;
        output_inst_id  <= INST_ID_NOP;
        output_mem_wen  <= MEN_X;
        output_rf_wen   <= REN_X;
        output_rs2_data <= 32'hffffffff;
        output_op1_data <= 32'hffffffff;
        output_wb_sel   <= WB_X;
        output_wb_addr  <= 0;
        output_csr_cmd  <= CSR_X;
        output_jmp_flg  <= 0;
        output_imm_i    <= 32'hffffffff;
    end else begin
        output_reg_pc   <= reg_pc;
        output_inst     <= inst;
        output_inst_id  <= inst_id;
        output_mem_wen  <= mem_wen;
        output_rf_wen   <= rf_wen;
        output_rs2_data <= rs2_data;
        output_op1_data <= op1_data;
        output_wb_sel   <= wb_sel;
        output_wb_addr  <= wb_addr;
        output_csr_cmd  <= csr_cmd;
        output_jmp_flg  <= jmp_flg;
        output_imm_i    <= imm_i_sext;
    end
    
    // save
    if (wb_branch_hazard) begin
        // TODO フラグを導入したい
        save_reg_pc     <= REGPC_NOP;
        save_inst       <= INST_NOP;
        save_inst_id    <= INST_ID_NOP;
        save_exe_fun    <= ALU_X;
        save_op1_data   <= 32'hffffffff;
        save_op2_data   <= 32'hffffffff;
        save_rs2_data   <= 32'hffffffff;
        save_mem_wen    <= MEN_X;
        save_rf_wen     <= REN_X;
        save_wb_sel     <= WB_X;
        save_wb_addr    <= 0;
        save_csr_cmd    <= CSR_X;
        save_jmp_flg    <= 0;
        save_imm_i_sext <= 32'hffffffff;
        save_imm_b_sext <= 32'hffffffff;
    end else begin
        save_reg_pc     <= reg_pc;
        save_inst       <= inst;
        save_inst_id    <= inst_id;
        save_exe_fun    <= exe_fun;
        save_op1_data   <= op1_data;
        save_op2_data   <= op2_data;
        save_rs2_data   <= rs2_data;
        save_mem_wen    <= mem_wen;
        save_rf_wen     <= rf_wen;
        save_wb_sel     <= wb_sel;
        save_wb_addr    <= wb_addr;
        save_csr_cmd    <= csr_cmd;
        save_jmp_flg    <= jmp_flg;
        save_imm_i_sext <= imm_i_sext;
        save_imm_b_sext <= imm_b_sext;
    end
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,exestage.reg_pc,%b", reg_pc);
    $display("data,exestage.inst_id,%b", inst_id);
    $display("data,exestage.exe_fun,%b", exe_fun);
    $display("data,exestage.op1_data,%b", op1_data);
    $display("data,exestage.op2_data,%b", op2_data);
    $display("data,exestage.output.stall,%b", output_stall_flg);
    $display("data,exestage.ismulticyc,%b", is_multicycle_exe);
    $display("data,exestage.lastismulc,%b", last_cycle_is_multicycle_exe);
`ifndef EXCLUDE_RV32M
    // $display("data,exestage.iscalcstrt,%b", is_calc_started);
    // $display("data,exestage.iscalculed,%b", is_calculated);
    // $display("data,exestage.isrv32mdiv,%b", is_rv32m_div_exe);
    $display("data,exestage.isrv32mmul,%b", is_rv32m_mul_exe);
    $display("data,exestage.div.valid,%b", divm_valid);
    $display("data,exestage.mult.valid,%b", multm_valid);
`endif

end
`endif

endmodule