module testPipeline();
  reg clk = 1;

  mainPipeline #() m(
    .clk(clk)
  );

  always
    #1 clk = ~clk;

  initial
	#100001 $finish;

endmodule
