`include "pkg_util.svh"
`include "pkg_csr.svh"
`include "basic.svh"

module MemoryStage
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

`include "basicparams.svh"

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
        ASEL_AMO_SWAP:  gen_amo_wdata = rs2_data;
        ASEL_AMO_ADD:   gen_amo_wdata = mem_rdata + rs2_data;
        ASEL_AMO_XOR:   gen_amo_wdata = mem_rdata ^ rs2_data;
        ASEL_AMO_AND:   gen_amo_wdata = mem_rdata & rs2_data;
        ASEL_AMO_OR :   gen_amo_wdata = mem_rdata | rs2_data;
        ASEL_AMO_MIN:   gen_amo_wdata =  (sign_sel == OP_SIGNED ? $signed(mem_rdata) < $signed(rs2_data) : mem_rdata < rs2_data) ? mem_rdata : rs2_data;
        ASEL_AMO_MAX:   gen_amo_wdata = !(sign_sel == OP_SIGNED ? $signed(mem_rdata) < $signed(rs2_data) : mem_rdata < rs2_data) ? mem_rdata : rs2_data;
        default:        gen_amo_wdata = DATA_X;
    endcase
endfunction

statetype state = IDLE;

logic   is_cmd_executed = 0;

// TODO logic   is_wen_replaced = 0;
MemSel  replace_mem_wen = MEN_X;
wire MemSel mem_wen     =   MemSel'(is_cmd_executed ? MEN_X :
                                    state != IDLE ? replace_mem_wen : ctrl.mem_wen);

/*
# A拡張の扱い
予約できるのは1つのみ。
SCはstoreとして実行する。
LRはloadとして実行する。結果は常に成功とする

AMOは、最初はloadとして実行し、replace_mem_wenをMEN_Sにすることでstoreを実行する。常に成功する。
*/
Addr aext_reserved_address = ADDR_MAX; // TODO validを用意してXにする
wire sc_executable  = aext_reserved_address == alu_out; // SCを実行するかどうか
logic sc_succeeded  = 0;

wire is_store   = mem_wen == MEN_S | (mem_wen == MEN_A & ctrl.a_sel == ASEL_SC);
wire is_load    = mem_wen == MEN_L | (mem_wen == MEN_A & ctrl.a_sel != ASEL_SC); // sc以外(lr, amo)は必ずloadする

wire memu_cmd_ready   = dreq.ready;
wire memu_valid       = dresp.valid;
wire UIntX memu_rdata = dresp.rdata;

assign dreq.valid   = state == WAIT_READY & valid & !is_cmd_executed & mem_wen != MEN_X;
assign dreq.wen     = is_store;
assign dreq.addr    = alu_out;
assign dreq.wdata   =   ctrl.mem_wen != MEN_A ? rs2_data :
                        ctrl.a_sel == ASEL_SC ? rs2_data :
                        gen_amo_wdata(ctrl.a_sel, ctrl.sign_sel, saved_mem_rdata, rs2_data);
assign dreq.wmask   = ctrl.mem_size;

// MEN_Xは未定義
function is_store_cmd(
    input MemSel cmd,
    input AextSel asel
);
    is_store_cmd = !(cmd == MEN_L | cmd == MEN_A & asel == ASEL_LR);
endfunction

assign next_trapinfo.valid = ctrl.mem_wen == MEN_X ? trapinfo.valid : dresp.error;
assign next_trapinfo.cause =    ctrl.mem_wen == MEN_X ? trapinfo.cause :
                                dresp.error ? (
                                    dresp.errty == FE_ACCESS_FAULT ? (
                                        is_store_cmd(ctrl.mem_wen, ctrl.a_sel) ? CsrCause::STORE_AMO_ACCESS_FAULT : CsrCause::LOAD_ACCESS_FAULT
                                    ) : (
                                        is_store_cmd(ctrl.mem_wen, ctrl.a_sel) ? CsrCause::STORE_AMO_PAGE_FAULT : CsrCause::LOAD_PAGE_FAULT
                                    )
                                ): 0;

