`default_nettype none

`include "pkg_csr.svh"
`include "pkg_util.svh"
// TODO ステージの接続にinterfaceを多用したい

module Core (
    input wire  clk,

    inout wire IReq             ireq,
    inout wire IResp            iresp,
    output BrInfo               brinfo,
    inout wire CacheReq         dreq,
    inout wire CacheResp        dresp,

    input wire                  external_interrupt_pending,
    input wire                  mti_pending,

    output wire CacheCntrInfo   cache_cntr
);

`include "basicparams.svh"

// id reg
logic       id_valid    = 0;
StageInfo   id_info     = 0;
TrapInfo    id_trap     = 0;
// id wire
wire        id_is_illegal;
// id -> ds wire
wire Ctrl   id_ctrl;
wire UIntX  id_imm_i;
wire UIntX  id_imm_s;
wire UIntX  id_imm_b;
wire UIntX  id_imm_j;
wire UIntX  id_imm_u;
wire UIntX  id_imm_z;

// ds reg
logic       ds_is_new   = 0;
logic       ds_valid    = 0;
StageInfo   ds_info     = 0;
TrapInfo    ds_trap     = 0;
Ctrl        ds_ctrl;
UIntX       ds_imm_i;
UIntX       ds_imm_s;
UIntX       ds_imm_b;
UIntX       ds_imm_j;
UIntX       ds_imm_u;
UIntX       ds_imm_z;
// ds wire
wire        ds_datahazard; // datahazard
// ds -> exe wire
wire UIntX  ds_op1_data;
wire UIntX  ds_op2_data;
wire UIntX  ds_rs2_data;

// exe
logic       exe_is_new  = 0;
logic       exe_valid   = 0;
StageInfo   exe_info    = 0;
TrapInfo    exe_trap    = 0;
Ctrl        exe_ctrl;
UIntX       exe_imm_i;
UIntX       exe_imm_b;
UIntX       exe_imm_j;
UIntX       exe_op1_data;
UIntX       exe_op2_data;
UIntX       exe_rs2_data;
// exe wire
wire        exe_branch_taken;
wire Addr   exe_branch_target;
wire        exe_calc_stall;
// exe -> mem wire
wire UIntX  exe_alu_out;

// mem reg
logic       mem_is_new  = 0;
logic       mem_valid   = 0;
StageInfo   mem_info    = 0;
TrapInfo    mem_trap    = 0;
Ctrl        mem_ctrl;
UIntX       mem_imm_i;
UIntX       mem_alu_out;
UIntX       mem_op1_data;
UIntX       mem_rs2_data;
Addr        mem_btarget;
// mem wire
wire        mem_memory_stall;
// mem -> csr wire
wire UIntX      mem_mem_rdata;
wire TrapInfo   mem_next_trap;

// csr reg
logic       csr_is_new  = 0;
logic       csr_valid   = 0;
StageInfo   csr_info    = 0;
TrapInfo    csr_trap    = 0;
Ctrl        csr_ctrl;
UIntX       csr_imm_i;
UIntX       csr_alu_out;
UIntX       csr_op1_data;
UIntX       csr_mem_rdata;
Addr        csr_btarget;
// csr wire
wire        csr_cmd_stall;
wire        csr_is_trap;
wire        csr_keep_trap;
wire Addr   csr_trap_vector;
// csr -> wb wire
wire UIntX  csr_csr_rdata;
wire        csr_no_wb;

// wb reg
logic       wb_valid = 0;
StageInfo   wb_info;
logic       wb_rf_wen;
UInt5       wb_reg_addr;
UIntX       wb_wdata;
wire UIntX  wb_regfile[31:0];

// forwarding register
FwCtrl  ds_fw;
FwCtrl  exe_fw;
FwCtrl  mem_fw;
FwCtrl  csr_fw;
FwCtrl  wb_fw;

// id/dsがvalidではないか、branchに失敗したクロックは保持
wire exe_branch_stall = (!ds_valid & !id_valid & !exe_trap.valid & (exe_is_new | !exe_br_checked)) | branch_fail;

// stall
// 各ステージに新しく値を流してはいけないかどうか
wire csr_stall  = csr_cmd_stall;
wire mem_stall  = mem_memory_stall | (mem_valid & csr_stall);

wire exe_stall  =   exe_calc_stall |
                    (exe_valid & mem_stall) |
                    exe_branch_stall;// 分岐予測の判定用
wire ds_stall   = ds_datahazard | (ds_valid & exe_stall);
wire id_stall   = id_valid & ds_stall;
wire if_stall   = id_stall;

