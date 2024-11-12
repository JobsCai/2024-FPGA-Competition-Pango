`timescale 1ns / 1ps
`define UD #1
module key_ctl(
    input                           sys_clk            ,
    input                           sys_rst_n   ,  //��λ�ź�
    input							key1			   ,                          
    input							key2			   ,                     
    input							key3			   ,
    input							key4			   ,// ����ģʽ0���ǵ�������                        
    input							key5			   ,// ����ģʽ0���ǵ���ɫ�Ⱥ�ɫ       
    input							key6			   ,// ����ģʽ0���ǵ���ɫ����ɫ    
    input							key7			   ,// ����ģʽ0���ǵ���ɫ����ɫ
    input	                        vs_in              ,
    input                           hs_in              ,
    input                           de_in              ,
    input                        [15:0]   img_data           ,
    

    output    lighter_and_color_hs      ,
    output    lighter_and_color_vs      ,
    output    lighter_and_color_de      ,
    output   [15:0] lighter_and_color_data  
                
);
//����12����change_en


   

//reg define
reg            key1_d0      ;
reg            key1_d1      ;
reg            key2_d0      ;
reg            key2_d1      ;
reg     [23:0] key1_cnt_time;
reg     [23:0] key2_cnt_time;
reg            key1_pulse   ; 
reg            key2_pulse   ;
reg   [2:0]  r_ctrl_plus10    ;  //key5
reg   [2:0]  g_ctrl_plus10    ;  //key6
reg   [2:0]  b_ctrl_plus10    ; //key7 
reg   [2:0]  rgb_ctrl_plus10  ;

//*****************************************************
//** main code
//*****************************************************

//�Դ��������˿ڵ������ӳ�����ʱ������ 
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key1_d0 <= 1'b0;
        key1_d1 <= 1'b0;
        key2_d0 <= 1'b0;
        key2_d1 <= 1'b0;
        key3_d0 <= 1'b0;
        key3_d1 <= 1'b0;
        key4_d0 <= 1'b0;
        key4_d1 <= 1'b0;
        key5_d0 <= 1'b0;
        key5_d1 <= 1'b0;
        key6_d0 <= 1'b0;
        key6_d1 <= 1'b0;
        key7_d0 <= 1'b0;
        key7_d1 <= 1'b0;
    end
    else begin
        key1_d0 <= key1;
        key1_d1 <= key1_d0;
        key2_d0 <= key2;
        key2_d1 <= key2_d0;
        key3_d0 <= key3;
        key3_d1 <= key3_d0;
        key4_d0 <= key4;
        key4_d1 <= key4_d0;
        key5_d0 <= key5;
        key5_d1 <= key5_d0;
        key6_d0 <= key6;
        key6_d1 <= key6_d0;
        key7_d0 <= key7;
        key7_d1 <= key7_d0;

    end 
end


//�԰���1�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key1_cnt_time <= 24'b0;
    end
    else begin
        if(key1_d1)
            key1_cnt_time <= 24'b0; 
        else if(key1_cnt_time >= 2500000)  
            key1_cnt_time <= key1_cnt_time;
        else
            key1_cnt_time <= key1_cnt_time + 1;                 
    end 
end

//�԰���2�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key2_cnt_time <= 24'b0;
    end
    else begin
        if(key2_d1)
            key2_cnt_time <= 24'b0; 
        else if(key2_cnt_time >= 2500000)  
            key2_cnt_time <= key2_cnt_time;
        else
            key2_cnt_time <= key2_cnt_time + 1;                 
    end 
end

//��������1����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key1_pulse <= 1'b0;
    else if(key1_cnt_time == 500_000) 
        key1_pulse <= 1'b1;
    else 
        key1_pulse <= 1'b0;
end

//��������2����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key2_pulse <= 1'b0;
    else if(key2_cnt_time == 500_000) 
        key2_pulse <= 1'b1;
    else 
        key2_pulse <= 1'b0;
end



//����3�л�����ģʽ
reg            key3_d0      ;
reg            key3_d1      ;
reg     [23:0] key3_cnt_time;
reg            key3_pulse   ; 



//�԰���3�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key3_cnt_time <= 24'b0;
    end
    else begin
        if(key3_d1)
            key3_cnt_time <= 24'b0; 
        else if(key3_cnt_time >= 2500000)  
            key3_cnt_time <= key3_cnt_time;
        else
            key3_cnt_time <= key3_cnt_time + 1;                 
    end 
