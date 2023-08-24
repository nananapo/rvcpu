`ifndef MEMINTERFACE_SV
`define MEMINTERFACE_SV

// ready, validはChiselのデータ型に従う
typedef struct packed {
    logic  ready;
    logic  valid;
    InstPc addr;
} IRequest;

typedef struct packed {
    logic   ready;
    logic   valid;
    InstPc  addr;
    Inst    inst;
    IId     inst_id;
    logic   is_c;
} IResponse;

typedef struct packed {
    logic   valid;  // 予測を更新するかどうか
    InstPc  pc;     // 更新したいpcのアドレス
    logic   is_br;  // 分岐命令か
    logic   is_jmp; // ジャンプ命令か
    logic   taken;  // 分岐したかどうか。ジャンプ命令なら常に1
    InstPc  target; // 分岐先
    `ifdef DEBUG
    logic   fail;   // 予測に成功したかどうか
    `endif
} IUpdatePredictionIO;

typedef struct packed {
    logic   ready;
    logic   valid;
    InstPc  addr;
    logic   wen;
    UIntX   wdata;
    MemSize wmask;
} DRequest;

typedef struct packed {
    logic   ready; // たぶん使わない
    logic   valid;
    InstPc  addr;
    UIntX   rdata;
} DResponse;
`endif