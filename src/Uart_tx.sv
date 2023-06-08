module Uart_tx
#(
    parameter FMAX_MHz = 32'd27,
    parameter BaudRate = 32'd115200
)
(
    input  wire         clk,        // system clock
    input  wire         start,      // set to 1 for start
    input  wire [7:0]   data,       // byte to transmit
    
    output wire         uart_tx,    // serial
    output wire         ready       // ready (1), busy (0)
);

`ifdef FAST_UART
    assign ready = 1;
`else

localparam [31:0] DELAY_FRAMES = (FMAX_MHz * 1000000) / BaudRate;

reg [3:0]   txState     = 0;
reg [31:0]  txCounter   = 0;
reg [2:0]   txBitNumber = 0;

reg [7:0]   dataCopy    = 0;

reg txPin = 1;
assign uart_tx = txPin;

reg readyPin = 1;
assign ready = readyPin;

localparam TX_STATE_IDLE        = 0;
localparam TX_STATE_START_BIT   = 1;
localparam TX_STATE_WRITE       = 2;
localparam TX_STATE_STOP_BIT    = 3;
localparam TX_STATE_DEBOUNCE    = 4;

always @(posedge clk) begin
    case (txState)
        TX_STATE_IDLE: begin
            if (start == 1) begin
                readyPin    <= 0;
                txState     <= TX_STATE_START_BIT;
                txCounter   <= 0;
                dataCopy    <= data;
            end
        end
        TX_STATE_START_BIT: begin
            txPin <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState     <= TX_STATE_WRITE;
                txBitNumber <= 0;
                txCounter   <= 0;
            end else 
                txCounter   <= txCounter + 1;
        end
        TX_STATE_WRITE: begin
            txPin <= dataCopy[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= TX_STATE_STOP_BIT;
                end else begin
                    txState     <= TX_STATE_WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_STOP_BIT: begin
            txPin <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState     <= TX_STATE_DEBOUNCE;
                txCounter   <= 0;
            end else 
                txCounter <= txCounter + 1;
        end
        TX_STATE_DEBOUNCE: begin
            txState     <= TX_STATE_IDLE;
            readyPin    <= 1;
        end
    endcase
end
`endif

endmodule