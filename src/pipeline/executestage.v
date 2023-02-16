module ExecuteStage
(
	input wire clk,

	input reg [4:0]  exe_fun,
	input reg [31:0] op1_data,
	input reg [31:0] op2_data,
	input reg [31:0] reg_pc,
	input reg [31:0] imm_b_sext,

	output reg [31:0] alu_out,
	output reg        br_flg,
	output reg [31:0] br_target
);

`include "../consts_core.v"

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

	$display("EXECUTE -------------");
    $display("exe_fun   : %d", exe_fun);
    $display("op1_data  : 0x%H", op1_data);
    $display("op2_data  : 0x%H", op2_data);
    $display("reg_pc    : 0x%H", reg_pc);
    $display("imm_b_sext: 0x%H", imm_b_sext);
end

endmodule