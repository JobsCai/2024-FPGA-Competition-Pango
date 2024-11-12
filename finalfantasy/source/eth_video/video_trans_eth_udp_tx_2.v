module video_trans_eth_udp_tx_2(    
    input                clk        , //ʱ���ź�
    input                rst_n      , //��λ�źţ��͵�ƽ��Ч
    
    input                tx_start_en, //��̫����ʼ�����ź�
    input        [31:0]  tx_data    , //��̫������������  
    input        [15:0]  tx_byte_num, //��̫�����͵���Ч�ֽ���
    input        [47:0]  des_mac    , //���͵�Ŀ��MAC��ַ
    input        [31:0]  des_ip     , //���͵�Ŀ��IP��ַ    
    input        [31:0]  crc_data   , //CRCУ������
    input         [7:0]  crc_next   , //CRC�´�У���������
    output  reg          tx_done    , //��̫����������ź�
    output  reg          tx_req     , //�����������ź�
    output  reg          gmii_tx_en , //GMII���������Ч�ź�
    output  reg  [7:0]   gmii_txd   , //GMII�������
    output  reg          crc_en     , //CRC��ʼУ��ʹ��
    output  reg          crc_clr      //CRC���ݸ�λ�ź� 
    );

//parameter define
//������MAC��ַ 00-11-22-33-44-55
parameter BOARD_MAC = 48'h00_11_22_33_44_55;
//������IP��ַ 192.168.1.123     
parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd123}; 
//Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff;
//Ŀ��IP��ַ 192.168.1.102     
parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102};

localparam  st_idle      = 7'b000_0001; //��ʼ״̬���ȴ���ʼ�����ź�
localparam  st_check_sum = 7'b000_0010; //IP�ײ�У���
localparam  st_preamble  = 7'b000_0100; //����ǰ����+֡��ʼ�綨��
localparam  st_eth_head  = 7'b000_1000; //������̫��֡ͷ
localparam  st_ip_head   = 7'b001_0000; //����IP�ײ�+UDP�ײ�
localparam  st_tx_data   = 7'b010_0000; //��������
localparam  st_crc       = 7'b100_0000; //����CRCУ��ֵ

localparam  ETH_TYPE     = 16'h0800  ;  //��̫��Э������ IPЭ��
//��̫��������С46���ֽڣ�IP�ײ�20���ֽ�+UDP�ײ�8���ֽ�
//������������46-20-8=18���ֽ�
localparam  MIN_DATA_NUM = 16'd18    ;    

//reg define
reg  [6:0]   cur_state      ;
reg  [6:0]   next_state     ;
                            
reg  [7:0]   preamble[7:0]  ; //ǰ����
reg  [7:0]   eth_head[13:0] ; //��̫���ײ�
reg  [31:0]  ip_head[6:0]   ; //IP�ײ� + UDP�ײ�
                            
reg          start_en_d0    ;
reg          start_en_d1    ;
reg  [15:0]  tx_data_num    ; //���͵���Ч�����ֽڸ���
reg  [15:0]  total_num      ; //���ֽ���
reg          trig_tx_en     ;
reg  [15:0]  udp_num        ; //UDP�ֽ���
reg          skip_en        ; //����״̬��תʹ���ź�
reg  [4:0]   cnt            ;
reg  [31:0]  check_buffer   ; //�ײ�У���
reg  [1:0]   tx_bit_sel     ;
reg  [15:0]  data_cnt       ; //�������ݸ���������
reg          tx_done_t      ;
reg  [4:0]   real_add_cnt   ; //��̫������ʵ�ʶ෢���ֽ���
                                    
//wire define                       
wire         pos_start_en    ;//��ʼ��������������
wire [15:0]  real_tx_data_num;//ʵ�ʷ��͵��ֽ���(��̫�������ֽ�Ҫ��)
//*****************************************************
//**                    main code
//*****************************************************

assign  pos_start_en = (~start_en_d1) & start_en_d0;
assign  real_tx_data_num = (tx_data_num >= MIN_DATA_NUM) 
                           ? tx_data_num : MIN_DATA_NUM; 
                           
//��tx_start_en��������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_en_d0 <= 1'b0;
        start_en_d1 <= 1'b0;
    end    
    else begin
        start_en_d0 <= tx_start_en;
        start_en_d1 <= start_en_d0;
    end
end 

//�Ĵ�������Ч�ֽ�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_data_num <= 16'd0;
        total_num <= 16'd0;
        udp_num <= 16'd0;
    end
    else begin
        if(pos_start_en && cur_state==st_idle) begin
            //���ݳ���
            tx_data_num <= tx_byte_num;        
            //IP���ȣ���Ч����+IP�ײ�����            
            total_num <= tx_byte_num + 16'd28;  
            //UDP���ȣ���Ч����+UDP�ײ�����            
            udp_num <= tx_byte_num + 16'd8;               
        end    
    end
end

//���������ź�
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        trig_tx_en <= 1'b0;
    else
        trig_tx_en <= pos_start_en;

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <= st_idle;  
    else
        cur_state <= next_state;
