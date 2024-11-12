module video_trans_eth_arp_rx_2
  #(
    //������MAC��ַ 00-11-22-33-44-55
    parameter BOARD_MAC = 48'h00_11_22_33_44_55,  
    //������IP��ַ 192.168.1.10   
    parameter BOARD_IP = {8'd192,8'd168,8'd1,8'd10}      
    )
   (
    input                clk        , //ʱ���ź�
    input                rst_n      , //��λ�źţ��͵�ƽ��Ч
                                    
    input                gmii_rx_dv , //GMII����������Ч�ź�
    input        [7:0]   gmii_rxd   , //GMII��������
    output  reg          arp_rx_done, //ARP��������ź�
    output  reg          arp_rx_type, //ARP�������� 0:����  1:Ӧ��
    output  reg  [47:0]  src_mac    , //���յ���ԴMAC��ַ
    output  reg  [31:0]  src_ip       //���յ���ԴIP��ַ
    );

//parameter define
localparam  st_idle     = 5'b0_0001; //��ʼ״̬���ȴ�����ǰ����
localparam  st_preamble = 5'b0_0010; //����ǰ����״̬ 
localparam  st_eth_head = 5'b0_0100; //������̫��֡ͷ
localparam  st_arp_data = 5'b0_1000; //����ARP����
localparam  st_rx_end   = 5'b1_0000; //���ս���

localparam  ETH_TPYE = 16'h0806;     //��̫��֡���� ARP

//reg define
reg    [4:0]   cur_state ;
reg    [4:0]   next_state;
                         
reg            skip_en   ; //����״̬��תʹ���ź�
reg            error_en  ; //��������ʹ���ź�
reg    [4:0]   cnt       ; //�������ݼ�����
reg    [47:0]  des_mac_t ; //���յ���Ŀ��MAC��ַ
reg    [31:0]  des_ip_t  ; //���յ���Ŀ��IP��ַ
reg    [47:0]  src_mac_t ; //���յ���ԴMAC��ַ
reg    [31:0]  src_ip_t  ; //���յ���ԴIP��ַ
reg    [15:0]  eth_type  ; //��̫������
reg    [15:0]  op_data   ; //������

//*****************************************************
//**                    main code
//*****************************************************

//(����ʽ״̬��)ͬ��ʱ������״̬ת��
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;  
    else
        cur_state <= next_state;
end

//����߼��ж�״̬ת������
always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle : begin                     //�ȴ�����ǰ����
            if(skip_en) 
                next_state = st_preamble;
            else
                next_state = st_idle;    
        end
        st_preamble : begin                 //����ǰ����
            if(skip_en) 
                next_state = st_eth_head;
            else if(error_en) 
                next_state = st_rx_end;    
            else
                next_state = st_preamble;   
        end
        st_eth_head : begin                 //������̫��֡ͷ
            if(skip_en) 
                next_state = st_arp_data;
            else if(error_en) 
                next_state = st_rx_end;
            else
                next_state = st_eth_head;   
        end  
        st_arp_data : begin                  //����ARP����
            if(skip_en)
                next_state = st_rx_end;
            else if(error_en)
                next_state = st_rx_end;
            else
                next_state = st_arp_data;   
        end                  
        st_rx_end : begin                   //���ս���
            if(skip_en)
                next_state = st_idle;
            else
                next_state = st_rx_end;          
        end
        default : next_state = st_idle;
    endcase                                          
end    

