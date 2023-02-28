module MemoryStage(
    input  wire			clk,

    input  wire         wb_branch_hazard,

	input  reg [31:0]	input_reg_pc,
    input  reg [31:0]	input_rs2_data,
    input  reg [31:0]	input_alu_out,
    input  reg 			input_br_flg,
    input  reg [31:0]	input_br_target,
    input  reg [4:0]	input_mem_wen,
	input  reg 			input_rf_wen,
    input  reg [3:0]	input_wb_sel,
	input  reg [4:0]	input_wb_addr,
	input  reg			input_jmp_flg,
	input  reg			input_inst_is_ecall,

	output wire [31:0]	output_read_data,
	output wire [31:0]	output_reg_pc,
	output wire [31:0]	output_alu_out,
	output wire 		output_br_flg,
	output wire [31:0]	output_br_target,
	output wire 		output_rf_wen,
	output wire [3:0]	output_wb_sel,
	output wire [4:0]	output_wb_addr,
	output wire			output_jmp_flg,
	output wire			output_inst_is_ecall,
	output wire			output_is_stall,

	output wire         mem_cmd_start,
	output wire         mem_cmd_write,
	input  reg			mem_cmd_ready,
	output wire [31:0]	mem_addr,
	output wire [31:0]	mem_wdata,
	output wire [31:0]	mem_wmask,
	input  reg  [31:0]	mem_rdata,
	input  reg			mem_rdata_valid
);

`include "include/core.v"
`include "include/memoryinterface.v"

localparam STATE_WAIT				= 0;
localparam STATE_WAIT_READY			= 1;
localparam STATE_WAIT_READ_VALID	= 2;

reg [1:0]   state           = STATE_WAIT;

wire [31:0]	reg_pc          = wb_branch_hazard ? REGPC_NOP      : input_reg_pc;
wire [31:0]	rs2_data        = wb_branch_hazard ? 32'hffffffff   : input_rs2_data;
wire [31:0]	alu_out         = wb_branch_hazard ? 32'hffffffff   : input_alu_out;
wire 		br_flg          = wb_branch_hazard ? 0              : input_br_flg;
wire [31:0]	br_target       = wb_branch_hazard ? 32'hffffffff   : input_br_target;
wire [4:0]	mem_wen         = wb_branch_hazard ? MEN_X          : input_mem_wen;
wire 		rf_wen          = wb_branch_hazard ? REN_X          : input_rf_wen;
wire [3:0]	wb_sel          = wb_branch_hazard ? WB_X           : input_wb_sel;
wire [4:0]	wb_addr         = wb_branch_hazard ? 0              : input_wb_addr;
wire		jmp_flg         = wb_branch_hazard ? 0              : input_jmp_flg;
wire		inst_is_ecall   = wb_branch_hazard ? 0              : input_inst_is_ecall;

reg [31:0]	save_reg_pc			= REGPC_NOP;
reg [31:0]	save_alu_out		= 0;
reg 		save_br_flg			= 0;
reg [31:0]	save_br_target		= 0;
reg [31:0]	save_rs2_data		= 0;
reg [4:0]	save_mem_wen		= 0;
reg 		save_rf_wen			= 0;
reg [3:0]	save_wb_sel			= 0;
reg [4:0]	save_wb_addr		= 0;
reg			save_jmp_flg		= 0;
reg			save_inst_is_ecall	= 0;


wire is_store       = mem_wen == MEN_SB || mem_wen == MEN_SH || mem_wen == MEN_SW;
wire is_load        = !is_store && mem_wen != MEN_X;
wire is_store_save  = save_mem_wen == MEN_SB || save_mem_wen == MEN_SH || save_mem_wen == MEN_SW;

wire next_flg =	(
    state == STATE_WAIT ? mem_wen == MEN_X :
    state == STATE_WAIT_READY ? is_store_save : 
    state == STATE_WAIT_READ_VALID ? mem_rdata_valid :
    1
);

assign output_is_stall = !next_flg;

// ***************
// MEMORY WIRE
// ***************
assign mem_cmd_start = (
    state == STATE_WAIT ? is_store || is_load : 
    state == STATE_WAIT_READY ? mem_cmd_ready : 0
);

assign mem_cmd_write = (
    state == STATE_WAIT ? is_store : 
    state == STATE_WAIT_READY ? mem_cmd_ready && is_store_save : 0
);

assign mem_addr = (
    state == STATE_WAIT ? alu_out :
    state == STATE_WAIT_READY ? save_alu_out :
    32'hffffffff
);

assign mem_wdata = (
    state == STATE_WAIT ? rs2_data : 
    state == STATE_WAIT_READY ? save_rs2_data : 
    32'hffffffff
);

assign mem_wmask = (
    state == STATE_WAIT ? (
        mem_wen == MEN_SB ? 32'h000000ff :
        mem_wen == MEN_SH ? 32'h0000ffff :
        32'hffffffff
    ) : 
    state == STATE_WAIT_READY ? (
        save_mem_wen == MEN_SB ? 32'h000000ff :
        save_mem_wen == MEN_SH ? 32'h0000ffff :
        32'hffffffff
    ) : 
    32'hffffffff
);

// ***************
// OUTPUT
// ***************

