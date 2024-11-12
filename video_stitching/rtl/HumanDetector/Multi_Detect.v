module Multi_Detect
#(
    parameter [9:0] IMG_HDISP = 11'd1920 ,
    parameter [9:0] IMG_VDISP = 11'd1080
)
(
    input wire        clk,
    input wire        rst_n,

    input             per_frame_vsync,
    input             per_frame_href,
    input             per_frame_clken,
    input             per_img_Bit,

    output reg [40:0] target_pos_out [15:0],
    
    input      [ 9:0] MIN_DIST,
    input             disp_sel
);

reg         per_frame_vsync_r;
reg         per_frame_href_r;
reg         per_frame_clken_r;
reg         per_img_Bit_r;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        per_frame_vsync_r <= 0;
        per_frame_href_r <= 0;
        per_frame_clken_r <= 0;
        per_img_Bit_r <= 8'd0;
    end
    else begin
        per_frame_vsync_r <= per_frame_vsync;
        per_frame_href_r <= per_frame_href;
        per_frame_clken_r <= per_frame_clken;
        per_img_Bit_r <= per_img_Bit;
    end
end

wire vsync_pos_flag;//场同步信号上升沿
wire vsync_neg_flag;//场同步信号下降沿

assign vsync_pos_flag = per_frame_vsync & (~per_frame_vsync_r);
assign vsync_neg_flag = (~per_frame_vsync) & per_frame_vsync_r;

reg [9:0]   x_cnt;
reg [9:0]   y_cnt;

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
//寄存坐标
reg [9:0]   x_cnt_r ;
reg [9:0]   y_cnt_r ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_cnt_r <= 10'd0;
        y_cnt_r <= 10'd0;
    end
    else begin
        x_cnt_r <= x_cnt;
        y_cnt_r <= y_cnt;
    end
end

reg [40:0] target_pos [15:0] ;//寄存各个运动目标的边界

wire [15:0] target_flag ;
wire [ 9:0] target_left [15:0] ;
wire [ 9:0] target_right [15:0] ;
wire [ 9:0] target_top [15:0] ;
wire [ 9:0] target_bottom [15:0] ;

wire [ 9:0] target_boarder_left [15:0] ;
wire [ 9:0] target_boarder_right [15:0] ;
wire [ 9:0] target_boarder_top [15:0] ;
wire [ 9:0] target_boarder_bottom [15:0] ;
generate
    genvar i;
        for( i = 0 ; i < 16 ; i = i + 1) begin: voluation//voluation表示循环的实例名称
            assign target_flag[i] = target_pos[i][40];
            assign target_bottom[i] = (target_pos[i][39:30] < IMG_VDISP - 1 - MIN_DIST ) ? (target_pos[i][39:30] + MIN_DIST) : IMG_VDISP;
            assign target_right[i]  = (target_pos[i][29:20] < IMG_HDISP - 1 - MIN_DIST ) ? (target_pos[i][29:20] + MIN_DIST) : IMG_HDISP;
            assign target_top[i]    = (target_pos[i][19:10] > 10'd0         + MIN_DIST ) ? (target_pos[i][19:10] - MIN_DIST) : 10'd0;
            assign target_left[i]   = (target_pos[i][ 9: 0] > 10'd0         + MIN_DIST ) ? (target_pos[i][ 9: 0] - MIN_DIST) : 10'd0;

            assign target_boarder_bottom[i] = target_pos[i][39:30]; //下边界的像素坐标
            assign target_boarder_right[i]  = target_pos[i][29:20]; //右边界的像素坐标
            assign target_boarder_top[i]    = target_pos[i][19:10]; //上边界的像素坐标
            assign target_boarder_left[i]   = target_pos[i][ 9: 0]; //左边界的像素坐标
        end
endgenerate

//检测并标记目标需要两个像素时钟 投票
integer j;
reg [ 3:0] target_cnt;
reg [15:0] new_target_flag; //检测到新目标的投票箱
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for( j = 0 ; j < 16 ; j = j + 1) begin
            target_pos[j] <= {1'b0,10'd0,10'd0,10'd0,10'd0};
        end
        new_target_flag <= 16'd0;
        target_cnt <= 4'd0;
    end
    //在一帧开始的时候进行初始化
    else if(vsync_pos_flag) begin
        for (j = 0; j < 16  ; j = j + 1) begin
            target_pos[j] <= {1'b0,10'd0,10'd0,10'd0,10'd0};
        end
        new_target_flag <= 16'd0;
        target_cnt <= 4'd0;
    end
    else begin
        //第一个时钟周期，找出标记为运动目标的像素点，由运动目标列表中的元素进行投票，判断是否为全新的运动目标
        if(per_frame_clken && per_img_Bit) begin
            for (j = 0; j < 16 ; j = j + 1 ) begin
                if(target_flag[j] == 1'b0) //运动目标列表中的数据无效，则该元素投票认定输入的灰度为新的最大值
                    begin
                        new_target_flag[j] <= 1'b1;
                    end
                else 
                    begin
                        if((x_cnt < target_left[j])||(x_cnt > target_right[j])||(y_cnt < target_top[j])||(y_cnt > target_bottom[j]))
                            begin
                                new_target_flag[j] <= 1'b1;
                            end
                        else 
                            begin
                                new_target_flag[j] <= 1'b0;
                            end
                    end
            end
        end
        else begin
            new_target_flag <= 16'd0;
        end
        //第二个时钟周期，根据投票结果，将候选数据更新到运动目标列表中
        if(per_frame_clken_r && per_img_Bit_r) begin
            if(new_target_flag == 16'hffff) begin
                target_pos[target_cnt] <= {1'b1,y_cnt_r,x_cnt_r,y_cnt_r,x_cnt_r};
                target_cnt <= target_cnt + 1'b1;
            end
            else if (new_target_flag > 16'd0) begin
                for( j = 0 ; j > 16; j = j+1) begin
                    if(new_target_flag[j] == 1'b1) begin
                        target_pos[j][40]   <= 1'b1;
                        if(x_cnt_r < target_pos[j][ 9: 0])
                            target_pos[j][ 9: 0] <= x_cnt_r;
                        if(x_cnt_r < target_pos[j][29:20])
                            target_pos[j][29:20] <= x_cnt_r;
                        if(y_cnt_r < target_pos[j][19:10])
                            target_pos[j][19:10] <= y_cnt_r;
                        if(y_cnt_r < target_pos[j][39:30])
                            target_pos[j][39:30] <= y_cnt_r;
                    end
                end
            end
        end
    end
end

integer k;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for( k = 0 ; k < 16 ; k = k + 1) begin
            target_pos_out[k] <= {1'b0,10'd0,10'd0,10'd0,10'd0};
        end
    end
    else if(vsync_pos_flag) begin
        for( k = 0 ; k < 16 ; k = k + 1) begin
            target_pos_out[k] <= target_pos[k];
        end
    end
end

endmodule