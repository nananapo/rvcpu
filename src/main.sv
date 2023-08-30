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
    output wire[31:0]   gp
`endif
);

`ifndef DEBUG
    wire         exit;
    wire[31:0]   gp;
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

logic [31:0]  timecounter = 0;
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
wire [31:0]     csr_satp;

wire BrInfo brinfo;
wire MemBusReq  mbreq_dcache;
wire MemBusResp mbresp_dcache;
wire ICacheReq  icreq_dcache;
wire ICacheResp icresp_dcache;
wire ICacheReq  icreq_ptw;
wire ICacheResp icresp_ptw;
wire IReq   ireq_iq;
wire IResp  iresp_iq;

wire MemBusReq  mbreq_dcache;
wire MemBusResp mbresp_dcache;
wire DCacheReq  dcreq_cntr_cache;
wire DCacheResp dcresp_cntr_cache;
wire DReq   dreq_mmio_cntr;
wire DResp  dresp_mmio_cntr;
wire DReq   dreq_unaligned;
wire DResp  dresp_unaligned;

`ifndef MEMORY_FILE_NAME
    `define MEMORY_FILE_NAME "../test/riscv-tests/rv32ui-p-add.bin.aligned"
    initial $display("WARN : initial memory file (MEMORY_FILE_NAME) is not set. default to %s", `MEMORY_FILE_NAME);
`endif
`ifndef MEMORY_SIZE
    `define MEMORY_SIZE 2 ** 20
    initial $display("WARN : memory size (MEMORY_SIZE) is not set. default to %s", `MEMORY_SIZE);
`endif

MemoryBus #(
    .FILEPATH(`MEMORY_FILE_NAME),
    .SIZE(`MEMORY_SIZE)
) memory (
    .clk(clk_in),
    .req(mbreq_mem),
    .resp(mbresp_mem)
);

MemBusCntr #() membuscntr (
    .clk(clk_in),
    .dreq(mbreq_dcache),
    .dresp(mbresp_dcache),
    .ireq(mbreq_icache),
    .iresp(mbresp_icache),
    .memreq(mbreq_mem),
    .memresp(mbresp_mem)
);

/* ---- Inst ---- */
MemICache #() memicache (
    .clk(clk_in),
    .ireq(icreq_ex),
    .iresp(icresp_ex),
    .busreq(mbreq_icache),
    .busresp(mbresp_icache)
);

PageTableWalker #() iptw (
    .clk(clk_in),
    .ireq(icreq_ptw),
    .iresp(icresp_ptw),
    .memreq(icreq_dcache),
    .memresp(icresp_dcache),
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
    .clk(clk),
    .dreq(dcreq_cntr_cache),
    .dresp(dcresp_cntr_cache),
    .busreq(mbreq_dcache),
    .busresp(mbresp_dcache)
);

MMIO_Cntr #(
    .FMAX_MHz(FMAX_MHz)
) memmapcntr (
    .clk(clk_in),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .mtime(reg_time),
    .mtimecmp(reg_mtimecmp),
    .dreq(dreq_mmio_cntr),
    .dresp(dresp_mmio_cnt),
    .creq(dcreq_cntr_cache),
    .cresp(dcresp_cntr_cache)
);

DAccessCntr #() daccesscntr (
    .clk(clk_in),
    .dreq(dreq_unaligned),
    .dresp(dresp_unaligned),
    .memreq(dreq_mmio_cntr),
    .memresp(dresp_mmio_cnt)
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
    .dreq(dreq_unaligned),
    .dresp(dresp_unaligned),
    .csr_mode(csr_mode),
    .csr_satp(csr_satp),

    .gp(gp),
    .exit(exit),

    .exited(exited)
);

endmodule