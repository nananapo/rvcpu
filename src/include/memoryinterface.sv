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
    // FIXME
    // フェッチが完了していない場合はaddrにフェッチ中のアドレスが設定されるようにしたほうがいいか？
    // でも、フェッチ中のアドレスさえ定まっていない(例えば仮想アドレスなどの)場合はどうしよう。
    // フェッチするまで分岐予測の結果判定を遅らせることで対処するか？
    // 結局それならフェッチ中のアドレスを設定する意味がない
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
