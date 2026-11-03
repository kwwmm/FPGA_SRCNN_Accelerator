`timescale 1ns / 1ps

module srcnn_line_buffer_8ch #(
    parameter IMG_W      = 150,
    parameter DATA_WIDTH = 16
)(
    input  wire                         i_clk,
    input  wire                         i_rstn,

    input  wire                         i_wr_en,
    input  wire [1:0]                   i_wr_line_sel,
    input  wire [7:0]                   i_wr_col,

    input  wire signed [DATA_WIDTH-1:0] i_wr_ch0,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch1,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch2,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch3,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch4,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch5,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch6,
    input  wire signed [DATA_WIDTH-1:0] i_wr_ch7,

    input  wire [1:0] i_rd_line_sel0,
    input  wire [1:0] i_rd_line_sel1,
    input  wire [1:0] i_rd_line_sel2,
    input  wire [1:0] i_rd_line_sel3,
    input  wire [1:0] i_rd_line_sel4,
    input  wire [1:0] i_rd_line_sel5,
    input  wire [1:0] i_rd_line_sel6,
    input  wire [1:0] i_rd_line_sel7,
    input  wire [1:0] i_rd_line_sel8,

    input  wire [7:0] i_rd_col0,
    input  wire [7:0] i_rd_col1,
    input  wire [7:0] i_rd_col2,
    input  wire [7:0] i_rd_col3,
    input  wire [7:0] i_rd_col4,
    input  wire [7:0] i_rd_col5,
    input  wire [7:0] i_rd_col6,
    input  wire [7:0] i_rd_col7,
    input  wire [7:0] i_rd_col8,

    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch0,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch1,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch2,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch3,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch4,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch5,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch6,
    output wire signed [DATA_WIDTH*9-1:0] o_raw_ch7
);

    srcnn_line_buffer_1ch u_lb_ch0 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch0),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch0[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch0[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch0[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch0[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch0[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch0[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch0[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch0[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch0[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch1 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch1),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch1[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch1[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch1[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch1[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch1[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch1[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch1[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch1[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch1[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch2 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch2),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch2[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch2[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch2[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch2[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch2[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch2[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch2[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch2[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch2[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch3 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch3),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch3[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch3[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch3[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch3[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch3[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch3[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch3[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch3[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch3[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch4 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch4),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch4[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch4[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch4[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch4[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch4[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch4[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch4[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch4[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch4[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch5 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch5),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch5[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch5[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch5[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch5[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch5[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch5[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch5[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch5[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch5[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch6 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch6),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch6[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch6[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch6[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch6[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch6[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch6[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch6[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch6[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch6[DATA_WIDTH*8 +: DATA_WIDTH])
    );

    srcnn_line_buffer_1ch u_lb_ch7 (
        .i_clk(i_clk), .i_rstn(i_rstn),
        .i_wr_en(i_wr_en), .i_wr_line_sel(i_wr_line_sel), .i_wr_col(i_wr_col),
        .i_wr_data(i_wr_ch7),

        .i_rd_line_sel0(i_rd_line_sel0), .i_rd_line_sel1(i_rd_line_sel1), .i_rd_line_sel2(i_rd_line_sel2),
        .i_rd_line_sel3(i_rd_line_sel3), .i_rd_line_sel4(i_rd_line_sel4), .i_rd_line_sel5(i_rd_line_sel5),
        .i_rd_line_sel6(i_rd_line_sel6), .i_rd_line_sel7(i_rd_line_sel7), .i_rd_line_sel8(i_rd_line_sel8),

        .i_rd_col0(i_rd_col0), .i_rd_col1(i_rd_col1), .i_rd_col2(i_rd_col2),
        .i_rd_col3(i_rd_col3), .i_rd_col4(i_rd_col4), .i_rd_col5(i_rd_col5),
        .i_rd_col6(i_rd_col6), .i_rd_col7(i_rd_col7), .i_rd_col8(i_rd_col8),

        .o_rd_data0(o_raw_ch7[DATA_WIDTH*0 +: DATA_WIDTH]),
        .o_rd_data1(o_raw_ch7[DATA_WIDTH*1 +: DATA_WIDTH]),
        .o_rd_data2(o_raw_ch7[DATA_WIDTH*2 +: DATA_WIDTH]),
        .o_rd_data3(o_raw_ch7[DATA_WIDTH*3 +: DATA_WIDTH]),
        .o_rd_data4(o_raw_ch7[DATA_WIDTH*4 +: DATA_WIDTH]),
        .o_rd_data5(o_raw_ch7[DATA_WIDTH*5 +: DATA_WIDTH]),
        .o_rd_data6(o_raw_ch7[DATA_WIDTH*6 +: DATA_WIDTH]),
        .o_rd_data7(o_raw_ch7[DATA_WIDTH*7 +: DATA_WIDTH]),
        .o_rd_data8(o_raw_ch7[DATA_WIDTH*8 +: DATA_WIDTH])
    );

endmodule