`default_nettype none

module test(
    input wire clk
);
  reg exit;
  reg [31:0] gp;
  reg [5:0] led;
  reg uart_rx = 0;
  reg uart_tx;

  main #() m(
    .clk27MHz(clk),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .mem_uart_tx(uart_tx),
    .mem_uart_rx(uart_rx),
    .exit(exit),
    .led(led),
    .gp(gp)
  );

endmodule