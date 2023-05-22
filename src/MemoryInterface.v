module MemoryInterface #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,

    input  wire         uart_rx,
    output wire         uart_tx,
    input  wire         mem_uart_rx,
    output wire         mem_uart_tx,

    input  wire [63:0]  mtime,
    output wire [63:0]  mtimecmp,
 
    input  wire         inst_start,
    output wire         inst_ready,
    input  wire [31:0]  i_addr,
    output wire [31:0]  inst,
    output wire         inst_valid,

    input  wire         d_cmd_write,
    input  wire         d_cmd_start,
    output reg          d_cmd_ready,
    input  wire [31:0]  d_addr,
    input  wire [31:0]  wdata,
    input  wire [31:0]  wmask,
    output wire [31:0]  rdata,
    output wire         rdata_valid,

    input  wire         exited  
);

`include "include/memoryinterface.v"

// メモリ
wire        mem_cmd_start;
wire        mem_cmd_write;
wire        mem_cmd_ready;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire        mem_rdata_valid;
wire [31:0] mem_wdata;
wire [31:0] mem_wmask;

`ifndef MEMORY_DISALLOW_UNALIGNED
MemoryUnalignedAccessController 
`else
MemoryMapController
`endif
#(
    .FMAX_MHz(FMAX_MHz),
    .MEMORY_SIZE(2097152), // 8MiB
`ifdef RISCV_TEST
    // make riscv-tests
    .MEMORY_FILE("../test/riscv-tests/MEMORY_FILE_NAME")
`elsif DEBUG
    // make d
    .MEMORY_FILE("../tinyos/kernel.bin.aligned")
`else
    // build
    .MEMORY_FILE("../tinyos/kernel.bin.aligned")
`endif
) memory (
    .clk(clk),

    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .mem_uart_rx(mem_uart_rx),
    .mem_uart_tx(mem_uart_tx),

    .mtime(mtime),
    .mtimecmp(mtimecmp),

    .input_cmd_start(mem_cmd_start),
    .input_cmd_write(mem_cmd_write),
    .output_cmd_ready(mem_cmd_ready),
    .input_addr(mem_addr),
    .output_rdata(mem_rdata),
    .output_rdata_valid(mem_rdata_valid),
    .input_wdata(mem_wdata)

    `ifndef MEMORY_DISALLOW_UNALIGNED
    ,
    .input_wmask(mem_wmask)
    `endif
);

localparam STATE_WAIT_CMD           = 2'd0;
localparam STATE_WAIT_MEMORY_READY  = 2'd1;
localparam STATE_WAIT_MEMORY_READ   = 2'd2;

reg [1:0] status = STATE_WAIT_CMD;


// 保存用
reg         cmd_is_inst = 0;
reg [31:0]  save_i_addr;
reg         save_d_cmd_start;
reg         save_d_cmd_write;
reg [31:0]  save_d_addr;
reg [31:0]  save_wdata;
reg [31:0]  save_wmask;

reg [31:0]  save_d_rdata = 32'hffffffff;
reg [31:0]  save_i_rdata = 32'hffffffff;

wire d_cmd_now_is_write = d_cmd_write && d_cmd_start;
wire d_cmd_save_is_write= save_d_cmd_write && save_d_cmd_start;

assign mem_cmd_start = (
    status == STATE_WAIT_CMD ? (
        mem_cmd_ready ? (
            inst_start || d_cmd_start
        ) : 0
    ) : 
    status == STATE_WAIT_MEMORY_READY ? (
        mem_cmd_ready ? 1 : 0
    ) :
    status == STATE_WAIT_MEMORY_READ ? (
        mem_rdata_valid ? (
            cmd_is_inst ? save_d_cmd_start : 0
        ) : 0
    ) : 0
);

