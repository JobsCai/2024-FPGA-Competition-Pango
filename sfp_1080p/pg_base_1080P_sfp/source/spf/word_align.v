module word_align(
	input         rst,
	input        rx_clk,
	input[31:0]  gt_rx_data,
	input[3:0]   gt_rx_ctrl,
	output [31:0] rx_data_align,
	output [3:0]  rx_ctrl_align
);
wire  chk_clk = rx_clk;

// ********************* RXD BUFFER *********************
wire  [39:0] rxd    ;
reg   [39:0] rxd_ff1 ;
reg   [39:0] rxd_ff2 ;
reg   [39:0] rxd_ff3 ;
reg   [39:0] rxd_ff4 ;
reg   [39:0] rxd_ff5 ;
wire  [ 3:0] rxk    ;
reg   [ 3:0] rxk_ff1 ;
reg   [ 3:0] rxk_ff2 ;
reg   [ 3:0] rxk_ff3 ;
reg   [39:0] rxd_algn ;
reg   [ 3:0] rxk_algn ;
reg   [39:0] rxd_algn_ff1 ;
reg   [39:0] rxd_algn_ff2 ;
reg   [ 3:0] rxk_algn_ff1 ;
reg   [ 3:0] rxk_algn_ff2 ;
reg   [1:0] rxbyte_shft ;
wire i_chk_rstn;
assign rxd = gt_rx_data;
assign rxk = gt_rx_ctrl;
assign i_chk_rstn=~rst;
assign rx_data_align=rxd_algn;
assign rx_ctrl_align=rxk_algn;

reg  [39:0] payload     ;
reg  [39:0] payload_buf ;
reg  [ 5:0] shift_bits  ;
reg  [ 5:0] shift_bits_ff1  ;
reg  [ 3:0] pl_err  ;
reg  [15:0] pattern_cnt  ;
wire [40:0] payload_shift ;

always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxd_ff1 <= 40'd0;
    else 
        rxd_ff1<= rxd;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxd_ff2 <= 40'd0;
    else 
        rxd_ff2 <= rxd_ff1;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxd_ff3 <= 40'd0;
    else 
        rxd_ff3 <= rxd_ff2;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxd_ff4 <= 40'd0;
    else 
        rxd_ff4 <= rxd_ff3;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxd_ff5 <= 40'd0;
    else 
        rxd_ff5 <= rxd_ff4;
end

always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxk_ff1 <=  4'd0;
    else 
        rxk_ff1 <= rxk;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxk_ff2 <=  4'd0;
    else 
        rxk_ff2 <= rxk_ff1;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        rxk_ff3 <=  4'd0;
    else 
        rxk_ff3 <= rxk_ff2;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) 
        shift_bits_ff1 <= 6'd0;
    else 
        shift_bits_ff1 <= shift_bits;
end


//×Ö½Ú¶ÔÆë
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0)
        rxbyte_shft <= 2'd0;
    else if((rxk==4'b1000)&&(rxk_ff1[3]==1'b0))
        rxbyte_shft <= 2'd1;
    else if((rxk[2:0]==3'b100)&&(rxk_ff1[3:2]==2'b00))
        rxbyte_shft <= 2'd2;
    else if((rxk[1:0]==2'b10)&&(rxk_ff1[3:1]==3'b000))
        rxbyte_shft <= 2'd3;
    else if((rxk[0]==1'b1)&&(rxk_ff1==4'b0000))
        rxbyte_shft <= 2'd0;
    else ;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) begin
        rxd_algn <= 40'd0;
        rxk_algn <= 4'd0;
    end
    else if(rxbyte_shft==2'd1) begin
        rxd_algn <= {8'b0,rxd_ff1[23:0],rxd_ff2[31:24]};
        rxk_algn <= {rxk_ff1[2:0],rxk_ff2[3]};
    end
    else if(rxbyte_shft==2'd2) begin
        rxd_algn <= {8'b0,rxd_ff1[15:0],rxd_ff2[31:16]};
        rxk_algn <= {rxk_ff1[1:0],rxk_ff2[3:2]};
    end
    else if(rxbyte_shft==2'd3) begin
        rxd_algn <= {8'b0,rxd_ff1[7:0],rxd_ff2[31:8]};
        rxk_algn <= {rxk_ff1[0],rxk_ff2[3:1]};
    end
    else begin
        rxd_algn <= {8'b0,rxd_ff2[31:0]};
        rxk_algn <= rxk_ff2[3:0];
    end
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) begin
        rxd_algn_ff1 <= 40'd0;
        rxk_algn_ff1 <= 4'd0;
    end
    else begin
        rxd_algn_ff1 <= rxd_algn;
        rxk_algn_ff1 <= rxk_algn;
    end
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0)
        pattern_cnt <= 16'd1;
    else if(rxk_algn==4'b0000) 
        pattern_cnt <= 16'd0;
    else if(pattern_cnt<16'd1) 
        pattern_cnt <= pattern_cnt+16'd1;
    else;
end
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0) begin
        payload[31:0] <= 32'b0;
        payload_buf[31:0] <= 32'b0;
    end
    else if(pattern_cnt==16'd0) begin
        payload[31:0] <= rxd_algn_ff1[31:0];
        payload_buf[31:0] <= payload[31:0];
    end
    else ;
end
assign payload_shift[31:0] = {payload_buf[30:0],payload_buf[31]}; 
always @ (posedge chk_clk or negedge i_chk_rstn) begin 
    if(i_chk_rstn==1'b0)
        pl_err <= 1'b0;
    else if((pattern_cnt==16'd0)&&(payload[31:0]!=payload_shift[31:0]))
        pl_err <= 1'b1;
    else
        pl_err <= 1'b0;
end

wire [39:0] rxd_dbg          = rxd;
wire [39:0] rxd_ff1_dbg      = rxd_ff1;
wire [39:0] rxd_ff2_dbg      = rxd_ff2;
wire [3:0]  rxk_dbg          = rxk;
wire [3:0]  rxk_ff1_dbg      = rxk_ff1;
wire [3:0]  rxk_ff2_dbg      = rxk_ff2;
wire [15:0]  pattern_cnt_dbg =  pattern_cnt;
wire [39:0]  payload_dbg     = payload;
wire [40:0]  payload_shift_dbg     = payload_shift;
wire [39:0] payload_buf_dbg = payload_buf;
wire  [39:0] rxd_algn_dbg = rxd_algn;
wire  [ 3:0] rxk_algn_dbg = rxk_algn;
wire  [1:0] rxbyte_shft_dbg = rxbyte_shft;


endmodule    

