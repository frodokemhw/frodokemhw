


module keyschedule
                (
                    input i_clk,
                    input i_rst,
                    input i_start,
                    input [127:0] i_key,
                    output[11*128-1:0] o_round_key,
                    output reg o_done
                );

reg [3:0] round;
parameter S_WAIT_START = 0;
parameter S_LOAD_ROUND_KEY = 1;
parameter S_DONE = 2;
reg [1:0] state = 0;
wire wr_en;
wire [127:0] oldkey;
wire [127:0] key;
reg  [127:0] key_reg;

reg [127:0] roundkey [0:10];
assign oldkey = round == 1? i_key : key_reg;
always@(posedge i_clk)
begin
    key_reg <= key;
end
keyschedule_round ksr(round,oldkey,key);
assign wr_en = (state == S_LOAD_ROUND_KEY) || (state == S_WAIT_START && i_start);


always@(posedge i_clk)
begin
	if (wr_en) begin
		roundkey[10-round] <= round == 0? i_key: key;
	end
end

genvar i;
generate
	for (i=0; i<11; i=i+1) begin: key_rounds
		assign o_round_key[128*(i+1)-1:128*(i)] = roundkey[i];
	end
endgenerate

always@(posedge i_clk)
begin
    if (i_rst) begin
        state <= S_WAIT_START;
        round <= 0;
        o_done <= 0;
    end
    else begin
        if (state == S_WAIT_START) begin
            o_done <= 0;
            if (i_start) begin
                state <= S_LOAD_ROUND_KEY;
                round <= round + 1;
            end
        end
        else if (state == S_LOAD_ROUND_KEY) begin
            if (round == 10) begin
                state <= S_DONE;
                round <= 0;
            end
            else begin
                state <= S_LOAD_ROUND_KEY;
                round <= round + 1;
            end
        end
        else if (state == S_DONE) begin
            o_done <= 1;
            state <= S_WAIT_START;
        end
    end
end
endmodule
