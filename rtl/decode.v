/*
    Decode module 
*/
`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif

module decode

(
    input                                           i_clk, 
    input                                           i_rst_n, 
    input                                           i_start,

    input  [2:0]                                    i_sec_level, //possible values 1,3,5

    input  [`WORD_SIZE_DECODE-1:0]                  i_k_mat,
    output  reg                                     o_k_mat_en,
    output  reg [`CLOG2(`L5_MBAR*`L5_NBAR/`T_DECODE)-1:0] o_k_mat_addr,
    
    output  [`L5_LEN_MU-1:0]                         o_k, 
    output reg                                       o_done
);




reg [`L5_LEN_MU-1:0] shift_reg;
reg shift_en;
always@(posedge i_clk)
begin
    shift_en <= o_k_mat_en;
    if (i_rst_n ==0 || i_start) begin
        shift_reg <= 0;
    end
    else if (shift_en && i_sec_level == 1) begin
        // shift_reg <= {shift_reg[`L5_LEN_MU-`L1_B-1:0], kbits_L1};
        shift_reg <= {shift_reg[`L5_LEN_MU-`L1_B-1:0], tmp_128};
    end    
    else if (shift_en && i_sec_level == 3) begin
        // shift_reg <= {shift_reg[`L5_LEN_MU-`L3_B-1:0], kbits_L3};
        shift_reg <= {shift_reg[`L5_LEN_MU-`L3_B-1:0], tmp_192};
    end    
    else if (shift_en && i_sec_level == 5) begin
        // shift_reg <= {shift_reg[`L5_LEN_MU-`L5_B-1:0], kbits_L5};
        shift_reg <= {shift_reg[`L5_LEN_MU-`L5_B-1:0], tmp_256};
    end    
end


wire [`L5_LEN_MU-1:0] k_before_byte_reorder;

assign k_before_byte_reorder =      (i_sec_level== 1)?  {{(`L5_LEN_MU - `L1_LEN_MU){1'b0}},shift_reg[127:0]}:
                                    (i_sec_level== 3)?  {{(`L5_LEN_MU - `L3_LEN_MU){1'b0}},shift_reg[191:0]}:                
                                    (i_sec_level== 5)?  shift_reg:                
                                                        {{(`L5_LEN_MU - `L1_LEN_MU){1'b0}},shift_reg[127:0]}; 

genvar v,w;
generate
    for (v=0; v < `L5_LEN_MU/8; v=v+1) begin
        for (w=0; w<8; w=w+1) begin
            assign o_k[8-w-1 + v*8] = k_before_byte_reorder[w + v*8];
        end
    end
endgenerate

// assign o_k =    (i_sec_level== 1)?  sr_reorder_B_L1:
//                 (i_sec_level== 3)?  sr_reorder_B_L3:                
//                 (i_sec_level== 5)?  sr_reorder_B_L5:                
//                                     sr_reorder_B_L1;  

wire [`T_DECODE*`L1_B-1:0] tmp_128;
wire [`T_DECODE*`L3_B-1:0] tmp_192;
wire [`T_DECODE*`L5_B-1:0] tmp_256;
wire [`L1_B:0] tmp_128_1 [`T_DECODE-1:0];
wire [`L3_B:0] tmp_192_1 [`T_DECODE-1:0];
wire [`L5_B:0] tmp_256_1 [`T_DECODE-1:0];

