`timescale 1ns / 1ps

//============================================================================
// srcnn_adder_tree8
//----------------------------------------------------------------------------
// Adds eight channel sums from MAC9 blocks.
// Inputs : 8 x signed 40-bit Q16.16 partial sums
// Output : signed 48-bit Q16.16 final sum
//============================================================================

module srcnn_adder_tree8 (
    input  wire signed [40*8-1:0] i_sum8,
    output wire signed [47:0]     o_sum
);

    wire signed [39:0] s0 = i_sum8[0*40 +: 40];
    wire signed [39:0] s1 = i_sum8[1*40 +: 40];
    wire signed [39:0] s2 = i_sum8[2*40 +: 40];
    wire signed [39:0] s3 = i_sum8[3*40 +: 40];
    wire signed [39:0] s4 = i_sum8[4*40 +: 40];
    wire signed [39:0] s5 = i_sum8[5*40 +: 40];
    wire signed [39:0] s6 = i_sum8[6*40 +: 40];
    wire signed [39:0] s7 = i_sum8[7*40 +: 40];

    assign o_sum =
        {{8{s0[39]}}, s0} + {{8{s1[39]}}, s1} +
        {{8{s2[39]}}, s2} + {{8{s3[39]}}, s3} +
        {{8{s4[39]}}, s4} + {{8{s5[39]}}, s5} +
        {{8{s6[39]}}, s6} + {{8{s7[39]}}, s7};

endmodule
