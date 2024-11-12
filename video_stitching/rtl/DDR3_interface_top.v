//************************************************
// Author       : Jack
// Create Date  : 2023年3月22日 19:56:33
// File Name    : DDR3_interface_top.v
// Version      : v1.2
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module DDR3_interface_top#(
    parameter FIFO_DATA_WIDTH       = 32    ,
    parameter CAM_H_PIXEL           = 1024  , // 摄像头水平方向像素个数
    parameter CAM_V_PIXEL           = 768   , // 摄像头垂直方向像素个数
    parameter HDMI_H_PIXEL          = 1920  , // HDMI输入水平方向像素个数
    parameter HDMI_V_PIXEL          = 1080  , // HDMI输入垂直方向像素个数
    parameter DISP_H                = 1920  , // HDMI输出水平方向像素个数
    parameter DISP_V                = 1080  , // HDMI输出垂直方向像素个数
    parameter MEM_H_PIXEL           = (DISP_H >> 1), // 每一个视频源显示时的行像素
    parameter MEM_V_PIXEL           = (DISP_V >> 1), // 每一个视频源显示时的列像素
    
    parameter MEM_ROW_WIDTH         = 15    ,
    parameter MEM_COL_WIDTH         = 10    ,
    parameter MEM_BANK_WIDTH        = 3     ,
    parameter MEM_DQ_WIDTH          = 32    ,
    parameter MEM_DM_WIDTH          = MEM_DQ_WIDTH/8,
    parameter MEM_DQS_WIDTH         = MEM_DQ_WIDTH/8,
    parameter MEM_BURST_LEN         = 8     ,
    
    parameter AXI_WRITE_BURST_LEN   = 8     , // 写突发传输长度，支持（1,2,4,8,16）
    parameter AXI_READ_BURST_LEN    = 16    , // 读突发传输长度，支持（1,2,4,8,16）
    parameter AXI_ID_WIDTH          = 4     ,
    parameter AXI_USER_WIDTH        = 1     ,
    parameter AXI_DATA_WIDTH        = MEM_DQ_WIDTH * MEM_BURST_LEN,
    parameter AXI_ADDR_WIDTH        = MEM_BANK_WIDTH + MEM_ROW_WIDTH + MEM_COL_WIDTH
)(
    input   wire                                sys_clk         ,
    input   wire                                key_rst_n       ,
    output  wire                                ddr_init_done   ,
    
    input   wire                                video0_wr_clk   ,
    input   wire                                video0_wr_en    ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video0_wr_data  ,
    input   wire                                video0_wr_rst   ,
    
    input   wire                                video1_wr_clk   ,
    input   wire                                video1_wr_en    ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video1_wr_data  ,
    input   wire                                video1_wr_rst   ,

    input   wire                                video2_wr_clk   ,
    input   wire                                video2_wr_en    ,
    input   wire    [23:0]       video2_wr_data  ,
    input   wire                                video2_wr_rst   ,

    input   wire                                video3_wr_clk   ,
    input   wire                                video3_wr_en    ,
    input   wire    [FIFO_DATA_WIDTH-1:0]       video3_wr_data  ,
    input   wire                                video3_wr_rst   ,
    
    input   wire                                fifo_rd_clk     ,
    input   wire                                fifo_rd_en      ,
    output  wire    [FIFO_DATA_WIDTH-1:0]       fifo_rd_data    ,
    input   wire                                rd_rst          ,
    
    output  wire                                mem_rst_n       ,
    output  wire                                mem_ck          ,
    output  wire                                mem_ck_n        ,
    output  wire                                mem_cke         ,
    output  wire                                mem_cs_n        ,
    output  wire                                mem_ras_n       ,
    output  wire                                mem_cas_n       ,
    output  wire                                mem_we_n        ,
    output  wire                                mem_odt         ,
    output  wire    [MEM_ROW_WIDTH-1:0]         mem_a           ,
    output  wire    [MEM_BANK_WIDTH-1:0]        mem_ba          ,
    inout   wire    [MEM_DQS_WIDTH-1:0]         mem_dqs         ,
    inout   wire    [MEM_DQS_WIDTH-1:0]         mem_dqs_n       ,
    inout   wire    [MEM_DQ_WIDTH-1:0]          mem_dq          ,
    output  wire    [MEM_DM_WIDTH-1:0]          mem_dm          ,
    
    output  wire                                fifo_video0_full,
    output  wire                                fifo_video1_full,
    output  wire                                fifo_o_full     
);

