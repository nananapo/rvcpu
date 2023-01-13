module main #(
    parameter WORD_LEN = 32
)(
    input  wire       rst_n,
    input  wire       clk,

    output reg [5:0] led    // 6 LEDS pin

/*
    output wire       hdmi_clk_p,
    output wire       hdmi_clk_n,
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,
*/
/*
    input wire btn1,         // right button
    output wire uart_tx      // uart transmission
*/
);

wire [WORD_LEN-1:0] reg_memory_i_addr;
wire [WORD_LEN-1:0] reg_memory_inst;
wire [WORD_LEN-1:0] reg_memory_d_addr;
wire [WORD_LEN-1:0] reg_memory_rdata;

wire exit;

Memory #(
    .WORD_LEN(WORD_LEN)
) memory (
    .i_addr(reg_memory_i_addr),
    .inst(reg_memory_inst),
    .d_addr(reg_memory_d_addr),
    .rdata(reg_memory_rdata)
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
    .memory_rdata(reg_memory_rdata)
);


always @(posedge clk) begin
    led[0] <= exit;
end

endmodule