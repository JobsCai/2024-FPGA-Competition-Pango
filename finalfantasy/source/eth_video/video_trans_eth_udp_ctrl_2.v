module video_trans_eth_ctrl_2(
    input              clk       ,     //ϵͳʱ��
    input              rst_n     ,     //ϵͳ��λ�źţ��͵�ƽ��Ч 
    //ARP��ض˿��ź�                                   
    input              arp_rx_done,    //ARP��������ź�
    input              arp_rx_type,    //ARP�������� 0:����  1:Ӧ��
    output  reg        arp_tx_en,      //ARP����ʹ���ź�
    output             arp_tx_type,    //ARP�������� 0:����  1:Ӧ��
    input              arp_tx_done,    //ARP��������ź�
    input              arp_gmii_tx_en, //ARP GMII���������Ч�ź� 
    input     [7:0]    arp_gmii_txd,   //ARP GMII�������
    //UDP��ض˿��ź�
    input              udp_tx_start_en,//UDP��ʼ�����ź�
    input              udp_tx_done,    //UDP��������ź�
    input              udp_gmii_tx_en, //UDP GMII���������Ч�ź�  
    input     [7:0]    udp_gmii_txd,   //UDP GMII�������   
    //GMII��������                     
    output             gmii_tx_en,     //GMII���������Ч�ź� 
    output    [7:0]    gmii_txd        //UDP GMII������� 
    );

//reg define
reg        protocol_sw; //Э���л��ź�
reg        udp_tx_busy; //UDP���ڷ������ݱ�־�ź�
reg        arp_rx_flag; //���յ�ARP�����źŵı�־

//*****************************************************
//**                    main code
//*****************************************************

assign arp_tx_type = 1'b1;   //ARP�������͹̶�ΪARPӦ��                                   
assign gmii_tx_en = protocol_sw ? udp_gmii_tx_en : arp_gmii_tx_en;
assign gmii_txd = protocol_sw ? udp_gmii_txd : arp_gmii_txd;

//����UDP����æ�ź�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        udp_tx_busy <= 1'b0;
    else if(udp_tx_start_en)   
        udp_tx_busy <= 1'b1;
    else if(udp_tx_done)
        udp_tx_busy <= 1'b0;
end

//���ƽ��յ�ARP�����źŵı�־
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        arp_rx_flag <= 1'b0;
    else if(arp_rx_done && (arp_rx_type == 1'b0))   
        arp_rx_flag <= 1'b1;
    else if(protocol_sw == 1'b0)
        arp_rx_flag <= 1'b0;
end

//����protocol_sw��arp_tx_en�ź�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        protocol_sw <= 1'b0;
        arp_tx_en <= 1'b0;
    end
    else begin
        arp_tx_en <= 1'b0;
        if(udp_tx_start_en)
            protocol_sw <= 1'b1;
        else if(arp_rx_flag && (udp_tx_busy == 1'b0)) begin
            protocol_sw <= 1'b0;
            arp_tx_en <= 1'b1;
        end    
    end        
end

endmodule
