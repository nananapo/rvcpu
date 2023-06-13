// 書き込んだクロックで取り出せる同期キュー
// circular logicにならないように注意する必要がある
// QUEUE_SIZEは2の冪にしてね
module FastQueue #(
    parameter DATA_SIZE = 32,
    parameter QUEUE_SIZE = 32
)(
    input wire clk,
    input wire kill,

    output wire wready,
    input wire wvalid,
    input wire [DATA_SIZE-1:0] wdata,

    input wire rready,
    output wire rvalid,
    output wire [DATA_SIZE-1:0] rdata
);

localparam QUEUE_WIDTH = $clog2(QUEUE_SIZE);

reg [DATA_SIZE-1:0] queue[QUEUE_WIDTH-1:0];
reg [QUEUE_WIDTH-1:0] head = 0;
reg [QUEUE_WIDTH-1:0] tail = 0;

assign wready   = tail + {{QUEUE_WIDTH-1{1'd0}}, 1'd1} != head;

wire in_stock   = head != tail;

assign rvalid   = in_stock || wvalid;
assign rdata    = in_stock ? queue[head] : wdata;

always @(posedge clk) begin
    if (kill)
        head <= tail;
    else begin
        if (wready && wvalid) begin
            // wdata -> rdataとなる場合を除く
            if (!(!in_stock && rready)) begin
                tail <= tail + 1;
                queue[tail] <= wdata;
            end
        end
        // stockから消費する場合にインクリメントする
        if (rready && rvalid && in_stock) begin
            head <= head + 1;
        end
    end
end

endmodule