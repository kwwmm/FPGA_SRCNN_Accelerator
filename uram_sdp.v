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

//============================================================================
//Warning! Do not modify the components of this module under any circumstances.
//============================================================================

//============================================================================
// URAM Specification & Memory Sizing
//----------------------------------------------------------------------------
// Target memory resource : UltraRAM (URAM)
//
// URAM tile capacity:
// - Data width : up to 72 bits
// - Depth      : 4096 words
//
// Demo data requirement:
// - Pixel format      : 16-bit Q8.8
// - Image resolution  : 150 x 150 = 22,500 pixels
// - Number of images  : 3
// - Total pixels      : 22,500 x 3 = 67,500 pixels
//
// Packing format:
// - 4 pixels are packed into one 64-bit word
// - 67,500 pixels / 4 = 16,875 words
//
// URAM allocation:
// - Required depth : 16,875 words
// - 1 URAM tile    : 4,096 words
// - 5 URAM tiles   : 4,096 x 5 = 20,480 words
//
// Therefore, this module uses:
// - DATA_WIDTH = 64
// - DEPTH      = 20,480
//============================================================================

`timescale 1ns / 1ps

module uram_sdp #(
    parameter DATA_WIDTH   = 64,    
    parameter DEPTH        = 20480, 
    parameter WORD_ADDR_W  = 15,
    parameter BYTE_ADDR_W  = 18
)(
    input  wire                     clka,
    input  wire                     ena,
    input  wire [(DATA_WIDTH/8)-1:0] wea,
    input  wire [WORD_ADDR_W-1:0]   addra,
    input  wire [DATA_WIDTH-1:0]    dina,

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL, MEM_ECC NONE, MEM_SIZE 262144, READ_WRITE_MODE READ_WRITE, MEM_WIDTH 64" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *)
    input  wire                     clkb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB RST" *)
    input  wire                     rstb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *)
    input  wire                     enb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *)
    input  wire [(DATA_WIDTH/8)-1:0] web,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *)
    input  wire [BYTE_ADDR_W-1:0]   addrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *)
    input  wire [DATA_WIDTH-1:0]    dinb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *)
    output reg  [DATA_WIDTH-1:0]    doutb
);
	//============================================================================
    // UltraRAM inference directive
    // This forces the memory array to be implemented using UltraRAM resources.
	//============================================================================
    (* ram_style = "ultra" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

	//============================================================================
    // Convert AXI byte address to 64-bit word address.
    // Since DATA_WIDTH = 64 bits = 8 bytes, the lower 3 address bits are ignored.
	//============================================================================
    wire [WORD_ADDR_W-1:0] addrb_word = addrb[BYTE_ADDR_W-1:3];

    //============================================================================
    // Memory Operation (Simple Dual-Port)
    //
    // Port A (clka):
    // - Write 64-bit data into URAM
    // - Enabled when ena = 1 and any bit of wea is asserted
    //
    // Port B (clka, shared clock):
    // - Read 64-bit data from URAM
    // - Output is registered (1-cycle latency)
    //============================================================================
    always @(posedge clka) begin
        // Port A: write SRCNN output data into URAM
        if (ena && (|wea)) begin
            mem[addra] <= dina;
        end

        // Port B: read stored data through AXI BRAM Controller
        if (enb) begin
            doutb <= mem[addrb_word];
        end
    end

endmodule
