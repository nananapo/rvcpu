module IDecode
    import basic::Inst, basic::UInt5;
    import stageinfo::*;
(
    input wire Inst     inst,
    output wire logic   is_illegal,
    output wire Ctrl    ctrl
);

import InstFormat::*;
import meminf::MemSize;

localparam X_2 = 2'b?;
localparam X_3 = 3'b?;
localparam X_5 = 5'b?;
localparam X_7 = 7'b?;
localparam X_X = 10'b?;

localparam WB_X = WB_ALU;
localparam SIZE_X = meminf::SIZE_W;

localparam T = 1'b1;
localparam F = 1'b0;

localparam DEFAULT_NOP = {ALU_ADD, BR_X, OP_SIGNED, OP1_X, OP2_X, MEN_X, ASEL_X, F, WB_X, CSR_X};

function [
    1 + // is_legal
    $bits(AluSel) +
    $bits(BrSel) +
    $bits(SignSel) +
    $bits(Op1Sel) +
    $bits(Op2Sel) +
    $bits(MemSel) +
    $bits(AextSel) +
    1 +  // rf_wen
    $bits(WbSel) +
    $bits(CsrCmd) - 1:0
] decode(
    input Inst inst
);
    casez (inst)
        // I
        {X_7    , X_X, LB_F3    , X_5, LOAD_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_L, ASEL_X, T, WB_MEM, CSR_X}; // LB
        {X_7    , X_X, LBU_F3   , X_5, LOAD_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_IMI , MEN_L, ASEL_X, T, WB_MEM, CSR_X}; // LBU
        {X_7    , X_X, LH_F3    , X_5, LOAD_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_L, ASEL_X, T, WB_MEM, CSR_X}; // LH
        {X_7    , X_X, LHU_F3   , X_5, LOAD_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_IMI , MEN_L, ASEL_X, T, WB_MEM, CSR_X}; // LHU
        {X_7    , X_X, LW_F3    , X_5, LOAD_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_L, ASEL_X, T, WB_MEM, CSR_X}; // LW
        {X_7    , X_X, SB_F3    , X_5, STORE_OP }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMS , MEN_S, ASEL_X, F, WB_X  , CSR_X}; // SB
        {X_7    , X_X, SH_F3    , X_5, STORE_OP }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMS , MEN_S, ASEL_X, F, WB_X  , CSR_X}; // SH
        {X_7    , X_X, SW_F3    , X_5, STORE_OP }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMS , MEN_S, ASEL_X, F, WB_X  , CSR_X}; // SW
        {ADD_F7 , X_X, ADD_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // ADD
        {SUB_F7 , X_X, SUB_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_SUB   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SUB
        {AND_F7 , X_X, AND_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_AND   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // AND
        {OR_F7  , X_X, OR_F3    , X_5, ALUR_OP  }   : decode = {T, ALU_OR    , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // OR
        {XOR_F7 , X_X, XOR_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_XOR   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // XOR
        {SLL_F7 , X_X, SLL_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_SLL   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SLL
        {SRL_F7 , X_X, SRL_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_SRL   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SRL
        {SRA_F7 , X_X, SRA_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_SRA   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SRA
        {SLT_F7 , X_X, SLT_F3   , X_5, ALUR_OP  }   : decode = {T, ALU_SLT   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SLT
        {SLTU_F7, X_X, SLTU_F3  , X_5, ALUR_OP  }   : decode = {T, ALU_SLT   , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SLTU
        {X_7    , X_X, ADDI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // ADDI
        {X_7    , X_X, ANDI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_AND   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // ANDI
        {X_7    , X_X, ORI_F3   , X_5, ALUI_OP  }   : decode = {T, ALU_OR    , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // ORI
        {X_7    , X_X, XORI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_XOR   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // XORI
        {SLLI_F7, X_X, SLLI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_SLL   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SLLI
        {SRLI_F7, X_X, SRLI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_SRL   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SRLI
        {SRAI_F7, X_X, SRAI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_SRA   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SRAI
        {X_7    , X_X, SLTI_F3  , X_5, ALUI_OP  }   : decode = {T, ALU_SLT   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SLTI
        {X_7    , X_X, SLTIU_F3 , X_5, ALUI_OP  }   : decode = {T, ALU_SLT   , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // SLTIU
        {X_7    , X_X, BEQ_F3   , X_5, BR_OP    }   : decode = {T, ALU_X     , BR_BEQ  , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, F, WB_X  , CSR_X}; // BEQ
        {X_7    , X_X, BNE_F3   , X_5, BR_OP    }   : decode = {T, ALU_X     , BR_BNE  , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, F, WB_X  , CSR_X}; // BNE
        {X_7    , X_X, BLT_F3   , X_5, BR_OP    }   : decode = {T, ALU_X     , BR_BLT  , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, F, WB_X  , CSR_X}; // BLT
        {X_7    , X_X, BGE_F3   , X_5, BR_OP    }   : decode = {T, ALU_X     , BR_BGE  , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, F, WB_X  , CSR_X}; // BGE
        {X_7    , X_X, BLTU_F3  , X_5, BR_OP    }   : decode = {T, ALU_X     , BR_BLT  , OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, F, WB_X  , CSR_X}; // BLTU
        {X_7    , X_X, BGEU_F3  , X_5, BR_OP    }   : decode = {T, ALU_X     , BR_BGE  , OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, F, WB_X  , CSR_X}; // BGEU
        {X_7    , X_X, X_3      , X_5, JAL_OP   }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_PC , OP2_IMJ , MEN_X, ASEL_X, T, WB_PC , CSR_X}; // JAL
        {X_7    , X_X, JALR_F3  , X_5, JALR_OP  }   : decode = {T, ALU_JALR  , BR_X    , OP_SIGNED  , OP1_RS1, OP2_IMI , MEN_X, ASEL_X, T, WB_PC , CSR_X}; // JALR
        {X_7    , X_X, X_3      , X_5, LUI_OP   }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_X  , OP2_IMU , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // LUI
        {X_7    , X_X, X_3      , X_5, AUIPC_OP }   : decode = {T, ALU_ADD   , BR_X    , OP_SIGNED  , OP1_PC , OP2_IMU , MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // AUIPC

        {X_7    , X_X, FENCE_F3 , X_5, MISC_MEM_OP} : decode = {T, DEFAULT_NOP}; // fence
        {X_7    , X_X, FENCEI_F3, X_5, MISC_MEM_OP} : decode = {T, DEFAULT_NOP}; // fence.i
        WFI                                         : decode = {T, DEFAULT_NOP}; // wfi TODO

        {SFENCE_VMA_F7, X_X, PRIV_F3, 5'b0, SYSTEM_OP}  : decode = {T, DEFAULT_NOP};

        {X_7    , X_X, CSRRW_F3 , X_5, SYSTEM_OP}   : decode = {T, ALU_COPY1 , BR_X    , OP_SIGNED  , OP1_RS1, OP2_X   , MEN_X, ASEL_X, T, WB_CSR, CSR_W}; // CSRRW
        {X_7    , X_X, CSRRWI_F3, X_5, SYSTEM_OP}   : decode = {T, ALU_COPY1 , BR_X    , OP_SIGNED  , OP1_IMZ, OP2_X   , MEN_X, ASEL_X, T, WB_CSR, CSR_W}; // CSRRWI
        {X_7    , X_X, CSRRS_F3 , X_5, SYSTEM_OP}   : decode = {T, ALU_COPY1 , BR_X    , OP_SIGNED  , OP1_RS1, OP2_X   , MEN_X, ASEL_X, T, WB_CSR, CSR_S}; // CSRRS
        {X_7    , X_X, CSRRSI_F3, X_5, SYSTEM_OP}   : decode = {T, ALU_COPY1 , BR_X    , OP_SIGNED  , OP1_IMZ, OP2_X   , MEN_X, ASEL_X, T, WB_CSR, CSR_S}; // CSRRSI
        {X_7    , X_X, CSRRC_F3 , X_5, SYSTEM_OP}   : decode = {T, ALU_COPY1 , BR_X    , OP_SIGNED  , OP1_RS1, OP2_X   , MEN_X, ASEL_X, T, WB_CSR, CSR_C}; // CSRRC
        {X_7    , X_X, CSRRCI_F3, X_5, SYSTEM_OP}   : decode = {T, ALU_COPY1 , BR_X    , OP_SIGNED  , OP1_IMZ, OP2_X   , MEN_X, ASEL_X, T, WB_CSR, CSR_C}; // CSRRCI
        ECALL                                       : decode = {T, ALU_X     , BR_X    , OP_SIGNED  , OP1_X  , OP2_X   , MEN_X, ASEL_X, F, WB_X  , CSR_ECALL}; // ECALL
        EBREAK                                      : decode = {T, ALU_X     , BR_X    , OP_SIGNED  , OP1_X  , OP2_X   , MEN_X, ASEL_X, F, WB_X  , CSR_EBREAK}; // EBREAK

        SRET                                        : decode = {T, ALU_X     , BR_X    , OP_SIGNED  , OP1_X  , OP2_X   , MEN_X, ASEL_X, F, WB_X  , CSR_SRET}; // MRET
        MRET                                        : decode = {T, ALU_X     , BR_X    , OP_SIGNED  , OP1_X  , OP2_X   , MEN_X, ASEL_X, F, WB_X  , CSR_MRET}; // SRET

        {M_F7   , X_X, M_MUL_F3     , X_5, M_OP}    : decode = {T, ALU_MUL   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // MUL
        {M_F7   , X_X, M_MULH_F3    , X_5, M_OP}    : decode = {T, ALU_MULH  , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // MULH
        {M_F7   , X_X, M_MULHSU_F3  , X_5, M_OP}    : decode = {T, ALU_MULHSU, BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // MULHSU
        {M_F7   , X_X, M_MULHU_F3   , X_5, M_OP}    : decode = {T, ALU_MULH  , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // MULHU
        {M_F7   , X_X, M_DIV_F3     , X_5, M_OP}    : decode = {T, ALU_DIV   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // DIV
        {M_F7   , X_X, M_DIVU_F3    , X_5, M_OP}    : decode = {T, ALU_DIV   , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // DIVU
        {M_F7   , X_X, M_REM_F3     , X_5, M_OP}    : decode = {T, ALU_REM   , BR_X    , OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // REM
        {M_F7   , X_X, M_REMU_F3    , X_5, M_OP}    : decode = {T, ALU_REM   , BR_X    , OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // REMU

        {A_LR_W_F5      , X_2, A_LR_W_RS2, X_5, A_F3, X_5, A_OP}  : decode = {T, ALU_COPY1, BR_X, OP_SIGNED, OP1_RS1, OP2_RS2W, MEN_A, ASEL_LR      , T, WB_MEM, CSR_X}; // LR
        {A_SC_W_F5      , X_2, X_5       , X_5, A_F3, X_5, A_OP}  : decode = {T, ALU_COPY1, BR_X, OP_SIGNED, OP1_RS1, OP2_RS2W, MEN_A, ASEL_SC      , T, WB_MEM, CSR_X}; // SC
        {A_AMOSWAP_W_F5 , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_SWAP, T, WB_MEM, CSR_X}; // AMO.SWAP
        {A_AMOADD_W_F5  , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_ADD , T, WB_MEM, CSR_X}; // AMO.ADD
        {A_AMOXOR_W_F5  , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_XOR , T, WB_MEM, CSR_X}; // AMO.XOR
        {A_AMOAND_W_F5  , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_AND , T, WB_MEM, CSR_X}; // AMO.AND
        {A_AMOOR_W_F5   , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_OR  , T, WB_MEM, CSR_X}; // AMO.OR
        {A_AMOMIN_W_F5  , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_MIN , T, WB_MEM, CSR_X}; // AMO.MIN
        {A_AMOMAX_W_F5  , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_SIGNED  , OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_MAX , T, WB_MEM, CSR_X}; // AMO.MAX
        {A_AMOMINU_W_F5 , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_MIN , T, WB_MEM, CSR_X}; // AMO.MINU
        {A_AMOMAXU_W_F5 , X_2, X_5, X_5, A_F3, X_5, A_OP}   : decode = {T, ALU_COPY1, BR_X, OP_UNSIGNED, OP1_RS1, OP2_RS2W, MEN_A, ASEL_AMO_MAX , T, WB_MEM, CSR_X}; // AMO.MAXU


        {ZICOND_F7, X_X, ZICOND_CZERO_EQZ_F3, X_5, ZICOND_OP} : decode = {T, ALU_CZERO_EQ, BR_X, OP_SIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // CZERO.EQZ
        {ZICOND_F7, X_X, ZICOND_CZERO_NEZ_F3, X_5, ZICOND_OP} : decode = {T, ALU_CZERO_NE, BR_X, OP_SIGNED, OP1_RS1, OP2_RS2W, MEN_X, ASEL_X, T, WB_ALU, CSR_X}; // CZERO.NEZ

        // TODO sfence
        {SVINVAL_SFENCE_F7      , X_5, X_5, SVINVAL_F3, X_5, SYSTEM_OP} : decode = {T, DEFAULT_NOP};
        {SVINVAL_SINVAL_VMA_F7  , X_5, X_5, SVINVAL_F3, X_5, SYSTEM_OP} : decode = {T, DEFAULT_NOP};

        default : decode = {F, DEFAULT_NOP};
    endcase
endfunction

wire is_legal;
assign is_illegal = !is_legal;

assign {
    is_legal,
    ctrl.i_exe,
    ctrl.br_exe,
    ctrl.sign_sel,
    ctrl.op1_sel,
    ctrl.op2_sel,
    ctrl.mem_sel,
    ctrl.a_sel,
    ctrl.rf_wen,
    ctrl.wb_sel,
    ctrl.csr_cmd
} = decode(inst);

wire [6:0] F7       = inst[31:25];
wire [2:0] F3       = inst[14:12];
wire UInt5 wb_addr  = inst[11:7];
wire [6:0] OP       = inst[6:0];

assign ctrl.mem_size = MemSize'(F3[1:0]);

assign ctrl.wb_addr     = RegSel'(wb_addr);
assign ctrl.jmp_pc_flg  = OP == JAL_OP;
assign ctrl.jmp_reg_flg = F3 == JALR_F3 & OP == JALR_OP;
assign ctrl.fence_i     = OP == MISC_MEM_OP & F3 == FENCEI_F3;
assign ctrl.sfence      = OP == SYSTEM_OP & F7 == SFENCE_VMA_F7 & F3 == PRIV_F3 & wb_addr == 5'b0;
assign ctrl.svinval     = OP == SYSTEM_OP & (F7 == SVINVAL_SINVAL_VMA_F7 | F7 == SVINVAL_SFENCE_F7) & F3 == SVINVAL_F3;
assign ctrl.wfi         = inst == WFI;

endmodule