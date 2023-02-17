module Memory (
    input wire clk,
    input wire [WORD_LEN-1:0] i_addr,
    output reg [WORD_LEN-1:0] inst,

    input  wire [4:0]  memory_cmd,
	output wire        memory_cmd_ready,
    input  wire [31:0] memory_d_addr,
    output wire [31:0] memory_rdata,
	output wire        memory_rdata_valid, 
    input  wire [31:0] memory_wmask,
    input  wire [31:0] memory_wdata
);

reg [31:0] mem [(16384 >> 2) - 1:0];

initial begin
    $readmemh("../../test/bin/sample.hex", mem);
end

endmodule
