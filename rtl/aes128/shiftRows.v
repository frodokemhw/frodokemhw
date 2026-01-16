/*
0 4 8 12 
1 5 9 13
2 6 10 14
3 7 11 15
*/


/*
0 4 8 12
13 1 5 9
10 14 2 6
7 11 15 3
*/

module shiftRows (
         input [127:0] in,
	      output [127:0] shifted
	      );
	
wire [7:0] map_in [0:15];
wire [7:0] map_shifted [0:15];

genvar i,j;
generate
	for(i=0; i<4; i=i+1)begin : loop3
		for(j=0; j<4; j=j+1)begin : loop4
			assign map_in[j*4+i] = in[128-8*(j*4+i)-1:128-8*(j*4+i+1)];
		end
	end
endgenerate

assign map_shifted[ 0]  = map_in[0];
assign map_shifted[13]  = map_in[1];
assign map_shifted[10]  = map_in[2];
assign map_shifted[ 7]  = map_in[3];
assign map_shifted[ 4]  = map_in[4];
assign map_shifted[ 1]  = map_in[5];
assign map_shifted[14]  = map_in[6];
assign map_shifted[11]  = map_in[7];
assign map_shifted[ 8]  = map_in[8];
assign map_shifted[ 5]  = map_in[9];
assign map_shifted[ 2]  = map_in[10];
assign map_shifted[15]  = map_in[11];
assign map_shifted[12]  = map_in[12];
assign map_shifted[ 9]  = map_in[13];
assign map_shifted[ 6]  = map_in[14];
assign map_shifted[ 3]  = map_in[15];

genvar m,n;
generate
	for(m=0; m<4; m=m+1)begin : loop1
		for(n=0; n<4; n=n+1)begin : loop2
			assign shifted[128-8*(n*4+m)-1:128-8*(n*4+m+1)] = map_shifted[n*4+m];
		end
	end
endgenerate

endmodule

