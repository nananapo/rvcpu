`default_nettype none

module test(
    input wire clk,
    input wire uart_rx
);

logic [5:0] led;
logic uart_tx;

main #() m(
  .clk27MHz(clk),
  .uart_tx(uart_tx),
  .uart_rx(uart_rx),
  .led(led)
);

initial begin
  `ifdef PRINT_DEBUGINFO
      $display("START_DEBUG_LOG");
  `endif
end
endmodule