`default_nettype none

module main (
    input  wire       clk,
	output reg [5:0]  led
);

reg			mem_inst_start;
reg			mem_inst_ready;
reg [31:0]	mem_i_addr;
reg [31:0]	mem_inst;
reg			mem_inst_valid;
reg [1:0]	mem_d_cmd;
reg			mem_d_cmd_ready;
reg [31:0]	mem_d_addr;
reg [31:0]	mem_wdata;
reg [31:0]	mem_wmask;
reg [31:0]	mem_rdata;
reg			mem_rdata_valid;

reg [31:0] clkCount = 0;
wire led_2;

initial begin
	led[0] <= 0;
	led[1] <= 0;
	led[2] <= 0;
	led[3] <= 0;
	led[4] <= 0;
end

always @(posedge clk) begin
    if (clkCount > 1000000000)
		led[0] <= 0;
    else
		led[0] <= 1;
    led[1] <= led_2;
	clkCount <= clkCount + 1;
end

MemoryInterface #() memory (
    .clk(clk),

	.inst_start(mem_inst_start),
	.inst_ready(mem_inst_ready),
    .i_addr(mem_i_addr),
    .inst(mem_inst),
    .inst_valid(mem_inst_valid),
    .d_cmd(mem_d_cmd),
	.d_cmd_ready(mem_d_cmd_ready),
	.d_addr(mem_d_addr),
    .wdata(mem_wdata),
    .wmask(mem_wmask),
    .rdata(mem_rdata),
    .rdata_valid(mem_rdata_valid)
);

Core core (
    .clk(clk),

	.memory_inst_start(mem_inst_start),
	.memory_inst_ready(mem_inst_ready),
    .memory_i_addr(mem_i_addr),
    .memory_inst(mem_inst),
    .memory_inst_valid(mem_inst_valid),
    .memory_d_cmd(mem_d_cmd),
	.memory_d_cmd_ready(mem_d_cmd_ready),
	.memory_d_addr(mem_d_addr),
    .memory_wdata(mem_wdata),
    .memory_wmask(mem_wmask),
    .memory_rdata(mem_rdata),
    .memory_rdata_valid(mem_rdata_valid),

    .led_2(led_2)
);

endmodule
