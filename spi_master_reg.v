module spi_master_reg #(
  parameter [0:0] CPOL = 1,
  parameter [0:0] CPHA = 0,
  parameter [7:0] WIDTH = 24,
  parameter [2:0] PAUSE = 3,  // if in_ena is continuing, pause will be + 1; if (in_ena <= !busy), pause will be + 2
  parameter [0:0] BIDIR = 0,
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
  output reg              miso_reg_ena
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
        bit_cnt <= 0;
        n_cs <= 1;
        mosi_reg <= 0;
        pause_cnt <= 0;
        busy <= 0;
        end
      else
        begin
        if(!busy)
          busy <= in_ena;
        else
          busy <= !n_cs | (pause_cnt != PAUSE - 1'b1);
        
        if(n_cs)
          begin
          n_cs <= !load_condition;
          bit_cnt <= 0;
          end
        else
          begin
          n_cs <= eoframe_condition;
          bit_cnt <= bit_cnt + 1'b1;
          end
        
        if(load_condition)
          mosi_reg <= in_data;
        else
          mosi_reg <= mosi_reg << 1;
          
        if(eoframe_condition)
          pause_cnt <= 0;
        else if(pause_cnt != PAUSE - 1'b1)
          pause_cnt <= pause_cnt + 1'b1;
        end
  else
    always@(negedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        bit_cnt <= 0;
        n_cs <= 1;
        mosi_reg <= 0;
        pause_cnt <= 0;
        busy <= 0;
        end
      else
        begin
        if(!busy)
          busy <= in_ena;
        else
          busy <= !n_cs | (pause_cnt != PAUSE - 1'b1);
        
        if(n_cs)
          begin
          n_cs <= !load_condition;
          bit_cnt <= 0;
          end
        else
          begin
          n_cs <= eoframe_condition;
          bit_cnt <= bit_cnt + 1'b1;
          end
        
        if(load_condition)
          mosi_reg <= in_data;
        else
          mosi_reg <= mosi_reg << 1;
          
        if(eoframe_condition)
          pause_cnt <= 0;
        else if(pause_cnt != PAUSE - 1'b1)
          pause_cnt <= pause_cnt + 1'b1;
        end
endgenerate



generate
  if(CPHA)
    always@(negedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        miso_reg <= 0;
        miso_reg_ena <= 0;
        end
      else
        begin
        if(!n_cs)
          begin
          miso_reg[0] <= miso_int;
          miso_reg[WIDTH-1:1] <= miso_reg[WIDTH-2:0];
          end
        
        miso_reg_ena <= eoframe_condition;
        end
  else
    always@(posedge sclk or negedge n_rst)
      if(!n_rst)
        begin
        miso_reg <= 0;
        miso_reg_ena <= 0;
        end
      else
        begin
        if(!n_cs)
          begin
          miso_reg[0] <= miso_int;
          miso_reg[WIDTH-1:1] <= miso_reg[WIDTH-2:0];
          end
        
        miso_reg_ena <= eoframe_condition;
        end
endgenerate



generate
  if(BIDIR)
    begin
    reg read;
    reg [7:0] z_cnt;
    reg io_update_reg;
    wire high_z = read & (z_cnt > SWAP_DIR_BIT_NUM);
   
    assign sdio = high_z ? 1'bz : mosi_int;
    assign miso_int = sdio;
    assign mosi = 0;
    assign io_update = io_update_reg;

    if(CPOL)
      always@(posedge sclk or negedge n_rst)
        if(!n_rst)
          begin
          z_cnt <= 0;
          read <= 0;
          io_update_reg <= 0;
          end
        else
          if(n_cs)
            begin
            z_cnt <= 0;
            read <= 0;
            io_update_reg <= 0;
            end
          else
            begin
            z_cnt <= z_cnt + 1'b1;
            io_update_reg <= eoframe_condition & !read;
            if(~|z_cnt)
              read <= mosi_int;
            end
    else
      always@(negedge sclk or negedge n_rst)
        if(!n_rst)
          begin
          z_cnt <= 0;
          read <= 0;
          io_update_reg <= 0;
          end
        else
          if(n_cs)
            begin
            z_cnt <= 0;
            read <= 0;
            io_update_reg <= 0;
            end
          else
            begin
            z_cnt <= z_cnt + 1'b1;
            io_update_reg <= eoframe_condition & !read;
            if(~|z_cnt)
              read <= mosi_int;
            end
    end
  else
    begin
    assign mosi = mosi_int;
    assign miso_int = miso;
    assign io_update = 0;
    end
endgenerate



endmodule