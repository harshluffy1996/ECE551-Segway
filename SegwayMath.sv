module SegwayMath(PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast, clk, rst_n);

input signed [11:0] PID_cntrl; 
input [11:0] steer_pot;
input  [7:0] ss_tmr;
input signed en_steer, pwr_up;
output signed [11:0] lft_spd, rght_spd;
output signed too_fast;
input clk, rst_n;

logic signed [19:0] PID_SS_inter;
logic signed [11:0] steer_pot;
logic signed [11:0] steer_pot_inter;
logic signed [11:0] steer_pot_scaled;
wire signed  [12:0] steer_control;
logic signed [11:0] PID_ss;
logic signed [12:0] lft_steer_cntrl, rght_steer_cntrl;
logic signed [12:0] lft_torque, rght_torque;
logic signed [12:0] PID_ss_new;
logic signed [11:0] steer_control_div;

logic signed [12:0] lft_torq_neg, lft_torq_pos;
logic signed [12:0] lft_torque_high, lft_torque_comp, lft_torque_comp_fin;
logic signed [12:0] lft_shaped;
//logic signed [11:0] lft_spd_max;

logic signed [12:0] rght_torq_neg, rght_torq_pos;
logic signed [12:0] rght_torque_high, rght_torque_comp, rght_torque_comp_fin;
logic signed  [12:0] rght_shaped;
//logic signed [11:0] rght_spd_max;

//logic signed [11:0] lft_shaped_sat;
//logic signed [11:0] rght_shaped_sat;

logic [12:0] lft_torque_abs;
logic [12:0] rght_torque_abs;

localparam  Coeff = 12'h7FF,
	    MIN_DUTY = 13'h3C0,
            LOW_TORQUE_BAND = 8'h3C,
            GAIN_MULT = 6'h10;

assign PID_SS_inter =  $signed({1'b0,ss_tmr})*PID_cntrl;   //Ensuring a smooth start

assign PID_ss = {PID_SS_inter[19:8]};


assign steer_pot_scaled = (steer_pot >= 12'hE00) ?  12'hE00 : (steer_pot <= 12'h200) ?
        12'h200 : steer_pot; // Limit the signal to avoid the extreme values

assign steer_pot_inter = steer_pot_scaled - $signed(Coeff); 

assign steer_control_div = {{{3{steer_pot_inter[11]}},steer_pot_inter[11:3]}} + {{{4{steer_pot_inter[11]}},steer_pot_inter[11:4]}}; // (3/16) of th steer_pot_inter value 

assign steer_control = {steer_control_div[11], steer_control_div}; //Sign extend the value to make it 13 bit




assign PID_ss_new = {1{PID_ss[11], PID_ss}};				//13 bit sign extended

assign lft_steer_cntrl = PID_ss_new + steer_control;

assign rght_steer_cntrl = PID_ss_new - steer_control;

assign lft_torque = (en_steer) ? lft_steer_cntrl : PID_ss_new;		//Left torque is generated when steer is enabled

assign rght_torque = (en_steer) ? rght_steer_cntrl : PID_ss_new;	//Right torque is generated when steer is enabled




/*Deadzone Shaping*/ //LEFT

assign lft_torq_neg = lft_torque - MIN_DUTY; //If left torque is negative

assign lft_torq_pos = lft_torque + MIN_DUTY; //If left torque is postive

assign lft_torque_comp = (lft_torque[12]) ? lft_torq_neg : lft_torq_pos; //Comparing positive and negative left torque using MSB

assign lft_torque_high = lft_torque*$signed(GAIN_MULT);

assign lft_torque_abs = (lft_torque[12]) ? (~(lft_torque) +1) : lft_torque;

assign lft_torque_comp_fin = (lft_torque_abs > LOW_TORQUE_BAND) ? lft_torque_comp : lft_torque_high;

assign lft_shaped = (pwr_up) ? lft_torque_comp_fin : 13'h0000;


/*Deadzone Shaping*/ //Right
assign rght_torq_neg = rght_torque - MIN_DUTY; //If right torque is negative

assign rght_torq_pos = rght_torque + MIN_DUTY; //If right torque is postive

assign rght_torque_comp = (rght_torque[12]) ? rght_torq_neg : rght_torq_pos; //Comparing positive and negative right torque using MSB

assign rght_torque_high = rght_torque*$signed(GAIN_MULT);		//Getting the shaped torque

assign rght_torque_abs = (rght_torque[12]) ? (~(rght_torque) +1) : rght_torque;

assign rght_torque_comp_fin = (rght_torque_abs > LOW_TORQUE_BAND) ? rght_torque_comp : rght_torque_high;

assign rght_shaped = (pwr_up) ? rght_torque_comp_fin : 13'h0000;

//-------

assign lft_spd =   (~lft_shaped[12] && |lft_shaped[11]) ? 12'h7FF :
						  (lft_shaped[12] && ~&lft_shaped[11]) ? 12'h800 :
						   lft_shaped[11:0];       // Saturated to 12 bits from 11 bits

assign rght_spd=   (~rght_shaped[12] && |rght_shaped[11]) ? 12'h7FF :
						  (rght_shaped[12] && ~&rght_shaped[11]) ? 12'h800 :
						   rght_shaped[11:0];


assign too_fast = (lft_spd > $signed(12'd1792) || rght_spd > $signed(12'd1792)) ? 1'b1 : 1'b0;  //Signal to inform the rider is speed is over the limit



endmodule
