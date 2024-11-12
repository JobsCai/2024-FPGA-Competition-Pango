module image_data(
	input  wire            sys_rst_n        ,
	input  wire            sys_clk          ,
	input  wire            vsync            ,
	input  wire            hsync            ,
	input  wire            rgb_valid        ,
	input  wire    [15:0]  rgb              ,

	input  wire            e_rxclk          ,
	input  wire            eth_tx_req       ,
	output reg             eth_tx_start     ,
	output wire    [31:0]  eth_tx_data      , 
	output wire    [15:0]  eth_tx_data_num
);

wire            fifo_empty      ;   //FIFO读空信号
wire            fifo_empty_fall ;   //FIFO读空信号下降沿
wire [31:0]     fifo_dout       ;
reg             fifo_empty_reg  ;   //fifo读空信号打一拍

reg             hsync_reg       ;
wire            hsync_fall      ;
reg  [23:0]     cnt_h           ;

reg             rgb_valid_r1    ;
reg             rgb_valid_r2    ;
wire            wr_fifo_en      ;
reg [15:0]      rgb_r1          ;
reg [15:0]      rgb_r2          ;
wire[15:0]      wr_fifo_data    ;

wire[11:0]      Wnum            ;
wire[10:0]      Rnum            ;
wire            fifo_full       ;


always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		hsync_reg <= 1'b0;
	else
		hsync_reg <= hsync;
end

assign hsync_fall = ((hsync_reg == 1'b1)&&(hsync == 1'b0));


always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		cnt_h <= 24'd0;
	else if(hsync_fall)
		if(cnt_h==24'd749)
		    cnt_h <= 24'd0;
		else 	
			cnt_h <= cnt_h + 1'b1;
	else
		cnt_h <= cnt_h;
end

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rgb_valid_r1 <= 1'b0;
	    rgb_valid_r2 <= 1'b0;
	end
	else begin
		rgb_valid_r1 <= rgb_valid;
	    rgb_valid_r2 <= rgb_valid_r1;
	end
end

assign wr_fifo_en = (cnt_h == 24'd26)? (rgb_valid || rgb_valid_r2):rgb_valid;

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		rgb_r1 <= 1'b0;
	    rgb_r2 <= 1'b0;
	end
	else begin
		rgb_r1 <= rgb;
	    rgb_r2 <= rgb_r1;
	end
end

assign wr_fifo_data = (cnt_h == 24'd26)?rgb_r2:rgb;

/*
udp_fifo_hs u_fifo(
	.Data(wr_fifo_data), //input [15:0] Data
	.Reset(~sys_rst_n), //input Reset
	.WrClk(sys_clk), //input WrClk
	.RdClk(e_rxclk), //input RdClk
	.WrEn(wr_fifo_en), //input WrEn
	.RdEn(eth_tx_req), //input RdEn
	.Wnum(Wnum), //output [11:0] Wnum
	.Rnum(Rnum), //output [10:0] Rnum
	.Q(fifo_dout), //output [31:0] Q
	.Empty(fifo_empty), //output Empty
	.Full(fifo_full) //output Full
);
*/

always@(posedge e_rxclk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		fifo_empty_reg <= 1'b0;
	else
		fifo_empty_reg <= fifo_empty;
end

assign fifo_empty_fall = ((fifo_empty_reg == 1'b1)&&(fifo_empty == 1'b0));

always@(posedge e_rxclk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		eth_tx_start <= 1'b0;
	else if(fifo_empty_fall)
		eth_tx_start <= 1'b1;
	else
		eth_tx_start <= 1'b0;
end

assign eth_tx_data_num = (cnt_h == 24'd26)? 16'd2564: 16'd2560;

assign eth_tx_data = {fifo_dout[15:0],fifo_dout[31:16]};




endmodule