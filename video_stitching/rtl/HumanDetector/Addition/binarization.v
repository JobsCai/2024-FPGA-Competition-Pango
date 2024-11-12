module binarization(
    //module clock
    input               clk             ,   
    input               rst_n           ,   

    
    input               ycbcr_vsync     ,   
    input               ycbcr_href      ,   
    input               ycbcr_de        ,   
    input   [7:0]       img_cb          ,
    input   [7:0]       img_cr          ,
    
    
    output              post_vsync      ,   
    output              post_href       ,   
    output              post_de         ,   
    output   reg        monoc               
);

//reg define
reg    ycbcr_vsync_d;
reg    ycbcr_href_d ;
reg    ycbcr_de_d   ;

//*****************************************************
//**                    main code
//*****************************************************

assign  post_vsync = ycbcr_vsync_d;
assign  post_href  = ycbcr_href_d ;
assign  post_de    = ycbcr_de_d   ;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        monoc <= 1'b0;
    else if((img_cb >= 77) && (img_cb <= 127) && (img_cr >= 133) && (img_cr <= 173))
        monoc <= 1'b1;
    else
        monoc <= 1'b0;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ycbcr_vsync_d <= 1'd0;
        ycbcr_href_d <= 1'd0;
        ycbcr_de_d    <= 1'd0;
    end
    else begin
        ycbcr_vsync_d <= ycbcr_vsync;
        ycbcr_href_d  <= ycbcr_href ;
        ycbcr_de_d    <= ycbcr_de   ;
    end
end

endmodule 