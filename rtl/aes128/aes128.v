module aes128
    #(
        parameter N=128,
        parameter Nr=10,
        parameter Nk=4)
    (
        input           i_clk,
        input           i_rst,
        input [127:0]   i_data,
        input [127:0]   i_key,
        input           i_start_key_schedule,
        output          o_done_key_schedule,
        input           i_start,
        output reg      o_done,
        output reg [127:0]  o_data
    );

wire [(128*(Nr+1))-1 :0] fullkeys;
wire [127:0] states [Nr+1:0] ;
wire [127:0] states_reg [Nr+1:0] ;
wire [127:0] afterSubBytes;
wire [127:0] afterShiftRows;
wire [Nr-1:0] done;

reg [127:0] i_data_reg;



always@(*)
begin
  i_data_reg <= i_data;  
end

keyschedule ks (
				.i_clk		(i_clk		            ),
				.i_rst		(i_rst		            ),
				.i_start	(i_start_key_schedule	),
				.i_key		(i_key		            ),
				.o_done		(o_done_key_schedule	),
				.o_round_key(fullkeys               )   
				);

addRoundKey addrk1 (i_data_reg,states_reg[0],fullkeys[((128*(Nr+1))-1)-:128]);
assign done[0] = i_start;

always@(posedge i_clk) begin
    o_done <= done[Nr-1];
end

genvar i;
generate
	
	for(i=1; i<Nr ;i=i+1)begin : loop
		encryptRound er
            (   .in(states_reg[i-1]),
                .key(fullkeys[(((128*(Nr+1))-1)-128*i)-:128]),
                .out(states[i])
            );


         register states_reg 
             (
                 .i_clk(i_clk),
                 .i_data(states[i]),
                 .o_data(states_reg[i])
             );
        
        register #(.WIDTH(1)) done_reg 
             (
                 .i_clk(i_clk),
                 .i_data(done[i-1]),
                 .o_data(done[i])
             );
        
            
         
	end


		subBytes sb(states_reg[Nr-1],afterSubBytes);
		shiftRows sr(afterSubBytes,afterShiftRows);
		addRoundKey addrk2(afterShiftRows,states[Nr],fullkeys[127:0]);
		
		always@(*) begin
		  o_data <= states[Nr];
		end

endgenerate


endmodule