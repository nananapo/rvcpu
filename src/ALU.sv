module ALU #(
    parameter       ENABLE_ALU      = 1'b0,
    parameter       ENABLE_BRANCH   = 1'b0 
)(
    input wire AluSel   i_exe,
    input wire BrSel    br_exe,
    input wire UIntX    op1_data,
    input wire UIntX    op2_data,
    output wire UIntX   alu_out,
    output wire         branch_take
);

`include "include/basicparams.svh"

// alu_out
function [$bits(UIntX)-1:0] alu_func(
    input AluSel fun,
    input UIntX  op1_data,
    input UIntX  op2_data
);
    case (fun) 
        ALU_ADD  : alu_func = op1_data + op2_data;
        ALU_SUB  : alu_func = op1_data - op2_data;
        ALU_AND  : alu_func = op1_data & op2_data;
        ALU_OR   : alu_func = op1_data | op2_data;
        ALU_XOR  : alu_func = op1_data ^ op2_data;
        ALU_SLL  : alu_func = op1_data << op2_data[4:0];
        ALU_SRL  : alu_func = op1_data >> op2_data[4:0];
        ALU_SRA  : alu_func = $signed($signed(op1_data) >>> op2_data[4:0]);
        ALU_SLT  : alu_func = {{`XLEN-1{1'b0}}, ($signed(op1_data) < $signed(op2_data))};
        ALU_SLTU : alu_func = {{`XLEN-1{1'b0}}, op1_data < op2_data};
        ALU_JALR : alu_func = (op1_data + op2_data) & (~1);
        ALU_COPY1: alu_func = op1_data;
        default  : alu_func = DATA_X;
    endcase
endfunction

function br_func(
    input BrSel fun,
    input UIntX op1_data,
    input UIntX op2_data
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

assign alu_out      = ENABLE_ALU    == 1'b0 ? DATA_X : alu_func(i_exe, op1_data, op2_data);
assign branch_take  = ENABLE_BRANCH == 1'b0 ? 1'bx  : br_func(br_exe, op1_data, op2_data);

endmodule