module DecodeStage
(
    input  wire       clk,

    input  wire       wb_branch_hazard,

    input  reg [31:0] input_inst,
    input  reg [31:0] input_reg_pc,
    input  reg [31:0] regfile[31:0],

    // 即値
    output reg [31:0] output_reg_pc,
    output reg [31:0] imm_i_sext,
    output reg [31:0] imm_s_sext,
    output reg [31:0] imm_b_sext,
    output reg [31:0] imm_j_sext,
    output reg [31:0] imm_u_shifted,
    output reg [31:0] imm_z_uext,

    // csignals
    output reg [4:0]  exe_fun,  // ALUの計算の種類
    output reg [31:0] op1_data, // ALU
    output reg [31:0] op2_data, // ALU
    output reg [31:0] rs2_data, // rs2で指定されたレジスタの値
    output reg [4:0]  mem_wen,  // メモリに書き込むか否か
    output reg [0:0]  rf_wen,   // レジスタに書き込むか否か
    output reg [3:0]  wb_sel,   // ライトバック先
    output reg [4:0]  wb_addr,  // ライトバック先レジスタ番号
    output reg [2:0]  csr_cmd,  // CSR
    output reg        jmp_flg,  // ジャンプ命令かのフラグ
    output reg        output_inst_is_ecall, // ecallかどうか

    input  wire       stall_flg
);

`include "include/core.v"
`include "include/inst.v"

initial begin
    exe_fun                 <= 0;
    op1_data                <= 0;
    op2_data                <= 0;
    rs2_data                <= 0;
    mem_wen                 <= 0;
    rf_wen                  <= 0;
    wb_sel                  <= 0;
    wb_addr                 <= 0;
    csr_cmd                 <= 0;
    jmp_flg                 <= 0;
    output_inst_is_ecall    <= 0;
end

reg  [31:0] save_inst   = INST_NOP;
reg  [31:0] save_reg_pc = REGPC_NOP;

wire [31:0] inst = (
    wb_branch_hazard ? INST_NOP :
    stall_flg ? save_inst : input_inst
);

wire [31:0] reg_pc = (
    wb_branch_hazard ? REGPC_NOP :
    stall_flg ? save_reg_pc : input_reg_pc
); 

wire [11:0] wire_imm_i = inst[31:20];
wire [11:0] wire_imm_s = {inst[31:25], inst[11:7]};
wire [11:0] wire_imm_b = {inst[31], inst[7], inst[30:25], inst[11:8]};
wire [19:0] wire_imm_j = {inst[31], inst[19:12], inst[20], inst[30:21]};
wire [19:0] wire_imm_u = inst[31:12];
wire [4:0]  wire_imm_z = inst[19:15];


