module DataSelectStage
(
    input wire clk,
    input wire [31:0]   regfile[31:0],

    input wire          ds_valid,
    input wire [31:0]   ds_pc,
    input wire [31:0]   ds_inst,
    input wire iidtype  ds_inst_id,
    input wire ctrltype ds_ctrl,
    input wire [31:0]   ds_imm_i,
    input wire [31:0]   ds_imm_s,
    input wire [31:0]   ds_imm_b,
    input wire [31:0]   ds_imm_j,
    input wire [31:0]   ds_imm_u,
    input wire [31:0]   ds_imm_z,
    
    output wire             ds_exe_valid,
    output wire [31:0]      ds_exe_pc,
    output wire [31:0]      ds_exe_inst,
    output wire iidtype     ds_exe_inst_id,
    output wire ctrltype    ds_exe_ctrl,
    output wire [31:0]      ds_exe_imm_i,
    output wire [31:0]      ds_exe_imm_b,
    output wire [31:0]      ds_exe_imm_j,
    output wire [31:0]      ds_exe_op1_data,
    output wire [31:0]      ds_exe_op2_data,
    output wire [31:0]      ds_exe_rs2_data,

    output wire             dh_stall_flg,
    input wire fw_ctrltype  dh_exe_fw,
    input wire fw_ctrltype  dh_mem_fw,
    input wire fw_ctrltype  dh_wb_fw
);

