module FetchStage(
    input  wire         clk,

    input  wire [31:0]  wb_reg_pc,
    input  wire         wb_branch_hazard,

    output reg [31:0]   id_reg_pc,
    output reg [31:0]   id_inst,

    output wire         mem_start,
    input  wire         mem_ready,
    output wire [31:0]  mem_addr,
    input  wire [31:0]  mem_data,
    input  wire         mem_data_valid,

    input  wire         stall_flg
);

`include "include/core.v"

localparam STATE_WAIT_READY = 0;
localparam STATE_WAIT_VALID = 1;

reg         state        = STATE_WAIT_READY;

reg [31:0]  inner_reg_pc = 0;
reg         is_fetched   = 0;

initial begin
    id_reg_pc   = REGPC_NOP;
    id_inst     = INST_NOP;
end

// フェッチ済みのデータ
reg [31:0]  saved_reg_pc = REGPC_NOP;
reg [31:0]  saved_inst   = INST_NOP;

function func_mem_start(
    input state,
    input mem_ready,
    input is_fetched,
    input mem_data_valid,
    input stall_flg
);
    case (state)
        STATE_WAIT_READY : func_mem_start = mem_ready;
        STATE_WAIT_VALID : begin
            if (stall_flg)
                func_mem_start = 0;
            else if (!is_fetched && mem_data_valid)
                func_mem_start = mem_ready;
            else if (is_fetched)
                func_mem_start = mem_ready;
            else
                func_mem_start = 0;
        end
    endcase

endfunction

assign mem_start = func_mem_start(
    state,
    mem_ready,
    is_fetched,
    mem_data_valid,
    stall_flg
);

function [31:0] func_mem_addr(
    input state,
    input wb_branch_hazard,
    input [31:0] wb_reg_pc,
    input [31:0] inner_reg_pc,
    input stall_flg,
    input is_fetched,
    input mem_data_valid
);
    case (state)
        STATE_WAIT_READY :
            func_mem_addr = wb_branch_hazard ? wb_reg_pc : inner_reg_pc;
        STATE_WAIT_VALID : begin
            if (stall_flg)
                func_mem_addr = REGPC_NOP;
            else if (!is_fetched && mem_data_valid)
                func_mem_addr = wb_branch_hazard ? wb_reg_pc : inner_reg_pc + 4;
            else if (is_fetched)
                func_mem_addr = wb_branch_hazard ? wb_reg_pc : inner_reg_pc;
            else
                func_mem_addr = REGPC_NOP;
        end
    endcase
endfunction

assign mem_addr = func_mem_addr(
    state,
    wb_branch_hazard,
    wb_reg_pc,
    inner_reg_pc,
    stall_flg,
    is_fetched,
    mem_data_valid
);

function [31:0] func_output_reg_pc(
    input stall_flg,
    input wb_branch_hazard,
    input state,
    input is_fetched,
    input mem_data_valid,
    input [31:0] inner_reg_pc,
    input [31:0] saved_reg_pc
);
    if (stall_flg || wb_branch_hazard)
        func_output_reg_pc = REGPC_NOP;
    else if (state == STATE_WAIT_VALID) begin
        if (!is_fetched && mem_data_valid)
            func_output_reg_pc = inner_reg_pc;
        else if (is_fetched)
            func_output_reg_pc = saved_reg_pc;
        else
            func_output_reg_pc = REGPC_NOP;
    end else 
        func_output_reg_pc = REGPC_NOP;
endfunction

wire [31:0] output_reg_pc = func_output_reg_pc(
    stall_flg,
    wb_branch_hazard,
    state,
    is_fetched,
    mem_data_valid,
    inner_reg_pc,
    saved_reg_pc
);

function [31:0] func_output_inst(
    input stall_flg,
    input wb_branch_hazard,
    input state,
    input is_fetched,
    input mem_data_valid,
    input [31:0] mem_data,
    input [31:0] saved_inst
);
    if (stall_flg || wb_branch_hazard)
        func_output_inst = INST_NOP;
    else if (state == STATE_WAIT_VALID) begin
        if (!is_fetched && mem_data_valid)
            func_output_inst = mem_data;
        else if (is_fetched)
            func_output_inst = saved_inst;
        else
            func_output_inst = INST_NOP;
    end else
        func_output_inst = INST_NOP;
endfunction

wire [31:0] output_inst = func_output_inst(
    stall_flg,
    wb_branch_hazard,
    state,
    is_fetched,
    mem_data_valid,
    mem_data,
    saved_inst
);

always @(posedge clk) begin
    if (!stall_flg) begin
        id_reg_pc   <= output_reg_pc;
        id_inst     <= output_inst;
    end
    if (wb_branch_hazard) begin
        inner_reg_pc <= wb_reg_pc;
    end

    case (state)
        STATE_WAIT_READY: begin
            if (mem_ready) begin
                state       <= STATE_WAIT_VALID;
                is_fetched  <= 0;
            end
        end
        STATE_WAIT_VALID: begin
            if (wb_branch_hazard) begin
                inner_reg_pc <= wb_reg_pc;
                if (mem_ready) begin
                    is_fetched <= 0;
                end else
                    state <= STATE_WAIT_READY;
            end else begin
                if (!is_fetched && mem_data_valid) begin
`ifdef DEBUG 
                    $display("Fetched");
`endif
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
    endcase
end

`ifdef DEBUG 
always @(posedge clk) begin
    $display("FETCH -------------");
    $display("status        : %d", state);
    $display("fetched       : %d", is_fetched);
    $display("reg_pc        : 0x%H", inner_reg_pc);
    $display("out.reg_pc    : 0x%H", output_reg_pc);
    $display("out.inst      : 0x%H", output_inst);
    $display("id.reg_pc     : 0x%H", id_reg_pc);
    $display("id.inst       : 0x%H", id_inst);
    $display("mem.start     : %d", mem_start);
    $display("mem.ready     : %d", mem_ready);
    $display("mem.data      : 0x%H", mem_data);
    $display("mem.valid     : %d", mem_data_valid);
    $display("stall_flg     : %d", stall_flg);
    $display("branch_haz    : %d", wb_branch_hazard);
    $display("branch_adr    : 0x%H", wb_reg_pc);
end
`endif

endmodule