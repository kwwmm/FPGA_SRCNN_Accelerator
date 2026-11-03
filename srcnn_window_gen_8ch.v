`timescale 1ns / 1ps

module srcnn_window_gen_8ch #(
    parameter IMG_W      = 150,
    parameter IMG_H      = 150,
    parameter DATA_WIDTH = 16
)(
    input  wire [7:0] i_out_row,
    input  wire [7:0] i_out_col,

    input  wire [1:0] i_top_line_sel,
    input  wire [1:0] i_mid_line_sel,
    input  wire [1:0] i_bot_line_sel,

    output wire [1:0] o_rd_line_sel0,
    output wire [1:0] o_rd_line_sel1,
    output wire [1:0] o_rd_line_sel2,
    output wire [1:0] o_rd_line_sel3,
    output wire [1:0] o_rd_line_sel4,
    output wire [1:0] o_rd_line_sel5,
    output wire [1:0] o_rd_line_sel6,
    output wire [1:0] o_rd_line_sel7,
    output wire [1:0] o_rd_line_sel8,

    output wire [7:0] o_rd_col0,
    output wire [7:0] o_rd_col1,
    output wire [7:0] o_rd_col2,
    output wire [7:0] o_rd_col3,
    output wire [7:0] o_rd_col4,
    output wire [7:0] o_rd_col5,
    output wire [7:0] o_rd_col6,
    output wire [7:0] o_rd_col7,
    output wire [7:0] o_rd_col8,

    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch0,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch1,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch2,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch3,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch4,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch5,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch6,
    input  wire signed [DATA_WIDTH*9-1:0] i_raw_ch7,

    output wire signed [DATA_WIDTH*72-1:0] o_feature
);

    wire [7:0] col_l;
    wire [7:0] col_c;
    wire [7:0] col_r;

    wire top_pad;
    wire bot_pad;
    wire left_pad;
    wire right_pad;

    assign col_l = (i_out_col == 8'd0)    ? 8'd0    : i_out_col - 8'd1;
    assign col_c = i_out_col;
    assign col_r = (i_out_col == IMG_W-1) ? IMG_W-1 : i_out_col + 8'd1;

    assign top_pad   = (i_out_row == 8'd0);
    assign bot_pad   = (i_out_row == IMG_H-1);
    assign left_pad  = (i_out_col == 8'd0);
    assign right_pad = (i_out_col == IMG_W-1);

    assign o_rd_line_sel0 = i_top_line_sel;
    assign o_rd_line_sel1 = i_top_line_sel;
    assign o_rd_line_sel2 = i_top_line_sel;

    assign o_rd_line_sel3 = i_mid_line_sel;
    assign o_rd_line_sel4 = i_mid_line_sel;
    assign o_rd_line_sel5 = i_mid_line_sel;

    assign o_rd_line_sel6 = i_bot_line_sel;
    assign o_rd_line_sel7 = i_bot_line_sel;
    assign o_rd_line_sel8 = i_bot_line_sel;

    assign o_rd_col0 = col_l;
    assign o_rd_col1 = col_c;
    assign o_rd_col2 = col_r;

    assign o_rd_col3 = col_l;
    assign o_rd_col4 = col_c;
    assign o_rd_col5 = col_r;

    assign o_rd_col6 = col_l;
    assign o_rd_col7 = col_c;
    assign o_rd_col8 = col_r;

    genvar ch;
    genvar k;

    generate
        for (ch = 0; ch < 8; ch = ch + 1) begin : GEN_CH
            for (k = 0; k < 9; k = k + 1) begin : GEN_K

                wire signed [DATA_WIDTH-1:0] raw_val;
                wire pad_en;

                if (ch == 0) begin : RAW_CH0
                    assign raw_val = i_raw_ch0[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else if (ch == 1) begin : RAW_CH1
                    assign raw_val = i_raw_ch1[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else if (ch == 2) begin : RAW_CH2
                    assign raw_val = i_raw_ch2[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else if (ch == 3) begin : RAW_CH3
                    assign raw_val = i_raw_ch3[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else if (ch == 4) begin : RAW_CH4
                    assign raw_val = i_raw_ch4[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else if (ch == 5) begin : RAW_CH5
                    assign raw_val = i_raw_ch5[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else if (ch == 6) begin : RAW_CH6
                    assign raw_val = i_raw_ch6[DATA_WIDTH*k +: DATA_WIDTH];
                end
                else begin : RAW_CH7
                    assign raw_val = i_raw_ch7[DATA_WIDTH*k +: DATA_WIDTH];
                end

                assign pad_en =
                    ((k == 0) && (top_pad || left_pad))   ||
                    ((k == 1) &&  top_pad)                ||
                    ((k == 2) && (top_pad || right_pad))  ||
                    ((k == 3) &&  left_pad)               ||
                    ((k == 5) &&  right_pad)              ||
                    ((k == 6) && (bot_pad || left_pad))   ||
                    ((k == 7) &&  bot_pad)                ||
                    ((k == 8) && (bot_pad || right_pad));

                assign o_feature[DATA_WIDTH*(ch*9+k) +: DATA_WIDTH] =
                    pad_en ? {DATA_WIDTH{1'b0}} : raw_val;

            end
        end
    endgenerate

endmodule