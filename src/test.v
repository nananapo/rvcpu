`default_nettype none

module test();
  reg clk = 1;
  reg exit;
  reg [31:0] gp;
  reg uart_rx = 0;
  reg uart_tx;

  main #() m(
    .clk(clk),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .exit(exit),
    .gp(gp)
  );

  always
    #1 clk = ~clk;

  initial
    #20001 $finish;

  always @(posedge clk) begin
	if (exit) begin
		if (gp == 1)
			$display("Test passed");
		else
			$display("Test failed : gp(%d) is not 1", gp);
    	$finish;
	end 
  end

endmodule
