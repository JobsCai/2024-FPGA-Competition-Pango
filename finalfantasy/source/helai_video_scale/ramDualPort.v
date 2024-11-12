//Dual port RAM
module ramDualPort #(
	parameter DATA_WIDTH    = 8,
	parameter ADDRESS_WIDTH = 8
)(
	input  wire                       clk  ,
	input  wire [(DATA_WIDTH-1):0]    dataA, 
	input  wire [(DATA_WIDTH-1):0]    dataB,
	input  wire [(ADDRESS_WIDTH-1):0] addrA, 
	input  wire [(ADDRESS_WIDTH-1):0] addrB,
	input  wire                       weA  , 
	input  wire                       weB  , 
	output reg [(DATA_WIDTH-1):0]     qA   , 
	output reg [(DATA_WIDTH-1):0]     qB   
);

// Declare the RAM variable
reg [DATA_WIDTH-1:0] ram[2**ADDRESS_WIDTH-1:0];

	//Port A
always @ (posedge clk) begin
	if (weA) begin
		ram[addrA] <= dataA;
		qA <= dataA;
	end
	else qA <= ram[addrA]; 
end 

//Port B
always @ (posedge clk) begin
	if (weB) begin
		ram[addrB] <= dataB;
		qB <= dataB;
	end
	else qB <= ram[addrB];
end

endmodule //ramDualPort