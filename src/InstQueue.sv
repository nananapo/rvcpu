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

reg [31:0]  request_pc  = 32'd0;

assign memreq.valid    = ireq.valid || // 分岐ハザードなら強制的にvalid
                            (queue_tail + 1) % QUEUE_SIZE == queue_head; // キューがフルではないならとりあえずvalid
assign memreq.addr     = ireq.valid ? ireq.addr : pc;

assign iresp.valid      = queue_head != queue_tail;
assign iresp.addr       = pc_queue[queue_head];
assign iresp.inst       = inst_queue[queue_head];
assign iresp.inst_id    = inst_id;

always @(posedge clk) begin
    if (ireq.valid) begin
        // ireq.valid -> 分岐予測に失敗
        // キューのサイズを0にして、pcにireq.addrを設定する。
        pc          <= ireq.addr;
        queue_head  <= queue_tail;
        inst_id     <= inst_id + 1;
    end else begin
        // リクエストが完了した
        if (memresp.valid && memresp.addr == request_pc) begin
            // キューが
            if (queue_head == queue_tail) begin

            end
        end
    end
end

endmodule