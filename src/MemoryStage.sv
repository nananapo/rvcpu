module MemoryStage(
    input  wire          clk,

    input  wire          wb_branch_hazard,

    input  wire[31:0]    input_reg_pc,
    input  wire[31:0]    input_inst,
    input  wire[63:0]    input_inst_id,
    input  wire[31:0]    input_rs2_data,
    input  wire[31:0]    input_alu_out,
    input  wire          input_br_flg,
    input  wire[31:0]    input_br_target,
    input  wire[3:0]     input_mem_wen,
    input  wire          input_rf_wen,
    input  wire[3:0]     input_wb_sel,
    input  wire[4:0]     input_wb_addr,
    input  wire          input_jmp_flg,

    output reg [31:0]    output_reg_pc,
    output reg [31:0]    output_inst,
    output reg [63:0]    output_inst_id,
    output reg [31:0]    output_read_data,
    output reg [31:0]    output_alu_out,
    output reg           output_br_flg,
    output reg [31:0]    output_br_target,
    output reg           output_rf_wen,
    output reg [3:0]     output_wb_sel,
    output reg [4:0]     output_wb_addr,
    output reg           output_jmp_flg,
    output reg           output_is_stall,

    output wire          mem_cmd_start,
    output wire          mem_cmd_write,
    input  wire          mem_cmd_ready,
    output wire [31:0]   mem_addr,
    output wire [31:0]   mem_wdata,
    output wire [31:0]   mem_wmask,
    input  wire [31:0]   mem_rdata,
    input  wire          mem_rdata_valid,

    output wire          output_datahazard_rf_wen,
    output wire [4:0]    output_datahazard_wb_addr,
    output wire          output_trappable,
    output wire [3:0]    output_zifencei_mem_wen
);

`include "include/core.sv"
`include "include/memoryinterface.sv"

initial begin
    output_read_data    = 32'hffffffff;
    output_reg_pc       = REGPC_NOP;
    output_inst         = INST_NOP;
    output_inst_id      = INST_ID_NOP;
    output_alu_out      = 32'hffffffff;
    output_br_flg       = 0;
    output_br_target    = 0;
    output_rf_wen       = 0;
    output_wb_sel       = 0;
    output_wb_addr      = 0;
    output_jmp_flg      = 0;
end

localparam STATE_WAIT               = 0;
localparam STATE_WAIT_READY         = 1;
localparam STATE_WAIT_READ_VALID    = 2;

reg [1:0]   state       = STATE_WAIT;

wire [31:0] reg_pc      = wb_branch_hazard ? REGPC_NOP      : input_reg_pc;
wire [31:0] inst        = wb_branch_hazard ? INST_NOP       : input_inst;
wire [63:0] inst_id     = wb_branch_hazard ? INST_ID_NOP    : input_inst_id;
wire [31:0] rs2_data    = wb_branch_hazard ? 32'hffffffff   : input_rs2_data;
wire [31:0] alu_out     = wb_branch_hazard ? 32'hffffffff   : input_alu_out;
wire        br_flg      = wb_branch_hazard ? 0              : input_br_flg;
wire [31:0] br_target   = wb_branch_hazard ? 32'hffffffff   : input_br_target;
wire [3:0]  mem_wen     = wb_branch_hazard ? MEN_X          : input_mem_wen;
wire        rf_wen      = wb_branch_hazard ? REN_X          : input_rf_wen;
wire [3:0]  wb_sel      = wb_branch_hazard ? WB_X           : input_wb_sel;
wire [4:0]  wb_addr     = wb_branch_hazard ? 0              : input_wb_addr;
wire        jmp_flg     = wb_branch_hazard ? 0              : input_jmp_flg;

reg [31:0]  save_reg_pc     = REGPC_NOP;
reg [31:0]  save_inst       = INST_NOP;
reg [63:0]  save_inst_id    = INST_ID_NOP;
reg [31:0]  save_alu_out    = 0;
reg         save_br_flg     = 0;
reg [31:0]  save_br_target  = 0;
reg [31:0]  save_rs2_data   = 0;
reg [3:0]   save_mem_wen    = 0;
reg         save_rf_wen     = 0;
reg [3:0]   save_wb_sel     = 0;
reg [4:0]   save_wb_addr    = 0;
reg         save_jmp_flg    = 0;


`ifndef EXCLUDE_RV32A
wire is_amoswap_w_aqrl      = mem_wen == MEN_AMOSWAP_W_AQRL;
wire is_amoswap_w_aqrl_save = save_mem_wen == MEN_AMOSWAP_W_AQRL;
`endif

wire is_store       = (
    mem_wen == MEN_SB || 
    mem_wen == MEN_SH || 
    mem_wen == MEN_SW
    );

