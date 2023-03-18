`default_nettype none

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

reg         mem_inst_start;
reg         mem_inst_ready;
reg [31:0]  mem_i_addr;
reg [31:0]  mem_inst;
reg         mem_inst_valid;
reg         mem_d_cmd_start;
reg         mem_d_cmd_write;
reg         mem_d_cmd_ready;
reg [31:0]  mem_d_addr;
reg [31:0]  mem_wdata;
reg [31:0]  mem_wmask;
reg [31:0]  mem_rdata;
reg         mem_rdata_valid;

reg         exited      = 0;

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

MemoryInterface #(
    .FMAX_MHz(FMAX_MHz)
) memory (
    .clk(clkConstrained),

    .mem_uart_rx(mem_uart_rx),
    .mem_uart_tx(mem_uart_tx),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx),

    .mtime(reg_time),
    .mtimecmp(reg_mtimecmp),

    .inst_start(mem_inst_start),
    .inst_ready(mem_inst_ready),
    .i_addr(mem_i_addr),
    .inst(mem_inst),
    .inst_valid(mem_inst_valid),
    .d_cmd_start(mem_d_cmd_start),
    .d_cmd_write(mem_d_cmd_write),
    .d_cmd_ready(mem_d_cmd_ready),
    .d_addr(mem_d_addr),
    .wdata(mem_wdata),
    .wmask(mem_wmask),
    .rdata(mem_rdata),
    .rdata_valid(mem_rdata_valid),

    .exited(exited)
);

Core #(
    .FMAX_MHz(FMAX_MHz)
) core (
    .clk(clkConstrained),
    
    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtimecmp(reg_mtimecmp),

    .memory_inst_start(mem_inst_start),
    .memory_inst_ready(mem_inst_ready),
    .memory_i_addr(mem_i_addr),
    .memory_inst(mem_inst),
    .memory_inst_valid(mem_inst_valid),
    .memory_d_cmd_start(mem_d_cmd_start),
    .memory_d_cmd_write(mem_d_cmd_write),
    .memory_d_cmd_ready(mem_d_cmd_ready),
    .memory_d_addr(mem_d_addr),
    .memory_wdata(mem_wdata),
    .memory_wmask(mem_wmask),
    .memory_rdata(mem_rdata),
    .memory_rdata_valid(mem_rdata_valid),

    .gp(gp),
    .exit(exit),

    .exited(exited)
);

endmodule