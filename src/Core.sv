`default_nettype none

`include "include/ctrltype.sv"
`include "include/memoryinterface.sv"

// TODO reg_pcをpcにする
module Core #(
    parameter FMAX_MHz = 27
)(
    input wire          clk,
    input wire          exited,

    input wire [63:0]   reg_cycle,
    input wire [63:0]   reg_time,
    input wire [63:0]   reg_mtime,
    input wire [63:0]   reg_mtimecmp,

    inout wire IRequest             ireq,
    inout wire IResponse            iresp,
    output IUpdatePredictionIO  updateio,
    inout wire DRequest             dreq,
    inout wire DResponse            dresp,

    output reg          exit,
    output reg [31:0]   gp
);

`include "include/core.sv"

initial begin
    updateio.valid = 0;
end

wire [31:0] regfile[31:0];
assign gp   = regfile[3];

// 何クロック目かのカウント
reg [31:0] clk_count = 0;

wire ds_dh_stall;           // データハザードによるストール
wire ds_zifencei_stall_flg; // fence.i命令でストールするかのフラグ
wire exe_calc_stall;        // exeステージでストールしているかどうかのフラグ
wire csr_stall_flg;         // csrステージが止まってる
wire mem_memory_unit_stall; // メモリステージでメモリがreadyではないストール

// IF -> ID -> EXE (CSR) -> MEM -> WB
wire pipeline_kill = exited;

wire if_stall = id_stall;

// InstQueueの仕様として、branch_hazard = 1の時は
assign iresp.ready  = !pipeline_kill &&
                      !if_stall;

// 最後のクロックでの分岐ハザード状態
// このレジスタを介してireqすることで、EXEステージとinstqueueが直接つながらないようにする。
reg branch_hazard_last_clock        = 0;
reg [31:0] branch_target_last_clock = 32'h0;

// branchするとき(分岐予測に失敗したとき)はireq経由でリクエストする
// ireq.validをtrueにすると、キューがリセットされる。
assign ireq.valid   = branch_hazard_last_clock;
assign ireq.addr    = branch_target_last_clock;


always @(posedge clk) begin
    branch_hazard_last_clock <= branch_hazard_now;
    branch_target_last_clock <= branch_target;
end

// id reg
reg         id_valid = 0;
reg [31:0]  id_reg_pc;
reg [31:0]  id_inst;
reg [63:0]  id_inst_id;

// if -> id logic
always @(posedge clk) begin
    if (branch_hazard_now || branch_hazard_last_clock) begin
        id_valid    <= 0;
        `ifdef PRINT_DEBUGINFO
            $display("info,decodestage.event.pipeline_flush,pipeline flush");
        `endif
    end else if (!iresp.valid && !id_stall) begin
        id_valid    <= 0;
    end else if (iresp.valid && !id_stall) begin
        id_valid    <= 1;
        id_reg_pc   <= iresp.addr;
        id_inst     <= iresp.inst;
        id_inst_id  <= iresp.inst_id;
    end
end

// id ->ds wire
wire            id_ds_valid;
wire [31:0]     id_ds_reg_pc;
wire [31:0]     id_ds_inst;
wire [63:0]     id_ds_inst_id;
wire ctrltype   id_ds_ctrl;

wire            id_stall = id_valid && (ds_stall);

// ds reg
reg         ds_valid = 0;
reg [31:0]  ds_reg_pc;
reg [31:0]  ds_inst;
reg [63:0]  ds_inst_id;
ctrltype    ds_ctrl;

// id -> ds logic
always @(posedge clk) begin
    if (branch_hazard_now) begin
        ds_valid    <= 0;
        `ifdef PRINT_DEBUGINFO
            $display("info,datastage.event.pipeline_flush,pipeline flush");
        `endif
    end else if (id_stall && !ds_stall)
        ds_valid    <= 0;
    else if (!id_stall && !ds_stall) begin
        ds_valid    <= id_ds_valid;
        ds_reg_pc   <= id_ds_reg_pc;
        ds_inst     <= id_ds_inst;
        ds_inst_id  <= id_ds_inst_id;
        ds_ctrl     <= id_ds_ctrl;
    end
end

// ds -> exe wire
wire            ds_exe_valid;
wire [31:0]     ds_exe_reg_pc;
wire [31:0]     ds_exe_inst;
wire [63:0]     ds_exe_inst_id;
wire ctrltype   ds_exe_ctrl;

