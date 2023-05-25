`default_nettype none

module Core #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,

    input wire [63:0]   reg_cycle,
    input wire [63:0]   reg_time,
    input wire [63:0]   reg_mtime,
    input wire [63:0]   reg_mtimecmp,
    
    output reg          memory_inst_start,
    input  wire         memory_inst_ready,
    output reg  [31:0]  memory_i_addr,
    input  wire [31:0]  memory_inst,
    input  wire         memory_inst_valid,
    output reg          memory_d_cmd_start,
    output reg          memory_d_cmd_write,
    input  wire         memory_d_cmd_ready,
    output reg  [31:0]  memory_d_addr,
    output reg  [31:0]  memory_wdata,
    output reg  [31:0]  memory_wmask,
    input  wire [31:0]  memory_rdata,
    input  wire         memory_rdata_valid,

    output reg          exit,
    output reg [31:0]   gp,
    
    input wire          exited
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

// inst
wire [31:0] mem_inst;
wire [31:0] wb_inst;

// stage inst id
wire [63:0] exe_inst_id;
wire [63:0] mem_inst_id;
wire [63:0] wb_inst_id;

wire pipeline_flush = exited;

// if -> id wire
wire        if_valid = 0;
wire [31:0] if_reg_pc;
wire [31:0] if_inst;
wire [63:0] if_inst_id;

wire        if_stall =  id_stall;

// id reg
reg         id_valid = 0;
reg [31:0]  id_reg_pc;
reg [31:0]  id_inst;
reg [63:0]  id_inst_id;

// if -> id logic
always @(posedge clk) begin
    if (pipeline_flush) begin
        id_valid    <= 0;
    end else if (!if_stall) begin
        id_valid    <= if_valid;
        id_reg_pc   <= if_reg_pc;
        id_inst     <= if_inst;
        id_inst_id  <= if_inst_id;
    end
end

// id -> exe wire
wire            id_exe_valid;
wire [31:0]     id_exe_reg_pc;
wire [31:0]     id_exe_inst;
wire [63:0]     id_exe_inst_id;
ctrltype wire   id_exe_ctrl;

wire            id_stall = exe_stall ||
                           id_zifencei_stall_flg || id_dh_stall;

// exe, csr reg
reg             exe_valid = 0;
reg [31:0]      exe_reg_pc;
reg [31:0]      exe_inst;
reg [63:0]      exe_inst_id;
ctrltype reg    exe_ctrl;

// id -> exe logic
always @(posedge clk) begin
    if (pipeline_flush) begin
        exe_valid   <= 0;
    end else if (!id_stall) begin
        exe_valid   <= id_exe_valid;
        exe_reg_pc  <= id_exe_reg_pc;
        exe_inst    <= id_exe_inst;
        exe_inst_id <= id_exe_inst_id;
        exe_ctrl    <= id_exe_ctrl;
    end
end

// exe -> mem wire
wire            exe_mem_valid;
wire [31:0]     exe_mem_reg_pc;
wire [31:0]     exe_mem_inst;
wire [63:0]     exe_mem_inst_id;
ctrltype wire   exe_mem_ctrl;
wire [31:0]     exe_mem_alu_out;

wire            exe_stall = mem_stall ||
                            exe_calc_stall ||
                            csr_stall_flg;

// csr -> mem wire
wire [31:0]     csr_mem_csr_rdata;

// exe, csr -> if wire
wire            branch_hazard = !csr_stall_flg && (csr_trap_flg || exe_branch_hazard);
wire [31:0]     branch_target = csr_trap_flg ? csr_trap_vector : exe_branch_target;

wire            exe_branch_hazard;
wire [31:0]     exe_branch_target;

wire            csr_trap_flg;
wire [31:0]     csr_trap_vector;

// mem reg
reg             mem_valid = 0;
reg [31:0]      mem_reg_pc;
reg [31:0]      mem_inst;
reg [63:0]      mem_inst_id;
ctrltype reg    mem_ctrl;
reg [31:0]      mem_alu_out;
reg [31:0]      mem_csr_rdata;

// exe -> mem logic
always @(posedge clk) begin
    if (pipeline_flush) begin
        mem_valid   <= 0;
    end else if (!exe_stall) begin
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
ctrltype wire   mem_wb_ctrl;
wire [31:0]     mem_wb_alu_out;
wire [31:0]     mem_wb_mem_data;
wire [31:0]     mem_wb_csr_rdata;

wire            mem_stall   = mem_memory_unit_stall;

// wb reg
reg             wb_valid    = 0;
reg [31:0]      wb_reg_pc;
reg [31:0]      wb_inst;
reg [63:0]      wb_inst_id;
// ctrltype reg    wb_ctrl;
reg [31:0]      wb_alu_out;
reg [31:0]      wb_mem_data;
reg [31:0]      wb_csr_rdata;
reg [31:0]      wb_trap_vector;

// TODO メモリアクセスの例外はどう処理しようか....
//
// トラップ先を求めるためにCSRステージからワイヤを生やす。
// mem以前をinvalidにする。
// で、trapか...

// mem -> wb logic
always @(posedge clk) begin
    if (pipeline_flush) begin
        wb_valid   <= 0;
    end else if (!mem_stall) begin
        wb_valid        <= mem_wb_valid;
        wb_reg_pc       <= mem_wb_reg_pc;
        wb_inst         <= mem_wb_inst;
        wb_inst_id      <= mem_wb_inst_id;
        // wb_ctrl         <= mem_wb_ctrl;
        wb_alu_out      <= mem_wb_alu_out;
        wb_mem_data     <= mem_wb_mem_data;
        wb_csr_rdata    <= mem_wb_csr_rdata;
        wb_trap_vector  <= mem_wb_trap_vector;
    end
end

FetchStage #() fetchstage (
    .clk(clk),

    .mem_start(memory_inst_start),
    .mem_ready(memory_inst_ready),
    .mem_addr(memory_i_addr),
    .mem_data(memory_inst),
    .mem_data_valid(memory_inst_valid),

    .if_valid(if_valid),
    .if_reg_pc(if_reg_pc),
    .if_inst(if_inst),
    .if_inst_id(if_inst_id),

    .branch_hazard(branch_hazard || exited),
    .branch_target(branch_target),

    .if_stall_flg(if_stall)
);

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
    .dh_wb_valid(wb_valid),
    .dh_wb_rf_wen(wb_ctrl.rf_wen),
    .dh_wb_wb_addr(wb_ctrl.wb_addr),
    .dh_mem_valid(mem_valid),
    .dh_mem_rf_wen(mem_ctrl.rf_wen),
    .dh_mem_wb_addr(mem_ctrl.wb_addr),
    .dh_exe_valid(exe_valid),
    .dh_exe_rf_wen(exe_ctrl.rf_wen),
    .dh_exe_wb_addr(exe_ctrl.wb_addr),

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

    .pipeline_flush(pipeline_flush),
    .calc_stall_flg(exe_calc_stall)
);

CSRStage #(
    .FMAX_MHz(FMAX_MHz)
) csrstage
(
    .clk(clk),

    .csr_valid(mem_valid),
    .csr_reg_pc(mem_reg_pc),
    .csr_inst(mem_inst),
    .csr_inst_id(mem_inst_id),
    .csr_ctrl(mem_ctrl),

    .csr_mem_csr_rdata(csr_mem_csr_rdata),
    
    .csr_stall_flg(csr_stall_flg),
    .csr_trap_flg(csr_trap_flg),
    .csr_trap_vector(csr_trap_vector),

    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtime(reg_mtime),
    .reg_mtimecmp(reg_mtimecmp)
);

MemoryStage #() memorystage
(
    .clk(clk),

    .mem_valid(mem_valid),
    .mem_reg_pc(mem_reg_pc),
    .mem_inst(mem_inst),
    .mem_inst_id(mem_inst_id),
    .mem_ctrl(mem_ctrl),
    .mem_alu_out(mem_alu_out),

    .mem_wb_valid(mem_wb_valid),
    .mem_wb_reg_pc(mem_wb_reg_pc),
    .mem_wb_inst(mem_wb_inst),
    .mem_wb_inst_id(mem_wb_inst_id),
    .mem_wb_ctrl(mem_wb_ctrl),
    .mem_wb_alu_out(mem_wb_alu_out),
    .mem_wb_mem_data(mem_wb_mem_data),

    .pipeline_flush(pipeline_flush),
    .memory_unit_stall(mem_memory_unit_stall),

    .memu_cmd_start(memory_d_cmd_start),
    .memu_cmd_write(memory_d_cmd_write),
    .memu_cmd_ready(memory_d_cmd_ready),
    .memu_addr(memory_d_addr),
    .memu_wdata(memory_wdata),
    .memu_wmask(memory_wmask),
    .memu_rdata(memory_rdata),
    .memu_rdata_valid(memory_rdata_valid)
);

WriteBackStage #() wbstage(
    .clk(clk),

    .regfile(regfile),

    .wb_valid(wb_valid),
    .wb_reg_pc(wb_reg_pc),
    .wb_inst(wb_inst),
    .inst_id(wb_inst_id),
    // .wb_ctrl(wb_ctrl),
    .wb_alu_out(wb_alu_out),
    .wb_mem_data(wb_mem_data),
    .wb_csr_rdata(wb_csr_rdata),

    .exit(exit)
);

`ifdef PRINT_DEBUGINFO
integer reg_i;
always @(negedge clk) begin
    clk_count <= clk_count + 1;
    $display("clock,%d", clk_count);
    $display("data,core.gp,%b", gp);
    $display("data,core.exit,%b", exit);
    for (reg_i = 0; reg_i < 32; reg_i = reg_i + 1) begin
        $display("data,core.regfile[%d],%b", reg_i, regfile[reg_i]);
    end
end
`endif

endmodule