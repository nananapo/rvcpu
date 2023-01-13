module Core #(
    parameter WORD_LEN = 32,
    parameter REGISTER_COUNT = 32,
    parameter REGISTER_COUNT_BIT = 5,
    parameter IMM_I_BITWISE = 12,

    parameter INST_LW_FUNCT3 = 3'b010,
    parameter INST_LW_OPCODE = 7'b0000011
) (
    input wire clk,
    input wire rst_n,
    output wire exit,
    output wire [WORD_LEN-1:0] memory_i_addr,
    input wire [WORD_LEN-1:0] memory_inst,
    output wire [WORD_LEN-1:0] memory_d_addr,
    input wire [WORD_LEN-1:0] memory_rdata
);

// registers
reg [WORD_LEN-1:0] regfile [REGISTER_COUNT-1:0];
// initialize regfile
integer loop_initial_regfile_i;
initial begin
    for (loop_initial_regfile_i = 0;
        loop_initial_regfile_i < REGISTER_COUNT;
        loop_initial_regfile_i = loop_initial_regfile_i + 1)
        regfile[loop_initial_regfile_i] = 0;
end

reg [WORD_LEN-1:0] reg_pc = 0;

// プログラムカウンタとメモリを接続
assign memory_i_addr = reg_pc;

// DECODE STAGE
wire [REGISTER_COUNT_BIT-1:0] rs1_addr = memory_inst[19:15];
wire [REGISTER_COUNT_BIT-1:0] rs2_addr = memory_inst[24:20];
wire [REGISTER_COUNT_BIT-1:0] wb_addr  = memory_inst[11:7];

wire [WORD_LEN-1:0] rs1_data = (rs1_addr == 0) ? 0 : regfile[rs1_addr];
wire [WORD_LEN-1:0] rs2_data = (rs2_addr == 0) ? 0 : regfile[rs2_addr];

wire [IMM_I_BITWISE-1:0] imm_i = memory_inst[31:20];
wire [WORD_LEN-1:0] imm_i_sext = {{WORD_LEN-IMM_I_BITWISE{imm_i[IMM_I_BITWISE-1]}}, imm_i};

// instructions
wire [2:0] funct3 = memory_inst[14:12];
wire [6:0] opcode = memory_inst[6:0];

wire inst_is_lw = (funct3 == INST_LW_FUNCT3 && opcode == INST_LW_OPCODE);

// EX STAGE
wire [WORD_LEN-1:0] alu_out = (inst_is_lw ? rs1_addr + imm_i_sext : 0);

// MEM STAGE
assign memory_d_addr = alu_out;

// 終了判定
assign exit = memory_i_addr == 8;

integer loop_i;
always @(negedge rst_n or posedge clk) begin
    if (!rst_n) begin
        reg_pc <= 0;
        for (loop_i = 0; loop_i < REGISTER_COUNT; loop_i = loop_i + 1)
            regfile[loop_i] <= 0;
    end else if (!exit) begin
        reg_pc <= reg_pc + 4;

        // WB STAGE
        if (inst_is_lw) begin
            regfile[wb_addr] <= memory_rdata;
        end

        $display("reg_pc    : %d", reg_pc);
        $display("inst      : 0x%H", memory_inst);
        $display("rs1_addr  : %d", rs1_addr);
        $display("rs2_addr  : %d", rs2_addr);
        $display("wb_addr   : %d", wb_addr);
        $display("rs1_data  : 0x%H", rs1_data);
        $display("rs2_data  : 0x%H", rs2_data);
        $display("wb_data   : 0x%H", memory_rdata);
        $display("dmem.addr : %d", memory_d_addr);

        $display("--------");
    end

end

endmodule