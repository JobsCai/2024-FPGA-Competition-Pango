// video_scale_down_near.sv
// �򻯰��ٽ���ֵ��Ƶ����ģ�顣ֻ֧��ˮƽ��С����ֱ��С��֧��������е���С�㷨������ǳ��٣�ռ��FPGA��ԴҲ���١�
// �ǳ��ʺ�����̬��Ƶ����еĶ໭��ָ�����ٽ��㷨�����첻�㣬������ PPT����ͼ��ҽѧӰ��Ⱦ�̬��Ƶͼ���Ӧ�á�
// �������������������ѧϰ���������ο������˲���֤�������������ȷ�ԡ�����ʹ�ñ�����������ĸ��־��ױ��˲������κ����Ρ�
// 708907433@qq.com
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module video_scale_down_near	#
(
	parameter	iPIXEL_DEPTH		= 8,				//������ɫ���
	parameter	iPIXEL_COLOR		= 3					//��ɫ��
)
(
	input												vin_clk,
	input												rst_n,
	input												frame_sync,	//������Ƶ֡ͬ����λ������Ч //����Ч
	input	[iPIXEL_COLOR-1:0][iPIXEL_DEPTH-1:0]		vin_dat,			//������Ƶ����
	input												vin_valid,			//������Ƶ������Ч
	output												vin_ready,			//����׼����
	output	reg	[iPIXEL_COLOR-1:0][iPIXEL_DEPTH-1:0]	vout_dat,			//�����Ƶ����
	output	reg											vout_valid,			//�����Ƶ������Ч
	input												vout_ready,			//���׼����
	input	[15:0]										vin_xres,			//������Ƶˮƽ�ֱ���
	input	[15:0]										vin_yres,			//������Ƶ��ֱ�ֱ���
	input	[15:0]										vout_xres,			//�����Ƶˮƽ�ֱ���
	input	[15:0]										vout_yres			//�����Ƶ��ֱ�ֱ���
);
	reg	[31:0]		scaler_height	= 0;	//��ֱ����ϵ����[31:16]��16λ����������16λ��С��
	reg	[31:0]		scaler_width	= 0;	//ˮƽ����ϵ����[31:16]��16λ����������16λ��С��
	reg	[15:0]		vin_x			= 0;	//������Ƶˮƽ����
	reg	[15:0]		vin_y			= 0;	//������Ƶ��ֱ����
	reg	[31:0]		vout_x			= 0;	//�����Ƶˮƽ����,��������,[31:16]��16λ����������
	reg	[31:0]		vout_y			= 0;	//�����Ƶ��ֱ����,��������,[31:16]��16λ����������
	
	assign	vin_ready			= vout_ready;	//�����ź�

	always@(posedge	frame_sync)
	begin
		scaler_width	<= ((vin_xres << 16 )/vout_xres) + 1;	//��Ƶˮƽ���ű�����2^16*������/������
		scaler_height	<= ((vin_yres << 16 )/vout_yres) + 1;	//��Ƶ��ֱ���ű�����2^16*����߶�/����߶�
	end

	always@(posedge	vin_clk)
	begin	//������Ƶˮƽ�����ʹ�ֱ�����������ظ���������
		if(frame_sync == 1 || rst_n == 0)begin
			vin_x			<= 0;
			vin_y			<= 0;
		end
		else if (vin_valid == 1 && vout_ready == 1)begin		//��ǰ������Ƶ������Ч
			if( vin_x < vin_xres -1 )begin						//vin_xres = ������Ƶ���
				vin_x	<= vin_x + 1;
			end
			else begin
				vin_x		<= 0;
				vin_y		<= vin_y + 1;
			end
		end
	end	//always
	
	always@(posedge	vin_clk)
	begin	//�ٽ���С�㷨�����Ǽ����Ҫ���������ر����������������������������ص�ˮƽ����ʹ�ֱ����
		if(frame_sync == 1 || rst_n == 0)begin
			vout_x		<= 0;
			vout_y		<= 0;
		end
		else if (vin_valid == 1 && vout_ready == 1)begin	//��ǰ������Ƶ������Ч
			if(vin_x < vin_xres -1)begin					//vin_xres = ������Ƶ���
				if (vout_x[31:16] <= vin_x)begin			//[31:16]��16λ����������
					vout_x	<= vout_x + scaler_width;		//vout_x ��Ҫ���������ص� x ����
				end
			end
			else begin
				vout_x		<= 0;
				if (vout_y[31:16] <= vin_y)begin			//[31:16]��16λ����������
					vout_y	<= vout_y + scaler_height;		//vout_y ��Ҫ���������ص� y ����
				end
			end
		end
	end	//	always
	//vin_x,vin_y һֱ�ڱ仯������������Ƶ��ɨ�裬һ����һ���еı仯
	//�� vin_x == vout_x && vin_y == vout_y �õ����ر�����������������õ����ء�
	always@(posedge	vin_clk)
	begin
		if(frame_sync == 1 || rst_n == 0)begin
			vout_dat	<= 0;
			vout_valid	<= 0;
		end
		else if (vout_ready == 1)begin		//��ǰ������Ƶ������Ч
			if(vout_x[31:16] == vin_x && vout_y[31:16] == vin_y)begin	//[31:16]��16λ����������,�ж��Ƿ���������
				vout_valid	<= vin_valid;			//�������Ч
				vout_dat	<= vin_dat;				//�õ����ر������
			end
			else begin
				vout_valid	<= 0;					//�������Ч�������õ����ء�
			end
		end	
	end	//	always
endmodule
