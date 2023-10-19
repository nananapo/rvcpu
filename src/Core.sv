`default_nettype none

module Core #(
    parameter FMAX_MHz = 27
)(
    input wire  clk,
    input wire  exited,

    input wire UInt64   reg_cycle,
    input wire UInt64   reg_time,
    input wire UInt64   reg_mtime,
    input wire UInt64   reg_mtimecmp,

    inout wire IReq     ireq,
    inout wire IResp    iresp,
    output BrInfo       brinfo,
    inout wire DReq     dreq,
    inout wire DResp    dresp,

    output wire CacheCntrInfo   cache_cntr,

    output logic    exit,
    output UIntX    gp
);

`include "csrparam.svh"
`include "basicparams.svh"

// id reg
logic       id_valid    = 0;
// TODO メモリエラーをnopかつvalidとして流す
TrapInfo    id_trap     = 0; // TODO assign
Addr        id_pc       = ADDR_X;
Inst        id_inst     = INST_NOP;
IId         id_inst_id;
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
logic       ds_is_new = 0;
logic       ds_valid = 0;
Addr        ds_pc;
TrapInfo    ds_trap = 0;
Inst        ds_inst;
IId         ds_inst_id;
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
logic       exe_is_new = 0;
logic       exe_valid = 0;
TrapInfo    exe_trap = 0;
Addr        exe_pc;
Inst        exe_inst;
IId         exe_inst_id;
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
logic       mem_is_new = 0;
logic       mem_valid = 0;
TrapInfo    mem_trap = 0;
Addr        mem_pc;
Inst        mem_inst;
IId         mem_inst_id;
Ctrl        mem_ctrl;
UIntX       mem_imm_i;
UIntX       mem_alu_out;
UIntX       mem_op1_data;
UIntX       mem_rs2_data;
// mem wire
wire        mem_memory_stall;
// mem -> csr wire
wire UIntX      mem_mem_rdata;
wire TrapInfo   mem_next_trap;

// csr reg
logic       csr_is_new = 0;
logic       csr_valid = 0;
TrapInfo    csr_trap = 0;
Addr        csr_pc;
Inst        csr_inst;
IId         csr_inst_id;
Ctrl        csr_ctrl;
UIntX       csr_imm_i;
UIntX       csr_alu_out;
UIntX       csr_op1_data;
UIntX       csr_mem_rdata;
// csr wire
wire        csr_cmd_stall;
wire        csr_is_trap;
wire        csr_keep_trap;
wire Addr   csr_trap_vector;
// csr -> wb wire
wire UIntX  csr_csr_rdata;

// wb reg
logic       wb_valid;
Addr        wb_pc;
Inst        wb_inst;
IId         wb_inst_id;
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

// for debug
assign gp = wb_regfile[3];

// id/dsがvalidではないか、branchに失敗したクロックは保持
wire exe_branch_stall = (!ds_valid && !id_valid && (exe_is_new || !exe_br_checked)) || branch_fail;

// stall
// 各ステージに新しく値を流してはいけないかどうか
wire csr_stall  = csr_cmd_stall;
wire mem_stall  = mem_memory_stall || (mem_valid && csr_stall);

wire exe_stall  =   exe_calc_stall ||
                    (exe_valid && mem_stall) ||
                    exe_branch_stall;// 分岐予測の判定用
wire ds_stall   = ds_datahazard || (ds_valid && exe_stall);
wire id_stall   = id_valid && ds_stall;
wire if_stall   = id_stall;

// IF Stage
assign iresp.ready  = !exited && !if_stall;

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

wire branch_fail            =   exe_valid && (exe_is_new || !exe_br_checked) &&
                                ( ds_valid ? (exe_branch_taken && ds_pc != exe_branch_target) || (!exe_branch_taken && ds_pc != exe_pc + 4)
                                : id_valid ? (exe_branch_taken && id_pc != exe_branch_target) || (!exe_branch_taken && id_pc != exe_pc + 4) : 1'b0 );
wire branch_hazard_now      =   csr_is_trap || branch_fail;
wire Addr  branch_target    =   csr_is_trap ? csr_trap_vector :
                                exe_branch_taken ? exe_branch_target : exe_pc + 4;

function is_ialigned(
    input Addr addr
);
  is_ialigned = addr[1:0] == 2'b00;
endfunction

always @(posedge clk) begin

    if (branch_hazard_now) begin
        exe_br_checked <= 1;
    end

    // if -> id
    if (branch_hazard_now || branch_hazard_last_clock) begin
        id_valid    <= 0;
        id_trap     <= 0;
        `ifdef PRINT_DEBUGINFO
            $display("info,decodestage.event.pipeline_flush,pipeline flush");
        `endif
    end else if (!id_stall) begin
        if (iresp.valid) begin
            id_valid        <= 1; // TODO この1はiresp.validにできるが....
            id_trap.valid   <= 0; // TODO if trap
            id_pc           <= iresp.addr;
            id_inst         <= iresp.inst;
            id_inst_id      <= iresp.inst_id;
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
        `ifdef PRINT_DEBUGINFO
            $display("info,datastage.event.pipeline_flush,pipeline flush");
        `endif
    end else if (ds_stall) begin
        ds_is_new   <= 0;
    end else begin
        ds_valid        <= id_valid;
        ds_is_new       <= 1;
        ds_pc           <= id_pc;
        ds_inst         <= id_inst;
        ds_inst_id      <= id_inst_id;
        ds_ctrl         <= id_ctrl;
        ds_imm_i        <= id_imm_i;
        ds_imm_s        <= id_imm_s;
        ds_imm_b        <= id_imm_b;
        ds_imm_j        <= id_imm_j;
        ds_imm_u        <= id_imm_u;
        ds_imm_z        <= id_imm_z;
        // trap
        ds_trap.valid   <= id_valid &&
                            (   id_trap.valid ||
                                id_is_illegal ||
                                id_ctrl.csr_cmd == CSR_ECALL ||
                                id_ctrl.csr_cmd == CSR_EBREAK);
        ds_trap.cause   <= id_trap.valid ? id_trap.cause : 
                            id_is_illegal ? CAUSE_ILLEGAL_INSTRUCTION :
                            id_ctrl.csr_cmd == CSR_ECALL ? CAUSE_ENVIRONMENT_CALL_FROM_U_MODE :
                            id_ctrl.csr_cmd == CSR_EBREAK ? CAUSE_BREAKPOINT : 0;
        // forwarding
        ds_fw.valid     <= id_valid && id_ctrl.rf_wen;
        ds_fw.fwdable   <= id_ctrl.wb_sel == WB_PC;
        ds_fw.addr      <= id_ctrl.wb_addr;
        ds_fw.wdata     <= id_pc + 4;
    end

    // ds -> exe
    if (csr_is_trap) begin
        exe_valid   <= 0;
        exe_is_new  <= 1;
        exe_trap    <= 0;
        exe_fw      <= 0;
        `ifdef PRINT_DEBUGINFO
            $display("info,exestage.event.pipeline_flush,pipeline flush");
        `endif
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
            exe_pc          <= ds_pc;
            exe_inst        <= ds_inst;
            exe_inst_id     <= ds_inst_id;
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
            exe_fw.valid    <= ds_valid && ds_fw.valid;
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
        `ifdef PRINT_DEBUGINFO
            $display("info,memstage.event.pipeline_flush,pipeline flush");
        `endif
    end else if (mem_stall) begin
        mem_is_new  <= 0;
    end else begin
        if (exe_calc_stall || exe_branch_stall) begin
            mem_valid   <= 0;
            mem_is_new  <= 1;
            mem_trap    <= 0;
            mem_fw      <= 0;
        end else begin
            mem_valid       <= exe_valid;
            mem_is_new      <= 1;
            mem_pc          <= exe_pc;
            mem_inst        <= exe_inst;
            mem_inst_id     <= exe_inst_id;
            mem_ctrl        <= exe_ctrl;
            mem_imm_i       <= exe_imm_i;
            mem_alu_out     <= exe_alu_out;
            mem_op1_data    <= exe_op1_data;
            mem_rs2_data    <= exe_rs2_data;
            // trap
            mem_trap.valid  <= exe_valid && (
                                exe_trap.valid ||
                                (exe_branch_taken && !is_ialigned(exe_branch_target)));
            mem_trap.cause  <= exe_trap.valid ? exe_trap.cause :
                                (exe_branch_taken && !is_ialigned(exe_branch_target)) ? CAUSE_INSTRUCTION_ADDRESS_MISALIGNED : 0;
            // forwarding
            mem_fw.valid    <= exe_valid && exe_fw.valid;
            mem_fw.fwdable  <= exe_fw.fwdable || exe_ctrl.wb_sel == WB_ALU;
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
            csr_pc          <= mem_pc;
            csr_inst        <= mem_inst;
            csr_inst_id     <= mem_inst_id;
            csr_ctrl        <= mem_ctrl;
            csr_imm_i       <= mem_imm_i;
            csr_alu_out     <= mem_alu_out;
            csr_mem_rdata   <= mem_mem_rdata;
            csr_op1_data    <= mem_op1_data;
            // trap
            csr_trap        <= mem_valid ? mem_next_trap : 0;
            // forwarding
            csr_fw.valid    <= mem_valid && mem_fw.valid;
            csr_fw.fwdable  <= mem_fw.fwdable || mem_ctrl.wb_sel == WB_MEM;
            csr_fw.addr     <= mem_fw.addr;
            csr_fw.wdata    <= mem_fw.fwdable ? mem_fw.wdata : mem_mem_rdata;
        end
    end

    // csr -> wb (no stall)
    if (csr_cmd_stall) begin
        wb_valid   <= 0;
        wb_fw      <= 0;
    end else begin
        wb_valid        <= csr_valid;
        wb_pc           <= csr_pc;
        wb_inst         <= csr_inst;
        wb_inst_id      <= csr_inst_id;
        wb_rf_wen       <= !csr_trap.valid && csr_ctrl.rf_wen; // trapの時は書き込まない
        wb_reg_addr     <= csr_ctrl.wb_addr;
        wb_wdata        <= csr_fw.fwdable ? csr_fw.wdata : csr_csr_rdata; // fwと等しい
        // forwarding
        wb_fw.valid     <= csr_valid;
        wb_fw.fwdable   <= 1;
        wb_fw.addr      <= csr_fw.addr;
        wb_fw.wdata     <= csr_fw.fwdable ? csr_fw.wdata : csr_csr_rdata;
    end
end

// ID Stage
IDecode #() idecode (
    .inst(id_inst),
    .is_illegal(id_is_illegal),
    .ctrl(id_ctrl)
);

ImmDecode #() immdecode (
    .inst(id_inst),
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
    .pc(ds_pc),
    .inst(ds_inst),
    .inst_id(ds_inst_id),
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
    .pc(exe_pc),
    .inst(exe_inst),
    .inst_id(exe_inst_id),
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

MemoryStage #() memorystage
(
    .clk(clk),
    .valid(
        mem_valid && 
        !csr_trap.valid &&
        csr_ctrl.csr_cmd != CSR_SRET &&
        csr_ctrl.csr_cmd != CSR_MRET &&
        !csr_ctrl.fence_i),
    .is_new(mem_is_new),
    .trapinfo(mem_trap),
    .pc(mem_pc),
    .inst(mem_inst),
    .inst_id(mem_inst_id),
    .ctrl(mem_ctrl),
    .alu_out(mem_alu_out),
    .rs2_data(mem_rs2_data),

    .next_trapinfo(mem_next_trap),
    .next_mem_rdata(mem_mem_rdata),

    .dreq(dreq),
    .dresp(dresp),

    .is_stall(mem_memory_stall),
    .exit(exit)
    
    `ifdef PRINT_DEBUGINFO
        ,
        .invalid_by_trap(
            mem_valid && (
            csr_trap.valid ||
            csr_ctrl.csr_cmd == CSR_SRET ||
            csr_ctrl.csr_cmd == CSR_MRET || 
            csr_ctrl.fence_i)
        )
    `endif
);

CSRStage #(
    .FMAX_MHz(FMAX_MHz)
) csrstage
(
    .clk(clk),

    .valid(csr_valid),
    .is_new(csr_is_new),
    .trapinfo(csr_trap),
    .pc(csr_pc),
    .inst(csr_inst),
    .inst_id(csr_inst_id),
    .ctrl(csr_ctrl),
    .imm_i(csr_imm_i),
    .op1_data(csr_op1_data),

    .next_csr_rdata(csr_csr_rdata),
    
    .is_stall(csr_cmd_stall),
    .csr_is_trap(csr_is_trap),
    .csr_keep_trap(csr_keep_trap),
    .trap_vector(csr_trap_vector),

    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtime(reg_mtime),
    .reg_mtimecmp(reg_mtimecmp),

    .cache_cntr(cache_cntr)
);

WriteBackStage #() wbstage(
    .clk(clk),

    .valid(wb_valid),
    .pc(wb_pc),
    .inst(wb_inst),
    .inst_id(wb_inst_id),
    .rf_wen(wb_rf_wen),
    .reg_addr(wb_reg_addr),
    .wdata(wb_wdata),
    
    .regfile(wb_regfile)
);

//////////////////////////////// 分岐情報を渡す ///////////////////////////////
// invalidで初期化
initial begin
    brinfo.valid = 0;
end
IId send_brinfo_exe_last = IID_RANDOM;
always @(posedge clk) begin
    if (exe_valid) send_brinfo_exe_last <= exe_inst_id;
    brinfo.valid    <=  exe_valid &&
                        exe_inst_id != send_brinfo_exe_last &&
                        (exe_ctrl.br_exe != BR_X || exe_ctrl.jmp_reg_flg);
    brinfo.pc       <= exe_pc;
    brinfo.is_br    <= exe_ctrl.br_exe != BR_X;
    brinfo.is_jmp   <= exe_ctrl.jmp_pc_flg || exe_ctrl.jmp_reg_flg;
    brinfo.taken    <= exe_branch_taken;
    brinfo.target   <= exe_branch_target;
end
/////////////////////////////////////////////////////////////////////////////

//////////////////////////////// 予測の成功率を表示する ///////////////////////
`ifdef PRINT_BRANCH_ACCURACY
int all_br_count = 0;
int all_inst_count = 0;
int fail_count = 0;
localparam COUNT = 1_000_000;
always @(posedge clk) begin
    if (exe_valid && exe_inst_id != send_brinfo_exe_last) begin
        if (all_inst_count >= COUNT) begin
            $display("MPKI : %d , %d%%", fail_count / (COUNT / 1000), (all_br_count - fail_count) * 100 / all_br_count);
            fail_count = 0;
            all_inst_count = 0;
            all_br_count = 0;
        end else begin
            if (exe_ctrl.br_exe != BR_X || exe_ctrl.jmp_reg_flg) begin
                fail_count += branch_fail ? 1 : 0;
                all_br_count += 1;
            end
            all_inst_count = all_inst_count + 1;
        end
    end
