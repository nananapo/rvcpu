// 書き込んだら次のクロックで取り出せる同期キュー
// QUEUE_SIZEは2の冪にしてね
module SyncQueue #(
    parameter DATA_SIZE = 32,
    parameter QUEUE_SIZE = 32
)(
    input wire clk,
    input wire kill,

    output wire wready,
    input wire  wvalid,
    input wire [DATA_SIZE-1:0] wdata,

    input wire  rready,
    output wire rvalid,
    output wire [DATA_SIZE-1:0] rdata
);

localparam QUEUE_WIDTH = $clog2(QUEUE_SIZE);

logic [DATA_SIZE-1:0] queue[QUEUE_SIZE-1:0];
logic [QUEUE_WIDTH-1:0] head = 0;
logic [QUEUE_WIDTH-1:0] tail = 0;

wire inner_wready = tail + {{QUEUE_WIDTH-1{1'd0}}, 1'd1} != head;
assign wready   = inner_wready && tail + {{QUEUE_WIDTH-2{1'd0}}, 2'b10} != head;
assign rvalid   = head != tail;
assign rdata    = queue[head];

always @(posedge clk) begin
    if (kill)
        head <= tail;
    else begin
        if (inner_wready && wvalid) begin
            tail <= tail + 1;
            queue[tail] <= wdata;
        end
        if (rready && rvalid)
            head <= head + 1;
    end
end

/*
always @(posedge clk) begin
    $display("data,fetchstage.queue.head,d,%b", head);
    $display("data,fetchstage.queue.tail,d,%b", tail);
    $display("data,fetchstage.queue.inner_wready,d,%b", inner_wready);
    $display("data,fetchstage.queue.wvalid,d,%b", wvalid);
    $display("data,fetchstage.queue.wdata,h,%b", wdata);
    $display("data,fetchstage.queue.rready,d,%b", rready);
    $display("data,fetchstage.queue.rvalid,d,%b", rvalid);
    $display("data,fetchstage.queue.rdata,h,%b", rdata);
end
*/

endmodule