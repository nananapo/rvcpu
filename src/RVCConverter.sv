module RVCConverter(
    input wire clk,
    inout wire IResp iresp,
    inout wire IResp memresp
);

`include "basicparams.svh"

assign iresp.valid  = memresp.valid;
assign memresp.ready= iresp.ready;
assign iresp.addr   = memresp.addr;
assign iresp.inst   = //TODO
`ifdef PRINT_DEBUGINFO
assign inst_id      = IID_X; // unused
`endif

// 1.5.1. Expanded Instruction-Length Encoding
assign is_c         = memresp.inst[1:0] != 2'b11;



endmodule