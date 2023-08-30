// direct map
module MemDCache #(
    parameter CACHE_WIDTH = 10
) (
    input wire clk,

    inout wire DCacheReq    dreq,
    inout wire DCacheResp   dresp,
    inout wire MemBusReq    busreq,
    inout wire MemBusResp   busresp
);

localparam CACHE_SIZE = 2 ** CACHE_WIDTH;

logic [31:0] cache_data  [CACHE_SIZE-1:0];
logic [31:0] cache_addrs [CACHE_SIZE-1:0];
logic cache_valid[CACHE_SIZE-1:0];
logic cache_modified[CACHE_SIZE-1:0];

typedef enum [1:0] {
    IDLE,
    MEM_READ_READY,
    MEM_READ_VALID,
    MEM_RESP_VALID,
    MEM_WRITE_READY
    // ,MEM_WRITE_BACK
} statetype;

statetype   state = IDLE;
DCacheReq   s_req;

logic [31:0] writeback_data;

logic       dresp_valid_reg;
logic[31:0] dresp_rdata_reg;

assign dreq.ready   = state == IDLE;
assign dresp.valid  = dresp_valid_reg;
assign dresp.rdata  = dresp_rdata_reg;

assign busreq.valid = state == MEM_READ_READY || state == MEM_WRITE_READY;
assign busreq.addr  = s_req.addr;
assign busreq.wen   = s_req.wen;
assign busreq.wdata = writeback_data;

wire [CACHE_WIDTH-1:0] req_addr_index = state == IDLE ? dreq.addr[CACHE_WIDTH + 2 - 1 : 2] : s_req.addr[CACHE_WIDTH + 2 - 1 : 2];
wire req_addr_in_valid_cache = cache_addrs[req_addr_index];
wire req_addr_is_modified = cache_modified[req_addr_index];

wire [CACHE_WIDTH-1:0] req_mem_index = req_addr_index;

always @(posedge clk) begin
    
    dresp_valid_reg <= (state == IDLE && req_addr_in_valid_cache) || state == MEM_RESP_VALID;
    dresp_rdata_reg <= cache_data[req_mem_index];
    
    case (state)
    IDLE: begin
        s_req <= dreq;
        if (dreq.valid && !req_addr_in_valid_cache) begin
            if (dreq.wen) begin
                if (req_addr_is_modified) begin
                    state <= MEM_WRITE_READY;
                    writeback_data <= cache_data[req_mem_index];
                end else begin
                    cache_data[req_mem_index]       <= dreq.wdata;
                    cache_addrs[req_addr_index]     <= dreq.addr;
                    cache_valid[req_addr_index]     <= 1;
                    cache_modified[req_addr_index]  <= 1;
                end
            end else begin
                if (req_addr_is_modified) begin
                    state <= MEM_WRITE_READY;
                    writeback_data <= cache_data[req_mem_index];
                end else begin
                    state <= MEM_READ_READY;
                end
            end
        end
    end
    MEM_READ_READY: begin
        if (busreq.ready) begin
            state <= MEM_READ_VALID;
            cache_addrs[req_addr_index]     <= s_req.addr;
            cache_valid[req_addr_index]     <= 0;
            cache_modified[req_addr_index]  <= 0;
        end
    end
    MEM_READ_VALID: begin
        if (busresp.valid) begin
            state <= MEM_RESP_VALID;
            cache_data[req_mem_index]   <= busresp.rdata;
            cache_valid[req_addr_index] <= 1;
        end
    end
    MEM_RESP_VALID: state <= IDLE;
    MEM_WRITE_READY: begin
        if (busreq.ready) begin
            if (s_req.wen) begin // ライトバック -> modifiedとして書き込みで終わり
                state <= IDLE;
                cache_data[req_mem_index]       <= sreq.wdata;
                cache_addrs[req_addr_index]     <= sreq.addr;
                cache_valid[req_addr_index]     <= 1;
                cache_modified[req_addr_index]  <= 1;
            end else begin // ライトバック -> read
                state <= MEM_READ_READY;
                cache_valid[req_addr_index]     <= 0;
                cache_modified[req_addr_index]  <= 0;
            end
        end
    end
    default: begin
        $display("MemICache : Unknown state");
        $finish;
    end
    endcase
end

endmodule