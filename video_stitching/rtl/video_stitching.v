//************************************************
// Author       : Jack
// Create Date  : 2023年4月11日 16:34:01
// File Name    : video_stitching.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************
`timescale 1ns / 1ps
`define UD #1
module video_stitching#(
    parameter SLAVE_ADDR            = 7'b0111100    , // 从器件的地址
    parameter CLK_FREQ              = 26'd50_000_000, // SCCB模块的时钟频率
    parameter SCCB_FREQ             = 18'd250_000   , // SCCB的驱动时钟频率

    parameter CAM_H_PIXEL           = 24'd960       , // 摄像头水平方向像素个数
    parameter CAM_V_PIXEL           = 24'd540       , // 摄像头垂直方向像素个数
    parameter HDMI_H_PIXEL          = 24'd960       , // 摄像头水平方向像素个数
    parameter HDMI_V_PIXEL          = 24'd540       , // 摄像头垂直方向像素个数
    parameter HDMI_RGB_R_WIDTH      = 8             ,
    parameter HDMI_RGB_G_WIDTH      = 8             ,
    parameter HDMI_RGB_B_WIDTH      = 8             ,

    parameter BOARD_MAC             = 48'h00_11_22_33_44_55         , //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_IP              = {8'd192, 8'd168, 8'd1, 8'd10} , //开发板IP地址 192.168.1.10
    parameter DES_MAC               = 48'hff_ff_ff_ff_ff_ff         , //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter DES_IP                = {8'd192, 8'd168, 8'd1, 8'd102}, //目的IP地址 192.168.1.102
    
    parameter CAM_DATA_WIDTH        = 16            ,
    parameter HDMI_DATA_WIDTH       = 24            ,
    parameter ETH_DATA_WIDTH        = 32            ,
    parameter FIFO_DATA_WIDTH       = 32            ,
    parameter MEM_ROW_WIDTH         = 15            ,
    parameter MEM_COL_WIDTH         = 10            ,
    parameter MEM_BANK_WIDTH        = 3             ,
    parameter MEM_DQ_WIDTH          = 32            ,
    parameter MEM_DM_WIDTH          = MEM_DQ_WIDTH/8,
    parameter MEM_DQS_WIDTH         = MEM_DQ_WIDTH/8,
    parameter MEM_BURST_LEN         = 8             ,
    parameter AXI_WRITE_BURST_LEN   = 8             , // 写突发传输长度，支持（1,2,4,8,16）
    parameter AXI_READ_BURST_LEN    = 16            , // 读突发传输长度，支持（1,2,4,8,16）
    parameter AXI_ID_WIDTH          = 4             ,
    parameter AXI_USER_WIDTH        = 1             ,
    
    parameter X_BITS    = 12        , // 行扫描周期位宽
    parameter Y_BITS    = 12        , // 场扫描周期位宽
    
    // 1920x1080@60 148.5MHz
    parameter H_SYNC    = 24'd44    , // 行同步
    parameter H_BACK    = 24'd148   , // 行显示后沿
    parameter H_DISP    = 24'd1920  , // 行有效数据
    parameter H_FRONT   = 24'd88    , // 行显示前沿
    parameter H_TOTAL   = 24'd2200  , // 行扫描周期
    
    parameter V_SYNC    = 24'd5     , // 场同步
    parameter V_BACK    = 24'd36    , // 场显示后沿
    parameter V_DISP    = 24'd1080  , // 场有效数据
    parameter V_FRONT   = 24'd4     , // 场显示前沿
    parameter V_TOTAL   = 24'd1125  ,    // 场扫描周期
    parameter BPS_NUM   = 16'd434 
)(
    input   wire            sys_clk     ,
    input   wire            key_rst_n   ,
    //UART
    input                   uart_rx     ,
    output                  uart_tx     ,
    
    // 摄像头接口
    input   wire            cam_pclk    , // 摄像头数据像素时钟
    input   wire            cam_vsync   , // 摄像头场同步信号
    input   wire            cam_href    , // 摄像头行同步信号
    input   wire    [ 7:0]  cam_data    , // 摄像头数据
    output  wire            cam_rst_n   , // 摄像头复位信号，低电平有效
    output  wire            cam_scl     , // 摄像头SCCB_SCL线
    inout   wire            cam_sda     , // 摄像头SCCB_SDA线
    //摄像头二
    input   wire            cam2_pclk    , // 摄像头数据像素时钟
    input   wire            cam2_vsync   , // 摄像头场同步信号
    input   wire            cam2_href    , // 摄像头行同步信号
    input   wire    [ 7:0]  cam2_data    , // 摄像头数据
    output  wire            cam2_rst_n   , // 摄像头复位信号，低电平有效
    output  wire            cam2_scl     , // 摄像头SCCB_SCL线
    inout   wire            cam2_sda     , // 摄像头SCCB_SDA线
    
    // 以太网 RGMII 接口
    input   wire            eth_rxc         , // RGMII 接收数据时钟
    input   wire            eth_rx_ctl      , // RGMII 输入数据有效信号
    input   wire    [3:0]   eth_rxd         , // RGMII 输入数据
    output  wire            eth_txc         , // RGMII 发送数据时钟
    output  wire            eth_tx_ctl      , // RGMII 输出数据有效信号
    output  wire    [3:0]   eth_txd         , // RGMII 输出数据
    output  wire            eth_rst_n       , // 以太网芯片复位信号，低电平有效
    
    // HDMI 接口
    output  wire            hdmi_rst_n      , // HDMI输出芯片复位
    
    output  wire            hdmi_rx_scl     , // HDMI输入芯片SCL信号
    inout   wire            hdmi_rx_sda     , // HDMI输入芯片SDA信号
    input   wire            hdmi_rx_pix_clk , // HDMI输入芯片时钟
    input   wire            hdmi_rx_vs      , // HDMI输入场同步信号
    input   wire            hdmi_rx_hs      , // HDMI输入行同步信号
    input   wire            hdmi_rx_de      , // HDMI输入数据有效信号
    input   wire    [23:0]  hdmi_rx_data    , // HDMI输入数据
    
    output  wire            hdmi_tx_scl     , // HDMI输出芯片SCL信号
    inout   wire            hdmi_tx_sda     , // HDMI输出芯片SDA信号
    output  wire            hdmi_tx_pix_clk , // HDMI输出芯片时钟
    output  reg             hdmi_tx_vs      , // HDMI输出场同步信号
    output  reg             hdmi_tx_hs      , // HDMI输出行同步信号
    output  reg             hdmi_tx_de      , // HDMI输出数据有效信号
    output  reg     [23:0]  hdmi_tx_data    , // HDMI输出数据
    
    output                                  mem_rst_n       ,
    output                                  mem_ck          ,
    output                                  mem_ck_n        ,
    output                                  mem_cke         ,
    output                                  mem_cs_n        ,
    output                                  mem_ras_n       ,
    output                                  mem_cas_n       ,
    output                                  mem_we_n        ,
    output                                  mem_odt         ,
    output      [MEM_ROW_WIDTH-1:0]         mem_a           ,
    output      [MEM_BANK_WIDTH-1:0]        mem_ba          ,
    inout       [MEM_DQS_WIDTH-1:0]         mem_dqs         ,
    inout       [MEM_DQS_WIDTH-1:0]         mem_dqs_n       ,
    inout       [MEM_DQ_WIDTH-1:0]          mem_dq          ,
    output      [MEM_DM_WIDTH-1:0]          mem_dm          ,
    //======================按键控制=============================
    input							key1			   ,//控制缩小
    input							key2			   ,//控制放大
    input							key3			   ,//控制灰度显示
    input							key4			   ,//控制亮度
    input							key5			   ,
    input							key6			   ,
    input							key7			   ,

    //====================HSST===================================
    input                                i_p_refckn_0              , // 
	input                                i_p_refckp_0              , // 
	input                                i_p_l2rxn                 ,
	input                                i_p_l2rxp                 ,
	input                                i_p_l3rxn                 ,
	input                                i_p_l3rxp                 ,
	output                               o_p_l2txn                 ,
	output                               o_p_l2txp                 ,
	output                               o_p_l3txn                 ,
	output                               o_p_l3txp                 ,
	output wire                          SFP_TX_DISABLE0           ,
	output wire                          SFP_TX_DISABLE1     	   ,
    //
    output  wire            led1        ,
    output  wire            led2        ,
    output  wire            led3        ,
    output  wire            led4        ,
    output  wire            led5        ,
    output  wire            led6        ,
    output  wire            led7        
    //output  wire     [10:0] distance    
    
);
/************************************************************
hsst参数定义
************************************************************/	
wire          i_wtchdg_clr_0 ;
assign        i_wtchdg_clr_0=1'b0;

