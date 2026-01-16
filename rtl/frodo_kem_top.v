/**
FrodoKEM Top Module to Perform KeyGen, Encapsulation and Decapsulation
**/

`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif

module frodo_kem_top
#(
    parameter SHAKE_INPUT_SIZE = `L5_LEN_SEC + `L5_LEN_SEC + `L5_LEN_SALT
)
(
    input                                               i_clk,
    input                                               i_rst_n,

    input                                               i_start,
    
    input   [1:0]                                       i_mode_sel,         // 0: KeyGen, 1: Encaps, 2: Decaps 
    input   [2:0]                                       i_sec_lev,          // 1, 3, 5

    // keygen uniform random inputs
    input   [`L5_LEN_SE-1:0]                            i_useed_se,
    input   [`L5_LEN_A-1:0]                             i_useed_z,

    // encap uniform random inputs
    input   [`L5_LEN_SEC-1:0]                           i_useed_u,
    input   [`L5_LEN_SALT-1:0]                          i_salt,

    // decap
    input   [`L5_LEN_SEC-1:0]                           i_useed_s,
    input   [`L5_LEN_SEC-1:0]                           i_pkh,
    
    // keygen outputs
    output [`L5_LEN_A-1:0]                              o_seed_a,   //public kee
    output [`L5_LEN_SEC-1:0]                            o_pkh,

    output [`WORD_SIZE-1:0]                             o_s,
    input [`CLOG2(`L5_N*`L5_NBAR/`T)-1:0]               i_s_addr,
    input                                               i_s_en,

    output [`WORD_SIZE-1:0]                             o_b,
    input [`CLOG2(`L5_N*`L5_NBAR/`T)-1:0]               i_b_addr,
    input                                               i_b_en,




    // encap and decap inputs
    input  [`L5_NBAR*`L5_WIDTH_Q-1:0]                   i_b,
    output [`CLOG2(`L5_N)-1:0]                          o_b_addr,
    output                                              o_b_en,
    input   [`L5_LEN_A-1:0]                             i_seed_a,


    // output  [`WORD_SIZE-1:0]                            o_s,
    // input   [`CLOG2(`L5_SAMP_MAT_DEPTH)-1:0]            i_s_addr,
    // input                                               i_s_en,

    // encap outputs
    output  [`WORD_SIZE-1:0]                            o_c1,
    input   [`CLOG2(`L5_B_MAT_DEPTH)-1:0]               i_c1_addr,
    input                                               i_c1_en,

    output [`L5_LEN_SEC-1:0]                            o_ss,

    

    input  [`WORD_SIZE-1:0]                             i_bprime,
    output [`CLOG2(`L5_N*`L5_NBAR/`T)-1:0]              o_bprime_addr,
    output                                              o_bprime_en,

    input  [`L5_WIDTH_Q*`L5_NBAR-1:0]                   i_s_mat,
    output [`CLOG2(`L5_N)-1:0]             o_s_mat_addr,
    output                                              o_s_mat_en,

    input  [127:0]                                      i_c,
    output [`CLOG2(8)-1:0]                              o_c_addr,
    output                                              o_c_en,

    //shake ports
    input                                               i_shake_out_valid,
    input  [`SHAKE128_OUTPUT_SIZE-1:0]                  i_shake_out,
    output [SHAKE_INPUT_SIZE-1:0]                       o_shake_in,
    output                                              o_shake_in_valid,
    output reg [15:0]                                   o_shake_in_size,    //bits
    output reg [31:0]                                   o_shake_out_size,   //bits
    output                                              o_shake_out_ready,    
    input                                               i_shake_in_ready,  
    output reg                                          o_shake_in_last_block,  

    //aes ports
    input                                               i_aes_variant,
    output  reg                                         o_aes_out_ready,
    input                                               i_aes_out_valid,
    input   [127:0]                                     i_aes_out,
    output   [`L5_LEN_A-1:0]                            o_aes_key, 
    output  [127:0]                                     o_aes_in, 
    output  reg                                         o_aes_in_valid, 
    input                                               i_aes_in_ready,


    
/*test inputs ports for loading data from memory to get data from PRNG this 
    is not part of the actual design and should be removed when integrating with the actual design
*/
//=======================================================
    //input from shake128
//     input                                               test_i_prng_valid,
//     input  [`SHAKE128_OUTPUT_SIZE-1:0]                  test_i_prng_in,
    output reg [1:0]                                    test_o_prng_mode, //= 0 for single input block, 1 for pkh, and 2 for ss gen
    output reg [10:0]                                   test_o_prng_addr,
    output reg [14:0]                                   test_o_prng_addr_a,
    output reg                                          test_o_prng_en,
    output reg                                          test_o_sel_mem_sa,
//=======================================================


    output  reg                                         o_done

);


parameter SHAKE128_OUTPUT_SIZE  = `SHAKE128_OUTPUT_SIZE;
parameter SHAKE256_OUTPUT_SIZE  = `SHAKE256_OUTPUT_SIZE;
parameter WORD_SIZE             = `WORD_SIZE;
parameter T                     = `T;

// parameter T_SHAKE128_OUTPUT_SIZE = SHAKE128_OUTPUT_SIZE + WORD_SIZE - SHAKE128_OUTPUT_SIZE%WORD_SIZE;
// parameter T_EXTRA_BITS = WORD_SIZE - SHAKE128_OUTPUT_SIZE%WORD_SIZE;
// parameter T_EXTRA_BITS = SHAKE128_OUTPUT_SIZE%WORD_SIZE;
// parameter T_EXTRA_BITS = T == 32? 448 :SHAKE128_OUTPUT_SIZE%WORD_SIZE;
parameter T_EXTRA_BITS = WORD_SIZE;
parameter T_SHAKE128_OUTPUT_SIZE = SHAKE128_OUTPUT_SIZE + T_EXTRA_BITS;

parameter L1_N          = `L1_N;
parameter L1_NBAR       = `L1_NBAR;
parameter L3_N          = `L3_N;
parameter L3_NBAR       = `L3_NBAR;
parameter L5_N          = `L5_N;
parameter L5_NBAR       = `L5_NBAR;
parameter L5_WIDTH_Q    = `L5_WIDTH_Q;

// reg start_mat_mul_kg;
reg start_mat_mul;
wire done_mat_mul;

reg                                         a_ready;
wire                                        mul_ready;

wire [`WORD_SIZE-1:0]                       a;
wire [`WORD_SIZE-1:0]                       a_row_1;
wire [`WORD_SIZE-1:0]                       a_row_2;
wire [`CLOG2(`L5_N)-1:0]                    a_addr;

