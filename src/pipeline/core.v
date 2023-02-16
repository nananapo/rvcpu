module CorePipeline(
    input   wire        clk,
    output  wire [31:0] memory_i_addr,
    input   wire [31:0] memory_inst,
    output  wire [31:0] memory_d_addr,
    input   wire [31:0] memory_rdata,
    output  wire        memory_wen,
    output  wire [31:0] memory_wmask,
    output  wire [31:0] memory_wdata,
    input   wire        memory_ready
);



reg [31:0] regfile [31:0];


// fetch stage
reg [31:0] if_reg_pc = 0;

// decode stage
reg [31:0] id_inst;

assign memory_i_addr = if_reg_pc;

// fetch stage
always @(posedge clk) begin
    id_inst <= memory_inst;
    if_reg_pc <= if_reg_pc + 4;
end



//**************************
// Decode Stage
//**************************

reg [31:0] id_imm_i_sext;
reg [31:0] id_imm_s_sext;
reg [31:0] id_imm_b_sext;
reg [31:0] id_imm_j_sext;
reg [31:0] id_imm_u_shifted;
reg [31:0] id_imm_z_uext;

reg [4:0]  id_ex_fun;
reg [31:0] id_op1_data;
reg [31:0] id_op2_data;
reg [0:0]  id_me_wen;
reg [0:0]  id_rfwen;
reg [3:0]  id_wbsel;
reg [2:0]  id_csr_cmd;
reg 	   id_jmp_flg;

DecodeStage #() decodestage
(
    .clk(clk),
    .inst(id_inst),

	.regfile(regfile),

	.imm_i_sext(id_imm_i_sext),
	.imm_s_sext(id_imm_s_sext),
	.imm_b_sext(id_imm_b_sext),
	.imm_j_sext(id_imm_j_sext),
	.imm_u_shifted(id_imm_u_shifted),
	.imm_z_uext(id_imm_z_uext),

	.exe_fun(id_ex_fun),
	.op1_data(id_op1_data),
	.op2_data(id_op2_data),
	.mem_wen(id_me_wen),
	.rf_wen(id_rfwen),
	.wb_sel(id_wbsel),
	.csr_cmd(id_csr_cmd),
	.jmp_flg(id_jmp_flg)
);

always @(posedge clk) begin
    $display("reg_pc    : 0x%H", if_reg_pc);
    $display("mem.inst  : 0x%H", memory_inst);
    $display("id.inst   : 0x%H", id_inst);
    $display("--------");
end

endmodule