assign is_stall = valid & (state != IDLE | (!is_cmd_executed & mem_wen != MEN_X));

UIntX  saved_mem_rdata;

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
            ASEL_LR: gen_rdata = mem_rdata;
            ASEL_SC: gen_rdata = sc_succeeded ? DATA_ZERO : {{XLEN-1{1'b0}}, 1'b1};
            default: gen_rdata = mem_rdata; // AMO : read-modify-write
        endcase
    end else begin
        case ({sign_sel, mem_size})
            {OP_SIGNED  , SIZE_B}: gen_rdata = {{24{mem_rdata[7]}}, mem_rdata[7:0]}; // lb
            {OP_SIGNED  , SIZE_H}: gen_rdata = {{16{mem_rdata[15]}}, mem_rdata[15:0]}; // lh
            {OP_SIGNED  , SIZE_W}: gen_rdata = mem_rdata; // lw
            {OP_UNSIGNED, SIZE_B}: gen_rdata = {24'b0, mem_rdata[7:0]}; // lbu
            {OP_UNSIGNED, SIZE_H}: gen_rdata = {16'b0, mem_rdata[15:0]}; // lhu
            default: gen_rdata = DATA_X;
        endcase
    end
endfunction

assign next_mem_rdata = gen_rdata(ctrl.mem_wen, ctrl.mem_size, ctrl.sign_sel, ctrl.a_sel, saved_mem_rdata, sc_succeeded);

always @(posedge clk) begin
    if (!valid | mem_wen == MEN_X) begin
        state           <= IDLE;
        is_cmd_executed <= 0;
        replace_mem_wen <= MEN_X;
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
        WAIT_RVALID: begin
            if (memu_valid) begin
                saved_mem_rdata <= memu_rdata;
                // A拡張で、LR, SCではないものはStoreする
                if (mem_wen == MEN_A & ctrl.a_sel != ASEL_LR & ctrl.a_sel != ASEL_SC) begin
                    state           <= WAIT_READY;
                    replace_mem_wen <= MEN_S;
                end else begin
                    state           <= IDLE;
                    is_cmd_executed <= 1;
                    replace_mem_wen <= MEN_X;
                end
            end
        end
        WAIT_WVALID: begin
            if (memu_valid) begin
                state <= IDLE;
                is_cmd_executed <= 1;
                replace_mem_wen <= MEN_X;
            end
        end
        default/*IDLE*/: begin
            replace_mem_wen <= mem_wen;
            if (mem_wen != MEN_X) begin
                // A拡張
                if (mem_wen == MEN_A) begin
                    case (ctrl.a_sel)
                        ASEL_SC: begin
                            if (sc_executable) begin
                                // 予約されている場合はstore
                                state           <= WAIT_READY;
                                sc_succeeded    <= 1;
                            end else begin
                                // されていないなら終了
                                state           <= IDLE;
                                replace_mem_wen <= MEN_X;
                                sc_succeeded    <= 0;
                                is_cmd_executed <= 1;
                            end
                            aext_reserved_address   <= ADDR_MAX; // TODO invalidate
                        end
                        ASEL_LR: begin
                            aext_reserved_address   <= alu_out;
                            state                   <= WAIT_READY;
                        end
                        default: state <= WAIT_READY;
                    endcase
                end else begin
                    // LOAD, STORE
                    state <= WAIT_READY;
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
    $display("data,memstage.inst_id,h,%b", valid | invalid_by_trap ? info.inst_id : iid::X);
    if (valid) begin
        $display("data,memstage.pc,h,%b", info.pc);
        $display("data,memstage.inst,h,%b", info.inst);
        $display("data,memstage.alu_out,h,%b", alu_out);
        $display("data,memstage.rs2_data,h,%b", rs2_data);
        $display("data,memstage.mem_wen,d,%b", mem_wen);
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