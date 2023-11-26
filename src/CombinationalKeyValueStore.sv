// TODO keyとmemが同じ長さの場合の処理 (mem_keyをなくす)
// TODO キーの作り方をinterfaceで注入できるようにする
module CombinationalKeyValueStore #(
    parameter KEY_WIDTH = 0,
    parameter VAL_WIDTH = 0,
    parameter MEM_WIDTH = 0
)(
    input wire clk,
    input wire reset,
    input wire [KEY_WIDTH-1:0]  key,
    output wire                 hit,
    output wire [VAL_WIDTH-1:0] value,
    input wire                  update_valid,
    input wire [KEY_WIDTH-1:0]  update_key,
    input wire [VAL_WIDTH-1:0]  update_value
);

initial begin
    if (KEY_WIDTH == 0) begin
        $fatal(1, "KEY_WIDTH is not set");
        `ffinish
    end
    if (VAL_WIDTH == 0) begin
        $fatal(1, "VAL_WIDTH is not set");
        `ffinish
    end
    if (MEM_WIDTH == 0) begin
        $fatal(1, "MEM_WIDTH is not set");
        `ffinish
    end
    if (MEM_WIDTH > KEY_WIDTH) begin
        $fatal(1, "MEM_WIDTH(%d) is longer than KEY_WIDTH(%d)", MEM_WIDTH, KEY_WIDTH);
        `ffinish
    end
    `ifdef DEBUG
        mem_keys = 0;
        mem_values = 0;
    `endif
end

localparam MEM_LEN = 2 ** MEM_WIDTH;

logic [MEM_LEN-1:0] mem_valids = 0;
logic [MEM_LEN-1:0][KEY_WIDTH-1:0] mem_keys;
logic [MEM_LEN-1:0][VAL_WIDTH-1:0] mem_values;

wire [MEM_WIDTH-1:0] search_mem_key = key[MEM_WIDTH-1:0];
wire [MEM_WIDTH-1:0] update_mem_key = update_key[MEM_WIDTH-1:0];

assign hit      = mem_valids[search_mem_key] === 1&& mem_keys[search_mem_key] === key;
assign value    = mem_values[search_mem_key];

always @(posedge clk) begin
    if (reset) begin
        mem_valids <= 0;
    end else if (update_valid) begin
        mem_valids[update_mem_key]  <= 1;
        mem_keys[update_mem_key]    <= update_key;
        mem_values[update_mem_key]  <= update_value;
    end
end

endmodule