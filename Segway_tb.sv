module Segway_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
wire RX_TX;
wire PWM1_rght, PWM2_rght, PWM1_lft, PWM2_lft;
wire piezo,piezo_n;
wire cmd_sent;
wire rst_n;					// synchronized global reset

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd;				// command host is sending to DUT
reg send_cmd;				// asserted to initiate sending of command
reg signed [15:0] rider_lean;
reg [11:0] ld_cell_lft, ld_cell_rght,steerPot,batt;	// A2D values
reg OVR_I_lft, OVR_I_rght;

///// Internal registers for testing purposes??? /////////
//logic signed [11:0] steer_pot;

reg rider_turn_left, rider_turn_rght;
////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM1_lft(PWM1_lft),
				  .PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
				  .PWM2_rght(PWM2_rght),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
ADC128S_FC iA2D(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
             .MISO(A2D_MISO),.MOSI(A2D_MOSI),.ld_cell_lft(ld_cell_lft),.ld_cell_rght(ld_cell_rght),
			 .steerPot(steerPot),.batt(batt));			
	 
////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.INERT_INT(INT),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.PWM1_lft(PWM1_lft),.PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
			.PWM2_rght(PWM2_rght),.OVR_I_lft(OVR_I_lft),.OVR_I_rght(OVR_I_rght),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));

//// Instantiate UART_tx (mimics command from BLE module) //////
UART_tx iTX(.clk(clk),.rst_n(rst_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));

/////////////////////////////////////
// Instantiate reset synchronizer //
///////////////////////////////////
rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));



	typedef enum {RIDER_PRESENT, MOTION_ON, RIDER__LEAN, TURN_LEFT, TURN_RIGHT, RIDER_FALL} test_t;
	test_t test;
	
	assign rider_turn_left = iPHYS.omega_rght > iPHYS.omega_lft;
	assign rider_turn_rght = iPHYS.omega_lft > iPHYS.omega_rght;


initial begin
  
  /// Your magic goes here ///
  Initialize_Segway;
  batt = 12'h9C4 			//Assigning value more than threshold battery value
	
	
	
  //TEST 1 : RIDER_PRESENT
  test = RIDER_PRESENT;
  ld_cell_rght = 12'h150;
  ld_cell_lft  = 12'h150;
  
  repeat(2000)@(posedge clk);
  @(negedge clk);
  
  check("pwr_up", 0, iDUT.pwr_up);
  
  //TEST 2 : MOTION_ON
  test = MOTION_ON;
  send_go;
  repeat(10)@(posedge iDUT.iNEMO.wrt);
  
  repeat(500)@(posedge clk);
  @(negedge clk);
  
  check("pwr_up", 0, iDUT.pwr_up);
  
  //TEST 3 : RIDER_LEAN
  test = RIDER__LEAN;
  rider_lean = 0xfff;
  repeat(800000)@(posedge clk);
  @(negedge clk);
	
  check("too_fast", 1, iDUT.too_fast);
  repeat(800000)@(posedge clk);
  @(negedge clk);
  
  check("too_fast", 0, iDUT.too_fast);
  
  //TEST 4 : TURN_LEFT
  test = TURN_LEFT;
  rider_lean = 12'hA60;
  repeat(35000)@(posedge clk);
  @(negedge clk);
  ld_cell_lft = 12h200;
  ld_cell_rght = 12'h100;
  repeat(35000)@(posedge clk);
  @(negedge clk);
  
  ld_cell_lft = 12'h200;
  ld_cell_rght = 12'h200;
  repeat(500000)@(posedge clk);
  @(negedge clk);
  
  check("rider_turn_left", 1, rider_turn_left);
  check("rider_turn_left", 0, rider_turn_left);
  
end
	
always
  #10 clk = ~clk;
	`include "tb_tasks.sv"
endmodule	
