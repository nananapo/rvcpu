// 書き込んだら次のクロックで取り出せる同期キュー
// キューのサイズは2 ** WIDTH - 1になる
module SyncQueue #(
    parameter DATA_SIZE = 32,
    parameter WIDTH = 5,
    parameter WREADY_NEXT = 0,
    parameter LOG = 0
)(
    input wire clk,
    input wire kill,

    output wire wready,
    input wire  wvalid,
    input wire [DATA_SIZE-1:0] wdata,

    input wire  rready,
    output wire rvalid,
    output wire [DATA_SIZE-1:0] rdata
); generate

if (WIDTH == 0) begin

    logic [DATA_SIZE-1:0] data = 0;
    logic is_empty = 1;

    assign wready = WREADY_NEXT ? 0 : is_empty;
    assign rvalid = !is_empty;
    assign rdata  = data;

    always @(posedge clk) begin
        if (is_empty & wvalid) begin
            is_empty    <= 0;
            data        <= wdata;
        end
        if (!is_empty & rready) begin
            is_empty    <= 1;
        end
    end

end else begin
    localparam QUEUE_SIZE = 2 ** WIDTH;

    logic [DATA_SIZE-1:0] queue[QUEUE_SIZE-1:0];
    logic [WIDTH-1:0] head = 0;
    logic [WIDTH-1:0] tail = 0;

    wire p_max  = tail + {{WIDTH-1{1'b0}}, 1'b1 } == head;
    wire p_max2 = tail + {{WIDTH-2{1'b0}}, 2'b10} == head;

    wire actual_wready = !p_max;

    assign wready   = WREADY_NEXT ? actual_wready & !p_max2 : actual_wready;
    assign rvalid   = head != tail;
    assign rdata    = queue[head];

    always @(posedge clk) begin
        if (kill)
            head <= tail;
        else begin
            if (actual_wready & wvalid) begin
                tail        <= tail + 1;
                queue[tail] <= wdata;
            end
            if (rready & rvalid)
                head <= head + 1;
        end
    end
    // if (LOG) always @(posedge clk) begin
    //     $display("data,fetchstage.queue.head,d,%b", head);
    //     $display("data,fetchstage.queue.tail,d,%b", tail);
    //     $display("data,fetchstage.queue.wready,d,%b", wready);
    //     $display("data,fetchstage.queue.actual_wready,d,%b", actual_wready);
    //     $display("data,fetchstage.queue.rvalid,d,%b", rvalid);
    // end
end

endgenerate endmodule