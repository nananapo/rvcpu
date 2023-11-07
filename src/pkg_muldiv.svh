`ifndef PKG_MULDIV_H
`define PKG_MULDIV_H

package muldiv;

import basic::UIntX;
import stageinfo::AluSel;

typedef struct packed {
    logic   valid;
    logic   ready; // output
    AluSel  sel;
    logic   is_signed;
    UIntX   op1;
    UIntX   op2;
} Req;

typedef struct packed {
    logic   valid;
    UIntX   result;
} Resp;

endpackage

`endif