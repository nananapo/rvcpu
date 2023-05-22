module WriteBackStage(
    input  wire         clk,

    input  wire [31:0]  reg_pc,
    input  wire [63:0]  inst_id,
    input  wire [3:0]   wb_sel,
    input  wire [31:0]  csr_rdata,
    input  wire [31:0]  memory_rdata,
    input  wire [4:0]   wb_addr,
    input  wire [2:0]   csr_cmd,
    input  wire         jmp_flg,
    input  wire         rf_wen,
    input  wire         br_flg,
    input  wire [31:0]  br_target,
    input  wire [31:0]  alu_out,
    input  wire [31:0]  trap_vector,

    output wire [31:0]  output_reg_pc,
    output wire         output_branch_hazard,

    output reg [31:0]   regfile[31:0],

    output wire         exit
);

`include "include/core.v"

`ifdef RISCV_TEST
    integer loop_i;
    initial begin
        for (loop_i = 0; loop_i < 32; loop_i = loop_i + 1)
            regfile[loop_i] = 32'hffffffff;
    end
    assign exit = reg_pc == 32'h00000044;
`else
    integer loop_i;
    initial begin
        regfile[1] = 32'hffffffff;
        regfile[2] = 32'h00002000;
        for (loop_i = 3; loop_i < 32; loop_i = loop_i + 1)
            regfile[loop_i] = 32'hffffffff;
    end
    assign exit = reg_pc == 32'hffffff00;
`endif

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

wire is_trap  = csr_cmd == CSR_ECALL ||
                csr_cmd == CSR_MRET ||
                csr_cmd == CSR_SRET;

assign output_reg_pc = (
    br_flg ? br_target : 
    jmp_flg ? alu_out :
    is_trap ? trap_vector :
    reg_pc_plus4
);

assign output_branch_hazard = br_flg || jmp_flg || is_trap;

reg [31:0] inst_count = 0;

always @(posedge clk) begin
    if (reg_pc != 32'hffffffff)
        inst_count += 1;
    if (rf_wen == REN_S) begin
        regfile[wb_addr] <= wb_data;
    end    
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,wbstage.inst_id,%b", inst_id);

    $display("data,wbstage.input.reg_pc,%b", reg_pc);
    $display("data,wbstage.input.wb_sel,%b", wb_sel);
    // $display("data,wbstage.input.csr_rdata,%b", csr_rdata);
    // $display("data,wbstage.input.memory_rdata,%b", memory_rdata);
    $display("data,wbstage.input.wb_addr,%b", wb_addr);
    // $display("data,wbstage.input.csr_cmd,%b", csr_cmd);
    // $display("data,wbstage.input.jmp_flg,%b", jmp_flg);
    $display("data,wbstage.input.rf_wen,%b", rf_wen);
    // $display("data,wbstage.input.br_flg,%b", br_flg);
    // $display("data,wbstage.input.br_target,%b", br_target);
    // $display("data,wbstage.input.alu_out,%b", alu_out);
    // $display("data,wbstage.input.trap_vector,%b", trap_vector);

    $display("data,wbstage.output.reg_pc,%b", output_reg_pc);
    $display("data,wbstage.output.branch_hazard,%b", output_branch_hazard);

    $display("data,wbstage.is_trap,%b", is_trap);
    $display("data,wbstage.wb_data,%b", wb_data);
    $display("data,wbstage.inst_count,%b", inst_count);
    // $display("data,wbstage.exit,%b", exit);
end
`endif

endmodule