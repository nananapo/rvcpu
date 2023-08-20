/* verilator lint_off CASEX */
module IDecode (
    input wire[31:0]        inst,
    output wire ctrltype    ctrl
);

`include "include/core.sv"
`include "include/inst.sv"

//  i_exe(4) : br_exe(3) : m_exe(4) : op1_sel(4) : op2_sel(4) : mem_wen(2) : mem_size(2) : rf_wen(1) : wb_sel(2) : csr_cmd(3)
function [4 + 3 + 4 + 4 + 4 + 2 + 2 + 1 + 2 + 3 - 1:0] decode(input [31:0] inst);
    casex (inst)
        // RV32I
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_LB_FUNCT3    , 5'bxxxxx, INST_LOAD_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LS, SIZE_B, REN_S, WB_MEM, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_LBU_FUNCT3   , 5'bxxxxx, INST_LOAD_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LU, SIZE_B, REN_S, WB_MEM, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_LH_FUNCT3    , 5'bxxxxx, INST_LOAD_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LS, SIZE_H, REN_S, WB_MEM, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_LHU_FUNCT3   , 5'bxxxxx, INST_LOAD_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LU, SIZE_H, REN_S, WB_MEM, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_LW_FUNCT3    , 5'bxxxxx, INST_LOAD_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LS, SIZE_W, REN_S, WB_MEM, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_SB_FUNCT3    , 5'bxxxxx, INST_STORE_OPCODE } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMS , MEN_S , SIZE_B, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_SH_FUNCT3    , 5'bxxxxx, INST_STORE_OPCODE } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMS , MEN_S , SIZE_H, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_SW_FUNCT3    , 5'bxxxxx, INST_STORE_OPCODE } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMS , MEN_S , SIZE_W, REN_X, WB_X  , CSR_X};
        {INST_ADD_FUNCT7 , 10'bxxxxxxxxxx, INST_ADD_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SUB_FUNCT7 , 10'bxxxxxxxxxx, INST_SUB_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_SUB , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_AND_FUNCT7 , 10'bxxxxxxxxxx, INST_AND_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_AND , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_OR_FUNCT7  , 10'bxxxxxxxxxx, INST_OR_FUNCT3    , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_OR  , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_XOR_FUNCT7 , 10'bxxxxxxxxxx, INST_XOR_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_XOR , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SLL_FUNCT7 , 10'bxxxxxxxxxx, INST_SLL_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_SLL , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SRL_FUNCT7 , 10'bxxxxxxxxxx, INST_SRL_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_SRL , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SRA_FUNCT7 , 10'bxxxxxxxxxx, INST_SRA_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_SRA , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SLT_FUNCT7 , 10'bxxxxxxxxxx, INST_SLT_FUNCT3   , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_SLT , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SLTU_FUNCT7, 10'bxxxxxxxxxx, INST_SLTU_FUNCT3  , 5'bxxxxx, INST_ALUR_OPCODE  } : decode = {ALUI_SLTU, BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_ADDI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_ANDI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_AND , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_ORI_FUNCT3   , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_OR  , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_XORI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_XOR , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SLLI_FUNCT7, 10'bxxxxxxxxxx, INST_SLLI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_SLL , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SRLI_FUNCT7, 10'bxxxxxxxxxx, INST_SRLI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_SRL , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_SRAI_FUNCT7, 10'bxxxxxxxxxx, INST_SRAI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_SRA , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_SLTI_FUNCT3  , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_SLT , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_SLTIU_FUNCT3 , 5'bxxxxx, INST_ALUI_OPCODE  } : decode = {ALUI_SLTU, BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_BEQ_FUNCT3   , 5'bxxxxx, INST_BR_OPCODE    } : decode = {ALUI_X, BR_BEQ , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_BNE_FUNCT3   , 5'bxxxxx, INST_BR_OPCODE    } : decode = {ALUI_X, BR_BNE , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_BLT_FUNCT3   , 5'bxxxxx, INST_BR_OPCODE    } : decode = {ALUI_X, BR_BLT , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_BGE_FUNCT3   , 5'bxxxxx, INST_BR_OPCODE    } : decode = {ALUI_X, BR_BGE , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_BLTU_FUNCT3  , 5'bxxxxx, INST_BR_OPCODE    } : decode = {ALUI_X, BR_BLTU, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_BGEU_FUNCT3  , 5'bxxxxx, INST_BR_OPCODE    } : decode = {ALUI_X, BR_BGEU, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , SIZE_X, REN_X, WB_X  , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_JAL_OPCODE   } : decode = {ALUI_ADD  , BR_X, ALUM_X, OP1_PC , OP2_IMJ, MEN_X , SIZE_X, REN_S, WB_PC , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_JALR_FUNCT3  , 5'bxxxxx, INST_JALR_OPCODE  } : decode = {ALUI_JALR , BR_X, ALUM_X, OP1_RS1, OP2_IMI, MEN_X , SIZE_X, REN_S, WB_PC , CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_LUI_OPCODE   } : decode = {ALUI_ADD  , BR_X, ALUM_X, OP1_X  , OP2_IMU, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_AUIPC_OPCODE } : decode = {ALUI_ADD  , BR_X, ALUM_X, OP1_PC , OP2_IMU, MEN_X , SIZE_X, REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_CSRRW_FUNCT3 , 5'bxxxxx, INST_CSR_OPCODE   } : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X  , MEN_X , SIZE_X, REN_S, WB_CSR, CSR_W};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_CSRRWI_FUNCT3, 5'bxxxxx, INST_CSR_OPCODE   } : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_IMZ, OP2_X  , MEN_X , SIZE_X, REN_S, WB_CSR, CSR_W};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_CSRRS_FUNCT3 , 5'bxxxxx, INST_CSR_OPCODE   } : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X  , MEN_X , SIZE_X, REN_S, WB_CSR, CSR_S};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_CSRRSI_FUNCT3, 5'bxxxxx, INST_CSR_OPCODE   } : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_IMZ, OP2_X  , MEN_X , SIZE_X, REN_S, WB_CSR, CSR_S};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_CSRRC_FUNCT3 , 5'bxxxxx, INST_CSR_OPCODE   } : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X  , MEN_X , SIZE_X, REN_S, WB_CSR, CSR_C};
        {7'bxxxxxxx      , 10'bxxxxxxxxxx, INST_CSRRCI_FUNCT3, 5'bxxxxx, INST_CSR_OPCODE   } : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_IMZ, OP2_X  , MEN_X , SIZE_X, REN_S, WB_CSR, CSR_C};
        INST_ECALL                                                                           : decode = {ALUI_X    , BR_X, ALUM_X, OP1_X  , OP2_X  , MEN_X , SIZE_X, REN_X, WB_X  , CSR_ECALL};
        INST_SRET                                                                            : decode = {ALUI_X    , BR_X, ALUM_X, OP1_X  , OP2_X  , MEN_X , SIZE_X, REN_X, WB_X  , CSR_SRET};
        INST_MRET                                                                            : decode = {ALUI_X    , BR_X, ALUM_X, OP1_X  , OP2_X  , MEN_X , SIZE_X, REN_X, WB_X  , CSR_MRET};
`ifndef EXCLUDE_RV32M
        // RV32M
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MUL_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MUL   , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULH_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MULH  , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULHSU_FUNCT3, 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MULHSU, OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULHU_FUNCT3 , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MULHU , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_DIV_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_DIV   , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_DIVU_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_DIVU  , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_REM_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_REM   , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_REMU_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_REMU  , OP1_RS1, OP2_RS2W, MEN_X, SIZE_X, REN_S, WB_ALU, CSR_X};
`endif
/*
`ifndef EXCLUDE_RV32A
        {INST_RV32A_AMOSWAP_W_FUNCT5, 2'bxx, 10'bxxxxxxxxxx, INST_RV32A_AMOSWAP_W_FUNCT3, 5'bxxxxx, INST_RV32A_OPCODE} :
            decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X, MEN_AMOSWAP_W_AQRL, REN_S, WB_MEMW, CSR_X};
`endif
*/
        default : // NOP
            decode = {ALUI_ADD, BR_X, ALUM_X, OP1_X, OP2_X, MEN_X, SIZE_X, REN_X, WB_X, CSR_X};
    endcase
endfunction

assign {
    ctrl.i_exe,
    ctrl.br_exe,
    ctrl.m_exe,
    ctrl.op1_sel,
    ctrl.op2_sel,
    ctrl.mem_wen,
    ctrl.mem_size,
    ctrl.rf_wen,
    ctrl.wb_sel,
    ctrl.csr_cmd
} = decode(inst);

wire [6:0] funct7       = inst[31:25];
wire [2:0] funct3       = inst[14:12];
wire [6:0] opcode       = inst[6:0];

assign ctrl.wb_addr     = inst[11:7];
assign ctrl.jmp_pc_flg  = opcode == INST_JAL_OPCODE;
assign ctrl.jmp_reg_flg = funct3 == INST_JALR_FUNCT3 && opcode == INST_JALR_OPCODE;
assign ctrl.svinval     = (funct7 == INST_SVINVAL_SFENCE_FUNCT7 || funct7 == INST_SVINVAL_SINVAL_VMA_FUNCT7) && funct3 == INST_SVINVAL_FUNCT3 && opcode == INST_SVINVAL_OPCODE;

endmodule