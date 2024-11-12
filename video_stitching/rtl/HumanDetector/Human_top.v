module Human_top(
    //module clock
    input           clk               ,  
    input           rst_n             ,  
    //输入图像数据
    input           pre_frame_vsync   ,
    input           pre_frame_href    ,
    input           pre_frame_de      ,
    input    [15:0] pre_rgb           ,

    //处理后的图像数据
    output          post_frame_vsync  ,   
    output          post_frame_href   ,   
    output          post_frame_de     ,   
    output   [15:0] post_rgb          ,
    output   [15:0] fushi             ,
    output   [15:0] erzhihua          ,
    output   [7:0]  img_r             ,
    output   [7:0]  img_g             ,
    output   [7:0]  img_b             ,
    output   [10:0] coor_data
    //画框
    //output   [11:0] x_min             ,
    //output   [11:0] x_max             ,
    //output   [11:0] y_min             ,
    //output   [11:0] y_max             ,
    //input    [11:0] lcd_x             ,
    //input    [11:0] lcd_y

);

//wire define
wire       [ 0:0]         img_y;
//wire     [ 7:0]         img_cb;
//wire     [ 7:0]         img_cr;
wire       [7:0 ]         post_img_y1;
wire       [7:0 ]         post_img_y2;
//wire     [ 7:0]         post_img_y;
wire                      pe_frame_vsync;
wire                      pe_frame_href;
wire                      pe_frame_clken;
// wire                  ycbcr_vsync;
// wire                  ycbcr_href;
// wire                  ycbcr_de;
// wire                  monoc;

//*****************************************************
//**                    main code
//*****************************************************
assign fushi = {16{~post1_img_y}};
assign erzhihua = {16{~img_y}};

assign  post_rgb = {16{~post2_img_y}};
assign  post_img_y1 = {8{img_y}};
assign  post_img_y2 = {8{post1_img_y}};

//RGB转YUV
RGB2yuv_human u_rgb2ycbcr_human(
    //module clock
    .clk             (clk    ),            
    .rst_n           (rst_n  ),            
    
    .pre_frame_vsync (pre_frame_vsync),    
    .pre_frame_href  (pre_frame_href ),    
    .pre_frame_de    (pre_frame_de   ),    
    .img_red         (pre_rgb[15:11] ),
    .img_green       (pre_rgb[10:5 ] ),
    .img_blue        (pre_rgb[ 4:0 ] ),
    
    .post_frame_vsync(pe_frame_vsync),     
    .post_frame_href (pe_frame_href),      
    .post_frame_de   (pe_frame_clken),     
    .img_y           (img_y),              
    .img_cb          (),
    .img_cr          ()
);

//腐蚀
wire                    post1_frame_vsync;
wire                    post1_frame_href;
wire                    post1_frame_de;
wire [0:0]              post1_img_y;

Erosion u_Erosion
(
    .clk              (clk),
    .rst_n            (rst_n),
    //准备要处理的图像
    .pre_frame_vsync  (pe_frame_vsync),     
    .pre_frame_href   (pe_frame_href),      
    .pre_frame_clken  (pe_frame_clken),     
    .pre_img_Bit      (post_img_y1),
    //输出的图像
    .post_frame_vsync (post1_frame_vsync),        
    .post_frame_href  (post1_frame_href ),        
    .post_frame_clken (post1_frame_de),           
    .post_img_Bit     (post1_img_y) 
);

//膨胀
wire                    post2_frame_vsync;
wire                    post2_frame_href;
wire                    post2_frame_de;
wire [0:0]              post2_img_y;

Dilation u_Dilation
(
    .clk              (clk),
    .rst_n            (rst_n),
    //准备要处理的图像
    .pre_frame_vsync  (post1_frame_vsync),     
    .pre_frame_href   (post1_frame_href),      
    .pre_frame_clken  (post1_frame_de),     
    .pre_img_Bit      (post_img_y2),
    //输出的图像
    .post_frame_vsync (post2_frame_vsync),        
    .post_frame_href  (post2_frame_href ),        
    .post_frame_clken (post2_frame_de),           
    .post_img_Bit     (post2_img_y) 
);

//方框
wire [10:0] rectangular_up1;
wire [10:0] rectangular_down1;
wire [10:0] rectangular_left1;
wire [10:0] rectangular_right1;
wire        flag1;


Detect_rectangular #(
    .IMG_HDISP (11'd960),
    .IMG_VDISP (11'd540)
) u_Dectect_Rectangular (
    .clk                (clk),
    .rst_n              (rst_n),
    //图像数据
    .per_frame_vsync    (post2_frame_vsync),
    .per_frame_href     (post2_frame_href),
    .per_frame_clken    (post2_frame_de),//prepared Image data output/capture enable clock
    .per_img_bit        (post2_img_y),

    .rectangular_up     (rectangular_up1),
    .rectangular_down   (rectangular_down1),
    .rectangular_left   (rectangular_left1),
    .rectangular_right  (rectangular_right1),
    .flag               (flag1)
);
//方框叠加
wire [7:0] post_img_r/*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [7:0] post_img_g/*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [7:0] post_img_b/*synthesis   PAP_MARK_DEBUG ="1"*/;

Add_rectangular #(
    .IMG_HDISP (11'd960),
    .IMG_VDISP (11'd540)
) u_Add_rectangular (
    .clk                (clk),
    .rst_n              (rst_n),

    //图像数据
    .per_frame_vsync    (pre_frame_vsync),
    .per_frame_href     (pre_frame_href),
    .per_frame_clken    (pre_frame_de),
    .per_img_red        (pre_rgb[15:11]),
    .per_img_green      (pre_rgb[10:5 ]),
    .per_img_blue       (pre_rgb[ 4:0 ]),

    //矩形框数据
    .rectangular_up     (rectangular_up1),
    .rectangular_down   (rectangular_down1),
    .rectangular_left   (rectangular_left1),
    .rectangular_right  (rectangular_right1),
    .flag               (flag1),

    //输出图像数据
    .post_frame_vsync   (post_frame_vsync),
    .post_frame_href    (post_frame_href),
    .post_frame_clken   (post_frame_de),
    .post_img_red       (post_img_r),
    .post_img_green     (post_img_g),
    .post_img_blue      (post_img_b),
    .coor_data          (coor_data)
);
assign img_r = {post_img_r};
assign img_g = {post_img_g};
assign img_b = {post_img_b};



endmodule
