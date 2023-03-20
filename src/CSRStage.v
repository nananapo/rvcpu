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
localparam CSR_ADDR_MIPID       = 12'hf13;
localparam CSR_ADDR_MHARTID     = 12'hf14;
localparam CSR_ADDR_MCONFIGPTR  = 12'hf15;

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

reg         reg_mcounteren_ir   = 0; // S-mode, U-modeがinstretにアクセスできるかどうか
reg         reg_mcounteren_tm   = 0; // S-mode, U-modeがtimeにアクセスできるかどうか
reg         reg_mcounteren_cy   = 0; // S-mode, U-modeがcycleにアクセスできるかどうか

//reg [25:0]  reg_mstatush_wpri   = 0;
reg         reg_mstatush_mbe    = 0;
reg         reg_mstatush_sbe    = 0;
//reg [3:0]   reg_mstatush_wpri   = 0;

// Machine Trap Handling
/*
3.1.9
割り込みiがM-modeにトラップする条件(全部trueのとき)
(a) 今のモードがMで、mstatusのMIEがsetされてる(1?) / または、M-odeより低いモード
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
localparam CSR_ADDR_MTVAL       = 12'h343; // exceptionなら実装によって書き込まれる?
localparam CSR_ADDR_MIP         = 12'h344; // 3.1.9
localparam CSR_ADDR_MTINST      = 12'h34a; // 0でいい、 8.6.3に書いてある?
localparam CSR_ADDR_MTVAL2      = 12'h34b; // 0でいい

localparam MCAUSE_MACHINE_TIMER_INTERRUPT = 32'b10000000_00000000_00000000_10000000;

reg [31:0]  reg_mscratch    = 0;
reg [31:0]  reg_mepc        = 0;
reg [31:0]  reg_mcause      = 0;
reg [31:0]  reg_mtval       = 0;

reg         reg_mip_meip    = 0;
reg         reg_mip_seip    = 0;
reg         reg_mip_mtip    = 0;
reg         reg_mip_stip    = 0;
reg         reg_mip_msip    = 0;
reg         reg_mip_ssip    = 0;

reg [31:0]  reg_mtinst      = 0;
reg [31:0]  reg_mtval2      = 0;

// Machine Memory Protection
localparam CSR_ADDR_PMPADDR0    = 12'h3B0;
localparam CSR_ADDR_PMPCFG0     = 12'h3A0;

reg [31:0]  reg_pmpaddr0    = 0;
reg [31:0]  reg_pmpcfg0     = 0;

// Supervisor Trap Setup
localparam CSR_ADDR_SSTATUS     = 12'h100;
localparam CSR_ADDR_SIE         = 12'h104;
localparam CSR_ADDR_STVEC       = 12'h105;
localparam CSR_ADDR_SCOUNTEREN  = 12'h106; // 4.1.5 cycle, time, instret, or hpmcounternにアクセスできるかどうかのフラグ 

// reg [31:0]  reg_sstatus     = 0;
// reg [31:0]  reg_sie         = 0;
reg [31:0]  reg_stvec       = 0;
reg reg_scounteren_ir       = 0; // U-modeがinstretにアクセスできるかどうか
reg reg_scounteren_tm       = 0; // U-modeがtimeにアクセスできるかどうか
reg reg_scounteren_cy       = 0; // U-modeがcycleにアクセスできるかどうか

// Supervisor Configuration
localparam CSR_ADDR_SENVCFG     = 12'h10a; // 後で調べる

// Supervisor Trap Handling
localparam CSR_ADDR_SSCRATCH    = 12'h140;
localparam CSR_ADDR_SEPC        = 12'h141;
localparam CSR_ADDR_SCAUSE      = 12'h142;
localparam CSR_ADDR_STVAL       = 12'h143;
localparam CSR_ADDR_SIP         = 12'h144;

localparam SCAUSE_SUPERVISOR_TIMER_INTERRUPT    = 32'b10000000_00000000_00000000_00100000;

reg [31:0]  reg_sscratch    = 0;
reg [31:0]  reg_sepc        = 0;
reg [31:0]  reg_scause      = 0;
reg [31:0]  reg_stval       = 0;
// sipはmipのサブセット
// reg [31:0]  reg_sip         = 0;

// Supervisor Protection and Translation
localparam CSR_ADDR_SATP        = 12'h180;

reg [31:0]  reg_satp        = 0;

// Debug/Trace Registers
localparam CSR_ADDR_SCONTEXT    = 12'h5a8;

reg [31:0]  reg_scontext    = 0; // わからん



// タイマ割りこみが起こりそうなのでストールするかどうか
wire timer_stall =  reg_mtime >= reg_mtimecmp &&    // mtimeがmtimecmpより大きい
                    ((
                        mode == MODE_MACHINE &&     // M-mode
                        reg_mie_mtie == 1 &&        // タイマ割込みが有効
                        reg_mideleg_mtie == 0 &&    // S-modeに委譲されていない
                        reg_mstatus_mie == 1        // mieによってマスクされない
                    ) || (
                        mode == MODE_SUPERVISOR &&  // S-mode
                        reg_mie_stie == 1 &&        // タイマ割込みが有効
                        reg_mstatus_sie == 1        // sieによってマスクされない
                    ));

assign output_stall_flg_may_interrupt = timer_stall;

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

always @(posedge clk) begin
    // タイマ割り込みを起こす
    if (timer_stall && input_interrupt_ready) begin
        output_csr_cmd  <= CSR_ECALL;

        // トラップ先はxtvec
        // 前のxieをxpieに保存して、xieは0にする
        // これは処理を共通にしたい....

        if (mode == MODE_MACHINE) begin
            // M-modeでタイマ割込みが起きたらM-modeにしか遷移しない
            mode            <= MODE_MACHINE;
            reg_mstatus_mpp <= mode;
            reg_mcause      <= MCAUSE_MACHINE_TIMER_INTERRUPT;

            trap_vector         <= reg_mtvec;
            reg_mstatus_mpie    <= reg_mstatus_mie;
            reg_mstatus_mie     <= 0;
            reg_mepc            <= if_reg_pc;
        end else begin
            // S-modeなら、S-modeかM-modeに遷移する
            // xppは、S-modeなら1、U-modeなら0になる
            if (reg_mideleg_mtie == 0) begin
                // M-modeに遷移
                mode            <= MODE_MACHINE;
                reg_mstatus_mpp <= mode;
                reg_mcause      <= MCAUSE_MACHINE_TIMER_INTERRUPT;

                trap_vector         <= reg_mtvec;
                reg_mstatus_mpie    <= reg_mstatus_mie;
                reg_mstatus_mie     <= 0;
                reg_mepc            <= if_reg_pc;
            end else begin
                // S-modeに遷移
                mode            <= MODE_SUPERVISOR;
                reg_mstatus_spp <= mode[0];
                reg_scause      <= SCAUSE_SUPERVISOR_TIMER_INTERRUPT;

                trap_vector         <= reg_stvec;
                reg_mstatus_spie    <= reg_mstatus_sie;
                reg_mstatus_sie     <= 0;
                reg_sepc            <= if_reg_pc;
            end
        end

        `ifdef DEBUG
        $display("TIMER INTERRUPT pc : 0x%H", if_reg_pc);
        `endif
    end else begin
        output_csr_cmd  <= csr_cmd;

        case (csr_cmd)
            CSR_ECALL: begin
                `ifdef DEBUG
                $display("MCAUSE : %d", mode);
                `endif
                // environment call from x-Mode execeptionを起こす
                trap_vector <= reg_mtvec;
                // 現在のモードに応じて書き込む値を変える
                // M-mode = 11
                // H-mode = 10
                // S-mode = 9
                // U-mode = 8
                reg_mcause  <= {28'b0, 4'd8 + {2'b0,mode}};
                mode        <= MODE_MACHINE; // TODO 適切なモードにする
            end
            CSR_MRET: begin
                `ifdef DEBUG
                $display("MPP %d", reg_mstatus_mpp);
                `endif
                // 現在のモードをチェックしてない...
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
                reg_mstatus_spp <= MODE_USER;
                reg_mstatus_sie <= reg_mstatus_spie;
                reg_mstatus_mprv<= 0;
            end
            default: begin end
        endcase 
    end

    case (addr)
        // Counters and Timers
        // TODO アクセス制御を共通化したい
        CSR_ADDR_CYCLE: begin
            // M-modeか、counterenで許可されているならアクセスできる
            if (mode == MODE_MACHINE || 
                (reg_mcounteren_cy == 1 && 
                    (mode == MODE_SUPERVISOR || 
                    (mode == MODE_USER && reg_scounteren_cy == 1))))
                csr_rdata <= reg_cycle[31:0]; 
            else
                csr_rdata <= 0;
        end
        CSR_ADDR_TIME: begin
            // M-modeか、counterenで許可されているならアクセスできる
            if (mode == MODE_MACHINE || 
                (reg_mcounteren_tm == 1 && 
                    (mode == MODE_SUPERVISOR || 
                    (mode == MODE_USER && reg_scounteren_tm == 1))))
                csr_rdata <= reg_time[31:0]; 
            else
                csr_rdata <= 0;
        end
        CSR_ADDR_CYCLEH: begin
            // M-modeか、counterenで許可されているならアクセスできる
            if (mode == MODE_MACHINE || 
                (reg_mcounteren_cy == 1 && 
                    (mode == MODE_SUPERVISOR || 
                    (mode == MODE_USER && reg_scounteren_cy == 1))))
                csr_rdata <= reg_cycle[63:32]; 
            else
                csr_rdata <= 0;
        end
        CSR_ADDR_TIMEH: begin
            // M-modeか、counterenで許可されているならアクセスできる
            if (mode == MODE_MACHINE || 
                (reg_mcounteren_tm == 1 && 
                    (mode == MODE_SUPERVISOR || 
                    (mode == MODE_USER && reg_scounteren_tm == 1))))
                csr_rdata <= reg_time[63:32]; 
            else
                csr_rdata <= 0;
        end

        // Machine Information Registers
        // CSR_ADDR_MVENDORID:  0
        // CSR_ADDR_MARCHID:    0
        // CSR_ADDR_MIPID:      0
        // CSR_ADDR_MHARTID:    0
        // CSR_ADDR_MCONFIGPTR: 0

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
        // CSR_ADDR_MISA = 0
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
        CSR_ADDR_MCOUNTEREN:csr_rdata <= {
            29'b0,
            reg_mcounteren_ir,
            reg_mcounteren_tm,
            reg_mcounteren_cy
        };
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
        CSR_ADDR_MTVAL:     csr_rdata <= reg_mtval;
        CSR_ADDR_MIP:       csr_rdata <= {
            20'b0,
            reg_mip_meip, 1'b0,
            reg_mip_seip, 1'b0,
            reg_mip_mtip, 1'b0,
            reg_mip_stip, 1'b0,
            reg_mip_msip, 1'b0,
            reg_mip_ssip, 1'b0
        };
        // CSR_ADDR_MTINST:    0
        // CSR_ADDR_MTVAL2:    0

        // Machine Memory Protection
        CSR_ADDR_PMPADDR0:  csr_rdata <= reg_pmpaddr0;
        CSR_ADDR_PMPCFG0:   csr_rdata <= reg_pmpcfg0;

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
        CSR_ADDR_SCOUNTEREN:    csr_rdata <= {
            29'b0,
            reg_scounteren_ir,
            reg_scounteren_tm,
            reg_scounteren_cy
        };

        // Supervisor Trap Handling
        CSR_ADDR_SSCRATCH:  csr_rdata <= reg_sscratch;
        CSR_ADDR_SEPC:      csr_rdata <= reg_sepc;
        CSR_ADDR_SCAUSE:    csr_rdata <= reg_scause;
        CSR_ADDR_STVAL:     csr_rdata <= reg_stval;
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

    save_csr_cmd    <= csr_cmd;
    save_csr_addr   <= addr;
    save_op1_data   <= op1_data;

    case (save_csr_cmd)
        CSR_X: begin end
        CSR_ECALL: begin end
        CSR_MRET: begin end
        CSR_SRET: begin end
        default: begin
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
                // CSR_ADDR_MIPID:
                // CSR_ADDR_MHARTID:
                // CSR_ADDR_MCONFIGPTR:

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
                CSR_ADDR_MCOUNTEREN: begin
                    reg_mcounteren_ir <= wdata[2];
                    reg_mcounteren_tm <= wdata[1];
                    reg_mcounteren_cy <= wdata[0];
                end
                CSR_ADDR_MSTATUSH: begin
                    //reg_mstatush_wpri   <= wdata[31:6],
                    reg_mstatush_mbe    <= wdata[5];
                    reg_mstatush_sbe    <= wdata[4];
                    //reg_mstatush_wpri   <= wdata[3:0];
                end

                // Machine Trap Handling
                CSR_ADDR_MSCRATCH:  reg_mscratch <= wdata;
                CSR_ADDR_MEPC:      reg_mepc     <= wdata;
                CSR_ADDR_MCAUSE:    reg_mcause   <= wdata;
                CSR_ADDR_MTVAL:     reg_mtval    <= wdata;
                CSR_ADDR_MIP: begin
                    reg_mip_meip    <= wdata[11];
                    reg_mip_seip    <= wdata[9];
                    reg_mip_mtip    <= wdata[7];
                    reg_mip_stip    <= wdata[5];
                    reg_mip_msip    <= wdata[3];
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
                CSR_ADDR_SCOUNTEREN: begin
                    reg_scounteren_ir <= wdata[2];
                    reg_scounteren_tm <= wdata[1];
                    reg_scounteren_cy <= wdata[0];
                end

                // Supervisor Trap Handling
                CSR_ADDR_SSCRATCH:  reg_sscratch <= wdata;
                CSR_ADDR_SEPC:      reg_sepc <= wdata;
                CSR_ADDR_SCAUSE:    reg_scause <= wdata;
                CSR_ADDR_STVAL:     reg_stval <= wdata;
                CSR_ADDR_SIP: begin
                    reg_mip_seip    <= wdata[9];
                    reg_mip_stip    <= wdata[5];
                    reg_mip_ssip    <= wdata[1];
                end

                // Supervisor Protection and Translation
                CSR_ADDR_SATP:      reg_satp    <= wdata; 

                default: begin end
            endcase
        end
    endcase
end

`ifdef DEBUG 
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