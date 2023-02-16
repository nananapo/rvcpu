module CorePipeline #() (
    input   wire                clk,
    input   wire                rst_n,
    output  wire                exit,

    output  wire [31:0] memory_i_addr,
    input   wire [31:0] memory_inst,
    output  wire [31:0] memory_d_addr,
    input   wire [31:0] memory_rdata,
    output  wire        memory_wen,
    output  wire [31:0] memory_wmask,
    output  wire [31:0] memory_wdata,
    input   wire        memory_ready
);














endmodule
