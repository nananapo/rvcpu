module MemCmdCntr (
    input wire  clk,
    input wire  exit,

    inout wire IRequest     ireq,
    inout wire IResponse   iresp,
    inout wire DRequest     dreq,
    inout wire DResponse   dresp,

    input wire          mem_req_ready,
    output wire         mem_req_valid,
    output wire [31:0]  mem_req_addr,
    output wire         mem_req_wen,
    output wire [31:0]  mem_req_wdata,
    input wire [31:0]   mem_resp_rdata,
    input wire          mem_resp_valid
);

typedef enum reg [1:0] {
    WAIT_CMD, WAIT_READY, WAIT_READ_VALID
} statetype;

statetype state = WAIT_CMD;

IRequest saved_ireq;
DRequest saved_dreq;

initial begin
    saved_dreq.valid = 0;
    saved_ireq.valid = 0;
end

// start : write : addr : wdata
function [1 + 1 + 32 + 32 - 1:0] memsig(
    input statetype state,
    input           ireq_valid,
    input [31:0]    ireq_addr,

    input           dreq_valid,
    input [31:0]    dreq_addr,
    input           dreq_wen,
    input [31:0]    dreq_wdata,

    input           sireq_valid,
    input [31:0]    sireq_addr,

    input           sdreq_valid,
    input [31:0]    sdreq_addr,
    input           sdreq_wen,
    input [31:0]    sdreq_wdata
);
case(state)
    WAIT_CMD:
        memsig = {  ireq_valid || dreq_valid,
                    !ireq_valid && dreq_valid && dreq_wen,
                    ireq_valid? ireq_addr : dreq_addr, // ireq優先
                    dreq_wdata  };
    WAIT_READY:
        memsig = {  sireq_valid || sdreq_valid,
                    !sireq_valid && sdreq_valid && sdreq_wen,
                    sireq_valid ? sireq_addr : sdreq_addr, // ireq優先
                    sdreq_wdata  };
    WAIT_READ_VALID:
        memsig = {  // 1. sireq_valid && sdreq_valid => sireqが終わって、sdreqが始まる
                    // 2. sireq_valid && !sdreq_valid => sireqが終わって、ireqかdreqが始まる
                    // 3. !sireq_valid => sireqが終わったかsireqが無くて、sdreqが終わったので、ireqかdreqが始まる
                    (sireq_valid && sdreq_valid) ||
                    // 2. (sireq_valid && !sdreq_valid && (ireq_valid || dreq_valid)) || 
                    // 3. (!sireq_valid && (ireq_valid || dreq_valid))
                    // 2と3は結局ireqかdreq
                    (ireq_valid || dreq_valid)
                    ,
                    // 1. sdreq
                    // 2,3. ireq or dreq、ただしireq優先。dreqならdreq_wen。ireqなら0
                    (sireq_valid && sdreq_valid) ? sdreq_wen :
                    (ireq_valid ? 1'b0 : dreq_wen)
                    ,
                    // 1. sdreq
                    // 2,3. ireq or dreq、ただしireq優先
                    (sireq_valid && sdreq_valid) ? sdreq_addr :
                    (ireq_valid ? ireq_addr : dreq_addr)
                    ,
                    // 1ならsdreq、それ以外ならdreq
                    (sireq_valid && sdreq_valid) ? sdreq_wdata : dreq_wdata
                    };
    default: memsig = {1'bz, 1'bz, 32'bz, 32'bz}; // ない
endcase
endfunction


assign {mem_req_valid, mem_req_wen, mem_req_addr, mem_req_wdata} = memsig(
    state,
    ireq.valid,
    ireq.addr,
    dreq.valid,
    dreq.addr,
    dreq.wen,
    dreq.wdata,
    saved_ireq.valid,
    saved_ireq.addr,
    saved_dreq.valid,
    saved_dreq.addr,
    saved_dreq.wen,
    saved_dreq.wdata
);

wire req_ready      = state == WAIT_CMD || 
                      (state == WAIT_READ_VALID && !(saved_ireq.valid && saved_dreq.valid));

assign ireq.ready   = req_ready;
assign iresp.valid  = state == WAIT_READ_VALID && mem_resp_valid && saved_ireq.valid;
assign iresp.addr   = saved_ireq.addr;
assign iresp.inst   = mem_resp_rdata;

assign dreq.ready   = req_ready;
assign dresp.valid  = state == WAIT_READ_VALID && mem_resp_valid && !saved_ireq.valid;
assign dresp.addr   = saved_dreq.addr;
assign dresp.rdata  = mem_resp_rdata;

always @(posedge clk) begin
    if (!exit) begin case (state) 
        WAIT_CMD: begin
            saved_ireq  <= ireq;
            saved_dreq  <= dreq;
            if (ireq.valid || dreq.valid) begin
                if (!mem_req_ready)  state <= WAIT_READY;
                else if (ireq.valid) state <= WAIT_READ_VALID;
                else if (dreq.valid) state <= statetype'(dreq.wen ? WAIT_CMD : WAIT_READ_VALID);
            end
        end
        WAIT_READY: begin
            if (mem_req_ready) begin
                if (saved_ireq.valid)
                    state <= WAIT_READ_VALID;
                else if(saved_dreq.valid)
                    state <= statetype'(saved_dreq.wen ? WAIT_CMD : WAIT_READ_VALID);
            end
        end
        WAIT_READ_VALID: begin
            if (mem_resp_valid) begin
                // ireqが終わった
                if (saved_ireq.valid) begin
                    // dreqが始まる
                    if (saved_dreq.valid) begin
                        saved_ireq.valid    <= 0;
                        state               <= statetype'(saved_dreq.wen ? WAIT_CMD : WAIT_READ_VALID);
                    // 新しく始める
                    end else if (ireq.valid || dreq.valid) begin
                        saved_ireq  <= ireq;
                        saved_dreq  <= dreq;
                        if (!mem_req_ready)  state <= WAIT_READY;
                        else if (ireq.valid) state <= WAIT_READ_VALID;
                        else if (dreq.valid) state <= statetype'(dreq.wen ? WAIT_CMD : WAIT_READ_VALID);
                    end else
                        state       <= WAIT_CMD;
                // dreqが終わった => 新しく始める
                end else if (saved_dreq.valid) begin
                    if (ireq.valid || dreq.valid) begin
                        saved_ireq  <= ireq;
                        saved_dreq  <= dreq;
                        if (!mem_req_ready)  state <= WAIT_READY;
                        else if (ireq.valid) state <= WAIT_READ_VALID;
                        else if (dreq.valid) state <= statetype'(dreq.wen ? WAIT_CMD : WAIT_READ_VALID);
                    end else
                        state       <= WAIT_CMD;
                end
            end
        end
        default: begin end
    endcase end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,meminterface.state,d,%b", state);
    $display("data,meminterface.dreq.ready,b,%b", dreq.ready);
    $display("data,meminterface.dreq.valid,b,%b", dreq.valid);
    $display("data,meminterface.dresp.valid,b,%b", dresp.valid);
    $display("data,meminterface.ireq.ready,b,%b", ireq.ready);
    $display("data,meminterface.ireq.valid,b,%b", ireq.valid);
    $display("data,meminterface.iresp.valid,b,%b", iresp.valid);
end
`endif

endmodule