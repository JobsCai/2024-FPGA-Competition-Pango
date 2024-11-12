`define UD #1
module video_trans_eth_2(
    input              sys_clk   , //系统时钟
    input              sys_rst_n , //系统复位信号，低电平有效
    output             rstn_out    , 
    //PL以太网RGMII接口   
    input              eth_rxc       , //RGMII接收数据时钟
    input              eth_rx_ctl    , //RGMII输入数据有效信号
    input       [3:0]  eth_rxd       , //RGMII输入数据
    output             eth_txc       , //RGMII发送数据时钟    
    output             eth_tx_ctl    , //RGMII输出数据有效信号
    output      [3:0]  eth_txd       , //RGMII输出数据        
	 output              e_mdc                    ,
	 inout               e_mdio                    ,
    output             eth_rst_n    ,//以太网芯片复位信号，低电平有效   

    output             gmii_tx_clk    ,  //GMII发送时钟
    input              udp_tx_start_en,  //以太网开始发送信号   
    input  [31:0]      tx_data        ,  //以太网待发送数据     
    input  [15:0]      tx_byte_num    ,  //以太网发送的有效字节数 单位:byte 
    output             udp_tx_done    ,  //UDP发送完成信号  
    output             tx_req         ,  //读数据请求信号    
           
    output             gmii_rx_clk    ,  //GMII接收时钟 
    output             rec_pkt_done   ,  //UDP单包数据接收完成信号 
    output             rec_en         ,  //UDP接收的数据使能信号          
    output [31:0]      rec_data       ,  //UDP接收的数据
    output [15:0]      rec_byte_num   ,   //UDP接收到的字节数


    //hdmi
   //hdmi_out 
    output            pix_clk       ,//pixclk    297mhz                       
    output     reg           vs_out        , 
    output     reg           hs_out        , 
    output     reg           de_out        ,
    output     reg    [7:0]  r_out         , 
    output     reg    [7:0]  g_out         , 
    output     reg    [7:0]  b_out         ,
    output            iic_tx_scl    ,
    inout             iic_tx_sda    ,
    output            led_int       

    );

//parameter define
//开发板MAC地址 00-11-22-33-44-55
parameter  BOARD_MAC = 48'haa_bb_cc_dd_ee_ff;     
//开发板IP地址 192.168.1.10
parameter  BOARD_IP  = {8'd192,8'd168,8'd3,8'd2};  
//目的MAC地址 ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;    
//目的IP地址 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd3,8'd3};  
              
wire          gmii_rx_clk   ; //GMII接收时钟
wire          gmii_rx_dv    ; //GMII接收数据有效信号
wire  [7:0]   gmii_rxd      ; //GMII接收数据
wire          gmii_tx_clk   ; //GMII发送时钟
wire          gmii_tx_en    ; //GMII发送数据使能信号
wire  [7:0]   gmii_txd      ; //GMII发送数据     

wire          arp_gmii_tx_en; //ARP GMII输出数据有效信号 
wire  [7:0]   arp_gmii_txd  ; //ARP GMII输出数据
wire          arp_rx_done   ; //ARP接收完成信号
wire          arp_rx_type   ; //ARP接收类型 0:请求  1:应答
wire  [47:0]  src_mac       ; //接收到目的MAC地址
wire  [31:0]  src_ip        ; //接收到目的IP地址    
wire          arp_tx_en     ; //ARP发送使能信号
wire          arp_tx_type   ; //ARP发送类型 0:请求  1:应答
wire  [47:0]  des_mac       ; //发送的目标MAC地址
wire  [31:0]  des_ip        ; //发送的目标IP地址   
wire          arp_tx_done   ; //ARP发送完成信号

wire          udp_gmii_tx_en; //UDP GMII输出数据有效信号 
wire  [7:0]   udp_gmii_txd  ; //UDP GMII输出数据
wire          rec_pkt_done  ; //UDP单包数据接收完成信号
wire          rec_en        ; //UDP接收的数据使能信号
wire          eth_rec_en    ; //24位 使能信号   
/*
wire  [31:0]  rec_data      ; //UDP接收的数据
wire  [23:0]  rec_data_24   ; //UDP 24位RGB数据      
wire  [15:0]  rec_byte_num  ; //UDP接收的有效字节数 单位:byte 
wire  [15:0]  tx_byte_num   ; //UDP发送的有效字节数 单位:byte 
wire          udp_tx_done   ; //UDP发送完成信号
wire          tx_req        ; //UDP读数据请求信号
wire  [31:0]  tx_data       ; //UDP待发送数据
wire          tx_start_en   ; //UDP发送开始使能信号*/

//*****************************************************
//**                    HDMI code
//*****************************************************



wire                        pix_clk    ;
wire                        cfg_clk    ;
wire                        locked     ;
wire                        rstn       ;
wire                        init_over  ;
reg  [15:0]                 rstn_1ms   ;



//*****************************************************
//**                    main code
//*****************************************************

/*
assign tx_start_en = rec_pkt_done;
assign tx_byte_num = rec_byte_num;*/
assign des_mac = src_mac;
assign des_ip = src_ip;
assign eth_rst_n = sys_rst_n;
/*
//GMII接口转RGMII接口
gmii_to_rgmii u_gmii_to_rgmii(
    .gmii_rx_clk   (gmii_rx_clk ),
    .gmii_rx_dv    (gmii_rx_dv  ),
    .gmii_rxd      (gmii_rxd    ),
    .gmii_tx_clk   (gmii_tx_clk ),
    .gmii_tx_en    (gmii_tx_en  ),
    .gmii_txd      (gmii_txd    ),
    
    .rgmii_rxc     (eth_rxc     ),
    .rgmii_rx_ctl  (eth_rx_ctl  ),
    .rgmii_rxd     (eth_rxd     ),
    .rgmii_txc     (eth_txc     ),
    .rgmii_tx_ctl  (eth_tx_ctl  ),
    .rgmii_txd     (eth_txd     )
    );

*/
wire            reset_n;
wire   [ 7:0]   gmii_txd;
wire            gmii_tx_en;
wire            gmii_tx_er;
wire            gmii_tx_clk;
wire            gmii_crs;
wire            gmii_col;
wire   [ 7:0]   gmii_rxd;
wire            gmii_rx_dv;
wire            gmii_rx_er;
wire            gmii_rx_clk;
wire  [ 1:0]    speed_selection; // 1x gigabit, 01 100Mbps, 00 10mbps
wire            duplex_mode;     // 1 full, 0 half
wire            rgmii_rxcpll;   
assign speed_selection = 2'b10;
assign duplex_mode = 1'b1;


util_gmii_to_rgmii_2 util_gmii_to_rgmii_m0(
	.reset(1'b0),
	
	.rgmii_td(eth_txd),
	.rgmii_tx_ctl(eth_tx_ctl),
	.rgmii_txc(eth_txc),
	.rgmii_rd(eth_rxd),
	.rgmii_rx_ctl(eth_rx_ctl),
	.gmii_rx_clk(gmii_rx_clk),
	.gmii_txd(gmii_txd),
	.gmii_tx_en(gmii_tx_en),
	.gmii_tx_er(1'b0),
	.gmii_tx_clk(gmii_tx_clk),
	.gmii_crs(gmii_crs),
	.gmii_col(gmii_col),
	.gmii_rxd(gmii_rxd),
    .rgmii_rxc(eth_rxc),//add
	.gmii_rx_dv(gmii_rx_dv),
	.gmii_rx_er(gmii_rx_er),
	.speed_selection(speed_selection),
	.duplex_mode(duplex_mode),
    .led(led),
    .pll_phase_shft_lock(pll_phase_shft_lock),
    .clk(clk),
    .sys_clk(sys_clk)
	);


//ARP通信
video_trans_eth_arp_2                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_video_trans_eth_arp(
    .rst_n         (sys_rst_n  ),

    .gmii_rx_clk   (gmii_rx_clk),
    .gmii_rx_dv    (gmii_rx_dv ),
    .gmii_rxd      (gmii_rxd   ),
    .gmii_tx_clk   (gmii_tx_clk),
    .gmii_tx_en    (arp_gmii_tx_en ),
    .gmii_txd      (arp_gmii_txd),
                    
    .arp_rx_done   (arp_rx_done),
    .arp_rx_type   (arp_rx_type),
    .src_mac       (src_mac    ),
    .src_ip        (src_ip     ),
    .arp_tx_en     (arp_tx_en  ),
    .arp_tx_type   (arp_tx_type),
    .des_mac       (des_mac    ),
    .des_ip        (des_ip     ),
    .tx_done       (arp_tx_done)
    );

//UDP通信
video_trans_eth_udp_2                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
   u_video_trans_eth_arp_udp(
    .rst_n         (sys_rst_n   ),  
    
    .gmii_rx_clk   (gmii_rx_clk ),           
    .gmii_rx_dv    (gmii_rx_dv  ),         
    .gmii_rxd      (gmii_rxd    ),                   
    .gmii_tx_clk   (gmii_tx_clk ), 
    .gmii_tx_en    (udp_gmii_tx_en),         
    .gmii_txd      (udp_gmii_txd),  

    .rec_pkt_done  (rec_pkt_done),    
    .rec_en        (rec_en      ),     
    .eth_rec_en    (eth_rec_en  ),
    .rec_data      (rec_data    ),  
    .rec_data_24   (rec_data_24 ),       
    .rec_byte_num  (rec_byte_num),      
    .tx_start_en   (udp_tx_start_en ),        
    .tx_data       (tx_data     ),         
    .tx_byte_num   (tx_byte_num ),  
    .des_mac       (des_mac     ),
    .des_ip        (des_ip      ),    
    .tx_done       (udp_tx_done ),        
    .tx_req        (tx_req      )           
    ); 
//
/*
eth_process    eth_process_inst
(
	.clk        (gmii_rx_clk),
	.rst_n      (sys_rst_n  ),
	//接收的32位数据分别输入
	.eth_rx1        (rec_data[7:0]),
	.eth_rx2        (rec_data[15:8]),
	.eth_rx3        (rec_data[23:16]),
	.eth_rx4        (rec_data[31:24]),//高位
	.eth_rx01       (rec_data_24[7:0]) ,
	.eth_rx02       (rec_data_24[15:8]) ,
	.eth_rx03       (rec_data_24[23:16]) ,
	.rec_en		    (rec_en),//输入32位数据有效信号
	.eth_rec_en	    (eth_rec_en),//输入24位数据有效信号
	//按键控制frame_cnt复位
	.key            (),
	//32位数据转换为24位数据
	.eth_hdmi_data	(eth_hdmi_data),//输出图像数据
	.eth_vs    		(eth_vs),//输出帧信号
	.eth_hs    		(eth_hs),//输出行信号
	.eth_valid 		(eth_valid),//24位数据有效信号
    .eth_led         (eth_led),
	.xpos			(),//横坐标
	.ypos			() //纵坐标
);


*/




////同步FIFO  
/*
sync_fifo_2048x32b u_sync_fifo_2048x32b (
  .clk             (gmii_rx_clk),   // input
  .rst             (~sys_rst_n),    // input
  .wr_en           (rec_en),        // input
  .wr_data         (rec_data),      // input [31:0]
  .wr_full         (),              // output
  .almost_full     (),              // output
  .rd_en           (tx_req),        // input
  .rd_data         (tx_data),       // output [31:0]
  .rd_empty        (),              // output
  .almost_empty    ()               // output
);
*/
video_trans_eth_ctrl_2 u_video_trans_eth_ctrl(
    .clk            (gmii_rx_clk),
    .rst_n          (sys_rst_n),

    .arp_rx_done    (arp_rx_done   ),
    .arp_rx_type    (arp_rx_type   ),
    .arp_tx_en      (arp_tx_en     ),
    .arp_tx_type    (arp_tx_type   ),
    .arp_tx_done    (arp_tx_done   ),
    .arp_gmii_tx_en (arp_gmii_tx_en),
    .arp_gmii_txd   (arp_gmii_txd  ),
    
    .udp_tx_start_en(udp_tx_start_en   ),
    .udp_tx_done    (udp_tx_done   ),    
    .udp_gmii_tx_en (udp_gmii_tx_en),
    .udp_gmii_txd   (udp_gmii_txd  ),

    .gmii_tx_en     (gmii_tx_en    ),
    .gmii_txd       (gmii_txd      )
    );


endmodule