module Uart_tx
#(
    parameter FREQUENCY_MHz = 32'd27,
    parameter BAUDRATE = 32'd115200
)
(
    input  wire         clk,        // system clock
    output wire         uart_tx,    // serial
    output wire         ready,      // ready (1), busy (0)
    input  wire         start,      // set to 1 for start
    input  wire [7:0]   data        // byte to transmit
);

`ifdef FAST_UART
    assign ready = 1;
`else

localparam [31:0] DELAY_FRAMES = (FREQUENCY_MHz * 1000000) / BAUDRATE;

typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    WRITE,
    STOP_BIT,
    DEBOUNCE
} statetype;

statetype   txState     = IDLE;
int         txCounter   = 0;
logic [2:0] txBitNumber = 0;

logic [7:0] dataCopy    = 0;

logic txPin = 1;
assign uart_tx = txPin;

logic readyPin = 1;
assign ready = readyPin;

always @(posedge clk) begin
    case (txState)
        IDLE: begin
            if (start == 1) begin
                readyPin    <= 0;
                txState     <= START_BIT;
                txCounter   <= 0;
                dataCopy    <= data;
            end
        end
        START_BIT: begin
            txPin <= 0;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState     <= WRITE;
                txBitNumber <= 0;
                txCounter   <= 0;
            end else
                txCounter   <= txCounter + 1;
        end
        WRITE: begin
            txPin <= dataCopy[txBitNumber];
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txBitNumber == 3'b111) begin
                    txState <= STOP_BIT;
                end else begin
                    txState     <= WRITE;
                    txBitNumber <= txBitNumber + 1;
                end
                txCounter <= 0;
            end else
                txCounter <= txCounter + 1;
        end
        STOP_BIT: begin
            txPin <= 1;
            if ((txCounter + 1) == DELAY_FRAMES) begin
                txState     <= DEBOUNCE;
                txCounter   <= 0;
            end else
                txCounter <= txCounter + 1;
        end
        DEBOUNCE: begin
            txState     <= IDLE;
            readyPin    <= 1;
        end
        default: begin
            $display("Uart_tx.sv : Unknown state %d", txState);
            `ffinish
        end
    endcase
end
`endif

endmodule