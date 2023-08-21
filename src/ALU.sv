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

// alu_out
function [$bits(UIntX)-1:0] alui_func(
    input AluSel fun,
    input UIntX  op1_data,
    input UIntX  op2_data
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
        ALUI_SLT    : alui_func = {{XLEN{1'b0}}, ($signed(op1_data) < $signed(op2_data))};
        ALUI_SLTU   : alui_func = {{XLEN{1'b0}}, op1_data < op2_data};
        ALUI_JALR   : alui_func = (op1_data + op2_data) & (~1);
        ALUI_COPY1  : alui_func = op1_data;
        default     : alui_func = DATA_X;
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

assign alu_out      = ENABLE_ALU    == 1'b0 ? DATA_X : alui_func(i_exe, op1_data, op2_data);
assign branch_take  = ENABLE_BRANCH == 1'b0 ? 1'bx  : br_func(br_exe, op1_data, op2_data);

endmodule