`timescale 1ns / 1ps

module srcnn_feature2_mem #(
    parameter IMG_SIZE   = 22500,
    parameter ADDR_WIDTH = 15,
    parameter DATA_WIDTH = 16
)(
    input  wire                         i_clk,

    input  wire                         i_we,
    input  wire [2:0]                   i_wr_ch,
    input  wire [ADDR_WIDTH-1:0]        i_wr_addr,
    input  wire signed [DATA_WIDTH-1:0] i_wr_data,

    input  wire [ADDR_WIDTH-1:0]        i_rd_addr,

    output wire signed [DATA_WIDTH-1:0] o_rd_ch0,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch1,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch2,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch3,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch4,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch5,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch6,
    output wire signed [DATA_WIDTH-1:0] o_rd_ch7
);

    (* ram_style = "ultra" *) reg [63:0] mem_low  [0:IMG_SIZE-1];
    (* ram_style = "ultra" *) reg [63:0] mem_high [0:IMG_SIZE-1];

    reg [63:0] rd_low_r;
    reg [63:0] rd_high_r;

    always @(posedge i_clk) begin
        if (i_we) begin
            case (i_wr_ch)
                3'd0: mem_low [i_wr_addr][15:0]   <= i_wr_data;
                3'd1: mem_low [i_wr_addr][31:16]  <= i_wr_data;
                3'd2: mem_low [i_wr_addr][47:32]  <= i_wr_data;
                3'd3: mem_low [i_wr_addr][63:48]  <= i_wr_data;
                3'd4: mem_high[i_wr_addr][15:0]   <= i_wr_data;
                3'd5: mem_high[i_wr_addr][31:16]  <= i_wr_data;
                3'd6: mem_high[i_wr_addr][47:32]  <= i_wr_data;
                3'd7: mem_high[i_wr_addr][63:48]  <= i_wr_data;
            endcase
        end

        rd_low_r  <= mem_low [i_rd_addr];
        rd_high_r <= mem_high[i_rd_addr];
    end

    assign o_rd_ch0 = rd_low_r [15:0];
    assign o_rd_ch1 = rd_low_r [31:16];
    assign o_rd_ch2 = rd_low_r [47:32];
    assign o_rd_ch3 = rd_low_r [63:48];

    assign o_rd_ch4 = rd_high_r[15:0];
    assign o_rd_ch5 = rd_high_r[31:16];
    assign o_rd_ch6 = rd_high_r[47:32];
    assign o_rd_ch7 = rd_high_r[63:48];

endmodule