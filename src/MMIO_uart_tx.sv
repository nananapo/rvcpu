module MMIO_uart_tx #(
    parameter FMAX_MHz = 27
)(
    input  wire clk,
    output wire uart_tx,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UIntX   req_wdata,

    output wire         resp_valid,
    output wire UIntX   resp_rdata

`ifdef PRINT_DEBUGINFO
    ,
    input wire can_output_log
`endif
);

`include "basicparams.svh"

wire logic q_rready;
wire logic q_rvalid;
wire UInt8 q_rdata;

SyncQueue #(
    .DATA_SIZE($bits(UInt8)),
    .WIDTH(10)
) queue (
    .clk(clk),
    .kill(1'b0),
    .wready(req_ready),
    .wvalid(req_valid & req_wen),
    .wdata(req_wdata[7:0]),
    .rready(q_rready),
    .rvalid(q_rvalid),
    .rdata(q_rdata)
);

Uart_tx #(
    .FMAX_MHz(FMAX_MHz)
) txModule(
    .clk(clk),
    .uart_tx(uart_tx),
    .ready(q_rready),
    .start(q_rvalid),
    .data(q_rdata)
);

assign resp_valid   = 1;
assign resp_rdata   = DATA_Z;

int clock_count = 0;
always @(posedge clk) clock_count++;

always @(posedge clk) begin
    if (q_rready & q_rvalid) begin
        `ifdef PRINT_DEBUGINFO
            if (can_output_log) begin
                $display("info,memmapio.uart_tx.send,send : 0x%h (%d)", q_rdata, q_rdata);
            end
        `endif

        `ifdef PRINT_UART_CLOCK
            $write("%d : %c\n", clock_count, q_rdata);
            $fflush();
        `else
            $write("%c", q_rdata);
            $fflush();
        `endif
    end
end

endmodule