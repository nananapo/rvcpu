`include "pkg_util.svh"
`include "pkg_csr.svh"
`include "memoryinterface.svh"

module CSRStage #(
    parameter FMAX_MHz = 27
) (
    input wire          clk,

    input wire          valid,
    input wire          is_new,
    input wire TrapInfo trapinfo,
    input wire Addr     pc,
    input wire Inst     inst,
    input wire IId      inst_id,
    input wire Ctrl     ctrl,
    input wire UIntX    imm_i,
    input wire UIntX    op1_data,
    input wire UIntX    alu_out,
    input wire Addr     btarget,

    output wire UIntX   next_csr_rdata,
    output wire         next_no_wb,

    output wire         is_stall,
    output wire         csr_is_trap,
    output wire         csr_keep_trap, // validのままにするtrapかどうか
    output Addr         trap_vector,

    input wire UInt64   reg_cycle,
    input wire UInt64   reg_time,
    input wire UInt64   reg_mtime,
    input wire UInt64   reg_mtimecmp,

    input wire          external_interrupt_pending,

    output wire CacheCntrInfo   cache_cntr
);

`include "basicparams.svh"


typedef enum logic [1:0] {
    XTVEC_DIRECT   = 2'b00,
    XTVEC_VECTORED = 2'b01
} xtvec_mode_type;

function [31:0] gen_wdata(
    input [2:0]  csr_cmd,
    input [31:0] op1_data,
    input [31:0] rdata
);
case (csr_cmd)
    CSR_W  : gen_wdata = op1_data;
    CSR_S  : gen_wdata = rdata | op1_data;
    CSR_C  : gen_wdata = rdata & ~op1_data;
    default: gen_wdata = 0;
endcase
endfunction

function [31:0] gen_rdata(
    input UInt12 addr,
    input [63:0] reg_cycle,
    input [63:0] reg_time,
    input [31:0] mstatus,
    input [31:0] sstatus,
    input [31:0] mstatush,
    input [31:0] misa,
    input [31:0] medeleg,
    input [31:0] mideleg,
    input [31:0] mie,
    input [31:0] sie,
    input [31:0] mscratch,
    input [31:0] mepc,
    input [31:0] mcause,
    input [31:0] mtval,
    input [31:0] mip,
    input [31:0] sip,
    input [31:0] mtinst,
    input [31:0] mtval2,
    input [31:0] sscratch,
    input [31:0] sepc,
    input [31:0] scause,
    input [31:0] stval,
    input [31:0] satp
);
case (addr)
    // Counters and Timers
    CsrAddr::CYCLE:     gen_rdata = reg_cycle[31:0];
    CsrAddr::TIME:      gen_rdata = reg_time[31:0];
    CsrAddr::CYCLEH:    gen_rdata = reg_cycle[63:32];
    CsrAddr::TIMEH:     gen_rdata = reg_time[63:32];
    // Machine Trap Setup
    CsrAddr::MSTATUS:   gen_rdata = mstatus;
    CsrAddr::MISA:      gen_rdata = misa;
    CsrAddr::MEDELEG:   gen_rdata = medeleg;
    CsrAddr::MIDELEG:   gen_rdata = mideleg;
    CsrAddr::MIE:       gen_rdata = mie;
    CsrAddr::MTVEC:     gen_rdata = mtvec;
    CsrAddr::MSTATUSH:  gen_rdata = mstatush;
    // Machine Trap Handling
    CsrAddr::MSCRATCH:  gen_rdata = mscratch;
    CsrAddr::MEPC:      gen_rdata = mepc;
    CsrAddr::MCAUSE:    gen_rdata = mcause;
    CsrAddr::MTVAL:     gen_rdata = mtval;
    CsrAddr::MIP:       gen_rdata = mip;
    CsrAddr::MTINST:    gen_rdata = mtinst;
    CsrAddr::MTVAL2:    gen_rdata = mtval2;
    // Machine Counter/Timers
    CsrAddr::MCYCLE:    gen_rdata = reg_cycle[31:0];
    CsrAddr::MCYCLEH:   gen_rdata = reg_cycle[63:32];
    // Supervisor Trap Setup
    CsrAddr::SSTATUS:   gen_rdata = sstatus;
    CsrAddr::SIE:       gen_rdata = sie;
    CsrAddr::STVEC:     gen_rdata = stvec;
    // Supervisor Trap Handling
    CsrAddr::SSCRATCH:  gen_rdata = sscratch;
    CsrAddr::SEPC:      gen_rdata = sepc;
    CsrAddr::SCAUSE:    gen_rdata = scause;
    CsrAddr::STVAL:     gen_rdata = stval;
    // CsrAddr::STVAL:     gen_rdata = stval;
    CsrAddr::SIP:       gen_rdata = sip;
    // Supervisor Protection and Translation
    CsrAddr::SATP:      gen_rdata = satp;
    default:        gen_rdata = 32'b0;
