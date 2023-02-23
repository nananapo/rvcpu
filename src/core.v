`default_nettype none

module Core(
    input   wire        clk,
	
	output reg			memory_inst_start,
	input  reg			memory_inst_ready,
	output reg [31:0]	memory_i_addr,
	input  reg [31:0]	memory_inst,
	input  reg			memory_inst_valid,
	output reg [2:0]	memory_d_cmd,
	input  reg			memory_d_cmd_ready,
	output reg [31:0]	memory_d_addr,
	output reg [31:0]	memory_wdata,
	output reg [31:0]	memory_wmask,
	input  reg [31:0]	memory_rdata,
	input  reg			memory_rdata_valid,

    output reg          led_2
);

assign led_2 = memory_inst_start == 0;


// 何クロック目かのカウント
reg [31:0] clk_count = 0;

// メモリステージのストールフラグ
wire wait_memory_stage;
wire memory_stage_is_stall = clk_count >= 5 ? wait_memory_stage : 0;

// レジスタ
wire [31:0]	regfile[31:0];

//**************************
// Fetch Stage
//**************************

// fetch -> decode 用のwire
wire [31:0]  id_reg_pc;
wire [31:0]  id_inst;

FetchStage #() fetchstage (
	.clk(clk),

	.id_reg_pc(id_reg_pc),
	.id_inst(id_inst),

	.mem_start(memory_inst_start),
	.mem_ready(memory_inst_ready),
	.mem_addr(memory_i_addr),
	.mem_data(memory_inst),
	.mem_data_valid(memory_inst_valid),

	.stall_flg(memory_stage_is_stall)
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
wire [4:0]  exe_mem_wen;
wire [0:0]  exe_rf_wen;
wire [3:0]  exe_wb_sel;
wire [4:0]  exe_wb_addr;
wire [2:0]  exe_csr_cmd;
wire 	    exe_jmp_flg;

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

	.stall_flg(memory_stage_is_stall)
);


// **************************
// Execute Stage
// **************************

wire [31:0] mem_alu_out;
wire        mem_br_flg;
wire [31:0] mem_br_target;

wire [31:0] mem_reg_pc;
wire [4:0]  mem_mem_wen;
wire [3:0]  mem_wb_sel;
wire [31:0] mem_rs2_data;
wire [31:0] csr_op1_data;
wire [2:0]	csr_csr_cmd;
wire [31:0]	csr_imm_i;

ExecuteStage #() executestage
(
    .clk(clk),

	.input_reg_pc(exe_reg_pc),
	.input_exe_fun(exe_exe_fun),
	.input_op1_data(exe_op1_data),
	.input_op2_data(exe_op2_data),
	.input_rs2_data(exe_rs2_data),
	.input_mem_wen(exe_mem_wen),
	.input_wb_sel(exe_wb_sel),
	.input_csr_cmd(exe_csr_cmd),
	.input_imm_i_sext(exe_imm_i_sext),
	.input_imm_b_sext(exe_imm_b_sext),

	.alu_out(mem_alu_out),
	.br_flg(mem_br_flg),
	.br_target(mem_br_target),

	.output_reg_pc(mem_reg_pc),
	.output_mem_wen(mem_mem_wen),
	.output_wb_sel(mem_wb_sel),
	.output_rs2_data(mem_rs2_data),
	.output_op1_data(csr_op1_data),
	.output_csr_cmd(csr_csr_cmd),
	.output_imm_i(csr_imm_i),

	.stall_flg(memory_stage_is_stall)
);

// **************************
// Memory Stage
// **************************

wire [31:0]		wb_read_data;
wire [31:0]		wb_reg_pc;
wire [31:0]		wb_alu_out;
wire [3:0]		wb_wb_sel;
wire			wb_next_flg;

MemoryStage #() memorystage
(
	.clk(clk),

	.reg_pc(mem_reg_pc),
    .rs2_data(mem_rs2_data),
    .alu_out(mem_alu_out),
    .mem_wen(mem_mem_wen),
    .wb_sel(mem_wb_sel),

	.output_read_data(wb_read_data),
	.output_reg_pc(wb_reg_pc),
	.output_alu_out(wb_alu_out),
	.output_wb_sel(wb_wb_sel),
	.next_flg(wb_next_flg),
	.output_is_stall(wait_memory_stage),

	.mem_cmd(memory_d_cmd),
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
wire [31:0]	trap_vector;

CSRStage #() csrstage
(
	.clk(clk),

	.csr_cmd(csr_csr_cmd),
	.op1_data(csr_op1_data),
	.imm_i(csr_imm_i),
	.trap_vector(trap_vector)
);



always @(negedge clk) begin
	clk_count <= clk_count + 1;
	$display("");
	$display("CLK %d", clk_count);
end

endmodule