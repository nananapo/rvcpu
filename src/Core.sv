`default_nettype none

`include "include/ctrltype.sv"
`include "include/memoryinterface.sv"

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
    output IUpdatePredictionIO  updateio, // reg
    inout wire DRequest     dreq,
    inout wire DResponse    dresp,
    output wire modetype    csr_mode,
    output wire [31:0]      csr_satp,

    output reg          exit,
    output reg [31:0]   gp
);

`include "include/core.sv"

// id reg
reg             id_valid = 0;
reg [31:0]      id_pc;
reg [31:0]      id_inst;
iidtype         id_inst_id;

// id -> ds wire
wire            id_ds_valid   = id_valid;
wire [31:0]     id_ds_pc      = id_pc;
wire [31:0]     id_ds_inst    = id_inst;
wire iidtype    id_ds_inst_id = id_inst_id;
wire ctrltype   id_ds_ctrl;
wire [31:0]     id_ds_imm_i;
wire [31:0]     id_ds_imm_s;
wire [31:0]     id_ds_imm_b;
wire [31:0]     id_ds_imm_j;
wire [31:0]     id_ds_imm_u;
wire [31:0]     id_ds_imm_z;

// ds reg
reg             ds_valid = 0;
reg [31:0]      ds_pc;
reg [31:0]      ds_inst;
iidtype         ds_inst_id;
ctrltype        ds_ctrl;
reg [31:0]      ds_imm_i;
reg [31:0]      ds_imm_s;
reg [31:0]      ds_imm_b;
reg [31:0]      ds_imm_j;
reg [31:0]      ds_imm_u;
reg [31:0]      ds_imm_z;

// ds wire
wire            ds_dh_stall; // datahazard

// ds -> exe wire
wire            ds_exe_valid;
wire [31:0]     ds_exe_pc;
wire [31:0]     ds_exe_inst;
wire iidtype    ds_exe_inst_id;
wire ctrltype   ds_exe_ctrl;
wire [31:0]     ds_exe_imm_i;
wire [31:0]     ds_exe_imm_b;
wire [31:0]     ds_exe_imm_j;
wire [31:0]     ds_exe_op1_data;
wire [31:0]     ds_exe_op2_data;
wire [31:0]     ds_exe_rs2_data;

// exe, csr reg
reg             exe_valid = 0;
reg [31:0]      exe_pc;
reg [31:0]      exe_inst;
iidtype         exe_inst_id;
ctrltype        exe_ctrl;
reg [31:0]      exe_imm_i;
reg [31:0]      exe_imm_b;
reg [31:0]      exe_imm_j;
reg [31:0]      exe_op1_data;
reg [31:0]      exe_op2_data;
reg [31:0]      exe_rs2_data;

// exe wire
wire            exe_branch_taken;
wire [31:0]     exe_branch_target;
wire            exe_calc_stall;

// csr wire
wire            csr_csr_trap_flg;
wire [31:0]     csr_trap_vector;
wire            csr_stall_flg;

// exe -> mem wire
wire            exe_mem_valid;
wire [31:0]     exe_mem_pc;
wire [31:0]     exe_mem_inst;
wire iidtype    exe_mem_inst_id;
wire ctrltype   exe_mem_ctrl;
wire [31:0]     exe_mem_alu_out;
wire [31:0]     exe_mem_rs2_data;

// csr -> mem wire
wire [31:0]     csr_mem_csr_rdata;
wire            satp_change_hazard;

// mem reg
reg             mem_valid = 0;
reg [31:0]      mem_pc;
reg [31:0]      mem_inst;
iidtype         mem_inst_id;
ctrltype        mem_ctrl;
reg [31:0]      mem_alu_out;
reg [31:0]      mem_csr_rdata;
reg [31:0]      mem_rs2_data;

// mem wire
wire            mem_memory_unit_stall;