assign         SFP_TX_DISABLE0       = 1'b0 ;
assign         SFP_TX_DISABLE1       = 1'b0 ;


wire tx0_clk;
wire gt0_txfsmresetdone;
wire gt1_txfsmresetdone;
wire gt2_txfsmresetdone;
wire gt3_txfsmresetdone;
wire[31:0] tx0_data;
wire[3:0] tx0_kchar;
wire tx1_clk;
wire[31:0] tx1_data;
wire[3:0] tx1_kchar; 
wire tx2_clk;
wire[31:0] tx2_data;
wire[3:0] tx2_kchar;
wire tx3_clk;
wire[31:0] tx3_data;
wire[3:0] tx3_kchar;
  
wire rx0_clk;
wire[31:0] rx0_data;
wire[3:0] rx0_kchar;
wire rx1_clk;
wire[31:0] rx1_data ;
wire[3:0] rx1_kchar ;
wire rx2_clk;
wire[31:0] rx2_data ;
wire[3:0] rx2_kchar ;
wire rx3_clk;
wire[31:0] rx3_data;
wire[3:0] rx3_kchar;

reg[31:0] gt_tx_data ;
reg[3:0] gt_tx_ctrl ;

wire[31:0] gt_tx_data0 /*synthesis   PAP_MARK_DEBUG ="1"*/;
wire[3:0] gt_tx_ctrl0 ;
wire[31:0] gt_tx_data1 ;
wire[3:0] gt_tx_ctrl1 ;

wire rx_clk;
wire tx_clk;
wire[31:0] rx_data   ;
wire[3:0] rx_kchar   ;

assign tx_clk = tx2_clk;
assign rx_clk = rx3_clk;
assign rx_data = rx2_data;
assign rx_kchar = rx2_kchar;
/*
assign tx0_data = gt_tx_data;
assign tx0_kchar = gt_tx_ctrl;
*/
/*
assign tx1_data = gt_tx_data;
assign tx1_kchar = gt_tx_ctrl;
*/
/*
assign tx2_data = gt_tx_data;
assign tx2_kchar = gt_tx_ctrl;
*/
assign tx3_data = gt_tx_data;
assign tx3_kchar = gt_tx_ctrl;
/****************************wire****************************/
wire                            cam_init_done   ;
wire                            sys_init_done   ;
wire                            cam_frame_vsync ;
wire                            cam_frame_href  ;
wire                            cam_frame_valid ;
wire    [CAM_DATA_WIDTH-1:0]    cam_frame_data  ;
wire    [HDMI_RGB_R_WIDTH-1:0]  cam_data_r      ;
wire    [HDMI_RGB_G_WIDTH-1:0]  cam_data_g      ;
wire    [HDMI_RGB_B_WIDTH-1:0]  cam_data_b      ;

