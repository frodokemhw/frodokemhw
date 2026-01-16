/*
    Matrix Multiplication testbench
*/
`ifndef VIVADO_SIM
    `include "../common/param.v"
`endif

module matrix_arithmetic_tb();


parameter N     =    `L5_N;
parameter N_BAR  =   `L5_NBAR;


parameter ELEMENT_WIDTH         = `L5_WIDTH_Q;
parameter T                     = `T; // Number of Multipliers

parameter A_ROWS                = N;
parameter A_COLS                = N;
parameter B_ROWS                = N_BAR;
parameter B_COLS                = N;


parameter WORD_SIZE             = ELEMENT_WIDTH*T;
parameter C_ROWS                = B_ROWS;
parameter C_COLS                = A_COLS;
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
wire [`CLOG2(A_COLS/T)-1:0]             o_a_addr;

wire [WORD_SIZE-1:0]                    b_to_mem;
wire [WORD_SIZE-1:0]                    i_b;
wire [`CLOG2(B_SIZE/WORD_SIZE)-1:0]     o_b_addr;

reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      i_c_addr;
reg                                     i_c_en;
wire [WORD_SIZE-1:0]                    o_c;

wire [WORD_SIZE-1:0]                    i_e;
reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      i_e_addr;
reg                                     i_e_wen;

reg [`CLOG2(C_SIZE/WORD_SIZE)-1:0]      b_addr;
reg                                     b_wen;

wire [WORD_SIZE-1:0]                    a_to_mem;
reg [`CLOG2(A_COLS*ELEMENT_WIDTH/WORD_SIZE)-1:0]      a_addr;
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
        assign a_to_mem[k*ELEMENT_WIDTH + ELEMENT_WIDTH -1 :k*ELEMENT_WIDTH] = a[T-k-1];
    end
endgenerate

genvar m;
generate
    for (m=0; m<T; m=m+1) begin
        assign i_e[m*ELEMENT_WIDTH + ELEMENT_WIDTH -1 :m*ELEMENT_WIDTH] = e[T-m-1];
    end
endgenerate

assign i_a = o_mem_sel?     a_row_2: 
                            a_row_1;

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
//parameter TEST_N = 24;
//parameter TEST_NBAR = 8;

wire [`CLOG2(A_ROWS):0]           I_A_ROWS;              
wire [`CLOG2(A_COLS):0]           I_A_COLS;              
wire [`CLOG2(B_ROWS):0]           I_B_ROWS;              
wire [`CLOG2(B_COLS):0]           I_B_COLS;              
wire [`CLOG2(B_ROWS):0]         I_B_ROWS_DIV_T;        
wire [`CLOG2(B_COLS):0]         I_B_COLS_DIV_T;        
wire [`CLOG2(A_ROWS):0]         I_A_ROWS_DIV_T;        
wire [`CLOG2(A_COLS)-1:0]       I_A_COLS_DIV_T;        
wire [`CLOG2(A_SIZE/WORD_SIZE):0] I_A_SIZE_DIV_WORD_SIZE;
wire [`CLOG2(B_SIZE/WORD_SIZE):0] I_B_SIZE_DIV_WORD_SIZE;
wire [`CLOG2(C_SIZE/WORD_SIZE):0] I_E_SIZE_DIV_WORD_SIZE;

