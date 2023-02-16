module test();
  reg clk = 0;

  main #() m(
    .clk(clk)
  );

  always
    #1 clk = ~clk;

  initial
	#100001 $finish;

endmodule
