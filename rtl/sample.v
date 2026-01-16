/*
    sample module 
*/

`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif

module sample
(

    input [`SAMPLE_IN_SIZE-1 : 0]               i_r, 
    input [2:0]                                 i_sec_level, // 1, 3, or 5
    output [`CLOG2(`L1_T_CHI_SIZE) + 1 - 1: 0]  o_e,
    output [`L5_WIDTH_Q - 1: 0]                 o_e_16
);

wire [`SAMPLE_IN_SIZE-2:0] r_shifted;
wire  r0;
reg [`CLOG2(`L1_T_CHI_SIZE) + 1-1:0] e_count;

wire [`L1_WIDTH_Q-1:0] e_count_L1;
wire [`L3_WIDTH_Q-1:0] e_count_L3;
wire [`L5_WIDTH_Q-1:0] e_count_L5;


assign r_shifted = i_r[`SAMPLE_IN_SIZE-1 : 1];

always@(*) begin
    if (i_sec_level == 1) begin
         e_count <=  r_shifted>15'h7fff ? 13:
                     r_shifted>15'h7ffe ? 12:
                     r_shifted>15'h7ffa ? 11:
                     r_shifted>15'h7fe9 ? 10:
                     r_shifted>15'h7fb1 ? 9:
                     r_shifted>15'h7f0d ? 8:
                     r_shifted>15'h7d67 ? 7:
                     r_shifted>15'h79a9 ? 6:
                     r_shifted>15'h722b ? 5:
                     r_shifted>15'h64f3 ? 4:
                     r_shifted>15'h5063 ? 3:
                     r_shifted>15'h3433 ? 2:
                     r_shifted>15'h1223 ? 1:
                                          0;
    end
    else if (i_sec_level == 3) begin
        e_count <=    r_shifted>15'h7fff ? 11:
                      r_shifted>15'h7ffe ? 10:
                      r_shifted>15'h7ff8 ? 9:
                      r_shifted>15'h7fdb ? 8:
                      r_shifted>15'h7f65 ? 7:
                      r_shifted>15'h7dd9 ? 6:
                      r_shifted>15'h798c ? 5:
                      r_shifted>15'h6f9b ? 4:
                      r_shifted>15'h5c89 ? 3:
                      r_shifted>15'h3e2b ? 2:
                      r_shifted>15'h1606 ? 1:
                                           0;
    end
    else if (i_sec_level == 5) begin
        e_count <=    r_shifted>15'h7fff ? 7:
                      r_shifted>15'h7ffd ? 6:
                      r_shifted>15'h7fd5 ? 5:
                      r_shifted>15'h7e69 ? 4:
                      r_shifted>15'h7682 ? 3:
                      r_shifted>15'h5ba6 ? 2:
                      r_shifted>15'h23b6 ? 1:
                                           0;
    end
    else begin
         e_count <=  r_shifted>15'h7fff ? 13:
                     r_shifted>15'h7ffe ? 12:
                     r_shifted>15'h7ffa ? 11:
                     r_shifted>15'h7fe9 ? 10:
                     r_shifted>15'h7fb1 ? 9:
                     r_shifted>15'h7f0d ? 8:
                     r_shifted>15'h7d67 ? 7:
                     r_shifted>15'h79a9 ? 6:
                     r_shifted>15'h722b ? 5:
                     r_shifted>15'h64f3 ? 4:
                     r_shifted>15'h5063 ? 3:
                     r_shifted>15'h3433 ? 2:
                     r_shifted>15'h1223 ? 1:
                                          0;
    end
end

assign r0 = i_r[0];

assign o_e = r0? ~e_count+1 : e_count; //2s complement = multiplication by -1

assign e_count_L1 = r0? `L1_Q - e_count  :e_count;
assign e_count_L3 = r0? `L3_Q - e_count  :e_count;
assign e_count_L5 = r0? `L5_Q - e_count  :e_count;

assign o_e_16 = (i_sec_level == 1) ?    {1'b0,e_count_L1} :
                (i_sec_level == 3) ?    e_count_L3 :
                (i_sec_level == 5) ?    e_count_L5 :
                                        {1'b0,e_count_L1}; 
endmodule
