module hdmi (
    input  wire       rst_n,
    input  wire       clk,

    output wire       hdmi_clk_p,
    output wire       hdmi_clk_n,
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,

    input wire btn1,         // right button
    output wire uart_tx      // uart transmission
);

// f_CLKOUT = f_CLKIN * FBDIV / IDIV, 3.125~600MHz
// f_VCO = f_CLKOUT * ODIV, 400~1200MHz
// f_PFD = f_CLKIN / IDIV = f_CLKOUT / FBDIV, 3~400MHz

localparam PLL_IDIV  =  2 - 1; // 0~63
localparam PLL_FBDIV = 57 - 1; // 0~63
localparam PLL_ODIV  =      2; // 2, 4, 8, 16, 32, 48, 64, 80, 96, 112, 128

// 720p
localparam DVI_H_BPORCH = 12'd220;
localparam DVI_H_ACTIVE = 12'd1280;
localparam DVI_H_FPORCH = 12'd110;
localparam DVI_H_SYNC   = 12'd40;
localparam DVI_H_POLAR  = 1'b1;
localparam DVI_V_BPORCH = 12'd20;
localparam DVI_V_ACTIVE = 12'd720;
localparam DVI_V_FPORCH = 12'd5;
localparam DVI_V_SYNC   = 12'd5;
localparam DVI_V_POLAR  = 1'b1;

// 1080p
//localparam DVI_H_BPORCH = 12'd148;
//localparam DVI_H_ACTIVE = 12'd1920;
//localparam DVI_H_FPORCH = 12'd88;
//localparam DVI_H_SYNC   = 12'd44;
//localparam DVI_H_POLAR  = 1'b1;
//localparam DVI_V_BPORCH = 12'd36;
//localparam DVI_V_ACTIVE = 12'd1080;
//localparam DVI_V_FPORCH = 12'd4;
//localparam DVI_V_SYNC   = 12'd5;
//localparam DVI_V_POLAR  = 1'b1;

/* 1440p
localparam DVI_H_BPORCH = 12'd40;
localparam DVI_H_ACTIVE = 12'd2560;
localparam DVI_H_FPORCH = 12'd8;
localparam DVI_H_SYNC   = 12'd32;
localparam DVI_H_POLAR  = 1'b1;
localparam DVI_V_BPORCH = 12'd6;
localparam DVI_V_ACTIVE = 12'd1440;
localparam DVI_V_FPORCH = 12'd13;
localparam DVI_V_SYNC   = 12'd8;
localparam DVI_V_POLAR  = 1'b0;
*/
//localparam DVI_H_BPORCH = 12'd80;
//localparam DVI_H_ACTIVE = 12'd2560;
//localparam DVI_H_FPORCH = 12'd48;
//localparam DVI_H_SYNC   = 12'd32;
//localparam DVI_H_POLAR  = 1'b1;
//localparam DVI_V_BPORCH = 12'd33;
//localparam DVI_V_ACTIVE = 12'd1440;
//localparam DVI_V_FPORCH = 12'd3;
//localparam DVI_V_SYNC   = 12'd5;
//localparam DVI_V_POLAR  = 1'b0;

wire rst;
wire clk_serial;
wire clk_pixel;
wire pll_locked;

reg       rgb_vs;
reg       rgb_hs;
reg       rgb_de;
reg [7:0] rgb_r;
reg [7:0] rgb_g;
reg [7:0] rgb_b;

assign rst = ~rst_n;


Gowin_rPLL #() pll (
    // clkout, lock, clkin
    .clkout(clk_serial),
    .lock(pll_locked),
    .clkin(clk)
);

