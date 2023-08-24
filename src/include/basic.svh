`ifndef BASIC_SVH
`define BASIC_SVH

// `define XLEN 64
// `define XLEN64
`define XLEN 32
`define XLEN32

`define IALIGN 32
`define ILEN 32

`ifdef DEBUG
    `define IID_LEN 64
`else
    `define IID_LEN 8
`endif


typedef logic [`ILEN-1:0] Inst;
typedef logic [`XLEN-1:0] InstPc;
typedef logic [`XLEN-1:0] UIntX;

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
    ALU_SLTU,
    ALU_JALR,
    ALU_COPY1,

    ALU_MUL,
    ALU_MULH,
    ALU_MULHSU,
    ALU_MULHU,
    ALU_DIV,
    ALU_DIVU,
    ALU_REM,
    ALU_REMU,

    ALU_CZERO_EQ,
    ALU_CZERO_NE
} AluSel;

typedef enum logic [2:0] {
    BR_X,
    BR_BEQ,
    BR_BNE,
    BR_BLT,
    BR_BGE,
    BR_BLTU,
    BR_BGEU
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
    MEN_LS, // load signed
    MEN_LU  // load unsigned
} MemSel;

typedef enum logic [1:0] {
    SIZE_B = 2'b00,
    SIZE_H = 2'b01,
    SIZE_W = 2'b10,
    SIZE_D = 2'b11
} MemSize;

typedef enum logic {
    REN_X   = 1'b0,
    REN_S   = 1'b1
} RwenSel;

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
    CSR_SRET, 
    CSR_MRET 
} CsrCmd;

typedef struct packed 
{
    AluSel      i_exe;
    BrSel       br_exe;
    Op1Sel      op1_sel;
    Op2Sel      op2_sel;
    MemSel      mem_wen;
    MemSize     mem_size;
    RwenSel     rf_wen;
    WbSel       wb_sel;
    logic [4:0] wb_addr;
    CsrCmd      csr_cmd;
    logic       jmp_pc_flg;
    logic       jmp_reg_flg;
    logic       svinval;
} Ctrl;

typedef struct packed
{
    logic        valid;
    logic        can_forward;
    logic [4:0]  addr;
    UIntX       wdata;
} FwCtrl;

`define IID_LEN 64
typedef struct packed {
    logic [`IID_LEN-1:0] id;
} IId;

typedef enum logic [1:0] {
    M_MODE = 2'b11, // Machine Mode
    H_MODE = 2'b10, // Hypervisor Mode
    S_MODE = 2'b01, // Supervisor Mode
    U_MODE = 2'b00  // User Mode
} modetype;

`endif