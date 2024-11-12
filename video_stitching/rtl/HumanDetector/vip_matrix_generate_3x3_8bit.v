module  vip_matrix_generate_3x3_8bit
(
    input             clk,  
    input             rst_n,

    input             pre_frame_vsync,
    input             pre_frame_href,
    input             pre_frame_clken,
    input      [7:0]  pre_img_y,
    
    output            matrix_frame_vsync,
    output            matrix_frame_href,
    output            matrix_frame_clken,
    output reg [7:0]  matrix_p11,
    output reg [7:0]  matrix_p12, 
    output reg [7:0]  matrix_p13,
    output reg [7:0]  matrix_p21, 
    output reg [7:0]  matrix_p22, 
    output reg [7:0]  matrix_p23,
    output reg [7:0]  matrix_p31, 
    output reg [7:0]  matrix_p32, 
    output reg [7:0]  matrix_p33
);

//wire define
wire [7:0] row1_data;  
wire [7:0] row2_data;  
wire       read_frame_href;
wire       read_frame_clken;

//reg define
reg  [7:0] pre_img_y_d[2:0];
reg  [7:0] row3_data;  
reg  [4:0] pre_frame_vsync_r;
reg  [4:0] pre_frame_href_r;
reg  [4:0] pre_frame_clken_r;

//*****************************************************
//**                    main code
//*****************************************************

assign read_frame_href    = pre_frame_href_r[3] ;
assign read_frame_clken   = pre_frame_clken_r[3];
assign matrix_frame_vsync = pre_frame_vsync_r[4];
assign matrix_frame_href  = pre_frame_href_r[4] ;
assign matrix_frame_clken = pre_frame_clken_r[4];

//��ǰ�����ӳ�4�ĺ���ڵ�3��
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        row3_data <= 0; 
        pre_img_y_d[0] <= 0;
        pre_img_y_d[1] <= 0;
        pre_img_y_d[2] <= 0;  
    end
    else begin
        pre_img_y_d[0] <= pre_img_y;
        pre_img_y_d[1] <= pre_img_y_d[0];
        pre_img_y_d[2] <= pre_img_y_d[1];
        row3_data <= pre_img_y_d[2];
    end
end

//���ڴ洢�����ݵ�RAM
line_shift_ram_8bit  u_line_shift_ram_8bit
(
    .clock          (clk),
    .rst_n          (rst_n),
    .clken          (pre_frame_clken),
    .pre_frame_href (pre_frame_href),
    
    .shiftin        (pre_img_y),   
    .taps0x         (row2_data),   
    .taps1x         (row1_data)    
);

//��ͬ���ź��ӳ�5�ģ�����ͬ��������
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pre_frame_vsync_r <= 0;
        pre_frame_href_r  <= 0;
        pre_frame_clken_r <= 0;
    end
    else begin
        pre_frame_vsync_r <= {pre_frame_vsync_r[3:0] , pre_frame_vsync};
        pre_frame_href_r  <= { pre_frame_href_r[3:0] , pre_frame_href };
        pre_frame_clken_r <= {pre_frame_clken_r[3:0] , pre_frame_clken};
    end
end

//��ͬ��������Ŀ����ź��£����ͼ�����
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        {matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
    end
    else if(read_frame_href) begin
        if(read_frame_clken) begin
            {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p12, matrix_p13, row1_data};
            {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p22, matrix_p23, row2_data};
            {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p32, matrix_p33, row3_data};
        end
        else begin
            {matrix_p11, matrix_p12, matrix_p13} <= {matrix_p11, matrix_p12, matrix_p13};
            {matrix_p21, matrix_p22, matrix_p23} <= {matrix_p21, matrix_p22, matrix_p23};
            {matrix_p31, matrix_p32, matrix_p33} <= {matrix_p31, matrix_p32, matrix_p33};
        end
    end
    else begin
        {matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
    end
end

endmodule 