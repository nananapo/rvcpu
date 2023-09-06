localparam XLEN = `XLEN;

`ifdef XLEN64
    localparam ADDR_MAX = 64'hffffffff_ffffffff;
    localparam ADDR_X   = 64'hx;
    localparam ADDR_ZRRO= 64'h0;
    localparam DATA_X   = 64'hx;
    localparam DATA_Z   = 64'hz;
    localparam DATA_ZERO= 64'h0;
    
    `ifdef RISCV_TEST
        localparam RISCVTESTS_EXIT_ADDR = 64'h1000;
    `endif
`else
    localparam ADDR_MAX = 32'hffffffff;
    localparam ADDR_X   = 32'hx;
    localparam ADDR_ZERO= 32'h0;
    localparam DATA_X   = 32'hx;
    localparam DATA_Z   = 32'hz;
    localparam DATA_ZERO= 32'h0;

    `ifdef RISCV_TEST
        localparam RISCVTESTS_EXIT_ADDR = 32'h1000;
    `endif
`endif

localparam XBIT_32 = 32'hx;
localparam XBIT_64 = 64'hx;
localparam ZBIT_32 = 32'hz;
localparam ZBIT_64 = 64'hz;



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