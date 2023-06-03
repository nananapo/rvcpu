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