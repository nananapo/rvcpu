module sendboard(
    input wire sys_clk,         // system clock
    input wire start,           // Set to 1 for send board
    input wire [8:0] maru,      // maru (3x3)
    input wire [8:0] batu,      // batu (3x3)
    output wire uart_tx,        // uart tx
    output wire ready           // ready(1), busy(0)
);

// state
localparam STATE_IDLE = 0;
localparam STATE_INIT_BOARD = 1;
localparam STATE_INIT_STR = 2;
localparam STATE_SUBMIT = 3;
localparam STATE_END = 4;
reg [3:0] state = 0;

// ready
reg readyPin = 1;
assign ready = readyPin;

// board
localparam BOARD_SIZE = 9;
reg [7:0] boardStr [BOARD_SIZE:0];
reg [31:0] index;

// str
localparam STR_COUNT = 12;
reg [7:0] sendStr [STR_COUNT:0];

//clockCount
reg [31:0] clockCount;
localparam CLOCK_WAIT = 20;


// UART
reg uart_start = 0;
reg [7:0] uart_data;
wire uart_ready;
uart_tx #() sender (
    .sys_clk(sys_clk),
    .start(uart_start),
    .data(uart_data),
    .uart_tx(uart_tx),
    .ready(uart_ready)
);


always @(posedge sys_clk) begin
    case(state)
        STATE_IDLE: begin
            if (start == 1) begin
                index <= 0;
                readyPin <= 0;
                state <= STATE_INIT_BOARD;
            end
        end
        STATE_INIT_BOARD: begin
            if (index == BOARD_SIZE + 1) begin
                index <= 0;
                state <= STATE_INIT_STR;
            end else begin
                if ((maru >> index) == 1) begin
                    boardStr[index] <= "o";
                end else if ((batu >> index) == 1) begin
                    boardStr[index] <= "x";
                end else begin
                    boardStr[index] <= "-";
                end
                index <= index + 1;
            end
        end
        STATE_INIT_STR: begin
            sendStr[0] <=  boardStr[0];
            sendStr[1] <=  boardStr[1];
            sendStr[2] <=  boardStr[2];
            sendStr[3] <=  "\n";
            sendStr[4] <=  boardStr[3];
            sendStr[5] <=  boardStr[4];
            sendStr[6] <=  boardStr[5];
            sendStr[7] <=  "\n";
            sendStr[8] <=  boardStr[6];
            sendStr[9] <=  boardStr[7];
            sendStr[10] <= boardStr[8];
            sendStr[11] <= "\n";
            state <= STATE_SUBMIT;
        end
        STATE_SUBMIT: begin
            if (index == STR_COUNT + 1) begin
                uart_start <= 0;
                state <= STATE_END;
            end else begin
                if (uart_ready == 1) begin
                    uart_start <= 1;
                    uart_data <= sendStr[index];
                    index <= index + 1;
                end
            end
        end
        STATE_END: begin
            if (uart_ready == 1) begin
                state <= STATE_IDLE;
                readyPin <= 1;
            end
        end
    endcase
//*/
end

endmodule