//************************************************
// Author       : Jack
// Creat Date   : 2023年3月22日 17:29:39
// File Name    : AXI_rw_FIFO.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 通过FIFO里的数据量对simplified_AXI发出读写请求信号
//************************************************

module AXI_rw_FIFO#(
    parameter AXI_DATA_WIDTH    = 256       , // AXI数据位宽
    parameter MEM_BURST_LEN     = 8         , // DDR突发长度
    parameter FIFO_DATA_WIDTH   = 32        , // FIFO用户端数据位宽
    parameter MEM_H_PIXEL       = 960       , // 写入一帧数据行像素
    parameter DISP_H            = 1920        // 读出一帧数据行像素
)(
    input   wire                                ddrphy_clkin        ,
    input   wire                                rst_n               ,
    
    input   wire                                video0_wr_clk       ,
    input   wire                                video0_wr_en        ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video0_wr_data      ,
    input   wire                                video0_wr_rst       ,

    input   wire                                video1_wr_clk       ,
    input   wire                                video1_wr_en        ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video1_wr_data      ,
    input   wire                                video1_wr_rst       ,

    input   wire                                video2_wr_clk       ,
    input   wire                                video2_wr_en        ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video2_wr_data      ,
    input   wire                                video2_wr_rst       ,

    input   wire                                video3_wr_clk       ,
    input   wire                                video3_wr_en        ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video3_wr_data      ,
    input   wire                                video3_wr_rst       ,
    
    input   wire                                fifo_rd_clk         ,
    input   wire                                fifo_rd_en          ,
    output  wire    [FIFO_DATA_WIDTH-1:0]       fifo_rd_data        ,
    input   wire                                fifo_rd_rst         ,
    
    output  wire    [3:0]                       axi_wr_req          ,
    
    input   wire                                axi_video0_wr_en    ,
    output  wire    [AXI_DATA_WIDTH-1:0]        axi_video0_wr_data  ,
    input   wire                                axi_video1_wr_en    ,
    output  wire    [AXI_DATA_WIDTH-1:0]        axi_video1_wr_data  ,
    input   wire                                axi_video2_wr_en    ,
    output  wire    [AXI_DATA_WIDTH-1:0]        axi_video2_wr_data  ,
    input   wire                                axi_video3_wr_en    ,
    output  wire    [AXI_DATA_WIDTH-1:0]        axi_video3_wr_data  ,
    
    output  reg                                 axi_rd_req          ,
    input   wire                                axi_rd_en           ,
    input   wire    [AXI_DATA_WIDTH-1:0]        axi_rd_data         ,
    
    output  wire                                fifo_video0_full    ,
    output  wire                                fifo_video1_full    ,
    output  wire                                fifo_o_full         
);
/****************************reg*****************************/
reg     [15:0]              r_fifo_o_rst            ;
reg                         fifo_o_rst_posedge      ;
reg                         fifo_o_rst_posedge_d    ;
reg     [ 9:0]              r_cnt_fifo_o_rst        ;


reg     [15:0]              r_fifo_video0_rst       ;
reg                         fifo_video0_rst_posedge ;
reg     [15:0]              r_fifo_video1_rst       ;
reg                         fifo_video1_rst_posedge ;
reg     [15:0]              r_fifo_video2_rst       ;
reg                         fifo_video2_rst_posedge ;
reg     [15:0]              r_fifo_video3_rst       ;
reg                         fifo_video3_rst_posedge ;

reg                         axi_video0_wr_req       ;
reg                         axi_video1_wr_req       ;
reg                         axi_video2_wr_req       ;
reg                         axi_video3_wr_req       ;

/****************************wire****************************/
wire    [8:0]               fifo_video0_water_level ;
wire    [8:0]               fifo_video1_water_level ;
wire    [8:0]               fifo_video2_water_level ;
wire    [8:0]               fifo_video3_water_level ;
wire    [9:0]               fifo_o_water_level      ;

wire                        fifo_video0_almost_full ;
wire                        fifo_video1_almost_full ;
wire                        fifo_video2_almost_full ;
wire                        fifo_video3_almost_full ;
wire                        fifo_o_almost_empty     ;

/********************combinational logic*********************/
assign axi_wr_req               = {axi_video3_wr_req, axi_video2_wr_req, axi_video1_wr_req, axi_video0_wr_req};

