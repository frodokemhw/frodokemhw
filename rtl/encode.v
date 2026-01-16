/*
    Encode module 
*/
`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif

module encode
(
    input                                       i_clk, 
    input                                       i_rst_n, 
    input                                       i_start, 
    input  [2:0]                                i_sec_level, //possible values 1,3,5 
    input  [`L5_LEN_MU-1:0]                     i_k,

    output                                      o_k_mat_wen,
    output [`CLOG2(`L5_MBAR*`L5_NBAR/`T_ENCODE)-1:0]  o_k_mat_addr,
    output [`WORD_SIZE_ENCODE-1:0]              o_k_mat,
    
    output reg                                  o_done
);


parameter BYTE = 8;
wire [`L5_LEN_MU-1:0] kbits; 


genvar i,j;
generate
    for (i=0; i < `L5_LEN_MU/8; i=i+1) begin
        for (j=0; j<8; j=j+1) begin
            assign kbits[8-j-1 + i*8] = i_k[j + i*8];
        end
    end
endgenerate

wire [`L1_LEN_MU-1:0] kbits_L1; 
wire [`L3_LEN_MU-1:0] kbits_L3; 
wire [`L5_LEN_MU-1:0] kbits_L5; 

assign kbits_L1 = kbits[`L1_LEN_MU-1:0];
assign kbits_L3 = kbits[`L3_LEN_MU-1:0];
assign kbits_L5 = kbits[`L5_LEN_MU-1:0];

wire [`L1_LEN_MU-1:0] kbits_reorder_L1; 
wire [`L3_LEN_MU-1:0] kbits_reorder_L3; 
wire [`L5_LEN_MU-1:0] kbits_reorder_L5; 

genvar a,b;
generate
    for (a=0; a < `L1_LEN_MU/`L1_B; a=a+1) begin
        for (b=0; b<`L1_B; b=b+1) begin
            assign kbits_reorder_L1[`L1_B-b-1 + a*`L1_B] = kbits_L1[b + a*`L1_B];
        end
    end
endgenerate

genvar c,d;
generate
    for (c=0; c < `L3_LEN_MU/`L3_B; c=c+1) begin
        for (d=0; d<`L3_B; d=d+1) begin
            assign kbits_reorder_L3[`L3_B-d-1 + c*`L3_B] = kbits_L3[d + c*`L3_B];
        end
    end
endgenerate

genvar e,f;
generate
    for (e=0; e < `L5_LEN_MU/`L5_B; e=e+1) begin
        for (f=0; f<`L5_B; f=f+1) begin
            assign kbits_reorder_L5[`L5_B-f-1 + e*`L5_B] = kbits_L5[f + e*`L5_B];
        end
    end
endgenerate

