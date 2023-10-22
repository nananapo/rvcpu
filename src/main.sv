`default_nettype none

`include "basic.svh"
`include "memoryinterface.svh"

module main #(
    parameter FMAX_MHz = 27
)(
    input  wire clk27MHz,
    input  wire uart_rx,
    output wire uart_tx,

    output logic [5:0]  led
`ifdef DEBUG
    ,
    output wire         exit,
    output wire UIntX   gp
`endif
);

`ifndef DEBUG
    wire        exit;
    wire UIntX  gp;
`endif

wire clk_in = clk27MHz;

logic exited = 0;
always @(posedge clk_in) begin
    if (exit) begin
        exited <= 1;
    end
    led[5:0] <= ~gp[5:0];
end

wire can_output_log;

// Counter and Timers
UInt64 reg_cycle = 0;
UInt64 reg_time  = 0;
wire UInt64 reg_mtimecmp;

int timecounter = 0;
always @(posedge clk_in) begin
    // cycleは毎クロックインクリメント
    reg_cycle   <= reg_cycle + 1;
    // timeをμ秒ごとにインクリメント
    if (timecounter == FMAX_MHz - 1) begin
        reg_time    <= reg_time + 1;
        timecounter <= 0;
    end else begin
        timecounter <= timecounter + 1;
    end
end

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
wire CacheReq   dcreq_ptw_cache;
wire CacheResp  dcresp_ptw_cache;
wire CacheReq   dcreq_acntr_ptw;
wire CacheResp  dcresp_acntr_ptw;
wire DReq       dreq_mmio_acntr;
wire DResp      dresp_mmio_acntr;
wire DReq       dreq_core_mmio;
wire DResp      dresp_core_mmio;

wire CacheCntrInfo  cache_cntr;

`ifndef MEM_FILE
    initial begin
        $display("ERROR : initial memory file (MEM_FILE) is not set.");
        $finish;
    end
`endif
`ifndef MEMORY_SIZE
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
    .ADDR_WIDTH(`XLEN),
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

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

/* ---- Inst ---- */
MemICache #() memicache (
    .clk(clk_in),
    .reset(cache_cntr.invalidate_icache),
    .ireq_in(icreq_ptw_cache),
    .iresp_in(icresp_ptw_cache),
    .busreq(mbreq_icache),
    .busresp(mbresp_icache)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

PageTableWalker #(
    .LOG_ENABLE(0),
    .EXECUTE_MODE(1),
    .LOG_ENABLE(0),
    .LOG_AS("memstage")
) iptw (
    .clk(clk_in),
    .reset(ireq_core_iq.valid),
    .preq(icreq_iq_ptw),
    .presp(icresp_iq_ptw),
    .memreq(icreq_ptw_cache),
    .memresp(icresp_ptw_cache),
    .mode(cache_cntr.i_mode),
    .satp(cache_cntr.satp),
    .mxr(cache_cntr.mxr),
    .sum(cache_cntr.sum)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

InstQueue #() instqueue (
    .clk(clk_in),
    .ireq(ireq_core_iq),
    .iresp(iresp_core_iq),
    .memreq(icreq_iq_ptw),
    .memresp(icresp_iq_ptw),
    .brinfo(brinfo)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

/* ---- Data ---- */
MemDCache #() memdcache (
    .clk(clk_in),
    .dreq_in(dcreq_ptw_cache),
    .dresp_in(dcresp_ptw_cache),
    .busreq(mbreq_dcache),
    .busresp(mbresp_dcache),
    .do_writeback(cache_cntr.do_writeback),
    .is_writebacked_all(cache_cntr.is_writebacked_all)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

PageTableWalker #(
    .LOG_ENABLE(0),
    .EXECUTE_MODE(0),
    .LOG_ENABLE(1),
    .LOG_AS("memstage")
) dptw (
    .clk(clk_in),
    .reset(1'b0),
    .preq(dcreq_acntr_ptw),
    .presp(dcresp_acntr_ptw),
    .memreq(dcreq_ptw_cache),
    .memresp(dcresp_ptw_cache),
    .mode(cache_cntr.d_mode),
    .satp(cache_cntr.satp),
    .mxr(cache_cntr.mxr),
    .sum(cache_cntr.sum)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

DAccessCntr #() daccesscntr (
    .clk(clk_in),
    .reset(1'b0),
    .dreq(dreq_mmio_acntr),
    .dresp(dresp_mmio_acntr),
    .memreq(dcreq_acntr_ptw),
    .memresp(dcresp_acntr_ptw)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

MMIO_Cntr #(
    .FMAX_MHz(FMAX_MHz)
) memmapcntr (
    .clk(clk_in),
    .reset(1'b0),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .mtime(reg_time),
    .mtimecmp(reg_mtimecmp),
    .dreq_in(dreq_core_mmio),
    .dresp_in(dresp_core_mmio),
    .memreq_in(dreq_mmio_acntr),
    .memresp_in(dresp_mmio_acntr)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

/* ---- Core ---- */
Core #(
    .FMAX_MHz(FMAX_MHz)
) core (
    .clk(clk_in),

    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtime(reg_time),
    .reg_mtimecmp(reg_mtimecmp),

    .ireq(ireq_core_iq),
    .iresp(iresp_core_iq),
    .brinfo(brinfo),
    .dreq(dreq_core_mmio),
    .dresp(dresp_core_mmio),
    .cache_cntr(cache_cntr),

    .gp(gp),
    .exit(exit),

    .exited(exited)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

endmodule
