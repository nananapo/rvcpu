module Core #(
    parameter WORD_LEN          = 32,
    parameter REGISTER_COUNT    = 32,
    parameter REGISTER_COUNT_BIT= 5,
    parameter IMM_I_BITWISE     = 12,
    parameter IMM_S_BITWISE     = 12,
    parameter IMM_B_BITWISE     = 12,
    parameter IMM_J_BITWISE     = 20,
    parameter IMM_U_BITWISE     = 20,
    parameter IMM_Z_BITWISE     = 5
) (
    input   wire                clk,
    input   wire                rst_n,
    output  wire                exit,

    output  wire [WORD_LEN-1:0] memory_i_addr,
    input   wire [WORD_LEN-1:0] memory_inst,
    output  wire [WORD_LEN-1:0] memory_d_addr,
    input   wire [WORD_LEN-1:0] memory_rdata,
    output  wire                memory_wen,
    output  wire [WORD_LEN-1:0] memory_wmask,
    output  wire [WORD_LEN-1:0] memory_wdata,
    input   wire                memory_ready,

	output	wire [WORD_LEN-1:0] gp
);

`include "consts_core.v"
`include "instdefs.v"

// registers
reg [WORD_LEN-1:0] regfile [REGISTER_COUNT-1:0];
// initialize regfile
integer loop_i;
initial begin
	regfile[0] = 0;
	regfile[1] = 0;
	regfile[2] = 1000;
    for (loop_i = 3; loop_i < REGISTER_COUNT; loop_i = loop_i + 1)
        regfile[loop_i] = 0;
end
reg  [WORD_LEN-1:0] reg_pc = 0;					// プログラムカウンタ
assign gp = regfile[3];


// IF STAGE
reg inst_clk = 0;                               // 命令フェッチ用の待機フラグ
wire [WORD_LEN-1:0] reg_pc_plus4 = reg_pc + 4;	// pc + 4
wire [0:0]          br_flg;						// 分岐のフラグ
wire [WORD_LEN-1:0] br_target;					// 分岐先
wire [0:0]			jmp_flg;					// ジャンプのフラグ

// プログラムカウンタとメモリの命令アドレスを接続
assign memory_i_addr = reg_pc;


// DECODE STAGE
wire [REGISTER_COUNT_BIT-1:0] rs1_addr = memory_inst[19:15];
wire [REGISTER_COUNT_BIT-1:0] rs2_addr = memory_inst[24:20];
wire [REGISTER_COUNT_BIT-1:0] wb_addr  = memory_inst[11:7];

wire [WORD_LEN-1:0] rs1_data = (rs1_addr == 0) ? 0 : regfile[rs1_addr];
wire [WORD_LEN-1:0] rs2_data = (rs2_addr == 0) ? 0 : regfile[rs2_addr];

wire [IMM_I_BITWISE-1:0] imm_i = memory_inst[31:20];
wire [WORD_LEN-1:0] imm_i_sext = {{WORD_LEN-IMM_I_BITWISE{imm_i[IMM_I_BITWISE-1]}}, imm_i};

wire [IMM_S_BITWISE-1:0] imm_s = {memory_inst[31:25], memory_inst[11:7]};
wire [WORD_LEN-1:0] imm_s_sext = {{WORD_LEN-IMM_S_BITWISE{imm_s[IMM_S_BITWISE-1]}}, imm_s};

