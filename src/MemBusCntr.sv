module MemBusCntr (
    input wire clk,
    inout wire MemBusReq    ireq_in,
    inout wire MemBusResp   iresp_in,
    inout wire MemBusReq    dreq_in,
    inout wire MemBusResp   dresp_in,
    inout wire MemBusReq    memreq_in,
    inout wire MemBusResp   memresp_in
);

MemBusReq   s_ireq;
MemBusReq   s_dreq;

// CHECK_I -> CHECK_D -> CHECK_I -> ...
//         -> I_WAIT_READY -> I_WAIT_VALID -> CHECK_D -> CHECK_I -> ...
//                                                    -> D_WAIT_READY -> D_WAIT_VALID -> CHECK_I -> CHECK_D -> ...
typedef enum logic [2:0] {
    CHECK_I,
    CHECK_D,
    I_WAIT_READY,
    I_WAIT_VALID,
    D_WAIT_READY,
    D_WAIT_VALID
} statetype;

statetype state = CHECK_I;

assign ireq_in.ready    = state == CHECK_I;
assign dreq_in.ready    = state == CHECK_D;

// TODO レジスタを介さない
assign memreq_in.valid  = state == I_WAIT_READY || state == D_WAIT_READY;
assign memreq_in.addr   = state == I_WAIT_READY ? s_ireq.addr  : s_dreq.addr;
assign memreq_in.wen    = state == I_WAIT_READY ? s_ireq.wen   : s_dreq.wen;
assign memreq_in.wdata  = state == I_WAIT_READY ? s_ireq.wdata : s_dreq.wdata;

logic   reg_iresp_valid;
logic   reg_dresp_valid;
Addr    reg_resp_addr;
UInt32  reg_resp_rdata;

// TODO レジスタを介さない
assign iresp_in.valid = reg_iresp_valid;
assign iresp_in.addr  = reg_resp_addr;
assign iresp_in.rdata = reg_resp_rdata;

assign dresp_in.valid = reg_dresp_valid;
assign dresp_in.addr  = reg_resp_addr;
assign dresp_in.rdata = reg_resp_rdata;

always @(posedge clk) begin
    case (state)
        CHECK_I: begin
            reg_iresp_valid <= 0;
            reg_dresp_valid <= 0;

            s_ireq  <= ireq_in;
            state   <= ireq_in.valid ? I_WAIT_READY : CHECK_D;
        end
        CHECK_D: begin
            reg_iresp_valid <= 0;
            reg_dresp_valid <= 0;
            
            s_dreq  <= dreq_in;
            state   <= dreq_in.valid ? D_WAIT_READY : CHECK_I;
        end
        I_WAIT_READY: if (memreq_in.ready) state <= s_ireq.wen ? CHECK_D : I_WAIT_VALID;
        I_WAIT_VALID: begin
            if (memresp_in.valid) begin
                state           <= CHECK_D;
                reg_iresp_valid <= 1;
                reg_resp_addr   <= s_ireq.addr;
                reg_resp_rdata  <= memresp_in.rdata;
            end
        end
        D_WAIT_READY: if (memreq_in.ready) state <= s_dreq.wen ? CHECK_I : D_WAIT_VALID;
        D_WAIT_VALID: begin
            if (memresp_in.valid) begin
                state           <= CHECK_I;
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