module Stage_Mem
    import basic::*;
    import stageinfo::*;
    import meminf::*;
(
    input wire              clk,
    input wire              valid,
    input wire              is_new,
    input wire TrapInfo     trapinfo,
    input wire StageInfo    info,
    input wire Ctrl         ctrl,
    input wire UIntX        alu_out,
    input wire UIntX        rs2_data,

    output wire TrapInfo    next_trapinfo,
    output wire UIntX       next_mem_rdata,

    inout wire CacheReq     dreq,
    inout wire CacheResp    dresp,

    output logic            is_stall
    `ifdef PRINT_DEBUGINFO
        ,
        input wire          invalid_by_trap
    `endif
);

/*
MEM Stageの動作

基本方針 : L1 D$にヒットしない場合は、クロック数がかかってもいいので単純に書く

メモリ命令が来た時、
* 自然なアラインがされていない場合、すでにtrapとされているので無視する
* A拡張の命令の場合、state移動後にdreq.readyを確認して、Aの命令フラグを立ててdreq.validする。結果を待つ。
* L1 TLBにヒットした場合、ストールしない
*/

import conf::*;

typedef enum logic [1:0]
{
    IDLE,
    WAIT_READY,
    WAIT_RVALID,
    WAIT_WVALID
} statetype;

function [$bits(UIntX)-1:0] gen_amo_wdata(
    input AextSel   a_sel,
    input SignSel   sign_sel,
    input UIntX     mem_rdata,
    input UIntX     rs2_data
);
    case (a_sel)
        ASEL_AMO_SWAP:  return rs2_data;
        ASEL_AMO_ADD:   return mem_rdata + rs2_data;
        ASEL_AMO_XOR:   return mem_rdata ^ rs2_data;
        ASEL_AMO_AND:   return mem_rdata & rs2_data;
        ASEL_AMO_OR :   return mem_rdata | rs2_data;
        ASEL_AMO_MIN:   return  (sign_sel == OP_SIGNED ? $signed(mem_rdata) < $signed(rs2_data) : mem_rdata < rs2_data) ? mem_rdata : rs2_data;
        ASEL_AMO_MAX:   return !(sign_sel == OP_SIGNED ? $signed(mem_rdata) < $signed(rs2_data) : mem_rdata < rs2_data) ? mem_rdata : rs2_data;
        default:        return XLEN_X;
    endcase
endfunction

// TODO SIZE_D対応
function [$bits(WMask32)-1:0] gen_wmask(
    input Addr      addr,
    input MemSize   size
);
    case (addr[1:0])
    2'd0: return {size == SIZE_W, size == SIZE_W, size == SIZE_W | size == SIZE_H, 1'b1}; // 全部
    2'd1: return 4'b0010; // SIZE_Bのみ
    2'd2: return {size == SIZE_H, 1'b1, 2'b0}; // SIZE_B, H
    2'd3: return 4'b1000; // SIZE_Bのみ
    endcase
endfunction

// TODO SIZE_D対応
function [$bits(UInt32)-1:0] gen_default_wdata(
    input Addr      addr,
    input MemSize   size,
    input UInt32    wdata
);
    case (addr[1:0])
    2'd0: return wdata;
    2'd1: return {wdata[23:0], 8'bx};
    2'd2: return {wdata[15:0], 16'bx};
    2'd3: return {wdata[7:0], 24'bx};
    endcase
endfunction

statetype state = IDLE;

logic   is_cmd_executed = 0;

// TODO readyを飛ばしたら事故りそう
logic       is_replaced     = 0; // これはIDLEのときは無効
MemSel      replace_mem_sel = MEN_X;
wire MemSel mem_sel         = MemSel'(is_replaced & state != IDLE ? replace_mem_sel : ctrl.mem_sel);

/*
# A拡張の扱い
予約できるのは1つのみ。
SCはstoreとして実行する。
LRはloadとして実行する。結果は常に成功とする

AMOは、最初はloadとして実行し、replace_mem_selをMEN_Sにすることでstoreを実行する。常に成功する。
*/
Addr aext_reserved_address = XLEN_MAX; // TODO validを用意してXにする
wire sc_executable  = aext_reserved_address == alu_out; // SCを実行するかどうか
logic sc_succeeded  = 0;

wire is_store   = mem_sel == MEN_S | (mem_sel == MEN_A & ctrl.a_sel == ASEL_SC);
wire is_load    = mem_sel == MEN_L | (mem_sel == MEN_A & ctrl.a_sel != ASEL_SC); // sc以外(lr, amo)は必ずloadする

