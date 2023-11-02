`include "pkg_util.svh"
`include "memoryinterface.svh"

// direct map
// wenは無視
module MemICache #(
    parameter CACHE_WIDTH = 8
)(
    input wire              clk,
    input wire              reset,

    inout wire CacheReq     ireq_in,
    inout wire CacheResp    iresp_in,
    inout wire MemBusReq    busreq,
    inout wire MemBusResp   busresp
);

localparam ADDR_WIDTH = CACHE_WIDTH;

initial begin
    if (CACHE_WIDTH < 2) begin
        $display("ICache.CACHE_WIDTH(=%d) should be greater than 1", CACHE_WIDTH);
        `ffinish
    end
end

localparam INST_WIDTH       = 32;

localparam LINE_INST_WIDTH  = 3;
localparam LINE_INST_COUNT  = 8;
localparam LINE_WIDTH       = INST_WIDTH * LINE_INST_COUNT;
localparam LINE_DATA_ADDR_WIDTH = LINE_INST_WIDTH + ADDR_WIDTH;

localparam ADDR_DISMISS_WIDTH   = LINE_INST_WIDTH + 2;
localparam CACHE_LENGTH         = 2 ** ADDR_WIDTH;

typedef logic [ADDR_WIDTH-1:0] CacheIndex;

typedef enum logic [1:0] {
    IDLE,
    MEM_WAIT_READY,
    MEM_READ_VALID,
    MEM_RESP_VALID
} statetype;

function [$bits(CacheIndex)-1:0] calc_cache_addr( input UIntX addr );
    calc_cache_addr = addr[ADDR_WIDTH-1 + ADDR_DISMISS_WIDTH:ADDR_DISMISS_WIDTH];
endfunction

function [$bits(UIntX)-1:0] normalize_addr( input UIntX addr );
    normalize_addr = {addr[31:ADDR_DISMISS_WIDTH], {ADDR_DISMISS_WIDTH{1'b0}}};
endfunction

statetype state = IDLE;

UInt32  cache_data[CACHE_LENGTH * LINE_INST_COUNT -1:0]; // 1列
Addr    cache_addrs[CACHE_LENGTH-1:0];
logic   cache_valid[CACHE_LENGTH-1:0];

initial begin
    for (int i = 0; i < CACHE_LENGTH; i++) begin
        cache_valid[i] = 0;
    end
end

CacheReq s_ireq;
wire CacheReq ireq = state == IDLE ? ireq_in : s_ireq;

// addrのキャッシュラインのindex
wire CacheIndex req_index = calc_cache_addr(ireq.addr);

// addrがキャッシュラインに存在し、validであるかどうか
wire cache_hit = cache_addrs[req_index] == normalize_addr(ireq_in.addr) & cache_valid[req_index];

wire [LINE_DATA_ADDR_WIDTH-1:0] req_mem_index_base = {req_index, {LINE_INST_WIDTH{1'b0}}};
wire [LINE_DATA_ADDR_WIDTH-1:0] req_mem_index = req_mem_index_base + {{LINE_DATA_ADDR_WIDTH - LINE_INST_WIDTH{1'b0}}, ireq.addr[LINE_INST_WIDTH+2-1:2]};

logic iresp_valid_reg = 0;
Inst  iresp_rdata_reg;
logic iresp_error_reg;

assign ireq_in.ready    = state == IDLE;
assign iresp_in.valid   = iresp_valid_reg;
assign iresp_in.rdata   = iresp_rdata_reg;
assign iresp_in.error   = iresp_error_reg;
assign iresp_in.errty   = FE_ACCESS_FAULT;

assign busreq.valid = state == MEM_WAIT_READY;
assign busreq.addr  = normalize_addr(ireq.addr) + read_count * 4;
assign busreq.wen   = 0;
assign busreq.wdata = 32'hx;

// キャッシュラインの何個まで読んだか
logic [LINE_INST_WIDTH-1:0] read_count;


`ifdef PRINT_CACHE_MISS
int cachemiss_count = 0;
int cachehit_count  = 0;

localparam CACHE_MISS_COUNT = 1000000;