wire is_load        = !is_store && mem_wen != MEN_X
    `ifndef EXCLUDE_RV32A
        || mem_wen == MEN_AMOSWAP_W_AQRL // loadとして扱ってしまう
    `endif
    ;

wire is_store_save  = save_mem_wen == MEN_SB || save_mem_wen == MEN_SH || save_mem_wen == MEN_SW;

wire next_flg = (
    state == STATE_WAIT ? mem_wen == MEN_X || (is_store && mem_cmd_ready):
    state == STATE_WAIT_READY ? (is_store_save && mem_cmd_ready) : 
    state == STATE_WAIT_READ_VALID ?

`ifndef EXCLUDE_RV32A
        // amoswap.w.aqrlならstoreします
        !is_amoswap_w_aqrl_save &&
`endif
        mem_rdata_valid :

    1
);

assign output_is_stall = !next_flg;

// ***************
// MEMORY WIRE
// ***************
assign mem_cmd_start = (
    state == STATE_WAIT ? is_store || is_load : 
    state == STATE_WAIT_READY ? mem_cmd_ready : 0
);

assign mem_cmd_write = (
    state == STATE_WAIT ? is_store : 
    state == STATE_WAIT_READY ? mem_cmd_ready && is_store_save : 0
);

assign mem_addr = (
    state == STATE_WAIT ? alu_out :
    state == STATE_WAIT_READY ? save_alu_out :
    32'hffffffff
);

assign mem_wdata = (
    state == STATE_WAIT ? rs2_data : 
    state == STATE_WAIT_READY ? save_rs2_data : 
    32'hffffffff
);

assign mem_wmask = (
    state == STATE_WAIT ? (
        mem_wen == MEN_SB ? 32'h000000ff :
        mem_wen == MEN_SH ? 32'h0000ffff :
        32'hffffffff
    ) : 
    state == STATE_WAIT_READY ? (
        save_mem_wen == MEN_SB ? 32'h000000ff :
        save_mem_wen == MEN_SH ? 32'h0000ffff :
        32'hffffffff
    ) : 
    32'hffffffff
);

// ***************
// OUTPUT
// ***************

assign output_datahazard_rf_wen     = state == STATE_WAIT ? rf_wen : save_rf_wen;
assign output_datahazard_wb_addr    = state == STATE_WAIT ? wb_addr : save_wb_addr;
assign output_trappable             = state == STATE_WAIT ? inst == INST_NOP : save_inst == INST_NOP;
assign output_zifencei_mem_wen      = state == STATE_WAIT ? mem_wen : save_mem_wen;

reg [31:0] mem_rdata_save = 32'hffffffff;

