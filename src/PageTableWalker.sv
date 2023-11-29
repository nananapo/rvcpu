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
import Sv32::*;

localparam ENABLE_L2_TLB0_LOG = 0;
localparam ENABLE_L2_TLB1_LOG = 0;

function logic is_leaf(
    input logic R,
    input logic W,
    input logic X
);
    return R | W | X;
endfunction

function Addr gen_l1pte_addr(input VPN1 vpn1); // TODO satp_ppn
    return {satp_ppn[PPN_LEN-2-1:0], vpn1, {PTESIZE_WIDTH{1'b0}}};
endfunction

function Addr gen_l0pte_addr(
    input PPN     ppn,
    input VPN0    vpn0
);
    return {ppn[PPN_LEN-2-1:0], vpn0, {PTESIZE_WIDTH{1'b0}}};
endfunction

function Addr gen_l1_paddr(
    input PPN1    ppn1,
    input VPN0    vpn_0,
    input Pgoff   pgoff
);
    return {ppn1[PPN1_LEN-2-1:0], vpn_0, pgoff};
endfunction

function Addr gen_l0_paddr(
    input PPN     ppn,
    input Pgoff   pgoff
);
    return {ppn[PPN_LEN-2-1:0], pgoff};
endfunction

function logic is_page_fault(
    input logic wen,
    input logic v,r,w,x,u,g,a,d,
    input csr::Mode mode,
    input logic mxr,
    input logic sum
);
    // Vが立っていない
    // W=1なのにR=0
    // Gが立っている
    // leafではないのにAかDが立っている
    // EXECUTE, S-modeでpte_U
    // DATA, S-modeでpte_Uかつsum = 0
    // EXECUTE, leafで、Xが立っていない
    // DATA, leftでW, Rが立っていない
    return !v |
            w & (!r) |
            g |
            !is_leaf(r, w, x) & (a | d) |
            mode == S_MODE & EXECUTE_MODE & u |
            mode == S_MODE & !EXECUTE_MODE & u & !sum |
            is_leaf(r, w, x) & EXECUTE_MODE & !x |
            is_leaf(r, w, x) & !EXECUTE_MODE & (wen & !w | !wen & !r & (!mxr | !x));
endfunction

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
    WAIT_L1_READY,
    WAIT_L2_TLB_READY,
    CHECK_L2_TLB,
    WALK_READY,
    WALK_VALID,
    REQ_READY,
    REQ_VALID,
    REQ_END,
    WAIT_SET_AD_READY
} statetype;

wire        satp_mode   = satp[31];
wire [8:0]  satp_asid   = satp[30:22];
wire PPN    satp_ppn    = satp[21:0];

statetype   state       = IDLE;
wire        sv32_enable = mode != M_MODE & satp_mode == 1;

logic       result_error    = 0;
FaultTy     result_errty    = FE_ACCESS_FAULT;
logic       result_is_mmio  = 1'bx;

// stateはIDLEだがvalid待ちであるかどうか
// PTWはIDLEかつL1 TLBがhitした時にidle_with_wait_validを1にする。
// このフラグによってresp.validをprespに届けることができるようになる
logic   idle_with_wait_valid = 0;
wire    is_idle = state == IDLE & (!idle_with_wait_valid | memresp.valid);

wire can_use_l1_tlb0 = l1_tlb0_resp_hit & !l1_tlb0_is_page_fault;
wire can_use_l1_tlb1 = l1_tlb1_resp_hit & !l1_tlb1_is_page_fault;

assign preq.ready   = sv32_enable ? is_idle : memreq.ready;
assign presp.valid  = sv32_enable ? state == REQ_END | (state == IDLE & idle_with_wait_valid & memresp.valid) : memresp.valid;
assign presp.error  = sv32_enable ? (state == IDLE ? memresp.error : result_error) : memresp.error;
assign presp.errty  = sv32_enable ? (state == IDLE ? memresp.errty : result_errty) : memresp.errty;
assign presp.is_mmio= sv32_enable ? (state == IDLE ? memresp.is_mmio : result_is_mmio) : memresp.is_mmio;
assign presp.rdata  = sv32_enable ? (state == IDLE ? memresp.rdata : result_rdata) : memresp.rdata;

assign memreq.valid = sv32_enable ? state == REQ_READY | state == WAIT_L1_READY | (state == IDLE & (
    (can_use_l1_tlb0 | can_use_l1_tlb1) & preq.valid & (!idle_with_wait_valid | memresp.valid) // tlbが使えて、preq.validで、validをwait中の場合はmemresp.validのとき
    )) : preq.valid;
assign memreq.addr  = sv32_enable ? (state == IDLE ? (
        can_use_l1_tlb0 ?
            gen_l0_paddr(l1_tlb0_resp_paddr_ppn, vaddr.pgoff) :
            gen_l1_paddr(l1_tlb1_resp_ppn1, vaddr.vpn0, vaddr.pgoff)
        ) : next_addr) : preq.addr;
assign memreq.wen   = sv32_enable ? (state == IDLE ? preq.wen : s_req.wen) : preq.wen;
assign memreq.wdata = sv32_enable ? (state == IDLE ? preq.wdata : s_req.wdata) : preq.wdata;
assign memreq.wmask = sv32_enable ? (state == IDLE ? preq.wmask : s_req.wmask) : preq.wmask;
assign memreq.pte   = PTE_AD'(2'b00);

assign ptereq.valid = state == WALK_READY | state == WAIT_SET_AD_READY;
assign ptereq.addr  = next_addr;
assign ptereq.wen   = 0;
assign ptereq.wdata = 0;
assign ptereq.wmask = 4'b0000;
assign ptereq.pte   = PTE_AD'({state == WAIT_SET_AD_READY, state == WAIT_SET_AD_READY & s_req.wen}); // A & D

CacheReq        s_req;          // preqがリクエストしたアドレス
logic [1:0]     level;          // ページのレベル
Addr            next_addr;      // 次にアクセスするアドレス
logic [31:0]    result_rdata;   // 結果

VAddr   n_vaddr(preq.addr);
VAddr   s_vaddr(s_req.addr);
VAddr   vaddr(state == IDLE ? preq.addr : s_req.addr);

UIntX   saved_pte_data = 0;
Addr    saved_pte_addr = 0;
PTE     resp_pte(pteresp.rdata);
PTE     last_pte(saved_pte_data);

/*
ページサイズでアラインされているかをチェックする。
-> アライメントされていなかったらページフォルト

non-leaf PTEのD, A, Uは将来のために予約されているので、前方互換性のためにソフトウェア的に0にする必要がある。
予約されているので、0ではない場合は、ページフォルト

LR/SCはページをまたがってはいけない

ミスアラインされたstoreは一部成功したりするかもだけど、途中で失敗しても戻さなくてもOK?

Gはとりあえず実装しないので、faultを発生させる
*/

// TODO updateのワイヤ化
// TODO pteの更新のFIFO化

// L1 TLB 0
localparam L1_TLB0_KLEN = VPN_LEN; // pteのvpn
localparam L1_TLB0_VLEN = PPN_LEN + PPN_LEN + 6;// PPN(paddr), PPN(PTEのアドレス用), pte(R,W,U,X,G,D)


wire VPN    l1_tlb0_req_vpn    = vaddr.vpn;
wire        l1_tlb0_resp_hit;
wire PPN    l1_tlb0_resp_paddr_ppn;
wire PPN    l1_tlb0_resp_pte_ppn;
wire        l1_tlb0_resp_pte_r;
wire        l1_tlb0_resp_pte_w;
wire        l1_tlb0_resp_pte_x;
wire        l1_tlb0_resp_pte_u;
wire        l1_tlb0_resp_pte_g;
wire        l1_tlb0_resp_pte_d;
logic       l1_tlb0_update_valid       = 0;
VPN         l1_tlb0_update_vpn         = 0;
PPN         l1_tlb0_update_paddr_ppn   = 0;
PPN         l1_tlb0_update_pte_ppn     = 0;
logic       l1_tlb0_update_pte_r       = 0;
logic       l1_tlb0_update_pte_w       = 0;
logic       l1_tlb0_update_pte_x       = 0;
logic       l1_tlb0_update_pte_u       = 0;
logic       l1_tlb0_update_pte_g       = 0;
logic       l1_tlb0_update_pte_d       = 0;

CombinationalKeyValueStore #(
    .KEY_WIDTH(L1_TLB0_KLEN),
    .VAL_WIDTH(L1_TLB0_VLEN),
    .MEM_WIDTH(5) // 適当
) l1_tlb0 (
    .clk(clk),
    .reset(flush_tlb),
    .key(l1_tlb0_req_vpn),
    .hit(l1_tlb0_resp_hit),
    .value({l1_tlb0_resp_paddr_ppn, l1_tlb0_resp_pte_ppn,
            l1_tlb0_resp_pte_r, l1_tlb0_resp_pte_w, l1_tlb0_resp_pte_x,
            l1_tlb0_resp_pte_u, l1_tlb0_resp_pte_g, l1_tlb0_resp_pte_d}),
    .update_valid(l1_tlb0_update_valid),
    .update_key(l1_tlb0_update_vpn),
    .update_value( {l1_tlb0_update_paddr_ppn, l1_tlb0_update_pte_ppn,
                    l1_tlb0_update_pte_r, l1_tlb0_update_pte_w, l1_tlb0_update_pte_x,
                    l1_tlb0_update_pte_u, l1_tlb0_update_pte_g, l1_tlb0_update_pte_d})
);

wire l1_tlb0_is_page_fault = is_page_fault(preq.wen, 1'b1,
                                            l1_tlb0_resp_pte_r, l1_tlb0_resp_pte_w, l1_tlb0_resp_pte_x,
                                            l1_tlb0_resp_pte_u, l1_tlb0_resp_pte_g, 1'b1, l1_tlb0_resp_pte_d,
                                            mode, mxr, sum);

// L1 TLB1 (PPN1 + PPN0)
localparam l1_TLB1_KLEN = VPN1_LEN; // pteのvpn
localparam l1_TLB1_VLEN = PPN1_LEN + 6;// PPN1(paddr), pte(R,W,U,X,G,D)

wire VPN1   l1_tlb1_req_vpn1   = vaddr.vpn1;
wire        l1_tlb1_resp_hit;
wire PPN1   l1_tlb1_resp_ppn1;
wire        l1_tlb1_resp_pte_r;
wire        l1_tlb1_resp_pte_w;
wire        l1_tlb1_resp_pte_x;
wire        l1_tlb1_resp_pte_u;
wire        l1_tlb1_resp_pte_g;
wire        l1_tlb1_resp_pte_d;
logic       l1_tlb1_update_valid   = 0;
VPN1        l1_tlb1_update_vpn1    = 0;
PPN1        l1_tlb1_update_ppn1    = 0;
logic       l1_tlb1_update_pte_r   = 0;
logic       l1_tlb1_update_pte_w   = 0;
logic       l1_tlb1_update_pte_x   = 0;
logic       l1_tlb1_update_pte_u   = 0;
logic       l1_tlb1_update_pte_g   = 0;
logic       l1_tlb1_update_pte_d   = 0;

CombinationalKeyValueStore #(
    .KEY_WIDTH(l1_TLB1_KLEN),
    .VAL_WIDTH(l1_TLB1_VLEN),
    .MEM_WIDTH(5) // 適当
) l1_tlb1 (
    .clk(clk),
    .reset(flush_tlb),
    .key(l1_tlb1_req_vpn1),
    .hit(l1_tlb1_resp_hit),
    .value({l1_tlb1_resp_ppn1,
            l1_tlb1_resp_pte_r, l1_tlb1_resp_pte_w, l1_tlb1_resp_pte_x,
            l1_tlb1_resp_pte_u, l1_tlb1_resp_pte_g, l1_tlb1_resp_pte_d}),
    .update_valid(l1_tlb1_update_valid),
    .update_key(l1_tlb1_update_vpn1),
    .update_value({ l1_tlb1_update_ppn1,
                    l1_tlb1_update_pte_r, l1_tlb1_update_pte_w, l1_tlb1_update_pte_x,
                    l1_tlb1_update_pte_u, l1_tlb1_update_pte_g, l1_tlb1_update_pte_d})
);

wire l1_tlb1_is_page_fault = is_page_fault(preq.wen, 1'b1,
                                            l1_tlb1_resp_pte_r, l1_tlb1_resp_pte_w, l1_tlb1_resp_pte_x,
                                            l1_tlb1_resp_pte_u, l1_tlb1_resp_pte_g, 1'b1, l1_tlb1_resp_pte_d,
                                            mode, mxr, sum);

// L2 TLB
wire l2_tlb_req_valid = sv32_enable & (state == WAIT_L2_TLB_READY | state == IDLE & preq.valid) & all_l2_tlb_ready;

// L2 TLB0 (PPN1 + PPN0)
localparam L2_TLB0_KLEN = VPN_LEN; // pteのvpn
localparam L2_TLB0_VLEN = PPN_LEN + PPN_LEN + 6;// PPN(paddr), PPN(PTEのアドレス用), pte(R,W,U,X,G,D)

wire        l2_tlb0_req_ready;
wire        l2_tlb0_req_valid  = l2_tlb_req_valid;
wire VPN    l2_tlb0_req_vpn    = vaddr.vpn;
wire        l2_tlb0_resp_valid;
wire        l2_tlb0_resp_hit;
wire PPN    l2_tlb0_resp_paddr_ppn;
wire PPN    l2_tlb0_resp_pte_ppn;
wire        l2_tlb0_resp_pte_r;
wire        l2_tlb0_resp_pte_w;
wire        l2_tlb0_resp_pte_x;
wire        l2_tlb0_resp_pte_u;
wire        l2_tlb0_resp_pte_g;
wire        l2_tlb0_resp_pte_d;
logic       l2_tlb0_update_valid       = 0;
VPN         l2_tlb0_update_vpn         = 0;
PPN         l2_tlb0_update_paddr_ppn   = 0;
PPN         l2_tlb0_update_pte_ppn     = 0;
logic       l2_tlb0_update_pte_r       = 0;
logic       l2_tlb0_update_pte_w       = 0;
logic       l2_tlb0_update_pte_x       = 0;
logic       l2_tlb0_update_pte_u       = 0;
logic       l2_tlb0_update_pte_g       = 0;
logic       l2_tlb0_update_pte_d       = 0;

MemoryKeyValueStore #(
    .KEY_WIDTH(L2_TLB0_KLEN),
    .VAL_WIDTH(L2_TLB0_VLEN),
    .MEM_WIDTH(10), // = 1024 適当
    .LOG_ENABLE(LOG_ENABLE && ENABLE_L2_TLB0_LOG),
    .LOG_AS({LOG_AS, ".tlb0"})
) l2_tlb0 (
    .clk(clk),
    .reset(flush_tlb),
    .req_ready(l2_tlb0_req_ready),
    .req_valid(l2_tlb0_req_valid),
    .req_key(l2_tlb0_req_vpn),
    .resp_valid(l2_tlb0_resp_valid),
    .resp_hit(l2_tlb0_resp_hit),
    .resp_value({   l2_tlb0_resp_paddr_ppn, l2_tlb0_resp_pte_ppn,
                    l2_tlb0_resp_pte_r, l2_tlb0_resp_pte_w, l2_tlb0_resp_pte_x,
                    l2_tlb0_resp_pte_u, l2_tlb0_resp_pte_g, l2_tlb0_resp_pte_d}),
    .update_valid(l2_tlb0_update_valid),
    .update_key(l2_tlb0_update_vpn),
    .update_value({ l2_tlb0_update_paddr_ppn, l2_tlb0_update_pte_ppn,
                    l2_tlb0_update_pte_r, l2_tlb0_update_pte_w, l2_tlb0_update_pte_x,
                    l2_tlb0_update_pte_u, l2_tlb0_update_pte_g, l2_tlb0_update_pte_d})
);

// TODO TLBを待ちつつフェッチしたい
// L2 TLB1 (PPN1 + PPN0)
localparam l2_TLB1_KLEN = VPN1_LEN; // pteのvpn
localparam l2_TLB1_VLEN = PPN1_LEN + 6;// PPN1(paddr), pte(R,W,U,X,G,D)

wire        l2_tlb1_req_ready;
wire        l2_tlb1_req_valid  = l2_tlb_req_valid;
wire VPN1   l2_tlb1_req_vpn1   = vaddr.vpn1;
wire        l2_tlb1_resp_valid;
wire        l2_tlb1_resp_hit;
wire PPN1   l2_tlb1_resp_ppn1;
wire        l2_tlb1_resp_pte_r;
wire        l2_tlb1_resp_pte_w;
wire        l2_tlb1_resp_pte_x;
wire        l2_tlb1_resp_pte_u;
wire        l2_tlb1_resp_pte_g;
wire        l2_tlb1_resp_pte_d;
logic       l2_tlb1_update_valid   = 0;
VPN1        l2_tlb1_update_vpn1    = 0;
PPN1        l2_tlb1_update_ppn1    = 0;
logic       l2_tlb1_update_pte_r   = 0;
logic       l2_tlb1_update_pte_w   = 0;
logic       l2_tlb1_update_pte_x   = 0;
logic       l2_tlb1_update_pte_u   = 0;
logic       l2_tlb1_update_pte_g   = 0;
logic       l2_tlb1_update_pte_d   = 0;

MemoryKeyValueStore #(
    .KEY_WIDTH(l2_TLB1_KLEN),
    .VAL_WIDTH(l2_TLB1_VLEN),
    .MEM_WIDTH(10), // = 1024 適当
    .LOG_ENABLE(LOG_ENABLE && ENABLE_L2_TLB1_LOG),
    .LOG_AS({LOG_AS, ".tlb1"})
) l2_tlb1 (
    .clk(clk),
    .reset(flush_tlb),
    .req_ready(l2_tlb1_req_ready),
    .req_valid(l2_tlb1_req_valid),
    .req_key(l2_tlb1_req_vpn1),
    .resp_valid(l2_tlb1_resp_valid),
    .resp_hit(l2_tlb1_resp_hit),
    .resp_value({   l2_tlb1_resp_ppn1,
                    l2_tlb1_resp_pte_r, l2_tlb1_resp_pte_w, l2_tlb1_resp_pte_x,
                    l2_tlb1_resp_pte_u, l2_tlb1_resp_pte_g, l2_tlb1_resp_pte_d}),
    .update_valid(l2_tlb1_update_valid),
    .update_key(l2_tlb1_update_vpn1),
    .update_value({ l2_tlb1_update_ppn1,
                    l2_tlb1_update_pte_r, l2_tlb1_update_pte_w, l2_tlb1_update_pte_x,
                    l2_tlb1_update_pte_u, l2_tlb1_update_pte_g, l2_tlb1_update_pte_d})
);

