localparam REGPC_NOP    = 32'hffffffff;
localparam INST_NOP     = 32'h00000033;
localparam INST_ID_NOP  = 64'bx;

localparam ALU_ADD  = 5'd0;
localparam ALU_SUB  = 5'd1;
localparam ALU_AND  = 5'd2;
localparam ALU_OR   = 5'd3;
localparam ALU_XOR  = 5'd4;
localparam ALU_SLL  = 5'd5;
localparam ALU_SRL  = 5'd6;
localparam ALU_SRA  = 5'd7;
localparam ALU_SLT  = 5'd8;
localparam ALU_SLTU = 5'd9;
localparam BR_BEQ   = 5'd10;
localparam BR_BNE   = 5'd11;
localparam BR_BLT   = 5'd12;
localparam BR_BGE   = 5'd13;
localparam BR_BLTU  = 5'd14;
localparam BR_BGEU  = 5'd15;
localparam ALU_JALR = 5'd16;
localparam ALU_COPY1= 5'd17; // op1をそのまま
localparam ALU_X    = 5'd18; // 何もしない

// RV32M
//`ifndef EXCLUDE_RV32M
localparam ALU_MUL      = 5'd19;
localparam ALU_MULH     = 5'd20;
localparam ALU_MULHSU   = 5'd21;
localparam ALU_MULHU    = 5'd22;
localparam ALU_DIV      = 5'd23;
localparam ALU_DIVU     = 5'd24;
localparam ALU_REM      = 5'd25;
localparam ALU_REMU     = 5'd26;
//`endif

localparam OP1_X    = 4'd0;
localparam OP1_RS1  = 4'd1;
localparam OP1_PC   = 4'd2;
localparam OP1_IMZ  = 4'd3;

localparam OP2_RS2W = 4'd0;
localparam OP2_IMI  = 4'd1;
localparam OP2_IMS  = 4'd2;
localparam OP2_IMJ  = 4'd3;
localparam OP2_IMU  = 4'd4;
localparam OP2_IMZ  = 4'd5;
localparam OP2_X    = 4'd6;

localparam MEN_X    = 4'd0;
localparam MEN_SB   = 4'd1;
localparam MEN_SH   = 4'd2;
localparam MEN_SW   = 4'd3;
localparam MEN_LB   = 4'd4;
localparam MEN_LBU  = 4'd5;
localparam MEN_LH   = 4'd6;
localparam MEN_LHU  = 4'd7;
localparam MEN_LW   = 4'd8;
// RV32A
//`ifndef EXCLUDE_RV32A
localparam MEN_AMOSWAP_W_AQRL = 4'd9;
//`endif

localparam REN_X    = 1'b0;
localparam REN_S    = 1'b1;

localparam WB_X     = 4'd0;
localparam WB_ALU   = 4'd0;
localparam WB_MEMB  = 4'd1;
localparam WB_MEMH  = 4'd2;
localparam WB_MEMW  = 4'd3;
localparam WB_MEMBU = 4'd4;
localparam WB_MEMHU = 4'd5;
localparam WB_PC    = 4'd6;
localparam WB_CSR   = 4'd7;

localparam CSR_X    = 3'd0;
localparam CSR_W    = 3'd1;
localparam CSR_S    = 3'd2;
localparam CSR_C    = 3'd3;
localparam CSR_ECALL= 3'd4;
localparam CSR_SRET = 3'd5;
localparam CSR_MRET = 3'd6;