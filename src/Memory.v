/* verilator lint_off WIDTH */
/*
ff000000 - ff0000ff : 送信したい文字列置き場
ff000100 : キューの末尾のindex(送信するときはこれを進める)
ff000104 : キューの先頭のindex(読み込みのみ)
*/
module Memory #(
    parameter MEMORY_SIZE = 2048,
    parameter MEMORY_FILE = ""
)(
    input  wire         clk,

    output reg [31:0]   memmapio_uart_tx_buffer[63:0],
    output reg [31:0]   memmapio_uart_tx_queue_tail,
    input  wire[31:0]   memmapio_uart_tx_queue_head,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,

    input  wire [31:0]  input_addr,
    output reg  [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata
);

// memory
reg [31:0] mem [MEMORY_SIZE-1:0];

initial begin
    if (MEMORY_FILE != "") begin
        $readmemh(MEMORY_FILE, mem);
    end
    output_rdata = 0;
    memmapio_uart_tx_queue_tail = 0;
end

wire [31:0] addr_shift = (input_addr >> 2) % MEMORY_SIZE;

assign output_cmd_ready    = 1;
assign output_rdata_valid  = 1;//!cmd_write;


localparam MEMMAPIO_UART_TX_BUFFER_OFFSET = 32'hff000000;
localparam MEMMAPIO_UART_TX_QUEUE_TAIL_OFFSET = 32'hff000100;
localparam MEMMAPIO_UART_TX_QUEUE_HEAD_OFFSET = 32'hff000104;

wire is_memmapio_uart_tx_buffer_addr    = MEMMAPIO_UART_TX_BUFFER_OFFSET <= input_addr && input_addr <= 32'hff0000ff;
wire is_memmapio_uart_tx_queue_tail_addr= input_addr == MEMMAPIO_UART_TX_QUEUE_TAIL_OFFSET;
wire is_memmapio_uart_tx_queue_head_addr= input_addr == MEMMAPIO_UART_TX_QUEUE_HEAD_OFFSET;

wire [5:0] memmapio_uart_tx_buffer_addr = input_addr[7:2];// (input_addr - MEMMAPIO_UART_TX_BUFFER_OFFSET) >> 2;

/*
always @(posedge clk) begin
    $display("Memory--------");
    $display("addr                                  : 0x%h", input_addr);
    $display("is_memmapio_uart_tx_buffer_addr       : %d", is_memmapio_uart_tx_buffer_addr);
    $display("is_memmapio_uart_tx_queue_tail_addr   : %d", is_memmapio_uart_tx_queue_tail_addr);
    $display("is_memmapio_uart_tx_queue_head_addr   : %d", is_memmapio_uart_tx_queue_head_addr);
end
*/

always @(posedge clk) begin
    if (is_memmapio_uart_tx_buffer_addr)
        output_rdata <= memmapio_uart_tx_buffer[memmapio_uart_tx_buffer_addr];
    else if (is_memmapio_uart_tx_queue_head_addr)
        output_rdata <= memmapio_uart_tx_queue_tail;
    else if (is_memmapio_uart_tx_queue_tail_addr)
        output_rdata <= memmapio_uart_tx_queue_head;
    else
        output_rdata <= {
            mem[addr_shift][7:0],
            mem[addr_shift][15:8],
            mem[addr_shift][23:16],
            mem[addr_shift][31:24]
        };

    if (input_cmd_start && input_cmd_write) begin
        if (is_memmapio_uart_tx_buffer_addr)
            memmapio_uart_tx_buffer[memmapio_uart_tx_buffer_addr] <= input_wdata;
        else if (is_memmapio_uart_tx_queue_tail_addr)
            memmapio_uart_tx_queue_tail <= input_wdata;
        else
            mem[addr_shift] <= {
                input_wdata[7:0],
                input_wdata[15:8],
                input_wdata[23:16],
                input_wdata[31:24]
            };
    end
end
endmodule