`include "include/memoryinterface.sv"

module DUnalignedAccessController (
    input wire          clk,
    inout wire DRequest     dreq,
    inout wire DResponse    dresp,
    inout wire DRequest     memreq,
    inout wire DResponse    memresp
);

wire        mem_cmd_start;
wire        mem_cmd_write;
wire        mem_cmd_ready;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire        mem_rdata_valid;
wire [31:0] mem_wdata;

assign          memreq.valid    = mem_cmd_start;
assign          memreq.wen      = mem_cmd_write;
assign          mem_cmd_ready   = memreq.ready;
assign          memreq.addr     = mem_addr;
assign          mem_rdata       = memresp.rdata;
assign          mem_rdata_valid = memresp.valid;
assign          memreq.wdata    = mem_wdata;
assign          memreq.wmask    = 32'hffffffff;

wire         input_cmd_start;
wire         input_cmd_write;
wire         output_cmd_ready;
wire [31:0]  input_addr;
wire [31:0]  output_rdata;
wire         output_rdata_valid;
wire [31:0]  input_wdata;
wire [31:0]  input_wmask;

assign input_cmd_start  = dreq.valid;
assign input_cmd_write  = dreq.wen;
assign dreq.ready       = output_cmd_ready;
assign input_addr       = dreq.addr;
assign dresp.rdata      = output_rdata;
assign dresp.valid      = output_rdata_valid;
assign input_wdata      = dreq.wdata;
assign input_wmask      = dreq.wmask;

reg         save_cmd_write  = 0;
reg [31:0]  save_addr       = 0;
reg [31:0]  save_wdata      = 0;
reg [31:0]  save_wmask      = 0;

wire[31:0]  save_addr_aligned   = {save_addr[31:2], 2'b00};

localparam STATE_IDLE                               = 0;
localparam STATE_WAIT_READY                         = 1;
localparam STATE_END                                = 2;

localparam STATE_READ_VALID_BEFORE_WRITE            = 3;
localparam STATE_WAIT_WRITE_READY                   = 4;
localparam STATE_WAIT_READNEXT_READY_BEFORE_WRITE   = 5;
localparam STATE_WAIT_READNEXT_VALID_BEFORE_WRITE   = 6;
localparam STATE_WAIT_WRITE_READY_UNALIGNED1        = 7;
localparam STATE_WAIT_WRITE_READY_UNALIGNED2        = 8;

localparam STATE_WAIT_READ_VALID                    = 9;
localparam STATE_WAIT_READNEXT_READY                = 11;
localparam STATE_WAIT_READNEXT_VALID                = 12;

localparam REGPC_NOP = 32'hffffffff;

reg [3:0]   state       = STATE_IDLE;
reg [31:0]  save_rdata1 = 0;
reg [31:0]  save_rdata2 = 0;

function func_mem_cmd_start(
    input [3:0] state,
    input mem_cmd_ready,
    input mem_rdata_valid
);
case(state)
    //STATE_IDLE                              : func_mem_cmd_start = 0;
    STATE_WAIT_READY                        : func_mem_cmd_start = 1;
    //STATE_END                               : func_mem_cmd_start = 0;
    //STATE_READ_VALID_BEFORE_WRITE           : func_mem_cmd_start = 0;
    STATE_WAIT_WRITE_READY                  : func_mem_cmd_start = 1;
    STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_cmd_start = 1;
    //STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_cmd_start = 0;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : func_mem_cmd_start = 1;
    STATE_WAIT_WRITE_READY_UNALIGNED2       : func_mem_cmd_start = 1;
    //STATE_WAIT_READ_VALID                   : func_mem_cmd_start = 0;
    STATE_WAIT_READNEXT_READY               : func_mem_cmd_start = 1;
    //STATE_WAIT_READNEXT_VALID               : func_mem_cmd_start = 0;
    default: func_mem_cmd_start = 0;
endcase
endfunction

assign mem_cmd_start = func_mem_cmd_start(state, mem_cmd_ready, mem_rdata_valid);

function func_mem_cmd_write(
    input [3:0] state,
    input mem_cmd_ready,
    input mem_rdata_valid,
    input save_cmd_write,
    input [31:0]save_addr,
    input [31:0]save_wmask
);
case(state)
    //STATE_IDLE                              : func_mem_cmd_write = 0;
    STATE_WAIT_READY                        : func_mem_cmd_write = save_cmd_write && 
                                                                   save_addr % 4 == 0 && 
                                                                   save_wmask == 32'hffffffff;
    //STATE_END                               : func_mem_cmd_write = 0;
    //STATE_READ_VALID_BEFORE_WRITE           : func_mem_cmd_write = 0;
    STATE_WAIT_WRITE_READY                  : func_mem_cmd_write = 1;
    //STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_cmd_write = 0;
    //STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_cmd_write = 0;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : func_mem_cmd_write = 1;
    STATE_WAIT_WRITE_READY_UNALIGNED2       : func_mem_cmd_write = 1;
    //STATE_WAIT_READ_VALID                   : func_mem_cmd_write = 0;
    //STATE_WAIT_READNEXT_READY               : func_mem_cmd_write = 0;
    //STATE_WAIT_READNEXT_VALID               : func_mem_cmd_write = 0;
    default: func_mem_cmd_write = 0;
endcase
endfunction

assign mem_cmd_write = func_mem_cmd_write(state, mem_cmd_ready, mem_rdata_valid, save_cmd_write, save_addr, save_wmask);

function [31:0] func_mem_addr(
    input [3:0] state,
    input [31:0] save_addr_aligned
);
case(state)
    //STATE_IDLE                              : func_mem_addr = REGPC_NOP;
    STATE_WAIT_READY                        : func_mem_addr = save_addr_aligned;
    //STATE_END                               : func_mem_addr = REGPC_NOP;
    STATE_READ_VALID_BEFORE_WRITE           : func_mem_addr = save_addr_aligned;
    STATE_WAIT_WRITE_READY                  : func_mem_addr = save_addr_aligned;
    STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_addr = save_addr_aligned + 4;
    STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_addr = save_addr_aligned + 4;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : func_mem_addr = save_addr_aligned;
    STATE_WAIT_WRITE_READY_UNALIGNED2       : func_mem_addr = save_addr_aligned + 4;
    STATE_WAIT_READ_VALID                   : func_mem_addr = save_addr_aligned;
    STATE_WAIT_READNEXT_READY               : func_mem_addr = save_addr_aligned + 4;
    STATE_WAIT_READNEXT_VALID               : func_mem_addr = save_addr_aligned + 4;
    default: func_mem_addr = REGPC_NOP;
endcase
endfunction

assign mem_addr = func_mem_addr(state, save_addr_aligned);

function [31:0] func_mem_wdata(
    input [3:0] state,
    input [31:0] save_wdata,
    input [31:0] save_wmask,
    input [31:0] save_rdata1,
    input [31:0] save_rdata2
);
case(state)
    //STATE_IDLE                              : func_mem_wdata = 0;
    STATE_WAIT_READY                        : func_mem_wdata = save_wdata;
    //STATE_END                               : func_mem_wdata = 0;
    //STATE_READ_VALID_BEFORE_WRITE           : func_mem_wdata = 0;
    STATE_WAIT_WRITE_READY                  : func_mem_wdata = (save_rdata1 & ~save_wmask) | (save_wdata & save_wmask);
    //STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_wdata = 0;
    //STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_wdata = 0;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : 
        case (save_addr % 4) 
            1: func_mem_wdata = {(save_rdata1[31:8]  & ~save_wmask[23:0]) | (save_wdata[23:0] & save_wmask[23:0]) , save_rdata1[7:0]};
            2: func_mem_wdata = {(save_rdata1[31:16] & ~save_wmask[15:0]) | (save_wdata[15:0] & save_wmask[15:0]) , save_rdata1[15:0]};
            3: func_mem_wdata = {(save_rdata1[31:24] & ~save_wmask[7:0])  | (save_wdata[7:0]  & save_wmask[7:0])  , save_rdata1[23:0]};
            0: func_mem_wdata = 0;
        endcase 
    STATE_WAIT_WRITE_READY_UNALIGNED2       :
        case (save_addr % 4) 
            1: func_mem_wdata = {save_rdata2[31:8] , (save_rdata2[7:0]  & ~save_wmask[31:24]) | (save_wdata[31:24] & save_wmask[31:24])};
            2: func_mem_wdata = {save_rdata2[31:16], (save_rdata2[15:0] & ~save_wmask[31:16]) | (save_wdata[31:16] & save_wmask[31:16])};
            3: func_mem_wdata = {save_rdata2[31:24], (save_rdata2[23:0] & ~save_wmask[31:8])  | (save_wdata[31:8]  & save_wmask[31:8]) };
            0: func_mem_wdata = 0;
        endcase 
    //STATE_WAIT_READ_VALID                   : func_mem_wdata = 0;
    //STATE_WAIT_READNEXT_READY               : func_mem_wdata = 0;
    //STATE_WAIT_READNEXT_VALID               : func_mem_wdata = 0;
    default: func_mem_wdata = 0;
endcase
endfunction

assign mem_wdata = func_mem_wdata(state, save_wdata, save_wmask, save_rdata1, save_rdata2);

assign output_cmd_ready = (
    state == STATE_IDLE ? 1 : 0
);

assign output_rdata = (
    state == STATE_WAIT_READ_VALID ? mem_rdata :
    state == STATE_WAIT_READNEXT_VALID ? (
        save_addr % 4 == 1 ? {mem_rdata[7:0] , save_rdata1[31:8] } :
        save_addr % 4 == 2 ? {mem_rdata[15:0], save_rdata1[31:16]} :
        save_addr % 4 == 3 ? {mem_rdata[23:0], save_rdata1[31:24]} : 
        32'hffffffff
    ) : 32'hffffffff
);

assign output_rdata_valid = (
    state == STATE_WAIT_READ_VALID ? (
        mem_rdata_valid && save_addr % 4 == 0
    ) :
    state == STATE_WAIT_READNEXT_VALID ? (
        mem_rdata_valid
    ) : 0
);

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (input_cmd_start) begin
                save_cmd_write  <= input_cmd_write;
                save_addr       <= input_addr;
                save_wdata      <= input_wdata;
                save_wmask      <= input_wmask;
                state           <= STATE_WAIT_READY;
            end
        end
        STATE_WAIT_READY: begin
            if (mem_cmd_ready) begin
                if (save_cmd_write) begin
                    if (save_addr % 4 == 0) begin
                        if (save_wmask == 32'hffffffff)
                            state   <= STATE_END;// 投げっぱなし
                        else
                            state   <= STATE_READ_VALID_BEFORE_WRITE;
                    end else
                        state   <= STATE_READ_VALID_BEFORE_WRITE;
                end else
                    state   <= STATE_WAIT_READ_VALID;
            end
        end
        STATE_END: state    <= STATE_IDLE;
        STATE_READ_VALID_BEFORE_WRITE: begin
            if (mem_rdata_valid) begin
                save_rdata1 <= mem_rdata;
                if (save_addr % 4 == 0) begin
                    state <= STATE_WAIT_WRITE_READY;
                end else begin
                    state <= STATE_WAIT_READNEXT_READY_BEFORE_WRITE;
                end
            end
        end
        STATE_WAIT_WRITE_READY: begin
            if (mem_cmd_ready)
                state   <= STATE_END;
        end
        STATE_WAIT_READNEXT_READY_BEFORE_WRITE: begin
            if (mem_cmd_ready)
                state   <= STATE_WAIT_READNEXT_VALID_BEFORE_WRITE;
        end
        STATE_WAIT_READNEXT_VALID_BEFORE_WRITE: begin
            if (mem_rdata_valid) begin
                save_rdata2 <= mem_rdata;
                state       <= STATE_WAIT_WRITE_READY_UNALIGNED1;
            end
        end
        STATE_WAIT_WRITE_READY_UNALIGNED1: begin
            // TODO ここで死ぬ
            if (mem_cmd_ready)
                state   <= STATE_WAIT_WRITE_READY_UNALIGNED2;
        end
        STATE_WAIT_WRITE_READY_UNALIGNED2: begin
            if (mem_cmd_ready)
                state   <= STATE_END;
        end
        STATE_WAIT_READ_VALID: begin
            if (mem_rdata_valid) begin
                if (save_addr % 4 == 0)
                    state       <= STATE_END;
                else begin
                    save_rdata1 <= mem_rdata;
                    state       <= STATE_WAIT_READNEXT_READY;
                end
            end
        end
        STATE_WAIT_READNEXT_READY: begin
            if (mem_cmd_ready)
                state   <= STATE_WAIT_READNEXT_VALID;
        end
        STATE_WAIT_READNEXT_VALID: begin
            if (mem_rdata_valid)
                state   <= STATE_END;
        end
    endcase
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    // $display("data,mem_unaligned_controller.state,d,%b", state);
    // $display("data,mem_unaligned_controller.ready,b,%b", output_cmd_ready);
    // $display("data,mem_unaligned_controller.cmd_start,b,%b", input_cmd_start);
    // $display("data,mem_unaligned_controller.wmask,b,%b", input_wmask);
    // $display("data,mem_unaligned_controller.memresp.valid,b,%b", memresp.valid);
    // $display("data,mem_unaligned_controller.memresp.rdata,h,%b", memresp.rdata);
end
`endif

endmodule

/*
    0  1  2  3
0  be be fe ca
4  ef be ad de

0 : cafebebe
1 : efcafebe
2 : beefcafe
3 : adbeefca

4 : deadbeef
*/