module register
    #(parameter WIDTH=128)
    (
        input  i_clk,
        input [WIDTH-1:0] i_data,
        output reg[WIDTH-1:0] o_data
    );
 
always@(posedge i_clk) begin
    o_data <= i_data;
end

   
endmodule