/*
    SRAM module 
*/

module sram
#(
    parameter WIDTH         = 16,
    parameter ADDR_WIDTH    = 4,
    parameter DEPTH         = 1 << ADDR_WIDTH,
    parameter FILE          = "",
    parameter INIT          = 0
)
(
    input                       i_clk,
    input                       i_ce_N, // =0 is chip enable
    
    input                       i_rdWr_N,  // =0 is write, =1 is read
    input  [ADDR_WIDTH-1:0]     i_ramAddr, 
    input  [WIDTH-1:0]          i_ramData,
    output reg [WIDTH-1:0]      o_ramData

);


// reg [WIDTH-1:0] ramData;
reg [WIDTH-1:0] chip[0:DEPTH-1];

  integer file;
  integer scan;
  integer i;
  
  initial
    begin
      // read file contents if FILE is given
      if (FILE != "")
        $readmemh(FILE, chip);
      
      // set all data to 0 if INIT is true
      if (INIT)
        for (i = 0; i < DEPTH; i = i + 1)
          chip[i] = {WIDTH{1'b0}};
    end


always @(posedge i_clk)
    begin
        if (~i_ce_N && ~i_rdWr_N) begin
            chip[i_ramAddr] <= i_ramData;
        end
        else if (~i_ce_N && i_rdWr_N)  begin
            o_ramData <= chip[i_ramAddr];
        end
        else begin 
            o_ramData <= {(WIDTH){1'bz}};
        end
    end


endmodule