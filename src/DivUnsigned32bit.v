module DivUnsigned32bit
(
    input wire  clk,

    input wire  start,
    output wire ready,
    output wire valid,
    output wire error,

    input wire [31:0]   dividend,   // 被除数
    input wire [31:0]   divisor,    // 除数
    output reg [31:0]   quotient,   // 商
    output reg [31:0]   remainder   // 余り
);

localparam STATE_IDLE       = 0;
localparam STATE_END        = 1;
localparam STATE_END_ERROR  = 2;
localparam STATE_FIND_ONE   = 3;
localparam STATE_DIVIDE     = 4;

reg [2:0] state = STATE_IDLE;

reg [31:0] right1;
reg [31:0] left1;
reg [31:0] shifted_divisor;

reg [31:0] save_divident;
reg [31:0] save_divisor;

assign ready = state == STATE_IDLE;
assign valid = state == STATE_END || state == STATE_END_ERROR;
assign error = state == STATE_END_ERROR;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (start) begin
                save_divident   <= dividend;
                save_divisor    <= divisor;
                shifted_divisor <= divisor;
                left1           <= 32'h8000_0000;
                right1          <= 32'h0000_0001;
                quotient        <= 0;
                remainder       <= dividend;
                if (divisor == 0) 
                    state <= STATE_END_ERROR;
                else if (divisor > dividend)
                    state <= STATE_END;
                else
                    state <= STATE_FIND_ONE;
            end
        end
        STATE_FIND_ONE: begin
            if (left1 & save_divisor == 1) begin
                state       <= STATE_DIVIDE;
            end else begin
                shifted_divisor <= shifted_divisor << 1;
                left1           <= left1 >> 1;
                right1          <= right1 << 1;
            end
        end
        STATE_DIVIDE: begin
            if (right1 == 1)
                state <= STATE_END;
            if (remainder > shifted_divisor) begin
                remainder   <= remainder - shifted_divisor;
                quotient    <= quotient | right1;
            end
            shifted_divisor <= shifted_divisor >> 1;
            right1          <= right1 >> 1;
        end
        //STATE_END:          state <= STATE_IDLE;
        //STATE_END_ERROR:    state <= STATE_IDLE;
        default: state <= STATE_IDLE;
    endcase
end

endmodule