module main #(
    parameter WORD_LEN = 32
)(
    input  wire       rst_n,
    input  wire       clk,
	output reg [5:0]  led,
    output wire       uart_tx,
    input  wire       btn1 
/*
	output wire [WORD_LEN-1:0] gp,	// テスト用
	output wire exit 				// テスト用
*/
);

wire [WORD_LEN-1:0] reg_memory_i_addr;
wire [WORD_LEN-1:0] reg_memory_inst;
wire [WORD_LEN-1:0] reg_memory_d_addr;
wire [WORD_LEN-1:0] reg_memory_rdata;
wire reg_memory_wen;
wire [WORD_LEN-1:0] reg_memory_wmask;
wire [WORD_LEN-1:0] reg_memory_wdata;
wire reg_memory_ready;

reg [1:0] clk9MHzCount = 0;
wire clk9MHz = clk9MHzCount == 0;

always @(posedge clk) begin
    if (clk9MHzCount == 2'b10)
        clk9MHzCount <= 0;
    else
        clk9MHzCount <= clk9MHzCount + 1;
end

localparam MEMORY_MAPPED_IO_SIZE = 32;
reg [WORD_LEN-1:0] memmap_io [(MEMORY_MAPPED_IO_SIZE >> 2) - 1:0];

Memory #(
    .WORD_LEN(WORD_LEN)
) memory (
    .clk(clk9MHz),
    .i_addr(reg_memory_i_addr),
    .inst(reg_memory_inst),
    .d_addr(reg_memory_d_addr),
    .rdata(reg_memory_rdata),
    .wen(reg_memory_wen),
    .wmask(reg_memory_wmask),
    .wdata(reg_memory_wdata),
    .data_ready(reg_memory_ready),
    .memmap_io(memmap_io)
);

reg [WORD_LEN-1:0] gp;
reg exit;

Core #(
    .WORD_LEN(WORD_LEN)
) core (
    .clk(clk9MHz),
    .rst_n(rst_n),
    .exit(exit),
    .memory_i_addr(reg_memory_i_addr),
    .memory_inst(reg_memory_inst),
    .memory_d_addr(reg_memory_d_addr),
    .memory_rdata(reg_memory_rdata),
    .memory_wen(reg_memory_wen),
    .memory_wmask(reg_memory_wmask),
    .memory_wdata(reg_memory_wdata),
    .memory_ready(reg_memory_ready),
	.gp(gp)
);

always @(posedge clk) begin
	led[0] <= exit;
	led[5:1] <= ~{gp[0], gp[1], gp[2], gp[3], gp[4]};
end

/*
現状の問題
* uart_txを使う時、開始したいかどうかを管理するフラグをメモリマップドioで操作したい
* ただし、uart_txが何クロックで動くかはメモリで管理したくない
* uart_txのフラグを1にメモリがしたら、uart_tx側(main.v)からメモリを直接変えてやったのだが、そんなことしたら合成できない(同時に代入はできないね)
じゃあどうするか
FIFOか！
FIFOなのか！
メモリより早く動けばいけるぞ
*/

reg uart_tx_start = 0;
reg [7:0] uart_tx_data;
wire uart_tx_ready;

uart_tx #() utx (
    .clk(clk9MHz),
    .start(uart_tx_start),
    .data(uart_tx_data),
    .uart_tx(uart_tx),
    .ready(uart_tx_ready)
);

reg [WORD_LEN-1:0] uart_tx_fifo_index = 0;

always @(posedge clk9MHz) begin
    if (uart_tx_start == 0 && uart_tx_ready && memmap_io[0] != (uart_tx_fifo_index % 32)) begin
        uart_tx_start <= 1;
        uart_tx_data <= memmap_io[1 + (uart_tx_fifo_index % 32)][31:24];
        uart_tx_fifo_index <= (uart_tx_fifo_index + 1) % 32;
    end else begin
        uart_tx_start <= 0;
    end
end

endmodule
