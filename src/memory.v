module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384
) (
    input wire [WORD_LEN-1:0] i_addr,
    output wire [WORD_LEN-1:0] inst,
    input wire [WORD_LEN-1:0] d_addr,
    output wire [WORD_LEN-1:0] rdata
);

reg [7:0] mem [MEMORY_SIZE-1:0];

initial begin
    $readmemh("../test/bin/sw.hex", mem);
end

assign inst = {mem[i_addr + 3], mem[i_addr + 2], mem[i_addr + 1], mem[i_addr]};
assign rdata = {mem[d_addr + 3], mem[d_addr + 2], mem[d_addr + 1], mem[d_addr]};

endmodule