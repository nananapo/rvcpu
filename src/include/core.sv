localparam REGPC_NOP    = 32'hffffffff;
localparam INST_NOP     = 32'h00000033;
`ifdef DEBUG
localparam INST_ID_NOP = 64'bx;
localparam INST_ID_RANDOM = 64'hffffffff_ffffffff;
localparam INST_ID_ZERO = 64'd1;
localparam INST_ID_ONE = 64'd1;
`else
localparam INST_ID_NOP = 8'bx;
localparam INST_ID_RANDOM = 8'hff;
localparam INST_ID_ZERO = 8'd0;
localparam INST_ID_ONE = 8'd1;
`endif

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

localparam WB_X     = 2'dx;
localparam SIZE_X   = 2'dx;
// RV32A
// localparam MEN_AMOSWAP_W_AQRL = 4'd9;

localparam REN_X    = 1'b0;
localparam REN_S    = 1'b1;

localparam CSR_X    = 3'd0;
localparam CSR_W    = 3'd1;
localparam CSR_S    = 3'd2;
localparam CSR_C    = 3'd3;
localparam CSR_ECALL= 3'd4;
localparam CSR_SRET = 3'd5;
localparam CSR_MRET = 3'd6;