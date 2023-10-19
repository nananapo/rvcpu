`include "basic.svh"
`include "muldiv.svh"

// TODO kill

module MulDivModule (
    input wire              clk,
    inout wire MulDivReq    req,
    output wire MulDivResp  resp
);

typedef enum logic [1:0] {
    IDLE,
    WAIT_READY,
    WAIT_CALC,
    RESULT
} statetype;
statetype   state = IDLE;

MulDivReq   s_req;
UIntX       result;
assign req.ready    = state == IDLE;
assign resp.valid   = state == RESULT;
assign resp.result  = result;

wire AluSel sel     = AluSel'(state == IDLE ? req.sel : s_req.sel);

wire is_div = sel == ALU_DIV || sel == ALU_REM;
wire is_mul = sel == ALU_MUL || sel == ALU_MULH || sel == ALU_MULHSU;

wire m_start = state == WAIT_READY & is_mul;
wire m_ready;
wire m_valid;
wire d_start = state == WAIT_READY & is_div;
wire d_ready;
wire d_valid;

wire [`XLEN*2+1:0]  m_product;
wire [`XLEN:0]      d_quotient;
wire [`XLEN:0]      d_remainder;

wire [`XLEN:0] op1ext = s_req.is_signed ?
                {s_req.op1[`XLEN-1], s_req.op1} : {1'b0, s_req.op1};
wire [`XLEN:0] op2ext = s_req.is_signed & (is_div || sel != ALU_MULHSU) ? 
                {s_req.op2[`XLEN-1], s_req.op2} : {1'b0, s_req.op2};

always @(posedge clk) case (state)
    IDLE: begin
        s_req   <= req;
        if (req.valid)
            state <= WAIT_READY;
    end
    WAIT_READY: begin
        if ((is_mul & m_ready) || (is_div & d_ready))
            state <= WAIT_CALC;
    end
    WAIT_CALC: begin
        if ((is_mul & m_valid) || (is_div & d_valid)) begin
            state       <= RESULT;
            case (s_req.sel) 
                ALU_DIV    : result <= d_quotient[`XLEN-1:0];
                ALU_REM    : result <= d_remainder[`XLEN-1:0];
                ALU_MUL    : result <= m_product[`XLEN-1:0];
                ALU_MULH   : result <= m_product[`XLEN*2-1:`XLEN];
                ALU_MULHSU : result <= m_product[`XLEN*2-1:`XLEN];
                default    : result <= 0;
            endcase
        end
    end
    RESULT: begin
        state       <= IDLE;
    end
    default: begin
        $display("MulDivModule : Unknown state %d", state);
        $finish;
    end
endcase

MultNbit #(
    .SIZE(`XLEN+1) // s * u用
) m (
    .clk(clk),
    .start(m_start),
    .ready(m_ready),
    .valid(m_valid),
    .is_signed(s_req.is_signed),
    .multiplicand(op1ext),
    .multiplier(op2ext),
    .product(m_product)
);

DivNbit #(
    .SIZE(`XLEN+1) // オーバーフロー対策
) d (
    .clk(clk),
    .start(d_start),
    .ready(d_ready),
    .valid(d_valid),
    .is_signed(s_req.is_signed),
    .dividend(op1ext),
    .divisor(op2ext),
    .quotient(d_quotient),
    .remainder(d_remainder)
);

endmodule