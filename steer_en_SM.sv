module steer_en_SM(clk,rst_n,tmr_full,sum_gt_min,sum_lt_min,diff_gt_1_4, diff_gt_15_16,clr_tmr,
				   en_steer,rider_off );

  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
  input tmr_full;			// asserted when timer reaches 1.3 sec
  input sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  input sum_lt_min;			// asserted when left_and right load cells are less than min_rider_weight

  /////////////////////////////////////////////////////////////////////////////
  // HEY HOFFMAN...you are a moron.  sum_gt_min would simply be ~sum_lt_min. 
  // Why have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's weight is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

  input diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  input diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// held high in intitial state when waiting for sum_gt_min
  
  logic [11:0] lft_ld, rght_ld;
  // You fill out the rest...use good SM coding practices ///
  logic [12:0] sum;
  logic [11:0] diff;
  localparam MIN_RIDER_WEIGHT = 12'h200;
  localparam WT_HYSTERESIS = 12'h040;
  logic [11:0] diff_abs;
  logic [25:0] tmr; //tmr_fast, tmr_norm;
  parameter fast_sim = 1;
  
  
  
  //State machine has 3 states
typedef enum reg [1:0] {IDLE,WAIT,STEER_EN} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      //IDLE State
      state <= IDLE;
    else
      //Move to next state
      state <= nxt_state;


always_comb begin
		//Default values 
				en_steer = 1'b0;
				nxt_state = IDLE;
				clr_tmr = 0;
				en_steer = 0;
				rider_off = 0;
				nxt_state = IDLE;

  case(state)
	// Proceed to next state if meeting all requirements
	IDLE: 	if (sum_gt_min) begin
				clr_tmr = 1'b1;
				nxt_state =  WAIT;
			end
			else
				rider_off = 1;

	// If below min weight, Rider_Off and go back to IDLE
	WAIT: 	if (sum_lt_min) begin
				rider_off = 1'b1;
				nxt_state = IDLE;
			end

// If Left load and right load has a high margin of difference
			else if (diff_gt_1_4) begin
				clr_tmr = 1'b1;
				nxt_state = WAIT;

			end

//If timer is full enable stter
			else if (tmr_full) begin
				en_steer = 1'b1;
				nxt_state = STEER_EN;
			end


// If there is still a weight difference, have to stay in WAIT state
			else if (!diff_gt_1_4) begin
				nxt_state = WAIT;
			end


// sum is less than rider weight
	STEER_EN: if (sum_lt_min) begin
				rider_off = 1'b1;
				nxt_state = IDLE;
			end


// Clear timer and go back to WAIT if rider off
			else if (diff_gt_15_16) begin
				clr_tmr = 1'b1;
				nxt_state = WAIT;
			end

// Next state gets Steer Enable if Rider is ON
			else if (!diff_gt_15_16) begin
				en_steer = 1'b1;
				nxt_state = STEER_EN;
			end

			default:nxt_state = IDLE;

		endcase
	end

endmodule 
