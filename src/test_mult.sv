`default_nettype none

module test_mult();
  reg clk = 1;

  reg           start;
  reg           is_signed;
  wire          ready;
  wire          valid;

  wire signed [63:0] product;
  reg signed [31:0] multiplicand;
  reg signed [31:0] multiplier;

  MultNbit #() m(
    .clk(clk),
    .start(start),
    .is_signed(is_signed),
    .ready(ready),
    .valid(valid),
    .multiplicand(multiplicand),
    .multiplier(multiplier),
    .product(product)
  );

  always
    #1 clk = ~clk;

  always @(posedge clk) begin
    if (valid) begin
    $display("data,test_mult.start,b,%b", start);
    $display("data,test_mult.issigned,b,%b", is_signed);
    $display("data,test_mult.ready,b,%b", ready);
    $display("data,test_mult.valid,b,%b", valid);
    $display("data,test_mult.multiplicand,d,%b", multiplicand);
    $display("data,test_mult.multiplier,d,%b", multiplier);
    $display("data,test_mult.product,d,%b", product);
    $finish();
    end
  end

  initial begin
    #0 begin
        start           = 1;
        is_signed       = 1;
        multiplier      = -2147483647;
        multiplicand    = 4;
    end
  end
endmodule
