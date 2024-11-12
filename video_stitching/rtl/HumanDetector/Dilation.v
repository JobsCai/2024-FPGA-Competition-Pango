module Dilation  
(

    //global clock
    input				clk,  				
	input				rst_n,				
	//Image data prepred to be processd
	input				pre_frame_vsync,	
	input				pre_frame_href,		
	input				pre_frame_clken,	
	input				pre_img_Bit,		
	//Image data has been processd
	output				post_frame_vsync,	
	output				post_frame_href,	
	output				post_frame_clken,	
	output				post_img_Bit
);

//生成8bit 3x3的矩阵，用于腐蚀操作
    wire        matrix_frame_vsync;
    wire        matrix_frame_href;
    wire        matrix_frame_clken;
    wire [7:0]  matrix_p11;
    wire [7:0]  matrix_p12; 
    wire [7:0]  matrix_p13;
    wire [7:0]  matrix_p21; 
    wire [7:0]  matrix_p22; 
    wire [7:0]  matrix_p23;
    wire [7:0]  matrix_p31; 
    wire [7:0]  matrix_p32; 
    wire [7:0]  matrix_p33;

vip_matrix_generate_3x3_8bit u_vip_matrix_generate_3x3_8bit(
    .clk        (clk), 
    .rst_n      (rst_n),
    
    
    .pre_frame_vsync    (pre_frame_vsync),
    .pre_frame_href     (pre_frame_href), 
    .pre_frame_clken    (pre_frame_clken),
    .pre_img_y          (pre_img_Bit),
    
    .matrix_frame_vsync (matrix_frame_vsync),
    .matrix_frame_href  (matrix_frame_href),
    .matrix_frame_clken (matrix_frame_clken),
    .matrix_p11         (matrix_p11),    
    .matrix_p12         (matrix_p12),    
    .matrix_p13         (matrix_p13),
    .matrix_p21         (matrix_p21),    
    .matrix_p22         (matrix_p22),    
    .matrix_p23         (matrix_p23),
    .matrix_p31         (matrix_p31),    
    .matrix_p32         (matrix_p32),    
    .matrix_p33         (matrix_p33)
);

    reg post_img_Bit1;
    reg post_img_Bit2;
    reg post_img_Bit3;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        begin
            post_img_Bit1 <= 1'b0;
            post_img_Bit2 <= 1'b0;
            post_img_Bit3 <= 1'b0;
        end
    else
        begin
            post_img_Bit1 <= matrix_p11 || matrix_p12 || matrix_p13;
            post_img_Bit2 <= matrix_p21 || matrix_p22 || matrix_p23;
            post_img_Bit3 <= matrix_p31 || matrix_p32 || matrix_p33;
        end
end

    reg post_img_Bit4;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        begin
            post_img_Bit4 <= 1'b0;
        end
    else
        begin
            post_img_Bit4 <= post_img_Bit1 || post_img_Bit2 || post_img_Bit3;
        end
end

reg [1:0] pre_frame_vsync_r;
reg [1:0] pre_frame_href_r;
reg [1:0] pre_frame_clken_r;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        begin
            pre_frame_vsync_r <= 0;
            pre_frame_href_r  <= 0;
            pre_frame_clken_r <= 0;
        end
    else
        begin
            pre_frame_vsync_r <= {pre_frame_vsync_r[0], matrix_frame_vsync};
            pre_frame_href_r  <= {pre_frame_href_r[0], matrix_frame_href};
            pre_frame_clken_r <= {pre_frame_clken_r[0], matrix_frame_clken};
        end
end

assign post_frame_vsync = pre_frame_vsync_r[1];
assign post_frame_href  = pre_frame_href_r[1];
assign post_frame_clken = pre_frame_clken_r[1];
assign post_img_Bit     = post_img_Bit4 ? 1'b1 : 1'b0;

endmodule