/*
    Encode testbench
*/
`include "../common/param.v"


module encode_tb();

reg                                         i_clk=0;
reg                                         i_rst_n;
reg                                         i_start=0;
reg [`L5_LEN_MU-1:0]                        i_k;
wire [`WORD_SIZE_ENCODE-1:0]                o_k_mat;
wire [`CLOG2(`L5_NBAR*`L5_NBAR/`T_ENCODE)-1:0]    o_k_mat_addr;
wire                                        o_k_mat_wen;
wire                                        o_done;
reg [2:0]                                   i_sec_level;
encode
DUT
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(i_start),
        .i_sec_level(i_sec_level),
        .i_k(i_k),
        .o_k_mat_wen(o_k_mat_wen),
        .o_k_mat_addr(o_k_mat_addr),
        .o_k_mat(o_k_mat),
        .o_done(o_done)
    );

integer start_time;

initial begin
    $dumpfile("encode_tb.vcd");
    $dumpvars(0,encode_tb);
    // f = $fopen("output.txt","w");
    i_start <= 0;
    i_rst_n <= 0;
    i_k <= 0;
    i_sec_level <= 1;
    #100
    i_rst_n <= 1;
    if (i_sec_level == 1) begin
        i_k <= {{(128){1'b0}},128'heb4a7c66ef4eba2ddb38c88d8bc706b1};
        // i_sec_level <= 1;
    end
    else if (i_sec_level == 3) begin
        i_k <= {{(64){1'b0}},192'hee716762c15e3b72aa7650a63b9a510040b03c0fe70475c0};
        // i_sec_level <= 3;
    end
    else if (i_sec_level == 5) begin
        i_k <= 256'h9f08587687ff66765c671de73e918d2823ca573ff4e7a31a9160324026e540ea;
        // i_sec_level <= 5;
    end
    i_start <= 1;
    start_time = $time;
    #10
    i_start <= 0;



    @(posedge o_done)
    $display("Encode Clock Cycle Count: %d", ($time - start_time)/10);
    #100
    $finish;
end

always #5 i_clk = ~i_clk;


endmodule