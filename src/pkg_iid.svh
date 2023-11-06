`ifndef PKG_IID_SVH
`define PKG_IID_SVH

`ifdef PRINT_DEBUGINFO
package iid;
    parameter X     = 64'bx;
    parameter ZERO  = 64'd0;
    parameter ONE   = 64'd1;

    typedef struct packed {
        logic [63:0] id;
    } Ty;

    function logic [63:0] inc(Ty iid);
        inc = iid.id + ONE;
    endfunction

    function logic [63:0] dec(Ty iid);
        dec = iid.id - ONE;
    endfunction
endpackage
`endif

`endif