`default_nettype none

module test_div();
  reg clk = 1;

  reg           start;
  reg           is_signed;
  wire          ready;
  wire          valid;
  wire          error;
  reg signed  [31:0]   dividend; 
  reg signed  [31:0]   divisor;  
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
    $display("data,test_div.start,%b", start);
    $display("data,test_div.ready,%b", ready);
    $display("data,test_div.valid,%b", valid);
    $display("data,test_div.dividend,%b", dividend);
    $display("data,test_div.divisor,%b", divisor);
    $display("data,test_div.quotient,%b", quotient);
    $display("data,test_div.remainder,%b", remainder);
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
