module DivUnsignedNbit #(
    parameter SIZE = 32
) (
    input wire  clk,

    input wire  start,
    output wire ready,
    output wire valid,
    output wire error,

    input wire [SIZE-1:0]   dividend,   // 被除数
    input wire [SIZE-1:0]   divisor,    // 除数
    output reg [SIZE-1:0]   quotient,   // 商
    output reg [SIZE-1:0]   remainder   // 余り
);

localparam STATE_IDLE       = 0;
localparam STATE_END        = 1;
localparam STATE_END_ERROR  = 2;
localparam STATE_FIND_ONE   = 3;
localparam STATE_DIVIDE     = 4;

reg [2:0] state = STATE_IDLE;

reg [SIZE-1:0] count;
reg [SIZE + SIZE - 1:0] shifted_divisor;

reg [SIZE-1:0] save_divisor;

assign ready = state == STATE_IDLE;
assign valid = state == STATE_END || state == STATE_END_ERROR;
assign error = state == STATE_END_ERROR;

always @(posedge clk) begin
    case (state)
        STATE_IDLE: begin
            if (start) begin
                save_divisor    <= divisor;
                if (divisor == 0) begin
                    state           <= STATE_END_ERROR;
                    remainder       <= dividend;
                    quotient        <= -1;
                end else if (divisor > dividend) begin
                    state           <= STATE_END;
                    remainder       <= dividend;
                    quotient        <= 0;
                end else begin
                    state           <= STATE_DIVIDE;
                    remainder       <= dividend;
                    quotient        <= 0;
                    shifted_divisor[SIZE+SIZE-1]        <= 0;
                    shifted_divisor[SIZE+SIZE-2:SIZE-1] <= divisor;
                    shifted_divisor[SIZE-2:0]           <= 0;
                    count           <= 1 << (SIZE - 1);
                end
            end
        end
        STATE_DIVIDE: begin
            if (count == 1)
                state <= STATE_END;
            if ({1'b0, remainder} >= shifted_divisor[SIZE:0]) begin
                remainder   <= remainder - shifted_divisor[SIZE-1:0];
                quotient    <= quotient | count;
            end
            shifted_divisor <= shifted_divisor >> 1;
            count           <= count >> 1;
        end
        //STATE_END:          state <= STATE_IDLE;
        //STATE_END_ERROR:    state <= STATE_IDLE;
        default: state <= STATE_IDLE;
    endcase
end

`ifdef PRINT_DEBUGINFO
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("data,divunbit.input.start,%b", start);
    $display("data,divunbit.output.ready,%b", ready);
    $display("data,divunbit.output.valid,%b", valid);
    $display("data,divunbit.output.error,%b", error);
    $display("data,divunbit.input.dividend,%b", dividend);
    $display("data,divunbit.input.divisor,%b", divisor);
    $display("data,divunbit.output.quotient,%b", quotient);
    $display("data,divunbit.output.remainder,%b", remainder);

    $display("data,divunbit.state,%b", state);
    $display("data,divunbit.save_divisor,%b", save_divisor);
    $display("data,divunbit.shifted_divisor,%b", shifted_divisor);
    $display("data,divunbit.count,%b", count);
end
`endif
`endif

endmodule