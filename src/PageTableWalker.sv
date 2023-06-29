// TLBはないです
module PageTableWalker
(
    input wire clk,

    inout wire IRequest     ireq,
    inout wire IResponse    iresp,
    inout wire IRequest     memreq,
    inout wire IResponse    memresp,

    input wire modetype     csr_mode,
    input wire [31:0]       csr_satp,
    input wire kill
);

localparam PAGESIZE_WIDTH = 12;
localparam PTESIZE_WIDTH  = 2;

// 単純にするため、
// * IDLEからとりあえずREADYに遷移
typedef enum reg [2:0] {
    IDLE, WALK_READY, WALK_VALID, IF_READY, IF_VALID, IF_END
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
wire [31:0] sv32_resp_inst;

assign ireq.ready    = sv32_enable ? sv32_req_ready : memreq.ready;
assign memreq.valid  = sv32_enable ? sv32_req_valid : ireq.valid;
assign memreq.addr   = sv32_enable ? sv32_req_addr  : ireq.addr;
// assign memresp.ready = sv32_enable ? sv32_resp_ready : iresp.ready; // ここでは使用していない
assign iresp.valid   = sv32_enable ? sv32_resp_valid : memresp.valid;
assign iresp.addr    = sv32_enable ? sv32_resp_addr  : memresp.addr;
assign iresp.inst    = sv32_enable ? sv32_resp_inst  : memresp.inst;
// assign iresp.inst_id = x // inst_idはInstQueueで設定する

// ireqがリクエストしたアドレス
reg [31:0]  s_req_addr;
// ページのレベル
reg [1:0]   level;
// 次にアクセスするアドレス
reg [33:0]  next_address;
// 結果
reg [31:0]  result_inst;
// 保存されたアドレスのvpn, offset
wire [9:0]  s_vpn1          = s_req_addr[31:22];
wire [9:0]  s_vpn0          = s_req_addr[21:12];
wire [11:0] s_page_offset   = s_req_addr[11:0];
// ireqのvpn1 (IDLEで使う)
wire [9:0]  idleonly_vpn1   = ireq.addr[31:22];
// D A G U X W R V
wire validonly_pte_R    = memresp.inst[1];
wire validonly_pte_X    = memresp.inst[3]; 
wire [11:0] validonly_pte_ppn1 = memresp.inst[31:20];
wire [9:0]  validonly_pte_ppn0 = memresp.inst[19:10];
wire [21:0] validonly_pte_ppn  = memresp.inst[31:10];

assign sv32_req_ready   = state == IDLE;
assign sv32_req_valid   = state == WALK_READY || state == IF_READY;
assign sv32_req_addr    = next_address[31:0];
assign sv32_resp_valid  = state == IF_END;
assign sv32_resp_addr   = s_req_addr;
assign sv32_resp_inst   = result_inst;

always @(posedge clk) begin
if (kill)
    state <= IDLE;
else if (sv32_enable) begin
    case (state)
    IDLE: begin
        if (ireq.valid) begin
            state       <=  WALK_READY; 
            s_req_addr  <= ireq.addr;
            // 5.3.2 step 3
            level       <= 1; // level = 2 - 1 = 1スタート
            next_address<= {satp_ppn, idleonly_vpn1, {PTESIZE_WIDTH{1'b0}}};
        end
    end
    WALK_READY: begin
        if (memreq.ready && memreq.valid) begin
            state <= WALK_VALID;
        end
    end
    WALK_VALID: begin
        if (memresp.valid) begin
            // 5.3.2 step 4
            // levelのチェックは例外を起こさない (まだ起こす仕組みが実装できない)
            // RかXが1ならPTEが見つかった
            // level == 11 (-1 or 2)ならアウト
            if (level == 2'b11 || validonly_pte_R || validonly_pte_X) begin
                state <= IF_READY;
                // 5.3.2 step 8
                // Sv32 physical address
                // ppn[1], ppn[0], page offset
                // 12    , 10    , 12
                if (level == 2'b11 || level == 2'b10)
                    next_address <= 34'b0; // ！！！勝手な未定義動作です！！！
                if (level == 2'b01)
                    next_address <= {validonly_pte_ppn1, s_vpn0, s_page_offset};
                if (level == 2'b00)
                    next_address <= {validonly_pte_ppn1, validonly_pte_ppn0, s_page_offset};
            end else begin
                // 5.3.2 step 4
                level <= level - 2'd1;
                // 2回目は必ずvpn0
                next_address <= {validonly_pte_ppn, s_vpn0, {PTESIZE_WIDTH{1'b0}}};
            end
        end
    end
    IF_READY: begin
        if (memreq.ready && memreq.valid) begin
            state <= IF_VALID;
        end
    end
    IF_VALID: begin
        if (memresp.valid) begin
            state <= IF_VALID;
            result_inst <= memresp.inst;
        end
    end
    default:/*IF_END:*/ begin
        state <= IDLE;
    end
    endcase
end
end

endmodule