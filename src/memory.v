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
    mem[0] = 8'h03;
    mem[1] = 8'h23;
    mem[2] = 8'h80;
    mem[3] = 8'h00;

    mem[4] = 8'h11;
    mem[5] = 8'h12;
    mem[6] = 8'h13;
    mem[7] = 8'h14;

    mem[8] = 8'h22;
    mem[9] = 8'h22;
    mem[10] = 8'h22;
    mem[11] = 8'h22;
end

assign inst = {mem[i_addr + 3], mem[i_addr + 2], mem[i_addr + 1], mem[i_addr]};
assign rdata = {mem[d_addr + 3], mem[d_addr + 2], mem[d_addr + 1], mem[d_addr]};

endmodule