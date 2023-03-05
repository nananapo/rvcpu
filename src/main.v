`default_nettype none

module main (
    input  wire         clk,
    output reg [5:0]    led,
    output reg          exit,
    output reg [31:0]   gp
);

reg         mem_inst_start;
reg         mem_inst_ready;
reg [31:0]  mem_i_addr;
reg [31:0]  mem_inst;
reg         mem_inst_valid;
reg         mem_d_cmd_start;
reg         mem_d_cmd_write;
reg         mem_d_cmd_ready;
reg [31:0]  mem_d_addr;
reg [31:0]  mem_wdata;
reg [31:0]  mem_wmask;
reg [31:0]  mem_rdata;
reg         mem_rdata_valid;

reg [31:0]  clkCount    = 0;
reg         exited      = 0;

always @(posedge clk) begin
    clkCount <= clkCount + 1;
    if (exit) begin
        exited <= 1;
    end
    led[0] = gp[5];
    led[1] = gp[4];
    led[2] = gp[3];
    led[3] = gp[2];
    led[4] = gp[1];
    led[5] = gp[0];
end

MemoryInterface #() memory (
    .clk(clk),

    .inst_start(mem_inst_start),
    .inst_ready(mem_inst_ready),
    .i_addr(mem_i_addr),
    .inst(mem_inst),
    .inst_valid(mem_inst_valid),
    .d_cmd_start(mem_d_cmd_start),
    .d_cmd_write(mem_d_cmd_write),
    .d_cmd_ready(mem_d_cmd_ready),
    .d_addr(mem_d_addr),
    .wdata(mem_wdata),
    .wmask(mem_wmask),
    .rdata(mem_rdata),
    .rdata_valid(mem_rdata_valid),

    .exited(exited)
);

Core core (
    .clk(clk),

    .memory_inst_start(mem_inst_start),
    .memory_inst_ready(mem_inst_ready),
    .memory_i_addr(mem_i_addr),
    .memory_inst(mem_inst),
    .memory_inst_valid(mem_inst_valid),
    .memory_d_cmd_start(mem_d_cmd_start),
    .memory_d_cmd_write(mem_d_cmd_write),
    .memory_d_cmd_ready(mem_d_cmd_ready),
    .memory_d_addr(mem_d_addr),
    .memory_wdata(mem_wdata),
    .memory_wmask(mem_wmask),
    .memory_rdata(mem_rdata),
    .memory_rdata_valid(mem_rdata_valid),

    .gp(gp),
    .exit(exit),

    .exited(exited)
);

endmodule