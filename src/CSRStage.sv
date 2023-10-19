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

    output wire UIntX   next_csr_rdata,

    output wire         is_stall,
    output wire         csr_is_trap,
    output wire         csr_keep_trap, // validのままにするtrapかどうか
    output Addr         trap_vector,

    input wire UInt64   reg_cycle,
    input wire UInt64   reg_time,
    input wire UInt64   reg_mtime,
    input wire UInt64   reg_mtimecmp,

    output wire CacheCntrInfo   cache_cntr
);

modetype    mode = M_MODE;
Addr        satp = ADDR_ZERO;

assign cache_cntr.mode  = mode;
assign cache_cntr.satp  = satp;

`include "csrparam.svh"
`include "basicparams.svh"

initial begin
    // 起動時はM-mode  (EEI)
    mode = M_MODE;
    satp = 0;
end

wire CsrCmd csr_cmd = ctrl.csr_cmd;
wire UInt12 addr    = imm_i[11:0];

// 2.1 CSR Address Mapping Conventions
wire can_access     = addr[9:8] <= mode;
wire can_read       = can_access;
wire can_write      = can_access & addr[11:10] != 2'b11;

wire cmd_is_write   = csr_cmd == CSR_W | csr_cmd == CSR_S | csr_cmd == CSR_C;
wire cmd_is_xret    = csr_cmd == CSR_SRET | csr_cmd == CSR_MRET;

