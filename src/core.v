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
    output  wire [WORD_LEN-1:0] memory_wdata,
	output	wire [WORD_LEN-1:0] gp
);

`include "consts_core.v"
`include "instdefs.v"

// registers
reg [WORD_LEN-1:0] regfile [REGISTER_COUNT-1:0];
// initialize regfile
integer loop_initial_regfile_i;
initial begin
    for (loop_initial_regfile_i = 0;
        loop_initial_regfile_i < REGISTER_COUNT;
        loop_initial_regfile_i = loop_initial_regfile_i + 1)
        regfile[loop_initial_regfile_i] = 0;
end
reg  [WORD_LEN-1:0] reg_pc = 0;					// プログラムカウンタ
assign gp = regfile[3];


// IF STAGE
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

wire inst_is_lw     = (funct3 == INST_LW_FUNCT3 && opcode == INST_LW_OPCODE);
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
    inst_is_lw    ? {ALU_ADD  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_MEM, CSR_X} :
    inst_is_sw    ? {ALU_ADD  , OP1_RS1, OP2_IMS, MEN_S, REN_X, WB_X  , CSR_X} :
    inst_is_add   ? {ALU_ADD  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_addi  ? {ALU_ADD  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_sub   ? {ALU_SUB  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_and   ? {ALU_AND  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_or    ? {ALU_OR   , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_xor   ? {ALU_XOR  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_andi  ? {ALU_AND  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_ori   ? {ALU_OR   , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
    inst_is_xori  ? {ALU_XOR  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_sll   ? {ALU_SLL  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_srl   ? {ALU_SRL  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_sra   ? {ALU_SRA  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_slli  ? {ALU_SLL  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_srli  ? {ALU_SRL  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_srai  ? {ALU_SRA  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_slt   ? {ALU_SLT  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_sltu  ? {ALU_SLTU , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_slti  ? {ALU_SLT  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_sltiu ? {ALU_SLTU , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_beq   ? {BR_BEQ   , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  , CSR_X} :
	inst_is_bne   ? {BR_BNE   , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  , CSR_X} :
	inst_is_blt   ? {BR_BLT   , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  , CSR_X} :
	inst_is_bge   ? {BR_BGE   , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  , CSR_X} :
	inst_is_bltu  ? {BR_BLTU  , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  , CSR_X} :
	inst_is_bgeu  ? {BR_BGEU  , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  , CSR_X} :
	inst_is_jal   ? {ALU_ADD  , OP1_PC , OP2_IMJ, MEN_X, REN_S, WB_PC , CSR_X} :
	inst_is_jalr  ? {ALU_JALR , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_PC , CSR_X} :
	inst_is_lui   ? {ALU_ADD  , OP1_X  , OP2_IMU, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_auipc ? {ALU_ADD  , OP1_PC , OP2_IMU, MEN_X, REN_S, WB_ALU, CSR_X} :
	inst_is_csrrw ? {ALU_COPY1, OP1_RS1, OP2_X  , MEN_X, REN_S, WB_CSR, CSR_W} :
	inst_is_csrrwi? {ALU_COPY1, OP1_IMZ, OP2_X  , MEN_X, REN_S, WB_CSR, CSR_W} :
	inst_is_csrrs ? {ALU_COPY1, OP1_RS1, OP2_X  , MEN_X, REN_S, WB_CSR, CSR_S} :
	inst_is_csrrsi? {ALU_COPY1, OP1_IMZ, OP2_X  , MEN_X, REN_S, WB_CSR, CSR_S} :
	inst_is_csrrc ? {ALU_COPY1, OP1_RS1, OP2_X  , MEN_X, REN_S, WB_CSR, CSR_C} :
	inst_is_csrrci? {ALU_COPY1, OP1_IMZ, OP2_X  , MEN_X, REN_S, WB_CSR, CSR_C} :
	inst_is_ecall ? {ALU_X    , OP1_X  , OP2_X  , MEN_X, REN_X, WB_X  , CSR_E} :
    0
);

assign jmp_flg = inst_is_jal || inst_is_jalr;

wire [WORD_LEN-1:0] op1_data = (
    op1_sel == OP1_RS1 ? rs1_data :
	op1_sel  == OP1_PC  ? reg_pc :
    0
);

wire [WORD_LEN-1:0] op2_data = (
    op2_sel == OP2_RS2 ? rs2_data :
    op2_sel == OP2_IMI ? imm_i_sext :
    op2_sel == OP2_IMS ? imm_s_sext :
    op2_sel == OP2_IMJ ? imm_j_sext :
    op2_sel == OP2_IMU ? imm_u_shifted :
    0
);




// CSR
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
assign memory_d_addr    = alu_out;
assign memory_wen       = mem_wen == MEN_S;
assign memory_wdata     = rs2_data;



// WB STAGE
wire [WORD_LEN-1:0] wb_data = (
    wb_sel == WB_MEM ? memory_rdata :
	wb_sel == WB_PC  ? reg_pc_plus4 :
	wb_sel == WB_CSR ? csr_rdata :
    alu_out
);




// 終了判定
assign exit = memory_i_addr == 32'h44;


reg inst_clk = 0;
reg csr_clock = 0;
reg mem_clock = 0;

always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
        reg_pc <= 0;
        inst_clk <= 0;
        mem_clock <= 0;
        csr_clock <= 0;
        regfile[3] <= 0; // gp
        $display("RESET");
    end else if (!inst_clk) begin
        inst_clk <= 1;
        $display("WAIT CLOCK");
    end else if (wb_sel == WB_MEM && !mem_clock) begin
        mem_clock <= 1;
        $display("LW WAIT CLOCK");
	end else if (!csr_clock && csr_cmd != CSR_X) begin
		csr_clock <= 1;
		csr_wen <= csr_cmd != CSR_X;
        $display("CSR WAIT CLOCK");
    end else if (!exit) begin
        inst_clk <= 0;
        mem_clock <= 0;
		csr_clock <= 0;
        csr_wen <= 0;

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
    $display("dmem.wen  : %d", memory_wen);
    $display("dmem.wdata: 0x%H", memory_wdata);
    $display("imm_i     : 0x%H", imm_i_sext);
	$display("imm_j     : 0x%H", imm_j_sext);
	$display("imm_u     : 0x%H", imm_u_shifted);
    $display("gp        : %d", gp);

    $display("1  : 0x%H", regfile[1]);
    $display("2  : 0x%H", regfile[2]);
    $display("3  : 0x%H", regfile[3]);
    $display("4  : 0x%H", regfile[4]);
    $display("5  : 0x%H", regfile[5]);
    $display("6  : 0x%H", regfile[6]);
    $display("7  : 0x%H", regfile[7]);
    $display("8  : 0x%H", regfile[8]);
    $display("9  : 0x%H", regfile[9]);
    $display("10 : 0x%H", regfile[10]);
    $display("11 : 0x%H", regfile[11]);
    $display("12 : 0x%H", regfile[12]);
    $display("13 : 0x%H", regfile[13]);
    $display("14 : 0x%H", regfile[14]);
    $display("15 : 0x%H", regfile[15]);
    $display("16 : 0x%H", regfile[16]);
    $display("17 : 0x%H", regfile[17]);
    $display("18 : 0x%H", regfile[18]);
    $display("19 : 0x%H", regfile[19]);
    $display("20 : 0x%H", regfile[20]);
    $display("21 : 0x%H", regfile[21]);
    $display("22 : 0x%H", regfile[22]);
    $display("23 : 0x%H", regfile[23]);
    $display("24 : 0x%H", regfile[24]);
    $display("25 : 0x%H", regfile[25]);
    $display("26 : 0x%H", regfile[26]);
    $display("27 : 0x%H", regfile[27]);
    $display("28 : 0x%H", regfile[28]);
    $display("29 : 0x%H", regfile[29]);
    $display("30 : 0x%H", regfile[30]);
    $display("31 : 0x%H", regfile[31]);

    $display("--------");

end

endmodule
