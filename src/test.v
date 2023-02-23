`default_nettype none

module test();
  reg clk = 1;

  main #() m(
    .clk(clk)
  );

  always
    #1 clk = ~clk;

  initial
	#10001 $finish;

endmodule
