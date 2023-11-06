`ifndef PKG_CONF_H
`define PKG_CONF_H

// `define XLEN 64
// `define XLEN64
`define XLEN 32
`define XLEN32

`define IALIGN 32
`define ILEN 32

package conf;

localparam FREQUENCY_MHz    = 27;
localparam UART_BAUDRATE    = 115200;
localparam XLEN             = `XLEN;
localparam ILEN             = `ILEN;

endpackage

`endif