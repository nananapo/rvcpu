module DecodeStage
(
    input  wire	      clk,

    input  reg [31:0] input_inst,
	input  reg [31:0] input_reg_pc,
	input  reg [31:0] regfile[31:0],

    // 即値
	output reg [31:0] output_reg_pc,
    output reg [31:0] imm_i_sext,
    output reg [31:0] imm_s_sext,
    output reg [31:0] imm_b_sext,
    output reg [31:0] imm_j_sext,
    output reg [31:0] imm_u_shifted,
    output reg [31:0] imm_z_uext,

    // csignals
    output reg [4:0]  exe_fun,  // ALUの計算の種類
    output reg [31:0] op1_data, // ALU
    output reg [31:0] op2_data, // ALU
	output reg [31:0] rs2_data, // rs2で指定されたレジスタの値
    output reg [4:0]  mem_wen,  // メモリに書き込むか否か
    output reg [0:0]  rf_wen,   // レジスタに書き込むか否か
    output reg [3:0]  wb_sel,   // ライトバック先
	output reg [4:0]  wb_addr,  // ライトバック先レジスタ番号
    output reg [2:0]  csr_cmd,  // CSR
    output reg 	      jmp_flg,  // ジャンプ命令かのフラグ
	output reg        output_inst_is_ecall, // ecallかどうか

	input  wire       stall_flg
);

`include "include/core.v"
`include "include/inst.v"

reg  [31:0] save_inst	= 0;
reg  [31:0] save_reg_pc	= 0;

wire [31:0] inst	= stall_flg ? save_inst : input_inst;
wire [31:0] reg_pc	= stall_flg ? save_reg_pc : input_reg_pc; 

wire [11:0] wire_imm_i = inst[31:20];
wire [11:0] wire_imm_s = {inst[31:25], inst[11:7]};
wire [11:0] wire_imm_b = {inst[31], inst[7], inst[30:25], inst[11:8]};
wire [19:0] wire_imm_j = {inst[31], inst[19:12], inst[20], inst[30:21]};
wire [19:0] wire_imm_u = inst[31:12];
wire [4:0]  wire_imm_z = inst[19:15];


