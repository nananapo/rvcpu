`default_nettype none

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

localparam REGPC_NOP	= 32'hffffffff;
localparam INST_NOP		= 32'h00000033;

localparam STATE_START		= 4'd0;
localparam STATE_WAIT_FETCH	= 4'd1;
localparam STATE_STOP		= 4'd2;

reg [31:0] reg_pc = 0;
reg [31:0] output_reg_pc_reg = REGPC_NOP;
reg [31:0] output_inst_reg = INST_NOP;

reg [3:0]  status = STATE_START;

reg        is_submitted = 0; // 次のステージに命令を送ったかのフラグ

assign id_reg_pc = (
	stall_flg ? REGPC_NOP : 
	status == STATE_WAIT_FETCH ? (
		mem_data_valid ? reg_pc : REGPC_NOP
	) :
	status == STATE_START ? (
		is_submitted ? REGPC_NOP : output_reg_pc_reg
	) :
	REGPC_NOP // ここには来ないはず
);

assign id_inst = (
	stall_flg ? INST_NOP :
	status == STATE_WAIT_FETCH ? (
		mem_data_valid ? mem_data : INST_NOP
	) :
	status == STATE_START ? (
		is_submitted ? INST_NOP : output_inst_reg
	) :
	INST_NOP// ここには来ないはず
);

always @(posedge clk) begin
	if (status == STATE_START) begin
		if (!stall_flg) begin
			if (mem_ready) begin
				mem_start	<= 1;
				mem_addr	<= reg_pc;
				status		<= STATE_WAIT_FETCH;
				is_submitted<= 0;
			end else begin
				is_submitted<= 1;
			end
		end
	end if (status == STATE_WAIT_FETCH) begin
		mem_start	<= 0;
		if (mem_data_valid) begin
			$display("Fetched");
			output_inst_reg		<= mem_data;
			output_reg_pc_reg	<= reg_pc;
			status				<= STATE_START;
			//reg_pc				<= reg_pc + 4;

			if (!stall_flg) begin
				is_submitted <= 1;
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
	$display("mem.data  : 0x%H", mem_data);
	$display("mem.valid : %d", mem_data_valid);
	$display("stall_flg : %d", stall_flg);
end

endmodule