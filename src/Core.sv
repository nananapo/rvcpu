`default_nettype none

`include "include/ctrltype.sv"

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

    inout wire IRequest     ireq,
    inout wire IResponse    iresp,
    inout wire DRequest     dreq,
    inout wire DResponse    dresp,

    output reg          exit,
    output reg [31:0]   gp
);

`include "include/core.sv"

wire [31:0] regfile[31:0];
assign gp   = regfile[3];

// 何クロック目かのカウント
reg [31:0] clk_count = 0;

wire id_dh_stall;           // データハザードによるストール
wire id_zifencei_stall_flg; // fence.i命令でストールするかのフラグ
wire exe_calc_stall;        // exeステージでストールしているかどうかのフラグ
wire csr_stall_flg;         // csrステージが止まってる
wire mem_memory_unit_stall; // メモリステージでメモリがreadyではないストール

// IF -> ID -> EXE (CSR) -> MEM -> WB
wire pipeline_kill = exited;

// if -> id wire
wire if_stall = (id_valid && id_stall) || id_dh_stall;

assign iresp.ready  = !pipeline_kill &&
                      !if_stall;

// branchするとき(分岐予測に失敗したとき)はireq経由でリクエストする
// ireq.validをtrueにすると、キューがリセットされる。
assign ireq.valid   = branch_hazard;
assign ireq.addr    = branch_target;

// id reg
reg         id_valid = 0;
reg [31:0]  id_reg_pc;
reg [31:0]  id_inst;
reg [63:0]  id_inst_id;

// if -> id logic
always @(posedge clk) begin
    if (!if_stall || branch_hazard) begin
        if (!iresp.valid || branch_hazard)
            id_valid    <= 0;
        else begin
            id_valid    <= 1;
            id_reg_pc   <= iresp.addr;
            id_inst     <= iresp.inst;
            id_inst_id  <= iresp.inst_id;
        end
    end
end

// id -> exe wire
wire            id_exe_valid;
wire [31:0]     id_exe_reg_pc;
wire [31:0]     id_exe_inst;
wire [63:0]     id_exe_inst_id;
wire ctrltype   id_exe_ctrl;

wire            id_stall = (exe_valid && exe_stall) ||
                           id_zifencei_stall_flg;

// exe, csr reg
reg             exe_valid = 0;
reg [31:0]      exe_reg_pc;
reg [31:0]      exe_inst;
reg [63:0]      exe_inst_id;
ctrltype        exe_ctrl;

// id -> exe logic
always @(posedge clk) begin
    if (!id_stall) begin
        // データハザードか分岐ハザードで、かつストールしてないなら、invalidとして流す。
        if (id_dh_stall || branch_hazard)
            exe_valid   <= 0;
        else begin 
            exe_valid   <= id_exe_valid;
            exe_reg_pc  <= id_exe_reg_pc;
            exe_inst    <= id_exe_inst;
            exe_inst_id <= id_exe_inst_id;
            exe_ctrl    <= id_exe_ctrl;
        end
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

// exeで分岐が発生した場合、idがvalidになるのを待って判定する。
wire            exe_stall = (mem_valid && mem_stall) ||
                            exe_calc_stall ||
                            (exe_branch_hazard && !id_valid) || 
                            csr_stall_flg;

// csr -> mem wire
wire [31:0]     csr_mem_csr_rdata;

// 分岐予測判定のため && 簡単のために、id_validになるまでストールしている
// irespと比べるとcircular logicになるので注意
wire            branch_fail   = exe_branch_hazard &&
                                (id_valid ? id_reg_pc != exe_branch_target : 0);// 0なのはストールするから

wire            csr_trap_fail = csr_csr_trap_flg &&
                                (id_valid ? id_reg_pc != csr_trap_vector : 1);// 1なのはストールしないから

wire            branch_hazard = !csr_stall_flg && (csr_trap_fail || branch_fail);
wire [31:0]     branch_target = csr_csr_trap_flg ? csr_trap_vector : exe_branch_target;

wire            exe_branch_hazard;
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
    if (!exe_stall) begin
        mem_valid       <= exe_mem_valid;
        mem_reg_pc      <= exe_mem_reg_pc;
        mem_inst        <= exe_mem_inst;
        mem_inst_id     <= exe_mem_inst_id;
        mem_ctrl        <= exe_mem_ctrl;
        mem_alu_out     <= exe_mem_alu_out;
        mem_csr_rdata   <= csr_mem_csr_rdata; 
    end
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

wire            mem_stall   = mem_memory_unit_stall;

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
    if (!mem_stall) begin
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

    .regfile(regfile),

    .id_valid(id_valid),
    .id_reg_pc(id_reg_pc),
    .id_inst(id_inst),
    .id_inst_id(id_inst_id),

    .id_exe_valid(id_exe_valid),
    .id_exe_reg_pc(id_exe_reg_pc),
    .id_exe_inst(id_exe_inst),
    .id_exe_inst_id(id_exe_inst_id),
    .id_exe_ctrl(id_exe_ctrl),

    .dh_stall_flg(id_dh_stall),
    .dh_exe_fw(exe_fw_ctrl),
    .dh_mem_fw(mem_fw_ctrl),
    .dh_wb_fw(wb_fw_ctrl),

    .zifencei_stall_flg(id_zifencei_stall_flg),
    .zifencei_mem_wen(
        (mem_valid && (mem_ctrl.mem_wen == MEN_SB || mem_ctrl.mem_wen == MEN_SH || mem_ctrl.mem_wen == MEN_SW)) || 
        (exe_valid && (exe_ctrl.mem_wen == MEN_SB || exe_ctrl.mem_wen == MEN_SH || exe_ctrl.mem_wen == MEN_SW)))
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

    .branch_hazard(exe_branch_hazard),
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