wire            ds_stall = ds_valid && (
                           exe_stall ||
                           ds_zifencei_stall_flg ||
                           ds_dh_stall);

// exe, csr reg
reg             exe_valid = 0;
reg [31:0]      exe_reg_pc;
reg [31:0]      exe_inst;
reg [63:0]      exe_inst_id;
ctrltype        exe_ctrl;

// ds -> exe logic
always @(posedge clk) begin
    if (branch_hazard_now && !exe_stall)
        exe_valid   <= 0;
    else if (ds_stall && !exe_stall)
        exe_valid   <= 0;
    else if (!ds_stall && !exe_stall) begin
        exe_valid   <= ds_exe_valid;
        exe_reg_pc  <= ds_exe_reg_pc;
        exe_inst    <= ds_exe_inst;
        exe_inst_id <= ds_exe_inst_id;
        exe_ctrl    <= ds_exe_ctrl;
    end
end

// exe -> mem wire
wire            exe_mem_valid;
wire [31:0]     exe_mem_reg_pc;
wire [31:0]     exe_mem_inst;
wire [63:0]     exe_mem_inst_id;
wire ctrltype   exe_mem_ctrl;
wire [31:0]     exe_mem_alu_out;

// exe,csr -> idのdatahazard
// exe->idを最長のパスにするわけにはいかない(それだとパイプラインの意味がない)
wire fw_ctrltype    exe_fw_ctrl;
assign exe_fw_ctrl.valid        = exe_valid && exe_ctrl.rf_wen == REN_S;
assign exe_fw_ctrl.can_forward  = 0;
assign exe_fw_ctrl.addr         = exe_ctrl.wb_addr;
assign exe_fw_ctrl.wdata        = 32'bz;

// exeで分岐予測の判定を行うため、idがvalidになるのを待つ
wire            exe_stall = exe_valid && (
                            (mem_valid && mem_stall) ||
                            exe_calc_stall ||
                            (exe_valid && !ds_valid) || 
                            csr_stall_flg);

// csr -> mem wire
wire [31:0]     csr_mem_csr_rdata;

// irespと比べるとcircular logicになるので注意
// TODO サイクル数を犠牲にしてクリティカルパスを短くする
wire            branch_fail   = ds_valid && exe_valid && (
                                    (exe_branch_taken && ds_reg_pc != exe_branch_target) ||
                                    (!exe_branch_taken && ds_reg_pc != exe_reg_pc + 4)
                                );
// CSRは必ずハザードを起こす
wire            csr_trap_fail = csr_csr_trap_flg;

wire            branch_hazard_now = !csr_stall_flg && (csr_trap_fail || branch_fail);
wire [31:0]     branch_target = csr_csr_trap_flg ? csr_trap_vector : 
                                exe_branch_taken ? exe_branch_target : exe_reg_pc + 4;

wire            exe_branch_taken;
wire [31:0]     exe_branch_target;

wire            csr_csr_trap_flg;
wire [31:0]     csr_trap_vector;

// mem reg
reg             mem_valid = 0;
reg [31:0]      mem_reg_pc;
reg [31:0]      mem_inst;
reg [63:0]      mem_inst_id;
ctrltype        mem_ctrl;
reg [31:0]      mem_alu_out;
reg [31:0]      mem_csr_rdata;

// exe -> mem logic
always @(posedge clk) begin
    // exeがストールしていても、メモリがストールしていないならinvalidにして流す
    if (exe_stall && !mem_stall)
        mem_valid       <= 0;
    else if (!exe_stall && !mem_stall) begin
        mem_valid       <= exe_mem_valid;
        mem_reg_pc      <= exe_mem_reg_pc;
        mem_inst        <= exe_mem_inst;
        mem_inst_id     <= exe_mem_inst_id;
        mem_ctrl        <= exe_mem_ctrl;
        mem_alu_out     <= exe_mem_alu_out;
        mem_csr_rdata   <= csr_mem_csr_rdata; 
    end
end

reg [63:0]      exe_last_inst_id = 64'hffffffffffffffff;
// 分岐予測の更新
always @(posedge clk) begin
    if (exe_valid) exe_last_inst_id <= exe_inst_id;
    updateio.valid  <= exe_valid && exe_inst_id != exe_last_inst_id;
    updateio.pc     <= exe_reg_pc;
    updateio.is_br  <= exe_ctrl.jmp_pc_flg || exe_ctrl.jmp_reg_flg || exe_ctrl.br_exe != BR_X;
    updateio.taken  <= exe_branch_taken;
    updateio.target <= exe_branch_target;
