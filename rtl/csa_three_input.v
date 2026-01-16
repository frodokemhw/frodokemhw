/**
Three Input Carry Save Adder Module

Performs carry save addition of three input values:
- Outputs sum and carry vectors
- Can be chained together to build larger adder trees
- Reduces three inputs to two outputs (sum + carry)
**/

module csa_three_input
#(
    parameter WIDTH = 16
)
(
    input               i_mode,
    input  [WIDTH-1:0]  i_a,
    input  [WIDTH-1:0]  i_b,
    input  [WIDTH-1:0]  i_c,

    output [WIDTH-1:0]  o_sum,
    output [WIDTH-1:0]  o_carry
);

// 3:2 Carry Save Adder logic
// Sum = A XOR B XOR C
// Carry = (A AND B) OR (A AND C) OR (B AND C)
wire [WIDTH-1:0] a;
wire [WIDTH-1:0] b;
wire [WIDTH-1:0] c;
wire [WIDTH-1:0] carry;

assign a = i_a;
assign b = i_b;

genvar j;
generate
    for (j = 0; j < WIDTH; j = j + 1) begin : c_assign_loop
        assign c[j] =   i_mode && j==0 ? 0 : 
                        i_mode ?        a[j-1] & b[j-1] :
                                        i_c[j];
    end
endgenerate

assign carry = ((i_a & i_b) | (i_a & i_c) | (i_b & i_c));

genvar i;
generate
    for (i = 0; i < WIDTH; i = i + 1) begin : sum_loop
        assign o_sum[i] = a[i] ^ b[i] ^ c[i];
    end
endgenerate

assign o_carry = {carry[WIDTH-2:0], 1'b0};

endmodule