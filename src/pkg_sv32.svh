`ifndef PKG_SV32_SVH
`define PKG_SV32_SVH


package Sv32;

import basic::UIntX, basic::Addr;

localparam ENABLE_TLB0_LOG = 0;
localparam ENABLE_TLB1_LOG = 0;

localparam VPN1_LEN = 10;
localparam VPN0_LEN = 10;
localparam VPN_LEN  = VPN1_LEN + VPN0_LEN;
localparam PGOFF_LEN= 12;

localparam PPN1_LEN = 12;
localparam PPN0_LEN = 10;
localparam PPN_LEN  = PPN1_LEN + PPN0_LEN;

typedef logic [VPN1_LEN-1:0]    VPN1;
typedef logic [VPN0_LEN-1:0]    VPN0;
typedef logic [VPN_LEN-1:0]     VPN;
typedef logic [PGOFF_LEN-1:0]   Pgoff;
typedef logic [PPN1_LEN-1:0]    PPN1;
typedef logic [PPN0_LEN-1:0]    PPN0;
typedef logic [PPN_LEN-1:0]     PPN;

endpackage

interface VAddr
    import conf::*;
    import basic::*;
    import Sv32::*;
(
    input Addr addr
);
    wire VPN1   vpn1 = addr[XLEN - 1:XLEN - VPN1_LEN];
    wire VPN0   vpn0 = addr[XLEN - VPN1_LEN - 1: XLEN - VPN_LEN];
    wire VPN    vpn  = addr[XLEN - 1:XLEN - VPN_LEN];
    wire Pgoff  pgoff= addr[XLEN - VPN_LEN - 1:0];
endinterface

interface PTE
    import conf::*;
    import basic::*;
    import Sv32::*;
(
    input UIntX pte
);
    /*
    X W R
    0 0 0 Pointer to next level of page table.
    0 0 1 Read-only page.
    0 1 0 Reserved for future use.
    0 1 1 Read-write page.
    1 0 0 Execute-only page.
    1 0 1 Read-execute page.
    1 1 0 Reserved for future use.
    1 1 1 Read-write-execute page.
    */
    wire PPN1   ppn1    = pte[XLEN - 1:XLEN - PPN1_LEN];
    wire PPN0   ppn0    = pte[XLEN - PPN1_LEN - 1:XLEN - PPN_LEN];
    wire PPN    ppn     = pte[XLEN - 1:XLEN - PPN_LEN];
    wire logic  v       = pte[0] === 1'b1;
    wire logic  r       = pte[1] === 1'b1;
    wire logic  w       = pte[2] === 1'b1;
    wire logic  x       = pte[3] === 1'b1;
    wire logic  u       = pte[4] === 1'b1;
    wire logic  g       = pte[5] === 1'b1;
    wire logic  a       = pte[6] === 1'b1;
    wire logic  d       = pte[7] === 1'b1;

    wire is_leaf = v & (r | w | x);
endinterface

`endif