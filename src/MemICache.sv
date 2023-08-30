// direct map
module MemICache #(
    // メモリのアドレスの下位何ビットを使うか
    // 容量は 32 byte (キャッシュラインの長さ) * pow(2, width) になる
    parameter ADDR_WIDTH = 8
)(
    input wire clk,

    inout wire ICacheReq    ireq,
    inout wire ICacheResp   iresp,
    inout wire MemBusReq    busreq,
    inout wire MemBusResp   busresp
);

localparam INST_WIDTH       = 32;

localparam LINE_INST_WIDTH  = 3;
localparam LINE_INST_COUNT  = 8;
localparam LINE_WIDTH       = INST_WIDTH * LINE_INST_COUNT;
localparam LINE_DATA_ADDR_WIDTH = LINE_INST_WIDTH + ADDR_WIDTH;

localparam ADDR_DISMISS_WIDTH = LINE_INST_WIDTH + 2;
localparam CACHE_LENGTH     = 2 ** ADDR_WIDTH;

typedef logic [ADDR_WIDTH-1:0] CacheIndex;

logic [31:0] cache_data  [CACHE_LENGTH * LINE_INST_COUNT -1:0]; // 1列
logic [31:0] cache_addrs [CACHE_LENGTH-1:0];
logic cache_valid[CACHE_LENGTH-1:0];

typedef enum [1:0] {
    IDLE,
    MEM_WAIT_READY,
    MEM_READ_VALID,
    MEM_RESP_VALID
} statetype;

statetype state = IDLE;

function [$bits(CacheIndex)-1:0] calc_cache_addr( input [31:0] addr );
    calc_cache_addr = addr[ADDR_WIDTH-1 + ADDR_DISMISS_WIDTH:ADDR_DISMISS_WIDTH];
endfunction

function [31:0] normalize_addr( input [31:0] addr );
    normalize_addr = {addr[31:ADDR_DISMISS_WIDTH], {ADDR_DISMISS_WIDTH{1'b0}}};
endfunction

// リクエストの保存
ICacheReq s_req;
// addrのキャッシュラインのindex
wire CacheIndex req_index = calc_cache_addr(state == IDLE ? ireq.addr : s_req.addr);
// addrがキャッシュラインに存在し、validであるかどうか
wire req_addr_in_valid_cache = cache_addrs[req_index] == ireq.addr && cache_valid[req_index];

wire [LINE_DATA_ADDR_WIDTH-1:0] req_mem_index_base = {req_index, {LINE_INST_WIDTH{1'b0}}};
wire [LINE_DATA_ADDR_WIDTH-1:0] req_mem_index = req_mem_index_base + s_req.addr[LINE_INST_WIDTH+2-1:2];

logic ireq_valid_reg;
Inst  ireq_rdata_reg;

assign ireq.ready   = state == IDLE;
assign ireq.valid   = ireq_valid_reg;
assign ireq.rdata   = ireq_rdata_reg;

assign busreq.valid = state == MEM_WAIT_READY;
assign busreq.addr  = normalize_addr(s_req.addr) + read_count * 4;
assign busreq.wen   = 0;
assign busreq.wdata = 32'hz;

// キャッシュラインの何個まで読んだか
logic [LINE_INST_WIDTH-1:0] read_count;

always @(posedge clk) begin
    ireq_valid_reg  <=  (state == IDLE && ireq.valid && req_addr_in_valid_cache) ||
                        (state == MEM_RESP_VALID);
    ireq_rdata_reg  <= cache_data[req_mem_index];
    
    case (state)
    IDLE: begin
        read_count  <= 0;
        s_req       <= ireq;
        if (ireq.valid && !req_addr_in_valid_cache) begin
            state <= MEM_WAIT_READY;
            cache_valid[req_index] <= 0;
        end
    end
    MEM_WAIT_READY: begin
        if (busreq.ready) begin
            state <= MEM_READ_VALID;
        end
    end
    MEM_READ_VALID: begin
        if (busresp.valid) begin
            read_count <= read_count + 1;
            if (read_count == LINE_INST_COUNT - 1) begin
                state <= MEM_RESP_VALID;
                cache_addr[req_index]  <= normalize_addr(sreq.addr);
                cache_valid[req_index] <= 1;
            end
            cache_data[req_mem_index_base + read_count] <= busresp.rdata;
        end
    end
    MEM_RESP_VALID: state <= IDLE;
    default: begin
        $display("MemICache : Unknown state");
        $finish;
    end
    endcase
end

endmodule