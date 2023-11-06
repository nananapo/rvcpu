`default_nettype none

module main_gowin
(
    input  wire clk27MHz,
    input  wire uart_rx,
    output wire uart_tx,
    output logic [5:0]  led
);

`define MEM_FILE "../xv6/kernel/kernel.bin.aligned"
`define MEMORY_WIDTH 16
`define MEMORY_DELAY 0

`define EDISK_FILEPATH "../xv6/fs.img.aligned"
`define EDISK_WIDTH 16

main #() m (
    .clk27MHz(clk27MHz),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .led(led)
);

endmodule