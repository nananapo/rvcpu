module CSRStage #(
    parameter FMAX_MHz = 27
)
(
    input  wire         clk,
    
    input wire [63:0]   reg_cycle,
    input wire [63:0]   reg_time,
    input wire [63:0]   reg_mtime,
    input wire [63:0]   reg_mtimecmp,

    input wire          wb_branch_hazard,
    
    // input
    input wire [2:0]    input_csr_cmd,
    input wire [31:0]   input_op1_data,
    input wire [31:0]   input_imm_i,

    // interruptができる状態(ほかのステージがnopか)どうか
    input wire          input_interrupt_ready,
    // Fetchステージのpc
    input wire [31:0]   if_reg_pc,

    // output
    output reg  [2:0]   output_csr_cmd,
    output reg  [31:0]  csr_rdata,
    output reg  [31:0]  trap_vector,

    // trapを起こしたいときにEXE以前を止めるために使う
    output wire         output_stall_flg_may_interrupt
);

`include "include/core.v"

// モード
localparam MODE_MACHINE     = 2'b11;
//localparam HYPERVISOR_MODE  = 2'b10;
localparam MODE_SUPERVISOR  = 2'b01;
localparam MODE_USER        = 2'b00;

// 現在のモード
reg [1:0]   mode = MODE_MACHINE;


/*-------実装済みのCSRたち--------*/

// Counters and Timers
localparam CSR_ADDR_CYCLE       = 12'hc00;
localparam CSR_ADDR_TIME        = 12'hc01;
localparam CSR_ADDR_CYCLEH      = 12'hc80;
localparam CSR_ADDR_TIMEH       = 12'hc81;
// TODO? INSTRET

// Machine Information Registers
localparam CSR_ADDR_MVENDORID   = 12'hf11;
localparam CSR_ADDR_MARCHID     = 12'hf12;
localparam CSR_ADDR_MIMPID      = 12'hf13;
localparam CSR_ADDR_MHARTID     = 12'hf14;
localparam CSR_ADDR_MCONFIGPTR  = 12'hf15;

reg [31:0] reg_mvendorid    = 32'b0;
reg [31:0] reg_marchid      = 32'b0;
reg [31:0] reg_mimpid       = 32'b0;
reg [31:0] reg_mhartid      = 32'b0;

// Machine Trap Setup
/*
基本はマシンモードで処理
trapは高い特権モードから低い特権モードに遷移することはない
ただ、同じ特権モードに遷移することはある

3.1.7
S-modeからM-modeにトラップするとき、
mpieはmieになる。mieは0になる。mppはSになる(S-modeを表すものになる)

3.1.7
mretする。MPPが権限モードyを表しているとする。
MIEはMPIEに変更される。MIPEは1になる。
MPPはサポートされてる最も低い権限モードの値に設定される。
(UがサポートされてたらU、それ以外はM)
(UではなくSの場合は？)
MPP!=Mの時、MPRVを0に設定する

3.1.8
RV32なら、SXL, UXLは32で固定

3.1.6.3
MPRVは有効な特権モードを変更する
MPRV=0:
    普通。現在のモードのtranslation(ページング？)とプロテクション機構を使う
MPRV=1:
    現在のモードがMPPに設定されてるかのように
    load, storeのアドレスはtranslate & protected。エンディアンも*
    命令は関係ない
UモードがサポートされてないならMPRV=read-only 0

M->S, U、S->Urにretするとき、mprvは0になる

MXRが有効だと、ReadableだけでなくてExecutableも読めるようになる
ページベースの仮想メモリじゃないなら意味なし
*/
localparam CSR_ADDR_MSTATUS     = 12'h300;
localparam CSR_ADDR_MISA        = 12'h301;
localparam CSR_ADDR_MEDELEG     = 12'h302;
localparam CSR_ADDR_MIDELEG     = 12'h303;
localparam CSR_ADDR_MIE         = 12'h304;
localparam CSR_ADDR_MTVEC       = 12'h305;
localparam CSR_ADDR_MCOUNTEREN  = 12'h306;
localparam CSR_ADDR_MSTATUSH    = 12'h310;

reg         reg_mstatus_sd      = 0;
//reg [7:0]   reg_mstatus_wpri    = 0;
reg         reg_mstatus_tsr     = 0;
reg         reg_mstatus_tw      = 0;
reg         reg_mstatus_tvm     = 0;
reg         reg_mstatus_mxr     = 0;
reg         reg_mstatus_sum     = 0;
reg         reg_mstatus_mprv    = 0;
reg [1:0]   reg_mstatus_xs      = 0;
reg [1:0]   reg_mstatus_fs      = 0;
// S-modeでtrapしても書き込まれない
reg [1:0]   reg_mstatus_mpp     = MODE_MACHINE; // 初期値をM-modeにする
reg [1:0]   reg_mstatus_vs      = 0;
// S-modeでtrapしたとき、アクティブなとモードが書き込まれる
reg         reg_mstatus_spp     = 0;
// S-modeでtrapしても書き込まれない
reg         reg_mstatus_mpie    = 0;
reg         reg_mstatus_ube     = 0;
// S-modeでtrapした時、sieが書き込まれる
reg         reg_mstatus_spie    = 0;
//reg         reg_mstatus_wpri    = 0;
// M-modeでtrapしたとき、クリアされる
reg         reg_mstatus_mie     = 0;
//reg         reg_mstatus_wpri    = 0;
// S-modeでtrapしたとき、クリアされる
reg         reg_mstatus_sie     = 0;
//reg         reg_mstatus_wpri    = 0;

// XLENや実装されている拡張を提供する
// WARLなので、この実装ではwriteを実装しない(くていいはず?)
// A, I, M拡張を実装しているのでそのbitを立てている
//                                   |MXL|0 |Extensions                |
//                                           ZYXWVUTSRQPONMLKJIHGFEDCBA
reg [31:0]  reg_misa            = 32'b01_000_00000000000001000100000001;

// サポートしないtrapは0を保持する
// 1はreadonlyであってはならない。
// デリゲートできるasynchronous trapはデリゲートされないことも必ずサポートしないといけない
reg [31:0]  reg_medeleg         = 0;

// サポートしないtrapは0を保持する
// machine-levelの割り込みに対して1のread-onlyなbitを作ってはいけない
// それ以外はOK
reg         reg_mideleg_mtie    = 0; // 7

reg         reg_mie_meie        = 0; // external interrupt、つまり何～？
reg         reg_mie_seie        = 0;
reg         reg_mie_mtie        = 0; // 7 timer interrupt
reg         reg_mie_stie        = 0;
reg         reg_mie_msie        = 0; // software interrupt、つまりecall?
reg         reg_mie_ssie        = 0;

reg [31:0]  reg_mtvec           = 0;

//reg         reg_mcounteren; // read-only zeroでよい

//reg [25:0]  reg_mstatush_wpri   = 0;
reg         reg_mstatush_mbe    = 0;
reg         reg_mstatush_sbe    = 0;
//reg [3:0]   reg_mstatush_wpri   = 0;

// Machine Trap Handling
/*
3.1.9
割り込みiがM-modeにトラップする条件(全部trueのとき)
(a) 今のモードがMで、mstatusのMIEがsetされてる(1?) / または、M-modeより低いモード
(b) mipとmieでiがsetされている
(c) midelegがあるなら、iがmidelegに設定されていない

3.1.14
M-modeにトラップするとき、mepcにはtrapが発生した時の(仮想)アドレスを設定する
それ以外では書かない、ソフトウェアも書き込む
-> ecallで書き込むってこと？
*/
localparam CSR_ADDR_MSCRATCH    = 12'h340; // 自由
localparam CSR_ADDR_MEPC        = 12'h341; // M-modeにトラップするとき、仮想アドレスに設定する
localparam CSR_ADDR_MCAUSE      = 12'h342; // trapするときに書き込む。上位1bitでInterruptかを判断する
localparam CSR_ADDR_MTVAL       = 12'h343; // exceptionなら実装によって書き込まれる。だが、read-only zeroでもよい(そういう実装にできる)
localparam CSR_ADDR_MIP         = 12'h344; // 3.1.9
localparam CSR_ADDR_MTINST      = 12'h34a; // 0でいい、 8.6.3に書いてある?
localparam CSR_ADDR_MTVAL2      = 12'h34b; // 0でいい

/*
Table 3.6
I ECODE Description
1 1     Supervisor software interrupt
1 3     Machine software interrupt
1 5     Supervisor timer interrupt
1 7     Machine timer interrupt
1 9     Supervisor external interrupt
1 11    Machine external interrupt
*/
localparam MCAUSE_SUPERVISOR_SOFTWARE_INTERRUPT = 32'b10000000_00000000_00000000_00000001;
localparam MCAUSE_MACHINE_SOFTWARE_INTERRUPT    = 32'b10000000_00000000_00000000_00000011;
localparam MCAUSE_SUPERVISOR_TIMER_INTERRUPT    = 32'b10000000_00000000_00000000_00000101;
localparam MCAUSE_MACHINE_TIMER_INTERRUPT       = 32'b10000000_00000000_00000000_00000111;
localparam MCAUSE_SUPERVISOR_EXTERNAL_INTERRUPT = 32'b10000000_00000000_00000000_00001001;
localparam MCAUSE_MACHINE_EXTERNAL_INTERRUPT    = 32'b10000000_00000000_00000000_00001011;
/*
Table 3.6
I ECODE Description
0 0     Instruction address misaligned
0 1     Instruction access fault
0 2     Illegal instruction
0 3     Breakpoint
0 4     Load address misaligned
0 5     Load access fault
0 6     Store/AMO address misaligned
0 7     Store/AMO access fault
0 8     Environment call from U-mode
0 9     Environment call from S-mode
0 11    Environment call from M-mode
0 12    Instruction page fault
0 13    Load page fault
0 15    Store/AMO page fault
*/
localparam MCAUSE_INSTRUCTION_ADDRESS_MISALIGNED    = 32'b0000;
localparam MCAUSE_INSTRUCTION_ACCESS_FAULT          = 32'b0001;
localparam MCAUSE_ILLEGAL_INSTRUCTION               = 32'b0010;
localparam MCAUSE_BREAKPOINT                        = 32'b0011;
localparam MCAUSE_LOAD_ADDRESS_MISALIGNED           = 32'b0100;
localparam MCAUSE_LOAD_ACCESS_FAULT                 = 32'b0101;
localparam MCAUSE_STORE_AMO_ADDRESS_MISALIGNED      = 32'b0110;
localparam MCAUSE_STORE_AMO_ACCESS_FAULT            = 32'b0111;
localparam MCAUSE_ENVIRONMENT_CALL_FROM_U_MODE      = 32'b1000;
localparam MCAUSE_ENVIRONMENT_CALL_FROM_S_MODE      = 32'b1001;
localparam MCAUSE_ENVIRONMENT_CALL_FROM_M_MODE      = 32'b1011;
localparam MCAUSE_INSTRUCTION_PAGE_FAULT            = 32'b1100;
localparam MCAUSE_LOAD_PAGE_FAULT                   = 32'b1101;
localparam MCAUSE_STORE_AMO_PAGE_FAULT              = 32'b1111;

/*
Table43.7 
Priority Exc. Code Description

Highest
3           Instruction address breakpoint
---
12, 1       First encountered page fault or access fault
---
1           Instruction access fault
---
2           Illegal instruction
0           Instruction address misaligned
8, 9, 11    Environment call
3           Environment break
3           Load/store/AMO address breakpoint
---
13,15,5,7   First encountered page fault or access fault
---
5, 7        Load/store/AMO access fault
---
4, 6        Load/store/AMO address misaligned
Lowest
*/


reg [31:0]  reg_mscratch    = 0;
reg [31:0]  reg_mepc        = 0;
reg [31:0]  reg_mcause      = 0;
// reg [31:0]  reg_mtval       = 0;

// 3.1.9
// Multiple simultaneous interrupts destined for M-mode are handled in the following decreasing
// priority order: MEI, MSI, MTI, SEI, SSI, STI.
reg         reg_mip_meip    = 0;
reg         reg_mip_seip    = 0;
wire        wire_mip_mtip   = reg_mtime >= reg_mtimecmp;
reg         reg_mip_stip    = 0;
reg         reg_mip_msip    = 0;
reg         reg_mip_ssip    = 0;

reg [31:0]  reg_mtinst      = 0;
// reg [31:0]  reg_mtval2      = 0;

// Machine Memory Protection
localparam CSR_ADDR_PMPADDR0    = 12'h3B0;
localparam CSR_ADDR_PMPCFG0     = 12'h3A0;

reg [31:0]  reg_pmpaddr0    = 0;
reg [31:0]  reg_pmpcfg0     = 0;

// Machine Counter/Timers
localparam CSR_ADDR_MCYCLE      = 12'hb00;
localparam CSR_ADDR_MINSTRET    = 12'hb02;
localparam CSR_ADDR_MCYCLEH     = 12'hb80;
localparam CSR_ADDR_MINSTRETH   = 12'hb82;

// Supervisor Trap Setup
localparam CSR_ADDR_SSTATUS     = 12'h100;
localparam CSR_ADDR_SIE         = 12'h104;
localparam CSR_ADDR_STVEC       = 12'h105;
localparam CSR_ADDR_SCOUNTEREN  = 12'h106; // 4.1.5 cycle, time, instret, or hpmcounternにアクセスできるかどうかのフラグ 

// reg [31:0]  reg_sstatus     = 0;
// reg [31:0]  reg_sie         = 0;
reg [31:0]  reg_stvec       = 0;
// reg reg_scounteren; // read-only zeroでよい

// Supervisor Configuration
localparam CSR_ADDR_SENVCFG     = 12'h10a; // 後で調べる

// Supervisor Trap Handling
localparam CSR_ADDR_SSCRATCH    = 12'h140;
localparam CSR_ADDR_SEPC        = 12'h141;
localparam CSR_ADDR_SCAUSE      = 12'h142;
localparam CSR_ADDR_STVAL       = 12'h143;
localparam CSR_ADDR_SIP         = 12'h144;

reg [31:0]  reg_sscratch    = 0;
reg [31:0]  reg_sepc        = 0;
reg [31:0]  reg_scause      = 0;
// reg [31:0]  reg_stval       = 0;
// sipはmipのサブセット
// reg [31:0]  reg_sip         = 0;

// Supervisor Protection and Translation
localparam CSR_ADDR_SATP        = 12'h180;

reg [31:0]  reg_satp        = 0;

// Debug/Trace Registers
localparam CSR_ADDR_SCONTEXT    = 12'h5a8;

reg [31:0]  reg_scontext    = 0; // わからん



// タイマ割りこみが起こりそうかどうか
wire machine_timer_interrupt_active = reg_mstatus_mie && reg_mie_mtie;

wire may_trap = machine_timer_interrupt_active;

assign output_stall_flg_may_interrupt = may_trap;

// 現在起きるinterruptのcause(とりあえず0)
// priority : MEI, MSI, MTI, SEI, SSI, STI
wire [31:0] interrupt_cause  = machine_timer_interrupt_active ? MCAUSE_MACHINE_TIMER_INTERRUPT : 32'b0;

// 現在起きるinterruptがM-modeへのトラップを起こすかのフラグ
wire trap_to_machine_mode   = 1;

// mtvecのMODEを考慮した飛び先
// 3.1.7
// MODE = Direct(0)     : BASE
// MODE = Vectored(1)   : BASE + cause * 4
wire [31:0] mtvec_addr = reg_mtvec[1:0] == 2'b00 ? reg_mtvec : {reg_mtvec[31:2], 2'b0} + {interrupt_cause[29:0], 2'b0};
// stvecのMODEを考慮した飛び先
wire [31:0] stvec_addr = reg_stvec[1:0] == 2'b00 ? reg_stvec : {reg_stvec[31:2], 2'b0} + {interrupt_cause[29:0], 2'b0};


/*---------CSR命令の実行----------*/
initial begin
    output_csr_cmd  = CSR_X;
    csr_rdata       = 0;
end

wire [2:0] csr_cmd  = wb_branch_hazard ? CSR_X : input_csr_cmd;
wire [31:0]op1_data = wb_branch_hazard ? 32'hffffffff : input_op1_data;
wire [31:0]imm_i    = wb_branch_hazard ? 32'hffffffff : input_imm_i;

// ecallなら0x342を読む
wire [11:0] addr = imm_i[11:0];

function [31:0] wdata_fun(
    input [2:0] csr_cmd,
    input [31:0]op1_data,
    input [31:0]csr_rdata
);
    case (csr_cmd)
        CSR_W       : wdata_fun = op1_data;
        CSR_S       : wdata_fun = csr_rdata | op1_data;
        CSR_C       : wdata_fun = csr_rdata & ~op1_data;
        default     : wdata_fun = 0;
    endcase
endfunction

reg [2:0] save_csr_cmd  = CSR_X;
reg [11:0]save_csr_addr = 0;
reg [31:0]save_op1_data = 0;

wire [31:0] wdata = wdata_fun(save_csr_cmd, save_op1_data, csr_rdata);

wire can_access = addr[9:8] <= mode;
wire can_read   = can_access && addr[11] == 0;
wire can_write  = can_access && addr[10] == 0;

always @(posedge clk) begin

    // 割り込みを起こす
    if (may_trap && input_interrupt_ready) begin
        `ifdef PRINT_DEBUGINFO
            $display("INTERRUPT pc : 0x%H", if_reg_pc);
        `endif
        // ECALLということにする
        output_csr_cmd      <= CSR_ECALL;

        if (trap_to_machine_mode) begin
            // M-modeに遷移
            mode                <= MODE_MACHINE;

            reg_mcause          <= interrupt_cause;
            reg_mepc            <= if_reg_pc;
            //reg_mtval           <= 0;
            reg_mstatus_mpp     <= mode;
            reg_mstatus_mpie    <= reg_mstatus_mie;
            reg_mstatus_mie     <= 0;

            trap_vector         <= mtvec_addr;
        end else begin
            // S-modeに遷移
            mode                <= MODE_SUPERVISOR;

            reg_scause          <= interrupt_cause;
            reg_sepc            <= if_reg_pc;
            // reg_stval           <= 0;
            reg_mstatus_spp     <= mode[0];
            reg_mstatus_spie    <= reg_mstatus_sie;
            reg_mstatus_sie     <= 0;

            trap_vector         <= stvec_addr;
        end
    end else begin
        output_csr_cmd  <= csr_cmd;

        // 例外、mret, sretを処理する
        case (csr_cmd)
            CSR_ECALL: begin
                // environment call from x-Mode execeptionを起こす
                trap_vector <= mode == MODE_USER ? stvec_addr : mtvec_addr;
                // 現在のモードに応じた値を書き込む
                case (mode)
                    MODE_USER:          reg_mcause <= MCAUSE_ENVIRONMENT_CALL_FROM_U_MODE; 
                    MODE_SUPERVISOR:    reg_mcause <= MCAUSE_ENVIRONMENT_CALL_FROM_S_MODE; 
                    MODE_MACHINE:       reg_mcause <= MCAUSE_ENVIRONMENT_CALL_FROM_M_MODE;
                    default:            reg_mcause <= 0;// TODO
                endcase
                // 一つ上の特権レベルに遷移する
                mode        <= mode == MODE_USER ? MODE_SUPERVISOR : MODE_MACHINE;
            end
            CSR_MRET: begin
                trap_vector     <= reg_mepc;
                mode            <= reg_mstatus_mpp;
                reg_mstatus_mpp <= MODE_USER;
                reg_mstatus_mie <= reg_mstatus_mpie;
                if (reg_mstatus_mpp != MODE_MACHINE) begin
                    reg_mstatus_mprv <= 0;
                end
            end
            CSR_SRET: begin
                trap_vector     <= reg_sepc;
                mode            <= {1'b0, reg_mstatus_spp};
                reg_mstatus_spp <= MODE_USER[0];
                reg_mstatus_sie <= reg_mstatus_spie;
                reg_mstatus_mprv<= 0;
            end
            default: begin end
        endcase 
    end

    if (can_read) begin
        case (addr)
            // Counters and Timers
            // TODO アクセス制御を共通化したい
            CSR_ADDR_CYCLE: csr_rdata <= reg_cycle[31:0];
            CSR_ADDR_TIME:  csr_rdata <= reg_time[31:0];
            CSR_ADDR_CYCLEH:csr_rdata <= reg_cycle[63:32];
            CSR_ADDR_TIMEH: csr_rdata <= reg_time[63:32];

            // Machine Information Registers
            CSR_ADDR_MVENDORID: csr_rdata <= reg_mvendorid;
            CSR_ADDR_MARCHID:   csr_rdata <= reg_marchid;
            CSR_ADDR_MIMPID:    csr_rdata <= reg_mimpid;
            CSR_ADDR_MHARTID:   csr_rdata <= reg_mhartid;
            // CSR_ADDR_MCONFIGPTR: read-only zero

            // Machine Trap Setup
            CSR_ADDR_MSTATUS:   csr_rdata <= {
                reg_mstatus_sd,
                8'b0,
                reg_mstatus_tsr,
                reg_mstatus_tw,
                reg_mstatus_tvm,
                reg_mstatus_mxr,
                reg_mstatus_sum,
                reg_mstatus_mprv,
                reg_mstatus_xs,
                reg_mstatus_fs,
                reg_mstatus_mpp,
                reg_mstatus_vs,
                reg_mstatus_spp,
                reg_mstatus_mpie,
                reg_mstatus_ube,
                reg_mstatus_spie,
                1'b0,
                reg_mstatus_mie,
                1'b0,
                reg_mstatus_sie,
                1'b0
            };
            CSR_ADDR_MISA:      csr_rdata <= reg_misa;
            CSR_ADDR_MEDELEG:   csr_rdata <= reg_medeleg;
            CSR_ADDR_MIDELEG:   csr_rdata <= {
                24'b0,
                reg_mideleg_mtie,
                7'b0
            };
            CSR_ADDR_MIE:       csr_rdata <= {
                16'b0,
                4'b0,
                reg_mie_meie, 1'b0,
                reg_mie_seie, 1'b0,
                reg_mie_mtie, 1'b0,
                reg_mie_stie, 1'b0,
                reg_mie_msie, 1'b0,
                reg_mie_ssie, 1'b0
            };
            CSR_ADDR_MTVEC:     csr_rdata <= reg_mtvec;
            // CSR_ADDR_MCOUNTEREN: 0
            CSR_ADDR_MSTATUSH:  csr_rdata <= {
                26'b0,
                reg_mstatush_mbe,
                reg_mstatush_sbe,
                4'b0
            };

            // Machine Trap Handling
            CSR_ADDR_MSCRATCH:  csr_rdata <= reg_mscratch;
            CSR_ADDR_MEPC:      csr_rdata <= reg_mepc;
            CSR_ADDR_MCAUSE:    csr_rdata <= reg_mcause;
            // CSR_ADDR_MTVAL:  read-only zero
            CSR_ADDR_MIP:       csr_rdata <= {
                20'b0,
                reg_mip_meip, 1'b0,
                reg_mip_seip, 1'b0,
                wire_mip_mtip, 1'b0,
                reg_mip_stip, 1'b0,
                reg_mip_msip, 1'b0,
                reg_mip_ssip, 1'b0
            };
            // CSR_ADDR_MTINST:    0
            // CSR_ADDR_MTVAL2:    0

            // Machine Memory Protection
            CSR_ADDR_PMPADDR0:  csr_rdata <= reg_pmpaddr0;
            CSR_ADDR_PMPCFG0:   csr_rdata <= reg_pmpcfg0;

            // Machine Counter/Timers
            CSR_ADDR_MCYCLE:    csr_rdata <= reg_cycle[31:0];
            // CSR_ADDR_MINSTRET: not impl
            CSR_ADDR_MCYCLEH:   csr_rdata <= reg_cycle[63:32];
            // CSR_ADDR_MINSTRETH: not impl

            // Supervisor Trap Setup
            // sstatusはmstatusのサブセット
            CSR_ADDR_SSTATUS:       csr_rdata <= {
                reg_mstatus_sd,
                11'b0,
                reg_mstatus_mxr,
                reg_mstatus_sum,
                1'b0,
                reg_mstatus_xs,
                reg_mstatus_fs,
                2'b0,
                reg_mstatus_vs,
                reg_mstatus_spp,
                1'b0,
                reg_mstatus_ube,
                reg_mstatus_spie,
                3'b0,
                reg_mstatus_sie,
                1'b0
            };
            // sieはmieのサブセット
            CSR_ADDR_SIE:           csr_rdata <= {
                16'b0,
                6'b0,
                reg_mie_seie,
                3'b0,
                reg_mie_stie,
                3'b0,
                reg_mie_ssie,
                1'b0
            };
            CSR_ADDR_STVEC:         csr_rdata <= reg_stvec;
            // CSR_ADDR_SCOUNTEREN: 0

            // Supervisor Trap Handling
            CSR_ADDR_SSCRATCH:  csr_rdata <= reg_sscratch;
            CSR_ADDR_SEPC:      csr_rdata <= reg_sepc;
            CSR_ADDR_SCAUSE:    csr_rdata <= reg_scause;
            // CSR_ADDR_STVAL:     csr_rdata <= reg_stval;
            CSR_ADDR_SIP:       csr_rdata <= {
                22'b0,
                reg_mip_seip, 1'b0,
                2'b0,
                reg_mip_stip, 1'b0,
                2'b0,
                reg_mip_ssip, 1'b0
            };

            // Supervisor Protection and Translation
            CSR_ADDR_SATP:      csr_rdata <= reg_satp; 

            default:            csr_rdata <= 32'b0;
        endcase
    end else begin
        csr_rdata <= 32'b0;
        // TODO trap
    end

    save_csr_cmd    <= csr_cmd;
    save_csr_addr   <= addr;
    save_op1_data   <= op1_data;

    case (save_csr_cmd)
        CSR_X: begin end
        CSR_ECALL: begin end
        CSR_MRET: begin end
        CSR_SRET: begin end
        default: begin
            if (can_write) begin
                case (save_csr_addr)
                    // Counters and Timers
                    // READ ONLY
                    // CSR_ADDR_CYCLE:
                    // CSR_ADDR_TIME:
                    // CSR_ADDR_CYCLEH:
                    // CSR_ADDR_TIMEH:
                    
                    // Machine Information Registers
                    // READ ONLY
                    // CSR_ADDR_MVENDORID: 
                    // CSR_ADDR_MARCHID:
                    // CSR_ADDR_MIMPID:
                    // CSR_ADDR_MHARTID:
                    // CSR_ADDR_MCONFIGPTR: read-only zero

                    // Machine Trap Setup
                    CSR_ADDR_MSTATUS: begin
                        reg_mstatus_sd      <= wdata[31];
                        //reg_mstatus_wpri    <= wdata[30:23];
                        reg_mstatus_tsr     <= wdata[22];
                        reg_mstatus_tw      <= wdata[21];
                        reg_mstatus_tvm     <= wdata[10];
                        reg_mstatus_mxr     <= wdata[19];
                        reg_mstatus_sum     <= wdata[18];
                        reg_mstatus_mprv    <= wdata[17];
                        reg_mstatus_xs      <= wdata[16:15];
                        reg_mstatus_fs      <= wdata[14:13];
                        reg_mstatus_mpp     <= wdata[12:11];
                        reg_mstatus_vs      <= wdata[10:9];
                        reg_mstatus_spp     <= wdata[8];
                        reg_mstatus_mpie    <= wdata[7];
                        reg_mstatus_ube     <= wdata[6];
                        reg_mstatus_spie    <= wdata[5];
                        //reg_mstatus_wpri    <= wdata[4];
                        reg_mstatus_mie     <= wdata[3];
                        //reg_mstatus_wpri    <= wdata[2];
                        reg_mstatus_sie     <= wdata[1];
                        //reg_mstatus_wpri    <= wdata[0];
                    end
                    // CSR_ADDR_MISA: READ ONLY
                    CSR_ADDR_MEDELEG:   reg_medeleg <= wdata;
                    CSR_ADDR_MIDELEG: begin
                        reg_mideleg_mtie <= wdata[7]; 
                    end
                    CSR_ADDR_MIE: begin
                        reg_mie_meie <= wdata[11];
                        reg_mie_seie <= wdata[9];
                        reg_mie_mtie <= wdata[7];
                        reg_mie_stie <= wdata[5];
                        reg_mie_msie <= wdata[3];
                        reg_mie_ssie <= wdata[1];
                    end
                    CSR_ADDR_MTVEC:     reg_mtvec   <= wdata;
                    // CSR_ADDR_MCOUNTEREN:  READ ONLY
                    CSR_ADDR_MSTATUSH: begin
                        //reg_mstatush_wpri   <= wdata[31:6],
                        reg_mstatush_mbe    <= wdata[5];
                        reg_mstatush_sbe    <= wdata[4];
                        //reg_mstatush_wpri   <= wdata[3:0];
                    end

                    // Machine Trap Handling
                    CSR_ADDR_MSCRATCH:  reg_mscratch <= wdata;
                    CSR_ADDR_MEPC:      reg_mepc     <= {wdata[31:2], 2'b00};
                    CSR_ADDR_MCAUSE:    reg_mcause   <= wdata;
                    // CSR_ADDR_MTVAL:  read-only zero
                    CSR_ADDR_MIP: begin
                        // reg_mip_meip    <= wdata[11]; // readonly
                        reg_mip_seip    <= wdata[9];
                        reg_mip_stip    <= wdata[5];
                        // reg_mip_msip    <= wdata[3]; // readonly
                        reg_mip_ssip    <= wdata[1];
                    end
                    // CSR_ADDR_MTINST:    0
                    // CSR_ADDR_MTVAL2:    0
            
                    // Machine Memory Protection
                    CSR_ADDR_PMPADDR0:  reg_pmpaddr0 <= wdata;
                    CSR_ADDR_PMPCFG0:   reg_pmpcfg0 <= wdata;

                    // Supervisor Trap Setup
                    CSR_ADDR_SSTATUS: begin
                        reg_mstatus_sd      <= wdata[31];
                        //reg_mstatus_wpri    <= wdata[30:20];
                        reg_mstatus_mxr     <= wdata[19];
                        reg_mstatus_sum     <= wdata[18];
                        //reg_mstatus_wpri    <= wdata[17];
                        reg_mstatus_xs      <= wdata[16:15];
                        reg_mstatus_fs      <= wdata[14:13];
                        //reg_mstatus_wpri    <= wdata[12:11];
                        reg_mstatus_vs      <= wdata[10:9];
                        reg_mstatus_spp     <= wdata[8];
                        //reg_mstatus_wpri    <= wdata[7];
                        reg_mstatus_ube     <= wdata[6];
                        reg_mstatus_spie    <= wdata[5];
                        //reg_mstatus_wpri    <= wdata[4:2];
                        reg_mstatus_sie     <= wdata[1];
                        //reg_mstatus_wpri    <= wdata[0];
                    end
                    CSR_ADDR_SIE: begin
                        reg_mie_seie <= wdata[9];
                        reg_mie_stie <= wdata[5];
                        reg_mie_ssie <= wdata[1];
                    end
                    CSR_ADDR_STVEC:     reg_stvec   <= wdata;
                    //CSR_ADDR_SCOUNTEREN: READ ONLY

                    // Supervisor Trap Handling
                    CSR_ADDR_SSCRATCH:  reg_sscratch <= wdata;
                    CSR_ADDR_SEPC:      reg_sepc <= wdata;
                    CSR_ADDR_SCAUSE:    reg_scause <= wdata;
                    // CSR_ADDR_STVAL:     reg_stval <= wdata;
                    CSR_ADDR_SIP: begin
                        reg_mip_seip    <= wdata[9];
                        reg_mip_stip    <= wdata[5];
                        reg_mip_ssip    <= wdata[1];
                    end

                    // Supervisor Protection and Translation
                    CSR_ADDR_SATP:      reg_satp    <= wdata; 

                    default: begin end
                endcase
            end else begin
                // TODO trap
            end
        end
    endcase
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("CSR STAGE------------");
    $display("mode         : %d", mode);
    $display("cmd          : %d", csr_cmd);
    $display("op1_data     : 0x%H", op1_data);
    $display("imm_i        : 0x%H", imm_i);
    $display("addr         : 0x%H", addr);
    $display("rdata        : 0x%H", csr_rdata);
    $display("wdata        : 0x%H", wdata);
    $display("trap_vector  : 0x%H", trap_vector);
    $display("mtvec        : 0x%H", reg_mtvec);
    $display("mtime        : 0x%H", reg_mtime);
    $display("mtimecmp     : 0x%H", reg_mtimecmp);
    $display("time.stall   : %d", timer_stall);
    $display("intr.ready   : %d", input_interrupt_ready);
end
`endif

endmodule