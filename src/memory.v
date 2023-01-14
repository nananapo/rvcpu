module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384
) (
    input wire clk,
    input wire [WORD_LEN-1:0] i_addr,
    output wire [WORD_LEN-1:0] inst,
    input wire [WORD_LEN-1:0] d_addr,
    output wire [WORD_LEN-1:0] rdata,
    input wire wen,
    input wire [WORD_LEN-1:0] wdata
);

reg [7:0] mem [MEMORY_SIZE-1:0];

initial begin
    $readmemh("../test/bin/rv32ui-p-add.hex", mem);
end

assign inst = {mem[i_addr + 3], mem[i_addr + 2], mem[i_addr + 1], mem[i_addr]};
assign rdata = {mem[d_addr + 3], mem[d_addr + 2], mem[d_addr + 1], mem[d_addr]};

always @(posedge clk) begin
    if (wen) begin
        mem[d_addr] <= wdata[7:0];
        mem[d_addr + 1] <= wdata[15:8];
        mem[d_addr + 2] <= wdata[23:16];
        mem[d_addr + 3] <= wdata[31:24];
    end
end

endmodule