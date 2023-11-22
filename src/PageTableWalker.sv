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

function logic is_leaf(
    input logic R,
    input logic W,
    input logic X
);
    is_leaf = R | W | X;
endfunction

function Addr gen_l1pte_addr(input VPN1 vpn1);
    gen_l1pte_addr = {satp_ppn[PPN_LEN-2-1:0], vpn1, {PTESIZE_WIDTH{1'b0}}};
endfunction

function Addr gen_l0pte_addr(
    input PPN     ppn,
    input VPN0    vpn0
);
    gen_l0pte_addr = {ppn[PPN_LEN-2-1:0], vpn0, {PTESIZE_WIDTH{1'b0}}};
endfunction

function Addr gen_l1_paddr(
    input PPN1    ppn1,
    input VPN0    vpn_0,
    input Pgoff   pgoff
);
    gen_l1_paddr = {ppn1[PPN1_LEN-2-1:0], vpn_0, pgoff};
endfunction

function Addr gen_l0_paddr(
    input PPN     ppn,
    input Pgoff   pgoff
);
    gen_l0_paddr = {ppn[PPN_LEN-2-1:0], pgoff};
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
    is_page_fault =
            !v |
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
    WAIT_TLB_READY,
    CHECK_TLB,
    WALK_READY,
    WALK_VALID,
    REQ_READY,
    REQ_VALID,
    REQ_END,
    WAIT_SET_AD_READY
} statetype;

wire        satp_mode    = satp[31];
wire [8:0]  satp_asid    = satp[30:22];
wire PPN    satp_ppn     = satp[21:0];

statetype   state  = IDLE;
wire        sv32_enable = mode != M_MODE & satp_mode == 1;

logic       result_error = 0;
FaultTy     result_errty = FE_ACCESS_FAULT;

assign preq.ready   = sv32_enable ? state == IDLE       : memreq.ready;
assign presp.valid  = sv32_enable ? state == REQ_END    : memresp.valid;
assign presp.rdata  = sv32_enable ? result_rdata        : memresp.rdata;
assign presp.error  = sv32_enable ? result_error        : memresp.error;
assign presp.errty  = sv32_enable ? result_errty        : memresp.errty;

assign memreq.valid = sv32_enable ? state == REQ_READY  : preq.valid;
assign memreq.addr  = sv32_enable ? next_addr           : preq.addr;
assign memreq.wen   = sv32_enable ? s_req.wen           : preq.wen;
assign memreq.wdata = sv32_enable ? s_req.wdata         : preq.wdata;
assign memreq.wmask = sv32_enable ? s_req.wmask         : preq.wmask;
assign memreq.pte   = PTE_AD'(2'b00);

assign ptereq.valid = state == WALK_READY | state == WAIT_SET_AD_READY;
assign ptereq.addr  = next_addr;
assign ptereq.wen   = 0;
assign ptereq.wdata = 0;
assign ptereq.wmask = SIZE_W;
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

// TLB
wire tlb_req_valid = sv32_enable & (state == WAIT_TLB_READY | state == IDLE & preq.valid) & all_tlb_ready;

// TLB0 (PPN1 + PPN0)
localparam TLB0_KLEN = VPN_LEN; // pteのvpn
localparam TLB0_VLEN = PPN_LEN + PPN_LEN + 6;// PPN(paddr), PPN(PTEのアドレス用), pte(R,W,U,X,G,D)

wire        tlb0_req_ready;
wire        tlb0_req_valid  = tlb_req_valid;
wire VPN    tlb0_req_vpn    = vaddr.vpn;
wire        tlb0_resp_valid;
wire        tlb0_resp_hit;
wire PPN    tlb0_resp_paddr_ppn;
wire PPN    tlb0_resp_pte_ppn;
wire        tlb0_resp_pte_r;
wire        tlb0_resp_pte_w;
wire        tlb0_resp_pte_x;
wire        tlb0_resp_pte_u;
wire        tlb0_resp_pte_g;
wire        tlb0_resp_pte_d;
logic       tlb0_update_valid       = 0;
VPN         tlb0_update_vpn         = 0;
PPN         tlb0_update_paddr_ppn   = 0;
PPN         tlb0_update_pte_ppn     = 0;
logic       tlb0_update_pte_r       = 0;
logic       tlb0_update_pte_w       = 0;
logic       tlb0_update_pte_x       = 0;
logic       tlb0_update_pte_u       = 0;
logic       tlb0_update_pte_g       = 0;
logic       tlb0_update_pte_d       = 0;

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
    .req_key(tlb0_req_vpn),
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

wire        tlb1_req_ready;
wire        tlb1_req_valid  = tlb_req_valid;
wire VPN1   tlb1_req_vpn1   = vaddr.vpn1;
wire        tlb1_resp_valid;
wire        tlb1_resp_hit;
wire PPN1   tlb1_resp_ppn1;
wire        tlb1_resp_pte_r;
wire        tlb1_resp_pte_w;
wire        tlb1_resp_pte_x;
wire        tlb1_resp_pte_u;
wire        tlb1_resp_pte_g;
wire        tlb1_resp_pte_d;
logic       tlb1_update_valid   = 0;
VPN1        tlb1_update_vpn1    = 0;
PPN1        tlb1_update_ppn1    = 0;
logic       tlb1_update_pte_r   = 0;
logic       tlb1_update_pte_w   = 0;
logic       tlb1_update_pte_x   = 0;
logic       tlb1_update_pte_u   = 0;
logic       tlb1_update_pte_g   = 0;
logic       tlb1_update_pte_d   = 0;

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
    .req_key(tlb1_req_vpn1),
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
        end
    end
    WAIT_TLB_READY: if (all_tlb_ready) state <= CHECK_TLB;
    CHECK_TLB: begin
        // TLBにあったら終了
        // TLBになかったらフェッチ
        if (tlb1_resp_valid)
            tlbs_saved_responsed[1] <= 1;
        if (tlb0_resp_valid)
            tlbs_saved_responsed[0] <= 1;
        if (tlb1_resp_valid & tlb1_resp_hit) begin
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
                state           <= REQ_READY;
                level           <= 1;
                saved_pte_addr  <= gen_l1pte_addr(s_vaddr.vpn1);
                saved_pte_data  <= {tlb1_resp_ppn1, {PPN0_LEN{1'b0}},
                                    2'b0, tlb1_resp_pte_d, 1'b1,
                                    tlb1_resp_pte_g, tlb1_resp_pte_u,
                                    tlb1_resp_pte_x, tlb1_resp_pte_w, tlb1_resp_pte_r, 1'b1};
                next_addr       <= gen_l1_paddr(tlb1_resp_ppn1, s_vaddr.vpn0, s_vaddr.pgoff);
            end
        end else if (tlb0_resp_valid & tlb0_resp_hit) begin
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
                state           <= REQ_READY;
                level           <= 0;
                saved_pte_addr  <= gen_l0pte_addr(tlb0_resp_pte_ppn, s_vaddr.vpn0);
                saved_pte_data  <= {tlb0_resp_paddr_ppn,
                                    2'b0, tlb0_resp_pte_d, 1'b1,
                                    tlb0_resp_pte_g, tlb0_resp_pte_u,
                                    tlb0_resp_pte_x, tlb0_resp_pte_w, tlb0_resp_pte_r, 1'b1};
                next_addr       <= gen_l0_paddr(tlb0_resp_paddr_ppn, s_vaddr.pgoff);
            end
        end else if (tlbs_all_responsed) begin
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
        end
    end
    REQ_END: begin
        if (result_error)
            state <= IDLE;
        else begin
            if (level === 1) begin
                tlb1_update_valid       <= 1;
                tlb1_update_vpn1        <= s_vaddr.vpn1;
                tlb1_update_ppn1        <= last_pte.ppn1;
                tlb1_update_pte_r       <= last_pte.r;
                tlb1_update_pte_w       <= last_pte.w;
                tlb1_update_pte_x       <= last_pte.x;
                tlb1_update_pte_u       <= last_pte.u;
                tlb1_update_pte_g       <= last_pte.g;
                tlb1_update_pte_d       <= last_pte.d | s_req.wen;
            end else if (level === 0) begin
                tlb0_update_valid       <= 1;
                tlb0_update_vpn         <= s_vaddr.vpn;
                tlb0_update_paddr_ppn   <= last_pte.ppn;
                tlb0_update_pte_ppn     <= {2'b0, saved_pte_addr[31:12]};
                tlb0_update_pte_r       <= last_pte.r;
                tlb0_update_pte_w       <= last_pte.w;
                tlb0_update_pte_x       <= last_pte.x;
                tlb0_update_pte_u       <= last_pte.u;
                tlb0_update_pte_g       <= last_pte.g;
                tlb0_update_pte_d       <= last_pte.d | s_req.wen;
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