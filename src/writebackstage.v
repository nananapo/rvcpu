module WriteBackStage(
	input  wire 		clk,

	input  wire [31:0]	reg_pc,
	input  wire [3:0]	wb_sel,
	input  wire [31:0]	csr_rdata,
	input  wire [31:0]	memory_read,
	input  wire [4:0]	wb_addr,
	input  wire 		rf_wen,
	input  wire [31:0]	br_target,
	input  wire [31:0]	alu_out,
	input  wire			inst_is_ecall,
	input  wire [31:0]	trap_vector_addr,

	output reg [31:0]	regfile[31:0]
);

`include "include/core.v"

// WB STAGE
wire [31:0] wb_data = (
	wb_sel == WB_MEMB ? {{24{memory_read[7]}}, memory_read} :
	wb_sel == WB_MEMBU? {24'b0, memory_read} :
	wb_sel == WB_MEMH ? {{16{memory_read[15]}}, memory_read} :
	wb_sel == WB_MEMHU? {16'b0, memory_read} :
	wb_sel == WB_MEMW ? memory_read :
	wb_sel == WB_PC   ? reg_pc_plus4 :
	wb_sel == WB_CSR  ? csr_rdata :
	alu_out
);

always @(posedge clk) begin
	if (rf_wen == REN_S) begin
	    regfile[wb_addr] <= wb_data;
	end	
	reg_pc <= (
		br_flg ? br_target : 
		jmp_flg ? alu_out :
		inst_is_ecall ? trap_vector_addr :
		reg_pc_plus4
	);
end

endmodule