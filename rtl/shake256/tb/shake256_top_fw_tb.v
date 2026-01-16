

// `timescale 1 ns / 10 ps
module shake_top_fw_tb;
parameter PERIOD = 10; //100MHz
parameter DELAY  = 0.1*PERIOD;

parameter REF_BIT   = 2*1088;      //output reference bit size
parameter DW        = 1344;        //data width


reg                      clk_i;              //system clock
reg                      rst_ni;             //system reset, active low
reg                      start_i;            //start of SHAKE process, 1 clock pulse, assert before putting input data
reg    [DW-1:0]          din_i;              //data input
reg                      din_valid_i;        //data input valid signal, transaction happens when both din_valid_i and din_ready_o HIGH
reg                      last_din_i;         //last data input, also used as first data output squeeze
reg    [7:0]             last_din_byte_i;    //byte length of last data input, 0 to 8 for DW=64
// reg    [7:0]            din_bytes_i;    //byte length of last data input, 0 to 8 for DW=64
reg                      dout_ready_i;       //signal to request output data, transaction happens when both dout_ready_i and dout_valid_o HIGH
wire                     din_ready_o;        //signal showing shake module ready to receive input data, transaction happens when both din_valid_i and din_ready_o HIGH
wire   [DW-1:0]            dout_o;             //data output
wire                     dout_valid_o;       //data output valid signal, transaction happens when both dout_ready_i and dout_valid_o HIGH
reg    [REF_BIT-1:0]     dout_ref;           //output reference
reg sel_shake128_i;

integer start_time;
integer time_shake_128;
integer time_shake_256;
initial
begin
  $dumpfile("shake256_top_fw_tb.vcd");
  $dumpvars(0, shake_top_fw_tb);
  clk_i = 0;
  rst_ni = 0;
  start_i = 0;
  din_valid_i = 0;
  last_din_i = 0;
  last_din_byte_i = 0;
  dout_ready_i = 0;
  sel_shake128_i = 0;
  #100 rst_ni = 1;
  start_time = 0;
//==============================================================================

//--------------SHAKE-256------------------------

  // #10 
  // @(posedge clk_i) #(DELAY) start_i = 1;
  // @(posedge clk_i) #(DELAY) start_i = 0;
  // $display("\nTest SHAKE-256 with NULL (0 bytes input), and 2x136 bytes (2x17 of 64 bits) output\n");
  // din_valid_i = 1;
  // last_din_i = 1;
  // last_din_byte_i = 0;
  // $display("Input: NULL\n");
  // @(posedge clk_i) #(DELAY);
  // din_valid_i = 0;
  // last_din_i = 0;
  // dout_ref = 'h46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762fd75dc4ddd8c0f200cb05019d67b592f6fc821c49479ab48640292eacb3b7c4be141e96616fb13957692cc7edd0b45ae3dc07223c8e92937bef84bc0eab862853349ec75546f58fb7c2775c38462c5010d846c185c15111e595522a6bcd16cf86f3d122109e3b1fdd943b6aec468a2d621a7c06c6a957c62b54dafc3be87567d677231395f6147293b68ceab7a9e0c58d864e8efde4e1b9a46cbe854713672f5caaae314ed9083dab4b099f8e300f01b8650f1f4b1d8fcf3f3cb53fb8e9eb2ea203bdc970f50ae55428a91f7f53ac266b28419c3778a15fd248d339ede785fb7f5a1aaa96d313eacc890936c173cdcd0f;

  // check_dout(2*1088/64);
  

