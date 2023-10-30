`default_nettype none

module test(
    input wire clk,
    input wire uart_rx
);

logic exit;
logic [5:0] led;
logic uart_tx;

main #() m(
  .clk27MHz(clk),
  .uart_tx(uart_tx),
  .uart_rx(uart_rx),
  .exit(exit),
  .led(led)
);

`ifdef RISCV_TESTS
  always @(posedge clk) begin
    if (exit) $finish;
  end
`endif

initial begin
  `ifdef PRINT_DEBUGINFO
      $display("START_DEBUG_LOG");
  `endif
end
endmodule