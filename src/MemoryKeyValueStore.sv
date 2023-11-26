// 1 cycleで処理が終わる
// TODO updateと同時にreqできなくする。BPも
// TODO keyとmemが同じ長さの場合の処理 (mem_keyをなくす)
module MemoryKeyValueStore #(
    parameter KEY_WIDTH = 0,
    parameter VAL_WIDTH = 0,
    parameter MEM_WIDTH = 0, // どこをキーにするかは悩ましい
    parameter LOG_ENABLE = 0,
    parameter LOG_AS = ""
)(
    input wire  clk,
    input wire  reset,

    output wire                 req_ready,
    input wire                  req_valid,
    input wire [KEY_WIDTH-1:0]  req_key,

    output logic                resp_valid,
    output logic                resp_hit,
    output logic [VAL_WIDTH-1:0]resp_value,

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
end

initial begin
    resp_valid  = 0;
    resp_hit    = 0;
    resp_value  = 0;
    for (int i = 0; i < MEM_LENGTH; i++)
        mem_valid[i] = 0;
end

// TODO updateと同時にできなくするときに使う
assign req_ready = 1;

localparam MEM_LENGTH = 2 ** MEM_WIDTH;

// TODO 全部合体してpackする
logic [MEM_LENGTH-1:0]  mem_valid;
logic [KEY_WIDTH-1:0]   mem_key[MEM_LENGTH-1:0];
logic [VAL_WIDTH-1:0]   mem_value[MEM_LENGTH-1:0];

wire [MEM_WIDTH-1:0]    update_mem_key = update_key[MEM_WIDTH-1:0];

wire [MEM_WIDTH-1:0]    req_mem_key = req_key[MEM_WIDTH-1:0];
wire                    mem_hit     = mem_valid[req_mem_key] === 1 & mem_key[req_mem_key] === req_key;
wire [VAL_WIDTH-1:0]    mem_rdata   = mem_value[req_mem_key];

always @(posedge clk) begin
    if (reset) begin
        mem_valid <= 0;
    end else begin
        if (req_valid) begin
            resp_valid  <= 1;
            resp_hit    <= mem_hit;
            resp_value  <= mem_rdata;
        end else
            resp_valid  <= 0;

        if (update_valid) begin
            mem_valid[update_mem_key]   <= 1;
            mem_key[update_mem_key]     <= update_key;
            mem_value[update_mem_key]   <= update_value;
        end
    end
end


`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) if (LOG_ENABLE) begin
    $display("data,%s.req_valid,b,%b", LOG_AS, req_valid);
    $display("data,%s.req_key,b,%b", LOG_AS, req_key);
    $display("data,%s.req_mem_key,b,%b", LOG_AS, req_mem_key);
    $display("data,%s.mem_hit,b,%b", LOG_AS, mem_hit);
    $display("data,%s.mem_rdata,b,%b", LOG_AS, mem_rdata);
    $display("data,%s.update_valid,b,%b", LOG_AS, update_valid);
    if (update_valid) begin
        $display("info,%s.update,%d %d %b(%d) %b(%d) : %h", 
                    LOG_AS, 
                    KEY_WIDTH, VAL_WIDTH, 
                    update_mem_key,update_mem_key,
                    update_key, update_key,
                    update_value);
    end
end
`endif
endmodule