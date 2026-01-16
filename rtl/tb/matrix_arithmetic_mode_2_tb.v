/*
    Matrix Multiplication testbench
*/

`ifndef VIVADO_SIM
    `include "../common/param.v"
`endif

module matrix_arithmetic_mode_2_tb();


parameter N     =    `L5_N;
parameter N_BAR  =   `L5_NBAR;


parameter ELEMENT_WIDTH         = `L5_WIDTH_Q;
parameter T                     = `T; // Number of Multipliers

parameter A_ROWS                = N;
parameter A_COLS                = N;
parameter B_ROWS                = T;
parameter B_COLS                = N;


parameter WORD_SIZE             = ELEMENT_WIDTH*T;
parameter C_ROWS                = `L5_N;
parameter C_COLS                = T;
parameter A_SIZE                = A_ROWS*A_COLS*ELEMENT_WIDTH;
parameter B_SIZE                = B_ROWS*B_COLS*ELEMENT_WIDTH;
parameter C_SIZE                = C_ROWS*C_COLS*ELEMENT_WIDTH;


reg                                     i_clk =0;
reg                                     i_rst_n;
reg                                     i_start;

reg                                     i_a_ready;

wire [WORD_SIZE-1:0]                    a_full_mem;
wire [WORD_SIZE-1:0]                    a_row_1;
wire [WORD_SIZE-1:0]                    a_row_2;

wire [WORD_SIZE-1:0]                    i_a;
wire [`CLOG2(A_COLS)-1:0]               o_a_addr;

wire [T*ELEMENT_WIDTH-1:0]              b_to_mem;
wire [WORD_SIZE-1:0]                    i_b;
wire [`CLOG2(B_SIZE/WORD_SIZE)-1:0]     o_b_addr;

reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      i_c_addr;
reg                                     i_c_en;
wire [WORD_SIZE-1:0]                    o_c;

// wire [WORD_SIZE-1:0]                    i_e;
reg [WORD_SIZE-1:0]                     i_e;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      i_e_addr;
reg                                     i_e_wen;

reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      b_addr;
reg                                     b_wen;

wire [8*ELEMENT_WIDTH-1:0]                    a_to_mem;
reg [`CLOG2(A_COLS*T*ELEMENT_WIDTH/WORD_SIZE)-1:0]      a_addr;
reg                                     a_wen;

wire                                    o_mem_sel;
wire                                    o_done;

reg  [`CLOG2(A_ROWS):0]                 i_a_rows;
reg  [`CLOG2(A_ROWS):0]                 i_b_rows;
reg  [`CLOG2(B_ROWS/T):0]               i_b_rows_div_t;
reg  [`CLOG2(B_COLS/T):0]               i_b_cols_div_t;
reg  [`CLOG2(A_ROWS/T):0]               i_a_rows_div_t;
reg  [`CLOG2(A_COLS/T)-1:0]             i_a_cols_div_t;
reg  [`CLOG2(A_SIZE/WORD_SIZE):0]       i_a_size_div_word_size;
reg  [`CLOG2(B_SIZE/WORD_SIZE):0]       i_b_size_div_word_size;
reg  [`CLOG2(C_SIZE/WORD_SIZE):0]       i_e_size_div_word_size;

reg [1:0]                                    i_mode;

reg [ELEMENT_WIDTH-1:0] b [0:T-1];
reg [ELEMENT_WIDTH-1:0] e [0:T-1];
reg [ELEMENT_WIDTH-1:0] a [0:T-1];

wire [2:0] i_sec_lev;


genvar k;
generate
    for (k=0; k<T; k=k+1) begin
        assign b_to_mem[k*ELEMENT_WIDTH + ELEMENT_WIDTH -1 :k*ELEMENT_WIDTH] = b[T-k-1];
    end
endgenerate

genvar kk;
generate
    for (kk=0; kk<8; kk=kk+1) begin
        assign a_to_mem[kk*ELEMENT_WIDTH + ELEMENT_WIDTH -1 :kk*ELEMENT_WIDTH] = a[8-kk-1];
    end
