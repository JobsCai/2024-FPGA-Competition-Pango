//************************************************
// Author       : Jack
// Creat Date   : 2023年3月24日 9:46:21
// File Name    : video_display.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module video_display#(
    parameter X_BITS    = 12        ,
    parameter Y_BITS    = 12        ,
    parameter H_DISP    = 12'd1920  , //行有效数据
    parameter V_DISP    = 12'd1080    //场有效数据
)(
    input   wire                    pix_clk     ,
    input   wire                    rst_n       ,
    
    input   wire    [X_BITS-1:0]    pix_x       ,
    input   wire    [Y_BITS-1:0]    pix_y       ,
    output  reg     [23:0]          pix_data    
);
/*************************parameter**************************/
localparam WHITE  = 24'b11111111_11111111_11111111;  //RGB888 白色
localparam BLACK  = 24'b00000000_00000000_00000000;  //RGB888 黑色
localparam RED    = 24'b11111111_00001100_00000000;  //RGB888 红色
localparam GREEN  = 24'b00000000_11111111_00000000;  //RGB888 绿色
localparam BLUE   = 24'b00000000_00000000_11111111;  //RGB888 蓝色
localparam YELLOW = 24'b11111111_11111111_00000000;  //RGB888 黄色
localparam PURPLE = 24'b11111111_00000000_11111111;  //RGB888 紫色
localparam CYAN   = 24'b00000000_11111111_11111111;  //RGB888 青色

localparam H_DISP_0 = H_DISP / 8  ;
localparam H_DISP_1 = 2 * H_DISP_0;
localparam H_DISP_2 = 3 * H_DISP_0;
localparam H_DISP_3 = 4 * H_DISP_0;
localparam H_DISP_4 = 5 * H_DISP_0;
localparam H_DISP_5 = 6 * H_DISP_0;
localparam H_DISP_6 = 7 * H_DISP_0;

/**************************process***************************/
always@(posedge pix_clk or negedge rst_n)
begin
    if(!rst_n)
        pix_data <= 24'd0;
    else if((pix_x >= 0) && (pix_x < H_DISP_0))
        pix_data <= WHITE;
    else if((pix_x >= H_DISP_0) && (pix_x < H_DISP_1))
        pix_data <= BLACK;
    else if((pix_x >= H_DISP_1) && (pix_x < H_DISP_2))
        pix_data <= RED;
    else if((pix_x >= H_DISP_2) && (pix_x < H_DISP_3))
        pix_data <= GREEN;
    else if((pix_x >= H_DISP_3) && (pix_x < H_DISP_4))
        pix_data <= BLUE;
    else if((pix_x >= H_DISP_4) && (pix_x < H_DISP_5))
        pix_data <= YELLOW;
    else if((pix_x >= H_DISP_5) && (pix_x < H_DISP_6))
        pix_data <= PURPLE;
    else
        pix_data <= CYAN;
end

endmodule
