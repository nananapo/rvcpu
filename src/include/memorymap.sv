localparam UART_TX_OFFSET               = 32'hff000000;
localparam UART_TX_QUEUE_OFFSET         = 32'h0;
localparam UART_TX_QUEUE_TAIL_OFFSET    = 32'h100;
localparam UART_TX_QUEUE_HEAD_OFFSET    = 32'h104;
localparam UART_TX_END                  = UART_TX_OFFSET + UART_TX_QUEUE_HEAD_OFFSET + 4;

localparam UART_RX_OFFSET               = 32'hff000200;
localparam UART_RX_BUFFER_OFFSET        = 32'h0;
localparam UART_RX_BUFFER_TAIL_OFFSET   = 32'h400;
localparam UART_RX_BUFFER_COUNT_OFFSET  = 32'h404;
localparam UART_RX_END                  = UART_RX_OFFSET + UART_RX_BUFFER_COUNT_OFFSET + 4;

localparam CLINT_OFFSET        = 32'hf0000000;
localparam CLINT_MTIME         = 32'h0;
localparam CLINT_MTIMEH        = 32'h4;
localparam CLINT_MTIMECMP      = 32'h8;
localparam CLINT_MTIMECMPH     = 32'hc;
localparam CLINT_DEBUG         = 32'h10;
localparam CLINT_END           = CLINT_OFFSET + CLINT_DEBUG + 4;
