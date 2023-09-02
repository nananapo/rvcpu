module MemBusCntr (
    input wire clk,
    inout wire MemBusReq    ireq_in,
    inout wire MemBusResp   iresp_in,
    inout wire MemBusReq    dreq_in,
    inout wire MemBusResp   dresp_in,
    inout wire MemBusReq    memreq_in,
    inout wire MemBusResp   memresp_in
);

`include "include/basicparams.svh"

MemBusReq   s_ireq;
MemBusReq   s_dreq;

typedef enum logic [2:0] {
    I_CHECK,
    I_READY,
    I_VALID,
    D_CHECK,
    D_READY,
    D_VALID
} statetype;

statetype state = I_CHECK;

assign ireq_in.ready    = state == I_CHECK;
assign dreq_in.ready    = state == D_CHECK;

assign memreq_in.valid  =   (state == I_READY || state == D_READY) ||
                            (state == I_CHECK && ireq_in.valid) ||
                            (state == D_CHECK && dreq_in.valid);

function [$bits(Addr) + 1 + $bits(UInt32) -1:0] memcmd (
    input statetype state,
    input MemBusReq ireq_in,
    input MemBusReq dreq_in,
    input MemBusReq s_ireq,
    input MemBusReq s_dreq
);
    case (state)
        I_CHECK: memcmd = {ireq_in.addr, ireq_in.wen, ireq_in.wdata};
        D_CHECK: memcmd = {dreq_in.addr, dreq_in.wen, dreq_in.wdata};
        I_READY: memcmd = { s_ireq.addr,  s_ireq.wen,  s_ireq.wdata};
        D_READY: memcmd = { s_dreq.addr,  s_dreq.wen,  s_dreq.wdata};
        default: memcmd = {ADDR_X, 1'b0, XBIT_32};
    endcase
endfunction
assign {
    memreq_in.addr, memreq_in.wen, memreq_in.wdata
} = memcmd(state, ireq_in, dreq_in, s_ireq, s_dreq);

logic   reg_iresp_valid = 0;
logic   reg_dresp_valid = 0;
Addr    reg_resp_addr;
UInt32  reg_resp_rdata;

assign iresp_in.valid = reg_iresp_valid;
assign iresp_in.addr  = reg_resp_addr;
assign iresp_in.rdata = reg_resp_rdata;

assign dresp_in.valid = reg_dresp_valid;
assign dresp_in.addr  = reg_resp_addr;
assign dresp_in.rdata = reg_resp_rdata;

always @(posedge clk) begin
    case (state)
        I_CHECK: begin
            reg_iresp_valid <= 0;
            reg_dresp_valid <= 0;

            s_ireq  <= ireq_in;
            state   <=  !ireq_in.valid ? D_CHECK :
                        !memreq_in.ready ? I_READY :
                        (ireq_in.wen ? D_CHECK : I_VALID);
        end
        D_CHECK: begin
            reg_iresp_valid <= 0;
            reg_dresp_valid <= 0;
            
            s_dreq  <= dreq_in;
            state   <=  !dreq_in.valid ? I_CHECK :
                        !memreq_in.ready ? D_READY :
                        (dreq_in.wen ? I_CHECK : D_VALID);
        end
        I_READY: if (memreq_in.ready) state <= s_ireq.wen ? D_CHECK : I_VALID;
        I_VALID: begin
            if (memresp_in.valid) begin
                state           <= D_CHECK;
                reg_iresp_valid <= 1;
                reg_resp_addr   <= s_ireq.addr;
                reg_resp_rdata  <= memresp_in.rdata;
            end
        end
        D_READY: if (memreq_in.ready) state <= s_dreq.wen ? I_CHECK : D_VALID;
        D_VALID: begin
            if (memresp_in.valid) begin
                state           <= I_CHECK;
                reg_dresp_valid <= 1;
                reg_resp_addr   <= s_dreq.addr;
                reg_resp_rdata  <= memresp_in.rdata;
            end
        end
        default: begin
            $display("MemBusCntr : Unknown state %d", state);
            $finish;
        end
    endcase
end


// `ifdef PRINT_DEBUGINFO
// always @(posedge clk) begin
//     $display("data,fetchstage.buscntr.state,d,%b", state);
//     if (memreq_in.valid) begin
//         $display("data,fetchstage.buscntr.memreq.ready,d,%b", memreq_in.ready);
//         $display("data,fetchstage.buscntr.memreq.valid,d,%b", memreq_in.valid);
//         $display("data,fetchstage.buscntr.memreq.addr,h,%b", memreq_in.addr);
//         $display("data,fetchstage.buscntr.memreq.wen,d,%b", memreq_in.wen);
//         $display("data,fetchstage.buscntr.memreq.wdata,h,%b", memreq_in.wdata);
//     end
//     $display("data,fetchstage.buscntr.memresp.valid,d,%b", memresp_in.valid);
//     $display("data,fetchstage.buscntr.memresp.rdata,h,%b", memresp_in.rdata);
//     $display("data,fetchstage.buscntr.reg_iresp_valid,b,%b", reg_iresp_valid);
//     $display("data,fetchstage.buscntr.reg_dresp_valid,b,%b", reg_dresp_valid);
// end
// `endif

endmodule