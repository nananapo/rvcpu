module WriteBackStage(
    input wire          clk,
    input wire          valid,
    input wire Addr     pc,
    input wire Inst     inst,
    input wire IId      inst_id,
    input wire          rf_wen,
    input wire UInt5    reg_addr,
    input wire UIntX    wdata,

    output wire         can_output_log,
    output UIntX        regfile[31:0]
);

`include "basicparams.svh"
initial begin
    regfile[0] = 0;
`ifdef RISCV_TESTS
    for (int i = 1; i < 32; i++) regfile[i] = ADDR_MAX;
`else
    `ifndef INITIAL_SP_VALUE
        `define INITIAL_SP_VALUE 32'h00007500
        $display("WARNING : initial value of sp (INITIAL_SP_VALUE) is not set. default to 0x%h", `INITIAL_SP_VALUE);
    `endif
    regfile[1] = ADDR_MAX;
    regfile[2] = `INITIAL_SP_VALUE;
    for (int i = 3; i < 32; i++) regfile[i] = ADDR_MAX;
`endif
end

always @(posedge clk) begin
    if (valid & rf_wen & reg_addr != 0) begin
        regfile[reg_addr] <= wdata;
    end
end

`ifdef PRINT_DEBUGINFO
int inst_count    = 0;
always @(posedge clk) begin
    if (valid) inst_count += 1;
end
always @(posedge clk) if (can_output_log) begin
    $display("data,wbstage.valid,b,%b", valid);
    $display("data,wbstage.inst_id,h,%b", valid ? inst_id : IID_X);
    if (valid) begin
        $display("data,wbstage.pc,h,%b", pc);
        $display("data,wbstage.inst,h,%b", inst);
        $display("data,wbstage.wb_addr,d,%b", reg_addr);
        $display("data,wbstage.wb_data,h,%b", wdata);
        $display("data,wbstage.inst_count,d,%b", inst_count);
    end
end
`endif

`ifdef START_LOG_INST_COUNT
    int sl_inst_count = 0;
    always @(posedge clk) begin
        if (valid) sl_inst_count += 1;
    end
    assign can_output_log = sl_inst_count > `START_LOG_INST_COUNT;
`else
    assign can_output_log = 1;
`endif

`ifdef END_INST_COUNT
int en_inst_count = 0;
always @(posedge clk) begin
    if (valid) en_inst_count += 1;
    if (en_inst_count == `END_INST_COUNT) begin
        $finish;
        $finish;
        $finish;
    end
end
`endif

`ifdef PRINT_LIGHT_WBLOG
int lb_inst_count = 0;
always @(posedge clk) begin
    if (valid) begin
        lb_inst_count += 1;
        if (can_output_log) begin
            $display("[%d] %h", lb_inst_count, pc);
            if (rf_wen & reg_addr != 0)
                $display("reg[%d] <= %h", reg_addr, wdata);
        end
    end
end
`endif

endmodule