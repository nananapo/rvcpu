`default_nettype none

`include "pkg_all.svh"

module main
(
    input  wire clk27MHz,
    input  wire uart_rx,
    output wire uart_tx,

    output logic [5:0]  led
);

import basic::Addr;
import meminf::*;

always @(posedge clk27MHz) begin
    led[0] <= uart_rx;
    led[1] <= uart_tx;
    for (int i = 2; i < 6; i++)
        led[i] <= 1;
end

wire clk_in = clk27MHz;

/* ---- Mem ---- */
wire MemBusReq  mbreq_mem;
wire MemBusResp mbresp_mem;

wire BrInfo     brinfo;
wire MemBusReq  mbreq_icache;
wire MemBusResp mbresp_icache;
wire CacheReq   icreq_ptw_cache;
wire CacheResp  icresp_ptw_cache;
/* verilator lint_off UNOPTFLAT */
wire CacheReq   icreq_iq_ptw;
/* verilator lint_on UNOPTFLAT */
wire CacheResp  icresp_iq_ptw;
wire IReq       ireq_core_iq;
wire IResp      iresp_core_iq;

wire MemBusReq  mbreq_dcache;
wire MemBusResp mbresp_dcache;

wire CacheReq   dreq_arb_cache;
wire CacheResp  dresp_arb_cache;
wire CacheReq   dreq_arb_arb;
wire CacheResp  dresp_arb_arb;
wire CacheReq   dreq_acntr_arb;
wire CacheResp  dresp_acntr_arb;
wire CacheReq   dreq_mmio_acntr;
wire CacheResp  dresp_mmio_acntr;
wire CacheReq   dreq_ptw_mmio;
wire CacheResp  dresp_ptw_mmio;
wire CacheReq   dreq_core_ptw;
wire CacheResp  dresp_core_ptw;

wire CacheCntrInfo  cache_cntr;

wire CacheReq   iptw_pte_req;
wire CacheResp  iptw_pte_resp;
wire CacheReq   dptw_pte_req;
wire CacheResp  dptw_pte_resp;

wire uart_rx_pending;
wire mti_pending;

wire external_interrupt_pending = uart_rx_pending;

`ifndef MEM_FILE
    initial begin
        $display("ERROR : initial memory file (MEM_FILE) is not set.");
        `ffinish
    end
`endif
`ifndef MEMORY_WIDTH
    `define MEMORY_WIDTH 20
    initial $display("WARN : memory width (MEMORY_WIDTH) is not set. default to %d", `MEMORY_WIDTH);
`endif
`ifndef MEMORY_DELAY
    `define MEMORY_DELAY 4
    initial $display("WARN : memory delay (MEMORY_DELAY) is not set. default to %d", `MEMORY_DELAY);
`endif

Memory #(
    .FILEPATH(`MEM_FILE),
    .MEM_WIDTH(`MEMORY_WIDTH),
    .ADDR_WIDTH(conf::XLEN),
    .DELAY_CYCLE(`MEMORY_DELAY)
) memory (
    .clk(clk_in),
    .req_ready(mbreq_mem.ready),
    .req_valid(mbreq_mem.valid),
    .req_addr(mbreq_mem.addr),
    .req_wen(mbreq_mem.wen),
    .req_wdata(mbreq_mem.wdata),
    .resp_valid(mbresp_mem.valid),
    .resp_addr(mbresp_mem.addr),
    .resp_error(mbresp_mem.error),
    .resp_rdata(mbresp_mem.rdata)
);

MemBusCntr #() membuscntr (
    .clk(clk_in),
    .ireq_in(mbreq_icache),
    .iresp_in(mbresp_icache),
    .dreq_in(mbreq_dcache),
    .dresp_in(mbresp_dcache),
    .memreq_in(mbreq_mem),
    .memresp_in(mbresp_mem)
);

/* ---- Inst ---- */
MemICache #() memicache (
    .clk(clk_in),
    .reset(cache_cntr.invalidate_icache),
    .ireq_in(icreq_ptw_cache),
    .iresp_in(icresp_ptw_cache),
    .busreq(mbreq_icache),
    .busresp(mbresp_icache)
);