endcase
endfunction

function [$bits(UIntX)-1:0] gen_expt_xtval(
    input UIntX     cause,
    input Addr      pc,
    input UIntX     inst,
    input UIntX     alu_out
);
    case (cause)
        CsrCause::INSTRUCTION_ADDRESS_MISALIGNED:
            gen_expt_xtval = btarget;
        CsrCause::BREAKPOINT,
        CsrCause::INSTRUCTION_ACCESS_FAULT,
        CsrCause::INSTRUCTION_PAGE_FAULT:
            gen_expt_xtval = pc;
        CsrCause::LOAD_ADDRESS_MISALIGNED,
        CsrCause::LOAD_ACCESS_FAULT,
        CsrCause::LOAD_PAGE_FAULT,
        CsrCause::STORE_AMO_ADDRESS_MISALIGNED,
        CsrCause::STORE_AMO_ACCESS_FAULT,
        CsrCause::STORE_AMO_PAGE_FAULT:
            gen_expt_xtval = alu_out;
        CsrCause::ILLEGAL_INSTRUCTION:
            gen_expt_xtval = inst;
        default:
            gen_expt_xtval = 0;
    endcase
endfunction

modetype    mode = M_MODE;
Addr        satp = ADDR_ZERO;

initial begin
    // 起動時はM-mode  (EEI)
    mode = M_MODE;
    satp = 0;
end

wire CsrCmd csr_cmd = ctrl.csr_cmd;
wire UInt12 addr    = imm_i[11:0];

// 2.1 CSR Address Mapping Conventions
wire can_access     =   addr == CsrAddr::SATP & mode == S_MODE ? !mstatus_tvm :
                        addr[9:8] <= mode;
wire is_readonly    = addr[11:10] == 2'b11;

wire cmd_is_write   = csr_cmd == CSR_W | csr_cmd == CSR_S | csr_cmd == CSR_C;
wire cmd_is_xret    = csr_cmd == CSR_SRET | csr_cmd == CSR_MRET;


