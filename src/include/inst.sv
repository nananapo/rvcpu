localparam INST_LOAD_OPCODE     = 7'b0000011;
localparam INST_LB_FUNCT3       = 3'b000;
localparam INST_LBU_FUNCT3      = 3'b100;
localparam INST_LH_FUNCT3       = 3'b001;
localparam INST_LHU_FUNCT3      = 3'b101;
localparam INST_LW_FUNCT3       = 3'b010;


localparam INST_STORE_OPCODE    = 7'b0100011;
localparam INST_SB_FUNCT3       = 3'b000;
localparam INST_SH_FUNCT3       = 3'b001;
localparam INST_SW_FUNCT3       = 3'b010;


localparam INST_ALUR_OPCODE     = 7'b0110011;
localparam INST_ADD_FUNCT7      = 7'b0000000;
localparam INST_SUB_FUNCT7      = 7'b0100000;
localparam INST_AND_FUNCT7      = 7'b0000000;
localparam INST_OR_FUNCT7       = 7'b0000000;
localparam INST_XOR_FUNCT7      = 7'b0000000;
localparam INST_SLL_FUNCT7      = 7'b0000000;
localparam INST_SRL_FUNCT7      = 7'b0000000;
localparam INST_SRA_FUNCT7      = 7'b0100000;
localparam INST_SLT_FUNCT7      = 7'b0000000;
localparam INST_SLTU_FUNCT7     = 7'b0000000;
localparam INST_AND_FUNCT3      = 3'b111;
localparam INST_ADD_FUNCT3      = 3'b000;
localparam INST_SUB_FUNCT3      = 3'b000;
localparam INST_OR_FUNCT3       = 3'b110;
localparam INST_XOR_FUNCT3      = 3'b100;
localparam INST_SLL_FUNCT3      = 3'b001;
localparam INST_SRL_FUNCT3      = 3'b101;
localparam INST_SRA_FUNCT3      = 3'b101;
localparam INST_SLT_FUNCT3      = 3'b010;
localparam INST_SLTU_FUNCT3     = 3'b011;


localparam INST_ALUI_OPCODE     = 7'b0010011;
localparam INST_SLLI_FUNCT7     = 7'b0000000;
localparam INST_SRLI_FUNCT7     = 7'b0000000;
localparam INST_SRAI_FUNCT7     = 7'b0100000;
localparam INST_ADDI_FUNCT3     = 3'b000;
localparam INST_ANDI_FUNCT3     = 3'b111;
localparam INST_ORI_FUNCT3      = 3'b110;
localparam INST_XORI_FUNCT3     = 3'b100;
localparam INST_SLLI_FUNCT3     = 3'b001;
localparam INST_SRLI_FUNCT3     = 3'b101;
localparam INST_SRAI_FUNCT3     = 3'b101;
localparam INST_SLTI_FUNCT3     = 3'b010;
localparam INST_SLTIU_FUNCT3    = 3'b011;


localparam INST_BR_OPCODE       = 7'b1100011;
localparam INST_BEQ_FUNCT3      = 3'b000;
localparam INST_BNE_FUNCT3      = 3'b001;
localparam INST_BLT_FUNCT3      = 3'b100;
localparam INST_BGE_FUNCT3      = 3'b101;
localparam INST_BLTU_FUNCT3     = 3'b110;
localparam INST_BGEU_FUNCT3     = 3'b111;


localparam INST_CSR_OPCODE      = 7'b1110011;
localparam INST_CSRRW_FUNCT3    = 3'b001;
localparam INST_CSRRWI_FUNCT3   = 3'b101;
localparam INST_CSRRS_FUNCT3    = 3'b010;
localparam INST_CSRRSI_FUNCT3   = 3'b110;
localparam INST_CSRRC_FUNCT3    = 3'b011;
localparam INST_CSRRCI_FUNCT3   = 3'b111;


localparam INST_JAL_OPCODE      = 7'b1101111;
localparam INST_JALR_FUNCT3     = 3'b000;
localparam INST_JALR_OPCODE     = 7'b1100111;
localparam INST_LUI_OPCODE      = 7'b0110111;
localparam INST_AUIPC_OPCODE    = 7'b0010111;


localparam INST_ECALL           = 32'b00000000000000000000000001110011;

/*----------------Zicsr----------------*/
localparam INST_SRET            = 32'b0001000_00010_00000_000_00000_1110011;
localparam INST_MRET            = 32'b0011000_00010_00000_000_00000_1110011;

/*----------------Zifencei-------------*/
localparam INST_ZIFENCEI_FENCEI_OPCODE = 7'b0001111;
localparam INST_ZIFENCEI_FENCEI_FUNCT3 = 3'b001;


/*----------------RV32M----------------*/
`ifndef EXCLUDE_RV32M
localparam INST_RV32M_OPCODE        = 7'b0110011;
localparam INST_RV32M_FUNCT7        = 7'b0000001;

localparam INST_RV32M_MUL_FUNCT3    = 3'b000;
localparam INST_RV32M_MULH_FUNCT3   = 3'b001;
localparam INST_RV32M_MULHSU_FUNCT3 = 3'b010;
localparam INST_RV32M_MULHU_FUNCT3  = 3'b011;
localparam INST_RV32M_DIV_FUNCT3    = 3'b100;
localparam INST_RV32M_DIVU_FUNCT3   = 3'b101;
localparam INST_RV32M_REM_FUNCT3    = 3'b110;
localparam INST_RV32M_REMU_FUNCT3   = 3'b111;
`endif

/*----------------RV32M----------------*/
`ifndef EXCLUDE_RV32A

localparam INST_RV32A_OPCODE            = 7'b0101111;

localparam INST_RV32A_AMOSWAP_W_FUNCT3  = 3'b010;
localparam INST_RV32A_AMOSWAP_W_FUNCT5  = 5'b00001;

`endif


/*----------------Svinal---------------*/
localparam INST_SVINVAL_OPCODE = 7'b1110011;
localparam INST_SVINVAL_FUNCT3 = 3'b000;
localparam INST_SVINVAL_SINVAL_VMA_FUNCT7 = 7'b0001011;
localparam INST_SVINVAL_SFENCE_FUNCT7 = 7'b0001100;