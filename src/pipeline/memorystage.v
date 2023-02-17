module MemoryStage(
	input wire clk,

	input [31:0] rs2_data,
	input [3:0]  wb_sel,
	input [4:0]  mem_wen,

	input [31:0] alu_out,
	
    output  wire [31:0] memory_d_addr,
    input   wire [31:0] memory_rdata,
    output  wire        memory_wen,
    output  wire [31:0] memory_wmask,
    output  wire [31:0] memory_wdata,
    input   wire        memory_ready
);

`include "../consts_core.v"

// MEM STAGE
reg [WORD_LEN-1:0] memory_d_addr_offset = 0;    // アドレスのオフセット
reg [1:0] mem_clock     = 0;                // load命令で待機するクロック数を管理するフラグ
assign memory_d_addr    = alu_out + memory_d_addr_offset;// データ読み出しのアドレス
reg[WORD_LEN-1:0] memory_rdata_previous;    // 前の読み込まれたデータ

// load系の命令かどうかを示す
wire is_load_op_byte = wb_sel == WB_MEMB || wb_sel == WB_MEMBU;
wire is_load_op_half = wb_sel == WB_MEMH || wb_sel == WB_MEMHU;
wire is_load_op_word = wb_sel == WB_MEMW;
wire is_load_op = (is_load_op_byte || is_load_op_half || is_load_op_word);

// load系の命令で待機しているかどうかを示す
wire load_wait = (
    is_load_op &&
    (
        // LB命令は1回で読み込める
        is_load_op_byte ? mem_clock != 2'b01 :
        // LHでaddr%4=3の時2回読み込む
        is_load_op_half ? (
            memory_d_addr % 4 == 3 ? mem_clock != 2'b10 : mem_clock != 2'b01
        ) :
        // LW命令は4byteアラインされていない場合は2回読む
        memory_d_addr % 4 == 0 ? mem_clock != 2'b01 : mem_clock != 2'b10
    )
);

// 今が待ちの最後のクロックかを示す
wire load_wait_last_clock = (
    is_load_op &&
    (
        is_load_op_byte ? mem_clock == 2'b00 :
        is_load_op_half ? (
            memory_d_addr % 4 == 3 ? mem_clock == 2'b01 : mem_clock == 2'b00
        ) :
        memory_d_addr % 4 == 0 ? mem_clock == 2'b00 : mem_clock == 2'b01
    )
);

wire [7:0] memory_b_read = (
    memory_d_addr % 4 == 1 ? memory_rdata[15:8] :
    memory_d_addr % 4 == 2 ? memory_rdata[23:16] :
    memory_d_addr % 4 == 3 ? memory_rdata[31:24] :
    memory_rdata[7:0]
);

wire [15:0] memory_h_read = (
    memory_d_addr % 4 == 1 ? memory_rdata[23:8] :
    memory_d_addr % 4 == 2 ? memory_rdata[31:16] :
    memory_d_addr % 4 == 3 ? {memory_rdata[7:0], memory_rdata_previous[31:24]} :
    memory_rdata[15:0]
);

wire [WORD_LEN-1:0] memory_w_read = (
    memory_d_addr % 4 == 1 ? {memory_rdata[7:0], memory_rdata_previous[31:8]} :
    memory_d_addr % 4 == 2 ? {memory_rdata[15:0], memory_rdata_previous[31:16]} :
    memory_d_addr % 4 == 3 ? {memory_rdata[23:0], memory_rdata_previous[31:24]} :
    memory_rdata
);


// store系の命令で待機しているかを示す
wire store_wait = (
    mem_wen == MEN_SB ? mem_clock != 2'b01 :
    mem_wen == MEN_SH ? mem_clock != 2'b01 :
    mem_wen == MEN_SW ? (
        memory_d_addr % 4 != 0 ? mem_clock != 2'b01 : mem_clock == 2'b00
    ) :
    0
);

// 書き込むデータのマスク
assign memory_wmask = (
    mem_clock == 0 ? (
        mem_wen == MEN_SB ? (
            memory_d_addr % 4 == 0 ? 32'h000000ff :
            memory_d_addr % 4 == 1 ? 32'h0000ff00 :
            memory_d_addr % 4 == 2 ? 32'h00ff0000 :
            32'hff000000
        ) :
        mem_wen == MEN_SH ? (
            memory_d_addr % 4 == 0 ? 32'h0000ffff :
            memory_d_addr % 4 == 1 ? 32'h00ffff00 :
            memory_d_addr % 4 == 2 ? 32'hffff0000 :
            32'hff000000
        ) :
        (
            memory_d_addr % 4 == 0 ? 32'hffffffff :
            memory_d_addr % 4 == 1 ? 32'hffffff00 :
            memory_d_addr % 4 == 2 ? 32'hffff0000 :
            32'hff000000
        )
    ) : (
        mem_wen == MEN_SH && memory_d_addr % 4 == 3 ? 32'h000000ff :
        mem_wen == MEN_SW ? (
            memory_d_addr % 4 == 1 ? 32'h000000ff :
            memory_d_addr % 4 == 2 ? 32'h0000ffff :
            memory_d_addr % 4 == 3 ? 32'h00ffffff : 0
        ) : 0
    ) 
);

// 書き込むデータ
assign memory_wdata = (
    mem_clock == 0 ? (
        memory_d_addr % 4 == 0 ? rs2_data :
        memory_d_addr % 4 == 1 ? {rs2_data[23:0], 8'b0} :
        memory_d_addr % 4 == 2 ? {rs2_data[15:0], 16'b0} :
        {rs2_data[7:0], 24'b0}
    ) : (
        memory_d_addr % 4 == 1 ? {24'b0, rs2_data[31:24]} :
        memory_d_addr % 4 == 2 ? {16'b0, rs2_data[31:16]} :
        memory_d_addr % 4 == 3 ? {8'b0, rs2_data[31:8]} :
        0
    )
);

assign memory_wen = mem_wen == MEN_S && store_wait; // メモリを書き込むかどうかのフラグ

endmodule