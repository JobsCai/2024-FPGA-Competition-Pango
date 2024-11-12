//////////////////////////////////////////////////////////////////////////////////////
//Module Name : udp_rx
//Description : This module is used to receive UDP data and verify UDP checksum
//
//////////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/1 ns
module udp_rx
(
 input                  clk,   
 input                  rst_n,  
 output        reg      start_led,
 
 input      [7:0]       udp_rx_data,
 input                  udp_rx_req,
 
 input                  mac_rec_error, 
 input      [7:0]       net_protocol,
 input      [31:0]      ip_rec_source_addr,
 input      [31:0]      ip_rec_destination_addr,
 input                  ip_checksum_error,
 input                  ip_addr_check_error,
 
 input      [15:0]      upper_layer_data_length, 
 output     [7:0]       udp_rec_ram_rdata /*synthesis PAP_MARK_DEBUG="1"*/,      //udp ram read data
 (* MARK_DEBUG="true" *)input      [10:0]      udp_rec_ram_read_addr,   //udp ram read address
 (* MARK_DEBUG="true" *)output reg [15:0]      udp_rec_data_length,     //udp data length
 output reg             udp_rec_data_valid       /*synthesis PAP_MARK_DEBUG="1"*/ ,   //udp data valid
 output    [23:0]        eth_hdmi_data,
 output                    eth_vs,
 output                    eth_valid   
);


wire rec_datavalid;     /*synthesis PAP_MARK_DEBUG="1"*/;
assign    rec_datavalid = udp_rec_data_valid;


reg  [15:0]             udp_rx_cnt ;
reg                     verify_end ;
reg                     udp_checksum_error ;  
          
(* MARK_DEBUG="true" *)reg	 [10:0]             ram_write_addr ;
(* MARK_DEBUG="true" *)reg	                    ram_wr_en ;
(* MARK_DEBUG="true" *)reg  [15:0]             udp_data_length ;
reg                     ip_addr_check_error_d0 ;
reg  [7:0]              udp_rx_data_d0  /*synthesis PAP_MARK_DEBUG="1"*/;         //udp data resigster

parameter IDLE             =  8'b0000_0001  ;
parameter REC_HEAD         =  8'b0000_0010  ;
parameter REC_DATA         =  8'b0000_0100  ;
parameter REC_ODD_DATA     =  8'b0000_1000  ;
parameter VERIFY_CHECKSUM  =  8'b0001_0000  ;
parameter REC_ERROR        =  8'b0010_0000  ;
parameter REC_END_WAIT     =  8'b0100_0000  ;
parameter REC_END          =  8'b1000_0000  ;

reg [7:0]     state      ;
reg [7:0]     next_state ;

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    state <= IDLE ;
  else 
    state <= next_state ;
end

