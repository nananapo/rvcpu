module FetchStage(
	input  wire			clk,

	output wire [31:0]	id_reg_pc,
	output wire [31:0]	id_inst,

	output reg			mem_start,
	input  reg			mem_ready,
	output reg [31:0]	mem_addr,
	input  reg [31:0]	mem_data,
	input  reg			mem_data_valid,

	input  reg			stall_flg
);

initial begin
	mem_start	<= 0;
end

reg [31:0] reg_pc = 0;

reg [31:0] output_reg_pc_reg;
reg [31:0] output_id_inst_reg;

localparam INST_NOP = 32'h00000033;

assign id_reg_pc = (
	stall_flg ? 0 : 
	mem_data_valid ? output_reg_pc_reg : 
	0
);

assign id_inst = (
	stall_flg ? INST_NOP :
	mem_data_valid ? output_id_inst_reg :
	INST_NOP
);

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
			status	<= STATE_START;
			$display("Fetched");
			if (!stall_flg) begin
				output_id_inst_reg	<= mem_data;
				output_reg_pc_reg	<= reg_pc;
				reg_pc				<= reg_pc + 4;
			end
		end
	end
end

always @(posedge clk) begin
	$display("FETCH -------------");
	$display("reg_pc    : 0x%H", reg_pc);
	$display("id_reg_pc : 0x%H", id_reg_pc);
	$display("id_inst   : 0x%H", id_inst);
	$display("status    : %d", status);
	$display("mem.start : %d", mem_start);
	$display("mem.ready : %d", mem_ready);
	$display("mem.valid : %d", mem_data_valid);
	$display("stall_flg : %d", stall_flg);
end

endmodule