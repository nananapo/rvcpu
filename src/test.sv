`default_nettype none

module test();

logic clk = 1;
logic uart_rx = 0;
logic uart_tx;

always #1 clk = ~clk;

initial begin
  `ifdef PRINT_DEBUGINFO
    $dumpfile("debug.vcd");
    $dumpvars(0,test);
  `endif
end

main #() m(
  .clk27MHz(clk),
  .uart_tx(uart_tx),
  .uart_rx(uart_rx)
);

initial begin
  `ifdef PRINT_DEBUGINFO
      $display("START_DEBUG_LOG");
      `ifndef INFINITE_LOG
          #500001 $finish;
      `endif
  `endif
end

endmodule
