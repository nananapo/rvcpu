module MemoryInterface (
	input wire clk,
 
	input  wire			inst_start,
	output wire			inst_ready,
    input  wire [31:0]	i_addr,
    output reg  [31:0]	inst,
    output wire			inst_valid,

    input  wire [2:0]	d_cmd,
	output reg			d_cmd_ready,
	input  wire [31:0]	d_addr,
    input  wire [31:0]	wdata,
    input  wire [31:0]	wmask,
    output reg  [31:0]	rdata,
    output wire			rdata_valid
);

`include "memory_const.v"

reg inst_valid_reg  = 0;
reg inst_ready_reg  = 1;
reg rdata_valid_reg = 0;
reg d_cmd_ready_reg = 1;

assign inst_valid	= inst_valid_reg  && inst_start == 0;
assign inst_ready	= inst_ready_reg  && inst_start == 0;
assign rdata_valid	= rdata_valid_reg && d_cmd == MEMORY_CMD_NOP;
assign d_cmd_ready	= d_cmd_ready_reg && d_cmd == MEMORY_CMD_NOP;

// メモリ
reg			mem_cmd_start = 0;
reg			mem_cmd_write;
wire		mem_cmd_ready;
reg  [31:0]	mem_addr;
wire [31:0]	mem_rdata;
wire		mem_rdata_valid;
reg [31:0]	mem_wdata;
reg [31:0]	mem_wmask;

Memory #(
	.MEMORY_SIZE(4096),
	.MEMORY_FILE("../../test/bin/sample.hex")
) memory(
	.clk(clk),

	.cmd_start(mem_cmd_start),
	.cmd_write(mem_cmd_write),
	.cmd_ready(mem_cmd_ready),
	.addr(mem_addr),
	.rdata(mem_rdata),
	.rdata_valid(mem_rdata_valid),
	.wdata(mem_wdata),
	.wmask(mem_wmask)
);

localparam STATE_WAIT_CMD			= 4'd0;
localparam STATE_WAIT_MEMORY_READY	= 4'd1; // メモリがreadyになるのを待っている
localparam STATE_WAIT_MEMORY_READ	= 4'd2; // メモリのrdata_readyが1になるのを待っている
// writeは投げっぱなしなので待たない
localparam STATE_END				= 4'd3;

reg [3:0]	status		= STATE_WAIT_CMD;

// 現在の操作が命令フェッチかどうかのフラグ
reg 		cmd_is_inst	= 0;

// 保存用
reg [31:0]	save_i_addr;
reg [2:0]	save_d_cmd;
reg [31:0]	save_d_addr;
reg [31:0]	save_wdata;
reg [31:0]	save_wmask;

wire d_cmd_is_op = d_cmd != MEMORY_CMD_NOP;
/*
always @(posedge clk) begin
	$display("MEMINF -------------");
	$display("inst_start      : %d", inst_start);
	$display("inst_ready      : %d", inst_ready);
	$display("i_addr          : 0x%H", i_addr);
	$display("inst            : 0x%H", inst);
	$display("inst_valid      : %d", inst_valid);
	$display("d_cmd           : %d", d_cmd);
	$display("d_cmd_ready     : %d", d_cmd_ready);
	$display("d_addr          : 0x%H", d_addr);
	$display("wdata           : 0x%H", wdata);
	$display("wmask           : 0x%H", wmask);
	$display("rdata           : 0x%H", rdata);
	$display("rdata_valid     : %d", rdata_valid);
	$display("status          : %d", status);
	$display("cmd_is_inst     : %d", cmd_is_inst);
	$display("mem_cmd_start   : %d", mem_cmd_start);
	$display("mem_cmd_write   : %d", mem_cmd_write);
	$display("mem_cmd_ready   : %d", mem_cmd_ready);
	$display("mem_addr        : 0x%H", mem_addr);
	$display("mem_rdata       : 0x%H", mem_rdata);
	$display("mem_rdata_valid : %d", mem_rdata_valid);
end
*/

always @(posedge clk) begin
	if (status == STATE_WAIT_CMD) begin
		if (inst_start || d_cmd_is_op) begin
			// レジスタに退避
			save_i_addr	<= i_addr;
			save_d_cmd	<= d_cmd;
			save_d_addr	<= d_addr;
			save_wdata	<= wdata;
			save_wmask	<= wmask;
			// コマンドを受け付けなくする
			inst_ready_reg	<= 0;
			d_cmd_ready_reg	<= 0;
			// 記述を楽に済ますのを優先して、一旦待つ
			status		<= STATE_WAIT_MEMORY_READY;
		end

		// 両方のコマンドが来た時
		if (inst_start && d_cmd_is_op) begin
			// 命令を選ぶ
			cmd_is_inst		<= 1;
			inst_valid_reg	<= 0;
			rdata_valid_reg	<= 0;
		// 命令だけ
		end else if (inst_start) begin
			cmd_is_inst		<= 1;
			inst_valid_reg	<= 0;
		// データだけ
		end else if (d_cmd_is_op) begin
			cmd_is_inst		<= 0;
			rdata_valid_reg	<= 0;
		end
	end else if (status == STATE_WAIT_MEMORY_READY) begin
		if (mem_cmd_ready) begin
			mem_cmd_start <= 1;

			if (cmd_is_inst) begin
				mem_addr		<= save_i_addr;
				mem_cmd_write	<= 0;
				status <= STATE_WAIT_MEMORY_READ;
			end else begin
				mem_addr		<= save_d_addr;
				mem_cmd_write	<= save_d_cmd == MEMORY_CMD_WRITE;
				mem_wdata		<= save_wdata;
				mem_wmask		<= save_wmask;
				if (save_d_cmd == MEMORY_CMD_READ) begin
					status <= STATE_WAIT_MEMORY_READ;
				end else begin
					status <= STATE_END;
				end
			end
		end
	end else if (status == STATE_WAIT_MEMORY_READ) begin
		mem_cmd_start <= 0;
		if (mem_rdata_valid) begin
			if (cmd_is_inst) begin
				inst		<= mem_rdata;
				inst_valid_reg	<= 1;
			end else begin
				rdata			<= mem_rdata;
				rdata_valid_reg	<= 1;
			end
			status <= STATE_END;
		end
	end else if (status == STATE_END) begin
		mem_cmd_start <= 0;
		// 処理していたのが命令かつd_cmdがNOPでなければ処理
		if (cmd_is_inst && save_d_cmd != MEMORY_CMD_NOP) begin
			cmd_is_inst <= 0;
			status <= STATE_WAIT_MEMORY_READY;
		end else begin
			// コマンドを受け付ける
			inst_ready_reg	<= 1;
			d_cmd_ready_reg	<= 1;
			status <= STATE_WAIT_CMD;
		end
	end
end

endmodule