typedef enum logic [11:0] {
    // Counters and Timers
    ADDR_CYCLE      = 12'hc00,
    ADDR_TIME       = 12'hc01,
    // ADDR_INSTRET    = 12'hc02, // read-only 0
    // ADDR_HPMCOUNTER~= 12'hc03 ~ 12'hc1f, // read-only 0
    ADDR_CYCLEH     = 12'hc80,
    ADDR_TIMEH      = 12'hc81,
    // ADDR_INSTRETH    = 12'hc82,
    // ADDR_HPMCOUNTERH~= 12'hc83 ~ 12'hc9f, // read-only 0

    // Supervisor Trap Setup
    ADDR_SSTATUS    = 12'h100,
    ADDR_SIE        = 12'h104,
    ADDR_STVEC      = 12'h105,
    ADDR_SCOUNTEREN = 12'h106, // 5.1.5 U-modeがcycle, time, instret, or hpmcounternにアクセスできるかどうかのフラグ
    // Supervisor Configuration
    // ADDR_SENVCFG    = 12'h10a, // read-only 0
    // Supervisor Trap Handling
    ADDR_SSCRATCH   = 12'h140,
    ADDR_SEPC       = 12'h141,
    ADDR_SCAUSE     = 12'h142,
    ADDR_STVAL      = 12'h143,
    ADDR_SIP        = 12'h144,
    // Supervisor Protection and Translation
    ADDR_SATP       = 12'h180,
    // Debug/Trace Registers
    // ADDR_SCONTEXT   = 12'h5a8

    // Machine Information Registers
    // ADDR_MVENDORID  = 12'hf11, // read-only 0
    // ADDR_MARCHID    = 12'hf12, // read-only 0
    // ADDR_MIMPID     = 12'hf13, // read-only 0
    // ADDR_MHARTID    = 12'hf14, // read-only 0
    // ADDR_MCONFIGPTR = 12'hf15, // read-only 0
    // Machine Trap Setup
    ADDR_MSTATUS    = 12'h300,
    ADDR_MISA       = 12'h301, // RV32IM(A)
    ADDR_MEDELEG    = 12'h302,
    ADDR_MIDELEG    = 12'h303,
    ADDR_MIE        = 12'h304,
    ADDR_MTVEC      = 12'h305,
    ADDR_MCOUNTEREN = 12'h306,
    ADDR_MSTATUSH   = 12'h310,
    // Machine Trap Handling
    ADDR_MSCRATCH   = 12'h340, // 自由
    ADDR_MEPC       = 12'h341, // M-modeにトラップするとき、仮想アドレスに設定する
    ADDR_MCAUSE     = 12'h342, // trapするときに書き込む。上位1bitでInterruptかを判断する
    ADDR_MTVAL      = 12'h343, // exceptionなら実装によって書き込まれる。だが、read-only zeroでもよい
    ADDR_MIP        = 12'h344, // 3.1.9
    ADDR_MTINST     = 12'h34a, // 9.4.5
    ADDR_MTVAL2     = 12'h34b,
    // Machine Configuration
    // ADDR_MENVCFG    = 12'h30A, // 未確認
    // ADDR_MENVCFGH   = 12'h31A, // 未確認
    // ADDR_MSECCFG    = 12'h747, // 未確認
    // ADDR_MSECCFGH   = 12'h757, // 未確認
    // Machine Memory Protection
    // ADDR_PMPADDR0   = 12'h3B0, // read-only 0 // 実装しない
    // ADDR_PMPCFG0    = 12'h3A0, // read-only 0 // 実装しない
    // Machine Non-Maskable Interrupt Handling
    // 未確認
    // Machine Counter/Timers
    ADDR_MCYCLE     = 12'hb00,
    ADDR_MINSTRET   = 12'hb02,
    ADDR_MCYCLEH    = 12'hb80,
    ADDR_MINSTRETH  = 12'hb82
} csr_addr_type;

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
    input [31:0] mip,
    input [31:0] sip,
    input [31:0] mtinst,
    input [31:0] mtvec2,
    input [31:0] sscratch,
    input [31:0] sepc,
    input [31:0] scause,
    input [31:0] satp
);
case (addr)
    // Counters and Timers
    ADDR_CYCLE:     gen_rdata = reg_cycle[31:0];
    ADDR_TIME:      gen_rdata = reg_time[31:0];
    ADDR_CYCLEH:    gen_rdata = reg_cycle[63:32];
    ADDR_TIMEH:     gen_rdata = reg_time[63:32];
    // Machine Trap Setup
    ADDR_MSTATUS:   gen_rdata = mstatus;
    ADDR_MISA:      gen_rdata = misa;
    ADDR_MEDELEG:   gen_rdata = medeleg;
    ADDR_MIDELEG:   gen_rdata = mideleg;
    ADDR_MIE:       gen_rdata = mie;
    ADDR_MTVEC:     gen_rdata = mtvec;
    ADDR_MSTATUSH:  gen_rdata = mstatush;
    // Machine Trap Handling
    ADDR_MSCRATCH:  gen_rdata = mscratch;
    ADDR_MEPC:      gen_rdata = mepc;
    ADDR_MCAUSE:    gen_rdata = mcause;
    ADDR_MIP:       gen_rdata = mip;
    ADDR_MTINST:    gen_rdata = mtinst;
    ADDR_MTVAL2:    gen_rdata = mtvec2;
    // Machine Counter/Timers
    ADDR_MCYCLE:    gen_rdata = reg_cycle[31:0];
    ADDR_MCYCLEH:   gen_rdata = reg_cycle[63:32];
    // Supervisor Trap Setup
    ADDR_SSTATUS:   gen_rdata = sstatus;
    ADDR_SIE:       gen_rdata = sie;
    ADDR_STVEC:     gen_rdata = stvec;
    // Supervisor Trap Handling
    ADDR_SSCRATCH:  gen_rdata = sscratch;
    ADDR_SEPC:      gen_rdata = sepc;
    ADDR_SCAUSE:    gen_rdata = scause;
    // ADDR_STVAL:     gen_rdata = stval;
    ADDR_SIP:       gen_rdata = sip;
    // Supervisor Protection and Translation
    ADDR_SATP:      gen_rdata = satp;
    default:        gen_rdata = 32'b0;
endcase
endfunction

wire mstatus_sd  = 0;

// TODO 作る？
wire mstatus_tsr = 0; // 3.1.6.5 サポートしない。1ならS-modeでSRETするとillegal instruction exceptionにする

// TODO 作る？
wire mstatus_tw  = 0; // 3.1.6.5 WFI instruction をサポートしないのでサポートしない

// TODO 作る?
wire mstatus_tvm = 0; // 3.1.6.5 SFENCE.VMA or SINVAL.VMA をサポートしないのでサポートしない

// TODO 作る
wire mstatus_mxr = 0; // 3.1.6.3
wire mstatus_sum = 0; // 3.1.6.3

wire mstatus_mprv= 0; // 3.1.6.3 サポートしない
wire [1:0] mstatus_xs = 0; // 3.1.6.6 サポートしない
wire [1:0] mstatus_fs = 0; // 3.1.6.6 サポートしない
logic [1:0] mstatus_mpp = M_MODE; // S-modeでtrapしても書き込まれない // 初期値をM-modeにする
wire [1:0] mstatus_vs = 0; // 3.1.6.6 サポートしない
logic mstatus_spp  = 0; // S-modeでtrapしたとき、アクティブなモードが書き込まれる
logic mstatus_mpie = 0; // S-modeでtrapしても書き込まれない
wire mstatus_ube = 0; // 3.1.6.4 サポートしない
logic mstatus_spie = 0; // S-modeでtrapした時、sieが書き込まれる
logic mstatus_mie  = 0; // M-modeでtrapしたとき、クリアされる
logic mstatus_sie  = 0; // S-modeでtrapしたとき、クリアされる