// mem -> wb wire
wire            mem_wb_valid;
wire [31:0]     mem_wb_pc;
wire [31:0]     mem_wb_inst;
wire iidtype    mem_wb_inst_id;
wire ctrltype   mem_wb_ctrl;
wire [31:0]     mem_wb_alu_out;
wire [31:0]     mem_wb_mem_rdata;
wire [31:0]     mem_wb_csr_rdata;

// wb reg
reg             wb_valid = 0;
reg [31:0]      wb_pc;
reg [31:0]      wb_inst;
iidtype         wb_inst_id;
ctrltype        wb_ctrl;
reg [31:0]      wb_alu_out;
reg [31:0]      wb_mem_rdata;
reg [31:0]      wb_csr_rdata;
wire [31:0]     wb_wdata_out;
wire [31:0]     wb_regfile[31:0];

// for debug
assign gp = wb_regfile[3];


// forwarding
wire fw_ctrltype exe_fw_ctrl;
wire fw_ctrltype mem_fw_ctrl;
wire fw_ctrltype wb_fw_ctrl;

// exeからフォワーディングはしない (パスが長くなる)
assign exe_fw_ctrl.valid        = exe_valid && exe_ctrl.rf_wen == REN_S;
assign exe_fw_ctrl.can_forward  = 0;
assign exe_fw_ctrl.addr         = exe_ctrl.wb_addr;
assign exe_fw_ctrl.wdata        = 32'bz;
// load命令ではないならフォワーディングできる
assign mem_fw_ctrl.valid        = mem_valid && mem_ctrl.rf_wen == REN_S;
assign mem_fw_ctrl.can_forward  = mem_ctrl.wb_sel == WB_ALU ||
                                  mem_ctrl.wb_sel == WB_PC ||
                                  mem_ctrl.wb_sel == WB_CSR;
assign mem_fw_ctrl.addr         = mem_ctrl.wb_addr;
// wb_selによってフォワーディングする値が変わる
assign mem_fw_ctrl.wdata        = mem_ctrl.wb_sel == WB_PC ? mem_pc + 4 :
                                  mem_ctrl.wb_sel == WB_CSR ? mem_csr_rdata :
                                  mem_alu_out;
assign wb_fw_ctrl.valid         = wb_valid && wb_ctrl.rf_wen == REN_S;
assign wb_fw_ctrl.can_forward   = 1;
assign wb_fw_ctrl.addr          = wb_ctrl.wb_addr;
assign wb_fw_ctrl.wdata         = wb_wdata_out;

// stall
wire if_stall   = id_stall;
wire id_stall   = id_valid && (ds_stall);
wire ds_stall   = ds_valid && (exe_stall || ds_dh_stall);
// exeで分岐予測の判定を行うため、idがvalidになるのを待つ
wire exe_stall  = exe_valid && (
                    (mem_valid && mem_stall) ||
                    exe_calc_stall ||
                    (!ds_valid && !id_valid) || 
                    csr_stall_flg);
wire mem_stall  = mem_valid && (mem_memory_unit_stall);



// IF Stage
assign iresp.ready  = !exited && !if_stall;

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
        id_pc       <= iresp.addr;
        id_inst     <= iresp.inst;
        id_inst_id  <= iresp.inst_id;
    end
end

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
        ds_pc       <= id_ds_pc;
        ds_inst     <= id_ds_inst;
        ds_inst_id  <= id_ds_inst_id;
        ds_ctrl     <= id_ds_ctrl;
        ds_imm_i    <= id_ds_imm_i;
        ds_imm_s    <= id_ds_imm_s;
        ds_imm_b    <= id_ds_imm_b;
        ds_imm_j    <= id_ds_imm_j;
        ds_imm_u    <= id_ds_imm_u;
        ds_imm_z    <= id_ds_imm_z;
    end
end

