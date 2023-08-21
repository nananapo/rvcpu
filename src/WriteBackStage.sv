module WriteBackStage(
    input wire          clk,

    output reg [31:0]   regfile[31:0],

    input wire          wb_valid,
    input wire [31:0]   wb_pc,
    input wire [31:0]   wb_inst,
    input IId       wb_inst_id,
    input Ctrl      wb_ctrl,
    input wire [31:0]   wb_alu_out,
    input wire [31:0]   wb_mem_rdata,
    input wire [31:0]   wb_csr_rdata,

    output wire [31:0]  wb_wdata_out,
    output wire         exit
);

wire [31:0] pc              = wb_pc;
wire [31:0] inst            = wb_inst;
wire IId inst_id        = wb_inst_id;
wire Ctrl ctrl          = wb_ctrl;
wire [31:0] alu_out         = wb_alu_out;
wire [31:0] memory_rdata    = wb_mem_rdata;
wire [31:0] csr_rdata       = wb_csr_rdata;

`ifdef RISCV_TEST
    integer loop_i;
    initial begin
        for (loop_i = 0; loop_i < 32; loop_i = loop_i + 1)
            regfile[loop_i] = 32'hffffffff;
    end
    assign exit = pc == 32'h00000044;
`else
    integer loop_i;
    initial begin
        regfile[1] = 32'hffffffff;
        regfile[2] = 32'h00007500;
        for (loop_i = 3; loop_i < 32; loop_i = loop_i + 1)
            regfile[loop_i] = 32'hffffffff;
    end
    assign exit = pc == 32'hffffff00;
`endif

// WB STAGE
function [31:0] wb_data_func(
    input [31:0]    pc,
    input WbSel   wb_sel,
    input [31:0]    alu_out,
    input [31:0]    csr_rdata,
    input [31:0]    memory_rdata
);
    case (wb_sel)
        WB_MEM  : wb_data_func = memory_rdata;
        WB_PC   : wb_data_func = pc + 4;
        WB_CSR  : wb_data_func = csr_rdata;
        default : wb_data_func = alu_out;
    endcase
endfunction

wire [31:0] wb_data = wb_data_func(pc, ctrl.wb_sel, alu_out, csr_rdata, memory_rdata);
assign wb_wdata_out = wb_data;

reg [31:0] inst_count = 0;
IId    saved_inst_id = IID_RANDOM;

wire is_new_inst = wb_valid && saved_inst_id != inst_id;

always @(posedge clk) begin
    if (wb_valid)
        saved_inst_id <= inst_id;
    if (is_new_inst)
        inst_count += 1;
    if (is_new_inst && ctrl.rf_wen == REN_S) begin
        regfile[ctrl.wb_addr] <= wb_data;
    end    
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,wbstage.valid,b,%b", wb_valid);
    $display("data,wbstage.inst_id,h,%b", is_new_inst ? inst_id : IID_X);
    if (wb_valid) begin
        $display("data,wbstage.pc,h,%b", pc);
        $display("data,wbstage.inst,h,%b", inst);
        $display("data,wbstage.wb_sel,d,%b", ctrl.wb_sel);
        $display("data,wbstage.wb_addr,d,%b", ctrl.wb_addr);
        $display("data,wbstage.wb_data,h,%b", wb_data);
        $display("data,wbstage.inst_count,d,%b", inst_count);
    end
end
`endif

endmodule