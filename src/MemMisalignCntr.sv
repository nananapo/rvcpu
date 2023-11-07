module MemMisalignCntr
    import meminf::*;
(
    input wire              clk,
    input wire              reset,
    inout wire CacheReq     dreq,
    inout wire CacheResp    dresp,
    inout wire CacheReq     memreq,
    inout wire CacheResp    memresp
);

import basic::*;

typedef enum logic [3:0] {
    IDLE,
    LOAD_READY,
    LOAD_VALID,
    LOAD_READY2,
    LOAD_VALID2,
    LOAD_END,
    LOAD_PUSH,
    STORE_CHECK,
    STORE_READY,
    STORE_VALID,
    STORE_READY2,
    STORE_VALID2,
    ERROR
} statetype;

statetype state = IDLE;

CacheReq sdreq;
initial begin
    sdreq.valid = 1'b0;
    sdreq.wen = 0;
    sdreq.wmask = SIZE_W;
end

/*
load byte
-> 0-3 アラインしてload、調整
load half
-> 0-2 アラインしてload、調整
-> 3   2回load
load word
-> 0 1回load
-> 1-3 2回load
load dword
-> 0 2回load
-> 1-3 3回load
*/

// 下位2ビット
wire [1:0]  saddr_lb = sdreq.addr[1:0];
// アドレスの4byte アラインされている形
wire [31:0] saddr_aligned = {sdreq.addr[31:2], 2'b00};

wire [31:0] swdata = sdreq.wdata;
wire        sis_b = sdreq.wmask == SIZE_B;
wire        sis_h = sdreq.wmask == SIZE_H;
wire        sis_w = sdreq.wmask == SIZE_W;

// このstore命令はloadする必要があるか
wire require_load = (!sis_w | saddr_lb != 2'b00);
// この命令は2回loadする必要があるか
wire is_load_twice = (sis_w & saddr_lb != 2'b00) | (sis_h & saddr_lb == 2'd3);

UInt32  saved_rdata1;
UInt32  saved_rdata2;

UInt32  store_wdata1;
UInt32  store_wdata2;

UInt32  load_result;
logic   error_result = 0;
FaultTy errty_result = FE_ACCESS_FAULT;

assign memreq.valid = state == LOAD_READY  | state == LOAD_READY2 | state == STORE_READY | state == STORE_READY2;
assign memreq.addr  = state == LOAD_READY  | state == STORE_READY ? saddr_aligned : saddr_aligned + 32'd4;
assign memreq.wen   = state == STORE_READY | state == STORE_READY2;
assign memreq.wdata = state == STORE_READY ? store_wdata1 : store_wdata2;
assign memreq.pte   = sdreq.pte;

assign dresp.valid  =   state == LOAD_PUSH |
                        state == STORE_VALID & !is_load_twice & memresp.valid |
                        state == STORE_VALID2 & memresp.valid |
                        state == ERROR;
assign dresp.error  = error_result;
assign dresp.errty  = errty_result;
assign dresp.rdata  = load_result;

assign dreq.ready   = state == IDLE;

always @(posedge clk) if (reset) state <= IDLE; else begin
    case (state)
    IDLE: begin
        sdreq <= dreq;
        if (dreq.valid) begin
            state <= statetype'(dreq.wen ? STORE_CHECK : LOAD_READY);
        end
    end
    LOAD_READY: begin
        if (memreq.ready) begin
            state <= LOAD_VALID;
        end
    end
    LOAD_VALID: begin
        if (memresp.valid) begin
            error_result    <= memresp.error;
            errty_result    <= memresp.errty;
            if (memresp.error) begin
                state           <= ERROR;
            end else begin
                state           <= statetype'(is_load_twice ? LOAD_READY2 : LOAD_END);
                saved_rdata1    <= memresp.rdata;
            end
        end
    end
    LOAD_READY2: begin
        if (memreq.ready) begin
            state <= LOAD_VALID2;
        end
    end
    LOAD_VALID2: begin
        if (memresp.valid) begin
            error_result    <= memresp.error;
            errty_result    <= memresp.errty;
            if (memresp.error) begin
                state           <= ERROR;
            end else begin
                state           <= LOAD_END;
                saved_rdata2    <= memresp.rdata;
            end
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
        state <= IDLE;
    end
    STORE_CHECK: begin
        state <= statetype'(require_load ? LOAD_READY : STORE_READY);
        store_wdata1 <= sdreq.wdata; // すぐにSTORE_READYに行く場合のwdataの準備
    end
    STORE_READY: begin
        if (memreq.ready) begin
            state <= STORE_VALID;
        end
    end
    STORE_VALID: begin
        if (memresp.valid) begin
            error_result    <= memresp.error;
            errty_result    <= memresp.errty;
            if (memresp.error) begin
                state   <= ERROR;
            end else begin
                state   <= statetype'(is_load_twice ? STORE_READY2 : IDLE);
            end
        end
    end
    STORE_READY2: begin
        if (memreq.ready) begin
            state <= STORE_VALID2;
        end
    end
    STORE_VALID2: begin
        if (memresp.valid) begin
            error_result    <= memresp.error;
            errty_result    <= memresp.errty;
            if (memresp.error) begin
                state   <= ERROR;
            end else begin
                state   <= IDLE;
            end
        end
    end
    ERROR: state <= IDLE;
    default: begin
        $display("MemMisalignCntr.sv : Unknown state %d", state);
        `ffinish
    end
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,dmemucntr.state,d,%b", state);
    $display("data,dmemucntr.saved_rdata1,h,%b", saved_rdata1);
    $display("data,dmemucntr.saved_rdata2,h,%b", saved_rdata2);
    $display("data,dmemucntr.load_result,h,%b", load_result);
    $display("data,dmemucntr.saddr_lb,h,%b", saddr_lb);
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