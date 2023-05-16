`default_nettype none

module test();
  reg clk = 1;
  reg exit;
  reg [31:0] gp;
  reg uart_rx = 0;
  reg uart_tx;

  main #() m(
    .clk27MHz(clk),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .exit(exit),
    .gp(gp)
  );

  always
    #1 clk = ~clk;

  initial begin
    $display("START_DEBUG_LOG");
    `ifdef PRINT_DEBUGINFO
        #20001 $finish;
    `endif
  end

  always @(posedge clk) begin
	if (exit) begin
		if (gp == 1)
			$display("info,coretest.result,Test passed");
		else
			$display("info,coretest,result,Test failed : gp(%d) is not 1", gp);
    	$finish;
	end 
  end

 initial begin
    `ifdef PRINT_DEBUGINFO
      $dumpfile("debug.vcd");
      $dumpvars(0,test);
    `endif
  end

endmodule