//==============================================================================
//--------------SHAKE-256------------------------
  #50 
  start_i = 1; sel_shake128_i = 0;   #(PERIOD)
  start_i = 0;   #(PERIOD)
  
  // wait(din_ready_o) @(posedge clk_i) #(DELAY);
  //   last_din_byte_i = 136;
  //   last_din_i = 0;
  //   din_valid_i = 1;
  //   din_i = {1088'h626c6b315f643031626c6b315f643032626c6b315f643033626c6b315f643034626c6b315f643035626c6b315f643036626c6b315f643037626c6b315f643038626c6b315f643039626c6b315f643130626c6b315f643131626c6b315f643132626c6b315f643133626c6b315f643134626c6b315f643135626c6b315f6431360000000000000000, {(DW-1088){1'b0}}};
  //   #(PERIOD)
  //   din_valid_i = 0;

  $display("\nTest SHAKE-256 -- 136 bytes input and 136 bytes output\n");
  wait(din_ready_o) @(posedge clk_i) #(DELAY);
    last_din_byte_i = 136;
    last_din_i = 1;
    din_valid_i = 1;
    din_i = {1088'h626c6b315f643031626c6b315f643032626c6b315f643033626c6b315f643034626c6b315f643035626c6b315f643036626c6b315f643037626c6b315f643038626c6b315f643039626c6b315f643130626c6b315f643131626c6b315f643132626c6b315f643133626c6b315f643134626c6b315f643135626c6b315f6431360000000000000000, {(DW-1088){1'b0}}};
    #(PERIOD)
    din_valid_i = 0;
    // start_time = $time;

   @(posedge clk_i) #(DELAY);
  din_valid_i = 0;
  last_din_i = 0;  
  
  wait(dout_valid_o) @(posedge clk_i) #(PERIOD);
  if (dout_o[1343:256] == 1088'h87f63b881e9eebb5e4f6d9524e3b18ebe349dcbb285faeb0ca639db2b319139ae95eead7d0fd36ec7538d273df7a1a0cb98718b6727e02cc08cd0c38b19d37b14f340fff58b83cec62eed473ea622e8acbb6a89332dca0e1e20a3ab7cb893bb034158ad601a3aa83719f143d333f2ea2dfd0f46e5acb2cded6dd235fa4d877286bfcb51fe3428eb4) begin
    $display("PASS - SHAKE-256: 136 bytes input and 136 bytes output\n");
  end
  else begin
    $display("FAIL - SHAKE-256: 136 bytes input and 136 bytes output\n");
  end

  wait(din_ready_o) @(posedge clk_i) #(PERIOD);
  start_i = 1; sel_shake128_i = 0;   #(PERIOD)
  start_i = 0;   #(PERIOD)

  $display("\nTest SHAKE-256 -- 32 bytes input and 3 x 136 bytes output\n");
  wait(din_ready_o) @(posedge clk_i) #(DELAY);
    last_din_byte_i = 32;
    last_din_i = 1;
    din_valid_i = 1;
    din_i = {256'h626c6b315f643031626c6b315f643032626c6b315f643033626c6b315f643034, {(DW-256){1'b0}}};
    start_time = $time;
    #(PERIOD)
    din_valid_i = 0;    
  @(posedge clk_i) #(DELAY);
  din_valid_i = 0;
  last_din_i = 0;   



  //draw more than one block of output
  wait(dout_valid_o) time_shake_256 = ($time - start_time)/PERIOD; @(posedge clk_i) #(PERIOD); dout_ready_i <= 1;
  
  if (dout_o[1343:256] == 1088'h1138fe10aa733750ad02f6535268fde500ccfab981e42f0708f781a0324e1b8f9beedab4f1b5ed69a6ead0ad41b1f608cdb4a4ee242fa704597c33fb12db83f0161e33100d29d957b5139343bafac31c934e3824b33272f8ad211ed8bbb3b6f324906c1808debaf1fe511577f514e47ae22a3a29986b13561c3c54976fb229c08065224b1f5152b9) begin
    $display("PASS - SHAKE-256: 136 bytes input and 136 bytes first output block\n");
  end
  else begin
    $display("FAIL - SHAKE-256: 136 bytes input and 136 bytes first output block\n");
  end
  #(PERIOD); dout_ready_i <= 0; #(PERIOD);
 
  wait(dout_valid_o) @(posedge clk_i) #(PERIOD); dout_ready_i <= 1;
  if (dout_o[1343:256] == 1088'h03962bd0afba11bd1ac3ec3bb97e5bac17e6f256c52f6dafb98f969d01184fcac84872c0f61510f22df7a07ebb5e8abe656bb1c67c60848d20c02a985fcdcea32a22039dd0803c292943920b0d70a939ea638604f354589d7ab287b908a3eae92db7616c892bb10df3deb0ff6d6881aadebf9e8bc8cb1d1b9b222e0064db6a7517d6cc7cb3b2a5ab) begin
    $display("PASS - SHAKE-256: 136 bytes input and 136 bytes second output block\n");
  end
  else begin
    $display("FAIL - SHAKE-256: 136 bytes input and 136 bytes second output block\n");
  end
  #(PERIOD); dout_ready_i <= 0; #(PERIOD);

  wait(dout_valid_o) @(posedge clk_i) #(PERIOD);
  if (dout_o[1343:256] == 1088'hec20469e2983f9aad63108621be0304bffa79d04111736b5d694ec7916f00428221339e3d5ccbf2849a4e77619365ca11c916387bfdbfabe9c840e607134ac9c2b3453d82e94413d8ded23ce7d65ada4cea4d7501d484593f7d3051c2503ae9bbecbb174449121449a1ecae26477d76c481e144ae5c0a11d97b6c243780cbb8f0191d43c7300e935) begin
    $display("PASS - SHAKE-256: 136 bytes input and 136 bytes third output block\n");
  end
  else begin
    $display("FAIL - SHAKE-256: 136 bytes input and 136 bytes third output block\n");
  end

  wait(din_ready_o) @(posedge clk_i) #(PERIOD);
// //--------------SHAKE-128------------------------
  $display("\nTest SHAKE-128 -- 168 bytes input and 168 bytes output\n");
  start_i = 1; sel_shake128_i = 1;   #(PERIOD)
  start_i = 0;   #(PERIOD)

  wait(din_ready_o) @(posedge clk_i) #(DELAY);
    last_din_byte_i = 168;
    last_din_i = 1;
    din_valid_i = 1;
    din_i = {1088'h626c6b315f643031626c6b315f643032626c6b315f643033626c6b315f643034626c6b315f643035626c6b315f643036626c6b315f643037626c6b315f643038626c6b315f643039626c6b315f643130626c6b315f643131626c6b315f643132626c6b315f643133626c6b315f643134626c6b315f643135626c6b315f6431360000000000000000, {(DW-1088){1'b0}}};
    #(PERIOD)
    din_valid_i = 0;

   @(posedge clk_i) #(DELAY);
  din_valid_i = 0;
  last_din_i = 0;  

  wait(dout_valid_o) @(posedge clk_i) #(PERIOD);
  if (dout_o == 1344'h126694d388a2cb38086684cf77a33616abe3dd45b1f330bccb389796e3d86d6c28c137c017c27cd0e64a977eea0b3b33f2d25b3ac84525faf83c973374732a05406f5fac58f31d4d455a8c7c7644aeead40dc6c22ca6999871a031a5ae3374d46f8b5d858efe5ea320bfcafbe03a732121b5336ff07e7f42ac05f7f08d9176657f39a4c4c35f13b52912c6d64719a9e0598e6a35ebb3db15198b7dcb61380586e146cf771849ccdc) begin
    $display("PASS - SHAKE-128 -- 168 bytes input and 168 bytes output\n");
  end
  else begin
    $display("FAIL - SHAKE-128 -- 168 bytes input and 168 bytes output\n");
  end


  $display("\nTest SHAKE-128 -- 32 bytes input and 2 x 168 bytes output\n");
  start_i = 1; sel_shake128_i = 1;   #(PERIOD)
  start_i = 0;   #(PERIOD)

  wait(din_ready_o) @(posedge clk_i) #(DELAY);
    start_time = $time;
    last_din_byte_i = 32;
    last_din_i = 1;
    din_valid_i = 1;
    din_i = {256'h626c6b315f643031626c6b315f643032626c6b315f643033626c6b315f643034, {(DW-256){1'b0}}};
    #(PERIOD)
    din_valid_i = 0;

    @(posedge clk_i) #(DELAY);
    din_valid_i = 0;
    last_din_i = 0;  

  //draw more than one block of output
  wait(dout_valid_o) time_shake_128 = ($time - start_time)/PERIOD; @(posedge clk_i) #(PERIOD); dout_ready_i <= 1;
  if (dout_o == 1344'h0c30ef281d3d7fc4cbdb8b6861a8963b566d10b6648e8aa58cb4dcf0cf8070bdc99aca6bfacdf48810f8fc5fbd63cd3e82e2b433275b31ab04bb23676e054da8ab14110eaec5470e5228050dfb652229af38d08c05ac3ed49733d809c0bf960df181637a5469f0942447fe6c65efa214f4686d53f106c6e75bc8c32a60e8eff02dbd2a24aa9c0c96ed5f5889b3fad07125da16c5e849fd14ecdaec17dfae2395332f662e78c594cc) begin
    $display("PASS - SHAKE-128: 168 bytes input and 168 bytes first output block\n");
  end
  else begin
    $display("FAIL - SHAKE-128: 168 bytes input and 168 bytes first output block\n");
  end
  #(PERIOD); dout_ready_i <= 0; #(PERIOD);
 
  wait(dout_valid_o) @(posedge clk_i) #(PERIOD); dout_ready_i <= 1;
  if (dout_o== 1344'hb8f860da60e5f133cd8206c483b2b708224dbe1518de40028b0fbb94c446b6bcee6e20980c0d7ad98cc5117432ae9f152abce8df85583fcc30f129a3ca1d49c0813263d22ff638fe2fd2424c45547b7147865f15f0b38ffc6f2efcbf59e499276af51a862386909cc7aeea3e3259509a697d16bd7179100f8ac0e9b81e88c61b3b3a019e9ead4f71209e8b3cd189eb5801f1d655779c5946a1fcd0b5f3e0090c2c429fcdd6d0c7e0) begin
    $display("PASS - SHAKE-128: 168 bytes input and 168 bytes second output block\n");
  end
  else begin
    $display("FAIL - SHAKE-128: 168 bytes input and 168 bytes second output block\n");
  end
  #(PERIOD); dout_ready_i <= 0; #(PERIOD); 
//==============================================================================

//==============================================================================

  $display("Clock Cycles taken for each SHAKE128 round: %d", time_shake_128);
  $display("Clock Cycles taken for each SHAKE256 round: %d", time_shake_256);

  #100 $finish;
end

always #(PERIOD/2) clk_i = ~clk_i;




shake_top_fw shake (
  .clk_i             (clk_i          ),//system clock
  .rst_ni            (rst_ni         ),//system reset, active low
  .start_i           (start_i        ),//start of SHAKE process, 1 clock pulse, assert before putting input data
  .sel_shake128_i    (sel_shake128_i        ),//start of SHAKE process, 1 clock pulse, assert before putting input data
  .din_i             (din_i          ),//data input
  .din_valid_i       (din_valid_i    ),//data input valid signal, transaction happens when both din_valid_i and din_ready_o HIGH
  .last_din_i        (last_din_i     ),//last data input, also used as first data output squeeze
  .last_din_byte_i   (last_din_byte_i),//byte length of last data input, 0 to 8 for DW=64
  .dout_ready_i      (dout_ready_i   ),//signal to request output data, transaction happens when both dout_ready_i and dout_valid_o HIGH
  .din_ready_o       (din_ready_o    ),//signal showing shake module ready to receive input data, transaction happens when both din_valid_i and din_ready_o HIGH
  .dout_o            (dout_o         ),//data output
  .dout_valid_o      (dout_valid_o   ) //data output valid signal, transaction happens when both dout_ready_i and dout_valid_o HIGH
);

endmodule 
