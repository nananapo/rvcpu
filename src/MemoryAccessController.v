module MemoryAccessController #(
    parameter MEMORY_SIZE = 4096,
    parameter MEMORY_FILE = ""
) (
    input  wire         clk,

    input  wire         cmd_start,
    input  wire         cmd_write,
    output wire         cmd_ready,

    input  wire [31:0]  addr,
    output reg  [31:0]  rdata,
    output wire         rdata_valid,
    input  wire [31:0]  wdata,
    input  wire [31:0]  wmask
);


MemoryAccessController #(
    .MEMORY_SIZE(MEMORY_SIZE),
    .MEMORY_FILE(MEMORY_FILE)
) memory (
    .clk(clk),

    .cmd_start(cmd_start),
    .cmd_write(cmd_write),
    .cmd_ready(cmd_ready),
    .addr(addr),
    .rdata(rdata),
    .rdata_valid(rdata_valid),
    .wdata(wdata),
    .wmask(wmask)
);

endmodule