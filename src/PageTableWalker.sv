// Sv32
module PageTableWalker #(
    parameter PAGESIZE_WIDTH    = 12,
    parameter PTESIZE_WIDTH     = 2,
    parameter LOG_ENABLE        = 0,
    parameter LOG_AS            = "fetchstage",
    parameter EXECUTE_MODE      = 0
) (
    input wire clk,
    input wire reset,

    inout wire CacheReq     preq,
    inout wire CacheResp    presp,
    inout wire CacheReq     memreq,
    inout wire CacheResp    memresp,

    input wire modetype     mode,
    input wire [31:0]       satp,
    input wire              mxr,
    input wire              sum

`ifdef PRINT_DEBUGINFO
    ,
    input wire can_output_log
`endif
);


// 5.1.11
// MODE(1) | ASID(9) | PPN(22)
// Table 23
// MODE = 0 : Bare (物理アドレスと同じ), ASID, PPNも0にする必要がある
//            0ではないなら動作はUNSPECIFIED！こわいね
// MODE = 1 : Sv32, ページングが有効

// 単純にするため、
// * IDLEからとりあえずREADYに遷移
typedef enum logic [2:0] {
    IDLE,
    WALK_READY,
    WALK_VALID,
    REQ_READY,
    REQ_VALID,
    REQ_END,
    WAIT_SET_AD_READY
} statetype;

wire       satp_mode = satp[31];
wire [8:0] satp_asid = satp[30:22];
wire [21:0] satp_ppn = satp[21:0];

statetype state  = IDLE;
wire sv32_enable = mode != M_MODE & satp_mode == 1;

wire        sv32_req_ready;
wire        sv32_req_valid;
wire [31:0] sv32_req_addr;
wire        sv32_resp_valid;
wire [31:0] sv32_resp_addr;
wire [31:0] sv32_resp_rdata;
logic       sv32_resp_error = 0;
FaultTy     sv32_resp_errty = FE_ACCESS_FAULT;

assign preq.ready   = sv32_enable ? sv32_req_ready  : memreq.ready;
assign memreq.valid = sv32_enable ? sv32_req_valid  : preq.valid;
assign memreq.addr  = sv32_enable ? sv32_req_addr   : preq.addr;
assign memreq.wen   = !EXECUTE_MODE & (sv32_enable ? s_req.wen : preq.wen); // EXECUTE_MODEでは、必ずloadしかしない
assign memreq.wdata = sv32_enable ? s_req.wdata     : preq.wdata;
assign presp.valid  = sv32_enable ? sv32_resp_valid : memresp.valid;
assign presp.rdata  = sv32_enable ? sv32_resp_rdata : memresp.rdata;
assign presp.error  = sv32_enable ? sv32_resp_error : memresp.error;
assign presp.errty  = sv32_enable ? sv32_resp_errty : memresp.errty;

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

/*
X=W=R=0のとき、ポインタ
WritableなものはReadableである。
Reservedだと、faultが発生する。

X W R
0 0 0 Pointer to next level of page table.
0 0 1 Read-only page.
0 1 0 Reserved for future use.
0 1 1 Read-write page.
1 0 0 Execute-only page.
1 0 1 Read-execute page.
1 1 0 Reserved for future use.
1 1 1 Read-write-execute page.
*/
wire pte_V  = memresp.rdata[0]; // validかどうか
wire pte_R  = memresp.rdata[1]; // Readable
wire pte_W  = memresp.rdata[2]; // Writable
wire pte_X  = memresp.rdata[3]; // Executable
// U-modeでアクセスできるかどうか
// SUM=1のとき、S-modeでもアクセスできるようになる。
// SUMにかかわらず、S-modeはU=1なページを実行できない
wire pte_U  = memresp.rdata[4]; 
wire pte_G  = memresp.rdata[5]; // Global mappingが何かわからない
// キャッシュの実装の都合上、命令用のPTWはAを変更しない。Dは元から変更されない。
wire pte_A  = memresp.rdata[6]; // 最後にAが0にされてからアクセスされたかどうか
wire pte_D  = memresp.rdata[7]; // 最古にDが0にされてからwriteされたかどうか