genvar ii;
generate
   for (ii=0; ii < `T_DECODE; ii =ii+1 ) begin
        
        assign tmp_128_1[ii] = i_k_mat[(ii+1)*`L5_WIDTH_Q-1:ii*`L5_WIDTH_Q] >> 12;
        assign tmp_128[(ii+1)*`L1_B-1:ii*`L1_B] = tmp_128_1[ii] == 0 || tmp_128_1[ii] == 7 ?    0 :
                                                  tmp_128_1[ii] == 1 || tmp_128_1[ii] == 2 ?    2 :
                                                  tmp_128_1[ii] == 3 || tmp_128_1[ii] == 4 ?    1 :
                                                  tmp_128_1[ii] == 5 || tmp_128_1[ii] == 6 ?    3 :
                                                                                                0;
        
        assign tmp_192_1[ii] = i_k_mat[(ii+1)*`L5_WIDTH_Q-1:ii*`L5_WIDTH_Q] >> 12;
        assign tmp_192[(ii+1)*`L3_B-1:ii*`L3_B] = tmp_192_1[ii] == 0  || tmp_192_1[ii] == 15 ?   0 :
                                                  tmp_192_1[ii] == 1  || tmp_192_1[ii] == 2  ?   4 :
                                                  tmp_192_1[ii] == 3  || tmp_192_1[ii] == 4  ?   2 :
                                                  tmp_192_1[ii] == 5  || tmp_192_1[ii] == 6  ?   6 :
                                                  tmp_192_1[ii] == 7  || tmp_192_1[ii] == 8  ?   1 :
                                                  tmp_192_1[ii] == 9  || tmp_192_1[ii] == 10 ?   5 :
                                                  tmp_192_1[ii] == 11 || tmp_192_1[ii] == 12 ?   3 :
                                                  tmp_192_1[ii] == 13 || tmp_192_1[ii] == 14 ?   7 :
                                                                                                 0;

        assign tmp_256_1[ii] = i_k_mat[(ii+1)*`L5_WIDTH_Q-1:ii*`L5_WIDTH_Q] >> 11;
        assign tmp_256[(ii+1)*`L5_B-1:ii*`L5_B] = tmp_192_1[ii] == 0  || tmp_192_1[ii] == 15 || tmp_192_1[ii] == 16 || tmp_192_1[ii] == 31 ?  0: 
                                                  tmp_192_1[ii] == 1  || tmp_192_1[ii] == 2  || tmp_192_1[ii] == 17 || tmp_192_1[ii] == 18 ?  4:
                                                  tmp_192_1[ii] == 3  || tmp_192_1[ii] == 4  || tmp_192_1[ii] == 19 || tmp_192_1[ii] == 20 ?  2:
                                                  tmp_192_1[ii] == 5  || tmp_192_1[ii] == 6  || tmp_192_1[ii] == 21 || tmp_192_1[ii] == 22 ?  6: 
                                                  tmp_192_1[ii] == 7  || tmp_192_1[ii] == 8  || tmp_192_1[ii] == 23 || tmp_192_1[ii] == 24  ? 1: 
                                                  tmp_192_1[ii] == 9  || tmp_192_1[ii] == 10 || tmp_192_1[ii] == 25 || tmp_192_1[ii] == 26 ?  5: 
                                                  tmp_192_1[ii] == 11 || tmp_192_1[ii] == 12 || tmp_192_1[ii] == 27 || tmp_192_1[ii] == 28 ?  3: 
                                                  tmp_192_1[ii] == 13 || tmp_192_1[ii] == 14 || tmp_192_1[ii] == 29 || tmp_192_1[ii] == 30?   7: 
                                                                                                                                              0;

   end 
endgenerate



reg [1:0] state;
localparam S_WAIT_START = 0;
localparam S_LOAD_K     = 1;
localparam S_DONE       = 2;

reg [`CLOG2(2**4):0] two_pow_b;

always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        state <= S_WAIT_START;
        o_k_mat_addr <= 0;
        two_pow_b <= 4;
        o_done <= 0;
    end
    else begin
        if (state == S_WAIT_START) begin
            o_done <= 0;
            if (i_start) begin
                state <= S_LOAD_K;
                o_k_mat_addr <= o_k_mat_addr + 1;
                if (i_sec_level == 1) begin
                    two_pow_b <= 2**`L1_B;
                end 
                else if (i_sec_level == 3) begin
                    two_pow_b <= 2**`L3_B;
                end
                else if (i_sec_level == 5) begin
                    two_pow_b <= 2**`L5_B;
                end
            end
            else begin
                o_k_mat_addr <= 0;
            end
        end

        else if (state == S_LOAD_K) begin
            if (o_k_mat_addr == `L5_MBAR*`L5_NBAR/`T_DECODE - 1) begin
                state <= S_DONE;
                o_k_mat_addr <= 0;
            end
            else begin
                o_k_mat_addr <= o_k_mat_addr + 1;
            end
        end

        else if (state == S_DONE) begin
            state <= S_WAIT_START;
            o_done <= 1;
        end
    end

end

always@(*)
begin
    case(state)

        S_WAIT_START: begin
            
            if (i_start) begin
                o_k_mat_en <= 1;
            end
            else begin
                o_k_mat_en <= 0;
            end
        end

        S_LOAD_K: begin
            o_k_mat_en <= 1;
        end

        S_DONE: begin
            o_k_mat_en <= 0;
            
        end

        default: begin
            o_k_mat_en <= 0;
        end

    endcase
end


endmodule
