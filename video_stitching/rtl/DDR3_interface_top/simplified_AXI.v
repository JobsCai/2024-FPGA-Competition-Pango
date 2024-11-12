//************************************************
// Author       : Jack
// Create Date  : 2023年3月22日 11:19:47
// File Name    : simplified_AXI.v
// Version      : v1.2
// Target Device: PANGO PGL50H
// Function     : 通过读写请求信号完成读写操作
//************************************************

module simplified_AXI#(
    parameter DISP_H                = 1920  , // 显示一帧数据的行像素个数
    parameter DISP_V                = 1080  , // 显示一帧数据的列像素个数
    parameter MEM_H_PIXEL           = 960   , // 每一个视频源显示时的行像素
    parameter MEM_V_PIXEL           = 540   , // 每一个视频源显示时的列像素
    
    parameter AXI_WRITE_BURST_LEN   = 16    , // 写突发传输长度，支持（1,2,4,8,16）
    parameter AXI_READ_BURST_LEN    = 16    , // 读突发传输长度，支持（1,2,4,8,16）
    parameter AXI_ID_WIDTH          = 4     , // AXI ID位宽
    parameter AXI_USER_WIDTH        = 1     , // AXI USRT位宽
    parameter AXI_DATA_WIDTH        = 256   , // AXI 数据位宽
    parameter MEM_ROW_WIDTH         = 15    , // DDR 行地址位宽
    parameter MEM_COL_WIDTH         = 10    , // DDR 列地址位宽
    parameter MEM_BANK_WIDTH        = 3     , // DDR BANK地址位宽
    parameter MEM_BURST_LEN         = 8     , // DDR 突发传输长度
    parameter AXI_ADDR_WIDTH        = MEM_BANK_WIDTH + MEM_ROW_WIDTH + MEM_COL_WIDTH
)(
    input   wire                            M_AXI_ACLK          ,
    input   wire                            M_AXI_ARESETN       ,
    
    // 写信号
    input   wire [3:0]                      axi_wr_grant        , // 输入FIFO：写请求
    
    output  reg                             axi_video0_wr_en    , // FIFO_video0：写使能
    input   wire [AXI_DATA_WIDTH-1:0]       axi_video0_wr_data  , // FIFO_video0：写数据
    input   wire                            video0_wr_rst       , // 视频源0写地址复位
    
    output  reg                             axi_video1_wr_en    , // FIFO_video1：写使能
    input   wire [AXI_DATA_WIDTH-1:0]       axi_video1_wr_data  , // FIFO_video1：写数据
    input   wire                            video1_wr_rst       , // 视频源1写地址复位
    
    output  reg                             axi_video2_wr_en    , // FIFO_video1：写使能
    input   wire [AXI_DATA_WIDTH-1:0]       axi_video2_wr_data  , // FIFO_video1：写数据
    input   wire                            video2_wr_rst       , // 视频源1写地址复位
    
    output  reg                             axi_video3_wr_en    , // FIFO_video1：写使能
    input   wire [AXI_DATA_WIDTH-1:0]       axi_video3_wr_data  , // FIFO_video1：写数据
    input   wire                            video3_wr_rst       , // 视频源1写地址复位
    
    // 读信号
    input   wire                            rd_req              , // 输出FIFO：读请求
    
    output  wire                            rd_en               , // 输出FIFO：读使能
    output  wire [AXI_DATA_WIDTH-1:0]       rd_data             , // 输出FIFO：读数据
    input   wire                            rd_rst              , // 读地址复位信号
    
    // AXI 接口信号
    output  wire [AXI_ADDR_WIDTH-1:0]       M_AXI_AWADDR    ,
    output  wire [AXI_USER_WIDTH-1:0]       M_AXI_AWUSER    ,
    output  wire [AXI_ID_WIDTH-1:0]         M_AXI_AWID      ,
    output  wire [3:0]                      M_AXI_AWLEN     ,
    input   wire                            M_AXI_AWREADY   ,
    output  wire                            M_AXI_AWVALID   ,
    
    output  wire [AXI_DATA_WIDTH-1:0]       M_AXI_WDATA     ,
    output  wire [AXI_DATA_WIDTH/8-1:0]     M_AXI_WSTRB     ,
    input   wire                            M_AXI_WREADY    ,
    input   wire [AXI_ID_WIDTH-1:0]         M_AXI_WID       ,
    output  wire                            M_AXI_WLAST     ,
    
    output  wire [AXI_ADDR_WIDTH-1:0]       M_AXI_ARADDR    ,
    output  wire [AXI_USER_WIDTH-1:0]       M_AXI_ARUSER    ,
    output  wire [AXI_ID_WIDTH-1:0]         M_AXI_ARID      ,
    output  wire [3:0]                      M_AXI_ARLEN     ,
    input   wire                            M_AXI_ARREADY   ,
    output  wire                            M_AXI_ARVALID   ,
    
    input   wire [AXI_DATA_WIDTH-1:0]       M_AXI_RDATA     ,
    input   wire [AXI_ID_WIDTH-1:0]         M_AXI_RID       ,
    input   wire                            M_AXI_RLAST     ,
    input   wire                            M_AXI_RVALID    
);

