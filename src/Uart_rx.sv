module Uart_rx
#(
    parameter FREQUENCY_MHz = 32'd27,
    parameter BAUDRATE = 32'd115200
)
(
    input  wire clk,

    input  wire         uart_rx,    // serial
    output logic [7:0]  rdata,      // rdata
    output wire         rvalid      // rdata is valid(1)
);

`ifdef FAST_UART
localparam [31:0] DELAY_FRAMES = 2;
`else
localparam [31:0] DELAY_FRAMES = (FREQUENCY_MHz * 1000000) / BAUDRATE;
`endif

localparam  HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    READ,
    STOP_BIT,
    DEBOUNCE
} statetype;

statetype   rxState     = IDLE;
int         rxCounter   = 0;
logic [2:0] rxBitNumber = 0;

logic [7:0] dataBuf     = 0;

wire rxPin = uart_rx;

assign rvalid = rxState == DEBOUNCE;

always @(posedge clk) begin
    case (rxState)
        IDLE: begin
            if (rxPin == 0) begin
                rxState     <= START_BIT;
                rxCounter   <= 0;
                rdata       <= 0;
            end
        end
        START_BIT: begin
            if ((rxCounter + 1) == HALF_DELAY_WAIT) begin
                rxState     <= READ;
                rxBitNumber <= 0;
                rxCounter   <= 0;
            end else
                rxCounter   <= rxCounter + 1;
        end
        READ: begin
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rdata[rxBitNumber] <= rxPin;
                if (rxBitNumber == 3'b111) begin
                    rxState <= STOP_BIT;
                end else begin
                    rxState     <= READ;
                    rxBitNumber <= rxBitNumber + 1;
                end
                rxCounter   <= 0;
            end else
                rxCounter   <= rxCounter + 1;
        end
        STOP_BIT: begin
            if ((rxCounter + 1) == DELAY_FRAMES & rxPin == 1) begin
                rxState     <= DEBOUNCE;
                rxCounter   <= 0;
            end else
                rxCounter   <= rxCounter + 1;
        end
        DEBOUNCE: begin
            rxState <= IDLE;
        end
        default: begin
            $display("Uart_rx.sv : Unknown state %d", rxState);
            `ffinish
        end
    endcase
end
endmodule