// MSTATUS
wire mstatus_sd     = 0;
// 3.1.6.5 Trap SRET : 1のとき、S-modeでSRETするとillegal instruction exceptionが発生する
logic mstatus_tsr   = 0;
// 3.1.6.5 Timwout Wait : 1のとき、WFIが一定時間内に完了しない場合にillegal instruction exceptionが発生する
// 実装を簡単にするため、1のときは待機しないで例外を発生させる
logic mstatus_tw    = 0;
// 3.1.6.5 Trap Virtual Memory : 1のとき、S-modeでsatpを編集, SFENCE.VMA/SINVAL.VMAを実行しようとするとillegal instruction exceptionが発生する
logic mstatus_tvm   = 0;
// 3.1.6.3 Make eXecutable Readable
// Address translationで、leaf PTEのX = 1でもloadできるようにするかどうか -> storeはできない？
logic mstatus_mxr   = 0;
// 3.1.6.3 permit Supervisor User Memory access
// 0のとき、S-modeでU=1にload, storeしようとするとfaultする
// 1のとき、faultしない。
// modeはMPRVに従う
logic mstatus_sum   = 0;
// 3.1.6.3 Modify PRiVilege
// 0のとき、普通にふるまう
// 1のとき、load/storeはMPPがmodeになっているかのようにアドレストランスレーション, プロテクションを行う。命令読み込みは影響を受けない
logic mstatus_mprv  = 0;
// 3.1.6.6 サポートしない
// F拡張を実装していないので必要ない
wire [1:0] mstatus_xs   = 0;
wire [1:0] mstatus_fs   = 0;
// M-modeにトラップするときに、現在のmodeが書き込まれる。
// EEI : 初期値はM-mode
logic [1:0] mstatus_mpp = M_MODE;
// 3.1.6.6 サポートしない, v系は実装していないはずなので必要ない
wire [1:0] mstatus_vs   = 0;
// S-modeにトラップするときに、現在のmodeが書き込まれる。
// EEI : 初期値はU-mode
logic mstatus_spp   = U_MODE[0];
// M-modeにトラップするときに、現在のMIEが書き込まれる
logic mstatus_mpie  = 0;
// 3.1.6.4 サポートしない, エンディアンを変更できる
wire mstatus_ube    = 0;
// S-modeにトラップするときに、現在のSIEが書き込まれる
logic mstatus_spie  = 0;
// Interrupt Enable Bit
logic mstatus_mie   = 0;
logic mstatus_sie   = 0;
// 3.1.6.4 サポートしない, エンディアンを変更できる
wire mstatush_mbe   = 0;
wire mstatush_sbe   = 0;

wire [31:0] mstatus = {
    mstatus_sd,
    8'b0,
    mstatus_tsr,
    mstatus_tw,
    mstatus_tvm,
    mstatus_mxr,
    mstatus_sum,
    mstatus_mprv,
    mstatus_xs,
    mstatus_fs,
    mstatus_mpp,
    mstatus_vs,
    mstatus_spp,
    mstatus_mpie,
    mstatus_ube,
    mstatus_spie,
    1'b0,
    mstatus_mie,
    1'b0,
    mstatus_sie,
    1'b0
};
wire [31:0] sstatus = {
    mstatus_sd,
    11'b0,
    mstatus_mxr,
    mstatus_sum,
    1'b0,
    mstatus_xs,
    mstatus_fs,
    2'b0,
    mstatus_vs,
    mstatus_spp,
    1'b0,
    mstatus_ube,
    mstatus_spie,
    3'b0,
    mstatus_sie,
    1'b0
};
wire [31:0] mstatush = {26'b0, mstatush_mbe, mstatush_sbe, 4'b0};

//                   |MXL|   |Extensions                      |
//                     32     ZY XWVU TSRQ PONM LKJI HGFE DCBA
wire [31:0] misa = 32'b0100_0000_0000_0000_0001_0001_0000_0001;

UIntX medeleg = 0;
UIntX mideleg = 0;
logic mie_meie = 0; // external interrupt
logic mie_seie = 0;
logic mie_mtie = 0; // timer interrupt
logic mie_stie = 0;
logic mie_msie = 0; // software interrupt
logic mie_ssie = 0;

wire [31:0] mie = {
    16'b0, 4'b0,
    mie_meie, 1'b0,
    mie_seie, 1'b0,
    mie_mtie, 1'b0,
    mie_stie, 1'b0,
    mie_msie, 1'b0,
    mie_ssie, 1'b0
};
wire [31:0] sie = {
    16'b0, 6'b0,
    mie_seie, 3'b0,
    mie_stie, 3'b0,
    mie_ssie, 1'b0
};

logic [31:0] mtvec = 0;

logic [31:0] mscratch   = 0;
logic [31:0] mepc       = 0;
logic [31:0] mcause     = 0;
logic [31:0] mtval      = 0;

