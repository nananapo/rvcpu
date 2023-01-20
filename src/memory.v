module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384,
    parameter MEMORY_MAPPED_IO_ADDR = 10240,
    parameter MEMORY_MAPPED_IO_SIZE = 33
) (
    input wire clk,
    input wire [WORD_LEN-1:0] i_addr,
    output reg [WORD_LEN-1:0] inst,
    input wire [WORD_LEN-1:0] d_addr,
    output reg [WORD_LEN-1:0] rdata,
    input wire wen,
    input wire [WORD_LEN-1:0] wmask,
    input wire [WORD_LEN-1:0] wdata,
    output wire data_ready,

    output reg [WORD_LEN-1:0] memmap_io [(MEMORY_MAPPED_IO_SIZE >> 2) - 1:0]
);

reg [WORD_LEN-1:0] mem [(MEMORY_SIZE >> 2) - 1:0];

initial begin
    //$readmemh("MEMORY_FILE_NAME", mem);
    $readmemh("../test/c/test.bin.aligned", mem);
    memmap_io[0] = 32'h00000000;
end

wire [13:0] i_addr_shifted = (i_addr % MEMORY_SIZE) >> 2;
wire [13:0] d_addr_shifted = (d_addr % MEMORY_SIZE) >> 2;

wire [WORD_LEN-1:0] wmask_rev = {wmask[7:0], wmask[15:8], wmask[23:16], wmask[31:24]};

reg writeclock = 0;

wire is_fullmask = wmask == 32'hffffffff;

wire is_memory_map_range = (
    (MEMORY_MAPPED_IO_ADDR >> 2) <= d_addr_shifted && 
    d_addr_shifted <= ((MEMORY_MAPPED_IO_ADDR >> 2) + (MEMORY_MAPPED_IO_SIZE >> 2))
);

wire [13:0] memmap_addr = (d_addr_shifted - (MEMORY_MAPPED_IO_ADDR >> 2)) % (MEMORY_MAPPED_IO_SIZE >> 2);

assign data_ready = wen && (
    is_fullmask ? 1 : writeclock == 1
);

always @(posedge clk) begin
    inst  <= {mem[i_addr_shifted][7:0], mem[i_addr_shifted][15:8], mem[i_addr_shifted][23:16], mem[i_addr_shifted][31:24]};

    if (is_memory_map_range)
        rdata <= {  
            memmap_io[memmap_addr][7:0],
            memmap_io[memmap_addr][15:8], 
            memmap_io[memmap_addr][23:16],
            memmap_io[memmap_addr][31:24]
        };
    else
        rdata <= {  
            mem[d_addr_shifted][7:0],
            mem[d_addr_shifted][15:8], 
            mem[d_addr_shifted][23:16],
            mem[d_addr_shifted][31:24]
        };

    if (wen) begin
        if (writeclock == 1 || is_fullmask) begin
            if (is_memory_map_range) begin
                memmap_io[memmap_addr]  <= (
                    is_fullmask ? {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]} :
                    ({rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]} & ~wmask_rev) |
                    ({wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]} & wmask_rev)
                );
            end else begin
                mem[d_addr_shifted] <= (
                    is_fullmask ? {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]} :
                    ({rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]} & ~wmask_rev) |
                    ({wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]} & wmask_rev)
                );
            end
            writeclock <= 0;
        end else begin
            writeclock <= writeclock + 1;
        end
    end else begin
        writeclock <= 0;
    end

    $display("memory.wen    : %d", wen);
    $display("memory.wdata  : %H", wdata);
    $display("memory.wmask  : %H", wmask);
    $display("memory.rmasked: %H", {mem[d_addr_shifted]} & ~wmask_rev);
    $display("memory.wmasked: %H", {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]} & wmask_rev);
    $display("memory.d_addr : %H -> %H", d_addr, d_addr_shifted);
    $display("memory.rdatar : %H", rdata);
    $display("memory.rdata  : %H", {mem[d_addr_shifted][7:0], mem[d_addr_shifted][15:8], mem[d_addr_shifted][23:16], mem[d_addr_shifted][31:24]});
    $display("memory.ready  : %H", data_ready);
    $display("memory.ismapio: %d(addr:%H)", is_memory_map_range, memmap_addr);
end

endmodule
