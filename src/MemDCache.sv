`include "memoryinterface.svh"
/*
direct map

新しく値を書き込むとき、エラーを確認しない
すべてをライトバックするとき、エラーの発生を確認しない
*/
module MemDCache #(
    parameter CACHE_WIDTH = 10
) (
    input wire clk,

    inout wire CacheReq     dreq_in,
    inout wire CacheResp    dresp_in,
    inout wire MemBusReq    busreq,
    inout wire MemBusResp   busresp,

    // 強制的にすべてwritebackするモードに移行する。
    // ただし、stateがIDLEになるのを待つ (ライトバック中だと壊れる)
    input wire              do_writeback,
    // すべてのデータがwritebackされている(変更されていない)かどうか
    output wire             is_writebacked_all
);

localparam CACHE_SIZE = 2 ** CACHE_WIDTH;

UInt32  cache_data[CACHE_SIZE-1:0];
Addr    cache_addrs[CACHE_SIZE-1:0];
logic   cache_valid[CACHE_SIZE-1:0];
logic   cache_modified[CACHE_SIZE-1:0];

// 変更されているがライトバックされていない値のカウント
logic [CACHE_WIDTH-1:0] modified_count = 0;
assign is_writebacked_all = modified_count == 0;

// writebackが要求されたが処理できていないかどうか
logic writeback_requested = 0;
logic [CACHE_WIDTH-1:0] wb_loop_address;

initial begin
    if (CACHE_WIDTH < 2) begin
        $display("DCache.CACHE_WIDTH(=%d) should be greater than 1", CACHE_WIDTH);
        $finish;
    end 
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
    WRITE_READY,
    WRITE_VALID,
    WB_LOOP_CHECK,
    WB_LOOP_READY
} statetype;

statetype   state = IDLE;
CacheReq    s_dreq;

wire CacheReq dreq = state == IDLE ? dreq_in : s_dreq;

Addr    wb_addr;
UInt32  wb_data;

logic   dresp_valid_reg;
UInt32  dresp_rdata_reg;
logic   dresp_error_reg;

assign dreq_in.ready    = state == IDLE;
assign dresp_in.valid   = dresp_valid_reg;
assign dresp_in.rdata   = dresp_rdata_reg;
assign dresp_in.error   = dresp_error_reg;

assign busreq.valid =   state == READ_READY || state == WRITE_READY || state == WB_LOOP_READY;
assign busreq.addr  =   state == READ_READY ? dreq.addr :
                        // WRITE_READY と WB_LOOP_CHECK はwb_addrを使う
                        state == WRITE_READY ? wb_addr :
                        /* state == WB_LOOP_CHECK ? */ wb_addr;
assign busreq.wen   =   state == READ_READY ? 1'b0 :
                        // WRITE_READY と WB_LOOP_CHECK はwen = 1
                        state == WRITE_READY ? 1'b1 : 
                        /* state == WB_LOOP_CHECK ? */ 1'b1;
assign busreq.wdata =   wb_data;

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
    // TODO これきれいにできない？
    dresp_valid_reg <=  (state == IDLE && (
                            cache_hit ||            // cache hit
                            !need_wb && dreq.wen    // ライトバックが必要なくて、そのまま上書きする
                        )) ||
                        state == RESP_VALID || // read 
                        state == WRITE_READY && (busreq.ready && dreq.wen); // writeback -> write
    dresp_rdata_reg <= cache_data[mem_index];

    if (do_writeback && state != IDLE && state != WB_LOOP_CHECK && state != WB_LOOP_READY) begin
        writeback_requested <= 1;
        `ifdef PRINT_DEBUGINFO
            $display("info,memstage.d$.event.wb_req,force writeback requested. state : %d count : %d", state, modified_count);
        `endif
    end
    
    case (state)
    IDLE: begin
        if (do_writeback || writeback_requested) begin
            state               <= WB_LOOP_CHECK;
            writeback_requested <= 0;
            wb_loop_address     <= 0;
            `ifdef PRINT_DEBUGINFO
                $display("info,memstage.d$.event.start,start force writeback.");
            `endif
        end else begin
            s_dreq <= dreq_in;
            if (dreq.valid) begin
                if (cache_hit) begin
                    dresp_error_reg <= 0;
                    // 上書き
                    if (dreq.wen) begin
                        cache_data[mem_index]   <= dreq.wdata;
                        // modifiedが0かつ変更するならmodifiedとする
                        if (cache_modified[info_index] == 0 && cache_data[mem_index] != dreq.wdata) begin
                            cache_modified[info_index]  <= 1;
                            modified_count              <= modified_count + 1;
                            `ifdef PRINT_DEBUGINFO
                                $display("info,memstage.d$.event.modified,cache modified %h", dreq.addr);
                            `endif
                        end
                    end
                    `ifdef PRINT_DEBUGINFO
                        $display("info,memstage.d$.event.cache_hit,%h wen:%d", dreq.addr, dreq.wen);
                    `endif
                end else begin
                    if (need_wb) begin
                        // ライトバック
                        state   <= WRITE_READY;
                        wb_addr <= cache_addrs[info_index];
                        wb_data <= cache_data[mem_index];
                        // 初期化
                        cache_data[mem_index]       <= 32'hx;
                        cache_addrs[info_index]     <= dreq.addr;
                        cache_valid[info_index]     <= 0;
                        cache_modified[info_index]  <= 0;
                        `ifdef PRINT_DEBUGINFO
                            $display("info,memstage.d$.event.need_wb,l/swith wb : %h", dreq.addr);
                        `endif
                    end else begin
                        if (dreq.wen) begin
                            // modifiedではないので上書きする -> 終了
                            // TODO readしてからwriteする
                            dresp_error_reg             <= 0;
                            cache_data[mem_index]       <= dreq.wdata;
                            cache_addrs[info_index]     <= dreq.addr;
                            cache_valid[info_index]     <= 1;
                            // とりあえずmodifiedとして登録する
                            cache_modified[info_index]  <= 1;
                            modified_count              <= modified_count + 1;
                            
                            `ifdef PRINT_DEBUGINFO
                                $display("info,memstage.d$.event.modified, write with no wb : %h <= %h", dreq.addr, dreq.wdata);
                            `endif
                        end else begin
                            // 読む
                            state <= READ_READY;
                            cache_data[mem_index]       <= 32'hx;
                            cache_addrs[info_index]     <= dreq.addr;
                            cache_valid[info_index]     <= 0;
                            // modifiedではないのでcountは変わらない
                            cache_modified[info_index]  <= 0;
                        end
                    end
                end
            end
        end
    end
    READ_READY: if (busreq.ready) state <= READ_VALID;
    READ_VALID: begin
        if (busresp.valid) begin
            if (busresp.error) begin
                state <= RESP_VALID;
                dresp_error_reg         <= 1;
                cache_valid[info_index] <= 0;
            end else begin
                state <= RESP_VALID;
                dresp_error_reg             <= 0;
                cache_data[mem_index]       <= busresp.rdata;
                cache_valid[info_index]     <= 1;
                cache_modified[info_index]  <= 0;
            end
        end
    end
    RESP_VALID: state <= IDLE;
    WRITE_READY: begin
        if (busreq.ready) begin
            // ライトバックが成功したかどうかは考慮しない
            if (dreq.wen) begin
                // ライトバック -> write
                // modifiedとして書き込みで終了
                // TODO readしてからwrite (errorチェック, 並行性制御のため)
                state <= IDLE;
                dresp_error_reg             <= 0;
                cache_data[mem_index]       <= dreq.wdata;
                cache_addrs[info_index]     <= dreq.addr;
                cache_valid[info_index]     <= 1;
                cache_modified[info_index]  <= 1;
                
                `ifdef PRINT_DEBUGINFO
                    $display("info,memstage.d$.event.write_as_mod,0x%h <= %h", dreq.addr, dreq.wdata);
                `endif
            end else begin
                // ライトバック -> read
                state           <= READ_READY;
                // ライトバックする必要があった → countを1減らす
                modified_count  <= modified_count - 1;
            end
        end
    end
    WB_LOOP_CHECK: begin
        if (is_writebacked_all) begin
            state <= IDLE;
            `ifdef PRINT_DEBUGINFO
                $display("info,memstage.d$.event.done_wb,Writebacked all modified data on D$.");
            `endif
        end else begin
            cache_valid[wb_loop_address]    <= 0;
            cache_modified[wb_loop_address] <= 0;
            if (cache_valid[wb_loop_address] && cache_modified[wb_loop_address]) begin
                state   <= WB_LOOP_READY;
                wb_addr <= cache_addrs[wb_loop_address];
                wb_data <= cache_data[wb_loop_address];
                
                `ifdef PRINT_DEBUGINFO
                    $display("info,memstage.d$.event.loop_need_wb,%h <= %h is modified, needs writeback", cache_addrs[wb_loop_address], cache_data[wb_loop_address]);
                `endif
            end
            wb_loop_address <= wb_loop_address + 1;
        end
    end
    WB_LOOP_READY: begin
        if (busreq.ready) begin
            state           <= WB_LOOP_CHECK;
            modified_count  <= modified_count  - 1;
        end
    end
    default: begin
        // TODO __LINE__ __FILE__
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