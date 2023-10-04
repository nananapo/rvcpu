`include "memoryinterface.svh"

// direct map
module MemDCache #(
    parameter CACHE_WIDTH = 10
) (
    input wire clk,

    inout wire CacheReq     dreq_in,
    inout wire CacheResp    dresp_in,
    inout wire MemBusReq    busreq,
    inout wire MemBusResp   busresp
);

localparam CACHE_SIZE = 2 ** CACHE_WIDTH;

UInt32  cache_data[CACHE_SIZE-1:0];
Addr    cache_addrs[CACHE_SIZE-1:0];
logic   cache_valid[CACHE_SIZE-1:0];
logic   cache_modified[CACHE_SIZE-1:0];

initial begin
    for (int i = 0; i < CACHE_SIZE; i++) begin
        cache_valid[i] = 0;
        cache_modified[i] = 0;
    end
end

typedef enum logic [2:0] {
    IDLE,
    READ_READY,
    READ_VALID,
    RESP_VALID,
    WRITE_READY
    // ,WRITE_BACK
} statetype;

statetype   state = IDLE;
CacheReq    s_dreq;

wire CacheReq dreq = state == IDLE ? dreq_in : s_dreq;

Addr    wb_addr;
UInt32  wb_data;

logic   dresp_valid_reg;
UInt32  dresp_rdata_reg;

assign dreq_in.ready= state == IDLE;
assign dresp.valid  = dresp_valid_reg;
assign dresp.rdata  = dresp_rdata_reg;

assign busreq.valid = state == READ_READY || state == WRITE_READY;
assign busreq.addr  = state == READ_READY ? dreq.addr : wb_addr;
assign busreq.wen   = state == WRITE_READY ? 1'b1 : dreq.wen;
assign busreq.wdata = wb_data;

wire [CACHE_WIDTH-1:0] info_index = dreq.addr[CACHE_WIDTH + 2 - 1 : 2];
wire cache_hit  = cache_valid[info_index] && cache_addrs[info_index] == dreq.addr;
wire need_wb    = cache_valid[info_index] && cache_modified[info_index];

wire [CACHE_WIDTH-1:0] mem_index = info_index;



`ifdef PRINT_CACHE_MISS
int cachemiss_count = 0;
int cachehit_count  = 0;

localparam CACHE_MISS_COUNT = 1000000;

always @(posedge clk) begin
    if (cachehit_count + cachemiss_count >= CACHE_MISS_COUNT) begin
        $display("d cache miss : %d%% (%d / %d)", cachemiss_count * 100 / CACHE_MISS_COUNT, cachemiss_count, CACHE_MISS_COUNT);
        cachehit_count  <= 0;
        cachemiss_count <= 0;
    end else if (state == IDLE && dreq.valid) begin
        if (cache_hit) begin
            cachehit_count  <= cachehit_count + 1;
        end else begin
            cachemiss_count <= cachemiss_count + 1;
        end
    end
end
`endif


always @(posedge clk) begin
    
    dresp_valid_reg <= (state == IDLE && cache_hit) 
                        || state == RESP_VALID;
    dresp_rdata_reg <= cache_data[mem_index];
    
    case (state)
    IDLE: begin
        s_dreq <= dreq_in;
        if (dreq.valid) begin
            if (cache_hit) begin
                // 上書き
                if (dreq.wen) begin
                    cache_data[mem_index]       <= dreq.wdata;
                    cache_modified[info_index]  <= 1;
                end
            end else begin
                if (need_wb) begin
                    // ライトバック
                    state   <= WRITE_READY;
                    wb_addr <= cache_addrs[info_index];
                    wb_data <= cache_data[mem_index];
                    // 
                    cache_data[mem_index]       <= 32'hx;
                    cache_addrs[info_index]     <= dreq.addr;
                    cache_valid[info_index]     <= 0;
                    cache_modified[info_index]  <= 0;
                end else begin
                    if (dreq.wen) begin
                        // 上書きする
                        cache_data[mem_index]       <= dreq.wdata;
                        cache_addrs[info_index]     <= dreq.addr;
                        cache_valid[info_index]     <= 1;
                        cache_modified[info_index]  <= 1;
                    end else begin
                        // 読む
                        state <= READ_READY;
                        cache_data[mem_index]       <= 32'hx;
                        cache_addrs[info_index]     <= dreq.addr;
                        cache_valid[info_index]     <= 0;
                        cache_modified[info_index]  <= 0;
                    end
                end
            end
        end
    end
    READ_READY: if (busreq.ready) state <= READ_VALID;
    READ_VALID: begin
        if (busresp.valid) begin
            state <= RESP_VALID;
            cache_data[mem_index]       <= busresp.rdata;
            cache_valid[info_index]     <= 1;
            cache_modified[info_index]  <= 0;
        end
    end
    RESP_VALID: state <= IDLE;
    WRITE_READY: begin
        if (busreq.ready) begin
            if (dreq.wen) begin
                // ライトバック -> write
                // modifiedとして書き込みで終わり
                state <= IDLE;
                cache_data[mem_index]       <= dreq.wdata;
                cache_addrs[info_index]     <= dreq.addr;
                cache_valid[info_index]     <= 1;
                cache_modified[info_index]  <= 1;
            end else begin
                // ライトバック -> read
                state <= READ_READY;
            end
        end
    end
    default: begin
        $display("MemDCache : Unknown state");
        $finish;
    end
    endcase
end

// `ifdef PRINT_DEBUGINFO
// always @(posedge clk) begin
//     $display("data,memstage.d$.state,d,%b", state);
//     if (dreq_in.valid && state == IDLE) begin
//         $display("data,memstage.d$.req.addr,h,%b", dreq_in.addr);
//         $display("data,memstage.d$.req.addr_index,h,%b", info_index);
//         $display("data,memstage.d$.req.cache_hit,d,%b", cache_hit);
//         $display("data,memstage.d$.req.cache_data,h,%b", cache_data[mem_index]);
//         $display("data,memstage.d$.req.wen,b,%b", dreq_in.wen);
//         $display("data,memstage.d$.req.wdata,h,%b", dreq_in.wdata);
//     end
//     if (busreq.valid) begin
//         $display("data,memstage.d$.busreq.ready,d,%b", busreq.ready);
//         $display("data,memstage.d$.busreq.valid,d,%b", busreq.valid);
//         $display("data,memstage.d$.busreq.addr,h,%b", busreq.addr);
//     end
//     $display("data,memstage.d$.busresp.valid,d,%b", busresp.valid);
//     $display("data,memstage.d$.busresp.rdata,h,%b", busresp.rdata);
// end
// `endif

endmodule