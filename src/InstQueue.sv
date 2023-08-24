
module InstQueue #(
    parameter QUEUE_SIZE = 16
) (
    input wire          clk,

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
// TODO さらにレジスタをはさんでjal_hazardを消したい
assign buf_wvalid       = !jal_hazard && requested && memresp.valid;
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

logic [31:0]  pc    = 32'd0;
IId     inst_id     = IID_ZERO;

logic         requested   = 0;
logic [31:0]  request_pc  = 32'd0;

wire branch_hazard  = ireq.valid;

wire [31:0] next_pc;

// TODO この処理を適切な場所に移動したい。
logic [31:0] last_fetched_pc     = 32'hffffffff;
logic [31:0] last_fetched_inst   = 32'hffffffff;

wire [19:0] last_imm_j          = {
                                    last_fetched_inst[31],
                                    last_fetched_inst[19:12],
                                    last_fetched_inst[20],
                                    last_fetched_inst[30:21]
                                  };
wire [31:0] last_imm_j_sext     = {{11{last_imm_j[19]}}, last_imm_j, 1'b0};

wire [6:0]  last_inst_opcode    = last_fetched_inst[6:0];
wire [2:0]  last_inst_funct3    = last_fetched_inst[14:12];

wire        last_inst_is_jal    = last_inst_opcode == JAL_OP;
wire [31:0] last_jal_target     = last_fetched_pc + last_imm_j_sext;

wire        last_inst_is_jalr_or_br = (
    (last_inst_opcode == JALR_OP && last_inst_funct3 == JALR_F3) || 
    last_inst_opcode == BR_OP
);

wire jal_hazard = last_inst_is_jal && requested && request_pc != last_jal_target;
// TODO ここまで




// 分岐予測
wire [31:0] next_pc_pred;
wire [31:0] pred_pc_base =  branch_hazard ? ireq.addr : 
                            jal_hazard ? last_jal_target :
                            pc;

`ifdef PRED_TBC
    TwoBitCounter #(
        .ADDR_WIDTH(10)
    ) bp (
        .clk(clk),
        .pc(pred_pc_base),
        .next_pc(next_pc_pred),
        .updateio(updateio)
    );
    initial $display("branch pred : two bit counter");
`elsif PRED_LOCAL
    LocalHistory2bit #() bp (
        .clk(clk),
        .pc(pred_pc_base),
        .next_pc(next_pc_pred),
        .updateio(updateio)
    );
    initial $display("branch pred : local history");
`elsif PRED_GLOBAL
    GlobalHistory2bit #() bp (
        .clk(clk),
        .pc(pred_pc_base),
        .next_pc(next_pc_pred),
        .updateio(updateio)
    );
    initial $display("branch pred : global history");
`else
    assign next_pc_pred = pred_pc_base + 4; 
    initial $display("no branch prediction module is selected");
`endif

`ifdef DEBUG
    wire [31:0] __next_pc = last_inst_is_jal && !last_inst_is_jalr_or_br ? last_jal_target + 4 : next_pc_pred;
    assign next_pc = __next_pc === 32'hxxxxxxxx ? 32'h0 : __next_pc;
`else
    assign next_pc = last_inst_is_jal && !last_inst_is_jalr_or_br ? last_jal_target + 4 : next_pc_pred;
`endif







assign memreq.valid = buf_wready_next;
assign memreq.addr  = pc;

always @(posedge clk) begin
    // 分岐予測に失敗
    if (branch_hazard) begin
        `ifdef PRINT_DEBUGINFO
            $display("info,fetchstage.event.branch_hazard,branch hazard");
        `endif
        pc          <= ireq.addr;
        requested   <= 0;

        last_fetched_pc     <= 32'hffffffff;
        last_fetched_inst   <= 32'hffffffff;
    // jalの先読み失敗
    end else if (jal_hazard) begin
        requested   <= 0;
        pc          <= last_jal_target;

        `ifdef PRINT_DEBUGINFO
            $display("info,fetchstage.event.jal_detect,jal hazard");
        `endif

        last_fetched_pc     <= 32'hffffffff;
        last_fetched_inst   <= 32'hffffffff;
    end else begin
        if (requested) begin
            // リクエストが完了した
            if (memresp.valid && memresp.addr == request_pc) begin
                last_fetched_pc         <= memresp.addr;
                last_fetched_inst       <= memresp.inst;

                `ifdef PRINT_DEBUGINFO
                    $display("info,fetchstage.event.fetch_end,fetch end");
                    $display("data,fetchstage.event.pc,h,%b", memresp.addr);
                    $display("data,fetchstage.event.inst,h,%b", memresp.inst);
                `endif

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
                    requested           <= 0;
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
    $display("data,fetchstage.requested,b,%b", requested);
    $display("data,fetchstage.request_pc,h,%b", request_pc);
end
`endif

`ifdef PRINT_DEBUGINFO

reg  [31:0] last_pc_pred_req;
always @(posedge clk) begin
    last_pc_pred_req <= pc;
end

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

    $display("data,btb.pred.use_prediction,b,%b", last_inst_is_jalr_or_br);
    $display("data,btb.pred.pc,h,%b", pred_pc_base);
    $display("data,btb.pred.pred_pc,h,%b", next_pc_pred);
end
`endif

endmodule
