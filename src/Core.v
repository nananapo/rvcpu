`default_nettype none

module Core(
    input  wire         clk,
    
    output reg          memory_inst_start,
    input  wire         memory_inst_ready,
    output reg [31:0]   memory_i_addr,
    input  wire [31:0]  memory_inst,
    input  wire         memory_inst_valid,
    output reg          memory_d_cmd_start,
    output reg          memory_d_cmd_write,
    input  wire         memory_d_cmd_ready,
    output reg [31:0]   memory_d_addr,
    output reg [31:0]   memory_wdata,
    output reg [31:0]   memory_wmask,
    input  wire [31:0]  memory_rdata,
    input  wire         memory_rdata_valid,

    output reg          exit,
    output reg [31:0]   gp,
    
    input wire          exited
);

`include "include/core.v"

// 何クロック目かのカウント
reg [31:0] clk_count = 0;

// メモリステージのストールフラグ
wire memory_stage_is_stall;

// データハザードによるストールフラグ
wire data_hazard_stall;

// レジスタ
wire [31:0] regfile[31:0];

assign gp   = regfile[3];

// wbstageからfetchへのライトバック
wire [31:0] wb_to_fetch_reg_pc;
// 分岐ハザードが起きてしまいましたフラグ
wire        wbstage_branch_hazard;
// fence.i命令でストールするかのフラグ
wire        id_zifencei_stall_flg;

//**************************
// Fetch Stage
//**************************

// fetch -> decode 用のwire
wire [31:0]  id_reg_pc;
wire [31:0]  id_inst;

FetchStage #() fetchstage (
    .clk(clk),

    .wb_reg_pc(wbstage_branch_hazard ? wb_to_fetch_reg_pc : 32'h00000000),
    .wb_branch_hazard(wbstage_branch_hazard || exited),

    .id_reg_pc(id_reg_pc),
    .id_inst(id_inst),

    .mem_start(memory_inst_start),
    .mem_ready(memory_inst_ready),
    .mem_addr(memory_i_addr),
    .mem_data(memory_inst),
    .mem_data_valid(memory_inst_valid),

    .stall_flg(memory_stage_is_stall || data_hazard_stall || id_zifencei_stall_flg)
);



// **************************
// Decode Stage
// **************************

// decode -> exe 用のwire
wire [31:0] exe_imm_i_sext;
wire [31:0] exe_imm_s_sext;
wire [31:0] exe_imm_b_sext;
wire [31:0] exe_imm_j_sext;
wire [31:0] exe_imm_u_shifted;
wire [31:0] exe_imm_z_uext;

wire [31:0] exe_reg_pc;
wire [4:0]  exe_exe_fun; // TODO bitwise
wire [31:0] exe_op1_data;
wire [31:0] exe_op2_data;
wire [31:0] exe_rs2_data;
wire [3:0]  exe_mem_wen;
wire        exe_rf_wen;
wire [3:0]  exe_wb_sel;
wire [4:0]  exe_wb_addr;
wire [2:0]  exe_csr_cmd;
wire        exe_jmp_flg;
wire        exe_inst_is_ecall;

