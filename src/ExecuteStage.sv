`include "muldiv.svh"
`include "pkg_util.svh"

module ExecuteStage
(
    input wire          clk,
    input wire          flush,
    input wire          valid,
    input wire          is_new,
    input wire Addr     pc,
    input wire Inst     inst,
    input wire IId      inst_id,
    input wire Ctrl     ctrl,
    input wire UIntX    imm_b,
    input wire UIntX    imm_j,
    input wire UIntX    op1_data,
    input wire UIntX    op2_data,
    input wire UIntX    rs2_data,

    output wire UIntX   next_alu_out,

    output wire         branch_taken,
    output wire Addr    branch_target,
    output wire         is_stall
);

`include "basicparams.svh"

typedef enum logic [1:0] {
    IDLE,
    WAIT_READY,
    WAIT_CALC
} statetype;

statetype state = IDLE;

wire AluSel i_exe   = ctrl.i_exe;
wire BrSel  br_exe  = ctrl.br_exe;

wire UIntX alu_out;
wire alu_branch_take;

UIntX saved_result;

ALU #(
    .ENABLE_ALU(1'b1),
    .ENABLE_BRANCH(1'b1)
) alu (
    .i_exe(i_exe),
    .br_exe(br_exe),
    .sign_sel(ctrl.sign_sel),
    .op1_data(op1_data),
    .op2_data(op2_data),
    .alu_out(alu_out),
    .branch_take(alu_branch_take)
);

wire MulDivReq mdreq;
wire MulDivResp mdresp;
MulDivModule #() muldiv (
    .clk(clk),
    .req(mdreq),
    .resp(mdresp)
);

wire is_muldiv          = i_exe == ALU_DIV | i_exe == ALU_REM |
                          i_exe == ALU_MUL | i_exe == ALU_MULH | i_exe == ALU_MULHSU;

assign mdreq.valid      = valid & ((is_new & state == IDLE & is_muldiv) | state == WAIT_READY);
assign mdreq.sel        = i_exe;
assign mdreq.is_signed  = ctrl.sign_sel == OP_SIGNED;
assign mdreq.op1        = op1_data;
assign mdreq.op2        = op2_data;

assign is_stall         = valid &
                            (
                                is_new & state == IDLE & is_muldiv |    // 計算前
                                state == WAIT_READY |                   // 待ち
                                state == WAIT_CALC & !mdresp.valid      // 計算中
                            );

assign next_alu_out     = state == WAIT_CALC ? mdresp.result :
                            is_muldiv ? saved_result : alu_out;
assign branch_taken     = valid & (ctrl.jmp_pc_flg | ctrl.jmp_reg_flg | alu_branch_take);
assign branch_target    =   (
                            ctrl.jmp_pc_flg ? pc + imm_j :
                            ctrl.jmp_reg_flg ? op1_data + op2_data :
                            pc + imm_b
                            ) & (~1);

always @(posedge clk) begin
    if (flush | !valid) begin
        // TODO kill muldiv
        state <= IDLE;
    end else begin
        case (state)
            IDLE: if (is_new & is_muldiv) begin
                state <= mdreq.ready ? WAIT_CALC : WAIT_READY;
            end
            WAIT_READY: if (mdreq.ready) state <= WAIT_CALC;
            WAIT_CALC: if (mdresp.valid) begin
                state           <= IDLE;
                saved_result    <= mdresp.result;
            end
            default: begin
                $display("ExecuteStage : Unknown state %d", state);
                $finish;
                $finish;
                $finish;
            end
        endcase
    end
end

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,exestage.valid,b,%b", valid);
    $display("data,exestage.inst_id,h,%b", valid ? inst_id : IID_X);
    if (valid) begin
        $display("data,exestage.pc,h,%b", pc);
        $display("data,exestage.inst,h,%b", inst);
        $display("data,exestage.i_exe,d,%b", i_exe);
        $display("data,exestage.br_exe,d,%b", br_exe);
        $display("data,exestage.op1_data,h,%b", op1_data);
        $display("data,exestage.op2_data,h,%b", op2_data);
        $display("data,exestage.is_stall,b,%b", is_stall);
        $display("data,exestage.is_muldiv,b,%b", is_muldiv);
        $display("data,exestage.jmp_flg,d,%b", ctrl.jmp_reg_flg | ctrl.jmp_pc_flg);
        $display("data,exestage.branch_taken,b,%b", branch_taken);
        $display("data,exestage.branch_target,h,%b", branch_target);
    end
end
`endif

endmodule