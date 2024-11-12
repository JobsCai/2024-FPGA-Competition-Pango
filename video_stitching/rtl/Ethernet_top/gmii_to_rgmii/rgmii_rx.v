//************************************************
// Author       : Jack
// Create Date  : 2023-04-28 15:22:05
// File Name    : rgmii_rx.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module rgmii_rx(
    //以太网RGMII接口
    input   wire            rgmii_rxc       , //RGMII接收时钟
    input   wire            rgmii_rx_ctl    , //RGMII接收数据控制信号
    input   wire    [3:0]   rgmii_rxd       , //RGMII接收数据

    //以太网GMII接口
    output  wire            gmii_rx_clk     , //GMII接收时钟
    output  reg             gmii_rx_dv      , //GMII接收数据有效信号
    output  reg     [7:0]   gmii_rxd        , //GMII接收数据

    output  wire            pll_lock    
);

/****************************wire****************************/
wire    [1:0]   gmii_rxdv_t     ; // 两位GMII接收有效信号
wire    [7:0]   gmii_rxd_t      ;

wire    [5:0]   nc_rxdv         ;
wire    [23:0]  nc_rxd          ;

/***********************instantiation************************/
pll_shift u_pll_shift(
    .clkin1     (rgmii_rxc      ), // input
    .pll_lock   (pll_lock       ), // output
    .clkout0    (gmii_rx_clk    )  // output 125MHz 180deg
);

//rgmii_rx_ctl 输入双沿采样
GTP_ISERDES #(
    .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
    .GRS_EN          ("TRUE"),  // 全局复位使能："TRUE"; "FALSE"
    .LRS_EN          ("TRUE")   // 局部复位使能："TRUE"; "FALSE"
)u_GTP_ISERDES(
    .DI              (rgmii_rx_ctl),
    .ICLK            (1'b0        ),
    .DESCLK          (gmii_rx_clk ),
    .RCLK            (gmii_rx_clk ),
    .WADDR           (3'd0        ),
    .RADDR           (3'd0        ),
    .RST             (1'b0        ),
    .DO              ({gmii_rxdv_t[1], gmii_rxdv_t[0], nc_rxdv})
);

// rgmii_rxd 输入双沿采样
genvar i;
generate for (i=0; i<4; i=i+1)
    begin: rxdata_bus
        //输入双沿采样寄存器
        GTP_ISERDES #(
            .ISERDES_MODE    ("IDDR"),  //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
            .GRS_EN          ("TRUE"),  // 全局复位使能："TRUE"; "FALSE"
            .LRS_EN          ("TRUE")   // 局部复位使能："TRUE"; "FALSE"
        )u_iddr_rxd(
            .DI              (rgmii_rxd[i]),
            .ICLK            (1'b0        ),
            .DESCLK          (gmii_rx_clk ),
            .RCLK            (gmii_rx_clk ),
            .WADDR           (3'd0        ),
            .RADDR           (3'd0        ),
            .RST             (1'b0        ),
            .DO              ({gmii_rxd_t[i+4], gmii_rxd_t[i], nc_rxd[6*i+5:6*i]})
        );
    end
endgenerate

/**************************process***************************/
always@(posedge gmii_rx_clk)
begin
    gmii_rxd   <= gmii_rxd_t;
    gmii_rx_dv <= gmii_rxdv_t[0] & gmii_rxdv_t[1];
end

endmodule