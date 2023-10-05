module DivNbit #(
    parameter SIZE = 32
) (
    input wire  clk,

    input wire  start,
    output wire ready,
    output wire valid,
    output wire error,

    input wire                      is_signed,  // signedかどうか
    input wire signed [SIZE-1:0]    dividend,   // 被除数
    input wire signed [SIZE-1:0]    divisor,    // 除数
    output logic signed [SIZE-1:0]  quotient,   // 商
    output logic signed [SIZE-1:0]  remainder   // 余り
);

typedef logic [SIZE-1:0] UIntS;
typedef enum logic {
    IDLE, WAIT
} statetype;

statetype state = IDLE;

logic result_div_is_minus = 0;
logic result_rem_is_minus = 0;

// mod(ified)_*
// unsignedで計算するために、signedでマイナスならマイナスをかけている
wire UIntS mod_dividend = is_signed ? (dividend > $signed({SIZE{1'b0}}) ? dividend : 0 - dividend) : dividend;
wire UIntS mod_divisor  = is_signed ? (divisor  > $signed({SIZE{1'b0}}) ? divisor  : 0 - divisor)  : divisor;
wire UIntS mod_quotient;
wire UIntS mod_remainder;

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
        IDLE: begin
            if (start) begin
                state               <= WAIT;
                result_div_is_minus <= is_signed && 
                                        ($signed(dividend) < $signed({SIZE{1'b0}})) != ($signed(divisor) < $signed({SIZE{1'b0}}));
                result_rem_is_minus <= is_signed && 
                                        ($signed(dividend) < $signed({SIZE{1'b0}}));
            end
        end
        WAIT: if (valid) state <= IDLE;
    endcase
end

endmodule