// direct map
module MemICache #(
    // メモリのアドレスの下位何ビットを使うか
    // 容量は 32 byte (キャッシュラインの長さ) * pow(2, width) になる
    parameter ADDR_WIDTH = 8
)(
    input wire clk,

    inout wire ICacheReq    ireq_in,
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

initial begin
    for (int i = 0; i < CACHE_LENGTH; i++) begin
        cache_valid[i] = 0;
    end
end

typedef enum logic [1:0] {
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


ICacheReq s_ireq;
wire ICacheReq ireq = state == IDLE ? ireq_in : s_ireq;

// addrのキャッシュラインのindex
wire CacheIndex req_index = calc_cache_addr(ireq.addr);

// addrがキャッシュラインに存在し、validであるかどうか
wire req_addr_in_valid_cache = cache_addrs[req_index] == normalize_addr(ireq_in.addr) && cache_valid[req_index];

wire [LINE_DATA_ADDR_WIDTH-1:0] req_mem_index_base = {req_index, {LINE_INST_WIDTH{1'b0}}};
wire [LINE_DATA_ADDR_WIDTH-1:0] req_mem_index = req_mem_index_base + {{LINE_DATA_ADDR_WIDTH - LINE_INST_WIDTH{1'b0}}, ireq.addr[LINE_INST_WIDTH+2-1:2]};

logic iresp_valid_reg = 0;
Inst  iresp_rdata_reg;

assign ireq_in.ready= state == IDLE;
assign iresp.valid  = iresp_valid_reg;
assign iresp.rdata  = iresp_rdata_reg;

assign busreq.valid = state == MEM_WAIT_READY;
assign busreq.addr  = normalize_addr(ireq.addr) + read_count * 4;
assign busreq.wen   = 0;
assign busreq.wdata = 32'hx;

// キャッシュラインの何個まで読んだか
logic [LINE_INST_WIDTH-1:0] read_count;

always @(posedge clk) begin
    iresp_valid_reg <=  (state == IDLE && ireq_in.valid && req_addr_in_valid_cache) ||
                        (state == MEM_RESP_VALID);
    iresp_rdata_reg <= cache_data[req_mem_index];
    
    case (state)
    IDLE: begin
        read_count  <= 0;
        s_ireq       <= ireq_in;
        if (ireq_in.valid && !req_addr_in_valid_cache) begin
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
            /* verilator lint_off WIDTH */
            cache_data[req_mem_index_base + read_count] <= busresp.rdata;
            if (read_count == LINE_INST_COUNT - 1) begin
            /* verilator lint_on WIDTH */
                state <= MEM_RESP_VALID;
                cache_addrs[req_index] <= normalize_addr(ireq.addr);
                cache_valid[req_index] <= 1;
            end else
                state <= MEM_WAIT_READY;
        end
    end
    MEM_RESP_VALID: state <= IDLE;
    default: begin
        $display("MemICache : Unknown state");
        $finish;
    end
    endcase
end

`ifdef PRINT_DEBUGINFO
// always @(posedge clk) begin
//     $display("data,fetchstage.i$.state,d,%b", state);
//     $display("data,fetchstage.i$.read_count,d,%b", read_count);

//     if (ireq_in.valid && state == IDLE) begin
//         $display("data,fetchstage.i$.req.addr,h,%b", ireq_in.addr);
//         $display("data,fetchstage.i$.req.addr_base,h,%b", normalize_addr(ireq_in.addr));
//         $display("data,fetchstage.i$.req.cache_hit,d,%b", req_addr_in_valid_cache);
//     end

//     $display("data,fetchstage.i$.busreq.ready,d,%b", busreq.ready);
//     $display("data,fetchstage.i$.busreq.valid,d,%b", busreq.valid);
//     $display("data,fetchstage.i$.busreq.addr,h,%b", busreq.addr);
//     $display("data,fetchstage.i$.busresp.valid,d,%b", busresp.valid);
//     $display("data,fetchstage.i$.busresp.rdata,h,%b", busresp.rdata);
// end
`endif

endmodule