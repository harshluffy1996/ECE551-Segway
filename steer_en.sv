module steer_en(clk, rst_n, lft_ld, rght_ld, en_steer, rider_off);

	input clk;				// 50MHz clock
    input rst_n;				// Active low asynch reset
	input signed [11:0] lft_ld, rght_ld;
	output logic en_steer;	// enables steering (goes to balance_cntrl)
    output logic rider_off;	// held high in intitial state when waiting for sum_gt_min
	
	logic [12:0] sum;
    logic [11:0] diff;
    localparam MIN_RIDER_WEIGHT = 12'h200;
    localparam WT_HYSTERESIS = 8'h40;
    logic [11:0] diff_abs;
    logic [25:0] tmr; //tmr_fast, tmr_norm;
    parameter fast_sim = 1;
	
	logic sum_gt_min, sum_lt_min, diff_gt_1_4, diff_gt_15_16;
	logic tmr_full, clr_tmr;
	
	
	steer_en_SM iDUT_SM(.clk(clk), .rst_n(rst_n), .sum_gt_min(sum_gt_min), .sum_lt_min(sum_lt_min), 
						   .diff_gt_1_4(diff_gt_1_4), .diff_gt_15_16(diff_gt_15_16), .clr_tmr(clr_tmr), 
						   .en_steer(en_steer), .rider_off(rider_off), .tmr_full(tmr_full));   


    assign sum = lft_ld + rght_ld;
  
    assign diff = lft_ld - rght_ld;
  
    assign sum_gt_min = (sum > MIN_RIDER_WEIGHT + WT_HYSTERESIS) ? 1'b1 : 1'b0;
  
    assign sum_lt_min = (sum < MIN_RIDER_WEIGHT - WT_HYSTERESIS) ? 1'b1 : 1'b0;
  
    assign diff_abs = (diff[11]) ? (~(diff) + 1) : diff;
  
    assign diff_gt_1_4 = (diff_abs > {{2{sum[11]}}, sum[11:2]}) ? 1'b1 : 1'b0;
  
    assign diff_gt_15_16 = (diff_abs > {{4{sum[11]}}, sum[11:4]}*15) ? 1'b1 : 1'b0;
    
    //assign tmr_fast = tmr >= 26'h0007FFF;
  
    //assign tmr_norm = tmr >= 26'h3FE56C0;
  
    assign tmr_full = (fast_sim) ? ((tmr >= 26'h0007FFF) ? 1'b1 : 1'b0) : ((tmr >= 26'h3FE56C0) ? 1'b1 : 1'b0);
  
  
    always @ (posedge clk, negedge rst_n) begin
	  if (!rst_n)
		 tmr <=  26'h0000000;
	  else if (clr_tmr)
		 tmr <=  26'h0000000;
	  else
		 tmr <=  tmr + 1;
	  end						   
	
endmodule