end

always @(*) begin
    next_state = st_idle;
    case(cur_state)
        st_idle     : begin                               //�ȴ���������
            if(skip_en)                
                next_state = st_check_sum;
            else
                next_state = st_idle;
        end  
        st_check_sum: begin                               //IP�ײ�У��
            if(skip_en)
                next_state = st_preamble;
            else
                next_state = st_check_sum;    
        end                             
        st_preamble : begin                               //����ǰ����+֡��ʼ�綨��
            if(skip_en)
                next_state = st_eth_head;
            else
                next_state = st_preamble;      
        end
        st_eth_head : begin                               //������̫���ײ�
            if(skip_en)
                next_state = st_ip_head;
            else
                next_state = st_eth_head;      
        end              
        st_ip_head : begin                                //����IP�ײ�+UDP�ײ�               
            if(skip_en)
                next_state = st_tx_data;
            else
                next_state = st_ip_head;      
        end
        st_tx_data : begin                                //��������                  
            if(skip_en)
                next_state = st_crc;
            else
                next_state = st_tx_data;      
        end
        st_crc: begin                                     //����CRCУ��ֵ
            if(skip_en)
                next_state = st_idle;
            else
                next_state = st_crc;      
        end
        default : next_state = st_idle;   
    endcase
end                      

//��������
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        skip_en <= 1'b0; 
        cnt <= 5'd0;
        check_buffer <= 32'd0;
        ip_head[1][31:16] <= 16'd0;
        tx_bit_sel <= 2'b0;
        crc_en <= 1'b0;
        gmii_tx_en <= 1'b0;
        gmii_txd <= 8'd0;
        tx_req <= 1'b0;
        tx_done_t <= 1'b0; 
        data_cnt <= 16'd0;
        real_add_cnt <= 5'd0;
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
        //Ŀ��MAC��ַ
        eth_head[0] <= DES_MAC[47:40];
        eth_head[1] <= DES_MAC[39:32];
        eth_head[2] <= DES_MAC[31:24];
        eth_head[3] <= DES_MAC[23:16];
        eth_head[4] <= DES_MAC[15:8];
        eth_head[5] <= DES_MAC[7:0];
        //ԴMAC��ַ
        eth_head[6] <= BOARD_MAC[47:40];
        eth_head[7] <= BOARD_MAC[39:32];
        eth_head[8] <= BOARD_MAC[31:24];
        eth_head[9] <= BOARD_MAC[23:16];
        eth_head[10] <= BOARD_MAC[15:8];
        eth_head[11] <= BOARD_MAC[7:0];
        //��̫������
        eth_head[12] <= ETH_TYPE[15:8];
        eth_head[13] <= ETH_TYPE[7:0];        
    end
    else begin
        skip_en <= 1'b0;
        tx_req <= 1'b0;
        crc_en <= 1'b0;
        gmii_tx_en <= 1'b0;
        tx_done_t <= 1'b0;
        case(next_state)
            st_idle     : begin
                if(trig_tx_en) begin
                    skip_en <= 1'b1; 
                    //�汾�ţ�4 �ײ����ȣ�5(��λ:32bit,20byte/4=5)
                    ip_head[0] <= {8'h45,8'h00,total_num};   
                    //16λ��ʶ��ÿ�η����ۼ�1      
                    ip_head[1][31:16] <= ip_head[1][31:16] + 1'b1; 
                    //bit[15:13]: 010��ʾ����Ƭ
                    ip_head[1][15:0] <= 16'h4000;    
                    //Э�飺17(udp)                  
                    ip_head[2] <= {8'h40,8'd17,16'h0};   
                    //ԴIP��ַ               
                    ip_head[3] <= BOARD_IP;
                    //Ŀ��IP��ַ    
                    if(des_ip != 32'd0)
                        ip_head[4] <= des_ip;
                    else
                        ip_head[4] <= DES_IP;       
                    //16λԴ�˿ںţ�1234  16λĿ�Ķ˿ںţ�1234                      
                    ip_head[5] <= {16'd2345,16'd2345};  
                    //16λudp���ȣ�16λudpУ���              
                    ip_head[6] <= {udp_num,16'h0000};  
                    //����MAC��ַ
                    if(des_mac != 48'b0) begin
                        //Ŀ��MAC��ַ
                        eth_head[0] <= des_mac[47:40];
                        eth_head[1] <= des_mac[39:32];
                        eth_head[2] <= des_mac[31:24];
                        eth_head[3] <= des_mac[23:16];
                        eth_head[4] <= des_mac[15:8];
                        eth_head[5] <= des_mac[7:0];
                    end
                end    
            end                                                       
            st_check_sum: begin                           //IP�ײ�У��
                cnt <= cnt + 5'd1;
                if(cnt == 5'd0) begin                   
                    check_buffer <= ip_head[0][31:16] + ip_head[0][15:0]
                                    + ip_head[1][31:16] + ip_head[1][15:0]
                                    + ip_head[2][31:16] + ip_head[2][15:0]
                                    + ip_head[3][31:16] + ip_head[3][15:0]
                                    + ip_head[4][31:16] + ip_head[4][15:0];
                end
                else if(cnt == 5'd1)                      //���ܳ��ֽ�λ,�ۼ�һ��
                    check_buffer <= check_buffer[31:16] + check_buffer[15:0];
                else if(cnt == 5'd2) begin                //�����ٴγ��ֽ�λ,�ۼ�һ��
                    check_buffer <= check_buffer[31:16] + check_buffer[15:0];
                end                             
                else if(cnt == 5'd3) begin                //��λȡ�� 
                    skip_en <= 1'b1;
                    cnt <= 5'd0;            
                    ip_head[2][15:0] <= ~check_buffer[15:0];
                end    
            end              
            st_preamble : begin                           //����ǰ����+֡��ʼ�綨��
                gmii_tx_en <= 1'b1;
                gmii_txd <= preamble[cnt];
                if(cnt == 5'd7) begin                        
                    skip_en <= 1'b1;
                    cnt <= 5'd0;    
                end
                else    
                    cnt <= cnt + 5'd1;                     
            end
            st_eth_head : begin                           //������̫���ײ�
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= eth_head[cnt];
                if (cnt == 5'd13) begin
                    skip_en <= 1'b1;
                    cnt <= 5'd0;
                end    
                else    
                    cnt <= cnt + 5'd1;    
            end                    
            st_ip_head  : begin                           //����IP�ײ� + UDP�ײ�
                crc_en <= 1'b1;
                gmii_tx_en <= 1'b1;
                tx_bit_sel <= tx_bit_sel + 2'd1;
                if(tx_bit_sel == 3'd0)
                    gmii_txd <= ip_head[cnt][31:24];
                else if(tx_bit_sel == 3'd1)
                    gmii_txd <= ip_head[cnt][23:16];
                else if(tx_bit_sel == 3'd2) begin
                    gmii_txd <= ip_head[cnt][15:8];
                    if(cnt == 5'd6) begin
                        //��ǰ���������ݣ��ȴ�������Чʱ����
                        tx_req <= 1'b1;                     
                    end
                end 
                else if(tx_bit_sel == 3'd3) begin
                    gmii_txd <= ip_head[cnt][7:0];  
                    if(cnt == 5'd6) begin
                        skip_en <= 1'b1;   
                        cnt <= 5'd0;
                    end    
                    else
                        cnt <= cnt + 5'd1;  
                end        
            end
            st_tx_data  : begin                           //��������
                crc_en <= 1'b1;
                gmii_tx_en <= 1'b1;
                tx_bit_sel <= tx_bit_sel + 3'd1;  
                if(data_cnt < tx_data_num - 16'd1)
                    data_cnt <= data_cnt + 16'd1;                        
                else if(data_cnt == tx_data_num - 16'd1)begin
                    //������͵���Ч��������18���ֽڣ��ں������λ
                    //�����ֵΪ���һ�η��͵���Ч����
                    gmii_txd <= 8'd0;
                    if(data_cnt + real_add_cnt < real_tx_data_num - 16'd1)
                        real_add_cnt <= real_add_cnt + 5'd1;  
                    else begin
                        skip_en <= 1'b1;
                        data_cnt <= 16'd0;
                        real_add_cnt <= 5'd0;
                        tx_bit_sel <= 3'd0;                        
                    end    
                end
                if(tx_bit_sel == 1'b0)
                    gmii_txd <= tx_data[31:24];
                else if(tx_bit_sel == 3'd1)
                    gmii_txd <= tx_data[23:16];                   
                else if(tx_bit_sel == 3'd2) begin
                    gmii_txd <= tx_data[15:8];   
                    if(data_cnt != tx_data_num - 16'd1)
                        tx_req <= 1'b1;  
                end
                else if(tx_bit_sel == 3'd3)
                    gmii_txd <= tx_data[7:0];                                                                                                
            end  
            st_crc      : begin                          //����CRCУ��ֵ
                gmii_tx_en <= 1'b1;
                tx_bit_sel <= tx_bit_sel + 3'd1;
                if(tx_bit_sel == 3'd0)
                    gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2],~crc_next[3],
                                 ~crc_next[4], ~crc_next[5], ~crc_next[6],~crc_next[7]};
                else if(tx_bit_sel == 3'd1)
                    gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18],~crc_data[19],
                                 ~crc_data[20], ~crc_data[21], ~crc_data[22],~crc_data[23]};
                else if(tx_bit_sel == 3'd2) begin
                    gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10],~crc_data[11],
                                 ~crc_data[12], ~crc_data[13], ~crc_data[14],~crc_data[15]};                              
                end
                else if(tx_bit_sel == 3'd3) begin
                    gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2],~crc_data[3],
                                 ~crc_data[4], ~crc_data[5], ~crc_data[6],~crc_data[7]};  
                    tx_done_t <= 1'b1;
                    skip_en <= 1'b1;
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

