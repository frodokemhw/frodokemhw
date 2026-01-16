module aes128_tb();
parameter Nr = 10; // Number of rounds for AES-128
parameter Nk = 4; // Number of 32-bit words in the key for AES-128

// The plain text used as input
reg[127:0] i_data;

// The different keys used for testing (one of each type)
reg[127:0] i_key;

// The expected outputs from the encryption module
wire[127:0] o_data_expected[0:2];

assign o_data_expected[0] = 128'ha35b3cb11eb233638fd2aa248ffdd579;
assign o_data_expected[1] = 128'h0025d29b796c4a43cbf8fe2474f461c3;
assign o_data_expected[2] = 128'hb1d95531148a2c8a62b4773a07b638e9;

// The result of the encryption module for every type
wire[127:0] o_data;

wire [(128*(Nr+1))-1 :0] fullkeys;

wire [(128*(Nr+1))-1 :0] o_round_key;
reg i_rst = 0;
reg i_start = 0;
reg i_start_key_schedule = 0;
reg i_clk = 0;
wire o_done;
wire o_done_key_schedule;


keyExpansion #(Nk,Nr) ke (i_key,fullkeys);

aes128 aes
    (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_data),
        .i_key(i_key),
        .i_start_key_schedule(i_start_key_schedule),
        .o_done_key_schedule(o_done_key_schedule),
        .i_start(i_start),
        .o_done(o_done),
        .o_data(o_data)
    );

always #5 i_clk = ~i_clk; // Clock generation


initial begin
    i_rst = 1;
    i_key = 0;
    i_data = 0;
    #100
    i_rst = 0;
    #10
    i_start_key_schedule = 1;
    i_key = 128'h_129cd242996d818ca55c2abbff0ddc61;
    #10
    i_start_key_schedule = 0;

    @(posedge o_done_key_schedule)
//  $display("Round Key 0:  %h \t %h",  a.fullkeys[128*(0+1)-1:128*0]  ,fullkeys[128*(0+1)-1:128*0]      );
//	$display("Round Key 1:  %h \t %h",  a.fullkeys[128*(1+1)-1:128*1]  ,fullkeys[128*(1+1)-1:128*1]      );
//	$display("Round Key 2:  %h \t %h",  a.fullkeys[128*(2+1)-1:128*2]  ,fullkeys[128*(2+1)-1:128*2]      );
//	$display("Round Key 3:  %h \t %h",  a.fullkeys[128*(3+1)-1:128*3]  ,fullkeys[128*(3+1)-1:128*3]      );
//	$display("Round Key 4:  %h \t %h",  a.fullkeys[128*(4+1)-1:128*4]  ,fullkeys[128*(4+1)-1:128*4]      );
//	$display("Round Key 5:  %h \t %h",  a.fullkeys[128*(5+1)-1:128*5]  ,fullkeys[128*(5+1)-1:128*5]      );
//	$display("Round Key 6:  %h \t %h",  a.fullkeys[128*(6+1)-1:128*6]  ,fullkeys[128*(6+1)-1:128*6]      );
//	$display("Round Key 7:  %h \t %h",  a.fullkeys[128*(7+1)-1:128*7]  ,fullkeys[128*(7+1)-1:128*7]      );
//	$display("Round Key 8:  %h \t %h",  a.fullkeys[128*(8+1)-1:128*8]  ,fullkeys[128*(8+1)-1:128*8]      );
//	$display("Round Key 9:  %h \t %h",  a.fullkeys[128*(9+1)-1:128*9]  ,fullkeys[128*(9+1)-1:128*9]      );
//	$display("Round Key 10: %h \t %h",  a.fullkeys[128*(10+1)-1:128*10],fullkeys[128*(10+1)-1:128*10]    );

    #10 
    i_data = 128'h_1a120000000000000000000000000000; i_start = 1; #10
    i_data = 128'h_00112233445566778899aabbccddeeff; i_start = 1; #10
    i_data = 128'h_00112233445566778899aabbccddeefe; i_start = 1; #10
    i_start = 0;
    #10
    
    @(posedge o_done)
    #10
    if (o_data !== o_data_expected[0]) begin
        $display("AES-128 Test 1 Failed: Expected %h, Got %h", o_data_expected[0], o_data);
    end else begin
        $display("AES-128 Test 1 Passed");
    end
    
    #10
    if (o_data !== o_data_expected[1]) begin
        $display("AES-128 Test 2 Failed: Expected %h, Got %h", o_data_expected[1], o_data);
    end else begin
        $display("AES-128 Test 2 Passed");
    end
    
    #10
    if (o_data !== o_data_expected[2]) begin
        $display("AES-128 Test 3 Failed: Expected %h, Got %h", o_data_expected[2], o_data);
    end else begin
        $display("AES-128 Test 3 Passed");
    end
    
    #1000;
    $finish;

end
wire test;
assign test = fullkeys == o_round_key;

endmodule