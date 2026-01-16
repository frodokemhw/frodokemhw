/*
    FrodoKEM top testbench supports L1, T=16 but could be easily extended to other configurations
*/

`ifndef VIVADO_SIM
    `include "../common/param.v"
`endif

module frodo_kem_top_tb();

parameter SEC_LEV = 1;
parameter MODE = 0;
parameter SHAKE_CLOCK_CYCLES = 24;

parameter SHAKE_INPUT_SIZE = `L5_LEN_SEC + `L5_LEN_SEC + `L5_LEN_SALT;

reg                                         i_clk = 0; 
reg                                         i_rst_n;

reg                                         i_start;
reg   [1:0]                                 i_mode_sel;       // 0: KeyGen, 1: Encaps, 2: Decaps 
reg   [2:0]                                 i_sec_lev;        // 1, 3, 5

// key generation uniform random ports
reg   [`L5_LEN_SEC-1:0]                     i_useed_s;
reg   [`L5_LEN_SE-1:0]                      i_useed_se;
reg   [`L5_LEN_A-1:0]                       i_useed_z;

//encapsulation uniform random ports
reg   [`L5_LEN_SEC-1:0]                     i_useed_u;
reg   [`L5_LEN_SALT-1:0]                    i_salt;

//decapsulation ports
reg [`L5_LEN_SEC-1:0]                       i_pkh;
reg [`L5_LEN_A-1:0]                         i_seed_a;

    // output ports
wire [`L5_LEN_A-1:0]                        o_seed_a;
wire [`L5_LEN_SEC-1:0]                      o_pkh;

//key generation ports
wire  [`WORD_SIZE-1:0]                      o_c1;   
reg   [`CLOG2(`L5_B_MAT_DEPTH)-1:0]         i_c1_addr = 0;
reg                                         i_c1_en = 0;

wire  [`WORD_SIZE-1:0]                      o_s;
reg   [`CLOG2(`L5_SAMP_MAT_DEPTH)-1:0]      i_s_addr;
reg                                         i_s_en;

//encapsulation and decapsulation ports
wire  [`L5_NBAR*`L5_WIDTH_Q-1:0]            i_b;   
wire   [`CLOG2(`L5_N)-1:0]                  o_b_addr;
wire                                        o_b_en;

wire  [`WORD_SIZE-1:0]                      i_bprime;   
wire   [`CLOG2(`L5_N)-1:0]                  o_bprime_addr;
wire                                        o_bprime_en;

wire  [`L5_WIDTH_Q*`L5_NBAR-1:0]            i_s_mat;   
wire  [`CLOG2(`L5_N)-1:0]                   o_s_mat_addr;
wire                                        o_s_mat_en;

wire   [127:0]                              i_c;   
wire   [`CLOG2(8)-1:0]                      o_c_addr;
wire                                        o_c_en;

reg                                         test_i_prng_valid;
wire  [`SHAKE128_OUTPUT_SIZE-1:0]           test_i_prng_in;
wire  [`SHAKE128_OUTPUT_SIZE-1:0]           test_i_prng_in_a;
wire  [10:0]                                test_o_prng_addr;
wire                                        test_o_prng_en;
wire [14:0]                                 test_o_prng_addr_a;
wire                                        test_o_sel_mem_sa;
wire [1:0]                                  test_o_prng_mode;

wire                                        o_done;

reg                                         shake_out_valid_single_block;
wire                                        i_shake_out_valid;
wire [`SHAKE128_OUTPUT_SIZE-1:0]            i_shake_out;
wire [SHAKE_INPUT_SIZE-1:0]                 o_shake_in;
wire                                        o_shake_in_valid;
wire [15:0]                                 o_shake_in_size;
wire [31:0]                                 o_shake_out_size;

reg                                         i_shake_in_ready;
wire                                        o_shake_out_ready;
wire                                        o_shake_in_last_block;

