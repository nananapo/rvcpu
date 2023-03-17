module CSRStage #(
    parameter FMAX_MHz = 27
)
(
    input  wire         clk,

    input  wire         wb_branch_hazard,
    
    // input
    input  wire [2:0]   input_csr_cmd,
    input  wire [31:0]  input_op1_data,
    input  wire [31:0]  input_imm_i,

    // output
    output reg  [2:0]   output_csr_cmd,
    output reg  [31:0]  csr_rdata,
    output wire [31:0]  trap_vector
);

`include "include/core.v"

// モード
localparam MACHINE_MODE     = 0;
localparam SUPERVISOR_MODE  = 1;
//localparam HYPERVISOR_MODE  = 2;
localparam USER_MODE        = 3;

// 現在のモード
reg [1:0] mode = MACHINE_MODE;


/*-------実装済みのCSRたち--------*/
localparam CSR_ADDR_MSCRATCH    = 12'h340;
localparam CSR_ADDR_MCAUSE      = 12'h342;
localparam CSR_ADDR_MTVEC       = 12'h305;

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

reg [31:0] reg_mscratch = 0;
reg [31:0] reg_mcause   = 0;
reg [31:0] reg_mtvec    = 0;
reg [63:0] reg_cycle    = 0;
reg [63:0] reg_time     = 0;

reg [31:0] timecounter = 0;
always @(posedge clk) begin
    // cycleは毎クロックインクリメント
    reg_cycle   <= reg_cycle + 1;
    // timeをμ秒ごとにインクリメント
    if (timecounter == FMAX_MHz - 1) begin
        reg_time    <= reg_time + 1;
        timecounter <= 0;
    end else begin
        timecounter <= timecounter + 1;
    end
end

assign trap_vector = reg_mtvec; 


/*---------CSR命令の実行----------*/
initial begin
    output_csr_cmd  = CSR_X;
    csr_rdata       = 0;
end

wire [2:0] csr_cmd  = wb_branch_hazard ? CSR_X : input_csr_cmd;
wire [31:0]op1_data = wb_branch_hazard ? 32'hffffffff : input_op1_data;
wire [31:0]imm_i    = wb_branch_hazard ? 32'hffffffff : input_imm_i;

// ecallなら0x342を読む
wire [11:0] addr = csr_cmd == CSR_ECALL ? CSR_ADDR_MCAUSE : imm_i[11:0];

function [31:0] wdata_fun(
    input [2:0] csr_cmd,
    input [31:0]op1_data,
    input [31:0]csr_rdata
);
    case (csr_cmd)
        CSR_W       : wdata_fun = op1_data;
        CSR_S       : wdata_fun = csr_rdata | op1_data;
        CSR_C       : wdata_fun = csr_rdata & ~op1_data;
        CSR_ECALL   : wdata_fun = 11;
        default     : wdata_fun = 0;
    endcase
endfunction

reg [2:0] save_csr_cmd  = CSR_X;
reg [11:0]save_csr_addr = 0;
reg [31:0]save_op1_data = 0;

wire [31:0] wdata = wdata_fun(save_csr_cmd, save_op1_data, csr_rdata);

always @(posedge clk) begin
    output_csr_cmd  <= csr_cmd;

    case (addr)
        CSR_ADDR_MCAUSE:    csr_rdata <= reg_mcause;
        CSR_ADDR_MTVEC:     csr_rdata <= reg_mtvec;
        CSR_ADDR_MSCRATCH:  csr_rdata <= reg_mscratch;
        
        // Counters and Timers
        CSR_ADDR_CYCLE:     csr_rdata <= reg_cycle[31:0];
        CSR_ADDR_TIME:      csr_rdata <= reg_time[31:0];
        CSR_ADDR_CYCLEH:    csr_rdata <= reg_cycle[63:32];
        CSR_ADDR_TIMEH:     csr_rdata <= reg_time[63:32];

        // Machine Information Registers
        // 全部 0
        //CSR_ADDR_MVENDORID: 
        //CSR_ADDR_MARCHID:
        //CSR_ADDR_MIPID:
        //CSR_ADDR_MHARTID:
        //CSR_ADDR_MCONFIGPTR:
        default:            csr_rdata <= 32'b0;
    endcase

    save_csr_cmd    <= csr_cmd;
    save_csr_addr   <= addr;
    save_op1_data   <= op1_data;

    if (save_csr_cmd != CSR_X) begin
        case (save_csr_addr)
            CSR_ADDR_MCAUSE:    reg_mcause  <= wdata;
            CSR_ADDR_MTVEC:     reg_mtvec   <= wdata;
            CSR_ADDR_MSCRATCH:  reg_mscratch<= wdata;
            // Counters and Timers
            // READ ONLY
            // CSR_ADDR_CYCLE:
            // CSR_ADDR_TIME:
            // CSR_ADDR_CYCLEH:
            // CSR_ADDR_TIMEH:
            
            // Machine Information Registers
            // READ ONLY
            //CSR_ADDR_MVENDORID: 
            //CSR_ADDR_MARCHID:
            //CSR_ADDR_MIPID:
            //CSR_ADDR_MHARTID:
            //CSR_ADDR_MCONFIGPTR:
            default:            reg_mtvec   <= reg_mtvec; //nop
        endcase
    end
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