wire                            cam2_init_done   ;
wire                            sys2_init_done   ;
wire                            cam2_frame_vsync ;
wire                            cam2_frame_href  ;
wire                            cam2_frame_valid ;
wire    [CAM_DATA_WIDTH-1:0]    cam2_frame_data  ;
wire    [HDMI_RGB_R_WIDTH-1:0]  cam2_data_r      ;
wire    [HDMI_RGB_G_WIDTH-1:0]  cam2_data_g      ;
wire    [HDMI_RGB_B_WIDTH-1:0]  cam2_data_b      ;

wire    [HDMI_RGB_R_WIDTH-1:0]  cam_data_r_1    /*synthesis syn_keep=1*/ ;
wire    [HDMI_RGB_G_WIDTH-1:0]  cam_data_g_1    /*synthesis syn_keep=1*/;
wire    [HDMI_RGB_B_WIDTH-1:0]  cam_data_b_1    /*synthesis syn_keep=1*/;
wire                   [23:0]   cam_wr_data_1   /*synthesis syn_keep=1*/;

wire    [HDMI_RGB_R_WIDTH-1:0]  cam_data_r_2    /*synthesis syn_keep=1*/ ;
wire    [HDMI_RGB_G_WIDTH-1:0]  cam_data_g_2    /*synthesis syn_keep=1*/;
wire    [HDMI_RGB_B_WIDTH-1:0]  cam_data_b_2    /*synthesis syn_keep=1*/;
wire                   [23:0]   cam_wr_data_2   /*synthesis syn_keep=1*/;

wire    [HDMI_RGB_R_WIDTH-1:0]  cam_data_r_3    /*synthesis syn_keep=1*/ ;
wire    [HDMI_RGB_G_WIDTH-1:0]  cam_data_g_3    /*synthesis syn_keep=1*/;
wire    [HDMI_RGB_B_WIDTH-1:0]  cam_data_b_3    /*synthesis syn_keep=1*/;
wire                   [23:0]   cam_wr_data_3   /*synthesis syn_keep=1*/;

wire    [HDMI_RGB_R_WIDTH-1:0]  cam_data_r_4    /*synthesis syn_keep=1*/ ;
wire    [HDMI_RGB_G_WIDTH-1:0]  cam_data_g_4    /*synthesis syn_keep=1*/;
wire    [HDMI_RGB_B_WIDTH-1:0]  cam_data_b_4    /*synthesis syn_keep=1*/;
wire                   [23:0]   cam_wr_data_4   /*synthesis syn_keep=1*/;

wire                            eth_rx_clk      ;
wire                            eth_frame_rst   ;
wire                            eth_frame_valid ;
wire    [ETH_DATA_WIDTH-1:0]    eth_frame_data  ;

wire                            ddr_init_done   ;
wire    [FIFO_DATA_WIDTH-1:0]   cam_wr_data     ;
wire    [FIFO_DATA_WIDTH-1:0]   cam2_wr_data     ;
wire    [FIFO_DATA_WIDTH-1:0]   hdmi_wr_data    ;

wire                            pix_req         ;
wire    [FIFO_DATA_WIDTH-1:0]   fifo_rd_data    ;
wire    [HDMI_DATA_WIDTH-1:0]   pix_data        ;
wire                            hdmi_tx_init    ;
wire                            hdmi_rx_init    ;

wire                            fifo_video0_full;
wire                            fifo_video1_full;
wire                            fifo_o_full     ;

wire                            post1_frame_vsync     ;//Sobel处理后的场同步信号
wire                            post1_frame_href      ;
wire                            post1_frame_de        ;//处理后的数据使能
wire    [15:0]                  post1_rgb            /*synthesis   PAP_MARK_DEBUG ="1"*/ ;//处理后的数据

wire                            post2_frame_vsync     ;//Sobel处理后的场同步信号
wire                            post2_frame_href      ;
wire                            post2_frame_de        ;//处理后的数据使能
wire    [15:0]                  post2_rgb             ;//处理后的数据

wire                            post3_frame_vsync     ;//Sobel处理后的场同步信号
wire                            post3_frame_href      ;
wire                            post3_frame_de        ;//处理后的数据使能
wire    [15:0]                  post3_rgb             ;//处理后的数据

wire                            hdmi_frame_vs   ;
wire                            hdmi_frame_hs   ;
wire                            hdmi_frame_valid;
wire    [HDMI_DATA_WIDTH-1:0]   hdmi_frame_data ;

wire                            hdmi_tx_vs_temp ; // HDMI输出场同步信号
wire                            hdmi_tx_hs_temp ; // HDMI输出行同步信号
wire                            hdmi_tx_de_temp ; // HDMI输出数据有效信号
wire    [23:0]                  hdmi_tx_data_temp; // HDMI输出数据
wire    [7:0]                  distance /*synthesis   PAP_MARK_DEBUG ="1"*/;

wire           txu_busy;         //transmitter is free.
wire           rxu_finish;       //receiver is free.
wire    [7:0]  rxu_data;         //the data receive from uart_rx.
                                    
wire    [7:0]  txu_data;         
                                    
wire           txu_en;           //enable transmit.
wire           rxu_en;




assign distance = 1966 / (L_coor - R_coor) ;

