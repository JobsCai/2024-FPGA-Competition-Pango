//************************************************
// Author       : Jack
// Create Date  : 2023年4月15日 14:27:45
// File Name    : Video_processing_top.v
// Version      : v1.0
// Target Device: PANGO PGL50H
// Function     : 
//************************************************

module Video_processing_top#(
    parameter HDMI_DATA_WIDTH   = 24    ,
    parameter HDMI_RGB_R_WIDTH  = 8     ,
    parameter HDMI_RGB_G_WIDTH  = 8     ,
    parameter HDMI_RGB_B_WIDTH  = 8     ,
    parameter HDMI_H_PIXEL      = 1920  ,
    parameter HDMI_V_PIXEL      = 1080  
)(
    input   wire                            sys_clk         ,
    input   wire                            sys_rst_n       ,
    
    input   wire                            hdmi_pix_clk    ,
    input   wire                            hdmi_vs         ,
    input   wire                            hdmi_hs         ,
    input   wire                            hdmi_de         ,
    input   wire    [HDMI_DATA_WIDTH-1:0]   hdmi_data       ,
    
    output  wire                            hdmi_frame_vs   ,
    output  wire                            hdmi_frame_hs   ,
    output  wire                            hdmi_frame_valid,
    output  wire    [HDMI_DATA_WIDTH-1:0]   hdmi_frame_data 
);
/*************************parameter**************************/


/****************************reg*****************************/
reg                 hdmi_hvalid ;
reg                 hdmi_vvalid ;

reg                 r0_hdmi_vs  ;
reg                 r1_hdmi_vs  ;
reg                 r0_hdmi_hs  ;
reg                 r1_hdmi_hs  ;

/****************************wire****************************/
wire                hdmi_vs_posedge;
wire                hdmi_hs_posedge;
wire                hdmi_data_valid;

/********************combinational logic*********************/
assign hdmi_vs_posedge = r0_hdmi_vs && !r1_hdmi_vs;
assign hdmi_hs_posedge = r0_hdmi_hs && !r1_hdmi_hs;
assign hdmi_data_valid = hdmi_hvalid && hdmi_vvalid;

/***********************instantiation************************/
bilinear_interpolation #(
    .DATA_WIDTH             (HDMI_DATA_WIDTH    ),
    .RGB_R_WIDTH            (HDMI_RGB_R_WIDTH   ),
    .RGB_G_WIDTH            (HDMI_RGB_G_WIDTH   ),
    .RGB_B_WIDTH            (HDMI_RGB_B_WIDTH   ),
    .FRAME_H_PIXEL          (HDMI_H_PIXEL       ),
    .FRAME_V_PIXEL          (HDMI_V_PIXEL       )
)u_bilinear_interpolation(
    .clk                    (hdmi_pix_clk       ),
    .rst_n                  (sys_rst_n          ),
    
    .frame_i_vs             (hdmi_vs            ),
    .frame_i_hs             (hdmi_hs            ),
    .frame_i_valid          (hdmi_de            ),
    .frame_i_data           (hdmi_data          ),
    
    .frame_o_vs             (hdmi_frame_vs      ),
    .frame_o_hs             (hdmi_frame_hs      ),
    .frame_o_valid          (hdmi_frame_valid   ),
    .frame_o_data           (hdmi_frame_data    )
);

/**************************process***************************/
always@(posedge hdmi_pix_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)
        begin
            r0_hdmi_vs <= 1'b0;
            r1_hdmi_vs <= 1'b0;
            r0_hdmi_hs <= 1'b0;
            r1_hdmi_hs <= 1'b0;
        end
    else
        begin
            r0_hdmi_vs <= hdmi_vs;
            r1_hdmi_vs <= r0_hdmi_vs;
            r0_hdmi_hs <= hdmi_hs;
            r1_hdmi_hs <= r0_hdmi_hs;
        end
end

always@(posedge hdmi_pix_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)
        hdmi_vvalid <= 1'b0;
    else if(hdmi_vs_posedge)
        hdmi_vvalid <= 1'b0;
    else if(hdmi_hs_posedge)
        hdmi_vvalid <= !hdmi_vvalid;
    else
        hdmi_vvalid <= hdmi_vvalid;
end

always@(posedge hdmi_pix_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)
        hdmi_hvalid <= 1'b0;
    else if(hdmi_hs_posedge)
        hdmi_hvalid <= 1'b0;
    else if(hdmi_de)
        hdmi_hvalid <= !hdmi_hvalid;
    else
        hdmi_hvalid <= hdmi_hvalid;
end

// always@(posedge hdmi_pix_clk or negedge sys_rst_n)
// begin
//     if(!sys_rst_n)
//         begin
//             hdmi_frame_vs    <= 1'b0;
//             hdmi_frame_hs    <= 1'b0;
//             hdmi_frame_valid <= 1'b0;
//             hdmi_frame_data  <=  'd0;
//         end
//     else
//         begin
//             hdmi_frame_vs    <= hdmi_vs;
//             hdmi_frame_hs    <= hdmi_hs;
//             hdmi_frame_valid <= hdmi_data_valid;
//             hdmi_frame_data  <= hdmi_data;
//         end
// end

/*---------------------------------------------------*/


endmodule
