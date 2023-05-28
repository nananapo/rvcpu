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