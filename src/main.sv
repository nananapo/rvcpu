`default_nettype none
`include "include/memoryinterface.sv"

module main #(
    parameter FMAX_MHz = 18 
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
    Gowin_rPLL rpll_clk(
        .clkout(clkConstrained), //output clkout
        .clkin(clk27MHz) //input clkin
    );
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

wire IRequest   ireq_mem;
wire IResponse  iresp_mem;
wire IRequest   ireq_core;
wire IResponse  iresp_core;

wire DRequest   dreq_mem;
wire DResponse  dresp_mem;
wire DRequest   dreq_unaligned;
wire DResponse  dresp_unaligned;

wire IUpdatePredictionIO    updateio;

MemoryInterface #(
    .FMAX_MHz(FMAX_MHz)
) memory (
    .clk(clkConstrained),
    .exit(exited),

    .mem_uart_rx(mem_uart_rx),
    .mem_uart_tx(mem_uart_tx),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx),

    .mtime(reg_time),
    .mtimecmp(reg_mtimecmp),

    .ireq(ireq_mem),
    .iresp(iresp_mem),
    .dreq(dreq_mem),
    .dresp(dresp_mem)
);

// IF/ID Stage <-> InstQueue <-> MemoryInterface
InstQueue #() instqueue (
    .clk(clkConstrained),
    .ireq(ireq_core),
    .iresp(iresp_core),
    .memreq(ireq_mem),
    .memresp(iresp_mem),
    .updateio(updateio)
);

// MEM Stage <-> DUnalignedAccessController <-> MemoryInterface
DUnalignedAccessController #() dunalignedaccesscontroller (
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

    .ireq(ireq_core),
    .iresp(iresp_core),
    .updateio(updateio),
    .dreq(dreq_unaligned),
    .dresp(dresp_unaligned),

    .gp(gp),
    .exit(exit),

    .exited(exited)
);

endmodule