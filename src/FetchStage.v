module FetchStage(
    input  wire         clk,

    input  wire [31:0]  wb_reg_pc,
    input  wire         wb_branch_hazard,

    output reg [31:0]   id_reg_pc,
    output reg [31:0]   id_inst,

    output wire [31:0]  if_reg_pc,

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

wire [31:0] output_reg_pc = (
    stall_flg ? REGPC_NOP :
    wb_branch_hazard ? REGPC_NOP :
    state == STATE_WAIT_VALID ? (
        (!is_fetched && mem_data_valid) ? inner_reg_pc :
        is_fetched ? saved_reg_pc : REGPC_NOP
    ) : REGPC_NOP
);

wire [31:0] output_inst = (
    stall_flg ? INST_NOP :
    wb_branch_hazard ? INST_NOP :
    state == STATE_WAIT_VALID ? (
        (!is_fetched && mem_data_valid) ? mem_data :
        is_fetched ? saved_inst : INST_NOP
    ) : INST_NOP
);

assign if_reg_pc =  wb_branch_hazard ? wb_reg_pc :
                    (state == STATE_WAIT_VALID && is_fetched) ? saved_reg_pc :
                    inner_reg_pc;

always @(posedge clk) begin

    id_reg_pc   <= output_reg_pc;
    id_inst     <= output_inst;

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
`ifdef PRINT_DEBUGINFO 
                    $display("info,fetchstage.instruction_fetched,Instruction Fetched");
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

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,fetchstage.status,%b", state);
    $display("data,fetchstage.fetched,%b", is_fetched);
    $display("data,fetchstage.reg_pc,%b", inner_reg_pc);
    $display("data,fetchstage.out.reg_pc,%b", output_reg_pc);
    $display("data,fetchstage.out.inst,%b", output_inst);
    $display("data,fetchstage.id.reg_pc,%b", id_reg_pc);
    $display("data,fetchstage.id.inst,%b", id_inst);
    $display("data,fetchstage.mem.start,%b", mem_start);
    $display("data,fetchstage.mem.ready,%b", mem_ready);
    $display("data,fetchstage.mem.data,%b", mem_data);
    $display("data,fetchstage.mem.valid,%b", mem_data_valid);
    $display("data,fetchstage.stall_flg,%b", stall_flg);
    $display("data,fetchstage.branch_haz,%b", wb_branch_hazard);
    $display("data,fetchstage.branch_adr,%b", wb_reg_pc);
end
`endif

endmodule