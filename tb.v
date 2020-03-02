`timescale 1 ms/ 1 ms

module tb();

reg n_rst;
reg sclk;
reg miso;
reg [23:0] in_data;
reg in_ena;

wire mosi;
wire n_cs;
wire io_update;
wire busy;
wire [23:0] miso_reg;
wire miso_reg_ena;

wire [7:0] my_bit_cnt;
wire [2:0] my_pause_cnt;
wire       my_load_cond;
wire       my_eof_cond;
wire       my_high_z;



spi_master_reg i1 (
	.n_rst (n_rst),
	
	.sclk (sclk),
	.miso (miso),
	.mosi (mosi),
	.n_cs (n_cs),
	.sdio (sdio),
	.io_update (io_update),
	
	.in_data (in_data),
  .in_ena (in_ena),
  .busy (busy),
  
  .miso_reg (miso_reg),
  .miso_reg_ena (miso_reg_ena),
  
  .my_bit_cnt (my_bit_cnt),
  .my_pause_cnt (my_pause_cnt),
  .my_load_cond (my_load_cond),
  .my_eof_cond (my_eof_cond),
  .my_high_z (my_high_z)
);


integer counter;

always #10 sclk = ~sclk;

always@(posedge sclk)
  if(!busy & in_ena)
    begin
    #5 in_data = $random;
    counter = counter + 1;
    end

  
always@(negedge sclk) // if CPHA: 0 = posedge, 1 = negedge
  if(!n_cs)
    #5 miso = $random;
    
always@(posedge sclk)
  if(counter == 15)
      #5 in_ena = 0;

initial
  begin
  
  n_rst = 0;
  sclk = 0;
  in_data = $random;
  in_ena = 0;
  miso = $random;
  counter = 0;


  #15
  #100
  
  n_rst = 1;

  #100
  
  in_ena = 1;
  
  
  #10000
  
  
  $display("Testbench end");
  $stop();

  end


endmodule

