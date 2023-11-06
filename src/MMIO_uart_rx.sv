module MMIO_uart_rx
    import basic::*;
#(
    parameter BUF_WIDTH = 10
)(
    input  wire clk,
    input  wire uart_rx,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UIntX   req_wdata,

    output logic        resp_valid,
    output UInt32       resp_rdata,

    // interrupt用
    // いずれ外にPLICを作りたい
    output wire         uart_rx_pending
);

import conf::*;

wire UInt8  rx_rdata;
wire        rx_rvalid;

Uart_rx #(
    .FREQUENCY_MHz(conf::FREQUENCY_MHz),
    .BAUDRATE(conf::UART_BAUDRATE)
) rxModule(
    .clk(clk),
    .rdata(rx_rdata),
    .rvalid(rx_rvalid),
    .uart_rx(uart_rx)
);

wire logic q_wready; // 無視
wire logic q_rready;
wire logic q_rvalid;
wire UInt8 q_rdata;

SyncQueue #(
    .DATA_SIZE($bits(UInt8)),
    .WIDTH(10)
) queue (
    .clk(clk),
    .kill(1'b0),
    .wready(q_wready),
    .wvalid(rx_rvalid),
    .wdata(rx_rdata),
    .rready(q_rready),
    .rvalid(q_rvalid),
    .rdata(q_rdata)
);

assign  req_ready   = 1;
initial resp_valid  = 0;

assign  q_rready = req_valid && req_addr == MemMap::UART_RX_VALUE;

assign  uart_rx_pending = q_rvalid;

always @(posedge clk) begin
    resp_valid <= req_valid;
    if (req_valid) begin
        case (req_addr)
        MemMap::UART_RX_EXISTS: resp_rdata <= {{XLEN-1{1'b0}}, q_rvalid};
        MemMap::UART_RX_VALUE:  resp_rdata <= {{XLEN-8{1'b0}}, q_rdata};
        endcase
    end
end

endmodule