always @(posedge clk) begin
    if (cachehit_count + cachemiss_count >= CACHE_MISS_COUNT) begin
        $display("i cache miss : %d%% (%d / %d)", cachemiss_count * 100 / CACHE_MISS_COUNT, cachemiss_count, CACHE_MISS_COUNT);
        cachehit_count  <= 0;
        cachemiss_count <= 0;
    end else if (state == IDLE & ireq_in.valid) begin
        if (cache_hit) begin
            cachehit_count  <= cachehit_count + 1;
        end else begin
            cachemiss_count <= cachemiss_count + 1;
        end
    end
end
`endif


always @(posedge clk) begin
    if (reset) begin
        state           <= IDLE;
        iresp_valid_reg <= 0;
        // すべてのキャッシュをinvalidにする
        for (int i = 0; i < CACHE_LENGTH; i++) begin
            cache_valid[i] = 0;
        end
        if (util::logEnabled())
            $display("info,fetchstage.i$.event.invalidated,Invalidated all cache!");
    end else begin
        iresp_valid_reg <=  (state == IDLE & ireq_in.valid & cache_hit) |
                            (state == MEM_RESP_VALID);
        iresp_rdata_reg <= cache_data[req_mem_index];

        case (state)
        IDLE: begin
            read_count  <= 0;
            s_ireq      <= ireq_in;
            if (ireq_in.valid) begin
                if (cache_hit)
                    iresp_error_reg <= 0;
                else begin
                    state <= MEM_WAIT_READY;
                    cache_valid[req_index] <= 0;
                end
            end
        end
        MEM_WAIT_READY: begin
            if (busreq.ready) begin
                state <= MEM_READ_VALID;
            end
        end
        MEM_READ_VALID: begin
            if (busresp.valid) begin
                if (busresp.error) begin
                    state <= MEM_RESP_VALID;
                    iresp_error_reg         <= 1;
                    cache_valid[req_index]  <= 0;
                end else begin
                    read_count <= read_count + 1;
                    /* verilator lint_off WIDTH */
                    cache_data[req_mem_index_base + read_count] <= busresp.rdata;
                    if (read_count == LINE_INST_COUNT - 1) begin
                    /* verilator lint_on WIDTH */
                        state <= MEM_RESP_VALID;
                        iresp_error_reg         <= 0;
                        cache_addrs[req_index]  <= normalize_addr(ireq.addr);
                        cache_valid[req_index]  <= 1;
                    end else
                        state <= MEM_WAIT_READY;
                end
            end
        end
        MEM_RESP_VALID: state <= IDLE;
        default: begin
            $display("MemICache : Unknown state");
            `ffinish
        end
        endcase
    end
end

`ifdef PRINT_DEBUGINFO
/* verilator lint_off WIDTH */
// always @(posedge clk) if (util::logEnabled()) begin
//     $display("data,fetchstage.i$.state,d,%b", state);
//     $display("data,fetchstage.i$.read_count,d,%b", read_count);

//     if (ireq_in.valid & state == IDLE) begin
//         $display("data,fetchstage.i$.req.addr,h,%b", ireq_in.addr);
//         $display("data,fetchstage.i$.req.addr_base,h,%b", normalize_addr(ireq_in.addr));
//         $display("data,fetchstage.i$.req.cache_hit,d,%b", cache_hit);
//     end

//     $display("data,fetchstage.i$.busreq.ready,d,%b", busreq.ready);
//     $display("data,fetchstage.i$.busreq.valid,d,%b", busreq.valid);
//     $display("data,fetchstage.i$.busreq.addr,h,%b", busreq.addr);
//     $display("data,fetchstage.i$.busresp.valid,d,%b", busresp.valid);
//     $display("data,fetchstage.i$.busresp.rdata,h,%b", busresp.rdata);

//     $display("data,fetchstage.i$.busresp.save_mem_index,h,%b", req_mem_index_base + read_count);
//     $display("data,fetchstage.i$.busresp.mem_index,h,%b", req_mem_index);
// end
/* verilator lint_on WIDTH */
`endif

endmodule