end

// mem -> wb wire
wire            mem_wb_valid;
wire [31:0]     mem_wb_reg_pc;
wire [31:0]     mem_wb_inst;
wire [63:0]     mem_wb_inst_id;
wire ctrltype   mem_wb_ctrl;
wire [31:0]     mem_wb_alu_out;
wire [31:0]     mem_wb_mem_rdata;
wire [31:0]     mem_wb_csr_rdata;

// mem -> id のdatahazard
wire fw_ctrltype    mem_fw_ctrl;
assign mem_fw_ctrl.valid        = mem_valid && mem_ctrl.rf_wen == REN_S;
// メモリ命令ではないならフォワーディングできる
assign mem_fw_ctrl.can_forward  = mem_ctrl.wb_sel == WB_ALU ||
                                  mem_ctrl.wb_sel == WB_PC ||
                                  mem_ctrl.wb_sel == WB_CSR;
assign mem_fw_ctrl.addr         = mem_ctrl.wb_addr;
// wb_selによってフォワーディングする値が変わる
assign mem_fw_ctrl.wdata        = mem_ctrl.wb_sel == WB_PC ? mem_reg_pc + 4 :
                                  mem_ctrl.wb_sel == WB_CSR ? mem_csr_rdata :
                                  mem_alu_out;

wire            mem_stall   = mem_valid && (mem_memory_unit_stall);

// wb reg
reg             wb_valid    = 0;
reg [31:0]      wb_reg_pc;
reg [31:0]      wb_inst;
reg [63:0]      wb_inst_id;
ctrltype        wb_ctrl;
reg [31:0]      wb_alu_out;
reg [31:0]      wb_mem_rdata;
reg [31:0]      wb_csr_rdata;
wire [31:0]     wb_wdata_out;

// TODO メモリアクセスの例外はどう処理しようか....
//
// トラップ先を求めるためにCSRステージからワイヤを生やす。
// mem以前をinvalidにする。
// で、trapか...

// mem -> wb logic
always @(posedge clk) begin
    // WBステージは1サイクルで終わる
    if (mem_stall)
        wb_valid        <= 0;
    else begin
        wb_valid        <= mem_wb_valid;
        wb_reg_pc       <= mem_wb_reg_pc;
        wb_inst         <= mem_wb_inst;
        wb_inst_id      <= mem_wb_inst_id;
        wb_ctrl         <= mem_wb_ctrl;
        wb_alu_out      <= mem_wb_alu_out;
        wb_mem_rdata    <= mem_wb_mem_rdata;
        wb_csr_rdata    <= mem_wb_csr_rdata;
    end
end

// wb -> id のdatahazard
wire fw_ctrltype    wb_fw_ctrl;
assign wb_fw_ctrl.valid         = wb_valid && wb_ctrl.rf_wen == REN_S;
assign wb_fw_ctrl.can_forward   = 1;
assign wb_fw_ctrl.addr          = wb_ctrl.wb_addr;
assign wb_fw_ctrl.wdata         = wb_wdata_out;

DecodeStage #() decodestage
(
    .clk(clk),

    .id_valid(id_valid),
    .id_reg_pc(id_reg_pc),
    .id_inst(id_inst),
    .id_inst_id(id_inst_id),

    .id_ds_valid(id_ds_valid),
    .id_ds_reg_pc(id_ds_reg_pc),
    .id_ds_inst(id_ds_inst),
    .id_ds_inst_id(id_ds_inst_id),
    .id_ds_ctrl(id_ds_ctrl)
);