wire [IMM_B_BITWISE-1:0] imm_b = {memory_inst[31], memory_inst[7], memory_inst[30:25], memory_inst[11:8]};
wire [WORD_LEN-1:0] imm_b_sext = {{WORD_LEN-IMM_B_BITWISE-1{imm_b[IMM_B_BITWISE-1]}}, imm_b, 1'b0};

wire [IMM_J_BITWISE-1:0] imm_j = {memory_inst[31], memory_inst[19:12], memory_inst[20], memory_inst[30:21]};
wire [WORD_LEN-1:0] imm_j_sext = {{WORD_LEN-IMM_J_BITWISE-1{imm_j[IMM_J_BITWISE-1]}}, imm_j, 1'b0};

wire [IMM_U_BITWISE-1:0] imm_u    = memory_inst[31:12];
wire [WORD_LEN-1:0] imm_u_shifted = {imm_u, 12'b0};

wire [IMM_Z_BITWISE-1:0] imm_z = memory_inst[19:15];
wire [WORD_LEN-1:0] imm_z_uext = {27'd0, imm_z};

wire [2:0] funct3 = memory_inst[14:12];
wire [7:0] funct7 = memory_inst[31:25];
wire [6:0] opcode = memory_inst[6:0];

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
wire inst_is_ecall  = memory_inst == INST_ECALL;

wire [4:0] exe_fun;// ALUの計算の種類
wire [3:0] op1_sel;// ALUで計算するデータの1項目
wire [3:0] op2_sel;// ALUで計算するデータの2項目
wire [0:0] mem_wen;// メモリに書き込むか否か
wire [0:0] rf_wen; // レジスタに書き込むか否か
wire [3:0] wb_sel; // ライトバック先
wire [2:0] csr_cmd;// CSR


assign {exe_fun, op1_sel, op2_sel, mem_wen, rf_wen, wb_sel, csr_cmd} = (
    inst_is_lb    ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_MEMB , CSR_X} :
    inst_is_lbu   ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_MEMBU, CSR_X} :
    inst_is_lh    ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_MEMH , CSR_X} :
    inst_is_lhu   ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_MEMHU, CSR_X} :
    inst_is_lw    ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_MEMW , CSR_X} :
    inst_is_sb    ? {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_S, REN_X, WB_X    , CSR_X} :
    inst_is_sh    ? {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_S, REN_X, WB_X    , CSR_X} :
    inst_is_sw    ? {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_S, REN_X, WB_X    , CSR_X} :
    inst_is_add   ? {ALU_ADD  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_addi  ? {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_sub   ? {ALU_SUB  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_and   ? {ALU_AND  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_or    ? {ALU_OR   , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_xor   ? {ALU_XOR  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_andi  ? {ALU_AND  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_ori   ? {ALU_OR   , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
    inst_is_xori  ? {ALU_XOR  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_sll   ? {ALU_SLL  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_srl   ? {ALU_SRL  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_sra   ? {ALU_SRA  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_slli  ? {ALU_SLL  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_srli  ? {ALU_SRL  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_srai  ? {ALU_SRA  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_slt   ? {ALU_SLT  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_sltu  ? {ALU_SLTU , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_slti  ? {ALU_SLT  , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_sltiu ? {ALU_SLTU , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_beq   ? {BR_BEQ   , OP1_RS1, OP2_RS2W, MEN_X, REN_X, WB_X    , CSR_X} :
	inst_is_bne   ? {BR_BNE   , OP1_RS1, OP2_RS2W, MEN_X, REN_X, WB_X    , CSR_X} :
	inst_is_blt   ? {BR_BLT   , OP1_RS1, OP2_RS2W, MEN_X, REN_X, WB_X    , CSR_X} :
	inst_is_bge   ? {BR_BGE   , OP1_RS1, OP2_RS2W, MEN_X, REN_X, WB_X    , CSR_X} :
	inst_is_bltu  ? {BR_BLTU  , OP1_RS1, OP2_RS2W, MEN_X, REN_X, WB_X    , CSR_X} :
	inst_is_bgeu  ? {BR_BGEU  , OP1_RS1, OP2_RS2W, MEN_X, REN_X, WB_X    , CSR_X} :
	inst_is_jal   ? {ALU_ADD  , OP1_PC , OP2_IMJ , MEN_X, REN_S, WB_PC   , CSR_X} :
	inst_is_jalr  ? {ALU_JALR , OP1_RS1, OP2_IMI , MEN_X, REN_S, WB_PC   , CSR_X} :
	inst_is_lui   ? {ALU_ADD  , OP1_X  , OP2_IMU , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_auipc ? {ALU_ADD  , OP1_PC , OP2_IMU , MEN_X, REN_S, WB_ALU  , CSR_X} :
	inst_is_csrrw ? {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X, REN_S, WB_CSR  , CSR_W} :
	inst_is_csrrwi? {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X, REN_S, WB_CSR  , CSR_W} :
	inst_is_csrrs ? {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X, REN_S, WB_CSR  , CSR_S} :
	inst_is_csrrsi? {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X, REN_S, WB_CSR  , CSR_S} :
	inst_is_csrrc ? {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X, REN_S, WB_CSR  , CSR_C} :
	inst_is_csrrci? {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X, REN_S, WB_CSR  , CSR_C} :
	inst_is_ecall ? {ALU_X    , OP1_X  , OP2_X   , MEN_X, REN_X, WB_X    , CSR_E} :
    0
);

assign jmp_flg = inst_is_jal || inst_is_jalr;

wire [WORD_LEN-1:0] op1_data = (
    op1_sel == OP1_RS1 ? rs1_data :
	op1_sel == OP1_PC  ? reg_pc :
    op1_sel == OP1_IMZ ? imm_z_uext :
    0
);

wire [WORD_LEN-1:0] op2_data = (
    op2_sel == OP2_RS2W ? rs2_data :
    op2_sel == OP2_IMI  ? imm_i_sext :
    op2_sel == OP2_IMS  ? imm_s_sext :
    op2_sel == OP2_IMJ  ? imm_j_sext :
    op2_sel == OP2_IMU  ? imm_u_shifted :
    0
);




// CSR
reg csr_clock = 0;  // CSR命令の時にレジスタ読み出しを待機するためのフラグ

wire [11:0] csr_addr = (
	csr_cmd == CSR_E ? 12'h342 : 
	imm_i
);

reg csr_wen = 0;
wire [WORD_LEN-1:0] csr_rdata;
wire [WORD_LEN-1:0] trap_vector_addr;
wire [WORD_LEN-1:0] csr_wdata = (
	csr_cmd == CSR_W ? op1_data :
	csr_cmd == CSR_S ? csr_rdata | op1_data :
	csr_cmd == CSR_C ? csr_rdata & ~op1_data :
	csr_cmd == CSR_E ? 11 : // 11はマシンモードからのecallであることを示す
	0
);

Csr csr (
	.clk(clk),
	.addr(csr_addr),
	.rdata(csr_rdata),
	.wen(csr_wen),
	.wdata(csr_wdata),
	.trap_vector(trap_vector_addr)
);




// EX STAGE
wire [WORD_LEN-1:0] alu_out = (
    exe_fun == ALU_ADD   ? op1_data + op2_data :
    exe_fun == ALU_SUB   ? op1_data - op2_data :
    exe_fun == ALU_AND   ? op1_data & op2_data :
    exe_fun == ALU_OR    ? op1_data | op2_data :
    exe_fun == ALU_XOR   ? op1_data ^ op2_data :
	exe_fun == ALU_SLL   ? op1_data << op2_data[4:0] :
	exe_fun == ALU_SRL   ? op1_data >> op2_data[4:0] :
	exe_fun == ALU_SRA   ? $signed($signed(op1_data) >>> op2_data[4:0]):
	exe_fun == ALU_SLT   ? ($signed(op1_data) < $signed(op2_data)) :
	exe_fun == ALU_SLTU  ? op1_data < op2_data :
	exe_fun == ALU_JALR  ? (op1_data + op2_data) & (~1) :
	exe_fun == ALU_COPY1 ? op1_data :
    0
);

assign br_flg = (
	exe_fun == BR_BEQ   ? (op1_data == op2_data) :
	exe_fun == BR_BNE   ? !(op1_data == op2_data) :
	exe_fun == BR_BLT   ? ($signed(op1_data) < $signed(op2_data)) :
	exe_fun == BR_BGE   ? !($signed(op1_data) < $signed(op2_data)) :
	exe_fun == BR_BLTU  ? (op1_data < op2_data) :
	exe_fun == BR_BGEU  ? !(op1_data < op2_data) :
	0
);

assign br_target = reg_pc + imm_b_sext;




// MEM STAGE
reg [WORD_LEN-1:0] memory_d_addr_offset = 0;    // アドレスのオフセット
reg [1:0] mem_clock     = 0;                // load命令で待機するクロック数を管理するフラグ
assign memory_d_addr    = alu_out + memory_d_addr_offset;// データ読み出しのアドレス
reg[WORD_LEN-1:0] memory_rdata_previous;    // 前の読み込まれたデータ

// load系の命令かどうかを示す
wire is_load_op_byte = wb_sel == WB_MEMB || wb_sel == WB_MEMBU;
wire is_load_op_half = wb_sel == WB_MEMH || wb_sel == WB_MEMHU;
wire is_load_op_word = wb_sel == WB_MEMW;
wire is_load_op = (is_load_op_byte || is_load_op_half || is_load_op_word);

// load系の命令で待機しているかどうかを示す
wire load_wait = (
    is_load_op &&
    (
        // LB命令は1回で読み込める
        is_load_op_byte ? mem_clock != 2'b01 :
        // LHでaddr%4=3の時2回読み込む
        is_load_op_half ? (
            memory_d_addr % 4 == 3 ? mem_clock != 2'b10 : mem_clock != 2'b01
        ) :
        // LW命令は4byteアラインされていない場合は2回読む
        memory_d_addr % 4 == 0 ? mem_clock != 2'b01 : mem_clock != 2'b10
    )
);

// 今が待ちの最後のクロックかを示す
wire load_wait_last_clock = (
    is_load_op &&
    (
        is_load_op_byte ? mem_clock == 2'b00 :
        is_load_op_half ? (
            memory_d_addr % 4 == 3 ? mem_clock == 2'b01 : mem_clock == 2'b00
        ) :
        memory_d_addr % 4 == 0 ? mem_clock == 2'b00 : mem_clock == 2'b01
    )
);

wire [7:0] memory_b_read = (
    memory_d_addr % 4 == 1 ? memory_rdata[15:8] :
    memory_d_addr % 4 == 2 ? memory_rdata[23:16] :
    memory_d_addr % 4 == 3 ? memory_rdata[31:24] :
    memory_rdata[7:0]
);

wire [15:0] memory_h_read = (
    memory_d_addr % 4 == 1 ? memory_rdata[23:8] :
    memory_d_addr % 4 == 2 ? memory_rdata[31:16] :
    memory_d_addr % 4 == 3 ? {memory_rdata[7:0], memory_rdata_previous[31:24]} :
    memory_rdata[15:0]
);

wire [WORD_LEN-1:0] memory_w_read = (
    memory_d_addr % 4 == 1 ? {memory_rdata[7:0], memory_rdata_previous[31:8]} :
    memory_d_addr % 4 == 2 ? {memory_rdata[15:0], memory_rdata_previous[31:16]} :
    memory_d_addr % 4 == 3 ? {memory_rdata[23:0], memory_rdata_previous[31:24]} :
    memory_rdata
);


// store系の命令で待機しているかを示す
wire store_wait = (
    inst_is_sb ? mem_clock != 2'b01 :
    inst_is_sh ? mem_clock != 2'b01 :
    inst_is_sw ? (
        memory_d_addr % 4 != 0 ? mem_clock != 2'b01 : mem_clock == 2'b00
    ) :
    0
);

// 書き込むデータのマスク
assign memory_wmask = (
    mem_clock == 0 ? (
        inst_is_sb ? (
            memory_d_addr % 4 == 0 ? 32'h000000ff :
            memory_d_addr % 4 == 1 ? 32'h0000ff00 :
            memory_d_addr % 4 == 2 ? 32'h00ff0000 :
            32'hff000000
        ) :
        inst_is_sh ? (
            memory_d_addr % 4 == 0 ? 32'h0000ffff :
            memory_d_addr % 4 == 1 ? 32'h00ffff00 :
            memory_d_addr % 4 == 2 ? 32'hffff0000 :
            32'hff000000
        ) :
        (
            memory_d_addr % 4 == 0 ? 32'hffffffff :
            memory_d_addr % 4 == 1 ? 32'hffffff00 :
            memory_d_addr % 4 == 2 ? 32'hffff0000 :
            32'hff000000
        )
    ) : (
        inst_is_sh && memory_d_addr % 4 == 3 ? 32'h000000ff :
        inst_is_sw ? (
            memory_d_addr % 4 == 1 ? 32'h000000ff :
            memory_d_addr % 4 == 2 ? 32'h0000ffff :
            memory_d_addr % 4 == 3 ? 32'h00ffffff : 0
        ) : 0
    ) 
);

// 書き込むデータ
assign memory_wdata = (
    mem_clock == 0 ? (
        memory_d_addr % 4 == 0 ? rs2_data :
        memory_d_addr % 4 == 1 ? {rs2_data[23:0], 8'b0} :
        memory_d_addr % 4 == 2 ? {rs2_data[15:0], 16'b0} :
        {rs2_data[7:0], 24'b0}
    ) : (
        memory_d_addr % 4 == 1 ? {24'b0, rs2_data[31:24]} :
        memory_d_addr % 4 == 2 ? {16'b0, rs2_data[31:16]} :
        memory_d_addr % 4 == 3 ? {8'b0, rs2_data[31:8]} :
        0
    )
);

assign memory_wen = mem_wen == MEN_S && store_wait; // メモリを書き込むかどうかのフラグ




// WB STAGE
wire [WORD_LEN-1:0] wb_data = (
    wb_sel == WB_MEMB ? {{24{memory_b_read[7]}}, memory_b_read} :
    wb_sel == WB_MEMBU? {24'b0, memory_b_read} :
    wb_sel == WB_MEMH ? {{16{memory_h_read[15]}}, memory_h_read} :
    wb_sel == WB_MEMHU? {16'b0, memory_h_read} :
    wb_sel == WB_MEMW ? memory_w_read :
	wb_sel == WB_PC   ? reg_pc_plus4 :
	wb_sel == WB_CSR  ? csr_rdata :
    alu_out
);




// 終了判定
assign exit = memory_i_addr == 32'h1000;


always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
        reg_pc <= 0;
        inst_clk <= 0;
        mem_clock <= 0;
        csr_clock <= 0;
        regfile[2] = 1000; // sp
        regfile[3] <= 0; // gp
        $display("RESET");
    end else if (inst_clk != 1'b1) begin
        // FETCH STAGE
        inst_clk <= 1;
        $display("INST WAIT CLOCK %d", inst_clk);
    end else if (load_wait) begin
        // LOAD命令のために待つ
        mem_clock <= mem_clock + 1;
        if (!load_wait_last_clock)
            memory_d_addr_offset <= memory_d_addr_offset + 4;
        memory_rdata_previous <= memory_rdata;
        $display("LOAD WAIT CLOCK %d", mem_clock);
    end else if (store_wait) begin
        // STORE命令のために待つ
        if (memory_ready) begin
            mem_clock <= mem_clock + 1;
            memory_d_addr_offset <= memory_d_addr_offset + 4;
        end
        $display("STORE WAIT CLOCK %d", mem_clock);
	end else if (!csr_clock && csr_cmd != CSR_X) begin
		csr_clock <= 1;
		csr_wen <= csr_cmd != CSR_X;
        $display("CSR WAIT CLOCK");
    end else if (!exit) begin
        $display("WB STAGE");
        inst_clk <= 0;
        mem_clock <= 0;
		csr_clock <= 0;
        csr_wen <= 0;
        memory_d_addr_offset <= 0;

        // WB STAGE
        if (rf_wen == REN_S) begin
            regfile[wb_addr] <= wb_data;
        end

	    reg_pc <= (
			br_flg ? br_target : 
			jmp_flg ? alu_out :
			inst_is_ecall ? trap_vector_addr :
			reg_pc_plus4
		);
    end

    $display("reg_pc    : 0x%H", reg_pc);
    $display("inst      : 0x%H", memory_inst);
    $display("rs1_addr  : %d", rs1_addr);
    $display("rs2_addr  : %d", rs2_addr);
    $display("wb_addr   : %d", wb_addr);
    $display("rs1_data  : 0x%H", rs1_data);
    $display("rs2_data  : 0x%H", rs2_data);
    $display("wb_data   : 0x%H", wb_data);
    $display("dmem.addr : %d", memory_d_addr);
    $display("dmem.wen  : %d(%d)", memory_wen, mem_wen);
    $display("dmem.wdata: 0x%H", memory_wdata);
    $display("dmem.r_raw: 0x%H", memory_rdata);
    $display("dmem.r_prv: 0x%H", memory_rdata_previous);
    $display("dmem.r_b  : 0x%H", memory_b_read);
    $display("dmem.r_h  : 0x%H", memory_h_read);
    $display("dmem.r_w  : 0x%H", memory_w_read);
    $display("imm_i     : 0x%H", imm_i_sext);
	$display("imm_j     : 0x%H", imm_j_sext);
	$display("imm_u     : 0x%H", imm_u_shifted);
	$display("imm_z     : 0x%H", imm_z_uext);
    $display("gp        : %d", gp);

    $display("1: 0x%H   9: 0x%H  17: 0x%H  25: 0x%H", regfile[1], regfile[9] , regfile[17], regfile[25]);
    $display("2: 0x%H  10: 0x%H  18: 0x%H  26: 0x%H", regfile[2], regfile[10], regfile[18], regfile[26]);
    $display("3: 0x%H  11: 0x%H  19: 0x%H  27: 0x%H", regfile[3], regfile[11], regfile[19], regfile[27]);
    $display("4: 0x%H  12: 0x%H  20: 0x%H  28: 0x%H", regfile[4], regfile[12], regfile[20], regfile[28]);
    $display("5: 0x%H  13: 0x%H  21: 0x%H  29: 0x%H", regfile[5], regfile[13], regfile[21], regfile[29]);
    $display("6: 0x%H  14: 0x%H  22: 0x%H  30: 0x%H", regfile[6], regfile[14], regfile[22], regfile[30]);
    $display("7: 0x%H  15: 0x%H  23: 0x%H  31: 0x%H", regfile[7], regfile[15], regfile[23], regfile[31]);
    $display("8: 0x%H  16: 0x%H  24: 0x%H  ",         regfile[8], regfile[16], regfile[24]);
    $display("--------");

end

endmodule
