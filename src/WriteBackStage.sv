module WriteBackStage(
    input wire clk,

    output UIntX regfile[31:0],

    input wire          wb_valid,
    input wire Addr     wb_pc,
    input wire Inst     wb_inst,
    input wire IId      wb_inst_id,
    input wire Ctrl     wb_ctrl,
    input wire UIntX    wb_alu_out,
    input wire UIntX    wb_mem_rdata,
    input wire UIntX    wb_csr_rdata,

    output wire UIntX   wb_wdata_out
);

`include "basicparams.svh"

wire Addr   pc          = wb_pc;
wire Inst   inst        = wb_inst;
wire IId    inst_id     = wb_inst_id;
wire Ctrl   ctrl        = wb_ctrl;
wire UIntX  alu_out     = wb_alu_out;
wire UIntX  memory_rdata= wb_mem_rdata;
wire UIntX  csr_rdata   = wb_csr_rdata;

initial begin
`ifdef RISCV_TESTS
    for (int i = 0; i < 32; i++) regfile[i] = ADDR_MAX;
`else
    regfile[1] = ADDR_MAX;
    regfile[2] = 32'h00007500;
    for (int i = 3; i < 32; i++) regfile[i] = ADDR_MAX;
`endif
end

// WB STAGE
function [$bits(UIntX)-1:0] wb_data_func(
    input Addr  pc,
    input WbSel wb_sel,
    input UIntX alu_out,
    input UIntX csr_rdata,
    input UIntX memory_rdata
);
    case (wb_sel)
        WB_MEM  : wb_data_func = memory_rdata;
        WB_PC   : wb_data_func = pc + 4;
        WB_CSR  : wb_data_func = csr_rdata;
        default : wb_data_func = alu_out;
    endcase
endfunction

wire UIntX wb_data  = wb_data_func(pc, ctrl.wb_sel, alu_out, csr_rdata, memory_rdata);
assign wb_wdata_out = wb_data;

UIntX inst_count    = 0;
IId   saved_inst_id = IID_RANDOM;

wire is_new_inst    = wb_valid && saved_inst_id != inst_id;

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