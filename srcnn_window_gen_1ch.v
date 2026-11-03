`timescale 1ns / 1ps

module srcnn_window_gen_1ch #(
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

    input  wire signed [DATA_WIDTH-1:0] i_data0,
    input  wire signed [DATA_WIDTH-1:0] i_data1,
    input  wire signed [DATA_WIDTH-1:0] i_data2,
    input  wire signed [DATA_WIDTH-1:0] i_data3,
    input  wire signed [DATA_WIDTH-1:0] i_data4,
    input  wire signed [DATA_WIDTH-1:0] i_data5,
    input  wire signed [DATA_WIDTH-1:0] i_data6,
    input  wire signed [DATA_WIDTH-1:0] i_data7,
    input  wire signed [DATA_WIDTH-1:0] i_data8,

    output wire signed [DATA_WIDTH*9-1:0] o_window
);

    wire [7:0] col_l;
    wire [7:0] col_c;
    wire [7:0] col_r;

    wire top_pad;
    wire bot_pad;
    wire left_pad;
    wire right_pad;

    assign col_l = (i_out_col == 8'd0)       ? 8'd0    : i_out_col - 8'd1;
    assign col_c = i_out_col;
    assign col_r = (i_out_col == IMG_W-1)    ? IMG_W-1 : i_out_col + 8'd1;

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

    assign o_window[DATA_WIDTH*0 +: DATA_WIDTH] =
        (top_pad || left_pad) ? {DATA_WIDTH{1'b0}} : i_data0;

    assign o_window[DATA_WIDTH*1 +: DATA_WIDTH] =
        (top_pad) ? {DATA_WIDTH{1'b0}} : i_data1;

    assign o_window[DATA_WIDTH*2 +: DATA_WIDTH] =
        (top_pad || right_pad) ? {DATA_WIDTH{1'b0}} : i_data2;

    assign o_window[DATA_WIDTH*3 +: DATA_WIDTH] =
        (left_pad) ? {DATA_WIDTH{1'b0}} : i_data3;

    assign o_window[DATA_WIDTH*4 +: DATA_WIDTH] =
        i_data4;

    assign o_window[DATA_WIDTH*5 +: DATA_WIDTH] =
        (right_pad) ? {DATA_WIDTH{1'b0}} : i_data5;

    assign o_window[DATA_WIDTH*6 +: DATA_WIDTH] =
        (bot_pad || left_pad) ? {DATA_WIDTH{1'b0}} : i_data6;

    assign o_window[DATA_WIDTH*7 +: DATA_WIDTH] =
        (bot_pad) ? {DATA_WIDTH{1'b0}} : i_data7;

    assign o_window[DATA_WIDTH*8 +: DATA_WIDTH] =
        (bot_pad || right_pad) ? {DATA_WIDTH{1'b0}} : i_data8;

endmodule