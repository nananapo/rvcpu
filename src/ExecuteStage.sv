module ExecuteStage
(
    input wire          clk,

    input wire          exe_valid,
    input wire [31:0]   exe_pc,
    input wire [31:0]   exe_inst,
    input wire iidtype  exe_inst_id,
    input wire ctrltype exe_ctrl,
    input wire [31:0]   exe_imm_b,
    input wire [31:0]   exe_imm_j,
    input wire [31:0]   exe_op1_data,
    input wire [31:0]   exe_op2_data,
    input wire [31:0]   exe_rs2_data,

    output wire             exe_mem_valid,
    output wire [31:0]      exe_mem_pc,
    output wire [31:0]      exe_mem_inst,
    output wire iidtype     exe_mem_inst_id,
    output wire ctrltype    exe_mem_ctrl,
    output wire [31:0]      exe_mem_alu_out,
    output wire [31:0]      exe_mem_rs2_data,
    
    output wire         branch_taken,
    output wire [31:0]  branch_target,

    input wire          pipeline_flush,
    output wire         calc_stall_flg
);

`include "include/core.sv"

wire [31:0] pc          = exe_pc;
wire [31:0] inst        = exe_inst;
wire iidtype inst_id    = exe_inst_id;
wire ctrltype ctrl      = exe_ctrl;

wire alui_exe_type i_exe= exe_ctrl.i_exe;
wire br_exe_type br_exe = exe_ctrl.br_exe;
wire alum_exe_type m_exe= exe_ctrl.m_exe;
wire [31:0] op1_data    = exe_op1_data;
wire [31:0] op2_data    = exe_op2_data;

wire [31:0] alu_out;
wire        alu_branch_take;

ALU #(
    .ENABLE_ALU(1'b1),
    .ENABLE_BRANCH(1'b1)
) alu (
    .i_exe(i_exe),
    .br_exe(br_exe),
    .op1_data(op1_data),
    .op2_data(op2_data),
    .alu_out(alu_out),
    .branch_take(alu_branch_take)
);

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

wire        is_div              = m_exe == ALUM_DIV || m_exe == ALUM_DIVU || m_exe == ALUM_REM || m_exe == ALUM_REMU;
wire        is_mul              = m_exe == ALUM_MUL || m_exe == ALUM_MULH || m_exe == ALUM_MULHU || m_exe == ALUM_MULHSU;

reg         calc_started        = 0; // 複数サイクルかかる計算を開始済みか
reg         is_calculated       = 0; // 複数サイクルかかる計算が終了しているか

iidtype     saved_inst_id       = INST_ID_RANDOM;
wire        may_start_m         = !is_calculated || saved_inst_id != inst_id; // 複数サイクルかかる計算を始める可能性があるか

wire        divm_start          = exe_valid && is_div && may_start_m && divm_ready;
wire        divm_signed         = m_exe == ALUM_DIV || m_exe == ALUM_REM;
wire        divm_ready;
wire        divm_valid;
wire        divm_error;
wire [32:0] divm_dividend       = divm_signed ? {op1_data[31], op1_data} : {1'b0, op1_data};
wire [32:0] divm_divisor        = divm_signed ? {op2_data[31], op2_data} : {1'b0, op2_data};
wire [32:0] divm_quotient;
wire [32:0] divm_remainder;

wire        multm_start         = exe_valid && is_mul && may_start_m && multm_ready;
wire        multm_signed        = m_exe == ALUM_MUL || m_exe == ALUM_MULH || m_exe == ALUM_MULHSU;
wire        multm_ready;
wire        multm_valid;
wire [32:0] multm_multiplicand  = multm_signed ? {op1_data[31], op1_data} : {1'b0, op1_data};
wire [32:0] multm_multiplier    = multm_signed && m_exe != ALUM_MULHSU ? {op2_data[31], op2_data} : {1'b0, op2_data};
wire [65:0] multm_product;

reg [31:0]  saved_result        = 0; // 複数サイクルかかる計算の結果
wire        calc_valid          = (is_div && divm_valid) || (is_mul && multm_valid); // 複数サイクルかかる計算が今クロックで終了したか
wire        is_multicycle_exe   = m_exe != ALUM_X; // 現在のm_exeが複数サイクルかかる計算かどうか

assign calc_stall_flg   = exe_valid && is_multicycle_exe && 
                          (divm_start || multm_start || !is_calculated); // モジュールで計算を始める = 未計算

assign exe_mem_valid    = exe_valid && !calc_stall_flg;
assign exe_mem_pc       = exe_pc;
assign exe_mem_inst     = exe_inst;
assign exe_mem_inst_id  = exe_inst_id;
assign exe_mem_ctrl     = exe_ctrl;
assign exe_mem_rs2_data = exe_rs2_data;

assign exe_mem_alu_out  = is_div || is_mul ? saved_result : alu_out;

assign branch_taken     = exe_valid && 
                          (exe_ctrl.jmp_pc_flg || exe_ctrl.jmp_reg_flg || alu_branch_take);
assign branch_target    = exe_ctrl.jmp_pc_flg ? exe_pc + exe_imm_j :
                          exe_ctrl.jmp_reg_flg ? op1_data + op2_data :
                          pc + exe_imm_b;

always @(posedge clk) begin
    if (exe_valid)
        saved_inst_id <= inst_id;
end

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
            case (m_exe) 
                ALUM_DIV     : saved_result <= divm_quotient[31:0];
                ALUM_DIVU    : saved_result <= divm_quotient[31:0];
                ALUM_REM     : saved_result <= divm_remainder[31:0];
                ALUM_REMU    : saved_result <= divm_remainder[31:0];
                ALUM_MUL     : saved_result <= multm_product[31:0];
                ALUM_MULH    : saved_result <= multm_product[63:32];
                ALUM_MULHU   : saved_result <= multm_product[63:32];
                ALUM_MULHSU  : saved_result <= multm_product[63:32];
                default     : saved_result <= 0;
            endcase
        end else begin
            is_calculated   <= 0;
        end
    end
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,exestage.valid,b,%b", exe_valid);
    $display("data,exestage.inst_id,h,%b", exe_valid ? exe_inst_id : INST_ID_NOP);
    if (exe_valid) begin
        $display("data,exestage.pc,h,%b", exe_pc);
        $display("data,exestage.inst,h,%b", exe_inst);
        $display("data,exestage.i_exe,d,%b", i_exe);
        $display("data,exestage.br_exe,d,%b", br_exe);
        $display("data,exestage.m_exe,d,%b", m_exe);
        $display("data,exestage.op1_data,h,%b", op1_data);
        $display("data,exestage.op2_data,h,%b", op2_data);
        $display("data,exestage.calc_stall,b,%b", calc_stall_flg);
        $display("data,exestage.ismulticyc,b,%b", is_multicycle_exe);
        $display("data,exestage.jmp_flg,d,%b", exe_ctrl.jmp_reg_flg || exe_ctrl.jmp_pc_flg);
        $display("data,exestage.branch_taken,b,%b", branch_taken);
        $display("data,exestage.branch_target,h,%b", branch_target);
    end
end
`endif

endmodule