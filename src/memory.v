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
    input wire [WORD_LEN-1:0] wdata
);

reg [WORD_LEN-1:0] mem [(MEMORY_SIZE >> 2) - 1:0];

initial begin
    // add 1,0,0
    //inst = 32'b00000000000000000000000010110011;
    $readmemh("../test/bin/sw.hex", mem);
end

wire [13:0] i_addr_mod = (i_addr % MEMORY_SIZE) >> 2;
wire [13:0] d_addr_mod = (d_addr % MEMORY_SIZE) >> 2;

always @(posedge clk) begin
    if (wen) begin
        mem[d_addr] <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
    end
    inst <= {mem[i_addr_mod][7:0], mem[i_addr_mod][15:8], mem[i_addr_mod][23:16], mem[i_addr_mod][31:24]};
    rdata <= {mem[d_addr_mod][7:0], mem[d_addr_mod][15:8], mem[d_addr_mod][23:16], mem[d_addr_mod][31:24]};
end

endmodule