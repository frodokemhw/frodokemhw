/*
    SRAM module 
*/

module sram_dp
#(
    parameter WIDTH         = 16,
    parameter ADDR_WIDTH    = 4,
    parameter DEPTH         = 1 << ADDR_WIDTH
)
(
    input                       i_clk,
    input                       i_ce_n, // =0 is chip enable
    
    input                       i_rdwr_n_0,  // =0 is write, =1 is read
    input  [ADDR_WIDTH-1:0]     i_addr_0, 
    input  [WIDTH-1:0]          i_data_0,
    output reg [WIDTH-1:0]      o_data_0,

    input                       i_rdwr_n_1,  // =0 is write, =1 is read
    input  [ADDR_WIDTH-1:0]     i_addr_1, 
    input  [WIDTH-1:0]          i_data_1,
    output reg [WIDTH-1:0]      o_data_1
);


reg [WIDTH-1:0] chip[DEPTH-1:0];


always @(posedge i_clk)
    begin
        if (~i_ce_n && ~i_rdwr_n_0) begin
            chip[i_addr_0] <= i_data_0;
        end
        else if (~i_ce_n && i_rdwr_n_0)  begin
            o_data_0 <= chip[i_addr_0];
        end
        else begin 
            o_data_0 <= {(WIDTH){1'bz}};
        end
    end

always @(posedge i_clk)
    begin
        if (~i_ce_n && ~i_rdwr_n_1) begin
            chip[i_addr_1] <= i_data_1;
        end
        else if (~i_ce_n && i_rdwr_n_1)  begin
            o_data_1 <= chip[i_addr_1];
        end
        else begin 
            o_data_1 <= {(WIDTH){1'bz}};
        end
    end

endmodule