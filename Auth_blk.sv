module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);

input clk, rst_n, RX, rider_off;
output logic pwr_up;

logic [7:0] rx_data;
logic clr_rdy, rdy;
logic [1:0] state, nxt_state;

localparam g = 8'h67;
localparam s = 8'h73;

typedef enum reg [1:0] { IDLE, PWR1, PWR2 } state_t;


UART_rx iUARTrx(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));



always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;
  

always_comb begin
  nxt_state = IDLE;
  pwr_up = 1'b0; 
  clr_rdy = 1'b0;
  
  case (state)
    IDLE: if (rdy & rx_data == g) begin 
            pwr_up = 1'b1;
            clr_rdy = 1'b1;
            nxt_state = PWR1;
          end
          else nxt_state = IDLE; 
    PWR1: begin
          pwr_up = 1'b1; 
          if (rdy & rx_data == s) begin 
            clr_rdy = 1'b1;
            nxt_state = PWR2;
          end
	  else if (rider_off & rdy & rx_data == s) begin 
            clr_rdy = 1'b1;
	    pwr_up = 1'b0;
            nxt_state = IDLE;
          end
          else nxt_state = PWR1;
        end
    PWR2: begin
          pwr_up = 1'b1; 
          if (rider_off) begin 
            pwr_up = 1'b0;
            nxt_state = IDLE;
          end
	  else if (rdy & rx_data == g) begin 
            clr_rdy = 1'b1;
            nxt_state = PWR1;
          end
          else nxt_state = PWR2;
        end
    default: nxt_state = IDLE;
  endcase
end

endmodule