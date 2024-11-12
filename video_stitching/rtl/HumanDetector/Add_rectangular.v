module Add_rectangular #(
    parameter [10:0] IMG_HDISP = 11'd1024,
    parameter [10:0] IMG_VDISP = 11'd768
) (
    input clk,
    input rst_n,

    //图像数据
    input           per_frame_vsync,
    input           per_frame_href,
    input           per_frame_clken,
    input  [4:0]    per_img_red,
    input  [5:0]    per_img_green,
    input  [4:0]    per_img_blue,

    //矩形框数据
    input  [10:0]    rectangular_up,
    input  [10:0]    rectangular_down,
    input  [10:0]    rectangular_left,
    input  [10:0]    rectangular_right,
    input            flag,

    //输出图像数据
    output reg       post_frame_vsync,
    output reg       post_frame_href,
    output reg       post_frame_clken,
    output reg [7:0] post_img_red/*synthesis syn_preserve="1"*/,
    output reg [7:0] post_img_green,
    output reg [7:0] post_img_blue,
    output wire [10:0] coor_data
);
    reg [10:0] x_cnt;
    reg [10:0] y_cnt;

/*  wire define */
wire    [ 7:0]      rgb888_r/*synthesis  syn_keep ="1"*/;
wire    [ 7:0]      rgb888_g/*synthesis  syn_keep="1"*/;
wire    [ 7:0]      rgb888_b/*synthesis  syn_keep="1"*/;

//RGB565 转 RGB888
assign rgb888_r = {per_img_red , per_img_red[4:2]};
assign rgb888_g = {per_img_green , per_img_green[5:4]};
assign rgb888_b = {per_img_blue , per_img_blue[4:2]};
assign coor_data = rectangular_right[10:1] + rectangular_left[10:1];

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
always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                post_frame_vsync <= 1'b0;
                post_frame_href  <= 1'b0;
                post_frame_clken <= 1'b0;
                post_img_red     <= 8'd0;
                post_img_green   <= 8'd0;
                post_img_blue    <= 8'd0;
            end
        else 
            begin
                post_frame_vsync <= per_frame_vsync;
                post_frame_href  <= per_frame_href;
                post_frame_clken <= per_frame_clken;
                
                if(flag)
                   begin
                        if((x_cnt > rectangular_left)&&(x_cnt < rectangular_right)&&((y_cnt == rectangular_up)||(y_cnt == rectangular_down)))
                            begin
                                post_img_red     <= 8'd255;
                                post_img_green   <= 8'd0;
                                post_img_blue    <= 8'd0;
                            end
                        else if((y_cnt > rectangular_up)&&(y_cnt < rectangular_down)&&((x_cnt == rectangular_left)||(x_cnt == rectangular_right)))
                            begin
                                post_img_red    <= 8'd255;
                                post_img_green  <= 8'd0;
                                post_img_blue   <= 8'd0;
                            end
                        else if((y_cnt > rectangular_up)&&(y_cnt < rectangular_down)&&((x_cnt == rectangular_left-1)||(x_cnt == rectangular_right-1)))
                            begin
                                post_img_red    <= 8'd255;
                                post_img_green  <= 8'd0;
                                post_img_blue   <= 8'd0;
                            end
                        else if((x_cnt > rectangular_left)&&(x_cnt < rectangular_right)&&((y_cnt == rectangular_up-1)||(y_cnt == rectangular_down-1)))
                            begin
                                post_img_red    <= 8'd255;
                                post_img_green  <= 8'd0;
                                post_img_blue   <= 8'd0;
                            end
                        else
                            begin
                                post_img_red     <= rgb888_r;
                                post_img_green   <= rgb888_g;
                                post_img_blue    <= rgb888_b;
                            end
                    end
                 else
                        begin
                            post_img_red     <= rgb888_r;
                            post_img_green   <= rgb888_g;
                            post_img_blue    <= rgb888_b;
                        end
            end
    end
endmodule