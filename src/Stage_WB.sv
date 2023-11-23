module Stage_WB
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

`ifdef BREAKPOINT
    `ifndef BP0
        `define BP0 0
        initial $fatal(1, "BP0 not set");
    `endif
    `ifndef BP1
        `define BP1 32'hffffffff
    `endif
    `ifndef BP2
        `define BP2 32'hffffffff
    `endif
    `ifndef BP3
        `define BP3 32'hffffffff
    `endif
    `ifndef BP4
        `define BP4 32'hffffffff
    `endif
    `ifndef BP5
        `define BP5 32'hffffffff
    `endif
    `ifndef BP6
        `define BP6 32'hffffffff
    `endif
    `ifndef BP7
        `define BP7 32'hffffffff
    `endif
    `ifndef BP8
        `define BP8 32'hffffffff
    `endif
    `ifndef BP9
        `define BP9 32'hffffffff
    `endif
    `ifndef BP10
        `define BP10 32'hffffffff
    `endif
    `ifndef BP11
        `define BP11 32'hffffffff
    `endif
    `ifndef BP12
        `define BP12 32'hffffffff
    `endif
    `ifndef BP13
        `define BP13 32'hffffffff
    `endif
    `ifndef BP14
        `define BP14 32'hffffffff
    `endif
    `ifndef BP15
        `define BP15 32'hffffffff
    `endif
    `ifndef BP16
        `define BP16 32'hffffffff
    `endif
    `ifndef BP17
        `define BP17 32'hffffffff
    `endif
`endif

always @(posedge clk) if (valid) begin
    if (rf_wen & reg_addr != 0) begin
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
`ifdef BREAKPOINT
    if (info.pc == `BP0 || info.pc == `BP1 || info.pc == `BP2 ||
        info.pc == `BP3 || info.pc == `BP4 || info.pc == `BP5 ||
        info.pc == `BP6 || info.pc == `BP7 || info.pc == `BP8 ||
        info.pc == `BP9 || info.pc == `BP10 || info.pc == `BP11 ||
        info.pc == `BP12 || info.pc == `BP13 || info.pc == `BP14 ||
        info.pc == `BP15 || info.pc == `BP16 || info.pc == `BP17) begin
        $display(/* info,wbstage.breakpoint. */"clock,%d", clock_count);
        $display(/* info,wbstage.breakpoint. */"icount,%h", inst_count);
        $display(/* info,wbstage.breakpoint. */"pc,%h", info.pc);
        $display(/* info,wbstage.breakpoint. */"inst,%h", info.inst);
        for (int i=1; i < 32; i++)
            $display("reg[%d] %h", i, regfile[i]);
    end
`endif
end

import util::*;

`ifdef DEBUG
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

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,wbstage.valid,b,%b", valid);
    $display("data,wbstage.inst_id,h,%b", valid ? info.id.id : iid::X);
    if (valid) begin
        $display("data,wbstage.pc,h,%b", info.pc);
        $display("data,wbstage.inst,h,%b", info.inst);
        $display("data,wbstage.wb_addr,d,%b", reg_addr);
        $display("data,wbstage.wb_data,h,%b", wdata);
        $display("data,wbstage.inst_count,d,%b", inst_count);
    end
end

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
    if (valid && debugLogEnabled) begin
        $display("[%d] %h", 0, info.pc);
        // if (rf_wen & reg_addr != 0)
        //     $display("reg[%d] <= %h", reg_addr, wdata);
    end
end
`endif
`endif

endmodule