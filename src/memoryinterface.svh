`ifndef MEMINTERFACE_SV
`define MEMINTERFACE_SV

`include "basic.svh"

// ready, validはChiselのデータ型に従う
typedef struct packed {
    logic  ready;
    logic  valid;
    Addr   addr;
} IReq;

typedef struct packed {
    logic   ready;
    logic   valid;
    Addr    addr;
    Inst    inst;
    IId     inst_id;
    logic   is_c;
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
    logic   ready; // in
    logic   valid; // out
    Addr    addr;  // out
    logic   wen;   // out
    UIntX   wdata; // out
    MemSize wmask; // out
} DReq;

typedef struct packed {
    // logic   ready; // たぶん使わない
    logic   valid;
    Addr    addr;
    UIntX   rdata;
} DResp;


typedef struct packed {
    logic   ready;
    logic   valid;
    Addr    addr;
    logic   wen;
    UInt32  wdata;
} MemBusReq;

typedef struct packed {
    // logic       ready;
    logic   valid;
    logic   error;
    Addr    addr;
    UInt32  rdata;
} MemBusResp;

typedef struct packed {
    logic   ready;
    logic   valid;
    Addr    addr;
    logic   wen;
    UInt32  wdata;
} CacheReq;

typedef struct packed {
    logic   valid;
    logic   error;
    UInt32  rdata;
} CacheResp;

`endif