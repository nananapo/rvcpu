/* verilator lint_off CASEX */

// TODO フォワーディングの有無でkanataを比較するとちょっと面白いので、フォワーディングするかどうかを設定できるといいかも
// フォワーディングがない実装は 4d5c53dd5ed32025d7428d088e6bbc968dafdc4d 以前を参照
module DecodeStage
(
    input wire          clk,

    input wire          id_valid,
    input wire[31:0]    id_reg_pc,
    input wire[31:0]    id_inst,
    input wire[63:0]    id_inst_id,
    
    output wire             id_ds_valid,
    output wire [31:0]      id_ds_reg_pc,
    output wire [31:0]      id_ds_inst,
    output wire [63:0]      id_ds_inst_id,
    output wire ctrltype    id_ds_ctrl
);

`include "include/core.sv"
`include "include/inst.sv"

wire [31:0] reg_pc  = id_reg_pc;
wire [31:0] inst    = id_inst;
wire [63:0] inst_id = id_inst_id;

//  i_exe : br_exe : m_exe : op1_sel : op2_sel : mem_wen : rf_wen : wb_sel : csr_cmd
function [4 + 3 + 4 + 4 + 4 + 4 + 1 + 4 + 3 - 1:0] decode(input [31:0] inst);
    casex (inst)
        // RV32I
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LB_FUNCT3    , 5'bxxxxx, INST_LB_OPCODE      }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LB, REN_S, WB_MEMB , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LBU_FUNCT3   , 5'bxxxxx, INST_LBU_OPCODE     }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LBU,REN_S, WB_MEMBU, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LH_FUNCT3    , 5'bxxxxx, INST_LH_OPCODE      }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LH, REN_S, WB_MEMH , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LHU_FUNCT3   , 5'bxxxxx, INST_LHU_OPCODE     }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LHU,REN_S, WB_MEMHU, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LW_FUNCT3    , 5'bxxxxx, INST_LW_OPCODE      }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_LW, REN_S, WB_MEMW , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SB_FUNCT3    , 5'bxxxxx, INST_SB_OPCODE      }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMS , MEN_SB, REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SH_FUNCT3    , 5'bxxxxx, INST_SH_OPCODE      }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMS , MEN_SH, REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SW_FUNCT3    , 5'bxxxxx, INST_SW_OPCODE      }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMS , MEN_SW, REN_X, WB_X    , CSR_X};
        {INST_ADD_FUNCT7    , 10'bxxxxxxxxxx, INST_ADD_FUNCT3   , 5'bxxxxx, INST_ADD_OPCODE     }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_ADDI_FUNCT3  , 5'bxxxxx, INST_ADDI_OPCODE    }  : decode = {ALUI_ADD , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SUB_FUNCT7    , 10'bxxxxxxxxxx, INST_SUB_FUNCT3   , 5'bxxxxx, INST_SUB_OPCODE     }  : decode = {ALUI_SUB , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_AND_FUNCT7    , 10'bxxxxxxxxxx, INST_AND_FUNCT3   , 5'bxxxxx, INST_AND_OPCODE     }  : decode = {ALUI_AND , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_OR_FUNCT7     , 10'bxxxxxxxxxx, INST_OR_FUNCT3    , 5'bxxxxx, INST_OR_OPCODE      }  : decode = {ALUI_OR  , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_XOR_FUNCT7    , 10'bxxxxxxxxxx, INST_XOR_FUNCT3   , 5'bxxxxx, INST_XOR_OPCODE     }  : decode = {ALUI_XOR , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_ANDI_FUNCT3  , 5'bxxxxx, INST_ANDI_OPCODE    }  : decode = {ALUI_AND , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_ORI_FUNCT3   , 5'bxxxxx, INST_ORI_OPCODE     }  : decode = {ALUI_OR  , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_XORI_FUNCT3  , 5'bxxxxx, INST_XORI_OPCODE    }  : decode = {ALUI_XOR , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLL_FUNCT7    , 10'bxxxxxxxxxx, INST_SLL_FUNCT3   , 5'bxxxxx, INST_SLL_OPCODE     }  : decode = {ALUI_SLL , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRL_FUNCT7    , 10'bxxxxxxxxxx, INST_SRL_FUNCT3   , 5'bxxxxx, INST_SRL_OPCODE     }  : decode = {ALUI_SRL , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRA_FUNCT7    , 10'bxxxxxxxxxx, INST_SRA_FUNCT3   , 5'bxxxxx, INST_SRA_OPCODE     }  : decode = {ALUI_SRA , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLLI_FUNCT7   , 10'bxxxxxxxxxx, INST_SLLI_FUNCT3  , 5'bxxxxx, INST_SLLI_OPCODE    }  : decode = {ALUI_SLL , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRLI_FUNCT7   , 10'bxxxxxxxxxx, INST_SRLI_FUNCT3  , 5'bxxxxx, INST_SRLI_OPCODE    }  : decode = {ALUI_SRL , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRAI_FUNCT7   , 10'bxxxxxxxxxx, INST_SRAI_FUNCT3  , 5'bxxxxx, INST_SRAI_OPCODE    }  : decode = {ALUI_SRA , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLT_FUNCT7    , 10'bxxxxxxxxxx, INST_SLT_FUNCT3   , 5'bxxxxx, INST_SLT_OPCODE     }  : decode = {ALUI_SLT , BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLTU_FUNCT7   , 10'bxxxxxxxxxx, INST_SLTU_FUNCT3  , 5'bxxxxx, INST_SLTU_OPCODE    }  : decode = {ALUI_SLTU, BR_X, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SLTI_FUNCT3  , 5'bxxxxx, INST_SLTI_OPCODE    }  : decode = {ALUI_SLT , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SLTIU_FUNCT3 , 5'bxxxxx, INST_SLTIU_OPCODE   }  : decode = {ALUI_SLTU, BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};

        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BEQ_FUNCT3   , 5'bxxxxx, INST_BEQ_OPCODE     }  : decode = {ALUI_X, BR_BEQ , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BNE_FUNCT3   , 5'bxxxxx, INST_BNE_OPCODE     }  : decode = {ALUI_X, BR_BNE , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BLT_FUNCT3   , 5'bxxxxx, INST_BLT_OPCODE     }  : decode = {ALUI_X, BR_BLT , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BGE_FUNCT3   , 5'bxxxxx, INST_BGE_OPCODE     }  : decode = {ALUI_X, BR_BGE , ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BLTU_FUNCT3  , 5'bxxxxx, INST_BLTU_OPCODE    }  : decode = {ALUI_X, BR_BLTU, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BGEU_FUNCT3  , 5'bxxxxx, INST_BGEU_OPCODE    }  : decode = {ALUI_X, BR_BGEU, ALUM_X, OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X, CSR_X};

        {7'bxxxxxxx         , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_JAL_OPCODE     }  : decode = {ALUI_ADD  , BR_X, ALUM_X, OP1_PC , OP2_IMJ , MEN_X , REN_S, WB_PC , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_JALR_FUNCT3  , 5'bxxxxx, INST_JALR_OPCODE    }  : decode = {ALUI_JALR , BR_X, ALUM_X, OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_PC , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_LUI_OPCODE     }  : decode = {ALUI_ADD  , BR_X, ALUM_X, OP1_X  , OP2_IMU , MEN_X , REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_AUIPC_OPCODE   }  : decode = {ALUI_ADD  , BR_X, ALUM_X, OP1_PC , OP2_IMU , MEN_X , REN_S, WB_ALU, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRW_FUNCT3 , 5'bxxxxx, INST_CSRRW_OPCODE   }  : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR, CSR_W};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRWI_FUNCT3, 5'bxxxxx, INST_CSRRWI_OPCODE  }  : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR, CSR_W};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRS_FUNCT3 , 5'bxxxxx, INST_CSRRS_OPCODE   }  : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR, CSR_S};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRSI_FUNCT3, 5'bxxxxx, INST_CSRRSI_OPCODE  }  : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR, CSR_S};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRC_FUNCT3 , 5'bxxxxx, INST_CSRRC_OPCODE   }  : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR, CSR_C};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRCI_FUNCT3, 5'bxxxxx, INST_CSRRCI_OPCODE  }  : decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR, CSR_C};
        INST_ECALL                                                                                 : decode = {ALUI_X    , BR_X, ALUM_X, OP1_X  , OP2_X   , MEN_X , REN_X, WB_X  , CSR_ECALL};
        INST_SRET                                                                                  : decode = {ALUI_X    , BR_X, ALUM_X, OP1_X  , OP2_X   , MEN_X , REN_X, WB_X  , CSR_SRET};
        INST_MRET                                                                                  : decode = {ALUI_X    , BR_X, ALUM_X, OP1_X  , OP2_X   , MEN_X , REN_X, WB_X  , CSR_MRET};

