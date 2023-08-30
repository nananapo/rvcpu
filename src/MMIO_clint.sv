module MMIO_clint #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire UIntX   req_addr,
    input  wire         req_wen,
    input  wire UInt32  req_wdata,
    
    output wire     resp_valid,
    output UInt32   resp_rdata,

    input wire UInt64   mtime,
    output UInt64       mtimecmp
);

assign req_ready    = 1;
assign resp_valid   = 1;

`include "include/memorymap.sv"

initial begin
    mtimecmp = 64'hffff_ffff_ffff_ffff;
end

wire is_mtime       = req_addr == CLINT_MTIME;
wire is_mtimeh      = req_addr == CLINT_MTIMEH;
wire is_mtimecmp    = req_addr == CLINT_MTIMECMP;
wire is_mtimecmph   = req_addr == CLINT_MTIMECMPH;
wire is_debugreg    = req_addr == CLINT_DEBUG;

logic nopr = 0;
logic nopw = 0;
logic [31:0] debugreg = 0;

always @(posedge clk) begin
    case (req_addr) 
        CLINT_MTIME:       resp_rdata <= mtime[31:0];
        CLINT_MTIMEH:      resp_rdata <= mtime[63:32];
        CLINT_MTIMECMP:    resp_rdata <= mtimecmp[31:0];
        CLINT_MTIMECMPH:   resp_rdata <= mtimecmp[63:32];
        CLINT_DEBUG:       resp_rdata <= debugreg;
        default:                    nopr <= 0;
    endcase

    if (req_wen) begin
        case (req_addr) 
            CLINT_MTIMECMP:    mtimecmp[31:0]  <= req_wdata;
            CLINT_MTIMECMPH:   mtimecmp[63:32] <= req_wdata;
            CLINT_DEBUG:       debugreg <= req_wdata;
            default:                    nopw <= 0;
        endcase
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,debug.isdebugreg,b,%b", is_debugreg);
    $display("data,debug.debugreg,h,%b", debugreg);
end
`endif

endmodule