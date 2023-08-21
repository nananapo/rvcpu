module LocalHistory2bit #(
    parameter WIDTH_PC = 5,
    parameter WIDTH_HIST = 10
)(
    input wire          clk,
    input wire [31:0]   pc,         // 予測したいアドレス
    output wire [31:0]  next_pc,    // pcから予測された次のアドレス
    input wire IUpdatePredictionIO updateio
);

localparam WIDTH_COUNTER = WIDTH_PC + WIDTH_HIST;
localparam DEFAULT_COUNTER_VALUE = 2'b0;
localparam DEFAULT_HISTORY_VALUE = {WIDTH_HIST{1'b0}};

localparam SIZE_PC      = 2 ** WIDTH_PC;
localparam SIZE_HIST    = 2 ** WIDTH_HIST;
localparam SIZE_COUNTER = 2 ** (WIDTH_PC + WIDTH_HIST);

logic [WIDTH_HIST-1:0] history [SIZE_PC-1:0]; // pc -> hist
logic [1:0]  counters [SIZE_COUNTER-1:0];         // hist + pc -> counter
logic [31:0] targets [SIZE_PC-1:0];           // pc -> target

initial begin
    for (int i = 0; i < SIZE_COUNTER; i++)
        counters[i] = DEFAULT_COUNTER_VALUE;
    for (int i = 0; i < SIZE_PC; i++)
        history[i] = DEFAULT_HISTORY_VALUE;
end
wire [WIDTH_PC-1:0] histi   = pc[WIDTH_PC+2-1:2];
wire [WIDTH_PC-1:0] u_histi = updateio.pc[WIDTH_PC+2-1:2];

wire [WIDTH_COUNTER-1:0] phti   = {history[histi], histi};
wire [WIDTH_COUNTER-1:0] u_phti = {history[u_histi], u_histi};

wire [1:0] count    = counters[phti];
wire [1:0] u_count  = counters[u_phti];

wire [31:0] target_untaken = pc + 4;
wire [31:0] target_taken   = targets[histi];

assign next_pc = count[1] == 1'b1 ? target_taken : target_untaken;

always @(posedge clk) begin
    if (updateio.valid) begin
        if (updateio.taken) begin
            targets[u_histi] <= updateio.target;
        end
        if (!(u_count == 2'b11 && updateio.taken) && 
            !(u_count == 2'b00 && !updateio.taken)) begin
            if (updateio.taken)
                counters[u_phti] <= u_count + 2'b1;
            else
                counters[u_phti] <= u_count - 2'b1;
        end
        history[u_histi] <= {history[u_histi][WIDTH_HIST-2:0], updateio.taken};
        // $display("info,fetchstage.lhpt.update,updated %h %b %d %d %d", updateio.target,  u_phti,  updateio.taken, updateio.is_br, updateio.is_jmp);
    end
end


/*
`ifdef PRINT_DEBUGINFO
always @(posedge clk) begin
    $display("data,fetchstage.lpht.pc,h,%b", pc);

    $display("data,fetchstage.lpht.histi,h,%b", histi);
    $display("data,fetchstage.lpht.phti,b,%b", phti);
    $display("data,fetchstage.lpht.history,b,%b", history[histi]);
    $display("data,fetchstage.lpht.count,b,%b", count);

    $display("data,fetchstage.lpht.next_pc,h,%b", next_pc);
end
`endif 
*/

endmodule