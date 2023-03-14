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

reg [31:0] count;
reg [63:0] shifted_divisor;

reg [31:0] save_divisor;

assign ready = state == STATE_IDLE;
assign valid = state == STATE_END || state == STATE_END_ERROR;
assign error = state == STATE_END_ERROR;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (start) begin
                save_divisor    <= divisor;
                shifted_divisor <= divisor;
                if (divisor == 0) begin
                    state <= STATE_END_ERROR;
                    remainder       <= dividend;
                    quotient        <= 32'hffff_ffff;
                end else if (divisor > dividend) begin
                    state <= STATE_END;
                    remainder       <= dividend;
                    quotient        <= 32'h0;
                end else begin
                    state <= STATE_DIVIDE;
                    remainder       <= dividend;
                    quotient        <= 32'h0;
                    shifted_divisor <= divisor << 31;
                    count           <= 32'h8000_0000;
                end
            end
        end
        STATE_DIVIDE: begin
            if (count == 1)
                state <= STATE_END;
            if (remainder >= shifted_divisor) begin
                remainder   <= remainder - shifted_divisor;
                quotient    <= quotient | count;
            end
            shifted_divisor <= shifted_divisor >> 1;
            count           <= count >> 1;
        end
        //STATE_END:          state <= STATE_IDLE;
        //STATE_END_ERROR:    state <= STATE_IDLE;
        default: state <= STATE_IDLE;
    endcase
end

`ifdef DEBUG
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("DIV-------------------");
    $display("state             : %d", state);
    $display("save_divisor      : 0b%b", save_divisor);
    $display("shifted_divisor   : 0b%b", shifted_divisor);
    $display("count             : 0b%b", count);
    $display("quotient          : %d", quotient);
    $display("remainder         : %d", remainder);
    $display("remainder         : 0b%b", remainder);
end
`endif
`endif

endmodule