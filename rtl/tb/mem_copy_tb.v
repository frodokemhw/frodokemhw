/*
    mem_copy testbench
*/
`include "../common/param.v"


module mem_copy_tb();

    parameter WIDTH     = 256;
    parameter MAX_MEM_DEPTH = 320;

    reg                                           i_clk = 0; 
    reg                                           i_rst_n; 
    reg                                           i_start;

    reg [`CLOG2(MAX_MEM_DEPTH)-1:0]               i_start_addr;
    reg [`CLOG2(MAX_MEM_DEPTH)-1:0]               i_end_addr;

    wire [`CLOG2(MAX_MEM_DEPTH)-1:0]              o_mem_in_addr; 
    wire                                          o_mem_in_en;
    wire  [WIDTH-1:0]                             i_mem_in;

    wire [`CLOG2(MAX_MEM_DEPTH)-1:0]              o_mem_out_addr; 
    wire                                          o_mem_out_en;
    wire  [WIDTH-1:0]                             o_mem_out;

    wire                                     o_done;

mem_copy
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
        .i_mem_in(i_mem_in),
        
        .o_mem_out_addr(o_mem_out_addr),
        .o_mem_out_en(o_mem_out_en),
        .o_mem_out(o_mem_out),
        
        .o_done(o_done)
    );

integer start_time;

initial begin
    $dumpfile("mem_copy_tb.vcd");
    $dumpvars(0,mem_copy_tb);
    // f = $fopen("output.txt","w");
    i_start <= 0;
    i_rst_n <= 0;
    i_end_addr <= 0;
    i_start_addr <= 0;

    #100
    i_rst_n <= 1;

    #20

    i_start <= 1;
    i_end_addr <= 319;
    i_start_addr    <= 0;
    start_time = $time;
    #10
    i_start <= 0;



    @(posedge o_done)
    $display("Memory copy clock cycle count: %d", ($time - start_time)/10);

    $writememh("copy_mem_dest.mem", DEST_MEM.chip);

    #100
    $finish;
end



sram #(.WIDTH(WIDTH), .ADDR_WIDTH(`CLOG2(MAX_MEM_DEPTH)), .FILE("./mem_files/ENCAP_B_L1.mem"))
SOURCE_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_mem_in_en? o_mem_in_addr:0),
        .i_ramData(0),
        .o_ramData(i_mem_in)
    );

sram #(.WIDTH(WIDTH), .ADDR_WIDTH(`CLOG2(MAX_MEM_DEPTH)))
DEST_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~o_mem_out_en),
        .i_ramAddr(o_mem_out_en? o_mem_out_addr: 0),
        .i_ramData(o_mem_out),
        .o_ramData()
    );


always #5 i_clk = ~i_clk;


endmodule