assign I_A_ROWS                  =  TEST_N;
assign I_A_COLS                  =  TEST_N;
assign I_B_ROWS                  =  (i_mode == 2'b01)?    TEST_NBAR: TEST_N;
assign I_B_COLS                  =  (i_mode == 2'b01)?    TEST_N: TEST_NBAR; 

assign I_A_ROWS_DIV_T            =  TEST_N/`T;
assign I_A_COLS_DIV_T            =  TEST_N/`T;
assign I_B_ROWS_DIV_T            =  I_B_ROWS/`T;
assign I_B_COLS_DIV_T            =  I_B_COLS/`T;

assign I_A_SIZE_DIV_WORD_SIZE    = (TEST_N*TEST_NBAR)/`T;
assign I_B_SIZE_DIV_WORD_SIZE    = (TEST_N*TEST_NBAR)/`T;
assign I_E_SIZE_DIV_WORD_SIZE    = (TEST_N*TEST_NBAR)/`T;


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

// assign I_B_ROWS                  =  8; //12;
// assign I_B_COLS                  =  640; //8;
// assign I_A_ROWS                  =  640; //8;
// assign I_A_COLS                  =  8; //12;
// assign I_B_ROWS_DIV_T            =  I_B_ROWS/T; //2;
// assign I_B_COLS_DIV_T            =  I_B_COLS/T; //2;
// assign I_A_ROWS_DIV_T            =  I_A_ROWS/T;
// assign I_A_COLS_DIV_T            =  I_A_COLS/T;
// assign I_A_SIZE_DIV_WORD_SIZE    =  I_A_ROWS*I_A_COLS/T; //12*8/`T;
// assign I_B_SIZE_DIV_WORD_SIZE    =  I_B_ROWS*I_B_COLS/T; //12*8/`T;
// assign I_E_SIZE_DIV_WORD_SIZE    =  I_B_ROWS*I_A_COLS/T; //12*8/`T;



integer start_time;
integer i,j;
integer f;
integer ii;
initial begin
    $dumpfile("matrix_arithmetic_tb.vcd");
    $dumpvars(0,matrix_arithmetic_tb);

    f = $fopen("output_comb.txt","w");
    // i_e <= {(WORD_SIZE){1'b0}};
    b_wen                   <=  0;
    b_addr                  <=  0;
    i_a_ready               <=  0;
    i_c_addr                <=  0;
    i_c_en                  <=  0;
    i_e_wen                 <=  0;
    i_e_addr                <=  0;
    i_start                 <=  0;
    i_rst_n                 <=  0;
    i_mode                  <=  2'b01;

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
    for (i = 0; i < B_ROWS*B_COLS/T; i = i+1) begin
        b_wen <= 1;
        b_addr <= i;
        for (j = 0; j < T; j = j+1) begin
            // b[j] <= T*i+j; 
            b[j] <= T*i+j < TEST_N*TEST_NBAR ? (T*i+j)+1: 0;
        end  
        #10;
    end

    b_wen <= 0;

    for (i = 0; i < C_ROWS*C_COLS/T; i = i+1) begin
        i_e_wen <= 1;
        i_e_addr <= i;
        for (j = 0; j < T; j = j+1) begin
             e[j] <= T*i+j < TEST_N*TEST_NBAR ? T*i+j: 0;
//            e[j] <= 0;
        end  
        #10;
    end
    i_e_wen <= 0;

    for (i = 0; i < A_COLS/T; i = i+1) begin
        a_wen <= 1;
        a_addr <= i;
        for (j = 0; j < T; j = j+1) begin
//            a[j] <= 2; 
            a[j] <= T*i+j < TEST_N*TEST_NBAR ? (T*i+j)+1: 0; 
        end  
        #10;
    end
    a_wen <= 0;

    $writememh("B.mem",  DUT.RESULT_RAM_1.chip);

    // for (i = 0; i < C_ROWS*C_COLS/T; i = i+1) begin
    //     i_c_en <= 1;
    //     i_c_addr <= i;
    //     #10;
    // end
    
    start_time <= $time;

    i_start <= 1;
    i_a_ready <=1;
    #20
    i_start <= 0;
    @(posedge o_done)
    $display("Matrix Multiplication Clock Cycles = %d", ($time-start_time)/10);
    
    
    #100
    $writememh("Mat_mul_out.mem",  DUT.RESULT_RAM_0.chip, 0, C_ROWS*C_COLS/T -1);
    #100

    for (i = 0; i < TEST_N*TEST_NBAR/T; i = i+1) begin
        i_c_en <= 1;
        i_c_addr <= i;  
        #20;
        $fwrite(f,"%x\n", o_c);
        
    end

    #100
    $fclose(f);  
    $finish;
end



always #5 i_clk = ~i_clk;


    sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(A_COLS*ELEMENT_WIDTH/WORD_SIZE)))
    A_ROW_MEM_1
        (
            .i_clk(i_clk),
            .i_ce_N(1'b0),
            .i_rdWr_N(~a_wen),
            .i_ramAddr(o_mem_en && ~o_mem_sel? o_a_addr : a_addr),
            .i_ramData(a_to_mem),
            .o_ramData(a_row_1)
        );

    sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(A_COLS*ELEMENT_WIDTH/WORD_SIZE)))
    A_ROW_MEM_2
        (
            .i_clk(i_clk),
            .i_ce_N(1'b0),
            .i_rdWr_N(~a_wen),
            .i_ramAddr(o_mem_en && o_mem_sel? o_a_addr : a_addr),
            .i_ramData(a_to_mem),
            .o_ramData(a_row_2)
        );
    
    sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(B_SIZE/WORD_SIZE)))
    B_MEM
        (
            .i_clk(i_clk),
            .i_ce_N(1'b0),
            .i_rdWr_N(~b_wen),
            .i_ramAddr(o_mem_en? o_b_addr : b_addr),
            .i_ramData(b_to_mem),
            .o_ramData(i_b)
        );





endmodule