assign mem_cmd_write = (
    status == STATE_WAIT_CMD ? (
        mem_cmd_ready ? (
            inst_start ? 0 : d_cmd_now_is_write
        ) : 0
    ) : 
    status == STATE_WAIT_MEMORY_READY ? (
        mem_cmd_ready ? (
            cmd_is_inst ? 0 : d_cmd_save_is_write
        ) : 0
    ) :
    status == STATE_WAIT_MEMORY_READ ? (
        mem_rdata_valid ? (
            cmd_is_inst ? d_cmd_save_is_write : 0
        ) : 0
    ) : 0 
);

localparam ADDR_NOP = 32'hffffffff;

assign mem_addr = (
    status == STATE_WAIT_CMD ? (
        mem_cmd_ready ? (
            inst_start ? i_addr : d_addr
        ) : ADDR_NOP
    ) : 
    status == STATE_WAIT_MEMORY_READY ? (
        mem_cmd_ready ? (
            cmd_is_inst ? save_i_addr : save_d_addr
        ) : ADDR_NOP
    ) : 
    status == STATE_WAIT_MEMORY_READ ? (
        mem_rdata_valid ? (
            cmd_is_inst ? (
                save_d_cmd_start ? 
                    save_d_addr :   // inst -> data
                    save_i_addr     // inst -> endなのでi_addrを維持
            ) : save_d_addr // data -> endなのでd_addrを維持
        ) : (
            cmd_is_inst ? save_i_addr : save_d_addr // valid待ちなのでaddrを維持
        )
    ) : ADDR_NOP
);

assign mem_wdata = (
    status == STATE_WAIT_CMD ? wdata : 
    status == STATE_WAIT_MEMORY_READY ? save_wdata : 
    status == STATE_WAIT_MEMORY_READ ? save_wdata :
    32'hffffffff
);

assign mem_wmask = (
    status == STATE_WAIT_CMD ? wmask : 
    status == STATE_WAIT_MEMORY_READY ? save_wmask : 
    status == STATE_WAIT_MEMORY_READ ? save_wmask :
    32'hffffffff
);


// d_cmdに関してはcmd_is_instかつsave_d_cmdがnopの時には進むことができるが、簡単にするためにいったん考えない
assign inst_ready   = status == STATE_WAIT_CMD;
assign d_cmd_ready  = status == STATE_WAIT_CMD;

assign inst_valid   = (
    status == STATE_WAIT_CMD ? 0 : 
    status == STATE_WAIT_MEMORY_READY ? 0 : 
    status == STATE_WAIT_MEMORY_READ ? (
        mem_rdata_valid && cmd_is_inst ? 1 : 0
    ) : 0
);
assign rdata_valid  = (
    status == STATE_WAIT_CMD ? !d_cmd_start : 
    status == STATE_WAIT_MEMORY_READY ? !save_d_cmd_start : 
    status == STATE_WAIT_MEMORY_READ ? (
        mem_rdata_valid && !cmd_is_inst ? 1 : 0
    ) : 0
);

assign inst         = (
    status == STATE_WAIT_CMD ? (
        inst_start ? 32'hffffffff : save_i_rdata
    ) :
    status == STATE_WAIT_MEMORY_READY ? (
        cmd_is_inst ? 32'hffffffff : save_i_rdata
    ) :
    status == STATE_WAIT_MEMORY_READ ? (
        cmd_is_inst ? (
            mem_rdata_valid ? mem_rdata : 32'hffffffff
        ) : save_i_rdata
    ) : 32'hffffffff
);

assign rdata        = (
    status == STATE_WAIT_CMD ? (
        d_cmd_start ? 32'hffffffff : save_d_rdata
    ) :
    status == STATE_WAIT_MEMORY_READY ? (
        save_d_cmd_start ? 32'hffffffff : save_d_rdata
    ) :
    status == STATE_WAIT_MEMORY_READ ? (
        save_d_cmd_start ? (
            (!cmd_is_inst && mem_rdata_valid) ? mem_rdata : 32'hffffffff
        ) : save_d_rdata
    ) : 32'hffffffff
);

