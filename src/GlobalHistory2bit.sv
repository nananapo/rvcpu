module GlobalHistory2bit #(
    parameter WIDTH_PC = 10,
    parameter WIDTH_HIST = 10
)(
    input wire          clk,
    input wire Addr     pc,         // 予測したいアドレス
    output wire         pred_taken,
    input wire BrInfo   brinfo
    `ifdef PRINT_DEBUGINFO
    ,
    input wire can_output_log
    `endif
);

localparam SIZE_PC      = 2 ** WIDTH_PC;
localparam SIZE_HIST    = 2 ** WIDTH_HIST;

localparam DEFAULT_COUNTER_VALUE = 2'b0;
localparam DEFAULT_HISTORY_VALUE = {WIDTH_HIST{1'b0}};

logic [1:0]  counters [SIZE_HIST-1:0]; // hist -> counter

initial begin
    for (int i = 0; i < SIZE_HIST; i++)
        counters[i] = DEFAULT_COUNTER_VALUE;
end

logic [WIDTH_HIST-1:0] hist = DEFAULT_HISTORY_VALUE;

wire [WIDTH_PC-1:0] pci     = pc[WIDTH_PC+2-1:2];
wire [WIDTH_PC-1:0] u_pci   = brinfo.pc[WIDTH_PC+2-1:2];

// TODO フェッチした時のhistが欲しいが、持ってこれない
wire [1:0] count    = counters[hist];
wire [1:0] u_count  = counters[hist]; // ここ

assign pred_taken = count[1] == 1'b1;

always @(posedge clk) begin
    if (brinfo.valid) begin
        hist <= {hist[WIDTH_HIST-2:0], brinfo.taken};
        if (!(u_count == 2'b11 & brinfo.taken) &
            !(u_count == 2'b00 & !brinfo.taken)) begin
            if (brinfo.taken)
                counters[hist] <= u_count + 2'b1;
            else
                counters[hist] <= u_count - 2'b1;
        end
    end
end

/*
`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (can_output_log) begin
    $display("data,fetchstage.glbh2.pc,h,%b", pc);
    $display("data,fetchstage.glbh2.pci,h,%b", pci);
    $display("data,fetchstage.glbh2.hist,b,%b", hist);
    $display("data,fetchstage.glbh2.count,b,%b", count);
    $display("data,fetchstage.glbh2.next_pc,h,%b", next_pc);
end
`endif
*/

endmodule