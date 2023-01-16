module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384
) (
    input wire clk,
    input wire [WORD_LEN-1:0] i_addr,
    output reg [WORD_LEN-1:0] inst,
    input wire [WORD_LEN-1:0] d_addr,
    output reg [WORD_LEN-1:0] rdata,
    input wire wen,
    input wire [1:0] wty,
    input wire [WORD_LEN-1:0] wdata
);

reg [WORD_LEN-1:0] mem [(MEMORY_SIZE >> 2) - 1:0];

initial begin
    $readmemh("MEMORY_FILE_NAME", mem);
end

wire [13:0] i_addr_shifted = (i_addr % MEMORY_SIZE) >> 2;
wire [13:0] d_addr_shifted = (d_addr % MEMORY_SIZE) >> 2;

always @(posedge clk) begin
    inst <= {mem[i_addr_shifted][7:0], mem[i_addr_shifted][15:8], mem[i_addr_shifted][23:16], mem[i_addr_shifted][31:24]};
    rdata = {mem[d_addr_shifted][7:0], mem[d_addr_shifted][15:8], mem[d_addr_shifted][23:16], mem[d_addr_shifted][31:24]};
    if (wen) begin
        mem[d_addr_shifted] = (
            wty == 0 ? {wdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]} : 
            wty == 1 ? {wdata[7:0], wdata[15:8], rdata[23:16], rdata[31:24]} :
            {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]}
        );
    end
end

endmodule