always @(*)
begin
    case(state)
	 IDLE            :begin
	                    if (udp_rx_req == 1'b1)
												next_state <= REC_HEAD ;
											else
												next_state <= IDLE ;
										end
	 REC_HEAD       : begin
	                    if (ip_checksum_error)
												next_state <= REC_ERROR ;
                      else if (udp_rx_cnt == 16'd7)
											begin
												if (udp_data_length == 16'd9)
													next_state <= REC_ODD_DATA ;
												else
													next_state <= REC_DATA ;
											end
											else if (ip_addr_check_error_d0)
													next_state <= REC_ERROR ;
											else
	                       next_state <= REC_HEAD ;
	                   end
	 REC_DATA       : begin
	                    if (ip_checksum_error)
												next_state <= REC_ERROR ;
											else if (udp_data_length[0] == 1'b1 && udp_rx_cnt == udp_data_length - 2)
												next_state <= REC_ODD_DATA ;
											else if (udp_data_length[0] == 1'b0 && udp_rx_cnt == udp_data_length - 1)
												next_state <= VERIFY_CHECKSUM ;
											else
	                      next_state <= REC_DATA ;
										end
	 REC_ODD_DATA   : begin
	                    if (ip_checksum_error)
												next_state <= REC_ERROR ;
											else if (udp_rx_cnt == udp_data_length - 1)
												next_state <= VERIFY_CHECKSUM ;
											else
	                      next_state <= REC_ODD_DATA ;
										end
	 VERIFY_CHECKSUM :begin
                      if (udp_checksum_error)
												next_state <= REC_ERROR ;
											else if (verify_end)
												next_state <= REC_END_WAIT ;
											else if (udp_rx_cnt == 16'hffff)
												next_state <= IDLE ;
											else
												next_state <= VERIFY_CHECKSUM ;
										end
	 REC_ERROR      : next_state <= IDLE  ; 
	 REC_END_WAIT   : begin
	                    if (udp_rx_cnt == 16'd63)
                            next_state <= REC_END ;
                        else
	                      next_state <= REC_END_WAIT ;
                       end
	 REC_END        : begin next_state <= IDLE ;  
                      end
	 default        : next_state <= IDLE  ;
	 endcase
end



wire    change_flag;


always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    ram_wr_en <= 1'b0 ;
  else if ((state == REC_DATA || state == REC_ODD_DATA) && udp_rx_cnt < udp_data_length)
    ram_wr_en <= 1'b1 ;
  else
    ram_wr_en <= 1'b0 ;
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    ram_write_addr <= 11'd0 ;
  else if (state == REC_DATA || state == REC_ODD_DATA)
    ram_write_addr <= udp_rx_cnt - 8 ;
  else
    ram_write_addr <= 11'd0 ;
end
//ip address check
always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
	 ip_addr_check_error_d0 <= 1'b0 ;
  else
	 ip_addr_check_error_d0 <= ip_addr_check_error ;
end
//udp data length 
always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    udp_data_length <= 16'd0 ;
  else if (state == IDLE)
    udp_data_length <= upper_layer_data_length ;
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    udp_rec_data_length <= 16'd0 ;
  else if (state == REC_END)
    udp_rec_data_length <= udp_data_length ;
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    udp_rx_cnt <= 16'd0 ;
  else if (state == REC_HEAD || state == REC_DATA  || state == REC_END_WAIT)
    udp_rx_cnt <= udp_rx_cnt + 1'b1 ;
  else
    udp_rx_cnt <= 16'd0 ;
end

reg         late_begin;
reg [40:0]  latence         ;    //延迟41个时钟周期来同步change bit

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
  begin
     udp_rx_data_d0 <= 8'd0 ;
     udp_rx_data_d1 <= 8'd0 ;
     udp_rx_data_d2 <= 8'd0 ;
     udp_rx_data_d3 <= 8'd0 ;
  end
  else
  begin
     udp_rx_data_d0 <= udp_rx_data ;
     udp_rx_data_d1 <= udp_rx_data_d0 ;
     udp_rx_data_d2 <= udp_rx_data_d1 ;
     udp_rx_data_d3 <= udp_rx_data_d2 ; 
  end
end

wire    late_signal;	  
reg change_bit /*synthesis PAP_MARK_DEBUG="1"*/;
//有些数据刚好是一样的 不能用这个去判断了
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        change_bit <= 1'b0;
    else    if(udp_rx_data == 8'hdd && udp_rx_data_d0 == 8'hdd)
        change_bit <= 1'b0;
    //2在最后
  /*  else    if(udp_rx_data_d0==8'h55 && udp_rx_data_d1==8'h55 && udp_rx_data_d2==8'h55 )
        change_bit <= 1'b1;*/
    else    if(udp_rec_ram_rdata != udp_reg_in)
        change_bit <= 1'b1;
    else    if( (x_pos == 318 || x_pos == 638 || x_pos == 958 || x_pos == 1278) &&rx_done )
        change_bit <= 1'b0;
    else
        change_bit <= change_bit;
end

//延迟41个时钟周期
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        latence <= 41'd0;
    else    if(udp_rx_data_d0==8'h22 && udp_rx_data_d1==8'h23 &&  udp_rx_data_d2 == 8'h2b )
        latence[40] <= 1'b0;
    else    if(( x_pos == 319 || x_pos == 639 || x_pos == 959 || x_pos == 1279) && rx_done)  
        latence[40] <= 1'b0;
    else    if(late_begin)
        latence <= {latence[39:0],1'b1};
    else
        latence[40] <= latence[40];
end

//判断延迟的开始
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        late_begin <= 1'b0;
    else    if(udp_rx_data_d0==8'h55 && udp_rx_data_d1==8'h55 && udp_rx_data_d2==8'h55 )
        late_begin <= 1'b1;
    else    if(( x_pos == 318 || x_pos == 638 || x_pos == 958 || x_pos == 1278) && rx_done)  
        late_begin <= 1'b0;
    else
        late_begin <= late_begin;
end



always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    done_cnt <= 3'd0;
  /*else    if(udp_rx_data_d0==8'hdd && udp_rx_data_d1 == 8'hdd  )
    done_cnt <= 3'd0;*/
  else    if(done_cnt == 3'd2)
    done_cnt <= 3'd0;
  else    if(cnt_begin && late_signal)
    done_cnt <= done_cnt + 1'b1;
  else
    done_cnt <= 3'd0;
end

reg [7:0]    udp_reg_in  /*synthesis PAP_MARK_DEBUG="1"*/;


always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
     udp_reg_in <= 8'd0 ;
  else
     udp_reg_in <= udp_rec_ram_rdata ;
end

udp_rx_ram_8_2048 udp_rx_ram_inst(
    .wr_data(udp_rx_data_d0),
    .wr_addr(ram_write_addr),
    .wr_en(ram_wr_en),
    .wr_clk(clk),
    .wr_rst(~rst_n),
    .rd_addr(udp_rec_ram_read_addr),
    .rd_data(udp_rec_ram_rdata),
    .rd_clk(clk),
    .rd_rst(~rst_n));


reg    [7:0]    udp_rx_data_d1;
reg    [7:0]    udp_rx_data_d2;
reg    [7:0]    udp_rx_data_d3;
reg    [7:0]    udp_rx_data_d4;

reg    [2:0]    done_cnt     /*synthesis PAP_MARK_DEBUG="1"*/;
reg             rx_done      /*synthesis PAP_MARK_DEBUG="1"*/;
reg             cnt_begin;


wire            data_valid    ;
wire  [10:0]    x_pos         ;
wire  [10:0]    y_pos         ;
        
//led 
//接收到 开始信号 开始计数
always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
  begin
    start_led <= 1'b0;
    cnt_begin <= 1'b0;
  end
  else    if(udp_rx_data==8'h33 && udp_rx_data_d0== 8'h2a && udp_rx_data_d1==8'h7a && udp_rx_data_d2==8'h4f)
  begin  
    start_led <= 1'b1;
    cnt_begin <= 1'b1;
  end
  else    if(udp_rx_data==8'h69 && udp_rx_data_d0== 8'h5e && udp_rx_data_d1==8'h21 && udp_rx_data_d2==8'h79)  
  begin      
    start_led <= 1'b0;
    cnt_begin <= 1'b0;    
  end
  else
  begin
    start_led <= start_led;
    cnt_begin <= cnt_begin;
  end
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    rx_done <= 1'b0;
  else     if(done_cnt == 3'd2)
    rx_done <= 1'b1;
  else
    rx_done <= 1'b0;
end

//以太网接收
eth_rx_process u_eth_rx_process(
    .sys_clk      ( clk      ),
    .rst_n        ( rst_n        ),
    .ram_data_in    (udp_rec_ram_rdata),
    .eth_data1    ( udp_rx_data    ),	//最低位
    .eth_data2    ( udp_rx_data_d0    ),
    .eth_data3    ( udp_rx_data_d1    ),
    .eth_data4    ( udp_rx_data_d2    ),
    .eth_data5    ( udp_rx_data_d3     ),
    .eth_rx_done  ( rx_done           ),
    .late_signal    (late_signal),
    .change_flag    (change_flag),
    .data_valid_wire   ( eth_valid   ),
    .eth_vs       ( eth_vs       ),
    .x_pos        ( x_pos        ),
    .y_pos        ( y_pos        ),
    .eth_hdmi_data  ( eth_hdmi_data  )
);

//****************************************************************//
//verify checksum
//****************************************************************//
reg  [16:0] checksum_tmp0 ;
reg  [16:0] checksum_tmp1 ;
reg  [16:0] checksum_tmp2 ;
reg  [17:0] checksum_tmp3 ;
reg  [18:0] checksum_tmp4 ;
reg  [31:0] checksum_tmp5 ;
reg  [31:0] checksum_buf ;
reg  [31:0] check_out ;
reg  [31:0] checkout_buf ;
wire [15:0] checksum ;
reg  [2:0]  checksum_cnt ;

//checksum function 
function    [31:0]  checksum_adder
(
 input       [31:0]  dataina,
 input       [31:0]  datainb
);

begin
    checksum_adder = dataina + datainb;
end   
endfunction 

function    [31:0]  checksum_out
(
 input       [31:0]  dataina
);

begin
    checksum_out = dataina[15:0]+dataina[31:16];
end  
 
endfunction 

always @(posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
			checksum_tmp0 <= 17'd0 ; 
			checksum_tmp1 <= 17'd0 ;
			checksum_tmp2 <= 17'd0 ;
			checksum_tmp3 <= 18'd0 ;
			checksum_tmp4 <= 19'd0 ; 
    end		
    else if (state == REC_HEAD)
    begin
      checksum_tmp0 <= checksum_adder(ip_rec_source_addr[31:16],ip_rec_source_addr[15:0]);  //source ip address
      checksum_tmp1 <= checksum_adder(ip_rec_destination_addr[31:16],ip_rec_destination_addr[15:0]);     //destination ip address
      checksum_tmp2 <= checksum_adder({8'd0,net_protocol},udp_data_length);                   //protocol type
			checksum_tmp3 <= checksum_adder(checksum_tmp0,checksum_tmp1);                   //protocol type
      checksum_tmp4 <= checksum_adder(checksum_tmp2,checksum_tmp3);
	 end
	 else if (state == IDLE)
	 begin
			checksum_tmp0 <= 17'd0 ; 
			checksum_tmp1 <= 17'd0 ;
			checksum_tmp2 <= 17'd0 ;
			checksum_tmp3 <= 18'd0 ;
			checksum_tmp4 <= 19'd0 ; 
    end	
end

always @(posedge clk or negedge rst_n)
begin
  if(rst_n == 1'b0)
      checksum_tmp5 <= 32'd0; 
  else if (state == REC_HEAD || state == REC_DATA)     
  begin
     if (udp_rx_cnt[0] == 1'b1)
      checksum_tmp5 <= checksum_adder({udp_rx_data_d0,udp_rx_data},checksum_buf);	
  end		
  else if (state == REC_ODD_DATA)
      checksum_tmp5 <= checksum_adder({udp_rx_data,8'h00},checksum_tmp5);   //if udp data length is odd, fill with one byte 8'h00
  else if (state == IDLE)
			checksum_tmp5 <= 32'd0 ;
end

always @(posedge clk or negedge rst_n)
begin
  if(rst_n == 1'b0)
      checksum_cnt <= 3'd0 ; 
  else if (state == 	VERIFY_CHECKSUM)	
	   checksum_cnt <= checksum_cnt + 1'b1 ;
  else
	   checksum_cnt <= 3'd0 ;	
end

always @(posedge clk or negedge rst_n)
begin
  if(rst_n == 1'b0)
      check_out <= 32'd0; 
  else if (state == 	VERIFY_CHECKSUM)	
  begin  
	 if(checksum_cnt == 3'd0)
	   check_out <= checksum_adder(checksum_tmp4, checksum_tmp5);
	 else if (checksum_cnt == 3'd1)
	   check_out <= checksum_out(check_out) ;
	 else if (checksum_cnt == 3'd2)
	   check_out <= checksum_out(check_out) ;	
  end
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    checksum_buf <= 32'd0 ;
  else if (state == REC_HEAD || state == REC_DATA)
    checksum_buf <= checksum_tmp5 ;
  else
    checksum_buf <= 32'd0 ;
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    checkout_buf <= 32'd0 ;
  else if (state == 	VERIFY_CHECKSUM)	
    checkout_buf <= check_out ;
  else
    checkout_buf <= 32'd0 ;
end

assign checksum = ~checkout_buf[15:0] ;
//**************************************************//
//generate udp rx end
always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
  begin
    udp_checksum_error <= 1'b0 ;
		verify_end <= 1'b0 ;
  end
  else if (state == VERIFY_CHECKSUM && checksum_cnt == 3'd4)
  begin
    if (checksum == 16'd0)	 
	 begin
      udp_checksum_error <= 1'b0 ;
			verify_end <= 1'b1 ;
    end
	 else
	 begin
	   udp_checksum_error <= 1'b1 ;
		 verify_end <= 1'b0 ;
	 end
  end
  else
  begin
    udp_checksum_error <= 1'b0 ;
		verify_end <= 1'b0 ;
  end
end 

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n)
    udp_rec_data_valid <= 1'b0 ;
	else if (state == REC_END_WAIT)
		udp_rec_data_valid <= 1'b0 ;
  else if (state == REC_END)
  begin
    if (mac_rec_error)
      udp_rec_data_valid <= 1'b0 ;
	 else 
      udp_rec_data_valid <= 1'b1 ;
  end
end

	
endmodule
