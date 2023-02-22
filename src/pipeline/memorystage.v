module MemoryStage(
    input  wire			clk,

	input  reg [31:0]	reg_pc,
    input  reg [31:0]	rs2_data,
    input  reg [31:0]	alu_out,
    input  reg [4:0]	mem_wen,
    input  reg [3:0]	wb_sel,

	output reg [31:0]	output_read_data,
	output reg [31:0]	output_reg_pc,
	output reg [31:0]	output_alu_out,
	output reg [3:0]	output_wb_sel,
	output wire			next_flg,
	output reg			output_is_stall,

	output reg [2:0]	mem_d_cmd,
	input  reg			mem_d_cmd_ready,
	output reg [31:0]	mem_d_addr,
	output reg [31:0]	mem_wdata,
	output reg [31:0]	mem_wmask,
	input  reg [31:0]	mem_rdata,
	input  reg			mem_rdata_valid,
);

`include "../consts_core.v"
`include "memory_const.v"

localparam STATE_WAIT				= 0;
localparam STATE_WAIT_READY			= 1;
localparam STATE_WAIT_READ_VALID	= 2;
localparam STATE_END				= 3;

reg [3:0] state = STATE_WAIT;

reg [31:0]	save_reg_pc;
reg [31:0]	save_alu_out;
reg [31:0]	save_rs2_data;
reg [4:0]	save_mem_wen;
reg [3:0]	save_wb_sel;

wire is_store = save_mem_wen == MEN_SB || save_mem_wen == MEN_SH || save_mem_wen == MEN_SW;
//wire is_load  = !is_store && save_mem_wen != MEN_X;

assign next_flg =	(state == STATE_WAIT && mem_wen == MEN_X) ||
					(state == STATE_END);

assign output_is_stall = !next_flg;

always @(posedge clk) begin
	if (state == STATE_WAIT) begin
		if (mem_wen != MEN_X) begin
			state			<= STATE_WAIT_READY;
			save_reg_pc		<= reg_pc;
			save_alu_out	<= alu_out;
			save_rs2_data	<= rs2_data;
			save_mem_wen	<= mem_wen;
			save_wb_sel		<= wb_sel;
		end else begin
			output_read_data<= 32'hffffffff;
			output_reg_pc	<= reg_pc;
			output_alu_out	<= alu_out;
			output_wb_sel	<= wb_sel;
		end
	end else if (state == STATE_WAIT_READY) begin
		if (mem_d_cmd_ready) begin
			mem_d_addr	<= save_alu_out;
			if (is_store) begin
				mem_d_cmd	<= MEMORY_CMD_WRITE;
				mem_wdata	<= save_rs2_data;
				mem_wmask	<= (
					save_mem_wen == MEN_SB ? 32'h000000ff : 
					save_mem_wen == MEN_SH ? 32'h0000ffff : 
					32'hffffffff
				);
				state		<= STATE_END;
			end else begin
				mem_d_cmd	<= MEMORY_CMD_READ;
				state		<= STATE_WAIT_READ_VALID;
			end
		end
	end else if (state == STATE_WAIT_READ_VALID) begin
		if (mem_rdata_valid) begin
			state			<= STATE_END;
			output_read_data<= (
				save_mem_wen == MEN_LB ? {24'b0, mem_rdata[7:0]} :
				save_mem_wen == MEN_LBU? {{24{mem_rdata[7]}}, mem_rdata[7:0]} :
				save_mem_wen == MEN_LH ? {{16{mem_rdata[15]}}, mem_rdata[15:0]} :
				save_mem_wen == MEN_LHU? {16'b0, mem_rdata[15:0]} :
				mem_rdata
			);
		end
	end else if (state == STATE_END) begin
		state			<= STATE_WAIT;
		output_reg_pc	<= save_reg_pc;
		output_alu_out	<= save_alu_out;
		output_wb_sel	<= save_wb_sel;
	end
end


always @(posedge clk) begin
	$display("MEMORY STAGE-------------");
    $display("reg_pc        : 0x%H", reg_pc);
    $display("rs2_data      : 0x%H", rs2_data);
    $display("alu_out       : 0x%H", alu_out);
    $display("mem_wen       : %d", mem_wen);
    $display("wb_sel        : %d", wb_sel);
    $display("out.read_data : 0x%H", output_read_data);
    $display("out._reg_pc   : 0x%H", output_reg_pc);
    $display("out._alu_out  : 0x%H", output_alu_out);
    $display("out._wb_sel   : %d", output_wb_sel);
    $display("next_flg      : %d", next_flg);
end

endmodule