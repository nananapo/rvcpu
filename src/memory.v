module Memory #(
    parameter WORD_LEN = 32,
    parameter MEMORY_SIZE = 16384
) (
    input wire clk,
    input wire [WORD_LEN-1:0] i_addr,
    output reg [WORD_LEN-1:0] inst,
    input wire [WORD_LEN-1:0] d_addr,
    output reg [WORD_LEN-1:0] rdata,
    input wire wen,
    input wire [WORD_LEN-1:0] wmask,
    input wire [WORD_LEN-1:0] wdata,
    output wire data_ready
);

reg [WORD_LEN-1:0] mem [(MEMORY_SIZE >> 2) - 1:0];

initial begin
    $readmemh("MEMORY_FILE_NAME", mem);
    //$readmemh("../test/bin/lw_b.hex", mem);
end

wire [13:0] i_addr_shifted = (i_addr % MEMORY_SIZE) >> 2;
wire [13:0] d_addr_shifted = (d_addr % MEMORY_SIZE) >> 2;

wire [WORD_LEN-1:0] wmask_rev = {wmask[7:0], wmask[15:8], wmask[23:16], wmask[31:24]};

reg writeclock = 0;
reg [WORD_LEN-1:0] rdatp;

assign data_ready = wen && (
    wmask == 32'hffffffff ? 1 : writeclock == 1
);

always @(posedge clk) begin
    inst  <= {mem[i_addr_shifted][7:0], mem[i_addr_shifted][15:8], mem[i_addr_shifted][23:16], mem[i_addr_shifted][31:24]};
    rdata <= {mem[d_addr_shifted][7:0], mem[d_addr_shifted][15:8], mem[d_addr_shifted][23:16], mem[d_addr_shifted][31:24]};

    if (wen) begin
        if (wmask == 32'hffffffff) begin
            mem[d_addr_shifted] = {wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]};
        end else begin
            if (writeclock == 0) begin
                rdatp <= {mem[d_addr_shifted][7:0], mem[d_addr_shifted][15:8], mem[d_addr_shifted][23:16], mem[d_addr_shifted][31:24]};
                writeclock <= writeclock + 1;
            end else if (writeclock == 1) begin
                mem[d_addr_shifted] <= (
                    ({rdatp[7:0], rdatp[15:8], rdatp[23:16], rdatp[31:24]} & ~wmask_rev) |
                    ({wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24]} & wmask_rev)
                );
                writeclock <= 0;
            end
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
end

endmodule