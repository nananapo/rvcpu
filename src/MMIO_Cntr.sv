module MMIO_Cntr
    import conf::*;
    import basic::*;
    import meminf::*;
(
    input  wire             clk,
    input  wire             reset,

    input  wire             uart_rx,
    output wire             uart_tx,

    inout  wire CacheReq    dreq_in,
    inout  wire CacheResp   dresp_in,
    inout  wire CacheReq    memreq_in,
    inout  wire CacheResp   memresp_in,

    output wire             uart_rx_pending,
    output wire             mti_pending
);

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

wire is_uart_tx     = MemMap::is_uart_tx_addr(dreq_in.addr);
wire is_uart_rx     = MemMap::is_uart_rx_addr(dreq_in.addr);
wire is_clint       = MemMap::is_clint_addr(dreq_in.addr);
wire is_edisk       = MemMap::is_edisk_addr(dreq_in.addr);
wire is_memory      = !is_uart_tx & !is_uart_rx & !is_clint & !is_edisk;

wire s_is_uart_tx   = MemMap::is_uart_tx_addr(s_dreq.addr);
wire s_is_uart_rx   = MemMap::is_uart_rx_addr(s_dreq.addr);
wire s_is_clint     = MemMap::is_clint_addr(s_dreq.addr);
wire s_is_edisk     = MemMap::is_edisk_addr(s_dreq.addr);
wire s_is_memory    = !s_is_uart_tx & !s_is_uart_rx & !s_is_clint & !s_is_edisk;

wire cmd_start  = !reset & (
                    state == WAIT_READY |
                    (state == IDLE | (state == WAIT_VALID & s_valid)) & dreq_in.valid);
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

// TODO ここらへんの三項演算子をcaseにする
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


wire Addr   req_addr    = state == WAIT_READY ? s_dreq.addr : dreq_in.addr;
wire        req_wen     = state == WAIT_READY ? s_dreq.wen  : dreq_in.wen;
wire UIntX  req_wdata   = state == WAIT_READY ? s_dreq.wdata: dreq_in.wdata;
wire MemSize req_wmask  = MemSize'(state == WAIT_READY ? s_dreq.wmask: dreq_in.wmask);
wire MemSize req_pte    = MemSize'(state == WAIT_READY ? s_dreq.pte: dreq_in.pte);

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
    if (util::logEnabled()) begin
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

assign memreq_in.valid  = is_memory & cmd_start;
assign memreq_in.addr   = req_addr;
assign memreq_in.wen    = req_wen;
assign memreq_in.wdata  = req_wdata;
assign memreq_in.wmask  = req_wmask;
assign memreq_in.pte    = req_pte;

MMIO_uart_rx memmap_uartrx (
    .clk(clk),
    .uart_rx(uart_rx),

    .req_ready(cmd_uart_rx_ready),
    .req_valid(cmd_uart_rx_start),
    .req_addr({{XLEN-4{1'b0}}, req_addr[3:0]}),
    .req_wen(req_wen),
    .req_wdata(req_wdata),
    .resp_valid(cmd_uart_rx_rvalid),
    .resp_rdata(cmd_uart_rx_rdata),

    .uart_rx_pending(uart_rx_pending)
);

MMIO_uart_tx memmap_uarttx (
    .clk(clk),
    .uart_tx(uart_tx),

    .req_ready(cmd_uart_tx_ready),
    .req_valid(cmd_uart_tx_start),
    .req_addr(0),
    .req_wen(req_wen),
    .req_wdata(req_wdata),
    .resp_valid(cmd_uart_tx_rvalid),
    .resp_rdata(cmd_uart_tx_rdata)
);

MMIO_clint memmap_clint (
    .clk(clk),

    .req_ready(cmd_clint_ready),
    .req_valid(cmd_clint_start),
    .req_addr({{XLEN-4{1'b0}}, req_addr[3:0]}),
    .req_wen(req_wen),
    .req_wdata(req_wdata),
    .resp_valid(cmd_clint_rvalid),
    .resp_rdata(cmd_clint_rdata),
    .mti_pending(mti_pending)
);

`ifndef EDISK_WIDTH
    `define EDISK_WIDTH 23
    initial $display("WARN: edisk width (EDISK_WIDTH) is not set. default to %d", `EDISK_WIDTH);
`endif

MMIO_EDisk #(
    .WIDTH(`EDISK_WIDTH)
) edisk (
    .clk(clk),

    .req_ready(cmd_edisk_ready),
    .req_valid(cmd_edisk_start),
    .req_addr({{XLEN-8{1'b0}}, req_addr[7:0]}),
    .req_wen(req_wen),
    .req_wdata(req_wdata),
    .resp_valid(cmd_edisk_rvalid),
    .resp_rdata(cmd_edisk_rdata)
);

endmodule