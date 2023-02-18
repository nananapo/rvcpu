module Memory (
    input  wire clk,
    input  wire [4:0]  cmd,
    output wire        cmd_ready,
    input  wire [31:0] addr,
    output reg  [31:0] rdata,
    input  wire [31:0] wdata
);

`include "memory_const.v"

localparam MEMORY_SIZE = 32'd16384;

reg [31:0] mem [(MEMORY_SIZE >> 2) - 1:0];

initial begin
    $readmemh("../../test/bin/sample.hex", mem);
end

reg [4:0]  exec_cmd = MEMORY_CMD_NOP;
reg [31:0] exec_addr;
reg [31:0] exec_wdata;

assign cmd_ready = exec_cmd == MEMORY_CMD_NOP;

always @(posedge clk) begin
	if (exec_cmd == MEMORY_CMD_NOP) begin
		if (cmd != MEMORY_CMD_NOP) begin
			exec_cmd   <= cmd;
			exec_addr  <= (addr >> 2) % MEMORY_SIZE;
			exec_wdata <= wdata;
		end
	end else if (exec_cmd == MEMORY_CMD_READ) begin
		rdata <= {
			mem[exec_addr][7:0],
			mem[exec_addr][15:8], 
			mem[exec_addr][23:16],
			mem[exec_addr][31:24]
		};
		exec_cmd <= MEMORY_CMD_NOP;
	end else if (exec_cmd == MEMORY_CMD_WRITE) begin
		mem[addr] <= {
			wdata[7:0],
			wdata[15:8],
			wdata[23:16],
			wdata[31:24]
		};
		exec_cmd <= MEMORY_CMD_NOP;
	end
end

endmodule
