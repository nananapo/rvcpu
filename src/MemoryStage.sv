module MemoryStage(
    input wire          clk,

    input wire          mem_valid,
    input wire Addr     mem_pc,
    input wire Inst     mem_inst,
    input wire IId      mem_inst_id,
    input wire Ctrl     mem_ctrl,
    input wire UIntX    mem_alu_out,
    input wire UIntX    mem_csr_rdata,
    input wire UIntX    mem_rs2_data,

    output wire         mem_wb_valid,
    output wire Addr    mem_wb_pc,
    output wire Inst    mem_wb_inst,
    output wire IId     mem_wb_inst_id,
    output wire Ctrl    mem_wb_ctrl,
    output wire UIntX   mem_wb_alu_out,
    output wire UIntX   mem_wb_mem_rdata,
    output wire UIntX   mem_wb_csr_rdata,

    output logic        memory_unit_stall,

    inout wire DReq     dreq,
    inout wire DResp    dresp
);

`include "include/basicparams.svh"

typedef enum logic [1:0]
{
    IDLE, WAIT_READY, WAIT_VALID 
} statetype;

statetype state = IDLE;

wire Addr   pc          = mem_pc;
wire Inst   inst        = mem_inst;
wire IId    inst_id     = mem_inst_id;
wire Ctrl   ctrl        = mem_ctrl;
wire UIntX  rs2_data    = mem_rs2_data;
wire UIntX  alu_out     = mem_alu_out;

logic   is_cmd_executed = 0;
IId     saved_inst_id   = IID_RANDOM;
wire    may_start_m     = !is_cmd_executed || saved_inst_id != inst_id;

MemSel replace_mem_wen  = MEN_X;
wire MemSel mem_wen     = MemSel'(!mem_valid ? MEN_X : 
                                saved_inst_id != inst_id ? ctrl.mem_wen : replace_mem_wen);
wire MemSize mem_size   = ctrl.mem_size;

wire is_store   = mem_wen == MEN_S;
wire is_load    = mem_wen == MEN_LS || mem_wen == MEN_LU;

wire memu_cmd_ready   = dreq.ready;
wire memu_valid       = dresp.valid;
wire UIntX memu_rdata = dresp.rdata;

assign dreq.valid   = state == WAIT_READY && mem_valid && may_start_m && mem_wen != MEN_X;
assign dreq.wen     = is_store;
assign dreq.addr    = alu_out;
assign dreq.wdata   = rs2_data;    
assign dreq.wmask   = mem_size;

assign memory_unit_stall = mem_valid && 
                            (state != IDLE || (may_start_m && mem_wen != MEN_X));

UIntX  saved_mem_rdata;

function [$bits(UIntX)-1:0] mem_rdata_func(
    input MemSel    mem_type,
    input MemSize   mem_size,
    input           mem_valid,
    input UIntX     mem_rdata
);
if (mem_type == MEN_LS) begin
    if (mem_size == SIZE_B) // lb
        mem_rdata_func = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
    else if (mem_size == SIZE_H) // lh
        mem_rdata_func = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
    else // lw
        mem_rdata_func = mem_rdata;
end else begin
    if (mem_size == SIZE_B) // lbu
        mem_rdata_func = {24'b0, mem_rdata[7:0]};
    else // lhu
        mem_rdata_func = {16'b0, mem_rdata[15:0]};
end
endfunction

assign mem_wb_valid     = mem_valid;
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
    if (!mem_valid || mem_wen == MEN_X) begin
        state           <= IDLE;
        is_cmd_executed <= 0;
        replace_mem_wen <= MEN_X;
    end else case (state)
        WAIT_READY: begin
            if (memu_cmd_ready) begin
                if (is_store) begin
                    state           <= IDLE;
                    replace_mem_wen <= MEN_X;
                    is_cmd_executed <= 1;
                end else begin
                    state           <= WAIT_VALID;
                end
            end
        end
        WAIT_VALID: begin
            if (memu_valid) begin
                saved_mem_rdata <= memu_rdata;
                begin
                    state           <= IDLE;
                    is_cmd_executed <= 1;
                    replace_mem_wen <= MEN_X;
                end
            end
        end
        default/*IDLE*/: begin
            replace_mem_wen <= mem_wen;
            if (mem_wen != MEN_X)
                state <= WAIT_READY; // ready待ちへ
        end
    endcase
end

`ifdef PRINT_MEMPERF
int memperf_counter = 0;
int clk_count = 0;
always @(posedge clk) begin
    memperf_counter += {31'b0, state == WAIT_READY || state == WAIT_VALID};
    if (clk_count % 10_000_000 == 0) begin
        $display("memperf : %d", memperf_counter);
        memperf_counter = 0;
    end
    clk_count += 1;
end
`endif

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,memstage.valid,b,%b", mem_valid);
    $display("data,memstage.state,d,%b", state);
    $display("data,memstage.inst_id,h,%b", mem_valid ? inst_id : IID_X);

    if (mem_valid) begin
        $display("data,memstage.pc,h,%b", pc);
        $display("data,memstage.inst,h,%b", inst);
        $display("data,memstage.alu_out,h,%b", alu_out);
        $display("data,memstage.rs2_data,h,%b", rs2_data);
        $display("data,memstage.mem_wen,d,%b", mem_wen);
        $display("data,memstage.mem_size,d,%b", mem_size);
        $display("data,memstage.is_load,b,%b", is_load);
        $display("data,memstage.is_store,b,%b", is_store);
        $display("data,memstage.memory_unit_stall,b,%b", memory_unit_stall);
        $display("data,memstage.output.read_data,h,%b", mem_wb_mem_rdata);

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