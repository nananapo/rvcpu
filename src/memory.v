module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384
) (
    input wire [WORD_LEN-1:0] addr,
    output wire [WORD_LEN-1:0] inst
);

reg [7:0] mem [MEMORY_SIZE-1:0];

initial begin
    mem[0] = 8'h11;
    mem[1] = 8'h12;
    mem[2] = 8'h13;
    mem[3] = 8'h14;

    mem[4] = 8'h21;
    mem[5] = 8'h22;
    mem[6] = 8'h23;
    mem[7] = 8'h24;

    mem[8] = 8'h31;
    mem[9] = 8'h32;
    mem[10] = 8'h33;
    mem[11] = 8'h34;
end

assign inst = {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};

endmodule