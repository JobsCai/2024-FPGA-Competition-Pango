`timescale 1ns / 1ps
module PE #(parameter	N = 8)
	 (
	input		Clk,
	input		Rst_n,
	input       compute_SA,
	input		[N-1:0]F,
	input		[N-1:0]W,
	input       [N*2-1:0]C,
	output	reg	[N-1:0]Next_F,
	output	reg [N*2:0]P
    );
    
    wire    [N*2:0] P_net;
    always@(posedge Clk or negedge Rst_n)begin
    	if(!Rst_n) begin
    		Next_F <=0;
    		P <=0;
    	end
    	else if(compute_SA )begin
            Next_F <=F;
    		P <=P_net;
    	end
    	else begin
    		Next_F <= Next_F;
    		P <= P;
    	end
    end
    reg [15:0] zero = 16'b1;


xbip_multadd  MultAccumIP
(
    .ce               ( 1          ),
    .rst              ( !Rst_n         ),
    .clk              ( Clk         ),
    .a0               ( F          ),
    .a1               ( C          ),
    .b0               ( W          ),
    .b1               ( 1          ),    
    .p                ( P_net           )
);

endmodule