// ds -> exe logic
always @(posedge clk) begin
    if (branch_hazard_now && !exe_stall)
        exe_valid   <= 0;
    else if (ds_stall && !exe_stall)
        exe_valid   <= 0;
    else if (!csr_stall_flg && csr_csr_trap_flg)
        exe_valid   <= 0;
    else if (!ds_stall && !exe_stall) begin
        exe_valid   <= ds_exe_valid;
        exe_pc      <= ds_exe_pc;
        exe_inst    <= ds_exe_inst;
        exe_inst_id <= ds_exe_inst_id;
        exe_ctrl    <= ds_exe_ctrl;
        exe_imm_i   <= ds_exe_imm_i;
        exe_imm_b   <= ds_exe_imm_b;
        exe_imm_j   <= ds_exe_imm_j;
        exe_op1_data<= ds_exe_op1_data;
        exe_op2_data<= ds_exe_op2_data;
        exe_rs2_data<= ds_exe_rs2_data;
    end
end

wire branch_fail = exe_valid && (
                      ds_valid ?
                          (exe_branch_taken && ds_pc != exe_branch_target) || (!exe_branch_taken && ds_pc != exe_pc + 4)
                      : id_valid ?
                          (exe_branch_taken && id_pc != exe_branch_target) || (!exe_branch_taken && id_pc != exe_pc + 4)
                      : 1'b0
                    );

// csrはトラップするときに1クロックストールする
wire branch_hazard_now = !csr_stall_flg && (csr_csr_trap_flg || branch_fail || satp_change_hazard);
// 分岐ハザードよりもCSRのトラップを優先する
wire [31:0] branch_target = csr_csr_trap_flg ? csr_trap_vector : 
                            exe_branch_taken ? exe_branch_target : exe_pc + 4;

// exe -> mem logic
always @(posedge clk) begin
    // exeがストールしていても、memがストールしていないならinvalidにして流す
    if (exe_stall && !mem_stall)
        mem_valid       <= 0;
    else if (!exe_stall && !mem_stall) begin
        mem_valid       <= exe_mem_valid;
        mem_pc          <= exe_mem_pc;
        mem_inst        <= exe_mem_inst;
        mem_inst_id     <= exe_mem_inst_id;
        mem_ctrl        <= exe_mem_ctrl;
        mem_alu_out     <= exe_mem_alu_out;
        mem_csr_rdata   <= csr_mem_csr_rdata; 
        mem_rs2_data    <= exe_mem_rs2_data;
    end
end

// invalidで初期化
initial begin
    updateio.valid = 0;
end

iidtype exe_last_inst_id = INST_ID_RANDOM;
// 分岐情報を渡す
always @(posedge clk) begin
    if (exe_valid) exe_last_inst_id <= exe_inst_id;
    updateio.valid  <=  exe_valid &&
                        exe_inst_id != exe_last_inst_id &&
                        (exe_ctrl.br_exe != BR_X || exe_ctrl.jmp_reg_flg);
    updateio.pc     <= exe_pc;
    updateio.is_br  <= exe_ctrl.br_exe != BR_X;
    updateio.is_jmp <= exe_ctrl.jmp_pc_flg || exe_ctrl.jmp_reg_flg;
    updateio.taken  <= exe_branch_taken;
    updateio.target <= exe_branch_target;
end

// mem -> wb logic
always @(posedge clk) begin
    // WBステージは1サイクルで終わる
    if (mem_stall)
        wb_valid        <= 0;
    else begin
        wb_valid        <= mem_wb_valid;
        wb_pc           <= mem_wb_pc;
        wb_inst         <= mem_wb_inst;
        wb_inst_id      <= mem_wb_inst_id;
        wb_ctrl         <= mem_wb_ctrl;
        wb_alu_out      <= mem_wb_alu_out;
        wb_mem_rdata    <= mem_wb_mem_rdata;
        wb_csr_rdata    <= mem_wb_csr_rdata;
    end
end



// ID Stage
IDecode #() idecode (
    .inst(id_inst),
    .ctrl(id_ds_ctrl)
);

