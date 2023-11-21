// Sv32
module PageTableWalker
    import meminf::*;
    import basic::Addr, basic::UIntX;
    import csr::*;
#(
    parameter PAGESIZE_WIDTH    = 12,
    parameter PTESIZE_WIDTH     = 2,
    parameter LOG_ENABLE        = 0,
    parameter LOG_AS            = "fetchstage",
    parameter EXECUTE_MODE      = 0
) (
    input wire clk,
    input wire reset,

    inout wire CacheReq     preq,
    inout wire CacheResp    presp,
    inout wire CacheReq     memreq,
    inout wire CacheResp    memresp,
    inout wire CacheReq     ptereq,
    inout wire CacheResp    pteresp,

    input wire csr::Mode    mode,
    input wire [31:0]       satp,
    input wire              mxr,
    input wire              sum,

    input wire              flush_tlb
);

import conf::*;

localparam ENABLE_TLB0_LOG = 0;
localparam ENABLE_TLB1_LOG = 0;

localparam VPN1_LEN = 10;
localparam VPN0_LEN = 10;
localparam VPN_LEN  = VPN1_LEN + VPN0_LEN;

localparam PPN1_LEN = 12;
localparam PPN0_LEN = 10;
localparam PPN_LEN  = PPN1_LEN + PPN0_LEN;

// 5.1.11
// MODE(1) | ASID(9) | PPN(22)
// Table 23
// MODE = 0 : Bare (物理アドレスと同じ), ASID, PPNも0にする必要がある
//            0ではないなら動作はUNSPECIFIED！こわいね
// MODE = 1 : Sv32, ページングが有効

// 単純にするため、
// * IDLEからとりあえずREADYに遷移
typedef enum logic [3:0] {
    IDLE,
    WAIT_TLB_READY,
    CHECK_TLB,
    WALK_READY,
    WALK_VALID,
    REQ_READY,
    REQ_VALID,
    REQ_END,
    WAIT_SET_AD_READY
} statetype;

wire       satp_mode = satp[31];
wire [8:0] satp_asid = satp[30:22];
wire [21:0] satp_ppn = satp[21:0];

statetype state  = IDLE;
wire sv32_enable = mode != M_MODE & satp_mode == 1;

logic   result_error = 0;
FaultTy result_errty = FE_ACCESS_FAULT;

assign preq.ready   = sv32_enable ? state == IDLE       : memreq.ready;
assign presp.valid  = sv32_enable ? state == REQ_END    : memresp.valid;
assign presp.rdata  = sv32_enable ? result_rdata        : memresp.rdata;
assign presp.error  = sv32_enable ? result_error        : memresp.error;
assign presp.errty  = sv32_enable ? result_errty        : memresp.errty;

assign memreq.valid = sv32_enable ? state == REQ_READY  : preq.valid;
assign memreq.addr  = sv32_enable ? next_addr[31:0]     : preq.addr;
assign memreq.wen   = sv32_enable ? s_req.wen           : preq.wen;
assign memreq.wdata = sv32_enable ? s_req.wdata         : preq.wdata;
assign memreq.wmask = sv32_enable ? s_req.wmask         : preq.wmask;
assign memreq.pte   = PTE_AD'(2'b00);

assign ptereq.valid = state == WALK_READY | state == WAIT_SET_AD_READY;
assign ptereq.addr  = next_addr[31:0];
assign ptereq.wen   = 0;
assign ptereq.wdata = 0;
assign ptereq.wmask = SIZE_W;
assign ptereq.pte   = PTE_AD'({state == WAIT_SET_AD_READY, state == WAIT_SET_AD_READY & s_req.wen}); // A & D

// preqがリクエストしたアドレス
CacheReq s_req;
// ページのレベル
logic [1:0]   level;
// 次にアクセスするアドレス
logic [33:0]  next_addr;
// 結果
logic [31:0]  result_rdata;
// 保存されたアドレスのvpn, offset
wire [VPN1_LEN-1:0] s_vpn1  = s_req.addr[31:22];
wire [VPN0_LEN-1:0] s_vpn0  = s_req.addr[21:12];
wire [VPN_LEN-1:0]  s_vpn   = s_req.addr[31:12];
wire [11:0] s_page_offset   = s_req.addr[11:0];
// preqのvpn1 (IDLEで使う)
wire [9:0]  idleonly_vpn1   = preq.addr[31:22];

