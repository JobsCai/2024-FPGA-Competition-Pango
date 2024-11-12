//************************************************
// Author       : Jack
// Create Date  : 2023-04-28 14:21:13
// File Name    : gmii_to_rgmii.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module gmii_to_rgmii(
    //以太网GMII接口
    output  wire            gmii_rx_clk , //GMII接收时钟
    output  wire            gmii_rx_dv  , //GMII接收数据有效信号
    output  wire    [7:0]   gmii_rxd    , //GMII接收数据
    output  wire            gmii_tx_clk , //GMII发送时钟
    input   wire            gmii_tx_en  , //GMII发送数据使能信号
    input   wire    [7:0]   gmii_txd    , //GMII发送数据
    //以太网RGMII接口   
    input   wire            rgmii_rxc   , //RGMII接收时钟
    input   wire            rgmii_rx_ctl, //RGMII接收数据控制信号
    input   wire    [3:0]   rgmii_rxd   , //RGMII接收数据
    output  wire            rgmii_txc   , //RGMII发送时钟
    output  wire            rgmii_tx_ctl, //RGMII发送数据控制信号
    output  wire    [3:0]   rgmii_txd     //RGMII发送数据
);

/********************combinational logic*********************/
assign gmii_tx_clk = gmii_rx_clk;

/***********************instantiation************************/
//RGMII接收
rgmii_rx u_rgmii_rx(
    .rgmii_rxc          (rgmii_rxc      ),
    .rgmii_rx_ctl       (rgmii_rx_ctl   ),
    .rgmii_rxd          (rgmii_rxd      ),
    
    .gmii_rx_clk        (gmii_rx_clk    ),
    .gmii_rx_dv         (gmii_rx_dv     ),
    .gmii_rxd           (gmii_rxd       ),

    .pll_lock           (pll_lock       )
    );

//RGMII发送
rgmii_tx u_rgmii_tx(
    .reset              (1'b0           ),

    .gmii_tx_clk        (gmii_tx_clk    ),
    .gmii_tx_en         (gmii_tx_en     ),
    .gmii_tx_er         (1'b0           ),
    .gmii_txd           (gmii_txd       ),
    
    .rgmii_txc          (rgmii_txc      ),
    .rgmii_tx_ctl       (rgmii_tx_ctl   ),
    .rgmii_txd          (rgmii_txd      )
    );

endmodule