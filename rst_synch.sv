module rst_synch(input clk,input RST_n,output reg rst_n);
logic rs1;

always_ff@(negedge clk,negedge RST_n) begin

	if(RST_n==0) begin
		rst_n<=0;
		rs1<=0;
		
	end
	else 		
		rs1<=1;
		rst_n<=rs1;
		
end

endmodule
	


