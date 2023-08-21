module CSRStage #(
    parameter FMAX_MHz = 27
) (
    input  wire         clk,

    input wire          csr_valid,
    input wire [31:0]   csr_pc,
    input wire [31:0]   csr_inst,
    input wire IId  csr_inst_id,
    input wire Ctrl csr_ctrl,
    input wire [31:0]   csr_imm_i,
    input wire [31:0]   csr_op1_data,

    output wire [31:0]  csr_mem_csr_rdata,

    output wire         csr_stall_flg,
    output wire         csr_trap_flg,
    output wire [31:0]  csr_trap_vector,

    input wire [63:0]   reg_cycle,
    input wire [63:0]   reg_time,
    input wire [63:0]   reg_mtime,
    input wire [63:0]   reg_mtimecmp,

    output wire modetype output_mode,
    output wire [31:0]   output_satp,
    output wire          satp_change_hazard
);

wire [31:0]  pc         = csr_pc;
wire IId inst_id    = csr_inst_id;
wire [2:0]   csr_cmd    = csr_ctrl.csr_cmd;
wire [31:0]  op1_data   = csr_op1_data;

// Table 3.6
                                                                                           // I ECODE Description 
localparam MCAUSE_SUPERVISOR_SOFTWARE_INTERRUPT = 32'b10000000_00000000_00000000_00000001; // 1 1     Supervisor software interrupt
localparam MCAUSE_MACHINE_SOFTWARE_INTERRUPT    = 32'b10000000_00000000_00000000_00000011; // 1 3     Machine software interrupt
localparam MCAUSE_SUPERVISOR_TIMER_INTERRUPT    = 32'b10000000_00000000_00000000_00000101; // 1 5     Supervisor timer interrupt
localparam MCAUSE_MACHINE_TIMER_INTERRUPT       = 32'b10000000_00000000_00000000_00000111; // 1 7     Machine timer interrupt
localparam MCAUSE_SUPERVISOR_EXTERNAL_INTERRUPT = 32'b10000000_00000000_00000000_00001001; // 1 9     Supervisor external interrupt
localparam MCAUSE_MACHINE_EXTERNAL_INTERRUPT    = 32'b10000000_00000000_00000000_00001011; // 1 11    Machine external interrupt
                                                            // I ECODE Description 
localparam MCAUSE_INSTRUCTION_ADDRESS_MISALIGNED= 32'b0000; // 0 0     Instruction address misaligned
localparam MCAUSE_INSTRUCTION_ACCESS_FAULT      = 32'b0001; // 0 1     Instruction access fault
localparam MCAUSE_ILLEGAL_INSTRUCTION           = 32'b0010; // 0 2     Illegal instruction
localparam MCAUSE_BREAKPOINT                    = 32'b0011; // 0 3     Breakpoint
localparam MCAUSE_LOAD_ADDRESS_MISALIGNED       = 32'b0100; // 0 4     Load address misaligned
localparam MCAUSE_LOAD_ACCESS_FAULT             = 32'b0101; // 0 5     Load access fault
localparam MCAUSE_STORE_AMO_ADDRESS_MISALIGNED  = 32'b0110; // 0 6     Store/AMO address misaligned
localparam MCAUSE_STORE_AMO_ACCESS_FAULT        = 32'b0111; // 0 7     Store/AMO access fault
localparam MCAUSE_ENVIRONMENT_CALL_FROM_U_MODE  = 32'b1000; // 0 8     Environment call from U-mode
localparam MCAUSE_ENVIRONMENT_CALL_FROM_S_MODE  = 32'b1001; // 0 9     Environment call from S-mode
localparam MCAUSE_ENVIRONMENT_CALL_FROM_M_MODE  = 32'b1011; // 0 11    Environment call from M-mode
localparam MCAUSE_INSTRUCTION_PAGE_FAULT        = 32'b1100; // 0 12    Instruction page fault
localparam MCAUSE_LOAD_PAGE_FAULT               = 32'b1101; // 0 13    Load page fault
localparam MCAUSE_STORE_AMO_PAGE_FAULT          = 32'b1111; // 0 15    Store/AMO page fault

