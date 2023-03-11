module MemoryMappedIO_Uart_tx
(
    input  wire         clk,
    output wire         uart_tx,

    input wire [31:0]   buffer[63:0],
    input wire [31:0]   input_queue_tail,
    output wire[31:0]   output_queue_head
);

reg         tx_start    = 0;
reg [7:0]   tx_data     = 0;
wire        tx_ready;

Uart_tx #() txModule(
    .clk(clk),

    .start(tx_start),
    .data(tx_data),
    .ready(tx_ready),
    .uart_tx(uart_tx)
);

wire [7:0] queue_tail       = input_queue_tail[7:0];
reg  [7:0] queue_head       = 0;

assign output_queue_head    = {24'b0, queue_head};

// アドレスは4byteずつ
wire [5:0] addr     = queue_head[7:2]; // queue_head >> 2
wire [1:0] addr_mod = queue_head[1:0]; // queue_head % 4

// 状態
localparam STATE_IDLE       = 0;
localparam STATE_WAIT_READY = 1;

reg state = STATE_IDLE;

// バッファから読んだデータ
reg [31:0] rdata = 0;

always @(posedge clk) begin
    //$display("queue: %d -> %d", queue_head, queue_tail);
    case (state)
        STATE_IDLE: begin
            tx_start    <= 0;
            if (queue_tail != queue_head) begin
                state   <= STATE_WAIT_READY;
                rdata   <= buffer[addr];
            end
        end
        STATE_WAIT_READY: begin
            if (tx_ready) begin
                tx_start    <= 1;
                //$display("uart_tx : 0x%h : %d", rdata, addr_mod);
                case (addr_mod)
                    0: tx_data  <= rdata[7:0];
                    1: tx_data  <= rdata[15:8];
                    2: tx_data  <= rdata[23:16];
                    3: tx_data  <= rdata[31:24];
                endcase
                queue_head  <= queue_head + 1;
                state <= STATE_IDLE;
            end
        end
    endcase
end

endmodule