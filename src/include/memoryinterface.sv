`ifndef MEMINTERFACE_SV
`define MEMINTERFACE_SV
// ready, validはChiselのデータ型に従う
typedef struct packed {
    logic           ready; // 使わない
    logic           valid;
    logic [31:0]    addr;
} IRequest;

typedef struct packed {
    logic           ready;
    logic           valid;
    logic [31:0]    addr;
    logic [31:0]    inst;
    logic [63:0]    inst_id;
} IResponse;

typedef struct packed {
    logic           valid;  // 予測を更新するかどうか
    logic [31:0]    pc;     // 更新したいpcのアドレス
    logic           is_br;  // 分岐,ジャンプ命令なら1, 分岐命令ではない場合は0
    logic           taken;  // 分岐したかどうか。ジャンプ命令なら常に1
    logic [31:0]    target; // 分岐先
} IUpdatePredictionIO;

typedef struct packed {
    logic           ready;
    logic           valid;
    logic [31:0]    addr;
    logic           wen;
    logic [31:0]    wdata;
    logic [31:0]    wmask; // DUnalignedAccessController との間でしか使わない
} DRequest;

typedef struct packed {
    logic           ready; // たぶん使わない
    logic           valid;
    logic [31:0]    addr;
    logic [31:0]    rdata;
} DResponse;
`endif