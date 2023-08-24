module Uart_rx
#(
    parameter FMAX_MHz = 32'd27,
    parameter BaudRate = 32'd115200
)
(
    input  wire clk,        // system clock

    input  wire         uart_rx,    // serial
    output logic [7:0]  rdata,// rdata
    output wire         rdata_valid // rdata is valid(1)
);

`ifdef FAST_UART
localparam [31:0] DELAY_FRAMES = 2;
`else
localparam [31:0] DELAY_FRAMES = (FMAX_MHz * 1000000) / BaudRate;
`endif

localparam  HALF_DELAY_WAIT = (DELAY_FRAMES / 2);

localparam RX_STATE_IDLE        = 0;
localparam RX_STATE_START_BIT   = 1;
localparam RX_STATE_READ        = 2;
localparam RX_STATE_STOP_BIT    = 3;
localparam RX_STATE_DEBOUNCE    = 4;

logic [3:0]   rxState     = RX_STATE_IDLE;
logic [31:0]  rxCounter   = 0;
logic [2:0]   rxBitNumber = 0;

logic [7:0]   dataBuf     = 0;

wire rxPin = uart_rx;

assign rdata_valid = rxState == RX_STATE_DEBOUNCE;

always @(posedge clk) begin
    case (rxState)
        RX_STATE_IDLE: begin
            if (rxPin == 0) begin
                rxState     <= RX_STATE_START_BIT;
                rxCounter   <= 0;
                rdata       <= 0;
            end
        end
        RX_STATE_START_BIT: begin
            if ((rxCounter + 1) == HALF_DELAY_WAIT) begin
                rxState     <= RX_STATE_READ;
                rxBitNumber <= 0;
                rxCounter   <= 0;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_READ: begin
            if ((rxCounter + 1) == DELAY_FRAMES) begin
                rdata[rxBitNumber] <= rxPin;
                if (rxBitNumber == 3'b111) begin
                    rxState <= RX_STATE_STOP_BIT;
                end else begin
                    rxState     <= RX_STATE_READ;
                    rxBitNumber <= rxBitNumber + 1;
                end
                rxCounter <= 0;
            end else 
                rxCounter <= rxCounter + 1;
        end
        RX_STATE_STOP_BIT: begin
            if ((rxCounter + 1) == DELAY_FRAMES && rxPin == 1) begin
                rxState     <= RX_STATE_DEBOUNCE;
                rxCounter   <= 0;
            end else 
                rxCounter   <= rxCounter + 1;
        end
        RX_STATE_DEBOUNCE: begin
            rxState     <= RX_STATE_IDLE;
        end
    endcase
end
endmodule