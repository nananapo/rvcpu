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

    // output
    output reg  [2:0]   output_csr_cmd,
    output reg  [31:0]  csr_rdata,
    output reg  [31:0]  trap_vector,

    // trapを起こしたいときにEXE以前を止めるために使う
    output wire         output_stall_flg_may_interrupt
);

`include "include/core.v"

// モード
localparam MODE_MACHINE     = 3;
//localparam HYPERVISOR_MODE  = 2;
localparam MODE_SUPERVISOR  = 1;
localparam MODE_USER        = 0;

// 現在のモード
reg [1:0]   mode = MODE_MACHINE;


/*-------実装済みのCSRたち--------*/

// Counters and Timers
localparam CSR_ADDR_CYCLE       = 12'hc00;
localparam CSR_ADDR_TIME        = 12'hc01;
localparam CSR_ADDR_CYCLEH      = 12'hc80;
localparam CSR_ADDR_TIMEH       = 12'hc81;

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

//reg [25:0]  reg_mstatush_wpri   = 0;
reg         reg_mstatush_mbe    = 0;
reg         reg_mstatush_sbe    = 0;
//reg [3:0]   reg_mstatush_wpri   = 0;

reg         reg_mie_meie        = 0;
reg         reg_mie_seie        = 0;
reg         reg_mie_mtie        = 0; // 7
reg         reg_mie_stie        = 0;
reg         reg_mie_msie        = 0;
reg         reg_mie_ssie        = 0;

reg [31:0]  reg_mtvec           = 0;

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

reg [31:0]  reg_mscratch    = 0;
reg [31:0]  reg_mepc        = 0;
reg [31:0]  reg_mcause      = 0;
reg [31:0]  reg_mtval       = 0;
reg [31:0]  reg_mip         = 0;
reg [31:0]  reg_mtinst      = 0;
reg [31:0]  reg_mtval2      = 0;

// タイマ割りこみが起こりそうなのでストールするかどうか
wire timer_stall =  reg_mtime >= reg_mtimecmp &&    // mtimeがmtimecmpより大きい
                                                    // TODO sie
                    reg_mie_mtie == 1 &&            // mieのmtieが1
                    (
                        // M-modeのとき、midelegによってS-modeに委譲されていなくて、mstatus.mieが1であることを確認する
                        (mode == MODE_MACHINE && reg_mideleg_mtie == 0 && reg_mstatus_mie == 1) ||
                        // S-modeのとき、midelegによってS-modeに委譲されていて、mstatus.sieが1であることを確認する
                        (mode == MODE_SUPERVISOR && reg_mideleg_mtie == 1 && reg_mstatus_sie == 1)
                    );

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
        if (reg_mideleg_mtie == 0) begin
            mode                <= MODE_MACHINE;
            trap_vector         <= reg_mtvec;
            reg_mstatus_mpie    <= reg_mstatus_mie;
            reg_mstatus_mie     <= 0;
        end else begin
            mode                <= MODE_SUPERVISOR;
            trap_vector         <= reg_mtvec; 
            //trap_vector         <= reg_stvec; 
            reg_mstatus_spie    <= reg_mstatus_sie;
            reg_mstatus_sie     <= 0;
        end
    end else begin
        output_csr_cmd  <= csr_cmd;
    end

    case (addr)
        // Counters and Timers
        CSR_ADDR_CYCLE:     csr_rdata <= reg_cycle[31:0];
        CSR_ADDR_TIME:      csr_rdata <= reg_time[31:0];
        CSR_ADDR_CYCLEH:    csr_rdata <= reg_cycle[63:32];
        CSR_ADDR_TIMEH:     csr_rdata <= reg_time[63:32];

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
        // CSR_ADDR_MCOUNTEREN: 実装しない
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
        CSR_ADDR_MIP:       csr_rdata <= reg_mip;
        // CSR_ADDR_MTINST:    0
        // CSR_ADDR_MTVAL2:    0
        default:            csr_rdata <= 32'b0;
    endcase

    save_csr_cmd    <= csr_cmd;
    save_csr_addr   <= addr;
    save_op1_data   <= op1_data;

    case (save_csr_cmd)
        CSR_X: reg_mtvec <= reg_mtvec; // nop
        CSR_ECALL: begin
            // environment call from x-Mode execeptionを起こす
            // 現在のモードに応じて書き込む値を変える
            reg_mcause  <= {30'b0, mode};
            mode        <= MODE_MACHINE; // TODO 適切なモードにする            
            trap_vector <= reg_mtvec;
        end
        CSR_MRET: begin
            // 現在のモードをチェックしてない
            mode            <= reg_mstatus_mpp;
            reg_mstatus_mpp <= MODE_USER;
            reg_mstatus_mie <= reg_mstatus_mpie;
            if (reg_mstatus_mpp != MODE_MACHINE) begin
                reg_mstatus_mprv <= 0;
            end
            trap_vector     <= reg_mepc;
        end
        /*
        CSR_SRET: begin
            trap_vector <= reg_sepc;
        end
        */
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
                // CSR_ADDR_MCOUNTEREN: 実装しない
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
                CSR_ADDR_MIP:       reg_mip      <= wdata;
                // CSR_ADDR_MTINST:    0
                // CSR_ADDR_MTVAL2:    0
                default:            reg_mtvec   <= reg_mtvec; //nop
            endcase
        end
    endcase
end

`ifdef DEBUG 
always @(posedge clk) begin
    $display("CSR STAGE------------");
    $display("cmd          : %d", csr_cmd);
    $display("op1_data     : 0x%H", op1_data);
    $display("imm_i        : 0x%H", imm_i);
    $display("addr         : 0x%H", addr);
    $display("rdata        : 0x%H", csr_rdata);
    $display("wdata        : 0x%H", wdata);
    $display("trap_vector  : 0x%H", trap_vector);
end
`endif

endmodule