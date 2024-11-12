
module util_gmii_to_rgmii (
  reset,
  rgmii_td,
  rgmii_tx_ctl,
  rgmii_txc,
  rgmii_rd,
  rgmii_rx_ctl,
  gmii_rx_clk,
  rgmii_rxc,
  gmii_txd,
  gmii_tx_en,
  gmii_tx_er,
  gmii_tx_clk,
  gmii_crs,
  gmii_col,
  gmii_rxd,
  gmii_rx_dv,
  gmii_rx_er,
  speed_selection,
  duplex_mode,
  led
  );
 output reg            led;
  input           rgmii_rxc;//add
  input           reset;
  output  [ 3:0]  rgmii_td;
  output          rgmii_tx_ctl;
  output          rgmii_txc;
  input   [ 3:0]  rgmii_rd;
  input           rgmii_rx_ctl;
  output           gmii_rx_clk;
  input   [ 7:0]  gmii_txd;
  input           gmii_tx_en;
  input           gmii_tx_er;
  output          gmii_tx_clk;
  output          gmii_crs;
  output          gmii_col;
  output  [ 7:0]  gmii_rxd;
  output          gmii_rx_dv;
  output          gmii_rx_er;
  input  [ 1:0]   speed_selection; // 1x gigabit, 01 100Mbps, 00 10mbps
  input           duplex_mode;     // 1 full, 0 half
  
  wire gigabit;
  wire gmii_tx_clk_s;
  wire gmii_rx_dv_s;

  wire  [ 7:0]    gmii_rxd_s;
  wire            rgmii_rx_ctl_delay;
  wire            rgmii_rx_ctl_s;
  // registers
  reg             tx_reset_d1;
  reg             tx_reset_sync;
  reg             rx_reset_d1;
  reg   [ 7:0]    gmii_txd_r;
  reg             gmii_tx_en_r;
  reg             gmii_tx_er_r;
  reg   [ 7:0]    gmii_txd_r_d1;
  reg             gmii_tx_en_r_d1;
  reg             gmii_tx_er_r_d1;

  reg             rgmii_tx_ctl_r;
  reg   [ 3:0]    gmii_txd_low;
  reg             gmii_col;
  reg             gmii_crs;

  reg  [ 7:0]     gmii_rxd;
  reg             gmii_rx_dv;
  reg             gmii_rx_er;
  wire         padt1     ;
  wire         padt2     ;
  wire         padt3     ;
  wire         padt4     ;
  wire         padt5     ;
  wire         padt6    ;
  wire         stx_txc   ;
  wire         stx_ctr   ;
  wire  [3:0]  stxd_rgm  ;
  assign gigabit        = speed_selection [1];
  assign gmii_tx_clk    = gmii_tx_clk_s;
  assign gmii_tx_clk_s  = gmii_rx_clk;
//test led
reg[28:0] cnt_timer;
  always @(posedge gmii_tx_clk_s)
  begin
  cnt_timer<=cnt_timer+1'b1;
