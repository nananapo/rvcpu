`include "pkg_util.svh"

module DataSelectStage
(
    input wire          clk,
    input wire UIntX    regfile[31:0],
    input wire          valid,
    input wire          is_new,
    input wire Addr     pc,
    input wire Inst     inst,
    input wire IId      inst_id,
    input wire Ctrl     ctrl,
    input wire UIntX    imm_i,
    input wire UIntX    imm_s,
    input wire UIntX    imm_j,
    input wire UIntX    imm_u,
    input wire UIntX    imm_z,

    output wire UIntX   next_op1_data,
    output wire UIntX   next_op2_data,
    output wire UIntX   next_rs2_data,

    input wire FwCtrl   fw_exe,
    input wire FwCtrl   fw_mem,
    input wire FwCtrl   fw_csr,
    input wire FwCtrl   fw_wbk,
    output wire         is_datahazard
);

`include "basicparams.svh"

function [$bits(UIntX)-1:0] gen_op1data(
    input Op1Sel   op1_sel,
    input Addr     pc,
    input UIntX    imm_z
);
case(op1_sel)
    OP1_PC  : gen_op1data = pc;
    OP1_IMZ : gen_op1data = imm_z;
    default : gen_op1data = 0;
endcase
endfunction

function [$bits(UIntX)-1:0] gen_op2data(
    input Op2Sel    op2_sel,
    input UInt5     rs2_addr,
    input UIntX     imm_i,
    input UIntX     imm_s,
    input UIntX     imm_j,
    input UIntX     imm_u
);
case(op2_sel)
    OP2_IMI : gen_op2data = imm_i;
    OP2_IMS : gen_op2data = imm_s;
    OP2_IMJ : gen_op2data = imm_j;
    OP2_IMU : gen_op2data = imm_u;
    default : gen_op2data = 0;
endcase
endfunction

wire UInt5 rs1_addr = inst[19:15];
wire UInt5 rs2_addr = inst[24:20];

/*  datahazard */
wire is1_zero    = rs1_addr == 0;
wire is2_zero    = rs2_addr == 0;
wire hazard_exe1 = fw_exe.valid & fw_exe.addr == rs1_addr & !is1_zero;
wire hazard_exe2 = fw_exe.valid & fw_exe.addr == rs2_addr & !is2_zero;
wire hazard_mem1 = fw_mem.valid & fw_mem.addr == rs1_addr & !is1_zero;
wire hazard_mem2 = fw_mem.valid & fw_mem.addr == rs2_addr & !is2_zero;
wire hazard_csr1 = fw_csr.valid & fw_csr.addr == rs1_addr & !is1_zero;
wire hazard_csr2 = fw_csr.valid & fw_csr.addr == rs2_addr & !is2_zero;
wire hazard_wbk1 = fw_wbk.valid & fw_wbk.addr == rs1_addr & !is1_zero;
wire hazard_wbk2 = fw_wbk.valid & fw_wbk.addr == rs2_addr & !is2_zero;

assign is_datahazard = valid & ((  hazard_exe1 ? !fw_exe.fwdable :
                                    hazard_mem1 ? !fw_mem.fwdable :
                                    hazard_csr1 ? !fw_csr.fwdable :
                                    hazard_wbk1 ? !fw_wbk.fwdable : 0) |
                                (   hazard_exe2 ? !fw_exe.fwdable :
                                    hazard_mem2 ? !fw_mem.fwdable :
                                    hazard_csr2 ? !fw_csr.fwdable :
                                    hazard_wbk2 ? !fw_wbk.fwdable : 0));

// zero判定はWriteback Stage
wire UIntX rs1_data =   hazard_exe1 ? fw_exe.wdata :
                        hazard_mem1 ? fw_mem.wdata :
                        hazard_csr1 ? fw_csr.wdata :
                        hazard_wbk1 ? fw_wbk.wdata : regfile[rs1_addr];

wire UIntX rs2_data =   hazard_exe2 ? fw_exe.wdata :
                        hazard_mem2 ? fw_mem.wdata :
                        hazard_csr2 ? fw_csr.wdata :
                        hazard_wbk2 ? fw_wbk.wdata : regfile[rs2_addr];

// op1_data, op2_data, rs2_dataはここで設定する
assign next_op1_data    = ctrl.op1_sel == OP1_RS1 ? rs1_data :
                            gen_op1data(ctrl.op1_sel, pc, imm_z);
assign next_op2_data    = ctrl.op2_sel == OP2_RS2W ? rs2_data :
                            gen_op2data(ctrl.op2_sel, rs2_addr, imm_i, imm_s, imm_j, imm_u);
assign next_rs2_data    = rs2_data;

`ifdef PRINT_DEBUGINFO
always @(posedge clk) if (util::logEnabled()) begin
    $display("data,datastage.valid,b,%b", valid);
    $display("data,datastage.inst_id,h,%b", valid ? inst_id : IID_X);
    if (valid) begin
        $display("data,datastage.pc,h,%b", pc);
        $display("data,datastage.inst,h,%b", inst);
        $display("data,datastage.decode.op1_sel,d,%b", ctrl.op1_sel);
        $display("data,datastage.decode.op2_sel,d,%b", ctrl.op2_sel);
        $display("data,datastage.decode.op1_data,h,%b", next_op1_data);
        $display("data,datastage.decode.op2_data,h,%b", next_op2_data);
        $display("data,datastage.decode.rs1_addr,d,%b", rs1_addr);
        $display("data,datastage.decode.rs2_addr,d,%b", rs2_addr);
        $display("data,datastage.decode.rs1_data,h,%b", rs1_data);
        $display("data,datastage.decode.rs2_data,h,%b", rs2_data);
        $display("data,datastage.datahazard,b,%b", is_datahazard);
    end
end
`endif

endmodule