/**
Variable shift Module 
**/

`ifndef VIVADO_SYNTH
    `include "../common/param.v"
`endif


module variable_shift
#(
    parameter WIDTH                = `SHAKE128_OUTPUT_SIZE + `WORD_SIZE
)
(
    input [WIDTH-1:0]           i_vector, 
    input [`CLOG2(WIDTH)-1:0]   i_shift,
    output [WIDTH-1:0]          o_shifted_vector
);


// Barrel shifter implementation for efficient synthesis
// Uses logarithmic stages instead of linear complexity

localparam SHIFT_BITS = `CLOG2(WIDTH);

wire [WIDTH-1:0] stage [SHIFT_BITS:0];
assign stage[0] = i_vector;

genvar i;
generate
    for (i = 0; i < SHIFT_BITS; i = i + 1) begin : barrel_stage
        wire [WIDTH-1:0] shifted;

        // Create shift amount for this stage (2^i)
        localparam STAGE_SHIFT = 1 << i;

        // Generate left shifted version (zeros fill from right)
        assign shifted = {stage[i][WIDTH-1-STAGE_SHIFT:0], {STAGE_SHIFT{1'b0}}};

        // Select between shifted and non-shifted based on shift bit
        assign stage[i+1] = i_shift[i] ? shifted : stage[i];
    end
endgenerate

assign o_shifted_vector = stage[SHIFT_BITS];



endmodule