//ʱ���·����״̬���,������̫������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        skip_en <= 1'b0;
        error_en <= 1'b0;
        cnt <= 5'd0;
        des_mac_t <= 48'd0;
        des_ip_t <= 32'd0;
        src_mac_t <= 48'd0;
        src_ip_t <= 32'd0;        
        eth_type <= 16'd0;
        op_data <= 16'd0;
        arp_rx_done <= 1'b0;
        arp_rx_type <= 1'b0;
        src_mac <= 48'd0;
        src_ip <= 32'd0;
    end
    else begin
        skip_en <= 1'b0;
        error_en <= 1'b0;  
        arp_rx_done <= 1'b0;
        case(next_state)
            st_idle : begin                                  //��⵽��һ��8'h55
                if((gmii_rx_dv == 1'b1) && (gmii_rxd == 8'h55)) 
                    skip_en <= 1'b1;
            end
            st_preamble : begin
                if(gmii_rx_dv) begin                         //����ǰ����
                    cnt <= cnt + 5'd1;
                    if((cnt < 5'd6) && (gmii_rxd != 8'h55))  //7��8'h55  
                        error_en <= 1'b1;
                    else if(cnt==5'd6) begin
                        cnt <= 5'd0;
                        if(gmii_rxd==8'hd5)                  //1��8'hd5
                            skip_en <= 1'b1;
                        else
                            error_en <= 1'b1;    
                    end  
                end  
            end
            st_eth_head : begin
                if(gmii_rx_dv) begin
                    cnt <= cnt + 5'b1;
                    if(cnt < 5'd6) 
                        des_mac_t <= {des_mac_t[39:0],gmii_rxd};
                    else if(cnt == 5'd6) begin
                        //�ж�MAC��ַ�Ƿ�Ϊ������MAC��ַ���߹�����ַ
                        if((des_mac_t != BOARD_MAC)
                            && (des_mac_t != 48'hff_ff_ff_ff_ff_ff))           
                            error_en <= 1'b1;
                    end
                    else if(cnt == 5'd12) 
                        eth_type[15:8] <= gmii_rxd;          //��̫��Э������
                    else if(cnt == 5'd13) begin
                        eth_type[7:0] <= gmii_rxd;
                        cnt <= 5'd0;
                        if(eth_type[15:8] == ETH_TPYE[15:8]  //�ж��Ƿ�ΪARPЭ��
                            && gmii_rxd == ETH_TPYE[7:0])
                            skip_en <= 1'b1; 
                        else
                            error_en <= 1'b1;                       
                    end        
                end  
            end
            st_arp_data : begin
                if(gmii_rx_dv) begin
                    cnt <= cnt + 5'd1;
                    if(cnt == 5'd6) 
                        op_data[15:8] <= gmii_rxd;           //������       
                    else if(cnt == 5'd7)
                        op_data[7:0] <= gmii_rxd;
                    else if(cnt >= 5'd8 && cnt < 5'd14)      //ԴMAC��ַ
                        src_mac_t <= {src_mac_t[39:0],gmii_rxd};
                    else if(cnt >= 5'd14 && cnt < 5'd18)     //ԴIP��ַ
                        src_ip_t<= {src_ip_t[23:0],gmii_rxd};
                    else if(cnt >= 5'd24 && cnt < 5'd28)     //Ŀ��IP��ַ
                        des_ip_t <= {des_ip_t[23:0],gmii_rxd};
                    else if(cnt == 5'd28) begin
                        cnt <= 5'd0;
                        if(des_ip_t == BOARD_IP) begin       //�ж�Ŀ��IP��ַ�Ͳ�����
                            if((op_data == 16'd1) || (op_data == 16'd2)) begin
                                skip_en <= 1'b1;
                                arp_rx_done <= 1'b1;
                                src_mac <= src_mac_t;
                                src_ip <= src_ip_t;
                                src_mac_t <= 48'd0;
                                src_ip_t <= 32'd0;
                                des_mac_t <= 48'd0;
                                des_ip_t <= 32'd0;
                                if(op_data == 16'd1)         
                                    arp_rx_type <= 1'b0;     //ARP����
                                else
                                    arp_rx_type <= 1'b1;     //ARPӦ��
                            end
                            else
                                error_en <= 1'b1;
                        end 
                        else
                            error_en <= 1'b1;
                    end
                end                                
            end
            st_rx_end : begin     
                cnt <= 5'd0;
                //�������ݽ������   
                if(gmii_rx_dv == 1'b0 && skip_en == 1'b0)
                    skip_en <= 1'b1; 
            end    
            default : ;
        endcase                                                        
    end
end

endmodule