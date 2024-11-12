//************************************************
// Author       : Jack
// Create Date  : 2023年4月16日 17:36:40
// File Name    : bilinear_interpolation.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 利用双线性插值实现缩小一半
//************************************************

module bilinear_interpolation#(
    parameter DATA_WIDTH    = 24        ,
    parameter RGB_R_WIDTH   = 8         ,
    parameter RGB_G_WIDTH   = 8         ,
    parameter RGB_B_WIDTH   = 8         ,
    parameter FRAME_H_PIXEL = 1920      ,
    parameter FRAME_V_PIXEL = 1080      
)(
    input   wire                        clk             ,
    input   wire                        rst_n           ,
    
    input   wire                        frame_i_vs      ,
    input   wire                        frame_i_hs      ,
    input   wire                        frame_i_valid   ,
    input   wire    [DATA_WIDTH-1:0]    frame_i_data    ,
    
    output  wire                        frame_o_vs      ,
    output  wire                        frame_o_hs      ,
    output  wire                        frame_o_valid   ,
    output  wire    [DATA_WIDTH-1:0]    frame_o_data    
);
/****************************reg*****************************/
reg             r0_frame_i_vs   ;
reg             r1_frame_i_vs   ;

/****************************wire****************************/
wire                        frame_rst       ; // 将场同步信号上升沿作为复位信号

wire                        frame_vs        ;
wire                        frame_hs        ;
wire                        frame_valid     ;
wire    [DATA_WIDTH-1:0]    frame_data_0    ;
wire    [DATA_WIDTH-1:0]    frame_data_1    ;
wire    [DATA_WIDTH-1:0]    frame_data_2    ;
wire    [DATA_WIDTH-1:0]    frame_data_3    ;

/********************combinational logic*********************/
assign frame_rst = r0_frame_i_vs && (!r1_frame_i_vs);

/***********************instantiation************************/
image_2x2 #(
    .DATA_WIDTH                 (DATA_WIDTH     ),
    .FRAME_H_PIXEL              (FRAME_H_PIXEL  )
)u_image_2x2(
    .clk                        (clk            ),
    .rst_n                      (rst_n          ),
    .frame_rst                  (frame_rst      ),
    
    .frame_i_vs                 (frame_i_vs     ),
    .frame_i_hs                 (frame_i_hs     ),
    .frame_i_valid              (frame_i_valid  ),
    .frame_i_data               (frame_i_data   ),
    
    .frame_o_vs                 (frame_vs       ),
    .frame_o_hs                 (frame_hs       ),
    .frame_o_valid              (frame_valid    ),
    .frame_o_data_0             (frame_data_0   ),
    .frame_o_data_1             (frame_data_1   ),
    .frame_o_data_2             (frame_data_2   ),
    .frame_o_data_3             (frame_data_3   )
);

bilinear_calculator #(
    .DATA_WIDTH                 (DATA_WIDTH     ),
    .RGB_R_WIDTH                (RGB_R_WIDTH    ),
    .RGB_G_WIDTH                (RGB_G_WIDTH    ),
    .RGB_B_WIDTH                (RGB_B_WIDTH    )
)u_bilinear_calculator(
    .clk                        (clk            ),
    .rst_n                      (rst_n          ),
    .frame_rst                  (frame_rst      ),
    
    .frame_i_vs                 (frame_vs       ),
    .frame_i_hs                 (frame_hs       ),
    .frame_i_valid              (frame_valid    ),
    .frame_i_data_0             (frame_data_0   ),
    .frame_i_data_1             (frame_data_1   ),
    .frame_i_data_2             (frame_data_2   ),
    .frame_i_data_3             (frame_data_3   ),
    
    .frame_o_vs                 (frame_o_vs     ),
    .frame_o_hs                 (frame_o_hs     ),
    .frame_o_valid              (frame_o_valid  ),
    .frame_o_data               (frame_o_data   )
);

/**************************process***************************/
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            r0_frame_i_vs <= 1'b0;
            r1_frame_i_vs <= 1'b0;
        end
    else
        begin
            r0_frame_i_vs <= frame_i_vs   ;
            r1_frame_i_vs <= r0_frame_i_vs;
        end
end

endmodule