/****************************wire****************************/
wire    [3:0]                   axi_wr_req          ;
wire    [3:0]                   axi_wr_grant        ;
wire                            axi_video0_wr_en    ;
wire                            axi_video1_wr_en    ;
wire                            axi_video2_wr_en    ;
wire                            axi_video3_wr_en    ;
wire    [AXI_DATA_WIDTH-1:0]    axi_video0_wr_data  ;
wire    [AXI_DATA_WIDTH-1:0]    axi_video1_wr_data  ;
wire    [AXI_DATA_WIDTH-1:0]    axi_video2_wr_data  ;
wire    [AXI_DATA_WIDTH-1:0]    axi_video3_wr_data  ;
wire                            axi_rd_req          ;
wire                            axi_rd_en           ;
wire    [AXI_DATA_WIDTH-1:0]    axi_rd_data         ;

wire                            ddrphy_clkin    ;
wire                            sys_rst_n       ;

wire    [AXI_ADDR_WIDTH-1:0]    axi_awaddr      ;
wire    [AXI_USER_WIDTH-1:0]    axi_awuser_ap   ;
wire    [AXI_ID_WIDTH-1:0]      axi_awuser_id   ;
wire    [3:0]                   axi_awlen       ;
wire                            axi_awready     ;
wire                            axi_awvalid     ;

wire    [AXI_DATA_WIDTH-1:0]    axi_wdata       ;
wire    [AXI_DATA_WIDTH/8-1:0]  axi_wstrb       ;
wire                            axi_wready      ;
wire    [AXI_ID_WIDTH-1:0]      axi_wusero_id   ;
wire                            axi_wusero_last ;

wire    [AXI_ADDR_WIDTH-1:0]    axi_araddr      ;
wire    [AXI_USER_WIDTH-1:0]    axi_aruser_ap   ;
wire    [AXI_ID_WIDTH-1:0]      axi_aruser_id   ;
wire    [3:0]                   axi_arlen       ;
wire                            axi_arready     ;
wire                            axi_arvalid     ;

wire    [AXI_DATA_WIDTH-1:0]    axi_rdata       ;
wire    [AXI_ID_WIDTH-1:0]      axi_rid         ;
wire                            axi_rlast       ;
wire                            axi_rvalid      ;

/********************combinational logic*********************/
assign sys_rst_n = key_rst_n && ddr_init_done; // FIFO模块在DDR初始化完成后才复位完成

