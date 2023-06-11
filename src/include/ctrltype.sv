`ifndef CTRLTYPE_SV
`define CTRLTYPE_SV

typedef enum reg [3:0] {
    ALUI_X,
    ALUI_ADD,
    ALUI_SUB,
    ALUI_AND,
    ALUI_OR,
    ALUI_XOR,
    ALUI_SLL,
    ALUI_SRL,
    ALUI_SRA,
    ALUI_SLT,
    ALUI_SLTU,
    ALUI_JALR,
    ALUI_COPY1
} alui_exe_type;

typedef enum reg [2:0] {
    BR_X,
    BR_BEQ,
    BR_BNE,
    BR_BLT,
    BR_BGE,
    BR_BLTU,
    BR_BGEU
} br_exe_type;

typedef enum reg [3:0] {
    ALUM_X,
    ALUM_MUL,
    ALUM_MULH,
    ALUM_MULHSU,
    ALUM_MULHU,
    ALUM_DIV,
    ALUM_DIVU,
    ALUM_REM,
    ALUM_REMU
} alum_exe_type;

typedef enum reg [1:0] {
    // WB_X    = 2'd0,
    WB_ALU  = 2'd0,
    WB_MEM  = 2'd1,
    WB_PC   = 2'd2,
    WB_CSR  = 2'd3
} wb_sel_type;

typedef enum reg [1:0] {
    MEN_X,  // x
    MEN_S,  // store
    MEN_LS, // load signed
    MEN_LU  // load unsigned
} men_type_type;

typedef enum reg [1:0] {
    // MENS_X  = 2'd0, // x
    MENS_W  = 2'd0, // word
    MENS_H  = 2'd1, // half word
    MENS_B  = 2'd2  // byte
} men_size_type;

typedef struct packed 
{
    alui_exe_type   i_exe; // 整数演算
    br_exe_type     br_exe;// 分岐計算
    alum_exe_type   m_exe; // M拡張計算
    reg [3:0]   op1_sel;
    reg [3:0]   op2_sel;
    reg [31:0]  op1_data;
    reg [31:0]  op2_data;
    reg [31:0]  rs2_data;
    men_type_type   mem_wen;
    men_size_type   mem_size;
    reg         rf_wen;
    wb_sel_type     wb_sel;
    reg [4:0]   wb_addr;
    reg [2:0]   csr_cmd;
    reg         jmp_pc_flg;
    reg         jmp_reg_flg;
    reg [31:0]  imm_i_sext;
    reg [31:0]  imm_s_sext;
    reg [31:0]  imm_b_sext;
    reg [31:0]  imm_j_sext;
    reg [31:0]  imm_u_shifted;
    reg [31:0]  imm_z_uext;
} ctrltype;

typedef struct packed
{
    reg         valid;
    reg         can_forward;
    reg [4:0]   addr;
    reg [31:0]  wdata;
} fw_ctrltype;
`endif