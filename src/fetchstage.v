module FetchStage(
	input  wire			clk,

    input  wire [31:0]  wb_reg_pc,
    input  wire         wb_branch_hazard,

	output wire [31:0]	id_reg_pc,
	output wire [31:0]	id_inst,

	output wire         mem_start,
	input  reg			mem_ready,
	output wire [31:0]  mem_addr,
	input  reg  [31:0]	mem_data,
	input  reg			mem_data_valid,

	input  reg			stall_flg
);

`include "include/core.v"

localparam STATE_WAIT_READY = 0;
localparam STATE_WAIT_VALID = 1;

reg         state        = STATE_WAIT_READY;

reg [31:0]  inner_reg_pc = 0;
reg         is_fetched   = 0;

// フェッチ済みのデータ
reg         saved_reg_pc = REGPC_NOP;
reg         saved_inst   = INST_NOP;

assign mem_start = (
    state == STATE_WAIT_READY ? mem_ready :
    state == STATE_WAIT_VALID ? (
        (!is_fetched && mem_data_valid) ? (
            stall_flg ? 0 : mem_ready
        ) :
        is_fetched ? (
            !stall_flg ? mem_ready : 0
        ) : 0
    ) : 0
);

assign mem_addr = (
    state == STATE_WAIT_READY ? (
        wb_branch_hazard ? wb_reg_pc : inner_reg_pc
    ) :
    state == STATE_WAIT_VALID ? (
        (!is_fetched && mem_data_valid) ? (
            stall_flg ? REGPC_NOP : (
                wb_branch_hazard ? wb_reg_pc : inner_reg_pc + 4
            )
        ) :
        is_fetched ? (
            !stall_flg ? (
                wb_branch_hazard ? wb_reg_pc : inner_reg_pc
            ) : REGPC_NOP
        ) : REGPC_NOP
    ) : REGPC_NOP
);

assign id_reg_pc = (
    stall_flg ? REGPC_NOP :
    wb_branch_hazard ? REGPC_NOP :
    state == STATE_WAIT_VALID ? (
        (!is_fetched && mem_data_valid) ? inner_reg_pc :
        is_fetched ? saved_reg_pc : REGPC_NOP
    ) : REGPC_NOP
);

assign id_inst = (
    stall_flg ? INST_NOP :
    wb_branch_hazard ? INST_NOP :
    state == STATE_WAIT_VALID ? (
        (!is_fetched && mem_data_valid) ? mem_data :
        is_fetched ? saved_inst : INST_NOP
    ) : INST_NOP
);

always @(posedge clk) begin
    if (state == STATE_WAIT_READY) begin
        if (mem_ready) begin
            state       <= STATE_WAIT_VALID;
            is_fetched  <= 0;
        end
    end else if (state == STATE_WAIT_VALID) begin
        if (wb_branch_hazard) begin
            inner_reg_pc <= wb_reg_pc;
            if (mem_ready) begin
                is_fetched <= 0;
            end else
                state <= STATE_WAIT_READY;
        end else begin
            if (!is_fetched && mem_data_valid) begin
                $display("Fetched");
                inner_reg_pc <= inner_reg_pc + 4;
                if (stall_flg) begin
                    saved_reg_pc    <= inner_reg_pc;
                    saved_inst      <= mem_data;
                    is_fetched      <= 1;
                end else begin
                    if (mem_ready) begin
                        is_fetched <= 0;
                    end else
                        state <= STATE_WAIT_READY;
                end
            end else if (is_fetched) begin
                if (!stall_flg) begin
                    if (mem_ready) begin
                        is_fetched <= 0;
                    end else
                        state <= STATE_WAIT_READY;
                end
            end
        end
    end
end

always @(posedge clk) begin
	$display("FETCH -------------");
	$display("status    : %d", state);
	$display("fetched   : %d", is_fetched);
	$display("reg_pc    : 0x%H", inner_reg_pc);
	$display("id.reg_pc : 0x%H", id_reg_pc);
	$display("id.inst   : 0x%H", id_inst);
	$display("mem.start : %d", mem_start);
	$display("mem.ready : %d", mem_ready);
	$display("mem.data  : 0x%H", mem_data);
	$display("mem.valid : %d", mem_data_valid);
	$display("stall_flg : %d", stall_flg);
end

endmodule