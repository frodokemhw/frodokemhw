/*
    Sample testbench
*/
`include "../common/param.v"

module sample_tb();


reg [`SAMPLE_IN_SIZE-1 : 0]                         i_r; 
reg [2:0]                                           i_sec_level; 
wire signed [`CLOG2(`L1_T_CHI_SIZE) + 1 - 1: 0]     o_e;
wire [`L5_WIDTH_Q-1:0]                              o_e_16;

sample 
DUT
    (
        .i_r(i_r),
        .i_sec_level(i_sec_level),
        .o_e(o_e),
        .o_e_16(o_e_16)
    );

integer i,f;
initial begin
    $dumpfile("sample_tb.vcd");
    $dumpvars(0,sample_tb);
    f = $fopen("output.txt","w");
    i_r <= 0;
    i_sec_level <= 1;
    for (i = 0; i < 2**16; i=i+1) begin
        i_r <= i;
        #10;
        // $fwrite(f,"%d\n",o_e);
        $fwrite(f,"%d\n",o_e_16);
    end

  

    #100

    $display("Sample Test done");
    $finish;
end

//  initial
//      $monitor("At time %t, value = %d (%0d) (%0d)",
//               $time, i_ramAddr, i_ramData, o_ramData);

// always #5 i_clk = ~i_clk;

endmodule