module FetchStage(
	input  wire			clk,

	output reg [31:0]	reg_pc,
	output reg [31:0]	inst,

	output reg			mem_start,
	input  reg			mem_ready,
	output reg [31:0]	mem_addr,
	input  reg [31:0]	mem_data,
	input  reg			mem_data_valid,

	input  reg			stall_flg
);

initial begin
	reg_pc		<= 0;
	mem_start	<= 0;
end

localparam STATE_START		= 4'd0;
localparam STATE_WAIT_FETCH	= 4'd1;

reg [3:0] status = STATE_START;

always @(posedge clk) begin
	if (status == STATE_START) begin
		if (mem_ready) begin
			mem_start	<= 1;
			mem_addr	<= reg_pc;
			status		<= STATE_WAIT_FETCH;
		end
	end if (status == STATE_WAIT_FETCH) begin
		mem_start	<= 0;
		if (mem_data_valid) begin
			inst	<= mem_data;
			status	<= STATE_START;
			reg_pc	<= reg_pc + 4;
		end
	end
end

always @(posedge clk) begin
	$display("FETCH -------------");
	$display("reg_pc    : 0x%H", reg_pc);
	$display("inst      : 0x%H", inst);
	$display("status    : %d", status);
	$display("mem.start : %d", mem_start);
	$display("mem.ready : %d", mem_ready);
	$display("mem.valid : %d", mem_data_valid);
end

endmodule