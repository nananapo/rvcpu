module MMIO_uart_tx #(
    parameter FMAX_MHz = 27
)(
    input  wire clk,
    output wire uart_tx,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UInt32  req_wdata,
    
    output wire         resp_valid,
    output wire UInt32  resp_rdata
);

`include "include/memorymap.sv"

typedef enum logic {
    IDLE,
    WAIT_READY
} statetype;
statetype state = IDLE;

assign req_ready    = state == IDLE;
assign resp_valid   = 1;
assign resp_rdata   = 32'h0;

logic   tx_start = 0;
UInt8   tx_data = 0;
wire    tx_ready;

Uart_tx #(
    .FMAX_MHz(FMAX_MHz)
) txModule(
    .clk(clk),
    .start(tx_start),
    .data(tx_data),
    .ready(tx_ready),
    .uart_tx(uart_tx)
);

always @(posedge clk) begin
    case (state)
        IDLE: begin
            tx_start<= 0;
            if (req_valid) begin
                state   <= WAIT_READY;
                tx_data <= req_wdata[7:0];
            end
        end
        WAIT_READY: begin
            if (tx_ready) begin
                state   <= IDLE;
                tx_start<= 1;
                `ifndef PRINT_DEBUGINFO
                    $write("%c", tx_data[7:0]);
                    $fflush();
                `endif
            end
        end
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    if (state == WAIT_READY && tx_ready) begin
        $display("info,memmapio.uart_tx.send,send : 0x%h (%d)", tx_data, tx_data);
    end
end
`endif

endmodule