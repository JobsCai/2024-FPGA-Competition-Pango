module video_packet_rec(
	input rst,
	input rx_clk/*synthesis PAP_MARK_DEBUG="1"*/,
	input[31:0] gt_rx_data,
	input[3:0] gt_rx_ctrl,
	input[15:0] vout_width,
	
	output vs,
	output reg de,
	output[15:0] vout_data
);

reg vs_r/*synthesis PAP_MARK_DEBUG="1"*/;
reg[15:0] vs_cnt/*synthesis PAP_MARK_DEBUG="1"*/;

always@(posedge rx_clk or posedge rst)
begin
    if(rst)
        vs_cnt <= 16'd0;
    else if(vs_r)
        vs_cnt <= vs_cnt + 16'd1;
    else
        vs_cnt <= 16'd0;
end

//恢复帧同步信号
always@(posedge rx_clk or posedge rst)
begin
	if(rst)
		vs_r <= 1'b0;
else if(gt_rx_ctrl == 4'b0001 && gt_rx_data == 32'hff_00_00_bc )    
		vs_r <= 1'b1;
	else if(vs_cnt > 20)
		vs_r <= 1'b0;
end
localparam IDLE           = 0;
localparam READ_LINE      = 1;
localparam SEND_LINE_END  = 2;

reg[2:0] state/*synthesis PAP_MARK_DEBUG="1"*/;
reg[15:0] data_cnt;
reg[15:0] wr_cnt;


wire buffer_rd_en;
reg wr_en;
wire[13:0] rd_data_count;
assign buffer_rd_en = (state == READ_LINE);
assign vs = vs_r;

fifo_2048_32i_16o fifo_2048_32i_16o_m0(     
    .wr_clk(rx_clk),
    .wr_rst(vs_r),
    .wr_en(wr_en),
    .wr_data(gt_rx_data),
    .wr_full(),
    .wr_water_level(),
    .almost_full(),
    .rd_clk(rx_clk),
    .rd_rst(vs_r),
    .rd_en(buffer_rd_en),
    .rd_data(vout_data),
    .rd_empty(),
    .rd_water_level(rd_data_count),
    .almost_empty());
always@(posedge rx_clk)
begin
	de <= buffer_rd_en;
end

//解析行同步信号
always@(posedge rx_clk or posedge rst)
begin
	if(rst)
		wr_en <= 1'b0;
	else if(gt_rx_ctrl == 4'b0001 && gt_rx_data == 32'hff_00_02_bc)
		wr_en <= 1'b1;
	else if(wr_cnt == ({1'b0,vout_width[15:1]} - 16'd1))
		wr_en <= 1'b0;
		
end

always@(posedge rx_clk or posedge rst)
begin
	if(rst)
		wr_cnt <= 16'd0;
	else if(wr_en)
		wr_cnt <= wr_cnt + 16'd1;
	else
		wr_cnt <= 16'd0;
end

always@(posedge rx_clk or posedge rst)
begin
	if(rst)
		data_cnt <= 16'd0;
	else if(buffer_rd_en)
		data_cnt <= data_cnt + 16'd1;
	else
		data_cnt <= 16'd0;
end
reg    debugger_flag/*synthesis PAP_MARK_DEBUG="1"*/;
always@(posedge rx_clk or posedge rst)
begin
	if(rst)
	begin
		state <= IDLE;
        debugger_flag<=1'd0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				//if(rd_data_count >= {vout_width[14:0],1'b0})
				if(rd_data_count >= vout_width[15:0])
					state <= READ_LINE;
				else
					state <= IDLE;
			end
			READ_LINE:
			begin    
                 if(vs_r)
                    debugger_flag    <=    1'd1;
				if(data_cnt == (vout_width[15:0]- 16'd1))
					state <= IDLE;
				else
					state <= READ_LINE;
			end
			
		endcase
	end
end

endmodule 