module MemoryMapController #(
    parameter MEMORY_SIZE = 4096,
    parameter MEMORY_FILE = ""
) (
    input  wire clk,

    input  wire uart_rx,
    output wire uart_tx,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,

    input  wire [31:0]  input_addr,
    output wire [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata
);

`include "include/memoryinterface.v"

localparam UART_TX_QUEUE_OFFSET         = 32'hff000000;
localparam UART_TX_QUEUE_TAIL_OFFSET    = 32'hff000100;
localparam UART_TX_QUEUE_HEAD_OFFSET    = 32'hff000104;

localparam UART_RX_BUFFER_OFFSET        = 32'hff000200;
localparam UART_RX_BUFFER_TAIL_OFFSET   = 32'hff000600;
localparam UART_RX_BUFFER_COUNT_OFFSET  = 32'hff000601;

wire is_uart_tx_addr    = UART_TX_QUEUE_OFFSET <= input_addr && input_addr <= UART_TX_QUEUE_HEAD_OFFSET;
wire is_uart_rx_addr    = UART_RX_BUFFER_OFFSET <= input_addr && input_addr <= UART_RX_BUFFER_COUNT_OFFSET;
wire is_default_memory  = !is_uart_tx_addr && !is_uart_rx_addr;

// UART_TX
wire        uart_tx_cmd_start   = is_uart_tx_addr ? input_cmd_start : 0;
wire        uart_tx_cmd_write   = is_uart_tx_addr ? input_cmd_write : 0;
wire        uart_tx_cmd_ready;
wire [31:0] uart_tx_addr        = input_addr - UART_TX_QUEUE_OFFSET;
wire [31:0] uart_tx_rdata;
wire        uart_tx_rdata_valid;
wire [31:0] uart_tx_wdata       = input_wdata;

MemoryMappedIO_Uart_tx #() memmap_uarttx (
    .clk(clk),
    .uart_tx(uart_tx),

    .input_cmd_start(uart_tx_cmd_start),
    .input_cmd_write(uart_tx_cmd_write),
    .output_cmd_ready(uart_tx_cmd_ready),
    .input_addr(uart_tx_addr),
    .output_rdata(uart_tx_rdata),
    .output_rdata_valid(uart_tx_rdata_valid),
    .input_wdata(uart_tx_wdata)
);

// UART_RX
wire        uart_rx_cmd_start   = is_uart_rx_addr ? input_cmd_start : 0;
wire        uart_rx_cmd_write   = is_uart_rx_addr ? input_cmd_write : 0;
wire        uart_rx_cmd_ready;
wire [31:0] uart_rx_addr        = input_addr - UART_RX_BUFFER_OFFSET;
wire [31:0] uart_rx_rdata;
wire        uart_rx_rdata_valid;
wire [31:0] uart_rx_wdata       = input_wdata;

MemoryMappedIO_Uart_rx #() memmap_uartrx (
    .clk(clk),
    .uart_rx(uart_rx),

    .input_cmd_start(uart_rx_cmd_start),
    .input_cmd_write(uart_rx_cmd_write),
    .output_cmd_ready(uart_rx_cmd_ready),
    .input_addr(uart_rx_addr),
    .output_rdata(uart_rx_rdata),
    .output_rdata_valid(uart_rx_rdata_valid),
    .input_wdata(uart_rx_wdata)
);

// メモリ
wire        mem_cmd_start   = is_default_memory ? input_cmd_start : 0;
wire        mem_cmd_write   = is_default_memory ? input_cmd_write : 0;
wire        mem_cmd_ready;
wire [31:0] mem_addr        = input_addr;
wire [31:0] mem_rdata;
wire        mem_rdata_valid;
wire [31:0] mem_wdata       = input_wdata;

Memory
#(
    .MEMORY_SIZE(4096),
    .MEMORY_FILE("../test/c/temp.bin.aligned")
) memory (
    .clk(clk),

    .input_cmd_start(mem_cmd_start),
    .input_cmd_write(mem_cmd_write),
    .output_cmd_ready(mem_cmd_ready),
    .input_addr(mem_addr),
    .output_rdata(mem_rdata),
    .output_rdata_valid(mem_rdata_valid),
    .input_wdata(mem_wdata)
);

/*
always @(posedge clk) begin
    $display("MemoryMapController--------");
    $display("addr                  : 0x%h", input_addr);
    $display("is_uart_tx_addr       : %d", is_uart_tx_addr);
    $display("uart_tx_addr          : 0x%h", uart_tx_addr);
    $display("start          : %d", input_cmd_start);
    $display("write          : %d", input_cmd_write);
    $display("wdata          : %d", input_wdata);
    $display("rdata          : 0x%h, 0x%h", output_rdata, uart_tx_rdata);
end
*/

assign output_cmd_ready     =   is_uart_tx_addr ? uart_tx_cmd_ready : 
                                is_uart_rx_addr ? uart_rx_cmd_ready : 
                                mem_cmd_ready;
assign output_rdata         =   is_uart_tx_addr ? uart_tx_rdata : 
                                is_uart_rx_addr ? uart_rx_rdata : 
                                mem_rdata;
assign output_rdata_valid   =   is_uart_tx_addr ? uart_tx_rdata_valid : 
                                is_uart_rx_addr ? uart_rx_rdata_valid : 
                                mem_rdata_valid;

endmodule