/**
Subtraction Module 
**/

`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif

module sub
#(
    parameter WIDTH                = 16
)
(
    // input i_clk,
    input [2:0]         i_sec_lev, // remove msb bit from the output for security level 1
    input [WIDTH-1:0]   i_a,
    input [WIDTH-1:0]   i_b,
    output [WIDTH-1:0]  o_c
);

wire [WIDTH:0] temp_c1;
wire [WIDTH:0] temp_c2;

wire [WIDTH:0] q;

assign temp_c1 = {1'b0,i_a} - {1'b0,i_b};
    
assign q = (i_sec_lev == 3'b001)?  `L1_Q: `L5_Q;

assign temp_c2 = temp_c1[WIDTH]? q + {temp_c1[WIDTH-1:0]} : temp_c1;

assign o_c = (i_sec_lev == 3'b001) ? {1'b0, temp_c2[WIDTH-1:0]} :
                                     temp_c2[WIDTH-1:0];
endmodule