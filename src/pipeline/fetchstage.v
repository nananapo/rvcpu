module Fetch #()
(
    input   wire        clk,
    output  wire [31:0] memory_i_addr,
    input   wire [31:0] memory_inst,

    output  reg  [31:0] reg_id_inst
);

reg [31:0] addr = 0;

assign memory_i_addr = add;

always @(posedge clk) begin
    reg_id_inst <= memory_inst;
    addr <= addr + 4;
end


endmodule