// IF Stage
assign iresp.ready  = !if_stall;

// 最後のクロックでの分岐ハザード状態
// このレジスタを介してireqすることで、EXE, CSRステージとinstqueueが直接つながらないようにする。
logic branch_hazard_last_clock  = 0;
UIntX branch_target_last_clock  = 32'h0;

// branchするとき(分岐予測に失敗したとき)はireq経由でリクエストする
// ireq.validをtrueにすると、キューがリセットされる。
assign ireq.valid   = branch_hazard_last_clock;
assign ireq.addr    = branch_target_last_clock;

always @(posedge clk) begin
    branch_hazard_last_clock <= branch_hazard_now;
    branch_target_last_clock <= branch_target;
end

// exeステージにある命令がすでに分岐チェックされたかどうか
// newか!checkedのとき、チェックする必要がある
// hazardが起きると1になり、命令がidに供給されると0に戻る
logic exe_br_checked = 0;

wire branch_fail            =   exe_valid & (exe_is_new | !exe_br_checked) &
                                ( ds_valid ? (exe_branch_taken & ds_info.pc != exe_branch_target) | (!exe_branch_taken & ds_info.pc != exe_info.pc + 4)
                                : id_valid ? (exe_branch_taken & id_info.pc != exe_branch_target) | (!exe_branch_taken & id_info.pc != exe_info.pc + 4) : 1'b0 );
wire branch_hazard_now      =   csr_is_trap | branch_fail;
wire Addr  branch_target    =   csr_is_trap ? csr_trap_vector :
                                exe_branch_taken ? exe_branch_target : exe_info.pc + 4;

always @(posedge clk) begin

    if (branch_hazard_now) begin
        exe_br_checked <= 1;
    end

    // if -> id
    if (branch_hazard_now | branch_hazard_last_clock) begin
        id_valid    <= 0;
        id_trap     <= 0;
        if (util::logEnabled())
            $display("info,decodestage.event.pipeline_flush,pipeline flush");
    end else if (!id_stall) begin
        if (iresp.valid) begin
            id_valid        <= 1;
            id_trap.valid   <= iresp.error;
            id_trap.cause   <= iresp.errty == FE_ACCESS_FAULT ?
                                CsrCause::INSTRUCTION_ACCESS_FAULT : CsrCause::INSTRUCTION_PAGE_FAULT;
            id_info.pc      <= iresp.addr;
            id_info.inst    <= iresp.inst;
            `ifdef PRINT_DEBUGINFO
            id_info.id      <= iresp.inst_id;
            `endif
            exe_br_checked  <= 0;
        end else begin
            id_valid    <= 0;
            id_trap     <= 0;
        end
    end

    // id -> ds
    if (branch_hazard_now) begin
        ds_valid    <= 0;
        ds_is_new   <= 1;
        ds_trap     <= 0;
        ds_fw       <= 0;
        if (util::logEnabled())
            $display("info,datastage.event.pipeline_flush,pipeline flush");
    end else if (ds_stall) begin
        ds_is_new   <= 0;
    end else begin
        ds_valid        <= id_valid;
        ds_is_new       <= 1;
        ds_info         <= id_info;
        ds_ctrl         <= id_ctrl;
        ds_imm_i        <= id_imm_i;
        ds_imm_s        <= id_imm_s;
        ds_imm_b        <= id_imm_b;
        ds_imm_j        <= id_imm_j;
        ds_imm_u        <= id_imm_u;
        ds_imm_z        <= id_imm_z;
        // trap
        ds_trap.valid   <= id_valid &
                            (   id_trap.valid |
                                id_is_illegal |
                                id_ctrl.csr_cmd == CSR_ECALL |
                                id_ctrl.csr_cmd == CSR_EBREAK);
        ds_trap.cause   <= id_trap.valid ? id_trap.cause :
                            id_is_illegal ? CsrCause::ILLEGAL_INSTRUCTION :
                            id_ctrl.csr_cmd == CSR_ECALL ? CsrCause::ENVIRONMENT_CALL_FROM_U_MODE :
                            id_ctrl.csr_cmd == CSR_EBREAK ? CsrCause::BREAKPOINT : 0;
        // forwarding
        ds_fw.valid     <= id_valid & id_ctrl.rf_wen;
        ds_fw.fwdable   <= id_ctrl.wb_sel == WB_PC;
        ds_fw.addr      <= id_ctrl.wb_addr;
        ds_fw.wdata     <= id_info.pc + 4;
    end

    // ds -> exe
    if (csr_is_trap) begin
        exe_valid   <= 0;
        exe_is_new  <= 1;
        exe_trap    <= 0;
        exe_fw      <= 0;
        if (util::logEnabled())
            $display("info,exestage.event.pipeline_flush,pipeline flush");
    end else if (exe_stall) begin
        exe_is_new  <= 0;
    end else begin
        if (ds_datahazard) begin
            exe_valid   <= 0;
            exe_is_new  <= 1;
            exe_trap    <= 0;
            exe_fw      <= 0;
        end else begin
            exe_valid       <= ds_valid;
            exe_is_new      <= 1;
            exe_info        <= ds_info;
            exe_ctrl        <= ds_ctrl;
            exe_imm_i       <= ds_imm_i;
            exe_imm_b       <= ds_imm_b;
            exe_imm_j       <= ds_imm_j;
            exe_op1_data    <= ds_op1_data;
            exe_op2_data    <= ds_op2_data;
            exe_rs2_data    <= ds_rs2_data;
            // trap
            exe_trap        <= ds_valid ? ds_trap : 0;
            // forwarding
            exe_fw.valid    <= ds_valid & ds_fw.valid;
            exe_fw.fwdable  <= ds_fw.fwdable;
            exe_fw.addr     <= ds_fw.addr;
            exe_fw.wdata    <= ds_fw.wdata;
        end
    end

    // exe -> mem
    if (csr_is_trap) begin
        mem_valid   <= 0;
        mem_is_new  <= 1;
        mem_trap    <= 0;
        mem_fw      <= 0;
        if (util::logEnabled())
            $display("info,memstage.event.pipeline_flush,pipeline flush");
    end else if (mem_stall) begin
        mem_is_new  <= 0;
    end else begin
        if (exe_calc_stall | exe_branch_stall) begin
            mem_valid   <= 0;
            mem_is_new  <= 1;
            mem_trap    <= 0;
            mem_fw      <= 0;
        end else begin
            mem_valid       <= exe_valid;
            mem_is_new      <= 1;
            mem_info        <= exe_info;
            mem_ctrl        <= exe_ctrl;
            mem_imm_i       <= exe_imm_i;
            mem_alu_out     <= exe_alu_out;
            mem_op1_data    <= exe_op1_data;
            mem_rs2_data    <= exe_rs2_data;
            // trap
            mem_trap.valid  <= exe_valid & (
                                exe_trap.valid |
                                (exe_branch_taken & !util::ialigned(exe_branch_target)));
            mem_trap.cause  <= exe_trap.valid ? exe_trap.cause :
                                (exe_branch_taken & !util::ialigned(exe_branch_target)) ? CsrCause::INSTRUCTION_ADDRESS_MISALIGNED : 0;
            mem_btarget     <= exe_branch_target;
            // forwarding
            mem_fw.valid    <= exe_valid & exe_fw.valid;
            mem_fw.fwdable  <= exe_fw.fwdable | exe_ctrl.wb_sel == WB_ALU;
            mem_fw.addr     <= exe_fw.addr;
            mem_fw.wdata    <= exe_fw.fwdable ? exe_fw.wdata : exe_alu_out;
        end
    end

    // mem -> csr
    if (csr_is_trap) begin
        csr_valid   <= csr_keep_trap;
        csr_is_new  <= 0;
        csr_trap    <= 0;
        csr_fw      <= 0;
    end else if (csr_stall) begin
        csr_is_new  <= 0;
    end else begin
        if (mem_memory_stall) begin
            csr_valid       <= csr_keep_trap;
            csr_is_new      <= 0;
            csr_trap        <= 0;
            csr_fw          <= 0;
        end else begin
            csr_valid       <= mem_valid;
            csr_is_new      <= 1;
            csr_info        <= mem_info;
            csr_ctrl        <= mem_ctrl;
            csr_imm_i       <= mem_imm_i;
            csr_alu_out     <= mem_alu_out;
            csr_mem_rdata   <= mem_mem_rdata;
            csr_op1_data    <= mem_op1_data;
            // trap
            csr_trap        <= mem_valid ? mem_next_trap : 0;
            csr_btarget     <= mem_btarget;
            // forwarding
            csr_fw.valid    <= mem_valid & mem_fw.valid;
            csr_fw.fwdable  <= mem_fw.fwdable | mem_ctrl.wb_sel == WB_MEM;
            csr_fw.addr     <= mem_fw.addr;
            csr_fw.wdata    <= mem_fw.fwdable ? mem_fw.wdata : mem_mem_rdata;
        end
    end

    // csr -> wb (no stall)
    if (csr_cmd_stall) begin
        wb_valid   <= 0;
        wb_fw      <= 0;
    end else begin
        wb_valid        <= !csr_no_wb & csr_valid;
        wb_info         <= csr_info;
        wb_rf_wen       <= !csr_trap.valid & csr_ctrl.rf_wen; // trapの時は書き込まない
        wb_reg_addr     <= csr_ctrl.wb_addr;
        wb_wdata        <= csr_fw.fwdable ? csr_fw.wdata : csr_csr_rdata; // fwと等しい
        // forwarding
        wb_fw.valid     <= csr_fw.valid & csr_valid;
        wb_fw.fwdable   <= 1;
        wb_fw.addr      <= csr_fw.addr;
        wb_fw.wdata     <= csr_fw.fwdable ? csr_fw.wdata : csr_csr_rdata;
    end
end

// ID Stage
IDecode #() idecode (
    .inst(id_info.inst),
    .is_illegal(id_is_illegal),
    .ctrl(id_ctrl)
);