wire [31:0] wire_imm_i_sext    = {{20{wire_imm_i[11]}}, wire_imm_i};
wire [31:0] wire_imm_s_sext    = {{20{wire_imm_s[11]}}, wire_imm_s};
wire [31:0] wire_imm_b_sext    = {{19{wire_imm_b[11]}}, wire_imm_b, 1'b0};
wire [31:0] wire_imm_j_sext    = {{11{wire_imm_j[19]}}, wire_imm_j, 1'b0};
wire [31:0] wire_imm_u_shifted = {wire_imm_u, 12'b0};
wire [31:0] wire_imm_z_uext    = {27'd0, wire_imm_z};

wire [2:0] funct3 = inst[14:12];
wire [7:0] funct7 = inst[31:25];
wire [6:0] opcode = inst[6:0];

wire inst_is_lb     = (funct3 == INST_LB_FUNCT3 && opcode == INST_LB_OPCODE);
wire inst_is_lbu    = (funct3 == INST_LBU_FUNCT3 && opcode == INST_LBU_OPCODE);
wire inst_is_lh     = (funct3 == INST_LH_FUNCT3 && opcode == INST_LH_OPCODE);
wire inst_is_lhu    = (funct3 == INST_LHU_FUNCT3 && opcode == INST_LHU_OPCODE);
wire inst_is_lw     = (funct3 == INST_LW_FUNCT3 && opcode == INST_LW_OPCODE);
wire inst_is_sb     = (funct3 == INST_SB_FUNCT3 && opcode == INST_SB_OPCODE);
wire inst_is_sh     = (funct3 == INST_SH_FUNCT3 && opcode == INST_SH_OPCODE);
wire inst_is_sw     = (funct3 == INST_SW_FUNCT3 && opcode == INST_SW_OPCODE);
wire inst_is_add    = (funct7 == INST_ADD_FUNCT7 && funct3 == INST_ADD_FUNCT3 && opcode == INST_ADD_OPCODE);
wire inst_is_sub    = (funct7 == INST_SUB_FUNCT7 && funct3 == INST_SUB_FUNCT3 && opcode == INST_SUB_OPCODE);
wire inst_is_addi   = (funct3 == INST_ADDI_FUNCT3 && opcode == INST_ADDI_OPCODE);
wire inst_is_and    = (funct7 == INST_AND_FUNCT7 && funct3 == INST_AND_FUNCT3 && opcode == INST_AND_OPCODE);
wire inst_is_or     = (funct7 == INST_OR_FUNCT7 && funct3 == INST_OR_FUNCT3 && opcode == INST_OR_OPCODE);
wire inst_is_xor    = (funct7 == INST_XOR_FUNCT7 && funct3 == INST_XOR_FUNCT3 && opcode == INST_XOR_OPCODE);
wire inst_is_andi   = (funct3 == INST_ANDI_FUNCT3 && opcode == INST_ANDI_OPCODE);
wire inst_is_ori    = (funct3 == INST_ORI_FUNCT3 && opcode == INST_ORI_OPCODE);
wire inst_is_xori   = (funct3 == INST_XORI_FUNCT3 && opcode == INST_XORI_OPCODE);
wire inst_is_sll    = (funct7 == INST_SLL_FUNCT7 && funct3 == INST_SLL_FUNCT3 && opcode == INST_SLL_OPCODE);
wire inst_is_srl    = (funct7 == INST_SRL_FUNCT7 && funct3 == INST_SRL_FUNCT3 && opcode == INST_SRL_OPCODE);
wire inst_is_sra    = (funct7 == INST_SRA_FUNCT7 && funct3 == INST_SRA_FUNCT3 && opcode == INST_SRA_OPCODE);
wire inst_is_slli   = (funct7 == INST_SLLI_FUNCT7 && funct3 == INST_SLLI_FUNCT3 && opcode == INST_SLLI_OPCODE);
wire inst_is_srli   = (funct7 == INST_SRLI_FUNCT7 && funct3 == INST_SRLI_FUNCT3 && opcode == INST_SRLI_OPCODE);
wire inst_is_srai   = (funct7 == INST_SRAI_FUNCT7 && funct3 == INST_SRAI_FUNCT3 && opcode == INST_SRAI_OPCODE);
wire inst_is_slt    = (funct7 == INST_SLT_FUNCT7 && funct3 == INST_SLT_FUNCT3 && opcode == INST_SLT_OPCODE);
wire inst_is_sltu   = (funct7 == INST_SLTU_FUNCT7 && funct3 == INST_SLTU_FUNCT3 && opcode == INST_SLTU_OPCODE);
wire inst_is_slti   = (funct3 == INST_SLTI_FUNCT3 && opcode == INST_SLTI_OPCODE);
wire inst_is_sltiu  = (funct3 == INST_SLTIU_FUNCT3 && opcode == INST_SLTIU_OPCODE);
wire inst_is_beq    = (funct3 == INST_BEQ_FUNCT3 && opcode == INST_BEQ_OPCODE);
wire inst_is_bne    = (funct3 == INST_BNE_FUNCT3 && opcode == INST_BNE_OPCODE);
wire inst_is_blt    = (funct3 == INST_BLT_FUNCT3 && opcode == INST_BLT_OPCODE);
wire inst_is_bge    = (funct3 == INST_BGE_FUNCT3 && opcode == INST_BGE_OPCODE);
wire inst_is_bltu   = (funct3 == INST_BLTU_FUNCT3 && opcode == INST_BLTU_OPCODE);
wire inst_is_bgeu   = (funct3 == INST_BGEU_FUNCT3 && opcode == INST_BGEU_OPCODE);
wire inst_is_jal    = (opcode == INST_JAL_OPCODE);
wire inst_is_jalr   = (funct3 == INST_JALR_FUNCT3 && opcode == INST_JALR_OPCODE);
wire inst_is_lui    = (opcode == INST_LUI_OPCODE);
wire inst_is_auipc  = (opcode == INST_AUIPC_OPCODE);
wire inst_is_csrrw  = (funct3 == INST_CSRRW_FUNCT3 && opcode == INST_CSRRW_OPCODE);
wire inst_is_csrrwi = (funct3 == INST_CSRRWI_FUNCT3 && opcode == INST_CSRRWI_OPCODE);
wire inst_is_csrrs  = (funct3 == INST_CSRRS_FUNCT3 && opcode == INST_CSRRS_OPCODE);
wire inst_is_csrrsi = (funct3 == INST_CSRRSI_FUNCT3 && opcode == INST_CSRRSI_OPCODE);
wire inst_is_csrrc  = (funct3 == INST_CSRRC_FUNCT3 && opcode == INST_CSRRC_OPCODE);
wire inst_is_csrrci = (funct3 == INST_CSRRCI_FUNCT3 && opcode == INST_CSRRCI_OPCODE);
wire inst_is_ecall  = inst == INST_ECALL;

wire [4:0] wire_exe_fun;
wire [3:0] wire_op1_sel;
wire [3:0] wire_op2_sel;
wire [4:0] wire_mem_wen;
wire [0:0] wire_rf_wen;
wire [3:0] wire_wb_sel;
wire [2:0] wire_csr_cmd;

assign {wire_exe_fun, wire_op1_sel, wire_op2_sel, wire_mem_wen, wire_rf_wen, wire_wb_sel, wire_csr_cmd} = (
    inst_is_lb    ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LB, REN_S, WB_MEMB , CSR_X} :
    inst_is_lbu   ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LBU,REN_S, WB_MEMBU, CSR_X} :
    inst_is_lh    ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LH, REN_S, WB_MEMH , CSR_X} :
    inst_is_lhu   ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LHU,REN_S, WB_MEMHU, CSR_X} :
    inst_is_lw    ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LW, REN_S, WB_MEMW , CSR_X} :
    inst_is_sb    ? {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_SB, REN_X, WB_X    , CSR_X} :
    inst_is_sh    ? {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_SH, REN_X, WB_X    , CSR_X} :
    inst_is_sw    ? {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_SW, REN_X, WB_X    , CSR_X} :
    inst_is_add   ? {ALU_ADD  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_addi  ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_sub   ? {ALU_SUB  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_and   ? {ALU_AND  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_or    ? {ALU_OR   , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_xor   ? {ALU_XOR  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_andi  ? {ALU_AND  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_ori   ? {ALU_OR   , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
    inst_is_xori  ? {ALU_XOR  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_sll   ? {ALU_SLL  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_srl   ? {ALU_SRL  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_sra   ? {ALU_SRA  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_slli  ? {ALU_SLL  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_srli  ? {ALU_SRL  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_srai  ? {ALU_SRA  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_slt   ? {ALU_SLT  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_sltu  ? {ALU_SLTU , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_slti  ? {ALU_SLT  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_sltiu ? {ALU_SLTU , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_beq   ? {BR_BEQ   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X} :
	inst_is_bne   ? {BR_BNE   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X} :
	inst_is_blt   ? {BR_BLT   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X} :
	inst_is_bge   ? {BR_BGE   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X} :
	inst_is_bltu  ? {BR_BLTU  , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X} :
	inst_is_bgeu  ? {BR_BGEU  , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X} :
	inst_is_jal   ? {ALU_ADD  , OP1_PC , OP2_IMJ , MEN_X , REN_S, WB_PC   , CSR_X} :
	inst_is_jalr  ? {ALU_JALR , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_PC   , CSR_X} :
	inst_is_lui   ? {ALU_ADD  , OP1_X  , OP2_IMU , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_auipc ? {ALU_ADD  , OP1_PC , OP2_IMU , MEN_X , REN_S, WB_ALU  , CSR_X} :
	inst_is_csrrw ? {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_W} :
	inst_is_csrrwi? {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_W} :
	inst_is_csrrs ? {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_S} :
	inst_is_csrrsi? {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_S} :
	inst_is_csrrc ? {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_C} :
	inst_is_csrrci? {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_C} :
	inst_is_ecall ? {ALU_X    , OP1_X  , OP2_X   , MEN_X , REN_X, WB_X    , CSR_E} :
    0
);

wire [4:0] wire_rs1_addr = inst[19:15];
wire [4:0] wire_rs2_addr = inst[24:20];
wire [4:0] wire_wb_addr  = inst[11:7];

always @(posedge clk) begin
    imm_i_sext      <= wire_imm_i_sext;
    imm_s_sext      <= wire_imm_s_sext;
    imm_b_sext      <= wire_imm_b_sext;
    imm_j_sext      <= wire_imm_j_sext;
    imm_u_shifted   <= wire_imm_u_shifted;
    imm_z_uext      <= wire_imm_z_uext;

    op1_data <= (
        wire_op1_sel == OP1_RS1 ? (wire_rs1_addr == 0) ? 0 : regfile[wire_rs1_addr] :
        wire_op1_sel == OP1_PC  ? reg_pc :
        wire_op1_sel == OP1_IMZ ? wire_imm_z_uext :
        0
    );

    op2_data <= (
        wire_op2_sel == OP2_RS2W ? (wire_rs2_addr == 0) ? 0 : regfile[wire_rs2_addr] :
        wire_op2_sel == OP2_IMI  ? wire_imm_i_sext :
        wire_op2_sel == OP2_IMS  ? wire_imm_s_sext :
        wire_op2_sel == OP2_IMJ  ? wire_imm_j_sext :
        wire_op2_sel == OP2_IMU  ? wire_imm_u_shifted :
        0
    );

	rs2_data				<= (wire_rs2_addr == 0) ? 0 : regfile[wire_rs2_addr];
    jmp_flg					<= inst_is_jal || inst_is_jalr;
	output_inst_is_ecall	<= inst_is_ecall;

	output_reg_pc <= reg_pc;
    exe_fun <= wire_exe_fun;
    mem_wen <= wire_mem_wen;
    rf_wen  <= wire_rf_wen;
    wb_sel  <= wire_wb_sel;
	wb_addr <= wire_wb_addr;
    csr_cmd	<= wire_csr_cmd;

	// save
	save_inst	<= inst;
	save_reg_pc	<= reg_pc;
end

always @(posedge clk) begin
	$display("DECODE STAGE-------------");
    $display("reg_pc    : 0x%H", reg_pc);
    $display("inst      : 0x%H", inst);
    $display("rs1_addr  : %d", wire_rs1_addr);
    $display("rs2_addr  : %d", wire_rs2_addr);
    $display("wb_addr   : %d", wire_wb_addr);
	$display("op1_data  : %H", (
        wire_op1_sel == OP1_RS1 ? (wire_rs1_addr == 0) ? 0 : regfile[wire_rs1_addr] :
        wire_op1_sel == OP1_PC  ? reg_pc :
        wire_op1_sel == OP1_IMZ ? wire_imm_z_uext :
        0
    ));
	$display("op2_data  : %H", (
        wire_op2_sel == OP2_RS2W ? (wire_rs2_addr == 0) ? 0 : regfile[wire_rs2_addr] :
        wire_op2_sel == OP2_IMI  ? wire_imm_i_sext :
        wire_op2_sel == OP2_IMS  ? wire_imm_s_sext :
        wire_op2_sel == OP2_IMJ  ? wire_imm_j_sext :
        wire_op2_sel == OP2_IMU  ? wire_imm_u_shifted :
        0
    ));
end

endmodule