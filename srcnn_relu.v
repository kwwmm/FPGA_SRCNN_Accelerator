`timescale 1ns / 1ps

//============================================================================
// srcnn_relu
//----------------------------------------------------------------------------
// ReLU activation
//
// Input : signed Q8.8 (16-bit)
// Output: signed Q8.8 (16-bit)
//
// ReLU(x)
//   x < 0 -> 0
//   else  -> x
//============================================================================

module srcnn_relu #(
    parameter DATA_WIDTH = 16
)(
    input  wire signed [DATA_WIDTH-1:0] i_data,
    output wire signed [DATA_WIDTH-1:0] o_data
);

    assign o_data = (i_data[DATA_WIDTH-1]) ?
                    {DATA_WIDTH{1'b0}} :
                    i_data;

endmodule