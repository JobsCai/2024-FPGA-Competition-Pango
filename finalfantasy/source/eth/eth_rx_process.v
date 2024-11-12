//输入32位数据  输出24位的RGB数据
//以太网输入数据处理 计算出坐标以及场信号和数据有效，拼接24位RGB
//之后的数据流进入 直接进去使能请求模块 然后去输出图像
module eth_rx_process
(

    input   wire                sys_clk         ,
    input   wire                rst_n           ,

    //以太网数据输入 高位在前
    input   wire    [7:0]       ram_data_in     , 
    input   wire    [7:0]       eth_data1       ,
    input   wire    [7:0]       eth_data2       ,
    input   wire    [7:0]       eth_data3       ,
    input   wire    [7:0]       eth_data4       ,
    input   wire    [7:0]       eth_data5       , 

    input   wire                eth_rx_done     /*synthesis PAP_MARK_DEBUG="1"*/,   //接收32位数据完成 

    output  reg                 change_flag     ,
    output  wire                late_signal     /*synthesis PAP_MARK_DEBUG="1"*/,

    output  wire                data_valid_wire      ,   //输出数据有效
    output  wire                eth_vs          ,   //输出帧信号
    output  wire    [10:0]      x_pos           ,   //横坐标
    output  wire    [10:0]      y_pos           ,   //纵坐标  
    output  wire    [23:0]      eth_hdmi_data       //输出以太网24位rgb数据  
);
//帧有效输出 高电平表示数据有效
assign eth_vs           = frame_begin ;
//输出数据
assign eth_hdmi_data    = eth_data_reg;
//横坐标
assign x_pos            = x_cnt       ;
//纵坐标
assign y_pos            = y_cnt       ;
//wire define
//reg         change_flag     ;    //数据发送标志
//wire    late_signal         /*synthesis PAP_MARK_DEBUG="1"*/   ;
wire    late_signal_x;
assign late_signal   = latence[45];
assign late_signal_x = latence[45];
//数据有效信号
wire    data_valid_wire    /*synthesis PAP_MARK_DEBUG="1"*/;
assign    data_valid_wire    =   (x_cnt != x_cnt_reg && (x_cnt !=0 || x_cnt_reg != 1280)  )?1'b1:1'b0;
//reg define
reg         frame_begin     /*synthesis PAP_MARK_DEBUG="1"*/;    //一帧开始信号
reg         data_valid_reg  /*synthesis PAP_MARK_DEBUG="1"*/;    //数据有效信号
reg         href_begin      /*synthesis PAP_MARK_DEBUG="1"*/;    //行开始信号    
reg         vs_rise_d0      ;    //上升沿
reg         vs_rise_d1      ;    //上升沿
reg         hs_rise_d0      ;    //上升沿
reg         hs_rise_d1      ;    //上升沿
reg         vs_down_d0      ;    //下降沿
reg         vs_down_d1      ;    //下降沿   
reg         locked          /*synthesis PAP_MARK_DEBUG="1"*/;    //锁住x_cnt  
reg [7:0]   ram_data_reg    ;    //ram的数据缓存 
reg [7:0]   ram_data_reg2   ;    //ram的数据缓存 
reg [10:0]  y_cnt           /*synthesis PAP_MARK_DEBUG="1"*/;    //纵坐标计数
reg [10:0]  x_cnt           /*synthesis PAP_MARK_DEBUG="1"*/;    //横坐标计数
reg [10:0]  x_cnt_reg       ;
reg [23:0]  eth_data_reg    /*synthesis PAP_MARK_DEBUG="1"*/;    //拼接好24位RGB数据 
reg [49:0]  latence         ;    //延迟41个时钟周期来同步change bit
reg         late_begin      ;

