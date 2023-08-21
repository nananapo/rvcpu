module MultNbit #(
    parameter SIZE = 32
) (
    input wire  clk,

    input wire  start,
    output wire ready,
    output wire valid,

    input wire                      is_signed,      // signedかどうか
    input wire signed [SIZE-1:0]    multiplicand,   // 被乗数
    input wire signed [SIZE-1:0]    multiplier,     // 乗数
    output logic signed [SIZE*2-1:0]  product         // 積
);

typedef enum logic { 
    IDLE, WAIT
} statetype;

statetype state = IDLE;

logic result_is_minus = 0;

// mod(ified)_*
// signedでマイナスな計算をunsignedでできるようにする
// TODO これ、必要あるか？後でチェックする
wire [SIZE-1:0]     mod_multiplicand = is_signed ? (multiplicand > $signed({SIZE{1'b0}}) ? multiplicand : 0 - multiplicand) : multiplicand;
wire [SIZE-1:0]     mod_multiplier   = is_signed ? (multiplier  > $signed({SIZE{1'b0}}) ? multiplier  : 0 - multiplier)  : multiplier;
wire [SIZE*2-1:0]   mod_product;

assign product = result_is_minus ? $signed($signed({SIZE*2-1{1'b0}}) - $signed(mod_product)) : mod_product;

MultUnsignedNbit #(
    .SIZE(SIZE)
) divuNbit
(
    .clk(clk),
    .start(start),
    .ready(ready),
    .valid(valid),
    .multiplicand(mod_multiplicand),
    .multiplier(mod_multiplier),
    .product(mod_product)
);

always @(posedge clk) begin
    case (state)
        IDLE: begin
            if (start) begin
                state               <= WAIT;
                result_is_minus     <= is_signed && ($signed(multiplier) < $signed({SIZE{1'b0}})) != ($signed(multiplicand) < $signed({SIZE{1'b0}}));
            end
        end
        WAIT:
            if (valid) state <= IDLE;
    endcase
end


`ifdef PRINT_DEBUGINFO
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("data,multnbit.input.start,b,%b", start);
    $display("data,multnbit.input.ready,b,%b", ready);
    $display("data,multnbit.input.valid,b,%b", valid);
    $display("data,multnbit.input.is_signed,b,%b", is_signed);
    $display("data,multnbit.input.multiplicand,d,%b", multiplicand);
    $display("data,multnbit.input.multiplier,d,%b", multiplier);
    $display("data,multnbit.output.product,d,%b", product);

    $display("data,multnbit.state,%d", state);
    $display("data,multnbit.result_is_minus,b,%b", result_is_minus);
    $display("data,multnbit.mod.multiplicand,d,%b", mod_multiplicand);
    $display("data,multnbit.mod.multiplier,d,%b", mod_multiplier);
    $display("data,multnbit.mod.product,d,%b", mod_product);
end
`endif
`endif

endmodule