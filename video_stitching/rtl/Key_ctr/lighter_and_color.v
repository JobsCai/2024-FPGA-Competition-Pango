`define COE  10*rgb_ctrl_plus10
`define COER 10*r_ctrl_plus10
`define COEG 10*g_ctrl_plus10
`define COEB 10*b_ctrl_plus10
module lighter_and_color(
//input
//	input		r_ctrl_plus10,//控制r
//	input		g_ctrl_plus10,//控制g
//	input		b_ctrl_plus10,//控制b
	input	[2:0]	rgb_ctrl_plus10,//控制rgb按键4来控制
	input	[2:0]	r_ctrl_plus10,//控制r按键5来控制
	input	[2:0]	g_ctrl_plus10,//控制g按键6来控制
	input	[2:0]	b_ctrl_plus10,//控制b按键7来控制
	input       clk,
	input       rst_n,

	input     		  hs_in,
	input     	 	  vs_in,
	input     		  de_in,
	input  [15:0]    data_in,

//output
	output   reg  		  hs_out,
	output     reg	 	  vs_out,
	output     reg		  de_out,
	output  [15:0]    data_out
		
);

wire   [8:0] r_data_out /* synthesis PAP_MARK_DEBUG="true" */;
wire   [8:0] g_data_out;
wire   [8:0] b_data_out;




wire   [7:0] r_data_in /* synthesis PAP_MARK_DEBUG="true" */;
wire   [7:0] g_data_in /* synthesis PAP_MARK_DEBUG="true" */;
wire   [7:0] b_data_in /* synthesis PAP_MARK_DEBUG="true" */;

assign   r_data_in =  {data_in[15:11] , data_in[13:11]};
assign   g_data_in =  {data_in[10:5]  , data_in[6:5]};
assign   b_data_in =  {data_in[4:0]   , data_in[2:0]};



assign r_data_out=r_data_in+`COE+`COER;//5
assign g_data_out=g_data_in+`COE+`COEG;//10
assign b_data_out=b_data_in+`COE+`COEB;//15
wire [7:0] test/* synthesis PAP_MARK_DEBUG="true" */;


reg   [7:0] rr_data_out ;
reg   [7:0] gg_data_out;
reg   [7:0] bb_data_out;
//vga信号delay 1拍
//生成输出时序
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin	
        hs_out<=0;
        vs_out<=0;
        de_out<=0;
      end
    else
    begin
        hs_out<=hs_in;
        vs_out<=vs_in;
        de_out<=de_in;
    end
end

always @(posedge clk or negedge rst_n)begin
  if(!rst_n) begin
    rr_data_out<=0;
    gg_data_out<=0;
	bb_data_out<=0;
  end
  else begin
    if(!(rgb_ctrl_plus10|r_ctrl_plus10|g_ctrl_plus10|b_ctrl_plus10)) begin
	    rr_data_out<=r_data_in;
		gg_data_out<=g_data_in;
		bb_data_out<=b_data_in;
	  end
    else
      begin
	  	rr_data_out<=(r_data_out>255)?255:r_data_out[7:0];
		gg_data_out<=(g_data_out>255)?255:g_data_out[7:0];
		bb_data_out<=(b_data_out>255)?255:b_data_out[7:0];
	  end
	
  end
end

assign data_out ={rr_data_out[7:3],gg_data_out[7:2],bb_data_out[7:3]};
assign test = rr_data_out;





endmodule
