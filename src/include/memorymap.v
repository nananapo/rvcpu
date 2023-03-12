localparam UART_TX_OFFSET               = 32'hff000000;
localparam UART_TX_QUEUE_OFFSET         = 32'h0;
localparam UART_TX_QUEUE_TAIL_OFFSET    = 32'h100;
localparam UART_TX_QUEUE_HEAD_OFFSET    = 32'h104;
localparam UART_TX_END                  = UART_TX_OFFSET + UART_TX_QUEUE_HEAD_OFFSET;

localparam UART_RX_OFFSET               = 32'hff000200;
localparam UART_RX_BUFFER_OFFSET        = 32'h0;
localparam UART_RX_BUFFER_TAIL_OFFSET   = 32'h400;
localparam UART_RX_BUFFER_COUNT_OFFSET  = 32'h404;
localparam UART_RX_END                  = UART_RX_OFFSET + UART_RX_BUFFER_COUNT_OFFSET;