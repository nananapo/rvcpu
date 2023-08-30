module MMIO_uart_rx #(
    parameter FMAX_MHz  = 27,
    parameter BUF_WIDTH = 10
)(
    input  wire clk,
    input  wire uart_rx,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UInt32  req_wdata,
    
    output wire     resp_valid,
    output UInt32   resp_rdata
);

localparam BUF_LEN = 2**BUF_WIDTH;
typedef logic [BUF_WIDTH-1:0] BufWidth;

// TODO キューのモジュールを使う

UInt8       buffer[BUF_LEN-1:0];
BufWidth    head = 0;
BufWidth    tail = 0;

// UART
wire UInt8  rx_rdata;
wire        rx_rvalid;

Uart_rx #(
    .FMAX_MHz(FMAX_MHz)
) rxModule(
    .clk(clk),
    .rdata(rx_rdata),
    .rvalid(rx_rvalid),
    .uart_rx(uart_rx)
);

assign req_ready    = 1;
assign resp_valid   = 1;

always @(posedge clk) begin
    if (rx_rvalid) begin
        buffer[tail] <= rx_rdata;
        tail <= tail + 1;
    end
    if (req_valid) begin
        if (head != tail) begin
            resp_rdata <= {24'b0, buffer[head]};
            head <= head + 1;
        end else begin
            resp_rdata <= 0;
        end
    end
end

endmodule