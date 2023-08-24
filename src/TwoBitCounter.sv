// TODO pcがかぶった時の挙動を知らない
// pcがかぶったとき、それが同じアドレスで命令が違う時も知らない
module TwoBitCounter #(
    parameter ADDR_WIDTH = 12
)(
    input wire          clk,
    input wire [31:0]   pc,         // 予測したいアドレス
    output wire         pred_taken,
    input wire IUpdatePredictionIO updateio
);

localparam ADDR_SIZE = 2 ** ADDR_WIDTH;

localparam DEFAULT_COUNTER_VALUE = 2'b0;

// 2bitのカウンタ。値によって成立するかどうかを決める
// 失敗したら、正しい方向に1bit進める
// take      <-> not take
// 11 <-> 10 <-> 01 <-> 0
logic [1:0] counters [ADDR_SIZE-1:0];

IUpdatePredictionIO saved_updateio;
initial begin
    saved_updateio.valid = 0;
end

// カウンタの初期化
initial begin
    for (int i = 0; i < ADDR_SIZE; i++) begin
        counters[i] = DEFAULT_COUNTER_VALUE;
    end
end

// pcをindexに変換する
wire [ADDR_WIDTH-1:0]   pc2i  =                pc[ADDR_WIDTH + 2 - 1:2];
wire [ADDR_WIDTH-1:0]   upc2i = saved_updateio.pc[ADDR_WIDTH + 2 - 1:2];

// 11と10がtakeなので、上位bitが1ならtake。それ以外ならpc + 4
assign pred_taken  = counters[pc2i][1] == 1'b1;

always @(posedge clk) begin
    saved_updateio <= updateio;
    if (saved_updateio.valid) begin
        if (!saved_updateio.is_br) begin
            counters[upc2i]  <= DEFAULT_COUNTER_VALUE;
        end else begin
            // 端ではなければ動かす
            if (!(counters[upc2i] == 2'b11 && saved_updateio.taken) &&
                !(counters[upc2i] == 2'b00 && !saved_updateio.taken)) begin
                counters[upc2i] = counters[upc2i] + (saved_updateio.taken ? 1 : -1); 
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
    $display("data,btb.counters[i],b,%b", counters[pc2i]);
end
`endif
*/

endmodule