//************************************************
// Author       : Jack
// Create Date  : 2023-04-28 16:11:31
// File Name    : rgmii_tx.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module rgmii_tx(
    input   wire            reset       ,

    //GMII发送端口
    input   wire            gmii_tx_clk     , // GMII 发送时钟
    input   wire            gmii_tx_en      , // GMII 输出数据有效信号
    input   wire            gmii_tx_er      , // GMII 输出数据错误信号
    input   wire    [7:0]   gmii_txd        , // GMII 输出数据
    
    //RGMII发送端口
    output  wire            rgmii_txc       , //RGMII发送数据时钟
    output  wire            rgmii_tx_ctl    , //RGMII输出数据有效信号
    output  wire    [3:0]   rgmii_txd         //RGMII输出数据
);

/****************************reg*****************************/
reg             r0_reset        ;
reg             r1_reset        ;

reg             r0_gmii_tx_en   ;
reg             r1_gmii_tx_en   ;
reg             r0_gmii_tx_er   ;
reg             r_rgmii_tx_ctl  ;

reg     [7:0]   r0_gmii_txd     ;
reg     [7:0]   r1_gmii_txd     ;

/****************************wire****************************/
wire            stx_txc         ;
wire            stx_ctr         ;
wire    [3:0]   stxd_rgm        ;

wire            padt_txc        ;
wire            padt_ctl        ;
wire    [3:0]   padt_txd        ;

/********************combinational logic*********************/
assign rgmii_txc = gmii_tx_clk;

/***********************instantiation************************/
// gmii_tx_en 输出双沿采样
GTP_OSERDES #(
    .OSERDES_MODE   ("ODDR"         ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
    .WL_EXTEND      ("FALSE"        ),  //"TRUE"; "FALSE"
    .GRS_EN         ("TRUE"         ),  //"TRUE"; "FALSE"
    .LRS_EN         ("TRUE"         ),  //"TRUE"; "FALSE"
    .TSDDR_INIT     (1'b0           )   //1'b0;1'b1
)u_GTP_OSERDES_ctl(
    .RCLK           (gmii_tx_clk    ), // input  输入时钟
    .SERCLK         (gmii_tx_clk    ), // input  串行时钟
    .OCLK           (1'd0           ), // input  数据输出时钟
    .RST            (r1_reset       ), // input  复位信号
    .DI             ({6'd0, r_rgmii_tx_ctl, r1_gmii_tx_en}), // 输入数据
    .TI             (4'd0           ), // input  三态控制输入
    .DO             (stx_ctr        ), // output 输出数据
    .TQ             (padt_ctl       )  // output 三态控制输出
);

GTP_OUTBUFT u_GTP_OUTBUFT_ctl(
    .I              (stx_ctr        ),
    .T              (padt_ctl       ),
    .O              (rgmii_tx_ctl   )
);

// gmii_txd 输出双沿采样
genvar i;
generate for (i=0; i<4; i=i+1)
    begin: txdata_bus
        GTP_OSERDES #( 
            .OSERDES_MODE   ("ODDR"         ),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
            .WL_EXTEND      ("FALSE"        ),  //"TRUE"; "FALSE"
            .GRS_EN         ("TRUE"         ),  //"TRUE"; "FALSE"
            .LRS_EN         ("TRUE"         ),  //"TRUE"; "FALSE"
            .TSDDR_INIT     (1'b0           )   //1'b0;1'b1
        )u_GTP_OSERDES_txd(
            .RCLK           (gmii_tx_clk    ), // input  输入时钟
            .SERCLK         (gmii_tx_clk    ), // input  串行时钟
            .OCLK           (1'd0           ), // input  数据输出时钟
            .RST            (r1_reset       ), // input  复位信号
            .DI             ({6'd0, r1_gmii_txd[i+4], r1_gmii_txd[i]}), // 输入数据
            .TI             (4'd0           ), // input  三态控制输入
            .DO             (stxd_rgm[i]    ), // output 输出数据
            .TQ             (padt_txd[i]    )  // output 三态控制输出
        );
        GTP_OUTBUFT u_GTP_OUTBUFT_txd(
            .I              (stxd_rgm[i]    ),
            .T              (padt_txd[i]    ),
            .O              (rgmii_txd[i]   )
        );
    end
endgenerate

/**************************process***************************/
always@(posedge gmii_tx_clk)
begin
    begin
        r0_reset <= reset   ;
        r1_reset <= r0_reset;
    end
end

always@(posedge gmii_tx_clk)
begin
    if(r1_reset)
        begin
            r0_gmii_tx_en <= 1'b0;
            r0_gmii_tx_er <= 1'b0;
        end
    else
        begin
            r0_gmii_tx_en  <= gmii_tx_en   ;
            r0_gmii_tx_er  <= gmii_tx_er   ;
            r1_gmii_tx_en  <= r0_gmii_tx_en;
            r_rgmii_tx_ctl <= r0_gmii_tx_en ^ r0_gmii_tx_er;
        end
end

always@(posedge gmii_tx_clk)
begin
    if(r1_reset)
        r0_gmii_txd <= 8'd0;
    else
        begin
            r0_gmii_txd <= gmii_txd   ;
            r1_gmii_txd <= r0_gmii_txd;
        end
end

endmodule