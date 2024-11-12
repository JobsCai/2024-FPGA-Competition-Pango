module img_data_pkt_2(
    input                 rst_n          ,   //��λ�źţ��͵�ƽ��Ч
    //ͼ������ź�
    input                 cam_pclk       /*synthesis PAP_MARK_DEBUG = "ture"*/,   //����ʱ��
    input                 img_vsync      /*synthesis PAP_MARK_DEBUG = "ture"*/,   //֡ͬ���ź�
    input                 img_data_en    /*synthesis PAP_MARK_DEBUG = "ture"*/,   //������Чʹ���ź�
    input        [15:0]   img_data       ,   //��Ч���� 
    
    input                 transfer_flag  ,   //ͼ��ʼ�����־,1:��ʼ���� 0:ֹͣ����
    //��̫������ź� 
    input                 eth_tx_clk     ,   //��̫������ʱ��
    input                 udp_tx_req     ,   //udp�������������ź�
    input                 udp_tx_done    /*synthesis PAP_MARK_DEBUG = "ture"*/,   //udp������������ź�                               
    output  reg           udp_tx_start_en/*synthesis PAP_MARK_DEBUG = "ture"*/,   //udp��ʼ�����ź�
    output       [31:0]   udp_tx_data    ,   //udp���͵�����
    output  reg  [15:0]   udp_tx_byte_num/*synthesis PAP_MARK_DEBUG = "ture"*/    //udp�������͵���Ч�ֽ���
    );    
    
//parameter define
parameter  CMOS_H_PIXEL = 16'd1280;  //ͼ��ˮƽ����ֱ���
parameter  CMOS_V_PIXEL = 16'd720;  //ͼ��ֱ����ֱ���
//ͼ��֡ͷ,���ڱ�־һ֡���ݵĿ�ʼ
parameter  IMG_FRAME_HEAD = {32'hf0_5a_a5_0f};

reg             img_vsync_d0    /*synthesis PAP_MARK_DEBUG = "ture"*/;  //֡��Ч�źŴ���
reg             img_vsync_d1    /*synthesis PAP_MARK_DEBUG = "ture"*/;  //֡��Ч�źŴ���
reg             neg_vsync_d0    ;  //֡��Ч�ź��½��ش���
                                
reg             wr_sw           ;  //����λƴ�ӵı�־
reg    [15:0]   img_data_d0     ;  //��Чͼ�����ݴ���
reg             wr_fifo_en      ;  //дfifoʹ��
reg    [31:0]   wr_fifo_data    ;  //дfifo����

reg             img_vsync_txc_d0;  //��̫������ʱ������,֡��Ч�źŴ���
reg             img_vsync_txc_d1;  //��̫������ʱ������,֡��Ч�źŴ���
reg             tx_busy_flag    /*synthesis PAP_MARK_DEBUG = "ture"*/;  //����æ�źű�־
                                
//wire define                   
wire            pos_vsync       ;  //֡��Ч�ź�������
wire            neg_vsync       /*synthesis PAP_MARK_DEBUG = "ture"*/;  //֡��Ч�ź��½���
wire            neg_vsynt_txc   ;  //��̫������ʱ������,֡��Ч�ź��½���
wire   [12:0]    fifo_rdusedw    ;  //��ǰFIFO����ĸ���

//*****************************************************
//**                    main code
//*****************************************************

//�źŲ���
assign neg_vsync = img_vsync_d1 & (~img_vsync_d0);
assign pos_vsync = ~img_vsync_d1 & img_vsync_d0;
assign neg_vsynt_txc = ~img_vsync_txc_d1 & img_vsync_txc_d0;

//��img_vsync�ź���ʱ����ʱ������,���ڲ���
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

//�Ĵ�neg_vsync�ź�
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) 
        neg_vsync_d0 <= 1'b0;
    else 
        neg_vsync_d0 <= neg_vsync;
end    

//��wr_sw��img_data_d0�źŸ�ֵ,����λƴ��
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

//��֡ͷ��ͼ������д��FIFO
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        wr_fifo_en <= 1'b0;
        wr_fifo_data <= 1'b0;
    end
    else begin
        if(neg_vsync) begin
            wr_fifo_en <= 1'b1;
            wr_fifo_data <= IMG_FRAME_HEAD;               //֡ͷ
        end
        else if(neg_vsync_d0) begin
            wr_fifo_en <= 1'b1;
            wr_fifo_data <= {CMOS_H_PIXEL,CMOS_V_PIXEL};  //ˮƽ�ʹ�ֱ����ֱ���
        end
        else if(img_data_en && wr_sw) begin
            wr_fifo_en <= 1'b1;
            wr_fifo_data <= {img_data_d0,img_data};       //ͼ������λƴ��,16λת32λ
          end
        else begin
            wr_fifo_en <= 1'b0;
            wr_fifo_data <= 1'b0;        
        end
    end
end

//��̫������ʱ������,��img_vsync�ź���ʱ����ʱ������,���ڲ���
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

//������̫�����͵��ֽ���
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n)
        udp_tx_byte_num <= 1'b0;
    else if(neg_vsynt_txc)
        udp_tx_byte_num <=  16'd8;
    else if(udp_tx_done)    
        udp_tx_byte_num <= {CMOS_H_PIXEL,1'b0};
end

reg    [12:0]    tx_cnt/*synthesis PAP_MARK_DEBUG = "ture"*/;    //�������ݼ���


//������̫�����Ϳ�ʼ�ź�
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;
        tx_cnt       <=    13'd0;
    end
    //��λ��δ����"��ʼ"����ʱ,��̫��������ͼ������
    else if(transfer_flag == 1'b0) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;     
        tx_cnt    <=    13'd0;   
    end
    else begin
        udp_tx_start_en <= 1'b0;
        //��FIFO�еĸ���������Ҫ���͵��ֽ���ʱ
        if(tx_busy_flag == 1'b0 && fifo_rdusedw /*>=udp_tx_byte_num[15:2]*/) begin    //ÿ���оͷ���һ��
            udp_tx_start_en <= 1'b1;                     //��ʼ���Ʒ���һ������
            tx_busy_flag <= 1'b1;

        end
        else if(udp_tx_done || neg_vsynt_txc) 
        begin
            tx_busy_flag <= 1'b0;
        end   

    end
end

//�첽FIFO
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