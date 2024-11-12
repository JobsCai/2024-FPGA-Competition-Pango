//************************************************
// Author       : Jack
// Create Date  : 2023年4月17日 9:21:41
// File Name    : bilinear_calculator.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module bilinear_calculator#(
    parameter DATA_WIDTH    = 24        ,
    parameter RGB_R_WIDTH   = 8         ,
    parameter RGB_G_WIDTH   = 8         ,
    parameter RGB_B_WIDTH   = 8         
)(
    input   wire                        clk             ,
    input   wire                        rst_n           ,
    input   wire                        frame_rst       ,
    
    input   wire                        frame_i_vs      ,
    input   wire                        frame_i_hs      ,
    input   wire                        frame_i_valid   ,
    input   wire    [DATA_WIDTH-1:0]    frame_i_data_0  ,
    input   wire    [DATA_WIDTH-1:0]    frame_i_data_1  ,
    input   wire    [DATA_WIDTH-1:0]    frame_i_data_2  ,
    input   wire    [DATA_WIDTH-1:0]    frame_i_data_3  ,
    
    output  reg                         frame_o_vs      ,
    output  reg                         frame_o_hs      ,
    output  reg                         frame_o_valid   ,
    output  wire    [DATA_WIDTH-1:0]    frame_o_data    
);
/*************************parameter**************************/


/****************************reg*****************************/
reg                         r0_frame_i_hs   ;
reg                         r1_frame_i_hs   ;

reg                         r_frame_h_valid ; // 行有效
reg                         r_frame_v_valid ; // 列有效

reg     [RGB_R_WIDTH-1:0]   r_frame_o_r     ;
reg     [RGB_G_WIDTH-1:0]   r_frame_o_g     ;
reg     [RGB_B_WIDTH-1:0]   r_frame_o_b     ;

reg     [RGB_R_WIDTH-1:0]   r_frame_r_0     ;
reg     [RGB_R_WIDTH-1:0]   r_frame_r_1     ;
reg     [RGB_R_WIDTH-1:0]   r_frame_r_2     ;
reg     [RGB_R_WIDTH-1:0]   r_frame_r_3     ;
reg     [RGB_G_WIDTH-1:0]   r_frame_g_0     ;
reg     [RGB_G_WIDTH-1:0]   r_frame_g_1     ;
reg     [RGB_G_WIDTH-1:0]   r_frame_g_2     ;
reg     [RGB_G_WIDTH-1:0]   r_frame_g_3     ;
reg     [RGB_B_WIDTH-1:0]   r_frame_b_0     ;
reg     [RGB_B_WIDTH-1:0]   r_frame_b_1     ;
reg     [RGB_B_WIDTH-1:0]   r_frame_b_2     ;
reg     [RGB_B_WIDTH-1:0]   r_frame_b_3     ;

reg                         r_frame_vs      ;
reg                         r_frame_hs      ;
reg                         r_frame_valid   ;

/****************************wire****************************/
wire                        frame_i_hs_posedge;
wire                        frame_data_valid; // 开始计算

wire    [RGB_R_WIDTH-1:0]   frame_i_r_0     ;
wire    [RGB_R_WIDTH-1:0]   frame_i_r_1     ;
wire    [RGB_R_WIDTH-1:0]   frame_i_r_2     ;
wire    [RGB_R_WIDTH-1:0]   frame_i_r_3     ;
wire    [RGB_G_WIDTH-1:0]   frame_i_g_0     ;
wire    [RGB_G_WIDTH-1:0]   frame_i_g_1     ;
wire    [RGB_G_WIDTH-1:0]   frame_i_g_2     ;
wire    [RGB_G_WIDTH-1:0]   frame_i_g_3     ;
wire    [RGB_B_WIDTH-1:0]   frame_i_b_0     ;
wire    [RGB_B_WIDTH-1:0]   frame_i_b_1     ;
wire    [RGB_B_WIDTH-1:0]   frame_i_b_2     ;
wire    [RGB_B_WIDTH-1:0]   frame_i_b_3     ;

/********************combinational logic*********************/
assign frame_i_hs_posedge = r0_frame_i_hs && (!r1_frame_i_hs);
assign frame_data_valid   = r_frame_h_valid && r_frame_v_valid;