ImmDecode #() immdecode (
    .inst(id_info.inst),
    .imm_i(id_imm_i),
    .imm_s(id_imm_s),
    .imm_b(id_imm_b),
    .imm_j(id_imm_j),
    .imm_u(id_imm_u),
    .imm_z(id_imm_z)
);

DataSelectStage #() dataselectstage
(
    .clk(clk),
    .regfile(wb_regfile),
    .valid(ds_valid),
    .is_new(ds_is_new),
    .info(ds_info),
    .ctrl(ds_ctrl),
    .imm_i(ds_imm_i),
    .imm_s(ds_imm_s),
    .imm_j(ds_imm_j),
    .imm_u(ds_imm_u),
    .imm_z(ds_imm_z),

    .next_op1_data(ds_op1_data),
    .next_op2_data(ds_op2_data),
    .next_rs2_data(ds_rs2_data),

    .is_datahazard(ds_datahazard),

    .fw_exe(exe_fw),
    .fw_mem(mem_fw),
    .fw_csr(csr_fw),
    .fw_wbk(wb_fw)
);

ExecuteStage #() executestage
(
    .clk(clk),
    .valid(exe_valid),
    .flush(1'b0),
    .is_new(exe_is_new),
    .info(exe_info),
    .ctrl(exe_ctrl),
    .imm_b(exe_imm_b),
    .imm_j(exe_imm_j),
    .op1_data(exe_op1_data),
    .op2_data(exe_op2_data),
    .rs2_data(exe_rs2_data),

    .next_alu_out(exe_alu_out),

    .branch_taken(exe_branch_taken),
    .branch_target(exe_branch_target),
    .is_stall(exe_calc_stall)
);

// TODO CSRでmstatus.MPRVを書き込む直後にMEM系があるときのタイミングがシビアなのをどうにかする
MemoryStage #() memorystage
(
    .clk(clk),
    .valid(
        mem_valid &
        !csr_trap.valid &
        csr_ctrl.csr_cmd != CSR_SRET &
        csr_ctrl.csr_cmd != CSR_MRET &
        !csr_ctrl.fence_i &
        !csr_ctrl.sfence &
        !csr_ctrl.svinval),
    .is_new(mem_is_new),
    .info(mem_info),
    .trapinfo(mem_trap),
    .ctrl(mem_ctrl),
    .alu_out(mem_alu_out),
    .rs2_data(mem_rs2_data),

    .next_trapinfo(mem_next_trap),
    .next_mem_rdata(mem_mem_rdata),

    .dreq(dreq),
    .dresp(dresp),

    .is_stall(mem_memory_stall)

    `ifdef PRINT_DEBUGINFO
        ,
        .invalid_by_trap(
            mem_valid & (
            csr_trap.valid |
            csr_ctrl.csr_cmd == CSR_SRET |
            csr_ctrl.csr_cmd == CSR_MRET |
            csr_ctrl.fence_i |
            csr_ctrl.sfence |
            csr_ctrl.svinval)
        )
    `endif
);

CSRStage #() csrstage (
    .clk(clk),

    .valid(csr_valid),
    .is_new(csr_is_new),
    .info(csr_info),
    .trapinfo(csr_trap),
    .ctrl(csr_ctrl),
    .imm_i(csr_imm_i),
    .op1_data(csr_op1_data),
    .alu_out(csr_alu_out),
    .btarget(csr_btarget),

    .next_csr_rdata(csr_csr_rdata),
    .next_no_wb(csr_no_wb),

    .is_stall(csr_cmd_stall),
    .csr_is_trap(csr_is_trap),
    .csr_keep_trap(csr_keep_trap),
    .trap_vector(csr_trap_vector),

    .external_interrupt_pending(external_interrupt_pending),
    .mip_mtip(mti_pending),

    .cache_cntr(cache_cntr)
);

