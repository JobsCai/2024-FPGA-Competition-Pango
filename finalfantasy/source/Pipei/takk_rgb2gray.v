`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////


module takk_rgb2gray(
    input   clk,
    input   rst_n,
    
    input   [23:0] data_in,
    input          data_in_valid,
    
    output  [7:0]   data_out,
    output  reg        data_out_valid
    );
    reg [15:0]  r_tmp;
    reg [15:0]  g_tmp;
    reg [15:0]  b_tmp;
    reg [15:0]  gray_tmp;
    always@(posedge clk,negedge rst_n)begin
        if(~rst_n)begin
            r_tmp <= 0;
            g_tmp <= 0;
            b_tmp <= 0;
        end
        else if(data_in_valid == 1'b1) begin
            r_tmp <= data_in[23:16]*8'd77;
            g_tmp <= data_in[15:8]*8'd150;
            b_tmp <= data_in[7:0]*8'd29;
        end
    end
    
   always@(posedge clk,negedge rst_n)begin
        if(~rst_n)begin
            gray_tmp <= 0;
        end
        else  begin
         gray_tmp <= r_tmp+g_tmp+b_tmp;
        end
    end
    
    assign data_out = gray_tmp[15:8];
    
    reg delay_data_in_valid;
    always@(posedge clk)begin
        delay_data_in_valid <= data_in_valid;
        data_out_valid <= delay_data_in_valid;
   end
    
endmodule
