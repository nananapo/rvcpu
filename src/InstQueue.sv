
module InstQueue #(
    parameter QUEUE_SIZE = 16,
    parameter INITIAL_ADDR = 32'h0
) (
    input wire clk,

    inout wire IRequest     ireq,
    inout wire IResponse    iresp,
    inout wire IRequest     memreq,
    inout wire IResponse    memresp,

    input wire IUpdatePredictionIO updateio
);

`include "include/basicparams.svh"
`include "include/inst.svh"

typedef struct packed {
    logic [31:0] addr;
    logic [31:0] inst;
    IId inst_id;
} BufType;

wire buf_kill;
wire buf_wready;
wire buf_wready_next;
wire buf_wvalid;
wire BufType buf_wdata;
wire BufType buf_rdata;

assign buf_kill         = branch_hazard;
assign buf_wvalid       = requested && memresp.valid;
assign buf_wdata.addr   = request_pc;
assign buf_wdata.inst   = memresp.inst;
assign buf_wdata.inst_id= inst_id - IID_ONE;

assign iresp.addr       = buf_rdata.addr;
assign iresp.inst       = buf_rdata.inst;
assign iresp.inst_id    = buf_rdata.inst_id;

SyncQueue #(
    .DATA_SIZE($bits(BufType)),
    .QUEUE_SIZE(QUEUE_SIZE)
) resqueue (
    .clk(clk),
    .kill(buf_kill),

    .wready(buf_wready),
    .wready_next(buf_wready_next),
    .wvalid(buf_wvalid),
    .wdata(buf_wdata),

    .rready(iresp.ready),
    .rvalid(iresp.valid),
    .rdata(buf_rdata)
);

logic [31:0]  pc    = INITIAL_ADDR;
IId     inst_id     = IID_ZERO;

logic         requested   = 0;
logic [31:0]  request_pc  = 32'd0;

wire branch_hazard  = ireq.valid;

wire [31:0] next_pc;



logic [31:0] last_fetched_pc = 32'h0;
logic [31:0] last_fetched_inst = 32'h0;


// TODO この処理を適切な場所に移動したい。
wire [31:0] fetched_pc      = requested ? memresp.addr : last_fetched_pc;
wire [31:0] fetched_inst    = requested ? memresp.inst : last_fetched_inst;

wire [19:0] imm_j_g         = { fetched_inst[31],
                                fetched_inst[19:12],
                                fetched_inst[20],
                                fetched_inst[30:21]};
wire [11:0] imm_b_g         = { fetched_inst[31],
                                fetched_inst[7],
                                fetched_inst[30:25],
                                fetched_inst[11:8]};

