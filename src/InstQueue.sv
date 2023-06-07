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

wire branch_hazard_and_failreq  = ireq.valid &&
                          // フェッチをリクエスト済みなら、リクエスト済みのアドレスと比べて、同じかつキューのサイズが0なら分岐ハザードは起こさない(フェッチが遅いだけと判断する)
                          // キューのサイズが0ではない場合は必ず分岐ハザードと判定する。
                          (requested ? request_pc != ireq.addr || queue_head != queue_tail : 1);

wire [31:0] next_pc;

// TODO この処理を適切な場所に移動したい。
reg [31:0] last_fetched_pc     = 32'hffffffff;
reg [31:0] last_fetched_inst   = 32'hffffffff;

wire [19:0] last_imm_j          = {
                                    last_fetched_inst[31],
                                    last_fetched_inst[19:12],
                                    last_fetched_inst[20],
                                    last_fetched_inst[30:21]
                                  };
wire [31:0] last_imm_j_sext     = {{11{last_imm_j[19]}}, last_imm_j, 1'b0};

wire [6:0]  last_inst_opcode    = last_fetched_inst[6:0];

wire        last_inst_is_jal    = last_inst_opcode == INST_JAL_OPCODE;
wire [31:0] last_jal_target     = last_fetched_pc + last_imm_j_sext;

wire jal_hazard = last_inst_is_jal && requested && request_pc != last_jal_target;
// TODO ここまで

`ifdef EXCLUDE_PREDICTION_MODULE
// 分岐予測を行わない場合はpc + 4を予測とする
assign next_pc = last_inst_is_jal ? last_jal_target + 4 : pc + 4;
`else

`include "include/inst.sv"

wire [31:0] next_pc_tbc;
TwoBitCounter #() tbc (
    .clk(clk),
    .pc(pc),
    .next_pc(next_pc_tbc),
    .updateio(updateio)
);

assign next_pc = last_inst_is_jal ? last_jal_target + 4 : next_pc_tbc;
`endif

// 2023/06/05
// ireqが直接memreqにつながらないようにすることにした。
// つながると、最長のパスがこれになる。(分岐判定の計算をしたうえで、そのアドレスがメモリにつながることになる。これは長すぎる)
// よって、サイクル数を(1か2ほど)食うことになるが、最高周波数を優先する。
wire queue_is_full      = (queue_tail + 3'd1 == queue_head) || // キューが埋まっている
                          // circular logicを避けるために、memresp.validのときにさらに+1するのをなくして、
                          // +2にと常に比較するようにしている。サイズ一個の損だが許容)
                          // TODO よく考えたらこれはいらない(ほかの書き方がある気がする)
                          (queue_tail + 3'd2 == queue_head);
wire queue_is_empty     = queue_head == queue_tail;
                          
assign memreq.valid     = !queue_is_full;
assign memreq.addr      = last_inst_is_jal ? last_jal_target : pc;

assign iresp.valid      = !jal_hazard && (
                          (queue_head != queue_tail) ||
                          (requested && memresp.valid && memresp.addr == request_pc)
                          );
assign iresp.addr       = queue_is_empty ? memresp.addr : pc_queue[queue_head];
assign iresp.inst       = queue_is_empty ? memresp.inst : inst_queue[queue_head];
`ifdef PRINT_DEBUGINFO
assign iresp.inst_id    = queue_is_empty ? inst_id - 64'd1 : inst_id_queue[queue_head];
`else
assign iresp.inst_id    = inst_id;
`endif

always @(posedge clk) begin
    // 分岐予測に失敗
    if (branch_hazard_and_failreq) begin
        `ifndef PRINT_DEBUGINFO
            inst_id     <= inst_id + 1;
        `endif
        `ifdef PRINT_DEBUGINFO
            $display("info,fetchstage.event.branch_hazard,branch hazard");
        `endif
        queue_head  <= queue_tail;
        pc          <= ireq.addr;
        requested   <= 0;

        // リクエストするなら、リクエストを繰り返さないようにlast_*を更新する。
        last_fetched_pc     <= 32'hffffffff;
        last_fetched_inst   <= 32'hffffffff;
    // jalの先読み失敗
    end else if (jal_hazard) begin
        requested   <= 0;
        // メモリがreadyかつmemreq.validならリクエストしてる
        if (memreq.ready && memreq.valid) begin
            pc         <= next_pc;
            requested  <= 1;
            request_pc <= memreq.addr;
            `ifdef PRINT_DEBUGINFO
                inst_id <= inst_id + 1;
                $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
            `endif

            // リクエストするなら、リクエストを繰り返さないようにlast_*を更新する。
            last_fetched_pc     <= 32'hffffffff;
            last_fetched_inst   <= 32'hffffffff;
        end
    end else begin
        if (requested) begin
            // リクエストが完了した
            if (memresp.valid && memresp.addr == request_pc) begin
                queue_tail              <= queue_tail + 1;
                pc_queue[queue_tail]    <= memresp.addr;
                inst_queue[queue_tail]  <= memresp.inst;

                last_fetched_pc         <= memresp.addr;
                last_fetched_inst       <= memresp.inst;

                `ifdef PRINT_DEBUGINFO
                    inst_id_queue[queue_tail]  <= inst_id - 64'd1;
                    $display("info,fetchstage.event.fetch_end,fetch end");
                    $display("data,fetchstage.event.pc,h,%b", memresp.addr);
                    $display("data,fetchstage.event.inst,h,%b", memresp.inst);
                `endif

                // メモリがreadyかつmemreq.validならリクエストしてる
                if (memreq.ready && memreq.valid) begin
                    requested           <= 1;
                    request_pc          <= memreq.addr;
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
                request_pc <= memreq.addr;
                `ifdef PRINT_DEBUGINFO
                    inst_id <= inst_id + 1;
                    $display("data,fetchstage.event.fetch_start,d,%b", inst_id);
                `endif
            end
        end

        // if/idがキューから1つ命令を取得する
        if (iresp.valid && iresp.ready) begin
            // 分岐ならheadをtailにする
            if (ireq.valid)
                queue_head  <= queue_tail;
            else
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
    $display("data,fetchstage.branch_hazard_and_failreq,b,%b", branch_hazard_and_failreq);
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
