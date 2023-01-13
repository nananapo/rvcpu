module Core #(
    parameter WORD_LEN = 32,
    parameter REGISTER_COUNT = 32
) (
    input wire clk,
    input wire rst_n,
    output wire exit,
    output wire [WORD_LEN-1:0] memory_addr,
    input wire [WORD_LEN-1:0] memory_inst
);

// registers
reg [WORD_LEN-1:0] regfile [REGISTER_COUNT-1:0];
reg [WORD_LEN-1:0] reg_pc = 0;

// プログラムカウンタとメモリを接続
assign memory_addr = reg_pc;

// 終了判定
assign exit = memory_inst == 32'h34333231;

integer loop_i;
always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
        reg_pc <= 0;
        for (loop_i = 0; loop_i < REGISTER_COUNT; loop_i = loop_i + 1)
            regfile[loop_i] <= 0;
    end else if (!exit) begin
        reg_pc <= reg_pc + 4;
    end

end

endmodule