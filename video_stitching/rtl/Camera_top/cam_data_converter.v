//************************************************
// Author       : Jack
// Creat Date   : 2023年3月27日 19:57:22
// File Name    : cam_data_converter.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module cam_data_converter(
    input   wire            rst_n           ,  // 复位信号
    //摄像头接口
    input   wire            cam_pclk        ,  // 摄像头数据像素时钟
    input   wire            cam_vsync       ,  // 摄像头场同步信号
    input   wire            cam_href        ,  // 摄像头行同步信号
    input   wire    [ 7:0]  cam_data        ,  // 摄像头数据
    //用户接口
    output  wire            cam_frame_vsync ,  // 帧有效信号
    output  wire            cam_frame_href  ,  // 行有效信号
    output  wire            cam_frame_valid ,  // 数据有效使能信号
    output  wire    [15:0]  cam_frame_data     // 有效数据 
);
/*************************parameter**************************/
parameter WAIT_FRAME = 4'd10; // 寄存器数据稳定等待的帧个数 

/****************************reg*****************************/
reg             r0_cam_vsync    ;
reg             r1_cam_vsync    ;
reg             r0_cam_href     ;
reg             r1_cam_href     ;

reg     [ 3:0]  cam_cnt         ; // 等待帧数稳定计数器
reg             frame_val_flag  ; // 帧有效的标志（即帧数稳定）

reg     [ 7:0]  r0_cam_data     ;
reg     [15:0]  r_cam_data_temp ; // 用于8位转16位的临时寄存器
reg             byte_flag       ;
reg             r0_byte_flag    ;

/****************************wire****************************/
wire            pos_vsync       ; // 输入场同步信号上升沿

/********************combinational logic*********************/
assign pos_vsync = (~r1_cam_vsync) & r0_cam_vsync;

//输出帧有效信号
assign cam_frame_vsync = frame_val_flag ? r1_cam_vsync    : 1'b0; 
//输出行有效信号
assign cam_frame_href  = frame_val_flag ? r1_cam_href     : 1'b0; 
//输出数据使能有效信号
assign cam_frame_valid = frame_val_flag ? r0_byte_flag    : 1'b0; 
//输出数据
assign cam_frame_data  = frame_val_flag ? r_cam_data_temp : 1'b0; 

/**************************process***************************/
always@(posedge cam_pclk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r0_cam_vsync <= 1'b0;
            r1_cam_vsync <= 1'b0;
            r0_cam_href  <= 1'b0;
            r1_cam_href  <= 1'b0;
        end
    else
        begin
            r0_cam_vsync <= cam_vsync   ;
            r1_cam_vsync <= r0_cam_vsync;
            r0_cam_href  <= cam_href    ;
            r1_cam_href  <= r0_cam_href ;
        end
end

//对帧数进行计数
always @(posedge cam_pclk or negedge rst_n)
begin
    if(!rst_n)
        cam_cnt <= 4'd0;
    else if(pos_vsync && (cam_cnt < WAIT_FRAME))
        cam_cnt <= cam_cnt + 4'd1;
    else
        cam_cnt <= cam_cnt;
end

//帧有效标志
always @(posedge cam_pclk or negedge rst_n)
begin
    if(!rst_n)
        frame_val_flag <= 1'b0;
    else if(pos_vsync && (cam_cnt == WAIT_FRAME))
        frame_val_flag <= 1'b1;
    else
        frame_val_flag <= frame_val_flag;
end

//8位数据转16位RGB565数据        
always @(posedge cam_pclk or negedge rst_n)
begin
    if(!rst_n) begin
        r_cam_data_temp <= 16'd0;
        r0_cam_data     <= 8'd0;
        byte_flag       <= 1'b0;
    end
    else if(cam_href) begin
        byte_flag   <= ~byte_flag;
        r0_cam_data <= cam_data;
        if(byte_flag)
            r_cam_data_temp <= {r0_cam_data,cam_data};
        else
            r_cam_data_temp <= r_cam_data_temp;
    end
    else begin
        byte_flag   <= 1'b0;
        r0_cam_data <= 8'd0;
    end
end

//产生输出数据有效信号(cam_frame_valid)
always @(posedge cam_pclk or negedge rst_n)
begin
    if(!rst_n)
        r0_byte_flag <= 1'b0;
    else
        r0_byte_flag <= byte_flag;
end

endmodule
