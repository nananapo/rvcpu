module MulDivModule (
    input wire  clk,
    input wire  req_valid,
    input wire  kill,
    output reg  req_ready,
    output reg  res_valid,

    input alum_exe_type     cmd,
    // a * b = c, a / b = c, a % b = c
    input wire [31:0]   a,
    input wire [31:0]   b,
    output reg [31:0]   c

    // TODO error flg
);

typedef enum reg [2:0] {
    S_WAIT, S_MUL, S_DIV, S_DONE_MUL, S_DONE_DIV
} statetype;

statetype state = S_WAIT;

reg [63:0] multiplicand;
reg [31:0] multiplier;

reg [31:0] remainder;
reg [63:0] divisor;

reg [63:0] result;

reg is_unsigned;
reg is_rem;
reg is_hi;
reg is_error;

reg [4:0] count; // 5bitなのは適当

always @(posedge clk) begin
if (kill) begin
    state       <= S_WAIT;
    req_ready   <= 0;
    res_valid   <= 0;
end else begin
    case (cmd)
        S_WAIT: begin
            if (req_valid && cmd != ALUM_X) begin
                state       <= (cmd == ALUM_MUL || cmd == ALUM_MULH || cmd == ALUM_MULHU || cmd == ALUM_MULHSU) ? S_MUL : S_DIV;
                res_valid   <= 0;
                req_ready   <= 0;

                multiplicand<= {32'b0, a};
                multiplier  <= b;
                remainder   <= a;
                divisor     <= {b, 32'b0};
                result      <= 64'b0;
                count       <= 0;

                is_unsigned <= cmd == ALUM_MULHSU || cmd == ALUM_MULHU || cmd == ALUM_DIVU || cmd == ALUM_REMU;
                is_rem      <= cmd == ALUM_REM || cmd == ALUM_REMU;
                is_hi       <= cmd == ALUM_MULH || cmd == ALUM_MULHU || cmd == ALUM_MULHSU;
                is_error    <= b == 32'b0;
            end
        end
        S_MUL: begin
            if (count == 31)
                state   <= S_DONE_MUL;
            if (multiplier[count] == 1'b1)
                result  <= result + multiplicand;
            count           <= count + 1'b1;
            multiplicand    <= multiplicand << 1;
        end
        S_DIV: begin
            if (count == 31)
                state   <= S_DONE_DIV;
            if ({32'b0, remainder} >= divisor) begin
                remainder   <= remainder - divisor[31:0];
                result      <= result + (1 << 31 - count);
            end
            divisor <= divisor >> 1;
            count   <= count + 1'b1;
        end
        S_DONE_DIV: begin
            state       <= S_WAIT;
            res_valid   <= 1;
            req_valid   <= 1;
            c           <= is_rem ? remainder : result[31:0];
        end
        S_DONE_MUL: begin
            state       <= S_WAIT;
            res_valid   <= 1;
            req_valid   <= 1;
            c           <= is_hi ? result[63:32] : result[31:0];
        end
        default: begin
            state <= S_WAIT;
            $display("Exception MulDivModule : Unknown state");
            $finish;
        end
    endcase
end end

endmodule