/********************combinational logic*********************/
assign sys_init_done    = cam_init_done && ddr_init_done;
assign sys2_init_done   = cam2_init_done && ddr_init_done;

assign hdmi_tx_pix_clk  = hdmi_rx_pix_clk;

assign cam_data_r       = {cam2_frame_data[15:11], cam2_frame_data[13:11]};
assign cam_data_g       = {cam2_frame_data[10: 5], cam2_frame_data[ 6: 5]};
assign cam_data_b       = {cam2_frame_data[ 4: 0], cam2_frame_data[ 2: 0]};


assign cam_wr_data      = {{(FIFO_DATA_WIDTH-HDMI_DATA_WIDTH){1'b0}}, cam_data_r, cam_data_g, cam_data_b};

assign hdmi_wr_data     = {{(FIFO_DATA_WIDTH-HDMI_DATA_WIDTH){1'b0}}, hdmi_frame_data};

assign pix_data         = fifo_rd_data[HDMI_DATA_WIDTH-1:0];

assign led1 = cam_init_done     ;
assign led2 = ddr_init_done     ;
assign led3 = hdmi_tx_init      ;
assign led4 = hdmi_rx_init      ;
assign led5 = fifo_video0_full  ;
assign led6 = fifo_video1_full  ;
//assign led7 = fifo_o_full       ;

/***********************instantiation************************/
/************************************************************
HSST数据处理 利用hdmi进来的数据


    .hdmi_frame_vs          (hdmi_frame_vs      ),
    .hdmi_frame_hs          (hdmi_frame_hs      ),
    .hdmi_frame_valid       (hdmi_frame_valid   ),
    .hdmi_frame_data        (hdmi_frame_data    )
************************************************************/
wire [7:0] r_in /*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [7:0] g_in /*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [7:0] b_in /*synthesis   PAP_MARK_DEBUG ="1"*/;

assign r_in = hdmi_rx_data[23:16];
assign g_in = hdmi_rx_data[15:8];
assign b_in = hdmi_rx_data[7:0];


reg    hdmi_vs_in_d0;
reg    hdmi_vs_in_d1;

always@(posedge hdmi_rx_pix_clk or negedge hdmi_rst_n)    begin
    if(!hdmi_rst_n)
    begin
        hdmi_vs_in_d0    <=    1'd0;
        hdmi_vs_in_d1    <=    1'd0;
    end
    else
    begin
        hdmi_vs_in_d0    <=    hdmi_rx_vs;
        hdmi_vs_in_d1    <=    hdmi_vs_in_d0;
    end
end


wire              hdmi_1_scale_de;
wire    [23:0]    hdmi_1_scale_data /*synthesis   PAP_MARK_DEBUG ="1"*/;
video_scale_process#(
    .PIX_DATA_WIDTH       ( 24 )
)u_video_scale_process_0(
    .video_clk            ( hdmi_rx_pix_clk          ),
    .rst_n                ( hdmi_rst_n             ),
    .frame_sync_n         ( ~hdmi_vs_in_d1       ),
    .video_data_in        ( hdmi_rx_data        ),
    .video_data_valid     ( hdmi_frame_valid     ),
    .video_data_out       ( hdmi_1_scale_data       ),
    .video_data_out_valid ( hdmi_1_scale_de ),
    .video_ready          ( 1'b1          ),
    .video_width_in       ( 1920       ),
    .video_height_in      ( 1080      ),
    .video_width_out      ( 1920      ),
    .video_height_out     ( 1080     )
);
always@(posedge tx_clk)
begin
    gt_tx_data  <= gt_tx_data0;
    gt_tx_ctrl <= gt_tx_ctrl0;           
end

video_packet_send video_packet_send_m0
(
	.rst                        (~hdmi_rst_n                   ),
	.tx_clk                     (tx_clk                      ),
	
	.pclk                       (hdmi_rx_pix_clk                   ),
	.vs                         (hdmi_vs_in_d1                 ),
	.de                         (hdmi_rx_de                 ),
	.vin_data                   ({r_in[7:3],g_in[7:2],b_in[7:3]}),
	.vin_width                  (16'd1920                     ),
	
	.gt_tx_data                 (gt_tx_data0                 ),
	.gt_tx_ctrl                 (gt_tx_ctrl0                 )
);

//32位数据对齐模块
wire[31:0] rx_data_align /* synthesis PAP_MARK_DEBUG="true" */;
wire[3:0] rx_ctrl_align /* synthesis PAP_MARK_DEBUG="true" */;
word_align word_align_m0
(
    .rst                        (~hdmi_rst_n               ),
    .rx_clk                     (rx_clk                  ),
    .gt_rx_data                 (rx_data                 ),
    .gt_rx_ctrl                 (rx_kchar                ),
    .rx_data_align              (rx_data_align           ),
    .rx_ctrl_align              (rx_ctrl_align           )
);


//GTP视频数据解析模块
wire vs_wr;
wire de_wr;
wire[15:0] vout_data_r /* synthesis PAP_MARK_DEBUG="true" */;

video_packet_rec video_packet_rec_m0
(
	.rst                        (~hdmi_rst_n                  ),
	.rx_clk                     (rx_clk                  ),
	.gt_rx_data                 (rx_data_align           ),
	.gt_rx_ctrl                 (rx_ctrl_align           ),
	.vout_width                 (16'd1920                ),
	
	.vs                         (vs_wr                   ),
	.de                         (de_wr                   ),
	.vout_data                  (vout_data_r             )
);

assign cam_data_r_4       = {cam_frame_data[15:11], cam_frame_data[13:11]};
assign cam_data_g_4       = {cam_frame_data[10: 5], cam_frame_data[ 6: 5]};
assign cam_data_b_4       = {cam_frame_data[ 4: 0], cam_frame_data[ 2: 0]};
assign cam_wr_data_4      = {{(FIFO_DATA_WIDTH-HDMI_DATA_WIDTH){1'b0}}, cam_data_r_4, cam_data_g_4, cam_data_b_4};


/************************************************************
hsst模块例化
************************************************************/ 
hsst_core u_hsst_core (
  .i_free_clk(sys_clk),                        // input
  .i_pll_rst_0(~hdmi_rst_n),                      // input
  .i_wtchdg_clr_0(i_wtchdg_clr_0),                // input
  .o_wtchdg_st_0(o_wtchdg_st_0),                  // output [1:0]
  .o_txlane_done_2(o_txlane_done_2),              // output
  .o_rxlane_done_3(o_rxlane_done_3),              // output
  .i_p_refckn_0(i_p_refckn_0),                    // input
  .i_p_refckp_0(i_p_refckp_0),                    // input
  .o_p_clk2core_tx_2(tx2_clk),         			 // output
  .i_p_tx2_clk_fr_core(tx2_clk),      			// input
  .i_p_tx3_clk_fr_core(tx2_clk),      			// input
  .o_p_clk2core_rx_2(rx3_clk),          		// output
  .i_p_rx2_clk_fr_core(rx3_clk),      			// input
  .i_p_rx3_clk_fr_core(rx3_clk),      			// input
  .i_p_l2rxn(i_p_l2rxn),                          // input
  .i_p_l2rxp(i_p_l2rxp),                          // input
  .i_p_l3rxn(i_p_l3rxn),                          // input
  .i_p_l3rxp(i_p_l3rxp),                          // input
  .o_p_l2txn(o_p_l2txn),                          // output
  .o_p_l2txp(o_p_l2txp),                          // output
  .o_p_l3txn(o_p_l3txn),                          // output
  .o_p_l3txp(o_p_l3txp),                          // output
  .i_txd_2(tx2_data),                              // input [31:0]
  .i_tdispsel_2(4'b0),                    // input [3:0]
  .i_tdispctrl_2(4'b0),                  // input [3:0]
  .i_txk_2(tx2_kchar),                              // input [3:0]
  .i_txd_3(tx3_data),                              // input [31:0]
  .i_tdispsel_3(4'b0),                    // input [3:0]
  .i_tdispctrl_3(4'b0),                  // input [3:0]
  .i_txk_3(tx3_kchar),                              // input [3:0]
  .o_rxd_2(rx2_data),                              // output [31:0]
  .o_rxk_2(rx2_kchar),                              // output [3:0]
  .o_rxd_3(rx3_data),                              // output [31:0]
  .o_rxk_3(rx3_kchar)                               // output [3:0]
);
/*****************************************************************/


Camera_top #(
    .SLAVE_ADDR             (SLAVE_ADDR         ), // 从器件的地址
    .CLK_FREQ               (CLK_FREQ           ), // SCCB模块的时钟频率
    .SCCB_FREQ              (SCCB_FREQ          ), // SCCB的驱动时钟频率
    .CAM_H_PIXEL            (CAM_H_PIXEL        ), // 摄像头水平方向像素个数
    .CAM_V_PIXEL            (CAM_V_PIXEL        )  // 摄像头垂直方向像素个数
)u_Camera_top(
    .sys_clk                (sys_clk            ), // input
    .sys_rst_n              (key_rst_n          ), // input
    .cam_init_done          (cam_init_done      ), // output 摄像头完成复位
    .sys_init_done          (sys_init_done      ), // input  DDR3和摄像头都完成复位
    
    .cam_pclk               (cam_pclk           ), // 摄像头数据像素时钟
    .cam_vsync              (cam_vsync          ), // 摄像头场同步信号
    .cam_href               (cam_href           ), // 摄像头行同步信号
    .cam_data               (cam_data           ), // 摄像头数据
    .cam_rst_n              (cam_rst_n          ), // 摄像头复位信号，低电平有效
    .cam_scl                (cam_scl            ), // 摄像头SCCB_SCL线
    .cam_sda                (cam_sda            ), // 摄像头SCCB_SDA线
    
    .cam_frame_vsync        (cam_frame_vsync    ), // output 帧有效信号
    .cam_frame_href         (cam_frame_href     ), // output 行有效信号
    .cam_frame_valid        (cam_frame_valid    ), // output 数据有效使能信号
    .cam_frame_data         (cam_frame_data     )  // output 有效数据
);

Camera_top #(
    .SLAVE_ADDR             (SLAVE_ADDR         ), // 从器件的地址
    .CLK_FREQ               (CLK_FREQ           ), // SCCB模块的时钟频率
    .SCCB_FREQ              (SCCB_FREQ          ), // SCCB的驱动时钟频率
    .CAM_H_PIXEL            (CAM_H_PIXEL        ), // 摄像头水平方向像素个数
    .CAM_V_PIXEL            (CAM_V_PIXEL        )  // 摄像头垂直方向像素个数
)u_Camera2_top(
    .sys_clk                (sys_clk            ), // input
    .sys_rst_n              (key_rst_n          ), // input
    .cam_init_done          (cam2_init_done      ), // output 摄像头完成复位
    .sys_init_done          (sys2_init_done      ), // input  DDR3和摄像头都完成复位
    
    .cam_pclk               (cam2_pclk           ), // 摄像头数据像素时钟
    .cam_vsync              (cam2_vsync          ), // 摄像头场同步信号
    .cam_href               (cam2_href           ), // 摄像头行同步信号
    .cam_data               (cam2_data           ), // 摄像头数据
    .cam_rst_n              (cam2_rst_n          ), // 摄像头复位信号，低电平有效
    .cam_scl                (cam2_scl            ), // 摄像头SCCB_SCL线
    .cam_sda                (cam2_sda            ), // 摄像头SCCB_SDA线
    
    .cam_frame_vsync        (cam2_frame_vsync    ), // output 帧有效信号
    .cam_frame_href         (cam2_frame_href     ), // output 行有效信号
    .cam_frame_valid        (cam2_frame_valid    ), // output 数据有效使能信号
    .cam_frame_data         (cam2_frame_data     )  // output 有效数据
);
//=====================按键控制亮度例化========================
key_ctl key_ctl_top(
    .sys_clk(cam_pclk)            ,
    .sys_rst_n(key_rst_n)   ,  //复位信号
    .key1(key1)			   ,
    .key2(key2)			   ,
    .key3(key3)			   ,
    .key4(key4)			   ,
    .key5(key5)			   ,
    .key6(key6)			   ,
    .key7(key7)			   , 		
    .vs_in (cam_frame_vsync),
    .hs_in (cam_frame_href),
    .de_in (cam_frame_valid),
    .img_data (cam_frame_data),
    .lighter_and_color_hs (post1_frame_href)      ,
    .lighter_and_color_vs (post1_frame_vsync)    ,
    .lighter_and_color_de (post1_frame_de)    ,
    .lighter_and_color_data    (post1_rgb)   
);



wire [10:0] L_coor /*synthesis   PAP_MARK_DEBUG ="1"*/;
wire [10:0] R_coor /*synthesis   PAP_MARK_DEBUG ="1"*/;
Human_top u_Human_top(
    .clk                (cam_pclk       ), 
    .rst_n              (key_rst_n      ),
    //处理前的图像
    .pre_frame_vsync    (cam_frame_vsync),
    .pre_frame_href     (cam_frame_href ),
    .pre_frame_de       (cam_frame_valid),
    .pre_rgb            (cam_frame_data ),

    .post_frame_vsync   (),
    .post_frame_href    (),
    .post_frame_de      (),
    .post_rgb           (),
    .img_r              (cam_data_r_1),
    .img_g              (cam_data_g_1),
    .img_b              (cam_data_b_1),
    .coor_data          (R_coor)
);
Human_top u_Human2_top(
    .clk                (cam2_pclk       ), 
    .rst_n              (key_rst_n      ),
    //处理前的图像
    .pre_frame_vsync    (post1_frame_vsync),
    .pre_frame_href     (post1_frame_href ),
    .pre_frame_de       (post1_frame_de),
    .pre_rgb            (post1_rgb ),

    .post_frame_vsync   (post2_frame_vsync),
    .post_frame_href    (),
    .post_frame_de      (post2_frame_de),
    .post_rgb           (post2_rgb),
    .img_r              (cam_data_r_2),
    .img_g              (cam_data_g_2),
    .img_b              (cam_data_b_2),
    .coor_data          (L_coor)
);

assign cam_wr_data_1 = {cam_data_r_1,cam_data_g_1,cam_data_b_1};
assign cam_wr_data_2 = {cam_data_r_2,cam_data_g_2,cam_data_b_2};
wire [7:0] test;

object_top u_object
(
    .clk               (cam_pclk       ),  // 时钟信号
    .rst_n             (key_rst_n       ),  // 复位信号（低有效）
    //图像处理前的数据接口
    .pre_frame_vsync   (post1_frame_vsync ),  // 处理前场同步信号
    .pre_frame_hsync   (post1_frame_href  ),  // 处理前行同步信号
    .pre_frame_de      (post1_frame_de ),  // 处理前数据输入使能
    .pre_rgb           (post1_rgb  ),  // 处理前RGB565颜色数据

    //图像处理后的数据接口
    .post_frame_vsync  (post3_frame_vsync),  // 处理后场同步信号
    .post_frame_hsync  (  ),  // 处理后行同步信号
    .post_frame_de     (post3_frame_de   ),  // 处理后数据输入使能
    .post_rgb          (post3_rgb        ),    // 处理后RGB565颜色数据
    .test              (test),


    .img_r             (cam_data_r_3),
    .img_g             (cam_data_g_3),
    .img_b             (cam_data_b_3)
);
assign cam_wr_data_3 = {cam_data_r_3,cam_data_g_3,cam_data_b_3};


Ethernet_top #(
    .BOARD_MAC              (BOARD_MAC          ), //开发板MAC地址 00-11-22-33-44-55
    .BOARD_IP               (BOARD_IP           ), //开发板IP地址 192.168.1.10
    .DES_MAC                (DES_MAC            ), //目的MAC地址 ff_ff_ff_ff_ff_ff
    .DES_IP                 (DES_IP             )  //目的IP地址 192.168.1.102
)u_Ethernet_top(
    .sys_clk                (sys_clk            ), // input  系统时钟
    .sys_rst_n              (key_rst_n          ), // input  系统复位信号，低电平有效

    //以太网RGMII接口
    .eth_rxc                (eth_rxc            ), // input  RGMII 接收数据时钟
    .eth_rx_ctl             (eth_rx_ctl         ), // input  RGMII 输入数据有效信号
    .eth_rxd                (eth_rxd            ), // input  RGMII 输入数据
    .eth_txc                (eth_txc            ), // output RGMII 发送数据时钟
    .eth_tx_ctl             (eth_tx_ctl         ), // output RGMII 输出数据有效信号
    .eth_txd                (eth_txd            ), // output RGMII 输出数据
    .eth_rst_n              (eth_rst_n          ), // output 以太网芯片复位信号，低电平有效

    .eth_rx_clk             (eth_rx_clk         ), // output 以太网接收数据时钟
    .eth_frame_valid        (eth_frame_valid    ), // output 以太网数据有效信号
    .eth_frame_data         (eth_frame_data     ), // output 以太网数据
    .eth_frame_rst          (eth_frame_rst      )  // output 以太网帧同步信号
);

DDR3_interface_top #(
    .FIFO_DATA_WIDTH        (FIFO_DATA_WIDTH    ), // FIFO 用户端数据位宽
    .CAM_H_PIXEL            (CAM_H_PIXEL        ), // CAMERA 行像素
    .CAM_V_PIXEL            (CAM_V_PIXEL        ), // CAMERA 列像素
    .HDMI_H_PIXEL           (HDMI_H_PIXEL       ), // HDMI 行像素
    .HDMI_V_PIXEL           (HDMI_V_PIXEL       ), // HDMI 列像素
    .DISP_H                 (H_DISP             ), // 显示的行像素
    .DISP_V                 (V_DISP             ), // 显示的列像素
    
    .MEM_ROW_WIDTH          (MEM_ROW_WIDTH      ), // DDR 行地址位宽
    .MEM_COL_WIDTH          (MEM_COL_WIDTH      ), // DDR 列地址位宽
    .MEM_BANK_WIDTH         (MEM_BANK_WIDTH     ), // DDR BANK地址位宽
    .MEM_BURST_LEN          (MEM_BURST_LEN      ), // DDR 突发传输长度
    
    .AXI_WRITE_BURST_LEN    (AXI_WRITE_BURST_LEN), // 写突发传输长度，支持（1,2,4,8,16）
    .AXI_READ_BURST_LEN     (AXI_READ_BURST_LEN ), // 读突发传输长度，支持（1,2,4,8,16）
    .AXI_ID_WIDTH           (AXI_ID_WIDTH       ), // AXI ID位宽
    .AXI_USER_WIDTH         (AXI_USER_WIDTH     )  // AXI USER位宽
)u_DDR3_interface_top(
    .sys_clk                (sys_clk            ), // input
    .key_rst_n              (key_rst_n          ), // input
    .ddr_init_done          (ddr_init_done      ), // output
    
    .video0_wr_clk          (cam2_pclk            ), // input
    .video0_wr_en           (cam2_frame_valid       ), // input
    .video0_wr_data         (cam_wr_data        ), // input
    .video0_wr_rst          (cam2_frame_vsync    ), // input
    
    .video2_wr_clk          (cam_pclk             ), // input
    .video2_wr_en           (cam_frame_valid       ), // input
    .video2_wr_data         (cam_wr_data_3        ), // input
    .video2_wr_rst          (cam_frame_vsync    ), // input
    
    // .video1_wr_clk          (eth_rx_clk         ), // input
    // .video1_wr_en           (eth_frame_valid    ), // input
    // .video1_wr_data         (eth_frame_data     ), // input
    // .video1_wr_rst          (eth_frame_rst      ), // input

	//.vs                         (vs_wr                   ),
	//.de                         (de_wr                   ),
	//.vout_data                  (vout_data_r             )

    .video1_wr_clk          (cam_pclk     ), // input
    .video1_wr_en           (cam_frame_valid   ), // input
    .video1_wr_data         (cam_wr_data_4       ), // input
    .video1_wr_rst          (cam_frame_vsync   ), // input

    .video3_wr_clk          (hdmi_rx_pix_clk    ), // input
    .video3_wr_en           (hdmi_frame_valid   ), // input
    .video3_wr_data         (hdmi_frame_data       ), // input
    .video3_wr_rst          (hdmi_frame_vs      ), // input
    
    .fifo_rd_clk            (hdmi_tx_pix_clk    ), // input
    .fifo_rd_en             (pix_req            ), // input
    .fifo_rd_data           (fifo_rd_data       ), // output
    .rd_rst                 (hdmi_tx_vs         ), // input
    
    .mem_rst_n              (mem_rst_n          ),
    .mem_ck                 (mem_ck             ),
    .mem_ck_n               (mem_ck_n           ),
    .mem_cke                (mem_cke            ),
    .mem_cs_n               (mem_cs_n           ),
    .mem_ras_n              (mem_ras_n          ),
    .mem_cas_n              (mem_cas_n          ),
    .mem_we_n               (mem_we_n           ),
    .mem_odt                (mem_odt            ),
    .mem_a                  (mem_a              ),
    .mem_ba                 (mem_ba             ),
    .mem_dqs                (mem_dqs            ),
    .mem_dqs_n              (mem_dqs_n          ),
    .mem_dq                 (mem_dq             ),
    .mem_dm                 (mem_dm             ),
    
    .fifo_video0_full       (fifo_video0_full   ),
    .fifo_video1_full       (fifo_video1_full   ),
    .fifo_o_full            (fifo_o_full        )
);
//============================UART
    reg  [7:0] receive_data;
    always @(posedge sys_clk)  receive_data <= distance;
    uart_data_gen uart_data_gen(
        .clk                  (  sys_clk      ),//input             clk,
        .read_data            (  receive_data ),//input      [7:0]  read_data,
        .tx_busy              (  txu_busy      ),//input             tx_busy,
        .write_max_num        (  8'h2        ),//input      [7:0]  write_max_num,
        .write_data           (  txu_data      ),//output reg [7:0]  write_data
        .write_en             (  txu_en        ) //output reg        write_en
    );
    
    //uart transmit data module.
    uart_tx #(
         .BPS_NUM            (  BPS_NUM       ) //parameter         BPS_NUM  =    16'd434
     )
     u_uart_tx(
        .clk                 (  sys_clk         ),// input            clk,               
        .tx_data             (  txu_data       ),// input [7:0]      tx_data,           
        .tx_pluse            (  txu_en         ),// input            tx_pluse,          
        .uart_tx             (  uart_tx       ),// output reg       uart_tx,                                  
        .tx_busy             (  txu_busy       ) // output           tx_busy            
    );                                             
                                               
    //Uart receive data module.                
    uart_rx #(
         .BPS_NUM            (  BPS_NUM       ) //parameter          BPS_NUM  =    16'd434
     )
     u_uart_rx (                        
        .clk                 (  sys_clk           ),// input             clk,                              
        .uart_rx             (  uart_rx       ),// input             uart_rx,            
        .rx_data             (  rxu_data       ),// output reg [7:0]  rx_data,                                   
        .rx_en               (  rxu_en         ),// output reg        rx_en,                          
        .rx_finish           (  rxu_finish     ) // output            rx_finish           
    );                                            
                                                  
    assign led7 = rxu_data;
//=====================================================================
HDMI_top #(
    .CLK_FREQ               (CLK_FREQ           ),
    
    .X_BITS                 (X_BITS             ), // 行扫描周期位宽
    .Y_BITS                 (Y_BITS             ), // 场扫描周期位宽
    
    .H_SYNC                 (H_SYNC             ), // 行同步
    .H_BACK                 (H_BACK             ), // 行显示后沿
    .H_DISP                 (H_DISP             ), // 行有效数据
    .H_FRONT                (H_FRONT            ), // 行显示前沿
    .H_TOTAL                (H_TOTAL            ), // 行扫描周期
    
    .V_SYNC                 (V_SYNC             ), // 场同步
    .V_BACK                 (V_BACK             ), // 场显示后沿
    .V_DISP                 (V_DISP             ), // 场有效数据
    .V_FRONT                (V_FRONT            ), // 场显示前沿
    .V_TOTAL                (V_TOTAL            )  // 场扫描周期
)u_HDMI_top(
    .sys_clk                (sys_clk            ), // input
    .hdmi_tx_pix_clk        (hdmi_tx_pix_clk    ), // input
    .sys_rst_n              (key_rst_n          ), // input
    .ddr_init_done          (ddr_init_done      ), // input
    .hdmi_rx_init           (hdmi_rx_init       ), // output
    .hdmi_tx_init           (hdmi_tx_init       ), // output
    .hdmi_rst_n             (hdmi_rst_n         ), // output
    
    .pix_req                (pix_req            ), // output 显示像素请求
    .pix_data               (pix_data           ), // input  显示像素数据
    
    .hdmi_rx_scl            (hdmi_rx_scl        ), // output
    .hdmi_rx_sda            (hdmi_rx_sda        ), // output
    
    .hdmi_tx_scl            (hdmi_tx_scl        ), // output
    .hdmi_tx_sda            (hdmi_tx_sda        ), // output
    .hdmi_tx_vs             (hdmi_tx_vs_temp    ), // output
    .hdmi_tx_hs             (hdmi_tx_hs_temp    ), // output
    .hdmi_tx_de             (hdmi_tx_de_temp    ), // output
    .hdmi_tx_data           (hdmi_tx_data_temp  )  // output
);

Video_processing_top #(
    .HDMI_DATA_WIDTH        (HDMI_DATA_WIDTH    ),
    .HDMI_RGB_R_WIDTH       (HDMI_RGB_R_WIDTH   ),
    .HDMI_RGB_G_WIDTH       (HDMI_RGB_G_WIDTH   ),
    .HDMI_RGB_B_WIDTH       (HDMI_RGB_B_WIDTH   ),
    .HDMI_H_PIXEL           (H_DISP             ),
    .HDMI_V_PIXEL           (V_DISP             )
)u_Video_processing_top(
    .sys_clk                (sys_clk            ),
    .sys_rst_n              (key_rst_n          ),
    
    .hdmi_pix_clk           (hdmi_rx_pix_clk    ),
    .hdmi_vs                (hdmi_rx_vs         ),
    .hdmi_hs                (hdmi_rx_hs         ),
    .hdmi_de                (hdmi_rx_de         ),
    .hdmi_data              (hdmi_rx_data       ),
    
    .hdmi_frame_vs          (hdmi_frame_vs      ),
    .hdmi_frame_hs          (hdmi_frame_hs      ),
    .hdmi_frame_valid       (hdmi_frame_valid   ),
    .hdmi_frame_data        (hdmi_frame_data    )
);
	//.vs                         (vs_wr                   ),
	//.de                         (de_wr                   ),
	//.vout_data                  (vout_data_r             )
// 输出打一拍
always@(posedge hdmi_tx_pix_clk)
begin
    if(!hdmi_tx_init)
        begin
            hdmi_tx_vs   <= 1'b0;
            hdmi_tx_hs   <= 1'b0;
            hdmi_tx_de   <= 1'b0;
            hdmi_tx_data <=  'd0;
        end
    else
        begin
            hdmi_tx_vs   <= hdmi_tx_vs_temp  ;
            hdmi_tx_hs   <= hdmi_tx_hs_temp  ;
            hdmi_tx_de   <= hdmi_tx_de_temp  ;
            hdmi_tx_data <= hdmi_tx_data_temp;
        end
end

endmodule
