module A2D_intf(clk,rst_n,nxt,lft_ld,rght_ld,steer_pot,batt,SS_n,SCLK,MOSI,MISO);
input clk,rst_n,nxt,MISO;
output reg [11:0] lft_ld,rght_ld,steer_pot,batt;
output SS_n,SCLK,MOSI;

logic wrt,done,update;
logic [15:0] cmd,rd_data;

logic [1:0] cnt;
logic [2:0] channel;

localparam CH_0=2'b00;
localparam CH_4=2'b01;
localparam CH_5=2'b10;
localparam CH_6=2'b11;

///instantiate SPI///
SPI_mnrch iDUT_SPI(.clk(clk),.rst_n(rst_n),.wrt(wrt),.done(done),.wt_data(cmd),.rd_data(rd_data),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));

//round robin counter//

always@(posedge clk,negedge rst_n)
if(!rst_n)
cnt<=2'b00;
else if (update)
cnt<=(cnt==2'b11) ? 2'b00 : cnt+1;

assign channel=(cnt==CH_0)?3'b000:(cnt==CH_4)?3'b100:(cnt==CH_5)?3'b101:3'b110;
assign cmd = {2'b00,channel,11'h000};


always_ff @(posedge clk,negedge rst_n)
if(!rst_n)
lft_ld<=12'h000;
else if(update&&cnt==CH_0)
lft_ld<=rd_data[11:0];
    
always_ff@(posedge clk,negedge rst_n)
if(!rst_n)
rght_ld<= 12'h000;
else if(update&&cnt==CH_4)
rght_ld<=rd_data[11:0];

always_ff@(posedge clk,negedge rst_n)
if(!rst_n)
steer_pot<=12'h000;
else if(update&&cnt==CH_5)
steer_pot<=rd_data[11:0];

always_ff@(posedge clk,negedge rst_n)
if(!rst_n)
batt<=12'h000;
else if(update&&cnt==CH_6)
batt<=rd_data[11:0];

////state machine////

typedef enum reg[1:0]{IDLE,SPI_trans_1,deadzone,SPI_trans_2} state_t;
state_t curr_state,nxt_state;

////sequential logic////
always_ff@(posedge clk,negedge rst_n)
if(!rst_n)
curr_state<=IDLE;
else curr_state<=nxt_state;

////combinational logic////

always_comb begin
wrt=0;
update=0;
nxt_state=IDLE;

case (curr_state)

IDLE: begin
if(nxt) begin
wrt=1;
nxt_state=SPI_trans_1;
end
end

SPI_trans_1: begin
if(done)
nxt_state=deadzone;
else nxt_state=SPI_trans_1;
end

deadzone: begin
wrt=1;
nxt_state=SPI_trans_2;
end

SPI_trans_2: begin
if(done) begin
update=1;
nxt_state=IDLE;
end
else nxt_state=SPI_trans_2;

end

default nxt_state=IDLE;

endcase
end
endmodule




