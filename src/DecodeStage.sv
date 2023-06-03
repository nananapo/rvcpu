/* verilator lint_off CASEX */

// TODO フォワーディングの有無でkanataを比較するとちょっと面白いので、フォワーディングするかどうかを設定できるといいかも
// フォワーディングがない実装は 4d5c53dd5ed32025d7428d088e6bbc968dafdc4d 以前を参照
module DecodeStage
(
    input wire          clk,

    input wire[31:0]    regfile[31:0],

    input wire          id_valid,
    input wire[31:0]    id_reg_pc,
    input wire[31:0]    id_inst,
    input wire[63:0]    id_inst_id, 
    
    output wire             id_exe_valid,
    output wire [31:0]      id_exe_reg_pc,
    output wire [31:0]      id_exe_inst,
    output wire [63:0]      id_exe_inst_id,
    output wire ctrltype    id_exe_ctrl,

    output wire             dh_stall_flg,
    input wire fw_ctrltype  dh_exe_fw,
    input wire fw_ctrltype  dh_mem_fw,
    input wire fw_ctrltype  dh_wb_fw,

    output wire         zifencei_stall_flg,
    input wire          zifencei_mem_wen
);

`include "include/core.sv"
`include "include/inst.sv"

wire [31:0] reg_pc  = id_reg_pc;
wire [31:0] inst    = id_inst;
wire [63:0] inst_id = id_inst_id;

