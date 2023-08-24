`default_nettype none

module test_div();
  logic clk = 1;

  logic start;
  logic is_signed;
  wire  ready;
  wire  valid;
  wire  error;
  logic signed [31:0]  dividend; 
  logic signed [31:0]  divisor;  
  wire signed [31:0]   quotient; 
  wire signed [31:0]   remainder;

  DivNbit #() m(
    .clk(clk),
    .start(start),
    .is_signed(is_signed),
    .ready(ready),
    .valid(valid),
    .error(error),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .remainder(remainder)
  );

  always
    #1 clk = ~clk;

  always @(posedge clk) begin
    if (valid) begin
    $display("data,test_div.start,b,%b", start);
    $display("data,test_div.ready,b,%b", ready);
    $display("data,test_div.valid,b,%b", valid);
    $display("data,test_div.dividend,d,%b", dividend);
    $display("data,test_div.divisor,d,%b", divisor);
    $display("data,test_div.quotient,d,%b", quotient);
    $display("data,test_div.remainder,d,%b", remainder);
    $finish();
    end
  end

  initial begin
    #0 begin
        start       = 1;
        is_signed   = 1;
        dividend    = 100;
        divisor     = 3;
    end
  end
endmodule
