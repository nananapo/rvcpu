// TODO pcがかぶった時の挙動を知らない
// pcがかぶったとき、それが同じアドレスで命令が違う時も知らない
module TwoBitCounter #(
    parameter ADDR_WIDTH    = 6,// (戒め) ロジックの深さがwidth + n段増えます
    parameter ADDR_SIZE     = 64
)(
    input wire          clk,
    input wire [31:0]   pc,         // 予測したいアドレス
    output wire [31:0]  next_pc,    // pcから予測された次のアドレス
    
    input wire IUpdatePredictionIO updateio
);

localparam DEFAULT_COUNTER_VALUE = 2'b0;

// 本当のpc (pc[ADDR_WIDTH + 2 - 1: 2]をindexにする。
// 下位2bitはC拡張の命令でもない限り0となる)
reg [31:0]  pc_keys         [ADDR_SIZE-1:0];
// ジャンプ先 (成立時), 非成立時はもちろんpc + 4 (あたりまえ体操)
reg [31:0]  targets_taken   [ADDR_SIZE-1:0];
// 2bitのカウンタ。値によって成立するかどうかを決める
// 失敗したら、正しい方向に1bit進める
// take      <-> not take
// 11 <-> 10 <-> 01 <-> 0
reg [1:0]   counters        [ADDR_SIZE-1:0];

// カウンタの初期化
int loop_i;
initial begin
    for (loop_i = 0; loop_i < ADDR_SIZE; loop_i = loop_i + 1) begin
        counters[loop_i] = DEFAULT_COUNTER_VALUE;
        pc_keys[loop_i] = 32'hffffffff;
    end
end

// pcをindexに変換する
wire [ADDR_WIDTH-1:0]   pc2i  =          pc[ADDR_WIDTH + 2 - 1:2];
wire [ADDR_WIDTH-1:0]   upc2i = updateio.pc[ADDR_WIDTH + 2 - 1:2];

// 11と10がtakeなので、上位bitが1ならtake。それ以外ならpc + 4
// ...
// C拡張の時、pc + 4だと常に失敗してしまうな
// このモジュールの意図は、次にフェッチするべきアドレスを予測することにあることをここに明記しておく
assign next_pc  = pc_keys[pc2i] == pc && counters[pc2i][1] == 1'b1 ? targets_taken[pc2i] : pc + 4;

always @(posedge clk) begin
    if (updateio.valid) begin
        if (!updateio.is_br) begin
            pc_keys[upc2i]   <= 32'hffffffff;
            counters[upc2i]  <= DEFAULT_COUNTER_VALUE;
        end else begin
            pc_keys[upc2i]   <= updateio.pc;
            if (updateio.taken)
                targets_taken[upc2i] <= updateio.target;
            // 端ではなければ動かす
            if (!(counters[upc2i] == 2'b11 && updateio.taken) &&
                !(counters[upc2i] == 2'b00 && !updateio.taken)) begin
                counters[upc2i] = counters[upc2i] + (updateio.taken ? 1 : -1); 
            end 
        end
    end
end

/*
`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,btb.request_pc,h,%b", pc);
    $display("data,btb.predict_pc,h,%b", next_pc);
    $display("data,btb.pc_index,b,%b", pc2i);
    $display("data,btb.pc_keys[i],b,%b", pc_keys[pc2i]);
    $display("data,btb.counters[i],b,%b", counters[pc2i]);
    $display("data,btb.update.valid,b,%b", updateio.valid);
    $display("data,btb.update.pc,b,%b", updateio.pc);
    $display("data,btb.update.pc_index,b,%b", upc2i);
    $display("data,btb.update.is_br,b,%b", updateio.is_br);
    $display("data,btb.update.taken,b,%b", updateio.taken);
    $display("data,btb.update.target,b,%b", updateio.target);
end
`endif
*/

endmodule