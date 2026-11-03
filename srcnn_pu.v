`timescale 1ns / 1ps

//============================================================================
// srcnn_pu
//----------------------------------------------------------------------------
// 2-stage internal pipeline + registered output for SRCNN_8_8.
//
// Pipeline timing:
//   Cycle N   : input window/feature/weight/bias valid
//   Cycle N+1 : REG1 = MAC9 x 8 result
//   Cycle N+2 : REG2 = L1 sign-extended sums / L2,L3 adder_tree8 sum
//   Cycle N+3 : o_result / o_l1_result_pack stable for memory write
//
// Important:
//   SRCNN.v must delay write enable/address/channel by 3 cycles.
//============================================================================

module srcnn_pu
(
    input  wire                    i_clk,
    input  wire                    i_rstn,
    input  wire                    i_valid,
    output wire                    o_valid,

    input  wire [1:0]              i_layer,

    input  wire signed [16*9-1:0]  i_l1_window,  // Layer1 real 1ch window
    input  wire signed [16*72-1:0] i_feature,    // Layer2/3 8ch window, 72 x 16-bit
    input  wire signed [16*72-1:0] i_weight,     // 72 x 16-bit

    input  wire signed [16*8-1:0]  i_l1_bias_pack,
    input  wire signed [15:0]      i_bias,
    input  wire                    i_relu_en,

    output reg  signed [16*8-1:0]  o_l1_result_pack,
    output reg  signed [15:0]      o_result
);

    //============================================================
    // Valid/control delay
    //============================================================
    reg [2:0] valid_pipe;

    reg signed [16*8-1:0] l1_bias_pack_d1;
    reg signed [16*8-1:0] l1_bias_pack_d2;

    reg signed [15:0] bias_d1;
    reg signed [15:0] bias_d2;

    reg relu_en_d1;
    reg relu_en_d2;

    assign o_valid = valid_pipe[2];

    always @(posedge i_clk) begin
        if (!i_rstn) begin
            valid_pipe      <= 3'b000;
            l1_bias_pack_d1 <= 0;
            l1_bias_pack_d2 <= 0;
            bias_d1         <= 0;
            bias_d2         <= 0;
            relu_en_d1      <= 1'b0;
            relu_en_d2      <= 1'b0;
        end else begin
            valid_pipe <= {valid_pipe[1:0], i_valid};

            l1_bias_pack_d1 <= i_l1_bias_pack;
            l1_bias_pack_d2 <= l1_bias_pack_d1;

            bias_d1 <= i_bias;
            bias_d2 <= bias_d1;

            relu_en_d1 <= i_relu_en;
            relu_en_d2 <= relu_en_d1;
        end
    end

    //============================================================
    // Stage 0: MAC9 x 8 combinational
    //============================================================
    wire signed [40*8-1:0] mac9_sum8;

    genvar ch;
    generate
        for (ch = 0; ch < 8; ch = ch + 1) begin : GEN_MAC9
            wire signed [16*9-1:0] feature9_sel;
            wire signed [16*9-1:0] weight9_sel;

            // L1: same 1ch window is broadcast to 8 output-channel MAC9 blocks.
            // L2/L3: each MAC9 receives one input channel's 3x3 window.
            assign feature9_sel = (i_layer == 2'd1) ?
                                  i_l1_window :
                                  i_feature[ch*16*9 +: 16*9];

            assign weight9_sel  = i_weight[ch*16*9 +: 16*9];

            srcnn_mac9_sum u_mac9_sum (
                .i_feature9    (feature9_sel),
                .i_weight9     (weight9_sel),
                .o_sum_q16_16  (mac9_sum8[ch*40 +: 40])
            );
        end
    endgenerate

    //============================================================
    // Stage 1 register: MAC9 result
    //============================================================
    reg signed [40*8-1:0] mac9_sum8_r;

    always @(posedge i_clk) begin
        if (!i_rstn) begin
            mac9_sum8_r <= 0;
        end else if (i_valid) begin
            mac9_sum8_r <= mac9_sum8;
        end
    end

    //============================================================
    // Stage 2 combinational: L2/L3 adder_tree8
    //============================================================
    wire signed [47:0] l23_sum_q16_16_w;

    srcnn_adder_tree8 u_adder_tree8 (
        .i_sum8 (mac9_sum8_r),
        .o_sum  (l23_sum_q16_16_w)
    );

    //============================================================
    // Stage 2 register:
    //   - L1: each MAC9 sum is one output channel
    //   - L2/L3: 8 input-channel partial sums are accumulated
    //============================================================
    reg signed [48*8-1:0] l1_sum48_pack_r;
    reg signed [47:0]     l23_sum_q16_16_r;

    integer i;
    always @(posedge i_clk) begin
        if (!i_rstn) begin
            l1_sum48_pack_r  <= 0;
            l23_sum_q16_16_r <= 0;
        end else if (valid_pipe[0]) begin
            l23_sum_q16_16_r <= l23_sum_q16_16_w;

            for (i = 0; i < 8; i = i + 1) begin
                l1_sum48_pack_r[i*48 +: 48]
                    <= {{8{mac9_sum8_r[i*40 + 39]}}, mac9_sum8_r[i*40 +: 40]};
            end
        end
    end

    //============================================================
    // Stage 3 combinational: Q8.8 + Bias + ReLU
    //============================================================
    wire signed [15:0] l23_sum_q8_8_w;
    wire signed [15:0] l23_bias_added_w;
    wire signed [15:0] l23_relu_out_w;

    srcnn_q8_8 u_l23_q8_8 (
        .i_data (l23_sum_q16_16_r),
        .o_data (l23_sum_q8_8_w)
    );

    srcnn_bias_add u_l23_bias_add (
        .i_data (l23_sum_q8_8_w),
        .i_bias (bias_d2),
        .o_data (l23_bias_added_w)
    );

    srcnn_relu u_l23_relu (
        .i_data (l23_bias_added_w),
        .o_data (l23_relu_out_w)
    );

    wire signed [16*8-1:0] l1_result_pack_w;

    generate
        for (ch = 0; ch < 8; ch = ch + 1) begin : GEN_L1_POST
            wire signed [15:0] l1_q8_8_w;
            wire signed [15:0] l1_bias_w;
            wire signed [15:0] l1_bias_added_w;
            wire signed [15:0] l1_relu_out_w;

            assign l1_bias_w = l1_bias_pack_d2[ch*16 +: 16];

            srcnn_q8_8 u_l1_q8_8 (
                .i_data (l1_sum48_pack_r[ch*48 +: 48]),
                .o_data (l1_q8_8_w)
            );

            srcnn_bias_add u_l1_bias_add (
                .i_data (l1_q8_8_w),
                .i_bias (l1_bias_w),
                .o_data (l1_bias_added_w)
            );

            srcnn_relu u_l1_relu (
                .i_data (l1_bias_added_w),
                .o_data (l1_relu_out_w)
            );

            assign l1_result_pack_w[ch*16 +: 16] = l1_relu_out_w;
        end
    endgenerate

    //============================================================
    // Stage 3 register: final PU outputs
    //============================================================
    always @(posedge i_clk) begin
        if (!i_rstn) begin
            o_l1_result_pack <= 0;
            o_result         <= 0;
        end else if (valid_pipe[1]) begin
            o_l1_result_pack <= l1_result_pack_w;
            o_result         <= relu_en_d2 ? l23_relu_out_w : l23_bias_added_w;
        end
    end

endmodule
