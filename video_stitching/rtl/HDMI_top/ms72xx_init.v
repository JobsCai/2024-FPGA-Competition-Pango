//************************************************
// Author       : Jack
// Creat Date   : 2023年3月23日 18:12:32
// File Name    : ms72xx_ctl.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 初始化 MS7200 和 MS7210 的顶层模块
//************************************************

module ms72xx_init#(
    parameter CLK_FREQ  = 26'd10_000_000
)(
    input   wire        sys_clk     ,
    input   wire        sys_rst_n   ,
    output  wire        init_over_tx,
    output  wire        init_over_rx,
    
    output  wire        iic_scl_tx  ,
    inout   wire        iic_sda_tx  ,
    output  wire        iic_scl_rx  ,
    inout   wire        iic_sda_rx  
);
/****************************reg*****************************/
reg             rst_n;
reg             rst_n_temp0;
reg             rst_n_temp1;

/****************************wire****************************/
wire    [ 7:0]  device_id_rx    ;
wire            iic_trig_rx     ;
wire            w_r_rx          ;
wire    [15:0]  addr_rx         ;
wire    [ 7:0]  data_in_rx      ;
wire            busy_rx         ;
wire    [ 7:0]  data_out_rx     ;
wire            byte_over_rx    ;

wire    [ 7:0]  device_id_tx    ;
wire            iic_trig_tx     ;
wire            w_r_tx          ;
wire    [15:0]  addr_tx         ;
wire    [ 7:0]  data_in_tx      ;
wire            busy_tx         ;
wire    [ 7:0]  data_out_tx     ;
wire            byte_over_tx    ;

wire            sda_in_rx       ;
wire            sda_out_rx      ;
wire            sda_out_en_rx   ;

wire            sda_in_tx       ;
wire            sda_out_tx      ;
wire            sda_out_en_tx   ;

/********************combinational logic*********************/
assign iic_sda_rx = sda_out_en_rx ? sda_out_rx : 1'bz   ;
assign sda_in_rx  = iic_sda_rx                          ;

assign iic_sda_tx = sda_out_en_tx ? sda_out_tx : 1'bz   ;
assign sda_in_tx  = iic_sda_tx                          ;

/***********************instantiation************************/
ms7200_lut u_ms7200_lut(
    .clk            (sys_clk        ),//input
    .rst_n          (rst_n          ),//input

    .init_over      (init_over_rx   ),//output reg          
    .device_id      (device_id_rx   ),//output        [7:0] 
    .iic_trig       (iic_trig_rx    ),//output reg          
    .w_r            (w_r_rx         ),//output reg          
    .addr           (addr_rx        ),//output reg   [15:0] 
    .data_in        (data_in_rx     ),//output reg   [ 7:0] 
    .busy           (busy_rx        ),//input               
    .data_out       (data_out_rx    ),//input        [ 7:0] 
    .byte_over      (byte_over_rx   ) //input               
);