end

//��������3����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key3_pulse <= 1'b0;
    else if(key3_cnt_time == 500_000) 
        key3_pulse <= 1'b1;
    else 
        key3_pulse <= 1'b0;
end


//����4��������
reg            key4_d0      ;
reg            key4_d1      ;
reg     [23:0] key4_cnt_time;
reg            key4_pulse   ; 



//�԰���2�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key4_cnt_time <= 24'b0;
    end
    else begin
        if(key4_d1)
            key4_cnt_time <= 24'b0; 
        else if(key4_cnt_time >= 2500000)  
            key4_cnt_time <= key4_cnt_time;
        else
            key4_cnt_time <= key4_cnt_time + 1;                 
    end 
end

//��������1����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key4_pulse <= 1'b0;
    else if(key4_cnt_time == 500_000) 
        key4_pulse <= 1'b1;
    else 
        key4_pulse <= 1'b0;
end
//����5�л�redģʽ
reg            key5_d0      ;
reg            key5_d1      ;
reg     [23:0] key5_cnt_time;
reg            key5_pulse   ; 

//�԰���3�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key5_cnt_time <= 24'b0;
    end
    else begin
        if(key5_d1)
            key5_cnt_time <= 24'b0; 
        else if(key5_cnt_time >= 2500000)  
            key5_cnt_time <= key5_cnt_time;
        else
            key5_cnt_time <= key5_cnt_time + 1;                 
    end 
end

//��������3����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key5_pulse <= 1'b0;
    else if(key5_cnt_time == 500_000) 
        key5_pulse <= 1'b1;
    else 
        key5_pulse <= 1'b0;
end

//����6�л�greenģʽ
reg            key6_d0      ;
reg            key6_d1      ;
reg     [23:0] key6_cnt_time;
reg            key6_pulse   ; 

//�԰���3�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key6_cnt_time <= 24'b0;
    end
    else begin
        if(key6_d1)
            key6_cnt_time <= 24'b0; 
        else if(key6_cnt_time >= 2500000)  
            key6_cnt_time <= key6_cnt_time;
        else
            key6_cnt_time <= key6_cnt_time + 1;                 
    end 
end

//��������3����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key6_pulse <= 1'b0;
    else if(key6_cnt_time == 500_000) 
        key6_pulse <= 1'b1;
    else 
        key6_pulse <= 1'b0;
end

//����7�л�blueģʽ
reg            key7_d0      ;
reg            key7_d1      ;
reg     [23:0] key7_cnt_time;
reg            key7_pulse   ; 

//�԰���3�ĵ͵�ƽʱ����м���
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        key7_cnt_time <= 24'b0;
    end
    else begin
        if(key7_d1)
            key7_cnt_time <= 24'b0; 
        else if(key7_cnt_time >= 2500000)  
            key7_cnt_time <= key7_cnt_time;
        else
            key7_cnt_time <= key7_cnt_time + 1;                 
    end 
end

always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        r_ctrl_plus10<=0;
    end
    else if(1) begin
        if(key5_pulse)
            r_ctrl_plus10<=r_ctrl_plus10+1;
        else
            r_ctrl_plus10<=r_ctrl_plus10;
        end
end

//��������3����
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)
        key7_pulse <= 1'b0;
    else if(key7_cnt_time == 500_000) 
        key7_pulse <= 1'b1;
    else 
        key7_pulse <= 1'b0;
end



//�л�����rgb_ctrl_plus10
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        rgb_ctrl_plus10<=0;
    end
    else if(1) begin
        if(key4_pulse)begin
            rgb_ctrl_plus10<=rgb_ctrl_plus10+1;
        end
        else
            rgb_ctrl_plus10<=rgb_ctrl_plus10;
        end
end

//�л�����������g_ctrl_plus10
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        g_ctrl_plus10<=0;
    end
    else if(1) begin
        if(key6_pulse)
            g_ctrl_plus10<=g_ctrl_plus10+1;
        else
            g_ctrl_plus10<=g_ctrl_plus10;
        end
end

