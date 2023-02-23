module Memory #(
	parameter MEMORY_SIZE = 2048,
	parameter MEMORY_FILE = ""
)(
	input  wire			clk,

	input  wire			cmd_start,
	input  wire			cmd_write,
	output wire			cmd_ready,

	input  wire [31:0]	addr,
	output reg  [31:0]	rdata,
	output wire			rdata_valid,
	input  wire [31:0]	wdata,
	input  wire [31:0]	wmask
);

// memory
reg [31:0] mem [MEMORY_SIZE-1:0];

initial begin
	if (MEMORY_FILE != "") begin
		$readmemh(MEMORY_FILE, mem);
	end
end

// status
localparam STATE_WAIT    = 0;
localparam STATE_READ    = 1;
localparam STATE_WRITE   = 2;

reg [3:0]	state = STATE_WAIT;

// saved input
reg [31:0]	addr_bup;
reg [31:0]	wdata_bup;
reg [31:0]	wmask_bup;

wire		wmask_isfull	= wmask_bup == 32'hffffffff;
wire [31:0] wmask_le		= {wmask_bup[7:0], wmask_bup[15:8], wmask_bup[23:16], wmask_bup[31:24]};
wire [31:0] wmask_rev_le	= ~wmask_le;

// shidted address
wire [31:0] addr_shift = addr_bup >> 2;

assign cmd_ready = state == STATE_WAIT;

reg rdata_valid_reg = 0;
assign rdata_valid = rdata_valid_reg && cmd_start == 0;

// アドレスが4byte alignedでは無い場合用
reg [3:0]	clock_cnt;
reg [31:0]	data_save;
reg [31:0]	data_save2;

always @(posedge clk) begin
	if (state == STATE_WAIT && cmd_start == 1) begin
		state		<= cmd_write ? STATE_WRITE : STATE_READ;
		addr_bup	<= addr;
		wdata_bup	<= wdata;
		wmask_bup	<= wmask;
		clock_cnt	<= 0;
		rdata_valid_reg	<= 0;
	end else if (state == STATE_READ) begin
		if (addr_bup % 4 == 0) begin
			rdata <= {
				mem[addr_shift][7:0],
				mem[addr_shift][15:8],
				mem[addr_shift][23:16],
				mem[addr_shift][31:24]
			};
			rdata_valid_reg <= 1;
			state <= STATE_WAIT;
		end else begin
			if (clock_cnt == 0) begin
				data_save <= mem[addr_shift];
				clock_cnt <= clock_cnt + 1;
			end else begin
				rdata <= {
					addr_bup % 4 == 1 ? {
							mem[addr_shift][31:24],
							data_save[31:8]
						} :
					addr_bup % 4 == 2 ? {
							mem[addr_shift][23:16],
							mem[addr_shift][31:24],
							data_save[31:16]
						} :
					{
						mem[addr_shift][15:8],
						mem[addr_shift][23:16],
						mem[addr_shift][31:24],
						data_save[31:24]
					}
				};
				rdata_valid_reg <= 1;
				state <= STATE_WAIT;	
			end
		end
	end else if (state == STATE_WRITE) begin
		if (addr_bup % 4 == 0) begin
			if (wmask_isfull) begin
				mem[addr_shift] = {
					wdata[7:0],
					wdata[15:8],
					wdata[23:16],
					wdata[31:24]
				};
				rdata_valid_reg <= 1;
				state <= STATE_WAIT;
			end else begin
				if (clock_cnt == 0) begin
					data_save <= mem[addr_shift];
					clock_cnt <= clock_cnt + 1;
				end else begin
					mem[addr_shift] = {
						({ wdata[7:0], wdata[15:8], wdata[23:16], wdata[31:24] } & wmask_le) |
						(data_save & wmask_rev_le)
					};
					rdata_valid_reg <= 1;
					state <= STATE_WAIT;
				end
			end
		end else begin
			if (clock_cnt == 0) begin
				data_save <= mem[addr_shift];
				clock_cnt <= clock_cnt + 1;
			end else if (clock_cnt == 1) begin
				data_save2 <= mem[addr_shift + 1];
				clock_cnt <= clock_cnt + 1;
			end else if (clock_cnt == 2) begin
				mem[addr_shift] <= {
					addr_bup == 1 ?
						(data_save & {8'hff, wmask_rev_le[31:8]}) |
						{8'h00, ({wdata_bup[7:0], wdata_bup[15:8], wdata_bup[23:16]} & wmask_le[31:8])} : 
					addr_bup == 2 ?
						(data_save & {16'hffff, wmask_rev_le[31:16]}) |
						{16'h0000, ({wdata_bup[7:0], wdata_bup[15:8]} & wmask_le[31:16])} :  
					(data_save & {24'hffffff, wmask_rev_le[31:24]}) | 
					{24'h000000, (wdata_bup[7:0] & wmask_le[31:24])}
				};
				clock_cnt <= clock_cnt + 1;
			end else begin
				mem[addr_shift + 1] <= {
					addr_bup == 1 ?
						(data_save & {wmask_rev_le[7:0], 24'hffffff}) | 
						{(wdata_bup[31:24] & wmask_le[7:0]), 24'h000000} :
					addr_bup == 2 ?
						(data_save & {wmask_rev_le[15:0], 16'hffff}) | 
						{({wdata_bup[23:16], wdata_bup[31:24]} & wmask_le[15:0]), 16'h0000} :
					(data_save & {wmask_rev_le[24:0], 8'hff}) | 
					{({wdata_bup[15:8], wdata_bup[23:16], wdata_bup[31:24]} & wmask_le[24:0]), 8'h00}
				};
				clock_cnt <= clock_cnt + 1;
			end
		end
	end
end
endmodule
