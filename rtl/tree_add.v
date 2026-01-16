/**
Tree Adder Module 

i_sec_lev = 1, 3, 5 (i_sec_lev = 1 MSB is zeroized from the output)

i_mode = 0 -> o_element = i_array[0] + i_array[1] + .. i_array[T-1] outputs one element

i_mode = 1 -> 
    o_array[0] = i_a[0] + i_b[0]; 
    o_array[1] = i_a[1] + i_b[1];  ... 
    o_array[T-1] =  i_a[T-1] + i_b[T-1] 
**/


module tree_add
#(
    parameter T                    = 16,
    parameter WIDTH                = 16
)
(
    input                   i_clk,
    input   [2:0]           i_sec_lev,      
    input                   i_mode,         
                                            

    input   [T*WIDTH-1:0]   i_a,
    input   [T*WIDTH-1:0]   i_b,
    
    input   [T*WIDTH-1:0]   i_array,
    output  [WIDTH-1:0]     i_element,

    output  [T*WIDTH-1:0]   o_array,
    output  [WIDTH-1:0]     o_element
);


parameter LOG_T = `CLOG2(T);

wire [WIDTH-1:0] temp [0:2*T-1];
wire [WIDTH-1:0] a [0:T-1];
wire [WIDTH-1:0] b [0:T-1];

genvar j;
generate 
    for (j = 0; j < T; j = j+1) begin
        assign temp[j] = i_array[(j+1)*WIDTH-1:j*WIDTH]; 
        assign a[j] = i_a[(j+1)*WIDTH-1:j*WIDTH];
        assign b[j] = i_b[(j+1)*WIDTH-1:j*WIDTH];
    end
endgenerate

genvar i;
generate
    for (i =0; i < T-1; i = i+1) begin
            add #(
                .WIDTH(WIDTH),
                .REG_OUT(0)
            )
            ADD_INST
                (
                    .i_clk(i_clk),
                    .i_sec_lev(i_sec_lev),
                    .i_a((i_mode == 1)? a[i] :temp[2*i]),
                    .i_b((i_mode == 1)? b[i] :temp[2*i+1]),
                    .o_c(temp[2**LOG_T+i])
                );
        end
endgenerate

add #(
                .WIDTH(WIDTH),
                .REG_OUT(0)
            )
            ADD_INST_T
                (
                    .i_clk(i_clk),
                    .i_sec_lev(i_sec_lev),
                    .i_a((i_mode == 1)? a[T-1] :temp[2*T-2]),
                    .i_b((i_mode == 1)? b[T-1] :i_element),
                    .o_c(temp[2*T-1])
                );

genvar k;
generate 
    for (k = 0; k < T-1; k = k+1) begin
        assign o_array[(k+1)*WIDTH-1:k*WIDTH] = temp[2**LOG_T+k];
    end
endgenerate

assign o_element = temp[2*T-1];
assign o_array[T*WIDTH-1:(T-1)*WIDTH] = temp[2*T-1];


endmodule