localparam INST_LB_FUNCT3       = 3'b000;
localparam INST_LB_OPCODE       = 7'b0000011;

localparam INST_LH_FUNCT3       = 3'b001;
localparam INST_LH_OPCODE       = 7'b0000011;

localparam INST_LW_FUNCT3		= 3'b010;
localparam INST_LW_OPCODE		= 7'b0000011;

localparam INST_SB_FUNCT3		= 3'b000;
localparam INST_SB_OPCODE		= 7'b0100011;

localparam INST_SH_FUNCT3		= 3'b001;
localparam INST_SH_OPCODE		= 7'b0100011;

localparam INST_SW_FUNCT3		= 3'b010;
localparam INST_SW_OPCODE		= 7'b0100011;

localparam INST_ADD_FUNCT7		= 7'b0000000;
localparam INST_ADD_FUNCT3		= 3'b000;
localparam INST_ADD_OPCODE		= 7'b0110011;

localparam INST_SUB_FUNCT7		= 7'b0100000;
localparam INST_SUB_FUNCT3		= 3'b000;
localparam INST_SUB_OPCODE		= 7'b0110011;

localparam INST_ADDI_FUNCT3		= 3'b000;
localparam INST_ADDI_OPCODE		= 7'b0010011;

localparam INST_AND_FUNCT7		= 7'b0000000;
localparam INST_AND_FUNCT3		= 3'b111;
localparam INST_AND_OPCODE		= 7'b0110011;

localparam INST_OR_FUNCT7		= 7'b0000000;
localparam INST_OR_FUNCT3		= 3'b110;
localparam INST_OR_OPCODE		= 7'b0110011;

localparam INST_XOR_FUNCT7		= 7'b0000000;
localparam INST_XOR_FUNCT3		= 3'b100;
localparam INST_XOR_OPCODE		= 7'b0110011;

localparam INST_ANDI_FUNCT3		= 3'b111;
localparam INST_ANDI_OPCODE		= 7'b0010011;

localparam INST_ORI_FUNCT3		= 3'b110;
localparam INST_ORI_OPCODE		= 7'b0010011;

localparam INST_XORI_FUNCT3		= 3'b100;
localparam INST_XORI_OPCODE		= 7'b0010011;

localparam INST_SLL_FUNCT7		= 7'b0000000;
localparam INST_SLL_FUNCT3		= 3'b001;
localparam INST_SLL_OPCODE		= 7'b0110011;

localparam INST_SRL_FUNCT7		= 7'b0000000;
localparam INST_SRL_FUNCT3		= 3'b101;
localparam INST_SRL_OPCODE		= 7'b0110011;

localparam INST_SRA_FUNCT7		= 7'b0100000;
localparam INST_SRA_FUNCT3		= 3'b101;
localparam INST_SRA_OPCODE		= 7'b0110011;

localparam INST_SLLI_FUNCT7		= 7'b0000000;
localparam INST_SLLI_FUNCT3		= 3'b001;
localparam INST_SLLI_OPCODE		= 7'b0010011;

localparam INST_SRLI_FUNCT7		= 7'b0000000;
localparam INST_SRLI_FUNCT3		= 3'b101;
localparam INST_SRLI_OPCODE		= 7'b0010011;

localparam INST_SRAI_FUNCT7		= 7'b0100000;
localparam INST_SRAI_FUNCT3		= 3'b101;
localparam INST_SRAI_OPCODE		= 7'b0010011;

localparam INST_SLT_FUNCT7		= 7'b0000000;
localparam INST_SLT_FUNCT3		= 3'b010;
localparam INST_SLT_OPCODE		= 7'b0110011;

localparam INST_SLTU_FUNCT7		= 7'b0000000;
localparam INST_SLTU_FUNCT3		= 3'b011;
localparam INST_SLTU_OPCODE		= 7'b0110011;

localparam INST_SLTI_FUNCT3		= 3'b010;
localparam INST_SLTI_OPCODE		= 7'b0010011;

localparam INST_SLTIU_FUNCT3	= 3'b011;
localparam INST_SLTIU_OPCODE	= 7'b0010011;

localparam INST_BEQ_FUNCT3		= 3'b000;
localparam INST_BEQ_OPCODE		= 7'b1100011;

localparam INST_BNE_FUNCT3		= 3'b001;
localparam INST_BNE_OPCODE		= 7'b1100011;

localparam INST_BLT_FUNCT3		= 3'b100;
localparam INST_BLT_OPCODE		= 7'b1100011;

localparam INST_BGE_FUNCT3		= 3'b101;
localparam INST_BGE_OPCODE		= 7'b1100011;

localparam INST_BLTU_FUNCT3		= 3'b110;
localparam INST_BLTU_OPCODE		= 7'b1100011;

localparam INST_BGEU_FUNCT3		= 3'b111;
localparam INST_BGEU_OPCODE		= 7'b1100011;

localparam INST_JAL_OPCODE		= 7'b1101111;

localparam INST_JALR_FUNCT3		= 3'b000;
localparam INST_JALR_OPCODE		= 7'b1100111;

localparam INST_LUI_OPCODE		= 7'b0110111;

localparam INST_AUIPC_OPCODE	= 7'b0010111;

localparam INST_CSRRW_FUNCT3	= 3'b001;
localparam INST_CSRRW_OPCODE	= 7'b1110011;

localparam INST_CSRRWI_FUNCT3	= 3'b101;
localparam INST_CSRRWI_OPCODE	= 7'b1110011;

localparam INST_CSRRS_FUNCT3	= 3'b010;
localparam INST_CSRRS_OPCODE	= 7'b1110011;

localparam INST_CSRRSI_FUNCT3	= 3'b110;
localparam INST_CSRRSI_OPCODE	= 7'b1110011;

localparam INST_CSRRC_FUNCT3	= 3'b011;
localparam INST_CSRRC_OPCODE	= 7'b1110011;

localparam INST_CSRRCI_FUNCT3	= 3'b111;
localparam INST_CSRRCI_OPCODE	= 7'b1110011;

localparam INST_ECALL			=32'b00000000000000000000000001110011;