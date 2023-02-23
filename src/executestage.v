module ExecuteStage
(
	input wire clk,

	input reg [31:0] input_reg_pc,
	input reg [4:0]  input_exe_fun,
	input reg [31:0] input_op1_data,
	input reg [31:0] input_op2_data,
	input reg [31:0] input_rs2_data,
	input reg [4:0]  input_mem_wen,
	input reg [3:0]  input_wb_sel,
	input reg [31:0] input_imm_b_sext,

	output reg [31:0] alu_out,
	output reg        br_flg,
	output reg [31:0] br_target,
	
	output reg [31:0] output_reg_pc,
	output reg [4:0]  output_mem_wen,
	output reg [3:0]  output_wb_sel,
	output reg [31:0] output_rs2_data,
	
	input  wire       stall_flg
);

`include "consts_core.v"

reg [31:0] save_reg_pc = 0;	
reg [4:0]  save_exe_fun = 0;	
reg [31:0] save_op1_data = 0;
reg [31:0] save_op2_data = 0;
reg [31:0] save_rs2_data = 0;
reg [4:0]  save_mem_wen = 0;	
reg [3:0]  save_wb_sel = 0;	
reg [31:0] save_imm_b_sext = 0;

wire [31:0] reg_pc		= stall_flg ? save_reg_pc : input_reg_pc;
wire [4:0]  exe_fun		= stall_flg ? save_exe_fun : input_exe_fun;
wire [31:0] op1_data	= stall_flg ? save_op1_data : input_op1_data;
wire [31:0] op2_data	= stall_flg ? save_op2_data : input_op2_data;
wire [31:0] rs2_data	= stall_flg ? save_rs2_data : input_rs2_data;
wire [4:0]  mem_wen		= stall_flg ? save_mem_wen : input_mem_wen;
wire [3:0]  wb_sel		= stall_flg ? save_wb_sel : input_wb_sel;
wire [31:0] imm_b_sext	= stall_flg ? save_imm_b_sext : input_imm_b_sext;

always @(posedge clk) begin
	// EX STAGE
	alu_out <= (
	    exe_fun == ALU_ADD   ? op1_data + op2_data :
	    exe_fun == ALU_SUB   ? op1_data - op2_data :
	    exe_fun == ALU_AND   ? op1_data & op2_data :
	    exe_fun == ALU_OR    ? op1_data | op2_data :
	    exe_fun == ALU_XOR   ? op1_data ^ op2_data :
		exe_fun == ALU_SLL   ? op1_data << op2_data[4:0] :
		exe_fun == ALU_SRL   ? op1_data >> op2_data[4:0] :
		exe_fun == ALU_SRA   ? $signed($signed(op1_data) >>> op2_data[4:0]):
		exe_fun == ALU_SLT   ? ($signed(op1_data) < $signed(op2_data)) :
		exe_fun == ALU_SLTU  ? op1_data < op2_data :
		exe_fun == ALU_JALR  ? (op1_data + op2_data) & (~1) :
		exe_fun == ALU_COPY1 ? op1_data :
	    0
	);

	br_flg <= (
		exe_fun == BR_BEQ   ? (op1_data == op2_data) :
		exe_fun == BR_BNE   ? !(op1_data == op2_data) :
		exe_fun == BR_BLT   ? ($signed(op1_data) < $signed(op2_data)) :
		exe_fun == BR_BGE   ? !($signed(op1_data) < $signed(op2_data)) :
		exe_fun == BR_BLTU  ? (op1_data < op2_data) :
		exe_fun == BR_BGEU  ? !(op1_data < op2_data) :
		0
	);

	br_target <= reg_pc + imm_b_sext;

	output_reg_pc   <= reg_pc;
	output_mem_wen  <= mem_wen;
	output_wb_sel   <= wb_sel;
	output_rs2_data <= rs2_data;

	// save
	save_reg_pc		<= reg_pc;	
	save_exe_fun	<= exe_fun;	
	save_op1_data	<= op1_data;
	save_op2_data	<= op2_data;
	save_rs2_data	<= rs2_data;
	save_mem_wen	<= mem_wen;	
	save_wb_sel		<= wb_sel;	
	save_imm_b_sext	<= imm_b_sext;
end

always @(posedge clk) begin
	$display("EXECUTE -------------");
    $display("exe_fun   : %d", exe_fun);
    $display("op1_data  : 0x%H", op1_data);
    $display("op2_data  : 0x%H", op2_data);
    $display("reg_pc    : 0x%H", reg_pc);
    $display("imm_b_sext: 0x%H", imm_b_sext);
end

endmodule