DecodeStage #() decodestage
(
    .clk(clk),

    .input_inst(id_inst),
    .input_reg_pc(id_reg_pc),
    .regfile(regfile),

    .imm_i_sext(exe_imm_i_sext),
    .imm_s_sext(exe_imm_s_sext),
    .imm_b_sext(exe_imm_b_sext),
    .imm_j_sext(exe_imm_j_sext),
    .imm_u_shifted(exe_imm_u_shifted),
    .imm_z_uext(exe_imm_z_uext),

    .output_reg_pc(exe_reg_pc),
    .exe_fun(exe_exe_fun),
    .op1_data(exe_op1_data),
    .op2_data(exe_op2_data),
    .rs2_data(exe_rs2_data),
    .mem_wen(exe_mem_wen),
    .rf_wen(exe_rf_wen),
    .wb_sel(exe_wb_sel),
    .wb_addr(exe_wb_addr),
    .csr_cmd(exe_csr_cmd),
    .jmp_flg(exe_jmp_flg),
    .output_inst_is_ecall(exe_inst_is_ecall),

    .memory_stage_stall_flg(memory_stage_is_stall),

    .wb_branch_hazard(wbstage_branch_hazard),

    .data_hazard_stall_flg(data_hazard_stall),
    .data_hazard_wb_rf_wen(wb_rf_wen),
    .data_hazard_wb_wb_addr(wb_wb_addr),
    .data_hazard_mem_rf_wen(mem_rf_wen),
    .data_hazard_mem_wb_addr(mem_wb_addr),
    .data_hazard_exe_rf_wen(exe_rf_wen),
    .data_hazard_exe_wb_addr(exe_wb_addr),
    
    .zifencei_stall_flg(id_zifencei_stall_flg),
    .zifencei_mem_mem_wen(mem_mem_wen == MEN_SB || mem_mem_wen == MEN_SH || mem_mem_wen == MEN_SW),
    .zifencei_exe_mem_wen(exe_mem_wen == MEN_SB || exe_mem_wen == MEN_SH || exe_mem_wen == MEN_SW)
);


// **************************
// Execute Stage
// **************************

wire [31:0] mem_alu_out;
wire        mem_br_flg;
wire [31:0] mem_br_target;
wire        mem_inst_is_ecall;

wire [31:0] mem_reg_pc;
wire [3:0]  mem_mem_wen;
wire        mem_rf_wen;
wire [3:0]  mem_wb_sel;
wire [31:0] mem_rs2_data;
wire [31:0] csr_op1_data;
wire [2:0]  csr_csr_cmd;
wire        mem_jmp_flg;
wire        mem_csr_cmd;
wire [4:0]  mem_wb_addr;
wire [31:0] csr_imm_i;

ExecuteStage #() executestage
(
    .clk(clk),

    .wb_branch_hazard(wbstage_branch_hazard),

    .input_reg_pc(exe_reg_pc),
    .input_exe_fun(exe_exe_fun),
    .input_op1_data(exe_op1_data),
    .input_op2_data(exe_op2_data),
    .input_rs2_data(exe_rs2_data),
    .input_mem_wen(exe_mem_wen),
    .input_rf_wen(exe_rf_wen),
    .input_wb_sel(exe_wb_sel),
    .input_wb_addr(exe_wb_addr),
    .input_csr_cmd(exe_csr_cmd),
    .input_jmp_flg(exe_jmp_flg),
    .input_imm_i_sext(exe_imm_i_sext),
    .input_imm_b_sext(exe_imm_b_sext),
    .input_inst_is_ecall(exe_inst_is_ecall),

    .alu_out(mem_alu_out),
    .br_flg(mem_br_flg),
    .br_target(mem_br_target),

    .output_reg_pc(mem_reg_pc),
    .output_mem_wen(mem_mem_wen),
    .output_rf_wen(mem_rf_wen),
    .output_rs2_data(mem_rs2_data),
    .output_op1_data(csr_op1_data),
    .output_wb_sel(mem_wb_sel),
    .output_wb_addr(mem_wb_addr),
    .output_csr_cmd(csr_csr_cmd),
    .output_jmp_flg(mem_jmp_flg),
    .output_imm_i(csr_imm_i),
    .output_inst_is_ecall(mem_inst_is_ecall),

    .stall_flg(memory_stage_is_stall)
);

// **************************
// Memory Stage
// **************************

wire        wb_rf_wen;
wire [31:0] wb_read_data;
wire [31:0] wb_reg_pc;
wire [31:0] wb_alu_out;
wire        wb_br_flg;
wire [31:0] wb_br_target;
wire [3:0]  wb_wb_sel;
wire [4:0]  wb_wb_addr;
wire        wb_jmp_flg;
wire        wb_inst_is_ecall;

