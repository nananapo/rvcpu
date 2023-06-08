module ALU #(
    parameter       ENABLE_ALU      = 1'b0,
    parameter       ENABLE_BRANCH   = 1'b0 
)(
    input wire alui_exe_type i_exe,
    input wire br_exe_type   br_exe,
    input wire [31:0]   op1_data,
    input wire [31:0]   op2_data,
    output wire [31:0]  alu_out,
    output wire         branch_take
);

`include "include/core.sv"

// alu_out
function [31:0] alui_func(
    input alui_exe_type fun,
    input [31:0] op1_data,
    input [31:0] op2_data
);
case (fun) 
    ALUI_ADD    : alui_func = op1_data + op2_data;
    ALUI_SUB    : alui_func = op1_data - op2_data;
    ALUI_AND    : alui_func = op1_data & op2_data;
    ALUI_OR     : alui_func = op1_data | op2_data;
    ALUI_XOR    : alui_func = op1_data ^ op2_data;
    ALUI_SLL    : alui_func = op1_data << op2_data[4:0];
    ALUI_SRL    : alui_func = op1_data >> op2_data[4:0];
    ALUI_SRA    : alui_func = $signed($signed(op1_data) >>> op2_data[4:0]);
    ALUI_SLT    : alui_func = {31'b0, ($signed(op1_data) < $signed(op2_data))};
    ALUI_SLTU   : alui_func = {31'b0, op1_data < op2_data};
    ALUI_JALR   : alui_func = (op1_data + op2_data) & (~1);
    ALUI_COPY1  : alui_func = op1_data;
    default     : alui_func = 32'hx;
endcase
endfunction

function br_func(
    input br_exe_type fun,
    input [31:0] op1_data,
    input [31:0] op2_data
);
case(fun) 
    BR_BEQ  : br_func = (op1_data == op2_data);
    BR_BNE  : br_func = !(op1_data == op2_data);
    BR_BLT  : br_func = ($signed(op1_data) < $signed(op2_data));
    BR_BGE  : br_func = !($signed(op1_data) < $signed(op2_data));
    BR_BLTU : br_func = (op1_data < op2_data);
    BR_BGEU : br_func = !(op1_data < op2_data);
    default : br_func = 1'b0;
endcase
endfunction

assign alu_out      = ENABLE_ALU    == 1'b0 ? 32'bx : alui_func(i_exe, op1_data, op2_data);
assign branch_take  = ENABLE_BRANCH == 1'b0 ? 1'bx  : br_func(br_exe, op1_data, op2_data);

endmodule