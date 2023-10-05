`default_nettype none

module test(
    input wire clk
);
  logic exit;
  logic [31:0] gp;
  logic [5:0] led;
  logic uart_rx = 0;
  logic uart_tx;

  main #() m(
    .clk27MHz(clk),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .exit(exit),
    .led(led),
    .gp(gp)
  );

`ifdef RISCV_TESTS
  always @(posedge clk) begin
	if (exit) begin
		if (gp == 1)
			$display("info,coretest.result,Test passed");
		else
			$display("info,coretest,result,Test failed : gp(%d) is not 1", gp);
    	$finish;
	end 
  end
`endif

initial begin
  `ifdef PRINT_DEBUGINFO
      $display("START_DEBUG_LOG");
  `endif
end
  
endmodule