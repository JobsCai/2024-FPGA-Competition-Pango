module Detect_rectangular 
#(
    parameter [10:0] IMG_HDISP = 11'd1024,
    parameter [10:0] IMG_VDISP = 11'd768
)
(
    input            clk,
    input            rst_n,
    //图像数据
    input            per_frame_vsync,
    input            per_frame_href,
    input            per_frame_clken,//prepared Image data output/capture enable clock
    input            per_img_bit,

    output reg [10:0] rectangular_up,
    output reg [10:0] rectangular_down,
    output reg [10:0] rectangular_left,
    output reg [10:0] rectangular_right,
    output reg        flag

);
reg [10:0] x_cnt;
reg [10:0] y_cnt;
reg [10:0] test /*synthesis   PAP_MARK_DEBUG ="1"*/;
reg [10:0] up_reg;
reg [10:0] down_reg;
reg [10:0] left_reg;
reg [10:0] right_reg;
reg        flag_reg;

//对输入的图像进行行列划分
always@(posedge clk or negedge rst_n)   
    begin
        if(!rst_n)
            begin 
                x_cnt <= 11'd0;
                y_cnt <= 11'd0;

            end
        else if (per_frame_vsync)
            begin
                x_cnt <= 11'd0;
                y_cnt <= 11'd0; 
            end 
        else if(per_frame_clken)
            begin
                if(x_cnt < IMG_HDISP - 1)
                    begin    
                        x_cnt <= x_cnt + 1'b1;
                        y_cnt <= y_cnt;
                    end
                else 
                    begin
                        x_cnt <= 11'd0;
                        y_cnt <= y_cnt + 1'b1;
                    end
            end
    end

//test
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            test <= 11'd0;
        else if(per_frame_vsync)
            test <= test + 1'b1;
        else
            test <= test;
    end

//求出目标的最大矩形边框
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                up_reg <= IMG_VDISP;
                down_reg <= 11'd0;
                left_reg <= IMG_HDISP;
                right_reg <= 11'd0;
                flag_reg <= 1'b0;
            end
        else if(per_frame_vsync)
            begin
                up_reg <= IMG_VDISP;
                down_reg <= 11'd0;
                left_reg <= IMG_HDISP;
                right_reg <= 11'd0;
                flag_reg <= 1'b0;
            end
        else if(per_frame_clken && per_img_bit)
            begin
                flag_reg <= 1'b1;
                if(x_cnt < left_reg)
                    left_reg <= x_cnt;
                else
                    left_reg <= left_reg;
                if(x_cnt > right_reg)
                    right_reg <= x_cnt;
                else
                    right_reg <= right_reg;
                if(y_cnt < up_reg)
                    up_reg <= y_cnt;
                else
                    up_reg <= up_reg;
                if(y_cnt > down_reg)
                    down_reg <= y_cnt;
                else
                    down_reg <= down_reg;
            end
    end
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                rectangular_up <= 11'd0;
                rectangular_down <= 11'd0;
                rectangular_left <= 11'd0;
                rectangular_right <= 11'd0;
                flag              <= 1'b0;
            end          
        else if (( x_cnt == IMG_HDISP - 1 )&&( y_cnt == IMG_VDISP - 1))
            begin
                rectangular_up     <= up_reg;
                rectangular_down   <= down_reg;
                rectangular_left   <= left_reg;
                rectangular_right  <= right_reg;
                flag               <= flag_reg;
                               
            end
    end
endmodule