wire is_leaf_node = !(!pte_R & !pte_W & !pte_X);

/*
ページサイズでアラインされているかをチェックする。
-> アライメントされていなかったらページフォルト

non-leaf PTEのD, A, Uは将来のために予約されているので、前方互換性のためにソフトウェア的に0にする必要がある。
予約されているので、0ではない場合は、ページフォルト

LR/SCはページをまたがってはいけない

ミスアラインされたstoreは一部成功したりするかもだけど、途中で失敗しても戻さなくてもOK?

Gはとりあえず実装しないので、faultを発生させる
*/

// PPN
wire [11:0] pte_ppn1    = memresp.rdata[31:20];
wire [9:0]  pte_ppn0    = memresp.rdata[19:10];
wire [21:0] pte_ppn     = memresp.rdata[31:10];

assign sv32_req_ready   = state == IDLE;
assign sv32_req_valid   = state == WALK_READY | state == REQ_READY | state == WAIT_SET_AD_READY;
assign sv32_req_addr    = next_addr[31:0];
assign sv32_resp_valid  = state == REQ_END;
assign sv32_resp_addr   = s_req.addr;
assign sv32_resp_rdata  = result_rdata;

UIntX   last_pte = 0;
Addr    last_addr= 0;
wire last_pte_A  = last_pte[6];
wire last_pte_D  = last_pte[7];

