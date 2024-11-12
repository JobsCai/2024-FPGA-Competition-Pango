`timescale 1ns / 1ps  
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test 
//////////////////////////////////////////////////////////////////////////////////
module ethernet_test(
    input       sys_clk,
    input       key,
    input       rst_n,
    output      phy_rst_n,
    output      start_led,
	output      e_mdc,
	inout       e_mdio,
	output[3:0] rgmii_txd,
	output      rgmii_txctl,
	output      rgmii_txc,
	input[3:0]  rgmii_rxd,
	input       rgmii_rxctl,
	input       rgmii_rxc,
    output      led
//output [15:0] flg,
//output                write_sel,
//output                udp_rec_data_valid,
//output               gmii_tx_clk_test,
//output pll_phase_shft_lock,
//output clk,
//output  al_full,
//output  emp_sum,
// output checksum_wr,
// output [4:0] use_rd,
// output [7:0]           udp_rec_ram_rdata ,
// output [10:0]          udp_rec_ram_read_addr ,
// output [15:0]          udp_rec_data_length 
    );
//assign phy_rst_n=pll_phase_shft_lock;
//assign phy_rst_n=key;
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

/*miim_top miim_top_m0(
	.reset_i            (1'b0),
	.miim_clock_i       (gmii_tx_clk),
	.mdc_o              (e_mdc),
	.mdio_io            (e_mdio),
	.link_up_o          (),                  //link status
	.speed_o            (),                  //link speed
	.speed_override_i   (2'b11)              //11: autonegoation
);
*/	
reset_dly delay_u0(
.clk       (sys_clk        ),
.rst_n     (rst_n ),
.rst_n_dly (phy_rst_n          )
);
util_gmii_to_rgmii util_gmii_to_rgmii_m0(
	.reset(1'b0),
	
	.rgmii_td(rgmii_txd),
	.rgmii_tx_ctl(rgmii_txctl),
	.rgmii_txc(rgmii_txc),
	.rgmii_rd(rgmii_rxd),
	.rgmii_rx_ctl(rgmii_rxctl),
	.gmii_rx_clk(gmii_rx_clk),
	.gmii_txd(gmii_txd),
	.gmii_tx_en(gmii_tx_en),
	.gmii_tx_er(1'b0),
	.gmii_tx_clk(gmii_tx_clk),
	.gmii_crs(gmii_crs),
	.gmii_col(gmii_col),
	.gmii_rxd(gmii_rxd),
    .rgmii_rxc(rgmii_rxc),//add
	.gmii_rx_dv(gmii_rx_dv),
	.gmii_rx_er(gmii_rx_er),
	.speed_selection(speed_selection),
	.duplex_mode(duplex_mode),
    .led(led),
    .pll_phase_shft_lock(pll_phase_shft_lock),
    .clk(clk),
    .sys_clk(sys_clk)
	);

assign gmii_tx_clk_test=~gmii_tx_clk;
wire[15:0] udp_send_data_length;

mac_test mac_test0
(
    .gmii_tx_clk            (gmii_tx_clk),
    .gmii_rx_clk            (gmii_rx_clk) ,
    .rst_n                  (rst_n),
    .start_led                (start_led),
    .push_button            (key),
    .gmii_rx_dv             (gmii_rx_dv),
    .gmii_rxd               (gmii_rxd ),
    .gmii_tx_en             (gmii_tx_en),
    .gmii_txd               (gmii_txd ),
    .udp_send_data_length(udp_send_data_length),
    .write_sel(write_sel),
    .udp_rec_data_valid(udp_rec_data_valid),
    .al_full (al_full),
    .emp_sum (emp_sum),
    .checksum_wr(checksum_wr),
    .use_rd  (use_rd),
    .udp_rec_ram_rdata(udp_rec_ram_rdata) ,
    . udp_rec_ram_read_addr(udp_rec_ram_read_addr) ,
    .udp_rec_data_length(udp_rec_data_length)      
 
); 
endmodule
