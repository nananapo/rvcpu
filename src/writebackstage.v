module WriteBackStage(
	wire input clk
);

// WB STAGE
wire [WORD_LEN-1:0] wb_data = (
	wb_sel == WB_MEMB ? {{24{memory_b_read[7]}}, memory_b_read} :
	wb_sel == WB_MEMBU? {24'b0, memory_b_read} :
	wb_sel == WB_MEMH ? {{16{memory_h_read[15]}}, memory_h_read} :
	wb_sel == WB_MEMHU? {16'b0, memory_h_read} :
	wb_sel == WB_MEMW ? memory_w_read :
	wb_sel == WB_PC   ? reg_pc_plus4 :
	wb_sel == WB_CSR  ? csr_rdata :
	alu_out
);

always @(posedge clk) begin
	if (rf_wen == REN_S) begin
	    regfile[wb_addr] <= wb_data;
	end	
	reg_pc <= (
		br_flg ? br_target : 
		jmp_flg ? alu_out :
		inst_is_ecall ? trap_vector_addr :
		reg_pc_plus4
	);
end

endmodule