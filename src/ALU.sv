module ALU
    import basic::*;
    import stageinfo::*;
#(
    parameter ENABLE_ALU    = 1'b0,
    parameter ENABLE_BRANCH = 1'b0
)(
    input wire AluSel   i_exe,
    input wire BrSel    br_exe,
    input wire SignSel  sign_sel,
    input wire UIntX    op1_data,
    input wire UIntX    op2_data,
    output wire UIntX   alu_out,
    output wire         branch_take
);

import conf::*;

// alu_out
function [$bits(UIntX)-1:0] alu_func(
    input AluSel    fun,
    input SignSel   sign_sel,
    input UIntX     op1_data,
    input UIntX     op2_data
);
    case (fun)
        ALU_ADD  : return op1_data + op2_data;
        ALU_SUB  : return op1_data - op2_data;
        ALU_AND  : return op1_data & op2_data;
        ALU_OR   : return op1_data | op2_data;
        ALU_XOR  : return op1_data ^ op2_data;
        ALU_SLL  : return op1_data << op2_data[4:0];
        ALU_SRL  : return op1_data >> op2_data[4:0];
        ALU_SRA  : return $signed($signed(op1_data) >>> op2_data[4:0]);
        ALU_SLT  : return sign_sel == OP_SIGNED ?
                            {{XLEN-1{1'b0}}, ($signed(op1_data) < $signed(op2_data))} : // SLT
                            {{XLEN-1{1'b0}}, op1_data < op2_data}; // SLTU
        ALU_JALR : return (op1_data + op2_data) & (~1);
        ALU_COPY1: return op1_data;
        ALU_CZERO_EQ: return op2_data === XLEN_ZERO ? op1_data : XLEN_ZERO;
        ALU_CZERO_NE: return op2_data !== XLEN_ZERO ? op1_data : XLEN_ZERO;
        default  : return XLEN_X;
    endcase
endfunction

function br_func(
    input BrSel     fun,
    input SignSel   sign_sel,
    input UIntX     op1_data,
    input UIntX     op2_data
);
    case(fun)
        BR_BEQ  : return (op1_data === op2_data);
        BR_BNE  : return !(op1_data === op2_data);
        BR_BLT  : return sign_sel == OP_SIGNED ?
                            ($signed(op1_data) < $signed(op2_data)) :
                            (op1_data < op2_data);
        BR_BGE  : return sign_sel == OP_SIGNED ?
                            !($signed(op1_data) < $signed(op2_data)) :
                            !(op1_data < op2_data);
        default : return 1'b0;
    endcase
endfunction

assign alu_out      = ENABLE_ALU    == 1'b0 ? XLEN_X : alu_func(i_exe, sign_sel, op1_data, op2_data);
assign branch_take  = ENABLE_BRANCH == 1'b0 ? 1'bx  : br_func(br_exe, sign_sel, op1_data, op2_data);

endmodule