//============================================================================
// Copyright (c) 2026 Seoul National University of Science and Technology
//                     (SEOULTECH)
//                     Intelligence Digital System Design Lab (IDSL)
//
// Course: Digital System Design, Spring 2026
//
// This source code is provided as educational material for the
// Digital System Design course at SEOULTECH. It is released under
// the MIT License to encourage learning and reuse.
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject
// to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//============================================================================


`timescale 1ns / 1ps

module top_srcnn(
    input  wire        clk,
    input  wire        rstn,
    input  wire        i_start,

    output wire        o_buf_en,
    output wire [7:0]  o_buf_wen,
    output wire [14:0] o_buf_addr,
    output wire [63:0] o_buf_data,

    output wire        done_intr_o
);

    wire        srcnn_done;
    wire        srcnn_wen;
    wire [16:0] srcnn_waddr;
    wire [15:0] srcnn_wdata;

    //============================================================================
    // STUDENT MODIFICATION AREA
    // Only this SRCNN instance can be modified by students.
    // All other parts of this file must NOT be changed.
    //============================================================================
    SRCNN your_srcnn (
        .i_clk              (clk),          
        .i_rstn             (rstn),         
        .i_start            (i_start),      

        .o_done             (srcnn_done), 
        .output_bram_wen    (srcnn_wen),  
        .output_bram_waddr  (srcnn_waddr),
        .L3_p_out           (srcnn_wdata) 
    );
    //============================================================================


    //============================================================================
    // PACKING LOGIC
    // Pack 4 consecutive 16-bit pixels into one 64-bit word.
    // srcnn_waddr[1:0] determines position within the word.
    // [pixel_3 | pixel_2 | pixel_1 | pixel_0]
    //============================================================================
    reg [15:0] pixel_0_r, pixel_1_r, pixel_2_r;
    reg        pack_wen_r;
    reg [14:0] pack_waddr_r;
    reg [63:0] pack_wdata_r;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
			// Reset all internal registers
            pixel_0_r    <= 16'b0;
            pixel_1_r    <= 16'b0;
            pixel_2_r    <= 16'b0;
            pack_wen_r   <= 1'b0;
            pack_waddr_r <= 15'b0;
            pack_wdata_r <= 64'b0;
        end else begin
			// Default: no write
            pack_wen_r <= 1'b0;
			
			// When SRCNN produces output, store pixels sequentially
            if (srcnn_wen) begin
                case (srcnn_waddr[1:0])
					// Store first pixel
                    2'b00: pixel_0_r <= srcnn_wdata;

					// Store second pixel
                    2'b01: pixel_1_r <= srcnn_wdata;

					// Store third pixel
                    2'b10: pixel_2_r <= srcnn_wdata;

					// When 4 pixels are collected:
					// - Pack into 64-bit
					// - Generate write enable
					// - Update write address (word-based)
                    2'b11: begin
                        pack_wdata_r <= {srcnn_wdata, pixel_2_r, pixel_1_r, pixel_0_r};
                        pack_waddr_r <= srcnn_waddr[16:2];
                        pack_wen_r   <= 1'b1;
                    end
                endcase
            end
        end
    end


    //============================================================================
    // URAM WRITE INTERFACE
    // - o_buf_en   : URAM write enable signal
    // - o_buf_wen  : byte-wise write enable (all bytes enabled)
    // - o_buf_addr : 64-bit word address
    // - o_buf_data : packed 64-bit output data
    //============================================================================
    assign o_buf_en   = pack_wen_r;
    assign o_buf_wen  = {8{pack_wen_r}};
    assign o_buf_addr = pack_waddr_r;
    assign o_buf_data = pack_wdata_r;

    //============================================================================
    // DONE SIGNAL
    // Forward SRCNN completion signal to system interrupt
    //============================================================================
    assign done_intr_o = srcnn_done;

endmodule
