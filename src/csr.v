module Csr #(
	parameter WORD_LEN		= 32,
    parameter REG_SIZE		= 4096,
	parameter REG_ADDR_SIZE	= 12,
	parameter TV_ADDR		= 12'h305
) (
	input wire						clk,
	input wire [REG_ADDR_SIZE-1:0]	addr,
	output reg [WORD_LEN-1:0]		rdata,
	input wire 						wen,
	input wire [WORD_LEN-1:0]		wdata,
	output reg [WORD_LEN-1:0]		trap_vector
);

reg [WORD_LEN-1:0] mem [REG_SIZE-1:0];

/*
integer loop_initial_regfile_i;
initial begin
    for (loop_initial_regfile_i = 0;
        loop_initial_regfile_i < 4096;
        loop_initial_regfile_i = loop_initial_regfile_i + 1)
        regfile[loop_initial_regfile_i] = 0;
end
*/

always @(posedge clk) begin
	rdata <= {mem[addr][7:0], mem[addr][15:8], mem[addr][23:16], mem[addr][31:24]};
	trap_vector <= {mem[TV_ADDR][7:0], mem[TV_ADDR][15:8], mem[TV_ADDR][23:16], mem[TV_ADDR][31:24]};
	if (wen) begin
		mem[addr] <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
	end
end

endmodule