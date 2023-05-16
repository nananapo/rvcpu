module DivNbit #(
    parameter SIZE = 32
) (
    input wire  clk,

    input wire  start,
    input wire  is_signed,
    output wire ready,
    output wire valid,
    output wire error,

    input wire signed [SIZE-1:0] dividend,   // 被除数
    input wire signed [SIZE-1:0] divisor,    // 除数
    output reg signed [SIZE-1:0] quotient,   // 商
    output reg signed [SIZE-1:0] remainder   // 余り
);

localparam STATE_IDLE   = 0;
localparam STATE_WAIT   = 1;

reg state = STATE_IDLE;

reg result_div_is_minus = 0;
reg result_rem_is_minus = 0;

wire [SIZE-1:0] mod_dividend    = is_signed ? (dividend > $signed({SIZE{1'b0}}) ? dividend : 0 - dividend) : dividend;
wire [SIZE-1:0] mod_divisor     = is_signed ? (divisor  > $signed({SIZE{1'b0}}) ? divisor  : 0 - divisor)  : divisor;
wire [SIZE-1:0] mod_quotient;
wire [SIZE-1:0] mod_remainder;

assign quotient     = !error && result_div_is_minus ? $signed($signed(0) - $signed(mod_quotient)) : mod_quotient;
assign remainder    = !error && result_rem_is_minus ? $signed($signed(0) - $signed(mod_remainder)) : mod_remainder;

DivUnsignedNbit #(
    .SIZE(SIZE)
) divuNbit
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
                                        ($signed(dividend) < $signed({SIZE{1'b0}})) != ($signed(divisor) < $signed({SIZE{1'b0}}));
                result_rem_is_minus <= is_signed && 
                                        ($signed(dividend) < $signed({SIZE{1'b0}}));
            end
        end
        STATE_WAIT:
            if (valid) state <= STATE_IDLE;
    endcase
end


`ifdef PRINT_DEBUGINFO
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("data,divnbit.state,%b", state);
    $display("data,divnbit.start,%b", start);
    $display("data,divnbit.ready,%b", ready);
    $display("data,divnbit.valid,%b", valid);
    $display("data,divnbit.divismin,%b", result_div_is_minus);
    $display("data,divnbit.remismin,%b", result_rem_is_minus);
    $display("data,divnbit.m.dividend,%b", mod_dividend);
    $display("data,divnbit.m.divisor,%b", mod_divisor);
    $display("data,divnbit.m.quotient,%b", mod_quotient);
    $display("data,divnbit.m.remainder,%b", mod_remainder);
end
`endif
`endif

endmodule