PageTableWalker #(
    .LOG_ENABLE(1),
    .EXECUTE_MODE(1),
    .LOG_AS("fetchstage")
) iptw (
    .clk(clk_in),
    .reset(ireq_core_iq.valid),
    .preq(icreq_iq_ptw),
    .presp(icresp_iq_ptw),
    .memreq(icreq_ptw_cache),
    .memresp(icresp_ptw_cache),
    .ptereq(iptw_pte_req),
    .pteresp(iptw_pte_resp),
    .mode(cache_cntr.i_mode),
    .satp(cache_cntr.satp),
    .mxr(cache_cntr.mxr),
    .sum(cache_cntr.sum),
    .flush_tlb(cache_cntr.invalidate_tlb)
);

Stage_Fetch #() fetchstage (
    .clk(clk_in),
    .ireq(ireq_core_iq),
    .iresp(iresp_core_iq),
    .memreq(icreq_iq_ptw),
    .memresp(icresp_iq_ptw),
    .brinfo(brinfo)
);

/* ---- Data ---- */
MemDCache #() memdcache (
    .clk(clk_in),
    .dreq_in(dreq_arb_cache),
    .dresp_in(dresp_arb_cache),
    .busreq(mbreq_dcache),
    .busresp(mbresp_dcache),
    .do_writeback(cache_cntr.do_writeback),
    .is_writebacked_all(cache_cntr.is_writebacked_all)
);

MemCacheCmdArbiter #() dcache_arbiter1 (
    .clk(clk_in),
    .ireq_in(iptw_pte_req),
    .iresp_in(iptw_pte_resp),
    .dreq_in(dreq_arb_arb),
    .dresp_in(dresp_arb_arb),
    .memreq_in(dreq_arb_cache),
    .memresp_in(dresp_arb_cache)
);

MemCacheCmdArbiter #() dcache_arbiter2 (
    .clk(clk_in),
    .ireq_in(dptw_pte_req),
    .iresp_in(dptw_pte_resp),
    .dreq_in(dreq_acntr_arb),
    .dresp_in(dresp_acntr_arb),
    .memreq_in(dreq_arb_arb),
    .memresp_in(dresp_arb_arb)
);

MemMisalignCntr #() dmiscntr (
    .clk(clk_in),
    .reset(1'b0),
    .dreq(dreq_mmio_acntr),
    .dresp(dresp_mmio_acntr),
    .memreq(dreq_acntr_arb),
    .memresp(dresp_acntr_arb)
);

MMIO_Cntr memmapcntr (
    .clk(clk_in),
    .reset(1'b0),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .dreq_in(dreq_ptw_mmio),
    .dresp_in(dresp_ptw_mmio),
    .memreq_in(dreq_mmio_acntr),
    .memresp_in(dresp_mmio_acntr),

    .mti_pending(mti_pending),
    .uart_rx_pending(uart_rx_pending)
);

PageTableWalker #(
    .EXECUTE_MODE(0),
    .LOG_ENABLE(1),
    .LOG_AS("memstage")
) dptw (
    .clk(clk_in),
    .reset(1'b0),
    .preq(dreq_core_ptw),
    .presp(dresp_core_ptw),
    .memreq(dreq_ptw_mmio),
    .memresp(dresp_ptw_mmio),
    .ptereq(dptw_pte_req),
    .pteresp(dptw_pte_resp),
    .mode(cache_cntr.d_mode),
    .satp(cache_cntr.satp),
    .mxr(cache_cntr.mxr),
    .sum(cache_cntr.sum),
    .flush_tlb(cache_cntr.invalidate_tlb)
);

/* ---- Core ---- */
Core #() core (
    .clk(clk_in),
    .ireq(ireq_core_iq),
    .iresp(iresp_core_iq),
    .brinfo(brinfo),
    .dreq(dreq_core_ptw),
    .dresp(dresp_core_ptw),
    .cache_cntr(cache_cntr),

    .external_interrupt_pending(external_interrupt_pending),
    .mti_pending(mti_pending)
);

endmodule