DataSelectStage #() dataselectstage
(
    .clk(clk),

    .regfile(regfile),

    .ds_valid(ds_valid),
    .ds_reg_pc(ds_reg_pc),
    .ds_inst(ds_inst),
    .ds_inst_id(ds_inst_id),
    .ds_ctrl(ds_ctrl),

    .ds_exe_valid(ds_exe_valid),
    .ds_exe_reg_pc(ds_exe_reg_pc),
    .ds_exe_inst(ds_exe_inst),
    .ds_exe_inst_id(ds_exe_inst_id),
    .ds_exe_ctrl(ds_exe_ctrl),

    .dh_stall_flg(ds_dh_stall),
    .dh_exe_fw(exe_fw_ctrl),
    .dh_mem_fw(mem_fw_ctrl),
    .dh_wb_fw(wb_fw_ctrl),

    .zifencei_stall_flg(ds_zifencei_stall_flg),
    .zifencei_mem_wen(1'b0)
    /*
    (mem_valid && (mem_ctrl.mem_wen == MEN_SB || mem_ctrl.mem_wen == MEN_SH || mem_ctrl.mem_wen == MEN_SW)) || 
    (exe_valid && (exe_ctrl.mem_wen == MEN_SB || exe_ctrl.mem_wen == MEN_SH || exe_ctrl.mem_wen == MEN_SW))
    */
);

ExecuteStage #() executestage
(
    .clk(clk),

    .exe_valid(exe_valid),
    .exe_reg_pc(exe_reg_pc),
    .exe_inst(exe_inst),
    .exe_inst_id(exe_inst_id),
    .exe_ctrl(exe_ctrl),

    .exe_mem_valid(exe_mem_valid),
    .exe_mem_reg_pc(exe_mem_reg_pc),
    .exe_mem_inst(exe_mem_inst),
    .exe_mem_inst_id(exe_mem_inst_id),
    .exe_mem_ctrl(exe_mem_ctrl),
    .exe_mem_alu_out(exe_mem_alu_out),

    .branch_taken(exe_branch_taken),
    .branch_target(exe_branch_target),

    .pipeline_flush(pipeline_kill),
    .calc_stall_flg(exe_calc_stall)
);

CSRStage #(
    .FMAX_MHz(FMAX_MHz)
) csrstage
(
    .clk(clk),

    .csr_valid(exe_valid),
    .csr_reg_pc(exe_reg_pc),
    .csr_inst(exe_inst),
    .csr_inst_id(exe_inst_id),
    .csr_ctrl(exe_ctrl),

    .csr_mem_csr_rdata(csr_mem_csr_rdata),
    
    .csr_stall_flg(csr_stall_flg),
    .csr_trap_flg(csr_csr_trap_flg),
    .csr_trap_vector(csr_trap_vector),

    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtime(reg_mtime),
    .reg_mtimecmp(reg_mtimecmp)
);

MemoryStage #() memorystage
(
    .clk(clk),

    .dreq(dreq),
    .dresp(dresp),

    .mem_valid(mem_valid),
    .mem_reg_pc(mem_reg_pc),
    .mem_inst(mem_inst),
    .mem_inst_id(mem_inst_id),
    .mem_ctrl(mem_ctrl),
    .mem_alu_out(mem_alu_out),
    .mem_csr_rdata(mem_csr_rdata),

    .mem_wb_valid(mem_wb_valid),
    .mem_wb_reg_pc(mem_wb_reg_pc),
    .mem_wb_inst(mem_wb_inst),
    .mem_wb_inst_id(mem_wb_inst_id),
    .mem_wb_ctrl(mem_wb_ctrl),
    .mem_wb_alu_out(mem_wb_alu_out),
    .mem_wb_mem_rdata(mem_wb_mem_rdata),
    .mem_wb_csr_rdata(mem_wb_csr_rdata),

    .pipeline_flush(pipeline_kill),
    .memory_unit_stall(mem_memory_unit_stall)
);

WriteBackStage #() wbstage(
    .clk(clk),

    .regfile(regfile),

    .wb_valid(wb_valid),
    .wb_reg_pc(wb_reg_pc),
    .wb_inst(wb_inst),
    .wb_inst_id(wb_inst_id),
    .wb_ctrl(wb_ctrl),
    .wb_alu_out(wb_alu_out),
    .wb_mem_rdata(wb_mem_rdata),
    .wb_csr_rdata(wb_csr_rdata),

    .wb_wdata_out(wb_wdata_out),
    .exit(exit)
);

`ifdef PRINT_DEBUGINFO
integer reg_i;
always @(negedge clk) begin
    clk_count <= clk_count + 1;
    $display("clock,%d", clk_count);
    $display("data,core.if_stall,b,%b", if_stall);
    $display("data,core.id_stall,b,%b", id_stall);
    $display("data,core.ds_stall,b,%b", ds_stall);
    $display("data,core.exe_stall,b,%b", exe_stall);
    $display("data,core.mem_stall,b,%b", mem_stall);
    $display("data,core.gp,h,%b", gp);
    $display("data,core.exit,b,%b", exit);
    for (reg_i = 1; reg_i < 32; reg_i = reg_i + 1) begin
        $display("data,core.regfile[%d],h,%b", reg_i, regfile[reg_i]);
    end
end
`endif

endmodule