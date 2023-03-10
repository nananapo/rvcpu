module MemoryAccessController #(
    parameter MEMORY_SIZE = 4096,
    parameter MEMORY_FILE = ""
) (
    input  wire         clk,

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

    .cmd_start(mem_cmd_start),
    .cmd_write(mem_cmd_write),
    .cmd_ready(mem_cmd_ready),
    .addr(mem_addr),
    .rdata(mem_rdata),
    .rdata_valid(mem_rdata_valid),
    .wdata(mem_wdata)
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

reg [3:0]   state       = STATE_IDLE;
reg [31:0]  save_rdata1 = 0;
reg [31:0]  save_rdata2 = 0;


always @(posedge clk) begin
    $display("MEMAC---------");
    $display("state         : %d", state);
    $display("input_start   : 0x%H", input_cmd_start);
    $display("input_addr    : 0x%H", input_addr);
    $display("ready         : %d", output_cmd_ready);
    $display("rdata         : 0x%h", output_rdata);
    $display("valid         : %d", output_rdata_valid);
    $display("mem_cmd_start : %d", mem_cmd_start);
    $display("mem_cmd_write : %d", mem_cmd_write);
    $display("mem_cmd_ready : %d", mem_cmd_ready);
    $display("mem_addr      : 0x%h", mem_addr);
    $display("mem_rdata     : 0x%h", mem_rdata);
    $display("mem_rdata_v   : %d", mem_rdata_valid);
end


assign mem_cmd_start = (
    state == STATE_IDLE ? 0 :
    state == STATE_WAIT_READY ? mem_cmd_ready :
    state == STATE_END ? 0 :
    state == STATE_READ_VALID_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_WRITE_READY ? mem_cmd_ready :
    state == STATE_WAIT_READNEXT_READY_BEFORE_WRITE ? mem_cmd_ready :
    state == STATE_WAIT_READNEXT_VALID_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_WRITE_READY_UNALIGNED1 ? mem_rdata_valid :
    state == STATE_WAIT_WRITE_READY_UNALIGNED2 ? mem_rdata_valid :
    state == STATE_WAIT_READ_VALID ? 0 :
    state == STATE_WAIT_READNEXT_READY ? mem_cmd_ready :
    state == STATE_WAIT_READNEXT_VALID ? 0 :
    0
);

assign mem_cmd_write = (
    state == STATE_IDLE ? 0 :
    state == STATE_WAIT_READY ? (
        !mem_cmd_ready ? 0 : (
            save_cmd_write && save_addr % 4 == 0 && save_wmask == 32'hffffffff
        )
    ) :
    state == STATE_END ? 0 :
    state == STATE_READ_VALID_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_WRITE_READY ? mem_cmd_ready :
    state == STATE_WAIT_READNEXT_READY_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_READNEXT_VALID_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_WRITE_READY_UNALIGNED1 ? mem_rdata_valid :
    state == STATE_WAIT_WRITE_READY_UNALIGNED2 ? mem_rdata_valid :
    state == STATE_WAIT_READ_VALID ? 0 :
    state == STATE_WAIT_READNEXT_READY ? 0 :
    state == STATE_WAIT_READNEXT_VALID ? 0 :
    0
);

localparam REGPC_NOP = 32'hffffffff;

assign mem_addr = (
    state == STATE_IDLE ? REGPC_NOP :
    state == STATE_WAIT_READY ? save_addr_aligned :
    state == STATE_END ? REGPC_NOP :
    state == STATE_READ_VALID_BEFORE_WRITE ? REGPC_NOP :
    state == STATE_WAIT_WRITE_READY ? save_addr_aligned :
    state == STATE_WAIT_READNEXT_READY_BEFORE_WRITE ? save_addr_aligned + 4 :
    state == STATE_WAIT_READNEXT_VALID_BEFORE_WRITE ? REGPC_NOP :
    state == STATE_WAIT_WRITE_READY_UNALIGNED1 ? save_addr_aligned :
    state == STATE_WAIT_WRITE_READY_UNALIGNED2 ? save_addr_aligned + 4 :
    state == STATE_WAIT_READ_VALID ? REGPC_NOP :
    state == STATE_WAIT_READNEXT_READY ? save_addr_aligned + 4 :
    state == STATE_WAIT_READNEXT_VALID ? REGPC_NOP :
    REGPC_NOP
);

assign mem_wdata = (
    state == STATE_IDLE ? 0 :
    state == STATE_WAIT_READY ? save_wdata :
    state == STATE_END ? 0 :
    state == STATE_READ_VALID_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_WRITE_READY ? (save_rdata1 & ~save_wmask) | (save_wdata & save_wmask) :
    state == STATE_WAIT_READNEXT_READY_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_READNEXT_VALID_BEFORE_WRITE ? 0 :
    state == STATE_WAIT_WRITE_READY_UNALIGNED1 ? (
        save_addr % 4 == 1 ? {(save_rdata1[31:8]  & ~save_wmask[23:0]) | (save_wdata[23:0] & save_wmask[23:0]) , save_rdata1[7:0]} :
        save_addr % 4 == 2 ? {(save_rdata1[31:16] & ~save_wmask[15:0]) | (save_wdata[15:0] & save_wmask[15:0]) , save_rdata1[15:0]} :
        save_addr % 4 == 3 ? {(save_rdata1[31:24] & ~save_wmask[7:0])  | (save_wdata[7:0]  & save_wmask[7:0])  , save_rdata1[23:0]} :
        0
    ) :
    state == STATE_WAIT_WRITE_READY_UNALIGNED2 ? (
        save_addr % 4 == 1 ? {save_rdata2[31:8] , (save_rdata2[7:0]  & ~save_wmask[31:24]) | (save_wdata[31:24] & save_wmask[31:24])} :
        save_addr % 4 == 2 ? {save_rdata2[31:16], (save_rdata2[15:0] & ~save_wmask[31:16]) | (save_wdata[31:16] & save_wmask[31:16])} :
        save_addr % 4 == 3 ? {save_rdata2[31:24], (save_rdata2[23:0] & ~save_wmask[31:8])  | (save_wdata[31:8]  & save_wmask[31:8]) } :
        0
    ) :
    state == STATE_WAIT_READ_VALID ? 0 :
    state == STATE_WAIT_READNEXT_READY ? 0 :
    state == STATE_WAIT_READNEXT_VALID ? 0 :
    0
);

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