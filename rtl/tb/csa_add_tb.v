/*
    CSA add testbench
*/
`ifndef VIVADO_SIM
    `include "../common/param.v"
`endif

module csa_add_tb();

parameter T = 64;
parameter WIDTH = 16;

reg                                         i_clk=0;
reg                                         i_mode;

wire [WIDTH*T-1:0]                          i_array;

wire [WIDTH*T-1:0]                          i_a;
wire [WIDTH*T-1:0]                          i_b;

wire [WIDTH-1:0]                            i_element;
wire [WIDTH-1:0]                            o_element_tree;
wire [WIDTH-1:0]                            o_element_csa;
reg [2:0]                                   i_sec_lev;


wire  [T*WIDTH-1:0]   o_array_tree;
wire  [T*WIDTH-1:0]   o_array_csa;

wire test_element = (o_element_tree == o_element_csa);
wire test_array = (o_array_tree == o_array_csa);

tree_add
    #(
        .T(T),
        .WIDTH(WIDTH)
    )
REF
    (
        .i_sec_lev(i_sec_lev),
        .i_mode(i_mode),
        .i_a(i_a),
        .i_b(i_b),
        .i_array(i_array),
        .i_element(i_element),
        .o_element(o_element_tree),
        .o_array(o_array_tree)
    );

csa_add
    #(
        .T(T),
        .WIDTH(WIDTH)
    )
DUT
    (
        .i_sec_lev(i_sec_lev),
        .i_mode(i_mode),
        .i_a(i_a),
        .i_b(i_b),
        .i_array(i_array),
        .i_element(i_element),
        .o_element(o_element_csa),
        .o_array(o_array_csa)
    );

integer start_time;

genvar i;
generate
    for (i = 0; i < T; i = i+1) begin
        assign i_array[(i+1)*WIDTH-1 : i*WIDTH] = i;
        assign i_a[(i+1)*WIDTH-1 : i*WIDTH] = i;
        assign i_b[(i+1)*WIDTH-1 : i*WIDTH] = i;
    end
endgenerate

assign i_element = T;

initial begin
    $dumpfile("csa_add_tb.vcd");
    $dumpvars(0,csa_add_tb);
    i_sec_lev <= 1;  
    
    i_mode <= 0;  
    #100
    i_mode <= 1;

    #100
    $finish;
end

always #5 i_clk = ~i_clk;


endmodule