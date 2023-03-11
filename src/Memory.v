/* verilator lint_off WIDTH */
module Memory #(
    parameter MEMORY_SIZE = 2048,
    parameter MEMORY_FILE = ""
)(
    input  wire         clk,
    input  wire         uart_rx,
    output wire         uart_tx,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,

    input  wire [31:0]  input_addr,
    output reg  [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata
);

// memory
reg [31:0] mem [MEMORY_SIZE-1:0];

initial begin
    if (MEMORY_FILE != "") begin
        $readmemh(MEMORY_FILE, mem);
    end
    output_rdata = 0;
end

wire [31:0] addr_shift = (input_addr >> 2) % MEMORY_SIZE;

assign output_cmd_ready    = 1;
assign output_rdata_valid  = 1;//!cmd_write;

always @(posedge clk) begin
    output_rdata <= {
        mem[addr_shift][7:0],
        mem[addr_shift][15:8],
        mem[addr_shift][23:16],
        mem[addr_shift][31:24]
    };

    if (input_cmd_start && input_cmd_write) begin
        mem[addr_shift] = {
            input_wdata[7:0],
            input_wdata[15:8],
            input_wdata[23:16],
            input_wdata[31:24]
        };
    end
end
endmodule