iic_dri#(
    .CLK_FRE        (CLK_FREQ       ),//parameter            CLK_FRE   = 27'd50_000_000,//system clock frequency
    .IIC_FREQ       (20'd400_000    ),//parameter            IIC_FREQ  = 20'd400_000,   //I2c clock frequency
    .T_WR           (10'd1          ),//parameter            T_WR      = 10'd5,         //I2c transmit delay ms
    .ADDR_BYTE      (2'd2           ),//parameter            ADDR_BYTE = 2'd1,          //I2C addr byte number
    .LEN_WIDTH      (8'd3           ),//parameter            LEN_WIDTH = 8'd3,          //I2C transmit byte width
    .DATA_BYTE      (2'd1           ) //parameter            DATA_BYTE = 2'd1           //I2C data byte number
)iic_dri_rx(                       
    .clk            (sys_clk        ),//input                clk,
    .rst_n          (rst_n          ),//input                rstn,
    .device_id      (device_id_rx   ),//input                device_id,
    .pluse          (iic_trig_rx    ),//input                pluse,                     //I2C transmit trigger
    .w_r            (w_r_rx         ),//input                w_r,                       //I2C transmit direction 1:send  0:receive
    .byte_len       (4'd1           ),//input  [LEN_WIDTH:0] byte_len,                  //I2C transmit data byte length of once trigger
               
    .addr           (addr_rx        ),//input  [7:0]         addr,                      //I2C transmit addr
    .data_in        (data_in_rx     ),//input  [7:0]         data_in,                   //I2C send data
                 
    .busy           (busy_rx        ),//output reg           busy=0,                    //I2C bus status
    
    .byte_over      (byte_over_rx   ),//output reg           byte_over=0,               //I2C byte transmit over flag               
    .data_out       (data_out_rx    ),//output reg[7:0]      data_out,                  //I2C receive data
                                    
    .scl            (iic_scl_rx     ),//output               scl,
    .sda_in         (sda_in_rx      ),//input                sda_in,
    .sda_out        (sda_out_rx     ),//output   reg         sda_out=1'b1,
    .sda_out_en     (sda_out_en_rx  ) //output               sda_out_en
);

ms7210_lut u_ms7210_lut(
    .clk            (sys_clk        ),//input
    .rst_n          (init_over_rx   ),//input

    .init_over      (init_over_tx   ),//output reg          
    .device_id      (device_id_tx   ),//output        [7:0] 
    .iic_trig       (iic_trig_tx    ),//output reg          
    .w_r            (w_r_tx         ),//output reg          
    .addr           (addr_tx        ),//output reg   [15:0] 
    .data_in        (data_in_tx     ),//output reg   [ 7:0] 
    .busy           (busy_tx        ),//input               
    .data_out       (data_out_tx    ),//input        [ 7:0] 
    .byte_over      (byte_over_tx   ) //input               
);

iic_dri#(
    .CLK_FRE        (CLK_FREQ       ),//parameter            CLK_FRE   = 27'd50_000_000,//system clock frequency
    .IIC_FREQ       (20'd400_000    ),//parameter            IIC_FREQ  = 20'd400_000,   //I2c clock frequency
    .T_WR           (10'd1          ),//parameter            T_WR      = 10'd5,         //I2c transmit delay ms
    .ADDR_BYTE      (2'd2           ),//parameter            ADDR_BYTE = 2'd1,          //I2C addr byte number
    .LEN_WIDTH      (8'd3           ),//parameter            LEN_WIDTH = 8'd3,          //I2C transmit byte width
    .DATA_BYTE      (2'd1           ) //parameter            DATA_BYTE = 2'd1           //I2C data byte number
)iic_dri_tx(                       
    .clk            (sys_clk        ),//input                clk,
    .rst_n          (rst_n          ),//input                rstn,
    .device_id      (device_id_tx   ),//input                device_id,
    .pluse          (iic_trig_tx    ),//input                pluse,                     //I2C transmit trigger
    .w_r            (w_r_tx         ),//input                w_r,                       //I2C transmit direction 1:send  0:receive
    .byte_len       (4'd1           ),//input  [LEN_WIDTH:0] byte_len,                  //I2C transmit data byte length of once trigger
               
    .addr           (addr_tx        ),//input  [7:0]         addr,                      //I2C transmit addr
    .data_in        (data_in_tx     ),//input  [7:0]         data_in,                   //I2C send data
                 
    .busy           (busy_tx        ),//output reg           busy=0,                    //I2C bus status
    
    .byte_over      (byte_over_tx   ),//output reg           byte_over=0,               //I2C byte transmit over flag               
    .data_out       (data_out_tx    ),//output reg[7:0]      data_out,                  //I2C receive data
                                    
    .scl            (iic_scl_tx     ),//output               scl,
    .sda_in         (sda_in_tx      ),//input                sda_in,
    .sda_out        (sda_out_tx     ),//output   reg         sda_out=1'b1,
    .sda_out_en     (sda_out_en_tx  ) //output               sda_out_en
);

/**************************process***************************/
always @(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)
        rst_n_temp0 <= 1'b0;
    else
        rst_n_temp0 <= sys_rst_n;
end
    
always @(posedge sys_clk)
begin
    rst_n_temp1 <= rst_n_temp0;
    rst_n <= rst_n_temp1;
end

endmodule
