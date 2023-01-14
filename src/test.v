module test();
  reg rst_n = 1;
  reg clk = 0;
  wire [5:0] led;
  wire exit;
  wire [31:0] gp;

  main #() m(
    .rst_n(rst_n),
    .clk(clk),
    .led(led),
	.exit(exit),
	.gp(gp)
  );

  always
    #1 clk = ~clk;

  initial begin
    #100000 $finish;
  end

  always @(posedge clk) begin
	if (exit)
    	$finish;
  end

  initial begin
    $dumpfile("debug.vcd");
    $dumpvars(0,test);
  end

endmodule
