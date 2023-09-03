`default_nettype none

`include "include/basic.svh"
`include "include/memoryinterface.sv"

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
    led[5:0] = ~gp[5:0];
end

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

wire modetype   csr_mode;
wire UIntX      csr_satp;

wire BrInfo     brinfo;
wire MemBusReq  mbreq_icache;
wire MemBusResp mbresp_icache;
wire ICacheReq  icreq_cache;
wire ICacheResp icresp_cache;
/* verilator lint_off UNOPTFLAT */
wire ICacheReq  icreq_ptw;
/* verilator lint_on UNOPTFLAT */
wire ICacheResp icresp_ptw;
wire IReq       ireq_iq;
wire IResp      iresp_iq;

wire MemBusReq  mbreq_dcache;
wire MemBusResp mbresp_dcache;
wire DCacheReq  dcreq_acntr_dcache;
wire DCacheResp dcresp_acntr_dcache;
wire DReq       dreq_mmio_acntr;
wire DResp      dresp_mmio_acntr;
wire DReq       dreq_core_mmio;
wire DResp      dresp_core_mmio;

`ifndef MEM_FILE
    `define MEM_FILE "../test/riscv-tests/rv32ui-p-add.bin.aligned"
    initial $display("WARN : initial memory file (MEM_FILE) is not set. default to %s", `MEM_FILE);
`endif
`ifndef MEMORY_SIZE
    `define MEMORY_WIDTH 20
    initial $display("WARN : memory width (MEMORY_WIDTH) is not set. default to %d", `MEMORY_WIDTH);
`endif

Memory #(
    .FILEPATH(`MEM_FILE),
    .ADDR_WIDTH(`MEMORY_WIDTH)
) memory (
    .clk(clk_in),
    .req_ready(mbreq_mem.ready),
    .req_valid(mbreq_mem.valid),
    .req_addr(mbreq_mem.addr),
    .req_wen(mbreq_mem.wen),
    .req_wdata(mbreq_mem.wdata),
    .resp_valid(mbresp_mem.valid),
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
    .ireq_in(icreq_cache),
    .iresp(icresp_cache),
    .busreq(mbreq_icache),
    .busresp(mbresp_icache)
);

PageTableWalker #() iptw (
    .clk(clk_in),
    .ireq(icreq_ptw),
    .iresp(icresp_ptw),
    .memreq(icreq_cache),
    .memresp(icresp_cache),
    .csr_mode(csr_mode),
    .csr_satp(csr_satp),
    .kill(ireq_iq.valid) // 分岐ロジックと同じになってしまっているので、分離する svinval
);

InstQueue #() instqueue (
    .clk(clk_in),
    .ireq(ireq_iq),
    .iresp(iresp_iq),
    .memreq(icreq_ptw),
    .memresp(icresp_ptw),
    .brinfo(brinfo)
);

/* ---- Data ---- */
MemDCache #() memdcache (
    .clk(clk_in),
    .dreq_in(dcreq_acntr_dcache),
    .dresp(dcresp_acntr_dcache),
    .busreq(mbreq_dcache),
    .busresp(mbresp_dcache)
);

DAccessCntr #() daccesscntr (
    .clk(clk_in),
    .dreq(dreq_mmio_acntr),
    .dresp(dresp_mmio_acntr),
    .memreq(dcreq_acntr_dcache),
    .memresp(dcresp_acntr_dcache)
);

MMIO_Cntr #(
    .FMAX_MHz(FMAX_MHz)
) memmapcntr (
    .clk(clk_in),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .mtime(reg_time),
    .mtimecmp(reg_mtimecmp),
    .dreq_in(dreq_core_mmio),
    .dresp_in(dresp_core_mmio),
    .memreq_in(dreq_mmio_acntr),
    .memresp_in(dresp_mmio_acntr)
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

    .ireq(ireq_iq),
    .iresp(iresp_iq),
    .brinfo(brinfo),
    .dreq(dreq_core_mmio),
    .dresp(dresp_core_mmio),
    .csr_mode(csr_mode),
    .csr_satp(csr_satp),

    .gp(gp),
    .exit(exit),

    .exited(exited)
);

endmodule
