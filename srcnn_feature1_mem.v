`timescale 1ns / 1ps

module srcnn_feature1_mem #(
    parameter IMG_SIZE   = 22500,
    parameter ADDR_WIDTH = 15,
    parameter DATA_WIDTH = 16
)(
    input  wire                           i_clk,

    // Kept for compatibility with old top/controller.
    // IMPORTANT: channel-wise partial write is intentionally NOT used,
    // because partial-word updates usually prevent UltraRAM inference.
    input  wire                           i_we,        // unused
    input  wire                           i_we_all,    // full 8-channel packed write
    input  wire [2:0]                     i_wr_ch,     // unused
    input  wire [ADDR_WIDTH-1:0]          i_wr_addr,
    input  wire signed [DATA_WIDTH-1:0]   i_wr_data,   // unused
    input  wire signed [DATA_WIDTH*8-1:0] i_wr_data_pack,

    input  wire [ADDR_WIDTH-1:0]          i_rd_addr,

    output wire signed [DATA_WIDTH-1:0]   o_rd_ch0,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch1,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch2,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch3,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch4,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch5,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch6,
    output wire signed [DATA_WIDTH-1:0]   o_rd_ch7
);

    // ============================================================
    // UltraRAM-friendly packed feature memory
    // ------------------------------------------------------------
    // 8 channels x 16-bit = 128-bit per pixel.
    // Split into two 64-bit memories to match the existing design.
    //
    // Critical rule for URAM inference:
    //   - only full 64-bit word writes are used
    //   - no bit-select / channel-select partial writes
    //
    // Layer1 writes F1 as a full 128-bit pack.
    // Layer2 in-place reuse must also collect ch0~ch7 first and then
    // write one full 128-bit F2 pack. This is handled in SRCNN.v.
    // ============================================================
    (* ram_style = "ultra" *) reg [63:0] mem_low  [0:IMG_SIZE-1];
    (* ram_style = "ultra" *) reg [63:0] mem_high [0:IMG_SIZE-1];

    reg [63:0] rd_low_r;
    reg [63:0] rd_high_r;

    always @(posedge i_clk) begin
        if (i_we_all) begin
            mem_low [i_wr_addr] <= i_wr_data_pack[ 63:  0];
            mem_high[i_wr_addr] <= i_wr_data_pack[127: 64];
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