frodo_kem_top 
DUT
    (
        .i_clk                  (i_clk                  ),
        .i_rst_n                (i_rst_n                ),
        .i_start                (i_start                ),
        .i_mode_sel             (i_mode_sel             ),      
        .i_sec_lev              (i_sec_lev              ),   

        .i_seed_a               (i_seed_a                 ),
        .i_salt                 (i_salt                 ),
        .i_useed_s              (i_useed_s              ),
        .i_useed_se             (i_useed_se             ),
        .i_useed_z              (i_useed_z              ),

        .i_useed_u              (i_useed_u              ),
        .o_seed_a               (o_seed_a               ),
        
        .i_pkh                  (i_pkh                  ), 
        
        .o_pkh                  (o_pkh                  ), 

        .o_c1                   (o_c1                   ),
        .i_c1_addr              (i_c1_addr              ),
        .i_c1_en                (0                      ),

        .o_s                    (o_s                    ),
        .i_s_addr               (i_s_addr               ),
        .i_s_en                 (0                      ),
        .i_b_en                 (0                      ),

        // encap        
        .i_b                    (i_b                    ),
        .o_b_addr               (o_b_addr               ),
        .o_b_en                 (o_b_en                 ),

        // decap        
        .i_bprime               (i_bprime               ),
        .o_bprime_addr          (o_bprime_addr          ),
        .o_bprime_en            (o_bprime_en            ),

        .i_s_mat                (i_s_mat                ),
        .o_s_mat_addr           (o_s_mat_addr           ),
        .o_s_mat_en             (o_s_mat_en             ),

        .i_c                    (i_c                    ),
        .o_c_addr               (o_c_addr               ),
        .o_c_en                 (o_c_en                 ),

        .test_o_prng_addr       (test_o_prng_addr       ),
        .test_o_prng_addr_a     (test_o_prng_addr_a     ),
        .test_o_prng_en         (test_o_prng_en         ),
        .test_o_sel_mem_sa      (test_o_sel_mem_sa      ),
        .test_o_prng_mode       (test_o_prng_mode       ),

        .i_shake_out            (test_o_sel_mem_sa? test_i_prng_in_a :test_i_prng_in),
        .i_shake_out_valid      (i_shake_out_valid      ),
        .o_shake_in_valid       (o_shake_in_valid       ),
        .o_shake_in             (o_shake_in             ),
        .o_shake_in_size        (o_shake_in_size        ),
        .o_shake_out_size       (o_shake_out_size       ),
        .i_shake_in_ready       (i_shake_in_ready       ),
        .o_shake_out_ready      (o_shake_out_ready      ),
        .o_shake_in_last_block  (o_shake_in_last_block  ),


        .i_aes_variant          (0                      ),
        .i_aes_out_valid        (0                      ),
        .i_aes_in_ready         (0                      ),

        .o_done                 (o_done                 )
    );

parameter C_ROWS = `L1_N;
parameter C_COLS = `L1_NBAR;