/*
X=W=R=0のとき、ポインタ
WritableなものはReadableである。
Reservedだと、faultが発生する。

X W R
0 0 0 Pointer to next level of page table.
0 0 1 Read-only page.
0 1 0 Reserved for future use.
0 1 1 Read-write page.
1 0 0 Execute-only page.
1 0 1 Read-execute page.
1 1 0 Reserved for future use.
1 1 1 Read-write-execute page.
*/
wire pte_V  = pteresp.rdata[0] === 1'b1; // validかどうか
wire pte_R  = pteresp.rdata[1] === 1'b1; // Readable
wire pte_W  = pteresp.rdata[2] === 1'b1; // Writable
wire pte_X  = pteresp.rdata[3] === 1'b1; // Executable
// U-modeでアクセスできるかどうか
// SUM=1のとき、S-modeでもアクセスできるようになる。
// SUMにかかわらず、S-modeはU=1なページを実行できない
wire pte_U  = pteresp.rdata[4] === 1'b1;
wire pte_G  = pteresp.rdata[5] === 1'b1; // Global mappingが何かわからない
// キャッシュの実装の都合上、命令用のPTWはAを変更しない。Dは元から変更されない。
wire pte_A  = pteresp.rdata[6] === 1'b1; // 最後にAが0にされてからアクセスされたかどうか
wire pte_D  = pteresp.rdata[7] === 1'b1; // 最古にDが0にされてからwriteされたかどうか

function logic is_leaf(
    input logic R,
    input logic W,
    input logic X
);
    is_leaf = R | W | X;
endfunction

/*
ページサイズでアラインされているかをチェックする。
-> アライメントされていなかったらページフォルト

non-leaf PTEのD, A, Uは将来のために予約されているので、前方互換性のためにソフトウェア的に0にする必要がある。
予約されているので、0ではない場合は、ページフォルト

LR/SCはページをまたがってはいけない

ミスアラインされたstoreは一部成功したりするかもだけど、途中で失敗しても戻さなくてもOK?

Gはとりあえず実装しないので、faultを発生させる
*/

// PPN
wire [PPN1_LEN-1:0] pte_ppn1    = pteresp.rdata[31:20];
wire [PPN0_LEN-1:0] pte_ppn0    = pteresp.rdata[19:10];
wire [PPN_LEN-1:0]  pte_ppn     = pteresp.rdata[31:10];

UIntX   last_pte = 0;
Addr    last_addr= 0;
wire [PPN1_LEN-1:0] last_pte_ppn1   = last_pte[31:20];
wire [PPN0_LEN-1:0] last_pte_ppn0   = last_pte[19:10];
wire [PPN_LEN-1:0]  last_pte_ppn    = last_pte[31:10];
wire                last_pte_R      = last_pte[1];
wire                last_pte_W      = last_pte[2];
wire                last_pte_X      = last_pte[3];
wire                last_pte_U      = last_pte[4];
wire                last_pte_G      = last_pte[5];
wire                last_pte_A      = last_pte[6];
wire                last_pte_D      = last_pte[7];


// TLB
wire tlb_req_valid = sv32_enable & (state == WAIT_TLB_READY | state == IDLE & preq.valid) & all_tlb_ready;

// TLB0 (PPN1 + PPN0)
localparam TLB0_KLEN = VPN_LEN; // pteのvpn
localparam TLB0_VLEN = PPN_LEN + PPN_LEN + 6;// PPN(paddr), PPN(PTEのアドレス用), pte(R,W,U,X,G,D)

wire                    tlb0_req_ready;
wire                    tlb0_req_valid  = tlb_req_valid;
wire [TLB0_KLEN-1:0]    tlb0_req_key    = state === IDLE ?
                                            preq.addr[XLEN - 1:XLEN - VPN_LEN] :
                                            s_req.addr[XLEN - 1:XLEN - VPN_LEN];
wire                    tlb0_resp_valid;
wire                    tlb0_resp_hit;
wire [PPN_LEN-1:0]      tlb0_resp_paddr_ppn;
wire [PPN_LEN-1:0]      tlb0_resp_pte_ppn;
wire                    tlb0_resp_pte_r;
wire                    tlb0_resp_pte_w;
wire                    tlb0_resp_pte_x;
wire                    tlb0_resp_pte_u;
wire                    tlb0_resp_pte_g;
wire                    tlb0_resp_pte_d;
logic                   tlb0_update_valid       = 0;
logic [VPN_LEN-1:0]     tlb0_update_vpn         = 0;
logic [PPN_LEN-1:0]     tlb0_update_paddr_ppn   = 0;
logic [PPN_LEN-1:0]     tlb0_update_pte_ppn     = 0;
logic                   tlb0_update_pte_r       = 0;
logic                   tlb0_update_pte_w       = 0;
logic                   tlb0_update_pte_x       = 0;
logic                   tlb0_update_pte_u       = 0;
logic                   tlb0_update_pte_g       = 0;
logic                   tlb0_update_pte_d       = 0;

