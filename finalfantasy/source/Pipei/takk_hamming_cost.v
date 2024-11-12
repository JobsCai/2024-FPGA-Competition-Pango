`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

`define MAX_DISP 64
module takk_hamming_cost(
    input clk,
    input rst_n,
    
    input   [24:0] data_in_L,
    input   [24:0] data_in_R,
    input          data_in_L_valid,
    input          data_in_R_valid,
    
    output  [`MAX_DISP*6-1:0] data_out,//代价空间 （可以后接WTA得到粗糙视差图）
    output  reg           data_out_valid
    
    );
    
    //============= 缓存 视差范围内的census向量 以便并行处理========================
    integer i;
    reg [24:0] census_array_L [0:`MAX_DISP-1];
    reg [24:0] census_array_R [0:`MAX_DISP-1];
    
    always@(posedge clk,negedge rst_n)begin
        if(~rst_n)begin
            for (i=0;i<`MAX_DISP;i=i+1)begin
                census_array_L[i]<=0;
                census_array_R[i]<=0;
            end
        end
        else if(data_in_R_valid == 1'b1)begin
            census_array_R[0]<=data_in_R;
            census_array_L[0]<=data_in_L;
            for (i=1;i<`MAX_DISP;i=i+1)begin
                census_array_R[i]<=census_array_R[i-1];
                census_array_L[i]<=census_array_L[i-1];
            end
        end    
    end
    
    //============== 并行异或运算 MAX_DISP=> 1 ======================
    wire [24:0] now_census_L ;
    reg  [24:0] hamming_distance_vec[0:`MAX_DISP-1];
    assign now_census_L = census_array_L[0];
    always@(posedge clk,negedge rst_n)begin
       if(~rst_n)begin
            for (i=0;i<`MAX_DISP;i=i+1)begin
                hamming_distance_vec[i]<=0;
            end
       end
       else begin
            for (i=0;i<`MAX_DISP;i=i+1)begin
                hamming_distance_vec[i]<=now_census_L ^ census_array_R[i];
            end
       end
    end
   //============== 统计1的个数  5级加法树======================     
    reg [1:0] add0[0:`MAX_DISP-1][0:12];
    reg [2:0] add1[0:`MAX_DISP-1][0:6];
    reg [3:0] add2[0:`MAX_DISP-1][0:3];
    reg [4:0] add3[0:`MAX_DISP-1][0:1];
    reg [5:0] add4[0:`MAX_DISP-1];
    integer disp_index,add_index;
    always@(posedge clk)begin
        //复位略去
        
        
        //===== add0 ======
        for(disp_index=0;disp_index<`MAX_DISP;disp_index=disp_index+1)begin//视差方向
            for(add_index=0;add_index<12;add_index=add_index+1)begin //组内加法
                add0[disp_index][add_index]<=hamming_distance_vec[disp_index][add_index*2]+hamming_distance_vec[disp_index][add_index*2+1];
            end
                add0[disp_index][12] <= hamming_distance_vec[disp_index][24];
        end
        //===== add1 ======
        for(disp_index=0;disp_index<`MAX_DISP;disp_index=disp_index+1)begin//视差方向
            for(add_index=0;add_index<6;add_index=add_index+1)begin //组内加法
                add1[disp_index][add_index]<=add0[disp_index][add_index*2]+add0[disp_index][add_index*2+1];
            end
                add1[disp_index][6] <= add0[disp_index][12];
        end
        //===== add2 ======
        for(disp_index=0;disp_index<`MAX_DISP;disp_index=disp_index+1)begin//视差方向
            for(add_index=0;add_index<3;add_index=add_index+1)begin //组内加法
                add2[disp_index][add_index]<=add1[disp_index][add_index*2]+add1[disp_index][add_index*2+1];
            end
                add2[disp_index][3] <= add0[disp_index][6];
        end
         //===== add3 ======
        for(disp_index=0;disp_index<`MAX_DISP;disp_index=disp_index+1)begin//视差方向
            for(add_index=0;add_index<2;add_index=add_index+1)begin //组内加法
                add3[disp_index][add_index]<=add2[disp_index][add_index*2]+add2[disp_index][add_index*2+1];
            end
        end
          //===== add4 ======
        for(disp_index=0;disp_index<`MAX_DISP;disp_index=disp_index+1)begin//视差方向
           add4[disp_index]<=add3[disp_index][0]+add2[disp_index][1];
        end
    end    
    
    //==================== 输出幅值 ==============
    genvar k;
    generate 
        for(k=0;k<`MAX_DISP;k=k+1)begin
            assign data_out[(k+1)*6-1:k*6] = add4[k];
        end
    endgenerate
    
    //============= data_valid 延时 6拍 ==========================
    reg [4:0] delay_data_in_valid;
    always@(posedge clk)begin
         delay_data_in_valid[4:1]<={delay_data_in_valid[3:0],data_in_L_valid};
    end
     always@(posedge clk)begin
         data_out_valid<=delay_data_in_valid[4];
    end
    
endmodule
