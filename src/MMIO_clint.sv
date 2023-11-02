`include "basic.svh"
`include "pkg_memory.svh"
`include "pkg_conf.svh"

module MMIO_clint (
    input  wire         clk,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire Addr    req_addr,
    input  wire         req_wen,
    input  wire UIntX   req_wdata,

    output wire         resp_valid,
    output UInt32       resp_rdata,

    output wire         mti_pending // Machine Timer Interrupt
);

assign req_ready    = 1;
assign resp_valid   = 1;

UInt64 mtime    = 0;
UInt64 mtimecmp = -1;

int timecounter = 0;
always @(posedge clk) begin
    // mtimeをμ秒ごとにインクリメント
    if (timecounter == conf::FREQUENCY_MHz - 1) begin
        timecounter <= 0;
        mtime       <= mtime + 1;
    end else begin
        timecounter <= timecounter + 1;
    end
end

assign mti_pending = mtime >= mtimecmp;

always @(posedge clk) begin
    `ifdef XLEN32
        case (req_addr)
            MemMap::CLINT_MTIME:    resp_rdata <= mtime[31:0];
            MemMap::CLINT_MTIMEH:   resp_rdata <= mtime[63:32];
            MemMap::CLINT_MTIMECMP: resp_rdata <= mtimecmp[31:0];
            MemMap::CLINT_MTIMECMPH:resp_rdata <= mtimecmp[63:32];
            default: begin end
        endcase
        if (req_ready & req_valid & req_wen) begin
            case (req_addr)
                MemMap::CLINT_MTIMECMP: mtimecmp[31:0]  <= req_wdata;
                MemMap::CLINT_MTIMECMPH:mtimecmp[63:32] <= req_wdata;
                default: begin end
            endcase
        end
    `elsif XLEN64
        case (req_addr)
            MemMap::CLINT_MTIME:    resp_rdata <= mtime;
            MemMap::CLINT_MTIMECMP: resp_rdata <= mtimecmp;
            default: begin end
        endcase
        if (req_valid & req_wen) begin
            case (req_addr)
                MemMap::CLINT_MTIMECMP: mtimecmp <= req_wdata;
                default: begin end
            endcase
        end
    `endif
end

endmodule