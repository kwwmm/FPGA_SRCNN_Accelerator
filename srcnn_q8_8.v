`timescale 1ns / 1ps

//============================================================================
// q8_8
//----------------------------------------------------------------------------
// Q16.16 -> Q8.8 conversion
//
// Input : signed 48-bit Q16.16
// Output: signed 16-bit Q8.8
//
// Operation:
//   arithmetic right shift by 8
//============================================================================

module srcnn_q8_8 #(
    parameter IN_WIDTH  = 48,
    parameter OUT_WIDTH = 16
)(
    input  wire signed [IN_WIDTH-1:0]  i_data,
    output wire signed [OUT_WIDTH-1:0] o_data
);

    assign o_data = i_data[23:8];

endmodule