/***********************instantiation************************/
AXI_rw_FIFO #(
    .AXI_DATA_WIDTH             (AXI_DATA_WIDTH     ), // AXI 数据位宽
    .MEM_BURST_LEN              (MEM_BURST_LEN      ), // DDR 突发传输长度
    .FIFO_DATA_WIDTH            (FIFO_DATA_WIDTH    ), // FIFO 用户端数据位宽
    .MEM_H_PIXEL                (MEM_H_PIXEL        ), // 写入一帧数据行像素
    .DISP_H                     (DISP_H             )  // 读出一帧数据行像素
)u_AXI_rw_FIFO(
    .ddrphy_clkin               (ddrphy_clkin       ), // input
    .rst_n                      (sys_rst_n          ), // input
    
    .video0_wr_clk              (video0_wr_clk      ), // input
    .video0_wr_en               (video0_wr_en       ), // input
    .video0_wr_data             (video0_wr_data     ), // input  [FIFO_DATA_WIDTH-1:0]
    .video0_wr_rst              (video0_wr_rst      ), // input
    
    .video1_wr_clk              (video1_wr_clk      ), // input
    .video1_wr_en               (video1_wr_en       ), // input
    .video1_wr_data             (video1_wr_data     ), // input  [FIFO_DATA_WIDTH-1:0]
    .video1_wr_rst              (video1_wr_rst      ), // input

    .video2_wr_clk              (video2_wr_clk      ), // input
    .video2_wr_en               (video2_wr_en       ), // input
    .video2_wr_data             (video2_wr_data     ), // input  [FIFO_DATA_WIDTH-1:0]
    .video2_wr_rst              (video2_wr_rst      ), // input

    .video3_wr_clk              (video3_wr_clk      ), // input
    .video3_wr_en               (video3_wr_en       ), // input
    .video3_wr_data             (video3_wr_data     ), // input  [FIFO_DATA_WIDTH-1:0]
    .video3_wr_rst              (video3_wr_rst      ), // input
    
    .fifo_rd_clk                (fifo_rd_clk        ), // input
    .fifo_rd_en                 (fifo_rd_en         ), // input
    .fifo_rd_data               (fifo_rd_data       ), // output [FIFO_DATA_WIDTH-1:0]
    .fifo_rd_rst                (rd_rst             ), // input
    
    .axi_wr_req                 (axi_wr_req         ), // output
    
    .axi_video0_wr_en           (axi_video0_wr_en   ), // input
    .axi_video0_wr_data         (axi_video0_wr_data ), // output [FIFO_DATA_WIDTH-1:0]
    
    .axi_video1_wr_en           (axi_video1_wr_en   ),// input
    .axi_video1_wr_data         (axi_video1_wr_data ),// output [FIFO_DATA_WIDTH-1:0]

    .axi_video2_wr_en           (axi_video2_wr_en   ),// input
    .axi_video2_wr_data         (axi_video2_wr_data ),// output [FIFO_DATA_WIDTH-1:0]

    .axi_video3_wr_en           (axi_video3_wr_en   ),// input
    .axi_video3_wr_data         (axi_video3_wr_data ),// output [FIFO_DATA_WIDTH-1:0]
    
    .axi_rd_req                 (axi_rd_req         ), // output
    .axi_rd_en                  (axi_rd_en          ), // input
    .axi_rd_data                (axi_rd_data        ), // input  [FIFO_DATA_WIDTH-1:0]
    
    .fifo_video0_full           (fifo_video0_full   ),
    .fifo_video1_full           (fifo_video1_full   ),
    .fifo_o_full                (fifo_o_full        )
);

arbiter u_arbiter(
    .request                    (axi_wr_req     ), // input  [HDMI, CAMERA]
    .grant                      (axi_wr_grant   )  // output [HDMI, CAMERA]
);