logic mip_meip = 0;
logic mip_seip = 0;
logic mip_mtip = 0;
logic mip_stip = 0;
logic mip_msip = 0;
logic mip_ssip = 0;
wire [31:0] mip = {
    20'b0,
    mip_meip, 1'b0,
    mip_seip, 1'b0,
    mip_mtip, 1'b0,
    mip_stip, 1'b0,
    mip_msip, 1'b0,
    mip_ssip, 1'b0
};
/*
Restricted views of the mip and mie registers appear as the sip and sie registers for supervisor level.
If an interrupt is delegated to S-mode by setting a bit in the mideleg register,
it becomes visible in the sip register and is maskable using the sie register.
Otherwise, the corresponding bits in sip and sie are read-only zero.
*/
wire [31:0] sip = mideleg & {
    22'b0,
    mip_seip, 1'b0,
    2'b0,
    mip_stip, 1'b0,
    2'b0,
    mip_ssip, 1'b0
};

logic [31:0] mtinst   = 0;
logic [31:0] mtval2   = 0;
logic [31:0] stvec    = 0;

// 3.1.7
// MODE = Direct(0)  : BASE
// MODE = Vectored(1): BASE + cause * 4
wire [31:0] mtvec_addr = mtvec[1:0] == XTVEC_DIRECT ? mtvec : {mtvec[31:2], 2'b0} + {cause_intr[29:0], 2'b0};
wire [31:0] stvec_addr = stvec[1:0] == XTVEC_DIRECT ? stvec : {stvec[31:2], 2'b0} + {cause_intr[29:0], 2'b0};

logic [31:0] sscratch   = 0;
logic [31:0] sepc       = 0;
logic [31:0] scause     = 0;
logic [31:0] stval      = 0;

wire UIntX  wdata = gen_wdata(csr_cmd, op1_data, rdata);
wire UIntX  rdata = gen_rdata(
    addr,
    reg_cycle,
    reg_time,
    mstatus,
    sstatus,
    mstatush,
    misa,
    medeleg,
    mideleg,
    mie,
    sie,
    mscratch,
    mepc,
    mcause,
    mtval,
    mip,
    sip,
    mtinst,
    mtval2,
    sscratch,
    sepc,
    scause,
    stval,
    satp
);

// TRAP
wire csr_access_fault   = cmd_is_write & !can_access;
wire csr_xret_no_priv   =   csr_cmd == CSR_MRET & mode != M_MODE |
                            csr_cmd == CSR_SRET & mode < S_MODE |
                            csr_cmd == CSR_SRET & mode == S_MODE & mstatus_tsr;
wire sfence_no_priv     =  (ctrl.sfence | ctrl.svinval) & (
                            mode == U_MODE |
                            mstatus_tvm & mode == S_MODE);
wire wfi_tw_nowait      = ctrl.wfi & mstatus_tw;

