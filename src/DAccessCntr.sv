module DAccessCntr (
    input wire              clk,
    inout wire DRequest     dreq,
    inout wire DResponse    dresp,
    inout wire DRequest     memreq,
    inout wire DResponse    memresp
);

typedef enum reg [3:0] {
    IDLE,
    LOAD_READY,
    LOAD_VALID,
    LOAD_READY2,
    LOAD_VALID2,
    LOAD_END,
    LOAD_PUSH,
    STORE_CHECK,
    STORE_READY,
    STORE_READY2
} statetype;

statetype state = IDLE;

DRequest sdreq;
initial begin
    sdreq.valid = 1'b0;
    sdreq.wen = 0;
    sdreq.wmask = SIZE_W;
end

// Storeの場合、投げっぱなし
// 4 byteアラインされていない、またはbyte, half命令は必ず先読みする。
//
// 4byteアラインされているかつbyte, half
// -> loadは1回
// 4byteアラインされていない、かつword
// -> loadは必ず2回
// 4byteアラインされていない、かつhalf
// -> addr % 4 == 1 or 2ならloadは1回
// -> addr % 4 == 3ならloadは2回
// 4byteアラインされていない、かつbyte
// -> loadは1回 
//
// 先読みするなら、LOAD(4 or 6) + STORE(3)、よって7 or 9クロック以上
//  IDLE -> STORE_CHECK -> LOAD_READY -> ... -> LOAD_END -> STORE_READY
// しないなら、3クロック以上
//  IDLE -> STORE_CHECK -> STORE_READY

// LOADの場合、
// 4byteアラインされているなら、4クロック以上
//  IDLE -> LOAD_READY -> LOAD_VALID -> LOAD_END -> LOAD_PUSH
// されていないなら、6クロック以上
//  IDLE -> LOAD_READY -> LOAD_VALID -> LOAD_READY2 -> LOAD_VALID2 -> LOAD_END -> LOAD_PUSH

