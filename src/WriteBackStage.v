module WriteBackStage(
    input  wire         clk,

    input  wire [31:0]  reg_pc,
    input  wire [3:0]   wb_sel,
    input  wire [31:0]  csr_rdata,
    input  wire [31:0]  memory_rdata,
    input  wire [4:0]   wb_addr,
    input  wire         jmp_flg,
    input  wire         rf_wen,
    input  wire         br_flg,
    input  wire [31:0]  br_target,
    input  wire [31:0]  alu_out,
    input  wire         inst_is_ecall,
    input  wire [31:0]  trap_vector,

    output wire [31:0]  output_reg_pc,
    output wire         output_branch_hazard,
    output reg [31:0]   regfile[31:0]
);

`include "include/core.v"

integer loop_i;
initial begin
    regfile[0] = 0;
    regfile[1] = 0;
    regfile[2] = 1000;
    for (loop_i = 3; loop_i < 32; loop_i = loop_i + 1)
        regfile[loop_i] = 0;
end

wire [31:0] reg_pc_plus4 = reg_pc + 4; 

// WB STAGE
function [31:0] wb_data_func(
    input [3:0]     wb_sel,
    input [31:0]    memory_rdata,
    input [31:0]    reg_pc_plus4,
    input [31:0]    csr_rdata,
    input [31:0]    alu_out
);
    case (wb_sel)
        WB_MEMB     : wb_data_func = {{24{memory_rdata[7]}}, memory_rdata[7:0]};
        WB_MEMBU    : wb_data_func = {24'b0, memory_rdata[7:0]};
        WB_MEMH     : wb_data_func = {{16{memory_rdata[15]}}, memory_rdata[15:0]};
        WB_MEMHU    : wb_data_func = {16'b0, memory_rdata[15:0]};
        WB_MEMW     : wb_data_func = memory_rdata;
        WB_PC       : wb_data_func = reg_pc_plus4;
        WB_CSR      : wb_data_func = csr_rdata;
        default     : wb_data_func = alu_out;
    endcase
endfunction

wire [31:0] wb_data = wb_data_func(wb_sel, memory_rdata, reg_pc_plus4, csr_rdata, alu_out);

assign output_reg_pc = (
    br_flg ? br_target : 
    jmp_flg ? alu_out :
    inst_is_ecall ? trap_vector :
    reg_pc_plus4
);

assign output_branch_hazard = br_flg || jmp_flg || inst_is_ecall;

always @(posedge clk) begin
    if (rf_wen == REN_S) begin
        regfile[wb_addr] <= wb_data;
    end    
end

`ifdef DEBUG 
always @(posedge clk) begin
    $display("WB STAGE--------------");
    $display("reg_pc         : 0x%H", reg_pc);
    $display("output_reg_pc  : 0x%H", output_reg_pc);
    $display("wb_sel         : %d", wb_sel);
    $display("csr_rdata      : 0x%H", csr_rdata);
    $display("memory_rdata   : 0x%H", memory_rdata);
    $display("wb_addr        : %d", wb_addr);
    $display("jmp_flg        : %d", jmp_flg);
    $display("rf_wen         : %d", rf_wen);
    $display("br_flg         : %d", br_flg);
    $display("br_target      : 0x%H", br_target);
    $display("alu_out        : 0x%H", alu_out);
    $display("inst_is_ecall  : %d", inst_is_ecall);
    $display("trap_vector    : 0x%H", trap_vector);
    $display("branch hazard  : %d", output_branch_hazard);
    $display("wb_data        : 0x%H", wb_data);
end
`endif

endmodule