wire mstatush_mbe = 0; // 3.1.6.4 サポートしない
wire mstatush_sbe = 0; // 3.1.6.4 サポートしない

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

logic [31:0] medeleg = 0;
// 9.4.2. Machine Interrupt Delegation Register (mideleg)
// When the hypervisor extension is implemented, bits 10, 6, and 2 of mideleg (corresponding to the
// standard VS-level interrupts) are each read-only one. Furthermore, if any guest external interrupts are
// implemented (GEILEN is nonzero), bit 12 of mideleg (corresponding to supervisor-level guest external
// interrupts) is also read-only one. VS-level interrupts and guest external interrupts are always delegated
// past M-mode to HS-mode
//
// 0 SGEIP MEIP VSEIP SEIP 0 MTIP VSTIP STIP 0 MSIP VSSIP SSIP 0
logic [15:0] mideleg_custom = 0;
wire mideleg_sgeip  = 0; // any guest external interruptsをサポートする
logic mideleg_meip  = 0;
wire mideleg_vseip  = 0; // hypervisor extensionをサポートしない
logic mideleg_seip  = 0;
logic mideleg_mtip  = 0;
wire mideleg_vstip  = 0; // hypervisor extensionをサポートしない
logic mideleg_stip  = 0;
logic mideleg_msip  = 0;
wire mideleg_vssip  = 0; // hypervisor extensionをサポートしない
logic mideleg_ssip  = 0;
wire [31:0] mideleg = {
    mideleg_custom,
    3'b0,
    mideleg_sgeip,
    mideleg_meip,
    mideleg_vseip,
    mideleg_seip,
    1'b0,
    mideleg_mtip,
    mideleg_vstip,
    mideleg_stip,
    1'b0,
    mideleg_msip,
    mideleg_vssip,
    mideleg_ssip,
    1'b0
};

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

logic [31:0] mscratch = 0;
logic [31:0] mepc     = 0;
logic [31:0] mcause   = 0;

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
wire [31:0] sip = {
    22'b0,
    mip_seip, 1'b0,
    2'b0,
    mip_stip, 1'b0,
    2'b0,
    mip_ssip, 1'b0
};

logic [31:0] mtinst   = 0;
logic [31:0] mtvec2   = 0;

logic [31:0] stvec    = 0;
logic [31:0] sscratch = 0;
logic [31:0] sepc     = 0;
logic [31:0] scause   = 0;

// 3.1.7
// MODE = Direct(0)  : BASE
// MODE = Vectored(1): BASE + cause * 4
wire [31:0] mtvec_addr = mtvec[1:0] == XTVEC_DIRECT ? mtvec : {mtvec[31:2], 2'b0} + {interrupt_cause[29:0], 2'b0};
wire [31:0] stvec_addr = stvec[1:0] == XTVEC_DIRECT ? stvec : {stvec[31:2], 2'b0} + {interrupt_cause[29:0], 2'b0};

// 3.1.6.1
// 3.1.9
wire global_mie = mode == M_MODE ? mstatus_mie : 1;
wire global_sie = mode == S_MODE ? mstatus_sie : mode == U_MODE;

// TODO interruptが発生しないのに発生してしまう?かと思ったが、0が0なので発生しないようだ

// 3.1.8. Machine Trap Delegation Registers (medeleg and mideleg)
// S-modeに委譲されているとき、M-modeならM-modeにトラップする。S-mode, U-modeならS-modeにトラップする。
wire interrupt_to_mmode = mideleg[interrupt_cause[4:0]] == 0;
wire exception_to_mmode = medeleg[exception_cause[4:0]] == 0;
wire trap_nochange = ctrl.fence_i;
wire trap_to_mmode = mode == M_MODE | (trapinfo.valid ? exception_to_mmode : interrupt_to_mmode);

