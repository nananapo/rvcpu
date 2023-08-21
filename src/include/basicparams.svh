`ifdef XLEN64
    localparam PC_MAX   = 64'hffffffff_ffffffff;
    localparam PC_X     = 64'hx;
    localparam DATA_X   = 64'hx;
`else
    localparam PC_MAX   = 32'hffffffff;
    localparam PC_X     = 32'hx;
    localparam DATA_X   = 32'hx;
`endif

localparam INST_NOP = 32'h00000033; // TODO ILEN

`ifdef DEBUG
    localparam IID_X = 64'bx;
    localparam IID_RANDOM = 64'hffffffff_ffffffff;
    localparam IID_ZERO = 64'd0;
    localparam IID_ONE = 64'd1;
`else
    localparam IID_X = 8'bx;
    localparam IID_RANDOM = 8'hff;
    localparam IID_ZERO = 8'd0;
    localparam IID_ONE = 8'd1;
`endif