module MemoryMapController #(
    parameter FMAX_MHz = 27,
    parameter MEMORY_SIZE = 4096,
    parameter MEMORY_FILE = ""
) (
    input  wire         clk,

    input  wire         uart_rx,
    output wire         uart_tx,
    input  wire         mem_uart_rx,
    output wire         mem_uart_tx,

    input  wire [63:0]  mtime,
    output wire [63:0]  mtimecmp,

    input  wire         input_cmd_start,
    input  wire         input_cmd_write,
    output wire         output_cmd_ready,

    input  wire [31:0]  input_addr,
    output wire [31:0]  output_rdata,
    output wire         output_rdata_valid,
    input  wire [31:0]  input_wdata
);

`include "include/memorymap.sv"

wire is_uart_tx_addr    = UART_TX_OFFSET <= input_addr && input_addr <= UART_TX_END;
wire is_uart_rx_addr    = UART_RX_OFFSET <= input_addr && input_addr <= UART_RX_END;
wire is_mtimereg_addr   = MACHINETIMEREG_OFFSET <= input_addr && input_addr <= MACHINETIMEREG_END;
wire is_default_memory  = !is_uart_tx_addr && !is_uart_rx_addr && !is_mtimereg_addr;

// UART_TX
wire        uart_tx_cmd_start   = is_uart_tx_addr ? input_cmd_start : 0;
wire        uart_tx_cmd_write   = is_uart_tx_addr ? input_cmd_write : 0;
wire        uart_tx_cmd_ready;
wire [31:0] uart_tx_addr        = input_addr - UART_TX_OFFSET;
wire [31:0] uart_tx_rdata;
wire        uart_tx_rdata_valid;
wire [31:0] uart_tx_wdata       = input_wdata;

MemoryMappedIO_Uart_tx #(
    .FMAX_MHz(FMAX_MHz)
) memmap_uarttx (
    .clk(clk),
    .uart_tx(uart_tx),

    .input_cmd_start(uart_tx_cmd_start),
    .input_cmd_write(uart_tx_cmd_write),
    .output_cmd_ready(uart_tx_cmd_ready),
    .input_addr(uart_tx_addr),
    .output_rdata(uart_tx_rdata),
    .output_rdata_valid(uart_tx_rdata_valid),
    .input_wdata(uart_tx_wdata)
);

// UART_RX
wire        uart_rx_cmd_start   = is_uart_rx_addr ? input_cmd_start : 0;
wire        uart_rx_cmd_write   = is_uart_rx_addr ? input_cmd_write : 0;
wire        uart_rx_cmd_ready;
wire [31:0] uart_rx_addr        = input_addr - UART_RX_OFFSET;
wire [31:0] uart_rx_rdata;
wire        uart_rx_rdata_valid;
wire [31:0] uart_rx_wdata       = input_wdata;

MemoryMappedIO_Uart_rx #(
    .FMAX_MHz(FMAX_MHz)
) memmap_uartrx (
    .clk(clk),
    .uart_rx(uart_rx),

    .input_cmd_start(uart_rx_cmd_start),
    .input_cmd_write(uart_rx_cmd_write),
    .output_cmd_ready(uart_rx_cmd_ready),
    .input_addr(uart_rx_addr),
    .output_rdata(uart_rx_rdata),
    .output_rdata_valid(uart_rx_rdata_valid),
    .input_wdata(uart_rx_wdata)
);

// Machine Time Register
wire        mtimereg_cmd_start   = is_mtimereg_addr ? input_cmd_start : 0;
wire        mtimereg_cmd_write   = is_mtimereg_addr ? input_cmd_write : 0;
wire        mtimereg_cmd_ready;
wire [31:0] mtimereg_addr        = input_addr - MACHINETIMEREG_OFFSET;
wire [31:0] mtimereg_rdata;
wire        mtimereg_rdata_valid;
wire [31:0] mtimereg_wdata       = input_wdata;

MemoryMapped_MachineTimeRegister #(
    .FMAX_MHz(FMAX_MHz)
) memmap_mtimereg (
    .clk(clk),

    .input_cmd_start(mtimereg_cmd_start),
    .input_cmd_write(mtimereg_cmd_write),
    .output_cmd_ready(mtimereg_cmd_ready),
    .input_addr(mtimereg_addr),
    .output_rdata(mtimereg_rdata),
    .output_rdata_valid(mtimereg_rdata_valid),
    .input_wdata(mtimereg_wdata),

    .mtime(mtime),
    .mtimecmp(mtimecmp)
);


// メモリ
wire        mem_cmd_start   = is_default_memory ? input_cmd_start : 0;
wire        mem_cmd_write   = is_default_memory ? input_cmd_write : 0;
wire        mem_cmd_ready;
wire [31:0] mem_addr        = input_addr;
wire [31:0] mem_rdata;
wire        mem_rdata_valid;
wire [31:0] mem_wdata       = input_wdata;


`ifdef MEMORY_UART
    UARTMemory #(
        .FMAX_MHz(FMAX_MHz)
    ) memory (
        .clk(clk),
        .uart_rx(mem_uart_rx),
        .uart_tx(mem_uart_tx),
        .cmd_start(mem_cmd_start),
        .cmd_write(mem_cmd_write),
        .cmd_ready(mem_cmd_ready),
        .addr(mem_addr),
        .rdata(mem_rdata),
        .rdata_valid(mem_rdata_valid),
        .wdata(mem_wdata)
    );