//�л�����������b_ctrl_plus10
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        b_ctrl_plus10<=0;
    end
    else if(1) begin
        if(key7_pulse)
            b_ctrl_plus10<=b_ctrl_plus10+1;
        else
            b_ctrl_plus10<=b_ctrl_plus10;
        end
end

wire    lighter_and_color_hs;
wire    lighter_and_color_vs;
wire    lighter_and_color_de;
wire   [15:0] lighter_and_color_data /* synthesis PAP_MARK_DEBUG="true" */;

lighter_and_color lighter_and_color(
//input
//	input		r_ctrl_plus10;//����r
//	input		g_ctrl_plus10;//����g
//	input		b_ctrl_plus10;//����b
	.rgb_ctrl_plus10(rgb_ctrl_plus10) ,//����rgb����4������
    .r_ctrl_plus10(r_ctrl_plus10)     ,
    .g_ctrl_plus10(g_ctrl_plus10)     ,
    .b_ctrl_plus10(b_ctrl_plus10)     ,   


	.clk(sys_clk),
	.rst_n(sys_rst_n),

	.hs_in(hs_in),
	.vs_in(vs_in),
	.de_in(de_in),
	.data_in(img_data),

//output
	.hs_out(lighter_and_color_hs),
	.vs_out(lighter_and_color_vs),
	.de_out(lighter_and_color_de),
	.data_out(lighter_and_color_data)
);



endmodule

/*
//��change_en����00000_1_00000,˵�����ڷŴ�״̬
assign scale_state = (change_en >= 128) ? 1'b1 : 1'b0;
// assign scale_state = (width_change >= 1080&&height_change>=1920) ? 1'b1 : 1'b0;

//����change_en
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        change_en <= 13'b0000001000000; //ԭʼ�ߴ���11'b00000100000,1�����ƷŴ�,��������С
    end
    else if (working_mode==0)begin
    case({key1_pulse,key2_pulse})
         2'b01:
          begin
                if(change_en == 11'b100000_0_000000)
                    change_en <= 11'b000000_1_000000; 
                else
                    change_en <= change_en<<1; 
          end
        2'b10:
        begin
                if(change_en == 11'b000000_0_000001)
                    change_en <= 11'b000000_1_000000; 
                else
                    change_en <= change_en>>1;  
        end
        default:    change_en <= change_en;
    endcase
    end
end

//����12 45����    ��һ��5
reg    [12:0] height_change=1080;
reg    [12:0] width_change=1920;
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        width_change <= 1920;
        height_change <=1080;
    end
    else if (working_mode==2)begin
    case({key1_pulse,key2_pulse,key4_pulse,key5_pulse})
         4'b0001://height_change   minus
          begin
              height_change<=height_change-10;      
          end
        4'b0010://height_change   plus
        begin
          height_change<=height_change+10;
        end
        4'b0100://width_change   minus
        begin
            width_change<=width_change-10;
        end

        4'b1000://width_change  plus
        begin
            width_change<=width_change+10;
        end
        default:    begin
                width_change <= width_change;
                height_change <=height_change;
            end
    endcase
    end
end
//����1��ʾ�Ҷ�ģʽ
reg change_yuv;
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        change_yuv<=0;
    end
    else if(working_mode==1) begin
        if(key1_pulse)
            change_yuv<=~change_yuv;
        else
            change_yuv<=change_yuv;
    end
end

//change_gauss_filter����1��ʾ��˹�˲�
reg change_gauss_filter;
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        change_gauss_filter<=0;
    end
    else if(working_mode==1) begin
        if(key2_pulse)
            change_gauss_filter<=~change_gauss_filter;
        else
            change_gauss_filter<=change_gauss_filter;
        end
end*/

/*
//key4�л�����change_sobel
reg change_sobel;
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        change_sobel<=0;
    end
    else if(working_mode==1) begin
        if(key4_pulse)begin
            change_sobel<=~change_sobel;
        end
        else
            change_sobel<=change_sobel;
        end
end

//�л�����������change_yuv
*/


//key5�л�����threshold+
/*reg [20:0] threshold=21'd15;
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        threshold<=0;
    end
    else if(working_mode==1) begin
        case({key5_pulse,key6_pulse})
        2'b10:threshold<=threshold+5;
        2'b01:threshold<=threshold-5;
        default:threshold<=threshold;
        endcase
    end
end*/

//key6�л�����threshold-