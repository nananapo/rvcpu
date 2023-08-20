`default_nettype none
`include "include/memoryinterface.sv"

module main #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk27MHz,

    // メモリにUARTを使うときに使うピン
    input  wire         mem_uart_rx,
    output wire         mem_uart_tx,

    // メモリにマップされるUARTのピン
    input  wire         uart_rx,
    output wire         uart_tx,
    
    output reg [5:0]    led

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

// クロックの生成
wire clkConstrained;
`ifdef DEBUG
    assign clkConstrained = clk27MHz;
`else
    /*
    Gowin_rPLL rpll_clk(
        .clkout(clkConstrained), //output clkout
        .clkin(clk27MHz) //input clkin
    );
    */
    assign clkConstrained = clk27MHz;
`endif

reg exited = 0;
always @(posedge clkConstrained) begin
    if (exit) begin
        exited <= 1;
    end
    led[5:0] = ~gp[5:0];
end

// Counter and Timers
reg [63:0]  reg_cycle    = 0;
reg [63:0]  reg_time     = 0;
wire[63:0]  reg_mtimecmp;

reg [31:0]  timecounter = 0;
always @(posedge clkConstrained) begin
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

wire modetype   csr_mode;
wire [31:0]     csr_satp;

wire IRequest   ireq_mem;
wire IResponse  iresp_mem;
wire IRequest   ireq_ptw;
wire IResponse  iresp_ptw;
wire IRequest   ireq_iq;
wire IResponse  iresp_iq;

wire DRequest   dreq_mem;
wire DResponse  dresp_mem;
wire DRequest   dreq_unaligned;
wire DResponse  dresp_unaligned;

wire IUpdatePredictionIO    updateio;

wire        memcntr_memmap_req_ready;
wire        memcntr_memmap_req_valid;
wire [31:0] memcntr_memmap_req_addr;
wire        memcntr_memmap_req_wen;
wire [31:0] memcntr_memmap_req_wdata;
wire [31:0] memcntr_memmap_resp_rdata;
wire        memcntr_memmap_resp_valid;

MemMapCntr #(
    .FMAX_MHz(FMAX_MHz),
`ifdef RISCV_TEST
    // make riscv-tests
    .MEMORY_SIZE(2097152),
    .MEMORY_FILE("../test/riscv-tests/MEMORY_FILE_NAME")
`elsif DEBUG
    // make d
    .MEMORY_SIZE(2097152),
    // .MEMORY_FILE("../tinyos/kernel.bin.aligned")
    // .MEMORY_FILE("../test/csr/m_timerinterrupt.c.bin.aligned")
    // .MEMORY_FILE("../test/riscv-tests/rv32ui-p-add.bin.aligned")
    .MEMORY_FILE("../test/bench/coremark/output/code.bin.aligned")
`else
    // build
    .MEMORY_SIZE(1024 * 8), // 8 * 8Kb
    // .MEMORY_FILE("../tinyos/kernel.bin.aligned")
    .MEMORY_FILE("../test/bench/coremark/output/code.bin.aligned")
    // .MEMORY_FILE("../test/csr/m_timerinterrupt.c.bin.aligned")
`endif
) memmapcntr (
    .clk(clkConstrained),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .mem_uart_rx(mem_uart_rx),
    .mem_uart_tx(mem_uart_tx),

    .mtime(reg_time),
    .mtimecmp(reg_mtimecmp),

    .output_cmd_ready(memcntr_memmap_req_ready),
    .input_cmd_start(memcntr_memmap_req_valid),
    .input_addr(memcntr_memmap_req_addr),
    .input_cmd_write(memcntr_memmap_req_wen),
    .input_wdata(memcntr_memmap_req_wdata),
    .output_rdata(memcntr_memmap_resp_rdata),
    .output_rdata_valid(memcntr_memmap_resp_valid)
);


MemCmdCntr #() memcmdcntr (
    .clk(clkConstrained),
    .exit(exited),

    .ireq(ireq_mem),
    .iresp(iresp_mem),
    .dreq(dreq_mem),
    .dresp(dresp_mem),

    .mem_req_ready(memcntr_memmap_req_ready),
    .mem_req_valid(memcntr_memmap_req_valid),
    .mem_req_addr(memcntr_memmap_req_addr),
    .mem_req_wen(memcntr_memmap_req_wen),
    .mem_req_wdata(memcntr_memmap_req_wdata),
    .mem_resp_rdata(memcntr_memmap_resp_rdata),
    .mem_resp_valid(memcntr_memmap_resp_valid)
);

// PTW
PageTableWalker #() ptw (
    .clk(clkConstrained),
    .ireq(ireq_ptw),
    .iresp(iresp_ptw),
    .memreq(ireq_mem),
    .memresp(iresp_mem),
    .csr_mode(csr_mode),
    .csr_satp(csr_satp),
    .kill(ireq_iq.valid) // 分岐のロジック再利用
);

// IF/ID Stage <-> InstQueue <-> MemCmdCntr
InstQueue #() instqueue (
    .clk(clkConstrained),
    .ireq(ireq_iq),
    .iresp(iresp_iq),
    .memreq(ireq_ptw),
    .memresp(iresp_ptw),
    .updateio(updateio)
);

// MEM Stage <-> DAccessCntr <-> MemCmdCntr
DAccessCntr #() dunalignedaccesscontroller (
    .clk(clkConstrained),
    .dreq(dreq_unaligned),
    .dresp(dresp_unaligned),
    .memreq(dreq_mem),
    .memresp(dresp_mem)
);

Core #(
    .FMAX_MHz(FMAX_MHz)
) core (
    .clk(clkConstrained),
    
    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtime(reg_time),
    .reg_mtimecmp(reg_mtimecmp),

    .ireq(ireq_iq),
    .iresp(iresp_iq),
    .updateio(updateio),
    .dreq(dreq_unaligned),
    .dresp(dresp_unaligned),
    .csr_mode(csr_mode),
    .csr_satp(csr_satp),

    .gp(gp),
    .exit(exit),

    .exited(exited)
);

endmodule