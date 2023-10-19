/*
funct3[2] == 0 : sext
funct3[2] == 1 : uext

funct3[1:0] == 00 : byte
funct3[1:0] == 01 : half
funct3[1:0] == 10 : word
*/
localparam LOAD_OP  = 7'b0000011;
localparam STORE_OP = 7'b0100011;
localparam LB_F3    = 3'b000;
localparam LH_F3    = 3'b001;
localparam LW_F3    = 3'b010;
localparam LBU_F3   = 3'b100;
localparam LHU_F3   = 3'b101;
localparam SB_F3    = 3'b000;
localparam SH_F3    = 3'b001;
localparam SW_F3    = 3'b010;

localparam MISC_MEM_OP  = 7'b0001111;
localparam FENCE_F3     = 3'b000;
localparam FENCEI_F3    = 3'b001; // Zifencei


localparam ALUR_OP  = 7'b0110011;
localparam ADD_F7   = 7'b0000000;
localparam SUB_F7   = 7'b0100000;
localparam AND_F7   = 7'b0000000;
localparam OR_F7    = 7'b0000000;
localparam XOR_F7   = 7'b0000000;
localparam SLL_F7   = 7'b0000000;
localparam SRL_F7   = 7'b0000000;
localparam SRA_F7   = 7'b0100000;
localparam SLT_F7   = 7'b0000000;
localparam SLTU_F7  = 7'b0000000;
localparam AND_F3   = 3'b111;
localparam ADD_F3   = 3'b000;
localparam SUB_F3   = 3'b000;
localparam OR_F3    = 3'b110;
localparam XOR_F3   = 3'b100;
localparam SLL_F3   = 3'b001;
localparam SRL_F3   = 3'b101;
localparam SRA_F3   = 3'b101;
localparam SLT_F3   = 3'b010;
localparam SLTU_F3  = 3'b011;


localparam ALUI_OP  = 7'b0010011;
localparam SLLI_F7  = 7'b0000000;
localparam SRLI_F7  = 7'b0000000;
localparam SRAI_F7  = 7'b0100000;
localparam ADDI_F3  = 3'b000;
localparam ANDI_F3  = 3'b111;
localparam ORI_F3   = 3'b110;
localparam XORI_F3  = 3'b100;
localparam SLLI_F3  = 3'b001;
localparam SRLI_F3  = 3'b101;
localparam SRAI_F3  = 3'b101;
localparam SLTI_F3  = 3'b010;
localparam SLTIU_F3 = 3'b011;


localparam BR_OP    = 7'b1100011;
localparam BEQ_F3   = 3'b000;
localparam BNE_F3   = 3'b001;
localparam BLT_F3   = 3'b100;
localparam BGE_F3   = 3'b101;
localparam BLTU_F3  = 3'b110;
localparam BGEU_F3  = 3'b111;

localparam SYSTEM_OP= 7'b1110011;

localparam CSRRW_F3 = 3'b001;
localparam CSRRWI_F3= 3'b101;
localparam CSRRS_F3 = 3'b010;
localparam CSRRSI_F3= 3'b110;
localparam CSRRC_F3 = 3'b011;
localparam CSRRCI_F3= 3'b111;


localparam JAL_OP   = 7'b1101111;
localparam JALR_F3  = 3'b000;
localparam JALR_OP  = 7'b1100111;
localparam LUI_OP   = 7'b0110111;
localparam AUIPC_OP = 7'b0010111;

localparam ECALL    = {12'b0, 13'b0, SYSTEM_OP};
localparam EBREAK   = {12'b1, 13'b0, SYSTEM_OP};
localparam WFI      = {12'b0001000_00101, 5'b0, 3'b0, 5'b0, SYSTEM_OP};

/*----------------Zicsr----------------*/
localparam SRET = {25'b0001000_00010_00000_000_00000, SYSTEM_OP};
localparam MRET = {25'b0011000_00010_00000_000_00000, SYSTEM_OP};


/*----------------32M-------------*/
localparam M_OP = 7'b0110011;
localparam M_F7 = 7'b0000001;
localparam M_MUL_F3    = 3'b000;
localparam M_MULH_F3   = 3'b001;
localparam M_MULHSU_F3 = 3'b010;
localparam M_MULHU_F3  = 3'b011;
localparam M_DIV_F3    = 3'b100;
localparam M_DIVU_F3   = 3'b101;
localparam M_REM_F3    = 3'b110;
localparam M_REMU_F3   = 3'b111;

/*----------------32A-------------*/
localparam A_OP = 7'b0101111;
localparam A_F3 = 3'b010; // TODO RV64
localparam A_LR_W_RS2       = 5'b0;
localparam A_LR_W_F5        = 5'b00010;
localparam A_SC_W_F5        = 5'b00011;
localparam A_AMOSWAP_W_F5   = 5'b00001;
localparam A_AMOADD_W_F5    = 5'b00000;
localparam A_AMOXOR_W_F5    = 5'b00100;
localparam A_AMOAND_W_F5    = 5'b01100;
localparam A_AMOOR_W_F5     = 5'b01000;
localparam A_AMOMIN_W_F5    = 5'b10000;
localparam A_AMOMAX_W_F5    = 5'b10100;
localparam A_AMOMINU_W_F5   = 5'b11000;
localparam A_AMOMAXU_W_F5   = 5'b11100;

/*----------------Svinal---------------*/
localparam SVINVAL_F3 = 3'b000;
localparam SVINVAL_SINVAL_VMA_F7 = 7'b0001011;
localparam SVINVAL_SFENCE_F7 = 7'b0001100;

localparam PRIV_F3          = 3'b000;
localparam SFENCE_VMA_F7    = 7'b0001001;

/*---------------Zicond----------------*/
localparam ZICOND_OP = 7'b0110011;
localparam ZICOND_F7 = 7'b0000111;
localparam ZICOND_CZERO_EQZ_F3 = 3'b101;
localparam ZICOND_CZERO_NEZ_F3 = 3'b111;