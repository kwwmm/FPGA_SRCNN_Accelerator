`timescale 1ns / 1ps

//============================================================================
// srcnn_mac9_sum
//----------------------------------------------------------------------------
// 9 parallel multipliers + local 9-input accumulation.
// Input data and weights are Q8.8 signed 16-bit.
// Product is Q16.16 signed 32-bit.
// Output sum is Q16.16 extended to 40-bit.
//============================================================================

module srcnn_mac9_sum (
    input  wire signed [16*9-1:0] i_feature9,
    input  wire signed [16*9-1:0] i_weight9,
    output wire signed [39:0]     o_sum_q16_16
);

    wire signed [15:0] f0 = i_feature9[ 0*16 +: 16];
    wire signed [15:0] f1 = i_feature9[ 1*16 +: 16];
    wire signed [15:0] f2 = i_feature9[ 2*16 +: 16];
    wire signed [15:0] f3 = i_feature9[ 3*16 +: 16];
    wire signed [15:0] f4 = i_feature9[ 4*16 +: 16];
    wire signed [15:0] f5 = i_feature9[ 5*16 +: 16];
    wire signed [15:0] f6 = i_feature9[ 6*16 +: 16];
    wire signed [15:0] f7 = i_feature9[ 7*16 +: 16];
    wire signed [15:0] f8 = i_feature9[ 8*16 +: 16];

    wire signed [15:0] w0 = i_weight9[ 0*16 +: 16];
    wire signed [15:0] w1 = i_weight9[ 1*16 +: 16];
    wire signed [15:0] w2 = i_weight9[ 2*16 +: 16];
    wire signed [15:0] w3 = i_weight9[ 3*16 +: 16];
    wire signed [15:0] w4 = i_weight9[ 4*16 +: 16];
    wire signed [15:0] w5 = i_weight9[ 5*16 +: 16];
    wire signed [15:0] w6 = i_weight9[ 6*16 +: 16];
    wire signed [15:0] w7 = i_weight9[ 7*16 +: 16];
    wire signed [15:0] w8 = i_weight9[ 8*16 +: 16];

    wire signed [31:0] p0 = f0 * w0;
    wire signed [31:0] p1 = f1 * w1;
    wire signed [31:0] p2 = f2 * w2;
    wire signed [31:0] p3 = f3 * w3;
    wire signed [31:0] p4 = f4 * w4;
    wire signed [31:0] p5 = f5 * w5;
    wire signed [31:0] p6 = f6 * w6;
    wire signed [31:0] p7 = f7 * w7;
    wire signed [31:0] p8 = f8 * w8;

    // Local tree. 40-bit is enough for nine signed 32-bit products.
    assign o_sum_q16_16 =
        {{8{p0[31]}}, p0} + {{8{p1[31]}}, p1} + {{8{p2[31]}}, p2} +
        {{8{p3[31]}}, p3} + {{8{p4[31]}}, p4} + {{8{p5[31]}}, p5} +
        {{8{p6[31]}}, p6} + {{8{p7[31]}}, p7} + {{8{p8[31]}}, p8};

endmodule
