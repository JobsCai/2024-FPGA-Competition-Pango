//************************************************
// Author       : Jack
// Creat Date   : 2023年3月27日 20:28:27
// File Name    : Camera_top.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module Camera_top#(
    parameter SLAVE_ADDR    = 7'b0111100    , // 从器件的地址
    parameter CLK_FREQ      = 26'd50_000_000, // SCCB模块的时钟频率
    parameter SCCB_FREQ     = 18'd250_000   , // SCCB的驱动时钟频率
    parameter CAM_H_PIXEL   = 11'd1024      , // 摄像头水平方向像素个数
    parameter CAM_V_PIXEL   = 11'd768         // 摄像头垂直方向像素个数
)(
    input   wire            sys_clk         ,
    input   wire            sys_rst_n       ,
    output  wire            cam_init_done   , // 摄像头完成复位
    input   wire            sys_init_done   , // DDR3和摄像头都完成复位
    
    //摄像头接口
    input   wire            cam_pclk        , // 摄像头数据像素时钟
    input   wire            cam_vsync       , // 摄像头场同步信号
    input   wire            cam_href        , // 摄像头行同步信号
    input   wire    [ 7:0]  cam_data        , // 摄像头数据
    output  wire            cam_rst_n       , // 摄像头复位信号，低电平有效
    output  wire            cam_scl         , // 摄像头SCCB_SCL线
    inout   wire            cam_sda         , // 摄像头SCCB_SDA线
    //用户接口
    output  wire            cam_frame_vsync , // 帧有效信号
    output  wire            cam_frame_href  , // 行有效信号
    output  wire            cam_frame_valid , // 数据有效使能信号
    output  wire    [15:0]  cam_frame_data    // 有效数据
);
/****************************wire****************************/
wire            sccb_exec   ;
wire    [23:0]  sccb_data   ;
wire            sccb_done   ;
wire            dri_clk     ;

/********************combinational logic*********************/
//不对摄像头硬件复位,固定高电平
assign cam_rst_n = 1'b1;
//电源休眠模式选择 0：正常模式 1：电源休眠模式
// assign cam_pwdn = 1'b0;

/***********************instantiation************************/
sccb_driver#(
    .SLAVE_ADDR         (SLAVE_ADDR     ), // 从器件的地址
    .CLK_FREQ           (CLK_FREQ       ), // SCCB模块的时钟频率
    .SCCB_FREQ          (SCCB_FREQ      )  // SCCB的驱动时钟频率
)u_sccb_driver(
    .clk                (sys_clk        ), // input  输入时钟
    .rst_n              (sys_rst_n      ), // input  复位信号
    .sccb_exec          (sccb_exec      ), // input  开始执行I2C传输信号
    .sccb_addr          (sccb_data[23:8]), // input  读写地址
    .sccb_data_w        (sccb_data[7:0] ), // input  写入数据
    .sccb_done          (sccb_done      ), // output SCCB一次操作完成信号
    .scl                (cam_scl        ), // output SCCB的SCL时钟信号
    .sda                (cam_sda        ), // inout  SCCB的SDA信号
    .dri_clk            (dri_clk        )  // output 驱动SCCB操作的驱动时钟
);

ov5640_lut#(
    .CAM_H_PIXEL        (CAM_H_PIXEL    ), // 摄像头水平方向像素个数
    .CAM_V_PIXEL        (CAM_V_PIXEL    )  // 摄像头垂直方向像素个数
)u_ov5640_lut(
    .clk                (dri_clk        ), // input  时钟信号
    .rst_n              (sys_rst_n      ), // input  复位信号，低电平有效
    
    .sccb_done          (sccb_done      ), // input  SCCB寄存器配置完成信号
    .sccb_exec          (sccb_exec      ), // output SCCB触发执行信号   
    .sccb_data          (sccb_data      ), // output SCCB要配置的地址与数据（高16位地址，低8位数据）
    .init_done          (cam_init_done  )  // output 初始化完成信号
);

cam_data_converter u_cam_data_converter(
    .rst_n              (sys_init_done & sys_rst_n),  // input 复位信号
    
    .cam_pclk           (cam_pclk       ), // input  摄像头数据像素时钟
    .cam_vsync          (cam_vsync      ), // input  摄像头场同步信号
    .cam_href           (cam_href       ), // input  摄像头行同步信号
    .cam_data           (cam_data       ), // input  摄像头数据
    
    .cam_frame_vsync    (cam_frame_vsync), // output 帧有效信号
    .cam_frame_href     (cam_frame_href ), // output 行有效信号
    .cam_frame_valid    (cam_frame_valid), // output 数据有效使能信号
    .cam_frame_data     (cam_frame_data )  // output 有效数据 
);

endmodule