wire [`WORD_SIZE-1:0]                       b;
wire [`CLOG2(`L5_SAMP_MAT_DEPTH)-1:0]       b_addr;

wire [`CLOG2(`L5_SAMP_MAT_DEPTH)-1:0]       c_addr;
wire                                        c_en;
wire [`WORD_SIZE-1:0]                       c;

wire [`WORD_SIZE-1:0]                       e;
wire [`CLOG2(`L5_SAMP_MAT_DEPTH)-1:0]       e_addr;
wire                                        e_wen;

wire                                        mem_sel;

reg  [`CLOG2(`L5_N):0]                     a_rows;
reg  [`CLOG2(`L5_N):0]                     a_cols;
reg  [`CLOG2(`L5_N):0]                     b_rows;
reg  [`CLOG2(`L5_N):0]                     b_cols;

reg  [`CLOG2(`L5_N/`T):0]                  a_rows_div_t;
reg  [`CLOG2(`L5_N/`T)-1:0]                a_cols_div_t;
reg  [`CLOG2(`L5_N/`T):0]                  b_rows_div_t;
reg  [`CLOG2(`L5_N/`T)-1:0]                b_cols_div_t;


reg  [`CLOG2(`L5_N*`L5_N/`T):0]            a_size_div_word_size;
reg  [`CLOG2(`L5_N*`L5_NBAR/`T):0]         b_size_div_word_size;
wire  [`CLOG2(`L5_N*`L5_NBAR/`T):0]        e_size_div_word_size;

// reg  [`CLOG2(`L5_N*`L5_NBAR/`T):0]         se_addr_depth;
reg  [`CLOG2(`L5_N):0]                     se_addr_depth;

// reg                                     ba_plus_e_en;
reg [1:0]                                  mat_mul_mode;


reg   [`L5_LEN_SALT-1:0]                  salt_reg;
reg   [`L5_LEN_SEC-1:0]                   s_reg;
reg   [`L5_LEN_SE-1:0]                    seed_se_reg;
reg   [`L5_LEN_A-1:0]                     z_reg;
reg   [`L5_LEN_SEC-1:0]                   k_reg;
reg   [`L5_LEN_SEC-1:0]                   u_reg;
reg   [`L5_LEN_SEC-1:0]                   pkh_reg;
reg   [`L5_LEN_SEC-1:0]                   ss_reg;
wire  en_seed_kg;
wire  en_seed_encap;
wire  en_seed_decap;
reg   en_seed_a;
reg   en_seed_se_k;
wire   en_ss;
wire   en_pkh;
wire   swap_k_with_s;

reg [3:0] sel_shake_in;
wire [7:0] byte_append;

reg shake_in_valid;
reg shake_out_ready;
reg [`CLOG2(SHAKE128_OUTPUT_SIZE):0] shake_block_output_size;

assign en_seed_kg       = (i_start) && (i_mode_sel == 0) && (state == S_WAIT_START)? 1: 0;
assign en_seed_encap    = (i_start) && (i_mode_sel == 1) && (state == S_WAIT_START)? 1: 0;
assign en_seed_decap    = (i_start) && (i_mode_sel == 2) && (state == S_WAIT_START)? 1: 0;
assign en_pkh = i_shake_out_valid && (state == S_WAIT_PKH_OUT)? 1: 0;
assign en_ss = i_shake_out_valid && (state == S_WAIT_SS)? 1: 0;
assign swap_k_with_s = (state == S_CHECK_FOR_FAILURE && (b_fail || c_fail))? 1: 0;

always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        s_reg <= 0;
        seed_se_reg <= 0;
        z_reg <= 0;
        salt_reg <= 0;
        k_reg <= 0;
        pkh_reg <= 0;
        ss_reg <= 0;
    end
    else begin
        if (en_seed_kg) begin
            seed_se_reg <= i_useed_se;
        end
        else if (en_seed_se_k) begin
            if (i_sec_lev == 1) begin
                seed_se_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_A], {(`L5_LEN_A - `L1_LEN_A){1'b0}}};
            end
            else if (i_sec_lev == 3) begin
                seed_se_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L3_LEN_A], {(`L5_LEN_A - `L3_LEN_A){1'b0}}};
            end
            else if (i_sec_lev == 5) begin
                seed_se_reg <= i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L5_LEN_A];
            end
            else begin
                seed_se_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_A], {(`L5_LEN_A - `L1_LEN_A){1'b0}}};
            end
        end

        if (en_seed_kg || en_seed_decap) begin
            s_reg <= i_useed_s;
        end

        if (en_seed_encap) begin
            salt_reg <= i_salt; 
        end

        if (en_seed_se_k) begin
            if (i_sec_lev == 1) begin
                k_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-`L1_LEN_A-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_A-`L1_LEN_SEC], {(`L5_LEN_SEC - `L1_LEN_SEC){1'b0}}};
            end
            else if (i_sec_lev == 3) begin
                k_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-`L3_LEN_A-1:SHAKE128_OUTPUT_SIZE-`L3_LEN_A-`L3_LEN_SEC], {(`L5_LEN_SEC - `L3_LEN_SEC){1'b0}}};
            end
            else if (i_sec_lev == 5) begin
                k_reg <= i_shake_out[SHAKE128_OUTPUT_SIZE-`L5_LEN_A-1:SHAKE128_OUTPUT_SIZE-`L5_LEN_A-`L5_LEN_SEC];
            end
            else begin
                k_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-`L1_LEN_A-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_A-`L1_LEN_SEC], {(`L5_LEN_SEC - `L1_LEN_SEC){1'b0}}};
            end
        end
        else if (swap_k_with_s) begin
            k_reg <= s_reg;
        end

        if (en_seed_encap) begin
            u_reg <= i_useed_u;
        end

        if (en_seed_kg) begin
            z_reg <= i_useed_z;
        end
        else if (en_seed_encap) begin
            z_reg <= i_seed_a;
        end
        else if (en_seed_a) begin
            if (i_sec_lev == 1) begin
                z_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_A], {(`L5_LEN_A - `L1_LEN_A){1'b0}}};
            end
            else if (i_sec_lev == 3) begin
                z_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L3_LEN_A], {(`L5_LEN_A - `L3_LEN_A){1'b0}}};
            end
            else if (i_sec_lev == 5) begin
                z_reg <= i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L5_LEN_A];
            end
            else begin
                z_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_A], {(`L5_LEN_A - `L1_LEN_A){1'b0}}};
            end
        end
        
        if (en_pkh || en_ss) begin
            if (i_sec_lev == 1) begin
                pkh_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_SEC], {(`L5_LEN_SEC - `L1_LEN_SEC){1'b0}}};
            end
            else if (i_sec_lev == 3) begin
                pkh_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L3_LEN_SEC], {(`L5_LEN_SEC - `L3_LEN_SEC){1'b0}}};
            end
            else if (i_sec_lev == 5) begin
                pkh_reg <= i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L5_LEN_SEC];
            end
            else begin
                pkh_reg <= {i_shake_out[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-`L1_LEN_SEC], {(`L5_LEN_SEC - `L1_LEN_SEC){1'b0}}};
            end
        end
        else if (en_seed_decap) begin
            pkh_reg <= i_pkh;
        end
    
    end
end

assign o_seed_a = z_reg;
assign o_pkh = pkh_reg;
assign o_ss = pkh_reg;

assign byte_append = (i_mode_sel == 0)? 8'h5f:
                                        8'h96;

wire [`L5_LEN_SEC+`L5_LEN_SEC+`L5_LEN_SALT-1:0] pkh_u_salt;

assign pkh_u_salt = (i_sec_lev == 1) ?  {pkh_reg[`L1_LEN_SEC-1:0], u_reg[`L1_LEN_SEC-1:0], salt_reg[`L1_LEN_SALT-1:0], {(SHAKE_INPUT_SIZE - `L1_LEN_SEC - `L1_LEN_SEC - `L1_LEN_SALT){1'b0}}}:
                    (i_sec_lev == 3) ?  {pkh_reg[`L3_LEN_SEC-1:0], u_reg[`L3_LEN_SEC-1:0], salt_reg[`L3_LEN_SALT-1:0], {(SHAKE_INPUT_SIZE - `L3_LEN_SEC - `L3_LEN_SEC - `L3_LEN_SALT){1'b0}}}:
                    (i_sec_lev == 5) ?  {pkh_reg[`L5_LEN_SEC-1:0], u_reg[`L5_LEN_SEC-1:0], salt_reg[`L5_LEN_SALT-1:0]}:
                                        {pkh_reg[`L1_LEN_SEC-1:0], u_reg[`L1_LEN_SEC-1:0], salt_reg[`L1_LEN_SALT-1:0], {(SHAKE_INPUT_SIZE - `L1_LEN_SEC - `L1_LEN_SEC - `L1_LEN_SALT){1'b0}}};

assign o_seed_a     =       z_reg;
assign o_shake_in   =       (sel_shake_in == 0)?                        {z_reg, {(SHAKE_INPUT_SIZE - `L5_LEN_A){1'b0}}}:
                            (sel_shake_in == 1)?                        {byte_append, seed_se_reg, {(SHAKE_INPUT_SIZE - `L5_LEN_SE - 8){1'b0}}}:
                            (sel_shake_in == 2)?                        {i_reg[7:0], i_reg[15:8], z_reg, {(SHAKE_INPUT_SIZE - `L5_LEN_A - 16){1'b0}}}:
                            (sel_shake_in == 3)?                        {sreg[SHAKE_INPUT_SIZE-1:0]}:
                            (sel_shake_in == 4)?                        {pkh_u_salt, {(SHAKE_INPUT_SIZE - `L5_LEN_SEC - `L5_LEN_SEC - `L5_LEN_SALT){1'b0}}}:
                            (sel_shake_in == 5)?                        {o_seed_a, {(SHAKE_INPUT_SIZE - `L5_LEN_A){1'b0}}}:
                            (sel_shake_in == 6 || sel_shake_in == 9)?   {c, {(SHAKE_INPUT_SIZE - `WORD_SIZE){1'b0}}}:
                            (sel_shake_in == 7)?                        {i_b, {(SHAKE_INPUT_SIZE - `L5_NBAR*`SAMPLE_IN_SIZE){1'b0}}}:
                            (sel_shake_in == 8)?                        {o_c1, {(SHAKE_INPUT_SIZE - `WORD_SIZE){1'b0}}}:
                            (sel_shake_in == 10)?                       {salt_reg, {(SHAKE_INPUT_SIZE - `L5_LEN_SALT){1'b0}}}:
                            (sel_shake_in == 11)?                       {k_reg, {(SHAKE_INPUT_SIZE - `L5_LEN_SEC){1'b0}}}:
                                                                        0;

assign o_shake_in_valid = (sel_shake_in == 2)?      a_shake_in_valid:
                                                    shake_in_valid;

assign o_shake_out_ready = (sel_shake_in == 2)?     a_shake_out_ready:
                                                    shake_out_ready;

always@(*)
begin
    if (i_sec_lev == 1) begin
        o_shake_in_size  =          (sel_shake_in == 0 || sel_shake_in == 5)?       `L1_LEN_A:
                                    (sel_shake_in == 1)?                            `L1_LEN_SE + 8:
                                    (sel_shake_in == 2)?                            `L1_LEN_A + 16:
                                    (sel_shake_in == 3)?                            `L1_LEN_A + `SAMPLE_IN_SIZE*(`L1_N*`L1_NBAR):
                                    (sel_shake_in == 4)?                            `L1_LEN_SEC + `L1_LEN_SEC + `L1_LEN_SALT:
                                    (sel_shake_in == 6 || sel_shake_in == 8)?       `WORD_SIZE:
                                    (sel_shake_in == 7 || sel_shake_in == 9)?       `L1_NBAR*`SAMPLE_IN_SIZE:
                                    (sel_shake_in == 10)?                           `L1_LEN_SALT:
                                    (sel_shake_in == 11)?                           `L1_LEN_SEC:
                                                                                    0;

        o_shake_out_size  =         (sel_shake_in == 0)?                           `L1_LEN_A:
                                    (sel_shake_in == 1 && i_mode_sel == 0)?         2*`SAMPLE_IN_SIZE*(`L1_N*`L1_NBAR):
                                    (sel_shake_in == 1)?                            2*`SAMPLE_IN_SIZE*(`L1_N*`L1_NBAR) + `SAMPLE_IN_SIZE*(`L1_NBAR*`L1_NBAR):
                                    (sel_shake_in == 2)?                            `SAMPLE_IN_SIZE*(`L1_N):
                                    (sel_shake_in == 4)?                            `L1_LEN_SE + `L1_LEN_SEC:
                                    (sel_shake_in == 5 || sel_shake_in == 6 || 
                                     sel_shake_in == 7 || sel_shake_in == 8 || 
                                     sel_shake_in == 9 || sel_shake_in == 10|| 
                                     sel_shake_in == 11)?                           `L1_LEN_SEC:
                                                                                    0;

        shake_block_output_size  = SHAKE128_OUTPUT_SIZE;
    end
    else if (i_sec_lev == 3) begin
        o_shake_in_size  =          (sel_shake_in == 0 || sel_shake_in == 5)?       `L3_LEN_A:
                                    (sel_shake_in == 1)?                            `L3_LEN_SE + 8:
                                    (sel_shake_in == 2)?                            `L3_LEN_A + 16:
                                    (sel_shake_in == 3)?                            `L3_LEN_A + `SAMPLE_IN_SIZE*(`L3_N*`L3_NBAR):
                                    (sel_shake_in == 4)?                            `L3_LEN_SEC + `L3_LEN_SEC + `L3_LEN_SALT:
                                    (sel_shake_in == 6 || sel_shake_in == 8)?        `WORD_SIZE:
                                    (sel_shake_in == 7 || sel_shake_in == 9)?       `L3_NBAR*`SAMPLE_IN_SIZE:
                                    (sel_shake_in == 10)?                            `L3_LEN_SALT:
                                    (sel_shake_in == 11)?                           `L3_LEN_SEC:
                                                                                    0;
    
        o_shake_out_size  =         (sel_shake_in == 0)?                            `L3_LEN_A:
                                    (sel_shake_in == 1 && i_mode_sel == 0)?         2*`SAMPLE_IN_SIZE*(`L3_N*`L3_NBAR):
                                    (sel_shake_in == 1)?                            2*`SAMPLE_IN_SIZE*(`L3_N*`L3_NBAR) + `SAMPLE_IN_SIZE*(`L3_NBAR*`L3_NBAR):
                                    (sel_shake_in == 2)?                            `SAMPLE_IN_SIZE*(`L3_N):
                                    (sel_shake_in == 4)?                            `L3_LEN_SE + `L3_LEN_SEC:
                                    (sel_shake_in == 5 || sel_shake_in == 6 || 
                                     sel_shake_in == 7 || sel_shake_in == 8 || 
                                     sel_shake_in == 9 || sel_shake_in == 10|| 
                                     sel_shake_in == 11)?                           `L3_LEN_SEC:
                                                                                    0;
        shake_block_output_size  = SHAKE256_OUTPUT_SIZE;
    end
    else if (i_sec_lev == 5) begin
        o_shake_in_size  =         (sel_shake_in == 0 || sel_shake_in == 5)?        `L5_LEN_A:
                                    (sel_shake_in == 1)?                            `L5_LEN_SE + 8:
                                    (sel_shake_in == 2)?                            `L5_LEN_A + 16:
                                    (sel_shake_in == 3)?                            `L5_LEN_A + `SAMPLE_IN_SIZE*(`L5_N*`L5_NBAR):
                                    (sel_shake_in == 4)?                            `L5_LEN_SEC + `L5_LEN_SEC + `L5_LEN_SALT:
                                    (sel_shake_in == 6 || sel_shake_in == 8)?       `WORD_SIZE:
                                    (sel_shake_in == 7 || sel_shake_in == 9)?       `L5_NBAR*`SAMPLE_IN_SIZE:
                                    (sel_shake_in == 10)?                            `L5_LEN_SALT:
                                    (sel_shake_in == 11)?                           `L5_LEN_SEC:
                                                                                    0;
                                                        
        o_shake_out_size  =         (sel_shake_in == 0)?                            `L5_LEN_A:
                                    (sel_shake_in == 1 && i_mode_sel == 0)?         2*`SAMPLE_IN_SIZE*(`L5_N*`L5_NBAR):
                                    (sel_shake_in == 1)?                            2*`SAMPLE_IN_SIZE*(`L5_N*`L5_NBAR) + `SAMPLE_IN_SIZE*(`L5_NBAR*`L5_NBAR):
                                    (sel_shake_in == 2)?                            `SAMPLE_IN_SIZE*(`L5_N):
                                    (sel_shake_in == 4)?                            `L5_LEN_SE + `L5_LEN_SEC:
                                    (sel_shake_in == 5 || sel_shake_in == 6 || 
                                     sel_shake_in == 7 || sel_shake_in == 8 || 
                                     sel_shake_in == 9 || sel_shake_in == 10|| 
                                     sel_shake_in == 11)?                           `L5_LEN_SEC:
                                                                                    0;
        shake_block_output_size  = SHAKE256_OUTPUT_SIZE;
    end
    else begin
        o_shake_in_size  =          (sel_shake_in == 0 || sel_shake_in == 5)?       `L1_LEN_A:
                                    (sel_shake_in == 1)?                            `L1_LEN_SE + 8:
                                    (sel_shake_in == 2)?                            `L1_LEN_A + 16:
                                    (sel_shake_in == 3)?                            `L1_LEN_A + `SAMPLE_IN_SIZE*(`L1_N*`L1_NBAR):
                                    (sel_shake_in == 4)?                            `L1_LEN_SEC + `L1_LEN_SEC + `L1_LEN_SALT:
                                    (sel_shake_in == 6 || sel_shake_in == 8)?       `WORD_SIZE:
                                    (sel_shake_in == 7 || sel_shake_in == 9)?       `L1_NBAR*`SAMPLE_IN_SIZE:
                                    (sel_shake_in == 10)?                           `L1_LEN_SALT:
                                    (sel_shake_in == 11)?                           `L1_LEN_SEC:
                                                                                    0;

        o_shake_out_size  =         (sel_shake_in == 0)?                            `L1_LEN_A:
                                    (sel_shake_in == 1 && i_mode_sel == 0)?         2*`SAMPLE_IN_SIZE*(`L1_N*`L1_NBAR):
                                    (sel_shake_in == 1)?                            2*`SAMPLE_IN_SIZE*(`L1_N*`L1_NBAR) + `SAMPLE_IN_SIZE*(`L1_NBAR*`L1_NBAR):
                                    (sel_shake_in == 2)?                            `SAMPLE_IN_SIZE*(`L1_N):
                                    (sel_shake_in == 4)?                            `L1_LEN_SE + `L1_LEN_SEC:
                                    (sel_shake_in == 5 || sel_shake_in == 6 || 
                                     sel_shake_in == 7 || sel_shake_in == 8 || 
                                     sel_shake_in == 9 || sel_shake_in == 10|| 
                                     sel_shake_in == 11)?                           `L1_LEN_SEC:
                                                                                    0;
        shake_block_output_size  = SHAKE128_OUTPUT_SIZE;
    end
end


// aes ports

assign o_aes_key = o_seed_a;
assign o_aes_in = {i_reg[7:0], i_reg[15:8], j_reg[7:0], j_reg[15:8], {(128-32){1'b0}}};

always@(*)
begin
    if (i_sec_lev == 1) begin
        if (mat_mul_mode == 2'b01) begin
            a_rows = L1_N;
            a_cols = L1_N;
            a_rows_div_t = L1_N/T;
            a_cols_div_t = L1_N/T;
            a_size_div_word_size = (L1_N*L1_N)/T;
        end
        else if (mat_mul_mode == 2'b10) begin
            a_rows = L1_N;
            a_cols = L1_NBAR;
            a_rows_div_t = L1_N/T;
            a_cols_div_t = 1;
            a_size_div_word_size = (L1_N*L1_NBAR)/T;
        end
        else begin
            a_rows = L1_N;
            a_cols = L1_N;
            a_rows_div_t = L1_N/T;
            a_cols_div_t = L1_N/T;
            a_size_div_word_size = (L1_N*L1_N)/T;
        end
    end
    else if (i_sec_lev == 3) begin
        if (mat_mul_mode == 2'b01) begin
            a_rows = L3_N;
            a_cols = L3_N;
            a_rows_div_t = L3_N/T;
            a_cols_div_t = L3_N/T;
            a_size_div_word_size = (L3_N*L3_N)/T;
        end
        else if (mat_mul_mode == 2'b10) begin
            a_rows = L3_N;
            a_cols = L3_NBAR;
            a_rows_div_t = L3_N/T;
            a_cols_div_t = 1;
            a_size_div_word_size = (L3_N*L3_NBAR)/T;
        end
        else begin
            a_rows = L3_N;
            a_cols = L3_N;
            a_rows_div_t = L3_N/T;
            a_cols_div_t = L3_N/T;
            a_size_div_word_size = (L3_N*L3_N)/T;
        end
    end
    else if (i_sec_lev == 5) begin
        if (mat_mul_mode == 2'b01) begin
            a_rows = L5_N;
            a_cols = L5_N;
            a_rows_div_t = L5_N/T;
            a_cols_div_t = L5_N/T;
            a_size_div_word_size = (L5_N*L5_N)/T;
        end
        else if (mat_mul_mode == 2'b10) begin
            a_rows = L5_N;
            a_cols = L5_NBAR;
            a_rows_div_t = L5_N/T;
            a_cols_div_t = 1;
            a_size_div_word_size = (L5_N*L5_NBAR)/T;
        end
        else begin
            a_rows = L5_N;
            a_cols = L5_N;
            a_rows_div_t = L5_N/T;
            a_cols_div_t = L5_N/T;
            a_size_div_word_size = (L5_N*L5_N)/T;
        end
    end
    else begin
        if (mat_mul_mode == 2'b01) begin
            a_rows = L1_N;
            a_cols = L1_N;
            a_rows_div_t = L1_N/T;
            a_cols_div_t = L1_N/T;
            a_size_div_word_size = (L1_N*L1_N)/T;
        end
        else if (mat_mul_mode == 2'b10) begin
            a_rows = L1_N;
            a_cols = L1_NBAR;
            a_rows_div_t = L1_N/T;
            a_cols_div_t = 1;
            a_size_div_word_size = (L1_N*L1_NBAR)/T;
        end
        else begin
            a_rows = L1_N;
            a_cols = L1_N;
            a_rows_div_t = L1_N/T;
            a_cols_div_t = L1_N/T;
            a_size_div_word_size = (L1_N*L1_N)/T;
        end
    end
end

always@(*)
begin
    if (i_sec_lev == 1) begin
        if (mat_mul_mode == 2'b01 || mat_mul_mode == 2'b10) begin
            b_rows = L1_NBAR;
            b_cols = L1_N;
            b_rows_div_t = 1;
            b_cols_div_t = L1_N/T;
            b_size_div_word_size = (L1_NBAR*L1_N)/T;
        end
        else begin
            b_rows = L1_N;
            b_cols = L1_NBAR;
            b_rows_div_t = L1_N/T;
            b_cols_div_t = T >= L1_NBAR? 1 : L1_NBAR/T;
            b_size_div_word_size = (L1_N*L1_NBAR)/T;
        end
    end
    else if (i_sec_lev == 3) begin
        if (mat_mul_mode == 2'b01 || mat_mul_mode == 2'b10) begin
            b_rows = L3_NBAR;
            b_cols = L3_N;
            b_rows_div_t = 1;
            b_cols_div_t = L3_N/T;
            b_size_div_word_size = (L3_NBAR*L3_N)/T;
        end
        else begin
            b_rows = L3_N;
            b_cols = L3_NBAR;
            b_rows_div_t = L3_N/T;
            b_cols_div_t = T >= L3_NBAR? 1 : L3_NBAR/T;
            b_size_div_word_size = (L3_N*L3_NBAR)/T;
        end
    end
    else if (i_sec_lev == 5) begin
        if (mat_mul_mode == 2'b01 || mat_mul_mode == 2'b10) begin
            b_rows = L5_NBAR;
            b_cols = L5_N;
            b_rows_div_t = 1;
            b_cols_div_t = L5_N/T;
            b_size_div_word_size = (L5_NBAR*L5_N)/T;
        end
        else begin
            b_rows = L5_N;
            b_cols = L5_NBAR;
            b_rows_div_t = L5_N/T;
            b_cols_div_t = T >= L5_NBAR? 1 : L5_NBAR/T;
            b_size_div_word_size = (L5_N*L5_NBAR)/T;
        end
    end
    else begin
        if (mat_mul_mode == 2'b01 || mat_mul_mode == 2'b10) begin
            b_rows = L1_NBAR;
            b_cols = L1_N;
            b_rows_div_t = 1;
            b_cols_div_t = L1_N/T;
            b_size_div_word_size = (L1_NBAR*L1_N)/T;
        end
        else begin
            b_rows = L1_N;
            b_cols = L1_NBAR;
            b_rows_div_t = L1_N/T;
            b_cols_div_t = T >= L1_NBAR? 1 : L1_NBAR/T;
            b_size_div_word_size = (L1_N*L1_NBAR)/T;
        end
    end
end

assign e_size_div_word_size = 8;


reg [T_SHAKE128_OUTPUT_SIZE -1:0] sreg;
wire [WORD_SIZE -1:0] sreg_sample;
reg load_sreg;
reg shift_sreg;
reg shift_sreg_epp;

// sampler for s and e
wire [64-1:0] sreg_t;
reg [`SAMPLE_IN_SIZE*`T-1:0] samp_sreg;

wire [`SAMPLE_IN_SIZE-1:0] r_in [`T-1:0];
wire [`SAMPLE_IN_SIZE*T-1:0] r_in_le;
wire [`SAMPLE_IN_SIZE*T-1:0] a_in_le;
wire [`WORD_SIZE-1:0] samp_a;
wire [T*(`CLOG2(`L1_T_CHI_SIZE) + 1)-1:0] samp_out;
wire [`L5_WIDTH_Q*T-1:0] samp_out_16;

wire [`L5_WIDTH_Q*`T-1:0] s_out;
wire [WORD_SIZE-1:0] e_out;
wire [16*8-1:0] e_pp_out;

reg e_rd_wr_en;
reg s_rd_wr_en;
reg epp_rd_wr_en;
reg [`CLOG2(`L5_N)-1:0] se_addr;



wire [T_SHAKE128_OUTPUT_SIZE-1:0] sreg_shift;
wire [T_SHAKE128_OUTPUT_SIZE-1:0] test_i_prng_in_shift;

assign test_i_prng_in_shift = {{(T_EXTRA_BITS){1'b0}},i_shake_out};


assign shift_val = sel_a? shift_val_a: shift_val_se;

variable_shift
    #(
        .WIDTH(T_SHAKE128_OUTPUT_SIZE)
    )
VAR_SHIFT
    (
        .i_vector(test_i_prng_in_shift),
        .i_shift(shift_val),
        .o_shifted_vector(sreg_shift)
    );



always@(posedge i_clk)
begin
    if (i_rst_n == 0 || i_start || refresh_sreg_a) begin
        sreg <= 0;
    end
    else begin
        if (load_sreg || load_areg) begin
            sreg <= sreg | sreg_shift; 
        end
        else if (shift_sreg || shift_areg)begin
            sreg <= {sreg[T_SHAKE128_OUTPUT_SIZE-WORD_SIZE-1:0], {(WORD_SIZE){1'b0}}};
        end
        else if (shift_sreg_aes) begin
            sreg[T_SHAKE128_OUTPUT_SIZE-1:T_SHAKE128_OUTPUT_SIZE-WORD_SIZE] <= {sreg[T_SHAKE128_OUTPUT_SIZE-128-1:T_SHAKE128_OUTPUT_SIZE-WORD_SIZE], i_aes_out};
        end
        else if (shift_sreg_epp)begin
            sreg <= {sreg[T_SHAKE128_OUTPUT_SIZE-16*8-1:0], {(16*8){1'b0}}};
        end
    end
end

assign sreg_sample = sreg[T_SHAKE128_OUTPUT_SIZE-1: T_SHAKE128_OUTPUT_SIZE-WORD_SIZE];


assign sreg_t = sreg[SHAKE128_OUTPUT_SIZE-1:SHAKE128_OUTPUT_SIZE-64];

genvar il;
generate
    for (il = 0; il < T; il = il + 1) begin
        assign r_in[il] = sreg_sample[`SAMPLE_IN_SIZE*(il+1)-1:`SAMPLE_IN_SIZE*il];
        assign a_in_le[`SAMPLE_IN_SIZE*(il+1)-1:`SAMPLE_IN_SIZE*il] = (i_sec_lev == 1)?    {1'b0, r_in[il][6:0], r_in[il][15:8]} : 
                                                                                            {r_in[il][7:0], r_in[il][15:8]};
        assign r_in_le[`SAMPLE_IN_SIZE*(il+1)-1:`SAMPLE_IN_SIZE*il] = {r_in[il][7:0], r_in[il][15:8]};
    end
endgenerate

//sampling on the fly
genvar is;
generate
    for (is = 0; is < T; is = is + 1) begin
        sample 
        SAMPLE_E_AND_R
            (
                .i_r(r_in_le[`SAMPLE_IN_SIZE*(is+1)-1:`SAMPLE_IN_SIZE*is]),
                // .i_r(r_in[is]),
                .i_sec_level(i_sec_lev),
                .o_e(samp_out[(`CLOG2(`L1_T_CHI_SIZE) + 1)*(is+1)-1:(`CLOG2(`L1_T_CHI_SIZE) + 1)*is]),
                .o_e_16(samp_out_16[(`L5_WIDTH_Q)*(is+1)-1:(`L5_WIDTH_Q)*is])
            );
    end
endgenerate



always@(posedge i_clk)
begin
    if (i_rst_n == 0 || i_start) begin
        se_addr <= 0;
    end
    if (se_addr == (se_addr_depth - 1) && (s_rd_wr_en || e_rd_wr_en || epp_rd_wr_en || a_rd_wr_en || a_rd_wr_en_aes || b_rd_addr_en)) begin
        se_addr <= 0;
    end
    else begin
        if (s_rd_wr_en || e_rd_wr_en || epp_rd_wr_en || a_rd_wr_en || a_rd_wr_en_aes || b_rd_addr_en) begin
            se_addr <= se_addr + 1;
        end
    end
end


sram #(.WIDTH(`WORD_SIZE), .ADDR_WIDTH(`CLOG2((`L5_N*`L5_NBAR)/`T)))
SAMP_S
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~s_rd_wr_en),
        .i_ramAddr(i_s_en? i_s_addr :mem_en? b_addr :se_addr),
        .i_ramData(samp_out_16),
        .o_ramData(s_out)
    );

assign o_s = s_out;

assign samp_out = (i_mode_sel == 0)? s_out : (i_mode_sel == 1 || i_mode_sel == 2)? e_out : e_pp_out;


sram #(.WIDTH(`WORD_SIZE), .ADDR_WIDTH(`CLOG2((`L5_N*`L5_NBAR)/`T)))
SAMP_E
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~e_rd_wr_en),
        .i_ramAddr(se_addr),
        .i_ramData(samp_out_16),
        .o_ramData(e_out)
    );

wire wr_en_samp_epp;
wire [16*8-1:0] epp_in;
wire [2:0] epp_in_addr;


assign wr_en_samp_epp = (epp_rd_wr_en) || wen_v || (sel_mc == 2'b00 & mc_mem_out_en);

assign epp_in = epp_rd_wr_en?   samp_out_16[WORD_SIZE-1:WORD_SIZE-16*8] :
                       wen_v?   v_shift_reg :
                                c_minus_bprimes;

assign epp_in_addr =    k_mat_decode_en?                        k_mat_decode_addr :
                        wen_v?                                  v_addr[2:0]:
                        sel_encode?                             epp_addr[2:0]:
                        epp_rd_wr_en?                           se_addr[2:0]:
                        (sel_mc == 2'b00 & mc_mem_out_en)?      mc_mem_out_addr[2:0]:
                                                                mc_mem_in_addr[2:0];

//BRAM E'' (Encaps and Decaps)
sram #(.WIDTH(16*8), .ADDR_WIDTH(`CLOG2((`L5_NBAR))))
SAMP_E_PP
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~wr_en_samp_epp),
        .i_ramAddr(epp_in_addr),
        .i_ramData(epp_in),
        .o_ramData(e_pp_out)
    );



assign o_c_addr = (mem_comp_mem_in_en && sel_mem_comp)? mem_comp_mem_in_addr[2:0] :mc_mem_in_addr[2:0];
assign o_c_en = mc_mem_in_en | (mem_comp_mem_in_en & sel_mem_comp);

wire [`L5_NBAR*`L5_WIDTH_Q-1:0] c_minus_bprimes;
wire [`L5_NBAR*`L5_WIDTH_Q-1:0] bprimes;

assign bprimes = c[WORD_SIZE-1: WORD_SIZE-`L5_NBAR*`L5_WIDTH_Q];

genvar isub;
generate
    for (isub = 0; isub < `L5_NBAR; isub = isub + 1) begin
        sub #(.WIDTH(`L5_WIDTH_Q))
        SUBTRACT
        (
            .i_sec_lev(i_sec_lev),
            .i_a(i_c[(isub+1)*L5_WIDTH_Q-1:isub*L5_WIDTH_Q]),
            .i_b(bprimes[(isub+1)*L5_WIDTH_Q-1:isub*L5_WIDTH_Q]),
            .o_c(c_minus_bprimes[(isub+1)*L5_WIDTH_Q-1:isub*L5_WIDTH_Q])
        ); 
    end
endgenerate

assign e = samp_out_16;
assign e_wen = e_rd_wr_en;
assign e_addr = se_addr;

assign b = s_out;

assign c_addr = i_b_en?                                i_b_addr: 
                b_rd_en?                                se_addr:
                (mem_comp_mem_in_en && sel_mem_comp)?   mem_comp_mem_in_addr: 
                                                        mc_mem_in_addr;

assign o_b = c;

assign c_en = mc_mem_in_en | (mem_comp_mem_in_en && sel_mem_comp) | i_b_en | b_rd_en;


wire [WORD_SIZE-1:0] a_mat_mul;
wire [WORD_SIZE-1:0] b_mat_mul;
wire start_mat_mul_mux;

assign a_mat_mul =  sel_mat_mul == 1? {i_b, {(WORD_SIZE-16*8){1'b0}}} : 
                    sel_mat_mul == 2? {i_s_mat, {(WORD_SIZE-16*8){1'b0}}} : 
                                        a;
// used in decap
assign o_s_mat_addr = a_addr; 
assign o_s_mat_en = sel_mat_mul == 2;


assign o_bprime_addr = (mem_comp_mem_in_en & ~sel_mem_comp)? mem_comp_mem_in_addr :b_addr;
assign o_bprime_en = (sel_mat_mul == 2) | (mem_comp_mem_in_en & ~sel_mem_comp);
assign b_mat_mul = sel_mat_mul == 2? i_bprime : b;

// used in encap
assign o_b_addr = (sel_shake_in == 7)? se_addr :a_addr;
assign o_b_en = (sel_mat_mul == 1) || (b_rd_en); 

assign start_mat_mul_mux = (sel_mat_mul == 1 | sel_mat_mul == 2)? start_mat_mul_ep :start_mat_mul;

// matrix multiplication 
matrix_arithmetic #(
    .A_ROWS(`L5_N), 
    .A_COLS(`L5_N),
    .B_ROWS(`L5_NBAR),
    .B_COLS(`L5_N),
    .ELEMENT_WIDTH(`L5_WIDTH_Q),
    .T(`T)
    )
MAT_MUL
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_start(start_mat_mul_mux),

        .i_mode(mat_mul_mode),
        .i_sec_lev(i_sec_lev),

        .i_a_rows(a_rows),
        .i_b_rows(b_rows),

        .i_a_rows_div_t(a_rows_div_t),
        .i_a_cols_div_t(a_cols_div_t),
        .i_b_rows_div_t(b_rows_div_t),
        .i_b_cols_div_t(b_cols_div_t),
        
        .i_a_size_div_word_size(a_size_div_word_size),   
        .i_b_size_div_word_size(b_size_div_word_size),   
        .i_e_size_div_word_size(e_size_div_word_size),   
        
        .i_a_ready(a_ready),
        .o_mul_ready(mul_ready),

        .i_a(a_mat_mul),
        .o_a_addr(a_addr),
        
        .i_b(b_mat_mul),
        .o_b_addr(b_addr),
        
        .i_e((sel_mc==2'b10 | sel_mc==2'b11)? mc_mem_out :e),
        .i_e_addr((sel_mc==2'b10 | sel_mc==2'b11)? mc_mem_out_addr :e_addr),
        .i_e_wen((sel_mc==2'b10 | sel_mc==2'b11)? mc_mem_out_en :e_wen),

        .i_c_addr(c_addr),
        .i_c_en(c_en),
        .o_c(c),
        
        .o_mem_sel(mem_sel),
        .o_mem_en(mem_en),

        .o_done(done_mat_mul)
    );




reg [5:0] state;
localparam S_WAIT_START                 = 6'd0;
localparam S_KEYGEN_SETUP               = 6'd1;
localparam S_ENCAP_SETUP                = 6'd2;
localparam S_DECAP_SETUP                = 6'd3;
localparam S_SEND_Z_TO_SHAKE            = 6'd4;
localparam S_WAIT_SHAKE_SEED_A          = 6'd5;
localparam S_SEND_SE_TO_SHAKE           = 6'd6;
localparam S_WAIT_SHAKE_OUT_SEED_SE     = 6'd7;
localparam S_LOAD_A_TO_SHIFT            = 6'd8;
localparam S_LOAD_B_TO_SHIFT            = 6'd9;

localparam S_DONE_PKH                   = 6'd10;
localparam S_SEND_PKH_U_SALT_TO_SHAKE   = 6'd11;
localparam S_WAIT_SHAKE_PKH_U_SALT      = 6'd12;
localparam S_PRNG_LOAD_S                = 6'd13;
localparam S_SAMPLE_S                   = 6'd14;
localparam S_PRNG_LOAD_E                = 6'd15;
localparam S_SAMPLE_E                   = 6'd16;
localparam S_PRNG_LOAD_EPP              = 6'd17;
localparam S_SAMPLE_EPP                 = 6'd18;
localparam S_GEN_A_MUL_S_PLUS_E         = 6'd19;

localparam S_GEN_A_MUL_S_PLUS_E_DONE    = 6'd20;
localparam S_COPY_BPRIME                = 6'd21;
localparam S_COPY_BPRIME_DONE           = 6'd22;
localparam S_COPY_EPP                   = 6'd23;
localparam S_COPY_EPP_DONE              = 6'd24;
localparam S_SB_PLUS_EPP                = 6'd25;
localparam S_SB_PLUS_EPP_DONE           = 6'd26;
localparam S_INIT_MEM_ZERO              = 6'd27;
localparam S_INIT_MEM_ZERO_DONE         = 6'd28;
localparam S_START_BS                   = 6'd29;

localparam S_DONE_BS                    = 6'd30;
localparam S_C_MINUS_BS                 = 6'd31;
localparam S_C_MINUS_BS_DONE            = 6'd32;
localparam S_START_DECODE               = 6'd33;
localparam S_DONE_DECODE                = 6'd34;
localparam S_START_MEM_COMP_B           = 6'd35;
localparam S_DONE_MEM_COMP_B            = 6'd36;
localparam S_START_MEM_COMP_C           = 6'd37;
localparam S_DONE_MEM_COMP_C            = 6'd38;
localparam S_CHECK_FOR_FAILURE          = 6'd39;

localparam S_PKH_SEED_A                 = 6'd40;
localparam S_PKH_B                      = 6'd41;
localparam S_WAIT_PKH_OUT               = 6'd42;
localparam S_SS_C1                      = 6'd43;
localparam S_SS_C1_LAST                 = 6'd44;
localparam S_SS_C2                      = 6'd45;
localparam S_SS_C2_LAST                 = 6'd46;
localparam S_SS_SALT                    = 6'd47;
localparam S_SS_SALT_LAST               = 6'd48;
localparam S_SS_K                       = 6'd49;
localparam S_SS_K_LAST                  = 6'd50;

localparam S_WAIT_SS                    = 6'd51;
localparam S_DONE                       = 6'd52;

reg [`CLOG2((`SHAKE128_OUTPUT_SIZE)) : 0] shift_val_se;
reg [`CLOG2((`SHAKE128_OUTPUT_SIZE)) : 0] shift_val_a;
wire [`CLOG2((`SHAKE128_OUTPUT_SIZE)) : 0] shift_val;
reg sel_a;

reg [`CLOG2((`SHAKE128_OUTPUT_SIZE)) : 0] track_shift;
reg [`CLOG2((`SHAKE128_OUTPUT_SIZE)) : 0] track_shift_a;
reg [`CLOG2((`SHAKE128_OUTPUT_SIZE/64)) : 0] count_shift;
reg start_mat_mul_ep;
reg [1:0] sel_mat_mul;
reg b_fail;
reg c_fail;

always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        state <= S_WAIT_START;
        count_shift <= 0;
        o_done  <= 0;
        test_o_prng_addr <= 0;
        test_o_sel_mem_sa <= 0;
        mat_mul_mode <= 2'b00;
        se_addr_depth <= b_size_div_word_size;
        track_shift <= T_EXTRA_BITS;
        shift_val_se <= T_EXTRA_BITS;
        shake_in_valid <= 0;
        shake_out_ready <= 0;
        test_o_prng_mode <= 0;
        o_shake_in_last_block <= 0;
        b_fail <= 0;
        c_fail <= 0;
    end
    else begin
        if (state == S_WAIT_START) begin
            test_o_prng_addr <= 0;
            test_o_prng_mode <= 0;
            count_shift <= 0;
            o_done <= 0; 
            test_o_sel_mem_sa <= 0;
            mat_mul_mode <= 2'b00;
            se_addr_depth <= b_size_div_word_size;
            shake_in_valid <= 0;
            shake_out_ready <= 0;
            o_shake_in_last_block <= 0;
            b_fail <= 0;
            c_fail <= 0;
            if (i_start) begin
                track_shift <= T_EXTRA_BITS;
                shift_val_se <= T_EXTRA_BITS;
                if (i_mode_sel == 0) begin
                    state <= S_KEYGEN_SETUP;
                end
                else if (i_mode_sel == 1) begin
                    state <= S_ENCAP_SETUP;
                end
                else if (i_mode_sel == 2) begin
                    state <= S_DECAP_SETUP;
                end
            end
        end

        else if (state == S_KEYGEN_SETUP) begin
            mat_mul_mode <= 2'b00;
            state <= S_SEND_Z_TO_SHAKE;
            se_addr_depth <= b_size_div_word_size;
        end

        else if (state == S_ENCAP_SETUP) begin
            state <= S_PKH_SEED_A;
            mat_mul_mode <= 2'b01;
            se_addr_depth <= b_rows;
        end

        else if (state == S_DECAP_SETUP) begin
            state <= S_INIT_MEM_ZERO;
            mat_mul_mode <= 2'b10;
        end

        else if (state == S_SEND_Z_TO_SHAKE) begin
            if (i_shake_in_ready) begin
                state <= S_WAIT_SHAKE_SEED_A;
                shake_in_valid <= 1;
                o_shake_in_last_block <= 1;
            end
        end

        else if (state == S_WAIT_SHAKE_SEED_A) begin
            shake_in_valid <= 0;
            o_shake_in_last_block <= 0;
            if (i_shake_out_valid) begin
                state <= S_SEND_SE_TO_SHAKE;
                shake_out_ready <= 1;
            end
        end

        else if (state == S_SEND_SE_TO_SHAKE) begin
            shake_out_ready <= 0;
            if (i_shake_in_ready) begin
                state <= S_WAIT_SHAKE_OUT_SEED_SE;
                shake_in_valid <= 1;
                o_shake_in_last_block <= 1;
            end
        end

        else if (state == S_WAIT_SHAKE_OUT_SEED_SE) begin
            shake_in_valid <= 0;
            o_shake_in_last_block <= 0;
            if (i_shake_out_valid) begin
                test_o_prng_addr <= test_o_prng_addr + 1;
                state <= S_SAMPLE_S;
                track_shift <= shake_block_output_size;
                shake_out_ready <= 1;
            end
        end

        else if (state == S_LOAD_A_TO_SHIFT) begin
            state <= S_DONE_PKH;
        end

        else if (state == S_DONE_PKH) begin
            state <= S_SEND_PKH_U_SALT_TO_SHAKE;
        end

        else if (state == S_SEND_PKH_U_SALT_TO_SHAKE) begin
            if (i_shake_in_ready) begin
                state <= S_WAIT_SHAKE_PKH_U_SALT;
                shake_in_valid <= 1;
            end
        end

        else if (state == S_WAIT_SHAKE_PKH_U_SALT) begin
            shake_in_valid <= 0;
            if (i_shake_out_valid) begin
                state <= S_SEND_SE_TO_SHAKE;
                shake_out_ready <= 1;
            end
        end

        else if(state == S_PRNG_LOAD_S) begin
            if (i_shake_out_valid) begin
                test_o_prng_addr <= test_o_prng_addr + 1;
                state <= S_SAMPLE_S;
                track_shift <= shake_block_output_size + track_shift;
                shake_out_ready <= 1;
            end
        end

        else if (state == S_SAMPLE_S) begin
                shake_out_ready <= 0;
                if (se_addr == b_size_div_word_size - 1 && s_rd_wr_en) begin
                    if (track_shift - WORD_SIZE < WORD_SIZE) begin
                        state <= S_PRNG_LOAD_E;
                        shift_val_se <=  T_EXTRA_BITS - (track_shift - WORD_SIZE);
                    end
                    else begin
                        state <= S_SAMPLE_E;
                    end
                end
                else begin

                    if (track_shift < 2*WORD_SIZE) begin
                        state <= S_PRNG_LOAD_S;
                        shift_val_se <=  T_EXTRA_BITS - (track_shift - WORD_SIZE);
                    end
                end    
                        track_shift <= track_shift - WORD_SIZE;
        end

        else if(state == S_PRNG_LOAD_E) begin
            if (i_shake_out_valid) begin
                test_o_prng_addr <= test_o_prng_addr + 1;
                state <= S_SAMPLE_E;
                track_shift <= shake_block_output_size + track_shift;
                shake_out_ready <= 1;
            end
        end

        else if (state == S_SAMPLE_E) begin
            shake_out_ready <= 0;
            if (se_addr == b_size_div_word_size - 1 && e_rd_wr_en) begin
                if (i_mode_sel == 0) begin
                    state <= S_GEN_A_MUL_S_PLUS_E;
                    se_addr_depth <= a_cols_div_t;
                end
                else if (i_mode_sel == 1 || i_mode_sel == 2) begin
                        se_addr_depth <= `L5_NBAR;
                    if (track_shift - 16*8 < 16*8) begin
                        state <= S_PRNG_LOAD_EPP;
                        shift_val_se <=  T_EXTRA_BITS - (track_shift - 16*8);
                   end
                    else begin
                        state <= S_SAMPLE_EPP;
                    end
                end
            end
            else begin

                if (track_shift - WORD_SIZE < WORD_SIZE) begin
                    state <= S_PRNG_LOAD_E;
                    shift_val_se <=  T_EXTRA_BITS - (track_shift - WORD_SIZE);
                end
            end    
                    track_shift <= track_shift - WORD_SIZE;
        end

        else if(state == S_PRNG_LOAD_EPP) begin
            if (i_shake_out_valid) begin
                test_o_prng_addr <= test_o_prng_addr + 1;
                state <= S_SAMPLE_EPP;
                track_shift <= shake_block_output_size + track_shift;
                shake_out_ready <= 1;
            end
        end

        else if (state == S_SAMPLE_EPP) begin
            shake_out_ready <= 0;
            if (se_addr == `L5_NBAR - 1 && epp_rd_wr_en) begin
                state <= S_GEN_A_MUL_S_PLUS_E;
                se_addr_depth <= a_cols_div_t;
            end
            else begin
                if (track_shift - 16*8 < 16*8) begin
                    state <= S_PRNG_LOAD_EPP;
                    shift_val_se <=  T_EXTRA_BITS - (track_shift - 16*8);       
                end
            end  
            track_shift <= track_shift - 16*8;  
        end

        else if (state == S_GEN_A_MUL_S_PLUS_E) begin
            test_o_sel_mem_sa <= 1;
            o_shake_in_last_block <= 1;
            state <= S_GEN_A_MUL_S_PLUS_E_DONE;
        end

        else if (state == S_GEN_A_MUL_S_PLUS_E_DONE) begin
            shake_in_valid <= 0;
            if (done_a_gen) begin
                o_shake_in_last_block <= 0;
                if (i_mode_sel == 0) begin
                    state <= S_PKH_SEED_A;
                end
                else begin
                    state <= S_COPY_BPRIME;
                end
            end
        end

        else if (state == S_COPY_BPRIME) begin
            state <= S_COPY_BPRIME_DONE;
        end
        
        else if (state == S_COPY_BPRIME_DONE) begin
            if (done_mem_copy) begin
                state <= S_COPY_EPP;
            end
        end
        
        else if (state == S_COPY_EPP) begin
            state <= S_COPY_EPP_DONE;
        end

        else if (state == S_COPY_EPP_DONE) begin
            if (done_mem_copy) begin
                state <= S_SB_PLUS_EPP;
                mat_mul_mode <= 2'b10;
            end
        end

        else if (state == S_SB_PLUS_EPP) begin
            state <= S_SB_PLUS_EPP_DONE;
        end

    
        else if (state == S_SB_PLUS_EPP_DONE) begin
            if (done_mat_mul) begin
                if (i_mode_sel == 2) begin
                    state <= S_START_MEM_COMP_C;
                end
                else begin
                    state <= S_SS_C1;
                    se_addr_depth <= b_size_div_word_size;
                end
            end
        end

        else if (state == S_INIT_MEM_ZERO) begin
            state <= S_INIT_MEM_ZERO_DONE;
        end

        else if (state == S_INIT_MEM_ZERO_DONE) begin
            if (done_mem_copy) begin
                state <= S_START_BS;
            end
        end

        else if (state == S_START_BS) begin
            state <= S_DONE_BS;
        end

        else if (state == S_DONE_BS) begin
            if (done_mat_mul) begin
                state <= S_C_MINUS_BS;
            end
        end

        else if (state == S_C_MINUS_BS) begin
            state <= S_C_MINUS_BS_DONE;
        end

        else if (state == S_C_MINUS_BS_DONE) begin
            if (done_mem_copy) begin
                state <= S_START_DECODE;
            end
        end

        else if (state == S_START_DECODE) begin
            state <= S_DONE_DECODE;
        end

        else if (state == S_DONE_DECODE) begin
            if (done_decode) begin
                state <= S_ENCAP_SETUP;
            end
        end

        else if (state == S_START_MEM_COMP_B) begin
            state <= S_DONE_MEM_COMP_B;
        end

        else if (state == S_DONE_MEM_COMP_B) begin
            if (done_mem_comp) begin
                state <= S_DONE;
                b_fail <= mem_comp_fail;
            end
        end

        else if (state == S_START_MEM_COMP_C) begin
            state <= S_DONE_MEM_COMP_C;
        end

        else if (state == S_DONE_MEM_COMP_C) begin
            if (done_mem_comp) begin
                state <= S_START_MEM_COMP_B;
                c_fail <= mem_comp_fail;
            end
        end

        else if (state == S_CHECK_FOR_FAILURE) begin
            state <= S_SS_C1;
            se_addr_depth <= b_size_div_word_size;
        end

        else if (state == S_PKH_SEED_A) begin 
            test_o_prng_mode <= 1;
            if (i_shake_in_ready) begin
                state <= S_PKH_B;
                shake_in_valid <= 1;
                o_shake_in_last_block <= 0;
            end
        end

        else if (state == S_PKH_B) begin
            if (i_shake_in_ready) begin
                shake_in_valid <= 1;
                if (se_addr == se_addr_depth-1) begin
                    o_shake_in_last_block <= 1;
                    state <= S_WAIT_PKH_OUT;
                end
                else begin
                    o_shake_in_last_block <= 0;
                end
            end
            else begin
                shake_in_valid <= 0;
            end
        end
        
        else if (state == S_WAIT_PKH_OUT) begin
            shake_in_valid <= 0;
            o_shake_in_last_block <= 0;
            se_addr_depth <= b_size_div_word_size;
            if (i_shake_out_valid) begin
                test_o_prng_mode <= 0;
                if (i_mode_sel == 0) begin
                    state <= S_DONE;
                end
                else begin
                    state <= S_SEND_PKH_U_SALT_TO_SHAKE;
                end
            end
        end

        else if (state == S_SS_C1) begin
            o_shake_in_last_block <= 0;
            if (i_shake_in_ready) begin
                shake_in_valid <= 1;
                if (se_addr == se_addr_depth-1) begin
                    state <= S_SS_C1_LAST;
                    se_addr_depth <= `L5_NBAR;
                end
                else begin
                    o_shake_in_last_block <= 0;
                end
            end
            else begin
                shake_in_valid <= 0;
            end        
        end

        else if (state == S_SS_C1_LAST) begin
            shake_in_valid <= 0;
            state <= S_SS_C2;
        end

        else if (state == S_SS_C2) begin
            
            if (i_shake_in_ready) begin
                shake_in_valid <= 1;
                if (se_addr == se_addr_depth-1) begin
                    state <= S_SS_C2_LAST;
                end
            end
            else begin
                shake_in_valid <= 0;
            end        
        end

        else if (state == S_SS_C2_LAST) begin
            shake_in_valid <= 0;
            state <= S_SS_SALT;
        end

        else if (state == S_SS_SALT) begin
            if (i_shake_in_ready) begin
                shake_in_valid <= 1;
                state <= S_SS_SALT_LAST;
            end
            else begin
                shake_in_valid <= 0;
            end
        end

        else if (state == S_SS_SALT_LAST) begin
            shake_in_valid <= 0;
            state <= S_SS_K;
        end

        else if (state == S_SS_K) begin
            if (i_shake_in_ready) begin
                shake_in_valid <= 1;
                o_shake_in_last_block <= 1;
                state <= S_SS_K_LAST;
            end
            else begin
                shake_in_valid <= 0;
                o_shake_in_last_block <= 0;
            end
        end

        else if (state == S_SS_K_LAST) begin
            shake_in_valid <= 0;
            state <= S_WAIT_SS;
            o_shake_in_last_block <= 0;
        end

        else if (state == S_WAIT_SS) begin
            o_shake_in_last_block <= 0;
            shake_in_valid <= 0;
            if (i_shake_out_valid) begin
                state <= S_DONE;
            end
        end

        else if (state == S_DONE) begin
            o_done <= 1;
            state <= S_WAIT_START;
        end

    end
end


always@(*)
begin
    case(state)
        S_WAIT_START: begin
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            en_seed_se_k <= 0;
            if (i_start) begin
                test_o_prng_en <= 1;
            end
            else begin
                test_o_prng_en <= 0;
            end
        end

        S_KEYGEN_SETUP: begin
            
            load_sreg <= 0;
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
        end

        S_ENCAP_SETUP: begin
            
            load_sreg <= 0;
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
        end

        S_DECAP_SETUP: begin
            load_sreg <= 0;
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
        end

        S_SEND_Z_TO_SHAKE: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
        end

        S_WAIT_SHAKE_SEED_A: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            if (i_shake_out_valid) begin
                en_seed_a <= 1;
            end
            else begin
                en_seed_a <= 0;
            end
        end

        S_SEND_SE_TO_SHAKE: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 1;
        end

        S_WAIT_SHAKE_OUT_SEED_SE: begin
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 1;
            if (i_shake_out_valid) begin
                load_sreg <= 1;
            end
            else begin
                load_sreg <= 0;
            end
            
        end

        S_LOAD_A_TO_SHIFT: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 3;
            en_seed_se_k <= 0;
        end

        S_DONE_PKH: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 3;
            en_seed_se_k <= 0;
        end

        S_SEND_PKH_U_SALT_TO_SHAKE: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 4;
            en_seed_se_k <= 0;
        end

        S_WAIT_SHAKE_PKH_U_SALT: begin
            if (i_shake_out_valid) begin
                en_seed_se_k <= 1;
            end
            else begin
                en_seed_se_k <= 0;
            end
            load_sreg <= 0;
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 4;
        end

        S_PRNG_LOAD_S: begin
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            // if (test_i_prng_valid) begin
            if (i_shake_out_valid) begin
                load_sreg <= 1;
            end
            else begin
                load_sreg <= 0;
            end
        end

        S_SAMPLE_S: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            shift_sreg_epp <= 0;
            
            if (track_shift < WORD_SIZE) begin
                s_rd_wr_en <= 0;
                shift_sreg <= 0;
            end
            else begin
                s_rd_wr_en <= 1;
                shift_sreg <= 1;
            end
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
        end

        S_PRNG_LOAD_E: begin
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            if (i_shake_out_valid) begin
                load_sreg <= 1;
            end
            else begin
                load_sreg <= 0;
            end
        end

        S_SAMPLE_E: begin
            test_o_prng_en <= 1;
            start_a_gen <= 0;
            load_sreg <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            
            s_rd_wr_en <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;

            if (track_shift < WORD_SIZE) begin
                e_rd_wr_en <= 0;
                shift_sreg <= 0;
            end
            else begin
                e_rd_wr_en <= 1;
                shift_sreg <= 1;
            end
        end

        S_PRNG_LOAD_EPP: begin
            test_o_prng_en <= 1;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            start_mem_copy <= 0;
            sel_mc <= 2'b00;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
            if (i_shake_out_valid) begin
                load_sreg <= 1;
            end
            else begin
                load_sreg <= 0;
            end
        end

        S_SAMPLE_EPP: begin
            test_o_prng_en <= 1;
            start_a_gen <= 0;
            load_sreg <= 0;
            epp_rd_wr_en <= 1;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg <= 0;
            
            shift_sreg_epp <= 1;
                
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_GEN_A_MUL_S_PLUS_E: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 1;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 1;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 2;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_GEN_A_MUL_S_PLUS_E_DONE: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 2;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_COPY_BPRIME: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b01;
            start_mem_copy <= 1;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_COPY_BPRIME_DONE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b01;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_COPY_EPP: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b10;
            start_mem_copy <= 1;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_COPY_EPP_DONE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b10;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_SB_PLUS_EPP: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 1;
            sel_mat_mul <= 1;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_SB_PLUS_EPP_DONE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 1;
            start_encode_cont <= 0;
            start_decode <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_INIT_MEM_ZERO: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b11;
            start_mem_copy <= 1;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_INIT_MEM_ZERO_DONE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b11;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_START_BS: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 1;
            sel_mat_mul <= 2;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_DONE_BS: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 2;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_C_MINUS_BS: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 1;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_C_MINUS_BS_DONE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_START_DECODE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 1;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_DONE_DECODE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_START_MEM_COMP_B: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 1;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_DONE_MEM_COMP_B: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_START_MEM_COMP_C: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 1;
            start_mem_comp <= 1;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_DONE_MEM_COMP_C: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 1;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_en <= 0;
            b_rd_addr_en <= 0;
        end

        S_PKH_SEED_A: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 5;
            en_seed_a <= 0;
            b_rd_en <= 1;
            b_rd_addr_en <= 0;
        end

        S_PKH_B: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            b_rd_en <= 1;
            if (i_shake_in_ready) begin
                b_rd_addr_en <= 1;
            end
            else begin
                b_rd_addr_en <= 0;
            end
            if (i_mode_sel == 0) begin
                sel_shake_in <= 6;
            end
            else begin
                sel_shake_in <= 7;
            end
        end

        S_WAIT_PKH_OUT: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
            if (i_mode_sel == 0) begin
                sel_shake_in <= 6;
            end
            else begin
                sel_shake_in <= 7;
            end
        end
        
        S_SS_C1: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_en <= 1;
            sel_shake_in <= 8;
            if (i_shake_in_ready) begin
                b_rd_addr_en <= 1;
            end
            else begin
                b_rd_addr_en <= 0;
            end
        end

        S_SS_C1_LAST: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_en <= 1;
            sel_shake_in <= 8;
            b_rd_addr_en <= 0;
        end

        S_SS_C2: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 1;
            sel_shake_in <= 9;
            if (i_shake_in_ready) begin
                b_rd_addr_en <= 1;
            end
            else begin
                b_rd_addr_en <= 0;
            end
        end

        S_SS_C2_LAST: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 1;
            sel_shake_in <= 9;
            b_rd_addr_en <= 0;
        end

        S_SS_SALT: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
            sel_shake_in <= 10;
        end

        S_SS_SALT_LAST: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
            sel_shake_in <= 10;
        end

        S_SS_K: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
            sel_shake_in <= 11;
        end

        S_SS_K_LAST: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
            sel_shake_in <= 11;
        end

        S_WAIT_SS: begin
            test_o_prng_en <= 1;
            load_sreg <= 0;
            shift_sreg <= 0;
            shift_sreg_epp <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            en_seed_se_k <= 0;
            sel_shake_in <= 0;
            en_seed_a <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
            sel_shake_in <= 11;
        end

        S_DONE: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            sel_mem_comp <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
        end

        default: begin
            test_o_prng_en <= 0;
            load_sreg <= 0;
            shift_sreg <= 0;
            s_rd_wr_en <= 0;
            e_rd_wr_en <= 0;
            start_a_gen <= 0;
            epp_rd_wr_en <= 0;
            sel_mc <= 2'b00;
            start_mem_copy <= 0;
            start_mat_mul_ep <= 0;
            sel_mat_mul <= 0;
            start_encode_cont <= 0;
            start_decode <= 0;
            start_mem_comp <= 0;
            shift_sreg_epp <= 0;
            en_seed_se_k <= 0;
            en_seed_a <= 0;
            sel_shake_in <= 0;
            b_rd_addr_en <= 0;
            b_rd_en <= 0;
        end
    endcase
end

wire [`CLOG2(`L5_N/`T)-1:0] a_row_addr;
wire [`CLOG2(`L5_N/`T)-1:0] a_row_addr_1;
wire [`CLOG2(`L5_N/`T)-1:0] a_row_addr_2;
reg [`CLOG2(`L5_N)-1:0] a_row_count;
reg [`CLOG2(`SHAKE128_OUTPUT_SIZE/64) : 0] count_shift_a;
reg a_rd_wr_en;
reg a_rd_wr_en_aes;
reg b_rd_addr_en;
reg b_rd_en;
reg start_a_gen;
reg done_a_gen;
reg load_areg;
reg load_intr_areg;
reg shift_areg;
reg [15:0] i_reg;
reg [15:0] j_reg;
reg first_time;
reg new_seed_a;
reg refresh_sreg_a;
reg shift_sreg_aes;

reg a_shake_in_valid;
reg a_shake_out_ready;

reg [`CLOG2(WORD_SIZE/128):0] count_shift_aes_a;

reg [4:0] a_state;
localparam A_WAIT_START         = 5'd0;
localparam A_SEED_SHAKE_1       = 5'd1;
localparam A_WAIT_SHAKE_1       = 5'd2;
localparam A_LOAD_A_ROW_1       = 5'd3;
localparam A_SAMPLE_A_ROW_1     = 5'd4;
localparam A_STALL_1            = 5'd5;
localparam A_SEED_SHAKE_2       = 5'd6;
localparam A_WAIT_SHAKE_2       = 5'd7;
localparam A_LOAD_A_ROW_2       = 5'd8;
localparam A_SAMPLE_A_ROW_2     = 5'd9;
localparam A_STALL_2            = 5'd10;
localparam A_LOAD_A2            = 5'd11;
localparam A_LOAD_A1            = 5'd12;


localparam A_SEED_AES_1         = 5'd13;
localparam A_LOAD_A_ROW_AES_1   = 5'd14;
localparam A_SAMPLE_A_ROW_AES_1 = 5'd15;
localparam A_STALL_AES_1        = 5'd16;
localparam A_SEED_AES_2         = 5'd17;
localparam A_LOAD_A_ROW_AES_2   = 5'd18;
localparam A_SAMPLE_A_ROW_AES_2 = 5'd19;
localparam A_STALL_AES_2        = 5'd20;
localparam A_LOAD_AES_A2        = 5'd21;
localparam A_LOAD_AES_A1        = 5'd22;
localparam A_SEND_IJ_TO_AES_1   = 5'd23;
localparam A_SEND_IJ_TO_AES_2   = 5'd24;


localparam A_DONE               = 5'd25;

always@(posedge i_clk)
begin
    if (i_rst_n==0) begin
        a_state <= A_WAIT_START;
        done_a_gen <= 0;
        test_o_prng_addr_a <= 0;
        count_shift_a <= 0;
        i_reg <= 0;
        j_reg <= 0;
        a_ready <= 0;
        first_time <= 1;
        new_seed_a <= 1;
        track_shift_a <= T_EXTRA_BITS;
        shift_val_a <= T_EXTRA_BITS;
        o_aes_in_valid <= 0;
        count_shift_aes_a <= 0;
        a_rd_wr_en_aes <= 0;
        a_shake_in_valid <= 0;
        a_shake_out_ready <= 0;
    end
    else begin
        if (a_state == A_WAIT_START) begin
            done_a_gen <= 0;
            test_o_prng_addr_a <= 0;
            count_shift_a <= 0;
            i_reg <= 0;
            j_reg <= 0;
            a_ready <= 0;
            first_time <= 1;
            new_seed_a <= 1;
            track_shift_a <= 0;
            shift_val_a <= T_EXTRA_BITS;
            o_aes_in_valid <= 0;
            count_shift_aes_a <= 0;
            a_rd_wr_en_aes <= 0;
            a_shake_in_valid <= 0;
            a_shake_out_ready <= 0;
            if (start_a_gen) begin
                if (i_aes_variant) begin
                    a_state <= A_SEED_AES_1;
                end
                else begin
                    a_state <= A_SEED_SHAKE_1;
                end
            end
        end
        
        
        else if (a_state == A_SEED_SHAKE_1) begin
            new_seed_a <= 1;
            if (i_reg == a_rows) begin
                a_state <= A_DONE;
            end
            else if (i_shake_in_ready && mul_ready) begin
                a_state <= A_WAIT_SHAKE_1;
                a_shake_in_valid <= 1;
            end

            if (mul_ready) begin
                a_ready <= 0;
            end
        end

        else if (a_state == A_WAIT_SHAKE_1) begin
            new_seed_a <= 0;
            a_shake_in_valid <= 0;
            a_shake_out_ready <= 0;
            if (i_reg == a_rows) begin
                a_state <= A_DONE;
            end
            else begin 
                a_state <= A_LOAD_A_ROW_1;
            end


        end
        
        else if (a_state == A_LOAD_A_ROW_1) begin
            if (i_shake_out_valid) begin
                a_state <= A_SAMPLE_A_ROW_1;
                test_o_prng_addr_a <= test_o_prng_addr_a + 1;
                new_seed_a <= 0;
                track_shift_a <= `SHAKE128_OUTPUT_SIZE + track_shift_a;
                a_shake_out_ready <= 1;
            end
        end

        else if (a_state == A_SAMPLE_A_ROW_1) begin
            a_shake_out_ready <= 0;
            if (a_row_addr == a_rows_div_t - 1 && a_rd_wr_en) begin
                a_state <= A_STALL_1;
                i_reg <= i_reg + 1;
                track_shift_a <= 0;
                shift_val_a <= T_EXTRA_BITS;
                i_reg <= i_reg + 1;
            end
            else begin

                if (track_shift_a - WORD_SIZE < WORD_SIZE) begin
                    a_state <= A_LOAD_A_ROW_1;
                    shift_val_a <=  T_EXTRA_BITS - (track_shift_a - WORD_SIZE);
                    
                end
                track_shift_a <= track_shift_a - WORD_SIZE;   
            end    
        end

        else if (a_state == A_STALL_1) begin
            a_state <= A_SEED_SHAKE_2;
            a_shake_out_ready <= 0;
            a_ready <= 1;
            if (first_time) begin
                first_time <= 0;
            end
        end
        
        else if (a_state == A_SEED_SHAKE_2) begin
            
            new_seed_a <= 1;
            track_shift_a <= 0;
            shift_val_a <= T_EXTRA_BITS;
            if (i_reg == a_rows) begin
                a_state <= A_DONE;
            end
            else if (i_shake_in_ready && mul_ready) begin
                a_state <= A_WAIT_SHAKE_2;
                a_shake_in_valid <= 1;
            end

            if (mul_ready) begin
                a_ready <= 0;
            end
        end
        
        else if (a_state == A_WAIT_SHAKE_2) begin
            new_seed_a <= 1;
            a_shake_in_valid <= 0;
            track_shift_a <= 0;
            shift_val_a <= T_EXTRA_BITS;
            if (i_reg == a_rows) begin
                a_state <= A_DONE;
            end
            else begin 
                a_state <= A_LOAD_A_ROW_2;
            end
        end

        else if (a_state == A_LOAD_A_ROW_2) begin
            if (i_shake_out_valid) begin
                a_state <= A_SAMPLE_A_ROW_2;
                test_o_prng_addr_a <= test_o_prng_addr_a + 1;
                new_seed_a <= 0;
                track_shift_a <= `SHAKE128_OUTPUT_SIZE + track_shift_a;
                a_shake_out_ready <= 1;
            end
        end

        else if (a_state == A_SAMPLE_A_ROW_2) begin
            
            a_shake_out_ready <= 0;
            if (a_row_addr == a_rows_div_t - 1 && a_rd_wr_en) begin
                a_state <= A_STALL_2;
                i_reg <= i_reg + 1;
                track_shift_a <= 0;
                shift_val_a <= T_EXTRA_BITS;
                i_reg <= i_reg + 1;
            end
            else begin

                if (track_shift_a - WORD_SIZE < WORD_SIZE) begin
                    a_state <= A_LOAD_A_ROW_2;
                    shift_val_a <=  T_EXTRA_BITS - (track_shift_a - WORD_SIZE);
                    
                end
                track_shift_a <= track_shift_a - WORD_SIZE;       
            end    
        end

        else if (a_state == A_STALL_2) begin
            a_state <= A_SEED_SHAKE_1;
            a_shake_out_ready <= 0;
            a_ready <= 1;
        end

       // AES A gen states 
        else if (a_state == A_SEED_AES_1) begin
            new_seed_a <= 1;
            a_rd_wr_en_aes <= 0;
            if (i_reg == a_rows) begin
                a_state <= A_DONE;
            end
            else if (mul_ready) begin
                a_state <= A_SEND_IJ_TO_AES_1;
                a_ready <= 0;
            end
        end

        else if (a_state == A_SEND_IJ_TO_AES_1) begin
            a_rd_wr_en_aes <= 0;
            if (i_aes_in_ready) begin
                a_state <= A_LOAD_A_ROW_AES_1;
                o_aes_in_valid <= 1;
            end
        end

        else if (a_state == A_LOAD_A_ROW_AES_1) begin
            o_aes_in_valid <= 0;
            if (i_aes_out_valid) begin
                new_seed_a <= 0;
                
                if (j_reg < a_cols-8) begin
                    j_reg <= j_reg + 8;
                    a_state <= A_SEND_IJ_TO_AES_1;
                end
                else begin
                    a_state <= A_STALL_AES_1;
                    j_reg <= 0;
                    count_shift_aes_a <= 0;
                    
                end

                if (count_shift_aes_a == WORD_SIZE/128-1) begin
                    count_shift_aes_a <= 0;
                    a_rd_wr_en_aes <= 1;
                end
                else begin
                    count_shift_aes_a <= count_shift_aes_a + 1;
                    a_rd_wr_en_aes <= 0;
                end
            end
        end

        else if (a_state == A_STALL_AES_1) begin
            a_ready <= 1;
            a_rd_wr_en_aes <= 0;
            a_state <= A_SEED_AES_2;
            i_reg <= i_reg + 1;
        end

         else if (a_state == A_SEED_AES_2) begin
            new_seed_a <= 1;
            a_rd_wr_en_aes <= 0;
            
            if (i_reg == a_rows) begin
                a_state <= A_DONE;
            end
            else if (mul_ready) begin
                a_state <= A_SEND_IJ_TO_AES_2;
            end
        end

        else if (a_state == A_SEND_IJ_TO_AES_2) begin
            a_ready <= 0;
            a_rd_wr_en_aes <= 0;
            if (i_aes_in_ready) begin
                a_state <= A_LOAD_A_ROW_AES_2;
                o_aes_in_valid <= 1;
            end
        end

        else if (a_state == A_LOAD_A_ROW_AES_2) begin
            o_aes_in_valid <= 0;
            if (i_aes_out_valid) begin
                new_seed_a <= 0;
                
                if (j_reg < a_cols-8) begin
                    j_reg <= j_reg + 8;
                    a_state <= A_SEND_IJ_TO_AES_2;
                end
                else begin
                    a_state <= A_STALL_AES_2;
                    j_reg <= 0;
                    count_shift_aes_a <= 0;
                    
                end

                if (count_shift_aes_a == WORD_SIZE/128-1) begin
                    count_shift_aes_a <= 0;
                    a_rd_wr_en_aes <= 1;
                end
                else begin
                    count_shift_aes_a <= count_shift_aes_a + 1;
                    a_rd_wr_en_aes <= 0;
                end
            end
        end

        else if (a_state == A_STALL_AES_2) begin
            a_ready <= 1;
            a_state <= A_SEED_AES_1;
            a_rd_wr_en_aes <= 0;
            i_reg <= i_reg + 1;
            if (first_time) begin
                first_time <= 0;
            end
        end

        else if (a_state == A_DONE) begin
            if (done_mat_mul) begin
                done_a_gen <= 1;
                a_state <= A_WAIT_START;
            end
        end
    end
end

always@(*)
begin
    case(a_state)
        A_WAIT_START: begin
            load_areg <= 0;
            load_intr_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            if (start_a_gen) begin
                sel_a <= 1;
            end
            else begin
                sel_a <= 0;
            end
        end

        A_SEED_SHAKE_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
        end
        
        A_WAIT_SHAKE_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 1;
            shift_sreg_aes <= 0;
            
        end

        A_LOAD_A_ROW_1: begin
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;

            if (i_shake_out_valid) begin
                load_areg <= 1;
            end
            else begin
                load_areg <= 0;
            end

            
            
        end

        A_SAMPLE_A_ROW_1: begin
            load_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            a_rd_wr_en <= 1;
            load_intr_areg <= 0;
            start_mat_mul <= 0;
            
            if (track_shift_a < WORD_SIZE) begin
                shift_areg <= 0;
            end
            else begin
                shift_areg <= 1;
            end
            

        end

        A_STALL_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            if (first_time) begin
                start_mat_mul <= 1;
            end
            else begin
                start_mat_mul <= 0;
            end
        end

        A_SEED_SHAKE_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 1;
            shift_sreg_aes <= 0;
            start_mat_mul <= 0;
        end
        
        A_WAIT_SHAKE_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 1;
            shift_sreg_aes <= 0;
            
        end

        A_LOAD_A_ROW_2: begin

            if (i_shake_out_valid) begin
                load_areg <= 1;
            end
            else begin
                load_areg <= 0;
            end

            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        A_SAMPLE_A_ROW_2: begin
            load_areg <= 0;
             if (track_shift_a < WORD_SIZE) begin
                shift_areg <= 0;
            end
            else begin
                shift_areg <= 1;
            end
            a_rd_wr_en <= 1;  
            start_mat_mul <= 0; 
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end
        
        A_STALL_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        A_SEED_AES_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        A_SEND_IJ_TO_AES_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        A_LOAD_A_ROW_AES_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            
            if (i_aes_out_valid) begin
                shift_sreg_aes <= 1;
            end
            else begin
                shift_sreg_aes <= 0;
            end
        end

        A_STALL_AES_1: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        A_SEED_AES_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
            if (first_time) begin
                start_mat_mul <= 1;
            end
            else begin
                start_mat_mul <= 0;
            end
        end

        A_SEND_IJ_TO_AES_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        A_LOAD_A_ROW_AES_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            
            if (i_aes_out_valid) begin
                shift_sreg_aes <= 1;
            end
            else begin
                shift_sreg_aes <= 0;
            end
        end

        A_STALL_AES_2: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 1;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end



        A_DONE: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 0;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end

        default: begin
            load_areg <= 0;
            shift_areg <= 0;
            a_rd_wr_en <= 0;
            start_mat_mul <= 0;
            load_intr_areg <= 0;
            sel_a <= 0;
            refresh_sreg_a <= 0;
            shift_sreg_aes <= 0;
            
        end
    
    endcase
end

assign a_row_addr = se_addr[`CLOG2(`L5_N/`T)-1:0];



wire a_row_1_wen;
wire a_row_2_wen;

assign a = mem_sel? a_row_2 : a_row_1;
assign a_row_addr_1 = mem_en && ~mem_sel? a_addr[`CLOG2(L5_N/T)-1:0] : a_row_addr;
assign a_row_addr_2 = mem_en && mem_sel? a_addr[`CLOG2(L5_N/T)-1:0] : a_row_addr;
assign a_row_1_wen = ((a_rd_wr_en && ~i_reg[0]) || (a_rd_wr_en_aes && ~i_reg[0]));
assign a_row_2_wen = ((a_rd_wr_en && i_reg[0]) || (a_rd_wr_en_aes && i_reg[0]));

assign samp_a = a_in_le;
sram #(.WIDTH(`WORD_SIZE), .ADDR_WIDTH(`CLOG2(`L5_N/`T)))
A_ROW_MEM_1
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~a_row_1_wen),
        .i_ramAddr(a_row_addr_1),
        .i_ramData(samp_a),
        .o_ramData(a_row_1)
    );

sram #(.WIDTH(`WORD_SIZE), .ADDR_WIDTH(`CLOG2(`L5_N/`T)))
A_ROW_MEM_2
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~a_row_2_wen),
        .i_ramAddr(a_row_addr_2),
        .i_ramData(samp_a),
        .o_ramData(a_row_2)
    );


wire [WORD_SIZE-1:0] bprime;
// memory for Bprime in Encap and Decap operations
sram #(.WIDTH(WORD_SIZE), .ADDR_WIDTH(`CLOG2(L5_N*L5_NBAR/T)))
Bprime_MEM
    (
        .i_clk(i_clk),
        .i_ce_N(1'b0),
        .i_rdWr_N(~(mc_mem_out_en&& sel_mc == 2'b01)),
        .i_ramAddr(b_rd_en? se_addr: i_c1_en? i_c1_addr: (mem_comp_mem_in_en & ~sel_mem_comp)?mem_comp_mem_in_addr[`CLOG2(L5_N*L5_NBAR/T)-1:0]: mc_mem_out_en? mc_mem_out_addr : 0),
        .i_ramData(mc_mem_out),
        .o_ramData(bprime)
    );
assign o_c1 = bprime;

reg [`CLOG2(`L5_N*`L5_N/`T)-1:0] a_addr_test;
always@(posedge i_clk)
begin
    if (i_rst_n == 0 || i_start) begin
        a_addr_test <= 0;
    end
    else begin
        if (a_rd_wr_en || a_rd_wr_en_aes) begin
            a_addr_test <= a_addr_test + 1;
        end
    end
end

//sram #(.WIDTH(`WORD_SIZE), .ADDR_WIDTH(`CLOG2(`L5_N*`L5_N/`T)))
//A_FULL_TEST
//    (
//        .i_clk(i_clk),
//        .i_ce_N(1'b0),
//        .i_rdWr_N(~(a_rd_wr_en || a_rd_wr_en_aes)),
//        .i_ramAddr(a_addr_test),
//        .i_ramData(samp_a),
//        .o_ramData()
//    );


reg                                             start_mem_copy;
wire [`CLOG2(L5_NBAR*L5_N/T)-1:0]               mc_end_addr;

wire [`CLOG2(L5_NBAR*L5_N/T)-1:0]               mc_mem_in_addr; 
wire                                            mc_mem_in_en;
wire  [WORD_SIZE-1:0]                           mc_mem_in;
wire [`CLOG2(L5_NBAR*L5_N/T)-1:0]               mc_mem_out_addr; 
wire                                            mc_mem_out_en;
wire  [WORD_SIZE-1:0]                           mc_mem_out;
wire                                            done_mem_copy;
reg [1:0]                                       sel_mc;

assign mc_end_addr =    (sel_mc == 2'b01)?  b_size_div_word_size - 1 :
                        (sel_mc == 2'b10)?  7:
                        (sel_mc == 2'b11)?  7:
                                            7;

assign mc_mem_in =      (sel_mc == 2'b01)?  c : 
                        (sel_mc == 2'b10)?  {e_pp_out, {(WORD_SIZE-128){1'b0}}}:
                        (sel_mc == 2'b11)?  {{(WORD_SIZE){1'b0}}}:
                                            {c_minus_bprimes, {(WORD_SIZE-128){1'b0}}};
mem_copy
#(
    .WIDTH(WORD_SIZE),
    .MAX_MEM_DEPTH(L5_N*L5_NBAR/T)
)
mem_copy_inst
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(start_mem_copy),

        .i_start_addr(0),
        .i_end_addr(mc_end_addr),

        .o_mem_in_addr(mc_mem_in_addr),
        .o_mem_in_en(mc_mem_in_en),
        .i_mem_in(mc_mem_in),
        
        .o_mem_out_addr(mc_mem_out_addr),
        .o_mem_out_en(mc_mem_out_en),
        .o_mem_out(mc_mem_out),
        
        .o_done(done_mem_copy)
    );


// Encode and Decode modules
reg [`L5_LEN_MU-1:0]  k_from_shake;
wire [`T_ENCODE*L5_WIDTH_Q-1:0]  k_mat;
wire k_mat_wen;
reg [3:0] count_encode;

reg start_encode_cont;
wire done_encode;
reg start_encode;

reg load_epp;

reg sel_encode;

reg [1:0]   e_state;
reg[2:0] epp_addr;
reg[3:0] v_addr;
wire [5:0] k_mat_addr;

reg wen_v;
localparam  E_WAIT_START    = 2'b00;
localparam  E_START_ENCODE  = 2'b01;
localparam  E_LOAD_ENCODE   = 2'b10;
localparam  E_DONE          = 2'b11;

always@(posedge i_clk)
begin
    if (en_seed_encap) begin
        k_from_shake <= i_useed_u;
    end
    else begin
        if (done_decode) begin
                k_from_shake <= k_decode;
        end
    end
end

encode
ENCODE
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n), // update to negedge reset
        .i_start(start_encode),
        .i_sec_level(i_sec_lev),
        .i_k(k_from_shake),
        .o_k_mat_wen(k_mat_wen),
        .o_k_mat_addr(k_mat_addr),
        .o_k_mat(k_mat),
        .o_done(done_encode)
    );


reg start_decode;
wire done_decode;
wire [`L5_LEN_MU-1:0] k_decode; 
wire [L5_WIDTH_Q*L5_NBAR-1:0] k_mat_decode;
wire k_mat_decode_en;
wire [`CLOG2(`L5_MBAR*`L5_NBAR/`T_DECODE)-1:0] k_mat_decode_addr;

assign k_mat_decode = e_pp_out;

decode
DECODE
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n), // update to negedge reset
        .i_start(start_decode),

        .i_sec_level(i_sec_lev),

        .i_k_mat(k_mat_decode),
        .o_k_mat_en(k_mat_decode_en),
        .o_k_mat_addr(k_mat_decode_addr),
        
        .o_k(k_decode),
        .o_done(done_decode)
    );




always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        e_state <= E_WAIT_START;
        epp_addr <= 0;
        count_encode <= 0;
        v_addr <= 0;
        epp_addr <= 0;
        wen_v <= 0;
    end
    else begin
        if (e_state == E_WAIT_START) begin
            epp_addr <= 0;
            v_addr <= 0;
            wen_v <= 0;
            if (start_encode_cont) begin
                e_state <= E_START_ENCODE;            
            end
        end

        else if (e_state == E_START_ENCODE) begin
            e_state <= E_LOAD_ENCODE;
        end

        else if (e_state == E_LOAD_ENCODE) begin
            if (k_mat_wen) begin
                if (count_encode == 5) begin
                    epp_addr <= epp_addr + 1;
                end

                if (count_encode == 7) begin
                    count_encode <= 0;
                    wen_v <= 1;
                end
                else begin
                    count_encode <= count_encode + 1;
                    wen_v <= 0;
                end
            end
            else begin
                wen_v <= 0;
            end

            if (wen_v) begin
                v_addr <= v_addr + 1;
            end

            if (v_addr == 8) begin
                e_state <= E_DONE;
            end
        end

        else if (e_state == E_DONE) begin
            e_state <= E_WAIT_START;
            v_addr <= 0;
            epp_addr <= 0;
            wen_v <= 0;
        end
    end
end

always@(*)
begin
    case(e_state)
        E_WAIT_START: begin
            start_encode <= 0;
            load_epp <= 0;
            if (start_encode_cont) begin
                sel_encode <= 1;
            end
            else begin
                sel_encode <= 0;
            end
        end

        E_START_ENCODE: begin
            load_epp <= 1;
            start_encode <= 1;
            sel_encode <= 1;
        end

        E_LOAD_ENCODE: begin
            start_encode <= 0;
            sel_encode <= 1;
            if (count_encode == 7) begin
                load_epp <= 1;
            end
            else begin
                load_epp <= 0;
            end
        end

        E_DONE: begin
            start_encode <= 0;
            load_epp <= 0;
            sel_encode <= 0;
        end
        
        default: begin
            start_encode <= 0;
            load_epp <= 0;
            sel_encode <= 0;
        end

    endcase
end

reg [127:0] epp_shift_reg;
always@(posedge i_clk)
begin
    if (load_epp) begin
        epp_shift_reg <= e_pp_out;
    end
    else if (k_mat_wen) begin
        epp_shift_reg <= {epp_shift_reg[128-16-1:0], {(16){1'b0}}};
    end
end

wire [L5_WIDTH_Q-1:0] v;
 add 
#(
    .WIDTH(L5_WIDTH_Q)
) V_ADD
(
    .i_clk(i_clk),
    .i_sec_lev(i_sec_lev),
    .i_a(epp_shift_reg[127:128-16]),
    .i_b(k_mat),
    .o_c(v)
);

reg [127:0] v_shift_reg;
always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        v_shift_reg <= {(128){1'b0}};
    end
    else if (k_mat_wen) begin
        v_shift_reg <= {v_shift_reg[128-16-1:0], v};
    end
end

wire mem_comp_fail;
wire done_mem_comp;
reg start_mem_comp;
wire mem_comp_mem_in_en;
wire  [`CLOG2(L5_N)-1:0] mem_comp_start_addr;
wire  [`CLOG2(L5_N)-1:0] mem_comp_end_addr;
wire [`CLOG2(L5_N)-1:0] mem_comp_mem_in_addr;
wire [WORD_SIZE-1:0] mem_comp_mem_in_1;
wire [WORD_SIZE-1:0] mem_comp_mem_in_2;
reg sel_mem_comp;

assign mem_comp_mem_in_1 = sel_mem_comp? {i_c, {(128){1'b0}}} :i_bprime;
assign mem_comp_mem_in_2 = sel_mem_comp? c :bprime;

// constant time comparisons for Decap
assign mem_comp_start_addr = 0;
assign mem_comp_end_addr = sel_mem_comp? 7 : b_size_div_word_size - 1 ;

mem_compare
#(
    .WIDTH(WORD_SIZE),
    .MAX_MEM_DEPTH(L5_N)
)
MEMORY_COMP
    (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(start_mem_comp),
        .i_start_addr(mem_comp_start_addr),
        .i_end_addr(mem_comp_end_addr),
        .o_mem_in_addr(mem_comp_mem_in_addr),
        .o_mem_in_en(mem_comp_mem_in_en),
        .i_mem_in_1(mem_comp_mem_in_1),
        .i_mem_in_2(mem_comp_mem_in_2),
        .o_fail(mem_comp_fail),
        .o_done(done_mem_comp)
    );

endmodule