assign frame_i_r_0        = frame_i_data_0[DATA_WIDTH-1:DATA_WIDTH-RGB_R_WIDTH];
assign frame_i_r_1        = frame_i_data_1[DATA_WIDTH-1:DATA_WIDTH-RGB_R_WIDTH];
assign frame_i_r_2        = frame_i_data_2[DATA_WIDTH-1:DATA_WIDTH-RGB_R_WIDTH];
assign frame_i_r_3        = frame_i_data_3[DATA_WIDTH-1:DATA_WIDTH-RGB_R_WIDTH];
assign frame_i_g_0        = frame_i_data_0[RGB_B_WIDTH+RGB_G_WIDTH-1:RGB_B_WIDTH];
assign frame_i_g_1        = frame_i_data_1[RGB_B_WIDTH+RGB_G_WIDTH-1:RGB_B_WIDTH];
assign frame_i_g_2        = frame_i_data_2[RGB_B_WIDTH+RGB_G_WIDTH-1:RGB_B_WIDTH];
assign frame_i_g_3        = frame_i_data_3[RGB_B_WIDTH+RGB_G_WIDTH-1:RGB_B_WIDTH];
assign frame_i_b_0        = frame_i_data_0[RGB_B_WIDTH-1:0];
assign frame_i_b_1        = frame_i_data_1[RGB_B_WIDTH-1:0];
assign frame_i_b_2        = frame_i_data_2[RGB_B_WIDTH-1:0];
assign frame_i_b_3        = frame_i_data_3[RGB_B_WIDTH-1:0];

assign frame_o_data       = {r_frame_o_r, r_frame_o_g, r_frame_o_b};

/**************************process***************************/
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r0_frame_i_hs <= 1'b0;
            r1_frame_i_hs <= 1'b0;
        end
    else
        begin
            r0_frame_i_hs <= frame_i_hs;
            r1_frame_i_hs <= r0_frame_i_hs;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_frame_h_valid <= 1'b0;
    else if(frame_rst)
        r_frame_h_valid <= 1'b0;
    else if(frame_i_valid)
        r_frame_h_valid <= !r_frame_h_valid;
    else
        r_frame_h_valid <= r_frame_h_valid;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        r_frame_v_valid <= 1'b1;
    else if(frame_rst)
        r_frame_v_valid <= 1'b1;
    else if(frame_i_hs_posedge)
        r_frame_v_valid <= !r_frame_v_valid;
    else
        r_frame_v_valid <= r_frame_v_valid;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r_frame_r_0 <= 'd0;
            r_frame_g_0 <= 'd0;
            r_frame_b_0 <= 'd0;
            r_frame_r_1 <= 'd0;
            r_frame_g_1 <= 'd0;
            r_frame_b_1 <= 'd0;
            r_frame_r_2 <= 'd0;
            r_frame_g_2 <= 'd0;
            r_frame_b_2 <= 'd0;
            r_frame_r_3 <= 'd0;
            r_frame_g_3 <= 'd0;
            r_frame_b_3 <= 'd0;
        end
    else
        begin
            r_frame_r_0 <= frame_i_r_0 >> 2;
            r_frame_g_0 <= frame_i_g_0 >> 2;
            r_frame_b_0 <= frame_i_b_0 >> 2;
            r_frame_r_1 <= frame_i_r_1 >> 2;
            r_frame_g_1 <= frame_i_g_1 >> 2;
            r_frame_b_1 <= frame_i_b_1 >> 2;
            r_frame_r_2 <= frame_i_r_2 >> 2;
            r_frame_g_2 <= frame_i_g_2 >> 2;
            r_frame_b_2 <= frame_i_b_2 >> 2;
            r_frame_r_3 <= frame_i_r_3 >> 2;
            r_frame_g_3 <= frame_i_g_3 >> 2;
            r_frame_b_3 <= frame_i_b_3 >> 2;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r_frame_o_r <= 'd0;
            r_frame_o_g <= 'd0;
            r_frame_o_b <= 'd0;
        end
    else
        begin
            r_frame_o_r <= r_frame_r_0 + r_frame_r_1 + r_frame_r_2 + r_frame_r_3;
            r_frame_o_g <= r_frame_g_0 + r_frame_g_1 + r_frame_g_2 + r_frame_g_3;
            r_frame_o_b <= r_frame_b_0 + r_frame_b_1 + r_frame_b_2 + r_frame_b_3;
        end
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r_frame_vs    <= 1'b0;
            r_frame_hs    <= 1'b0;
            r_frame_valid <= 1'b0;
        end
    else
        begin
            r_frame_vs    <= frame_i_vs;
            r_frame_hs    <= frame_i_hs;
            r_frame_valid <= frame_data_valid;
        end
end


always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            frame_o_vs    <= 1'b0;
            frame_o_hs    <= 1'b0;
            frame_o_valid <= 1'b0;
        end
    else
        begin
            frame_o_vs    <= r_frame_vs;
            frame_o_hs    <= r_frame_hs;
            frame_o_valid <= r_frame_valid;
        end
end

endmodule