MemoryKeyValueStore #(
    .KEY_WIDTH(TLB0_KLEN),
    .VAL_WIDTH(TLB0_VLEN),
    .MEM_WIDTH(10), // = 1024 適当
    .LOG_ENABLE(LOG_ENABLE && ENABLE_TLB0_LOG),
    .LOG_AS({LOG_AS, ".tlb0"})
) tlb0 (
    .clk(clk),
    .req_ready(tlb0_req_ready),
    .req_valid(tlb0_req_valid),
    .req_key(tlb0_req_key),
    .resp_valid(tlb0_resp_valid),
    .resp_hit(tlb0_resp_hit),
    .resp_value({tlb0_resp_paddr_ppn, tlb0_resp_pte_ppn, 
                tlb0_resp_pte_r,tlb0_resp_pte_w,tlb0_resp_pte_x,
                tlb0_resp_pte_u,tlb0_resp_pte_g,tlb0_resp_pte_d}),
    .update_valid(tlb0_update_valid),
    .update_key(tlb0_update_vpn),
    .update_value({tlb0_update_paddr_ppn, tlb0_update_pte_ppn,
                    tlb0_update_pte_r,tlb0_update_pte_w,tlb0_update_pte_x,
                    tlb0_update_pte_u,tlb0_update_pte_g,tlb0_update_pte_d}),
    .flush(flush_tlb)
);

// TODO TLBを待ちつつフェッチしたい
// TLB1 (PPN1 + PPN0)
localparam TLB1_KLEN = VPN1_LEN; // pteのvpn
localparam TLB1_VLEN = PPN1_LEN + 6;// PPN1(paddr), pte(R,W,U,X,G,D)

wire                    tlb1_req_ready;
wire                    tlb1_req_valid  = tlb_req_valid;
wire [TLB1_KLEN-1:0]    tlb1_req_key    = state === IDLE ?
                                            preq.addr[XLEN - 1:XLEN - VPN1_LEN] :
                                            s_req.addr[XLEN - 1:XLEN - VPN1_LEN];
wire                    tlb1_resp_valid;
wire                    tlb1_resp_hit;
wire [PPN1_LEN-1:0]     tlb1_resp_ppn1;
wire                    tlb1_resp_pte_r;
wire                    tlb1_resp_pte_w;
wire                    tlb1_resp_pte_x;
wire                    tlb1_resp_pte_u;
wire                    tlb1_resp_pte_g;
wire                    tlb1_resp_pte_d;
logic                   tlb1_update_valid   = 0;
logic [VPN1_LEN-1:0]    tlb1_update_vpn1    = 0;
logic [PPN1_LEN-1:0]    tlb1_update_ppn1    = 0;
logic                   tlb1_update_pte_r   = 0;
logic                   tlb1_update_pte_w   = 0;
logic                   tlb1_update_pte_x   = 0;
logic                   tlb1_update_pte_u   = 0;
logic                   tlb1_update_pte_g   = 0;
logic                   tlb1_update_pte_d   = 0;

MemoryKeyValueStore #(
    .KEY_WIDTH(TLB1_KLEN),
    .VAL_WIDTH(TLB1_VLEN),
    .MEM_WIDTH(10), // = 1024 適当
    .LOG_ENABLE(LOG_ENABLE && ENABLE_TLB1_LOG),
    .LOG_AS({LOG_AS, ".tlb1"})
) tlb1 (
    .clk(clk),
    .req_ready(tlb1_req_ready),
    .req_valid(tlb1_req_valid),
    .req_key(tlb1_req_key),
    .resp_valid(tlb1_resp_valid),
    .resp_hit(tlb1_resp_hit),
    .resp_value({tlb1_resp_ppn1,
                tlb1_resp_pte_r,tlb1_resp_pte_w,tlb1_resp_pte_x,
                tlb1_resp_pte_u,tlb1_resp_pte_g,tlb1_resp_pte_d}),
    .update_valid(tlb1_update_valid),
    .update_key(tlb1_update_vpn1),
    .update_value({tlb1_update_ppn1,
                    tlb1_update_pte_r,tlb1_update_pte_w,tlb1_update_pte_x,
                    tlb1_update_pte_u,tlb1_update_pte_g,tlb1_update_pte_d}),
    .flush(flush_tlb)
);

