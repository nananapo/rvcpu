`default_nettype none

module test();
  logic clk = 1;
  logic exit;
  logic [31:0] gp;
  logic uart_rx = 0;
  logic uart_tx;

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
    `ifdef PRINT_DEBUGINFO
        $display("START_DEBUG_LOG");
        `ifndef INFINITE_LOG
            #10001 $finish;
        `endif
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
