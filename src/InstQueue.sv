module InstQueue #(
    parameter QUEUE_SIZE = 16,
    parameter INITIAL_ADDR = 32'h0
) (
    input wire clk,

    inout wire IReq         ireq,
    inout wire IResp        iresp,
    inout wire CacheReq     memreq,
    inout wire CacheResp    memresp,
    input wire BrInfo       brinfo,

    input wire can_output_log
);

`include "basicparams.svh"
`include "inst.svh"

typedef struct packed {
    Addr    addr;
    Inst    inst;
    IId     inst_id; // TODO IIdを削除する
    logic   error;
    FaultTy errty;
} BufType;

wire buf_kill;
wire buf_wready;
wire buf_wvalid;
wire BufType buf_wdata;
wire BufType buf_rdata;

assign buf_kill         = branch_hazard;
assign buf_wvalid       = requested & memresp.valid;
assign buf_wdata.addr   = request_pc;
assign buf_wdata.inst   = memresp.rdata;
assign buf_wdata.inst_id= inst_id - IID_ONE;
assign buf_wdata.error  = memresp.error;
assign buf_wdata.errty  = memresp.errty;

assign iresp.addr       = buf_rdata.addr;
assign iresp.inst       = buf_rdata.inst;
assign iresp.inst_id    = buf_rdata.inst_id;
assign iresp.error      = buf_rdata.error;
assign iresp.errty      = buf_rdata.errty;

SyncQueue #(
    .DATA_SIZE($bits(BufType)),
    .WIDTH($clog2(QUEUE_SIZE)),
    .WREADY_NEXT(1),
    .LOG(0)
) resqueue (
    .clk(clk),
    .kill(buf_kill),

    .wready(buf_wready),
    .wvalid(buf_wvalid),
    .wdata(buf_wdata),

    .rready(iresp.ready),
    .rvalid(iresp.valid),
    .rdata(buf_rdata)
);

Addr    pc      = INITIAL_ADDR;
IId     inst_id = IID_ZERO;

logic   requested   = 0;
Addr    request_pc  = ADDR_ZERO;

wire branch_hazard  = ireq.valid;

wire Addr next_pc;



Addr last_fetched_pc    = 32'h0;
Inst last_fetched_inst  = 32'h0;


// TODO この処理を適切な場所に移動したい。
wire fetched_is_valid   = !requested | (memresp.valid & !memresp.error);
wire Addr fetched_pc    = requested ? request_pc : last_fetched_pc;
wire Inst fetched_inst  = requested ? memresp.rdata : last_fetched_inst;

wire [19:0] imm_j_g         = { fetched_inst[31],
                                fetched_inst[19:12],
                                fetched_inst[20],
                                fetched_inst[30:21]};
wire [11:0] imm_b_g         = { fetched_inst[31],
                                fetched_inst[7],
                                fetched_inst[30:25],
                                fetched_inst[11:8]};

