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

reg [WORD_LEN-1:0] reg_memory_addr = 0;
wire [WORD_LEN-1:0] reg_memory_inst;

wire exit;

Memory #(
    .WORD_LEN(WORD_LEN)
) memory (
    .addr(memory_addr),
    .inst(memory_inst)
);

Core #(
    .WORD_LEN(WORD_LEN)
) core (
    .clk(clk),
    .rst_n(rst_n),
    .exit(exit),
    .memory_addr(memory_addr),
    .memory_inst(memory_inst)
);


always @(posedge clk) begin
    led[0] <= exit;
end

endmodule