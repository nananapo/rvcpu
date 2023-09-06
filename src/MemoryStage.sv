module MemoryStage(
    input wire          clk,

    inout wire DReq     dreq,
    inout wire DResp    dresp,

    input wire          mem_valid,
    input wire Addr     mem_pc,
    input wire Inst     mem_inst,
    input wire IId      mem_inst_id,
    input wire Ctrl     mem_ctrl,
    input wire UIntX    mem_alu_out,
    input wire UIntX    mem_csr_rdata,
    input wire UIntX    mem_rs2_data,

    output wire         mem_wb_valid,
    output wire Addr    mem_wb_pc,
    output wire Inst    mem_wb_inst,
    output wire IId     mem_wb_inst_id,
    output wire Ctrl    mem_wb_ctrl,
    output wire UIntX   mem_wb_alu_out,
    output wire UIntX   mem_wb_mem_rdata,
    output wire UIntX   mem_wb_csr_rdata,

    output logic        memory_unit_stall,

    output wire         exit
);

`include "include/basicparams.svh"

typedef enum logic [1:0]
{
    IDLE,
    WAIT_READY,
    WAIT_VALID 
} statetype;

statetype state = IDLE;

wire Addr   pc          = mem_pc;
wire Inst   inst        = mem_inst;
wire IId    inst_id     = mem_inst_id;
wire Ctrl   ctrl        = mem_ctrl;
wire UIntX  rs2_data    = mem_rs2_data;
wire UIntX  alu_out     = mem_alu_out;

logic   is_cmd_executed = 0;
IId     saved_inst_id   = IID_RANDOM;
wire    may_start_m     = !is_cmd_executed || saved_inst_id != inst_id;

MemSel replace_mem_wen  = MEN_X;
wire MemSel mem_wen     = MemSel'(!mem_valid ? MEN_X : 
                                saved_inst_id != inst_id ? ctrl.mem_wen : replace_mem_wen);
wire MemSize mem_size   = ctrl.mem_size;

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

wire is_store   = mem_wen == MEN_S || (mem_wen == MEN_A && ctrl.a_sel == ASEL_SC);
wire is_load    = mem_wen == MEN_L || (mem_wen == MEN_A && ctrl.a_sel != ASEL_SC); // sc以外(lr, amo)は必ずloadする

wire memu_cmd_ready   = dreq.ready;
wire memu_valid       = dresp.valid;
wire UIntX memu_rdata = dresp.rdata;

assign dreq.valid   = state == WAIT_READY && mem_valid && may_start_m && mem_wen != MEN_X;
assign dreq.wen     = is_store;
assign dreq.addr    = alu_out;
assign dreq.wdata   =   ctrl.mem_wen != MEN_A ? rs2_data :
                        ctrl.a_sel == ASEL_SC ? rs2_data :
                        gen_amo_wdata(ctrl.a_sel, ctrl.sign_sel, saved_mem_rdata, rs2_data);
assign dreq.wmask   = mem_size;

assign memory_unit_stall = mem_valid && (state != IDLE || (may_start_m && mem_wen != MEN_X));

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

assign mem_wb_valid     = mem_valid;
assign mem_wb_pc        = mem_pc;
assign mem_wb_inst      = mem_inst;
assign mem_wb_inst_id   = mem_inst_id;
assign mem_wb_ctrl      = mem_ctrl;
assign mem_wb_alu_out   = mem_alu_out;
assign mem_wb_mem_rdata = gen_rdata(ctrl.mem_wen, ctrl.mem_size, ctrl.sign_sel, ctrl.a_sel, saved_mem_rdata, sc_succeeded);
assign mem_wb_csr_rdata = mem_csr_rdata;


`ifdef RISCV_TEST
    assign exit = mem_valid && is_store && alu_out == RISCVTESTS_EXIT_ADDR;
`else
    assign exit = 0;
`endif

always @(posedge clk) begin
    if (mem_valid)
        saved_inst_id <= inst_id;
end

always @(posedge clk) begin
    if (!mem_valid || mem_wen == MEN_X) begin
        state           <= IDLE;
        is_cmd_executed <= 0;
        replace_mem_wen <= MEN_X;
    end else case (state)
        WAIT_READY: begin
            if (memu_cmd_ready) begin
                if (is_store) begin
                    state           <= IDLE;
                    replace_mem_wen <= MEN_X;
                    is_cmd_executed <= 1;
                end else begin
                    state           <= WAIT_VALID;
                end
            end
        end
        WAIT_VALID: begin
            if (memu_valid) begin
                saved_mem_rdata <= memu_rdata;
                // A拡張で、LR, SCではないものはStoreする
                if (mem_wen == MEN_A && ctrl.a_sel != ASEL_LR && ctrl.a_sel != ASEL_SC) begin
                    state           <= WAIT_READY;
                    replace_mem_wen <= MEN_S;
                end else begin
                    state           <= IDLE;
                    is_cmd_executed <= 1;
                    replace_mem_wen <= MEN_X;
                end
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

`ifdef PRINT_MEMPERF
int memperf_counter = 0;
int clk_count = 0;
always @(posedge clk) begin
    memperf_counter += {31'b0, state == WAIT_READY || state == WAIT_VALID};
    if (clk_count % 10_000_000 == 0) begin
        $display("memperf : %d", memperf_counter);
        memperf_counter = 0;
    end
    clk_count += 1;
end
`endif

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,memstage.valid,b,%b", mem_valid);
    $display("data,memstage.state,d,%b", state);
    $display("data,memstage.inst_id,h,%b", mem_valid ? inst_id : IID_X);

    if (mem_valid) begin
        $display("data,memstage.pc,h,%b", pc);
        $display("data,memstage.inst,h,%b", inst);
        $display("data,memstage.alu_out,h,%b", alu_out);
        $display("data,memstage.rs2_data,h,%b", rs2_data);
        $display("data,memstage.mem_wen,d,%b", mem_wen);
        $display("data,memstage.mem_size,d,%b", mem_size);
        $display("data,memstage.is_load,b,%b", is_load);
        $display("data,memstage.is_store,b,%b", is_store);
        $display("data,memstage.reserved_addr,h,%b", aext_reserved_address);
        $display("data,memstage.memory_unit_stall,b,%b", memory_unit_stall);
        $display("data,memstage.output.read_data,h,%b", mem_wb_mem_rdata);
    end
end
`endif

endmodule