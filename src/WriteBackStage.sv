module WriteBackStage
    import basic::*;
    import stageinfo::*;
(
    input wire              clk,
    input wire              valid,
    input wire StageInfo    info,
    input wire              rf_wen,
    input wire UInt5        reg_addr,
    input wire UIntX        wdata,
    output UIntX            regfile[31:0]
);

initial begin
    regfile[0] = 0;
    for (int i = 1; i < 32; i++) regfile[i] = XLEN_MAX;
end

logic [63:0] inst_count  = 0;
logic [63:0] clock_count = 0;
always @(posedge clk) begin
    clock_count++;
    if (valid) inst_count += 1;
end

always @(posedge clk) begin
    if (valid & rf_wen & reg_addr != 0) begin
        regfile[reg_addr] <= wdata;
`ifdef XZSTOP
        for (int i = 0; i < `XLEN; i++) begin
            if (!(wdata[i] === 1'b0 | wdata[i] === 1'b1)) begin
                $display("ERR-XZSTOP! %h: %h <= %h", info.pc, reg_addr, wdata);
                `ffinish
            end
        end
`endif
    end
end

import util::*;

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,wbstage.valid,b,%b", valid);
    $display("data,wbstage.inst_id,h,%b", valid ? info.id : iid::X);
    if (valid) begin
        $display("data,wbstage.pc,h,%b", info.pc);
        $display("data,wbstage.inst,h,%b", info.inst);
        $display("data,wbstage.wb_addr,d,%b", reg_addr);
        $display("data,wbstage.wb_data,h,%b", wdata);
        $display("data,wbstage.inst_count,d,%b", inst_count);
    end
end

`ifndef START_LOG_CLOCK_COUNT
    `define START_LOG_CLOCK_COUNT 0
`endif
`ifdef START_LOG_INST_COUNT
    wire debugLogEnabled = inst_count > `START_LOG_INST_COUNT && clock_count >= `START_LOG_CLOCK_COUNT;
`else
    /* verilator lint_off UNSIGNED */
    wire debugLogEnabled = 1 && clock_count >= `START_LOG_CLOCK_COUNT;
    /* verilator lint_on UNSIGNED */
`endif

logic last_log_level = 0;
always @(negedge clk) begin
    last_log_level <= debugLogEnabled;
    if (last_log_level != debugLogEnabled) begin
        setLogLevel(int'(debugLogEnabled));
    end
end

`endif

`ifdef END_CLOCK_COUNT
always @(posedge clk) begin
    if (`END_CLOCK_COUNT >= 0 && clock_count >= `END_CLOCK_COUNT) begin
        `ffinish
    end
end
`endif

`ifdef END_INST_COUNT
always @(posedge clk) begin
    if (inst_count == `END_INST_COUNT) begin
        `ffinish
    end
end
`endif

`ifdef PRINT_LIGHT_WBLOG
always @(posedge clk) begin
    if (valid) begin
        if (util::logEnabled()) begin
            $display("[%d] %h", inst_count, pc);
            if (rf_wen & reg_addr != 0)
                $display("reg[%d] <= %h", reg_addr, wdata);
        end
    end
end
`endif

endmodule