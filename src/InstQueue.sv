module InstQueue #(
    parameter QUEUE_SIZE = 5'd16
) (
    input wire          clk,

    inout wire IRequest     ireq,
    inout wire IResponse    iresp,
    inout wire IRequest     memreq,
    inout wire IResponse    memresp,

    input wire IUpdatePredictionIO updateio
);

reg [3:0]   queue_head  = 0;
reg [3:0]   queue_tail  = 0;
reg [31:0]  pc_queue[QUEUE_SIZE-1:0];
reg [31:0]  inst_queue[QUEUE_SIZE-1:0];
`ifdef PRINT_DEBUGINFO
reg [63:0]  inst_id_queue[QUEUE_SIZE-1:0];
`endif

reg [31:0]  pc          = 32'd0;
reg [63:0]  inst_id     = 64'd0;

reg         requested   = 0;
reg [31:0]  request_pc  = 32'd0;

wire branch_hazard      = ireq.valid &&
                          // フェッチをリクエスト済みなら、リクエスト済みのアドレスと比べて、同じかつキューのサイズが0なら分岐ハザードは起こさない(フェッチが遅いだけと判断する)
                          // キューのサイズが0ではない場合は必ず分岐ハザードと判定する。
                          (requested ? request_pc != ireq.addr || queue_head != queue_tail: 1);

wire [31:0] next_pc;

`ifdef EXCLUDE_PREDICTION_MODULE
// 分岐予測を行わない場合はpc + 4を予測とする
assign next_pc = pc + 4;
`else
TwoBitCounter #() tbc (
    .clk(clk),
    .pc(pc),
    .next_pc(next_pc),
    .updateio(updateio)
);
`endif

wire queue_is_full      = !branch_hazard && //分岐ハザードなら空
                          (
                            (queue_tail + 3'd1 == queue_head) || // キューが埋まっている
                            // circular logicを避けるために、memresp.validのときにさらに+1するのをなくして、
                            // +2にと常に比較するようにしている。サイズ一個の損だが許容)
                            (queue_tail + 3'd2 == queue_head)
                          );  
                          
assign memreq.valid     = !queue_is_full;
assign memreq.addr      = ireq.valid ? ireq.addr : pc;

assign iresp.valid      = (queue_head != queue_tail) ||
                          (requested && memresp.valid && memresp.addr == request_pc);
assign iresp.addr       = queue_head == queue_tail ? memresp.addr : pc_queue[queue_head];
assign iresp.inst       = queue_head == queue_tail ? memresp.inst : inst_queue[queue_head];
`ifdef PRINT_DEBUGINFO
assign iresp.inst_id    = queue_head == queue_tail ? inst_id - 64'd1 : inst_id_queue[queue_head];
`else
assign iresp.inst_id    = inst_id;
`endif

always @(posedge clk) begin
    // 分岐予測に失敗
    if (branch_hazard) begin
        `ifndef PRINT_DEBUGINFO
            inst_id     <= inst_id + 1;
        `endif
        queue_head  <= queue_tail; // キューのサイズを0にする

        `ifdef PRINT_DEBUGINFO
        $display("info,fetchstage.prediction_failed,branch hazard");
        `endif

        // メモリがreadyかつmemreq.validならリクエストしてる
        if (memreq.ready && memreq.valid) begin
            // TODO ここでも分岐予測をしたい
            // もしくは簡単のために分岐失敗時は1クロック消費して次のクロックでリクエストする
            pc          <= ireq.addr + 4;
            requested   <= 1;
            request_pc  <= ireq.addr;
            `ifdef PRINT_DEBUGINFO
                inst_id <= inst_id + 1;
                $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
            `endif
        end else begin
            pc          <= ireq.addr;
            requested   <= 0;
        end
        // TODO $display(予測失敗)
    end else begin
        if (requested) begin
            // リクエストが完了した
            if (memresp.valid && memresp.addr == request_pc) begin
                queue_tail              <= queue_tail + 1;
                pc_queue[queue_tail]    <= memresp.addr;
                inst_queue[queue_tail]  <= memresp.inst;

                `ifdef PRINT_DEBUGINFO
                    inst_id_queue[queue_tail]  <= inst_id - 64'd1;
                    $display("info,fetchstage.event.fetch_end,fetch end");
                    $display("data,fetchstage.event.pc,h,%b", memresp.addr);
                    $display("data,fetchstage.event.inst,h,%b", memresp.inst);
                `endif

                // メモリがreadyかつmemreq.validならリクエストしてる
                if (memreq.ready && memreq.valid) begin
                    requested           <= 1;
                    request_pc          <= pc;
                    pc                  <= next_pc;

                    `ifdef PRINT_DEBUGINFO
                        inst_id <= inst_id + 1;
                        $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                    `endif
                end else
                    requested           <= 0;
            end
        end else begin
            // メモリがreadyかつmemreq.validならリクエストしてる
            if (memreq.ready && memreq.valid) begin
                pc         <= next_pc;
                requested  <= 1;
                request_pc <= pc;
                `ifdef PRINT_DEBUGINFO
                    inst_id <= inst_id + 1;
                    $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                `endif
            end
        end

        // if/idがキューから1つ命令を取得する
        if (iresp.valid && iresp.ready) begin
            queue_head  <= queue_head + 1;
            `ifndef PRINT_DEBUGINFO
                // PRINT_DEBUGINFOではないなら受け取るときにinst_idをインクリメントする。
                // PRINT_DEBUGINFOなら、フェッチするときにインクリメントする。そして格納するときは1引いた値を入れる
                inst_id     <= inst_id + 1;
            `endif
        end
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,fetchstage.pc,h,%b", pc);
    $display("data,fetchstage.next_pc,h,%b", next_pc);
    $display("data,fetchstage.branch_hazard,b,%b", branch_hazard);
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
    $display("data,fetchstage.queue_is_full,b,%b", queue_is_full);
    // $display("data,fetchstage.queue_head,h,%b", queue_head);
    // $display("data,fetchstage.queue_tail,h,%b", queue_tail);
end
`endif

endmodule
