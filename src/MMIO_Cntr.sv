module MMIO_Cntr #(
    parameter FMAX_MHz = 27
) (
    input  wire clk,

    input  wire uart_rx,
    output wire uart_tx,
    input  wire UInt64  mtime,
    output wire UInt64  mtimecmp,

    inout  wire DReq    dreq_in,
    inout  wire DResp   dresp_in,
    inout  wire DCacheReq   creq_in,
    inout  wire DCacheResp  cresp_in
);

typedef enum logic [1:0] {
    IDLE,
    WAIT_READY,
    READ_VALID
} statetype;

statetype state = IDLE;
DReq  s_dreq;


initial begin
    s_dreq.valid = 0;
end

wire DReq dreq  = state == IDLE ? dreq_in : s_dreq;

`include "include/memorymap.sv"
wire is_uart_tx     = UART_TX_OFFSET <= dreq.addr   && dreq.addr <= UART_TX_END;
wire is_uart_rx     = UART_RX_OFFSET <= dreq.addr   && dreq.addr <= UART_RX_END;
wire is_clint       = CLINT_OFFSET   <= dreq.addr   && dreq.addr <= CLINT_END;
wire is_memory      = !is_uart_tx && !is_uart_rx && !is_clint;

wire s_is_uart_tx   = UART_TX_OFFSET <= s_dreq.addr && s_dreq.addr <= UART_TX_END;
wire s_is_uart_rx   = UART_RX_OFFSET <= s_dreq.addr && s_dreq.addr <= UART_RX_END;
wire s_is_clint     = CLINT_OFFSET   <= s_dreq.addr && s_dreq.addr <= CLINT_END;
wire s_is_memory    = !s_is_uart_tx && !s_is_uart_rx && !s_is_clint;

wire cmd_start  = (state == IDLE || state == WAIT_READY) && dreq.valid;
wire cmd_ready  =   is_uart_tx ? cmd_uart_tx_ready : 
                    is_uart_rx ? cmd_uart_rx_ready :
                    is_clint   ? cmd_clint_ready :
                    creq_in.ready;
                    
/* verilator lint_off UNOPTFLAT */
wire s_rvalid   = s_dreq.valid && (
                    (s_is_memory  && cresp_in.valid) ||
                    (s_is_uart_tx && cmd_uart_tx_rvalid) || 
                    (s_is_uart_rx && cmd_uart_rx_rvalid) || 
                    (s_is_clint   && cmd_clint_rvalid) );
/* verilator lint_on UNOPTFLAT */

wire [31:0] s_rdata =   s_is_memory  ? cresp_in.rdata :
                        s_is_uart_tx ? cmd_uart_tx_rdata :
                        s_is_uart_rx ? cmd_uart_rx_rdata :
                        /*s_is_clint   ?*/cmd_clint_rdata /*: 32'bx */;

assign dreq_in.ready    = state == IDLE || (state == READ_VALID && s_rvalid);

assign dresp_in.valid   = s_rvalid;
assign dresp_in.addr    = s_dreq.addr;
assign dresp_in.rdata   = s_rdata;

assign creq_in.valid    = is_memory && cmd_start;
assign creq_in.addr     = dreq.addr;
assign creq_in.wen      = dreq.wen;
assign creq_in.wdata    = dreq.wdata;

always @(posedge clk) begin
    case (state)
        IDLE: if (dreq_in.valid) begin
            s_dreq  <= dreq_in;
            state   <= cmd_ready ? (dreq.wen ? IDLE : READ_VALID) : WAIT_READY;
        end
        WAIT_READY: if (cmd_ready) state <= dreq.wen ? IDLE : READ_VALID;
        READ_VALID: if (s_rvalid) state <= IDLE;
        default: state <= IDLE;
    endcase
end

wire        cmd_uart_tx_ready;
wire        cmd_uart_rx_ready;
wire        cmd_clint_ready;
wire        cmd_uart_tx_rvalid;
wire        cmd_uart_rx_rvalid;
wire        cmd_clint_rvalid;
wire UInt32 cmd_uart_tx_rdata;
wire UInt32 cmd_uart_rx_rdata;
wire UInt32 cmd_clint_rdata;
wire        cmd_uart_tx_start = is_uart_tx && cmd_start;
wire        cmd_uart_rx_start = is_uart_rx && cmd_start;
wire        cmd_clint_start   = is_clint && cmd_start;
wire Addr   cmd_uart_tx_addr  = dreq.addr - UART_TX_OFFSET;
wire Addr   cmd_uart_rx_addr  = dreq.addr - UART_RX_OFFSET;
wire Addr   cmd_clint_addr    = dreq.addr - CLINT_OFFSET;

MMIO_uart_rx #(
    .FMAX_MHz(FMAX_MHz)
) memmap_uartrx (
    .clk(clk),
    .uart_rx(uart_rx),

    .req_ready(cmd_uart_rx_ready),
    .req_valid(cmd_uart_rx_start),
    .req_addr(cmd_uart_rx_addr),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_uart_rx_rvalid),
    .resp_rdata(cmd_uart_rx_rdata)
);

MMIO_uart_tx #(
    .FMAX_MHz(FMAX_MHz)
) memmap_uarttx (
    .clk(clk),
    .uart_tx(uart_tx),

    .req_ready(cmd_uart_tx_ready),
    .req_valid(cmd_uart_tx_start),
    .req_addr(cmd_uart_tx_addr),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_uart_tx_rvalid),
    .resp_rdata(cmd_uart_tx_rdata)
);

MMIO_clint #(
    .FMAX_MHz(FMAX_MHz)
) memmap_clint (
    .clk(clk),

    .req_ready(cmd_clint_ready),
    .req_valid(cmd_clint_start),
    .req_addr(cmd_clint_addr),
    .req_wen(dreq.wen),
    .req_wdata(dreq.wdata),
    .resp_valid(cmd_clint_rvalid),
    .resp_rdata(cmd_clint_rdata),

    .mtime(mtime),
    .mtimecmp(mtimecmp)
);

endmodule