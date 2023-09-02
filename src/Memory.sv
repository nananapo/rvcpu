module Memory #(
    parameter FILEPATH = "",
    parameter ADDR_WIDTH = 16
)(
    input  wire clk,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire Addr    req_addr,
    input  wire         req_wen,
    input  wire UInt32  req_wdata,
    output wire     resp_valid,
    output UInt32   resp_rdata
);

localparam SIZE = 2 ** ADDR_WIDTH;
typedef logic [ADDR_WIDTH-1:0] MemAddr;

logic valid_old = 0;

assign req_ready    = 1;
assign resp_valid   = valid_old;

// memory
UInt32 mem [SIZE-1:0];

initial begin
    $display("Memory : %s", FILEPATH);
    `ifdef MEM_ZERO_CLEAR
    for (int l = 0; l < SIZE; l++)
        mem[l] = 32'b0;     
    `endif
    if (FILEPATH != "") begin
        $readmemh(FILEPATH, mem);
    end
    resp_rdata = 0;
end

wire MemAddr addr_shift = req_addr[ADDR_WIDTH+2 -1:2];

always @(posedge clk) begin
    valid_old <= req_valid;
    resp_rdata <= {
        mem[addr_shift][7:0],
        mem[addr_shift][15:8],
        mem[addr_shift][23:16],
        mem[addr_shift][31:24]
    };
    if (req_valid && req_wen) begin
        mem[addr_shift] <= {
            req_wdata[7:0],
            req_wdata[15:8],
            req_wdata[23:16],
            req_wdata[31:24]
        };
    end
end
endmodule