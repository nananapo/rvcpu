`ifndef PKG_MEMINF_SVH
`define PKG_MEMINF_SVH

package meminf;

import basic::Addr, basic::Inst, basic::UInt32;
import csr::Mode;

typedef enum logic [1:0] {
    SIZE_B = 2'b00,
    SIZE_H = 2'b01,
    SIZE_W = 2'b10,
    SIZE_D = 2'b11
} MemSize;

typedef enum logic {
    // TODO Xをいれてerrorと合体する
    FE_ACCESS_FAULT,
    FE_PAGE_FAULT
} FaultTy;

// ready, validはChiselのデータ型に従う
typedef struct packed {
    logic  ready;
    logic  valid;
    Addr   addr;
} IReq;

typedef struct packed {
    logic   ready;
    logic   valid;
    logic   error;
    FaultTy errty;
    Addr    addr;
    Inst    inst;
    `ifdef PRINT_DEBUGINFO
    iid::Ty inst_id;
    `endif
} IResp;

typedef struct packed {
    logic   valid;  // 予測を更新するかどうか
    Addr    pc;     // 更新したいpcのアドレス
    logic   is_br;  // 分岐命令か
    logic   is_jmp; // ジャンプ命令か
    logic   taken;  // 分岐したかどうか。ジャンプ命令なら常に1
    Addr    target; // 分岐先
} BrInfo;

typedef struct packed {
    logic   ready;
    logic   valid;
    Addr    addr;
    logic   wen;
    UInt32  wdata;
} MemBusReq;

typedef struct packed {
    logic   valid;
    logic   error;
    Addr    addr;
    UInt32  rdata;
} MemBusResp;

typedef struct packed {
    logic a;
    logic d;
} PTE_AD;

typedef struct packed {
    logic   ready;
    logic   valid;
    Addr    addr;
    logic   wen;
    UInt32  wdata;
    MemSize wmask;
    PTE_AD  pte;
} CacheReq;

typedef struct packed {
    logic   valid;
    logic   error;
    FaultTy errty;
    UInt32  rdata;
} CacheResp;

typedef struct packed {
    Mode    i_mode;
    Mode    d_mode;
    logic   mxr;
    logic   sum;
    Addr    satp;
    logic   do_writeback;
    logic   is_writebacked_all;
    logic   invalidate_icache;
} CacheCntrInfo; 

endpackage

`endif