end
`endif
/////////////////////////////////////////////////////////////////////////////

`ifdef PRINT_DEBUGINFO
int clk_count = 0;
always @(negedge clk) begin
    clk_count <= clk_count + 1;
    $display("clock,%d", clk_count);

    $display("data,decodestage.trapinfo.valid,b,%b", id_trap.valid);
    $display("data,datastage.trapinfo.valid,b,%b", ds_trap.valid);
    $display("data,exestage.trapinfo.valid,b,%b", exe_trap.valid);
    $display("data,memstage.trapinfo.valid,b,%b", mem_trap.valid);
    $display("data,csrstage.trapinfo.valid,b,%b", csr_trap.valid);
end

always @(posedge clk) begin
    $display("data,decodestage.valid,b,%b", id_valid);
    $display("data,decodestage.inst_id,h,%b", id_valid ? id_inst_id : IID_X);
    if (id_valid) begin
        $display("data,decodestage.pc,h,%b", id_pc);
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
    $display("data,core.gp,h,%b", gp);
    $display("data,core.exit,b,%b", exit);
    `ifdef PRINT_REG
        for (int i = 1; i < 32; i++) begin
            $display("data,core.regfile[%d],h,%b", i, wb_regfile[i]);
        end
    `endif
end
`endif

endmodule