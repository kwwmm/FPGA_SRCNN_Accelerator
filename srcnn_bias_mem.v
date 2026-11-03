`timescale 1ns / 1ps

//============================================================================
// srcnn_bias_mem
//----------------------------------------------------------------------------
// Stores all bias values for SRCNN_8_8 using distributed RAM / LUTRAM style.
//
// B1 : 8 bias
// B2 : 8 bias
// B3 : 1 bias
//
// Total depth = 17
//
// Address map:
//   0  ~ 7   : B1
//   8  ~ 15  : B2
//   16       : B3
//
// Data format:
//   signed 16-bit Q8.8
//============================================================================

module srcnn_bias_mem #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH      = 17,
    parameter ADDR_WIDTH = 5
)(
    input  wire [ADDR_WIDTH-1:0]        i_addr,
    output wire signed [DATA_WIDTH-1:0] o_bias,
    output wire signed [DATA_WIDTH*8-1:0] o_b1_pack
);

    (* ram_style = "distributed" *)
    reg signed [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh(
        "C:\\DSD26_Termproject\\01_Reference_SW\\q88_8_8bias\\fixed_point_B1_hex.txt",
        mem, 0, 7);

        $readmemh(
        "C:\\DSD26_Termproject\\01_Reference_SW\\q88_8_8bias\\fixed_point_B2_hex.txt",
        mem, 8, 15);

        $readmemh(
        "C:\\DSD26_Termproject\\01_Reference_SW\\q88_8_8bias\\fixed_point_B3_hex.txt",
        mem, 16, 16);
    end

    assign o_bias = mem[i_addr];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_B1_PACK
            assign o_b1_pack[i*DATA_WIDTH +: DATA_WIDTH] = mem[i];
        end
    endgenerate

endmodule