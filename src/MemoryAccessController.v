module MemoryAccessController #(
    parameter MEMORY_SIZE = 4096,
    parameter MEMORY_FILE = ""
) (
    input  wire         clk,
    input  wire         uart_rx,
    output wire         uart_tx,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,
    input  wire [31:0]  input_addr,
    output wire [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata,
    input  wire [31:0]  input_wmask
);

wire        mem_cmd_start;
wire        mem_cmd_write;
wire        mem_cmd_ready;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire        mem_rdata_valid;
wire [31:0] mem_wdata;

Memory #(
    .MEMORY_SIZE(MEMORY_SIZE),
    .MEMORY_FILE(MEMORY_FILE)
) memory (
    .clk(clk),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),

    .input_cmd_start(mem_cmd_start),
    .input_cmd_write(mem_cmd_write),
    .output_cmd_ready(mem_cmd_ready),
    .input_addr(mem_addr),
    .output_rdata(mem_rdata),
    .output_rdata_valid(mem_rdata_valid),
    .input_wdata(mem_wdata)
);

reg         save_cmd_write  = 0;
reg [31:0]  save_addr       = 0;
reg [31:0]  save_wdata      = 0;
reg [31:0]  save_wmask      = 0;

wire[31:0]  save_addr_aligned   = {save_addr[31:2], 2'b00};

localparam STATE_IDLE               = 0;
localparam STATE_WAIT_READY         = 1;
localparam STATE_END                = 2;

localparam STATE_READ_VALID_BEFORE_WRITE    = 3;
localparam STATE_WAIT_WRITE_READY   = 4;
localparam STATE_WAIT_READNEXT_READY_BEFORE_WRITE   = 5;
localparam STATE_WAIT_READNEXT_VALID_BEFORE_WRITE   = 6;
localparam STATE_WAIT_WRITE_READY_UNALIGNED1    = 7;
localparam STATE_WAIT_WRITE_READY_UNALIGNED2    = 8;

localparam STATE_WAIT_READ_VALID            = 9;
localparam STATE_WAIT_READNEXT_READY        = 11;
localparam STATE_WAIT_READNEXT_VALID        = 12;

localparam REGPC_NOP = 32'hffffffff;

reg [3:0]   state       = STATE_IDLE;
reg [31:0]  save_rdata1 = 0;
reg [31:0]  save_rdata2 = 0;

/*
always @(posedge clk) begin
    $display("MEMAC---------");
    $display("state         : %d", state);
    $display("input_start   : %d", input_cmd_start);
    $display("input_write   : %d", input_cmd_write);
    $display("input_addr    : 0x%H", input_addr);
    $display("ready         : %d", output_cmd_ready);
    $display("rdata         : 0x%h", output_rdata);
    $display("valid         : %d", output_rdata_valid);
    $display("save.addr     : 0x%h", save_addr);
    $display("save.wmask    : 0x%h", save_wmask);
    $display("save.wdata    : 0x%h", save_wdata);
    $display("save.read1    : 0x%h", save_rdata1);
    $display("save.read2    : 0x%h", save_rdata2);
    $display("mem_cmd_start : %d", mem_cmd_start);
    $display("mem_cmd_write : %d", mem_cmd_write);
    $display("mem_cmd_ready : %d", mem_cmd_ready);
    $display("mem_addr      : 0x%h", mem_addr);
    $display("mem_rdata     : 0x%h", mem_rdata);
    $display("mem_rdata_v   : %d", mem_rdata_valid);
    $display("mem_wdata     : 0x%h", mem_wdata);
end
*/

function func_mem_cmd_start(
    input [3:0] state,
    input mem_cmd_ready,
    input mem_rdata_valid
);
case(state)
    //STATE_IDLE                              : func_mem_cmd_start = 0;
    STATE_WAIT_READY                        : func_mem_cmd_start = mem_cmd_ready;
    //STATE_END                               : func_mem_cmd_start = 0;
    //STATE_READ_VALID_BEFORE_WRITE           : func_mem_cmd_start = 0;
    STATE_WAIT_WRITE_READY                  : func_mem_cmd_start = mem_cmd_ready;
    STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_cmd_start = mem_cmd_ready;
    //STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_cmd_start = 0;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : func_mem_cmd_start = mem_rdata_valid;
    STATE_WAIT_WRITE_READY_UNALIGNED2       : func_mem_cmd_start = mem_rdata_valid;
    //STATE_WAIT_READ_VALID                   : func_mem_cmd_start = 0;
    STATE_WAIT_READNEXT_READY               : func_mem_cmd_start = mem_cmd_ready;
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
    STATE_WAIT_READY                        : func_mem_cmd_write = mem_cmd_ready && 
                                                                   save_cmd_write && 
                                                                   save_addr % 4 == 0 && 
                                                                   save_wmask == 32'hffffffff;
    //STATE_END                               : func_mem_cmd_write = 0;
    //STATE_READ_VALID_BEFORE_WRITE           : func_mem_cmd_write = 0;
    STATE_WAIT_WRITE_READY                  : func_mem_cmd_write = mem_cmd_ready;
    //STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_cmd_write = 0;
    //STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_cmd_write = 0;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : func_mem_cmd_write = mem_rdata_valid;
    STATE_WAIT_WRITE_READY_UNALIGNED2       : func_mem_cmd_write = mem_rdata_valid;
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
    //STATE_READ_VALID_BEFORE_WRITE           : func_mem_addr = REGPC_NOP;
    STATE_WAIT_WRITE_READY                  : func_mem_addr = save_addr_aligned;
    STATE_WAIT_READNEXT_READY_BEFORE_WRITE  : func_mem_addr = save_addr_aligned + 4;
    //STATE_WAIT_READNEXT_VALID_BEFORE_WRITE  : func_mem_addr = REGPC_NOP;
    STATE_WAIT_WRITE_READY_UNALIGNED1       : func_mem_addr = save_addr_aligned;
    STATE_WAIT_WRITE_READY_UNALIGNED2       : func_mem_addr = save_addr_aligned + 4;
    //STATE_WAIT_READ_VALID                   : func_mem_addr = REGPC_NOP;
    STATE_WAIT_READNEXT_READY               : func_mem_addr = save_addr_aligned + 4;
    //STATE_WAIT_READNEXT_VALID               : func_mem_addr = REGPC_NOP;
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
                save_cmd_write      <= input_cmd_write;
                save_addr           <= input_addr;
                save_wdata          <= input_wdata;
                save_wmask          <= input_wmask;

                state               <= STATE_WAIT_READY;
                //output_cmd_ready    <= 0;
                //output_rdata_valid  <= 0;
            end
        end
        STATE_WAIT_READY: begin
            if (mem_cmd_ready) begin
                if (save_cmd_write) begin
                    if (save_addr % 4 == 0) begin
                        if (save_wmask == 32'hffffffff) begin
                            // 投げっぱなし
                            //mem_cmd_write   <= 1;
                            //mem_addr        <= save_addr_aligned;
                            state           <= STATE_END;
                        end else begin
                            //mem_cmd_write   <= 0;
                            //mem_addr        <= save_addr_aligned;
                            state           <= STATE_READ_VALID_BEFORE_WRITE;
                        end
                    end else begin
                        //mem_cmd_write   <= 0;
                        //mem_addr        <= save_addr_aligned;
                        state           <= STATE_READ_VALID_BEFORE_WRITE;
                    end
                end else begin
                    //mem_cmd_write   <= 0;
                    //mem_addr        <= save_addr_aligned;
                    state           <= STATE_WAIT_READ_VALID;
                end
            end
        end
        STATE_END: begin
            state               <= STATE_IDLE;
            //output_cmd_ready    <= 1;
            //output_rdata_valid  <= 0;
        end
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
            if (mem_cmd_ready) begin
                //mem_cmd_write   <= 1;
                //mem_addr        <= save_addr_aligned;
                //mem_wdata       <= (save_rdata1 & ~save_wmask) | (save_wdata & save_wmask);
                state           <= STATE_END;
            end
        end
        STATE_WAIT_READNEXT_READY_BEFORE_WRITE: begin
            if (mem_cmd_ready) begin
                //mem_cmd_write   <= 0;
                //mem_addr        <= save_addr_aligned + 4;
                state           <= STATE_WAIT_READNEXT_VALID_BEFORE_WRITE;
            end
        end
        STATE_WAIT_READNEXT_VALID_BEFORE_WRITE: begin
            if (mem_rdata_valid) begin
                save_rdata2 <= mem_rdata;
                state       <= STATE_WAIT_WRITE_READY_UNALIGNED1;
            end
        end
        STATE_WAIT_WRITE_READY_UNALIGNED1: begin
            if (mem_rdata_valid) begin
                //mem_cmd_write   <= 1;
                //mem_addr        <= save_addr_aligned;
                /*
                case (save_addr % 4)
                    1: mem_wdata <= {(save_rdata1[31:8]  & ~save_wmask[23:0]) | (save_wdata[23:0] & save_wmask[23:0]) , save_rdata1[7:0]};
                    2: mem_wdata <= {(save_rdata1[31:16] & ~save_wmask[15:0]) | (save_wdata[15:0] & save_wmask[15:0]) , save_rdata1[15:0]};
                    3: mem_wdata <= {(save_rdata1[31:24] & ~save_wmask[7:0])  | (save_wdata[7:0]  & save_wmask[7:0])  , save_rdata1[23:0]};
                endcase
                */
                state           <= STATE_WAIT_WRITE_READY_UNALIGNED2;
            end
        end
        STATE_WAIT_WRITE_READY_UNALIGNED2: begin
            if (mem_rdata_valid) begin
                state           <= STATE_END;
                //mem_cmd_write   <= 1;
                //mem_addr        <= save_addr_aligned + 4;
                /*
                case (save_addr % 4)
                    1: mem_wdata <= {save_rdata2[31:8] , (save_rdata2[7:0]  & ~save_wmask[31:24]) | (save_wdata[31:24] & save_wmask[31:24])};
                    2: mem_wdata <= {save_rdata2[31:16], (save_rdata2[15:0] & ~save_wmask[31:16]) | (save_wdata[31:16] & save_wmask[31:16])};
                    3: mem_wdata <= {save_rdata2[31:24], (save_rdata2[23:0] & ~save_wmask[31:8])  | (save_wdata[31:8]  & save_wmask[31:8]) };
                endcase
                */
            end
        end
        STATE_WAIT_READ_VALID: begin
            if (mem_rdata_valid) begin
                if (save_addr % 4 == 0) begin
                    state               <= STATE_END;
                    //output_rdata_valid  <= 1;
                    //output_rdata        <= mem_rdata;
                end else begin
                    save_rdata1 <= mem_rdata;
                    state       <= STATE_WAIT_READNEXT_READY;
                end
            end
        end
        STATE_WAIT_READNEXT_READY: begin
            if (mem_cmd_ready) begin
                //mem_cmd_write   <= 0;
                state           <= STATE_WAIT_READNEXT_VALID;
            end
        end
        STATE_WAIT_READNEXT_VALID: begin
            if (mem_rdata_valid) begin
                state                   <= STATE_END;
                //output_rdata_valid      <= 1;
                /*
                case (save_addr % 4)
                    1: output_rdata <= {save_rdata1[7:0] , mem_rdata[31:8] };
                    2: output_rdata <= {save_rdata1[15:0], mem_rdata[31:16]};
                    3: output_rdata <= {save_rdata1[23:0], mem_rdata[31:24]};
                endcase
                */
            end
        end
    endcase
end

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