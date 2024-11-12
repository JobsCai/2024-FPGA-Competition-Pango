//************************************************
// Author       : Jack
// Create Date  : 2023-05-04 19:50:54
// File Name    : Ethernet_top.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module Ethernet_top #(
    parameter BOARD_MAC     = 48'h00_11_22_33_44_55         , //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_IP      = {8'd192, 8'd168, 8'd1, 8'd10} , //开发板IP地址 192.168.1.10
    parameter DES_MAC       = 48'hff_ff_ff_ff_ff_ff         , //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter DES_IP        = {8'd192, 8'd168, 8'd1, 8'd102}  //目的IP地址 192.168.1.102
)(
    input   wire            sys_clk         , // 系统时钟
    input   wire            sys_rst_n       , // 系统复位信号，低电平有效
    //以太网RGMII接口
    input   wire            eth_rxc         , // RGMII 接收数据时钟
    input   wire            eth_rx_ctl      , // RGMII 输入数据有效信号
    input   wire    [3:0]   eth_rxd         , // RGMII 输入数据
    output  wire            eth_txc         , // RGMII 发送数据时钟
    output  wire            eth_tx_ctl      , // RGMII 输出数据有效信号
    output  wire    [3:0]   eth_txd         , // RGMII 输出数据
    output  wire            eth_rst_n       , // 以太网芯片复位信号，低电平有效

    output  wire            eth_rx_clk      , // 以太网接收数据时钟
    output  wire            eth_frame_valid , // 以太网数据有效信号
    output  wire    [31:0]  eth_frame_data  , // 以太网数据
    output  wire            eth_frame_rst     // 以太网帧同步信号
);

/****************************wire****************************/
wire            gmii_rx_clk     ; // GMII 接收时钟
wire            gmii_rx_dv      ; // GMII 接收数据有效信号
wire    [7:0]   gmii_rxd        ; // GMII 接收数据
wire            gmii_tx_clk     ; // GMII 发送时钟
wire            gmii_tx_en      ; // GMII 发送数据有效信号
wire    [7:0]   gmii_txd        ; // GMII 发送数据

wire            arp_rx_done     ; // ARP 接收完成信号
wire            arp_rx_type     ; // ARP 接收类型 0:请求  1:应答
wire    [47:0]  src_mac         ; // 接收到目的MAC地址
wire    [31:0]  src_ip          ; // 接收到目的IP地址
wire            arp_tx_en       ; // ARP 发送使能信号
wire            arp_tx_type     ; // ARP 发送类型 0:请求  1:应答
wire            arp_tx_done     ; // 以太网发送完成信号
wire    [47:0]  des_mac         ; // 发送的目标MAC地址
wire    [31:0]  des_ip          ; // 发送的目标IP地址


/********************combinational logic*********************/
assign des_mac     = src_mac    ;
assign des_ip      = src_ip     ;
assign eth_rst_n   = sys_rst_n  ;
assign eth_rx_clk  = gmii_rx_clk;

assign arp_tx_en   = arp_rx_done && (arp_rx_type == 1'b0);
assign arp_tx_type = 1'b1; // ARP 发送类型固定为应答

/***********************instantiation************************/
// GMII 接口转 RGMII 接口
gmii_to_rgmii u_gmii_to_rgmii(
    .gmii_rx_clk    (gmii_rx_clk), // output GMII 接收时钟
    .gmii_rx_dv     (gmii_rx_dv ), // output GMII 接收数据有效
    .gmii_rxd       (gmii_rxd   ), // output GMII 接收数据[7:0]
    .gmii_tx_clk    (gmii_tx_clk), // output GMII 发送时钟
    .gmii_tx_en     (gmii_tx_en ), // input  GMII 发送数据有效
    .gmii_txd       (gmii_txd   ), // input  GMII 发送数据[7:0]
    
    .rgmii_rxc      (eth_rxc    ), // input  RGMII 接收时钟
    .rgmii_rx_ctl   (eth_rx_ctl ), // input  RGMII 接收数据有效
    .rgmii_rxd      (eth_rxd    ), // input  RGMII 接收数据[3:0]
    .rgmii_txc      (eth_txc    ), // output RGMII 发送时钟
    .rgmii_tx_ctl   (eth_tx_ctl ), // output RGMII 发送数据有效
    .rgmii_txd      (eth_txd    )  // output RGMII 发送数据[3:0]
);

// ARP通信
arp #(
    .BOARD_MAC      (BOARD_MAC      ),
    .BOARD_IP       (BOARD_IP       ),
    .DES_MAC        (DES_MAC        ),
    .DES_IP         (DES_IP         )
)u_arp(
    .sys_rst_n      (sys_rst_n      ), // input  系统复位

    .gmii_rx_clk    (gmii_rx_clk    ), // output GMII 接收时钟
    .gmii_rx_dv     (gmii_rx_dv     ), // output GMII 接收数据有效
    .gmii_rxd       (gmii_rxd       ), // output GMII 接收数据[7:0]
    .gmii_tx_clk    (gmii_tx_clk    ), // output GMII 发送时钟
    .gmii_tx_en     (gmii_tx_en     ), // input  GMII 发送数据有效
    .gmii_txd       (gmii_txd       ), // input  GMII 发送数据[7:0]

    .arp_rx_done    (arp_rx_done    ), // output ARP 接收完成
    .arp_rx_type    (arp_rx_type    ), // output ARP 接收类型（0请求 or 1应答）
    .src_mac        (src_mac        ), // output ARP 发送端 MAC 地址
    .src_ip         (src_ip         ), // output ARP 发送端 IP 地址
    .arp_tx_en      (arp_tx_en      ), // input  ARP 发送使能
    .arp_tx_type    (arp_tx_type    ), // input  ARP 发送类型（0请求 or 1应答）
    .des_mac        (des_mac        ), // input  ARP 接收端 MAC 地址
    .des_ip         (des_ip         ), // input  ARP 接收端 IP 地址
    .tx_done        (arp_tx_done    )  // output ARP 发送完成
);

udp_rx #(
    .BOARD_MAC      (BOARD_MAC      ),
    .BOARD_IP       (BOARD_IP       )
)u_udp_rx(
    .clk            (gmii_rx_clk    ), // input  模块时钟
    .rst_n          (sys_rst_n      ), // input  模块复位
    .gmii_rx_dv     (gmii_rx_dv     ), // input  GMII 接收数据有效
    .gmii_rxd       (gmii_rxd       ), // input  GMII 接收数据[7:0]

    .rx_start       (eth_frame_rst  ), // output 帧同步信号
    .rx_valid       (eth_frame_valid), // output 接收数据有效
    .rx_data        (eth_frame_data )  // output 以太网接收的数据
);

endmodule