reg [`L5_LEN_MU-1:0] kbits_sreg; 

always@(posedge i_clk)
begin
    if (i_start) begin
        if (i_sec_level == 1) begin
            kbits_sreg <= {kbits_reorder_L1, {(`L5_LEN_MU - `L1_LEN_MU){1'b0}}};
        end
        else if (i_sec_level == 3) begin
            kbits_sreg <= {kbits_reorder_L3, {(`L5_LEN_MU - `L3_LEN_MU){1'b0}}};
        end
        else if (i_sec_level == 5) begin
            kbits_sreg <= {kbits_reorder_L5};
        end
        else begin
            kbits_sreg <= {kbits_reorder_L1, {(`L5_LEN_MU - `L1_LEN_MU){1'b0}}};
        end
    end
    else begin
        if (i_sec_level == 1) begin
            kbits_sreg <= {kbits_sreg[`L5_LEN_MU-`T_ENCODE*`L1_B-1:0],{(`T_ENCODE*`L1_B){1'b0}}};
        end
        else if (i_sec_level == 3) begin
            kbits_sreg <= {kbits_sreg[`L5_LEN_MU-`T_ENCODE*`L3_B-1:0],{(`T_ENCODE*`L3_B){1'b0}}};
        end
        else if (i_sec_level == 5) begin
            kbits_sreg <= {kbits_sreg[`L5_LEN_MU-`T_ENCODE*`L5_B-1:0],{(`T_ENCODE*`L5_B){1'b0}}};
        end
        else begin
            kbits_sreg <= {kbits_sreg[`L5_LEN_MU-`T_ENCODE*`L1_B-1:0],{(`T_ENCODE*`L1_B){1'b0}}};
        end
    end
end

wire [`T_ENCODE*`L1_B-1:0] kbits_msb_L1;
wire [`T_ENCODE*`L3_B-1:0] kbits_msb_L3;
wire [`T_ENCODE*`L5_B-1:0] kbits_msb_L5;

assign kbits_msb_L1 = kbits_sreg[`L5_LEN_MU-1:`L5_LEN_MU-`T_ENCODE*`L1_B];
assign kbits_msb_L3 = kbits_sreg[`L5_LEN_MU-1:`L5_LEN_MU-`T_ENCODE*`L3_B];
assign kbits_msb_L5 = kbits_sreg[`L5_LEN_MU-1:`L5_LEN_MU-`T_ENCODE*`L5_B];

wire [`L5_WIDTH_Q-1:0] mat_val_L1 [0:2**`L1_B -1];
wire [`L5_WIDTH_Q-1:0] mat_val_L3 [0:2**`L3_B -1];
wire [`L5_WIDTH_Q-1:0] mat_val_L5 [0:2**`L5_B -1];


genvar g;
generate
    for (g=0; g < 2**`L1_B ; g=g+1) begin
        assign mat_val_L1[g] = g*`L1_Q/(2**`L1_B);
    end
endgenerate

genvar h;
generate
    for (h=0; h < 2**`L3_B ; h=h+1) begin
        assign mat_val_L3[h] = h*`L3_Q/(2**`L3_B);
    end
endgenerate

genvar m;
generate
    for (m=0; m < 2**`L5_B ; m=m+1) begin
        assign mat_val_L5[m] = m*`L5_Q/(2**`L5_B);
    end
endgenerate

wire [`WORD_SIZE_ENCODE-1:0]              k_mat_L1;
wire [`WORD_SIZE_ENCODE-1:0]              k_mat_L3;
wire [`WORD_SIZE_ENCODE-1:0]              k_mat_L5;

genvar r;
generate
    for (r=0; r < `T_ENCODE; r=r+1) begin
        assign k_mat_L1[(r+1)*`L5_WIDTH_Q-1:r*`L5_WIDTH_Q] = mat_val_L1[kbits_msb_L1[(r+1)*`L1_B-1:r*`L1_B]];
        assign k_mat_L3[(r+1)*`L5_WIDTH_Q-1:r*`L5_WIDTH_Q] = mat_val_L3[kbits_msb_L3[(r+1)*`L3_B-1:r*`L3_B]];
        assign k_mat_L5[(r+1)*`L5_WIDTH_Q-1:r*`L5_WIDTH_Q] = mat_val_L5[kbits_msb_L5[(r+1)*`L5_B-1:r*`L5_B]];
    end
endgenerate

assign o_k_mat =    (i_sec_level== 1)?  k_mat_L1:
                    (i_sec_level== 3)?  k_mat_L3:                
                    (i_sec_level== 5)?  k_mat_L5:                
                                        k_mat_L1;

reg [`CLOG2(`L5_MBAR*`L5_NBAR/`T_ENCODE):0] count;
reg en_count;
always@(posedge i_clk)
begin
    if (i_rst_n == 0 || i_start) begin
        count <= 0;
    end
    else if (en_count) begin
        count <= count + 1;
    end
end

always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        en_count <= 0;
    end
    else if (i_start || count < `L5_MBAR*`L5_NBAR/`T_ENCODE - 1) begin
        en_count <= 1;
    end
    else begin
        en_count <= 0;
    end
end

always@(posedge i_clk)
begin
    if (i_rst_n == 0) begin
        o_done <= 0;
    end
    else if (i_start) begin
        o_done <= 0;
    end
    else if (count == `L5_MBAR*`L5_NBAR/`T_ENCODE - 1) begin
        o_done <= 1;
    end
end

assign o_k_mat_addr = count[`CLOG2(`L5_MBAR*`L5_NBAR/`T_ENCODE)-1:0];
assign o_k_mat_wen = en_count;


endmodule