integer start_time, a_gen_time;
integer i,j;
integer f;
initial begin
    $dumpfile("frodo_kem_top_tb.vcd");
    $dumpvars(0,frodo_kem_top_tb);

    $display("SEC_LEVEL", SEC_LEV);
    $display("MODE", MODE);
    $display("T", `T);

    i_rst_n <= 0;


    i_mode_sel <= MODE;
    i_sec_lev <= SEC_LEV;

    if (MODE == 0) begin
        i_useed_se  <= {{256'h2FD81A25CCB148032DCD739936737F2DB505D7CFAD1B497499323C8686325E47}, {(`L5_LEN_SE - 256){1'b0}}};
        i_useed_z   <= {128'h92f267aafa3f87ca60d01cb54f29202a, {(`L5_LEN_A - 128){1'b0}}};
        i_salt      <= 0;
        i_useed_u   <= 0;
        i_pkh       <= 0;
        i_seed_a    <= 0;
        i_useed_s   <= 0;
    end
    else if (MODE == 1) begin
        i_useed_se   <= 0;
        i_useed_z    <= 0;
        i_salt      <= {256'hD639002198172A7B1942ECA8F6C001BA26202BEE59AC275484EA767D41D8D357, {(`L5_LEN_SALT - 256){1'b0}}};
        i_useed_u   <= {{(`L5_LEN_SEC - 128){1'b0}},128'hEB4A7C66EF4EBA2DDB38C88D8BC706B1};
        i_pkh       <= 0;
        i_seed_a    <= {128'hA3B0D78801479DE0F67B9CD5BCCA3D43, {(`L5_LEN_A - 128){1'b0}}};
        i_useed_s   <= 0;
    end
    else if (MODE == 2) begin
        i_useed_se  <= 0;
        i_useed_z   <= 0;
        i_salt      <= {256'hD639002198172A7B1942ECA8F6C001BA26202BEE59AC275484EA767D41D8D357, {(`L5_LEN_SALT - 256){1'b0}}};
        i_useed_u   <= 0;
        i_pkh       <= {128'h13CA7D97B3852EDB48E21B7C5088FBAD, {(`L5_LEN_SEC - 128){1'b0}}};
        i_seed_a    <= {128'hA3B0D78801479DE0F67B9CD5BCCA3D43, {(`L5_LEN_A - 128){1'b0}}};
        i_useed_s   <= {128'h7C9935A0B07694AA0C6D10E4DB6B1ADD, {(`L5_LEN_SEC - 128){1'b0}}};
    end 


    i_c1_en <= 0;
    i_s_en <= 0;
    i_c1_addr <= 0;
    i_s_addr <= 0;
    i_start <= 0;
    i_shake_in_ready <= 0;
    
    #100
    i_rst_n <= 1;
    i_start <= 1;
    i_shake_in_ready <= 1;


    
    start_time <= $time;

    i_start <= 1;
    #10
    i_start <= 0;



    @(posedge o_done)
    #100
    $display("FrodoKEM Clock Cycles = %d", ($time-start_time)/10);
    $writememh("S.out",  DUT.SAMP_S.chip, 0, C_ROWS*C_COLS/`T -1);
    $writememh("E.out",  DUT.SAMP_E.chip, 0, C_ROWS*C_COLS/`T -1);
    $writememh("EPP.out",  DUT.SAMP_E_PP.chip, 0, `L5_NBAR -1);
    $writememh("A_ROW_1.out",  DUT.A_ROW_MEM_1.chip, 0, `L1_N/`T -1);
    $writememh("A_ROW_2.out",  DUT.A_ROW_MEM_2.chip, 0, `L1_N/`T -1);
    $writememh("B.out",  DUT.MAT_MUL.RESULT_RAM_0.chip, 0, `L1_N*`L1_NBAR/`T -1);
    $writememh("Bprime.out",  DUT.Bprime_MEM.chip, 0, `L1_N*`L1_NBAR/`T -1);
//    $writememh("A.out",  DUT.A_FULL_TEST.chip, 0, `L1_N*`L1_N/`T -1);
    #100



    #100
    $finish;
end




always #5 i_clk = ~i_clk;


`ifndef VIVADO_SIM
    parameter FILE_SHAKE128_OUTPUT = (SEC_LEV == 1 && (MODE == 1 || MODE == 2)) ? "./mem_files/shake/EN_S128_L1.mem": (SEC_LEV == 1 && (MODE == 0)) ? "./mem_files/shake/KG_S128_L1.mem": 0;
`endif
`ifdef VIVADO_SIM
    parameter FILE_SHAKE128_OUTPUT = (SEC_LEV == 1 && (MODE == 1 || MODE == 2)) ? "EN_S128_L1.mem": (SEC_LEV == 1 && (MODE == 0)) ? "KG_S128_L1.mem": 0;
`endif

sram #(
        .FILE(
            FILE_SHAKE128_OUTPUT
            ),
        .WIDTH(`SHAKE128_OUTPUT_SIZE), 
        .ADDR_WIDTH(7)
        )
SHAKE_OUTPUT_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(test_o_prng_en? test_o_prng_addr : 0),
        .i_ramData(0),
        .o_ramData(test_i_prng_in)
    );

`ifndef VIVADO_SIM
    parameter FILE_SHAKE128_OUTPUT_A = "./mem_files/shake/SHAKE128_OUTPUT_A.mem";
`endif
`ifdef VIVADO_SIM
    parameter FILE_SHAKE128_OUTPUT_A = "SHAKE128_OUTPUT_A.mem";
`endif

sram #(
        .FILE(
            FILE_SHAKE128_OUTPUT_A
            ),
        .WIDTH(`SHAKE128_OUTPUT_SIZE), 
        .ADDR_WIDTH(15)
        )
SHAKE_OUTPUT_MEM_A
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(test_o_prng_en? test_o_prng_addr_a : 0),
        .i_ramData(0),
        .o_ramData(test_i_prng_in_a)
    );

`ifndef VIVADO_SIM
    parameter FILE_ENCAP_B_L1 = "./mem_files/shake/ENCAP_B_L1.mem";
`endif
`ifdef VIVADO_SIM
    parameter FILE_ENCAP_B_L1 = "ENCAP_B_L1.mem";
`endif

