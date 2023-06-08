module WriteBackStage(
    input wire          clk,

    output reg [31:0]   regfile[31:0],

    input wire          wb_valid,
    input wire [31:0]   wb_reg_pc,
    input wire [31:0]   wb_inst,
    input wire [63:0]   wb_inst_id,
    input ctrltype      wb_ctrl,
    input wire [31:0]   wb_alu_out,
    input wire [31:0]   wb_mem_rdata,
    input wire [31:0]   wb_csr_rdata,

    output wire [31:0]  wb_wdata_out,
    output wire         exit
);

`include "include/core.sv"

wire [31:0] reg_pc         = wb_reg_pc;
wire [31:0] inst           = wb_inst;
wire [63:0] inst_id        = wb_inst_id;
// ctrltype ctrl           = wb_ctrl;
wire [31:0] alu_out        = wb_alu_out;
wire [31:0] memory_rdata   = wb_mem_rdata;
wire [31:0] csr_rdata      = wb_csr_rdata;

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
        regfile[2] = 32'h00007500;
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
assign wb_wdata_out = wb_data;

reg [31:0] inst_count = 0;
reg [63:0] saved_inst_id = 64'hffff000000000000;

wire is_new_inst = wb_valid && saved_inst_id != inst_id;

always @(posedge clk) begin
    if (wb_valid)
        saved_inst_id <= inst_id;
    if (is_new_inst)
        inst_count += 1;
    if (is_new_inst && wb_ctrl.rf_wen == REN_S) begin
        regfile[wb_ctrl.wb_addr] <= wb_data;
    end    
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,wbstage.valid,b,%b", wb_valid);
    $display("data,wbstage.inst_id,h,%b", is_new_inst ? inst_id : INST_ID_NOP);
    if (wb_valid) begin
        $display("data,wbstage.reg_pc,h,%b", reg_pc);
        $display("data,wbstage.inst,h,%b", inst);
        $display("data,wbstage.wb_sel,d,%b", wb_ctrl.wb_sel);
        $display("data,wbstage.wb_addr,d,%b", wb_ctrl.wb_addr);
        $display("data,wbstage.wb_data,h,%b", wb_data);
        $display("data,wbstage.inst_count,d,%b", inst_count);
        // $display("data,wbstage.exit,%b", exit);
    end
end
`endif

endmodule