assign fifo_video0_almost_full  = (fifo_video0_water_level >= (MEM_H_PIXEL / MEM_BURST_LEN));
assign fifo_video1_almost_full  = (fifo_video1_water_level >= (MEM_H_PIXEL / MEM_BURST_LEN));
assign fifo_video2_almost_full  = (fifo_video2_water_level >= (MEM_H_PIXEL / MEM_BURST_LEN));
assign fifo_video3_almost_full  = (fifo_video3_water_level >= (MEM_H_PIXEL / MEM_BURST_LEN));
assign fifo_o_almost_empty      = (fifo_o_water_level < (DISP_H / MEM_BURST_LEN) - 1);

/***********************instantiation************************/
axi_fifo_video u_axi_fifo_video0(
    .wr_clk             (video0_wr_clk      ), // input
    .wr_rst             (!rst_n || fifo_video0_rst_posedge), // input
    .wr_en              (video0_wr_en       ), // input
    .wr_data            (video0_wr_data     ), // input [31:0]
    .wr_full            (fifo_video0_full   ), // output
    .almost_full        (                   ), // output
    .rd_clk             (ddrphy_clkin       ), // input
    .rd_rst             (!rst_n || fifo_video0_rst_posedge), // input
    .rd_en              (axi_video0_wr_en   ), // input
    .rd_data            (axi_video0_wr_data ), // output [255:0]
    .rd_empty           (                   ), // output
    .almost_empty       (                   ), // output
    .rd_water_level     (fifo_video0_water_level)  // output [8:0]
);

axi_fifo_video u_axi_fifo_video1(
    .wr_clk             (video1_wr_clk      ), // input
    .wr_rst             (!rst_n || fifo_video1_rst_posedge), // input
    .wr_en              (video1_wr_en       ), // input
    .wr_data            (video1_wr_data     ), // input [31:0]
    .wr_full            (fifo_video1_full   ), // output
    .almost_full        (                   ), // output
    .rd_clk             (ddrphy_clkin       ), // input
    .rd_rst             (!rst_n || fifo_video1_rst_posedge), // input
    .rd_en              (axi_video1_wr_en   ), // input
    .rd_data            (axi_video1_wr_data ), // output [255:0]
    .rd_empty           (                   ), // output
    .almost_empty       (                   ), // output
    .rd_water_level     (fifo_video1_water_level)  // output [9:0]
);

axi_fifo_video u_axi_fifo_video2(
    .wr_clk             (video2_wr_clk      ), // input
    .wr_rst             (!rst_n || fifo_video2_rst_posedge), // input
    .wr_en              (video2_wr_en       ), // input
    .wr_data            (video2_wr_data     ), // input [31:0]
    .wr_full            (fifo_video2_full   ), // output
    .almost_full        (                   ), // output
    .rd_clk             (ddrphy_clkin       ), // input
    .rd_rst             (!rst_n || fifo_video2_rst_posedge), // input
    .rd_en              (axi_video2_wr_en   ), // input
    .rd_data            (axi_video2_wr_data ), // output [255:0]
    .rd_empty           (                   ), // output
    .almost_empty       (                   ), // output
    .rd_water_level     (fifo_video2_water_level)  // output [9:0]
);

axi_fifo_video u_axi_fifo_video3(
    .wr_clk             (video3_wr_clk      ), // input
    .wr_rst             (!rst_n || fifo_video3_rst_posedge), // input
    .wr_en              (video3_wr_en       ), // input
    .wr_data            (video3_wr_data     ), // input [31:0]
    .wr_full            (fifo_video3_full   ), // output
    .almost_full        (                   ), // output
    .rd_clk             (ddrphy_clkin       ), // input
    .rd_rst             (!rst_n || fifo_video3_rst_posedge), // input
    .rd_en              (axi_video3_wr_en   ), // input
    .rd_data            (axi_video3_wr_data ), // output [255:0]
    .rd_empty           (                   ), // output
    .almost_empty       (                   ), // output
    .rd_water_level     (fifo_video3_water_level)  // output [9:0]
);

axi_fifo_o u_axi_fifo_o(
    .wr_clk             (ddrphy_clkin       ), // input
    .wr_rst             (!rst_n || fifo_o_rst_posedge_d), // input
    .wr_en              (axi_rd_en          ), // input
    .wr_data            (axi_rd_data        ), // input [255:0]
    .wr_full            (fifo_o_full        ), // output
    .almost_full        (                   ), // output
    .wr_water_level     (fifo_o_water_level ), // output [9:0]
    .rd_clk             (fifo_rd_clk        ), // input
    .rd_rst             (!rst_n || fifo_o_rst_posedge_d), // input
    .rd_en              (fifo_rd_en         ), // input
    .rd_data            (fifo_rd_data       ), // output [31:0]
    .rd_empty           (                   ), // output
    .almost_empty       (                   )  // output
);

