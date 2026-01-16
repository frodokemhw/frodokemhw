/*
    mem_compare testbench
*/
`include "../common/param.v"


module mem_compare_tb();

    parameter WIDTH     = 128;
    parameter MAX_MEM_DEPTH = 640;

    reg                                           i_clk = 0; 
    reg                                           i_rst_n; 
    reg                                           i_start;

    reg [`CLOG2(MAX_MEM_DEPTH)-1:0]               i_start_addr;
    reg [`CLOG2(MAX_MEM_DEPTH)-1:0]               i_end_addr;

    wire [`CLOG2(MAX_MEM_DEPTH)-1:0]              o_mem_in_addr; 
    wire                                          o_mem_in_en;
    wire  [WIDTH-1:0]                             i_mem_in_1;
    wire  [WIDTH-1:0]                             i_mem_in_2;

    
    wire                                     o_done;
    wire                                     o_fail;

mem_compare
#(
    .WIDTH(WIDTH),
    .MAX_MEM_DEPTH(MAX_MEM_DEPTH)
)
DUT
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(i_start),

        .i_start_addr(i_start_addr),
        .i_end_addr(i_end_addr),

        .o_mem_in_addr(o_mem_in_addr),
        .o_mem_in_en(o_mem_in_en),
        .i_mem_in_1(i_mem_in_1),
        .i_mem_in_2(i_mem_in_2),
        
        .o_fail(o_fail),
        
        .o_done(o_done)
    );

integer start_time;

initial begin
    $dumpfile("mem_compare_tb.vcd");
    $dumpvars(0,mem_compare_tb);
    // f = $fopen("output.txt","w");
    i_start <= 0;
    i_rst_n <= 0;
    i_end_addr <= 0;
    i_start_addr <= 0;

    #100
    i_rst_n <= 1;

    #20

    i_start <= 1;
    i_end_addr <= MAX_MEM_DEPTH-1;
    i_start_addr    <= 0;
    start_time = $time;
    #10
    i_start <= 0;



    @(posedge o_done)
    $display("Memory compare clock cycle count: %d", ($time - start_time)/10);

    #100
    $finish;
end



sram #(.WIDTH(WIDTH), .ADDR_WIDTH(`CLOG2(MAX_MEM_DEPTH)), .FILE("./mem_files/shake/ENCAP_B_L1.mem"))
SOURCE_MEM_1
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_mem_in_en? o_mem_in_addr:0),
        .i_ramData(0),
        .o_ramData(i_mem_in_1)
    );

sram #(.WIDTH(WIDTH), .ADDR_WIDTH(`CLOG2(MAX_MEM_DEPTH)), .FILE("./mem_files/shake/DECAP_S_L1.mem"))
SOURCE_MEM_2
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_mem_in_en? o_mem_in_addr:0),
        .i_ramData(0),
        .o_ramData(i_mem_in_2)
    );


always #5 i_clk = ~i_clk;


endmodule