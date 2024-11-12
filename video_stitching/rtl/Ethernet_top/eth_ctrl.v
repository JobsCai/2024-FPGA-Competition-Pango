//************************************************
// Author       : Jack
// Create Date  : 2023-05-01 20:19:45
// File Name    : eth_ctrl.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module eth_ctrl(
    input   wire            clk             , // 系统时钟
    input   wire            rst_n           , // 系统复位信号，低电平有效
    //ARP相关端口信号
    input   wire            arp_rx_done     , // ARP接收完成信号
    input   wire            arp_rx_type     , // ARP接收类型 0:请求  1:应答
    output  wire            arp_tx_en       , // ARP发送使能信号
    output  wire            arp_tx_type     , // ARP发送类型 0:请求  1:应答
    input   wire            arp_tx_done     , // ARP发送完成信号
    input   wire            arp_gmii_tx_en  , // ARP GMII输出数据有效信号 
    input   wire    [7:0]   arp_gmii_txd    , // ARP GMII输出数据
    //UDP相关端口信号
    input   wire            udp_gmii_tx_en  , // UDP GMII输出数据有效信号
    input   wire    [7:0]   udp_gmii_txd    , // UDP GMII输出数据
    //GMII发送引脚
    output  wire            gmii_tx_en      , // GMII输出数据有效信号
    output  wire    [7:0]   gmii_txd          // UDP GMII输出数据
);

/****************************reg*****************************/
reg             protocol_sw ; // 协议切换信号

/********************combinational logic*********************/
assign arp_tx_en   = arp_rx_done && (arp_rx_type == 1'b0);
assign arp_tx_type = 1'b1; // ARP 发送类型固定为应答
assign gmii_tx_en  = protocol_sw ? udp_gmii_tx_en : arp_gmii_tx_en;
assign gmii_txd    = protocol_sw ? udp_gmii_txd   : arp_gmii_txd  ;

/**************************process***************************/
// 根据 ARP 发送使能/完成信号，切换 GMII 引脚
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        protocol_sw <= 1'b1;
    else if(arp_tx_en)
        protocol_sw <= 1'b0;
    else if(arp_tx_done)
        protocol_sw <= 1'b1;
    else
        protocol_sw <= protocol_sw;
end

endmodule