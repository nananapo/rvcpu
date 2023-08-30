module MMIO_uart_rx #(
    parameter FMAX_MHz = 27
)(
    input  wire clk,
    input  wire uart_rx,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UInt32  req_wdata,
    
    output wire     resp_valid,
    output UInt32   resp_rdata
);

`include "include/memorymap.sv"

localparam STATE_IDLE                       = 0;
localparam STATE_WRITE_MEM                  = 1;
localparam STATE_READBUF_AFTER_RX           = 2;
localparam STATE_READBUF_BEFORE_WRITE_MEM   = 3;

// メモリ
logic [31:0] buffer[255:0];
logic [9:0]  buffer_tail  = 0;
logic [31:0] buffer_count = 0;

`ifdef DEBUG
initial begin
    $readmemh("../test/bin/mem256zero.hex", buffer, 0, 255);
end
`endif

wire is_tail_addr   = req_addr == UART_RX_BUFFER_TAIL_OFFSET;
wire is_count_addr  = req_addr == UART_RX_BUFFER_COUNT_OFFSET;
wire is_buffer_addr = !is_count_addr && !is_tail_addr; 

// UART
wire [7:0]  rx_rdata;
wire        rx_rvalid;

Uart_rx #(
    .FMAX_MHz(FMAX_MHz)
) rxModule(
    .clk(clk),
    .rdata(rx_rdata),
    .rvalid(rx_rvalid),
    .uart_rx(uart_rx)
);

// アドレスは4byteずつ
function [7:0] func_read_addr(
    input [1:0] state,
    input       rx_rvalid,
    input [9:0] buffer_tail,
    input [31:0]req_addr
);
    case (state)
        STATE_IDLE                      : func_read_addr = rx_rvalid ? buffer_tail[9:2] : req_addr[9:2];
        STATE_WRITE_MEM                 : func_read_addr = req_addr[9:2];
        STATE_READBUF_AFTER_RX          : func_read_addr = req_addr[9:2];
        STATE_READBUF_BEFORE_WRITE_MEM  : func_read_addr = buffer_tail[9:2];
        default                         : func_read_addr = 0;
    endcase
endfunction

wire [7:0] read_addr    = func_read_addr(state, rx_rvalid, buffer_tail, req_addr);
wire [7:0] write_addr   = buffer_tail[9:2];

// 状態
logic [1:0] state = STATE_IDLE;

// バッファから読んだデータ
logic [31:0] buf_rdata = 0;
// UART
logic [7:0] uart_rdata = 0;

function [31:0] func_buf_wdata(
    input [31:0] buf_rdata,
    input [7:0] uart_rdata,
    input [1:0]  addr_mod
);
    case (addr_mod) 
        0: func_buf_wdata = {buf_rdata[31:8], uart_rdata};
        1: func_buf_wdata = {buf_rdata[31:16], uart_rdata, buf_rdata[7:0]};
        2: func_buf_wdata = {buf_rdata[31:24], uart_rdata, buf_rdata[15:0]};
        3: func_buf_wdata = {uart_rdata, buf_rdata[23:0]};
    endcase
endfunction
wire [31:0] buf_wdata = func_buf_wdata(buf_rdata, uart_rdata, buffer_tail[1:0]);

assign req_ready     = state == STATE_IDLE;
assign resp_valid   = is_tail_addr || is_count_addr || (
    is_buffer_addr ?
        state == STATE_READBUF_BEFORE_WRITE_MEM || state == STATE_IDLE
        : 0
);

logic save_req_valid = 0;
logic save_req_wen = 0;

always @(posedge clk) begin

    if (is_tail_addr)
        resp_rdata <= {22'b0, buffer_tail};
    else if (is_count_addr)
        resp_rdata <= buffer_count;
    else if (is_buffer_addr)
        resp_rdata <= buf_rdata;

    buf_rdata            <= buffer[read_addr];
    save_req_valid <= req_valid;
    save_req_wen <= req_wen;

    case (state)
        STATE_IDLE: begin
            if (rx_rvalid) begin
                state       <= STATE_WRITE_MEM;
                uart_rdata  <= rx_rdata;
            end else if (req_valid) begin
                state       <= STATE_READBUF_AFTER_RX;
            end
        end
        STATE_WRITE_MEM: begin
            buffer[write_addr]  <= buf_wdata;
            buffer_tail         <= buffer_tail + 1;
            if (buffer_tail == 10'd1023)
                buffer_count <= buffer_count + 1;
            
            if (save_req_valid && is_buffer_addr)
                state <= STATE_READBUF_AFTER_RX;
            else
                state <= STATE_IDLE;
        end
        STATE_READBUF_AFTER_RX: begin
            state <= STATE_IDLE;
            if (rx_rvalid) begin
                uart_rdata  <= rx_rdata;
                state       <= STATE_READBUF_BEFORE_WRITE_MEM;
            end
        end
        STATE_READBUF_BEFORE_WRITE_MEM: begin
            state <= STATE_WRITE_MEM;
            // ここでcmdのbuf_rdataは読めるようになってる
        end
    endcase
end


`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    // $display("info,memmapio.uart_rx.buffer,Buffer : %d (%d)", buffer_tail, buffer_count);
    // $display("info,memmapio.uart_rx.buffer_data,BufferData : %d 0x%h %d %h", read_addr, buffer[read_addr], resp_valid, resp_rdata);
    // if (state == STATE_IDLE && rx_rvalid) begin
    //      $display("info,memmapio.uart_rx.rvalid, rvalid 0x%h : %d", rx_rdata, buffer_tail[1:0]);
    // end
end
`endif


endmodule