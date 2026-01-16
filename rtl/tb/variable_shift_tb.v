/*
    Variable shift testbench
*/
`include "../common/param.v"


module variable_shift_tb();
parameter WIDTH = 24;

reg                                         i_clk=0;

reg [WIDTH-1:0]                             i_vector;
reg [`CLOG2(WIDTH)-1:0]                     i_shift;
wire [WIDTH-1:0]                             o_shifted_vector;



variable_shift
    #(
        .WIDTH(WIDTH)
    )
DUT
    (
        .i_vector(i_vector),
        .i_shift(i_shift),
        .o_shifted_vector(o_shifted_vector)
    );

integer start_time;
integer i;
initial begin
    $dumpfile("variable_shift_tb.vcd");
    $dumpvars(0,variable_shift_tb);

    i_vector <= 1;
    for (i = 0; i < WIDTH; i = i + 1) begin
        i_shift <= i;
        #10;
    end


    #100
    $finish;
end

initial
 $monitor("i_vector = %b  ,i_shift = %d, o_shifted_vector = %b", i_vector, i_shift, o_shifted_vector);


always #5 i_clk = ~i_clk;


endmodule