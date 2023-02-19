module FetchStage(
	input  wire			clk,

	output reg			reg_pc,
	output reg [31:0]	inst,

	output reg			memory_inst_start,
	input  reg			memory_inst_ready,
	output reg [31:0]	memory_i_addr,
	input  reg [31:0]	memory_inst,
	input  reg			memory_inst_valid
);

initial begin
	reg_pc <= 0;
	memory_inst_start <= 0;
end


always @(posedge clk) begin
	if (firstClock == 0) begin
		firstClock <= 1;
    	reg_pc <= reg_pc + 4;
	end else begin 
    	id_inst <= memory_inst;
    	reg_pc <= reg_pc + 4;
	end

	$display("FETCH -------------");
    $display("if.reg_pc  : 0x%H", reg_pc);
    $display("id.reg_pc  : 0x%H", id_reg_pc);
    $display("mem.inst  : 0x%H", memory_inst);
    $display("id.inst   : 0x%H", id_inst);
end

endmodule