module main (
	input wire clk
);

wire [31:0] reg_memory_i_addr;
wire [31:0] reg_memory_inst;
wire [31:0] reg_memory_d_addr;
wire [31:0] reg_memory_rdata;
wire reg_memory_wen;
wire [31:0] reg_memory_wmask;
wire [31:0] reg_memory_wdata;
wire reg_memory_ready;

reg [1:0] clk9MHzCount = 0;
wire clk9MHz = clk9MHzCount == 0;

always @(posedge clk) begin
    if (clk9MHzCount == 2'b10)
        clk9MHzCount <= 0;
    else
        clk9MHzCount <= clk9MHzCount + 1;
end

localparam MEMORY_MAPPED_IO_SIZE = 132;
wire [31:0] memmap_io [(MEMORY_MAPPED_IO_SIZE >> 2) - 1:0];

Memory #(
    .WORD_LEN(32)
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

CorePipeline #() core (
    .clk(clk9MHz),

    .memory_i_addr(reg_memory_i_addr),
    .memory_inst(reg_memory_inst),
    .memory_d_addr(reg_memory_d_addr),
    .memory_rdata(reg_memory_rdata),
    .memory_wen(reg_memory_wen),
    .memory_wmask(reg_memory_wmask),
    .memory_wdata(reg_memory_wdata),
    .memory_ready(reg_memory_ready)
);

endmodule
