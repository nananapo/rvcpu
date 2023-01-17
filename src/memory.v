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

/*
# 2023/01/17 13:10

lb命令とlh命令のテストが通らない
メモリのエンディアンとアドレスの関係がよくわからなくなったので整理

アドレス| データ(アドレス)
--|---- ---- ---- ----
0 |0    1    2    3
4 |4    5    6    7
8 |8    9    10   11
--|---- ---- ---- ----
riscvはリトルエンディアン
下位bitが前に来る
つまり, 0xcafebebe, 0xdeadbeefの場合は
--|---- ---- ---- ----
0 |be   be   fe   ca
4 |ef   be   ad   de
--|---- ---- ---- ----
になるはず
で、アドレス0を読むと
be be fe caを並び替えて
ca fe be beにする

じゃあ、アドレス1を読むとどうなる?

並びとしては
be fe ca efなので、
ef ca fe beになると思う
じゃあ、現在の実装(796fcfa06fe5d6fa8647f437dc1e0a4428a0c21d)を見る

1余りの場合、
da_s  : be be fe ca
da_s+1: ef be ad de
{mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24], mem[da_s_p][7:0]}
なので、
fe be be deになる
ぜんぜん違うね

正しくは、
{mem[da_s_p][31:24], mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16]}
2余りの場合は
{mem[da_s_p][23:16], mem[da_s_p][31:24], mem[da_s][7:0], mem[da_s][15:8]}
3余りの場合は
{mem[da_s_p][15:8], mem[da_s_p][23:16], mem[da_s_p][31:24], mem[da_s][7:0]}


sw命令もどうにかするか
cafebebeをアドレス4に保存する
0 |0    1    2    3
4 |be   be   fe   ca
こうなる。保存する時は、
{wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]}
を1に保存する。

じゃあアドレス3に保存すると
0 |0    1    2    be
4 |be   fe   ca   7
になってほしい
このためには、
mem[0] = {rdata[31:8], wdata[7:0]}
mem[1] = {wdata[15:8], wdata[23:16], wdata[31:24], rdata_p[7:0]}
にする必要がある。

アドレス2の時は
mem[0] = {rdata[31:14], wdata[7:0], wdata[15:8]}
mem[1] = {wdata[23:16], wdata[31:24], rdata_p[15:0]}
アドレス1の時は
mem[0] = {rdata[31:24], wdata[7:0], wdata[15:8], wdata[23:16]}
mem[1] = {wdata[31:24], rdata_p[23:0]}

BSRAMの推論的に、2読み込み2保存ってできたっけ？
* 心配
* 命令の読み込みもあるので3読み込みになる
* 無理かもしれないしメモリをきれいなコードにしたいので、core側で2回読むようにするか
*/


reg [WORD_LEN-1:0] mem [(MEMORY_SIZE >> 2) - 1:0];

initial begin
    //$readmemh("MEMORY_FILE_NAME", mem);
    $readmemh("../test/bin/lw_b.hex", mem);
end

wire [13:0] i_addr_shifted = (i_addr % MEMORY_SIZE) >> 2;
wire [13:0] da_s = (d_addr % MEMORY_SIZE) >> 2;
wire [13:0] da_s_p = da_s + 1;


wire [1:0] d_addr_mod4 = d_addr % 4;

always @(posedge clk) begin
    inst <= {mem[i_addr_shifted][7:0], mem[i_addr_shifted][15:8], mem[i_addr_shifted][23:16], mem[i_addr_shifted][31:24]};

/*
    $display("daddr %h(%d) -> %h -> %h", d_addr, d_addr % 4, da_s, da_s_p);
    $display("%h, %h", mem[da_s], mem[da_s_p]);
    $display("0: %h", {mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24]});
    $display("1: %h", {mem[da_s_p][31:24], mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16]});
    $display("2: %h", {mem[da_s_p][23:16], mem[da_s_p][31:24], mem[da_s][7:0], mem[da_s][15:8]});
    $display("3: %h", {mem[da_s_p][15:8], mem[da_s_p][23:16], mem[da_s_p][31:24], mem[da_s][7:0]});
*/

    case (d_addr_mod4) 
        2'b00: rdata <= {mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16], mem[da_s][31:24]};
        2'b01: rdata <= {mem[da_s_p][31:24], mem[da_s][7:0], mem[da_s][15:8], mem[da_s][23:16]};
        2'b10: rdata <= {mem[da_s_p][23:16], mem[da_s_p][31:24], mem[da_s][7:0], mem[da_s][15:8]};
        2'b11: rdata <= {mem[da_s_p][15:8], mem[da_s_p][23:16], mem[da_s_p][31:24], mem[da_s][7:0]};
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