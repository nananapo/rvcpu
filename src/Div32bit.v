module Div32bit
(
    input wire  clk,

    input wire  start,
    input wire  is_signed,
    output wire ready,
    output wire valid,
    output wire error,

    input wire signed [31:0]    dividend,   // 被除数
    input wire signed [31:0]    divisor,    // 除数
    output reg signed [31:0]    quotient,   // 商
    output reg signed [31:0]    remainder   // 余り
);

localparam STATE_IDLE   = 0;
localparam STATE_WAIT   = 1;

reg state = STATE_IDLE;

reg result_div_is_minus = 0;
reg result_rem_is_minus = 0;

wire [31:0] mod_dividend    = is_signed ? (dividend > $signed(0) ? dividend : 0 - dividend) : dividend;
wire [31:0] mod_divisor     = is_signed ? (divisor > $signed(0) ? divisor : 0 - divisor) : divisor;
wire [31:0] mod_quotient;
wire [31:0] mod_remainder;

assign quotient     = result_div_is_minus ? $signed($signed(0) - $signed(mod_quotient)) : mod_quotient;
assign remainder    = result_rem_is_minus ? $signed($signed(0) - $signed(mod_remainder)) : mod_remainder;

DivUnsigned32bit #() divu32bit
(
    .clk(clk),
    .start(start),
    .ready(ready),
    .valid(valid),
    .error(error),
    .dividend(mod_dividend),
    .divisor(mod_divisor),
    .quotient(mod_quotient),
    .remainder(mod_remainder)
);

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (start) begin
                state               <= STATE_WAIT;
                result_div_is_minus <= is_signed && 
                                        ($signed(dividend) < $signed(0)) != ($signed(divisor) < $signed(0));
                result_rem_is_minus <= is_signed && 
                                        ($signed(dividend) < $signed(0));
            end
        end
        STATE_WAIT:
            if (valid) state <= STATE_IDLE;
    endcase
end


`ifdef DEBUG
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("div32bit-------------------");
    $display("state         : %d", state);
    $display("start         : %d", start);
    $display("ready         : %d", ready);
    $display("valid         : %d", valid);
    $display("divismin      : %d", result_div_is_minus);
    $display("remismin      : %d", result_rem_is_minus);
    $display("m.dividend    : %d", mod_dividend);
    $display("m.divisor     : %d", mod_divisor);
    $display("m.quotient    : %d", mod_quotient);
    $display("m.remainder   : %d", mod_remainder);
end
`endif
`endif

endmodule