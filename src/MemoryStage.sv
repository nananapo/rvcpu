module MemoryStage(
    input wire          clk,

    input wire          mem_valid,
    input wire [31:0]   mem_reg_pc,
    input wire [31:0]   mem_inst,
    input wire [63:0]   mem_inst_id,
    input wire ctrltype mem_ctrl,
    input wire [31:0]   mem_alu_out,
    input wire [31:0]   mem_csr_rdata,

    output wire             mem_wb_valid,
    output wire [31:0]      mem_wb_reg_pc,
    output wire [31:0]      mem_wb_inst,
    output wire [63:0]      mem_wb_inst_id,
    output wire ctrltype    mem_wb_ctrl,
    output wire [31:0]      mem_wb_alu_out,
    output wire [31:0]      mem_wb_mem_rdata,
    output wire [31:0]      mem_wb_csr_rdata,

    input wire          pipeline_flush, // TODO killする
    output reg          memory_unit_stall,

    output wire         memu_cmd_start,
    output wire         memu_cmd_write,
    input  wire         memu_cmd_ready,
    input  wire         memu_valid,
    output wire [31:0]  memu_addr,
    output wire [31:0]  memu_wdata,
    output wire [31:0]  memu_wmask,
    input  wire [31:0]  memu_rdata
);

`include "include/core.sv"
`include "include/memoryinterface.sv"

// TODO enumにする
localparam STATE_WAIT               = 0;
localparam STATE_WAIT_READY         = 1;
localparam STATE_WAIT_READ_VALID    = 2;

reg [1:0]   state       = STATE_WAIT;

wire [31:0]     reg_pc      = mem_reg_pc;
wire [31:0]     inst        = mem_inst;
wire [63:0]     inst_id     = mem_inst_id;
wire ctrltype   ctrl        = mem_ctrl;
wire [31:0]     rs2_data    = mem_ctrl.rs2_data;
wire [31:0]     alu_out     = mem_alu_out;

reg         is_cmd_executed = 0;
reg [63:0]  saved_inst_id   = 0;
wire        may_start_m     = !is_cmd_executed || saved_inst_id != inst_id;

// amoswapはload -> writeするのでmem_wenを置き換える
reg [3:0]   replace_mem_wen = MEN_X;
wire [3:0]  mem_wen         = !mem_valid ? MEN_X : 
                              saved_inst_id != inst_id ? ctrl.mem_wen : replace_mem_wen;

wire is_store   = mem_wen == MEN_SB || mem_wen == MEN_SH || mem_wen == MEN_SW;
wire is_load    = mem_wen == MEN_LB || mem_wen == MEN_LBU || mem_wen == MEN_LH || mem_wen == MEN_LHU || mem_wen == MEN_LW || mem_wen == MEN_AMOSWAP_W_AQRL;

// ***************
// MEMORY WIRE
// ***************
assign memu_cmd_start    = state == STATE_WAIT_READY && mem_valid && may_start_m && mem_wen != MEN_X;
assign memu_cmd_write    = is_store;
assign memu_addr         = alu_out;
assign memu_wdata        = rs2_data;
assign memu_wmask        = mem_wen == MEN_SB ? 32'h000000ff :
                          mem_wen == MEN_SH ? 32'h0000ffff : 32'hffffffff;

assign memory_unit_stall = mem_valid || state != STATE_WAIT || (may_start_m && mem_wen != MEN_X);

reg [31:0]  saved_mem_rdata;

function [31:0] gen_memdata(
    input [3:0]     mem_wen,
    input           mem_valid,
    input [31:0]    mem_rdata
);
    case(mem_wen)
    MEN_LB : gen_memdata = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
    MEN_LBU: gen_memdata = {24'b0, mem_rdata[7:0]};
    MEN_LH : gen_memdata = {16'b0, mem_rdata[15:0]};
    MEN_LHU: gen_memdata = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
    default: gen_memdata = mem_rdata; // amoswapを含む
    endcase
endfunction

assign mem_wb_valid     = mem_valid && !pipeline_flush;
assign mem_wb_reg_pc    = mem_reg_pc;
assign mem_wb_inst      = mem_inst;
assign mem_wb_inst_id   = mem_inst_id;
assign mem_wb_ctrl      = mem_ctrl;
assign mem_wb_alu_out   = mem_alu_out;
assign mem_wb_mem_rdata = gen_memdata(ctrl.mem_wen, mem_valid, saved_mem_rdata);
assign mem_wb_csr_rdata = mem_csr_rdata;

always @(posedge clk)
    saved_inst_id <= inst_id;

always @(posedge clk) begin
    if (pipeline_flush || !mem_valid || mem_wen == MEN_X) begin
        state           <= STATE_WAIT;
        is_cmd_executed <= 0;
        replace_mem_wen <= MEN_X;
    end else case (state)
        STATE_WAIT: begin
            replace_mem_wen <= mem_wen;
            if (mem_wen != MEN_X)
                state <= STATE_WAIT_READY; // ready待ちへ
        end
        STATE_WAIT_READY: begin
            if (memu_cmd_ready) begin
                if (is_store) begin
                    state           <= STATE_WAIT;
                    replace_mem_wen <= MEN_X;
                    is_cmd_executed <= 1;
                end else begin
                    state           <= STATE_WAIT_READ_VALID;
                end
            end
        end
        STATE_WAIT_READ_VALID: begin
            if (memu_valid) begin
                saved_mem_rdata <= memu_rdata;
                if (mem_wen == MEN_AMOSWAP_W_AQRL) begin
                    state           <= STATE_WAIT_READY;
                    is_cmd_executed <= 0;
                    replace_mem_wen <= MEN_SW;
                end else begin
                    state           <= STATE_WAIT;
                    is_cmd_executed <= 1;
                    replace_mem_wen <= MEN_X;
                end
            end
        end
    endcase
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,memstage.state,%b", state);
    $display("data,memstage.reg_pc,%b", reg_pc);
    $display("data,memstage.inst_id,%b", inst_id);
    $display("data,memstage.rs2_data,%b", rs2_data);
    $display("data,memstage.alu_out,%b", alu_out);
    $display("data,memstage.mem_wen,%b", mem_wen);
    
    // $display("data,memstage.output.reg_pc,%b", mem_wb_reg_pc);
    $display("data,memstage.output.read_data,%b", mem_wb_mem_rdata);

    $display("data,memstage.is_load,%b", is_load);
    $display("data,memstage.is_store,%b", is_store);
    $display("data,memstage.memory_unit_stall,%b", memory_unit_stall);

    // $display("data,memstage.memu.cmd.s,%b", memu_cmd_start);
    // $display("data,memstage.memu.cmd.w,%b", memu_cmd_write);
    // $display("data,memstage.memu.cmd_ready,%b", memu_cmd_ready);
    // $display("data,memstage.memu.addr,%b", memu_addr);
    // $display("data,memstage.memu.wdata,%b", memu_wdata);
    // $display("data,memstage.memu.wmask,%b", memu_wmask);
    // $display("data,memstage.memu.rdata,%b", memu_rdata);
    // $display("data,memstage.memu.valid,%b", memu_valid);
end
`endif

endmodule