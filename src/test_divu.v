`default_nettype none

module test_divu();
  reg clk = 1;

  reg           start;
  wire          ready;
  wire          valid;
  wire          error;
  reg [31:0]    dividend; 
  reg [31:0]    divisor;  
  wire [31:0]   quotient; 
  wire [31:0]   remainder;

  DivUnsigned32bit #() m(
    .clk(clk),
    .start(start),
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
        dividend    = 101;
        divisor     = 10;
    end
  end
endmodule
