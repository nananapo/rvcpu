module ALU #(
    parameter       ENABLE_ALU      = 1'b0,
    parameter       ENABLE_BRANCH   = 1'b0 
)(
    input [4:0]     exe_fun,
    input [31:0]    op1_data,
    input [31:0]    op2_data,
    output [31:0]   alu_out,
    output          branch_take
);

`include "include/core.sv"

// alu_out
function [31:0] alu_out_func(
    input [4:0 ] exe_fun,
    input [31:0] op1_data,
    input [31:0] op2_data
);
case (exe_fun) 
    ALU_ADD     : alu_out_func = op1_data + op2_data;
    ALU_SUB     : alu_out_func = op1_data - op2_data;
    ALU_AND     : alu_out_func = op1_data & op2_data;
    ALU_OR      : alu_out_func = op1_data | op2_data;
    ALU_XOR     : alu_out_func = op1_data ^ op2_data;
    ALU_SLL     : alu_out_func = op1_data << op2_data[4:0];
    ALU_SRL     : alu_out_func = op1_data >> op2_data[4:0];
    ALU_SRA     : alu_out_func = $signed($signed(op1_data) >>> op2_data[4:0]);
    ALU_SLT     : alu_out_func = {31'b0, ($signed(op1_data) < $signed(op2_data))};
    ALU_SLTU    : alu_out_func = {31'b0, op1_data < op2_data};
    ALU_JALR    : alu_out_func = (op1_data + op2_data) & (~1);
    ALU_COPY1   : alu_out_func = op1_data;
    default     : alu_out_func = 32'hx;
endcase
endfunction

function br_flg_func(
    input [4:0 ] exe_fun,
    input [31:0] op1_data,
    input [31:0] op2_data
);
    case(exe_fun) 
    BR_BEQ  : br_flg_func = (op1_data == op2_data);
    BR_BNE  : br_flg_func = !(op1_data == op2_data);
    BR_BLT  : br_flg_func = ($signed(op1_data) < $signed(op2_data));
    BR_BGE  : br_flg_func = !($signed(op1_data) < $signed(op2_data));
    BR_BLTU : br_flg_func = (op1_data < op2_data);
    BR_BGEU : br_flg_func = !(op1_data < op2_data);
    default : br_flg_func = 1'b0;
    endcase
endfunction

assign alu_out      = ENABLE_ALU    == 1'b0 ? 32'bx : alu_out_func(exe_fun, op1_data, op2_data);
assign branch_take  = ENABLE_BRANCH == 1'b0 ? 1'bx  : br_flg_func(exe_fun, op1_data, op2_data);

endmodule