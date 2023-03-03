module Memory #(
    parameter MEMORY_SIZE = 2048,
    parameter MEMORY_FILE = ""
)(
    input  wire         clk,

    input  wire         cmd_start,
    input  wire         cmd_write,
    output wire         cmd_ready,

    input  wire [31:0]  addr,
    output reg  [31:0]  rdata,
    output wire         rdata_valid,
    input  wire [31:0]  wdata,
    input  wire [31:0]  wmask
);

// memory
reg [31:0] mem [MEMORY_SIZE-1:0];

initial begin
    if (MEMORY_FILE != "") begin
        $readmemh(MEMORY_FILE, mem);
    end
    rdata = 0;
end

wire [31:0] addr_shift = (addr >> 2) % MEMORY_SIZE;

assign cmd_ready    = 1;
assign rdata_valid  = !cmd_write;

always @(posedge clk) begin
    rdata <= {
        mem[addr_shift][7:0],
        mem[addr_shift][15:8],
        mem[addr_shift][23:16],
        mem[addr_shift][31:24]
    };

    if (cmd_start && cmd_write) begin
        mem[addr_shift] = {
            wdata[7:0],
            wdata[15:8],
            wdata[23:16],
            wdata[31:24]
        };
    end
end
endmodule
