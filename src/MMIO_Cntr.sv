module MMIO_Cntr #(
    parameter FMAX_MHz = 27
) (
    input  wire             clk,
    input  wire             reset,

    input  wire             uart_rx,
    output wire             uart_tx,
    input  wire UInt64      mtime,
    output wire UInt64      mtimecmp,

    inout  wire CacheReq    dreq_in,
    inout  wire CacheResp   dresp_in,
    inout  wire CacheReq    memreq_in,
    inout  wire CacheResp   memresp_in,

    output wire             uart_rx_pending

`ifdef PRINT_DEBUGINFO
    ,
    input wire can_output_log
`endif
);

`include "basicparams.svh"
`include "memorymap.svh"

function in_range(
    input UIntX left,
    input UIntX right,
    input UIntX addr
);
    in_range = left <= addr && addr <= right;
endfunction

typedef enum logic [1:0] {
    IDLE,
    WAIT_READY,
    WAIT_VALID
} statetype;

statetype state = IDLE;
CacheReq  s_dreq;

initial begin
    s_dreq.valid = 0;
end

wire CacheReq dreq = state == IDLE ? dreq_in : s_dreq;

// TODO メモリを8000_0000以降に配置することで判定を簡略化する
wire is_uart_tx     = dreq.addr == MMIO_UARTTX;
wire is_uart_rx     = in_range(MMIO_UARTRX_OFFSET, MMIO_UARTRX_END, dreq.addr);
wire is_clint       = in_range(CLINT_OFFSET, CLINT_END, dreq.addr);
wire is_edisk       = in_range(EDISK_OFFSET, EDISK_END, dreq.addr);
wire is_memory      = !is_uart_tx & !is_uart_rx & !is_clint & !is_edisk;

wire s_is_uart_tx   = s_dreq.addr == MMIO_UARTTX;
wire s_is_uart_rx   = in_range(MMIO_UARTRX_OFFSET, MMIO_UARTRX_END, s_dreq.addr);
wire s_is_clint     = in_range(CLINT_OFFSET, CLINT_END, s_dreq.addr);
wire s_is_edisk     = in_range(EDISK_OFFSET, EDISK_END, s_dreq.addr);
wire s_is_memory    = !s_is_uart_tx & !s_is_uart_rx & !s_is_clint & !s_is_edisk;

wire cmd_start  = (state == IDLE | state == WAIT_READY) & dreq.valid;
wire cmd_ready  =   is_uart_tx  ? cmd_uart_tx_ready :
                    is_uart_rx  ? cmd_uart_rx_ready :
                    is_clint    ? cmd_clint_ready :
                    is_edisk    ? cmd_edisk_ready :
                    memreq_in.ready;

/* verilator lint_off UNOPTFLAT */
wire s_valid   = s_dreq.valid & (
                    (s_is_memory    & memresp_in.valid) |
                    (s_is_uart_tx   & cmd_uart_tx_rvalid) |
                    (s_is_uart_rx   & cmd_uart_rx_rvalid) |
                    (s_is_clint     & cmd_clint_rvalid) |
                    (s_is_edisk     & cmd_edisk_rvalid));
/* verilator lint_on UNOPTFLAT */

wire UIntX s_rdata  =   s_is_memory     ? memresp_in.rdata :
                        s_is_uart_tx    ? cmd_uart_tx_rdata :
                        s_is_uart_rx    ? cmd_uart_rx_rdata :
                        s_is_clint      ? cmd_clint_rdata :
                        /*s_is_edisk ? */ cmd_edisk_rdata /*: 32'bx */;

assign dreq_in.ready    = state == IDLE | (state == WAIT_VALID & s_valid);

assign dresp_in.valid   = s_valid;
assign dresp_in.rdata   = s_rdata;
assign dresp_in.error   = s_is_memory ? memresp_in.error : 0;
assign dresp_in.errty   = s_is_memory ? memresp_in.errty : FE_ACCESS_FAULT;

assign memreq_in.valid  = is_memory & cmd_start;
assign memreq_in.addr   = dreq.addr;
assign memreq_in.wen    = dreq.wen;
assign memreq_in.wdata  = dreq.wdata;
assign memreq_in.wmask  = dreq.wmask;

always @(posedge clk) if (reset) state <= IDLE; else begin
    case (state)
        IDLE: if (dreq_in.valid) begin
            s_dreq  <= dreq_in;
            state   <= cmd_ready ? WAIT_VALID : WAIT_READY;
        end
        WAIT_READY: if (cmd_ready)  state <= WAIT_VALID;
        WAIT_VALID: if (s_valid) begin
            if (dreq_in.valid) begin
                s_dreq  <= dreq_in;
                state   <= cmd_ready ? WAIT_VALID : WAIT_READY;
            end else begin
                state   <= IDLE;
            end
        end
        default: state <= IDLE;
    endcase

    /*
    if (can_output_log) begin
        $display("info,memstage.mmiocntr,state(%d) mready(%d)", state, memreq_in.ready);
    end
    */
end

wire        cmd_uart_tx_ready;
wire        cmd_uart_tx_rvalid;
wire UIntX  cmd_uart_tx_rdata;
wire        cmd_uart_tx_start   = is_uart_tx & cmd_start;

wire        cmd_uart_rx_ready;
wire        cmd_uart_rx_rvalid;
wire UIntX  cmd_uart_rx_rdata;
wire        cmd_uart_rx_start   = is_uart_rx & cmd_start;

wire        cmd_clint_ready;
wire        cmd_clint_rvalid;
wire UIntX  cmd_clint_rdata;
wire        cmd_clint_start     = is_clint & cmd_start;

wire        cmd_edisk_ready;
wire        cmd_edisk_rvalid;
wire UIntX  cmd_edisk_rdata;
wire        cmd_edisk_start     = is_edisk & cmd_start;

MMIO_uart_rx #(
    .FMAX_MHz(FMAX_MHz)
) memmap_uartrx (
    .clk(clk),
    .uart_rx(uart_rx),

    .req_ready(cmd_uart_rx_ready),
    .req_valid(cmd_uart_rx_start),
    .req_addr({{XLEN-4{1'b0}}, dreq.addr[3:0]}),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_uart_rx_rvalid),
    .resp_rdata(cmd_uart_rx_rdata),

    .uart_rx_pending(uart_rx_pending)
);

MMIO_uart_tx #(
    .FMAX_MHz(FMAX_MHz)
) memmap_uarttx (
    .clk(clk),
    .uart_tx(uart_tx),

    .req_ready(cmd_uart_tx_ready),
    .req_valid(cmd_uart_tx_start),
    .req_addr(0),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_uart_tx_rvalid),
    .resp_rdata(cmd_uart_tx_rdata)

`ifdef PRINT_DEBUGINFO
    ,
    .can_output_log(can_output_log)
`endif
);

MMIO_clint #(
    .FMAX_MHz(FMAX_MHz)
) memmap_clint (
    .clk(clk),

    .req_ready(cmd_clint_ready),
    .req_valid(cmd_clint_start),
    .req_addr({{XLEN-4{1'b0}}, dreq.addr[3:0]}),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_clint_rvalid),
    .resp_rdata(cmd_clint_rdata),

    .mtime(mtime),
    .mtimecmp(mtimecmp)
);

MMIO_EDisk #() edisk (
    .clk(clk),

    .req_ready(cmd_edisk_ready),
    .req_valid(cmd_edisk_start),
    .req_addr({{XLEN-8{1'b0}}, dreq.addr[7:0]}),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_edisk_rvalid),
    .resp_rdata(cmd_edisk_rdata)
);

endmodule