wire [31:0] imm_j_sext      = {{11{imm_j_g[19]}}, imm_j_g, 1'b0};
wire [31:0] imm_b_sext      = {{19{imm_b_g[11]}}, imm_b_g, 1'b0};

wire [6:0]  inst_opcode     = fetched_inst[6:0];
wire [2:0]  inst_funct3     = fetched_inst[14:12];

wire        inst_is_jal     = inst_opcode == JAL_OP;
wire [31:0] jal_target      = fetched_pc + imm_j_sext;

wire inst_is_jalr = inst_opcode == JALR_OP && inst_funct3 == JALR_F3;
wire inst_is_br = inst_opcode == BR_OP;

wire jal_hazard = inst_is_jal && /* requested &&*/ request_pc != jal_target;
// TODO ここまで




// 分岐予測
wire [31:0] pred_pc_base = request_pc;
wire pred_taken;
wire [31:0] pred_taken_pc = pred_pc_base + imm_b_sext;
wire [31:0] next_pc_pred = pred_taken ? pred_taken_pc : pred_pc_base + 4;

`ifdef PRED_TBC
    TwoBitCounter #(
        .ADDR_WIDTH(10)
    ) bp (
        .clk(clk),
        .pc(pred_pc_base),
        .pred_taken(pred_taken),
        .updateio(updateio)
    );
    initial $display("branch pred : two bit counter");
`elsif PRED_LOCAL
    LocalHistory2bit #() bp (
        .clk(clk),
        .pc(pred_pc_base),
        .pred_taken(pred_taken),
        .updateio(updateio)
    );
    initial $display("branch pred : local history");
`elsif PRED_GLOBAL
    GlobalHistory2bit #() bp (
        .clk(clk),
        .pc(pred_pc_base),
        .pred_taken(pred_taken),
        .updateio(updateio)
    );
    initial $display("branch pred : global history");
`else
    `define NO_PREDICITION_MODULE
    assign pred_taken = 0; 
    initial $display("no branch prediction module is selected");
`endif

`ifdef DEBUG
    wire [31:0] __next_pc = jal_hazard ? jal_target + 4 :
                            inst_is_br ? next_pc_pred + 4: 
                            pc + 4;
    assign next_pc = __next_pc === 32'hxxxxxxxx ? 32'h0 : __next_pc;
`else
    // ここではbranch_hazard時のpcを指定しない。
    // branch_hazardはalways内で処理
    assign next_pc =    jal_hazard ? jal_target + 4 :
                        inst_is_br ? next_pc_pred + 4: 
                        pc + 4;
`endif







`ifdef PRINT_MEMPERF
int perf_counter = 0;
int clk_count = 0;
always @(posedge clk) begin
    perf_counter += {31'b0, requested && (memresp.valid && memresp.addr == request_pc)};
    if (clk_count % 10_000_000 == 0) begin
        $display("iperf : %d", perf_counter);
        perf_counter = 0;
    end
    clk_count += 1;
end
`endif

assign memreq.valid = buf_wready_next;
assign memreq.addr  =   branch_hazard ? ireq.addr :
                        jal_hazard ? jal_target :
                        inst_is_br ? next_pc_pred :
                        pc;

logic firstClk = 1;

always @(posedge clk) begin
    // 分岐予測に失敗
    if (branch_hazard) begin
        `ifdef PRINT_DEBUGINFO
            $display("info,fetchstage.event.branch_hazard,branch hazard");
        `endif
        pc          <= ireq.addr;
        requested   <= 0;
        request_pc  <= ireq.addr;
        last_fetched_pc  <= 32'h0;
        last_fetched_inst <= 32'h0;
    end else begin
        if (jal_hazard) begin
            `ifdef PRINT_DEBUGINFO
                $display("info,fetchstage.event.jal_detect,jal hazard");
            `endif
        end
        if (requested) begin
            // リクエストが完了した
            if (memresp.valid && memresp.addr == request_pc) begin
                `ifdef PRINT_DEBUGINFO
                    $display("info,fetchstage.event.fetch_end,fetch end");
                    $display("data,fetchstage.event.pc,h,%b", memresp.addr);
                    $display("data,fetchstage.event.inst,h,%b", memresp.inst);
                `endif

                last_fetched_pc <= memresp.addr;
                last_fetched_inst <= memresp.inst;

                // メモリがreadyかつmemreq.validならリクエストしてる
                if (memreq.ready && memreq.valid) begin
                    requested   <= 1;
                    request_pc  <= memreq.addr;
                    pc          <= next_pc;
                    inst_id     <= inst_id + 1;
                    `ifdef PRINT_DEBUGINFO
                        $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                    `endif
                end else
                    requested   <= 0;
            end
        end else begin
            // メモリがreadyかつmemreq.validならリクエストしてる
            if (memreq.ready && memreq.valid) begin
                pc          <= next_pc;
                requested   <= 1;
                request_pc  <= memreq.addr;
                inst_id     <= inst_id + 1;
                `ifdef PRINT_DEBUGINFO
                    $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                `endif
            end
        end
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,fetchstage.pc,h,%b", pc);
    $display("data,fetchstage.next_pc,h,%b", next_pc);
    // $display("data,fetchstage.ireq.valid,b,%b", ireq.valid);
    // $display("data,fetchstage.ireq.addr,h,%b", ireq.addr);
    $display("data,fetchstage.iresp.valid,b,%b", iresp.valid);
    $display("data,fetchstage.iresp.ready,b,%b", iresp.ready);
    $display("data,fetchstage.iresp.addr,h,%b", iresp.addr);
    $display("data,fetchstage.iresp.inst,h,%b", iresp.inst);
    // $display("data,fetchstage.memreq.ready,b,%b", memreq.ready);
    // $display("data,fetchstage.memreq.valid,b,%b", memreq.valid);
    // $display("data,fetchstage.memreq.addr,h,%b", memreq.addr);
    // $display("data,fetchstage.memresp.valid,b,%b", memresp.valid);
    // $display("data,fetchstage.memresp.addr,h,%b", memresp.addr);
    // $display("data,fetchstage.memresp.inst,h,%b", memresp.inst);
    $display("data,fetchstage.requested_pc,h,%b", request_pc);
    $display("data,fetchstage.requesting_pc,h,%b", memreq.addr);
    $display("data,fetchstage.requested_pc,h,%b", request_pc);
    $display("data,fetchstage.memresp.inst_is_br,b,%b", inst_is_br);
end
`endif

`ifdef PRINT_DEBUGINFO

always @(posedge clk) begin
    $display("data,btb.update.valid,b,%b", updateio.valid);
    $display("data,btb.update.pc,h,%b", updateio.pc);
    $display("data,btb.update.is_br,b,%b", updateio.is_br);
    $display("data,btb.update.is_jmp,b,%b", updateio.is_jmp);
    $display("data,btb.update.taken,b,%b", updateio.taken);
    $display("data,btb.update.target,h,%b", updateio.target);
    `ifdef DEBUG
        $display("data,btb.update.fail,b,%b", updateio.fail);
    `endif

    $display("data,btb.pred.inst,h,%b", fetched_inst);
    $display("data,btb.pred.when_pc_taken,h,%b", pred_taken_pc);
    $display("data,btb.pred.inst_is_jal,h,%b", inst_is_jal);
    $display("data,btb.pred.inst_is_jalr,h,%b", inst_is_jalr);
    $display("data,btb.pred.inst_is_br,h,%b", inst_is_br);

    $display("data,btb.pred.use_prediction,b,%b", !branch_hazard && !jal_hazard && inst_is_br);
    $display("data,btb.pred.pc,h,%b", pred_pc_base);
    $display("data,btb.pred.pred_pc,h,%b", next_pc_pred);
end
`endif

endmodule
