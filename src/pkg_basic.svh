`ifndef PKG_BASIC_SVH
`define PKG_BASIC_SVH

package basic;

typedef logic [conf::ILEN-1:0]  Inst;
typedef logic [conf::XLEN-1:0]  Addr;
typedef logic [conf::XLEN-1:0]  UIntX;
typedef logic [4:0]             UInt5;
typedef logic [7:0]             UInt8;
typedef logic [11:0]            UInt12;
typedef logic [31:0]            UInt32;
typedef logic [63:0]            UInt64;

`ifdef XLEN64
    localparam XLEN_MAX     = 64'hffffffff_ffffffff;
    localparam XLEN_ZERO    = 64'h0;
    localparam XLEN_X       = 64'hx;
    `ifdef RISCV_TESTS
    localparam RISCVTESTS_EXIT_ADDR = 64'h1000;
    `endif
`else
    localparam XLEN_MAX     = 32'hffffffff;
    localparam XLEN_ZERO    = 32'h0;
    localparam XLEN_X       = 32'hx;
    `ifdef RISCV_TESTS
    localparam RISCVTESTS_EXIT_ADDR = 32'h1000;
    `endif
`endif
localparam INST_NOP = 32'h00000033; // TODO ILEN

endpackage

`endif