`ifndef EXCLUDE_RV32M
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MUL_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MUL   , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULH_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MULH  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULHSU_FUNCT3, 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MULHSU, OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULHU_FUNCT3 , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_MULHU , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_DIV_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_DIV   , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_DIVU_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_DIVU  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_REM_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_REM   , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_REMU_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALUI_X, BR_X, ALUM_REMU  , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
`endif

`ifndef EXCLUDE_RV32A
        {INST_RV32A_AMOSWAP_W_FUNCT5, 2'bxx, 10'bxxxxxxxxxx, INST_RV32A_AMOSWAP_W_FUNCT3, 5'bxxxxx, INST_RV32A_OPCODE} :
            decode = {ALUI_COPY1, BR_X, ALUM_X, OP1_RS1, OP2_X, MEN_AMOSWAP_W_AQRL, REN_S, WB_MEMW, CSR_X};
`endif

        // default : nop
        default : 
            decode = {ALUI_ADD, BR_X, ALUM_X, OP1_X, OP2_X, MEN_X, REN_X, WB_X, CSR_X};
    endcase
endfunction

wire alui_exe_type  i_exe;
wire br_exe_type    br_exe;
wire alum_exe_type  m_exe;
wire [3:0] op1_sel;
wire [3:0] op2_sel;
wire [3:0] mem_wen;
wire [0:0] rf_wen;
wire [3:0] wb_sel;
wire [2:0] csr_cmd;
assign {i_exe, br_exe, m_exe, op1_sel, op2_sel, mem_wen, rf_wen, wb_sel, csr_cmd} = decode(inst);

