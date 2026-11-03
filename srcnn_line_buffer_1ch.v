`timescale 1ns / 1ps

module srcnn_line_buffer_1ch #(
    parameter IMG_W      = 150,
    parameter DATA_WIDTH = 16
)(
    input  wire                         i_clk,
    input  wire                         i_rstn,

    input  wire                         i_wr_en,
    input  wire [1:0]                   i_wr_line_sel,
    input  wire [7:0]                   i_wr_col,
    input  wire signed [DATA_WIDTH-1:0] i_wr_data,

    input  wire [1:0]                   i_rd_line_sel0,
    input  wire [1:0]                   i_rd_line_sel1,
    input  wire [1:0]                   i_rd_line_sel2,
    input  wire [1:0]                   i_rd_line_sel3,
    input  wire [1:0]                   i_rd_line_sel4,
    input  wire [1:0]                   i_rd_line_sel5,
    input  wire [1:0]                   i_rd_line_sel6,
    input  wire [1:0]                   i_rd_line_sel7,
    input  wire [1:0]                   i_rd_line_sel8,

    input  wire [7:0]                   i_rd_col0,
    input  wire [7:0]                   i_rd_col1,
    input  wire [7:0]                   i_rd_col2,
    input  wire [7:0]                   i_rd_col3,
    input  wire [7:0]                   i_rd_col4,
    input  wire [7:0]                   i_rd_col5,
    input  wire [7:0]                   i_rd_col6,
    input  wire [7:0]                   i_rd_col7,
    input  wire [7:0]                   i_rd_col8,

    output wire signed [DATA_WIDTH-1:0] o_rd_data0,
    output wire signed [DATA_WIDTH-1:0] o_rd_data1,
    output wire signed [DATA_WIDTH-1:0] o_rd_data2,
    output wire signed [DATA_WIDTH-1:0] o_rd_data3,
    output wire signed [DATA_WIDTH-1:0] o_rd_data4,
    output wire signed [DATA_WIDTH-1:0] o_rd_data5,
    output wire signed [DATA_WIDTH-1:0] o_rd_data6,
    output wire signed [DATA_WIDTH-1:0] o_rd_data7,
    output wire signed [DATA_WIDTH-1:0] o_rd_data8
);

    reg signed [DATA_WIDTH-1:0] line0 [0:IMG_W-1];
    reg signed [DATA_WIDTH-1:0] line1 [0:IMG_W-1];
    reg signed [DATA_WIDTH-1:0] line2 [0:IMG_W-1];

    integer i;

	always @(posedge i_clk) begin
		if (i_wr_en) begin
			case (i_wr_line_sel)
				2'd0: line0[i_wr_col] <= i_wr_data;
				2'd1: line1[i_wr_col] <= i_wr_data;
				2'd2: line2[i_wr_col] <= i_wr_data;
			endcase
		end
	end
    assign o_rd_data0 =
        (i_rd_line_sel0 == 2'd0) ? line0[i_rd_col0] :
        (i_rd_line_sel0 == 2'd1) ? line1[i_rd_col0] :
        (i_rd_line_sel0 == 2'd2) ? line2[i_rd_col0] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data1 =
        (i_rd_line_sel1 == 2'd0) ? line0[i_rd_col1] :
        (i_rd_line_sel1 == 2'd1) ? line1[i_rd_col1] :
        (i_rd_line_sel1 == 2'd2) ? line2[i_rd_col1] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data2 =
        (i_rd_line_sel2 == 2'd0) ? line0[i_rd_col2] :
        (i_rd_line_sel2 == 2'd1) ? line1[i_rd_col2] :
        (i_rd_line_sel2 == 2'd2) ? line2[i_rd_col2] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data3 =
        (i_rd_line_sel3 == 2'd0) ? line0[i_rd_col3] :
        (i_rd_line_sel3 == 2'd1) ? line1[i_rd_col3] :
        (i_rd_line_sel3 == 2'd2) ? line2[i_rd_col3] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data4 =
        (i_rd_line_sel4 == 2'd0) ? line0[i_rd_col4] :
        (i_rd_line_sel4 == 2'd1) ? line1[i_rd_col4] :
        (i_rd_line_sel4 == 2'd2) ? line2[i_rd_col4] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data5 =
        (i_rd_line_sel5 == 2'd0) ? line0[i_rd_col5] :
        (i_rd_line_sel5 == 2'd1) ? line1[i_rd_col5] :
        (i_rd_line_sel5 == 2'd2) ? line2[i_rd_col5] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data6 =
        (i_rd_line_sel6 == 2'd0) ? line0[i_rd_col6] :
        (i_rd_line_sel6 == 2'd1) ? line1[i_rd_col6] :
        (i_rd_line_sel6 == 2'd2) ? line2[i_rd_col6] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data7 =
        (i_rd_line_sel7 == 2'd0) ? line0[i_rd_col7] :
        (i_rd_line_sel7 == 2'd1) ? line1[i_rd_col7] :
        (i_rd_line_sel7 == 2'd2) ? line2[i_rd_col7] :
                                   {DATA_WIDTH{1'b0}};

    assign o_rd_data8 =
        (i_rd_line_sel8 == 2'd0) ? line0[i_rd_col8] :
        (i_rd_line_sel8 == 2'd1) ? line1[i_rd_col8] :
        (i_rd_line_sel8 == 2'd2) ? line2[i_rd_col8] :
                                   {DATA_WIDTH{1'b0}};

endmodule