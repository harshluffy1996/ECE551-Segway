/*PID CONTROL*/
module PID(ptch, ptch_rt,rider_off, pwr_up,vld, PID_cntrl, clk, rst_n, ss_tmr);

input signed [15:0] ptch, ptch_rt;
reg [17:0] integrator;
output signed [11:0] PID_cntrl;
input clk, rst_n;
output reg [7:0] ss_tmr;
logic signed [9:0]  ptch_err_sat;
logic signed [14:0] P_term;
logic signed [14:0] I_term;
logic signed [12:0] D_term;
logic signed [15:0]  PID_inter;
input rider_off, pwr_up, vld;
logic signed [17:0] ptch_err_sat_signExt, ptch_err_sat_sign_Ext_Add, vld_integrator, ride_off_cond_integrator;

logic [8:0] tmr_inc;
reg vld_ov, not_ovf, cnd1, cnd2;
localparam P_COEFF = 5'h0C;
parameter fast_sim =1;

//soft start timer//
logic signed [26:0] pre_ss_tmr, tmr, post_ss_tmr;


//Speeding up integrator
generate if(fast_sim) begin
assign tmr_inc = 9'h100;
//assign tmr = &post_ss_tmr[26:8]? post_ss_tmr:post_ss_tmr+tmr_inc;
assign I_term = (~integrator[17] && |integrator[16:14]) ? 15'h3FFF :
		 (integrator[17] && ~&integrator[16:14]) ? 15'h8000 :					//Saturation to 15 bits
	 	  integrator[15:1];
end else begin
assign tmr_inc = 9'h001;
//assign tmr  = &post_ss_tmr[26:8]? post_ss_tmr:post_ss_tmr+tmr_inc;
assign I_term = {{3{integrator[17]}},integrator[17:6]};
end
endgenerate

assign ptch_err_sat =   (~ptch[15] && |ptch[14:9]) ? 10'h1FF :	//16 bit pitch saturated to 10 bit
			(ptch[15] && ~&ptch[14:9]) ? 10'h200 :
			 ptch[9:0];				

assign P_term = ptch_err_sat*$signed(P_COEFF);

//assign I_term = {{3{integrator[17]}},integrator[17:6]};		//Integrator by 64

assign D_term = ~{{3{ptch_rt[15]}},ptch_rt[15:6]};		//ptch by 64


assign PID_inter = {{{1{P_term[14]}}, P_term} + {{1{I_term[14]}}, I_term} + {{3{D_term[12]}}, D_term}}; //Sum of sign extended PID terms

assign PID_cntrl = (~PID_inter[15] && |PID_inter[14:11]) ? 12'h7FF :
		    (PID_inter[15] && ~&PID_inter[14:11]) ? 12'h800 :					//Saturation to 12 bits
			    PID_inter[11:0];



//Coding for getting integrator
assign ptch_err_sat_signExt = {{8{ptch_err_sat[9]}},ptch_err_sat} ;
assign ptch_err_sat_sign_Ext_Add = ptch_err_sat_signExt+integrator;
assign vld_integrator = vld_ov?ptch_err_sat_sign_Ext_Add:integrator;
assign ride_off_cond_integrator = rider_off?18'h00000:vld_integrator;

always_ff@(posedge clk) begin
if(!rst_n)
integrator<=0;
else
integrator<=ride_off_cond_integrator;
end

assign vld_ov= vld&~not_ovf;
assign cnd1= {~ptch_err_sat_signExt[17]&&~integrator[17]&&ptch_err_sat_sign_Ext_Add[17]};
assign cnd2= {ptch_err_sat_signExt[17]&&integrator[17]&&~ptch_err_sat_sign_Ext_Add[17]};
assign not_ovf=cnd1||cnd2;




always_ff @(posedge clk, negedge rst_n) begin
if (!rst_n)
post_ss_tmr<=0;
else post_ss_tmr<=pre_ss_tmr;
end

assign tmr = &post_ss_tmr[26:8]? post_ss_tmr:post_ss_tmr+tmr_inc;
assign pre_ss_tmr = pwr_up?tmr : 27'h0000000;
assign ss_tmr= post_ss_tmr[26:19];

endmodule