typedef enum reg [11:0] { 
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

typedef enum reg [1:0] { 
    XTVEC_DIRECT   = 2'b00,
    XTVEC_VECTORED = 2'b01
} xtvec_mode_type;

// 現在のモード
modetype mode = M_MODE;

wire mstatus_sd  = 0;
wire mstatus_tsr = 0; // 3.1.6.5 サポートしない。1ならS-modeでSRETするとillegal instruction exceptionにする
wire mstatus_tw  = 0; // 3.1.6.5 WFI instruction をサポートしないのでサポートしない
wire mstatus_tvm = 0; // 3.1.6.5 SFENCE.VMA or SINVAL.VMA をサポートしないのでサポートしない
wire mstatus_mxr = 0; // 3.1.6.3 サポートしない
wire mstatus_sum = 0; // 3.1.6.3 サポートしない
wire mstatus_mprv= 0; // 3.1.6.3 サポートしない
wire [1:0] mstatus_xs = 0; // 3.1.6.6 サポートしない
wire [1:0] mstatus_fs = 0; // 3.1.6.6 サポートしない
reg [1:0] mstatus_mpp = M_MODE; // S-modeでtrapしても書き込まれない // 初期値をM-modeにする
wire [1:0] mstatus_vs = 0; // 3.1.6.6 サポートしない
reg mstatus_spp  = 0; // S-modeでtrapしたとき、アクティブなモードが書き込まれる
reg mstatus_mpie = 0; // S-modeでtrapしても書き込まれない
wire mstatus_ube = 0; // 3.1.6.4 サポートしない
reg mstatus_spie = 0; // S-modeでtrapした時、sieが書き込まれる
reg mstatus_mie  = 0; // M-modeでtrapしたとき、クリアされる
reg mstatus_sie  = 0; // S-modeでtrapしたとき、クリアされる

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

//                   |MXL|   |Extensions                |
//                     32     ZYXWVUTSRQPONMLKJIHGFEDCBA
wire [31:0] misa = 32'b01_000_00000000000001000100000001;

reg [31:0] medeleg = 0;
// 9.4.2. Machine Interrupt Delegation Register (mideleg)
// When the hypervisor extension is implemented, bits 10, 6, and 2 of mideleg (corresponding to the
// standard VS-level interrupts) are each read-only one. Furthermore, if any guest external interrupts are
// implemented (GEILEN is nonzero), bit 12 of mideleg (corresponding to supervisor-level guest external
// interrupts) is also read-only one. VS-level interrupts and guest external interrupts are always delegated
// past M-mode to HS-mode
// 
// 0 SGEIP MEIP VSEIP SEIP 0 MTIP VSTIP STIP 0 MSIP VSSIP SSIP 0
reg [15:0] mideleg_custom = 0;
wire mideleg_sgeip  = 0; // any guest external interruptsをサポートする
reg mideleg_meip    = 0;
wire mideleg_vseip  = 0; // hypervisor extensionをサポートしない
reg mideleg_seip    = 0;
reg mideleg_mtip    = 0;
wire mideleg_vstip  = 0; // hypervisor extensionをサポートしない
reg mideleg_stip    = 0;
reg mideleg_msip    = 0;
wire mideleg_vssip  = 0; // hypervisor extensionをサポートしない
reg mideleg_ssip    = 0;
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

reg mie_meie = 0; // external interrupt
reg mie_seie = 0;
reg mie_mtie = 0; // timer interrupt
reg mie_stie = 0;
reg mie_msie = 0; // software interrupt
reg mie_ssie = 0;

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

reg [31:0] mtvec = 0;

reg [31:0] mscratch = 0;
reg [31:0] mepc     = 0;
reg [31:0] mcause   = 0;

reg mip_meip = 0;
reg mip_seip = 0;
reg mip_mtip = 0;
reg mip_stip = 0;
reg mip_msip = 0;
reg mip_ssip = 0;
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

reg [31:0] mtinst   = 0;
reg [31:0] mtvec2   = 0;

reg [31:0] stvec    = 0;
reg [31:0] sscratch = 0;
reg [31:0] sepc     = 0;
reg [31:0] scause   = 0;
// 5.1.11
// MODE(1) | ASID(9) | PPN(22)
// Table 23
// MODE = 0 : Bare (物理アドレスと同じ), ASID, PPNも0にする必要がある
//            0ではないなら動作はUNSPECIFIED！こわいね 
// MODE = 1 : Sv32, ページングが有効
reg [31:0] satp     = 0;

// 3.1.7
// MODE = Direct(0)  : BASE
// MODE = Vectored(1): BASE + cause * 4
wire [31:0] mtvec_addr = mtvec[1:0] == XTVEC_DIRECT ? mtvec : {mtvec[31:2], 2'b0} + {interrupt_cause[29:0], 2'b0};
wire [31:0] stvec_addr = stvec[1:0] == XTVEC_DIRECT ? stvec : {stvec[31:2], 2'b0} + {interrupt_cause[29:0], 2'b0};

// 3.1.6.1
// 3.1.9
wire global_mie = mode == M_MODE ? mstatus_mie : 1;
wire global_sie = mode == S_MODE ? mstatus_sie : mode == U_MODE;

// 3.1.9
// Multiple simultaneous interrupts destined for M-mode are handled in the following decreasing
// priority order: MEI, MSI, MTI, SEI, SSI, STI.
// TODO mip_* && mie_*をまとめる
wire [31:0] interrupt_cause = (
    (mip_meip && mie_meie) ? MCAUSE_MACHINE_EXTERNAL_INTERRUPT :
    (mip_msip && mie_msie) ? MCAUSE_MACHINE_SOFTWARE_INTERRUPT :
    (mip_mtip && mie_mtie) ? MCAUSE_MACHINE_TIMER_INTERRUPT : 
    (mip_seip && mie_seie) ? MCAUSE_SUPERVISOR_EXTERNAL_INTERRUPT :
    (mip_ssip && mie_ssie) ? MCAUSE_SUPERVISOR_SOFTWARE_INTERRUPT :
    (mip_stip && mie_stie) ? MCAUSE_SUPERVISOR_TIMER_INTERRUPT : 
    32'b0
);
wire [31:0] exception_cause = (
    MCAUSE_ENVIRONMENT_CALL_FROM_U_MODE + {30'b0, mode} // ecall
);
wire [31:0] trap_cause = may_expt ? exception_cause : interrupt_cause;

// 3.1.8. Machine Trap Delegation Registers (medeleg and mideleg)
// S-modeに委譲されているとき、M-modeならM-modeにトラップする。S-mode, U-modeならS-modeにトラップする。
wire interrupt_to_mmode = mideleg[interrupt_cause[4:0]] == 0;
wire exception_to_mmode = medeleg[exception_cause[4:0]] == 0;
wire trap_to_mmode = mode == M_MODE || (may_expt ? exception_to_mmode : interrupt_to_mmode);

// trapが起こりそうかどうか
wire may_expt = (
    csr_cmd == CSR_ECALL // ecall
);
wire may_interrupt = (interrupt_to_mmode ? global_mie : global_sie) &&
(
    (mip_meip && mie_meie) ||
    (mip_msip && mie_msie) ||
    (mip_mtip && mie_mtie) ||
    (mip_seip && mie_seie) ||
    (mip_ssip && mie_ssie) ||
    (mip_stip && mie_stie)
);
wire may_trap = may_expt || may_interrupt;

wire [11:0] addr = csr_imm_i[11:0];

function [31:0] wdata_fun(
    input [2:0]  csr_cmd,
    input [31:0] op1_data,
    input [31:0] rdata
);
case (csr_cmd)
    CSR_W  : wdata_fun = op1_data;
    CSR_S  : wdata_fun = rdata | op1_data;
    CSR_C  : wdata_fun = rdata & ~op1_data;
    default: wdata_fun = 0;
endcase
endfunction

function [31:0] rdata_f(
    input [11:0] addr,
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
    ADDR_CYCLE:     rdata_f = reg_cycle[31:0];
    ADDR_TIME:      rdata_f = reg_time[31:0];
    ADDR_CYCLEH:    rdata_f = reg_cycle[63:32];
    ADDR_TIMEH:     rdata_f = reg_time[63:32];
    // Machine Trap Setup
    ADDR_MSTATUS:   rdata_f = mstatus;
    ADDR_MISA:      rdata_f = misa;
    ADDR_MEDELEG:   rdata_f = medeleg;
    ADDR_MIDELEG:   rdata_f = mideleg;
    ADDR_MIE:       rdata_f = mie;
    ADDR_MTVEC:     rdata_f = mtvec;
    ADDR_MSTATUSH:  rdata_f = mstatush;
    // Machine Trap Handling
    ADDR_MSCRATCH:  rdata_f = mscratch;
    ADDR_MEPC:      rdata_f = mepc;
    ADDR_MCAUSE:    rdata_f = mcause;
    ADDR_MIP:       rdata_f = mip;
    ADDR_MTINST:    rdata_f = mtinst;
    ADDR_MTVAL2:    rdata_f = mtvec2;
    // Machine Counter/Timers
    ADDR_MCYCLE:    rdata_f = reg_cycle[31:0];
    ADDR_MCYCLEH:   rdata_f = reg_cycle[63:32];
    // Supervisor Trap Setup
    ADDR_SSTATUS:   rdata_f = sstatus;
    ADDR_SIE:       rdata_f = sie;
    ADDR_STVEC:     rdata_f = stvec;
    // Supervisor Trap Handling
    ADDR_SSCRATCH:  rdata_f = sscratch;
    ADDR_SEPC:      rdata_f = sepc;
    ADDR_SCAUSE:    rdata_f = scause;
    // ADDR_STVAL:     rdata_f = stval;
    ADDR_SIP:       rdata_f = sip;
    // Supervisor Protection and Translation
    ADDR_SATP:      rdata_f = satp; 
    default:        rdata_f = 32'b0;
endcase
endfunction

wire [31:0] wdata = wdata_fun(csr_cmd, op1_data, rdata);
wire [31:0] rdata = can_read ? rdata_f(
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
assign csr_mem_csr_rdata = rdata;

// 2.1 CSR Address Mapping Conventions
wire can_access = addr[9:8] <= mode;
wire can_read   = can_access;
wire can_write  = can_access && addr[11:10] != 2'b11;

IId saved_inst_id = IID_RANDOM;
always @(posedge clk) begin
    if (csr_valid)
        saved_inst_id <= csr_inst_id;
end

wire cmd_is_2clock  = csr_cmd[2] != 1'b0;
wire cmd_is_trap    = csr_cmd[2] == 1'b1;
wire cmd_is_write = csr_cmd == CSR_W || csr_cmd == CSR_S || csr_cmd == CSR_C;

assign csr_stall_flg = csr_valid &&
                       cmd_is_2clock &&
                       (csr_inst_id != saved_inst_id);
assign csr_trap_flg  = csr_valid && (may_trap || cmd_is_trap);

assign output_mode = mode;
assign output_satp = satp;
assign satp_change_hazard = csr_valid && ((can_write && cmd_is_write && addr == ADDR_SATP) || csr_ctrl.svinval); // SVINVALはsatpを変えてしまったものとして扱うことでflushする

// mret, sret, ecallのtrap_vectorはレジスタ経由で渡す
// 割り込み、例外はワイヤで渡す
reg [31:0] trap_vector;
assign csr_trap_vector = may_trap ? (trap_to_mmode ? mtvec_addr : stvec_addr) : trap_vector;

always @(posedge clk) begin
if (csr_valid) begin
    // trapを起こす
    if (may_trap) begin
        `ifdef PRINT_DEBUGINFO
            $display("info,csrstage.trap.pc,0x%h", pc);
            $display("info,csrstage.trap.to_mmode,%b", trap_to_mmode);
            $display("info,csrstage.trap.cause,0x%h", mtvec_addr);
            $display("info,csrstage.trap.mtvec,0x%h", mtvec_addr);
            $display("info,csrstage.trap.stvec,0x%h", stvec_addr);
        `endif
        // 3.1.6.1
        // To support nested traps, each privilege mode x that can respond to interrupts has a two-level stack of
        // interrupt-enable bits and privilege modes. xPIE holds the value of the interrupt-enable bit active prior
        // to the trap, and xPP holds the previous privilege mode. The xPP fields can only hold privilege modes
        // up to x, so MPP is two bits wide and SPP is one bit wide. When a trap is taken from privilege mode y
        // into privilege mode x, xPIE is set to the value of xIE; xIE is set to 0; and xPP is set to y
        if (trap_to_mmode) begin
            mode         <= M_MODE;
            mcause       <= trap_cause;
            mepc         <= pc;
            mstatus_mpie <= mstatus_mie;
            mstatus_mie  <= 0;
            mstatus_mpp  <= mode;
        end else begin
            mode         <= S_MODE;
            scause       <= trap_cause;
            sepc         <= pc;
            mstatus_spie <= mstatus_sie;
            mstatus_sie  <= 0;
            mstatus_spp  <= mode[0];
        end
        // interruptならmipを0にする
        if (!may_expt) begin
                 if (mip_meip && mie_meie) mip_meip <= 0;
            else if (mip_msip && mie_msie) mip_msip <= 0;
            else if (mip_mtip && mie_mtie) mip_mtip <= 0;
            else if (mip_seip && mie_seie) mip_seip <= 0;
            else if (mip_ssip && mie_ssie) mip_ssip <= 0;
            else if (mip_stip && mie_stie) mip_stip <= 0;
        end
    end else begin
        // pending registerを更新する
        mip_mtip <= reg_mtime >= reg_mtimecmp;
        if (csr_inst_id != saved_inst_id) begin
            // mret, sretを処理する
            case (csr_cmd)
                // MRET, SRET
                // 3.1.6.1
                // An MRET or SRET instruction is used to return from a trap in M-mode or S-mode respectively. When
                // executing an xRET instruction, supposing xPP holds the value y, xIE is set to xPIE; the privilege mode is
                // changed to y; xPIE is set to 1; and xPP is set to the least-privileged supported mode (U if U-mode is
                // implemented, else M). If y≠M, xRET also sets MPRV=0.
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
                default: begin end
            endcase
        end

        if (can_write && cmd_is_write) begin
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
                    mideleg_custom <= wdata[31:16];
                    mideleg_meip <= wdata[11];
                    mideleg_seip <= wdata[9];
                    mideleg_mtip <= wdata[7];
                    mideleg_stip <= wdata[5];
                    mideleg_msip <= wdata[3];
                    mideleg_ssip <= wdata[1];
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
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,csrstage.valid,b,%b", csr_valid);
    $display("data,csrstage.inst_id,h,%b", csr_cmd == CSR_X || !csr_valid ? IID_X : inst_id);
    if (csr_valid && (csr_cmd != CSR_X || may_trap)) begin
        $display("data,csrstage.pc,h,%b", pc);
        $display("data,csrstage.inst,h,%b", csr_inst);

        $display("data,csrstage.mode,d,%b", mode);
        $display("data,csrstage.csr_cmd,d,%b", csr_cmd);
        $display("data,csrstage.addr,h,%b", addr);
        $display("data,csrstage.wdata,h,%b", wdata);
        $display("data,csrstage.rdata,h,%b", rdata);
        $display("data,csrstage.trap_vector,h,%b", trap_vector);
        $display("data,csrstage.csr_trap_flg,b,%b", csr_trap_flg);
        $display("data,csrstage.csr_stall_flg,b,%b", csr_stall_flg);
        $display("data,csrstage.may_trap,b,%b", may_trap);
    end
end
`endif

endmodule