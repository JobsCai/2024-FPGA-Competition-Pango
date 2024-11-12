// video_scale_down_near.sv
// 简化版临近插值视频缩放模块。只支持水平缩小、垂直缩小。支持任意比列的缩小算法。代码非常少，占用FPGA资源也很少。
// 非常适合做动态视频监控中的多画面分割。由于临近算法的先天不足，不适用 PPT、地图、医学影像等静态视频图像的应用。
// 免责申明：本代码仅供学习、交流、参考。本人不保证代码的完整性正确性。由于使用本代码而产生的各种纠纷本人不负担任何责任。
// 708907433@qq.com
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module video_scale_down_near	#
(
	parameter	iPIXEL_DEPTH		= 8,				//像素颜色深度
	parameter	iPIXEL_COLOR		= 3					//颜色数
)
(
	input												vin_clk,
	input												rst_n,
	input												frame_sync,	//输入视频帧同步复位，低有效 //高有效
	input	[iPIXEL_COLOR-1:0][iPIXEL_DEPTH-1:0]		vin_dat,			//输入视频数据
	input												vin_valid,			//输入视频数据有效
	output												vin_ready,			//输入准备好
	output	reg	[iPIXEL_COLOR-1:0][iPIXEL_DEPTH-1:0]	vout_dat,			//输出视频数据
	output	reg											vout_valid,			//输出视频数据有效
	input												vout_ready,			//输出准备好
	input	[15:0]										vin_xres,			//输入视频水平分辨率
	input	[15:0]										vin_yres,			//输入视频垂直分辨率
	input	[15:0]										vout_xres,			//输出视频水平分辨率
	input	[15:0]										vout_yres			//输出视频垂直分辨率
);
	reg	[31:0]		scaler_height	= 0;	//垂直缩放系数，[31:16]高16位是整数，低16位是小数
	reg	[31:0]		scaler_width	= 0;	//水平缩放系数，[31:16]高16位是整数，低16位是小数
	reg	[15:0]		vin_x			= 0;	//输入视频水平计数
	reg	[15:0]		vin_y			= 0;	//输入视频垂直计数
	reg	[31:0]		vout_x			= 0;	//输出视频水平计数,定浮点数,[31:16]高16位是整数部分
	reg	[31:0]		vout_y			= 0;	//输出视频垂直计数,定浮点数,[31:16]高16位是整数部分
	
	assign	vin_ready			= vout_ready;	//流控信号

	always@(posedge	frame_sync)
	begin
		scaler_width	<= ((vin_xres << 16 )/vout_xres) + 1;	//视频水平缩放比例，2^16*输入宽度/输出宽度
		scaler_height	<= ((vin_yres << 16 )/vout_yres) + 1;	//视频垂直缩放比例，2^16*输入高度/输出高度
	end

	always@(posedge	vin_clk)
	begin	//输入视频水平计数和垂直计数，按像素个数计数。
		if(frame_sync == 1 || rst_n == 0)begin
			vin_x			<= 0;
			vin_y			<= 0;
		end
		else if (vin_valid == 1 && vout_ready == 1)begin		//当前输入视频数据有效
			if( vin_x < vin_xres -1 )begin						//vin_xres = 输入视频宽度
				vin_x	<= vin_x + 1;
			end
			else begin
				vin_x		<= 0;
				vin_y		<= vin_y + 1;
			end
		end
	end	//always
	
	always@(posedge	vin_clk)
	begin	//临近缩小算法，就是计算出要保留的像素保留，其他的像素舍弃。保留像素的水平坐标和垂直坐标
		if(frame_sync == 1 || rst_n == 0)begin
			vout_x		<= 0;
			vout_y		<= 0;
		end
		else if (vin_valid == 1 && vout_ready == 1)begin	//当前输入视频数据有效
			if(vin_x < vin_xres -1)begin					//vin_xres = 输入视频宽度
				if (vout_x[31:16] <= vin_x)begin			//[31:16]高16位是整数部分
					vout_x	<= vout_x + scaler_width;		//vout_x 需要保留的像素的 x 坐标
				end
			end
			else begin
				vout_x		<= 0;
				if (vout_y[31:16] <= vin_y)begin			//[31:16]高16位是整数部分
					vout_y	<= vout_y + scaler_height;		//vout_y 需要保留的像素的 y 坐标
				end
			end
		end
	end	//	always
	//vin_x,vin_y 一直在变化，随着输入视频的扫描，一线线一行行的变化
	//当 vin_x == vout_x && vin_y == vout_y 该点像素保留输出，否则舍弃该点像素。
	always@(posedge	vin_clk)
	begin
		if(frame_sync == 1 || rst_n == 0)begin
			vout_dat	<= 0;
			vout_valid	<= 0;
		end
		else if (vout_ready == 1)begin		//当前输入视频数据有效
			if(vout_x[31:16] == vin_x && vout_y[31:16] == vin_y)begin	//[31:16]高16位是整数部分,判断是否保留该像素
				vout_valid	<= vin_valid;			//置输出有效
				vout_dat	<= vin_dat;				//该点像素保留输出
			end
			else begin
				vout_valid	<= 0;					//置输出无效，舍弃该点像素。
			end
		end	
	end	//	always
endmodule
