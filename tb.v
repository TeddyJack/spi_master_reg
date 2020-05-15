`timescale 1 ps / 1 ps
`define TUPS 1000000000 // timescale units per second. if 1 ns then TUPS = 10^9
`define SYS_CLK 25  // in MHz



module tb();

reg [23:0] in_data;
reg in_ena;
reg miso;
reg n_rst;
reg treg_sdio;
reg sys_clk;

wire io_update;
wire busy;
wire [23:0]  miso_reg;
wire mosi;
wire n_cs;
wire sclk;
wire sdio;
wire miso_reg_ena;
wire [7:0] my_bit_cnt;
wire my_load_cond;
wire my_eoframe_cond;
wire [2:0] my_pause_cnt;

assign sdio = treg_sdio;



spi_master_reg i1 (
  .io_update (io_update),
  .in_data (in_data),
  .in_ena (in_ena),
  .busy (busy),
  .miso (miso),
  .miso_reg (miso_reg),
  .mosi (mosi),
  .n_cs (n_cs),
  .n_rst (n_rst),
  .sclk (sclk),
  .sdio (sdio),
  .miso_reg_ena (miso_reg_ena),
  .sys_clk (sys_clk),
  .my_bit_cnt (my_bit_cnt),
  .my_load_cond (my_load_cond),
  .my_eoframe_cond (my_eoframe_cond),
  .my_pause_cnt (my_pause_cnt)
);



// calculate timing constants
integer CLK_T = `TUPS / (`SYS_CLK * 1000000);
integer CLK_HALF = `TUPS / (`SYS_CLK * 1000000) / 2;

// generating clocks
always #CLK_HALF sys_clk = !sys_clk;

initial
  begin
  in_data = 0;
  in_ena = 0;
  miso = 0;
  n_rst = 0;
  treg_sdio = 1'bz;
  sys_clk = 1;
  
  #(CLK_T/4)  // initial offset to 1/4 of period for easier clocking
 
  #(10*CLK_T)
  
  n_rst = 1;

  #(1000*CLK_T)
  
  in_ena = 1;
  in_data = {1'b1,23'b0};
  
  #(1000*CLK_T)
  
  in_ena = 0;
  
  #(1000*CLK_T)
  
  $display("Testbench end");
  $stop();
  end



endmodule