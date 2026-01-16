/*
    memory copy module 
*/

`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif

module mem_copy
#(
    parameter WIDTH     = 32,
    parameter MAX_MEM_DEPTH = 16
)
(
    input                                           i_clk, 
    input                                           i_rst_n, 
    input                                           i_start,

    input [`CLOG2(MAX_MEM_DEPTH)-1:0]               i_start_addr,
    input [`CLOG2(MAX_MEM_DEPTH)-1:0]               i_end_addr,

    output reg [`CLOG2(MAX_MEM_DEPTH)-1:0]          o_mem_in_addr, 
    output reg                                      o_mem_in_en,
    input  [WIDTH-1:0]                              i_mem_in,

    output reg [`CLOG2(MAX_MEM_DEPTH)-1:0]          o_mem_out_addr, 
    output reg                                      o_mem_out_en,
    output  [WIDTH-1:0]                             o_mem_out,

    output reg                                       o_done
);


assign o_mem_out = i_mem_in;

reg [1:0] state = 0;

parameter S_WAIT_START = 2'b00;
parameter S_STALL      = 2'b01;
parameter S_COPY       = 2'b10;
parameter S_DONE       = 2'b11;

always@(posedge i_clk)
begin
    if (~i_rst_n) begin
        state <= S_WAIT_START;
        o_mem_in_addr <= 0;
        o_done <= 0;
    end
    else begin
        if (state == S_WAIT_START) begin
            o_done <= 0;
            if (i_start) begin
                state <= S_STALL;
                o_mem_in_addr <= i_start_addr;
            end
        end

        else if (state == S_STALL) begin
                state <= S_COPY;
                o_mem_in_addr <= o_mem_in_addr+1;
        end

        else if (state == S_COPY) begin
            if (o_mem_in_addr == i_end_addr) begin
                state <= S_DONE;
            end
            else begin
                o_mem_in_addr <= o_mem_in_addr + 1;
            end
        end

        else if (state == S_DONE) begin
            state <= S_WAIT_START;
            o_done <= 1;
        end
    end
    o_mem_out_addr <= o_mem_in_addr;
    o_mem_out_en <= o_mem_in_en;
end 

always@(*)
begin
    case(state)
        S_WAIT_START: begin
            o_mem_in_en <= 0;
        end

        S_STALL: begin
            o_mem_in_en <= 1;
        end

        S_COPY: begin
            o_mem_in_en <= 1;
        end

        S_COPY: begin
            o_mem_in_en <= 1;
        end

        S_DONE: begin
            o_mem_in_en <= 0;
        end

        default: begin
            o_mem_in_en <= 0;
        end
    endcase
end


endmodule
