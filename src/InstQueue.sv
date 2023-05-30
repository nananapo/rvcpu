module InstIssuer #(
    parameter QUEUE_SIZE = 16
) (
    input wire          clk,

    input IRequest      ireq,
    output IResponse    iresp,
    output IRequest     memreq,
    input IResponse     memresp
);

reg [4:0]   queue_head  = 0;
reg [4:0]   queue_tail  = 0;
reg [31:0]  pc_queue[QUEUE_SIZE-1:0];
reg [31:0]  inst_queue[QUEUE_SIZE-1:0];

reg [31:0]  pc          = 32'd0;
reg [63:0]  inst_id     = 64'd0;

reg         requested   = 0;
reg [31:0]  request_pc  = 32'd0;

wire [31:0] next_pc     = pc;
wire queue_is_full      = ireq.valid || //分岐ハザードなら空
                          (queue_tail + 1) % QUEUE_SIZE == queue_head; // キューがフル

assign memreq.valid     = !queue_is_full;
assign memreq.addr      = ireq.valid ? ireq.addr : pc;

assign iresp.valid      = queue_head != queue_tail && !ireq.valid;
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
                pc                      <= next_pc;
                queue_tail              <= (queue_tail + 1) % QUEUE_SIZE;
                pc_queue[queue_tail]    <= memresp.addr;
                inst_queue[queue_tail]  <= memresp.inst;
                // TODO $display(inst_id)
            end
        end else begin
            // メモリがreadyならリクエスト
            if (memreq.ready) begin
                pc         <= next_pc;
                requested  <= 1;
                request_pc <= pc;
            end
        end
        // if/idがキューから1つ命令を取得する
        if (iresp.ready) begin
            queue_head  <= queue_head + 1;
            inst_id     <= inst_id + 1;
        end
    end
end

endmodule
