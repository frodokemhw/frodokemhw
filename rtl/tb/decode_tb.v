/*
    Decode testbench
*/
`include "../common/param.v"


module decode_tb();

reg                                         i_clk=0;
reg                                         i_rst_n;
reg                                         i_start;
reg                                         start_encode;
wire                                         done_encode;



wire [`L5_LEN_MU-1:0]                          o_k;

wire [`WORD_SIZE_DECODE-1:0]                i_k_mat;
wire [`CLOG2(`L5_NBAR*`L5_NBAR/`T_DECODE)-1:0]    o_k_mat_addr;
wire                                        o_k_mat_en;

wire                                        o_done;
reg [2:0]                                   i_sec_level;

decode
DUT
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(i_start),

        .i_sec_level(i_sec_level),

        .i_k_mat(i_k_mat),
        .o_k_mat_en(o_k_mat_en),
        .o_k_mat_addr(o_k_mat_addr),
        
        .o_k(o_k),
        .o_done(o_done)
    );

integer start_time;

initial begin
    $dumpfile("decode_tb.vcd");
    $dumpvars(0,decode_tb);
    // f = $fopen("output.txt","w");
    start_encode <= 0;
    i_start <= 0;
    i_rst_n <= 0;
    #100
    i_rst_n <= 1;
    i_sec_level <= 1;

    i_start <= 1;
    start_time = $time;
    #10
    i_start <= 0;



    @(posedge o_done)    
    $display("Decode Clock Cycle Count: %d", ($time - start_time)/10);
    #10
    $display("Decode String =  %x", o_k);

    #100
    $finish;
end


parameter m_file = "./mem_files/ENCODED_M.mem";

sram #(.WIDTH(`WORD_SIZE_DECODE), .ADDR_WIDTH(`CLOG2(`L5_NBAR*`L5_NBAR/`T_ENCODE)), .FILE(m_file))
ENCODED_K_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1),
        .i_ramAddr(o_k_mat_en? o_k_mat_addr: 0),
        .i_ramData(0),
        .o_ramData(i_k_mat)
    );


always #5 i_clk = ~i_clk;


endmodule