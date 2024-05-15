module SPI_mnrch(clk, rst_n, rd_data, done, MOSI, MISO, SCLK, SS_n, wrt, wt_data);
input clk, rst_n, MISO, wrt;
//logic [15:0] wt_data;

output SCLK, MOSI;
output reg SS_n, done;
output [15:0] rd_data;
input [15:0] wt_data;
logic [3:0] bit_cntr;
logic [15:0] shft_reg;
logic [3:0] SCLK_div;


logic set_done, done15, shft, smpl, shft_im, ld_sclk, init, MISO_SMPL;

//OUTPUT FLOP for DONE
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n )
			done <= 0;
	else if(init || !set_done)
			done <= 0;
	else if(set_done) 
			done <= 1;
		
end


///SS_n is the slave select and it is low before any data is sent to the slave/serf
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n )
			SS_n <= 1;
	else if(init )
			SS_n  <= 0;
	else if(set_done) 
			SS_n <= 1;
	
			
end



///SCLK
always_ff @ (posedge clk) begin
	if (ld_sclk)
		SCLK_div <= 4'b1011;
	else
		SCLK_div <= SCLK_div + 1;
end

assign SCLK = SCLK_div[3];

assign shft_im = (SCLK_div == 4'b1111) ? 1:0; //We Shift the data on the falling edge

assign smpl    = (SCLK_div == 4'b0111) ? 1:0; //Sample MISO on the rising edge



always_ff @ (posedge clk) begin  //MISO data getting sampled
	if (smpl)
		MISO_SMPL <= MISO;
end

assign MOSI = shft_reg[15]; 	//MSB of Shift REgister is MOSI Data

assign rd_data = shft_reg;  	//At the end Shift REgister is nothing but rd_data





///Getting MOSI out and MISO in using a single SHIFT REGISTER
always_ff @ (posedge clk) begin 
	if (init)
		shft_reg <= wt_data;
	else if (shft)
		shft_reg <= {shft_reg[14:0], MISO_SMPL};
end

///Bit Counter
always_ff @ (posedge clk) begin
	if (init) 
		bit_cntr <= 4'b0000;
	else if (shft)
		bit_cntr <= bit_cntr + 1;
end
	
assign done15 = &bit_cntr[3:0]; //Counter gets full when the data gets transmitted

//////////STATE MACHINE//////////

typedef enum reg [1:0] {IDLE, FRONT_PORCH, BITS, BACK_PORCH} state_t;
state_t state, next_state;

///Next state transition logic
always_ff @ (posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= next_state;
	end
end

always@(*)
begin
	init = 0;
	shft = 0;
	set_done = 0;
	ld_sclk = 1;
	next_state = state;
	
	case (state)
	
	IDLE : begin
		
		if(wrt) begin
			init = 1;
			set_done = 0;
			ld_sclk = 0;
			shft = 0;
			next_state =  FRONT_PORCH;
			
		end
		
	end
	
	FRONT_PORCH : begin
		init = 0;
		ld_sclk = 0;
		
		if(!shft_im && smpl) begin
			next_state = BITS;
		end
		
	end
	
	BITS : begin
	
		ld_sclk = 0;
		if(!shft_im && smpl && done15) begin
			shft = 0;
			next_state = BACK_PORCH;
		end
		else if(shft_im && !smpl) begin
			
			shft = 1;
		end
	
	end
	
	BACK_PORCH : begin
		if(shft_im && !smpl && done15) begin
			init = 0;
			set_done = 1;
			ld_sclk = 1;
			shft = 1;
			next_state = IDLE;
		end
		else 
			ld_sclk = 0;
	end
    endcase
		
end
		
endmodule	
		
	
	

				