wire        raise_expt  = valid & (trapinfo.valid | csr_access_fault | csr_xret_no_priv | sfence_no_priv | wfi_tw_nowait);
wire UIntX  cause_expt  = trapinfo.valid ?
                            (csr_cmd == CSR_ECALL ? CsrCause::ENVIRONMENT_CALL_FROM_U_MODE + {30'b0, mode} : trapinfo.cause ) :
                            csr_access_fault | csr_xret_no_priv | sfence_no_priv | wfi_tw_nowait ? CsrCause::ILLEGAL_INSTRUCTION : 0;

wire intr_toM   = mideleg[cause_intr[4:0]] == 0 | mode == M_MODE;
wire expt_toM   = medeleg[cause_expt[4:0]] == 0 | mode == M_MODE;
wire trap_toM   = raise_expt ? expt_toM : intr_toM;

// interruptが起こりそうかどうか
wire raise_intr =   (intr_toM ? // 3.1.9
                        (mode == M_MODE ? mstatus_mie : 1) :
                        (mode == S_MODE ? mstatus_sie : mode == U_MODE)
                    ) & (
                        (mip_meip & mie_meie) |
                        (mip_msip & mie_msie) |
                        (mip_mtip & mie_mtie) |
                        (mip_seip & mie_seie) |
                        (mip_ssip & mie_ssie) |
                        (mip_stip & mie_stie)
                    );

// 3.1.9
// Multiple simultaneous interrupts destined for M-mode are handled in the following decreasing
// priority order: MEI, MSI, MTI, SEI, SSI, STI.
wire [31:0] cause_intr = (
                            (mip_meip & mie_meie) ? CsrCause::MACHINE_EXTERNAL_INTERRUPT :
                            (mip_msip & mie_msie) ? CsrCause::MACHINE_SOFTWARE_INTERRUPT :
                            (mip_mtip & mie_mtie) ? CsrCause::MACHINE_TIMER_INTERRUPT :
                            (mip_seip & mie_seie) ? CsrCause::SUPERVISOR_EXTERNAL_INTERRUPT :
                            (mip_ssip & mie_ssie) ? CsrCause::SUPERVISOR_SOFTWARE_INTERRUPT :
                            (mip_stip & mie_stie) ? CsrCause::SUPERVISOR_TIMER_INTERRUPT :
                            32'b0
                        );
wire [31:0] cause_trap = raise_expt ? cause_expt : cause_intr;

wire UIntX  expt_xtval = gen_expt_xtval(cause_expt, pc, inst, alu_out);

UIntX       rdata_saved;
assign      next_csr_rdata = rdata_saved;

wire this_raise_trap    = valid & (raise_expt | raise_intr);
logic last_raise_trap   = 0;

wire is_fence       = ctrl.fence_i | (!sfence_no_priv & (ctrl.sfence | ctrl.svinval));
wire trap_nochange  = is_fence; // TODO 改名
wire undone_fence_i = is_fence & !cache_cntr.is_writebacked_all;
wire fence_clocked  = is_fence & !undone_fence_i & inst_clock == 2'b0;

assign is_stall     = valid & (
                ( is_new & (this_raise_trap | cmd_is_xret | cmd_is_write | trap_nochange)) |
                (!is_new & undone_fence_i | fence_clocked)
);
assign csr_is_trap  = valid & !is_new & (last_raise_trap | cmd_is_xret | undone_fence_i | fence_clocked);
assign csr_keep_trap= trap_nochange;

assign next_no_wb   = valid & (this_raise_trap | last_raise_trap); // TODO xretは除外

assign cache_cntr.i_mode            = mode;
assign cache_cntr.d_mode            = modetype'(mode == M_MODE & mstatus_mprv ? modetype'(mstatus_mpp) : mode);
assign cache_cntr.mxr               = mstatus_mxr;
assign cache_cntr.sum               = mstatus_sum;
assign cache_cntr.satp              = satp;
assign cache_cntr.do_writeback      = valid & is_new & is_fence;
assign cache_cntr.invalidate_icache = valid & is_new & is_fence;

logic [1:0] inst_clock = 0;
logic csr_no_wb = 0; // トラップの時にCSRに書き込む命令が実行されないようにするためのフラグ

always @(posedge clk) begin
    last_raise_trap <= this_raise_trap;
    if (valid & is_new) begin
        inst_clock <= 0;
        // trapを起こす
        if (trap_nochange) begin
            trap_vector <= pc + 4;
            csr_no_wb   <= 1;
            if (util::logEnabled())
                $display("info,csrstage.trap.nochange,0x%h", pc);
        end else if (this_raise_trap) begin
            csr_no_wb   <= 1;
            if (util::logEnabled()) begin
                $display("info,csrstage.trap.pc,0x%h", pc);
                $display("info,csrstage.trap.cause,0x%h", cause_trap);
            end
            if (trap_toM) begin
                mode            <= M_MODE;
                mcause          <= cause_trap;
                mepc            <= pc;
                mtval           <= raise_expt ? expt_xtval : mtval;
                mstatus_mpie    <= mstatus_mie;
                mstatus_mie     <= 0;
                mstatus_mpp     <= mode;
                trap_vector     <= mtvec_addr;
            end else begin
                mode            <= S_MODE;
                scause          <= cause_trap;
                sepc            <= pc;
                stval           <= raise_expt ? expt_xtval : stval;
                mstatus_spie    <= mstatus_sie;
                mstatus_sie     <= 0;
                mstatus_spp     <= mode[0];
                trap_vector     <= stvec_addr;
            end
            // interruptならmipを0にする
            if (!raise_expt & raise_intr) begin
                     if (mip_meip & mie_meie) mip_meip <= 0;
                else if (mip_msip & mie_msie) mip_msip <= 0;
                else if (mip_mtip & mie_mtie) mip_mtip <= 0;
                else if (mip_seip & mie_seie) mip_seip <= 0;
                else if (mip_ssip & mie_ssie) mip_ssip <= 0;
                else if (mip_stip & mie_stie) mip_stip <= 0;
            end
        end else begin
            // pending registerを更新する
            // PLICがないのでとりあえずS-mode用にしてる
            mip_seip <= external_interrupt_pending;
            mip_mtip <= reg_mtime >= reg_mtimecmp;
            // rdataを保存
            rdata_saved <= rdata;
            // mret, sretを処理する
            case (csr_cmd)
                CSR_MRET: begin
                    csr_no_wb       <= 1;
                    mstatus_mie     <= mstatus_mpie;
                    mode            <= modetype'(mstatus_mpp);
                    mstatus_mpie    <= 1;
                    mstatus_mpp     <= U_MODE;
                    trap_vector     <= mepc;
                    if (modetype'(mstatus_mpp) != M_MODE)
                        mstatus_mprv <= 0;
                end
                CSR_SRET: begin
                    csr_no_wb       <= 1;
                    mstatus_sie     <= mstatus_spie;
                    mode            <= modetype'({1'b0, mstatus_spp});
                    mstatus_spie    <= 1;
                    mstatus_spp     <= U_MODE[0];
                    trap_vector     <= sepc;
                    if (modetype'({1'b0, mstatus_spp}) != M_MODE)
                        mstatus_mprv <= 0;
                end
                default: begin
                    csr_no_wb   <= 0;
                    trap_vector <= 0;
                end
            endcase
        end
    end
    if (valid & !is_new) begin
        inst_clock <= inst_clock + 1;
        if (cmd_is_write & can_access & !is_readonly & !csr_no_wb) begin
            if (util::logEnabled())
                $display("info,csrstage.event.write_csr,Write %h to %h", wdata, addr);
            case (addr)
                // Machine Trap Setup
                CsrAddr::MSTATUS: begin
                    mstatus_tsr     <= wdata[22];
                    mstatus_tw      <= wdata[21];
                    mstatus_tvm     <= wdata[20];
                    mstatus_mxr     <= wdata[19];
                    mstatus_sum     <= wdata[18];
                    mstatus_mprv    <= wdata[17];
                    mstatus_mpp     <= wdata[12:11];
                    mstatus_spp     <= wdata[8];
                    mstatus_mpie    <= wdata[7];
                    mstatus_spie    <= wdata[5];
                    mstatus_mie     <= wdata[3];
                    mstatus_sie     <= wdata[1];
                end
                CsrAddr::MEDELEG: medeleg   <= wdata;
                CsrAddr::MIDELEG: begin
                    // qemuの動作を見たら、M系は立てられなかった
                    mideleg[1]  <= wdata[1];
                    mideleg[5]  <= wdata[5];
                    mideleg[9]  <= wdata[9];
                end
                CsrAddr::MIE: begin
                    mie_meie <= wdata[11];
                    mie_seie <= wdata[9];
                    mie_mtie <= wdata[7];
                    mie_stie <= wdata[5];
                    mie_msie <= wdata[3];
                    mie_ssie <= wdata[1];
                end
                CsrAddr::MTVEC:     mtvec       <= wdata;
                // Machine Trap Handling
                CsrAddr::MSCRATCH:  mscratch    <= wdata;
                CsrAddr::MEPC:      mepc        <= {wdata[31:2], 2'b00};
                CsrAddr::MCAUSE:    mcause      <= wdata;
                CsrAddr::MTVAL:     mtval       <= wdata;
                CsrAddr::MIP: begin
                    mip_seip <= wdata[9];
                    mip_stip <= wdata[5];
                    mip_ssip <= wdata[1];
                end
                CsrAddr::MTVAL2:    mtval2      <= wdata;
                // Supervisor Trap Setup
                CsrAddr::SSTATUS: begin
                    mstatus_mxr     <= wdata[19];
                    mstatus_sum     <= wdata[18];
                    mstatus_spp     <= wdata[8];
                    mstatus_spie    <= wdata[5];
                    mstatus_sie     <= wdata[1];
                end
                CsrAddr::SIE: begin
                    // SIEとSIPはdelegされていないと書き込めない
                    mie_seie <= mideleg[9] & wdata[9];
                    mie_stie <= mideleg[5] & wdata[5];
                    mie_ssie <= mideleg[1] & wdata[1];
                end
                CsrAddr::STVEC:     stvec       <= wdata;
                // Supervisor Trap Handling
                CsrAddr::SSCRATCH:  sscratch    <= wdata;
                CsrAddr::SEPC:      sepc        <= wdata;
                CsrAddr::SCAUSE:    scause      <= wdata;
                CsrAddr::STVAL:     stval       <= wdata;
                CsrAddr::SIP: begin
                    mip_seip <= mideleg[9] & wdata[9];
                    mip_stip <= mideleg[5] & wdata[5];
                    mip_ssip <= mideleg[1] & wdata[1];
                end
                // Supervisor Protection and Translation
                CsrAddr::SATP: satp <= wdata;
                default: begin end
            endcase
        end
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,csrstage.valid,b,%b", valid);
    $display("data,csrstage.inst_id,h,%b", valid ? inst_id : IID_X);
    if (valid) begin
        $display("data,csrstage.pc,h,%b", pc);
        $display("data,csrstage.inst,h,%b", inst);
        $display("data,csrstage.is_stall,b,%b", is_stall);
    end
    $display("data,csrstage.mode,d,%b", mode);
    $display("data,csrstage.mstatus,h,%b", mstatus);
    $display("data,csrstage.mstatus.mie,b,%b", mstatus_mie);
    $display("data,csrstage.mstatus.sie,b,%b", mstatus_sie);
    $display("data,csrstage.mip,b,%b", mip);
    $display("data,csrstage.mie,b,%b", mie);
    $display("data,csrstage.medeleg,h,%b", medeleg);
    $display("data,csrstage.mideleg,h,%b", mideleg);
    $display("info,csrstage.mtvec,0x%h", mtvec);
    $display("info,csrstage.stvec,0x%h", stvec);
    $display("info,csrstage.mepc,0x%h", mepc);
    $display("info,csrstage.sepc,0x%h", sepc);

    if (valid && is_fence) begin
        $display("data,csrstage.$.do_wb,b,%b", cache_cntr.do_writeback);
        $display("data,csrstage.$.is_wbed_all,b,%b", cache_cntr.is_writebacked_all);
        $display("data,csrstage.$.invalidate_i$,b,%b", cache_cntr.invalidate_icache);
    end

    if (valid & (csr_cmd != CSR_X | this_raise_trap)) begin
        $display("data,csrstage.csr_cmd,d,%b", csr_cmd);
        $display("data,csrstage.can_access,d,%b", can_access);
        $display("data,csrstage.addr,h,%b", addr);
        $display("data,csrstage.wdata,h,%b", wdata);
        $display("data,csrstage.rdata,h,%b", next_csr_rdata);
        $display("data,csrstage.csr_is_trap,b,%b", this_raise_trap);
    end
end
`endif

endmodule