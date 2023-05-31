module MemoryInterface #(
    parameter FMAX_MHz = 27
)(
    input  wire         clk,
    input  wire         exit,

    input  wire         uart_rx,
    output wire         uart_tx,
    input  wire         mem_uart_rx,
    output wire         mem_uart_tx,

    input  wire [63:0]  mtime,
    output wire [63:0]  mtimecmp,
    
    inout wire IRequest      ireq,
    inout wire IResponse     iresp,
    inout wire DRequest      dreq,
    inout wire DResponse     dresp
);

typedef enum reg [1:0] {
    WAIT_CMD, WAIT_MEM_READY, WAIT_MEM_READ_VALID
} statetype;

statetype state = WAIT_CMD;

IRequest saved_ireq;
DRequest saved_dreq;

initial begin
    saved_dreq.valid = 0;
    saved_ireq.valid = 0;
end

MemoryMapController #(
    .FMAX_MHz(FMAX_MHz),
`ifdef RISCV_TEST
    // make riscv-tests
    .MEMORY_SIZE(2097152), // 8MiB
    .MEMORY_FILE("../test/riscv-tests/MEMORY_FILE_NAME")
`elsif DEBUG
    // make d
    .MEMORY_SIZE(2097152), // 8MiB
    //.MEMORY_FILE("../tinyos/kernel.bin.aligned")
    .MEMORY_FILE("../test/riscv-tests/rv32ui-p-add.bin.aligned")
`else
    // build
    .MEMORY_SIZE(1024 * 8), // 8MiB
    .MEMORY_FILE("../tinyos/kernel.bin.aligned")
`endif
) memmapcontroller (
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
);

wire        mem_cmd_start   = state == WAIT_MEM_READY && (ireq.valid || dreq.valid);
wire        mem_cmd_write   = !saved_ireq.valid && saved_dreq.valid && saved_dreq.wen;
wire        mem_cmd_ready;
wire [31:0] mem_addr        = saved_ireq.valid ? saved_ireq.addr : saved_dreq.addr;
wire [31:0] mem_rdata;
wire        mem_rdata_valid;
wire [31:0] mem_wdata       = dreq.wdata;
wire [31:0] mem_wmask       = dreq.wmask;

assign ireq.ready   = state == WAIT_CMD;
assign iresp.valid  = state == WAIT_MEM_READ_VALID && mem_rdata_valid && saved_ireq.valid;
assign iresp.addr   = saved_ireq.addr;
assign iresp.inst   = mem_rdata;

assign dreq.ready   = state == WAIT_CMD;
assign dresp.valid  = state == WAIT_MEM_READ_VALID && mem_rdata_valid && !saved_ireq.valid;
assign dresp.addr   = saved_dreq.addr;
assign dresp.inst   = mem_rdata;

always @(posedge clk) begin
    if (!exit) begin case (state) 
        WAIT_CMD: begin
            saved_ireq  <= ireq;
            saved_dreq  <= dreq;
            if (ireq.valid || dreq.valid)
                state <= WAIT_MEM_READY;
        end
        WAIT_MEM_READY: begin
            if (mem_cmd_ready) begin
                if (saved_ireq.valid)
                    state <= WAIT_MEM_READ_VALID;
                else if(saved_dreq.valid)
                    state <= saved_dreq.wen ? WAIT_CMD : WAIT_MEM_READ_VALID;
            end
        end
        WAIT_MEM_READ_VALID: begin
            if (mem_rdata_valid) begin
                if (saved_ireq.valid) begin
                    saved_ireq.valid    <= 0;
                    state               <= saved_dreq.valid ? WAIT_MEM_READY : WAIT_CMD;
                end else if (saved_dreq.valid)
                    state <= WAIT_CMD;
            end
        end
        default: begin end
    endcase end
end

endmodule