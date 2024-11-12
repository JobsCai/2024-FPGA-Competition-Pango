module Rectangular (
    input               clk,
    input               rst_n,
    input               per_frame_vsync,
    input               per_frame_href,
    input               per_frame_clken,
    input               per_img_Bit,
    output              post_frame_vsync,
    output              post_frame_href,
    output              post_frame_clken,
    output  reg [11:0]  x_min,
    output  reg [11:0]  x_max,
    output  reg [11:0]  y_min,
    output  reg [11:0]  y_max,
    input 		[11:0]	lcd_x,
	input 		[11:0]	lcd_y,
    output      [15:0]  post_img
);
    
endmodule