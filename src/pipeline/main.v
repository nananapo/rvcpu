module main (
	input wire clk
);

wire [31:0] memory_i_addr;
wire [31:0] memory_inst;

wire [4:0]  memory_cmd;
wire        memory_cmd_ready;
wire [31:0] memory_d_addr;
wire [31:0] memory_rdata;
wire        memory_rdata_valid; 
wire [31:0] memory_wmask;
wire [31:0] memory_wdata;

Memory #() memory (
    .clk(clk),

    .i_addr(memory_i_addr),
    .inst(memory_inst),

    .cmd(memory_cmd),
    .cmd_ready(memory_cmd_ready),
    .d_addr(memory_d_addr),
    .rdata(memory_rdata),
    .rdata_valid(memory_rdata_valid),
    .wmask(memory_wmask),
    .wdata(memory_wdata)
);

CorePipeline #() core (
    .clk(clk),

    .memory_i_addr(memory_i_addr),
    .memory_inst(memory_inst),

    .memory_cmd(memory_cmd),
	.memory_cmd_ready(memory_cmd_ready),
	.memory_d_addr(memory_d_addr),
	.memory_rdata(memory_rdata),
	.memory_rdata_valid(memory_rdata_valid),
	.memory_wmask(memory_wmask),
	.memory_wdata(memory_wdata)
);

endmodule