WriteBackStage #() wbstage(
    .clk(clk),

    .valid(wb_valid),
    .info(wb_info),
    .rf_wen(wb_rf_wen),
    .reg_addr(wb_reg_addr),
    .wdata(wb_wdata),

    .regfile(wb_regfile)
);

//////////////////////////////// 分岐情報を渡す ///////////////////////////////
// invalidで初期化
initial brinfo.valid = 0;
always @(posedge clk) begin
    brinfo.valid    <=  exe_valid &
                        exe_is_new &
                        (exe_ctrl.br_exe != BR_X | exe_ctrl.jmp_reg_flg);
    brinfo.pc       <= exe_info.pc;
    brinfo.is_br    <= exe_ctrl.br_exe != BR_X;
    brinfo.is_jmp   <= exe_ctrl.jmp_pc_flg | exe_ctrl.jmp_reg_flg;
    brinfo.taken    <= exe_branch_taken;
    brinfo.target   <= exe_branch_target;
end
/////////////////////////////////////////////////////////////////////////////

//////////////////////////////// 予測の成功率を表示する ///////////////////////
`ifdef PRINT_BRANCH_ACCURACY
int all_br_count    = 0;
int all_inst_count  = 0;
int fail_count      = 0;
localparam COUNT    = 1_000_000;
always @(posedge clk) begin
    if (exe_valid & exe_is_new) begin
        if (all_inst_count >= COUNT) begin
            $display("MPKI : %d , %d%%", fail_count / (COUNT / 1000), (all_br_count - fail_count) * 100 / all_br_count);
            fail_count      = 0;
            all_inst_count  = 0;
            all_br_count    = 0;
        end else begin
            if (exe_ctrl.br_exe != BR_X | exe_ctrl.jmp_reg_flg) begin
                fail_count      += branch_fail ? 1 : 0;
                all_br_count    += 1;
            end
            all_inst_count = all_inst_count + 1;
        end
    end
end
`endif
/////////////////////////////////////////////////////////////////////////////