ImmDecode #() immdecode (
    .inst(id_inst),
    .imm_i(id_ds_imm_i),
    .imm_s(id_ds_imm_s),
    .imm_b(id_ds_imm_b),
    .imm_j(id_ds_imm_j),
    .imm_u(id_ds_imm_u),
    .imm_z(id_ds_imm_z)
);

DataSelectStage #() dataselectstage
(
    .clk(clk),

    .regfile(wb_regfile),

    .ds_valid(ds_valid),
    .ds_pc(ds_pc),
    .ds_inst(ds_inst),
    .ds_inst_id(ds_inst_id),
    .ds_ctrl(ds_ctrl),
    .ds_imm_i(ds_imm_i),
    .ds_imm_s(ds_imm_s),
    .ds_imm_b(ds_imm_b),
    .ds_imm_j(ds_imm_j),
    .ds_imm_u(ds_imm_u),
    .ds_imm_z(ds_imm_z),

    .ds_exe_valid(ds_exe_valid),
    .ds_exe_pc(ds_exe_pc),
    .ds_exe_inst(ds_exe_inst),
    .ds_exe_inst_id(ds_exe_inst_id),
    .ds_exe_ctrl(ds_exe_ctrl),
    .ds_exe_imm_i(ds_exe_imm_i),
    .ds_exe_imm_b(ds_exe_imm_b),
    .ds_exe_imm_j(ds_exe_imm_j),
    .ds_exe_op1_data(ds_exe_op1_data),
    .ds_exe_op2_data(ds_exe_op2_data),
    .ds_exe_rs2_data(ds_exe_rs2_data),

    .dh_stall_flg(ds_dh_stall),
    .dh_exe_fw(exe_fw_ctrl),
    .dh_mem_fw(mem_fw_ctrl),
    .dh_wb_fw(wb_fw_ctrl)
);

ExecuteStage #() executestage
(
    .clk(clk),

    .exe_valid(exe_valid),
    .exe_pc(exe_pc),
    .exe_inst(exe_inst),
    .exe_inst_id(exe_inst_id),
    .exe_ctrl(exe_ctrl),
    .exe_imm_b(exe_imm_b),
    .exe_imm_j(exe_imm_j),
    .exe_op1_data(exe_op1_data),
    .exe_op2_data(exe_op2_data),
    .exe_rs2_data(exe_rs2_data),

    .exe_mem_valid(exe_mem_valid),
    .exe_mem_pc(exe_mem_pc),
    .exe_mem_inst(exe_mem_inst),
    .exe_mem_inst_id(exe_mem_inst_id),
    .exe_mem_ctrl(exe_mem_ctrl),
    .exe_mem_alu_out(exe_mem_alu_out),
    .exe_mem_rs2_data(exe_mem_rs2_data),

    .branch_taken(exe_branch_taken),
    .branch_target(exe_branch_target),

    .calc_stall_flg(exe_calc_stall)
);

CSRStage #(
    .FMAX_MHz(FMAX_MHz)
) csrstage
(
    .clk(clk),

    .csr_valid(exe_valid),
    .csr_pc(exe_pc),
    .csr_inst(exe_inst),
    .csr_inst_id(exe_inst_id),
    .csr_ctrl(exe_ctrl),
    .csr_imm_i(exe_imm_i),
    .csr_op1_data(exe_op1_data),

    .csr_mem_csr_rdata(csr_mem_csr_rdata),
    
    .csr_stall_flg(csr_stall_flg),
    .csr_trap_flg(csr_csr_trap_flg),
    .csr_trap_vector(csr_trap_vector),

    .reg_cycle(reg_cycle),
    .reg_time(reg_time),
    .reg_mtime(reg_mtime),
    .reg_mtimecmp(reg_mtimecmp),

    .output_mode(csr_mode),
    .output_satp(csr_satp),
    .satp_change_hazard(satp_change_hazard)
);