`else
    Memory
    #(
        .MEMORY_SIZE(MEMORY_SIZE),
        .MEMORY_FILE(MEMORY_FILE)
    ) memory (
        .clk(clk),

        .input_cmd_start(mem_cmd_start),
        .input_cmd_write(mem_cmd_write),
        .output_cmd_ready(mem_cmd_ready),
        .input_addr(mem_addr),
        .output_rdata(mem_rdata),
        .output_rdata_valid(mem_rdata_valid),
        .input_wdata(mem_wdata)
    );
`endif

`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    // $display("data,memorymapcontroller.is_uart_tx_addr,b,%b", is_uart_tx_addr);
    // $display("data,memorymapcontroller.uart_tx_addr,h,%b", uart_tx_addr);
    // $display("data,memorymapcontroller.is_uart_rx_addr,b,%b", is_uart_rx_addr);
    // $display("data,memorymapcontroller.uart_rx_addr,h,%b", uart_rx_addr);
    // $display("data,memorymapcontroller.is_mtimereg_addr,b,%b", is_mtimereg_addr);
    // $display("data,memorymapcontroller.mtimereg_addr,h,%b", mtimereg_addr);
    $display("data,memorymapcontroller.start,b,%b", input_cmd_start);
    $display("data,memorymapcontroller.addr,h,%b", input_addr);
    $display("data,memorymapcontroller.write,b,%b", input_cmd_write);
    $display("data,memorymapcontroller.wdata,h,%b", input_wdata);
    $display("data,memorymapcontroller.rdata.output,h,%b", output_rdata);
    // $display("data,memorymapcontroller.rdata.uart_tx,h,%b", uart_tx_rdata);
    // $display("data,memorymapcontroller.rdata.uart_rx,h,%b", uart_rx_rdata);
end
`endif

assign output_cmd_ready     =   is_uart_tx_addr ? uart_tx_cmd_ready : 
                                is_uart_rx_addr ? uart_rx_cmd_ready : 
                                is_mtimereg_addr? mtimereg_cmd_ready :
                                mem_cmd_ready;
assign output_rdata         =   is_uart_tx_addr ? uart_tx_rdata : 
                                is_uart_rx_addr ? uart_rx_rdata : 
                                is_mtimereg_addr? mtimereg_rdata :
                                mem_rdata;
assign output_rdata_valid   =   is_uart_tx_addr ? uart_tx_rdata_valid : 
                                is_uart_rx_addr ? uart_rx_rdata_valid : 
                                is_mtimereg_addr? mtimereg_rdata_valid : 
                                mem_rdata_valid;

endmodule