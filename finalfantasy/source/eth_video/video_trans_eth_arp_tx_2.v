module video_trans_eth_arp_tx_2( 
    input                clk        , //ʱ���ź�
    input                rst_n      , //��λ�źţ��͵�ƽ��Ч
    
    input                arp_tx_en  , //ARP����ʹ���ź�
    input                arp_tx_type, //ARP�������� 0:����  1:Ӧ��
    input        [47:0]  des_mac    , //���͵�Ŀ��MAC��ַ
    input        [31:0]  des_ip     , //���͵�Ŀ��IP��ַ
    input        [31:0]  crc_data   , //CRCУ������
    input         [7:0]  crc_next   , //CRC�´�У���������
    output  reg          tx_done    , //��̫����������ź�
    output  reg          gmii_tx_en , //GMII���������Ч�ź�
    output  reg  [7:0]   gmii_txd   , //GMII�������
    output  reg          crc_en     , //CRC��ʼУ��ʹ��
    output  reg          crc_clr      //CRC���ݸ�λ�ź� 
    );

//parameter define
//������MAC��ַ 00-11-22-33-44-55
parameter BOARD_MAC = 48'h00_11_22_33_44_55;
//������IP��ַ 192.168.1.10
parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd10}; 
//Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
//Ŀ��IP��ַ 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};

localparam  st_idle      = 5'b0_0001; //��ʼ״̬���ȴ���ʼ�����ź�
localparam  st_preamble  = 5'b0_0010; //����ǰ����+֡��ʼ�綨��
localparam  st_eth_head  = 5'b0_0100; //������̫��֡ͷ
localparam  st_arp_data  = 5'b0_1000; //
localparam  st_crc       = 5'b1_0000; //����CRCУ��ֵ

localparam  ETH_TYPE     = 16'h0806 ; //��̫��֡���� ARPЭ��
localparam  HD_TYPE      = 16'h0001 ; //Ӳ������ ��̫��
localparam  PROTOCOL_TYPE= 16'h0800 ; //�ϲ�Э��ΪIPЭ��
//��̫��������СΪ46���ֽ�,���㲿���������
localparam  MIN_DATA_NUM = 16'd46   ;    

//reg define
reg  [4:0]  cur_state     ;
reg  [4:0]  next_state    ;
                          
reg  [7:0]  preamble[7:0] ; //ǰ����+SFD
reg  [7:0]  eth_head[13:0]; //��̫���ײ�
reg  [7:0]  arp_data[27:0]; //ARP����
                            
reg         tx_en_d0      ; //arp_tx_en�ź���ʱ
reg         tx_en_d1      ; 
reg         skip_en       ; //����״̬��תʹ���ź�
reg  [5:0]  cnt           ; 
reg  [4:0]  data_cnt      ; //�������ݸ���������
reg         tx_done_t     ; 
                                
//wire define                   
wire        pos_tx_en     ; //arp_tx_en�ź�������

//*****************************************************
//**                    main code
//*****************************************************

assign  pos_tx_en = (~tx_en_d1) & tx_en_d0;
                           
//��arp_tx_en�ź���ʱ��������,���ڲ�arp_tx_en��������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_en_d0 <= 1'b0;
        tx_en_d1 <= 1'b0;
    end    
    else begin
        tx_en_d0 <= arp_tx_en;
        tx_en_d1 <= tx_en_d0;
    end
end 

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
        st_idle : begin                     //����״̬
            if(skip_en)                
                next_state = st_preamble;
            else
                next_state = st_idle;
        end                          
        st_preamble : begin                 //����ǰ����+֡��ʼ�綨��
            if(skip_en)
                next_state = st_eth_head;
            else
                next_state = st_preamble;      
        end
        st_eth_head : begin                 //������̫���ײ�
            if(skip_en)
                next_state = st_arp_data;
            else
                next_state = st_eth_head;      
        end              
        st_arp_data : begin                 //����ARP����                      
            if(skip_en)
                next_state = st_crc;
            else
                next_state = st_arp_data;      
        end
        st_crc: begin                       //����CRCУ��ֵ
            if(skip_en)
                next_state = st_idle;
            else
                next_state = st_crc;      
        end
        default : next_state = st_idle;   
    endcase
