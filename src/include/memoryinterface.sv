`ifndef MEMINTERFACE_SV
`define MEMINTERFACE_SV

`include "include/ctrltype.sv"

// ready, validはChiselのデータ型に従う
typedef struct packed {
    logic           ready;
    logic           valid;
    logic [31:0]    addr;
} IRequest;

typedef struct packed {
    logic           ready;
    logic           valid;
    logic [31:0]    addr;
    logic [31:0]    inst;
    iidtype         inst_id;
} IResponse;

typedef struct packed {
    logic           valid;  // 予測を更新するかどうか
    logic [31:0]    pc;     // 更新したいpcのアドレス
    logic           is_br;  // 分岐命令か
    logic           is_jmp; // ジャンプ命令か
    logic           taken;  // 分岐したかどうか。ジャンプ命令なら常に1
    logic [31:0]    target; // 分岐先
} IUpdatePredictionIO;

typedef struct packed {
    logic           ready;
    logic           valid;
    logic [31:0]    addr;
    logic           wen;
    logic [31:0]    wdata;
    sizetype        wmask;
} DRequest;

typedef struct packed {
    logic           ready; // たぶん使わない
    logic           valid;
    logic [31:0]    addr;
    logic [31:0]    rdata;
} DResponse;
`endif