wire        all_l2_tlb_ready           = l2_tlb0_req_ready & l2_tlb1_req_ready;
logic [1:0] l2_tlbs_saved_responsed    = 0;
wire        l2_tlbs_all_responsed      = (l2_tlbs_saved_responsed | {l2_tlb0_resp_valid, l2_tlb1_resp_valid}) == 2'b11;

always @(posedge clk) if (reset) begin
        state <= IDLE;
        idle_with_wait_valid <= 0;
    end else if (sv32_enable) begin
    case (state)
    IDLE: begin
        l1_tlb1_update_valid    <= 0;
        l1_tlb0_update_valid    <= 0;
        l2_tlb1_update_valid    <= 0;
        l2_tlb0_update_valid    <= 0;
        l2_tlbs_saved_responsed <= 0;

        if (preq.valid & is_idle) begin
            s_req <= preq;
            if (EXECUTE_MODE & preq.wen) begin
                $fatal(1, "PTW(EXECUTE MODE) with wen=1");
                `ffinish
            end
            if (l1_tlb1_resp_hit | l1_tlb0_resp_hit) begin
                if (l1_tlb1_resp_hit & l1_tlb1_is_page_fault | l1_tlb0_resp_hit & l1_tlb0_is_page_fault) begin
                    // TODO エラーに移行する処理をfunction化する
                    state           <= REQ_END;
                    result_error    <= 1;
                    result_errty    <= FE_PAGE_FAULT;
                    result_is_mmio  <= 0;
                    idle_with_wait_valid    <= 0;
                end else if (l1_tlb1_resp_hit) begin
                    result_is_mmio  <= 1'bx;
                    next_addr <= gen_l1_paddr(l1_tlb1_resp_ppn1, vaddr.vpn0, vaddr.pgoff);
                    // 書き込みかつdが立っていないときは、結果を確認する
                    if (preq.wen & !(l1_tlb1_resp_pte_d === 1'b1)) begin
                        idle_with_wait_valid    <= 0;
                        // PTE.d書き込みに移動
                        state           <= memreq.ready ? REQ_VALID : REQ_READY;
                        level           <= 1;
                        saved_pte_addr  <= gen_l1pte_addr(vaddr.vpn1);
                        saved_pte_data  <= {l1_tlb1_resp_ppn1, {PPN0_LEN{1'b0}},
                                            2'b0, l1_tlb1_resp_pte_d, 1'b1,
                                            l1_tlb1_resp_pte_g, l1_tlb1_resp_pte_u,
                                            l1_tlb1_resp_pte_x, l1_tlb1_resp_pte_w, l1_tlb1_resp_pte_r, 1'b1};
                    end else begin
                        // それ以外の場合は、validを確認するまでs_reqを保持しておく
                        idle_with_wait_valid <= 1;
                        if (!memreq.ready) state <= WAIT_L1_READY;
                    end
                end else /*if (l1_tlb0_resp_hit)*/ begin
                    result_is_mmio  <= 1'bx;
                    // READYではなかった時のためにnext_addrを保存する
                    next_addr <= gen_l0_paddr(l1_tlb0_resp_paddr_ppn, vaddr.pgoff);
                    // 書き込みかつdが立っていないときは、結果を確認する
                    if (preq.wen & !(l1_tlb0_resp_pte_d === 1'b1)) begin
                        idle_with_wait_valid    <= 0;
                        // PTE.d書き込みに移動
                        state           <= memreq.ready ? REQ_VALID : REQ_READY;
                        level           <= 1;
                        saved_pte_addr  <= gen_l0pte_addr(l1_tlb0_resp_pte_ppn, vaddr.vpn0);
                        saved_pte_data  <= {l1_tlb0_resp_paddr_ppn,
                                            2'b0, l1_tlb0_resp_pte_d, 1'b1,
                                            l1_tlb0_resp_pte_g, l1_tlb0_resp_pte_u,
                                            l1_tlb0_resp_pte_x, l1_tlb0_resp_pte_w, l1_tlb0_resp_pte_r, 1'b1};
                    end else begin
                        // それ以外の場合は、validを確認するまでs_reqを保持しておく
                        idle_with_wait_valid <= 1;
                        if (!memreq.ready) state <= WAIT_L1_READY;
                    end
                end
            end else begin
                // TODO function化
                state   <= all_l2_tlb_ready ? CHECK_L2_TLB : WAIT_L2_TLB_READY;
                level   <= 1; // level = 2 - 1 = 1スタート
                idle_with_wait_valid    <= 0;
                result_is_mmio          <= 1'bx;
            end
        end else begin
            if (idle_with_wait_valid & memresp.valid) begin
                idle_with_wait_valid <= 0;
            end
        end
    end
    WAIT_L1_READY: if (memreq.ready) state <= IDLE;
    WAIT_L2_TLB_READY: if (all_l2_tlb_ready) state <= CHECK_L2_TLB;
    CHECK_L2_TLB: begin
        // TLBにあったら終了
        // TLBになかったらフェッチ
        if (l2_tlb1_resp_valid)
            l2_tlbs_saved_responsed[1] <= 1;
        if (l2_tlb0_resp_valid)
            l2_tlbs_saved_responsed[0] <= 1;
        if (l2_tlb1_resp_valid & l2_tlb1_resp_hit) begin
            if (is_page_fault(
                    s_req.wen, 1'b1,
                    l2_tlb1_resp_pte_r, l2_tlb1_resp_pte_w, l2_tlb1_resp_pte_x,
                    l2_tlb1_resp_pte_u, l2_tlb1_resp_pte_g, 1'b1, l2_tlb1_resp_pte_d,
                    mode, mxr, sum))
            begin
                state           <= REQ_END;
                result_error    <= 1;
                result_errty    <= FE_PAGE_FAULT;
            end else begin
                state           <= REQ_READY;
                level           <= 1;
                saved_pte_addr  <= gen_l1pte_addr(s_vaddr.vpn1);
                saved_pte_data  <= {l2_tlb1_resp_ppn1, {PPN0_LEN{1'b0}},
                                    2'b0, l2_tlb1_resp_pte_d, 1'b1,
                                    l2_tlb1_resp_pte_g, l2_tlb1_resp_pte_u,
                                    l2_tlb1_resp_pte_x, l2_tlb1_resp_pte_w, l2_tlb1_resp_pte_r, 1'b1};
                next_addr       <= gen_l1_paddr(l2_tlb1_resp_ppn1, s_vaddr.vpn0, s_vaddr.pgoff);
            end
        end else if (l2_tlb0_resp_valid & l2_tlb0_resp_hit) begin
            if (is_page_fault(
                    s_req.wen, 1'b1,
                    l2_tlb0_resp_pte_r, l2_tlb0_resp_pte_w, l2_tlb0_resp_pte_x,
                    l2_tlb0_resp_pte_u, l2_tlb0_resp_pte_g, 1'b1, l2_tlb0_resp_pte_d,
                    mode, mxr, sum))
            begin
                state           <= REQ_END;
                result_error    <= 1;
                result_errty    <= FE_PAGE_FAULT;
            end else begin
                state           <= REQ_READY;
                level           <= 0;
                saved_pte_addr  <= gen_l0pte_addr(l2_tlb0_resp_pte_ppn, s_vaddr.vpn0);
                saved_pte_data  <= {l2_tlb0_resp_paddr_ppn,
                                    2'b0, l2_tlb0_resp_pte_d, 1'b1,
                                    l2_tlb0_resp_pte_g, l2_tlb0_resp_pte_u,
                                    l2_tlb0_resp_pte_x, l2_tlb0_resp_pte_w, l2_tlb0_resp_pte_r, 1'b1};
                next_addr       <= gen_l0_paddr(l2_tlb0_resp_paddr_ppn, s_vaddr.pgoff);
            end
        end else if (l2_tlbs_all_responsed) begin
            state       <= WALK_READY;
            next_addr   <= gen_l1pte_addr(s_vaddr.vpn1);
        end
    end
    WALK_READY: if (ptereq.ready) begin
        state           <= WALK_VALID;
        saved_pte_addr  <= next_addr;
    end
    WALK_VALID: if (pteresp.valid) begin
        // FAULT判定
        if (pteresp.error |
            is_page_fault(  s_req.wen,
                            resp_pte.v, resp_pte.r, resp_pte.w, resp_pte.x,
                            resp_pte.u, resp_pte.g, resp_pte.a, resp_pte.d,
                            mode, mxr, sum) |
            level == 2'b11 | level == 2'b10)
        begin
            state           <= REQ_END;
            result_error    <= 1;
            result_errty    <= FaultTy'(pteresp.error ? FE_ACCESS_FAULT : FE_PAGE_FAULT);
        end else if (resp_pte.is_leaf) begin
            // 5.3.2 step 6
            // superpageがmisalignかどうか調べる
            if (level == 2'b01 & resp_pte.ppn0 != 0) begin
                state           <= REQ_END;
                result_error    <= 1;
                result_errty    <= FE_PAGE_FAULT;
            end else begin
                state           <= REQ_READY;
                saved_pte_data  <= pteresp.rdata;
                // 5.3.2 step 8
                // Sv32 physical address
                // ppn[1], ppn[0], page offset
                // 12    , 10    , 12
                if (level == 2'b01)
                    next_addr <= gen_l1_paddr(resp_pte.ppn1, s_vaddr.vpn0, s_vaddr.pgoff);
                else
                    next_addr <= gen_l0_paddr(resp_pte.ppn, s_vaddr.pgoff);
            end
        end else begin
            // 5.3.2 step 4
            state       <= WALK_READY;
            level       <= level - 2'd1;
            next_addr   <= gen_l0pte_addr(resp_pte.ppn, s_vaddr.vpn0);
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
            result_is_mmio  <= memresp.is_mmio;
        end
    end
    REQ_END: begin
        if (result_error)
            state <= IDLE;
        else begin
            if (level === 1) begin
                // l1
                l1_tlb1_update_valid       <= 1;
                l1_tlb1_update_vpn1        <= s_vaddr.vpn1;
                l1_tlb1_update_ppn1        <= last_pte.ppn1;
                l1_tlb1_update_pte_r       <= last_pte.r;
                l1_tlb1_update_pte_w       <= last_pte.w;
                l1_tlb1_update_pte_x       <= last_pte.x;
                l1_tlb1_update_pte_u       <= last_pte.u;
                l1_tlb1_update_pte_g       <= last_pte.g;
                l1_tlb1_update_pte_d       <= last_pte.d | s_req.wen;
                // l2
                l2_tlb1_update_valid       <= 1;
                l2_tlb1_update_vpn1        <= s_vaddr.vpn1;
                l2_tlb1_update_ppn1        <= last_pte.ppn1;
                l2_tlb1_update_pte_r       <= last_pte.r;
                l2_tlb1_update_pte_w       <= last_pte.w;
                l2_tlb1_update_pte_x       <= last_pte.x;
                l2_tlb1_update_pte_u       <= last_pte.u;
                l2_tlb1_update_pte_g       <= last_pte.g;
                l2_tlb1_update_pte_d       <= last_pte.d | s_req.wen;
            end else if (level === 0) begin
                // l1
                l1_tlb0_update_valid       <= 1;
                l1_tlb0_update_vpn         <= s_vaddr.vpn;
                l1_tlb0_update_paddr_ppn   <= last_pte.ppn;
                l1_tlb0_update_pte_ppn     <= {2'b0, saved_pte_addr[31:12]};
                l1_tlb0_update_pte_r       <= last_pte.r;
                l1_tlb0_update_pte_w       <= last_pte.w;
                l1_tlb0_update_pte_x       <= last_pte.x;
                l1_tlb0_update_pte_u       <= last_pte.u;
                l1_tlb0_update_pte_g       <= last_pte.g;
                l1_tlb0_update_pte_d       <= last_pte.d | s_req.wen;
                // l2
                l2_tlb0_update_valid       <= 1;
                l2_tlb0_update_vpn         <= s_vaddr.vpn;
                l2_tlb0_update_paddr_ppn   <= last_pte.ppn;
                l2_tlb0_update_pte_ppn     <= {2'b0, saved_pte_addr[31:12]};
                l2_tlb0_update_pte_r       <= last_pte.r;
                l2_tlb0_update_pte_w       <= last_pte.w;
                l2_tlb0_update_pte_x       <= last_pte.x;
                l2_tlb0_update_pte_u       <= last_pte.u;
                l2_tlb0_update_pte_g       <= last_pte.g;
                l2_tlb0_update_pte_d       <= last_pte.d | s_req.wen;
            end
            // A, Dを書き込む条件がそろっている
            if (!last_pte.a | s_req.wen & !last_pte.d) begin
                state       <= WAIT_SET_AD_READY;
                next_addr   <= saved_pte_addr;
            end else begin
                state <= IDLE;
            end
        end
    end
    WAIT_SET_AD_READY: begin
        l1_tlb1_update_valid <= 0;
        l1_tlb0_update_valid <= 0;
        l2_tlb1_update_valid <= 0;
        l2_tlb0_update_valid <= 0;
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
        $display("data,%s.ptw.csr_mode,d,%b", LOG_AS, mode);
        $display("data,%s.ptw.satp,h,%b", LOG_AS, satp);
        $display("data,%s.ptw.satp.ppn,h,%b", LOG_AS, satp_ppn);
        $display("data,%s.ptw.proc.addr,h,%b", LOG_AS, state == IDLE ? preq.addr : s_req.addr);
        $display("data,%s.ptw.proc.vpn[1],h,%b", LOG_AS, vaddr.vpn1);
        $display("data,%s.ptw.proc.vpn[0],h,%b", LOG_AS, vaddr.vpn0);
        $display("data,%s.ptw.level,d,%b", LOG_AS, level);
        $display("data,%s.ptw.next_addr,h,%b", LOG_AS, next_addr);
        $display("data,%s.ptw.pte.DAGUXWRV,b,%b", LOG_AS, resp_pte.pte[7:0]);
        $display("data,%s.ptw.pte.ppn[1],h,%b", LOG_AS, resp_pte.ppn1);
        $display("data,%s.ptw.pte.ppn[0],h,%b", LOG_AS, resp_pte.ppn0);
        $display("data,%s.ptw.pte.ppn,h,%b", LOG_AS, resp_pte.ppn);

        $display("data,%s.ptw.ptereq.ready,b,%b", LOG_AS, ptereq.ready);
        $display("data,%s.ptw.ptereq.valid,b,%b", LOG_AS, ptereq.valid);
        $display("data,%s.ptw.ptereq.addr,h,%b", LOG_AS, ptereq.addr);
        $display("data,%s.ptw.ptereq.pte,h,%b", LOG_AS, ptereq.pte);
        $display("data,%s.ptw.pteresp.valid,b,%b", LOG_AS, pteresp.valid);
        $display("data,%s.ptw.pteresp.error,b,%b", LOG_AS, pteresp.error);
        $display("data,%s.ptw.pteresp.rdata,h,%b", LOG_AS, pteresp.rdata);

        $display("data,%s.ptw.memreq.ready,b,%b", LOG_AS, memreq.ready);
        $display("data,%s.ptw.memreq.valid,b,%b", LOG_AS, memreq.valid);
        $display("data,%s.ptw.memreq.addr,h,%b", LOG_AS, memreq.addr);
        $display("data,%s.ptw.memreq.wen,b,%b", LOG_AS, memreq.wen);
        $display("data,%s.ptw.memreq.wdata,h,%b", LOG_AS, memreq.wdata);
        $display("data,%s.ptw.memresp.valid,b,%b", LOG_AS, memresp.valid);
        $display("data,%s.ptw.memresp.error,b,%b", LOG_AS, memresp.error);
        $display("data,%s.ptw.memresp.rdata,h,%b", LOG_AS, memresp.rdata);
    end
end
`endif

endmodule