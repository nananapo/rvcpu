module MemoryMappedIO_Uart_tx
(
    input  wire         clk,
    output wire         uart_tx,

    input wire [7:0]    buffer[255:0],
    input wire [7:0]    queue_tail,
    output reg [7:0]    queue_head
);

wire        tx_start;
wire [7:0]  tx_data;
wire        tx_ready;

initial begin
    queue_head = 0;
end

Uart_tx #() txModule(
    .clk(clk),

    .start(tx_start),
    .data(tx_data),
    .ready(tx_ready),
    .uart_tx(uart_tx)
);

assign tx_start = queue_tail != queue_head && tx_ready;
assign tx_data  = buffer[queue_head];

always @(posedge clk) begin
    if (tx_start) begin
        queue_head <= queue_head + 1;
    end
end

endmodule