simplified_AXI #(
    .DISP_H                     (DISP_H             ), // 显示一帧数据的行像素个数
    .DISP_V                     (DISP_V             ), // 显示一帧数据的列像素个数
    .MEM_H_PIXEL                (MEM_H_PIXEL        ), // 每一个视频源显示时的行像素
    .MEM_V_PIXEL                (MEM_V_PIXEL        ), // 每一个视频源显示时的列像素
    
    .AXI_WRITE_BURST_LEN        (AXI_WRITE_BURST_LEN), // AXI 写突发传输长度
    .AXI_READ_BURST_LEN         (AXI_READ_BURST_LEN ), // AXI 读突发传输长度
    .AXI_ID_WIDTH               (AXI_ID_WIDTH       ), // AXI ID位宽
    .AXI_USER_WIDTH             (AXI_USER_WIDTH     ), // AXI USER位宽
    .AXI_DATA_WIDTH             (AXI_DATA_WIDTH     ), // AXI 数据位宽
    .MEM_ROW_WIDTH              (MEM_ROW_WIDTH      ), // DDR 行地址位宽
    .MEM_COL_WIDTH              (MEM_COL_WIDTH      ), // DDR 列地址位宽
    .MEM_BANK_WIDTH             (MEM_BANK_WIDTH     ), // DDR BANK地址位宽
    .MEM_BURST_LEN              (MEM_BURST_LEN      )  // DDR 突发传输长度
)u_simplified_AXI(
    .M_AXI_ACLK                 (ddrphy_clkin       ), // input
    .M_AXI_ARESETN              (sys_rst_n          ), // input

    .axi_wr_grant               (axi_wr_grant       ), // input  输入FIFO：写请求
    
    .axi_video0_wr_en           (axi_video0_wr_en   ), // output FIFO_video0：写使能
    .axi_video0_wr_data         (axi_video0_wr_data ), // input  FIFO_video0：写数据
    .video0_wr_rst              (video0_wr_rst      ), // input  视频源0写地址复位
    
    .axi_video1_wr_en           (axi_video1_wr_en   ), // output FIFO_video1：写使能
    .axi_video1_wr_data         (axi_video1_wr_data ), // input  FIFO_video1：写数据
    .video1_wr_rst              (video1_wr_rst      ), // input  视频源1写地址复位

    .axi_video2_wr_en           (axi_video2_wr_en   ), // output FIFO_video1：写使能
    .axi_video2_wr_data         (axi_video2_wr_data ), // input  FIFO_video1：写数据
    .video2_wr_rst              (video2_wr_rst      ), // input  视频源1写地址复位

    .axi_video3_wr_en           (axi_video3_wr_en   ), // output FIFO_video1：写使能
    .axi_video3_wr_data         (axi_video3_wr_data ), // input  FIFO_video1：写数据
    .video3_wr_rst              (video3_wr_rst      ), // input  视频源1写地址复位
    
    .rd_req                     (axi_rd_req         ), // input  输出FIFO：读请求
    .rd_en                      (axi_rd_en          ), // output 输出FIFO：读使能
    .rd_data                    (axi_rd_data        ), // output 输出FIFO：读数据
    .rd_rst                     (rd_rst             ), // input  读地址复位信号

    .M_AXI_AWADDR               (axi_awaddr     ),
    .M_AXI_AWUSER               (axi_awuser_ap  ),
    .M_AXI_AWID                 (axi_awuser_id  ),
    .M_AXI_AWLEN                (axi_awlen      ),
    .M_AXI_AWREADY              (axi_awready    ),
    .M_AXI_AWVALID              (axi_awvalid    ),
                                
    .M_AXI_WDATA                (axi_wdata      ),
    .M_AXI_WSTRB                (axi_wstrb      ),
    .M_AXI_WREADY               (axi_wready     ),
    .M_AXI_WID                  (axi_wusero_id  ),
    .M_AXI_WLAST                (axi_wusero_last),
                                
    .M_AXI_ARADDR               (axi_araddr     ),
    .M_AXI_ARUSER               (axi_aruser_ap  ),
    .M_AXI_ARID                 (axi_aruser_id  ),
    .M_AXI_ARLEN                (axi_arlen      ),
    .M_AXI_ARREADY              (axi_arready    ),
    .M_AXI_ARVALID              (axi_arvalid    ),
                                
    .M_AXI_RDATA                (axi_rdata      ),
    .M_AXI_RID                  (axi_rid        ),
    .M_AXI_RLAST                (axi_rlast      ),
    .M_AXI_RVALID               (axi_rvalid     )
);

