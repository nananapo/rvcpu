module MemoryMappedIO_Uart_tx #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,
    output wire         uart_tx,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,
    
    input  wire [31:0]  input_addr,
    output logic [31:0] output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata
);

`include "include/memorymap.sv"

logic [31:0]  buffer[63:0];
logic  [7:0]  queue_tail  = 0;
logic  [7:0]  queue_head  = 0;

integer loop_i;
initial begin
    for (loop_i = 0; loop_i < 64; loop_i = loop_i + 1)
        buffer[loop_i] = 32'b0;
end

assign output_cmd_ready     = 1;
assign output_rdata_valid   = 1;

wire [5:0] buffer_addr  = input_addr[7:2];

wire is_queue_head_addr = input_addr == UART_TX_QUEUE_HEAD_OFFSET;
wire is_queue_tail_addr = input_addr == UART_TX_QUEUE_TAIL_OFFSET;
wire is_buffer_addr     = !is_queue_head_addr && !is_queue_tail_addr; 

// メモリ
always @(posedge clk) begin
    if (is_buffer_addr)
        output_rdata <= buffer[buffer_addr];
    else if (is_queue_head_addr)
        output_rdata <= {24'b0, queue_head};
    else if (is_queue_tail_addr)
        output_rdata <= {24'b0, queue_tail};

    if (input_cmd_start && input_cmd_write) begin
        if (is_buffer_addr)
            buffer[buffer_addr] <= input_wdata;
        else if (is_queue_tail_addr)
            queue_tail          <= input_wdata[7:0];
    end        
end

// UART
logic         tx_start    = 0;
logic [7:0]   tx_data     = 0;
wire        tx_ready;

Uart_tx #(
    .FMAX_MHz(FMAX_MHz)
) txModule(
    .clk(clk),

    .start(tx_start),
    .data(tx_data),
    .ready(tx_ready),
    .uart_tx(uart_tx)
);

// アドレスは4byteずつ
wire [5:0] addr     = queue_head[7:2]; // queue_head >> 2
wire [1:0] addr_mod = queue_head[1:0]; // queue_head % 4

// 状態
localparam STATE_IDLE       = 0;
localparam STATE_WAIT_READY = 1;

logic state = STATE_IDLE;

// バッファから読んだデータ
logic [31:0] rdata = 0;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            tx_start    <= 0;
            if (queue_tail != queue_head) begin
                state   <= STATE_WAIT_READY;
                rdata   <= buffer[addr];
            end
        end
        STATE_WAIT_READY: begin
            if (tx_ready) begin
                tx_start    <= 1;
                case (addr_mod)
                    0: begin
                        tx_data  <= rdata[7:0];
                        `ifndef PRINT_DEBUGINFO
                            $write("%c", rdata[7:0]);
                        `else
                            // $display("data,uart_tx.out,b,%b", rdata[7:0]);
                        `endif
                    end
                    1: begin 
                        tx_data  <= rdata[15:8];
                        `ifndef PRINT_DEBUGINFO
                            $write("%c", rdata[15:8]);
                        `else
                            // $display("data,uart_tx.out,b,%b", rdata[15:8]);
                        `endif
                    end
                    2: begin 
                        tx_data  <= rdata[23:16];
                        `ifndef PRINT_DEBUGINFO
                            $write("%c", rdata[23:16]);
                        `else
                            // $display("data,uart_tx.out,b,%b", rdata[23:16]);
                        `endif
                    end
                    3: begin 
                        tx_data  <= rdata[31:24];
                        `ifndef PRINT_DEBUGINFO
                            $write("%c", rdata[31:24]);
                        `else
                            // $display("data,uart_tx.out,b,%b", rdata[31:24]);
                        `endif
                    end
                endcase
                $fflush();
                queue_head  <= queue_head + 1;
                state       <= STATE_IDLE;
            end
        end
    endcase
end



`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("info,memmapio.uart_tx.queue,queue: %d -> %d", queue_head, queue_tail);
    if (state == STATE_WAIT_READY && tx_ready) begin
        $display("info,memmapio.uart_tx.send,send : 0x%h (%d) : %d", rdata, rdata, addr_mod);
    end
end
`endif

endmodule