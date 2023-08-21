module ImmDecode (
    input  wire Inst  inst,
    output wire UIntX imm_i,
    output wire UIntX imm_s,
    output wire UIntX imm_b,
    output wire UIntX imm_j,
    output wire UIntX imm_u,
    output wire UIntX imm_z
);

wire [11:0] imm_i_g = inst[31:20];
wire [11:0] imm_s_g = {inst[31:25], inst[11:7]};
wire [11:0] imm_b_g = {inst[31], inst[7], inst[30:25], inst[11:8]};
wire [19:0] imm_j_g = {inst[31], inst[19:12], inst[20], inst[30:21]};
wire [19:0] imm_u_g = inst[31:12];
wire [4:0]  imm_z_g = inst[19:15];

assign imm_i = {{20{imm_i_g[11]}}, imm_i_g};
assign imm_s = {{20{imm_s_g[11]}}, imm_s_g};
assign imm_b = {{19{imm_b_g[11]}}, imm_b_g, 1'b0};
assign imm_j = {{11{imm_j_g[19]}}, imm_j_g, 1'b0};
assign imm_u = {imm_u_g, 12'b0};
assign imm_z = {27'd0, imm_z_g};

endmodule