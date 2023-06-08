module UARTMemory #(
    parameter FMAX_MHz = 27 
)(
    input  wire         clk,
    input  wire         uart_rx,
    output wire         uart_tx,

    input  wire         cmd_start,
    input  wire         cmd_write,
    output reg          cmd_ready,

    input  wire [31:0]  addr,
    output reg  [31:0]  rdata,
    output reg          rdata_valid,
    input  wire [31:0]  wdata
);

initial begin
    cmd_ready   = 1;
    rdata       = 0;
    rdata_valid = 0;
end

wire [7:0]  rx_rdata;
wire        rx_rdata_valid;

reg         tx_start = 0;
reg  [7:0]  tx_data  = 0;
wire        tx_ready;

Uart_rx #(
    .FMAX_MHz(FMAX_MHz)
) rxModule (
    .clk(clk),
    .uart_rx(uart_rx),
    .rdata(rx_rdata),
    .rdata_valid(rx_rdata_valid)
);

Uart_tx #() txModule(
    .clk(clk),
    .start(tx_start),
    .data(tx_data),
    .ready(tx_ready),
    .uart_tx(uart_tx)
);

localparam STATE_IDLE               = 0;
localparam STATE_SEND_CMD           = 1;
localparam STATE_SEND_CMD_RESET     = 2;
localparam STATE_SEND_ADDR          = 3;
localparam STATE_SEND_ADDR_RESET    = 4;
localparam STATE_SEND_DATA          = 5;
localparam STATE_SEND_DATA_RESET    = 6;
localparam STATE_RECEIVE_DATA       = 7;
localparam STATE_END                = 8;

reg [3:0]   state = STATE_IDLE;

reg         save_cmd_write;
reg [31:0]  save_addr;
reg [31:0]  save_wdata;
reg [2:0]   count;

always @(posedge clk) begin
    case (state) 
        STATE_IDLE: begin
            if (cmd_start) begin
                state           <= STATE_SEND_CMD;
                save_cmd_write  <= cmd_write;
                save_addr       <= addr;
                save_wdata      <= wdata;
                cmd_ready       <= 0;
            end
        end
        STATE_SEND_CMD: begin
            if (tx_ready) begin
                state       <= STATE_SEND_CMD_RESET;
                tx_start    <= 1;
                tx_data     <= {7'b0, save_cmd_write};
            end
        end
        STATE_SEND_CMD_RESET: begin
            state       <= STATE_SEND_ADDR;
            tx_start    <= 0;
            count       <= 0;
        end
        STATE_SEND_ADDR: begin
            if (tx_ready) begin
                state       <= STATE_SEND_ADDR_RESET;
                count       <= count + 1;
                tx_start    <= 1;
                case (count) 
                    0 : tx_data <= save_addr[31:24];
                    1 : tx_data <= save_addr[23:16];
                    2 : tx_data <= save_addr[15:8];
                    3 : tx_data <= save_addr[7:0];
                endcase
            end
        end
        STATE_SEND_ADDR_RESET: begin
            tx_start <= 0;
            if (count == 4) begin
                state <= save_cmd_write ? STATE_SEND_DATA : STATE_RECEIVE_DATA;
                count <= 0;
            end else 
                state <= STATE_SEND_ADDR;
        end
        STATE_SEND_DATA: begin
            if (tx_ready) begin
                state       <= STATE_SEND_DATA_RESET;
                tx_start    <= 1;
                count       <= count + 1;
                case (count) 
                    0 : tx_data <= save_wdata[31:24];
                    1 : tx_data <= save_wdata[23:16];
                    2 : tx_data <= save_wdata[15:8];
                    3 : tx_data <= save_wdata[7:0];
                endcase
            end
        end
        STATE_SEND_DATA_RESET: begin
            tx_start <= 0;
            if (count == 4)
                state <= STATE_END;
            else
                state <= STATE_SEND_DATA;
        end
        STATE_RECEIVE_DATA: begin
            if (rx_rdata_valid) begin
                count       <= count + 1;
                case (count) 
                    0 : rdata[31:24] <= rx_rdata;
                    1 : rdata[23:16] <= rx_rdata;
                    2 : rdata[15:8]  <= rx_rdata;
                    3 : rdata[7:0]   <= rx_rdata;
                endcase
                if (count == 3) begin
                    state       <= STATE_END;
                    rdata_valid <= 1;
                end
            end
        end
        STATE_END: begin
            tx_start    <= 0;
            state       <= STATE_IDLE;
            cmd_ready   <= 1;
            rdata_valid <= 0;
        end
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,uart_mem.state,d,%b", state);
    $display("data,uart_mem.cmd_start,b,%b", cmd_start);
    $display("data,uart_mem.cmd_write,b,%b", cmd_write);
    $display("data,uart_mem.cmd_ready,b,%b", cmd_ready);
end
`endif

endmodule