/*************************parameter**************************/
localparam WRITE_BURST_COUNT = MEM_H_PIXEL / (AXI_WRITE_BURST_LEN * MEM_BURST_LEN); // 一次写操作突发传输的次数
localparam READ_BURST_COUNT  = DISP_H      / (AXI_READ_BURST_LEN  * MEM_BURST_LEN); // 一次读操作突发传输的次数
localparam WRITE_BURST_ADDR  = MEM_BURST_LEN * AXI_WRITE_BURST_LEN; // AXI接口每次突发写传输地址改变量
localparam READ_BURST_ADDR   = MEM_BURST_LEN * AXI_READ_BURST_LEN ; // AXI接口每次突发读传输地址改变量

localparam VIDEO0_START_ADDR = 'd0;
localparam VIDEO0_END_ADDR   = DISP_H * MEM_V_PIXEL + VIDEO0_START_ADDR;
localparam VIDEO1_START_ADDR = MEM_H_PIXEL;
localparam VIDEO1_END_ADDR   = DISP_H * MEM_V_PIXEL + VIDEO1_START_ADDR;
localparam VIDEO2_START_ADDR = DISP_H * MEM_V_PIXEL;
localparam VIDEO2_END_ADDR   = DISP_H * MEM_V_PIXEL + VIDEO2_START_ADDR;
localparam VIDEO3_START_ADDR = DISP_H * MEM_V_PIXEL + MEM_H_PIXEL;
localparam VIDEO3_END_ADDR   = DISP_H * MEM_V_PIXEL + VIDEO3_START_ADDR;

/****************************reg*****************************/
reg     [3:0]                               r_input_source      ; // 寄存输入视频源

reg                                         r_m_axi_awvalid     ; // 写地址有效
reg     [3:0]                               r_awburst_count     ; // 记录一次写操作发送的地址个数
reg     [MEM_ROW_WIDTH+MEM_COL_WIDTH-1:0]   r_video0_wr_addr    ; // 视频源0 写地址
reg     [MEM_BANK_WIDTH-2:0]                r_video0_wr_bank    ; // 视频源0 写BNAK
reg     [MEM_ROW_WIDTH+MEM_COL_WIDTH-1:0]   r_video1_wr_addr    ; // 视频源1 写地址
reg     [MEM_BANK_WIDTH-2:0]                r_video1_wr_bank    ; // 视频源1 写BNAK
reg     [MEM_ROW_WIDTH+MEM_COL_WIDTH-1:0]   r_video2_wr_addr    ; // 视频源2 写地址
reg     [MEM_BANK_WIDTH-2:0]                r_video2_wr_bank    ; // 视频源2 写BNAK
reg     [MEM_ROW_WIDTH+MEM_COL_WIDTH-1:0]   r_video3_wr_addr    ; // 视频源3 写地址
reg     [MEM_BANK_WIDTH-2:0]                r_video3_wr_bank    ; // 视频源3 写BNAK
reg     [AXI_ADDR_WIDTH-1:0]                r_wr_addr           ; // 写地址

reg     [AXI_DATA_WIDTH-1:0]                r_wr_data           ; // 写数据
reg                                         r_m_axi_wlast       ;
reg     [3:0]                               r_wburst_cnt        ; // 记录一次突发传输发送数据个数
reg     [3:0]                               r_wburst_count      ; // 记录一次写操作突发传输次数

