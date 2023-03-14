module MemoryStage(
    input  wire          clk,

    input  wire          wb_branch_hazard,

    input  wire[31:0]    input_reg_pc,
    input  wire[31:0]    input_rs2_data,
    input  wire[31:0]    input_alu_out,
    input  wire          input_br_flg,
    input  wire[31:0]    input_br_target,
    input  wire[3:0]     input_mem_wen,
    input  wire          input_rf_wen,
    input  wire[3:0]     input_wb_sel,
    input  wire[4:0]     input_wb_addr,
    input  wire          input_jmp_flg,

    output reg [31:0]    output_read_data,
    output reg [31:0]    output_reg_pc,
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
    input  wire          mem_rdata_valid
);

`include "include/core.v"
`include "include/memoryinterface.v"

initial begin
    output_read_data    = 32'hffffffff;
    output_reg_pc       = 32'hffffffff;
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
reg [31:0]  save_alu_out    = 0;
reg         save_br_flg     = 0;
reg [31:0]  save_br_target  = 0;
reg [31:0]  save_rs2_data   = 0;
reg [3:0]   save_mem_wen    = 0;
reg         save_rf_wen     = 0;
reg [3:0]   save_wb_sel     = 0;
reg [4:0]   save_wb_addr    = 0;
reg         save_jmp_flg    = 0;


wire is_store       = mem_wen == MEN_SB || mem_wen == MEN_SH || mem_wen == MEN_SW;
wire is_load        = !is_store && mem_wen != MEN_X;
wire is_store_save  = save_mem_wen == MEN_SB || save_mem_wen == MEN_SH || save_mem_wen == MEN_SW;

function func_next_flg(
    input [1:0] state,
    input [3:0] mem_wen,
    input is_store,
    input mem_cmd_ready,
    input is_store_save,
    input mem_rdata_valid
);
    case(state)
        STATE_WAIT : func_next_flg = mem_wen == MEN_X || (is_store && mem_cmd_ready);
        STATE_WAIT_READY : func_next_flg = is_store_save && mem_cmd_ready;
        STATE_WAIT_READ_VALID : func_next_flg = mem_rdata_valid;
        default : func_next_flg = 1;
    endcase
endfunction

wire next_flg = func_next_flg(
    state,
    mem_wen,
    is_store,
    mem_cmd_ready,
    is_store_save,
    mem_rdata_valid
);

assign output_is_stall = !next_flg;

// ***************
// MEMORY WIRE
// ***************
function func_mem_cmd_start(
    input [1:0] state,
    input is_store,
    input is_load,
    input mem_cmd_ready
);
    case (state)
        STATE_WAIT: func_mem_cmd_start = is_store || is_load;
        STATE_WAIT_READY: func_mem_cmd_start = mem_cmd_ready;
        default: func_mem_cmd_start = 0;
    endcase
endfunction

assign mem_cmd_start = func_mem_cmd_start(
    state,
    is_store,
    is_load,
    mem_cmd_ready
);


function func_mem_cmd_write(
    input [1:0] state,
    input is_store,
    input mem_cmd_ready,
    input is_store_save
);
    case (state)
        STATE_WAIT: func_mem_cmd_write = is_store;
        STATE_WAIT_READY: func_mem_cmd_write = mem_cmd_ready && is_store_save;
        default: func_mem_cmd_write = 0;
    endcase
endfunction

assign mem_cmd_write = func_mem_cmd_write(
    state,
    is_store,
    mem_cmd_ready,
    is_store_save
);


function [31:0] func_mem_addr(
    input [1:0]  state,
    input [31:0] alu_out,
    input [31:0] save_alu_out
);
    case (state)
        STATE_WAIT: func_mem_addr = alu_out;
        STATE_WAIT_READY: func_mem_addr = save_alu_out;
        default: func_mem_addr = 32'hffffffff;
    endcase
endfunction

assign mem_addr = func_mem_addr(
    state,
    alu_out,
    save_alu_out
);


function [31:0] func_mem_wdata(
    input [1:0]  state,
    input [31:0] rs2_data,
    input [31:0] save_rs2_data
);
    case (state)
        STATE_WAIT: func_mem_wdata = rs2_data;
        STATE_WAIT_READY: func_mem_wdata = save_rs2_data;
        default: func_mem_wdata = 32'hffffffff;
    endcase
endfunction

assign mem_wdata = func_mem_addr(
    state,
    rs2_data,
    save_rs2_data
);


function [31:0] func_mem_wmask(
    input [1:0]  state,
    input [31:0] rs2_data,
    input [31:0] save_rs2_data
);
    case (state == STATE_WAIT ? mem_wen : save_mem_wen)
        MEN_SB: func_mem_wmask = 32'h000000ff;
        MEN_SH: func_mem_wmask = 32'h0000ffff;
        default:func_mem_wmask = 32'hffffffff;
    endcase
