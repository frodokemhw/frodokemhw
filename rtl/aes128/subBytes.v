module subBytes(
	input [127:0] in,
	output [127:0] out
	);


genvar i;
generate 
for(i=0;i<16;i=i+1) begin :sub_Bytes 
	sbox s
	   (
	       .a(in[(i+1)*8-1:8*i]),
	       .c(out[(i+1)*8-1:8*i])
	    );
	end
endgenerate


endmodule