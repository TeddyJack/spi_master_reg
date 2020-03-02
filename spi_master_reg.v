`timescale 1 ms/ 1 ms

module spi_master_reg #(
  parameter [0:0] CPOL = 1,
  parameter [0:0] CPHA = 1,
  parameter [7:0] WIDTH = 24,
  parameter [2:0] PAUSE = 4,  // if in_ena is continuing, pause will be + 1; if (in_ena <= #5 !busy), pause will be + 2
  parameter [0:0] BIDIR = 1,
  parameter [7:0] SWAP_DIR_BIT_NUM = 7  // after this bit (counts from 0) sdio goes into high-z state
)(
  input                   n_rst,
        
  input                   sclk,
  input                   miso,
  output                  mosi,
  output reg              n_cs,
  inout                   sdio,
  output                  io_update,
        
  input       [WIDTH-1:0] in_data,
  input                   in_ena,
  output reg              busy,
  
  output reg  [WIDTH-1:0] miso_reg,
  output reg              miso_reg_ena,
  
  output            [7:0] my_bit_cnt,
  output            [2:0] my_pause_cnt,
  output                  my_load_cond,
  output                  my_eof_cond,
  output                  my_high_z
);


wire mosi_int;
wire miso_int;

reg [WIDTH-1:0] mosi_reg;
assign mosi_int = mosi_reg[WIDTH-1];
reg [7:0] bit_cnt;
reg [2:0] pause_cnt;

wire load_condition = !busy & in_ena;
wire eoframe_condition = (bit_cnt == WIDTH - 1'b1);


generate
  if(CPOL)    
    always@(posedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        bit_cnt <= #5 0;
        n_cs <= #5 1;
        mosi_reg <= #5 0;
        pause_cnt <= #5 0;
        busy <= #5 0;
        end
      else
        begin
        if(!busy)
          busy <= #5 in_ena;
        else
          busy <= #5 !n_cs | (pause_cnt != PAUSE - 1'b1);
        
        if(n_cs)
          begin
          n_cs <= #5 !load_condition;
          bit_cnt <= #5 0;
          end
        else
          begin
          n_cs <= #5 eoframe_condition;
          bit_cnt <= #5 bit_cnt + 1'b1;
          end
        
        if(load_condition)
          mosi_reg <= #5 in_data;
        else
          mosi_reg <= #5 mosi_reg << 1;
          
        if(eoframe_condition)
          pause_cnt <= #5 0;
        else if(pause_cnt != PAUSE - 1'b1)
          pause_cnt <= #5 pause_cnt + 1'b1;
        end
  else
    always@(negedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        bit_cnt <= #5 0;
        n_cs <= #5 1;
        mosi_reg <= #5 0;
        pause_cnt <= #5 0;
        busy <= #5 0;
        end
      else
        begin
        if(!busy)
          busy <= #5 in_ena;
        else
          busy <= #5 !n_cs | (pause_cnt != PAUSE - 1'b1);
        
        if(n_cs)
          begin
          n_cs <= #5 !load_condition;
          bit_cnt <= #5 0;
          end
        else
          begin
          n_cs <= #5 eoframe_condition;
          bit_cnt <= #5 bit_cnt + 1'b1;
          end
        
        if(load_condition)
          mosi_reg <= #5 in_data;
        else
          mosi_reg <= #5 mosi_reg << 1;
          
        if(eoframe_condition)
          pause_cnt <= #5 0;
        else if(pause_cnt != PAUSE - 1'b1)
          pause_cnt <= #5 pause_cnt + 1'b1;
        end
endgenerate



generate
  if(CPHA)
    always@(negedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        miso_reg <= #5 0;
        miso_reg_ena <= #5 0;
        end
      else
        begin
        if(!n_cs)
          begin
          miso_reg[0] <= #5 miso_int;
          miso_reg[WIDTH-1:1] <= #5 miso_reg[WIDTH-2:0];
          end
        
        miso_reg_ena <= #5 eoframe_condition;
        end
  else
    always@(posedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        miso_reg <= #5 0;
        miso_reg_ena <= #5 0;
        end
      else
        begin
        if(!n_cs)
          begin
          miso_reg[0] <= #5 miso_int;
          miso_reg[WIDTH-1:1] <= #5 miso_reg[WIDTH-2:0];
          end
        
        miso_reg_ena <= #5 eoframe_condition;
        end
endgenerate



generate
  if(BIDIR)
    begin
    reg read;
    reg [7:0] z_cnt;
    reg io_update_reg;
    wire high_z = read & (z_cnt > SWAP_DIR_BIT_NUM);
    assign my_high_z = high_z;  // debug
   
    assign sdio = high_z ? 1'bz : mosi_int;
    assign miso_int = sdio;
    assign mosi = 0;
    assign io_update = io_update_reg;

    if(CPOL)
      always@(posedge sclk or negedge n_rst)
        if(!n_rst)
          begin
          z_cnt <= #5 0;
          read <= #5 0;
          io_update_reg <= #5 0;
          end
        else
          if(n_cs)
            begin
            z_cnt <= #5 0;
            read <= #5 0;
            io_update_reg <= #5 0;
            end
          else
            begin
            z_cnt <= #5 z_cnt + 1'b1;
            io_update_reg <= #5 eoframe_condition & !read;
            if(~|z_cnt)
              read <= #5 mosi_int;
            end
    else
      always@(negedge sclk or negedge n_rst)
        if(!n_rst)
          begin
          z_cnt <= #5 0;
          read <= #5 0;
          io_update_reg <= #5 0;
          end
        else
          if(n_cs)
            begin
            z_cnt <= #5 0;
            read <= #5 0;
            io_update_reg <= #5 0;
            end
          else
            begin
            z_cnt <= #5 z_cnt + 1'b1;
            io_update_reg <= #5 eoframe_condition & !read;
            if(~|z_cnt)
              read <= #5 mosi_int;
            end
    end
  else
    begin
    assign mosi = mosi_int;
    assign miso_int = miso;
    assign io_update = 0;
    end
endgenerate


assign my_bit_cnt = bit_cnt;
assign my_pause_cnt = pause_cnt;
assign my_load_cond = load_condition;
assign my_eof_cond = eoframe_condition;



endmodule