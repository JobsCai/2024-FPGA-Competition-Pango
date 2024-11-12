module line_shift_ram_8bit(
    input          clock, 
    input          rst_n,  
    input          clken,
    input          pre_frame_href,
    
    input   [7:0]  shiftin,  
    output  [7:0]  taps0x,   
    output  [7:0]  taps1x    
);

//reg define
reg  [2:0]  clken_dly;
reg  [10:0] ram_rd_addr;
reg  [10:0] ram_rd_addr_d0;
reg  [10:0] ram_rd_addr_d1;
reg  [7:0]  shiftin_d0;
reg  [7:0]  shiftin_d1;
reg  [7:0]  shiftin_d2;

//*****************************************************
//**                    main code
//*****************************************************

//����������ʱ��ram��ַ�ۼ�
always@(posedge clock)begin
    if(pre_frame_href)
        if(clken)
            ram_rd_addr <= ram_rd_addr + 1 ;
        else
            ram_rd_addr <= ram_rd_addr ;
    else
        ram_rd_addr <= 0 ;
end

//ʱ��ʹ���ź��ӳ�����
always@(posedge clock) begin
    clken_dly <= { clken_dly[1:0] , clken };
end

//��ram��ַ�ӳٶ���
always@(posedge clock ) begin
    ram_rd_addr_d0 <= ram_rd_addr;
    ram_rd_addr_d1 <= ram_rd_addr_d0;
end

//���������ӳ�����
always@(posedge clock)begin
    shiftin_d0 <= shiftin;
    shiftin_d1 <= shiftin_d0;
    shiftin_d2 <= shiftin_d1;
end

//���ڴ洢ǰһ��ͼ���RAM
blk_mem_gen_0 u_ram_2048x8_0 (
    .wr_data (shiftin_d2 ),   //input [7:0]ramд����
    .wr_addr (ram_rd_addr_d1),//input [4:0]ramд��ַ
    .wr_en   (clken_dly[2]),  //inpu���ӳٵĵ�����ʱ�����ڣ���ǰ�е�����д��RAM0
    .wr_clk  (clock ),        //input
    .wr_rst  (~rst_n ),       //input
    .rd_addr (ram_rd_addr ),  //input [4:0]ram����ַ
    .rd_data (taps0x ),       //output[7:0]ram�������ӳ�һ��ʱ�����ڣ����RAM0��ǰһ��ͼ�������
    .rd_clk  (clock ),        //input
    .rd_rst  (~rst_n )        //input
);

//���ڴ洢ǰǰһ��ͼ���RAM
blk_mem_gen_0 u_ram_2048x8_1 (
    .wr_data (taps0x),        //input [7:0]ramд����
    .wr_addr (ram_rd_addr_d1),//input [4:0]ramд��ַ
    .wr_en   (clken_dly[2] ), //input���ӳٵĵ�����ʱ�����ڣ���ǰһ��ͼ�������д��RAM1
    .wr_clk  (clock ),        //input
    .wr_rst  (~rst_n ),       //input
    .rd_addr (ram_rd_addr ),  //input [4:0]ram����ַ
    .rd_data (taps1x ),       //output[7:0]ram�������ӳ�һ��ʱ�����ڣ����RAM1��ǰǰһ��ͼ�������
    .rd_clk  (clock ),        //input
    .rd_rst  (~rst_n )        //input
);
endmodule 