end                      

//ʱ���·����״̬�����������̫������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        skip_en <= 1'b0; 
        cnt <= 6'd0;
        data_cnt <= 5'd0;
        crc_en <= 1'b0;
        gmii_tx_en <= 1'b0;
        gmii_txd <= 8'd0;
        tx_done_t <= 1'b0; 
        
        //��ʼ������    
        //ǰ���� 7��8'h55 + 1��8'hd5 
        preamble[0] <= 8'h55;                
        preamble[1] <= 8'h55;
        preamble[2] <= 8'h55;
        preamble[3] <= 8'h55;
        preamble[4] <= 8'h55;
        preamble[5] <= 8'h55;
        preamble[6] <= 8'h55;
        preamble[7] <= 8'hd5;
        //��̫��֡ͷ 
        eth_head[0] <= DES_MAC[47:40];      //Ŀ��MAC��ַ
        eth_head[1] <= DES_MAC[39:32];
        eth_head[2] <= DES_MAC[31:24];
        eth_head[3] <= DES_MAC[23:16];
        eth_head[4] <= DES_MAC[15:8];
        eth_head[5] <= DES_MAC[7:0];        
        eth_head[6] <= BOARD_MAC[47:40];    //ԴMAC��ַ
        eth_head[7] <= BOARD_MAC[39:32];    
        eth_head[8] <= BOARD_MAC[31:24];    
        eth_head[9] <= BOARD_MAC[23:16];    
        eth_head[10] <= BOARD_MAC[15:8];    
        eth_head[11] <= BOARD_MAC[7:0];     
        eth_head[12] <= ETH_TYPE[15:8];     //��̫��֡����
        eth_head[13] <= ETH_TYPE[7:0];      
        //ARP����                           
        arp_data[0] <= HD_TYPE[15:8];       //Ӳ������
        arp_data[1] <= HD_TYPE[7:0];
        arp_data[2] <= PROTOCOL_TYPE[15:8]; //�ϲ�Э������
        arp_data[3] <= PROTOCOL_TYPE[7:0];
        arp_data[4] <= 8'h06;               //Ӳ����ַ����,6
        arp_data[5] <= 8'h04;               //Э���ַ����,4
        arp_data[6] <= 8'h00;               //OP,������ 8'h01��ARP���� 8'h02:ARPӦ��
        arp_data[7] <= 8'h01;
        arp_data[8] <= BOARD_MAC[47:40];    //���Ͷ�(Դ)MAC��ַ
        arp_data[9] <= BOARD_MAC[39:32];
        arp_data[10] <= BOARD_MAC[31:24];
        arp_data[11] <= BOARD_MAC[23:16];
        arp_data[12] <= BOARD_MAC[15:8];
        arp_data[13] <= BOARD_MAC[7:0];
        arp_data[14] <= BOARD_IP[31:24];    //���Ͷ�(Դ)IP��ַ
        arp_data[15] <= BOARD_IP[23:16];
        arp_data[16] <= BOARD_IP[15:8];
        arp_data[17] <= BOARD_IP[7:0];
        arp_data[18] <= DES_MAC[47:40];     //���ն�(Ŀ��)MAC��ַ
        arp_data[19] <= DES_MAC[39:32];
        arp_data[20] <= DES_MAC[31:24];
        arp_data[21] <= DES_MAC[23:16];
        arp_data[22] <= DES_MAC[15:8];
        arp_data[23] <= DES_MAC[7:0];  
        arp_data[24] <= DES_IP[31:24];      //���ն�(Ŀ��)IP��ַ
        arp_data[25] <= DES_IP[23:16];
        arp_data[26] <= DES_IP[15:8];
        arp_data[27] <= DES_IP[7:0];
    end
    else begin
        skip_en <= 1'b0;
        crc_en <= 1'b0;
        gmii_tx_en <= 1'b0;
        tx_done_t <= 1'b0;
        case(next_state)
            st_idle : begin
                if(pos_tx_en) begin
                    skip_en <= 1'b1;  
                    //���Ŀ��MAC��ַ��IP��ַ�Ѿ�����,������ȷ�ĵ�ַ
                    if((des_mac != 48'b0) || (des_ip != 32'd0)) begin
                        eth_head[0] <= des_mac[47:40];
                        eth_head[1] <= des_mac[39:32];
                        eth_head[2] <= des_mac[31:24];
                        eth_head[3] <= des_mac[23:16];
                        eth_head[4] <= des_mac[15:8];
                        eth_head[5] <= des_mac[7:0];  
                        arp_data[18] <= des_mac[47:40];
                        arp_data[19] <= des_mac[39:32];
                        arp_data[20] <= des_mac[31:24];
                        arp_data[21] <= des_mac[23:16];
                        arp_data[22] <= des_mac[15:8];
                        arp_data[23] <= des_mac[7:0];  
                        arp_data[24] <= des_ip[31:24];
                        arp_data[25] <= des_ip[23:16];
                        arp_data[26] <= des_ip[15:8];
                        arp_data[27] <= des_ip[7:0];
                    end
                    if(arp_tx_type == 1'b0)
                        arp_data[7] <= 8'h01;            //ARP���� 
                    else 
                        arp_data[7] <= 8'h02;            //ARPӦ��
                end    
            end                                                                   
            st_preamble : begin                          //����ǰ����+֡��ʼ�綨��
                gmii_tx_en <= 1'b1;
                gmii_txd <= preamble[cnt];
                if(cnt == 6'd7) begin                        
                    skip_en <= 1'b1;
                    cnt <= 1'b0;    
                end
                else    
                    cnt <= cnt + 1'b1;                     
            end
            st_eth_head : begin                          //������̫���ײ�
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= eth_head[cnt];
                if (cnt == 6'd13) begin
                    skip_en <= 1'b1;
                    cnt <= 1'b0;
                end    
                else    
                    cnt <= cnt + 1'b1;    
            end                    
            st_arp_data : begin                          //����ARP����  
                crc_en <= 1'b1;
                gmii_tx_en <= 1'b1;
                //���ٷ���46���ֽ�
                if (cnt == MIN_DATA_NUM - 1'b1) begin    
                    skip_en <= 1'b1;
                    cnt <= 1'b0;
                    data_cnt <= 1'b0;
                end    
                else    
                    cnt <= cnt + 1'b1;  
                if(data_cnt <= 6'd27) begin
                    data_cnt <= data_cnt + 1'b1;
                    gmii_txd <= arp_data[data_cnt];
                end    
                else
                    gmii_txd <= 8'd0;                    //Padding,���0
            end
            st_crc      : begin                          //����CRCУ��ֵ
                gmii_tx_en <= 1'b1;
                cnt <= cnt + 1'b1;
                if(cnt == 6'd0)
                    gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2],~crc_next[3],
                                 ~crc_next[4], ~crc_next[5], ~crc_next[6],~crc_next[7]};
                else if(cnt == 6'd1)
                    gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18],
                                 ~crc_data[19], ~crc_data[20], ~crc_data[21], 
                                 ~crc_data[22],~crc_data[23]};
                else if(cnt == 6'd2) begin
                    gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10],
                                 ~crc_data[11],~crc_data[12], ~crc_data[13], 
                                 ~crc_data[14],~crc_data[15]};                              
                end
                else if(cnt == 6'd3) begin
                    gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2],~crc_data[3],
                                 ~crc_data[4], ~crc_data[5], ~crc_data[6],~crc_data[7]};  
                    tx_done_t <= 1'b1;
                    skip_en <= 1'b1;
                    cnt <= 1'b0;
                end                                                                                                                                            
            end                          
            default :;  
        endcase                                             
    end
end            

//��������źż�crcֵ��λ�ź�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_done <= 1'b0;
        crc_clr <= 1'b0;
    end
    else begin
        tx_done <= tx_done_t;
        crc_clr <= tx_done_t;
    end
end

endmodule