MemoryStage #() memorystage
(
    .clk(clk),

    .wb_branch_hazard(wbstage_branch_hazard),

    .input_reg_pc(mem_reg_pc),
    .input_rs2_data(mem_rs2_data),
    .input_alu_out(mem_alu_out),
    .input_br_flg(mem_br_flg),
    .input_br_target(mem_br_target),
    .input_mem_wen(mem_mem_wen),
    .input_rf_wen(mem_rf_wen),
    .input_wb_sel(mem_wb_sel),
    .input_wb_addr(mem_wb_addr),
    .input_jmp_flg(mem_jmp_flg),
    .input_inst_is_ecall(mem_inst_is_ecall),

    .output_rf_wen(wb_rf_wen),
    .output_read_data(wb_read_data),
    .output_reg_pc(wb_reg_pc),
    .output_alu_out(wb_alu_out),
    .output_br_flg(wb_br_flg),
    .output_br_target(wb_br_target),
    .output_wb_sel(wb_wb_sel),
    .output_wb_addr(wb_wb_addr),
    .output_jmp_flg(wb_jmp_flg),
    .output_inst_is_ecall(wb_inst_is_ecall),
    .output_is_stall(memory_stage_is_stall),

    .mem_cmd_start(memory_d_cmd_start),
    .mem_cmd_write(memory_d_cmd_write),
    .mem_cmd_ready(memory_d_cmd_ready),
    .mem_addr(memory_d_addr),
    .mem_wdata(memory_wdata),
    .mem_wmask(memory_wmask),
    .mem_rdata(memory_rdata),
    .mem_rdata_valid(memory_rdata_valid)
);

// **************************
// CSR Stage
// **************************
wire [31:0]    wb_csr_rdata;
wire [31:0]    wb_trap_vector;

CSRStage #() csrstage
(
    .clk(clk),

    .wb_branch_hazard(wbstage_branch_hazard),

    .input_csr_cmd(csr_csr_cmd),
    .input_op1_data(csr_op1_data),
    .input_imm_i(csr_imm_i),

    .csr_rdata(wb_csr_rdata),
    .trap_vector(wb_trap_vector)
);


// **************************
// WriteBack Stage
// **************************
WriteBackStage #() wbstage(
    .clk(clk),

    .reg_pc(wb_reg_pc),
    .wb_sel(wb_wb_sel),
    .csr_rdata(wb_csr_rdata),
    .memory_rdata(wb_read_data),
    .wb_addr(wb_wb_addr),
    .jmp_flg(wb_jmp_flg),
    .rf_wen(wb_rf_wen),
    .br_flg(wb_br_flg),
    .br_target(wb_br_target),
    .alu_out(wb_alu_out),
    .inst_is_ecall(wb_inst_is_ecall),
    .trap_vector(wb_trap_vector),

    .output_reg_pc(wb_to_fetch_reg_pc),
    .output_branch_hazard(wbstage_branch_hazard),

    .regfile(regfile),

    .exit(exit)
);

`ifdef DEBUG 
always @(negedge clk) begin
    clk_count <= clk_count + 1;
    $display("");
    $display("CLK %d", clk_count);
    $display("gp   : ", gp);
    $display("exit : ", exit);
end

always @(posedge clk) begin
    $display("Registers --------------");
    $display("1: 0x%H   9: 0x%H  17: 0x%H  25: 0x%H", regfile[1], regfile[9] , regfile[17], regfile[25]);
    $display("2: 0x%H  10: 0x%H  18: 0x%H  26: 0x%H", regfile[2], regfile[10], regfile[18], regfile[26]);
    $display("3: 0x%H  11: 0x%H  19: 0x%H  27: 0x%H", regfile[3], regfile[11], regfile[19], regfile[27]);
    $display("4: 0x%H  12: 0x%H  20: 0x%H  28: 0x%H", regfile[4], regfile[12], regfile[20], regfile[28]);
    $display("5: 0x%H  13: 0x%H  21: 0x%H  29: 0x%H", regfile[5], regfile[13], regfile[21], regfile[29]);
    $display("6: 0x%H  14: 0x%H  22: 0x%H  30: 0x%H", regfile[6], regfile[14], regfile[22], regfile[30]);
    $display("7: 0x%H  15: 0x%H  23: 0x%H  31: 0x%H", regfile[7], regfile[15], regfile[23], regfile[31]);
    $display("8: 0x%H  16: 0x%H  24: 0x%H  ",         regfile[8], regfile[16], regfile[24]);
end
`endif

endmodule