//////////////////////////////// バグの可能性がある怪しい挙動を補足する ////////
`ifdef DETECT_ABNORMAL_STALL

`ifndef ABNORMAL_STOP_THRESHOLD
    `define ABNORMAL_STOP_THRESHOLD 100000
    initial $display("WARNING : ABNORMAL_STOP_THRESHOLD is not set, default to %d", `ABNORMAL_STOP_THRESHOLD);
`endif

int abn_clk_count = 0;
always @(negedge clk)
    abn_clk_count++;

Addr last_ds_pc     = 0;
Addr last_exe_pc    = 0;
Addr last_mem_pc    = 0;
Addr last_csr_pc    = 0;

int ds_same_count   = 0;
int exe_same_count  = 0;
int mem_same_count  = 0;
int csr_same_count  = 0;

always @(posedge clk) begin
    ds_same_count  <= ds_info.pc  == last_ds_pc  ? ds_same_count  + 1 : 0;
    exe_same_count <= exe_info.pc == last_exe_pc ? exe_same_count + 1 : 0;
    mem_same_count <= mem_info.pc == last_mem_pc ? mem_same_count + 1 : 0;
    csr_same_count <= csr_info.pc == last_csr_pc ? csr_same_count + 1 : 0;

    last_ds_pc  <= ds_info.pc;
    last_exe_pc <= exe_info.pc;
    last_mem_pc <= mem_info.pc;
    last_csr_pc <= csr_info.pc;

    if (    ds_same_count  >= `ABNORMAL_STOP_THRESHOLD |
            exe_same_count >= `ABNORMAL_STOP_THRESHOLD |
            mem_same_count >= `ABNORMAL_STOP_THRESHOLD |
            csr_same_count >= `ABNORMAL_STOP_THRESHOLD ) begin
        $display("!!!FORCE STOP!!!");
        $display("[%d - %d clock]", abn_clk_count - `ABNORMAL_STOP_THRESHOLD, abn_clk_count);
        $display("name(valid) pc");
        $display(" id(%d) pc = %h", id_valid, id_info.pc);
        $display(" ds(%d) pc = %h, for %d clock", ds_valid, last_ds_pc , ds_same_count );
        $display("exe(%d) pc = %h, for %d clock", exe_valid, last_exe_pc, exe_same_count);
        $display("mem(%d) pc = %h, for %d clock", mem_valid, last_mem_pc, mem_same_count);
        $display("csr(%d) pc = %h, for %d clock", csr_valid, last_csr_pc, csr_same_count);
        $display(" wb(%d) pc = %h", wb_valid, wb_info.pc);
        `ffinish
    end
end
`endif
/////////////////////////////////////////////////////////////////////////////

