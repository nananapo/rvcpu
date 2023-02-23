module CSRStage(
	input wire clk
	output reg [WORD_LEN-1:0]		trap_vector
);

// CSR
reg csr_clock = 0;  // CSR命令の時にレジスタ読み出しを待機するためのフラグ

wire [11:0] csr_addr = (
	csr_cmd == CSR_E ? 12'h342 : 
	imm_i
);

reg csr_wen = 0;
wire [WORD_LEN-1:0] csr_rdata;
wire [WORD_LEN-1:0] trap_vector_addr;
wire [WORD_LEN-1:0] csr_wdata = (
	csr_cmd == CSR_W ? op1_data :
	csr_cmd == CSR_S ? csr_rdata | op1_data :
	csr_cmd == CSR_C ? csr_rdata & ~op1_data :
	csr_cmd == CSR_E ? 11 : // 11はマシンモードからのecallであることを示す
	0
);

Csr csr (
	.clk(clk),
	.addr(csr_addr),
	.rdata(csr_rdata),
	.wen(csr_wen),
	.wdata(csr_wdata),
	.trap_vector(trap_vector_addr)
);

reg [WORD_LEN-1:0] mem [REG_SIZE-1:0];

endmodule