wire [31:0] output_read_data_wire = (
    state == STATE_WAIT_READ_VALID ? (
        mem_rdata_valid ? (
                save_mem_wen == MEN_LB ? {{24{mem_rdata[7]}}, mem_rdata[7:0]} :
                save_mem_wen == MEN_LBU? {24'b0, mem_rdata[7:0]} :
                save_mem_wen == MEN_LH ? {16'b0, mem_rdata[15:0]} :
                save_mem_wen == MEN_LHU? {{16{mem_rdata[15]}}, mem_rdata[15:0]} :
                mem_rdata
        ) : 32'hffffffff
    ) : mem_rdata_save
);

wire output_is_current = (
    state == STATE_WAIT ? (
        (!is_store && !is_load) ? 1 :
        mem_cmd_ready ? is_store : 0
    ) : 0
);

wire output_is_save = (
    state == STATE_WAIT ? 0 :
    state == STATE_WAIT_READY ? mem_cmd_ready && is_store_save :
    state == STATE_WAIT_READ_VALID ? mem_rdata_valid : 
    0
);

wire [31:0] output_reg_pc_wire = (
    output_is_current ? reg_pc :
    output_is_save ? save_reg_pc :
    REGPC_NOP
);

wire [31:0] output_inst_wire = (
    output_is_current ? inst :
    output_is_save ? save_inst :
    INST_NOP
);

wire [63:0] output_inst_id_wire = (
    output_is_current ? inst_id :
    output_is_save ? save_inst_id :
    INST_ID_NOP
);

wire [31:0] output_alu_out_wire  = (
    output_is_current ? alu_out :
    output_is_save ? save_alu_out :
    32'hffffffff
);

wire output_br_flg_wire = (
    output_is_current ? br_flg :
    output_is_save ? save_br_flg :
    0
);

wire [31:0] output_br_target_wire = (
    output_is_current ? br_target :
    output_is_save ? save_br_target :
    32'hffffffff
);

wire output_rf_wen_wire = (
    output_is_current ? rf_wen :
    output_is_save ? save_rf_wen :
    REN_X
);

wire [3:0] output_wb_sel_wire = (
    output_is_current ? wb_sel :
    output_is_save ? save_wb_sel :
    WB_X
);

wire [4:0] output_wb_addr_wire = (
    output_is_current ? wb_addr :
    output_is_save ? save_wb_addr :
    5'b11111
);

wire output_jmp_flg_wire = (
    output_is_current ? jmp_flg :
    output_is_save ? save_jmp_flg :
    0
);

wire [1:0] state_clk = wb_branch_hazard ? STATE_WAIT : state;

always @(posedge clk) begin
    case (state_clk)
        STATE_WAIT: begin
            save_reg_pc     <= reg_pc;
            save_inst       <= inst;
            save_inst_id    <= inst_id;
            save_alu_out    <= alu_out;
            save_br_flg     <= br_flg;
            save_br_target  <= br_target;
            save_rs2_data   <= rs2_data;
            save_mem_wen    <= mem_wen;
            save_rf_wen     <= rf_wen;
            save_wb_sel     <= wb_sel;
            save_wb_addr    <= wb_addr;
            save_jmp_flg    <= jmp_flg;

            if (is_store) begin
                if (mem_cmd_ready)
                    state <= STATE_WAIT;
                else
                    state <= STATE_WAIT_READY;
            end else if (is_load) begin
                if (mem_cmd_ready)
                    state <= STATE_WAIT_READ_VALID;
                else
                    state <= STATE_WAIT_READY;
            end
        end
        STATE_WAIT_READY: begin
            if (mem_cmd_ready) begin
                if (is_store_save) 
                    state <= STATE_WAIT;
                else
                    state <= STATE_WAIT_READ_VALID;
            end
        end
        STATE_WAIT_READ_VALID: begin
            if (mem_rdata_valid) begin
`ifndef EXCLUDE_RV32A
                if (is_amoswap_w_aqrl_save) begin
                    state           <= STATE_WAIT_READY;
                    save_mem_wen    <= MEN_SW;
                    mem_rdata_save  <= mem_rdata;
                end else
`endif
                    state <= STATE_WAIT;
            end
        end
    endcase

    output_read_data    <= output_read_data_wire;
    output_reg_pc       <= output_reg_pc_wire;
    output_inst         <= output_inst_wire;
    output_inst_id      <= output_inst_id_wire;
    output_alu_out      <= output_alu_out_wire;
    output_br_flg       <= output_br_flg_wire;
    output_br_target    <= output_br_target_wire;
    output_rf_wen       <= output_rf_wen_wire;
    output_wb_sel       <= output_wb_sel_wire;
    output_wb_addr      <= output_wb_addr_wire;
    output_jmp_flg      <= output_jmp_flg_wire;
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,memstage.status,%b", state);
    $display("data,memstage.reg_pc,%b", reg_pc);
    $display("data,memstage.inst_id,%b", 
        wb_branch_hazard ? INST_ID_NOP :
        state == STATE_WAIT ? input_inst_id :
        save_inst_id
    );
    $display("data,memstage.rs2_data,%b", rs2_data);
    $display("data,memstage.alu_out,%b", alu_out);
    $display("data,memstage.mem_wen,%b", mem_wen);
    // $display("data,memstage.wb_sel,%b", wb_sel);
    // $display("data,memstage.is_load,%b", is_load);
    // $display("data,memstage.is_store,%b", is_store);
    // $display("data,memstage.is_store.save,%b", is_store_save);
    $display("data,memstage.output.read_data,%b", output_read_data);
    // $display("data,memstage.output.reg_pc,%b", output_reg_pc);
    // $display("data,memstage.output.alu_out,%b", output_alu_out);
    // $display("data,memstage.output.wb_sel,%b", output_wb_sel);
    $display("data,memstage.next_flg,%b", next_flg);
    $display("data,memstage.stall_flg,%b", output_is_stall);

    // $display("data,memstage.mem.cmd.s,%b", mem_cmd_start);
    // $display("data,memstage.mem.cmd.w,%b", mem_cmd_write);
    // $display("data,memstage.mem.cmd_ready,%b", mem_cmd_ready);
    // $display("data,memstage.mem.addr,%b", mem_addr);
    // $display("data,memstage.mem.wdata,%b", mem_wdata);
    // $display("data,memstage.mem.wmask,%b", mem_wmask);
    // $display("data,memstage.mem.rdata,%b", mem_rdata);
    // $display("data,memstage.mem.valid,%b", mem_rdata_valid);
    // $display("data,memstage.save.mem_wen,%b", save_mem_wen);
    // $display("data,memstage.wire.output.rdata,%b", output_read_data_wire);
end
`endif

endmodule