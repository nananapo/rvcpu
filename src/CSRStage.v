module CSRStage #(
    parameter TV_ADDR = 12'h305
)(
    input  wire         clk,

    input  wire         wb_branch_hazard,
    
    // input
    input  wire [2:0]   input_csr_cmd,
    input  wire [31:0]  input_op1_data,
    input  wire [31:0]  input_imm_i,

    // output
    output reg  [2:0]   output_csr_cmd,
    output reg  [31:0]  csr_rdata,
    output reg  [31:0]  trap_vector
);

`include "include/core.v"

initial begin
    csr_rdata   = 0;
    trap_vector = 0;
    mem[TV_ADDR]= 0;
end

`ifndef DEBUG
// BSRAMが足りないので1024にする
localparam CSR_SIZE = 1024;
`else
localparam CSR_SIZE = 4096;
`endif

reg [31:0] mem [CSR_SIZE-1:0];

initial begin
    $readmemh("../test/bin/csr.hex", mem);
end

wire [2:0] csr_cmd    = wb_branch_hazard ? CSR_X : input_csr_cmd;
wire [31:0]op1_data   = wb_branch_hazard ? 32'hffffffff : input_op1_data;
wire [31:0]imm_i      = wb_branch_hazard ? 32'hffffffff : input_imm_i;

// ecallなら0x342を読む
wire [31:0] addr32bit = (csr_cmd == CSR_ECALL ? 32'h342 : imm_i) % CSR_SIZE;
wire [11:0] addr = addr32bit[11:0];

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
    csr_rdata       <= {mem[addr][7:0], mem[addr][15:8], mem[addr][23:16], mem[addr][31:24]};
    trap_vector     <= {mem[TV_ADDR][7:0], mem[TV_ADDR][15:8], mem[TV_ADDR][23:16], mem[TV_ADDR][31:24]};
    
    save_csr_cmd    <= csr_cmd;
    save_csr_addr   <= addr;
    save_op1_data   <= op1_data;
    if (save_csr_cmd != CSR_X) begin
        mem[save_csr_addr] <= {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
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