`include "include/core.sv"

wire [31:0] pc      = ds_pc;
wire [31:0] inst    = ds_inst;
wire iidtype inst_id= ds_inst_id;

wire [4:0] rs1_addr = inst[19:15];
wire [4:0] rs2_addr = inst[24:20];

// データハザード判定
wire dh_exe_rs1 = dh_exe_fw.valid && dh_exe_fw.addr == rs1_addr && rs1_addr != 0;
wire dh_exe_rs2 = dh_exe_fw.valid && dh_exe_fw.addr == rs2_addr && rs2_addr != 0;
wire dh_mem_rs1 = dh_mem_fw.valid && dh_mem_fw.addr == rs1_addr && rs1_addr != 0;
wire dh_mem_rs2 = dh_mem_fw.valid && dh_mem_fw.addr == rs2_addr && rs2_addr != 0;
wire dh_wb_rs1  = dh_wb_fw.valid  && dh_wb_fw.addr  == rs1_addr && rs1_addr != 0;
wire dh_wb_rs2  = dh_wb_fw.valid  && dh_wb_fw.addr  == rs2_addr && rs2_addr != 0;

assign dh_stall_flg = ds_valid && (
    // dh_*_rs*ですでにチェックしているため冗長だが、わかりやすさのために残してもいいと考えている
    (/*dh_exe_fw.valid && */!dh_exe_fw.can_forward && (dh_exe_rs1 || dh_exe_rs2)) ||
    (/*dh_mem_fw.valid && */!dh_mem_fw.can_forward && (dh_mem_rs1 || dh_mem_rs2)) ||
    (/*dh_wb_fw.valid  && */!dh_wb_fw.can_forward  && (dh_wb_rs1  || dh_wb_rs2 ))
    );

function [31:0] gen_op1data(
    input [3:0]     op1_sel,
    input [31:0]    pc,
    input [31:0]    imm_z
);
case(op1_sel) 
    OP1_PC  : gen_op1data = pc;
    OP1_IMZ : gen_op1data = imm_z;
    default : gen_op1data = 0;
endcase
endfunction

function [31:0] gen_op2data(
    input [3:0]     op2_sel,
    input [4:0]     rs2_addr,
    input [31:0]    imm_i,
    input [31:0]    imm_s,
    input [31:0]    imm_j,
    input [31:0]    imm_u
);
case(op2_sel) 
    OP2_IMI : gen_op2data = imm_i;
    OP2_IMS : gen_op2data = imm_s;
    OP2_IMJ : gen_op2data = imm_j;
    OP2_IMU : gen_op2data = imm_u;
    default : gen_op2data = 0;
endcase
endfunction

wire [31:0] rs2_data = rs2_addr == 0 ? 0 : 
                // exeは常にフォワーディングできないので考えないでおく
                //dh_exe_rs2 ? dh_exe_fw.wdata :
                dh_mem_rs2 ? dh_mem_fw.wdata : 
                dh_wb_rs2  ? dh_wb_fw.wdata : regfile[rs2_addr];
wire [31:0] rs1_data = rs1_addr == 0 ? 0 :
                // exeは常にフォワーディングできないので考えないでおく
                //dh_exe_rs1 ? dh_exe_fw.wdata :
                dh_mem_rs1 ? dh_mem_fw.wdata : 
                dh_wb_rs1  ? dh_wb_fw.wdata : regfile[rs1_addr];

// ds -> exe
assign ds_exe_valid     = !dh_stall_flg && ds_valid;
assign ds_exe_pc        = pc;
assign ds_exe_inst      = inst;
assign ds_exe_inst_id   = inst_id;

// idからそのまま
assign ds_exe_ctrl.i_exe        = ds_ctrl.i_exe;
assign ds_exe_ctrl.br_exe       = ds_ctrl.br_exe;
assign ds_exe_ctrl.m_exe        = ds_ctrl.m_exe;
assign ds_exe_ctrl.op1_sel      = ds_ctrl.op1_sel;
assign ds_exe_ctrl.op2_sel      = ds_ctrl.op2_sel;
assign ds_exe_ctrl.mem_wen      = ds_ctrl.mem_wen;
assign ds_exe_ctrl.mem_size     = ds_ctrl.mem_size;
assign ds_exe_ctrl.rf_wen       = ds_ctrl.rf_wen;
assign ds_exe_ctrl.wb_sel       = ds_ctrl.wb_sel;
assign ds_exe_ctrl.wb_addr      = ds_ctrl.wb_addr;
assign ds_exe_ctrl.csr_cmd      = ds_ctrl.csr_cmd;
assign ds_exe_ctrl.jmp_pc_flg   = ds_ctrl.jmp_pc_flg;
assign ds_exe_ctrl.jmp_reg_flg  = ds_ctrl.jmp_reg_flg;
assign ds_exe_ctrl.svinval      = ds_ctrl.svinval;

assign ds_exe_imm_i = ds_imm_i;
assign ds_exe_imm_b = ds_imm_b;
assign ds_exe_imm_j = ds_imm_j;

// op1_data, op2_data, rs2_dataはここで設定する
assign ds_exe_op1_data  = ds_ctrl.op1_sel == OP1_RS1 ? rs1_data : 
                            gen_op1data(ds_ctrl.op1_sel, pc, ds_imm_z);
assign ds_exe_op2_data  = ds_ctrl.op2_sel == OP2_RS2W ? rs2_data :
                            gen_op2data(ds_ctrl.op2_sel, rs2_addr, ds_imm_i, ds_imm_s, ds_imm_j, ds_imm_u);
assign ds_exe_rs2_data  = rs2_data;


`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,datastage.valid,b,%b", ds_valid);
    $display("data,datastage.inst_id,h,%b", ds_valid ? inst_id : INST_ID_NOP);
    if (ds_valid) begin
        $display("data,datastage.pc,h,%b", pc);
        $display("data,datastage.inst,h,%b", inst);

        $display("data,datastage.decode.op1_sel,d,%b", ds_ctrl.op1_sel);
        $display("data,datastage.decode.op2_sel,d,%b", ds_ctrl.op2_sel);
        $display("data,datastage.decode.op1_data,h,%b", ds_exe_op1_data);
        $display("data,datastage.decode.op2_data,h,%b", ds_exe_op2_data);
        $display("data,datastage.decode.rs1_addr,d,%b", rs1_addr);
        $display("data,datastage.decode.rs2_addr,d,%b", rs2_addr);
        $display("data,datastage.decode.rs1_data,h,%b", rs1_data);
        $display("data,datastage.decode.rs2_data,h,%b", rs2_data);
        $display("data,datastage.datahazard,b,%b", dh_stall_flg);
    end
end
`endif

endmodule