wire        all_tlb_ready           = tlb0_req_ready & tlb1_req_ready;
logic [1:0] tlbs_saved_responsed    = 0;
wire        tlbs_all_responsed      = (tlbs_saved_responsed | {tlb0_resp_valid, tlb1_resp_valid}) == 2'b11;

function logic is_page_fault(
    input logic wen,
    input logic pte_V,
    input logic pte_R,
    input logic pte_W,
    input logic pte_X,
    input logic pte_U,
    input logic pte_G,
    input logic pte_A,
    input logic pte_D,
    input csr::Mode mode,
    input logic mxr,
    input logic sum
);
    // メモリがエラー
    // Vが立っていない
    // W=1なのにR=0
    // Gが立っている
    // leafではないのにAかDが立っている
    // EXECUTE, S-modeでpte_U
    // DATA, S-modeでpte_Uかつsum = 0
    // EXECUTE, leafで、Xが立っていない
    // DATA, leftでW, Rが立っていない
    is_page_fault =
            !pte_V |
            pte_W & (!pte_R) |
            pte_G |
            !is_leaf(pte_R, pte_W, pte_X) & (pte_A | pte_D) |
            mode == S_MODE & EXECUTE_MODE & pte_U |
            mode == S_MODE & !EXECUTE_MODE & pte_U & !sum |
            is_leaf(pte_R, pte_W, pte_X) & EXECUTE_MODE & !pte_X |
            is_leaf(pte_R, pte_W, pte_X) & !EXECUTE_MODE & (wen & !pte_W | !wen & !pte_R & (!mxr | !pte_X));
endfunction

