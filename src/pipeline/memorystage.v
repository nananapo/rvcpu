module MemoryStage(
	input wire clk,

	input [31:0] rs2_data,
	input [3:0]  wb_sel,
	input [4:0]  mem_wen,

	input [31:0] alu_out,
	
    output wire [4:0]  memory_cmd,
	input  wire        memory_cmd_ready,
    output wire [31:0] memory_d_addr,
    input  wire [31:0] memory_rdata,
	input  wire        memory_rdata_valid, 
    output wire [31:0] memory_wmask,
    output wire [31:0] memory_wdata
);

`include "../consts_core.v"

endmodule