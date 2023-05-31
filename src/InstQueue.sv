module InstQueue #(
    parameter QUEUE_SIZE = 5'd16
) (
    input wire          clk,

    inout wire IRequest     ireq,
    inout wire IResponse    iresp,
    inout wire IRequest     memreq,
    inout wire IResponse    memresp
);

reg [3:0]   queue_head  = 0;
reg [3:0]   queue_tail  = 0;
reg [31:0]  pc_queue[QUEUE_SIZE-1:0];
reg [31:0]  inst_queue[QUEUE_SIZE-1:0];

reg [31:0]  pc          = 32'd0;
reg [63:0]  inst_id     = 64'd0;

reg         requested   = 0;
reg [31:0]  request_pc  = 32'd0;

wire [31:0] next_pc     = pc + 4; // ここで分岐予測したい
wire queue_is_full      = ireq.valid || //分岐ハザードなら空
                          queue_tail + 1 == queue_head; // キューがフル

assign memreq.valid     = !queue_is_full;
assign memreq.addr      = ireq.valid ? ireq.addr : pc;

assign iresp.valid      = queue_head != queue_tail;
assign iresp.addr       = pc_queue[queue_head];
assign iresp.inst       = inst_queue[queue_head];
assign iresp.inst_id    = inst_id;

always @(posedge clk) begin
    // ireq.valid -> 分岐予測に失敗
    if (ireq.valid) begin
        // pcにireq.addrを設定する。
        pc          <= ireq.addr;
        inst_id     <= inst_id + 1;
        queue_head  <= queue_tail; // キューのサイズを0にする

        // リクエスト状態を設定
        requested   <= memreq.ready;
        request_pc  <= ireq.addr;

        // TODO $display(予測失敗)
    end else begin
        if (requested) begin
            // リクエストが完了した
            if (memresp.valid && memresp.addr == request_pc) begin
                queue_tail              <= queue_tail + 1;
                pc_queue[queue_tail]    <= memresp.addr;
                inst_queue[queue_tail]  <= memresp.inst;
                `ifdef PRINT_DEBUGINFO
                $display("info,fetchstage.fetch_finish,Fetched : 0x%h -> 0x%h", request_pc, memresp.inst);
                `endif
                if (memreq.ready && memreq.valid) begin
                    requested           <= 1;
                    request_pc          <= pc;
                    pc                  <= next_pc;
                    `ifdef PRINT_DEBUGINFO
                    $display("info,fetchstage.fetch_requested,Request : 0x%h", pc);
                    `endif
                end else
                    requested           <= 0;
            end
        end else begin
            // メモリがreadyならリクエスト
            if (memreq.ready && memreq.valid) begin
                pc         <= next_pc;
                requested  <= 1;
                request_pc <= pc;
                `ifdef PRINT_DEBUGINFO
                $display("info,fetchstage.fetch_requested,Request : 0x%h", pc);
                `endif
            end
        end

        // if/idがキューから1つ命令を取得する
        if (iresp.valid && iresp.ready) begin
            queue_head  <= queue_head + 1;
            inst_id     <= inst_id + 1;
        end
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,fetchstage.ireq.valid,b,%b", ireq.valid);
    $display("data,fetchstage.iresp.valid,b,%b", iresp.valid);
    $display("data,fetchstage.iresp.ready,b,%b", iresp.ready);
    $display("data,fetchstage.requested,b,%b", requested);
    $display("data,fetchstage.request_pc,h,%b", request_pc);
    $display("data,fetchstage.memresp.valid,b,%b", memresp.valid);
    $display("data,fetchstage.memresp.addr,h,%b", memresp.addr);
    $display("data,fetchstage.queue_is_full,b,%b", queue_is_full);
    $display("data,fetchstage.queue_head,h,%b", queue_head);
    $display("data,fetchstage.queue_tail,h,%b", queue_tail);
end
`endif

endmodule