always @(posedge clk) begin
    if (!exited) begin
    case (status) 
        STATE_WAIT_CMD: begin
            save_i_addr         <= i_addr;
            save_d_cmd_start    <= d_cmd_start;
            save_d_cmd_write    <= d_cmd_write;
            save_d_addr         <= d_addr;
            save_wdata          <= wdata;
            save_wmask          <= wmask;

            if (inst_start) begin
                cmd_is_inst <= 1;
                if (mem_cmd_ready)
                    status <= STATE_WAIT_MEMORY_READ;// wait cmd -> wait read
                else
                    status <= STATE_WAIT_MEMORY_READY;// wait cmd -> wait mem ready
            end else if (d_cmd_start) begin
                cmd_is_inst <= 0;
                if (mem_cmd_ready)
                    status <= d_cmd_write ? STATE_WAIT_CMD : STATE_WAIT_MEMORY_READ;// wait cmd -> (read? -> wait read) , (write? -> wait cmd)
                else
                    status <= STATE_WAIT_MEMORY_READY;// wait cmd -> wait ready
            end
        end
        STATE_WAIT_MEMORY_READY: begin
             if (mem_cmd_ready) begin
                if (cmd_is_inst)
                    status <= STATE_WAIT_MEMORY_READ;// cmd ready -> wait read
                else begin
                    if (save_d_cmd_write)
                        status <= STATE_WAIT_CMD; // cmd ready -> write -> wait cmd
                    else
                        status <= STATE_WAIT_MEMORY_READ;// cmd ready -> wait dmem read
                end
            end
        end
        STATE_WAIT_MEMORY_READ: begin
            if (mem_rdata_valid) begin
                if (cmd_is_inst) begin
                    save_i_rdata <= mem_rdata;
                    if (save_d_cmd_start) begin
                        cmd_is_inst <= 0;
                        if (mem_cmd_ready) begin
                            if (save_d_cmd_write)
                                status <= STATE_WAIT_CMD;// inst -> wait cmd
                            else
                                status <= STATE_WAIT_MEMORY_READ;// inst -> d_cmd
                        end else 
                            status <= STATE_WAIT_MEMORY_READY;// inst -> wait ready
                    end else
                        status <= STATE_WAIT_CMD;// inst -> wait cmd
                end else begin
                    save_d_rdata <= mem_rdata;
                    status <= STATE_WAIT_CMD;// d_cmd -> wait cmd
                end
            end
        end
        default: begin end
    endcase
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,memoryinterface.inst_start,%b", inst_start);
    $display("data,memoryinterface.inst_ready,%b", inst_ready);
    // $display("data,memoryinterface.i_addr,%b", i_addr);
    // $display("data,memoryinterface.inst,%b", inst);
    // $display("data,memoryinterface.inst_valid,%b", inst_valid);
    // $display("data,memoryinterface.d_cmd_start,%b", d_cmd_start);
    // $display("data,memoryinterface.d_cmd_write,%b", d_cmd_write);
    // $display("data,memoryinterface.d_cmd_ready,%b", d_cmd_ready);
    // $display("data,memoryinterface.d_addr,%b", d_addr);
    // $display("data,memoryinterface.wdata,%b", wdata);
    // $display("data,memoryinterface.wmask,%b", wmask);
    // $display("data,memoryinterface.rdata,%b", rdata);
    // $display("data,memoryinterface.rdata_valid,%b", rdata_valid);
    // $display("data,memoryinterface.cmd_is_inst,%b", cmd_is_inst);
    // $display("data,memoryinterface.mem_cmd_start,%b", mem_cmd_start);
    // $display("data,memoryinterface.mem_cmd_write,%b", mem_cmd_write);
    // $display("data,memoryinterface.mem_cmd_ready,%b", mem_cmd_ready);
    // $display("data,memoryinterface.mem_addr,%b", mem_addr);
    // $display("data,memoryinterface.mem_rdata,%b", mem_rdata);
    // $display("data,memoryinterface.mem_rdata_valid,%b", mem_rdata_valid);
    $display("data,memoryinterface.status,%b", status);
end
`endif

endmodule