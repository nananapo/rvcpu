module Core #(
    parameter WORD_LEN          = 32,
    parameter REGISTER_COUNT    = 32,
    parameter REGISTER_COUNT_BIT= 5,
    parameter IMM_I_BITWISE     = 12,
    parameter IMM_S_BITWISE     = 12,
    parameter IMM_B_BITWISE     = 11,
    parameter IMM_J_BITWISE     = 20,

    parameter INST_LW_FUNCT3    = 3'b010,
    parameter INST_LW_OPCODE    = 7'b0000011,

    parameter INST_SW_FUNCT3    = 3'b010,
    parameter INST_SW_OPCODE    = 7'b0100011,
    
    parameter INST_ADD_FUNCT7   = 7'b0000000,
    parameter INST_ADD_FUNCT3   = 3'b000,
    parameter INST_ADD_OPCODE   = 7'b0110011,
    
    parameter INST_SUB_FUNCT7   = 7'b0100000,
    parameter INST_SUB_FUNCT3   = 3'b000,
    parameter INST_SUB_OPCODE   = 7'b0110011,
    
    parameter INST_ADDI_FUNCT3  = 3'b000,
    parameter INST_ADDI_OPCODE  = 7'b0010011,

    parameter INST_AND_FUNCT7   = 7'b0000000,
    parameter INST_AND_FUNCT3   = 3'b111,
    parameter INST_AND_OPCODE   = 7'b0110011,

    parameter INST_OR_FUNCT7    = 7'b0000000,
    parameter INST_OR_FUNCT3    = 3'b110,
    parameter INST_OR_OPCODE    = 7'b0110011,

    parameter INST_XOR_FUNCT7   = 7'b0000000,
    parameter INST_XOR_FUNCT3   = 3'b100,
    parameter INST_XOR_OPCODE   = 7'b0110011,

    parameter INST_ANDI_FUNCT3  = 3'b111,
    parameter INST_ANDI_OPCODE  = 7'b0010011,

    parameter INST_ORI_FUNCT3   = 3'b110,
    parameter INST_ORI_OPCODE   = 7'b0010011,

    parameter INST_XORI_FUNCT3  = 3'b100,
    parameter INST_XORI_OPCODE  = 7'b0010011,

    parameter INST_SLL_FUNCT7   = 7'b0000000,
    parameter INST_SLL_FUNCT3   = 3'b001,
    parameter INST_SLL_OPCODE   = 7'b0110011,

    parameter INST_SRL_FUNCT7   = 7'b0000000,
    parameter INST_SRL_FUNCT3   = 3'b101,
    parameter INST_SRL_OPCODE   = 7'b0110011,

    parameter INST_SRA_FUNCT7   = 7'b0100000,
    parameter INST_SRA_FUNCT3   = 3'b101,
    parameter INST_SRA_OPCODE   = 7'b0110011,

    parameter INST_SLLI_FUNCT7  = 7'b0000000,
    parameter INST_SLLI_FUNCT3  = 3'b001,
    parameter INST_SLLI_OPCODE  = 7'b0010011,

    parameter INST_SRLI_FUNCT7  = 7'b0000000,
    parameter INST_SRLI_FUNCT3  = 3'b101,
    parameter INST_SRLI_OPCODE  = 7'b0010011,

    parameter INST_SRAI_FUNCT7  = 7'b0100000,
    parameter INST_SRAI_FUNCT3  = 3'b101,
    parameter INST_SRAI_OPCODE  = 7'b0010011,

    parameter INST_SLT_FUNCT7   = 7'b0000000,
    parameter INST_SLT_FUNCT3   = 3'b010,
    parameter INST_SLT_OPCODE   = 7'b0110011,

    parameter INST_SLTU_FUNCT7  = 7'b0000000,
    parameter INST_SLTU_FUNCT3  = 3'b011,
    parameter INST_SLTU_OPCODE  = 7'b0110011,

    parameter INST_SLTI_FUNCT3  = 3'b010,
    parameter INST_SLTI_OPCODE  = 7'b0010011,

    parameter INST_SLTIU_FUNCT3 = 3'b011,
    parameter INST_SLTIU_OPCODE = 7'b0010011,

	parameter INST_BEQ_FUNCT3   = 3'b000,
    parameter INST_BEQ_OPCODE   = 7'b1100011,

	parameter INST_BNE_FUNCT3   = 3'b001,
    parameter INST_BNE_OPCODE   = 7'b1100011,

	parameter INST_BLT_FUNCT3   = 3'b100,
    parameter INST_BLT_OPCODE   = 7'b1100011,

	parameter INST_BGE_FUNCT3   = 3'b101,
    parameter INST_BGE_OPCODE   = 7'b1100011,

	parameter INST_BLTU_FUNCT3  = 3'b110,
    parameter INST_BLTU_OPCODE  = 7'b1100011,

	parameter INST_BGEU_FUNCT3  = 3'b111,
    parameter INST_BGEU_OPCODE  = 7'b1100011,

	parameter INST_JAL_OPCODE	= 7'b1101111,

	parameter INST_JALR_FUNCT3	= 3'b000,
	parameter INST_JALR_OPCODE	= 7'b1100111
) (
    input   wire                clk,
    input   wire                rst_n,
    output  wire                exit,
    output  wire [WORD_LEN-1:0] memory_i_addr,
    input   wire [WORD_LEN-1:0] memory_inst,
    output  wire [WORD_LEN-1:0] memory_d_addr,
    input   wire [WORD_LEN-1:0] memory_rdata,
    output  wire                memory_wen,
    output  wire [WORD_LEN-1:0] memory_wdata
);