function [5 + 4 + 4 + 4 + 1 + 4 + 3 - 1:0] decode(input [31:0] inst);
    casex (inst)
        // RV32I
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LB_FUNCT3    , 5'bxxxxx, INST_LB_OPCODE      } : decode = {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LB, REN_S, WB_MEMB , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LBU_FUNCT3   , 5'bxxxxx, INST_LBU_OPCODE     } : decode = {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LBU,REN_S, WB_MEMBU, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LH_FUNCT3    , 5'bxxxxx, INST_LH_OPCODE      } : decode = {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LH, REN_S, WB_MEMH , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LHU_FUNCT3   , 5'bxxxxx, INST_LHU_OPCODE     } : decode = {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LHU,REN_S, WB_MEMHU, CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_LW_FUNCT3    , 5'bxxxxx, INST_LW_OPCODE      } : decode = {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_LW, REN_S, WB_MEMW , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SB_FUNCT3    , 5'bxxxxx, INST_SB_OPCODE      } : decode = {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_SB, REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SH_FUNCT3    , 5'bxxxxx, INST_SH_OPCODE      } : decode = {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_SH, REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SW_FUNCT3    , 5'bxxxxx, INST_SW_OPCODE      } : decode = {ALU_ADD  , OP1_RS1, OP2_IMS , MEN_SW, REN_X, WB_X    , CSR_X};
        {INST_ADD_FUNCT7    , 10'bxxxxxxxxxx, INST_ADD_FUNCT3   , 5'bxxxxx, INST_ADD_OPCODE     } : decode = {ALU_ADD  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_ADDI_FUNCT3  , 5'bxxxxx, INST_ADDI_OPCODE    } : decode = {ALU_ADD  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SUB_FUNCT7    , 10'bxxxxxxxxxx, INST_SUB_FUNCT3   , 5'bxxxxx, INST_SUB_OPCODE     } : decode = {ALU_SUB  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_AND_FUNCT7    , 10'bxxxxxxxxxx, INST_AND_FUNCT3   , 5'bxxxxx, INST_AND_OPCODE     } : decode = {ALU_AND  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_OR_FUNCT7     , 10'bxxxxxxxxxx, INST_OR_FUNCT3    , 5'bxxxxx, INST_OR_OPCODE      } : decode = {ALU_OR   , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_XOR_FUNCT7    , 10'bxxxxxxxxxx, INST_XOR_FUNCT3   , 5'bxxxxx, INST_XOR_OPCODE     } : decode = {ALU_XOR  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_ANDI_FUNCT3  , 5'bxxxxx, INST_ANDI_OPCODE    } : decode = {ALU_AND  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_ORI_FUNCT3   , 5'bxxxxx, INST_ORI_OPCODE     } : decode = {ALU_OR   , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_XORI_FUNCT3  , 5'bxxxxx, INST_XORI_OPCODE    } : decode = {ALU_XOR  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLL_FUNCT7    , 10'bxxxxxxxxxx, INST_SLL_FUNCT3   , 5'bxxxxx, INST_SLL_OPCODE     } : decode = {ALU_SLL  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRL_FUNCT7    , 10'bxxxxxxxxxx, INST_SRL_FUNCT3   , 5'bxxxxx, INST_SRL_OPCODE     } : decode = {ALU_SRL  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRA_FUNCT7    , 10'bxxxxxxxxxx, INST_SRA_FUNCT3   , 5'bxxxxx, INST_SRA_OPCODE     } : decode = {ALU_SRA  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLLI_FUNCT7   , 10'bxxxxxxxxxx, INST_SLLI_FUNCT3  , 5'bxxxxx, INST_SLLI_OPCODE    } : decode = {ALU_SLL  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRLI_FUNCT7   , 10'bxxxxxxxxxx, INST_SRLI_FUNCT3  , 5'bxxxxx, INST_SRLI_OPCODE    } : decode = {ALU_SRL  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SRAI_FUNCT7   , 10'bxxxxxxxxxx, INST_SRAI_FUNCT3  , 5'bxxxxx, INST_SRAI_OPCODE    } : decode = {ALU_SRA  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLT_FUNCT7    , 10'bxxxxxxxxxx, INST_SLT_FUNCT3   , 5'bxxxxx, INST_SLT_OPCODE     } : decode = {ALU_SLT  , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {INST_SLTU_FUNCT7   , 10'bxxxxxxxxxx, INST_SLTU_FUNCT3  , 5'bxxxxx, INST_SLTU_OPCODE    } : decode = {ALU_SLTU , OP1_RS1, OP2_RS2W, MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SLTI_FUNCT3  , 5'bxxxxx, INST_SLTI_OPCODE    } : decode = {ALU_SLT  , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_SLTIU_FUNCT3 , 5'bxxxxx, INST_SLTIU_OPCODE   } : decode = {ALU_SLTU , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BEQ_FUNCT3   , 5'bxxxxx, INST_BEQ_OPCODE     } : decode = {BR_BEQ   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BNE_FUNCT3   , 5'bxxxxx, INST_BNE_OPCODE     } : decode = {BR_BNE   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BLT_FUNCT3   , 5'bxxxxx, INST_BLT_OPCODE     } : decode = {BR_BLT   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BGE_FUNCT3   , 5'bxxxxx, INST_BGE_OPCODE     } : decode = {BR_BGE   , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BLTU_FUNCT3  , 5'bxxxxx, INST_BLTU_OPCODE    } : decode = {BR_BLTU  , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_BGEU_FUNCT3  , 5'bxxxxx, INST_BGEU_OPCODE    } : decode = {BR_BGEU  , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_JAL_OPCODE     } : decode = {ALU_ADD  , OP1_PC , OP2_IMJ , MEN_X , REN_S, WB_PC   , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_JALR_FUNCT3  , 5'bxxxxx, INST_JALR_OPCODE    } : decode = {ALU_JALR , OP1_RS1, OP2_IMI , MEN_X , REN_S, WB_PC   , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_LUI_OPCODE     } : decode = {ALU_ADD  , OP1_X  , OP2_IMU , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, 3'bxxx            , 5'bxxxxx, INST_AUIPC_OPCODE   } : decode = {ALU_ADD  , OP1_PC , OP2_IMU , MEN_X , REN_S, WB_ALU  , CSR_X};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRW_FUNCT3 , 5'bxxxxx, INST_CSRRW_OPCODE   } : decode = {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_W};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRWI_FUNCT3, 5'bxxxxx, INST_CSRRWI_OPCODE  } : decode = {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_W};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRS_FUNCT3 , 5'bxxxxx, INST_CSRRS_OPCODE   } : decode = {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_S};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRSI_FUNCT3, 5'bxxxxx, INST_CSRRSI_OPCODE  } : decode = {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_S};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRC_FUNCT3 , 5'bxxxxx, INST_CSRRC_OPCODE   } : decode = {ALU_COPY1, OP1_RS1, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_C};
        {7'bxxxxxxx         , 10'bxxxxxxxxxx, INST_CSRRCI_FUNCT3, 5'bxxxxx, INST_CSRRCI_OPCODE  } : decode = {ALU_COPY1, OP1_IMZ, OP2_X   , MEN_X , REN_S, WB_CSR  , CSR_C};
        INST_ECALL                                                                                : decode = {ALU_X    , OP1_X  , OP2_X   , MEN_X , REN_X, WB_X    , CSR_ECALL};
        INST_SRET                                                                                 : decode = {ALU_X    , OP1_X  , OP2_X   , MEN_X , REN_X, WB_X    , CSR_SRET};
        INST_MRET                                                                                 : decode = {ALU_X    , OP1_X  , OP2_X   , MEN_X , REN_X, WB_X    , CSR_MRET};

`ifndef EXCLUDE_RV32M
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MUL_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_MUL      , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULH_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_MULH     , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULHSU_FUNCT3, 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_MULHSU   , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_MULHU_FUNCT3 , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_MULHU    , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_DIV_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_DIV      , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_DIVU_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_DIVU     , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_REM_FUNCT3   , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_REM      , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
        {INST_RV32M_FUNCT7, 10'bxxxxxxxxxx, INST_RV32M_REMU_FUNCT3  , 5'bxxxxx, INST_RV32M_OPCODE} : decode = {ALU_REMU     , OP1_RS1, OP2_RS2W, MEN_X, REN_S, WB_ALU, CSR_X};
`endif

`ifndef EXCLUDE_RV32A
        {INST_RV32A_AMOSWAP_W_FUNCT5, 2'bxx, 10'bxxxxxxxxxx, INST_RV32A_AMOSWAP_W_FUNCT3, 5'bxxxxx, INST_RV32A_OPCODE} :
            decode = {ALU_COPY1, OP1_RS1, OP2_X, MEN_AMOSWAP_W_AQRL, REN_S, WB_MEMW, CSR_X};
`endif

        // default : nop
        default : 
            decode = {ALU_ADD, OP1_X, OP2_X, MEN_X, REN_X, WB_X, CSR_X};
    endcase
endfunction

wire [4:0] exe_fun;
wire [3:0] op1_sel;
wire [3:0] op2_sel;
wire [3:0] mem_wen;
wire [0:0] rf_wen;
wire [3:0] wb_sel;
wire [2:0] csr_cmd;
assign {exe_fun, op1_sel, op2_sel, mem_wen, rf_wen, wb_sel, csr_cmd} = decode(inst);

wire [4:0] rs1_addr         = inst[19:15];
wire [4:0] rs2_addr         = inst[24:20];
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
// Zifencei
wire inst_is_fence_i        = funct3 == INST_ZIFENCEI_FENCEI_FUNCT3 && opcode == INST_ZIFENCEI_FENCEI_OPCODE;

// fence.iのストール判定
// fence.i命令かつ、EXEかMEMステージがmem_wenならストールする
// TODO これでは書き込みが保証されない
assign zifencei_stall_flg   = id_valid && inst_is_fence_i && zifencei_mem_wen;

// データハザード判定
wire dh_exe_rs1 = dh_exe_fw.valid && dh_exe_fw.addr == rs1_addr && rs1_addr != 0;
wire dh_exe_rs2 = dh_exe_fw.valid && dh_exe_fw.addr == rs2_addr && rs2_addr != 0;
wire dh_mem_rs1 = dh_mem_fw.valid && dh_mem_fw.addr == rs1_addr && rs1_addr != 0;
wire dh_mem_rs2 = dh_mem_fw.valid && dh_mem_fw.addr == rs2_addr && rs2_addr != 0;
wire dh_wb_rs1  = dh_wb_fw.valid  && dh_wb_fw.addr  == rs1_addr && rs1_addr != 0;
wire dh_wb_rs2  = dh_wb_fw.valid  && dh_wb_fw.addr  == rs2_addr && rs2_addr != 0;

assign dh_stall_flg = id_valid && (
    // dh_*_rs*ですでにチェックしているため冗長だが、わかりやすさのために残してもいいと考えている
    (/*dh_exe_fw.valid && */!dh_exe_fw.can_forward && (dh_exe_rs1 || dh_exe_rs2)) ||
    (/*dh_mem_fw.valid && */!dh_mem_fw.can_forward && (dh_mem_rs1 || dh_mem_rs2)) ||
    (/*dh_wb_fw.valid  && */!dh_wb_fw.can_forward  && (dh_wb_rs1  || dh_wb_rs2 ))
    );

function [31:0] gen_op1data(
    input [3:0]     op1_sel,
    input [31:0]    reg_pc,
    input [31:0]    imm_z_uext
);
case(op1_sel) 
    OP1_PC  : gen_op1data = reg_pc;
    OP1_IMZ : gen_op1data = imm_z_uext;
    default : gen_op1data = 0;
endcase
endfunction

function [31:0] gen_op2data(
    input [3:0]     op2_sel,
    input [4:0]     rs2_addr,
    input [31:0]    imm_i_sext,
    input [31:0]    imm_s_sext,
    input [31:0]    imm_j_sext,
    input [31:0]    imm_u_shifted
);
case(op2_sel) 
    OP2_IMI : gen_op2data = imm_i_sext;
    OP2_IMS : gen_op2data = imm_s_sext;
    OP2_IMJ : gen_op2data = imm_j_sext;
    OP2_IMU : gen_op2data = imm_u_shifted;
    default : gen_op2data = 0;
endcase
endfunction

wire [31:0] rs2_data = rs2_addr == 0 ? 0 : 
                // exeは常にフォワーディングできないので考えないでおく
                //dh_exe_rs2 ? dh_exe_fw.wdata :
                dh_mem_rs2 ? dh_mem_fw.wdata : 
                dh_wb_rs2  ? dh_wb_fw.wdata : regfile[rs2_addr];
wire [31:0] rs1_data = rs1_addr == 0 ? 0 :
                // exeは常にフォワーディングできないので考えないでおく
                //dh_exe_rs1 ? dh_exe_fw.wdata :
                dh_mem_rs1 ? dh_mem_fw.wdata : 
                dh_wb_rs1  ? dh_wb_fw.wdata : regfile[rs1_addr];

assign id_exe_valid             = !dh_stall_flg &&
                                  !zifencei_stall_flg &&
                                  id_valid;
assign id_exe_reg_pc            = reg_pc;
assign id_exe_inst              = inst;
assign id_exe_inst_id           = inst_id;

assign id_exe_ctrl.exe_fun      = exe_fun;
assign id_exe_ctrl.op1_data     = op1_sel == OP1_RS1 ? rs1_data :
                                    gen_op1data(op1_sel,reg_pc,imm_z_uext);
assign id_exe_ctrl.op2_data     = op2_sel == OP2_RS2W ? rs2_data :
                                    gen_op2data(op2_sel,rs2_addr,imm_i_sext,imm_s_sext,imm_j_sext,imm_u_shifted);
assign id_exe_ctrl.rs2_data     = rs2_data;
assign id_exe_ctrl.mem_wen      = mem_wen;
assign id_exe_ctrl.rf_wen       = rf_wen;
assign id_exe_ctrl.wb_sel       = wb_sel;
assign id_exe_ctrl.wb_addr      = wb_addr;
assign id_exe_ctrl.csr_cmd      = csr_cmd;
assign id_exe_ctrl.jmp_pc_flg   = inst_is_jal;
assign id_exe_ctrl.jmp_reg_flg  = inst_is_jalr;
assign id_exe_ctrl.imm_i_sext   = imm_i_sext;
assign id_exe_ctrl.imm_s_sext   = imm_s_sext;
assign id_exe_ctrl.imm_b_sext   = imm_b_sext;
assign id_exe_ctrl.imm_j_sext   = imm_j_sext;
assign id_exe_ctrl.imm_u_shifted= imm_u_shifted;
assign id_exe_ctrl.imm_z_uext   = imm_z_uext;

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,decodestage.valid,b,%b", id_valid);
    $display("data,decodestage.inst_id,h,%b", id_valid ? inst_id : INST_ID_NOP);
    if (id_valid) begin
        $display("data,decodestage.reg_pc,h,%b", reg_pc);
        $display("data,decodestage.inst,h,%b", inst);

        $display("data,decodestage.decode.exe_fun,d,%b", exe_fun);
        $display("data,decodestage.decode.op1_sel,d,%b", op1_sel);
        $display("data,decodestage.decode.op2_sel,d,%b", op2_sel);
        $display("data,decodestage.decode.op1_data,h,%b", id_exe_ctrl.op1_data);
        $display("data,decodestage.decode.op2_data,h,%b", id_exe_ctrl.op2_data);
        $display("data,decodestage.decode.rs1_addr,d,%b", rs1_addr);
        $display("data,decodestage.decode.rs2_addr,d,%b", rs2_addr);
        $display("data,decodestage.decode.rs1_data,h,%b", rs1_data);
        $display("data,decodestage.decode.rs2_data,h,%b", rs2_data);
        $display("data,decodestage.decode.mem_wen,d,%b", mem_wen);
        $display("data,decodestage.decode.rf_wen,d,%b", rf_wen);
        $display("data,decodestage.decode.wb_sel,d,%b", wb_sel);
        $display("data,decodestage.decode.wb_addr,d,%b", wb_addr);
        $display("data,decodestage.decode.csr_cmd,d,%b", csr_cmd);
        $display("data,decodestage.decode.jmp_pc,d,%b", id_exe_ctrl.jmp_pc_flg);
        $display("data,decodestage.decode.jmp_reg,d,%b", id_exe_ctrl.jmp_reg_flg);
        $display("data,decodestage.decode.imm_i,h,%b", imm_i_sext);
        $display("data,decodestage.decode.imm_s,h,%b", imm_s_sext);
        $display("data,decodestage.decode.imm_b,h,%b", imm_b_sext);
        $display("data,decodestage.decode.imm_j,h,%b", imm_j_sext);
        $display("data,decodestage.decode.imm_u,h,%b", imm_u_shifted);
        $display("data,decodestage.decode.imm_z,h,%b", imm_z_uext);

        $display("data,decodestage.decode.is_fence_i,b,%b", inst_is_fence_i);
        
        $display("data,decodestage.datahazard,b,%b", dh_stall_flg);
        $display("data,decodestage.fence_i_stall,b,%b", zifencei_stall_flg);
    end
end
`endif

endmodule