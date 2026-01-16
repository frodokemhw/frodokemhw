/*
    SRAM testbench
*/

module sram_tb();
parameter WIDTH         = 16;
parameter ADDR_WIDTH    = 4;
parameter DEPTH         = 1 << ADDR_WIDTH;

reg                       i_clk =0;
reg                        i_ce_N; // =0 is chip enable
reg                        i_rdWr_N;  // =0 is read, =1 is Write
reg   [ADDR_WIDTH-1:0]     i_ramAddr; 
reg   [WIDTH-1:0]          i_ramData;
wire  [WIDTH-1:0]          o_ramData;


sram #(.WIDTH(WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
DUT
    (
        .i_clk(i_clk),
        .i_ce_N(i_ce_N),
        .i_rdWr_N(i_rdWr_N),
        .i_ramAddr(i_ramAddr),
        .i_ramData(i_ramData),
        .o_ramData(o_ramData)
    );

integer i;
initial begin
    $dumpfile("sram_tb.vcd");
    $dumpvars(0,sram_tb);
    i_ce_N <= 1;
    i_rdWr_N <= 1;
    i_ramAddr <= 0;
    i_ramData <= 0;
    #100
    i_ce_N <= 0;
    for (i = 0; i < DEPTH-1; i=i+1) begin
        i_rdWr_N <= 0;
        i_ramAddr <= i;
        i_ramData <= i;
        #10;
    end

    i_rdWr_N <= 1;

    #100

    for (i = 0; i < DEPTH-1; i=i+1) begin
        i_ramAddr <= i;
        #10;
    end
    $display("SRAM Test done");
    $finish;
end

 initial
     $monitor("At time %t, value = %d (%0d) (%0d)",
              $time, i_ramAddr, i_ramData, o_ramData);

always #5 i_clk = ~i_clk;

endmodule