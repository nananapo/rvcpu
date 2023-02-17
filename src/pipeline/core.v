module CorePipeline(
    input   wire        clk,

    output  wire [31:0] memory_i_addr,
    input   wire [31:0] memory_inst,
	
    output wire [4:0]  memory_cmd,
	input  wire        memory_cmd_ready,
    output wire [31:0] memory_d_addr,
    input  wire [31:0] memory_rdata,
    output wire [31:0] memory_wmask,
    output wire [31:0] memory_wdata
);

// レジスタ
reg [31:0] regfile [31:0];

integer loop_i;
initial begin
	regfile[0] = 0;
	regfile[1] = 0;
	regfile[2] = 1000;
    for (loop_i = 3; loop_i < 32; loop_i = loop_i + 1)
        regfile[loop_i] = 0;
end

// fetch stage
reg [31:0] if_reg_pc = 0;
assign memory_i_addr = if_reg_pc;

// fetch -> decode stage 用のレジスタ
reg [31:0]  id_inst;
reg [31:0]  id_reg_pc;



// 最初のクロックだけ休む用のフラグ
reg firstClock = 0;

// fetch stage
always @(posedge clk) begin
	if (firstClock == 0) begin
		firstClock <= 1;
    	if_reg_pc <= if_reg_pc + 4;
	end else begin 
    	id_inst <= memory_inst;
		id_reg_pc <= if_reg_pc - 4;
    	if_reg_pc <= if_reg_pc + 4;
	end

	$display("FETCH -------------");
    $display("if.reg_pc  : 0x%H", if_reg_pc);
    $display("id.reg_pc  : 0x%H", id_reg_pc);
    $display("mem.inst  : 0x%H", memory_inst);
    $display("id.inst   : 0x%H", id_inst);
end



//**************************
// Decode Stage
//**************************

// decode -> exe 用のレジスタ
reg [31:0] exe_imm_i_sext;
reg [31:0] exe_imm_s_sext;
reg [31:0] exe_imm_b_sext;
reg [31:0] exe_imm_j_sext;
reg [31:0] exe_imm_u_shifted;
reg [31:0] exe_imm_z_uext;

reg [31:0] exe_reg_pc;
reg [4:0]  exe_exe_fun; // TODO bitwise
reg [31:0] exe_op1_data;
reg [31:0] exe_op2_data;
reg [31:0] exe_rs2_data;
reg [4:0]  exe_mem_wen;
reg [0:0]  exe_rf_wen;
reg [3:0]  exe_wb_sel;
reg [4:0]  exe_wb_addr;
reg [2:0]  exe_csr_cmd;
reg 	   exe_jmp_flg;

DecodeStage #() decodestage
(
    .clk(clk),
    .inst(id_inst),
	.reg_pc(id_reg_pc),

	.regfile(regfile),

	.imm_i_sext(exe_imm_i_sext),
	.imm_s_sext(exe_imm_s_sext),
	.imm_b_sext(exe_imm_b_sext),
	.imm_j_sext(exe_imm_j_sext),
	.imm_u_shifted(exe_imm_u_shifted),
	.imm_z_uext(exe_imm_z_uext),

	.output_reg_pc(exe_reg_pc),
	.exe_fun(exe_exe_fun),
	.op1_data(exe_op1_data),
	.op2_data(exe_op2_data),
	.rs2_data(exe_rs2_data),
	.mem_wen(exe_mem_wen),
	.rf_wen(exe_rf_wen),
	.wb_sel(exe_wb_sel),
	.wb_addr(exe_wb_addr),
	.csr_cmd(exe_csr_cmd),
	.jmp_flg(exe_jmp_flg)
);


//**************************
// Execute Stage
//**************************

reg [31:0] mem_alu_out;
reg        mem_br_flg;
reg [31:0] mem_br_target;

reg [31:0] mem_reg_pc;
reg [4:0]  mem_mem_wen;
reg [3:0]  mem_wb_sel;
reg [31:0] mem_rs2_data;

ExecuteStage #() executestage
(
    .clk(clk),

	.imm_b_sext(exe_imm_b_sext),

	.reg_pc(exe_reg_pc),
	.exe_fun(exe_exe_fun),
	.op1_data(exe_op1_data),
	.op2_data(exe_op2_data),
	.rs2_data(exe_rs2_data),
	.mem_wen(exe_mem_wen),
	.wb_sel(exe_wb_sel),

	.alu_out(mem_alu_out),
	.br_flg(mem_br_flg),
	.br_target(mem_br_target),

	.output_reg_pc(mem_reg_pc),
	.output_mem_wen(mem_mem_wen),
	.output_wb_sel(mem_wb_sel),
	.output_rs2_data(mem_rs2_data)
);


//**************************
// Memory Stage
//**************************
MemoryStage #() memorystage
(
	.clk(clk),

	.rs2_data(mem_rs2_data),
	.wb_sel(mem_wb_sel),
	.mem_wen(mem_mem_wen),

	.alu_out(mem_alu_out),

	.memory_cmd(memory_cmd),
	.memory_cmd_ready(memory_cmd_ready),

	.memory_d_addr(memory_d_addr),
	.memory_rdata(memory_rdata),

	.memory_wmask(memory_wmask),
	.memory_wdata(memory_wdata)
);

reg [31:0] clk_count = 0;

always @(negedge clk) begin
	clk_count <= clk_count + 1;
	$display("");
	$display("CLK %d", clk_count - 1);
end

endmodule