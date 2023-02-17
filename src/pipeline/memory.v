module Memory (
    input wire clk,

    input wire [31:0] i_addr,
    output reg [31:0] inst,

    input  wire [4:0]  cmd,
	output wire        cmd_ready,
    input  wire [31:0] d_addr,
    output wire [31:0] rdata,
    input  wire [31:0] wmask,
    input  wire [31:0] wdata
);

reg [31:0] mem [(16384 >> 2) - 1:0];

initial begin
    $readmemh("../../test/bin/sample.hex", mem);
end

endmodule
