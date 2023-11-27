`ifndef PKG_STAGEINFO_SVH
`define PKG_STAGEINFO_SVH

package stageinfo;

import meminf::MemSize;

typedef enum logic [4:0] {
    ALU_X,
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_SLT,
    ALU_JALR,
    ALU_COPY1,

    ALU_MUL,
    ALU_MULH,
    ALU_MULHSU,
    ALU_DIV,
    ALU_REM,

    ALU_CZERO_EQ,
    ALU_CZERO_NE
} AluSel;

typedef enum logic [2:0] {
    BR_X,
    BR_BEQ,
    BR_BNE,
    BR_BLT,
    BR_BGE
} BrSel;

typedef enum logic [1:0] {
    OP1_X,
    OP1_RS1,
    OP1_PC,
    OP1_IMZ
} Op1Sel;

typedef enum logic [2:0] {
    OP2_X,
    OP2_RS2W,
    OP2_IMI,
    OP2_IMS,
    OP2_IMJ,
    OP2_IMU,
    OP2_IMZ
} Op2Sel;

typedef enum logic [1:0] {
    MEN_X,  // x
    MEN_S,  // store
    MEN_L,  // load
    MEN_A   // A-ext
} MemSel;

typedef enum logic {
    OP_UNSIGNED,
    OP_SIGNED
} SignSel;

typedef enum logic [1:0] {
    WB_ALU,
    WB_MEM,
    WB_PC,
    WB_CSR
} WbSel;

typedef enum logic [2:0] {
    CSR_X,
    CSR_W,
    CSR_S,
    CSR_C,
    CSR_ECALL,
    CSR_EBREAK,
    CSR_SRET,
    CSR_MRET
} CsrCmd;

typedef enum logic [3:0] {
    ASEL_X,
    ASEL_LR,
    ASEL_SC,
    ASEL_AMO_SWAP,
    ASEL_AMO_ADD,
    ASEL_AMO_XOR,
    ASEL_AMO_AND,
    ASEL_AMO_OR,
    ASEL_AMO_MAX,
    ASEL_AMO_MIN
} AextSel;

typedef enum logic [4:0] {
    REG_ZERO= 5'd0,
    REG_RA  = 5'd1,
    REG_SP  = 5'd2,
    REG_GP  = 5'd3,
    REG_TP  = 5'd4,
    REG_T0  = 5'd5,
    REG_T1  = 5'd6,
    REG_T2  = 5'd7,
    REG_S0  = 5'd8,
    REG_S1  = 5'd9,
    REG_A0  = 5'd10,
    REG_A1  = 5'd11,
    REG_A2  = 5'd12,
    REG_A3  = 5'd13,
    REG_A4  = 5'd14,
    REG_A5  = 5'd15,
    REG_A6  = 5'd16,
    REG_A7  = 5'd17,
    REG_S2  = 5'd18,
    REG_S3  = 5'd19,
    REG_S4  = 5'd20,
    REG_S5  = 5'd21,
    REG_S6  = 5'd22,
    REG_S7  = 5'd23,
    REG_S8  = 5'd24,
    REG_S9  = 5'd25,
    REG_S10 = 5'd26,
    REG_S11 = 5'd27,
    REG_T3  = 5'd28,
    REG_T4  = 5'd29,
    REG_T5  = 5'd30,
    REG_T6  = 5'd31
} RegSel;

typedef struct packed {
    basic::Addr pc;
    basic::Inst inst;
`ifdef PRINT_DEBUGINFO
    iid::Ty     id;
`endif
} StageInfo;

typedef struct packed 
{
    AluSel  i_exe;
    BrSel   br_exe;
    SignSel sign_sel;
    Op1Sel  op1_sel;
    Op2Sel  op2_sel;
    MemSel  mem_sel;
    MemSize mem_size;
    logic   rf_wen;
    WbSel   wb_sel;
    RegSel  wb_addr;
    CsrCmd  csr_cmd;
    logic   jmp_pc_flg;
    logic   jmp_reg_flg;
    logic   fence_i;
    logic   sfence;
    logic   svinval;
    logic   wfi;
    AextSel a_sel;
} Ctrl;

typedef struct packed
{
    logic           valid;
    logic           fwdable;
    RegSel          addr;
    basic::UIntX    wdata;
} FwCtrl;

typedef struct packed {
    logic           valid;
    basic::UIntX    cause;
} TrapInfo;

endpackage

`endif