if( cnt_timer==29'h3ffffff)
begin
   led=~led;
    cnt_timer<=29'h0;
end
  end
  /*BUFG bufmr_rgmii_rxc(
    .I(~rgmii_rxc),
    .O(gmii_rx_clk)
   );
*/
//assign gmii_rx_clk=rgmii_rxc;
assign gmii_rx_clk=~rgmii_rxc;
  always @(posedge gmii_rx_clk)
  begin
    gmii_rxd       = gmii_rxd_s;
    gmii_rx_dv     = gmii_rx_dv_s;
    gmii_rx_er     = gmii_rx_dv_s ^ rgmii_rx_ctl_s;
  end

  always @(posedge gmii_tx_clk_s) begin
    tx_reset_d1    <= reset;
    tx_reset_sync  <= tx_reset_d1;
  end

  always @(posedge gmii_tx_clk_s)
  begin
    rgmii_tx_ctl_r = gmii_tx_en_r ^ gmii_tx_er_r;
    gmii_txd_low   = gigabit ? gmii_txd_r[7:4] :  gmii_txd_r[3:0];
    gmii_col       = duplex_mode ? 1'b0 : (gmii_tx_en_r| gmii_tx_er_r) & ( gmii_rx_dv | gmii_rx_er) ;
    gmii_crs       = duplex_mode ? 1'b0 : (gmii_tx_en_r| gmii_tx_er_r| gmii_rx_dv | gmii_rx_er);
  end

  always @(posedge gmii_tx_clk_s) begin
    if (tx_reset_sync == 1'b1) begin
      gmii_txd_r   <= 8'h0;
      gmii_tx_en_r <= 1'b0;
      gmii_tx_er_r <= 1'b0;
    end
    else
    begin
      gmii_txd_r   <= gmii_txd;
      gmii_tx_en_r <= gmii_tx_en;
      gmii_tx_er_r <= gmii_tx_er;
      gmii_txd_r_d1   <= gmii_txd_r;
      gmii_tx_en_r_d1 <= gmii_tx_en_r;
      gmii_tx_er_r_d1 <= gmii_tx_er_r;
    end
  end



  /*ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE")
  ) rgmii_txc_out (
    .Q (rgmii_txc),
    .C (gmii_tx_clk_s),
    .CE(1),
    .D1(1),
    .D2(0),
    .R(tx_reset_sync),
    .S(0));
*/
GTP_OSERDES #(
 .OSERDES_MODE("ODDR"),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
 .WL_EXTEND   ("FALSE"),     //"TRUE"; "FALSE"
 .GRS_EN      ("TRUE"),         //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .TSDDR_INIT  (1'b0)         //1'b0;1'b1
) gtp_ogddr6(
   .DO    (stx_txc),
   .TQ    (padt6),
   .DI    ({7'd0,1'b1}),
   .TI    (4'd0),
   .RCLK  (gmii_tx_clk_s),
   .SERCLK(gmii_tx_clk_s),
   .OCLK  (1'd0),
   .RST   (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft6
(
    
    .I(stx_txc),     
    .T(padt6)  ,
    .O(rgmii_txc)        
);

  /*generate
  genvar i;
  for (i = 0; i < 4; i = i + 1) begin : gen_tx_data
    ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE")
    ) rgmii_td_out (
      .Q (rgmii_td[i]),
      .C (gmii_tx_clk_s),
      .CE(1),
      .D1(gmii_txd_r_d1[i]),
      .D2(gmii_txd_low[i]),
      .R(tx_reset_sync),
      .S(0));
  end
  endgenerate
*/
GTP_OSERDES #(
 .OSERDES_MODE("ODDR"),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
 .WL_EXTEND   ("FALSE"),     //"TRUE"; "FALSE"
 .GRS_EN      ("TRUE"),         //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .TSDDR_INIT  (1'b0)         //1'b0;1'b1
) gtp_ogddr2(
   .DO    (stxd_rgm[3]),
   .TQ    (padt2),
   .DI    ({6'd0,gmii_txd_low[3],gmii_txd_r_d1[3]}),
   .TI    (4'd0),
   .RCLK  (gmii_tx_clk_s),
   .SERCLK(gmii_tx_clk_s),
   .OCLK  (1'd0),
   .RST   (tx_reset_sync)
); 

GTP_OUTBUFT  gtp_outbuft2
(
    
    .I(stxd_rgm[3]),     
    .T(padt2)  ,
    .O(rgmii_td[3])        
);
//---------------------------------------

GTP_OSERDES #(
 .OSERDES_MODE("ODDR"),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
 .WL_EXTEND   ("FALSE"),     //"TRUE"; "FALSE"
 .GRS_EN      ("TRUE"),         //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .TSDDR_INIT  (1'b0)         //1'b0;1'b1
) gtp_ogddr3(
   .DO    (stxd_rgm[2]),
   .TQ    (padt3),
   .DI    ({6'd0,gmii_txd_low[2],gmii_txd_r_d1[2]}),
   .TI    (4'd0),
   .RCLK  (gmii_tx_clk_s),
   .SERCLK(gmii_tx_clk_s),
   .OCLK  (1'd0),
   .RST   (tx_reset_sync)
); 

GTP_OUTBUFT  gtp_outbuft3
(    
    .I(stxd_rgm[2]),     
    .T(padt3)  ,
    .O(rgmii_td[2])        
);
//--------------------------------------

GTP_OSERDES #(
 .OSERDES_MODE("ODDR"),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
 .WL_EXTEND   ("FALSE"),     //"TRUE"; "FALSE"
 .GRS_EN      ("TRUE"),         //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .TSDDR_INIT  (1'b0)         //1'b0;1'b1
) gtp_ogddr4(
   .DO    (stxd_rgm[1]),
   .TQ    (padt4),
   .DI    ({6'd0,gmii_txd_low[1],gmii_txd_r_d1[1]}),
   .TI    (4'd0),
   .RCLK  (gmii_tx_clk_s),
   .SERCLK(gmii_tx_clk_s),
   .OCLK  (1'd0),
   .RST   (tx_reset_sync)
); 

GTP_OUTBUFT  gtp_outbuft4
(
    .I(stxd_rgm[1]),     
    .T(padt4)  ,
    .O(rgmii_td[1])        
);
//--------------------------------------

GTP_OSERDES #(
 .OSERDES_MODE("ODDR"),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
 .WL_EXTEND   ("FALSE"),     //"TRUE"; "FALSE"
 .GRS_EN      ("TRUE"),         //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .TSDDR_INIT  (1'b0)         //1'b0;1'b1
) gtp_ogddr5(
   .DO    (stxd_rgm[0]),
   .TQ    (padt5),
   .DI    ({6'd0,gmii_txd_low[0],gmii_txd_r_d1[0]}),
   .TI    (4'd0),
   .RCLK  (gmii_tx_clk_s),
   .SERCLK(gmii_tx_clk_s),
   .OCLK  (1'd0),
   .RST   (tx_reset_sync)
); 


GTP_OUTBUFT  gtp_outbuft5
(
    
    .I(stxd_rgm[0]),     
    .T(padt5)  ,
    .O(rgmii_td[0])        
);
  /*ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE")
  ) rgmii_tx_ctl_out (
    .Q (rgmii_tx_ctl),
    .C (gmii_tx_clk_s),
    .CE(1),
    .D1(gmii_tx_en_r_d1),
    .D2(rgmii_tx_ctl_r),
    .R(tx_reset_sync),
    .S(0));

  */
GTP_OSERDES #(
 .OSERDES_MODE("ODDR"),  //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
 .WL_EXTEND   ("FALSE"),     //"TRUE"; "FALSE"
 .GRS_EN      ("TRUE"),         //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .TSDDR_INIT  (1'b0)         //1'b0;1'b1
) gtp_ogddr1(
   .DO    (stx_ctr),
   .TQ    (padt1),
   .DI    ({6'd0,rgmii_tx_ctl_r,gmii_tx_en_r_d1}),
   .TI    (4'd0),
   .RCLK  (gmii_tx_clk_s),
   .SERCLK(gmii_tx_clk_s),
   .OCLK  (1'd0),
   .RST   (tx_reset_sync)
); 
GTP_OUTBUFT  gtp_outbuft1
(
    
    .I(stx_ctr),     
    .T(padt1)  ,
    .O(rgmii_tx_ctl)        
);
     
     /* generate
      for (i = 0; i < 4; i = i + 1) begin
        IDDR #(
          .DDR_CLK_EDGE("SAME_EDGE_PIPELINED")
        ) rgmii_rx_iddr (
          .Q1(gmii_rxd_s[i]),
          .Q2(gmii_rxd_s[i+4]),
          .C(gmii_rx_clk),
          .CE(1),
          .D(rgmii_rd[i]),
          .R(0),
          .S(0));
      end
      endgenerate
    
      IDDR #(
        .DDR_CLK_EDGE("SAME_EDGE_PIPELINED")
      ) rgmii_rx_ctl_iddr (
        .Q1(gmii_rx_dv_s),
        .Q2(rgmii_rx_ctl_s),
        .C(gmii_rx_clk),
        .CE(1),
        .D(rgmii_rx_ctl),
        .R(0),
        .S(0));
*/
wire [5:0] nc1;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr1(
  .DI    (rgmii_rd[0]),
  .ICLK  (1'd0      ),
  .DESCLK(gmii_rx_clk    ),
  .RCLK  (gmii_rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (1'b0),
  .DO    ({gmii_rxd_s[4],gmii_rxd_s[0],nc1})
);

wire [5:0] nc2;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr2(
  .DI    (rgmii_rd[1]),
  .ICLK  (1'd0      ),
  .DESCLK(gmii_rx_clk    ),
  .RCLK  (gmii_rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (1'b0),
  .DO    ({gmii_rxd_s[5],gmii_rxd_s[1],nc2})
);

wire [5:0] nc3;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr3(
  .DI    (rgmii_rd[2]),
  .ICLK  (1'd0      ),
  .DESCLK(gmii_rx_clk    ),
  .RCLK  (gmii_rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (1'b0),
  .DO    ({gmii_rxd_s[6],gmii_rxd_s[2],nc3})
);

wire [5:0] nc4;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr4(
  .DI    (rgmii_rd[3]),
  .ICLK  (1'd0      ),
  .DESCLK(gmii_rx_clk    ),
  .RCLK  (gmii_rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (1'b0),
  .DO    ({gmii_rxd_s[7],gmii_rxd_s[3],nc4})
);

wire [5:0] nc5;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr5(
  .DI    (rgmii_rx_ctl),
  .ICLK  (1'd0      ),
  .DESCLK(gmii_rx_clk    ),
  .RCLK  (gmii_rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (1'b0),
  .DO    ({rgmii_rx_ctl_s,gmii_rx_dv_s,nc5})
);

/*wire [5:0] nc6;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr6(
  .DI    (col_rgm    ),
  .ICLK  (1'd0      ),
  .DESCLK(rx_clk    ),
  .RCLK  (rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (rst),
  .DO    ({col_gm,col_gm1,nc6})
);

wire [5:0] nc7;
GTP_ISERDES #(
 .ISERDES_MODE("IDDR"),   //"IDDR","IMDDR","IGDES4","IMDES4","IGDES7","IGDES8","IMDES8"
 .GRS_EN      ("TRUE"),          //"TRUE"; "FALSE"
 .LRS_EN      ("TRUE")           //"TRUE"; "FALSE"
) igddr7(
  .DI    (crs_rgm   ),
  .ICLK  (1'd0      ),
  .DESCLK(rx_clk    ),
  .RCLK  (rx_clk    ),
  .WADDR (3'd0),
  .RADDR (3'd0),
  .RST   (rst),
  .DO    ({crs_gm,crs_gm1,nc7})
);
*/
endmodule