wire [4:0] wb_addr          = inst[11:7];

wire [11:0] imm_i           = inst[31:20];
wire [11:0] imm_s           = {inst[31:25], inst[11:7]};
wire [11:0] imm_b           = {inst[31], inst[7], inst[30:25], inst[11:8]};
wire [19:0] imm_j           = {inst[31], inst[19:12], inst[20], inst[30:21]};
wire [19:0] imm_u           = inst[31:12];
wire [4:0]  imm_z           = inst[19:15];

wire [31:0] imm_i_sext      = {{20{imm_i[11]}}, imm_i};
wire [31:0] imm_s_sext      = {{20{imm_s[11]}}, imm_s};
wire [31:0] imm_b_sext      = {{19{imm_b[11]}}, imm_b, 1'b0};
wire [31:0] imm_j_sext      = {{11{imm_j[19]}}, imm_j, 1'b0};
wire [31:0] imm_u_shifted   = {imm_u, 12'b0};
wire [31:0] imm_z_uext      = {27'd0, imm_z};

wire [2:0] funct3           = inst[14:12];
wire [6:0] funct7           = inst[31:25];
wire [6:0] opcode           = inst[6:0];

wire inst_is_jal            = opcode == INST_JAL_OPCODE;
wire inst_is_jalr           = funct3 == INST_JALR_FUNCT3 && opcode == INST_JALR_OPCODE;

assign id_ds_valid          = id_valid;
assign id_ds_reg_pc         = reg_pc;
assign id_ds_inst           = inst;
assign id_ds_inst_id        = inst_id;

assign id_ds_ctrl.i_exe         = i_exe;
assign id_ds_ctrl.br_exe        = br_exe;
assign id_ds_ctrl.m_exe         = m_exe;
assign id_ds_ctrl.op1_sel       = op1_sel;
assign id_ds_ctrl.op2_sel       = op2_sel;
assign id_ds_ctrl.op1_data      = 32'hzzzzzzzz;
assign id_ds_ctrl.op2_data      = 32'hzzzzzzzz;
assign id_ds_ctrl.rs2_data      = 32'hzzzzzzzz;
assign id_ds_ctrl.mem_wen       = mem_wen;
assign id_ds_ctrl.rf_wen        = rf_wen;
assign id_ds_ctrl.wb_sel        = wb_sel;
assign id_ds_ctrl.wb_addr       = wb_addr;
assign id_ds_ctrl.csr_cmd       = csr_cmd;
assign id_ds_ctrl.jmp_pc_flg    = inst_is_jal;
assign id_ds_ctrl.jmp_reg_flg   = inst_is_jalr;
assign id_ds_ctrl.imm_i_sext    = imm_i_sext;
assign id_ds_ctrl.imm_s_sext    = imm_s_sext;
assign id_ds_ctrl.imm_b_sext    = imm_b_sext;
assign id_ds_ctrl.imm_j_sext    = imm_j_sext;
assign id_ds_ctrl.imm_u_shifted = imm_u_shifted;
assign id_ds_ctrl.imm_z_uext    = imm_z_uext;

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,decodestage.valid,b,%b", id_valid);
    $display("data,decodestage.inst_id,h,%b", id_valid ? inst_id : INST_ID_NOP);
    if (id_valid) begin
        $display("data,decodestage.reg_pc,h,%b", reg_pc);
        $display("data,decodestage.inst,h,%b", inst);

        $display("data,decodestage.decode.i_exe,d,%b", i_exe);
        $display("data,decodestage.decode.br_exe,d,%b", br_exe);
        $display("data,decodestage.decode.m_exe,d,%b", m_exe);
        $display("data,decodestage.decode.op1_sel,d,%b", op1_sel);
        $display("data,decodestage.decode.op2_sel,d,%b", op2_sel);
        $display("data,decodestage.decode.mem_wen,d,%b", mem_wen);
        $display("data,decodestage.decode.rf_wen,d,%b", rf_wen);
        $display("data,decodestage.decode.wb_sel,d,%b", wb_sel);
        $display("data,decodestage.decode.wb_addr,d,%b", wb_addr);
        $display("data,decodestage.decode.csr_cmd,d,%b", csr_cmd);
        $display("data,decodestage.decode.jmp_pc,d,%b", id_ds_ctrl.jmp_pc_flg);
        $display("data,decodestage.decode.jmp_reg,d,%b", id_ds_ctrl.jmp_reg_flg);
        $display("data,decodestage.decode.imm_i,h,%b", imm_i_sext);
        $display("data,decodestage.decode.imm_s,h,%b", imm_s_sext);
        $display("data,decodestage.decode.imm_b,h,%b", imm_b_sext);
        $display("data,decodestage.decode.imm_j,h,%b", imm_j_sext);
        $display("data,decodestage.decode.imm_u,h,%b", imm_u_shifted);
        $display("data,decodestage.decode.imm_z,h,%b", imm_z_uext);
    end
end
`endif

endmodule