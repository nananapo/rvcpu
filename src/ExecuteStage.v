module ExecuteStage
(
    input wire clk,

    input  wire      wb_branch_hazard,

    input wire[31:0] input_reg_pc,
    input wire[4:0]  input_exe_fun,
    input wire[31:0] input_op1_data,
    input wire[31:0] input_op2_data,
    input wire[31:0] input_rs2_data,
    input wire[3:0]  input_mem_wen,
    input wire       input_rf_wen,
    input wire[3:0]  input_wb_sel,
    input wire[4:0]  input_wb_addr,
    input wire[2:0]  input_csr_cmd,
    input wire       input_jmp_flg,
    input wire[31:0] input_imm_i_sext,
    input wire[31:0] input_imm_b_sext,

    output reg [31:0] alu_out,
    output reg        br_flg,
    output reg [31:0] br_target,
    
    output reg [31:0] output_reg_pc,
    output reg [3:0]  output_mem_wen,
    output reg        output_rf_wen,
    output reg [31:0] output_rs2_data,
    output reg [31:0] output_op1_data,
    output reg [3:0]  output_wb_sel,
    output reg [4:0]  output_wb_addr,
    output reg [2:0]  output_csr_cmd,
    output reg        output_jmp_flg,
    output reg [31:0] output_imm_i,
    
    input  wire       stall_flg,
    output wire       output_stall_flg
);

