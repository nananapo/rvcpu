module Memory #(
    parameter FILEPATH = "",
    parameter SIZE = 2048
)(
    input  wire clk,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UInt32  req_wdata,
    output wire     resp_valid,
    output UInt32   resp_rdata
);

assign req_ready    = 1;
assign resp_valid   = 1;

// memory
logic [31:0] mem [SIZE-1:0];

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

wire [31:0] addr_shift = (req_addr >> 2) % SIZE;

always @(posedge clk) begin
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