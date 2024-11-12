/*
临近插值缩小模块 支持任意比例缩小
video_width_in
video_height_in
video_width_out
video_height_out
*/
module video_scale_process	#
(
	parameter	PIX_DATA_WIDTH		= 24				//像素宽度
)
(
	input												video_clk,
	input												rst_n,
	input												frame_sync_n,					//输入视频帧同步复位，低有效 //高有效
	
	input		[PIX_DATA_WIDTH-1:0]					video_data_in,					//输入视频数据
	input												video_data_valid,				//输入视频数据有效
	
	output	reg	[PIX_DATA_WIDTH-1:0]					video_data_out,					//输出视频数据
	output	reg											video_data_out_valid,			//输出视频数据有效
	input												video_ready,					//输出准备好
	
	input	[15:0]										video_width_in,					//输入视频宽度
	input	[15:0]										video_height_in,				//输入视频高度
	
	input	[15:0]										video_width_out,				//输出视频宽度
	input	[15:0]										video_height_out				//输出视频高度
);
/**********************************************************************************************************
reg define		此处定点化 左移16位进行定点化
--------[31:16] 高16位是整数，[15:0]低16位是小数
**********************************************************************************************************/
reg	[31:0]		scale_height_coffe	   ;	//竖直缩放系数
reg	[31:0]		scale_width_coffe	   ;	//水平缩放系数
reg	[15:0]		vin_x_cnt			   ;	//输入视频横坐标
reg	[15:0]		vin_y_cnt			   ;	//输入视频纵坐标
reg	[31:0]		vout_x_cnt			   ;	//输出视频横坐标
reg	[31:0]		vout_y_cnt			   ;	//输出视频纵坐标
/**********************************************************************************************************
assign
**********************************************************************************************************/

/**********************************************************************************************************
always电路
**********************************************************************************************************/
always@(posedge	frame_sync_n)	begin
	scale_width_coffe	<= ((video_width_in << 16 )/video_width_out) + 1;	//视频水平缩放比例，2^16*输入宽度/输出宽度
	scale_height_coffe	<= ((video_height_in << 16 )/video_height_out) + 1;	//视频垂直缩放比例，2^16*输入高度/输出高度
end

always@(posedge	video_clk)	begin	//输入视频水平计数和垂直计数，按像素个数计数。
	if(frame_sync_n == 0 || rst_n == 0)
	begin
		vin_x_cnt			<= 0;
		vin_y_cnt			<= 0;
	end
	else if (video_data_valid == 1 && video_ready == 1)					//当前输入视频数据有效
	begin						
		if( vin_x_cnt < video_width_in -1 )begin						//video_width_in = 输入视频宽度
			vin_x_cnt	<= vin_x_cnt + 1;
		end
		else begin
			vin_x_cnt		<= 0;
			vin_y_cnt		<= vin_y_cnt + 1;
		end
	end
end	

//判断整数部分是否接近或者是否一致 舍弃不要的
always@(posedge	video_clk)
begin	
	if(frame_sync_n == 0 || rst_n == 0)
	begin
		vout_x_cnt		<= 0;
		vout_y_cnt		<= 0;
	end
	else if (video_data_valid == 1 && video_ready == 1)
	begin	//当前输入视频数据有效
		if(vin_x_cnt < video_width_in -1)	//输入视频 一行未结束
		begin					
			if (vout_x_cnt[31:16] <= vin_x_cnt)	//[31:16]高16位是整数部分
			begin			
				vout_x_cnt	<= vout_x_cnt + scale_width_coffe;		//加上缩放比例 得到输出后的坐标
			end
		end
		else 
		begin
			vout_x_cnt		<= 0;
			if (vout_y_cnt[31:16] <= vin_y_cnt)					//整数部分判断			
				vout_y_cnt	<= vout_y_cnt + scale_height_coffe;		//加上缩放比例 得到输出后的坐标
		end
	end
end	

//一直扫描 找到 输出和输入 一致的时候 就赋值
always@(posedge	video_clk)	begin
	if(frame_sync_n == 0 || rst_n == 0)
	begin
		video_data_out	<= 0;
		video_data_out_valid	<= 0;
	end
	else if (video_ready == 1)	//当前输入视频数据有效
	begin		
		if(vout_x_cnt[31:16] == vin_x_cnt && vout_y_cnt[31:16] == vin_y_cnt)	//[31:16]高16位是整数部分,判断是否保留该像素
		begin	
			video_data_out_valid	<= video_data_valid;			//置输出有效
			video_data_out	<= video_data_in;				//该点像素保留输出
		end
		else 
			video_data_out_valid	<= 0;					//置输出无效，舍弃该点像素。
	end	
end	
endmodule