`include "include/core.v"

initial begin
    alu_out                 = 0;
    br_flg                  = 0;
    br_target               = 0;
    output_reg_pc           = 0;
    output_mem_wen          = 0;
    output_rf_wen           = 0;
    output_rs2_data         = 0;
    output_op1_data         = 0;
    output_wb_sel           = 0;
    output_wb_addr          = 0;
    output_csr_cmd          = 0;
    output_jmp_flg          = 0;
    output_imm_i            = 0;
end

reg [31:0] save_reg_pc          = 0;    
reg [4:0]  save_exe_fun         = 0;    
reg [31:0] save_op1_data        = 0;
reg [31:0] save_op2_data        = 0;
reg [31:0] save_rs2_data        = 0;
reg [3:0]  save_mem_wen         = 0;    
reg        save_rf_wen          = 0;
reg [3:0]  save_wb_sel          = 0;    
reg [4:0]  save_wb_addr         = 0;    
reg [2:0]  save_csr_cmd         = 0;
reg        save_jmp_flg         = 0;    
reg [31:0] save_imm_i_sext      = 0;
reg [31:0] save_imm_b_sext      = 0;

wire [31:0] reg_pc          = stall_flg ? save_reg_pc : input_reg_pc;
wire [4:0]  exe_fun         = stall_flg ? save_exe_fun : input_exe_fun;
wire [31:0] op1_data        = stall_flg ? save_op1_data : input_op1_data;
wire [31:0] op2_data        = stall_flg ? save_op2_data : input_op2_data;
wire [31:0] rs2_data        = stall_flg ? save_rs2_data : input_rs2_data;
wire [3:0]  mem_wen         = stall_flg ? save_mem_wen : input_mem_wen;
wire        rf_wen          = stall_flg ? save_rf_wen : input_rf_wen;
wire [3:0]  wb_sel          = stall_flg ? save_wb_sel : input_wb_sel;
wire [4:0]  wb_addr         = stall_flg ? save_wb_addr : input_wb_addr;
wire [2:0]  csr_cmd         = stall_flg ? save_csr_cmd : input_csr_cmd;
wire        jmp_flg         = stall_flg ? save_jmp_flg : input_jmp_flg;
wire [31:0] imm_i_sext      = stall_flg ? save_imm_i_sext : input_imm_i_sext;
wire [31:0] imm_b_sext      = stall_flg ? save_imm_b_sext : input_imm_b_sext;

`ifndef EXCLUDE_RV32M
wire [63:0] mult_signed_signed      = $signed(op1_data) * $signed(op2_data);
wire [63:0] mult_signed_unsigned    = $signed(op1_data) * $signed({1'b0,op2_data});
wire [63:0] mult_unsigned_unsigned  = $unsigned(op1_data) * $unsigned(op2_data);
`endif

always @(posedge clk) begin
    // EX STAGE
    if (wb_branch_hazard) begin
        alu_out     <= 32'hffffffff;
        br_flg      <= 0; 
        br_target   <= 32'hffffffff;
    end else begin
        // alu_out
        case (exe_fun) 
            ALU_ADD     : alu_out <= op1_data + op2_data;
            ALU_SUB     : alu_out <= op1_data - op2_data;
            ALU_AND     : alu_out <= op1_data & op2_data;
            ALU_OR      : alu_out <= op1_data | op2_data;
            ALU_XOR     : alu_out <= op1_data ^ op2_data;
            ALU_SLL     : alu_out <= op1_data << op2_data[4:0];
            ALU_SRL     : alu_out <= op1_data >> op2_data[4:0];
            ALU_SRA     : alu_out <= $signed($signed(op1_data) >>> op2_data[4:0]);
            ALU_SLT     : alu_out <= {31'b0, ($signed(op1_data) < $signed(op2_data))};
            ALU_SLTU    : alu_out <= {31'b0, op1_data < op2_data};
            ALU_JALR    : alu_out <= (op1_data + op2_data) & (~1);
            ALU_COPY1   : alu_out <= op1_data;

`ifndef EXCLUDE_RV32M 
            ALU_MUL     : alu_out <= mult_signed_signed[31:0];
            ALU_MULH    : alu_out <= mult_signed_signed[63:32];
            ALU_MULHSU  : alu_out <= mult_signed_unsigned[63:32];
            ALU_MULHU   : alu_out <= mult_unsigned_unsigned[63:32];
            // ALU_DIV     : alu_out <= div_signed;
            // ALU_DIVU    : alu_out <= div_unsigned;
            // ALU_REM     :
            // ALU_REMU    :
`endif

            default     : alu_out <= 0;
        endcase
        // br_flg
        case(exe_fun) 
            BR_BEQ  : br_flg <= (op1_data == op2_data);
            BR_BNE  : br_flg <= !(op1_data == op2_data);
            BR_BLT  : br_flg <= ($signed(op1_data) < $signed(op2_data));
            BR_BGE  : br_flg <= !($signed(op1_data) < $signed(op2_data));
            BR_BLTU : br_flg <= (op1_data < op2_data);
            BR_BGEU : br_flg <= !(op1_data < op2_data);
            default : br_flg <= 0;
        endcase
        br_target <= reg_pc + imm_b_sext;
    end
    
    if (wb_branch_hazard) begin
        // output
        output_reg_pc       <= REGPC_NOP;
        output_mem_wen      <= MEN_X;
        output_rf_wen       <= REN_X;
        output_rs2_data     <= 32'hffffffff;
        output_op1_data     <= 32'hffffffff;
        output_wb_sel       <= WB_X;
        output_wb_addr      <= 0;
        output_csr_cmd      <= CSR_X;
        output_jmp_flg      <= 0;
        output_imm_i        <= 32'hffffffff;

        // save
        save_reg_pc         <= 32'hffffffff;
        save_exe_fun        <= ALU_X;
        save_op1_data       <= 32'hffffffff;
        save_op2_data       <= 32'hffffffff;
        save_rs2_data       <= 32'hffffffff;
        save_mem_wen        <= MEN_X;
        save_rf_wen         <= REN_X;
        save_wb_sel         <= WB_X;
        save_wb_addr        <= 0;
        save_csr_cmd        <= CSR_X;
        save_jmp_flg        <= 0;
        save_imm_i_sext     <= 32'hffffffff;
        save_imm_b_sext     <= 32'hffffffff;
    end else begin
        // output
        output_reg_pc       <= reg_pc;
        output_mem_wen      <= mem_wen;
        output_rf_wen       <= rf_wen;
        output_rs2_data     <= rs2_data;
        output_op1_data     <= op1_data;
        output_wb_sel       <= wb_sel;
        output_wb_addr      <= wb_addr;
        output_csr_cmd      <= csr_cmd;
        output_jmp_flg      <= jmp_flg;
        output_imm_i        <= imm_i_sext;

        // save
        save_reg_pc         <= reg_pc;    
        save_exe_fun        <= exe_fun;    
        save_op1_data       <= op1_data;
        save_op2_data       <= op2_data;
        save_rs2_data       <= rs2_data;
        save_mem_wen        <= mem_wen;
        save_rf_wen         <= rf_wen;
        save_wb_sel         <= wb_sel;
        save_wb_addr        <= wb_addr;
        save_csr_cmd        <= csr_cmd;
        save_jmp_flg        <= jmp_flg;
        save_imm_i_sext     <= imm_i_sext;
        save_imm_b_sext     <= imm_b_sext;
    end
end

`ifdef DEBUG 
always @(posedge clk) begin
    $display("EXECUTE -------------");
    $display("exe_fun   : %d", exe_fun);
    $display("op1_data  : 0x%H", op1_data);
    $display("op2_data  : 0x%H", op2_data);
    $display("reg_pc    : 0x%H", reg_pc);
    $display("imm_b_sext: 0x%H", imm_b_sext);
end
`endif

endmodule