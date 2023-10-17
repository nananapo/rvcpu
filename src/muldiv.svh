`ifndef MULDIV_H
`define MULDIV_H

typedef struct packed {
    logic   valid;
    logic   ready; // output
    AluSel  sel;
    logic   is_signed;
    UIntX   op1;
    UIntX   op2;
} MulDivReq;

typedef struct packed {
    logic   valid;
    UIntX   result;
} MulDivResp;

`endif