UIntX   saved_mem_rdata = 0;
logic   saved_error = 0;
FaultTy saved_errty = FE_ACCESS_FAULT;

wire memu_cmd_ready = dreq.ready;
wire memu_valid     = dresp.valid;
wire memu_error     =   state == IDLE ? (!is_new & is_cmd_executed & saved_error) :
                        (state == WAIT_RVALID | state == WAIT_WVALID) & dresp.valid & dresp.error;
wire FaultTy memu_errty  = FaultTy'(state == IDLE & !is_new ? saved_errty : dresp.errty);

// dreqに渡す用の4byteアラインされたアドレス
wire Addr aligned_addr = {alu_out[$bits(Addr)-1:2], 2'b0};

// TODO trapinfo.validのときに実行しないようにする
assign dreq.valid   = valid & state == WAIT_READY & !is_cmd_executed & mem_sel != MEN_X;
assign dreq.wen     = is_store;
assign dreq.addr    = aligned_addr;
assign dreq.wdata   =   ctrl.mem_sel != MEN_A ? gen_default_wdata(alu_out, ctrl.mem_size, rs2_data) :
                        ctrl.a_sel == ASEL_SC ? rs2_data : // MEN_AはSIZE_Wで、今のところ必ずアラインされている
                        gen_amo_wdata(ctrl.a_sel, ctrl.sign_sel, saved_mem_rdata, rs2_data);
assign dreq.wmask   =   ctrl.mem_sel == MEN_A ? 4'b1111 :
                        gen_wmask(alu_out, ctrl.mem_size);

// MEN_Xは未定義
function is_store_cmd(
    input MemSel cmd,
    input AextSel asel
);
    return !(cmd == MEN_L | cmd == MEN_A & asel == ASEL_LR);
endfunction



wire is_memtrap = valid & ctrl.mem_sel != MEN_X & memu_error;
assign next_trapinfo.valid =    trapinfo.valid | is_memtrap;
assign next_trapinfo.cause =    trapinfo.valid | !is_memtrap ? trapinfo.cause :
                                    memu_errty == FE_ACCESS_FAULT ? (
                                        is_store_cmd(ctrl.mem_sel, ctrl.a_sel) ? CsrCause::STORE_AMO_ACCESS_FAULT : CsrCause::LOAD_ACCESS_FAULT
                                    ) : (
                                        is_store_cmd(ctrl.mem_sel, ctrl.a_sel) ? CsrCause::STORE_AMO_PAGE_FAULT : CsrCause::LOAD_PAGE_FAULT
                                    );

assign is_stall = valid & ( state == IDLE & is_new & ctrl.mem_sel != MEN_X |
                            state != IDLE);

function [$bits(UIntX)-1:0] gen_rdata(
    input MemSel    mem_type,
    input MemSize   mem_size,
    input SignSel   sign_sel,
    input AextSel   a_sel,
    input UIntX     mem_rdata,
    input logic     sc_succeeded
);
    if (mem_type == MEN_A) begin
        case (a_sel)
            ASEL_LR: return mem_rdata;
            ASEL_SC: return sc_succeeded ? XLEN_ZERO : {{XLEN-1{1'b0}}, 1'b1};
            default: return mem_rdata; // AMO : read-modify-write
        endcase
    end else begin
        case ({sign_sel, mem_size})
            {OP_SIGNED  , SIZE_B}: return {{24{mem_rdata[7]}}, mem_rdata[7:0]}; // lb
            {OP_SIGNED  , SIZE_H}: return {{16{mem_rdata[15]}}, mem_rdata[15:0]}; // lh
            {OP_SIGNED  , SIZE_W}: return mem_rdata; // lw
            {OP_UNSIGNED, SIZE_B}: return {24'b0, mem_rdata[7:0]}; // lbu
            {OP_UNSIGNED, SIZE_H}: return {16'b0, mem_rdata[15:0]}; // lhu
            default: return XLEN_X;
        endcase
    end
endfunction

assign next_mem_rdata = gen_rdata(ctrl.mem_sel, ctrl.mem_size, ctrl.sign_sel, ctrl.a_sel, saved_mem_rdata, sc_succeeded);

always @(posedge clk) begin
    if (!valid | trapinfo.valid) begin // TOOD reset
        state           <= IDLE;
        saved_error     <= 0;
        is_replaced     <= 0;
        is_cmd_executed <= 0;
    end else case (state)
        WAIT_READY: begin
            if (memu_cmd_ready) begin
                if (is_store) begin
                    state   <= WAIT_WVALID;
                end else begin
                    state   <= WAIT_RVALID;
                end
            end
        end
        WAIT_RVALID: if (memu_valid) begin
            case (alu_out[1:0])
                2'd0: saved_mem_rdata <= dresp.rdata;
                2'd1: saved_mem_rdata <= {8'bx, dresp.rdata[31:8]};
                2'd2: saved_mem_rdata <= {16'bx, dresp.rdata[31:16]};
                2'd3: saved_mem_rdata <= {24'bx, dresp.rdata[31:24]};
            endcase
            saved_error     <= dresp.error;
            saved_errty     <= dresp.errty;
            if (dresp.error) begin
                state           <= IDLE;
                is_cmd_executed <= 1;
            end else begin
                // A拡張で、LR, SCではないものはStoreする
                if (mem_sel == MEN_A & ctrl.a_sel != ASEL_LR & ctrl.a_sel != ASEL_SC) begin
                    state           <= WAIT_READY;
                    is_replaced     <= 1;
                    replace_mem_sel <= MEN_S;
                end else begin
                    state           <= IDLE;
                    is_cmd_executed <= 1;
                end
            end
        end
        WAIT_WVALID: if (memu_valid) begin
            saved_error <= dresp.error;
            saved_errty <= dresp.errty;
            state       <= IDLE;
            is_cmd_executed <= 1;
        end
        default/*IDLE*/: if (is_new) begin
            is_replaced     <= 0;
            saved_error     <= 0;
            if (ctrl.mem_sel == MEN_X) begin
                is_cmd_executed <= 0;
            end else begin
                // A拡張
                if (ctrl.mem_sel == MEN_A) begin
                    case (ctrl.a_sel)
                        ASEL_SC: begin
                            if (sc_executable) begin
                                // 予約されている場合はstore
                                state           <= WAIT_READY;
                                sc_succeeded    <= 1;
                                is_cmd_executed <= 0;
                            end else begin
                                // されていないなら終了
                                state           <= IDLE;
                                sc_succeeded    <= 0;
                                is_cmd_executed <= 1;
                            end
                            aext_reserved_address   <= XLEN_MAX; // TODO invalidate
                        end
                        ASEL_LR: begin
                            aext_reserved_address   <= alu_out;
                            state                   <= WAIT_READY;
                            is_cmd_executed         <= 0;
                        end
                        default: begin
                            state           <= WAIT_READY;
                            is_cmd_executed <= 0;
                        end
                    endcase
                end else begin
                    // LOAD, STORE
                    state           <= WAIT_READY;
                    is_cmd_executed <= 0;
                end
            end
        end
    endcase
end

//////////////////////////////// ストールの割合を表示する /////////////////////
`ifdef PRINT_MEMPERF
int memperf_counter = 0;
int clk_count = 0;
always @(posedge clk) begin
    memperf_counter += {31'b0, is_stall};
    if (clk_count % 10_000_000 == 0) begin
        $display("memorystage.stall.ratio,%d", memperf_counter);
        memperf_counter = 0;
    end
    clk_count += 1;
end
`endif
/////////////////////////////////////////////////////////////////////////////

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,memstage.valid,b,%b", valid | invalid_by_trap);
    if (invalid_by_trap) begin
        $display("info,memstage.valid_but_invalid,this stage is invalid.");
    end
    $display("data,memstage.state,d,%b", state);
    $display("data,memstage.inst_id,h,%b", valid | invalid_by_trap ? info.id.id : iid::X);
    if (valid) begin
        $display("data,memstage.pc,h,%b", info.pc);
        $display("data,memstage.inst,h,%b", info.inst);
        $display("data,memstage.alu_out,h,%b", alu_out);
        $display("data,memstage.rs2_data,h,%b", rs2_data);
        $display("data,memstage.mem_sel,d,%b", mem_sel);
        $display("data,memstage.mem_size,d,%b", ctrl.mem_size);
        $display("data,memstage.is_load,b,%b", is_load);
        $display("data,memstage.is_store,b,%b", is_store);
        $display("data,memstage.reserved_addr,h,%b", aext_reserved_address);
        $display("data,memstage.is_stall,b,%b", is_stall);
        $display("data,memstage.output.read_data,h,%b", next_mem_rdata);
    end
end
`endif

endmodule