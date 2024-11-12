`timescale 1ns / 1ps
`define H 12
`define W 12
//////////////////////////////////////////////////////////////////////////////////

//640x480
module takk_census( //5x5窗口大小
    input   clk,
    input   rst_n,
    
    input   [7:0]   data_in,
    input           data_in_valid,
    
    output  [24:0]  data_out,
    output   reg    data_out_valid
    );
    //======================== 坐标计数器 ===============
    reg [9:0] x_pos;
    reg [9:0] y_pos;
    always@(posedge clk ,negedge rst_n)begin
        if(~rst_n)
            x_pos <= 0;
        else if( x_pos == `W-1 && data_in_valid ==1'b1)
            x_pos <= 0;
        else if(data_in_valid ==1'b1)
            x_pos <= x_pos + 1'b1;
    end
    
    always@(posedge clk ,negedge rst_n)begin
        if(~rst_n)
            y_pos <= 0;
        else if( y_pos == `H-1 && x_pos == `W-1 && data_in_valid ==1'b1)
            y_pos <= 0;
        else if(data_in_valid ==1'b1 && x_pos == `W-1)
            y_pos <= y_pos + 1'b1;
    end
    //======================= 缓存部分 ==================
    reg [9 : 0] addra;
    reg [9 : 0] addrb;
    wire [9:0] addra_plus2 = addra + 2 ;
     //=========== 地址
    always@(posedge clk,negedge rst_n)begin
        if(~rst_n)begin
            addra<=0;
            addrb<=0;
        end
        else if(data_in_valid==1'b1)begin
            //========== a ==========
            if(addra == `W-1)
                addra<=0;
            else
                addra<=addra+1'd1;
            //========= b ===========
            if(addra_plus2 > `W-1)
                addrb <= addra_plus2 - `W;
            else
                addrb <= addra_plus2;
        end
    end
    
    //=========== 数据 ==============
    wire [7:0] wr_data;
    wire [7:0] rd_data;
    wire [7:0] linebuffer_in[0:4];
    wire [7:0] linebuffer_out[0:4];
    
    assign linebuffer_in[0] = data_in;
    genvar k ;
    generate 
        for (k=1;k<5;k=k+1)begin
            assign linebuffer_in[k] = linebuffer_out[k-1];
        end
    endgenerate
    
    generate 
         for (k=0;k<5;k=k+1)begin
            linebuffer your_instance_name (
              .wr_clk(clk),    // input wire clka
              .wr_clk_en(data_in_valid),      // input wire ena
              .wr_en(data_in_valid),      // input wire [0 : 0] wea
              .wr_addr(addra),  // input wire [9 : 0] addra
              .wr_data(linebuffer_in[k]),    // input wire [7 : 0] dina
              .wr_rst(~rst_n),
              .rd_rst(~rst_n),
              
              .rd_clk(clk),    // input wire clkb
              .rd_clk_en(data_in_valid),      // input wire enb
              .rd_addr(addrb),  // input wire [9 : 0] addrb
              .rd_data(linebuffer_out[k])  // output wire [7 : 0] doutb
            );
        end
    endgenerate
    
    //=============== 取出窗口====================================
    reg [7:0] window [4:0][4:0];
    integer i,j;
    always@(posedge clk,negedge rst_n)begin
        if(~rst_n)begin
            for(i=0;i<5;i=i+1)begin
                for(j=0;j<5;j=j+1)begin
                     window[i][j]<=0;
                end
            end
        end
        else begin
            for(i=0;i<5;i=i+1)begin
                window[i][0]<=linebuffer_in[i];
                for(j=1;j<5;j=j+1)begin
                     window[i][j]<=window[i][j-1];
                end
            end
        end
    end
    //====================== Census 计算 ==========================
    wire [7:0] center;
    reg [24:0] census_vec ;
    assign center = window[2][2];
    genvar x,y;
    generate
        for(y=0;y<5;y=y+1)begin
            for(x=0;x<5;x=x+1)begin
                always@(posedge clk)begin
                    if(window[y][x] > center )
                        census_vec[y*5+x] <= 1'b1;
                    else
                        census_vec[y*5+x] <= 1'b0;
                end
            end 
        end
    endgenerate
    
    
    
    assign data_out = census_vec;
    always@(posedge clk)
        data_out_valid <= data_in_valid;
        
endmodule
