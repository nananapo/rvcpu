module MemoryMapped_MachineTimeRegister #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,
    
    input  wire [31:0]  input_addr,
    output reg  [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata,

    input wire  [63:0]  mtime,
    output reg  [63:0]  mtimecmp
);

`include "include/memorymap.v"

assign output_cmd_ready     = 1;
assign output_rdata_valid   = 1;

wire is_mtime       = input_addr == MACHINETIMEREG_MTIME;
wire is_mtimeh      = input_addr == MACHINETIMEREG_MTIMEH;
wire is_mtimecmp    = input_addr == MACHINETIMEREG_MTIMECMP;
wire is_mtimecmph   = input_addr == MACHINETIMEREG_MTIMECMPH;

reg nopr = 0;
reg nopw = 0;

always @(posedge clk) begin
    case (input_addr) 
        MACHINETIMEREG_MTIME:       output_rdata <= mtime[31:0];
        MACHINETIMEREG_MTIMEH:      output_rdata <= mtime[63:32];
        MACHINETIMEREG_MTIMECMP:    output_rdata <= mtimecmp[31:0];
        MACHINETIMEREG_MTIMECMPH:   output_rdata <= mtimecmp[63:32];
        default:                    nop <= 0;
    endcase

    if (input_cmd_write) begin
        case (input_addr) 
            MACHINETIMEREG_MTIMECMP:    mtimecmp[31:0]  <= input_wdata;
            MACHINETIMEREG_MTIMECMPH:   mtimecmp[63:32] <= input_wdata;
            default:                    nopw <= 0;
        endcase
    end
end

endmodule