ddr3_interface #(
    .MEM_ROW_WIDTH              (MEM_ROW_WIDTH  ),
    .MEM_COLUMN_WIDTH           (MEM_COL_WIDTH  ),
    .MEM_BANK_WIDTH             (MEM_BANK_WIDTH ),
    .MEM_DQ_WIDTH               (MEM_DQ_WIDTH   ),
    .MEM_DM_WIDTH               (MEM_DM_WIDTH   ),
    .MEM_DQS_WIDTH              (MEM_DQS_WIDTH  ),
    .CTRL_ADDR_WIDTH            (AXI_ADDR_WIDTH )
)u_ddr3_interface(
    .ref_clk                    (sys_clk        ),   // input
    .resetn                     (key_rst_n      ),   // input
    .ddr_init_done              (ddr_init_done  ),   // output
    .ddrphy_clkin               (ddrphy_clkin   ),   // output
    .pll_lock                   (               ),   // output
    
    .axi_awaddr                 (axi_awaddr     ),   // input {ROW[14], BANK[2:0], ROW[13:0], COL[9:0]}
    .axi_awuser_ap              (axi_awuser_ap  ),   // input
    .axi_awuser_id              (axi_awuser_id  ),   // input [3:0]
    .axi_awlen                  (axi_awlen      ),   // input [3:0]
    .axi_awready                (axi_awready    ),   // output
    .axi_awvalid                (axi_awvalid    ),   // input
    
    .axi_wdata                  (axi_wdata      ),   // input [32*8-1:0]
    .axi_wstrb                  (axi_wstrb      ),   // input [31:0]
    .axi_wready                 (axi_wready     ),   // output
    .axi_wusero_id              (axi_wusero_id  ),   // output [3:0]
    .axi_wusero_last            (axi_wusero_last),   // output
    
    .axi_araddr                 (axi_araddr     ),   // input {ROW[14], BANK[2:0], ROW[13:0], COL[9:0]}
    .axi_aruser_ap              (axi_aruser_ap  ),   // input
    .axi_aruser_id              (axi_aruser_id  ),   // input [3:0]
    .axi_arlen                  (axi_arlen      ),   // input [3:0]
    .axi_arready                (axi_arready    ),   // output
    .axi_arvalid                (axi_arvalid    ),   // input
    
    .axi_rdata                  (axi_rdata      ),   // output [32*8-1:0]
    .axi_rid                    (axi_rid        ),   // output [3:0]
    .axi_rlast                  (axi_rlast      ),   // output
    .axi_rvalid                 (axi_rvalid     ),   // output
    
    .apb_clk                    (1'b0           ),
    .apb_rst_n                  (1'b0           ),
    .apb_sel                    (1'b0           ),
    .apb_enable                 (1'b0           ),
    .apb_addr                   (8'd0           ),
    .apb_write                  (1'b0           ),
    .apb_ready                  (               ),
    .apb_wdata                  (16'd0          ),
    .apb_rdata                  (               ),
    .apb_int                    (               ),
    
    .debug_data                 (               ),
    .debug_calib_ctrl           (               ),
    .debug_slice_state          (               ),
    .dll_step                   (               ),
    .dll_lock                   (               ),
    .force_read_clk_ctrl        (1'b0           ), 
    .init_slip_step             (4'd0           ),
    .init_read_clk_ctrl         (3'd0           ), 
    .force_ck_dly_en            (1'b0           ),
    .force_ck_dly_set_bin       (8'h14          ),
    .ddrphy_gate_update_en      (1'b0           ),
    .update_com_val_err_flag    (               ),
    .rd_fake_stop               (1'b0           ),
    .ck_dly_set_bin             (               ),
    
    .mem_rst_n                  (mem_rst_n      ),   // output
    .mem_ck                     (mem_ck         ),   // output
    .mem_ck_n                   (mem_ck_n       ),   // output
    .mem_cke                    (mem_cke        ),   // output
    .mem_cs_n                   (mem_cs_n       ),   // output
    .mem_ras_n                  (mem_ras_n      ),   // output
    .mem_cas_n                  (mem_cas_n      ),   // output
    .mem_we_n                   (mem_we_n       ),   // output
    .mem_odt                    (mem_odt        ),   // output
    .mem_a                      (mem_a          ),   // output [14:0]
    .mem_ba                     (mem_ba         ),   // output [2:0]
    .mem_dqs                    (mem_dqs        ),   // inout  [3:0]
    .mem_dqs_n                  (mem_dqs_n      ),   // inout  [3:0]
    .mem_dq                     (mem_dq         ),   // inout  [31:0]
    .mem_dm                     (mem_dm         )    // output [3:0]
);

endmodule
