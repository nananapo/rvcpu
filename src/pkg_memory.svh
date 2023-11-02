`ifndef PKG_MEMORY_SVH
`define PKG_MEMORY_SVH

package MemMap;
// TODO マップ場所を変える
// TODO XLEN64対応
parameter CLINT_OFFSET      = 32'hf0000000;
parameter CLINT_MTIME       = 32'h0;
parameter CLINT_MTIMEH      = 32'h4;
parameter CLINT_MTIMECMP    = 32'h8;
parameter CLINT_MTIMECMPH   = 32'hc;
parameter CLINT_END         = CLINT_OFFSET + CLINT_MTIMECMPH + 4;

parameter EDISK_OFFSET      = 32'hf8000000;
parameter EDISK_ADDR        = 32'h0;
parameter EDISK_WEN         = 32'h8;
parameter EDISK_DATA        = 32'h10; // DATAを読むとread , writeする
parameter EDISK_END         = EDISK_OFFSET + EDISK_DATA + 8;

parameter UART_TX           = 32'hff000000;

parameter UART_RX_OFFSET    = 32'hff000010;
parameter UART_RX_EXISTS    = 32'h0;
parameter UART_RX_VALUE     = 32'h8;
parameter UART_RX_END       = UART_RX_OFFSET + UART_RX_VALUE + 8;

function is_clint_addr(input Addr addr);
    is_clint_addr = util::x_in_range(addr, CLINT_OFFSET, CLINT_END);
endfunction

function is_edisk_addr(input Addr addr);
    is_edisk_addr = util::x_in_range(addr, EDISK_OFFSET, EDISK_END);
endfunction

function is_uart_rx_addr(input Addr addr);
    is_uart_rx_addr = util::x_in_range(addr, UART_RX_OFFSET, UART_RX_END);
endfunction

function is_uart_tx_addr(input Addr addr);
    is_uart_tx_addr = addr === UART_TX;
endfunction

// TODO メモリを8000_0000以降に配置することでメモリ判定を簡略化する

endpackage
`endif