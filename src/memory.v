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
    //$readmemh("MEMORY_FILE_NAME", mem);
    $readmemh("../test/bin/lw_b.hex", mem);
end

wire [13:0] i_addr_shifted = (i_addr % MEMORY_SIZE) >> 2;
wire [13:0] da_s = (d_addr % MEMORY_SIZE) >> 2;
wire [13:0] da_s_plus = da_s + 1;


wire [1:0] d_addr_mod4 = d_addr % 4;

always @(posedge clk) begin
    inst <= {mem[i_addr_shifted][7:0], mem[i_addr_shifted][15:8], mem[i_addr_shifted][23:16], mem[i_addr_shifted][31:24]};

    $display("daddr %h(%d) -> %h -> %h", d_addr, d_addr % 4, da_s, da_s_plus);
    $display("0: %h", {mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24]});
    $display("1: %h", {mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24], mem[da_s_plus][7:0]});
    $display("2: %h", {mem[da_s][23:16], mem[da_s][31:24], mem[da_s_plus][7:0], mem[da_s_plus][15:8]});
    $display("3: %h", {mem[da_s][31:24], mem[da_s_plus][7:0], mem[da_s_plus][15:8], mem[da_s_plus][23:16]});
    
    //rdata <= {mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24]};
    case (d_addr_mod4) 
        2'b00: rdata <= {mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24]};
        2'b01: rdata <= {mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24], mem[da_s_plus][7:0]};
        2'b10: rdata <= {mem[da_s][23:16], mem[da_s][31:24], mem[da_s_plus][7:0], mem[da_s_plus][15:8]};
        2'b11: rdata <= {mem[da_s][31:24], mem[da_s_plus][7:0], mem[da_s_plus][15:8], mem[da_s_plus][23:16]};
    endcase

    if (wen) begin
        mem[da_s] <= (
            wty == 0 ? {wdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]} : 
            wty == 1 ? {wdata[7:0], wdata[15:8], rdata[23:16], rdata[31:24]} :
            {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]}
        );
    end
end

endmodule