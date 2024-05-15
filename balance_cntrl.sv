module balance_cntrl(clk, rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, steer_pot, en_steer, lft_spd, rght_spd, too_fast);

input clk, rst_n, vld, rider_off;
input en_steer;
input signed [15:0] ptch, ptch_rt;
input [11:0] steer_pot;

input pwr_up; 
output reg too_fast;
output reg signed [11:0] lft_spd, rght_spd;

logic signed [11:0] PID_cntrl, steer_pot, steer_pot_scaled;
logic  [7:0]  ss_tmr;

//logic signed [12:0] left_shaped, rght_shaped;
//logic signed [12:0] lft_torque, rght_torque;
parameter fast_sim =1;
//logic [7:0]ss_timer;

PID iDUT1(.clk(clk), .rst_n(rst_n), .ptch(ptch), .ptch_rt(ptch_rt), .pwr_up(pwr_up), .vld(vld), .rider_off(rider_off), .PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr));

//assign ss_tmr = ss_timer;

SegwayMath iDUT2(.PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr), .steer_pot(steer_pot), .en_steer(en_steer), .pwr_up(pwr_up), .lft_spd(lft_spd), .rght_spd(rght_spd), .too_fast(too_fast), .clk(clk), .rst_n(rst_n));

endmodule
