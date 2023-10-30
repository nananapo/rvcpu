module MemCacheCmdArbiter (
    input wire clk,
    inout wire CacheReq     ireq_in,
    inout wire CacheResp    iresp_in,
    inout wire CacheReq     dreq_in,
    inout wire CacheResp    dresp_in,
    inout wire CacheReq     memreq_in,
    inout wire CacheResp    memresp_in

`ifdef PRINT_DEBUGINFO
    ,
    input wire can_output_log
`endif
);

`include "basicparams.svh"

CacheReq    s_ireq;
CacheReq    s_dreq;

typedef enum logic [2:0] {
    I_CHECK,
    I_READY,
    I_VALID,
    D_CHECK,
    D_READY,
    D_VALID
} statetype;

function [$bits(Addr) + 1 + $bits(UInt32) + $bits(MemSize) + $bits(PTE_AD) -1:0] memcmd (
    input statetype state,
    input CacheReq  ireq_in,
    input CacheReq  dreq_in,
    input CacheReq  s_ireq,
    input CacheReq  s_dreq
);
    case (state)
        I_CHECK: memcmd = {ireq_in.addr, ireq_in.wen, ireq_in.wdata, ireq_in.wmask,  ireq_in.pte};
        D_CHECK: memcmd = {dreq_in.addr, dreq_in.wen, dreq_in.wdata, dreq_in.wmask,  dreq_in.pte};
        I_READY: memcmd = { s_ireq.addr,  s_ireq.wen,  s_ireq.wdata,  s_ireq.wmask,   s_ireq.pte};
        D_READY: memcmd = { s_dreq.addr,  s_dreq.wen,  s_dreq.wdata,  s_dreq.wmask,   s_dreq.pte};
        default: memcmd = {ADDR_X, 1'b0, XBIT_32, SIZE_W, {$bits(PTE_AD){1'b0}}};
    endcase
endfunction

statetype state = I_CHECK;

assign ireq_in.ready    = state == I_CHECK;
assign dreq_in.ready    = state == D_CHECK;

assign memreq_in.valid  =   (state == I_READY | state == D_READY) |
                            (state == I_CHECK & ireq_in.valid) |
                            (state == D_CHECK & dreq_in.valid);

assign {
    memreq_in.addr, memreq_in.wen, memreq_in.wdata, memreq_in.wmask, memreq_in.pte
} = memcmd(state, ireq_in, dreq_in, s_ireq, s_dreq);

assign iresp_in.valid = state == I_VALID & memresp_in.valid;
assign iresp_in.error = memresp_in.error;
assign iresp_in.errty = memresp_in.errty;
assign iresp_in.rdata = memresp_in.rdata;

assign dresp_in.valid = state == D_VALID & memresp_in.valid;
assign dresp_in.error = memresp_in.error;
assign dresp_in.errty = memresp_in.errty;
assign dresp_in.rdata = memresp_in.rdata;

always @(posedge clk) begin
    case (state)
        I_CHECK: begin
            s_ireq  <= ireq_in;
            state   <=  !ireq_in.valid ? D_CHECK :
                        memreq_in.ready ? I_VALID : I_READY;
        end
        I_READY: if (memreq_in.ready) state <= I_VALID;
        I_VALID: if (memresp_in.valid) state <= D_CHECK;
        D_CHECK: begin
            s_dreq      <= dreq_in;
            state       <=  !dreq_in.valid ? I_CHECK :
                            memreq_in.ready ? D_VALID : D_READY;
        end
        D_READY: if (memreq_in.ready)  state <= D_VALID;
        D_VALID: if (memresp_in.valid) state <= I_CHECK;
        default: begin
            $display("MemCacheCmdArbiter : Unknown state %d", state);
            $finish;
            $finish;
            $finish;
        end
    endcase
end

endmodule