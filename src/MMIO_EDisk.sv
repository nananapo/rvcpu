module MMIO_EDisk (
    input  wire         clk,

    output wire         req_ready,
    input  wire         req_valid,
    input  wire Addr    req_addr,
    input  wire         req_wen,
    input  wire UIntX   req_wdata,
    output wire         resp_valid,
    output UInt32       resp_rdata
);

`include "memorymap.svh"

typedef enum logic [1:0] {
    IDLE,
    COMMIT,
    VALID
} statetype;

statetype state = IDLE;

assign req_ready    = state == IDLE;
assign resp_valid   = state == VALID;

UIntX edisk_addr    = 0;
logic edisk_wen     = 0;
UIntX edisk_rwdata   = 0;

// サイズは適当
wire [22:0] waddr = edisk_addr[24:2];
UInt32 edisk[2**23-1:0];

`ifndef EDISK_FILEPATH
initial
    $display("WARNING : EDISK_FILEPATH not specified");
`endif

initial begin
    `ifdef EDISK_FILEPATH
        $readmemh(`EDISK_FILEPATH, edisk);
    `endif
end

always @(posedge clk) begin
    case (state)
    IDLE: if (req_valid) begin
        case (req_addr)
        EDISK_ADDR: begin
            state       <= VALID;
            resp_rdata  <= edisk_addr;
            if (req_wen) edisk_addr <= req_wdata;
        end
        EDISK_WEN: begin
            state       <= VALID;
            resp_rdata  <= {{`XLEN-1{1'b0}}, edisk_wen};
            if (req_wen) edisk_wen <= req_wdata[0];
        end
        EDISK_DATA: begin
            state           <= COMMIT;
            edisk_rwdata    <= req_wdata;
        end
        default: begin end
        endcase
    end
    COMMIT: begin
        state   <= VALID;
        if (edisk_wen)
            edisk[waddr] <= edisk_rwdata;
        resp_rdata  <= edisk[waddr];
        // $display("addr %h : %h", waddr, edisk[waddr]);
    end
    VALID: state <= IDLE;
    default: begin
        $display("ERROR MMIO_EDisk.sv : Unknown state %d", state);
        $finish;
        $finish;
        $finish;
    end
    endcase
end

endmodule