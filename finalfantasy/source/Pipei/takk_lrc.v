`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
`define MAX_DISP 64
`define T 8
module takk_lrc(
    input   clk,
    input   rst_n,
    
    input   [7:0]   data_in_L,
    input   [7:0]   data_in_R,
    
    input           data_in_L_valid,
    input           data_in_R_valid,
    
    
    output  [7:0]   data_out,
    output   reg       data_out_valid
    );
//=================== 数据缓存 移位寄存===========================
    reg [7:0]   disparity_buffer[0:`MAX_DISP-1];
    integer i;
    always@(posedge clk ,negedge rst_n)begin
        if(~rst_n)begin
            for(i=0;i<`MAX_DISP;i=i+1)begin
                disparity_buffer[i]<=0;
            end
        end
        else begin
            disparity_buffer[0] <= data_in_L;
            for(i=1;i<`MAX_DISP;i=i+1)begin
                disparity_buffer[i]<=disparity_buffer[i-1];
            end
        end
    end
    
    wire [7:0] corr_disp;
    reg  [7:0] data_out_reg;
    assign corr_disp = disparity_buffer[`MAX_DISP-data_in_R];
    
    //=================== 做比较 ============================
    always@(posedge clk ,negedge rst_n)begin
       if(corr_disp>=data_in_R)begin
            if(corr_disp - data_in_R < `T)
                data_out_reg <= data_in_R;
            else
                data_out_reg <= 0;
       end
       else begin
            if(data_in_R -  corr_disp < `T)
                data_out_reg <= data_in_R;
            else
                data_out_reg <= 0;
       end
    end
    
    //=================================
    assign data_out = data_out_reg;
    always@(posedge clk)
        data_out_valid  <= data_in_L_valid;
    
endmodule
