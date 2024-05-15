module UART_rx(clk,rst_n,RX,clr_rdy,rx_data,rdy);
input clk,rst_n,RX;
input logic clr_rdy;
output logic rdy;
output logic [7:0]rx_data;

logic set_rdy, start, receiving, set_res_ff, shift ;
logic RX_sync_ff1_q, RX_sync_ff2_q;
logic [3:0] bit_count;
logic bit_count_cmp;
logic [8:0] rx_shift_reg;
logic [11:0] baud_cnt, initial_baud_cnt_value;

// For metastability reasons we double flop
always_ff @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		RX_sync_ff1_q <= 1;
		RX_sync_ff2_q <= 1;
	end
	else  begin
		RX_sync_ff1_q <= RX ;
		RX_sync_ff2_q <= RX_sync_ff1_q;
	end
end

// Transitioning form Receive to Idle
assign bit_count_cmp = bit_count[3] & (!bit_count[2]) & bit_count[1] & (!bit_count[0]) ;
//Asserting shift after completion of baud count
assign shift = (baud_cnt == 12'd0) ? 1 : 0;
//Getting the data bits
assign rx_data = rx_shift_reg[7:0];




//State Machine
typedef enum reg {IDLE, RECEIVE} state_t;
state_t state, next_state;

//Block for State Register
always_ff @ (posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

//State Transitions
always_comb begin
	set_rdy = 0;
	receiving = 0;
	start = 0;
	next_state = state;
	
	case (state)
		RECEIVE : begin
			if (bit_count_cmp == 1) begin
				next_state = IDLE;
				set_rdy = 1;
			end
			else begin
				start = 0;
				receiving = 1;
			end
		end
		default : begin
			if (RX_sync_ff2_q == 0) begin
				next_state = RECEIVE;
				start = 1;
				receiving = 1;
			end
		end
	endcase
end


// Setting and resetting based on the value of clr_rdy
always_ff @ (posedge clk, posedge clr_rdy) begin
	if(clr_rdy)
		set_res_ff <= 0;
	else if (start)
		set_res_ff <= 0;
	else if (set_rdy)
		set_res_ff <= 1;
end

always_ff @ (posedge clk, negedge rst_n) begin
	if (!rst_n)
		rdy <= 0;
	else
		rdy <= set_res_ff;
end

// Receiver shifting data
always_ff @ (posedge clk) begin
	if (shift)
		rx_shift_reg <= {RX_sync_ff2_q, rx_shift_reg[8:1]};

end



// counting the number of bits received
always_ff @ (posedge clk) begin
	if (start)
		bit_count <= 0;
	else if (shift)
		bit_count = bit_count + 1;
end

// baud_cnt for 1302 or 2604 cycles for receiving bits

assign initial_baud_cnt_value = start ? 12'd1302 : 12'd2604 ;

always_ff @ (posedge clk) begin
	if(start || shift)
		baud_cnt <= initial_baud_cnt_value ;
	else if (receiving)
		baud_cnt <= baud_cnt - 1;	
end



endmodule