/**************************process***************************/
// FIFO模块对AXI接口发出的读写请求信号
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        axi_video0_wr_req <= 1'b0;
    else if(fifo_video0_almost_full)
        axi_video0_wr_req <= 1'b1;
    else
        axi_video0_wr_req <= 1'b0;
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        axi_video1_wr_req <= 1'b0;
    else if(fifo_video1_almost_full)
        axi_video1_wr_req <= 1'b1;
    else
        axi_video1_wr_req <= 1'b0;
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        axi_video2_wr_req <= 1'b0;
    else if(fifo_video2_almost_full)
        axi_video2_wr_req <= 1'b1;
    else
        axi_video2_wr_req <= 1'b0;
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        axi_video3_wr_req <= 1'b0;
    else if(fifo_video3_almost_full)
        axi_video3_wr_req <= 1'b1;
    else
        axi_video3_wr_req <= 1'b0;
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        axi_rd_req <= 1'b0;
    else if(!fifo_video3_almost_full && !fifo_video2_almost_full && !fifo_video1_almost_full && !fifo_video0_almost_full && fifo_o_almost_empty && (r_cnt_fifo_o_rst == 10'd1000)) // 输出FIFO复位后等待10ms再发出读请求信号
        axi_rd_req <= 1'b1;
    else
        axi_rd_req <= 1'b0;
end

/*---------------------------------------------------*/
// 输入FIFO_video0的复位信号持续16个周期高电平
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        r_fifo_video0_rst <= 16'd0;
    else
        r_fifo_video0_rst <= {r_fifo_video0_rst[15:0], video0_wr_rst};
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        fifo_video0_rst_posedge <= 1'b0;
    else if(!r_fifo_video0_rst[15] && r_fifo_video0_rst[0])
        fifo_video0_rst_posedge <= 1'b1;
    else
        fifo_video0_rst_posedge <= 1'b0;
end

// 输入FIFO_video1的复位信号持续16个周期高电平
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        r_fifo_video1_rst <= 16'd0;
    else
        r_fifo_video1_rst <= {r_fifo_video1_rst[15:0], video1_wr_rst};
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        fifo_video1_rst_posedge <= 1'b0;
    else if(!r_fifo_video1_rst[15] && r_fifo_video1_rst[0])
        fifo_video1_rst_posedge <= 1'b1;
    else
        fifo_video1_rst_posedge <= 1'b0;
end

// 输入FIFO_video2的复位信号持续16个周期高电平
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        r_fifo_video2_rst <= 16'd0;
    else
        r_fifo_video2_rst <= {r_fifo_video2_rst[15:0], video2_wr_rst};
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        fifo_video2_rst_posedge <= 1'b0;
    else if(!r_fifo_video2_rst[15] && r_fifo_video2_rst[0])
        fifo_video2_rst_posedge <= 1'b1;
    else
        fifo_video2_rst_posedge <= 1'b0;
end

// 输入FIFO_video3的复位信号持续16个周期高电平
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        r_fifo_video3_rst <= 16'd0;
    else
        r_fifo_video3_rst <= {r_fifo_video3_rst[15:0], video3_wr_rst};
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        fifo_video3_rst_posedge <= 1'b0;
    else if(!r_fifo_video3_rst[15] && r_fifo_video3_rst[0])
        fifo_video3_rst_posedge <= 1'b1;
    else
        fifo_video3_rst_posedge <= 1'b0;
end

// 输出FIFO的复位信号持续16个周期高电平
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        r_fifo_o_rst <= 16'd0;
    else
        r_fifo_o_rst <= {r_fifo_o_rst[15:0], fifo_rd_rst};
end

always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        fifo_o_rst_posedge <= 1'b0;
    else if(!r_fifo_o_rst[15] && r_fifo_o_rst[0])
        fifo_o_rst_posedge <= 1'b1;
    else
        fifo_o_rst_posedge <= 1'b0;
end

// 由于FIFO是异步复位，因此将复位信号延迟一个周期给FIFO，让计数器先清零
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        fifo_o_rst_posedge_d <= 1'b0;
    else
        fifo_o_rst_posedge_d <= fifo_o_rst_posedge;
end

// 在输出FIFO复位后计数器开始计时
always@(posedge ddrphy_clkin or negedge rst_n)
begin
    if(!rst_n)
        r_cnt_fifo_o_rst <= 10'd0;
    else if(fifo_o_rst_posedge)
        r_cnt_fifo_o_rst <= 10'd0;
    else if(r_cnt_fifo_o_rst == 10'd1000)
        r_cnt_fifo_o_rst <= r_cnt_fifo_o_rst;
    else
        r_cnt_fifo_o_rst <= r_cnt_fifo_o_rst + 1'b1;
end

endmodule
