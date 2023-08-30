module MemBusCntr (
    input wire MemBusReq    ireq_in,
    output MemBusResp       iresp_in,
    input wire MemBusReq    dreq_in,
    output MemBusResp       dresp_in,
    input wire MemBusReq    memreq_in,
    output wire MemBusResp  memresp_in
);

MemBusReq   s_ireq;
MemBusReq   s_dreq;

typedef enum [1:0] {
    CHECK_I,
    CHECK_D,
    I_WAIT_READY,
    I_WAIT_VALID,
    D_WAIT_READY,
    D_WAIT_VALID
} statetype;

statetype state = IDLE;

assign ireq_in.ready    = state == CHECK_I;
assign dreq_in.ready    = state == CHECK_D;

assign memreq_in.valid  = state == I_WAIT_READY || state == D_WAIT_READY;
assign memreq_in.addr   = state == I_WAIT_READY ? s_ireq.addr : s_dreq.addr;
assign memreq_in.wen    = state == I_WAIT_READY ? s_ireq.wen : s_dreq.wen;
assign memreq_in.wen    = state == I_WAIT_READY ? s_ireq.wdata : s_dreq.wdata;

// CHECK_I -> CHECK_D -> CHECK_I -> ...
//         -> I_WAIT_READY -> I_WAIT_VALID -> CHECK_D -> CHECK_I -> ...
//                                                    -> D_WAIT_READY -> D_WAIT_VALID -> CHECK_I -> CHECK_D -> ...
always @(posedge clk) begin
    if (state != I_WAIT_VALID && state != D_WAIT_VALID) begin
        iresp_in.valid  <= 0;
        dresp_in.valid  <= 0;
    end
    case (state)
        CHECK_I: begin
            s_ireq  <= ireq_in;
            state   <= ireq_in.valid ? I_WAIT_READY : CHECK_D;
        end
        I_WAIT_READY: if (memreq_in.ready) state <= s_ireq.wen ? CHECK_D : I_WAIT_VALID;
        I_WAIT_VALID: begin
            if (memresp_in.valid) begin
                state           <= CHECK_D;
                iresp_in.valid  <= 1;
                iresp_in.addr   <= s_ireq.addr;
                iresp_in.rdata  <= memresp_in.rdata;
            end
        end
        CHECK_D: begin
            s_dreq  <= dreq_in;
            state   <= dreq_in.valid ? D_WAIT_READY : CHECK_I;
        end
        D_WAIT_READY: if (memreq_in.ready) state <= s_dreq.wen ? CHECK_I : D_WAIT_VALID;
        D_WAIT_VALID: begin
            if (memresp_in.valid) begin
                state           <= CHECK_I;
                dresp_in.valid  <= 1;
                dresp_in.addr   <= s_dreq.addr;
                dresp_in.rdata  <= memresp_in.rdata;
            end
        end
    endcase
end

endmodule