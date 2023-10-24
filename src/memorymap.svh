localparam CLINT_OFFSET     = 32'hf0000000;
localparam CLINT_MTIME      = 32'h0;
localparam CLINT_MTIMEH     = 32'h4;
localparam CLINT_MTIMECMP   = 32'h8;
localparam CLINT_MTIMECMPH  = 32'hc;
localparam CLINT_END        = CLINT_OFFSET + CLINT_MTIMECMPH + 4;

localparam EDISK_OFFSET     = 32'hf8000000;
localparam EDISK_ADDR       = 32'h0;
localparam EDISK_WEN        = 32'h8;
localparam EDISK_DATA       = 32'h10; // DATAを読むとread , writeする
localparam EDISK_END        = EDISK_OFFSET + EDISK_DATA + 8;

localparam MMIO_ADDR_UART_TX = 32'hff000000;
localparam MMIO_ADDR_UART_RX = 32'hff000200;