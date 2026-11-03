`timescale 1ns / 1ps

module SRCNN #(
    parameter IN_ADDR_WIDTH = 17,
    parameter IN_WIDTH      = 16
)(
    input  wire                     i_clk,
    input  wire                     i_rstn,
    input  wire                     i_start,

    output wire                     o_done,
    output wire                     output_bram_wen,
    output wire [IN_ADDR_WIDTH-1:0] output_bram_waddr,
    output wire [IN_WIDTH-1:0]      L3_p_out
);

    wire [1:0] layer;
    wire [1:0] img_idx;

    wire [IN_ADDR_WIDTH-1:0] input_rd_addr;
    wire [14:0] f1_rd_addr;
    wire [14:0] f2_rd_addr;

    wire lb_wr_en;
    wire [1:0] lb_wr_line_sel;
    wire [7:0] lb_wr_col;

    wire [7:0] out_row;
    wire [7:0] out_col;

    wire [1:0] top_line_sel;
    wire [1:0] mid_line_sel;
    wire [1:0] bot_line_sel;

    wire [9:0] weight_base_addr;
    wire [4:0] bias_addr;
    wire relu_en;

    wire f1_we;
    wire [2:0] f1_wr_ch;
    wire [14:0] f1_wr_addr;

    wire f2_we;
    wire [2:0] f2_wr_ch;
    wire [14:0] f2_wr_addr;

    wire out_we;
    wire [14:0] out_wr_addr;

    srcnn_controller u_controller (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_start(i_start),

        .o_img_idx(img_idx),
        .o_layer(layer),

        .o_input_rd_addr(input_rd_addr),
        .o_f1_rd_addr(f1_rd_addr),
        .o_f2_rd_addr(f2_rd_addr),

        .o_lb_wr_en(lb_wr_en),
        .o_lb_wr_line_sel(lb_wr_line_sel),
        .o_lb_wr_col(lb_wr_col),

        .o_out_row(out_row),
        .o_out_col(out_col),

        .o_top_line_sel(top_line_sel),
        .o_mid_line_sel(mid_line_sel),
        .o_bot_line_sel(bot_line_sel),

        .o_weight_base_addr(weight_base_addr),
        .o_bias_addr(bias_addr),
        .o_relu_en(relu_en),

        .o_f1_we(f1_we),
        .o_f1_wr_ch(f1_wr_ch),
        .o_f1_wr_addr(f1_wr_addr),

        .o_f2_we(f2_we),
        .o_f2_wr_ch(f2_wr_ch),
        .o_f2_wr_addr(f2_wr_addr),

        .o_out_we(out_we),
        .o_out_wr_addr(out_wr_addr),

        .o_done(o_done)
    );

    //==================================================
    // input memory
    //==================================================
    wire signed [15:0] input_data;
    wire [IN_ADDR_WIDTH-1:0] input_addr_img;

    assign input_addr_img = img_idx * 17'd22500 + input_rd_addr;

    srcnn_input_mem u_input_mem (
        .i_clk(i_clk),
        .i_rd_addr(input_addr_img),
        .o_rd_data(input_data)
    );

    //==================================================
    // feature memories
    //==================================================
    wire signed [15:0] f1_ch0, f1_ch1, f1_ch2, f1_ch3;
    wire signed [15:0] f1_ch4, f1_ch5, f1_ch6, f1_ch7;

    wire signed [15:0] f2_ch0, f2_ch1, f2_ch2, f2_ch3;
    wire signed [15:0] f2_ch4, f2_ch5, f2_ch6, f2_ch7;

    wire signed [16*8-1:0] pu_l1_result_pack;
    wire signed [15:0]     pu_result;

    //==================================================
    // PU pipeline valid and delayed write controls
    // PU output is registered after 3 cycles.
    // Therefore memory write enable/address/channel must be delayed 3 cycles.
    //==================================================
    wire pu_in_valid;
    wire pu_valid;

    assign pu_in_valid = f1_we | f2_we | out_we;

    reg        f1_we_d1,  f1_we_d2,  f1_we_d3;
    reg        f2_we_d1,  f2_we_d2,  f2_we_d3;
    reg        out_we_d1, out_we_d2, out_we_d3;

    reg [14:0] f1_wr_addr_d1,  f1_wr_addr_d2,  f1_wr_addr_d3;
    reg [14:0] f2_wr_addr_d1,  f2_wr_addr_d2,  f2_wr_addr_d3;
    reg [14:0] out_wr_addr_d1, out_wr_addr_d2, out_wr_addr_d3;

    reg [2:0]  f1_wr_ch_d1, f1_wr_ch_d2, f1_wr_ch_d3;
    reg [2:0]  f2_wr_ch_d1, f2_wr_ch_d2, f2_wr_ch_d3;

    reg [1:0]  img_idx_d1, img_idx_d2, img_idx_d3;

    always @(posedge i_clk) begin
        if (!i_rstn) begin
            f1_we_d1  <= 1'b0; f1_we_d2  <= 1'b0; f1_we_d3  <= 1'b0;
            f2_we_d1  <= 1'b0; f2_we_d2  <= 1'b0; f2_we_d3  <= 1'b0;
            out_we_d1 <= 1'b0; out_we_d2 <= 1'b0; out_we_d3 <= 1'b0;

            f1_wr_addr_d1  <= 15'd0; f1_wr_addr_d2  <= 15'd0; f1_wr_addr_d3  <= 15'd0;
            f2_wr_addr_d1  <= 15'd0; f2_wr_addr_d2  <= 15'd0; f2_wr_addr_d3  <= 15'd0;
            out_wr_addr_d1 <= 15'd0; out_wr_addr_d2 <= 15'd0; out_wr_addr_d3 <= 15'd0;

            f1_wr_ch_d1 <= 3'd0; f1_wr_ch_d2 <= 3'd0; f1_wr_ch_d3 <= 3'd0;
            f2_wr_ch_d1 <= 3'd0; f2_wr_ch_d2 <= 3'd0; f2_wr_ch_d3 <= 3'd0;

            img_idx_d1 <= 2'd0; img_idx_d2 <= 2'd0; img_idx_d3 <= 2'd0;
        end else begin
            f1_we_d1  <= f1_we;
            f1_we_d2  <= f1_we_d1;
            f1_we_d3  <= f1_we_d2;

            f2_we_d1  <= f2_we;
            f2_we_d2  <= f2_we_d1;
            f2_we_d3  <= f2_we_d2;

            out_we_d1 <= out_we;
            out_we_d2 <= out_we_d1;
            out_we_d3 <= out_we_d2;

            f1_wr_addr_d1  <= f1_wr_addr;
            f1_wr_addr_d2  <= f1_wr_addr_d1;
            f1_wr_addr_d3  <= f1_wr_addr_d2;

            f2_wr_addr_d1  <= f2_wr_addr;
            f2_wr_addr_d2  <= f2_wr_addr_d1;
            f2_wr_addr_d3  <= f2_wr_addr_d2;

            out_wr_addr_d1 <= out_wr_addr;
            out_wr_addr_d2 <= out_wr_addr_d1;
            out_wr_addr_d3 <= out_wr_addr_d2;

            f1_wr_ch_d1 <= f1_wr_ch;
            f1_wr_ch_d2 <= f1_wr_ch_d1;
            f1_wr_ch_d3 <= f1_wr_ch_d2;

            f2_wr_ch_d1 <= f2_wr_ch;
            f2_wr_ch_d2 <= f2_wr_ch_d1;
            f2_wr_ch_d3 <= f2_wr_ch_d2;

            img_idx_d1 <= img_idx;
            img_idx_d2 <= img_idx_d1;
            img_idx_d3 <= img_idx_d2;
        end
    end


    // ============================================================
    // In-place feature-map reuse
    // ------------------------------------------------------------
    // L1 stores F1 into feature1_mem as an 8-channel packed pixel.
    // L2 no longer writes feature2_mem. Instead, the delayed L2 result
    // overwrites feature1_mem one channel at a time at the same pixel
    // address. This is safe for this controller because L2 consumes F1
    // through its own 3-row line buffer; once a row has been loaded into
    // that line buffer, the original row in feature1_mem is no longer
    // needed for future L2 windows.
    //
    // During L3, the controller still drives o_f2_rd_addr.  We reuse
    // that address to read the overwritten F2 values from feature1_mem.
    // ============================================================
    wire [14:0] f1_mem_rd_addr;
    assign f1_mem_rd_addr = (layer == 2'd3) ? f2_rd_addr : f1_rd_addr;

    // ============================================================
    // L2 in-place full-pack write collector
    // ------------------------------------------------------------
    // UltraRAM does not infer well when a packed memory is updated
    // by bit-select / channel-select writes. Therefore, L2 results
    // are collected into a 128-bit register for ch0~ch7 and written
    // back to feature1_mem only once when ch7 arrives.
    // ============================================================
    reg signed [16*8-1:0] l2_result_pack_r;

    wire signed [16*8-1:0] l2_result_pack_next =
        (f2_wr_ch_d3 == 3'd0) ? {l2_result_pack_r[127:16],  pu_result} :
        (f2_wr_ch_d3 == 3'd1) ? {l2_result_pack_r[127:32],  pu_result, l2_result_pack_r[15:0]} :
        (f2_wr_ch_d3 == 3'd2) ? {l2_result_pack_r[127:48],  pu_result, l2_result_pack_r[31:0]} :
        (f2_wr_ch_d3 == 3'd3) ? {l2_result_pack_r[127:64],  pu_result, l2_result_pack_r[47:0]} :
        (f2_wr_ch_d3 == 3'd4) ? {l2_result_pack_r[127:80],  pu_result, l2_result_pack_r[63:0]} :
        (f2_wr_ch_d3 == 3'd5) ? {l2_result_pack_r[127:96],  pu_result, l2_result_pack_r[79:0]} :
        (f2_wr_ch_d3 == 3'd6) ? {l2_result_pack_r[127:112], pu_result, l2_result_pack_r[95:0]} :
                                  {pu_result, l2_result_pack_r[111:0]};

    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            l2_result_pack_r <= {128{1'b0}};
        end
        else if (f2_we_d3) begin
            l2_result_pack_r <= l2_result_pack_next;
        end
    end

    wire        f1_full_we       = f1_we_d3 | (f2_we_d3 & (f2_wr_ch_d3 == 3'd7));
    wire [14:0] f1_full_wr_addr  = f1_we_d3 ? f1_wr_addr_d3 : f2_wr_addr_d3;
    wire signed [16*8-1:0] f1_full_wr_pack =
        f1_we_d3 ? pu_l1_result_pack : l2_result_pack_next;

    srcnn_feature1_mem u_f1_mem (
        .i_clk(i_clk),
        .i_we(1'b0),
        .i_we_all(f1_full_we),
        .i_wr_ch(3'd0),
        .i_wr_addr(f1_full_wr_addr),
        .i_wr_data(16'sd0),
        .i_wr_data_pack(f1_full_wr_pack),

        .i_rd_addr(f1_mem_rd_addr),

        .o_rd_ch0(f1_ch0),
        .o_rd_ch1(f1_ch1),
        .o_rd_ch2(f1_ch2),
        .o_rd_ch3(f1_ch3),
        .o_rd_ch4(f1_ch4),
        .o_rd_ch5(f1_ch5),
        .o_rd_ch6(f1_ch6),
        .o_rd_ch7(f1_ch7)
    );

    // feature2_mem removed: during L3, f2_ch* aliases the F2 data
    // that has been overwritten into feature1_mem.
    assign f2_ch0 = f1_ch0;
    assign f2_ch1 = f1_ch1;
    assign f2_ch2 = f1_ch2;
    assign f2_ch3 = f1_ch3;
    assign f2_ch4 = f1_ch4;
    assign f2_ch5 = f1_ch5;
    assign f2_ch6 = f1_ch6;
    assign f2_ch7 = f1_ch7;


    //==================================================
    // common window read wires
    //==================================================
    wire [1:0] rd_line_sel0, rd_line_sel1, rd_line_sel2;
    wire [1:0] rd_line_sel3, rd_line_sel4, rd_line_sel5;
    wire [1:0] rd_line_sel6, rd_line_sel7, rd_line_sel8;

    wire [7:0] rd_col0, rd_col1, rd_col2;
    wire [7:0] rd_col3, rd_col4, rd_col5;
    wire [7:0] rd_col6, rd_col7, rd_col8;

    //==================================================
    // L1: 1ch line buffer + window_gen_1ch
    //==================================================
    wire signed [15:0] l1_d0, l1_d1, l1_d2;
    wire signed [15:0] l1_d3, l1_d4, l1_d5;
    wire signed [15:0] l1_d6, l1_d7, l1_d8;

    wire signed [16*9-1:0]  l1_window;

    wire [1:0] l1_rd_line_sel0, l1_rd_line_sel1, l1_rd_line_sel2;
    wire [1:0] l1_rd_line_sel3, l1_rd_line_sel4, l1_rd_line_sel5;
    wire [1:0] l1_rd_line_sel6, l1_rd_line_sel7, l1_rd_line_sel8;

    wire [7:0] l1_rd_col0, l1_rd_col1, l1_rd_col2;
    wire [7:0] l1_rd_col3, l1_rd_col4, l1_rd_col5;
    wire [7:0] l1_rd_col6, l1_rd_col7, l1_rd_col8;

    srcnn_window_gen_1ch u_l1_window_gen (
        .i_out_row(out_row),
        .i_out_col(out_col),

        .i_top_line_sel(top_line_sel),
        .i_mid_line_sel(mid_line_sel),
        .i_bot_line_sel(bot_line_sel),

        .o_rd_line_sel0(l1_rd_line_sel0),
        .o_rd_line_sel1(l1_rd_line_sel1),
        .o_rd_line_sel2(l1_rd_line_sel2),
        .o_rd_line_sel3(l1_rd_line_sel3),
        .o_rd_line_sel4(l1_rd_line_sel4),
        .o_rd_line_sel5(l1_rd_line_sel5),
        .o_rd_line_sel6(l1_rd_line_sel6),
        .o_rd_line_sel7(l1_rd_line_sel7),
        .o_rd_line_sel8(l1_rd_line_sel8),

        .o_rd_col0(l1_rd_col0),
        .o_rd_col1(l1_rd_col1),
        .o_rd_col2(l1_rd_col2),
        .o_rd_col3(l1_rd_col3),
        .o_rd_col4(l1_rd_col4),
        .o_rd_col5(l1_rd_col5),
        .o_rd_col6(l1_rd_col6),
        .o_rd_col7(l1_rd_col7),
        .o_rd_col8(l1_rd_col8),

        .i_data0(l1_d0),
        .i_data1(l1_d1),
        .i_data2(l1_d2),
        .i_data3(l1_d3),
        .i_data4(l1_d4),
        .i_data5(l1_d5),
        .i_data6(l1_d6),
        .i_data7(l1_d7),
        .i_data8(l1_d8),

        .o_window(l1_window)
    );

    srcnn_line_buffer_1ch u_l1_lb (
        .i_clk(i_clk),
        .i_rstn(i_rstn),

        .i_wr_en(lb_wr_en && layer == 2'd1),
        .i_wr_line_sel(lb_wr_line_sel),
        .i_wr_col(lb_wr_col),
        .i_wr_data(input_data),

        .i_rd_line_sel0(l1_rd_line_sel0),
        .i_rd_line_sel1(l1_rd_line_sel1),
        .i_rd_line_sel2(l1_rd_line_sel2),
        .i_rd_line_sel3(l1_rd_line_sel3),
        .i_rd_line_sel4(l1_rd_line_sel4),
        .i_rd_line_sel5(l1_rd_line_sel5),
        .i_rd_line_sel6(l1_rd_line_sel6),
        .i_rd_line_sel7(l1_rd_line_sel7),
        .i_rd_line_sel8(l1_rd_line_sel8),

        .i_rd_col0(l1_rd_col0),
        .i_rd_col1(l1_rd_col1),
        .i_rd_col2(l1_rd_col2),
        .i_rd_col3(l1_rd_col3),
        .i_rd_col4(l1_rd_col4),
        .i_rd_col5(l1_rd_col5),
        .i_rd_col6(l1_rd_col6),
        .i_rd_col7(l1_rd_col7),
        .i_rd_col8(l1_rd_col8),

        .o_rd_data0(l1_d0),
        .o_rd_data1(l1_d1),
        .o_rd_data2(l1_d2),
        .o_rd_data3(l1_d3),
        .o_rd_data4(l1_d4),
        .o_rd_data5(l1_d5),
        .o_rd_data6(l1_d6),
        .o_rd_data7(l1_d7),
        .o_rd_data8(l1_d8)
    );

    //==================================================
    // L2: 8ch line buffer + window_gen_8ch
    //==================================================
    wire signed [16*9-1:0] l2_raw_ch0, l2_raw_ch1, l2_raw_ch2, l2_raw_ch3;
    wire signed [16*9-1:0] l2_raw_ch4, l2_raw_ch5, l2_raw_ch6, l2_raw_ch7;
    wire signed [16*72-1:0] l2_feature;

    wire [1:0] l2_rd_line_sel0, l2_rd_line_sel1, l2_rd_line_sel2;
    wire [1:0] l2_rd_line_sel3, l2_rd_line_sel4, l2_rd_line_sel5;
    wire [1:0] l2_rd_line_sel6, l2_rd_line_sel7, l2_rd_line_sel8;

    wire [7:0] l2_rd_col0, l2_rd_col1, l2_rd_col2;
    wire [7:0] l2_rd_col3, l2_rd_col4, l2_rd_col5;
    wire [7:0] l2_rd_col6, l2_rd_col7, l2_rd_col8;

    srcnn_window_gen_8ch u_l2_window_gen (
        .i_out_row(out_row),
        .i_out_col(out_col),

        .i_top_line_sel(top_line_sel),
        .i_mid_line_sel(mid_line_sel),
        .i_bot_line_sel(bot_line_sel),

        .o_rd_line_sel0(l2_rd_line_sel0),
        .o_rd_line_sel1(l2_rd_line_sel1),
        .o_rd_line_sel2(l2_rd_line_sel2),
        .o_rd_line_sel3(l2_rd_line_sel3),
        .o_rd_line_sel4(l2_rd_line_sel4),
        .o_rd_line_sel5(l2_rd_line_sel5),
        .o_rd_line_sel6(l2_rd_line_sel6),
        .o_rd_line_sel7(l2_rd_line_sel7),
        .o_rd_line_sel8(l2_rd_line_sel8),

        .o_rd_col0(l2_rd_col0),
        .o_rd_col1(l2_rd_col1),
        .o_rd_col2(l2_rd_col2),
        .o_rd_col3(l2_rd_col3),
        .o_rd_col4(l2_rd_col4),
        .o_rd_col5(l2_rd_col5),
        .o_rd_col6(l2_rd_col6),
        .o_rd_col7(l2_rd_col7),
        .o_rd_col8(l2_rd_col8),

        .i_raw_ch0(l2_raw_ch0),
        .i_raw_ch1(l2_raw_ch1),
        .i_raw_ch2(l2_raw_ch2),
        .i_raw_ch3(l2_raw_ch3),
        .i_raw_ch4(l2_raw_ch4),
        .i_raw_ch5(l2_raw_ch5),
        .i_raw_ch6(l2_raw_ch6),
        .i_raw_ch7(l2_raw_ch7),

        .o_feature(l2_feature)
    );

    srcnn_line_buffer_8ch u_l2_lb (
        .i_clk(i_clk),
        .i_rstn(i_rstn),

        .i_wr_en(lb_wr_en && layer == 2'd2),
        .i_wr_line_sel(lb_wr_line_sel),
        .i_wr_col(lb_wr_col),

        .i_wr_ch0(f1_ch0),
        .i_wr_ch1(f1_ch1),
        .i_wr_ch2(f1_ch2),
        .i_wr_ch3(f1_ch3),
        .i_wr_ch4(f1_ch4),
        .i_wr_ch5(f1_ch5),
        .i_wr_ch6(f1_ch6),
        .i_wr_ch7(f1_ch7),

        .i_rd_line_sel0(l2_rd_line_sel0),
        .i_rd_line_sel1(l2_rd_line_sel1),
        .i_rd_line_sel2(l2_rd_line_sel2),
        .i_rd_line_sel3(l2_rd_line_sel3),
        .i_rd_line_sel4(l2_rd_line_sel4),
        .i_rd_line_sel5(l2_rd_line_sel5),
        .i_rd_line_sel6(l2_rd_line_sel6),
        .i_rd_line_sel7(l2_rd_line_sel7),
        .i_rd_line_sel8(l2_rd_line_sel8),

        .i_rd_col0(l2_rd_col0),
        .i_rd_col1(l2_rd_col1),
        .i_rd_col2(l2_rd_col2),
        .i_rd_col3(l2_rd_col3),
        .i_rd_col4(l2_rd_col4),
        .i_rd_col5(l2_rd_col5),
        .i_rd_col6(l2_rd_col6),
        .i_rd_col7(l2_rd_col7),
        .i_rd_col8(l2_rd_col8),

        .o_raw_ch0(l2_raw_ch0),
        .o_raw_ch1(l2_raw_ch1),
        .o_raw_ch2(l2_raw_ch2),
        .o_raw_ch3(l2_raw_ch3),
        .o_raw_ch4(l2_raw_ch4),
        .o_raw_ch5(l2_raw_ch5),
        .o_raw_ch6(l2_raw_ch6),
        .o_raw_ch7(l2_raw_ch7)
    );

    //==================================================
    // L3: 8ch line buffer + window_gen_8ch
    //==================================================
    wire signed [16*9-1:0] l3_raw_ch0, l3_raw_ch1, l3_raw_ch2, l3_raw_ch3;
    wire signed [16*9-1:0] l3_raw_ch4, l3_raw_ch5, l3_raw_ch6, l3_raw_ch7;
    wire signed [16*72-1:0] l3_feature;

    wire [1:0] l3_rd_line_sel0, l3_rd_line_sel1, l3_rd_line_sel2;
    wire [1:0] l3_rd_line_sel3, l3_rd_line_sel4, l3_rd_line_sel5;
    wire [1:0] l3_rd_line_sel6, l3_rd_line_sel7, l3_rd_line_sel8;

    wire [7:0] l3_rd_col0, l3_rd_col1, l3_rd_col2;
    wire [7:0] l3_rd_col3, l3_rd_col4, l3_rd_col5;
    wire [7:0] l3_rd_col6, l3_rd_col7, l3_rd_col8;

    srcnn_window_gen_8ch u_l3_window_gen (
        .i_out_row(out_row),
        .i_out_col(out_col),

        .i_top_line_sel(top_line_sel),
        .i_mid_line_sel(mid_line_sel),
        .i_bot_line_sel(bot_line_sel),

        .o_rd_line_sel0(l3_rd_line_sel0),
        .o_rd_line_sel1(l3_rd_line_sel1),
        .o_rd_line_sel2(l3_rd_line_sel2),
        .o_rd_line_sel3(l3_rd_line_sel3),
        .o_rd_line_sel4(l3_rd_line_sel4),
        .o_rd_line_sel5(l3_rd_line_sel5),
        .o_rd_line_sel6(l3_rd_line_sel6),
        .o_rd_line_sel7(l3_rd_line_sel7),
        .o_rd_line_sel8(l3_rd_line_sel8),

        .o_rd_col0(l3_rd_col0),
        .o_rd_col1(l3_rd_col1),
        .o_rd_col2(l3_rd_col2),
        .o_rd_col3(l3_rd_col3),
        .o_rd_col4(l3_rd_col4),
        .o_rd_col5(l3_rd_col5),
        .o_rd_col6(l3_rd_col6),
        .o_rd_col7(l3_rd_col7),
        .o_rd_col8(l3_rd_col8),

        .i_raw_ch0(l3_raw_ch0),
        .i_raw_ch1(l3_raw_ch1),
        .i_raw_ch2(l3_raw_ch2),
        .i_raw_ch3(l3_raw_ch3),
        .i_raw_ch4(l3_raw_ch4),
        .i_raw_ch5(l3_raw_ch5),
        .i_raw_ch6(l3_raw_ch6),
        .i_raw_ch7(l3_raw_ch7),

        .o_feature(l3_feature)
    );

    srcnn_line_buffer_8ch u_l3_lb (
        .i_clk(i_clk),
        .i_rstn(i_rstn),

        .i_wr_en(lb_wr_en && layer == 2'd3),
        .i_wr_line_sel(lb_wr_line_sel),
        .i_wr_col(lb_wr_col),

        .i_wr_ch0(f2_ch0),
        .i_wr_ch1(f2_ch1),
        .i_wr_ch2(f2_ch2),
        .i_wr_ch3(f2_ch3),
        .i_wr_ch4(f2_ch4),
        .i_wr_ch5(f2_ch5),
        .i_wr_ch6(f2_ch6),
        .i_wr_ch7(f2_ch7),

        .i_rd_line_sel0(l3_rd_line_sel0),
        .i_rd_line_sel1(l3_rd_line_sel1),
        .i_rd_line_sel2(l3_rd_line_sel2),
        .i_rd_line_sel3(l3_rd_line_sel3),
        .i_rd_line_sel4(l3_rd_line_sel4),
        .i_rd_line_sel5(l3_rd_line_sel5),
        .i_rd_line_sel6(l3_rd_line_sel6),
        .i_rd_line_sel7(l3_rd_line_sel7),
        .i_rd_line_sel8(l3_rd_line_sel8),

        .i_rd_col0(l3_rd_col0),
        .i_rd_col1(l3_rd_col1),
        .i_rd_col2(l3_rd_col2),
        .i_rd_col3(l3_rd_col3),
        .i_rd_col4(l3_rd_col4),
        .i_rd_col5(l3_rd_col5),
        .i_rd_col6(l3_rd_col6),
        .i_rd_col7(l3_rd_col7),
        .i_rd_col8(l3_rd_col8),

        .o_raw_ch0(l3_raw_ch0),
        .o_raw_ch1(l3_raw_ch1),
        .o_raw_ch2(l3_raw_ch2),
        .o_raw_ch3(l3_raw_ch3),
        .o_raw_ch4(l3_raw_ch4),
        .o_raw_ch5(l3_raw_ch5),
        .o_raw_ch6(l3_raw_ch6),
        .o_raw_ch7(l3_raw_ch7)
    );

    //==================================================
    // PU input mux
    //==================================================
    wire signed [16*72-1:0] pu_feature;

    assign pu_feature =
        (layer == 2'd2) ? l2_feature :
        (layer == 2'd3) ? l3_feature :
                          {1152{1'b0}};

    wire signed [16*72-1:0] pu_weight;
    wire signed [15:0] pu_bias;
    wire signed [16*8-1:0] pu_b1_pack;

    srcnn_weight_mem u_weight_mem (
        .i_base_addr(weight_base_addr),
        .o_weight(pu_weight)
    );

    srcnn_bias_mem u_bias_mem (
        .i_addr(bias_addr),
        .o_bias(pu_bias),
        .o_b1_pack(pu_b1_pack)
    );

    srcnn_pu u_pu (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_valid(pu_in_valid),
        .o_valid(pu_valid),

        .i_layer(layer),
        .i_l1_window(l1_window),
        .i_feature(pu_feature),
        .i_weight(pu_weight),
        .i_l1_bias_pack(pu_b1_pack),
        .i_bias(pu_bias),
        .i_relu_en(relu_en),
        .o_l1_result_pack(pu_l1_result_pack),
        .o_result(pu_result)
    );

    //==================================================
    // final output
    //==================================================
    assign output_bram_wen   = out_we_d3;
    assign output_bram_waddr = img_idx_d3 * 17'd22500 + {2'b00, out_wr_addr_d3};
    assign L3_p_out          = pu_result;

endmodule