wire UIntX  imm_j_sext      = {{11{imm_j_g[19]}}, imm_j_g, 1'b0};
wire UIntX  imm_b_sext      = {{19{imm_b_g[11]}}, imm_b_g, 1'b0};

wire [6:0]  inst_opcode     = fetched_inst[6:0];
wire [2:0]  inst_funct3     = fetched_inst[14:12];

wire Addr   jal_target      = fetched_pc + imm_j_sext;

wire inst_is_jal    = fetched_is_valid & inst_opcode == JAL_OP;
wire inst_is_jalr   = fetched_is_valid & inst_opcode == JALR_OP & inst_funct3 == JALR_F3;
wire inst_is_br     = fetched_is_valid & inst_opcode == BR_OP;
wire jal_hazard     = inst_is_jal & /* requested &*/ request_pc != jal_target;
// TODO ここまで




// 分岐予測
wire Addr pred_pc_base = request_pc;
wire pred_taken;
wire Addr pred_taken_pc = pred_pc_base + imm_b_sext;
wire Addr next_pc_pred = pred_taken ? pred_taken_pc : pred_pc_base + 4;

`ifdef PRED_TBC
    TwoBitCounter #(
        .ADDR_WIDTH(10)
    ) bp (
        .clk(clk),
        .pc(pred_pc_base),
        .pred_taken(pred_taken),
        .brinfo(brinfo)
    );
    initial $display("branch pred : two bit counter");
`elsif PRED_LOCAL
    LocalHistory2bit #() bp (
        .clk(clk),
        .pc(pred_pc_base),
        .pred_taken(pred_taken),
        .brinfo(brinfo)
    );
    initial $display("branch pred : local history");
`elsif PRED_GLOBAL
    GlobalHistory2bit #() bp (
        .clk(clk),
        .pc(pred_pc_base),
        .pred_taken(pred_taken),
        .brinfo(brinfo)
    );
    initial $display("branch pred : global history");
`else
    `define NO_PREDICITION_MODULE
    assign pred_taken = 0;
    initial $display("no branch prediction module is selected");
`endif

`ifdef DEBUG
    wire Addr __next_pc = jal_hazard ? jal_target + 4 :
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


assign memreq.valid = buf_wready;
assign memreq.addr  =   branch_hazard ? ireq.addr :
                        jal_hazard ? jal_target :
                        inst_is_br ? next_pc_pred :
                        pc;
assign memreq.wen   = 0;
assign memreq.wdata = ZBIT_32;

logic firstClk = 1;

always @(posedge clk) begin
    // 分岐予測に失敗
    if (branch_hazard) begin
        `ifdef PRINT_DEBUGINFO
        if (can_output_log)
            $display("info,fetchstage.event.branch_hazard,branch hazard");
        `endif
        pc                  <= ireq.addr;
        requested           <= 0;
        request_pc          <= ireq.addr;
        last_fetched_pc     <= 32'h0;
        last_fetched_inst   <= 32'h0;
    end else begin
        if (jal_hazard) begin
            `ifdef PRINT_DEBUGINFO
            if (can_output_log)
                $display("info,fetchstage.event.jal_detect,jal hazard");
            `endif
        end
        if (requested) begin
            // リクエストが完了した
            if (memresp.valid) begin
                `ifdef PRINT_DEBUGINFO
                if (can_output_log) begin
                    $display("info,fetchstage.event.fetch_end,fetch end");
                    $display("data,fetchstage.event.pc,h,%b", request_pc);
                    $display("data,fetchstage.event.inst,h,%b", memresp.rdata);
                end
                `endif

                last_fetched_pc   <= request_pc;
                last_fetched_inst <= memresp.rdata;

                // メモリがreadyかつmemreq.validならリクエストしてる
                if (memreq.ready & memreq.valid) begin
                    requested   <= 1;
                    request_pc  <= memreq.addr;
                    pc          <= next_pc;
                    inst_id     <= inst_id + 1;
                    `ifdef PRINT_DEBUGINFO
                    if (can_output_log)
                        $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                    `endif
                end else
                    requested   <= 0;
            end
        end else begin
            // メモリがreadyかつmemreq.validならリクエストしてる
            if (memreq.ready & memreq.valid) begin
                pc          <= next_pc;
                requested   <= 1;
                request_pc  <= memreq.addr;
                inst_id     <= inst_id + 1;
                `ifdef PRINT_DEBUGINFO
                if (can_output_log)
                    $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                `endif
            end
        end
    end
end

`ifdef PRINT_MEMPERF
int perf_counter = 0;
int clk_count = 0;
always @(posedge clk) begin
    perf_counter += {31'b0, requested & memresp.valid};
    if (clk_count % 10_000_000 == 0) begin
        $display("iperf : %d", perf_counter);
        perf_counter = 0;
    end
    clk_count += 1;
end
`endif

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (can_output_log) begin
    $display("data,fetchstage.pc,h,%b", pc);
    $display("data,fetchstage.next_pc,h,%b", next_pc);
    $display("data,fetchstage.requested_pc,h,%b", request_pc);
    $display("data,fetchstage.requesting_pc,h,%b", memreq.addr);
    $display("data,fetchstage.requested_pc,h,%b", request_pc);
    $display("data,fetchstage.error,d,%b", memresp.error);
    $display("data,fetchstage.errty,d,%b", memresp.errty);

    $display("data,fetchstage.ireq.valid,b,%b", ireq.valid);
    if (ireq.valid) begin
        $display("data,fetchstage.ireq.addr,h,%b", ireq.addr);
    end

    $display("data,fetchstage.iresp.valid,b,%b", iresp.valid);
    if (iresp.valid) begin
        $display("data,fetchstage.iresp.ready,b,%b", iresp.ready);
        $display("data,fetchstage.iresp.addr,h,%b", iresp.addr);
        $display("data,fetchstage.iresp.inst,h,%b", iresp.inst);
    end
    // $display("data,fetchstage.memreq.ready,b,%b", memreq.ready);
    // $display("data,fetchstage.memreq.valid,b,%b", memreq.valid);
    // $display("data,fetchstage.memreq.addr,h,%b", memreq.addr);
    // $display("data,fetchstage.memresp.valid,b,%b", memresp.valid);
    // $display("data,fetchstage.memresp.inst,h,%b", memresp.rdata);
    // $display("data,fetchstage.memresp.inst_is_br,b,%b", inst_is_br);
end
`endif

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (can_output_log) begin
    $display("data,btb.update.valid,b,%b", brinfo.valid);
    $display("data,btb.update.pc,h,%b", brinfo.pc);
    $display("data,btb.update.is_br,b,%b", brinfo.is_br);
    $display("data,btb.update.is_jmp,b,%b", brinfo.is_jmp);
    $display("data,btb.update.taken,b,%b", brinfo.taken);
    $display("data,btb.update.target,h,%b", brinfo.target);

    $display("data,btb.pred.inst,h,%b", fetched_inst);
    $display("data,btb.pred.when_pc_taken,h,%b", pred_taken_pc);
    $display("data,btb.pred.inst_is_jal,h,%b", inst_is_jal);
    $display("data,btb.pred.inst_is_jalr,h,%b", inst_is_jalr);
    $display("data,btb.pred.inst_is_br,h,%b", inst_is_br);

    $display("data,btb.pred.use_prediction,b,%b", !branch_hazard & !jal_hazard & inst_is_br);
    $display("data,btb.pred.pc,h,%b", pred_pc_base);
    $display("data,btb.pred.pred_pc,h,%b", next_pc_pred);
end
`endif

endmodule
