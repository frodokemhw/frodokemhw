module add
#(
    parameter WIDTH                = 16,
    parameter REG_OUT           = 1'b0
)
(
    input                   i_clk,
    input [2:0]             i_sec_lev, // remove msb bit from the output for security level 1
    input [WIDTH-1:0]       i_a,
    input [WIDTH-1:0]       i_b,
    output reg [WIDTH-1:0]  o_c
);

wire [WIDTH-1:0] temp_c1;
wire [WIDTH-1:0] temp_c2;

    assign temp_c1 = i_a + i_b;
    assign temp_c2 = (i_sec_lev == 3'b001)?     {1'b0, temp_c1[WIDTH-2:0]}: 
                                                temp_c1;
    
generate
    if (REG_OUT == 1'b1) begin
        always @(posedge i_clk) begin
            o_c <= temp_c2;
        end
    end    
    else begin
        always @(*) begin
            o_c <= temp_c2;
        end 
    end
endgenerate

endmodule