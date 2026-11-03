`timescale 1ns / 1ps

//============================================================================
// srcnn_input_mem for SRCNN_8_8
//----------------------------------------------------------------------------
// Stores 3 input images.
//
// Image count   : 3
// Image size    : 150 x 150 = 22500 pixels
// Total entries : 3 x 22500 = 67500
// Data format   : signed 16-bit Q8.8
//
// Address map:
//   test_0 : 0     ~ 22499
//   test_1 : 22500 ~ 44999
//   test_2 : 45000 ~ 67499
//
// Read latency:
//   1-cycle synchronous read
//============================================================================

module srcnn_input_mem #(
    parameter IMG_SIZE   = 22500,
    parameter NUM_IMAGES = 3,
    parameter DEPTH      = 67500,
    parameter ADDR_WIDTH = 17,
    parameter DATA_WIDTH = 16
)(
    input  wire                         i_clk,
    input  wire [ADDR_WIDTH-1:0]        i_rd_addr,
    output wire signed [DATA_WIDTH-1:0] o_rd_data
);

    (* ram_style = "block" *)
    reg signed [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg signed [DATA_WIDTH-1:0] rd_data_r;

    assign o_rd_data = rd_data_r;

    initial begin
        $readmemh(
        "C:\\DSD26_Termproject\\02_Provided_Data\\input_Y_channel_only_hex\\test_0_hex.txt",
        mem, 0, 22499);

        $readmemh(
        "C:\\DSD26_Termproject\\02_Provided_Data\\input_Y_channel_only_hex\\test_1_hex.txt",
        mem, 22500, 44999);

        $readmemh(
        "C:\\DSD26_Termproject\\02_Provided_Data\\input_Y_channel_only_hex\\test_2_hex.txt",
        mem, 45000, 67499);
    end

    always @(posedge i_clk) begin
        rd_data_r <= mem[i_rd_addr];
    end

endmodule