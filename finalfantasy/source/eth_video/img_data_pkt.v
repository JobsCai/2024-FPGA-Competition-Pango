module img_data_pkt(
    input                 rst_n          ,   //复位信号，低电平有效
    //图像相关信号
    input                 cam_pclk       /*synthesis PAP_MARK_DEBUG = "ture"*/,   //像素时钟
    input                 img_vsync      /*synthesis PAP_MARK_DEBUG = "ture"*/,   //帧同步信号
    input                 img_data_en    /*synthesis PAP_MARK_DEBUG = "ture"*/,   //数据有效使能信号
    input        [15:0]   img_data       ,   //有效数据 
    
    input                 transfer_flag  ,   //图像开始传输标志,1:开始传输 0:停止传输
    //以太网相关信号 
    input                 eth_tx_clk     ,   //以太网发送时钟
    input                 udp_tx_req     ,   //udp发送数据请求信号
    input                 udp_tx_done    /*synthesis PAP_MARK_DEBUG = "ture"*/,   //udp发送数据完成信号                               
    output  reg           udp_tx_start_en/*synthesis PAP_MARK_DEBUG = "ture"*/,   //udp开始发送信号
    output       [31:0]   udp_tx_data    ,   //udp发送的数据
    output  reg  [15:0]   udp_tx_byte_num/*synthesis PAP_MARK_DEBUG = "ture"*/    //udp单包发送的有效字节数
    );    
    
//parameter define
parameter  CMOS_H_PIXEL = 16'd1280;  //图像水平方向分辨率
parameter  CMOS_V_PIXEL = 16'd720;  //图像垂直方向分辨率
//图像帧头,用于标志一帧数据的开始
parameter  IMG_FRAME_HEAD = {32'hf0_5a_a5_0f};

reg             img_vsync_d0    /*synthesis PAP_MARK_DEBUG = "ture"*/;  //帧有效信号打拍
reg             img_vsync_d1    /*synthesis PAP_MARK_DEBUG = "ture"*/;  //帧有效信号打拍
reg             neg_vsync_d0    ;  //帧有效信号下降沿打拍
                                
reg             wr_sw           ;  //用于位拼接的标志
reg    [15:0]   img_data_d0     ;  //有效图像数据打拍
reg             wr_fifo_en      ;  //写fifo使能
reg    [31:0]   wr_fifo_data    ;  //写fifo数据

reg             img_vsync_txc_d0;  //以太网发送时钟域下,帧有效信号打拍
reg             img_vsync_txc_d1;  //以太网发送时钟域下,帧有效信号打拍
reg             tx_busy_flag    /*synthesis PAP_MARK_DEBUG = "ture"*/;  //发送忙信号标志
                                
//wire define                   
wire            pos_vsync       ;  //帧有效信号上升沿
wire            neg_vsync       /*synthesis PAP_MARK_DEBUG = "ture"*/;  //帧有效信号下降沿
wire            neg_vsynt_txc   ;  //以太网发送时钟域下,帧有效信号下降沿
wire   [12:0]    fifo_rdusedw    ;  //当前FIFO缓存的个数

//*****************************************************
//**                    main code
//*****************************************************

//信号采沿
assign neg_vsync = img_vsync_d1 & (~img_vsync_d0);
assign pos_vsync = ~img_vsync_d1 & img_vsync_d0;
assign neg_vsynt_txc = ~img_vsync_txc_d1 & img_vsync_txc_d0;

//对img_vsync信号延时两个时钟周期,用于采沿
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        img_vsync_d0 <= 1'b0;
        img_vsync_d1 <= 1'b0;
    end
    else begin
        img_vsync_d0 <= img_vsync;
        img_vsync_d1 <= img_vsync_d0;
    end
end

//寄存neg_vsync信号
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) 
        neg_vsync_d0 <= 1'b0;
    else 
        neg_vsync_d0 <= neg_vsync;
end    

//对wr_sw和img_data_d0信号赋值,用于位拼接
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        wr_sw <= 1'b0;
        img_data_d0 <= 1'b0;
    end
     else if(neg_vsync)
        wr_sw <= 1'b0;
    else if(img_data_en) begin
        wr_sw <= ~wr_sw;
        img_data_d0 <= img_data;
    end    
end 

//将帧头和图像数据写入FIFO
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        wr_fifo_en <= 1'b0;
        wr_fifo_data <= 1'b0;
    end
    else begin
        if(neg_vsync) begin
            wr_fifo_en <= 1'b1;
            wr_fifo_data <= IMG_FRAME_HEAD;               //帧头
        end
        else if(neg_vsync_d0) begin
            wr_fifo_en <= 1'b1;
            wr_fifo_data <= {CMOS_H_PIXEL,CMOS_V_PIXEL};  //水平和垂直方向分辨率
        end
        else if(img_data_en && wr_sw) begin
            wr_fifo_en <= 1'b1;
            wr_fifo_data <= {img_data_d0,img_data};       //图像数据位拼接,16位转32位
          end
        else begin
            wr_fifo_en <= 1'b0;
            wr_fifo_data <= 1'b0;        
        end
    end
end

//以太网发送时钟域下,对img_vsync信号延时两个时钟周期,用于采沿
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n) begin
        img_vsync_txc_d0 <= 1'b0;
        img_vsync_txc_d1 <= 1'b0;
    end
    else begin
        img_vsync_txc_d0 <= img_vsync;
        img_vsync_txc_d1 <= img_vsync_txc_d0;
    end
end

//控制以太网发送的字节数
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n)
        udp_tx_byte_num <= 1'b0;
    else if(neg_vsynt_txc)
        udp_tx_byte_num <=  16'd8;
    else if(udp_tx_done)    
        udp_tx_byte_num <= {CMOS_H_PIXEL,1'b0};
end

reg    [12:0]    tx_cnt/*synthesis PAP_MARK_DEBUG = "ture"*/;    //发送数据计数


//控制以太网发送开始信号
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;
        tx_cnt       <=    13'd0;
    end
    //上位机未发送"开始"命令时,以太网不发送图像数据
    else if(transfer_flag == 1'b0) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;     
        tx_cnt    <=    13'd0;   
    end
    else begin
        udp_tx_start_en <= 1'b0;
        //当FIFO中的个数满足需要发送的字节数时
        if(tx_busy_flag == 1'b0 && fifo_rdusedw /*>=udp_tx_byte_num[15:2]*/) begin    //每半行就发送一次
            udp_tx_start_en <= 1'b1;                     //开始控制发送一包数据
            tx_busy_flag <= 1'b1;

        end
        else if(udp_tx_done || neg_vsynt_txc) 
        begin
            tx_busy_flag <= 1'b0;
        end   

    end
end

//异步FIFO
async_fifo_1024x32b async_fifo_1024x32b_inst (
  .wr_clk(cam_pclk),                    // input
  .wr_rst(pos_vsync | (~transfer_flag)),                    // input
  .wr_en(wr_fifo_en),                      // input
  .wr_data(wr_fifo_data),                  // input [31:0]
  .wr_full(),                  // output
  .wr_water_level(),    // output [10:0]
  .almost_full(),          // output
  .rd_clk(eth_tx_clk),                    // input
  .rd_rst(pos_vsync | (~transfer_flag)),                    // input
  .rd_en(udp_tx_req),                      // input
  .rd_data(udp_tx_data),                  // output [31:0]
  .rd_empty(),                // output
  .rd_water_level(fifo_rdusedw),    // output [10:0]
  .almost_empty()         // output
);





endmodule