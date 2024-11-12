module object_top(
    //module clock
    input           clk             ,  // 时钟信号
    input           rst_n           ,  // 复位信号（低有效）

    //图像处理前的数据接口
    input           pre_frame_vsync ,  // 处理前场同步信号
    input           pre_frame_hsync ,  // 处理前行同步信号
    input           pre_frame_de    ,  // 处理前数据输入使能
    input    [15:0] pre_rgb         ,  // 处理前RGB565颜色数据

    //图像处理后的数据接口
    output          post_frame_vsync,  // 处理后场同步信号
    output          post_frame_hsync,  // 处理后行同步信号
    output          post_frame_de   ,  // 处理后数据输入使能
    output   [15:0] post_rgb        ,    // 处理后RGB565颜色数据
    output   [15:0] test,
    output   [15:0] fushi,

    output   [7:0]  img_r             ,
    output   [7:0]  img_g             ,
    output   [7:0]  img_b             

);

parameter  SOBEL_THRESHOLD = 105; //sobel阈值

//wire define
wire 	    post1_frame_vsync	;
wire 	    post1_frame_href	;
wire 	    post1_frame_clken	;
wire [7:0]	post1_img_Bit	    ;
wire [0:0]  post1_Red           ;
wire [7:0]  post_img_y1         ;
wire [7:0]  post_img_y2         ;
    

//wire define
wire 	    post3_frame_vsync	;
wire 	    post3_frame_href	;
wire 	    post3_frame_clken	;


//*****************************************************
//**                    main code
//*****************************************************

assign  post_rgb = {16{~post_img_bit}};
assign  test  =  {16{~post1_Red}};
assign  fushi =  {16{~post4_img_y}};
assign  post_img_y1 = {8{post1_Red}};
assign  post_img_y2 = {8{post2_img_y}};

//RGB转YCbCr模块
rgb2ycbcr u_rgb2ycbcr(
    //module clock
    .clk                (clk             ), // 时钟信号
    .rst_n              (rst_n           ), // 复位信号（低有效）
    //图像处理前的数据接口
    .pre_frame_vsync    (pre_frame_vsync ), // vsync信号
    .pre_frame_href     (pre_frame_hsync ), // href信号
    .pre_frame_de       (pre_frame_de    ), // data enable信号
    .img_red            (pre_rgb[15:11]  ),
    .img_green          (pre_rgb[10:5 ]  ),
    .img_blue           (pre_rgb[ 4:0 ]  ),
    //图像处理后的数据接口
    .post_frame_vsync   (post1_frame_vsync  ), // vsync信号
    .post_frame_href    (post1_frame_href   ), // href信号
    .post_frame_de      (post1_frame_clken  ), // data enable信号
    .img_Red            (post1_Red          ),
    .img_y              (post1_img_Bit      ),
    .img_cb             (                   ),
    .img_cr             (                   )
);


wire                    post2_frame_vsync;
wire                    post2_frame_href;
wire                    post2_frame_de;
wire [0:0]              post2_img_y;

Dilation u_Erosion
(
    .clk              (clk),
    .rst_n            (rst_n),
    //准备要处理的图像
    .pre_frame_vsync  (post1_frame_vsync),     
    .pre_frame_href   (post1_frame_href),      
    .pre_frame_clken  (post1_frame_clken),     
    .pre_img_Bit      (post_img_y1),
    //输出的图像
    .post_frame_vsync (post2_frame_vsync),        
    .post_frame_href  (post2_frame_href ),        
    .post_frame_clken (post2_frame_de),           
    .post_img_Bit     (post2_img_y) 
);

//膨胀
wire                    post4_frame_vsync;
wire                    post4_frame_href;
wire                    post4_frame_de;
wire [0:0]              post4_img_y;

Erosion u_Dilation
(
    .clk              (clk),
    .rst_n            (rst_n),
    //准备要处理的图像
    .pre_frame_vsync  (post2_frame_vsync),     
    .pre_frame_href   (post2_frame_href),      
    .pre_frame_clken  (post2_frame_de),     
    .pre_img_Bit      (post_img_y2),
    //输出的图像
    .post_frame_vsync (post4_frame_vsync),        
    .post_frame_href  (post4_frame_href ),        
    .post_frame_clken (post4_frame_de),           
    .post_img_Bit     (post4_img_y) 
);


sobel
    #(
    .SOBEL_THRESHOLD  (SOBEL_THRESHOLD)    //sobel阈值
    )
u_pic_sobel(
    .clk             (clk              ),   
    .rst_n           (rst_n            ),  
    
    //处理前数据
    .per_frame_vsync (post1_frame_vsync ), //处理前帧有效信号
    .per_frame_href  (post1_frame_href ), //处理前行有效信号
    .per_frame_clken (post1_frame_clken ), //处理前图像使能信号
    .per_img_y       (post1_img_Bit ), //处理前输入灰度数据
    
    //处理后的数据
    .post_frame_vsync (post3_frame_vsync), //处理后帧有效信号
    .post_frame_href  (post3_frame_hsync), //处理后行有效信号
    .post_frame_clken (post3_frame_de   ), //输出使能信号
    .post_img_bit     (post_img_bit    )  //输出像素
        
);

wire [10:0] rectangular_up;
wire [10:0] rectangular_down;
wire [10:0] rectangular_left;
wire [10:0] rectangular_right;
wire        flag;

Object_rectangular #(
    .IMG_HDISP (11'd960),
    .IMG_VDISP (11'd540)
) u_object_Rectangular (
    .clk                (clk),
    .rst_n              (rst_n),
    //图像数据
    .per_frame_vsync    (post1_frame_vsync),
    .per_frame_href     (post1_frame_href ),
    .per_frame_clken    (post1_frame_clken),//prepared Image data output/capture enable clock
    .per_img_bit        (post4_img_y      ),
    .per_img_sobel      (post_img_bit     ),

    .rectangular_up     (rectangular_up),
    .rectangular_down   (rectangular_down),
    .rectangular_left   (rectangular_left),
    .rectangular_right  (rectangular_right),
    .flag               (flag)
);
//方框叠加
wire [7:0] post_img_r/*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [7:0] post_img_g/*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [7:0] post_img_b/*synthesis   PAP_MARK_DEBUG ="1"*/;

Add_object_rectangular #(
    .IMG_HDISP (11'd960),
    .IMG_VDISP (11'd540)
) u_object_rectangular (
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
    .rectangular_up     (rectangular_up),
    .rectangular_down   (rectangular_down),
    .rectangular_left   (rectangular_left),
    .rectangular_right  (rectangular_right),
    .flag               (flag),

    //输出图像数据
    .post_frame_vsync   (post_frame_vsync),
    .post_frame_href    (post_frame_href),
    .post_frame_clken   (post_frame_de),
    .post_img_red       (post_img_r),
    .post_img_green     (post_img_g),
    .post_img_blue      (post_img_b),
    .coor_data          ()
);
assign img_r = {post_img_r};
assign img_g = {post_img_g};
assign img_b = {post_img_b};




endmodule