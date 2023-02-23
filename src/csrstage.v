`default_nettype none

module CSRStage #(
	parameter TV_ADDR = 12'h305
)(
	input  wire			clk,
	
	// input
	input  wire [2:0]	csr_cmd,
	input  wire [31:0]	op1_data,
	input  wire [31:0]	imm_i,

	// output
	output reg  [31:0]	output_csr_rdata,
	output wire [31:0]	trap_vector
);

`include "include/core.v"

reg [31:0] mem [4095:0];

// trap先
assign trap_vector = {mem[TV_ADDR][7:0], mem[TV_ADDR][15:8], mem[TV_ADDR][23:16], mem[TV_ADDR][31:24]};

// ecallなら0x342を読む
wire [11:0] addr	= csr_cmd == CSR_E ? 12'h342 : imm_i;
wire [31:0] rdata	= {mem[addr][7:0], mem[addr][15:8], mem[addr][23:16], mem[addr][31:24]};

wire [31:0] wdata = (
	csr_cmd == CSR_W ? op1_data :
	csr_cmd == CSR_S ? rdata | op1_data :
	csr_cmd == CSR_C ? rdata & ~op1_data :
	csr_cmd == CSR_E ? 11 :
	0
);

always @(posedge clk) begin
	if (csr_cmd != CSR_X) begin
		output_csr_rdata	<= rdata;
		mem[addr]			<= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
	end
end

always @(posedge clk) begin
	$display("CSR STAGE------------");
	$display("cmd          : %d", csr_cmd);
	$display("op1_data     : %d", op1_data);
	$display("imm_i        : 0x%H", imm_i);
	$display("addr         : 0x%H", addr);
	$display("rdata        : 0x%H", rdata);
	$display("wdata        : 0x%H", wdata);
	$display("trap_vector  : 0x%H", trap_vector);
end

endmodule