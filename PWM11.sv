module PWM11(clk,rst_n,duty,PWM_sig,PWM_synch,OVR_I_blank_n);
input clk;
input rst_n;
input [10:0]duty;
output reg PWM_sig;
output reg PWM_synch;
output reg OVR_I_blank_n;
logic [10:0]cnt;

assign PWM_synch=(&cnt);  	 //To synchronize changes to in duty to PWM Cycle.
assign OVR_I_blank_n=(cnt>255);  //Ignoring the over current if present in thr first 256 clock cycles.

//Always block for setting and resetting PWM_sig
always_ff@(posedge clk,negedge rst_n) begin
	if(rst_n==0) begin
	PWM_sig<=0;		//If reset is asserted
	end
	else if(cnt>=duty) begin  //PWM_sig is reset if cnt if greater than duty
	PWM_sig<=0;
	end
	else if(cnt<duty) begin
	PWM_sig<=1;		 //PWM_sig is set if cnt is less than duty
	end
end

//Always block for 11 bit Counter
always_ff@(posedge clk,negedge rst_n) begin
	if(rst_n==0) begin
	cnt<=0;
	end
	else begin
	cnt<=cnt+1;
	end
end
endmodule



	

