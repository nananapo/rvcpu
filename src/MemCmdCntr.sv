module MemCmdCntr (
    input wire  clk,
    input wire  exit,

    inout wire DRequest     req,
    inout wire DResponse    dresp,

    input wire          mem_req_ready,
    output wire         mem_req_valid,
    output wire [31:0]  mem_req_addr,
    output wire         mem_req_wen,
    output wire [31:0]  mem_req_wdata,
    input wire [31:0]   mem_resp_rdata,
    input wire          mem_resp_valid
);

typedef enum logic [1:0] {
    WAIT_CMD, WAIT_READY, WAIT_READ_VALID
} statetype;

statetype state = WAIT_CMD;

DRequest saved_req;
initial begin
    saved_req.valid = 0;
end

// start : write : addr : wdata
function [1 + 1 + 32 + 32 - 1:0] memsig(
    input statetype state,

    input           req_valid,
    input [31:0]    req_addr,
    input           req_wen,
    input [31:0]    req_wdata,

    input           sreq_valid,
    input [31:0]    sreq_addr,
    input           sreq_wen,
    input [31:0]    sreq_wdata
);
case(state)
    WAIT_CMD: memsig = { req_valid, req_wen, req_addr, req_wdata };
    WAIT_READY: memsig = { sreq_valid, sreq_wen, sreq_addr, sreq_wdata };
    WAIT_READ_VALID: memsig = { req_valid, req_wen, req_addr, req_wdata };
    default: memsig = {1'bz, 1'bz, 32'bz, 32'bz}; // ない
endcase
endfunction

assign {mem_req_valid, mem_req_wen, mem_req_addr, mem_req_wdata} = memsig(
    state,
    req.valid,
    req.addr,
    req.wen,
    req.wdata,
    saved_req.valid,
    saved_req.addr,
    saved_req.wen,
    saved_req.wdata
);

wire req_ready      = state == WAIT_CMD || 
                      (state == WAIT_READ_VALID && !saved_req.valid);

assign req.ready   = req_ready;
assign dresp.valid  = state == WAIT_READ_VALID && mem_resp_valid;
assign dresp.addr   = saved_req.addr;
assign dresp.rdata  = mem_resp_rdata;

always @(posedge clk) begin
    if (!exit) begin case (state) 
        WAIT_CMD: begin
            saved_req  <= req;
            if (req.valid) begin
                if (!mem_req_ready)
                    state <= WAIT_READY;
                else
                    state <= statetype'(req.wen ? WAIT_CMD : WAIT_READ_VALID);
            end
        end
        WAIT_READY: begin
            if (mem_req_ready)
                state <= statetype'(saved_req.wen ? WAIT_CMD : WAIT_READ_VALID);
        end
        WAIT_READ_VALID: begin
            if (mem_resp_valid) begin
                if (req.valid) begin
                    saved_req  <= req;
                    if (!mem_req_ready)
                        state <= WAIT_READY;
                    else
                        state <= statetype'(req.wen ? WAIT_CMD : WAIT_READ_VALID);
                end else
                    state <= WAIT_CMD;
            end
        end
        default: begin end
    endcase end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,memcmdcntr.state,d,%b", state);
    $display("data,memcmdcntr.req.ready,b,%b", req.ready);
    $display("data,memcmdcntr.req.valid,b,%b", req.valid);
    $display("data,memcmdcntr.dresp.valid,b,%b", dresp.valid);
    $display("data,memcmdcntr.iresp.valid,b,%b", iresp.valid);
end
`endif

endmodule