//延迟41个时钟周期
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        latence <= 50'd0;
    else    if(eth_data4==8'h79 && eth_data3==8'h21 && eth_data2==8'h5e )
        latence <= 50'd0;
    else    if(eth_data2==8'h66 && eth_data3==8'h55 &&  eth_data4 == 8'h4e )
        latence <= 50'd0;
    else    if(eth_data2==8'h2a && eth_data3==8'h7a &&  eth_data4 == 8'h4f )
        latence <= 50'd0;
    else    if(eth_data2==8'h37 && eth_data3==8'h6f &&  eth_data4 == 8'h3b )
        latence <= 50'd0;
    else    if(( x_cnt == 319 || x_cnt == 639 || x_cnt == 959 || x_cnt == 1279) && eth_rx_done)  
        latence <= 50'd0;
    else    if(late_begin)
        latence <= {latence[48:0],1'b1};
    else
        latence <= latence;
end


//判断延迟的开始
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        late_begin <= 1'b0;
    else    if(eth_data4==8'h4e && eth_data3==8'h55 && eth_data2==8'h66 && eth_data1==8'h2f)
        late_begin <= 1'b0;
    else    if(eth_data4==8'h79 && eth_data3==8'h21 && eth_data2==8'h5e && eth_data1==8'h69)
        late_begin <= 1'b0;
    else    if(eth_data4==8'h4f && eth_data3==8'h7a && eth_data2==8'h2a && eth_data1==8'h33)
        late_begin <= 1'b0;
    else    if(eth_data2==8'h37 && eth_data3==8'h6f &&  eth_data4 == 8'h3b )
        late_begin <= 1'b0;
    else    if(eth_data4==8'h55 && eth_data3 == 8'h55 && eth_data2 == 8'h55)
        late_begin <= 1'b1;
    else    if(( x_cnt == 319 || x_cnt == 639 || x_cnt == 959 || x_cnt == 1279) && eth_rx_done)  
        late_begin <= 1'b0;
    else
        late_begin <= late_begin;
end
//判断帧头
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        frame_begin <= 1'b0;
    //检测到帧头 表示一帧开始
    else    //if(eth_rx_done) //接收完一次32位数据 可以不要这个条件 
    begin
        if(eth_data4==8'h4f && eth_data3==8'h7a && eth_data2==8'h2a && eth_data1==8'h33)
            frame_begin <= 1'b1;
        //检测到帧尾 一帧结束     y_cnt
        else    if(eth_data4==8'h79 && eth_data3==8'h21 && eth_data2==8'h5e && eth_data1==8'h69  )
            frame_begin <= 1'b0;
    /*    else    if(y_cnt==959 && eth_rx_done && x_cnt == 1279)
            frame_begin <= 1'b0;*/
        else
            frame_begin <= frame_begin;
    end
  /*  else
        frame_begin <= frame_begin;*/
end 
//打拍
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
    begin
        vs_rise_d0 <= 1'b0; 
        vs_rise_d1 <= 1'b0;
    end 
    else
    begin
        vs_rise_d0 <= frame_begin;
        vs_rise_d1 <= vs_rise_d0;
    end
end

always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
    begin
        hs_rise_d0 <= 1'b0; 
        hs_rise_d1 <= 1'b0;
    end 
    else
    begin
        hs_rise_d0 <= href_begin;
        hs_rise_d1 <= hs_rise_d0;
    end
end

always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
    begin
        vs_down_d0 <= 1'b0;
        vs_down_d1 <= 1'b0;
    end
    else
    begin
        vs_down_d0 <= frame_begin;
        vs_down_d1 <= vs_down_d0;
    end
end

//行有效
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        href_begin <= 1'b0;
    else    if(frame_begin) //接收完成 一帧有效 且接受完32位时判断 
    begin
        //一行开始就拉高 可以用做纵坐标计数 每拉高一次就让纵坐标加1  最后应该是959
        if(eth_data4==8'h3b && eth_data3==8'h6f && eth_data2==8'h37 && eth_data1==8'h49)    //一行开始信号
            href_begin <= 1'b1;
        else    if(x_cnt == 1279 && eth_rx_done)
            href_begin <= 1'b0;
      /* else    if(eth_data4==8'h4e && eth_data3==8'h55 && eth_data2==8'h66 && eth_data1==8'h2f)
            href_begin <= 1'b0;*/
        else
            href_begin <= href_begin ;
    end
    else
        href_begin <= 1'b0;
end


//判断数据是否有效
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        data_valid_reg <= 1'b0;
    else    if(frame_begin  )
    begin
        if(eth_rx_done && eth_data4 == 8'h3b && eth_data3 == 8'h6f && eth_data2 == 8'h37)
            data_valid_reg <= 1'b0;
        else    if(eth_rx_done && eth_data4==8'h4e && eth_data3==8'h55 && eth_data2==8'h66)
            data_valid_reg <= 1'b0;
        else    if(eth_rx_done && eth_data4==8'h79 && eth_data3==8'h21 && eth_data2==8'h5e)
            data_valid_reg <= 1'b0;
        else    if(eth_rx_done) //之后每接收到一个32位数据有效拉高
            data_valid_reg <= 1'b1;
        else
            data_valid_reg <= 1'b0;
    end
    else
        data_valid_reg <= 1'b0;
end

//拼接数据 接收一次要四个时钟周期 
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        eth_data_reg <= 24'd0   ;
    else    if(frame_begin) //一帧数据有效
    begin
        if(eth_rx_done )   //上一旦接收完32位数据 就把数据拼接下来 和数据有效保持同步
            eth_data_reg <= {eth_data2,eth_data3,eth_data4};    //R G B
        else    if(ram_data_reg !=ram_data_reg2 )
            eth_data_reg <= {eth_data2,eth_data3,eth_data4};    //R G B
        else
            eth_data_reg <= 24'd0;
    end
    else
        eth_data_reg <= 24'd0;
end

//缓存一拍 用来比较
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
    begin
        ram_data_reg <= 8'd0;
        ram_data_reg2<= 8'd0;
    end
    else
    begin
        ram_data_reg <= ram_data_in     ;
        ram_data_reg2<= ram_data_reg    ;
    end
end


reg [1:0]    flag;

//每切换一次 就开始一直计数
//0：319  320：639  640：959  960：1279
//让他保证每次到319的时候就不要再加 等到 切换标志到达才继续加
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        change_flag <= 1'b0;
//要锁住等到 
    else    if(ram_data_reg !=ram_data_in )
    begin
        change_flag <= 1'b1;
    end                                         
    //提前一个时钟周期锁住
    else    if(( x_cnt == 319 || x_cnt == 639 || x_cnt == 959 || x_cnt == 1279) &&eth_rx_done)
        change_flag <= 1'b0;
    else    if(eth_data1 == 8'hdd && eth_data2 == 8'hdd)
        change_flag <= 1'b0;
    else
        change_flag <= change_flag;
end

reg    [2:0]    reg_cnt;

//横坐标计数 一行开始 或者计数到1279就清0 接收完成且帧有效就加1 帧有效是最高判断 
//锁住坐标不让坐标增加 
//现在直接判断了 8'h22 导致 一些画面数据 也是 8'h22然后废了
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        locked <= 1'b0;
    //一行开始信号 这是候要区分是不是真正的一行开始信号 这个时候就是真正的行信号 更改一下行信号的开始
    else    if(eth_data2==8'h37 && eth_data3==8'h6f &&  eth_data4 == 8'h3b && ram_data_in ==8'h2b)   
        locked <= 1'b1;
    else    if(ram_data_reg !=ram_data_in )
        locked <= 1'b0;
    else    
        locked <= locked;
end

always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
    begin
        x_cnt <= 11'd0;
        flag  <= 3'd0 ;
        reg_cnt <= 3'd0;
    end
    else    if(frame_begin && href_begin && locked==0) //帧开始 且行有效
    begin    
        if(x_cnt == 1280)
            x_cnt <= 11'd0;       
        if(eth_rx_done && (eth_data1 != 8'hdd || eth_data2 != 8'hdd || eth_data3 != 8'hdd)  && late_signal_x ) //一行开始的上升沿
                x_cnt <= x_cnt + 1'b1;
       /*s else    if(eth_rx_done)
                x_cnt <= x_cnt + 1'b1;*/
        //如果不同 则过两个周期就加1 多延时一个时钟周期保持同步
        //两个人之间相同没变也要加 
      /*  else    if( (ram_data_reg !=ram_data_reg2)  )
        begin
            x_cnt   <= x_cnt + 1'b1;
        end*/
        else
            x_cnt <= x_cnt;
    end
    else
        x_cnt <= 11'd0;
end

//坐标缓存
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
        x_cnt_reg <= 11'd0;
    else
        x_cnt_reg <= x_cnt;
end





//纵坐标计数
//第一次的加一要去掉
reg [1:0]    first_flag;
always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n)
    begin
        y_cnt <= 11'd0;
        first_flag <= 2'd0;
    end
    else    if(frame_begin) //帧开始
    begin   
        if(hs_rise_d0 && (~hs_rise_d1))  //行的上升沿到达一次 就 加一 
        begin
            if(first_flag==0)
            begin
                first_flag <= first_flag + 1'b1;
                y_cnt <= y_cnt;
            end
            else
                y_cnt <= y_cnt + 1'b1;
        end        
        else
            y_cnt <= y_cnt;
    end
    else
    begin
        y_cnt <= 11'd0;
        first_flag <= 2'd0;
    end
end


endmodule









