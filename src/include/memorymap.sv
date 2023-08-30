localparam MMIO_ADDR_UART_TX = 32'hff000000;
localparam MMIO_ADDR_UART_RX = 32'hff000200;

localparam CLINT_OFFSET        = 32'hf0000000;
localparam CLINT_MTIME         = 32'h0;
localparam CLINT_MTIMEH        = 32'h4;
localparam CLINT_MTIMECMP      = 32'h8;
localparam CLINT_MTIMECMPH     = 32'hc;
localparam CLINT_DEBUG         = 32'h10;
localparam CLINT_END           = CLINT_OFFSET + CLINT_DEBUG + 4;