endgenerate

genvar m;
generate
    for (m=0; m<8; m=m+1) begin
        assign e_before_append[m*ELEMENT_WIDTH + ELEMENT_WIDTH -1 :m*ELEMENT_WIDTH] = e[8-m-1];
    end
endgenerate

wire [8*ELEMENT_WIDTH-1:0] e_before_append;
wire [WORD_SIZE-1:0] e_append;
assign e_append = {e_before_append, {(WORD_SIZE-8*ELEMENT_WIDTH){1'b0}}};
// assign i_e = e_append;

assign i_a = {a_full_mem[8*ELEMENT_WIDTH-1:0], {(WORD_SIZE-8*ELEMENT_WIDTH){1'b0}}};

matrix_arithmetic #(
    .A_ROWS(A_ROWS), 
    .A_COLS(A_COLS),
    .B_ROWS(B_ROWS),
    .B_COLS(B_COLS),
    .ELEMENT_WIDTH(ELEMENT_WIDTH),
    .T(T)
    )
DUT
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_start(i_start),

        .i_mode(i_mode),
        .i_sec_lev(i_sec_lev),

        .i_a_rows(i_a_rows),
        .i_b_rows(i_b_rows),
        .i_b_rows_div_t(i_b_rows_div_t),
        .i_b_cols_div_t(i_b_cols_div_t),
        .i_a_rows_div_t(i_a_rows_div_t),
        .i_a_cols_div_t(i_a_cols_div_t),
        .i_a_size_div_word_size(i_a_size_div_word_size),   
        .i_b_size_div_word_size(i_b_size_div_word_size),   
        .i_e_size_div_word_size(i_e_size_div_word_size),   
        
        .i_a_ready(i_a_ready),

        .i_a(i_a),
        .o_a_addr(o_a_addr),
        
        .i_b(i_b),
        .o_b_addr(o_b_addr),
        
        .i_e(i_e),
        .i_e_addr(i_e_addr),
        .i_e_wen(i_e_wen),

        .i_c_addr(i_c_addr),
        .i_c_en(i_c_en),
        .o_c(o_c),
        
        .o_mem_sel(o_mem_sel),

        .o_mem_en(o_mem_en),
        .o_done(o_done)
    );

parameter TEST_N = `L1_N;
parameter TEST_NBAR = `L1_NBAR;
assign i_sec_lev = 1;
// parameter TEST_N = 24;
// parameter TEST_NBAR = 8;

wire [`CLOG2(A_ROWS):0]           I_A_ROWS;              
wire [`CLOG2(A_COLS):0]           I_A_COLS;              
wire [`CLOG2(B_ROWS):0]           I_B_ROWS;              
wire [`CLOG2(B_COLS):0]           I_B_COLS;              
// wire [`CLOG2(B_ROWS):0]           I_B_ROWS;              
wire [`CLOG2(B_ROWS):0]         I_B_ROWS_DIV_T;        
wire [`CLOG2(B_COLS):0]         I_B_COLS_DIV_T;        
wire [`CLOG2(A_ROWS):0]         I_A_ROWS_DIV_T;        
wire [`CLOG2(A_COLS)-1:0]       I_A_COLS_DIV_T;        
wire [`CLOG2(A_SIZE/WORD_SIZE):0] I_A_SIZE_DIV_WORD_SIZE;
wire [`CLOG2(B_SIZE/WORD_SIZE):0] I_B_SIZE_DIV_WORD_SIZE;
wire [`CLOG2(C_SIZE/WORD_SIZE):0] I_E_SIZE_DIV_WORD_SIZE;

// assign I_A_ROWS                  =  TEST_N;
// assign I_B_ROWS                  =  i_mode == 1?    TEST_NBAR: 
//                                     i_mode == 2?    TEST_NBAR: 
//                                                     TEST_N;
// assign I_A_ROWS_DIV_T            =  TEST_N/`T;

// assign I_A_COLS_DIV_T            =  i_mode == 2?    TEST_NBAR/`T:
//                                                     TEST_N/`T;
// assign I_B_SIZE_DIV_WORD_SIZE    = i_mode == 2? TEST_NBAR :(TEST_N*TEST_NBAR)/`T;


// assign I_B_ROWS                  =  2*4; //12;
// assign I_B_COLS                  =  2*6; //8;
// assign I_A_ROWS                  =  2*6; //8;
// assign I_A_COLS                  =  2*4; //12;
// assign I_B_ROWS_DIV_T            =  2*2; //2;
// assign I_A_ROWS_DIV_T            =  2*2;
// assign I_A_COLS_DIV_T            =  2*3;
// assign I_A_SIZE_DIV_WORD_SIZE    =  2*2*6*4/`T; //12*8/`T;
// assign I_B_SIZE_DIV_WORD_SIZE    =  2*2*4*6/`T; //12*8/`T;
// assign I_E_SIZE_DIV_WORD_SIZE    =  2*2*4*4/`T; //12*8/`T;

assign I_B_ROWS                  =  8; 
assign I_B_COLS                  =  640;
assign I_A_ROWS                  =  640;
assign I_A_COLS                  =  8; 
// assign I_B_ROWS_DIV_T            =  I_B_ROWS/T; //2;
assign I_B_ROWS_DIV_T            =  1; //2;
assign I_B_COLS_DIV_T            =  I_B_COLS/T; //2;
assign I_A_ROWS_DIV_T            =  I_A_ROWS/T;
// assign I_A_COLS_DIV_T            =  I_A_COLS/T;
assign I_A_COLS_DIV_T            =  1;
assign I_A_SIZE_DIV_WORD_SIZE    =  I_A_ROWS*I_A_COLS/T; //12*8/`T;
assign I_B_SIZE_DIV_WORD_SIZE    =  I_B_ROWS*I_B_COLS/T; //12*8/`T;
assign I_E_SIZE_DIV_WORD_SIZE    =  I_B_ROWS*I_A_COLS/8; //12*8/`T;



integer start_time;
integer i,j;
integer f;
integer ii;
initial begin
    $dumpfile("matrix_arithmetic_mode_2_tb.vcd");
    $dumpvars(0,matrix_arithmetic_mode_2_tb);

    f = $fopen("output_comb.txt","w");
    // i_e <= {(WORD_SIZE){1'b0}};
    b_wen                   <=  0;
    a_wen                   <=  0;
    b_addr                  <=  0;
    i_a_ready               <=  0;
    i_c_addr                <=  0;
    i_c_en                  <=  0;
    i_e_wen                 <=  0;
    i_e_addr                <=  0;
    i_start                 <=  0;
    i_rst_n                 <=  0;
    i_mode                  <=  2;

    #10 

    i_a_rows                <= I_A_ROWS;
    i_b_rows                <= I_B_ROWS;
    i_a_rows_div_t          <= I_A_ROWS_DIV_T;
    i_b_rows_div_t          <= I_B_ROWS_DIV_T;
    i_a_cols_div_t          <= I_A_COLS_DIV_T;
    i_b_cols_div_t          <= I_B_COLS_DIV_T;
    i_a_size_div_word_size  <= I_A_SIZE_DIV_WORD_SIZE;
    i_b_size_div_word_size  <= I_B_SIZE_DIV_WORD_SIZE;
    i_e_size_div_word_size  <= I_E_SIZE_DIV_WORD_SIZE;

    #100
     
    i_rst_n <= 1;
    // for (i = 0; i < B_ROWS*B_COLS/T; i = i+1) begin
    //     b_wen <= 1;
    //     b_addr <= i;
    //     for (j = 0; j < T; j = j+1) begin
    //         // b[j] <= T*i+j; 
    //         b[j] <= T*i+j < 8*I_B_COLS ? T*i+j+1: 0;
    //     end  
    //     #10;
    // end

    b_wen <= 0;

    // for (i = 0; i < B_ROWS*B_COLS/T; i = i+1) begin
    //     a_wen <= 1;
    //     b_addr <= i;
    //     for (j = 0; j < T; j = j+1) begin
    //         // b[j] <= T*i+j; 
    //         a[j] <= 8*i+j < I_A_ROWS*I_A_COLS ? 8*i+j: 0;
    //     end  
    //     #10;
    // end

    a_wen <= 0;


    // for (i = 0; i < 8; i = i+1) begin
    //     i_e_wen <= 1;
    //     i_e_addr <= i;
    //     for (j = 0; j < 8; j = j+1) begin
    //         e[j] <= 8*i+j < I_B_ROWS*I_A_COLS ? 8*i+j: 0;
    //         // e[j] <= 0;
    //     end  
    //     #10;
    // end
    i_e <= {128'h7fff7fff7ffc7ffd7ffe7ffc7ffb0002, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 0; i_e_wen <= 1; #10
    i_e <= {128'h00037ffc00067ffb7fff7ffb7fff7fff, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 1; i_e_wen <= 1; #10
    i_e <= {128'h0001000300027ffa7fff000400007ffb, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 2; i_e_wen <= 1; #10
    i_e <= {128'h000500020001000300027ffe00030004, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 3; i_e_wen <= 1; #10
    i_e <= {128'h00017ffe7ffd7ffd7ffd00027ffe7ffc, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 4; i_e_wen <= 1; #10
    i_e <= {128'h0000000100017fff000400027ffd0001, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 5; i_e_wen <= 1; #10
    i_e <= {128'h000400067ffe00007fff000000030002, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 6; i_e_wen <= 1; #10
    i_e <= {128'h7fff0000000100040001000300007ffb, {(WORD_SIZE-8*16){1'b0}}}; i_e_addr <= 7; i_e_wen <= 1; #10
    i_e_wen <= 0;


    $writememh("B.mem",  DUT.B_MEM.chip);
    $writememh("A.mem",  DUT.A_MEM.chip);

    // for (i = 0; i < C_ROWS*C_COLS/T; i = i+1) begin
    //     i_c_en <= 1;
    //     i_c_addr <= i;
    //     #10;
    // end
    
    start_time <= $time;

    i_start <= 1;
    i_a_ready <=0;
    #10
    i_start <= 0;
    @(posedge o_done)
    $display("Matrix Multiplication Clock Cycles = %d", ($time-start_time)/10);
    
    if (i_mode == 2)
        $writememh("Mat_mul_out_csa.mem",  DUT.RESULT_RAM_0.chip, 0, I_E_SIZE_DIV_WORD_SIZE-1);
    else
        $writememh("Mat_mul_out_csa.mem",  DUT.RESULT_RAM_0.chip, 0, C_ROWS*C_COLS/T -1);
    
    #100

    for (ii = 0; ii < I_B_ROWS*I_A_COLS/T; ii = ii+1) begin
        i_c_en <= 1;
        i_c_addr <= i_c_addr + 1;  
        #10;
        $fwrite(f,"%x\n", o_c);
        
    end

    #100
    $fclose(f);  
    $finish;
end



always #5 i_clk = ~i_clk;


sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(B_SIZE/WORD_SIZE)), .FILE("./mem_files/shake/ENCAP_SPRIME_L1.mem"))
B_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~b_wen),
        .i_ramAddr(o_mem_en? o_b_addr : b_addr),
        .i_ramData(b_to_mem),
        .o_ramData(i_b)
    );

sram #(.WIDTH(8*ELEMENT_WIDTH), .ADDR_WIDTH(`CLOG2(A_COLS)), .FILE("./mem_files/shake/ENCAP_B_L1.mem"))
A_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~a_wen),
        .i_ramAddr(o_mem_en? o_a_addr : b_addr),
        .i_ramData(a_to_mem),
        .o_ramData(a_full_mem)
    );

endmodule