endfunction

assign mem_wmask = func_mem_wmask(
    state,
    rs2_data,
    save_rs2_data
);

// OUTPUT

function [31:0] func_output_read_data_wire(
    input [1:0]     state,
    input           mem_rdata_valid,
    input [3:0]     save_mem_wen,
    input [31:0]    mem_rdata
);
    case (state)
        STATE_WAIT: func_output_read_data_wire = 32'hffffffff;
        STATE_WAIT_READ_VALID: begin
            if (mem_rdata_valid) begin
                case (save_mem_wen)
                    MEN_LB : func_output_read_data_wire = {24'b0, mem_rdata[7:0]};
                    MEN_LBU: func_output_read_data_wire = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                    MEN_LH : func_output_read_data_wire = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                    MEN_LHU: func_output_read_data_wire = {16'b0, mem_rdata[15:0]};
                    default: func_output_read_data_wire = mem_rdata;
                endcase
            end else
                func_output_read_data_wire = 32'hffffffff;
        end
        default: func_output_read_data_wire = 32'hffffffff;
    endcase
endfunction

wire [31:0] output_read_data_wire = func_output_read_data_wire(
    state,
    mem_rdata_valid,
    save_mem_wen,
    mem_rdata
);

wire output_is_current = 
    state == STATE_WAIT && 
    ((!is_store && !is_load) ||
    (mem_cmd_ready && is_store));

wire output_is_save = (
    state == STATE_WAIT ? 0 :
    state == STATE_WAIT_READY ? is_store_save :
    state == STATE_WAIT_READ_VALID ? mem_rdata_valid : 
    0
);


wire [1:0] state_clk = wb_branch_hazard ? STATE_WAIT : state;

always @(posedge clk) begin
    case (state_clk)
        STATE_WAIT: begin
            save_reg_pc     <= reg_pc;
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
            if (mem_rdata_valid)
                state <= STATE_WAIT;
        end
    endcase

    if (output_is_current) begin
        output_reg_pc       <= reg_pc;
        output_alu_out      <= alu_out;
        output_br_flg       <= br_flg;
        output_br_target    <= br_target;
        output_rf_wen       <= rf_wen;
        output_wb_sel       <= wb_sel;
        output_wb_addr      <= wb_addr;
        output_jmp_flg      <= jmp_flg;
    end else if (output_is_save) begin
        output_reg_pc       <= save_reg_pc;
        output_alu_out      <= save_alu_out;
        output_br_flg       <= save_br_flg;
        output_br_target    <= save_br_target;
        output_rf_wen       <= save_rf_wen;
        output_wb_sel       <= save_wb_sel;
        output_wb_addr      <= save_wb_addr;
        output_jmp_flg      <= save_jmp_flg;
    end else begin
        output_reg_pc       <= REGPC_NOP;
        output_alu_out      <= 32'hffffffff;
        output_br_flg       <= 0;
        output_br_target    <= REGPC_NOP;
        output_rf_wen       <= REN_X;
        output_wb_sel       <= WB_X;
        output_wb_addr      <= 0;
        output_jmp_flg      <= 0;
    end

    output_read_data    <= output_read_data_wire;
end

`ifdef DEBUG 
always @(posedge clk) begin
    $display("MEMORY STAGE-------------");
    $display("status        : %d", state);
    $display("reg_pc        : 0x%H", reg_pc);
    $display("rs2_data      : 0x%H", rs2_data);
    $display("alu_out       : 0x%H", alu_out);
    $display("mem_wen       : %d", mem_wen);
    $display("wb_sel        : %d", wb_sel);
    $display("is_load       : %d", is_load);
    $display("is_store      : %d", is_store);
    $display("is_store.save : %d", is_store_save);
    $display("out.read_data : 0x%H", output_read_data);
    $display("out._reg_pc   : 0x%H", output_reg_pc);
    $display("out._alu_out  : 0x%H", output_alu_out);
    $display("out._wb_sel   : %d", output_wb_sel);
    $display("next_flg      : %d", next_flg);
    $display("stall_flg     : %d", output_is_stall);
    $display("mem.cmd.s     : %d", mem_cmd_start);
    $display("mem.cmd.w     : %d", mem_cmd_write);
    $display("mem.cmd_ready : %d", mem_cmd_ready);
    $display("mem.addr      : 0x%H", mem_addr);
    $display("mem.wdata     : 0x%H", mem_wdata);
    $display("mem.wmask     : 0x%H", mem_wmask);
    $display("mem.rdata     : 0x%H", mem_rdata);
    $display("mem.valid     : %d", mem_rdata_valid);
    $display("save.mem_wen  : %d", save_mem_wen);
    $display("wire.out.rdata: 0x%h", output_read_data_wire);
end
`endif

endmodule