MemoryStage #() memorystage
(
    .clk(clk),

    .dreq(dreq),
    .dresp(dresp),

    .mem_valid(mem_valid),
    .mem_pc(mem_pc),
    .mem_inst(mem_inst),
    .mem_inst_id(mem_inst_id),
    .mem_ctrl(mem_ctrl),
    .mem_alu_out(mem_alu_out),
    .mem_csr_rdata(mem_csr_rdata),
    .mem_rs2_data(mem_rs2_data),

    .mem_wb_valid(mem_wb_valid),
    .mem_wb_pc(mem_wb_pc),
    .mem_wb_inst(mem_wb_inst),
    .mem_wb_inst_id(mem_wb_inst_id),
    .mem_wb_ctrl(mem_wb_ctrl),
    .mem_wb_alu_out(mem_wb_alu_out),
    .mem_wb_mem_rdata(mem_wb_mem_rdata),
    .mem_wb_csr_rdata(mem_wb_csr_rdata),

    .memory_unit_stall(mem_memory_unit_stall)
);

WriteBackStage #() wbstage(
    .clk(clk),

    .regfile(wb_regfile),

    .wb_valid(wb_valid),
    .wb_pc(wb_pc),
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
always @(posedge clk) begin
    $display("data,decodestage.valid,b,%b", id_valid);
    $display("data,decodestage.inst_id,h,%b", id_valid ? id_inst_id : INST_ID_NOP);
    if (id_valid) begin
        $display("data,decodestage.pc,h,%b", id_pc);
        $display("data,decodestage.inst,h,%b", id_inst);
        $display("data,decodestage.decode.i_exe,d,%b", id_ds_ctrl.i_exe);
        $display("data,decodestage.decode.br_exe,d,%b", id_ds_ctrl.br_exe);
        $display("data,decodestage.decode.m_exe,d,%b", id_ds_ctrl.m_exe);
        $display("data,decodestage.decode.op1_sel,d,%b", id_ds_ctrl.op1_sel);
        $display("data,decodestage.decode.op2_sel,d,%b", id_ds_ctrl.op2_sel);
        $display("data,decodestage.decode.mem_wen,d,%b", id_ds_ctrl.mem_wen);
        $display("data,decodestage.decode.mem_size,d,%b", id_ds_ctrl.mem_size);
        $display("data,decodestage.decode.rf_wen,d,%b", id_ds_ctrl.rf_wen);
        $display("data,decodestage.decode.wb_sel,d,%b", id_ds_ctrl.wb_sel);
        $display("data,decodestage.decode.wb_addr,d,%b", id_ds_ctrl.wb_addr);
        $display("data,decodestage.decode.csr_cmd,d,%b", id_ds_ctrl.csr_cmd);
        $display("data,decodestage.decode.jmp_pc,d,%b", id_ds_ctrl.jmp_pc_flg);
        $display("data,decodestage.decode.jmp_reg,d,%b", id_ds_ctrl.jmp_reg_flg);
        $display("data,decodestage.decode.svinval,d,%b", id_ds_ctrl.svinval);
        $display("data,decodestage.decode.imm_i,h,%b", id_ds_imm_i);
        $display("data,decodestage.decode.imm_s,h,%b", id_ds_imm_s);
        $display("data,decodestage.decode.imm_b,h,%b", id_ds_imm_b);
        $display("data,decodestage.decode.imm_j,h,%b", id_ds_imm_j);
        $display("data,decodestage.decode.imm_u,h,%b", id_ds_imm_u);
        $display("data,decodestage.decode.imm_z,h,%b", id_ds_imm_z);
    end
end

reg [31:0] clk_count = 0;
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
    `ifdef PRINT_REG
    for (reg_i = 1; reg_i < 32; reg_i = reg_i + 1) begin
        $display("data,core.regfile[%d],h,%b", reg_i, regfile[reg_i]);
    end
    `endif
end
`endif

endmodule