/* 参考
assign output_reg_pc = (
    state == STATE_WAIT ? (
        (!is_store && !is_load) ? reg_pc :
        mem_cmd_ready ? (
            is_store ? reg_pc : 32'hffffffff
        ) : 32'hffffffff
    ) :
    state == STATE_WAIT_READY ? (
        is_store_save ? save_reg_pc : 32'hffffffff
    ) :
    state == STATE_WAIT_READ_VALID ? (
        mem_rdata_valid ? save_reg_pc : 32'hffffffff
    ) : 32'hffffffff
);
*/

assign output_read_data = (
    state == STATE_WAIT ? 32'hffffffff :
    state == STATE_WAIT_READ_VALID ? (
        mem_rdata_valid ? (
				save_mem_wen == MEN_LB ? {24'b0, mem_rdata[7:0]} :
				save_mem_wen == MEN_LBU? {{24{mem_rdata[7]}}, mem_rdata[7:0]} :
				save_mem_wen == MEN_LH ? {{16{mem_rdata[15]}}, mem_rdata[15:0]} :
				save_mem_wen == MEN_LHU? {16'b0, mem_rdata[15:0]} :
				mem_rdata
        ) : 32'hffffffff
    ) : 32'hffffffff
);

wire output_is_current = (
    state == STATE_WAIT ? (
        (!is_store && !is_load) ? 1 :
        mem_cmd_ready ? is_store : 0
    ) : 0
);

wire output_is_save = (
    state == STATE_WAIT ? 0 :
    state == STATE_WAIT_READY ? is_store_save :
    state == STATE_WAIT_READ_VALID ? mem_rdata_valid : 
    0
);

assign output_reg_pc = (
    output_is_current ? reg_pc :
    output_is_save ? save_reg_pc :
    32'hffffffff
);

assign output_alu_out  = (
    output_is_current ? alu_out :
    output_is_save ? save_alu_out :
    32'hffffffff
);

assign output_br_flg = (
    output_is_current ? br_flg :
    output_is_save ? save_br_flg :
    0
);

assign output_br_target = (
    output_is_current ? br_target :
    output_is_save ? save_br_target :
    32'hffffffff
);

assign output_rf_wen = (
    output_is_current ? rf_wen :
    output_is_save ? save_rf_wen :
    REN_X
);

assign output_wb_sel = (
    output_is_current ? wb_sel :
    output_is_save ? save_wb_sel :
    WB_X
);

assign output_wb_addr = (
    output_is_current ? wb_addr :
    output_is_save ? save_wb_addr :
    5'b11111
);

assign output_jmp_flg = (
    output_is_current ? jmp_flg :
    output_is_save ? save_jmp_flg :
    0
);

assign output_inst_is_ecall = (
    output_is_current ? inst_is_ecall :
    output_is_save ? save_inst_is_ecall :
    0
);

always @(posedge clk) begin
	if (wb_branch_hazard || state == STATE_WAIT) begin

		save_reg_pc			<= reg_pc;
		save_alu_out		<= alu_out;
		save_br_flg			<= br_flg;
		save_br_target		<= br_target;
		save_rs2_data		<= rs2_data;
		save_mem_wen		<= mem_wen;
		save_rf_wen			<= rf_wen;
		save_wb_sel			<= wb_sel;
		save_wb_addr		<= wb_addr;
		save_jmp_flg		<= jmp_flg;
		save_inst_is_ecall	<= inst_is_ecall;

        if (is_store) begin
            if (mem_cmd_ready)
                state <= STATE_WAIT;
            else
                state <= STATE_WAIT_READY;
        end else if (is_load) begin
            if (mem_cmd_ready)
                state <= STATE_WAIT_READ_VALID;
            else
                state <= STATE_WAIT_READY;
        end
	end else if (state == STATE_WAIT_READY) begin
		if (mem_cmd_ready) begin
            if (is_store_save) 
			    state <= STATE_WAIT_READ_VALID;
            else
        		state <= STATE_WAIT;
		end
	end else if (state == STATE_WAIT_READ_VALID) begin
		if (mem_rdata_valid)
			state <= STATE_WAIT;
	end
end


always @(posedge clk) begin
	$display("MEMORY STAGE-------------");
	$display("status        : %d", state);
    $display("reg_pc        : 0x%H", reg_pc);
    $display("rs2_data      : 0x%H", rs2_data);
    $display("alu_out       : 0x%H", alu_out);
    $display("mem_wen       : %d", mem_wen);
    $display("wb_sel        : %d", wb_sel);
    $display("is_load       : %d", is_load);
    $display("is_store      : %d", is_store);
    $display("is_store.save : %d", is_store_save);
    $display("out.read_data : 0x%H", output_read_data);
    $display("out._reg_pc   : 0x%H", output_reg_pc);
    $display("out._alu_out  : 0x%H", output_alu_out);
    $display("out._wb_sel   : %d", output_wb_sel);
    $display("next_flg      : %d", next_flg);
    $display("stall_flg     : %d", output_is_stall);
	$display("mem.cmd.s     : %d", mem_cmd_start);
	$display("mem.cmd.w     : %d", mem_cmd_write);
	$display("mem.cmd_ready : %d", mem_cmd_ready);
	$display("mem.addr      : 0x%H", mem_addr);
	$display("mem.wdata     : 0x%H", mem_wdata);
	$display("mem.wmask     : 0x%H", mem_wmask);
	$display("mem.rdata     : 0x%H", mem_rdata);
	$display("mem.valid     : %d", mem_rdata_valid);
end

endmodule