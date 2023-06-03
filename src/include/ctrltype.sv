`ifndef CTRLTYPE_SV
`define CTRLTYPE_SV
typedef struct packed 
{
    reg [4:0]   exe_fun;
    reg [31:0]  op1_data;
    reg [31:0]  op2_data;
    reg [31:0]  rs2_data;
    reg [3:0]   mem_wen;
    reg         rf_wen;
    reg [3:0]   wb_sel;
    reg [4:0]   wb_addr;
    reg [2:0]   csr_cmd;
    reg         br_flg;
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