// trapが起こりそうかどうか
wire raise_interrupt = (interrupt_to_mmode ? global_mie : global_sie) &
(
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
// TODO mip_* & mie_*をまとめる
wire [31:0] interrupt_cause = (
    (mip_meip & mie_meie) ? CAUSE_MACHINE_EXTERNAL_INTERRUPT :
    (mip_msip & mie_msie) ? CAUSE_MACHINE_SOFTWARE_INTERRUPT :
    (mip_mtip & mie_mtie) ? CAUSE_MACHINE_TIMER_INTERRUPT :
    (mip_seip & mie_seie) ? CAUSE_SUPERVISOR_EXTERNAL_INTERRUPT :
    (mip_ssip & mie_ssie) ? CAUSE_SUPERVISOR_SOFTWARE_INTERRUPT :
    (mip_stip & mie_stie) ? CAUSE_SUPERVISOR_TIMER_INTERRUPT :
    32'b0
);
wire [31:0] exception_cause = trapinfo.cause + (csr_cmd == CSR_ECALL ? {30'b0, mode} : 0);
wire [31:0] trap_cause = trapinfo.valid ? exception_cause : interrupt_cause;

wire UIntX  wdata = gen_wdata(csr_cmd, op1_data, rdata);
wire UIntX  rdata = can_read ? gen_rdata( // TODO 例外で不要になる
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
    mip,
    sip,
    mtinst,
    mtvec2,
    sscratch,
    sepc,
    scause,
    satp
) : 32'b0;
UIntX       rdata_saved;
assign      next_csr_rdata = rdata_saved;

wire this_raise_trap    = trapinfo.valid | raise_interrupt;
logic last_raise_trap   = 0;

wire undone_fence_i = ctrl.fence_i & !cache_cntr.is_writebacked_all;

wire fence_clocked  = ctrl.fence_i & !undone_fence_i & inst_clock == 2'b0;

assign is_stall     = valid & (
                ( is_new & (this_raise_trap | cmd_is_xret | cmd_is_write | trap_nochange)) |
                (!is_new & undone_fence_i | fence_clocked)
);
assign csr_is_trap  = valid & !is_new & (last_raise_trap | undone_fence_i | fence_clocked);
assign csr_keep_trap= trap_nochange;

assign cache_cntr.do_writeback      = is_new & ctrl.fence_i;
assign cache_cntr.invalidate_icache = is_new & ctrl.fence_i;

logic [1:0] inst_clock = 0;

always @(posedge clk) begin
    last_raise_trap <= this_raise_trap | cmd_is_xret;
    if (valid & is_new) begin
        inst_clock <= 0;
        // trapを起こす
        if (trap_nochange) begin
            trap_vector <= pc + 4;
            `ifdef PRINT_DEBUGINFO
                $display("info,csrstage.trap.nochange,0x%h", pc);
            `endif
        end else if (this_raise_trap) begin
            `ifdef PRINT_DEBUGINFO
                $display("info,csrstage.trap.pc,0x%h", pc);
                $display("info,csrstage.trap.to_mmode,%b", trap_to_mmode);
                $display("info,csrstage.trap.cause,0x%h", trap_cause);
            `endif
            if (trap_to_mmode) begin
                mode         <= M_MODE;
                mcause       <= trap_cause;
                mepc         <= pc;
                mstatus_mpie <= mstatus_mie;
                mstatus_mie  <= 0;
                mstatus_mpp  <= mode;
                trap_vector  <= mtvec_addr;
            end else begin
                mode         <= S_MODE;
                scause       <= trap_cause;
                sepc         <= pc;
                mstatus_spie <= mstatus_sie;
                mstatus_sie  <= 0;
                mstatus_spp  <= mode[0];
                trap_vector  <= stvec_addr;
            end
            // interruptならmipを0にする
            if (!trapinfo.valid & raise_interrupt) begin
                     if (mip_meip & mie_meie) mip_meip <= 0;
                else if (mip_msip & mie_msie) mip_msip <= 0;
                else if (mip_mtip & mie_mtie) mip_mtip <= 0;
                else if (mip_seip & mie_seie) mip_seip <= 0;
                else if (mip_ssip & mie_ssie) mip_ssip <= 0;
                else if (mip_stip & mie_stie) mip_stip <= 0;
            end
        end else begin
            // pending registerを更新する
            mip_mtip <= reg_mtime >= reg_mtimecmp;
            // rdataを保存
            rdata_saved <= rdata;
            // mret, sretを処理する
            case (csr_cmd)
                CSR_MRET: begin
                    mstatus_mie     <= mstatus_mpie;
                    mode            <= modetype'(mstatus_mpp);
                    mstatus_mpie    <= 1;
                    mstatus_mpp     <= U_MODE;
                    trap_vector     <= mepc;
                end
                CSR_SRET: begin
                    mstatus_sie     <= mstatus_spie;
                    mode            <= modetype'({1'b0, mstatus_spp});
                    mstatus_spie    <= 1;
                    mstatus_spp     <= U_MODE[0];
                    trap_vector     <= sepc;
                end
                default: begin
                    trap_vector     <= ADDR_MAX;
                end
            endcase
        end
    end
    if (valid & !is_new) begin
        inst_clock <= inst_clock + 1;
        if (can_write & cmd_is_write) begin
            $display("info,csrstage.event.write_csr,Write %h to %h", wdata, addr);
            case (addr)
                // Machine Trap Setup
                ADDR_MSTATUS: begin
                    mstatus_mpp  <= wdata[12:11];
                    mstatus_spp  <= wdata[8];
                    mstatus_mpie <= wdata[7];
                    mstatus_spie <= wdata[5];
                    mstatus_mie  <= wdata[3];
                    mstatus_sie  <= wdata[1];
                end
                ADDR_MEDELEG: medeleg <= wdata;
                ADDR_MIDELEG: begin
                    mideleg_custom  <= wdata[31:16];
                    mideleg_meip    <= wdata[11];
                    mideleg_seip    <= wdata[9];
                    mideleg_mtip    <= wdata[7];
                    mideleg_stip    <= wdata[5];
                    mideleg_msip    <= wdata[3];
                    mideleg_ssip    <= wdata[1];
                end
                ADDR_MIE: begin
                    mie_meie <= wdata[11];
                    mie_seie <= wdata[9];
                    mie_mtie <= wdata[7];
                    mie_stie <= wdata[5];
                    mie_msie <= wdata[3];
                    mie_ssie <= wdata[1];
                end
                ADDR_MTVEC: mtvec <= wdata;
                // Machine Trap Handling
                ADDR_MSCRATCH:  mscratch <= wdata;
                ADDR_MEPC:      mepc     <= {wdata[31:2], 2'b00};
                ADDR_MCAUSE:    mcause   <= wdata;
                ADDR_MIP: begin
                    mip_seip <= wdata[9];
                    mip_stip <= wdata[5];
                    mip_ssip <= wdata[1];
                end
                ADDR_MTVAL2: mtvec2 <= wdata;
                // Supervisor Trap Setup
                ADDR_SSTATUS: begin
                    mstatus_spp <= wdata[8];
                    mstatus_spie<= wdata[5];
                    mstatus_sie <= wdata[1];
                end
                ADDR_SIE: begin
                    mie_seie <= wdata[9];
                    mie_stie <= wdata[5];
                    mie_ssie <= wdata[1];
                end
                ADDR_STVEC: stvec   <= wdata;
                // Supervisor Trap Handling
                ADDR_SSCRATCH: sscratch <= wdata;
                ADDR_SEPC:     sepc <= wdata;
                ADDR_SCAUSE:   scause <= wdata;
                ADDR_SIP: begin
                    mip_seip <= wdata[9];
                    mip_stip <= wdata[5];
                    mip_ssip <= wdata[1];
                end
                // Supervisor Protection and Translation
                ADDR_SATP: satp <= wdata;
                default: begin end
            endcase
        end
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
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
    $display("data,csrstage.interrupt_to_mmode,b,%b", interrupt_to_mmode);
    $display("data,csrstage.global_mie,b,%b", global_mie);
    $display("data,csrstage.global_sie,b,%b", global_sie);
    $display("data,csrstage.mip,b,%b", mip);
    $display("data,csrstage.mie,b,%b", mie);
    $display("data,csrstage.medeleg,h,%b", medeleg);
    $display("data,csrstage.mideleg,h,%b", mideleg);
    $display("info,csrstage.mtvec,0x%h", mtvec_addr);
    $display("info,csrstage.stvec,0x%h", stvec_addr);
    $display("info,csrstage.mepc,0x%h", mepc);
    $display("info,csrstage.sepc,0x%h", sepc);

    if (ctrl.fence_i) begin
        $display("data,csrstage.$.do_wb,b,%b", cache_cntr.do_writeback);
        $display("data,csrstage.$.is_wbed_all,b,%b", cache_cntr.is_writebacked_all);
        $display("data,csrstage.$.invalidate_i$,b,%b", cache_cntr.invalidate_icache);
    end

    if (valid & (csr_cmd != CSR_X | this_raise_trap)) begin
        $display("data,csrstage.csr_cmd,d,%b", csr_cmd);
        $display("data,csrstage.addr,h,%b", addr);
        $display("data,csrstage.wdata,h,%b", wdata);
        $display("data,csrstage.rdata,h,%b", next_csr_rdata);
        $display("data,csrstage.csr_is_trap,b,%b", this_raise_trap);
    end
end
`endif

endmodule