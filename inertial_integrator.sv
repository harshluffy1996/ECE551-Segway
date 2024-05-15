//Team Name : Olympus


module inertial_integrator(clk, rst_n, vld, ptch_rt, AZ, ptch);
	

	input clk, rst_n;				//CLOCK AND RESET

	input vld;						//High for a single clock cycle when new inertial readings are valid.
	input [15:0] ptch_rt, AZ;		//16-bit signed raw pitch rate from inertial sensor and AZ will be used for sensor fusion
	output signed [15:0] ptch;

	reg [26:0] ptch_int;			//Pitch integrating accumulator. This is the register ptch_rt is summed into

	wire [15:0] ptch_rt_comp;
	wire signed [15:0] AZ_comp, ptch_acc;
	wire signed [26:0] fusion_ptch_offset;
	wire signed [25:0] ptch_acc_product;

	localparam PTCH_RT_OFFSET 	= 16'h0050;
	localparam AZ_OFFSET 		= 16'h00A0;
	localparam FUDGE 			= 327;


//Sensor Fusion--> To lessen gyro's long term drift and accelerometer's noisy readings

	assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;	//For integration of ptch_rt_comp

	assign AZ_comp = AZ - AZ_OFFSET;				//Sensor fusion (acceleration in Z direction)

	assign ptch_acc_product = AZ_comp * $signed(FUDGE);	

	assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]}; //Pitch angle calculated using accelerometer only.

	assign ptch = ptch_int[26:11];				//Scaling factor dervied by trial and error on actual segway.

	assign fusion_ptch_offset = (ptch_acc > ptch) ? 1024 : -1024;	//If ptch from acclerometer is greater than ptch from gyro.


//Flop that concatenates ptch_int
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			ptch_int <= 0;
		else if(vld)
			ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset;

	end
endmodule