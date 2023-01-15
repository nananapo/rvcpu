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

  reg [63:0] testclk = 0;

  always
    #1 clk = ~clk;

  always @(posedge clk) begin
	if (exit) begin
		if (gp == 1)
			$display("Test passed");
		else
			$display("Test failed : gp(%d) is not 1", gp);
    	$finish;
	end else begin
		if (testclk >= 100000) begin
			$display("Test failed : Max clock exceeded");
			$finish;
		end else
			testclk <= testclk + 1;
	end
  end

  initial
	#10001 $finish;

  initial begin
    $dumpfile("debug.vcd");
    $dumpvars(0,test);
  end

endmodule
