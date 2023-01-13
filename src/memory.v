module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384
) (
    input wire [WORD_LEN-1:0] addr,
    output wire [WORD_LEN-1:0] inst
);

reg [7:0] mem [MEMORY_SIZE-1:0];

initial begin
    mem[0] = 11;
    mem[1] = 12;
    mem[2] = 13;
    mem[3] = 14;

    mem[4] = 21;
    mem[5] = 22;
    mem[6] = 23;
    mem[7] = 24;

    mem[8] = 31;
    mem[9] = 32;
    mem[10] = 33;
    mem[11] = 34;
end

assign inst = {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};

endmodule