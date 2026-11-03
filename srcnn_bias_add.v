`timescale 1ns / 1ps

//============================================================================
// srcnn_bias_add
//----------------------------------------------------------------------------
// Bias addition for SRCNN PU
//
// Input : signed 16-bit Q8.8
// Bias  : signed 16-bit Q8.8
// Output: signed 16-bit Q8.8
//============================================================================

module srcnn_bias_add #(
    parameter DATA_WIDTH = 16
)(
    input  wire signed [DATA_WIDTH-1:0] i_data,
    input  wire signed [DATA_WIDTH-1:0] i_bias,

    output wire signed [DATA_WIDTH-1:0] o_data
);

    assign o_data = i_data + i_bias;

endmodule