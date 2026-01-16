/*
    SRAM Dual Port testbench
*/

module sram_dp_tb();
parameter WIDTH         = 16;
parameter ADDR_WIDTH    = 4;
parameter DEPTH         = 1 << ADDR_WIDTH;

reg                        i_clk =0;
reg                        i_ce_n;      // =0 is chip enable
reg                        i_rdwr_n_0;  // =0 is write, =1 is read
reg   [ADDR_WIDTH-1:0]     i_addr_0; 
reg   [WIDTH-1:0]          i_data_0;
wire  [WIDTH-1:0]          o_data_0;

reg                        i_rdwr_n_1;  // =0 is read, =1 is Write
reg   [ADDR_WIDTH-1:0]     i_addr_1; 
reg   [WIDTH-1:0]          i_data_1;
wire  [WIDTH-1:0]          o_data_1;


sram_dp #(.WIDTH(WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
DUT
    (
        .i_clk(i_clk),
        .i_ce_n(i_ce_n),
        .i_rdwr_n_0(i_rdwr_n_0),
        .i_addr_0(i_addr_0),
        .i_data_0(i_data_0),
        .o_data_0(o_data_0),
        .i_rdwr_n_1(i_rdwr_n_1),
        .i_addr_1(i_addr_1),
        .i_data_1(i_data_1),
        .o_data_1(o_data_1)
    );

integer i;
initial begin
    $dumpfile("sram_dp_tb.vcd");
    $dumpvars(0,sram_dp_tb);
    i_ce_n <= 1;
    i_rdwr_n_0 <= 1;
    i_rdwr_n_1 <= 1;
    i_addr_0 <= 0;
    i_data_0 <= 0;
    #100
    i_ce_n <= 0;
    for (i = 0; i < DEPTH-1; i=i+1) begin
        i_rdwr_n_0 <= 0;
        i_addr_0 <= i;
        i_data_0 <= i;
        #10;
    end

    i_rdwr_n_0 <= 1;

    #100

    for (i = 0; i < DEPTH-1; i=i+1) begin
        i_addr_1 <= i;
        #10;
    end
    $display("SRAM Test done");
    $finish;
end

 initial
     $monitor("At time %t, i_addr_0 = %d, i_data_0 = %0d, o_data_0= %0d, i_addr_1 = %d, i_data_1 = %0d, o_data_1= %0d", $time, i_addr_0, i_data_0, o_data_0, i_addr_1, i_data_1, o_data_1);

always #5 i_clk = ~i_clk;

endmodule