//************************************************
// Author       : Jack
// Create Date  : 2023年4月17日 8:55:36
// File Name    : image_2x2.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module image_2x2#(
    parameter DATA_WIDTH    = 24        ,
    parameter FRAME_H_PIXEL = 1920      
)(
    input   wire                        clk             ,
    input   wire                        rst_n           ,
    input   wire                        frame_rst       ,
    
    input   wire                        frame_i_vs      ,
    input   wire                        frame_i_hs      ,
    input   wire                        frame_i_valid   ,
    input   wire    [DATA_WIDTH-1:0]    frame_i_data    ,
    
    output  reg                         frame_o_vs      ,
    output  reg                         frame_o_hs      ,
    output  reg                         frame_o_valid   ,
    output  reg     [DATA_WIDTH-1:0]    frame_o_data_0  ,
    output  wire    [DATA_WIDTH-1:0]    frame_o_data_1  ,
    output  reg     [DATA_WIDTH-1:0]    frame_o_data_2  ,
    output  reg     [DATA_WIDTH-1:0]    frame_o_data_3  
);
/****************************reg*****************************/
reg     [10:0]      pix_x       ; // 行坐标

/****************************wire****************************/


/********************combinational logic*********************/


/***********************instantiation************************/
s_d_ram_2048x24 u_s_d_ram_2048x24(
    .wr_data        (frame_i_data   ), // input [23:0]
    .wr_addr        (pix_x          ), // input [10:0]
    .wr_en          (frame_i_valid  ), // input
    .wr_clk         (clk            ), // input
    .wr_rst         (!rst_n || frame_rst), // input
    .rd_addr        (pix_x          ), // input [10:0]
    .rd_data        (frame_o_data_1 ), // output [23:0]
    .rd_clk         (clk            ), // input
    .rd_rst         (!rst_n || frame_rst) // input
);

/**************************process***************************/
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        pix_x <= 10'd0;
    else if(frame_rst)
        pix_x <= 10'd0;
    else if(frame_i_valid)
        if(pix_x == FRAME_H_PIXEL - 1'b1)
            pix_x <= 10'd0;
        else
            pix_x <= pix_x + 1'b1;
    else
        pix_x <= pix_x;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        frame_o_data_0 <= 'd0;
    else
        frame_o_data_0 <= frame_o_data_1;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        frame_o_data_3 <= 'd0;
    else
        frame_o_data_3 <= frame_i_data;
end

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        frame_o_data_2 <= 'd0;
    else
        frame_o_data_2 <= frame_o_data_3;
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
            frame_o_vs    <= frame_i_vs   ;
            frame_o_hs    <= frame_i_hs   ;
            frame_o_valid <= frame_i_valid;
        end
end

endmodule
