module MemoryStage(
    input wire          clk,

    input wire          mem_valid,
    input wire [31:0]   mem_pc,
    input wire [31:0]   mem_inst,
    input wire iidtype  mem_inst_id,
    input wire ctrltype mem_ctrl,
    input wire [31:0]   mem_alu_out,
    input wire [31:0]   mem_csr_rdata,

    output wire             mem_wb_valid,
    output wire [31:0]      mem_wb_pc,
    output wire [31:0]      mem_wb_inst,
    output wire iidtype     mem_wb_inst_id,
    output wire ctrltype    mem_wb_ctrl,
    output wire [31:0]      mem_wb_alu_out,
    output wire [31:0]      mem_wb_mem_rdata,
    output wire [31:0]      mem_wb_csr_rdata,

    input wire          pipeline_flush,
    output reg          memory_unit_stall,

    inout wire DRequest     dreq, // TODO kill
    inout wire DResponse    dresp
);

`include "include/core.sv"
`include "include/memoryinterface.sv"

// TODO enumにする
localparam STATE_WAIT               = 0;
localparam STATE_WAIT_READY         = 1;
localparam STATE_WAIT_READ_VALID    = 2;

reg [1:0]   state       = STATE_WAIT;

wire [31:0]     pc          = mem_pc;
wire [31:0]     inst        = mem_inst;
wire iidtype    inst_id     = mem_inst_id;
wire ctrltype   ctrl        = mem_ctrl;
wire [31:0]     rs2_data    = mem_ctrl.rs2_data;
wire [31:0]     alu_out     = mem_alu_out;

reg     is_cmd_executed = 0;
iidtype saved_inst_id   = INST_ID_RANDOM;
wire    may_start_m     = !is_cmd_executed || saved_inst_id != inst_id;

// amoswapはload -> writeするのでmem_wenを置き換える
men_type_type replace_mem_wen = MEN_X;
wire men_type_type mem_wen  = men_type_type'(!mem_valid ? MEN_X : 
                                saved_inst_id != inst_id ? ctrl.mem_wen : replace_mem_wen);
wire men_size_type mem_size = ctrl.mem_size;

wire is_store   = mem_wen == MEN_S;
wire is_load    = mem_wen == MEN_LS || mem_wen == MEN_LU; // || mem_wen == MEN_AMOSWAP_W_AQRL;

// TODO いずれwireではなくdreq, drespに置き換える
wire        memu_cmd_start  = state == STATE_WAIT_READY && mem_valid && may_start_m && mem_wen != MEN_X;
wire        memu_cmd_write  = is_store;
wire        memu_cmd_ready;
wire        memu_valid;
wire [31:0] memu_addr       = alu_out;
wire [31:0] memu_wdata      = rs2_data;
wire [31:0] memu_wmask      = mem_size == MENS_B ? 32'h000000ff :
                              mem_size == MENS_H ? 32'h0000ffff : 32'hffffffff;
wire [31:0] memu_rdata;

assign dreq.valid       = memu_cmd_start;
assign dreq.wen         = memu_cmd_write;
assign memu_cmd_ready   = dreq.ready;
assign memu_valid       = dresp.valid;
assign dreq.addr        = memu_addr;
assign dreq.wdata       = memu_wdata;    
assign dreq.wmask       = memu_wmask;
assign memu_rdata       = dresp.rdata;

assign memory_unit_stall = mem_valid && 
                            (state != STATE_WAIT || (may_start_m && mem_wen != MEN_X));

reg [31:0]  saved_mem_rdata;

function [31:0] mem_rdata_func(
    input men_type_type mem_type,
    input men_size_type mem_size,
    input               mem_valid,
    input [31:0]        mem_rdata
);
if (mem_type == MEN_LS) begin
    if (mem_size == MENS_B) // lb
        mem_rdata_func = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
    else if (mem_size == MENS_H) // lh
        mem_rdata_func = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
    else // lw
        mem_rdata_func = mem_rdata;
end else begin
    if (mem_size == MENS_B) // lbu
        mem_rdata_func = {24'b0, mem_rdata[7:0]};
    else // lhu
        mem_rdata_func = {16'b0, mem_rdata[15:0]};
end
endfunction

assign mem_wb_valid     = mem_valid && !pipeline_flush;
assign mem_wb_pc        = mem_pc;
assign mem_wb_inst      = mem_inst;
assign mem_wb_inst_id   = mem_inst_id;
assign mem_wb_ctrl      = mem_ctrl;
assign mem_wb_alu_out   = mem_alu_out;
assign mem_wb_mem_rdata = mem_rdata_func(ctrl.mem_wen, ctrl.mem_size, mem_valid, saved_mem_rdata);
assign mem_wb_csr_rdata = mem_csr_rdata;

always @(posedge clk) begin
    if (mem_valid)
        saved_inst_id <= inst_id;
end

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
                /* TODO
                if (mem_wen == MEN_AMOSWAP_W_AQRL) begin
                    state           <= STATE_WAIT_READY;
                    is_cmd_executed <= 0;
                    replace_mem_wen <= MEN_S;
                    replace_mem_size <= MEN_W; // Xと同じなのでやる必要がないのでは？
                end else 
                */
                begin
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
    $display("data,memstage.valid,b,%b", mem_valid);
    $display("data,memstage.state,d,%b", state);
    $display("data,memstage.inst_id,h,%b", mem_valid ? inst_id : INST_ID_NOP);
    if (mem_valid) begin
        $display("data,memstage.pc,h,%b", pc);
        $display("data,memstage.inst,h,%b", inst);
        $display("data,memstage.rs2_data,h,%b", rs2_data);
        $display("data,memstage.alu_out,h,%b", alu_out);
        $display("data,memstage.mem_wen,d,%b", mem_wen);
        $display("data,memstage.mem_size,d,%b", mem_size);
        
        $display("data,memstage.output.read_data,h,%b", mem_wb_mem_rdata);

        $display("data,memstage.is_load,b,%b", is_load);
        $display("data,memstage.is_store,b,%b", is_store);
        $display("data,memstage.memory_unit_stall,b,%b", memory_unit_stall);

        // $display("data,memstage.memu.cmd.s,b,%b", memu_cmd_start);
        // $display("data,memstage.memu.cmd.w,b,%b", memu_cmd_write);
        // $display("data,memstage.memu.cmd_ready,b,%b", memu_cmd_ready);
        // $display("data,memstage.memu.addr,h,%b", memu_addr);
        // $display("data,memstage.memu.wdata,h,%b", memu_wdata);
        // $display("data,memstage.memu.wmask,h,%b", memu_wmask);
        // $display("data,memstage.memu.rdata,h,%b", memu_rdata);
        // $display("data,memstage.memu.valid,b,%b", memu_valid);
    end
end
`endif

endmodule