sram #(
        .FILE(
            FILE_ENCAP_B_L1
            ),
        .WIDTH(`L5_NBAR*`L5_WIDTH_Q), 
        .ADDR_WIDTH(`CLOG2(`L5_N))
        
        )
ENCAP_B
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_b_en? o_b_addr : 0),
        .i_ramData(0),
        .o_ramData(i_b)
    );

`ifndef VIVADO_SIM
    parameter FILE_DECAP_BPRIME_L1 = "./mem_files/shake/DECAP_BPRIME_L1.mem";
`endif
`ifdef VIVADO_SIM
    parameter FILE_DECAP_BPRIME_L1 = "DECAP_BPRIME_L1.mem";
`endif

sram #(
        .FILE(
            FILE_DECAP_BPRIME_L1
            ),
        .WIDTH(`WORD_SIZE), 
        .ADDR_WIDTH(`CLOG2(`L5_N*`L5_NBAR/`T))
        
        )
DECAP_BPRIME
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_bprime_en? o_bprime_addr : 0),
        .i_ramData(0),
        .o_ramData(i_bprime)
    );

`ifndef VIVADO_SIM
    parameter FILE_DECAP_S_L1 = "./mem_files/shake/DECAP_S_L1.mem";
`endif
`ifdef VIVADO_SIM
    parameter FILE_DECAP_S_L1 = "DECAP_S_L1.mem";
`endif

sram #(
        .FILE(
            FILE_DECAP_S_L1 
            ),
        .WIDTH(`WORD_SIZE), 
        .ADDR_WIDTH(`CLOG2(`L5_N))
        
        )
DECAP_S
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_s_mat_en? o_s_mat_addr : 0),
        .i_ramData(0),
        .o_ramData(i_s_mat)
    );

`ifndef VIVADO_SIM
    parameter FILE_DECAP_C_L1 = "./mem_files/shake/DECAP_C_L1.mem";
`endif
`ifdef VIVADO_SIM
    parameter FILE_DECAP_C_L1 = "DECAP_C_L1.mem";
`endif

sram #(
        .FILE(FILE_DECAP_C_L1),
        .WIDTH(`WORD_SIZE), 
        .ADDR_WIDTH(`CLOG2(8))
        
        )
DECAP_C
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(1'b1),
        .i_ramAddr(o_c_en? o_c_addr : 0),
        .i_ramData(0),
        .o_ramData(i_c)
    );



reg [5:0] cycle_count;
reg count_en;

always@(posedge i_clk)
begin
    if (i_rst_n == 0 || stop_shake) begin
        cycle_count <= 0;
    end
    else begin
        if (count_en) begin
            if (cycle_count == SHAKE_CLOCK_CYCLES) begin
                cycle_count <= 0;
            end
            else begin
                cycle_count <= cycle_count + 1;
            end
        end
    end

    if (o_shake_in_valid) begin
        count_en <= 1;
    end
    else if (stop_shake) begin
        count_en <= 0;
    end

    if (i_rst_n == 0) begin
        shake_out_valid_single_block <= 0;
    end
    if (cycle_count == SHAKE_CLOCK_CYCLES) begin
        shake_out_valid_single_block <= 1;
    end
    else if (o_shake_out_ready || stop_shake) begin
        shake_out_valid_single_block <= 0;
    end
end

assign i_shake_out_valid = test_o_prng_mode != 0? 1: shake_out_valid_single_block;

wire [31:0] shake_output_size;
assign shake_output_size = (SEC_LEV == 0 || test_o_sel_mem_sa)? `SHAKE128_OUTPUT_SIZE : `SHAKE256_OUTPUT_SIZE;

reg [31:0] shake_out_size_counter;
reg [31:0] shake_out_size_reg;
reg stop_shake;
//output counter
always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        shake_out_size_reg <= 0;
        shake_out_size_counter <= 0;
        stop_shake <= 1;
    end
    else if (o_shake_in_valid) begin
        shake_out_size_reg <= o_shake_out_size;
        shake_out_size_counter <= 0;
        stop_shake <= 0;
    end
    else if (o_shake_out_ready) begin
        shake_out_size_counter <= shake_out_size_counter + shake_output_size;
        stop_shake <= 0;
    end
    else if (shake_out_size_counter >= shake_out_size_reg) begin
        shake_out_size_counter <= 0;
        stop_shake <= 1;
    end
end

endmodule