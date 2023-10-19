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
    output logic [SIZE-1:0] quotient,   // 商
    output logic [SIZE-1:0] remainder   // 余り
);

typedef enum logic [2:0] { 
    IDLE, DONE, DONE_ERROR, FIND_ONE, DIVIDE
} statetype;

statetype state = IDLE;

logic [SIZE-1:0] count;
logic [SIZE + SIZE - 1:0] shifted_divisor;

logic [SIZE-1:0] save_divisor;

assign ready = state == IDLE;
assign valid = state == DONE | state == DONE_ERROR;
assign error = state == DONE_ERROR;

always @(posedge clk) begin
    case (state)
        IDLE: begin
            if (start) begin
                save_divisor    <= divisor;
                if (divisor == 0) begin
                    state       <= DONE_ERROR;
                    remainder   <= dividend;
                    quotient    <= -1;
                end else if (divisor > dividend) begin
                    state       <= DONE;
                    remainder   <= dividend;
                    quotient    <= 0;
                end else begin
                    state       <= DIVIDE;
                    remainder   <= dividend;
                    quotient    <= 0;
                    shifted_divisor[SIZE+SIZE-1]        <= 0;
                    shifted_divisor[SIZE+SIZE-2:SIZE-1] <= divisor;
                    shifted_divisor[SIZE-2:0]           <= 0;
                    count       <= 1 << (SIZE - 1);
                end
            end
        end
        DIVIDE: begin
            if (count == 1)
                state <= DONE;
            if ({{SIZE{1'b0}}, remainder} >= shifted_divisor) begin
                remainder   <= remainder - shifted_divisor[SIZE-1:0];
                quotient    <= quotient | count;
            end
            shifted_divisor <= shifted_divisor >> 1;
            count           <= count >> 1;
        end
        //DONE:          state <= IDLE;
        //DONE_ERROR:    state <= IDLE;
        default: state <= IDLE;
    endcase
end

endmodule