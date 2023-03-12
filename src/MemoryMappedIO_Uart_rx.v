module MemoryMappedIO_Uart_rx
(
    input  wire         clk,
    input  wire         uart_rx,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,
    
    input  wire [31:0]  input_addr,
    output reg  [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata
);

`include "include/memorymap.v"

localparam STATE_IDLE               = 0;
localparam STATE_WRITE_MEM          = 1;
localparam STATE_READBUF_AFTER_RX   = 2;

// メモリ
reg [31:0] buffer[255:0];
reg [9:0]  buffer_tail  = 0;
reg [31:0] buffer_count = 0;

`ifdef DEBUG
initial begin
    $readmemh("../test/bin/mem256zero.hex", buffer);
end
`endif

wire is_tail_addr   = input_addr == UART_RX_BUFFER_TAIL_OFFSET;
wire is_count_addr  = input_addr == UART_RX_BUFFER_COUNT_OFFSET;
wire is_buffer_addr = !is_count_addr && !is_tail_addr; 

// UART
wire [7:0]  rx_rdata;
wire        rx_rdata_valid;

Uart_rx #() rxModule(
    .clk(clk),
    .rdata(rx_rdata),
    .rdata_valid(rx_rdata_valid),
    .uart_rx(uart_rx)
);

// アドレスは4byteずつ
function [7:0] func_addr(
    input [1:0] state,
    input       rx_rdata_valid,
    input [9:0] buffer_tail,
    input [31:0]input_addr
);
    case (state)
        STATE_IDLE              : func_addr = rx_rdata_valid ? buffer_tail[9:2] : input_addr[9:2];
        STATE_WRITE_MEM         : func_addr = buffer_tail[9:2];
        STATE_READBUF_AFTER_RX  : func_addr = input_addr[9:2];
        default                 : func_addr = 0;
    endcase
endfunction

wire [7:0] addr     = func_addr(state, rx_rdata_valid, buffer_tail, input_addr);
wire [1:0] addr_mod = buffer_tail[1:0]; // buffer_tail % 4

// 状態
reg [1:0] state = STATE_IDLE;

// バッファから読んだデータ
reg [31:0] buf_rdata = 0;
// UART
reg [7:0] uart_rdata = 0;

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
wire [31:0] buf_wdata = func_buf_wdata(buf_rdata, uart_rdata, addr_mod);

assign output_cmd_ready     = state == STATE_IDLE;
assign output_rdata_valid   = state == STATE_IDLE;

reg save_input_cmd_start = 0;
reg save_input_cmd_write = 0;

always @(posedge clk) begin

    if (is_tail_addr)
        output_rdata <= {22'b0, buffer_tail};
    else if (is_count_addr)
        output_rdata <= buffer_count;
    else if (is_buffer_addr)
        output_rdata <= buffer[addr];

    buf_rdata            <= buffer[addr];
    save_input_cmd_start <= input_cmd_start;
    save_input_cmd_write <= input_cmd_write;

    case (state)
        STATE_IDLE: begin
            if (rx_rdata_valid) begin
                state       <= STATE_WRITE_MEM;
                uart_rdata  <= rx_rdata;
            end
        end
        STATE_WRITE_MEM: begin
            buffer[addr]    <= buf_wdata;
            buffer_tail     <= buffer_tail + 1;
            if (buffer_tail == 10'd1023)
                buffer_count <= buffer_count + 1;
            
            if (save_input_cmd_start && is_buffer_addr)
                state <= STATE_READBUF_AFTER_RX;
            else
                state <= STATE_IDLE;
        end
        STATE_READBUF_AFTER_RX: begin
            state <= STATE_IDLE;
        end
    endcase
end


`ifdef DEBUG
always @(posedge clk) begin
    $display("uart_rx buffer[1024] %d (%d)", buffer_tail, buffer_count);
    $display("uart_rx [%d] in: 0x%h %d %h", addr, buffer[addr], output_rdata_valid, output_rdata);
    if (state == STATE_IDLE && rx_rdata_valid) begin
        $display("uart_rx : 0x%h : %d", rx_rdata, addr_mod);
    end
end
`endif


endmodule