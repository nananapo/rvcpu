module main #(
    parameter WORD_LEN = 32
)(
    input  wire       rst_n,
    input  wire       clk,

    output reg [5:0] led    // 6 LEDS pin
);

wire [WORD_LEN-1:0] reg_memory_i_addr;
wire [WORD_LEN-1:0] reg_memory_inst;
wire [WORD_LEN-1:0] reg_memory_d_addr;
wire [WORD_LEN-1:0] reg_memory_rdata;
wire reg_memory_wen;
wire [WORD_LEN-1:0] reg_memory_wdata;

wire exit;

Memory #(
    .WORD_LEN(WORD_LEN)
) memory (
    .i_addr(reg_memory_i_addr),
    .inst(reg_memory_inst),
    .d_addr(reg_memory_d_addr),
    .rdata(reg_memory_rdata),
    .wen(reg_memory_wen),
    .wdata(reg_memory_wdata)
);

Core #(
    .WORD_LEN(WORD_LEN)
) core (
    .clk(clk),
    .rst_n(rst_n),
    .exit(exit),
    .memory_i_addr(reg_memory_i_addr),
    .memory_inst(reg_memory_inst),
    .memory_d_addr(reg_memory_d_addr),
    .memory_rdata(reg_memory_rdata),
    .memory_wen(reg_memory_wen),
    .memory_wdata(reg_memory_wdata)
);


always @(posedge clk) begin
    led[0] <= exit;
end

endmodule