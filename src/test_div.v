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

  Div32bit #() m(
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
    $display("test-------------------");
    $display("start     : %d", start);
    $display("ready     : %d", ready);
    $display("valid     : %d", valid);
    $display("dividend  : %d", dividend);
    $display("divisor   : %d", divisor);
    $display("quotient  : %d", quotient);
    $display("remainder : %d", remainder);
    $finish();
    end
  end

  initial begin
    #0 begin
        start       = 1;
        is_signed   = 1;
        dividend    = -111111;
        divisor     = -7;
    end
  end
endmodule