always @(posedge clk) if (reset) state <= IDLE; else if (sv32_enable) begin
    case (state)
    IDLE: begin
        tlb1_update_valid   <= 0;
        tlb0_update_valid   <= 0;
        tlbs_saved_responsed<= 0;
        if (preq.valid) begin
            if (EXECUTE_MODE & preq.wen) begin
                $display("ERROR: PTE(EXECUTE MODE) with wen=1");
                `ffinish
            end
            state       <= all_tlb_ready ? CHECK_TLB : WAIT_TLB_READY;
            s_req       <= preq;
            // 5.3.2 step 3
            level       <= 1; // level = 2 - 1 = 1スタート
            next_addr   <= {satp_ppn, idleonly_vpn1, {PTESIZE_WIDTH{1'b0}}};
        end
    end
    WAIT_TLB_READY: if (all_tlb_ready) state <= CHECK_TLB;
    CHECK_TLB: begin
        // TLBにあったら終了
        // TLBになかったらフェッチ
        if (tlb0_resp_valid)
            tlbs_saved_responsed[0] <= 1;
        if (tlb1_resp_valid)
            tlbs_saved_responsed[1] <= 1;
        if (tlb0_resp_valid & tlb0_resp_hit) begin
            if (is_page_fault(
                    s_req.wen, 1'b1,
                    tlb0_resp_pte_r, tlb0_resp_pte_w, tlb0_resp_pte_x,
                    tlb0_resp_pte_u, tlb0_resp_pte_g, 1'b1, tlb0_resp_pte_d,
                    mode, mxr, sum))
            begin
                state           <= REQ_END;
                result_error    <= 1;
                result_errty    <= FE_PAGE_FAULT;
            end else begin
                state       <= REQ_READY;
                level       <= 0;
                last_addr   <= {tlb0_resp_pte_ppn[19:0], s_vpn0, {PTESIZE_WIDTH{1'b0}}};
                last_pte    <= {tlb0_resp_paddr_ppn, 2'b0,
                                tlb0_resp_pte_d, 1'b1,
                                tlb0_resp_pte_g, tlb0_resp_pte_u,
                                tlb0_resp_pte_x, tlb0_resp_pte_w, tlb0_resp_pte_r,
                                1'b1};
                next_addr   <= {tlb0_resp_paddr_ppn, s_page_offset};
            end
        end else if (tlb1_resp_valid & tlb1_resp_hit) begin
            if (is_page_fault(
                    s_req.wen, 1'b1,
                    tlb1_resp_pte_r, tlb1_resp_pte_w, tlb1_resp_pte_x,
                    tlb1_resp_pte_u, tlb1_resp_pte_g, 1'b1, tlb1_resp_pte_d,
                    mode, mxr, sum))
            begin
                state           <= REQ_END;
                result_error    <= 1;
                result_errty    <= FE_PAGE_FAULT;
            end else begin
                state       <= REQ_READY;
                level       <= 1;
                last_addr   <= {satp_ppn[19:0], s_vpn1, {PTESIZE_WIDTH{1'b0}}};
                last_pte    <= {tlb1_resp_ppn1, 10'b0, 2'b0,
                                tlb1_resp_pte_d, 1'b1,
                                tlb1_resp_pte_g, tlb1_resp_pte_u,
                                tlb1_resp_pte_x, tlb1_resp_pte_w, tlb1_resp_pte_r,
                                1'b1};
                next_addr   <= {tlb1_resp_ppn1, s_vpn0, s_page_offset};
            end
        end else if (tlbs_all_responsed)
            state   <= WALK_READY;
    end
    WALK_READY: if (ptereq.ready) begin
        state       <= WALK_VALID;
        last_addr   <= next_addr[31:0];
    end
    WALK_VALID: if (pteresp.valid) begin
        // FAULT判定
        if (pteresp.error |
            is_page_fault(s_req.wen,pte_V,pte_R,pte_W,pte_X,pte_U,pte_G,pte_A,pte_D,mode,mxr,sum) |
            level == 2'b11 | level == 2'b10)
        begin
            state           <= REQ_END;
            result_error    <= 1;
            result_errty    <= FaultTy'(pteresp.error ? FE_ACCESS_FAULT : FE_PAGE_FAULT);
        end else if (is_leaf(pte_R, pte_W, pte_X)) begin
            // 5.3.2 step 6
            // superpageがmisalignかどうか調べる
            if (level == 2'b01 & pte_ppn0 != 0) begin
                state           <= REQ_END;
                result_error    <= 1;
                result_errty    <= FE_PAGE_FAULT;
            end else begin
                state       <= REQ_READY;
                last_pte    <= pteresp.rdata;
                // 5.3.2 step 8
                // Sv32 physical address
                // ppn[1], ppn[0], page offset
                // 12    , 10    , 12
                if (level == 2'b01)
                    next_addr <= {pte_ppn1, s_vpn0, s_page_offset};
                else
                    next_addr <= {pte_ppn, s_page_offset};
            end
        end else begin
            state   <= WALK_READY;
            // 5.3.2 step 4
            level   <= level - 2'd1;
            // 2回目は必ずvpn0
            next_addr<= {pte_ppn, s_vpn0, {PTESIZE_WIDTH{1'b0}}};
        end
    end
    // TODO READYに遷移するところですぐにreadyしてしまう
    REQ_READY: begin
        if (memreq.ready) begin
            state <= REQ_VALID;
        end
    end
    // TODO ENDと合体させる
    REQ_VALID: begin
        if (memresp.valid) begin
            state           <= REQ_END;
            result_rdata    <= memresp.rdata;
            result_error    <= memresp.error;
            result_errty    <= memresp.errty;
        end
    end
    REQ_END: begin
        if (result_error)
            state <= IDLE;
        else begin
            if (level === 1) begin
                tlb1_update_valid       <= 1;
                tlb1_update_vpn1        <= s_vpn1;
                tlb1_update_ppn1        <= last_pte_ppn1;
                tlb1_update_pte_r       <= last_pte_R;
                tlb1_update_pte_w       <= last_pte_W;
                tlb1_update_pte_x       <= last_pte_X;
                tlb1_update_pte_u       <= last_pte_U;
                tlb1_update_pte_g       <= last_pte_G;
                tlb1_update_pte_d       <= last_pte_D | s_req.wen;
            end else if (level === 0) begin
                tlb0_update_valid       <= 1;
                tlb0_update_vpn         <= s_vpn;
                tlb0_update_paddr_ppn   <= last_pte[31:10];
                tlb0_update_pte_ppn     <= {2'b0, last_addr[31:12]}; // TODO 2'b0
                tlb0_update_pte_r       <= last_pte_R;
                tlb0_update_pte_w       <= last_pte_W;
                tlb0_update_pte_x       <= last_pte_X;
                tlb0_update_pte_u       <= last_pte_U;
                tlb0_update_pte_g       <= last_pte_G;
                tlb0_update_pte_d       <= last_pte_D | s_req.wen;
            end
            // A, Dを書き込む条件がそろっている
            if (!last_pte_A | s_req.wen & !last_pte_D) begin
                state       <= WAIT_SET_AD_READY;
                next_addr   <= {2'b0, last_addr};
            end else begin
                state <= IDLE;
            end
        end
    end
    WAIT_SET_AD_READY: begin
        tlb1_update_valid <= 0;
        tlb0_update_valid <= 0;
        if (ptereq.ready) begin
            state <= IDLE;
        end
    end
    default: state <= IDLE;
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) if (LOG_ENABLE) begin
    if (sv32_enable) begin
        $display("data,%s.ptw.state,d,%b", LOG_AS, state);
        $display("data,%s.ptw.reset,b,%b", LOG_AS, reset);
        $display("data,%s.ptw.satp,h,%b", LOG_AS, satp);
        $display("data,%s.ptw.mode,d,%b", LOG_AS, mode);
        $display("data,%s.ptw.proc_pc,h,%b", LOG_AS, state == IDLE ? preq.addr : s_req.addr);
        $display("data,%s.ptw.next_addr,h,%b", LOG_AS, next_addr[31:0]);

        // if (memreq.ready & memreq.valid) begin
            $display("data,%s.ptw.memreq.ready,b,%b", LOG_AS, memreq.ready);
            $display("data,%s.ptw.memreq.valid,b,%b", LOG_AS, memreq.valid);
            $display("data,%s.ptw.memreq.addr,h,%b", LOG_AS, memreq.addr);
            $display("data,%s.ptw.memreq.wen,b,%b", LOG_AS, memreq.wen);
            $display("data,%s.ptw.memreq.wdata,h,%b", LOG_AS, memreq.wdata);
        // end
        // if (memresp.valid) begin
            $display("data,%s.ptw.memresp.valid,b,%b", LOG_AS, memresp.valid);
            $display("data,%s.ptw.memresp.error,b,%b", LOG_AS, memresp.error);
            $display("data,%s.ptw.memresp.rdata,h,%b", LOG_AS, memresp.rdata);
        // end

        // if (ptereq.ready & ptereq.valid) begin
            $display("data,%s.ptw.ptereq.ready,b,%b", LOG_AS, ptereq.ready);
            $display("data,%s.ptw.ptereq.valid,b,%b", LOG_AS, ptereq.valid);
            $display("data,%s.ptw.ptereq.addr,h,%b", LOG_AS, ptereq.addr);
            $display("data,%s.ptw.ptereq.wen,b,%b", LOG_AS, ptereq.wen);
            $display("data,%s.ptw.ptereq.wdata,h,%b", LOG_AS, ptereq.wdata);
        // end
        // if (pteresp.valid) begin
            $display("data,%s.ptw.pteresp.valid,b,%b", LOG_AS, pteresp.valid);
            $display("data,%s.ptw.pteresp.error,b,%b", LOG_AS, pteresp.error);
            $display("data,%s.ptw.pteresp.rdata,h,%b", LOG_AS, pteresp.rdata);
        // end

        $display("data,%s.ptw.level,d,%b", LOG_AS, level);
        $display("data,%s.ptw.pte.R,b,%b", LOG_AS, pte_R);
        $display("data,%s.ptw.pte.X,b,%b", LOG_AS, pte_X);
        $display("data,%s.ptw.pte.V,b,%b", LOG_AS, pte_V);

        $display("data,%s.ptw.satp.ppn,h,%b", LOG_AS, satp_ppn);
        $display("data,%s.ptw.pte.ppn[1],h,%b", LOG_AS, pte_ppn1);
        $display("data,%s.ptw.pte.ppn[0],h,%b", LOG_AS, pte_ppn0);
        $display("data,%s.ptw.pte.ppn,h,%b", LOG_AS, pte_ppn);

        $display("data,%s.ptw.vpn[1],h,%b", LOG_AS, s_vpn1);
        $display("data,%s.ptw.vpn[0],h,%b", LOG_AS, s_vpn0);

        // $display("data,%s.tlb0.resp.valid,b,%b", LOG_AS, tlb0_resp_valid);
        // $display("data,%s.tlb0.resp.hit,b,%b", LOG_AS, tlb0_resp_hit);
        // $display("data,%s.tlb1.resp.valid,b,%b", LOG_AS, tlb1_resp_valid);
        // $display("data,%s.tlb1.resp.hit,b,%b", LOG_AS, tlb1_resp_hit);
    end
end
`endif

endmodule