always @(posedge clk) if (reset) state <= IDLE; else if (sv32_enable) begin
    case (state)
    IDLE: begin
        if (preq.valid) begin
            state       <= WALK_READY;
            s_req       <= preq;
            // 5.3.2 step 3
            level       <= 1; // level = 2 - 1 = 1スタート
            next_addr   <= {satp_ppn, 12'b0} + {22'b0, idleonly_vpn1, {PTESIZE_WIDTH{1'b0}}};
        end
    end
    WALK_READY: if (memreq.ready) state <= WALK_VALID;
    WALK_VALID: if (memresp.valid) begin
        last_pte    <= memresp.rdata;
        last_addr   <= sv32_req_addr;
        // メモリがエラー
        // Vが立っていない
        // W=1なのにR=0
        // Gが立っている
        // leafではないのにAかDが立っている
        // EXECUTE, S-modeでpte_U
        // DATA, S-modeでpte_Uかつsum = 0
        // EXECUTE, leafで、Xが立っていない
        // DATA, leftでW, Rが立っていない
        // levelが3 => 1周してしまった
        // はaccess fault
        if (memresp.error |
            !pte_V |
            pte_W & (!pte_R) |
            pte_G |
            !is_leaf_node & (pte_A | pte_D) | 
            mode == S_MODE & EXECUTE_MODE & pte_U | 
            mode == S_MODE & !EXECUTE_MODE & pte_U & !sum |
            is_leaf_node & EXECUTE_MODE & !pte_X |
            is_leaf_node & !EXECUTE_MODE & (s_req.wen & !pte_W | !s_req.wen & !pte_R & (!mxr | !pte_X)) |
            level == 2'b11 | level == 2'b10
        ) begin
            state           <= REQ_END;
            sv32_resp_error <= 1;
            sv32_resp_errty <= FaultTy'(memresp.error ? FE_ACCESS_FAULT : FE_PAGE_FAULT);
        end else if (is_leaf_node) begin
            // 5.3.2 step 4
            state <= REQ_READY;
            // 5.3.2 step 8
            // Sv32 physical address
            // ppn[1], ppn[0], page offset
            // 12    , 10    , 12
            if (level == 2'b01)
                next_addr <= {pte_ppn1, s_vpn0, s_page_offset};
            else
                next_addr <= {pte_ppn, s_page_offset};
        end else begin
            state   <= WALK_READY;
            // 5.3.2 step 4
            level   <= level - 2'd1;
            // 2回目は必ずvpn0
            next_addr<= {pte_ppn, 12'b0} + {22'b0, s_vpn0, {PTESIZE_WIDTH{1'b0}}};
        end
    end
    REQ_READY: begin
        if (memreq.ready) begin
            state <= REQ_VALID;
        end
    end
    REQ_VALID: begin
        if (memresp.valid) begin
            state           <= REQ_END;
            result_rdata    <= memresp.rdata;
            sv32_resp_error <= memresp.error;
            sv32_resp_errty <= memresp.errty;
        end
    end
    REQ_END: begin
        if (EXECUTE_MODE | sv32_resp_error)
            state <= IDLE;
        else begin
            // A, Dを書き込む条件がそろっている
            if (!last_pte_A | s_req.wen & !last_pte_D) begin
                state       <= WAIT_SET_AD_READY;
                next_addr   <= {2'b0, last_addr};
                s_req.wen   <= 1;
                s_req.wdata <= last_pte | 
                                {25'b0, 1'b1, 6'b0} |       // A
                                {24'b0, s_req.wen, 7'b0};   // D
            end else begin
                state <= IDLE;
            end
        end
    end
    WAIT_SET_AD_READY: begin
        if (memreq.ready) begin
            state <= IDLE;
        end
    end
    default: state <= IDLE;
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (can_output_log) if (LOG_ENABLE) begin
    if (sv32_enable) begin
        $display("data,%s.ptw.state,d,%b", LOG_AS, state);
        $display("data,%s.ptw.reset,b,%b", LOG_AS, reset);
        $display("data,%s.ptw.satp,h,%b", LOG_AS, satp);
        $display("data,%s.ptw.mode,d,%b", LOG_AS, mode);
        $display("data,%s.ptw.proc_pc,h,%b", LOG_AS, state == IDLE ? preq.addr : s_req.addr);
        $display("data,%s.ptw.next_addr,h,%b", LOG_AS, next_addr[31:0]);

        $display("data,%s.ptw.memreq.ready,b,%b", LOG_AS, memreq.ready);
        $display("data,%s.ptw.memreq.valid,b,%b", LOG_AS, memreq.valid);
        $display("data,%s.ptw.memreq.addr,h,%b", LOG_AS, memreq.addr);
        $display("data,%s.ptw.memreq.wen,b,%b", LOG_AS, memreq.wen);
        $display("data,%s.ptw.memreq.wdata,h,%b", LOG_AS, memreq.wdata);
        $display("data,%s.ptw.memresp.valid,b,%b", LOG_AS, memresp.valid);
        $display("data,%s.ptw.memresp.rdata,h,%b", LOG_AS, memresp.rdata);

        $display("data,%s.ptw.level,d,%b", LOG_AS, level);
        $display("data,%s.ptw.pte.R,b,%b", LOG_AS, pte_R);
        $display("data,%s.ptw.pte.X,b,%b", LOG_AS, pte_X);
        $display("data,%s.ptw.pte.V,b,%b", LOG_AS, pte_V);

        $display("data,%s.ptw.satp.ppn,h,%b", LOG_AS, satp_ppn);
        $display("data,%s.ptw.pte.ppn[1],h,%b", LOG_AS, pte_ppn1);
        $display("data,%s.ptw.pte.ppn[0],h,%b", LOG_AS, pte_ppn0);
        $display("data,%s.ptw.pte.ppn,h,%b", LOG_AS, pte_ppn);

        $display("data,%s.ptw.vpn[1],h,%b", LOG_AS, s_vpn1);
        $display("data,%s.ptw.vpn[0],h,%b", LOG_AS, s_vpn0);
    end
end
`endif

endmodule