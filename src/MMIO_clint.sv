module MMIO_clint #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire Addr    req_addr,
    input  wire         req_wen,
    input  wire UIntX   req_wdata,
    
    output wire     resp_valid,
    output UInt32   resp_rdata,

    input wire UInt64   mtime,
    output UInt64       mtimecmp
);

`include "include/memorymap.svh"

assign req_ready    = 1;
assign resp_valid   = 1;

initial mtimecmp = 64'hffff_ffff_ffff_ffff;

always @(posedge clk) begin
    `ifdef XLEN32
        case (req_addr) 
            CLINT_MTIME:    resp_rdata <= mtime[31:0];
            CLINT_MTIMEH:   resp_rdata <= mtime[63:32];
            CLINT_MTIMECMP: resp_rdata <= mtimecmp[31:0];
            CLINT_MTIMECMPH:resp_rdata <= mtimecmp[63:32];
            default: begin end
        endcase
        if (req_wen) begin
            case (req_addr) 
                CLINT_MTIMECMP: mtimecmp[31:0]  <= req_wdata;
                CLINT_MTIMECMPH:mtimecmp[63:32] <= req_wdata;
                default: begin end
            endcase
        end
    `elsif XLEN64
        case (req_addr) 
            CLINT_MTIME:    resp_rdata <= mtime;
            CLINT_MTIMECMP: resp_rdata <= mtimecmp;
            default: begin end
        endcase
        if (req_wen) begin
            case (req_addr) 
                CLINT_MTIMECMP: mtimecmp <= req_wdata;
                default: begin end
            endcase
        end
    `endif
end

endmodule