wire [31:0] wire_imm_i_sext    = {{20{wire_imm_i[11]}}, wire_imm_i};
wire [31:0] wire_imm_s_sext    = {{20{wire_imm_s[11]}}, wire_imm_s};
wire [31:0] wire_imm_b_sext    = {{19{wire_imm_b[11]}}, wire_imm_b, 1'b0};
wire [31:0] wire_imm_j_sext    = {{11{wire_imm_j[19]}}, wire_imm_j, 1'b0};
wire [31:0] wire_imm_u_shifted = {wire_imm_u, 12'b0};
wire [31:0] wire_imm_z_uext    = {27'd0, wire_imm_z};

wire [2:0] funct3 = inst[14:12];
wire [7:0] funct7 = inst[31:25];
wire [6:0] opcode = inst[6:0];

wire inst_is_ecall  = inst == INST_ECALL;
wire inst_is_jal    = (opcode == INST_JAL_OPCODE);
wire inst_is_jalr   = (funct3 == INST_JALR_FUNCT3 && opcode == INST_JALR_OPCODE);

function [5 + 4 + 4 + 5 + 1 + 4 + 3 - 1:0] decode(inst);
    casex (inst)
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
        INST_ECALL                                                                                : decode = {ALU_X    , OP1_X  , OP2_X   , MEN_X , REN_X, WB_X    , CSR_E};
        default                                                                                   : decode = {ALU_ADD  , OP1_RS1, OP2_RS2W, MEN_X , REN_X, WB_X    , CSR_X};
    endcase
endfunction

wire [4:0] wire_exe_fun;
wire [3:0] wire_op1_sel;
wire [3:0] wire_op2_sel;
wire [4:0] wire_mem_wen;
wire [0:0] wire_rf_wen;
wire [3:0] wire_wb_sel;
wire [2:0] wire_csr_cmd;
assign {wire_exe_fun, wire_op1_sel, wire_op2_sel, wire_mem_wen, wire_rf_wen, wire_wb_sel, wire_csr_cmd} = decode(inst);

wire [4:0] wire_rs1_addr = inst[19:15];
wire [4:0] wire_rs2_addr = inst[24:20];
wire [4:0] wire_wb_addr  = inst[11:7];

always @(posedge clk) begin
    imm_i_sext      <= wire_imm_i_sext;
    imm_s_sext      <= wire_imm_s_sext;
    imm_b_sext      <= wire_imm_b_sext;
    imm_j_sext      <= wire_imm_j_sext;
    imm_u_shifted   <= wire_imm_u_shifted;
    imm_z_uext      <= wire_imm_z_uext;

    op1_data <= (
        wire_op1_sel == OP1_RS1 ? (wire_rs1_addr == 0) ? 0 : regfile[wire_rs1_addr] :
        wire_op1_sel == OP1_PC  ? reg_pc :
        wire_op1_sel == OP1_IMZ ? wire_imm_z_uext :
        0
    );

    op2_data <= (
        wire_op2_sel == OP2_RS2W ? (wire_rs2_addr == 0) ? 0 : regfile[wire_rs2_addr] :
        wire_op2_sel == OP2_IMI  ? wire_imm_i_sext :
        wire_op2_sel == OP2_IMS  ? wire_imm_s_sext :
        wire_op2_sel == OP2_IMJ  ? wire_imm_j_sext :
        wire_op2_sel == OP2_IMU  ? wire_imm_u_shifted :
        0
    );

    rs2_data                <= (wire_rs2_addr == 0) ? 0 : regfile[wire_rs2_addr];
    jmp_flg                 <= inst_is_jal || inst_is_jalr;
    output_inst_is_ecall    <= inst_is_ecall;

    output_reg_pc   <= reg_pc;
    exe_fun         <= wire_exe_fun;
    mem_wen         <= wire_mem_wen;
    rf_wen          <= wire_rf_wen;
    wb_sel          <= wire_wb_sel;
    wb_addr         <= wire_wb_addr;
    csr_cmd         <= wire_csr_cmd;

    // save
    save_inst   <= wb_branch_hazard ? INST_NOP  : inst;
    save_reg_pc <= wb_branch_hazard ? REGPC_NOP : reg_pc;
end

always @(posedge clk) begin
    $display("DECODE STAGE-------------");
    $display("reg_pc    : 0x%H", reg_pc);
    $display("inst      : 0x%H", inst);
    $display("rs1_addr  : %d", wire_rs1_addr);
    $display("rs2_addr  : %d", wire_rs2_addr);
    $display("wb_addr   : %d", wire_wb_addr);
    $display("op1_data  : 0x%H", (
        wire_op1_sel == OP1_RS1 ? (wire_rs1_addr == 0) ? 0 : regfile[wire_rs1_addr] :
        wire_op1_sel == OP1_PC  ? reg_pc :
        wire_op1_sel == OP1_IMZ ? wire_imm_z_uext :
        0
    ));
    $display("op2_data  : 0x%H", (
        wire_op2_sel == OP2_RS2W ? (wire_rs2_addr == 0) ? 0 : regfile[wire_rs2_addr] :
        wire_op2_sel == OP2_IMI  ? wire_imm_i_sext :
        wire_op2_sel == OP2_IMS  ? wire_imm_s_sext :
        wire_op2_sel == OP2_IMJ  ? wire_imm_j_sext :
        wire_op2_sel == OP2_IMU  ? wire_imm_u_shifted :
        0
    ));
    $display("w.exe_fun : %d", wire_exe_fun);
    $display("w.op1_sel : %d", wire_op1_sel);
    $display("w.op2_sel : %d", wire_op2_sel);
    $display("w.mem_wen : %d", wire_mem_wen);
    $display("w.rf_wen  : %d", wire_rf_wen);
    $display("w.wb_sel  : %d", wire_wb_sel);
    $display("w.csr_cmd : %d", wire_csr_cmd);
end

endmodule