reg     [MEM_ROW_WIDTH+MEM_COL_WIDTH-1:0]   r_rd_addr           ; // 读地址
reg     [MEM_BANK_WIDTH-2:0]                r_rd_bank           ; // 读BANK [MEM_BANK_WIDTH-2:0]
reg     [3:0]                               r_arburst_count     ; // 记录一次读操作发送的地址个数
reg                                         r_m_axi_arvalid     ; // 读地址有效

reg     [3:0]                               r_rburst_count      ; // 记录一次读操作突发传输次数

reg                                         r_video0_wr_rst     ; // 视频源0 写地址复位信号上升沿
reg                                         r0_video0_wr_rst    ;
reg                                         r1_video0_wr_rst    ;
reg                                         r_video1_wr_rst     ; // 视频源1 写地址复位信号上升沿
reg                                         r0_video1_wr_rst    ;
reg                                         r1_video1_wr_rst    ;
reg                                         r_video2_wr_rst     ; // 视频源1 写地址复位信号上升沿
reg                                         r0_video2_wr_rst    ;
reg                                         r1_video2_wr_rst    ;
reg                                         r_video3_wr_rst     ; // 视频源1 写地址复位信号上升沿
reg                                         r0_video3_wr_rst    ;
reg                                         r1_video3_wr_rst    ;
reg                                         r_rd_rst            ; // 读地址复位信号上升沿
reg                                         r0_rd_rst           ;
reg                                         r1_rd_rst           ;

/****************************wire****************************/
wire                                write_start         ;
wire                                write_state         ;
wire                                video0_waddr_end    ; // 视频源0 写到最后一个地址
wire                                video1_waddr_end    ; // 视频源1 写到最后一个地址
wire                                video2_waddr_end    ; // 视频源2 写到最后一个地址
wire                                video3_waddr_end    ; // 视频源3 写到最后一个地址
wire                                write_done          ; // 一次写操作结束

wire                                read_start          ;
wire                                read_state          ;
wire                                read_done           ; // 一次读操作结束
wire                                raddr_end           ; // 读到最后一个地址

/********************combinational logic*********************/
assign M_AXI_AWADDR         = {r_wr_addr[MEM_COL_WIDTH], 
                               r_wr_addr[AXI_ADDR_WIDTH-1: AXI_ADDR_WIDTH-MEM_BANK_WIDTH], 
                               r_wr_addr[MEM_COL_WIDTH+MEM_ROW_WIDTH-1:MEM_COL_WIDTH+1], 
                               r_wr_addr[MEM_COL_WIDTH-1:0]}        ;
assign M_AXI_AWUSER         = 'd0                                   ;
assign M_AXI_AWID           = 'd0                                   ;
assign M_AXI_AWLEN          = AXI_WRITE_BURST_LEN - 1               ;
assign M_AXI_AWVALID        = r_m_axi_awvalid                       ;
assign video0_waddr_end     = r_video0_wr_addr == VIDEO0_END_ADDR   ;
assign video1_waddr_end     = r_video1_wr_addr == VIDEO1_END_ADDR   ;
assign video2_waddr_end     = r_video2_wr_addr == VIDEO2_END_ADDR   ;
assign video3_waddr_end     = r_video3_wr_addr == VIDEO3_END_ADDR   ;