CLKDIV #(
    //.DIV_MODE (5)
    .DIV_MODE (2)
) clk_pixel_gen (
    .HCLKIN (clk_serial),
    .RESETN (rst_n),
    .CALIB  (1'b0),
    .CLKOUT (clk_pixel)
);

DVI_TX_Top dvi_tx (
    .I_rst_n       (rst_n),       // input I_rst_n
    //.I_serial_clk  (clk_serial),  // input I_serial_clk
    .I_rgb_clk     (clk_pixel),   // input I_rgb_clk
    .I_rgb_vs      (rgb_vs),      // input I_rgb_vs
    .I_rgb_hs      (rgb_hs),      // input I_rgb_hs
    .I_rgb_de      (rgb_de),      // input I_rgb_de
    .I_rgb_r       (rgb_r),       // input [7:0] I_rgb_r
    .I_rgb_g       (rgb_g),       // input [7:0] I_rgb_g
    .I_rgb_b       (rgb_b),       // input [7:0] I_rgb_b
    .O_tmds_clk_p  (hdmi_clk_p),  // output O_tmds_clk_p
    .O_tmds_clk_n  (hdmi_clk_n),  // output O_tmds_clk_n
    .O_tmds_data_p (hdmi_data_p), // output [2:0] O_tmds_data_p
    .O_tmds_data_n (hdmi_data_n)  // output [2:0] O_tmds_data_n
);

// Video Timing Generator

reg [11:0] cnt_h;
reg [11:0] cnt_h_next;
reg [11:0] cnt_v;
reg [11:0] cnt_v_next;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        cnt_h <= 12'd0;
        cnt_v <= 12'd0;
    end else if (!pll_locked) begin
        cnt_h <= 12'd0;
        cnt_v <= 12'd0;
    end else begin
        cnt_h <= cnt_h_next;
        cnt_v <= cnt_v_next;
    end

always @(*) begin
    if (cnt_h == DVI_H_BPORCH + DVI_H_ACTIVE + DVI_H_FPORCH + DVI_H_SYNC - 1'd1) begin
        cnt_h_next = 12'd0;
        if (cnt_v == DVI_V_BPORCH + DVI_V_ACTIVE + DVI_V_FPORCH + DVI_V_SYNC - 1'd1) begin
            cnt_v_next = 12'd0;
        end else begin
            cnt_v_next = cnt_v + 1'd1;
        end
    end else begin
        cnt_h_next = cnt_h + 1'd1;
        cnt_v_next = cnt_v;
    end
end

always @(*) begin
    if (cnt_h < DVI_H_BPORCH + DVI_H_ACTIVE + DVI_H_FPORCH) begin
        rgb_hs = ~DVI_H_POLAR;
    end else begin
        rgb_hs = DVI_H_POLAR;
    end

    if (cnt_v < DVI_V_BPORCH + DVI_V_ACTIVE + DVI_V_FPORCH) begin
        rgb_vs = ~DVI_V_POLAR;
    end else begin
        rgb_vs = DVI_V_POLAR;
    end

    if (cnt_h < DVI_H_BPORCH || cnt_h >= DVI_H_BPORCH + DVI_H_ACTIVE) begin
        rgb_de = 1'b0;
    end else if (cnt_v < DVI_V_BPORCH || cnt_v >= DVI_V_BPORCH + DVI_V_ACTIVE) begin
        rgb_de = 1'b0;
    end else begin
        rgb_de = 1'b1;
    end
end


// Video Pattern Generator

reg [23:0] cnt_de;
reg [23:0] cnt_de_next;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        cnt_de <= 1'd0;
    end else begin
        cnt_de <= cnt_de_next;
    end

always @(*)
    if (rgb_vs == DVI_V_POLAR) begin
        cnt_de_next = 24'd0;
    end else if (rgb_de) begin
        cnt_de_next = cnt_de + 1'd1;
    end else begin
        cnt_de_next = cnt_de;
    end

localparam VRAM_SCALE = 3'd3;

localparam VRAM_HEIGHT = (DVI_V_ACTIVE >> VRAM_SCALE);
localparam VRAM_WIDTH  = (DVI_H_ACTIVE >> VRAM_SCALE);
localparam VRAM_SIZE   = VRAM_HEIGHT * {24'b0, VRAM_WIDTH};

reg [23:0] vram [VRAM_SIZE - 1:0];

localparam SW_STATE_IDLE = 0;
localparam SW_STATE_CHANGE = 1;

reg switchstate = SW_STATE_IDLE;
reg [23:0] swindex = 0;
wire [11:0] sw_x = swindex % VRAM_WIDTH;
wire [11:0] sw_y = swindex / VRAM_HEIGHT;

reg [23:0] colors [7:0];
initial begin
    colors[0] = 24'hB4958A;
    colors[1] = 24'h898E76;
    colors[2] = 24'h546F7E;
    colors[3] = 24'h211D33;
    colors[4] = 24'h808DA9;
    colors[5] = 24'h589BBB;
    colors[6] = 24'h87CDE3;
    colors[7] = 24'hE6C1A4;
end

reg [31:0] sw_clock = 0;

always @(posedge clk) begin
    if (switchstate == SW_STATE_IDLE) begin
        if (sw_clock == 32'd60000000) begin
            switchstate <= SW_STATE_CHANGE;
            swindex <= 0;
            sw_clock <= 0;

            colors[0] <= colors[1];
            colors[1] <= colors[2];
            colors[2] <= colors[3];
            colors[3] <= colors[4];
            colors[4] <= colors[5];
            colors[5] <= colors[6];
            colors[6] <= colors[7];
            colors[7] <= colors[0];
        end else
            sw_clock <= sw_clock + 1;
    end else begin
        if (swindex >= VRAM_SIZE) begin
            switchstate <= SW_STATE_IDLE;
        end else begin
            vram[swindex] <= colors[sw_x  / (VRAM_WIDTH / 8)];
            swindex <= swindex + 1;
        end
    end
end

wire [11:0] act_x = cnt_de % DVI_H_ACTIVE;
wire [11:0] act_y = cnt_de / DVI_H_ACTIVE;

wire [11:0] v_x = act_x >> VRAM_SCALE;
wire [11:0] v_y = act_y >> VRAM_SCALE;

wire [23:0] v_index = v_x + v_y * VRAM_WIDTH;

always @(negedge rst_n or posedge clk_pixel)
    if (!rst_n) begin
        {rgb_r, rgb_g, rgb_b} <= 24'h000000;
    end else begin
        if (v_index < VRAM_SIZE)
            {rgb_r, rgb_g, rgb_b} <= vram[v_index];
        else
            {rgb_r, rgb_g, rgb_b} <= 24'hFF0000;
    end

endmodule
