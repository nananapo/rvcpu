// Sv32
module PageTableWalker #(
    parameter PAGESIZE_WIDTH = 12,
    parameter PTESIZE_WIDTH  = 2,
    parameter LOG_ENABLE = 0
) (
    input wire clk,

    inout wire CacheReq     preq,
    inout wire CacheResp    presp,
    inout wire CacheReq     memreq,
    inout wire CacheResp    memresp,

    input wire modetype     csr_mode,
    input wire [31:0]       csr_satp,

    // output wire error,
    input wire  kill
);

// 単純にするため、
// * IDLEからとりあえずREADYに遷移
typedef enum logic [2:0] {
    IDLE, WALK_READY, WALK_VALID, REQ_READY, REQ_VALID, REQ_END
} statetype;

wire       satp_mode = csr_satp[31];
wire [8:0] satp_asid = csr_satp[30:22];
wire [21:0] satp_ppn = csr_satp[21:0];

statetype state  = IDLE;
wire sv32_enable = csr_mode != M_MODE && satp_mode == 1;

wire        sv32_req_ready;
wire        sv32_req_valid;
wire [31:0] sv32_req_addr;
wire        sv32_resp_valid;
wire [31:0] sv32_resp_addr;
wire [31:0] sv32_resp_rdata;

assign preq.ready   = sv32_enable ? sv32_req_ready  : memreq.ready;
assign memreq.valid = sv32_enable ? sv32_req_valid  : preq.valid;
assign memreq.addr  = sv32_enable ? sv32_req_addr   : preq.addr;
assign memreq.wen   = sv32_enable ? s_req.wen       : preq.wen;
assign memreq.wdata = sv32_enable ? s_req.wdata     : preq.wdata;
assign presp.valid  = sv32_enable ? sv32_resp_valid : memresp.valid;
assign presp.rdata  = sv32_enable ? sv32_resp_rdata : memresp.rdata;

// preqがリクエストしたアドレス
CacheReq s_req;
// ページのレベル
logic [1:0]   level;
// 次にアクセスするアドレス
logic [33:0]  next_addr;
// 結果
logic [31:0]  result_rdata;
// 保存されたアドレスのvpn, offset
wire [9:0]  s_vpn1          = s_req.addr[31:22];
wire [9:0]  s_vpn0          = s_req.addr[21:12];
wire [11:0] s_page_offset   = s_req.addr[11:0];
// preqのvpn1 (IDLEで使う)
wire [9:0]  idleonly_vpn1   = preq.addr[31:22];
// D A G U X W R V
wire validonly_pte_R    = memresp.rdata[1];
wire validonly_pte_X    = memresp.rdata[3]; 
wire validonly_pte_V    = memresp.rdata[0];
wire [11:0] validonly_pte_ppn1 = memresp.rdata[31:20];
wire [9:0]  validonly_pte_ppn0 = memresp.rdata[19:10];
wire [21:0] validonly_pte_ppn  = memresp.rdata[31:10];

assign sv32_req_ready   = state == IDLE;
assign sv32_req_valid   = state == WALK_READY || state == REQ_READY;
assign sv32_req_addr    = next_addr[31:0];
assign sv32_resp_valid  = state == REQ_END;
assign sv32_resp_addr   = s_req.addr;
assign sv32_resp_rdata  = result_rdata;

always @(posedge clk) begin
if (kill)
    state <= IDLE;
else if (sv32_enable) begin
    case (state)
    IDLE: begin
        if (preq.valid) begin
            state   <= WALK_READY; 
            s_req   <= preq;
            // 5.3.2 step 3
            level   <= 1; // level = 2 - 1 = 1スタート
            next_addr <= {satp_ppn, 12'b0} + {22'b0, idleonly_vpn1, {PTESIZE_WIDTH{1'b0}}};
        end
    end
    WALK_READY: begin
        if (memreq.ready) begin
            state <= WALK_VALID;
        end
    end
    WALK_VALID: begin
        if (memresp.valid) begin
            if (validonly_pte_V) begin
                // 5.3.2 step 4
                // levelのチェックは例外を起こさない (まだ起こす仕組みが実装できない)
                // RかXが1ならPTEが見つかった
                // level == 11 (-1 or 2)ならアウト
                if (level == 2'b11 || validonly_pte_R || validonly_pte_X) begin
                    state <= REQ_READY;
                    // 5.3.2 step 8
                    // Sv32 physical address
                    // ppn[1], ppn[0], page offset
                    // 12    , 10    , 12
                    case (level)
                        2'b11,
                        2'b10: next_addr <= 34'b0; // 勝手な未定義動作 : 失敗したら0にする
                        2'b01: next_addr <= {validonly_pte_ppn1, s_vpn0, s_page_offset};
                        2'b00: next_addr <= {validonly_pte_ppn, s_page_offset};
                    endcase
                end else begin
                    state <= WALK_READY;
                    // 5.3.2 step 4
                    level <= level - 2'd1;
                    // 2回目は必ずvpn0
                    next_addr <= {validonly_pte_ppn, 12'b0} + {22'b0, s_vpn0, {PTESIZE_WIDTH{1'b0}}};
                end
            end else begin
                state       <= REQ_READY;
                next_addr   <= 34'b0; // 勝手な未定義動作 : 失敗したら0にする
            end
        end
    end
    REQ_READY: begin
        if (memreq.ready) begin
            state <= REQ_VALID;
        end
    end
    REQ_VALID: begin
        if (memresp.valid) begin
            state <= REQ_END;
            result_rdata <= memresp.rdata;
        end
    end
    default:/*REQ_END:*/ begin
        state <= IDLE;
    end
    endcase
end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (LOG_ENABLE) begin
    if (sv32_enable) begin
        $display("data,fetchstage.ptw.state,d,%b", state);
        $display("data,fetchstage.ptw.kill,b,%b", kill);
        $display("data,fetchstage.ptw.satp,h,%b", csr_satp);
        $display("data,fetchstage.ptw.mode,d,%b", csr_mode);
        $display("data,fetchstage.ptw.proc_pc,h,%b", state == IDLE ? preq.addr : s_req.addr);
        $display("data,fetchstage.ptw.next_addr,h,%b", next_addr[31:0]);

        // $display("data,fetchstage.ptw.memreq.ready,b,%b", memreq.ready);
        // $display("data,fetchstage.ptw.memreq.valid,b,%b", memreq.valid);
        // $display("data,fetchstage.ptw.memreq.addr,h,%b", memreq.addr);
        // $display("data,fetchstage.ptw.memresp.valid,b,%b", memresp.valid);
        // $display("data,fetchstage.ptw.memresp.rdata,h,%b", memresp.rdata);

        // $display("data,fetchstage.ptw.level,d,%b", level);
        // $display("data,fetchstage.ptw.pte.R,b,%b", validonly_pte_R);
        // $display("data,fetchstage.ptw.pte.X,b,%b", validonly_pte_X);
        // $display("data,fetchstage.ptw.pte.V,b,%b", validonly_pte_V);

        // $display("data,fetchstage.ptw.satp.ppn,h,%b", satp_ppn);
        // $display("data,fetchstage.ptw.pte.ppn[1],h,%b", validonly_pte_ppn1);
        // $display("data,fetchstage.ptw.pte.ppn[0],h,%b", validonly_pte_ppn0);
        // $display("data,fetchstage.ptw.pte.ppn,h,%b", validonly_pte_ppn);

        // $display("data,fetchstage.ptw.vpn[1],h,%b", s_vpn1);
        // $display("data,fetchstage.ptw.vpn[0],h,%b", s_vpn0);
    end
end
`endif

endmodule