// 下位2ビット
wire [1:0]  saddr_lb = sdreq.addr[1:0];
// アドレスの4byte アラインされている形
wire [31:0] saddr_aligned = {sdreq.addr[31:2], 2'b00};

wire [31:0] swdata = sdreq.wdata;
wire        sis_b = sdreq.wmask == SIZE_B;
wire        sis_h = sdreq.wmask == SIZE_H;
wire        sis_w = sdreq.wmask == SIZE_W;

// このstore命令はloadする必要があるか
wire require_load = (!sis_w || saddr_lb != 2'b00);
// この命令は2回loadする必要があるか
wire is_load_twice = (sis_w && saddr_lb != 2'b00) || (sis_h && saddr_lb == 2'd3);

reg [31:0]  saved_rdata1;
reg [31:0]  saved_rdata2;

reg [31:0]  store_wdata1;
reg [31:0]  store_wdata2;

reg [31:0]  load_result;

assign memreq.valid = state == LOAD_READY || state == LOAD_READY2 || state == STORE_READY || state == STORE_READY2;
assign memreq.addr  = state == LOAD_READY || state == STORE_READY ? saddr_aligned : saddr_aligned + 32'd4;
assign memreq.wen   = state == STORE_READY || state == STORE_READY2;
assign memreq.wdata = state == STORE_READY ? store_wdata1 : store_wdata2;

assign dresp.valid  = state == LOAD_PUSH;
assign dresp.addr   = sdreq.addr;
assign dresp.rdata  = load_result;

assign dreq.ready   = state == IDLE;

always @(posedge clk) begin
    case (state)
    LOAD_READY: begin
        if (memreq.ready) begin
            state <= LOAD_VALID;
        end
    end
    LOAD_VALID: begin
        if (memresp.valid) begin
            state <= statetype'(is_load_twice ? LOAD_READY2 : LOAD_END);
            saved_rdata1 <= memresp.rdata;
        end
    end
    LOAD_READY2: begin
        if (memreq.ready) begin
            state <= LOAD_VALID2;
        end
    end
    LOAD_VALID2: begin
        if (memresp.valid) begin
            state <= LOAD_END;
            saved_rdata2 <= memresp.rdata;
        end
    end
    LOAD_END: begin
        state <= statetype'(sdreq.wen ? STORE_READY : LOAD_PUSH);

        // storeの準備, loadの結果準備
        case (saddr_lb)
        2'd0: begin
            load_result  <= saved_rdata1;
            store_wdata1 <= {saved_rdata1[31:16], // アラインされたw命令はloadしないので無視
                             sis_b ? saved_rdata1[15:8] : swdata[15:8], // 2byte目はb命令でなければ書き込む
                             swdata[7:0]}; // 1byteは必ず書き込む
        end
        2'd1: begin
            store_wdata2 <= {saved_rdata2[31:8],
                             swdata[31:24]}; // 2回書き込むときは必ずw命令
            store_wdata1 <= {!sis_w ? saved_rdata1[31:24] : swdata[23:16], // 3byte目はw命令なら書き込む
                             sis_b  ? saved_rdata1[23:16] : swdata[15:8],  // 2byte目はb命令でなければ書き込む
                             swdata[7:0], // 1byteは必ず書き込む
                             saved_rdata1[7:0]};
            load_result  <= {saved_rdata2[7:0], saved_rdata1[31:8]};
        end
        2'd2: begin
            store_wdata2 <= {saved_rdata2[31:16],
                             swdata[31:16]}; // 2回書き込むときは必ずw命令
            store_wdata1 <= {sis_b ? saved_rdata1[31:24] : swdata[15:8], // 2byte目はb命令でなければ書き込む
                             swdata[7:0], // 1byteは必ず書き込む
                             saved_rdata1[15:0]};
            load_result  <= {saved_rdata2[15:0], saved_rdata1[31:16]};
        end
        2'd3: begin
            store_wdata2 <= {saved_rdata2[31:24],
                             sis_w  ? swdata[31:16] : saved_rdata2[23:8], // 4, 3byte目はw命令なら書き込む
                             !sis_b ? swdata[15:8]  : saved_rdata2[7:0]}; // 2byte目はb命令でなければ書き込む
            store_wdata1 <= {swdata[7:0], saved_rdata1[23:0]}; // 1byteは必ず書き込む
            load_result  <= {saved_rdata2[23:0], saved_rdata1[31:24]};
        end
        endcase
    end
    LOAD_PUSH: begin
        // TODO dresp.readyを待つ？
        state <= IDLE;
    end
    STORE_CHECK: begin
        state <= statetype'(require_load ? LOAD_READY : STORE_READY);
        store_wdata1 <= sdreq.wdata; // すぐにSTORE_READYに行く場合のwdataの準備
    end
    STORE_READY: begin
        if (memreq.ready) begin
            state <= statetype'(is_load_twice ? STORE_READY2 : IDLE);
        end
    end
    STORE_READY2: begin
        if (memreq.ready) begin
            state <= IDLE;
        end
    end
    default/*IDLE*/: begin
        sdreq <= dreq;
        if (dreq.valid) begin
            state <= statetype'(dreq.wen ? STORE_CHECK : LOAD_READY);
        end
    end
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,dmemucntr.state,d,%b", state);
    $display("data,dmemucntr.saved_rdata1,h,%b", saved_rdata1);
    $display("data,dmemucntr.saved_rdata2,h,%b", saved_rdata2);
    $display("data,dmemucntr.load_result,h,%b", load_result);
    $display("data,dmemucntr.saddr_lb,h,%b", saddr_lb);
    /*
    $display("data,dmemucntr.dreq.ready,b,%b", dreq.ready);
    $display("data,dmemucntr.dreq.valid,b,%b", dreq.valid);
    $display("data,dmemucntr.dresp.valid,b,%b", dresp.valid);
    $display("data,dmemucntr.ireq.ready,b,%b", ireq.ready);
    $display("data,dmemucntr.ireq.valid,b,%b", ireq.valid);
    $display("data,dmemucntr.iresp.valid,b,%b", iresp.valid);
    */
end
`endif

endmodule

/*
    0  1  2  3
0  be be fe ca
4  ef be ad de

0 : cafebebe
1 : efcafebe
2 : beefcafe
3 : adbeefca

4 : deadbeef
*/