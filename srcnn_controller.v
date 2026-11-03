`timescale 1ns / 1ps

module srcnn_controller #(
    parameter IMG_W = 150,
    parameter IMG_H = 150,
    parameter IMG_SIZE = 22500,
    parameter IN_ADDR_WIDTH = 17,
    parameter FEAT_ADDR_W = 15,
    parameter W_ADDR_W = 10,
    parameter B_ADDR_W = 5
)(
    input  wire i_clk,
    input  wire i_rstn,
    input  wire i_start,

    output reg [1:0] o_img_idx,
    output reg [1:0] o_layer,

    output reg [IN_ADDR_WIDTH-1:0] o_input_rd_addr,
    output reg [FEAT_ADDR_W-1:0]   o_f1_rd_addr,
    output reg [FEAT_ADDR_W-1:0]   o_f2_rd_addr,

    output reg        o_lb_wr_en,
    output reg [1:0]  o_lb_wr_line_sel,
    output reg [7:0]  o_lb_wr_col,

    output reg [7:0]  o_out_row,
    output reg [7:0]  o_out_col,

    output reg [1:0]  o_top_line_sel,
    output reg [1:0]  o_mid_line_sel,
    output reg [1:0]  o_bot_line_sel,

    output reg [W_ADDR_W-1:0] o_weight_base_addr,
    output reg [B_ADDR_W-1:0] o_bias_addr,
    output reg                o_relu_en,

    output reg                   o_f1_we,
    output reg [2:0]             o_f1_wr_ch,
    output reg [FEAT_ADDR_W-1:0] o_f1_wr_addr,

    output reg                   o_f2_we,
    output reg [2:0]             o_f2_wr_ch,
    output reg [FEAT_ADDR_W-1:0] o_f2_wr_addr,

    output reg                   o_out_we,
    output reg [FEAT_ADDR_W-1:0] o_out_wr_addr,

    output reg o_done
);

    localparam S_IDLE = 6'd0;

    localparam S_L1_LOAD_ROW0_ADDR  = 6'd1;
    localparam S_L1_LOAD_ROW0_WRITE = 6'd2;
    localparam S_L1_LOAD_ROW1_ADDR  = 6'd3;
    localparam S_L1_LOAD_ROW1_WRITE = 6'd4;
    localparam S_L1_LOAD_NEXT_ADDR  = 6'd5;
    localparam S_L1_LOAD_NEXT_WRITE = 6'd6;
    localparam S_L1_CALC_SET        = 6'd7;
    localparam S_L1_CALC_WRITE      = 6'd8;
	localparam S_L1_FINISH_WAIT = 6'd42;

    localparam S_L2_LOAD_ROW0_ADDR  = 6'd9;
    localparam S_L2_LOAD_ROW0_WAIT  = 6'd10;
    localparam S_L2_LOAD_ROW0_WRITE = 6'd11;
    localparam S_L2_LOAD_ROW1_ADDR  = 6'd12;
    localparam S_L2_LOAD_ROW1_WAIT  = 6'd13;
    localparam S_L2_LOAD_ROW1_WRITE = 6'd14;
    localparam S_L2_LOAD_NEXT_ADDR  = 6'd15;
    localparam S_L2_LOAD_NEXT_WAIT  = 6'd16;
    localparam S_L2_LOAD_NEXT_WRITE = 6'd17;
    localparam S_L2_CALC_SET        = 6'd18;
    localparam S_L2_CALC_WRITE      = 6'd19;
	localparam S_L2_FINISH_WAIT = 6'd43;

    localparam S_L3_LOAD_ROW0_ADDR  = 6'd20;
    localparam S_L3_LOAD_ROW0_WAIT  = 6'd21;
    localparam S_L3_LOAD_ROW0_WRITE = 6'd22;
    localparam S_L3_LOAD_ROW1_ADDR  = 6'd23;
    localparam S_L3_LOAD_ROW1_WAIT  = 6'd24;
    localparam S_L3_LOAD_ROW1_WRITE = 6'd25;
    localparam S_L3_LOAD_NEXT_ADDR  = 6'd26;
    localparam S_L3_LOAD_NEXT_WAIT  = 6'd27;
    localparam S_L3_LOAD_NEXT_WRITE = 6'd28;
    localparam S_L3_CALC_SET        = 6'd29;
    localparam S_L3_CALC_WRITE      = 6'd30;

    localparam S_NEXT_IMG = 6'd40;
    localparam S_DONE     = 6'd41;

    reg [5:0] state;

    reg [7:0] load_row;
    reg [7:0] load_col;

    reg [7:0] out_row;
    reg [7:0] out_col;
    reg [2:0] out_ch;

    reg [7:0] rd_col_d;
    reg [1:0] rd_line_sel_d;

    function [1:0] line_sel_for_row_mod3;
        input [7:0] row_idx;
        begin
            case (row_idx % 3)
                0: line_sel_for_row_mod3 = 2'd0;
                1: line_sel_for_row_mod3 = 2'd1;
                2: line_sel_for_row_mod3 = 2'd2;
                default: line_sel_for_row_mod3 = 2'd0;
            endcase
        end
    endfunction

    task set_line_sel;
        input [7:0] row;
        begin
            if (row == 8'd0) begin
                o_top_line_sel <= 2'd0;
                o_mid_line_sel <= 2'd0;
                o_bot_line_sel <= 2'd1;
            end
            else if (row == IMG_H-1) begin
                o_top_line_sel <= line_sel_for_row_mod3(row - 8'd1);
                o_mid_line_sel <= line_sel_for_row_mod3(row);
                o_bot_line_sel <= 2'd0;
            end
            else begin
                o_top_line_sel <= line_sel_for_row_mod3(row - 8'd1);
                o_mid_line_sel <= line_sel_for_row_mod3(row);
                o_bot_line_sel <= line_sel_for_row_mod3(row + 8'd1);
            end
        end
    endtask

    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            state <= S_IDLE;

            o_img_idx <= 2'd0;
            o_layer   <= 2'd0;

            load_row <= 8'd0;
            load_col <= 8'd0;
            out_row  <= 8'd0;
            out_col  <= 8'd0;
            out_ch   <= 3'd0;

            rd_col_d      <= 8'd0;
            rd_line_sel_d <= 2'd0;

            o_input_rd_addr <= 0;
            o_f1_rd_addr    <= 0;
            o_f2_rd_addr    <= 0;

            o_lb_wr_en       <= 1'b0;
            o_lb_wr_line_sel <= 2'd0;
            o_lb_wr_col      <= 8'd0;

            o_out_row <= 8'd0;
            o_out_col <= 8'd0;

            o_top_line_sel <= 2'd0;
            o_mid_line_sel <= 2'd0;
            o_bot_line_sel <= 2'd1;

            o_weight_base_addr <= 0;
            o_bias_addr        <= 0;
            o_relu_en          <= 1'b1;

            o_f1_we      <= 1'b0;
            o_f1_wr_ch   <= 3'd0;
            o_f1_wr_addr <= 0;

            o_f2_we      <= 1'b0;
            o_f2_wr_ch   <= 3'd0;
            o_f2_wr_addr <= 0;

            o_out_we      <= 1'b0;
            o_out_wr_addr <= 0;

            o_done <= 1'b0;
        end
        else begin
            o_lb_wr_en <= 1'b0;
            o_f1_we    <= 1'b0;
            o_f2_we    <= 1'b0;
            o_out_we   <= 1'b0;
            o_done     <= 1'b0;

            case (state)

                S_IDLE: begin
                    o_layer   <= 2'd0;
                    o_img_idx <= 2'd0;

                    if (i_start) begin
                        o_layer  <= 2'd1;
                        load_row <= 8'd0;
                        load_col <= 8'd0;
                        out_row  <= 8'd0;
                        out_col  <= 8'd0;
                        out_ch   <= 3'd0;
                        state <= S_L1_LOAD_ROW0_ADDR;
                    end
                end

                // ==================================================
                // L1
                // ==================================================
                S_L1_LOAD_ROW0_ADDR: begin
                    o_layer <= 2'd1;
                    o_input_rd_addr <= load_row * IMG_W + load_col;                   
                    rd_col_d <= load_col;
                    rd_line_sel_d <= 2'd0;
                    state <= S_L1_LOAD_ROW0_WRITE;
                end

                S_L1_LOAD_ROW0_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        load_row <= 8'd1;
                        state <= S_L1_LOAD_ROW1_ADDR;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L1_LOAD_ROW0_ADDR;
                    end
                end

                S_L1_LOAD_ROW1_ADDR: begin
                    o_input_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= 2'd1;
                    state <= S_L1_LOAD_ROW1_WRITE;
                end

                S_L1_LOAD_ROW1_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        load_row <= 8'd2;
                        out_row <= 8'd0;
                        out_col <= 8'd0;
                        out_ch  <= 3'd0;
                        state <= S_L1_CALC_SET;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L1_LOAD_ROW1_ADDR;
                    end
                end

                S_L1_LOAD_NEXT_ADDR: begin
                    o_input_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= line_sel_for_row_mod3(load_row);
                    state <= S_L1_LOAD_NEXT_WRITE;
                end

                S_L1_LOAD_NEXT_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        state <= S_L1_CALC_SET;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L1_LOAD_NEXT_ADDR;
                    end
                end

                S_L1_CALC_SET: begin
                    o_layer <= 2'd1;
                    o_out_row <= out_row;
                    o_out_col <= out_col;
                    set_line_sel(out_row);

                    // Layer1 optimized path:
                    // one 1ch window is broadcast to 8 MAC9 blocks,
                    // so all 8 output channels are generated together.
                    o_weight_base_addr <= 10'd0;   // W1[0..7][3x3]
                    o_bias_addr        <= 5'd0;    // B1 pack is read in bias_mem
                    o_relu_en          <= 1'b1;

                    state <= S_L1_CALC_WRITE;
                end

                S_L1_CALC_WRITE: begin
                    // feature1_mem writes all 8 channels at this pixel.
                    o_f1_we      <= 1'b1;
                    o_f1_wr_ch   <= 3'd0;
                    o_f1_wr_addr <= out_row * IMG_W + out_col;
                    out_ch       <= 3'd0;

                    if (out_col == IMG_W-1) begin
                        out_col <= 8'd0;

                        if (out_row == IMG_H-1) begin
                            state <= S_L1_FINISH_WAIT;
                        end
                        else begin
                            out_row <= out_row + 8'd1;

                            if ((out_row + 8'd2) <= IMG_H-1) begin
                                load_row <= out_row + 8'd2;
                                load_col <= 8'd0;
                                state <= S_L1_LOAD_NEXT_ADDR;
                            end
                            else begin
                                state <= S_L1_CALC_SET;
                            end
                        end
                    end
                    else begin
                        out_col <= out_col + 8'd1;
                        state <= S_L1_CALC_SET;
                    end
                end
				S_L1_FINISH_WAIT: begin
                     o_layer <= 2'd2;
                 
                     load_row <= 8'd0;
                     load_col <= 8'd0;
                     out_row  <= 8'd0;
                     out_col  <= 8'd0;
                     out_ch   <= 3'd0;
                 
                     state <= S_L2_LOAD_ROW0_ADDR;
                 end

                // ==================================================
                // L2 - feature1_mem read has 1-cycle latency
                // ADDR -> WAIT -> WRITE
                // ==================================================
                S_L2_LOAD_ROW0_ADDR: begin
                    o_layer <= 2'd2;
                    o_f1_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= 2'd0;
                    state <= S_L2_LOAD_ROW0_WAIT;
                end

                S_L2_LOAD_ROW0_WAIT: begin
                    state <= S_L2_LOAD_ROW0_WRITE;
                end

                S_L2_LOAD_ROW0_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        load_row <= 8'd1;
                        state <= S_L2_LOAD_ROW1_ADDR;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L2_LOAD_ROW0_ADDR;
                    end
                end

                S_L2_LOAD_ROW1_ADDR: begin
                    o_f1_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= 2'd1;
                    state <= S_L2_LOAD_ROW1_WAIT;
                end

                S_L2_LOAD_ROW1_WAIT: begin
                    state <= S_L2_LOAD_ROW1_WRITE;
                end

                S_L2_LOAD_ROW1_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        load_row <= 8'd2;
                        out_row <= 8'd0;
                        out_col <= 8'd0;
                        out_ch  <= 3'd0;
                        state <= S_L2_CALC_SET;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L2_LOAD_ROW1_ADDR;
                    end
                end

                S_L2_LOAD_NEXT_ADDR: begin
                    o_f1_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= line_sel_for_row_mod3(load_row);
                    state <= S_L2_LOAD_NEXT_WAIT;
                end

                S_L2_LOAD_NEXT_WAIT: begin
                    state <= S_L2_LOAD_NEXT_WRITE;
                end

                S_L2_LOAD_NEXT_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        state <= S_L2_CALC_SET;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L2_LOAD_NEXT_ADDR;
                    end
                end

                S_L2_CALC_SET: begin
                    o_layer <= 2'd2;
                    o_out_row <= out_row;
                    o_out_col <= out_col;
                    set_line_sel(out_row);

                    o_weight_base_addr <= 10'd72 + out_ch * 10'd72;
                    o_bias_addr        <= 5'd8 + out_ch;
                    o_relu_en          <= 1'b1;

                    state <= S_L2_CALC_WRITE;
                end

                S_L2_CALC_WRITE: begin
                    o_f2_we      <= 1'b1;
                    o_f2_wr_ch   <= out_ch;
                    o_f2_wr_addr <= out_row * IMG_W + out_col;

                    if (out_ch == 3'd7) begin
                        out_ch <= 3'd0;

                        if (out_col == IMG_W-1) begin
                            out_col <= 8'd0;

                        if (out_row == IMG_H-1) begin
                            state <= S_L2_FINISH_WAIT;
                        end
                            else begin
                                out_row <= out_row + 8'd1;

                                if ((out_row + 8'd2) <= IMG_H-1) begin
                                    load_row <= out_row + 8'd2;
                                    load_col <= 8'd0;
                                    state <= S_L2_LOAD_NEXT_ADDR;
                                end
                                else begin
                                    state <= S_L2_CALC_SET;
                                end
                            end
                        end
                        else begin
                            out_col <= out_col + 8'd1;
                            state <= S_L2_CALC_SET;
                        end
                    end
                    else begin
                        out_ch <= out_ch + 3'd1;
                        state <= S_L2_CALC_SET;
                    end
                end
               S_L2_FINISH_WAIT: begin
                   o_layer <= 2'd3;
               
                   load_row <= 8'd0;
                   load_col <= 8'd0;
               
                   out_row <= 8'd0;
                   out_col <= 8'd0;
                   out_ch  <= 3'd0;
               
                   state <= S_L3_LOAD_ROW0_ADDR;
               end

                // ==================================================
                // L3 - feature2_mem read has 1-cycle latency
                // ADDR -> WAIT -> WRITE
                // ==================================================
                S_L3_LOAD_ROW0_ADDR: begin
                    o_layer <= 2'd3;
                    o_f2_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= 2'd0;
                    state <= S_L3_LOAD_ROW0_WAIT;
                end

                S_L3_LOAD_ROW0_WAIT: begin
                    state <= S_L3_LOAD_ROW0_WRITE;
                end

                S_L3_LOAD_ROW0_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        load_row <= 8'd1;
                        state <= S_L3_LOAD_ROW1_ADDR;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L3_LOAD_ROW0_ADDR;
                    end
                end

                S_L3_LOAD_ROW1_ADDR: begin
                    o_f2_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= 2'd1;
                    state <= S_L3_LOAD_ROW1_WAIT;
                end

                S_L3_LOAD_ROW1_WAIT: begin
                    state <= S_L3_LOAD_ROW1_WRITE;
                end

                S_L3_LOAD_ROW1_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        load_row <= 8'd2;
                        out_row <= 8'd0;
                        out_col <= 8'd0;
                        out_ch  <= 3'd0;
                        state <= S_L3_CALC_SET;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L3_LOAD_ROW1_ADDR;
                    end
                end

                S_L3_LOAD_NEXT_ADDR: begin
                    o_f2_rd_addr <= load_row * IMG_W + load_col;
                    rd_col_d <= load_col;
                    rd_line_sel_d <= line_sel_for_row_mod3(load_row);
                    state <= S_L3_LOAD_NEXT_WAIT;
                end

                S_L3_LOAD_NEXT_WAIT: begin
                    state <= S_L3_LOAD_NEXT_WRITE;
                end

                S_L3_LOAD_NEXT_WRITE: begin
                    o_lb_wr_en       <= 1'b1;
                    o_lb_wr_line_sel <= rd_line_sel_d;
                    o_lb_wr_col      <= rd_col_d;

                    if (load_col == IMG_W-1) begin
                        load_col <= 8'd0;
                        state <= S_L3_CALC_SET;
                    end
                    else begin
                        load_col <= load_col + 8'd1;
                        state <= S_L3_LOAD_NEXT_ADDR;
                    end
                end

                S_L3_CALC_SET: begin
                    o_layer <= 2'd3;
                    o_out_row <= out_row;
                    o_out_col <= out_col;
                    set_line_sel(out_row);

                    o_weight_base_addr <= 10'd648;
                    o_bias_addr        <= 5'd16;
                    o_relu_en          <= 1'b0;

                    state <= S_L3_CALC_WRITE;
                end

                S_L3_CALC_WRITE: begin
                    o_out_we      <= 1'b1;
                    o_out_wr_addr <= out_row * IMG_W + out_col;

                    if (out_col == IMG_W-1) begin
                        out_col <= 8'd0;

                        if (out_row == IMG_H-1) begin
                            state <= S_NEXT_IMG;
                        end
                        else begin
                            out_row <= out_row + 8'd1;

                            if ((out_row + 8'd2) <= IMG_H-1) begin
                                load_row <= out_row + 8'd2;
                                load_col <= 8'd0;
                                state <= S_L3_LOAD_NEXT_ADDR;
                            end
                            else begin
                                state <= S_L3_CALC_SET;
                            end
                        end
                    end
                    else begin
                        out_col <= out_col + 8'd1;
                        state <= S_L3_CALC_SET;
                    end
                end

                S_NEXT_IMG: begin
                    o_done <= 1'b1;

                    if (o_img_idx == 2'd2) begin
                        state <= S_DONE;
                    end
                    else begin
                        o_img_idx <= o_img_idx + 2'd1;
                        o_layer <= 2'd1;

                        load_row <= 8'd0;
                        load_col <= 8'd0;
                        out_row  <= 8'd0;
                        out_col  <= 8'd0;
                        out_ch   <= 3'd0;

                        state <= S_L1_LOAD_ROW0_ADDR;
                    end
                end

                S_DONE: begin
                    o_layer <= 2'd0;

                    if (!i_start)
                        state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule