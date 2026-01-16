
module keyschedule_round
	#(
		parameter Nk=4, 
		parameter N=128, 
		parameter Nr=10
	)
	(
		input [3:0] round,
		input [127:0] oldkey,
		output [127:0] key	
	);

wire [7:0] map_oldkey [0:15];
wire [7:0] map_key [0:15];

wire [7:0] rc [0:13];
assign rc[0] = 8'h01;
assign rc[1] = 8'h02;
assign rc[2] = 8'h04;
assign rc[3] = 8'h08;
assign rc[4] = 8'h10;
assign rc[5] = 8'h20;
assign rc[6] = 8'h40;
assign rc[7] = 8'h80;
assign rc[8] = 8'h1b;
assign rc[9] = 8'h36;
assign rc[10] = 8'h6c;
assign rc[11] = 8'hd8;
assign rc[12] = 8'hab;
assign rc[13] = 8'h4d;

wire [7:0] sbox_oldkey_12;
wire [7:0] sbox_oldkey_13;
wire [7:0] sbox_oldkey_14;
wire [7:0] sbox_oldkey_15;

sbox sbox1 (map_oldkey[12],sbox_oldkey_12);
sbox sbox2 (map_oldkey[13],sbox_oldkey_13);
sbox sbox3 (map_oldkey[14],sbox_oldkey_14);
sbox sbox4 (map_oldkey[15],sbox_oldkey_15);

assign map_key[0] = map_oldkey[0] 	^ sbox_oldkey_13 ^ rc[round-1];
assign map_key[1] = map_oldkey[1] 	^ sbox_oldkey_14;
assign map_key[2] = map_oldkey[2] 	^ sbox_oldkey_15;
assign map_key[3] = map_oldkey[3] 	^ sbox_oldkey_12;

assign map_key[4] = map_oldkey[4] 	^ map_key[0];
assign map_key[5] = map_oldkey[5] 	^ map_key[1];
assign map_key[6] = map_oldkey[6] 	^ map_key[2];
assign map_key[7] = map_oldkey[7] 	^ map_key[3];

assign map_key[8] = map_oldkey[8] 	^ map_key[4];
assign map_key[9] = map_oldkey[9] 	^ map_key[5];
assign map_key[10] = map_oldkey[10] ^ map_key[6];
assign map_key[11] = map_oldkey[11] ^ map_key[7];

assign map_key[12] = map_oldkey[12] ^ map_key[8] ;
assign map_key[13] = map_oldkey[13] ^ map_key[9] ;
assign map_key[14] = map_oldkey[14] ^ map_key[10];
assign map_key[15] = map_oldkey[15] ^ map_key[11];


genvar i,j;
generate
	for(i=0; i<4; i=i+1)begin : loop3
		for(j=0; j<4; j=j+1)begin : loop4
			assign map_oldkey[j*4+i] = oldkey[128-8*(j*4+i)-1:128-8*(j*4+i+1)];
		end
	end
endgenerate

genvar m,n;
generate
	for(m=0; m<4; m=m+1)begin : loop1
		for(n=0; n<4; n=n+1)begin : loop2
			assign key[128-8*(n*4+m)-1:128-8*(n*4+m+1)] = map_key[n*4+m];
		end
	end
endgenerate

endmodule