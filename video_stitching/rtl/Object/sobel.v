module sobel
#(
    parameter  SOBEL_THRESHOLD = 128 //Sobel
)
(
    input       clk  ,               //cmos
    input       rst_n,  

    input       per_frame_vsync , 
    input       per_frame_href  ,  
    input       per_frame_clken , 
    input [7:0] per_img_y       ,       

    output      post_frame_vsync, 
    output      post_frame_href ,  
    output      post_frame_clken, 
    output      post_img_bit    
);
//reg define 
reg [9:0]  gx_temp2; 
reg [9:0]  gx_temp1; 
reg [9:0]  gx_data ; 
reg [9:0]  gy_temp1; 
reg [9:0]  gy_temp2; 
reg [9:0]  gy_data ; 
reg [20:0] gxy_square       ;
reg [20:0] per_frame_vsync_r;
reg [20:0] per_frame_href_r ; 
reg [20:0] per_frame_clken_r;
reg        post_img_bit_r   ;

//wire define 
wire        matrix_frame_vsync; 
wire        matrix_frame_href ;  
wire        matrix_frame_clken; 
wire [10:0] dim               ;

wire [7:0]  matrix_p11; 
wire [7:0]  matrix_p12; 
wire [7:0]  matrix_p13; 
wire [7:0]  matrix_p21; 
wire [7:0]  matrix_p22; 
wire [7:0]  matrix_p23;
wire [7:0]  matrix_p31; 
wire [7:0]  matrix_p32; 
wire [7:0]  matrix_p33;

assign post_frame_vsync = per_frame_vsync_r[19];
assign post_frame_href  = per_frame_href_r[19] ;
assign post_frame_clken = per_frame_clken_r[19];
assign post_img_bit     = post_frame_href ? post_img_bit_r : 1'b0;


pic_matrix_3x3_8bit u_pic_matrix_3x3_8bit(
    .clk                 (clk               ),    
    .rst_n               (rst_n             ),

    .per_frame_vsync     (per_frame_vsync   ), 
    .per_frame_href      (per_frame_href    ),  
    .per_frame_clken     (per_frame_clken   ), 
    .per_img_y           (per_img_y         ),       
    

    .matrix_frame_vsync  (matrix_frame_vsync), 
    .matrix_frame_href   (matrix_frame_href ),  
    .matrix_frame_clken  (matrix_frame_clken), 
    .matrix_p11          (matrix_p11        ), 
    .matrix_p12          (matrix_p12        ), 
    .matrix_p13          (matrix_p13        ), 
    .matrix_p21          (matrix_p21        ), 
    .matrix_p22          (matrix_p22        ),  
    .matrix_p23          (matrix_p23        ),
    .matrix_p31          (matrix_p31        ), 
    .matrix_p32          (matrix_p32        ),  
    .matrix_p33          (matrix_p33        )
);

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gy_temp1 <= 10'd0;
        gy_temp2 <= 10'd0;
        gy_data <=  10'd0;
    end
    else begin
        gy_temp1 <= matrix_p13 + (matrix_p23 << 1) + matrix_p33; 
        gy_temp2 <= matrix_p11 + (matrix_p21 << 1) + matrix_p31; 
        gy_data <= (gy_temp1 >= gy_temp2) ? gy_temp1 - gy_temp2 : 
                   (gy_temp2 - gy_temp1);
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gx_temp1 <= 10'd0;
        gx_temp2 <= 10'd0;
        gx_data <=  10'd0;
    end
    else begin
        gx_temp1 <= matrix_p11 + (matrix_p12 << 1) + matrix_p13; 
        gx_temp2 <= matrix_p31 + (matrix_p32 << 1) + matrix_p33; 
        gx_data <= (gx_temp1 >= gx_temp2) ? gx_temp1 - gx_temp2 : 
                   (gx_temp2 - gx_temp1);
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        gxy_square <= 21'd0;
    else
        gxy_square <= gx_data * gx_data + gy_data * gy_data;
end

sqrt 
#(     
      .d_width (22),
      .q_width (10),
      .r_width (11) 
)
u_sqrt(
      .clk     (clk              ),
      .rst     (!rst_n           ),
      .i_vaild (1                ),
      .data_i  ({1'b0,gxy_square}),
      
      .o_vaild (                 ),
      .data_o  (dim              ), 
      .data_r  (                 )  
);  

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        post_img_bit_r <= 1'b0;
    else if(dim >= SOBEL_THRESHOLD)
        post_img_bit_r <= 1'b1; 
    else
    post_img_bit_r <= 1'b0; 
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        per_frame_vsync_r <= 0;
        per_frame_href_r  <= 0;
        per_frame_clken_r <= 0;
    end
    else begin
        per_frame_vsync_r  <=  {per_frame_vsync_r[19:0],matrix_frame_vsync};
        per_frame_href_r   <=  {per_frame_href_r[19:0],matrix_frame_href};
        per_frame_clken_r  <=  {per_frame_clken_r[19:0],matrix_frame_clken};
    end
end

endmodule 