module test();
  reg rst_n = 1;
  reg clk = 0;
  wire exit;
  wire [31:0] gp;

  main #() m(
    .rst_n(rst_n),
    .clk(clk),
	  .exit(exit),
	  .gp(gp)
  );

  always
    #1 clk = ~clk;

  always @(posedge clk) begin
	if (exit) begin
		if (gp == 1)
			$display("Test passed");
		else
			$display("Test failed : gp(%d) is not 1", gp);
    	$finish;
	end 
  end

  initial
	#100001 $finish;

  initial begin
    $dumpfile("debug.vcd");
    $dumpvars(0,test);
  end

endmodule
