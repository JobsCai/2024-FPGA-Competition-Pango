/*
�ٽ���ֵ��Сģ�� ֧�����������С
video_width_in
video_height_in
video_width_out
video_height_out
*/
module video_scale_process	#
(
	parameter	PIX_DATA_WIDTH		= 24				//���ؿ��
)
(
	input												video_clk,
	input												rst_n,
	input												frame_sync_n,					//������Ƶ֡ͬ����λ������Ч //����Ч
	
	input		[PIX_DATA_WIDTH-1:0]					video_data_in,					//������Ƶ����
	input												video_data_valid,				//������Ƶ������Ч
	
	output	reg	[PIX_DATA_WIDTH-1:0]					video_data_out,					//�����Ƶ����
	output	reg											video_data_out_valid,			//�����Ƶ������Ч
	input												video_ready,					//���׼����
	
	input	[15:0]										video_width_in,					//������Ƶ���
	input	[15:0]										video_height_in,				//������Ƶ�߶�
	
	input	[15:0]										video_width_out,				//�����Ƶ���
	input	[15:0]										video_height_out				//�����Ƶ�߶�
);
/**********************************************************************************************************
reg define		�˴����㻯 ����16λ���ж��㻯
--------[31:16] ��16λ��������[15:0]��16λ��С��
**********************************************************************************************************/
reg	[31:0]		scale_height_coffe	   ;	//��ֱ����ϵ��
reg	[31:0]		scale_width_coffe	   ;	//ˮƽ����ϵ��
reg	[15:0]		vin_x_cnt			   ;	//������Ƶ������
reg	[15:0]		vin_y_cnt			   ;	//������Ƶ������
reg	[31:0]		vout_x_cnt			   ;	//�����Ƶ������
reg	[31:0]		vout_y_cnt			   ;	//�����Ƶ������
/**********************************************************************************************************
assign
**********************************************************************************************************/

/**********************************************************************************************************
always��·
**********************************************************************************************************/
always@(posedge	frame_sync_n)	begin
	scale_width_coffe	<= ((video_width_in << 16 )/video_width_out) + 1;	//��Ƶˮƽ���ű�����2^16*������/������
	scale_height_coffe	<= ((video_height_in << 16 )/video_height_out) + 1;	//��Ƶ��ֱ���ű�����2^16*����߶�/����߶�
end

always@(posedge	video_clk)	begin	//������Ƶˮƽ�����ʹ�ֱ�����������ظ���������
	if(frame_sync_n == 0 || rst_n == 0)
	begin
		vin_x_cnt			<= 0;
		vin_y_cnt			<= 0;
	end
	else if (video_data_valid == 1 && video_ready == 1)					//��ǰ������Ƶ������Ч
	begin						
		if( vin_x_cnt < video_width_in -1 )begin						//video_width_in = ������Ƶ���
			vin_x_cnt	<= vin_x_cnt + 1;
		end
		else begin
			vin_x_cnt		<= 0;
			vin_y_cnt		<= vin_y_cnt + 1;
		end
	end
end	

//�ж����������Ƿ�ӽ������Ƿ�һ�� ������Ҫ��
always@(posedge	video_clk)
begin	
	if(frame_sync_n == 0 || rst_n == 0)
	begin
		vout_x_cnt		<= 0;
		vout_y_cnt		<= 0;
	end
	else if (video_data_valid == 1 && video_ready == 1)
	begin	//��ǰ������Ƶ������Ч
		if(vin_x_cnt < video_width_in -1)	//������Ƶ һ��δ����
		begin					
			if (vout_x_cnt[31:16] <= vin_x_cnt)	//[31:16]��16λ����������
			begin			
				vout_x_cnt	<= vout_x_cnt + scale_width_coffe;		//�������ű��� �õ�����������
			end
		end
		else 
		begin
			vout_x_cnt		<= 0;
			if (vout_y_cnt[31:16] <= vin_y_cnt)					//���������ж�			
				vout_y_cnt	<= vout_y_cnt + scale_height_coffe;		//�������ű��� �õ�����������
		end
	end
end	

//һֱɨ�� �ҵ� ��������� һ�µ�ʱ�� �͸�ֵ
always@(posedge	video_clk)	begin
	if(frame_sync_n == 0 || rst_n == 0)
	begin
		video_data_out	<= 0;
		video_data_out_valid	<= 0;
	end
	else if (video_ready == 1)	//��ǰ������Ƶ������Ч
	begin		
		if(vout_x_cnt[31:16] == vin_x_cnt && vout_y_cnt[31:16] == vin_y_cnt)	//[31:16]��16λ����������,�ж��Ƿ���������
		begin	
			video_data_out_valid	<= video_data_valid;			//�������Ч
			video_data_out	<= video_data_in;				//�õ����ر������
		end
		else 
			video_data_out_valid	<= 0;					//�������Ч�������õ����ء�
	end	
end	
endmodule
