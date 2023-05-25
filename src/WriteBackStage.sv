module WriteBackStage(
    input wire          clk,

    output reg [31:0]   regfile[31:0],

    input wire          wb_valid,
    input wire [31:0]   wb_reg_pc,
    input wire [31:0]   wb_inst,
    input wire [63:0]   wb_inst_id,
    input ctrltype      wb_ctrl,
    input  wire [31:0]  wb_alu_out,
    input  wire [31:0]  wb_mem_rdata,
    input  wire [31:0]  wb_csr_rdata,

    output wire         exit
);

`include "include/core.sv"

wire reg_pc         = wb_reg_pc;
wire inst           = wb_inst;
wire inst_id        = wb_inst_id;
// wire ctrl           = wb_ctrl;
wire alu_out        = wb_alu_out;
wire memory_rdata   = wb_mem_rdata;
wire csr_rdata      = wb_csr_rdata;

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

// WB STAGE
function [31:0] wb_data_func(
    input [31:0]    reg_pc,
    input [3:0]     wb_sel,
    input [31:0]    alu_out,
    input [31:0]    csr_rdata,
    input [31:0]    memory_rdata
);
    case (wb_sel)
        WB_MEMB     : wb_data_func = {{24{memory_rdata[7]}}, memory_rdata[7:0]};
        WB_MEMBU    : wb_data_func = {24'b0, memory_rdata[7:0]};
        WB_MEMH     : wb_data_func = {{16{memory_rdata[15]}}, memory_rdata[15:0]};
        WB_MEMHU    : wb_data_func = {16'b0, memory_rdata[15:0]};
        WB_MEMW     : wb_data_func = memory_rdata;
        WB_PC       : wb_data_func = reg_pc + 4;
        WB_CSR      : wb_data_func = csr_rdata;
        default     : wb_data_func = alu_out;
    endcase
endfunction

wire [31:0] wb_data = wb_data_func(reg_pc, wb_ctrl.wb_sel, alu_out, csr_rdata, memory_rdata);

reg [31:0] inst_count = 0;

always @(posedge clk) begin
    if (reg_pc != 32'hffffffff)
        inst_count += 1;
    if (wb_ctrl.rf_wen == REN_S) begin
        regfile[wb_ctrl.wb_addr] <= wb_data;
    end    
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,wbstage.inst_id,%b", inst_id);
    $display("data,wbstage.input.reg_pc,%b", reg_pc);
    $display("data,wbstage.input.wb_sel,%b", wb_ctrl.wb_sel);
    $display("data,wbstage.input.wb_addr,%b", wb_ctrl.wb_addr);
    $display("data,wbstage.wb_data,%b", wb_data);
    $display("data,wbstage.inst_count,%b", inst_count);
    // $display("data,wbstage.exit,%b", exit);
end
`endif

endmodule