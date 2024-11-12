//************************************************
// Author       : Jack
// Create Date  : 2023-04-28 16:33:04
// File Name    : arp.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module arp #(
    parameter BOARD_MAC     = 48'h00_11_22_33_44_55         , //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_IP      = {8'd192, 8'd168, 8'd1, 8'd10} , //开发板IP地址 192.168.1.10
    parameter DES_MAC       = 48'hff_ff_ff_ff_ff_ff         , //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter DES_IP        = {8'd192, 8'd168, 8'd1, 8'd102}  //目的IP地址 192.168.1.102
)(
    input   wire            sys_rst_n      , //复位信号，低电平有效
    //GMII接口
    input   wire            gmii_rx_clk, //GMII接收数据时钟
    input   wire            gmii_rx_dv , //GMII输入数据有效信号
    input   wire    [7:0]   gmii_rxd   , //GMII输入数据
    input   wire            gmii_tx_clk, //GMII发送数据时钟
    output  wire            gmii_tx_en , //GMII输出数据有效信号
    output  wire    [7:0]   gmii_txd   , //GMII输出数据

    //用户接口
    output  wire            arp_rx_done, //ARP接收完成信号
    output  wire            arp_rx_type, //ARP接收类型 0:请求  1:应答
    output  wire    [47:0]  src_mac    , //接收到目的MAC地址
    output  wire    [31:0]  src_ip     , //接收到目的IP地址
    input   wire            arp_tx_en  , //ARP发送使能信号
    input   wire            arp_tx_type, //ARP发送类型 0:请求  1:应答
    input   wire    [47:0]  des_mac    , //发送的目标MAC地址
    input   wire    [31:0]  des_ip     , //发送的目标IP地址
    output  wire            tx_done      //以太网发送完成信号
);

/****************************wire****************************/
wire            crc_en  ; //CRC开始校验使能
wire            crc_clr ; //CRC数据复位信号
wire    [ 7:0]  crc_d8  ; //输入待校验8位数据
wire    [31:0]  crc_data; //CRC校验数据
wire    [31:0]  crc_next; //CRC下次校验完成数据

/********************combinational logic*********************/
assign crc_d8 = gmii_txd;

/***********************instantiation************************/
//ARP接收模块
arp_rx #(
    .BOARD_MAC          (BOARD_MAC      ),
    .BOARD_IP           (BOARD_IP       )
)u_arp_rx(
    .clk                (gmii_rx_clk    ), // input  模块时钟
    .rst_n              (sys_rst_n      ), // input  模块复位

    .gmii_rx_dv         (gmii_rx_dv     ), // input  GMII 接收数据有效
    .gmii_rxd           (gmii_rxd       ), // input  GMII 接收数据[7:0]
    .arp_rx_done        (arp_rx_done    ), // output ARP 接收完成
    .arp_rx_type        (arp_rx_type    ), // output ARP 接收类型（0请求 or 1应答）
    .src_mac            (src_mac        ), // output 发送端 MAC 地址
    .src_ip             (src_ip         )  // output 发送端 IP 地址
);

//ARP发送模块
arp_tx #(
    .BOARD_MAC          (BOARD_MAC      ),
    .BOARD_IP           (BOARD_IP       ),
    .DES_MAC            (DES_MAC        ),
    .DES_IP             (DES_IP         )
)u_arp_tx(
    .clk                (gmii_tx_clk    ), // input  模块时钟
    .rst_n              (sys_rst_n      ), // input  模块复位

    .arp_tx_en          (arp_tx_en      ), // input  ARP 发送使能
    .arp_tx_type        (arp_tx_type    ), // input  ARP 发送类型（0请求 or 1应答）
    .des_mac            (des_mac        ), // input  接收端 MAC 地址
    .des_ip             (des_ip         ), // input  接收端 IP 地址
    .crc_data           (crc_data       ), // input  CRC 校验数据
    .crc_next           (crc_next[31:24]), // input  CRC 校验数据
    .tx_done            (tx_done        ), // output ARP 发送完成
    .gmii_tx_en         (gmii_tx_en     ), // output GMII 发送数据有效
    .gmii_txd           (gmii_txd       ), // output GMII 发送数据
    .crc_en             (crc_en         ), // output CRC 校验使能
    .crc_clr            (crc_clr        )  // output CRC 校验数据清除
);

//以太网发送CRC校验模块
crc32_d8 u_crc32_d8(
    .clk                (gmii_tx_clk    ),
    .rst_n              (sys_rst_n      ),
    .data               (crc_d8         ),
    .crc_en             (crc_en         ),
    .crc_clr            (crc_clr        ),
    .crc_data           (crc_data       ),
    .crc_next           (crc_next       )
);

endmodule