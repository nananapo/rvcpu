module MultUnsignedNbit #(
    parameter SIZE = 32
) (
    input wire  clk,

    input wire  start,
    output wire ready,
    output wire valid,

    input wire [SIZE-1:0]   multiplicand,   // 被乗数
    input wire [SIZE-1:0]   multiplier,     // 乗数
    output reg [SIZE*2-1:0] product         // 積
);

localparam STATE_IDLE   = 0;
localparam STATE_MULT   = 1;
localparam STATE_END    = 2;

reg [1:0] state = STATE_IDLE;

reg [9:0] count = 0;

reg [SIZE*2-1:0] save_multiplicand;
reg [SIZE-1:0] save_multiplier;

assign ready = state == STATE_IDLE;
assign valid = state == STATE_END;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (start) begin
                state               <= STATE_MULT;
                save_multiplicand   <= {{SIZE{1'b0}}, multiplicand};
                save_multiplier     <= multiplier;
                product             <= 0;
                count               <= 0;
            end
        end
        STATE_MULT: begin
            if (count == SIZE - 1)
                state <= STATE_END;
            if (save_multiplier[0] == 1)
                product <= product + save_multiplicand;
            save_multiplicand   <= save_multiplicand << 1;
            save_multiplier     <= save_multiplier >> 1; 
            count               <= count + 1;
        end
        default: state <= STATE_IDLE;
    endcase
end

`ifdef PRINT_DEBUGINFO
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("data,multunbit.input.start,%b", start);
    $display("data,multunbit.input.ready,%b", ready);
    $display("data,multunbit.input.valid,%b", valid);
    $display("data,multunbit.input.multiplicand,%b", multiplicand);
    $display("data,multunbit.input.multiplier,%b", multiplier);
    $display("data,multunbit.output.product,%b", product);
    
    $display("data,multunbit.state,%b", state);
    $display("data,multunbit.count,%b", count);
    $display("data,multunbit.save_multiplicand,%b", save_multiplicand);
    $display("data,multunbit.save_multiplier,%b", save_multiplier);
end
`endif
`endif

endmodule