localparam ALU_ADD  = 5'b00000;
localparam ALU_SUB  = 5'b00001;
localparam ALU_AND  = 5'b00010;
localparam ALU_OR   = 5'b00011;
localparam ALU_XOR  = 5'b00100;
localparam ALU_SLL  = 5'b00101;
localparam ALU_SRL  = 5'b00110;
localparam ALU_SRA  = 5'b00111;
localparam ALU_SLT  = 5'b01000;
localparam ALU_SLTU = 5'b01001;
localparam BR_BEQ   = 5'b01010;
localparam BR_BNE   = 5'b01011;
localparam BR_BLT   = 5'b01100;
localparam BR_BGE   = 5'b01101;
localparam BR_BLTU  = 5'b01110;
localparam BR_BGEU  = 5'b01111;
localparam ALU_JALR = 5'b10000;

localparam OP1_RS1  = 4'b0000;
localparam OP1_PC   = 4'b0001;

localparam OP2_RS2  = 4'b0000;
localparam OP2_IMI  = 4'b0001;
localparam OP2_IMS  = 4'b0010;
localparam OP2_IMJ  = 4'b0011;


localparam MEN_X    = 1'b0;
localparam MEN_S    = 1'b1;

localparam REN_X    = 1'b0;
localparam REN_S    = 1'b1;

localparam WB_X     = 4'b0000;
localparam WB_ALU   = 4'b0000;
localparam WB_MEM   = 4'b0001;
localparam WB_PC	= 4'b0010;



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

