localparam ALU_ADD  = 5'b00000;
localparam ALU_SUB  = 5'b00001;
localparam ALU_AND  = 5'b00010;
localparam ALU_OR   = 5'b00011;
localparam ALU_XOR  = 5'b00100;
localparam ALU_SLL  = 5'b00101;
localparam ALU_SRL  = 5'b00110;
localparam ALU_SRA  = 5'b00111;
localparam ALU_SLT  = 5'b01000;
localparam ALU_SLTU = 5'b01001;
localparam BR_BEQ   = 5'b01010;
localparam BR_BNE   = 5'b01011;
localparam BR_BLT   = 5'b01100;
localparam BR_BGE   = 5'b01101;
localparam BR_BLTU  = 5'b01110;
localparam BR_BGEU  = 5'b01111;
localparam ALU_JALR = 5'b10000;
localparam ALU_COPY1= 5'b10001; // op1をそのまま
localparam ALU_X    = 5'b10010; // 何もしない

localparam OP1_X	= 4'b0000;
localparam OP1_RS1  = 4'b0001;
localparam OP1_PC   = 4'b0010;
localparam OP1_IMZ  = 4'b0011;

localparam OP2_RS2W = 4'b0000;
localparam OP2_IMI  = 4'b0001;
localparam OP2_IMS  = 4'b0010;
localparam OP2_IMJ  = 4'b0011;
localparam OP2_IMU  = 4'b0100;
localparam OP2_IMZ  = 4'b0101;
localparam OP2_X    = 4'b0110;

localparam MEN_X    = 1'b0;
localparam MEN_S    = 1'b1;

localparam REN_X    = 1'b0;
localparam REN_S    = 1'b1;

localparam WB_X     = 4'b0000;
localparam WB_ALU   = 4'b0000;
localparam WB_MEMB  = 4'b0001;
localparam WB_MEMH  = 4'b0010;
localparam WB_MEMW  = 4'b0011;
localparam WB_MEMBU = 4'b0100;
localparam WB_MEMHU = 4'b0101;
localparam WB_PC	= 4'b0110;
localparam WB_CSR   = 4'b0111;

localparam CSR_X    = 3'b000;
localparam CSR_W    = 3'b001;
localparam CSR_S    = 3'b010;
localparam CSR_C    = 3'b011;
localparam CSR_E    = 3'b100;