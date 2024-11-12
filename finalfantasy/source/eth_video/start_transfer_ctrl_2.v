//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           start_transfer_ctrl
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        ͼ��ʼ�������ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module start_transfer_ctrl_2(
    input                 clk                ,   //ʱ���ź�
    input                 rst_n              ,   //��λ�źţ��͵�ƽ��Ч
    input                 udp_rec_pkt_done   ,   //UDP�������ݽ�������ź�
    input                 udp_rec_en         ,   //UDP���յ�����ʹ���ź� 
    input        [31:0]   udp_rec_data       ,   //UDP���յ�����
    input        [15:0]   udp_rec_byte_num   ,   //UDP���յ����ֽ���
                                                 
    output  reg           transfer_flag          //ͼ��ʼ�����־,1:��ʼ���� 0:ֹͣ����
    );    
    
//parameter define
parameter  START = "1";  //��ʼ����
parameter  STOP  = "0";  //ֹͣ����

//*****************************************************
//**                    main code
//*****************************************************

//�������յ�������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        transfer_flag <= 1'b0;
    else if(udp_rec_pkt_done && udp_rec_byte_num == 1'b1) begin
        if(udp_rec_data[31:24] == START)         //��ʼ����
            transfer_flag <= 1'b1;
        else if(udp_rec_data[31:24] == STOP)     //ֹͣ����
            transfer_flag <= 1'b0;
    end
end 

endmodule