wire [IMM_J_BITWISE-1:0] imm_j = {memory_inst[20], memory_inst[10:1], memory_inst[11], memory_inst[19:12]};
wire [WORD_LEN-1:0] imm_j_sext = {{WORD_LEN-IMM_J_BITWISE-1{imm_j[IMM_J_BITWISE-1]}}, imm_j, 1'b0};


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

wire [4:0] exe_fun;// ALUの計算の種類
wire [3:0] op1_sel;// ALUで計算するデータの1項目
wire [3:0] op2_sel;// ALUで計算するデータの2項目
wire [0:0] mem_wen;// メモリに書き込むか否か
wire [0:0] rf_wen; // レジスタに書き込むか否か
wire [3:0] wb_sel; // ライトバック先

assign {exe_fun, op1_sel, op2_sel, mem_wen, rf_wen, wb_sel} = (
    inst_is_lw   ? {ALU_ADD , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_MEM} :
    inst_is_sw   ? {ALU_ADD , OP1_RS1, OP2_IMS, MEN_S, REN_X, WB_X  } :
    inst_is_add  ? {ALU_ADD , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
    inst_is_addi ? {ALU_ADD , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
    inst_is_sub  ? {ALU_SUB , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
    inst_is_and  ? {ALU_AND , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
    inst_is_or   ? {ALU_OR  , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
    inst_is_xor  ? {ALU_XOR , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
    inst_is_andi ? {ALU_AND , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
    inst_is_ori  ? {ALU_OR  , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
    inst_is_xori ? {ALU_XOR , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
	inst_is_sll  ? {ALU_SLL , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
	inst_is_srl  ? {ALU_SRL , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
	inst_is_sra  ? {ALU_SRA , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
	inst_is_slli ? {ALU_SLL , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
	inst_is_srli ? {ALU_SRL , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
	inst_is_srai ? {ALU_SRA , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
	inst_is_slt  ? {ALU_SLT , OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
	inst_is_sltu ? {ALU_SLTU, OP1_RS1, OP2_RS2, MEN_X, REN_S, WB_ALU} :
	inst_is_slti ? {ALU_SLT , OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
	inst_is_sltiu? {ALU_SLTU, OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_ALU} :
	inst_is_beq  ? {BR_BEQ  , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  } :
	inst_is_bne  ? {BR_BNE  , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  } :
	inst_is_blt  ? {BR_BLT  , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  } :
	inst_is_bge  ? {BR_BGE  , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  } :
	inst_is_bltu ? {BR_BLTU , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  } :
	inst_is_bgeu ? {BR_BGEU , OP1_RS1, OP2_RS2, MEN_X, REN_X, WB_X  } :
	inst_is_jal  ? {ALU_ADD , OP1_PC , OP2_IMJ, MEN_X, REN_S, WB_PC } :
	inst_is_jalr ? {ALU_JALR, OP1_RS1, OP2_IMI, MEN_X, REN_S, WB_PC } :
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
    0
);




// EX STAGE
wire [WORD_LEN-1:0] alu_out = (
    exe_fun == ALU_ADD  ? op1_data + op2_data :
    exe_fun == ALU_SUB  ? op1_data - op2_data :
    exe_fun == ALU_AND  ? op1_data & op2_data :
    exe_fun == ALU_OR   ? op1_data | op2_data :
    exe_fun == ALU_XOR  ? op1_data ^ op2_data :
	exe_fun == ALU_SLL  ? op1_data << op2_data[4:0] :
	exe_fun == ALU_SRL  ? op1_data >> op2_data[4:0] :
	exe_fun == ALU_SRA  ? op1_data >>> op2_data[4:0] :
	exe_fun == ALU_SLT  ? ($signed(op1_data) < $signed(op2_data)) :
	exe_fun == ALU_SLTU ? op1_data < op2_data :
	exe_fun == ALU_JALR ? (op1_data + op2_data) & (~1) :
    0
);

assign br_flg = (
	exe_fun == BR_BEQ   ? (op1_data == op2_data) :
	exe_fun == BR_BNE   ? !(op1_data == op2_data) :
	exe_fun == BR_BLT   ? ($signed(op1_data) < $signed(op2_data)) :
	exe_fun == BR_BGE   ? ($signed(op1_data) < $signed(op2_data)) :
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
    alu_out
    //wb_sel == WB_ALU ? alu_out :
    //0
);




// 終了判定
assign exit = memory_i_addr == 8;




always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
        reg_pc <= 0;
        for (loop_initial_regfile_i = 0; loop_initial_regfile_i < REGISTER_COUNT; loop_initial_regfile_i = loop_initial_regfile_i + 1)
            regfile[loop_initial_regfile_i] <= 0;
    end else if (!exit) begin

        reg_pc <= (
			br_flg ? br_target : 
			jmp_flg ? alu_out :
			reg_pc_plus4
		);

        // WB STAGE
        if (rf_wen == REN_S) begin
            regfile[wb_addr] <= wb_data;
        end

        $display("reg_pc    : %d", reg_pc);
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

        $display("--------");
    end

end

endmodule
