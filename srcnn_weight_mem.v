`timescale 1ns / 1ps

module srcnn_weight_mem #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH      = 720,
    parameter ADDR_WIDTH = 10
)(
    input  wire [ADDR_WIDTH-1:0] i_base_addr,

    output wire [DATA_WIDTH*72-1:0] o_weight
);

    (* ram_style = "distributed" *)
    reg signed [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer k;

    initial begin

        $readmemh(
        "C:\\DSD26_Termproject\\01_Reference_SW\\q88_8_8weight\\fixed_point_W1_hex.txt",
        mem, 0, 71);

        $readmemh(
        "C:\\DSD26_Termproject\\01_Reference_SW\\q88_8_8weight\\fixed_point_W2_hex.txt",
        mem, 72, 647);

        $readmemh(
        "C:\\DSD26_Termproject\\01_Reference_SW\\q88_8_8weight\\fixed_point_W3_hex.txt",
        mem, 648, 719);

    end

    genvar i;

    generate

        for(i=0;i<72;i=i+1)
        begin : GEN_WEIGHT

            assign o_weight[i*16 +: 16]
                = mem[i_base_addr + i];

        end

    endgenerate

endmodule