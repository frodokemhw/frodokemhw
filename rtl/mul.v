/**
Multiplication Module 
**/


module mul
#(
    parameter WIDTH                = 16
)
(
    input [WIDTH-1:0] i_a,
    input [WIDTH-1:0] i_b,
    output [WIDTH-1:0] o_c
);


    assign o_c = i_a*i_b;

endmodule