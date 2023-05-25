module FetchStage(
    input  wire         clk,

    output wire         mem_start,
    input  wire         mem_ready,
    output wire [31:0]  mem_addr,
    input  wire [31:0]  mem_data,
    input  wire         mem_data_valid,

    output wire         if_valid,
    output wire [31:0]  if_reg_pc,
    output wire [31:0]  if_inst,
    output wire [63:0]  if_inst_id,

    input  wire         if_stall_flg,
    input  wire [31:0]  branch_target,
    input  wire         branch_hazard
);

`include "include/core.sv"

typedef enum {  
    WAIT_READY, WAIT_VALID, FETCHED_WAIT_MOVE
} statetype;

reg statetype state = WAIT_READY;

wire        stall_flg = if_stall_flg;

reg [31:0]  reg_pc  = 0;
reg [63:0]  inst_id = 0; // 命令フェッチ試行ごとにユニークなID

// フェッチ済みのデータ
reg [31:0]  saved_reg_pc;
reg [31:0]  saved_inst;
reg [63:0]  saved_inst_id;

// 無効/有効フラグ
assign if_valid     =   branch_hazard ? 0 : // 分岐中は無効
                        // 分岐していないとき、今フェッチ完了したか、フェッチ済みなら有効
                        (state == WAIT_VALID && mem_data_valid) || state == FETCHED_WAIT_MOVE;

assign if_reg_pc    =   state == FETCHED_WAIT_MOVE ? saved_reg_pc : reg_pc;
assign if_inst      =   state == FETCHED_WAIT_MOVE ? saved_inst : mem_data;
assign if_inst_id   =   state == FETCHED_WAIT_MOVE ? saved_inst_id : inst_id;


// mem_start : mem_addr
function [1 + 32 - 1:0] sig_mem_ctrl(
    logic           mem_ready,
    logic [31:0]    mem_data,
    logic           mem_data_valid,
    statetype       state,
    logic [31:0]    reg_pc,
    logic           stall_flg,
    logic           branch_hazard,
    logic [31:0]    branch_target
);
if (branch_hazard)
    sig_mem_ctrl = {1'b1, branch_target};
else
    case (state)
    WAIT_READY:         sig_mem_ctrl = {1'b1, reg_pc};
    // ストールしていない必要がある
    WAIT_VALID:         sig_mem_ctrl = {mem_data_valid && !stall_flg, reg_pc + 32'd4};
    FETCHED_WAIT_MOVE:  sig_mem_ctrl = {!stall_flg, reg_pc};
    endcase
endfunction

assign {mem_start, mem_addr} = sig_mem_ctrl(mem_ready, mem_data, mem_data_valid, state, reg_pc, stall_flg, branch_hazard, branch_target);

/*
 TODO
 fetchしたものを溜めたい、branchならclearしたい
 fetchしたらストールにかかわらずフェッチ開始したい
 TODO
 fetch_wait_move必要か？validについて考え直したい
*/
always @(posedge clk) begin
    // 分岐なら、reg_pcとinst_idを更新する
    if (branch_hazard) begin
        reg_pc  <= branch_target;
        inst_id <= inst_id + 1;
        state   <= mem_ready ? WAIT_VALID : WAIT_READY; // メモリがreadyなら、すぐにフェッチ要求する
    end else begin
        case (state)
        WAIT_READY:
            if (mem_ready) state <= WAIT_VALID;
        WAIT_VALID:
            if (mem_data_valid) begin
                `ifdef PRINT_DEBUGINFO 
                    $display("info,fetchstage.instruction_fetched,Instruction Fetched");
                `endif
                // フェッチしたら、reg_pcとinst_idを更新する
                reg_pc          <= reg_pc + 4;
                inst_id         <= inst_id + 1;

                // レジスタに保存
                saved_reg_pc    <= reg_pc;
                saved_inst      <= mem_data;
                saved_inst_id   <= inst_id;

                // stall_flg        => FETCHED_WAIT_MOVE
                // メモリがready    => WAIT_VALIDのまま次のフェッチ
                // メモリが!ready   => WAIT_READYでreadyを待つ
                state           <= stall_flg ? FETCHED_WAIT_MOVE :
                                   (mem_ready ? WAIT_VALID : WAIT_READY);
            end
        FETCHED_WAIT_MOVE:
            // ストール終了を待つ
            if (!stall_flg)
                state <= mem_ready ? WAIT_VALID : WAIT_READY;// メモリがreadyなら次のフェッチへ
        endcase
    end
end

`ifdef PRINT_DEBUGINFO 
always @(posedge clk) begin
    $display("data,fetchstage.output.memory.start,%b", mem_start);
    $display("data,fetchstage.input.memory.ready,%b", mem_ready);
    $display("data,fetchstage.output.memory.addr,%b", mem_addr);
    $display("data,fetchstage.input.memory.data,%b", mem_data);
    $display("data,fetchstage.input.memory.data_valid,%b", mem_data_valid);

    // $display("data,fetchstage.input.branch_target,%b", branch_target);
    // $display("data,fetchstage.input.branch_hazard,%b", branch_hazard);
    // $display("data,fetchstage.input.stall_flg,%b", stall_flg);

    $display("data,fetchstage.output.if_valid,%b", if_valid);
    $display("data,fetchstage.output.if_reg_pc,%b", if_reg_pc);
    $display("data,fetchstage.output.if_inst,%b", if_inst);
    // $display("data,fetchstage.output.if_inst_id,%b", if_inst_id);

    $display("data,fetchstage.inst_id,%b", inst_id);
    $display("data,fetchstage.state,%b", state);

end
`endif

endmodule