`ifdef PRINT_DEBUGINFO
int clk_count = 0;
always @(negedge clk) begin
    clk_count <= clk_count + 1;
    if (util::logEnabled()) begin
        $display("clock,%d", clk_count);
        $display("data,decodestage.trapinfo.valid,b,%b", id_trap.valid);
        $display("data,datastage.trapinfo.valid,b,%b", ds_trap.valid);
        $display("data,exestage.trapinfo.valid,b,%b", exe_trap.valid);
        $display("data,memstage.trapinfo.valid,b,%b", mem_trap.valid);
        $display("data,csrstage.trapinfo.valid,b,%b", csr_trap.valid);
        $display("data,csrstage.csr_is_trap,b,%b", csr_is_trap);
        $display("data,exestage.branch_fail,b,%b", branch_fail);
    end
end

always @(posedge clk) if (util::logEnabled()) begin
    $display("data,decodestage.valid,b,%b", id_valid);
    $display("data,decodestage.inst_id,h,%b", id_valid ? id_inst_id : IID_X);
    if (id_valid) begin
        $display("data,decodestage.pc,h,%b", id_info.pc);
        $display("data,decodestage.inst,h,%b", id_inst);
        $display("data,decodestage.illegal,b,%b", id_is_illegal);
        $display("data,decodestage.decode.i_exe,d,%b", id_ctrl.i_exe);
        $display("data,decodestage.decode.br_exe,d,%b", id_ctrl.br_exe);
        $display("data,decodestage.decode.op1_sel,d,%b", id_ctrl.op1_sel);
        $display("data,decodestage.decode.op2_sel,d,%b", id_ctrl.op2_sel);
        $display("data,decodestage.decode.mem_wen,d,%b", id_ctrl.mem_wen);
        $display("data,decodestage.decode.mem_size,d,%b", id_ctrl.mem_size);
        $display("data,decodestage.decode.rf_wen,d,%b", id_ctrl.rf_wen);
        $display("data,decodestage.decode.wb_sel,d,%b", id_ctrl.wb_sel);
        $display("data,decodestage.decode.wb_addr,d,%b", id_ctrl.wb_addr);
        $display("data,decodestage.decode.csr_cmd,b,%b", id_ctrl.csr_cmd);
        $display("data,decodestage.decode.jmp_pc,d,%b", id_ctrl.jmp_pc_flg);
        $display("data,decodestage.decode.jmp_reg,d,%b", id_ctrl.jmp_reg_flg);
        $display("data,decodestage.decode.fence_i,d,%b", id_ctrl.fence_i);
        $display("data,decodestage.decode.sfence,d,%b", id_ctrl.sfence);
        $display("data,decodestage.decode.svinval,d,%b", id_ctrl.svinval);
        $display("data,decodestage.decode.imm_i,h,%b", id_imm_i);
        $display("data,decodestage.decode.imm_s,h,%b", id_imm_s);
        $display("data,decodestage.decode.imm_b,h,%b", id_imm_b);
        $display("data,decodestage.decode.imm_j,h,%b", id_imm_j);
        $display("data,decodestage.decode.imm_u,h,%b", id_imm_u);
        $display("data,decodestage.decode.imm_z,h,%b", id_imm_z);
    end

    $display("data,core.if_stall,b,%b", if_stall);
    $display("data,core.id_stall,b,%b", id_stall);
    $display("data,core.ds_stall,b,%b", ds_stall);
    $display("data,core.exe_stall,b,%b", exe_stall);
    $display("data,core.mem_stall,b,%b", mem_stall);
    $display("data,core.csr_stall,b,%b", csr_stall);
    `ifdef PRINT_REG
        for (int i = 1; i < 32; i++) begin
            $display("data,core.regfile[%d],h,%b", i, wb_regfile[i]);
        end
    `endif
end
`endif

endmodule