assign M_AXI_WDATA          = r_wr_data                             ;
assign M_AXI_WSTRB          = {(AXI_DATA_WIDTH/8){1'b1}}            ;
assign M_AXI_WLAST          = r_m_axi_wlast                         ;
assign write_done           = M_AXI_WLAST && (r_wburst_count == WRITE_BURST_COUNT - 1);

assign M_AXI_ARADDR         = {r_rd_addr[MEM_COL_WIDTH], 
                              {1'b0, r_rd_bank}, 
                               r_rd_addr[MEM_COL_WIDTH+MEM_ROW_WIDTH-1:MEM_COL_WIDTH+1], 
                               r_rd_addr[MEM_COL_WIDTH-1:0]}        ;
assign M_AXI_ARLEN          = AXI_READ_BURST_LEN - 1                ;
assign M_AXI_ARUSER         = 'd0                                   ;
assign M_AXI_ARID           = 'd0                                   ;
assign M_AXI_ARVALID        = r_m_axi_arvalid                       ;
assign raddr_end            = r_rd_addr == DISP_H * DISP_V          ;

assign rd_en                = M_AXI_RVALID                          ;
assign rd_data              = M_AXI_RDATA                           ;
assign read_done            = M_AXI_RLAST && (r_rburst_count == READ_BURST_COUNT - 1);

/****************************FSM*****************************/
localparam ST_IDLE          = 5'b00001;
localparam ST_WRITE_START   = 5'b00010;
localparam ST_WRITE_STATE   = 5'b00100;
localparam ST_READ_START    = 5'b01000;
localparam ST_READ_STATE    = 5'b10000;

reg     [4:0]   fsm_c;
reg     [4:0]   fsm_n;

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        fsm_c <= ST_IDLE;
    else
        fsm_c <= fsm_n;
end

always@(*)
begin
    case(fsm_c)
        ST_IDLE:
            if(r_rd_rst || r_video0_wr_rst || r_video1_wr_rst || r_video2_wr_rst || r_video3_wr_rst)
                fsm_n = ST_IDLE;
            else if(axi_wr_grant != 4'b0000) // 写的优先级更高
                fsm_n = ST_WRITE_START;
            else if(rd_req)
                fsm_n = ST_READ_START;
            else
                fsm_n = ST_IDLE;
        ST_WRITE_START:
                fsm_n = ST_WRITE_STATE;
        ST_WRITE_STATE:
            if(write_done)
                fsm_n = ST_IDLE;
            else
                fsm_n = ST_WRITE_STATE;
        ST_READ_START:
                fsm_n = ST_READ_STATE;
        ST_READ_STATE:
            if(read_done)
                fsm_n = ST_IDLE;
            else
                fsm_n = ST_READ_STATE;
        default:
                fsm_n = ST_IDLE;
    endcase
end

assign write_start = (fsm_c == ST_WRITE_START) ? 1'b1 : 1'b0;
assign write_state = (fsm_c == ST_WRITE_STATE) ? 1'b1 : 1'b0;
assign read_start  = (fsm_c == ST_READ_START)  ? 1'b1 : 1'b0;
assign read_state  = (fsm_c == ST_READ_STATE)  ? 1'b1 : 1'b0;

/**************************process***************************/
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_input_source <= 2'b00;
    else if(fsm_c == ST_WRITE_START)
        r_input_source <= axi_wr_grant;
    else
        r_input_source <= r_input_source;
end

/*写地址通道---------------------------------------------------*/
// 视频源0
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video0_wr_addr  <= VIDEO0_START_ADDR;
    else case(fsm_c)
        ST_IDLE:
            if(r_video0_wr_rst) // 在输入数据每一帧开始时复位写地址
                r_video0_wr_addr <= VIDEO0_START_ADDR;
            else if(video0_waddr_end) // 当写到最后一个地址时复位写地址
                r_video0_wr_addr <= VIDEO0_START_ADDR;
            else
                r_video0_wr_addr <= r_video0_wr_addr;
        ST_WRITE_STATE:
            if(M_AXI_AWREADY && M_AXI_AWVALID && r_input_source[0])
                if(r_awburst_count == WRITE_BURST_COUNT - 1) // 这一行写完时，直接跳到下一行
                    r_video0_wr_addr <= r_video0_wr_addr + WRITE_BURST_ADDR + MEM_H_PIXEL;
                else
                    r_video0_wr_addr <= r_video0_wr_addr + WRITE_BURST_ADDR;
            else
                r_video0_wr_addr <= r_video0_wr_addr;
        default:
            r_video0_wr_addr <= r_video0_wr_addr;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video0_wr_bank <= 2'd1;
    else if(fsm_c == ST_IDLE)
        if(video0_waddr_end) // 当写到最后一个地址时改变BANK地址
            if(r_video0_wr_bank == r_rd_bank - 1'b1) // 读BANK始终落后写BANK
                r_video0_wr_bank <= r_video0_wr_bank;
            else
                r_video0_wr_bank <= r_video0_wr_bank + 1'b1;
        else
            r_video0_wr_bank <= r_video0_wr_bank;
    else
        r_video0_wr_bank <= r_video0_wr_bank;
end

// 视频源1
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video1_wr_addr  <= VIDEO1_START_ADDR;
    else case(fsm_c)
        ST_IDLE:
            if(r_video1_wr_rst) // 在输入数据每一帧开始时复位写地址
                r_video1_wr_addr <= VIDEO1_START_ADDR;
            else if(video1_waddr_end) // 当写到最后一个地址时复位写地址
                r_video1_wr_addr <= VIDEO1_START_ADDR;
            else
                r_video1_wr_addr <= r_video1_wr_addr;
        ST_WRITE_STATE:
            if(M_AXI_AWREADY && M_AXI_AWVALID && r_input_source[1])
                if(r_awburst_count == WRITE_BURST_COUNT - 1) // 这一行写完时，直接跳到下一行
                    r_video1_wr_addr <= r_video1_wr_addr + WRITE_BURST_ADDR + MEM_H_PIXEL;
                else
                    r_video1_wr_addr <= r_video1_wr_addr + WRITE_BURST_ADDR;
            else
                r_video1_wr_addr <= r_video1_wr_addr;
        default:
            r_video1_wr_addr <= r_video1_wr_addr;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video1_wr_bank <= 2'd1;
    else if(fsm_c == ST_IDLE)
        if(video1_waddr_end) // 当写到最后一个地址时改变BANK地址
            if(r_video1_wr_bank == r_rd_bank - 1'b1) // 读BANK始终落后写BANK
                r_video1_wr_bank <= r_video1_wr_bank;
            else
                r_video1_wr_bank <= r_video1_wr_bank + 1'b1;
        else
            r_video1_wr_bank <= r_video1_wr_bank;
    else
        r_video1_wr_bank <= r_video1_wr_bank;
end

// 视频源2
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video2_wr_addr  <= VIDEO2_START_ADDR;
    else case(fsm_c)
        ST_IDLE:
            if(r_video2_wr_rst) // 在输入数据每一帧开始时复位写地址
                r_video2_wr_addr <= VIDEO2_START_ADDR;
            else if(video2_waddr_end) // 当写到最后一个地址时复位写地址
                r_video2_wr_addr <= VIDEO2_START_ADDR;
            else
                r_video2_wr_addr <= r_video2_wr_addr;
        ST_WRITE_STATE:
            if(M_AXI_AWREADY && M_AXI_AWVALID && r_input_source[2])
                if(r_awburst_count == WRITE_BURST_COUNT - 1) // 这一行写完时，直接跳到下一行
                    r_video2_wr_addr <= r_video2_wr_addr + WRITE_BURST_ADDR + MEM_H_PIXEL;
                else
                    r_video2_wr_addr <= r_video2_wr_addr + WRITE_BURST_ADDR;
            else
                r_video2_wr_addr <= r_video2_wr_addr;
        default:
            r_video2_wr_addr <= r_video2_wr_addr;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video2_wr_bank <= 2'd1;
    else if(fsm_c == ST_IDLE)
        if(video2_waddr_end) // 当写到最后一个地址时改变BANK地址
            if(r_video2_wr_bank == r_rd_bank - 1'b1) // 读BANK始终落后写BANK
                r_video2_wr_bank <= r_video2_wr_bank;
            else
                r_video2_wr_bank <= r_video2_wr_bank + 1'b1;
        else
            r_video2_wr_bank <= r_video2_wr_bank;
    else
        r_video2_wr_bank <= r_video2_wr_bank;
end

// 视频源3
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video3_wr_addr  <= VIDEO2_START_ADDR;
    else case(fsm_c)
        ST_IDLE:
            if(r_video3_wr_rst) // 在输入数据每一帧开始时复位写地址
                r_video3_wr_addr <= VIDEO3_START_ADDR;
            else if(video3_waddr_end) // 当写到最后一个地址时复位写地址
                r_video3_wr_addr <= VIDEO3_START_ADDR;
            else
                r_video3_wr_addr <= r_video3_wr_addr;
        ST_WRITE_STATE:
            if(M_AXI_AWREADY && M_AXI_AWVALID && r_input_source[3])
                if(r_awburst_count == WRITE_BURST_COUNT - 1) // 这一行写完时，直接跳到下一行
                    r_video3_wr_addr <= r_video3_wr_addr + WRITE_BURST_ADDR + MEM_H_PIXEL;
                else
                    r_video3_wr_addr <= r_video3_wr_addr + WRITE_BURST_ADDR;
            else
                r_video3_wr_addr <= r_video3_wr_addr;
        default:
            r_video3_wr_addr <= r_video3_wr_addr;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video3_wr_bank <= 2'd1;
    else if(fsm_c == ST_IDLE)
        if(video3_waddr_end) // 当写到最后一个地址时改变BANK地址
            if(r_video3_wr_bank == r_rd_bank - 1'b1) // 读BANK始终落后写BANK
                r_video3_wr_bank <= r_video3_wr_bank;
            else
                r_video3_wr_bank <= r_video3_wr_bank + 1'b1;
        else
            r_video3_wr_bank <= r_video3_wr_bank;
    else
        r_video3_wr_bank <= r_video3_wr_bank;
end

// 在时钟下降沿更新写地址
always@(negedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_wr_addr <= 'd0;
    else if(fsm_c == ST_WRITE_STATE)
        case(r_input_source)
            4'b1000:
                r_wr_addr <= {1'b0, r_video3_wr_bank, r_video3_wr_addr};
            4'b0100:
                r_wr_addr <= {1'b0, r_video2_wr_bank, r_video2_wr_addr};
            4'b0010:
                r_wr_addr <= {1'b0, r_video1_wr_bank, r_video1_wr_addr};
            4'b0001:
                r_wr_addr <= {1'b0, r_video0_wr_bank, r_video0_wr_addr};
            default:
                r_wr_addr <= 'd0;
        endcase
    else
        r_wr_addr <= 'd0;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_m_axi_awvalid <= 1'b0;
    else case(fsm_c)
        ST_WRITE_START:
            r_m_axi_awvalid <= 1'b1;
        ST_WRITE_STATE:
            if(r_awburst_count < WRITE_BURST_COUNT - 1)
                r_m_axi_awvalid <= 1'b1;
            else if(r_awburst_count == WRITE_BURST_COUNT - 1)
                if(M_AXI_AWREADY && M_AXI_AWVALID)
                    r_m_axi_awvalid <= 1'b0;
                else
                    r_m_axi_awvalid <= 1'b1;
            else
                r_m_axi_awvalid <= 1'b0;
        default:
            r_m_axi_awvalid <= 1'b0;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_awburst_count <= 4'd0;
    else case(fsm_c)
        ST_WRITE_START:
            r_awburst_count <= 4'd0;
        ST_WRITE_STATE:
            if(M_AXI_AWREADY && M_AXI_AWVALID)
                r_awburst_count <= r_awburst_count + 1'b1;
            else
                r_awburst_count <= r_awburst_count;
        default:
            r_awburst_count <= 4'd0;
    endcase
end

/*写数据通道---------------------------------------------------*/
always@(*)
begin
    if(!M_AXI_ARESETN)
        r_wr_data = 'd0;
    else if(fsm_c == ST_WRITE_STATE)
        case(r_input_source)
            4'b1000:
                r_wr_data = axi_video3_wr_data;
            4'b0100:
                r_wr_data = axi_video2_wr_data;
            4'b0010:
                r_wr_data = axi_video1_wr_data;
            4'b0001:
                r_wr_data = axi_video0_wr_data;
            default:
                r_wr_data = 'd0;
        endcase
    else
        r_wr_data = 'd0;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_m_axi_wlast <= 1'b0;
    else if(r_wburst_cnt == AXI_WRITE_BURST_LEN - 2)
        r_m_axi_wlast <= 1'b1;
    else
        r_m_axi_wlast <= 1'b0;
end

always@(*)
begin
    case(fsm_c)
        ST_WRITE_START: // 在一次写操作开始时就先从输入FIFO中读出一个数据
            if(axi_wr_grant[0])
                axi_video0_wr_en = 1'b1;
            else
                axi_video0_wr_en = 1'b0;
        ST_WRITE_STATE:
            if(r_input_source[0])
                if(write_done) // 一次写操作结束的最后不拉高写使能，防止从输入FIFO中多读出一个数据
                    axi_video0_wr_en = 1'b0;
                else
                    axi_video0_wr_en = M_AXI_WREADY;
            else
                axi_video0_wr_en = 1'b0;
        default:
            axi_video0_wr_en = 1'b0;
    endcase
end

always@(*)
begin
    case(fsm_c)
        ST_WRITE_START: // 在一次写操作开始时就先从输入FIFO中读出一个数据
            if(axi_wr_grant[1])
                axi_video1_wr_en = 1'b1;
            else
                axi_video1_wr_en = 1'b0;
        ST_WRITE_STATE:
            if(r_input_source[1])
                if(write_done) // 一次写操作结束的最后不拉高写使能，防止从输入FIFO中多读出一个数据
                    axi_video1_wr_en = 1'b0;
                else
                    axi_video1_wr_en = M_AXI_WREADY;
            else
                axi_video1_wr_en = 1'b0;
        default:
            axi_video1_wr_en = 1'b0;
    endcase
end

always@(*)
begin
    case(fsm_c)
        ST_WRITE_START: // 在一次写操作开始时就先从输入FIFO中读出一个数据
            if(axi_wr_grant[2])
                axi_video2_wr_en = 1'b1;
            else
                axi_video2_wr_en = 1'b0;
        ST_WRITE_STATE:
            if(r_input_source[2])
                if(write_done) // 一次写操作结束的最后不拉高写使能，防止从输入FIFO中多读出一个数据
                    axi_video2_wr_en = 1'b0;
                else
                    axi_video2_wr_en = M_AXI_WREADY;
            else
                axi_video2_wr_en = 1'b0;
        default:
            axi_video2_wr_en = 1'b0;
    endcase
end

always@(*)
begin
    case(fsm_c)
        ST_WRITE_START: // 在一次写操作开始时就先从输入FIFO中读出一个数据
            if(axi_wr_grant[3])
                axi_video3_wr_en = 1'b1;
            else
                axi_video3_wr_en = 1'b0;
        ST_WRITE_STATE:
            if(r_input_source[3])
                if(write_done) // 一次写操作结束的最后不拉高写使能，防止从输入FIFO中多读出一个数据
                    axi_video3_wr_en = 1'b0;
                else
                    axi_video3_wr_en = M_AXI_WREADY;
            else
                axi_video3_wr_en = 1'b0;
        default:
            axi_video3_wr_en = 1'b0;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_wburst_cnt <= 4'd0;
    else if(M_AXI_WLAST) // 在一次突发传输后清零
        r_wburst_cnt <= 4'd0;
    else if(M_AXI_WREADY)
        r_wburst_cnt <= r_wburst_cnt + 1;
    else
        r_wburst_cnt <= r_wburst_cnt;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_wburst_count <= 4'd0;
    else if(write_start) // 在一次写操作开始时清零
        r_wburst_count <= 4'd0;
    else if(M_AXI_WLAST)
        r_wburst_count <= r_wburst_count + 1;
    else
        r_wburst_count <= r_wburst_count;
end

/*读地址通道---------------------------------------------------*/
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_rd_addr <= 'd0;
    else case(fsm_c)
        ST_IDLE:
            if(r_rd_rst) // 在输出数据每一帧开始时复位读地址
                r_rd_addr <= 'd0;
            else if(raddr_end) // 当为最后一个读地址时复位读地址
                r_rd_addr <= 'd0;
            else
                r_rd_addr <= r_rd_addr;
        ST_READ_STATE:
            if(M_AXI_ARREADY && M_AXI_ARVALID)
                r_rd_addr <= r_rd_addr + READ_BURST_ADDR;
            else
                r_rd_addr <= r_rd_addr;
        default:
            r_rd_addr <= r_rd_addr;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_rd_bank <= 3'd0;
    else if(fsm_c == ST_IDLE)
        if(raddr_end) // 当读到最后一个地址时改变BANK地址
            if((r_rd_bank == r_video0_wr_bank + 1'b1) && (r_rd_bank == r_video1_wr_bank + 1'b1) && (r_rd_bank == r_video2_wr_bank + 1'b1) && (r_rd_bank == r_video3_wr_bank + 1'b1)) // 当所有写BANK都落后读BANK时
                r_rd_bank <= r_rd_bank + 1'b1;
            else
                r_rd_bank <= r_rd_bank;
        else
            r_rd_bank <= r_rd_bank;
    else
        r_rd_bank <= r_rd_bank;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_m_axi_arvalid <= 1'b0;
    else case(fsm_c)
        ST_READ_START:
            r_m_axi_arvalid <= 1'b1;
        ST_READ_STATE:
            if(r_arburst_count < READ_BURST_COUNT - 1)
                r_m_axi_arvalid <= 1'b1;
            else if(r_arburst_count == READ_BURST_COUNT - 1)
                if(M_AXI_ARREADY && M_AXI_ARVALID)
                    r_m_axi_arvalid <= 1'b0;
                else
                    r_m_axi_arvalid <= 1'b1;
            else
                r_m_axi_arvalid <= 1'b0;
        default:
            r_m_axi_arvalid <= 1'b0;
    endcase
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_arburst_count <= 4'd0;
    else case(fsm_c)
        ST_READ_START: // 在写操作开始时清空写地址个数计数器
            r_arburst_count <= 4'd0;
        ST_READ_STATE:
            if(M_AXI_ARREADY && M_AXI_ARVALID)
                r_arburst_count <= r_arburst_count + 1'b1;
            else
                r_arburst_count <= r_arburst_count;
        default:
            r_arburst_count <= 4'd0;
    endcase
end

/*读数据通道---------------------------------------------------*/
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_rburst_count <= 4'd0;
    else if(read_start) // 在一次读操作开始时清零
        r_rburst_count <= 4'd0;
    else if(M_AXI_RLAST)
        r_rburst_count <= r_rburst_count + 1;
    else
        r_rburst_count <= r_rburst_count;
end

/*读写地址复位信号---------------------------------------------------*/
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        begin
            r0_video0_wr_rst <= 1'b0;
            r1_video0_wr_rst <= 1'b0;
            r0_video1_wr_rst <= 1'b0;
            r1_video1_wr_rst <= 1'b0;
            r0_video2_wr_rst <= 1'b0;
            r1_video2_wr_rst <= 1'b0;
            r0_video3_wr_rst <= 1'b0;
            r1_video3_wr_rst <= 1'b0;
            r0_rd_rst        <= 1'b0;
            r1_rd_rst        <= 1'b0;
        end
    else
        begin
            r0_video0_wr_rst <= video0_wr_rst   ;
            r1_video0_wr_rst <= r0_video0_wr_rst;
            r0_video1_wr_rst <= video1_wr_rst   ;
            r1_video1_wr_rst <= r0_video1_wr_rst;
            r0_video2_wr_rst <= video2_wr_rst   ;
            r1_video2_wr_rst <= r0_video2_wr_rst;
            r0_video3_wr_rst <= video3_wr_rst   ;
            r1_video3_wr_rst <= r0_video3_wr_rst;
            r0_rd_rst        <= rd_rst          ;
            r1_rd_rst        <= r0_rd_rst       ;
        end
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video0_wr_rst <= 1'b0;
    else if(r0_video0_wr_rst && !r1_video0_wr_rst)
        r_video0_wr_rst <= 1'b1;
    else if(r_video0_wr_addr == VIDEO0_START_ADDR)
        r_video0_wr_rst <= 1'b0;
    else
        r_video0_wr_rst <= r_video0_wr_rst;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video1_wr_rst <= 1'b0;
    else if(r0_video1_wr_rst && !r1_video1_wr_rst)
        r_video1_wr_rst <= 1'b1;
    else if(r_video1_wr_addr == VIDEO1_START_ADDR)
        r_video1_wr_rst <= 1'b0;
    else
        r_video1_wr_rst <= r_video1_wr_rst;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video2_wr_rst <= 1'b0;
    else if(r0_video2_wr_rst && !r1_video2_wr_rst)
        r_video2_wr_rst <= 1'b1;
    else if(r_video2_wr_addr == VIDEO2_START_ADDR)
        r_video2_wr_rst <= 1'b0;
    else
        r_video2_wr_rst <= r_video2_wr_rst;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_video3_wr_rst <= 1'b0;
    else if(r0_video3_wr_rst && !r1_video3_wr_rst)
        r_video3_wr_rst <= 1'b1;
    else if(r_video3_wr_addr == VIDEO3_START_ADDR)
        r_video3_wr_rst <= 1'b0;
    else
        r_video3_wr_rst <= r_video3_wr_rst;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)
begin
    if(!M_AXI_ARESETN)
        r_rd_rst <= 1'b0;
    else if(r0_rd_rst && !r1_rd_rst)
        r_rd_rst <= 1'b1;
    else if(r_rd_addr == 'd0)
        r_rd_rst <= 1'b0;
    else
        r_rd_rst <= r_rd_rst;
end

endmodule
