//************************************************
// Author       : Jack
// Creat Date   : 2023年3月23日 21:54:05
// File Name    : video_driver.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module video_driver#(
    parameter X_BITS    = 12        ,
    parameter Y_BITS    = 12        ,

    parameter H_SYNC    = 12'd44    , //行同步
    parameter H_BACK    = 12'd148   , //行显示后沿
    parameter H_DISP    = 12'd1920  , //行有效数据
    parameter H_FRONT   = 12'd88    , //行显示前沿
    parameter H_TOTAL   = 12'd2200  , //行扫描周期

    parameter V_SYNC    = 12'd5     , //场同步
    parameter V_BACK    = 12'd36    , //场显示后沿
    parameter V_DISP    = 12'd1080  , //场有效数据
    parameter V_FRONT   = 12'd4     , //场显示前沿
    parameter V_TOTAL   = 12'd1125    //场扫描周期
)(
    input   wire                    pix_clk     ,
    input   wire                    rst_n       ,
    
    output  wire                    video_hs    ,
    output  wire                    video_vs    ,
    output  wire                    video_de    ,
    output  wire    [23:0]          video_data  ,
    
    output  wire    [X_BITS-1:0]    pix_x       ,
    output  wire    [Y_BITS-1:0]    pix_y       ,
    output  wire                    pix_req    , // 请求像素数据输入（像素点坐标提前实际时序一个周期）
    input   wire    [23:0]          pix_data    
);
/****************************reg*****************************/
reg     [X_BITS-1:0]    cnt_h   ; // 行计数器
reg     [X_BITS-1:0]    cnt_v   ; // 场计数器

/****************************wire****************************/
wire                    video_en; // 输出数据有效信号

/********************combinational logic*********************/
assign video_hs  = ( cnt_h < H_SYNC ) ? 1'b1 : 1'b0; // 行同步信号赋值
assign video_vs  = ( cnt_v < V_SYNC ) ? 1'b1 : 1'b0; // 场同步信号赋值

assign video_en  = (((cnt_h >= H_SYNC+H_BACK) && (cnt_h < H_SYNC+H_BACK+H_DISP))
                 &&((cnt_v >= V_SYNC+V_BACK) && (cnt_v < V_SYNC+V_BACK+V_DISP)))
                 ?  1'b1 : 1'b0;
assign video_de  = video_en;
assign video_data= video_en ? pix_data : 24'd0;

assign pix_req    = (((cnt_h >= H_SYNC+H_BACK-1'b1) && 
                   (cnt_h < H_SYNC+H_BACK+H_DISP-1'b1))
                   && ((cnt_v >= V_SYNC+V_BACK) && (cnt_v < V_SYNC+V_BACK+V_DISP)))
                   ? 1'b1 : 1'b0;
                  
//像素点坐标
assign pix_x     = pix_req ? (cnt_h - (H_SYNC + H_BACK - 1'b1)) : 'd0;
assign pix_y     = pix_req ? (cnt_v - (V_SYNC + V_BACK - 1'b1)) : 'd0;

/**************************process***************************/
always@(posedge pix_clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_h <= 'd0;
    else if(cnt_h <= H_TOTAL - 1)
        cnt_h <= cnt_h + 1;
    else
        cnt_h <= 'd0;
end

always@(posedge pix_clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_v <= 'd0;
    else if(cnt_h == H_TOTAL - 1)
        if(cnt_v <= V_TOTAL - 1)
            cnt_v <= cnt_v + 1;
        else
            cnt_v <= 'd0;
    else
        cnt_v <= cnt_v;
end

endmodule
