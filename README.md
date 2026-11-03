# SRCNN 8_8 FPGA Accelerator

A Verilog RTL implementation of an FPGA accelerator for SRCNN 8_8 inference.

This repository contains the RTL modules and testbench for the SRCNN 8_8 model I implemented as part of a Digital System Design course project.

> **External data files are required.**
> Model weights, biases, and input image data are not included in the current upload. Prepare these files separately and update the `$readmemh` paths before running the simulation.

## 1. Overview

| Item | Specification |
| --- | --- |
| Model | Three-layer SRCNN |
| Channel configuration | 1 → 8 → 8 → 1 |
| Input | Three bicubic-upsampled 150×150 Y-channel images |
| Output | Three enhanced 150×150 Y-channel images |
| Data format | Signed 16-bit Q8.8 fixed-point |
| Convolution | 3×3 kernels with zero padding of 1 |
| Activation | ReLU after Layer 1 and Layer 2; no ReLU after Layer 3 |
| Testbench clock | 100 MHz, 10 ns period |

The accelerator performs CNN inference on the luminance channel. Bicubic upsampling, RGB/YCbCr conversion, and final RGB image reconstruction are handled outside the RTL.

## 2. Architecture Highlights

- **Reusable processing unit:** A shared PU performs computations across all three layers.
- **Parallel computation:** Eight MAC9 blocks provide 72 parallel multiplications.
- **Line buffers:** Single-channel and eight-channel line buffers supply data for 3×3 windows.
- **Three-stage pipeline:** Computation is divided into pipeline stages, with write controls delayed to match the output data.
- **In-place feature memory reuse:** Layer 2 outputs overwrite Feature1 memory locations after the original data is no longer needed.
- **Packed feature writes:** Eight Layer 2 channel results are collected into a 128-bit word before being written to feature memory.

## 3. Main Modules

The names below refer to Verilog module names.

| Module | Description |
| --- | --- |
| `SRCNN` | Accelerator core and datapath integration |
| `srcnn_controller` | Layer sequencing, image sequencing, address generation, and control |
| `srcnn_pu` | Shared processing unit |
| `srcnn_mac9_sum` | Nine-product sum for a 3×3 convolution window |
| `srcnn_adder_tree8` | Accumulation of partial sums from eight input channels |
| `srcnn_q8_8` | Fixed-point conversion |
| `srcnn_bias_add` | Bias addition |
| `srcnn_relu` | ReLU activation |
| `srcnn_line_buffer_1ch` | Single-channel line buffer |
| `srcnn_line_buffer_8ch` | Eight-channel line buffer |
| `srcnn_window_gen_1ch` | Single-channel window generation and zero padding |
| `srcnn_window_gen_8ch` | Eight-channel window generation and zero padding |
| `srcnn_input_mem` | Storage for three input images |
| `srcnn_weight_mem` | Weight initialization and access |
| `srcnn_bias_mem` | Bias initialization and access |
| `srcnn_feature1_mem` | Shared feature memory for Layer 1 and Layer 2 outputs |
| `tb_SRCNN` | Core simulation and output data logging |
| `top_srcnn` | System integration wrapper and 64-bit output packing |
| `uram_sdp` | Memory module for the system output buffer |

The `srcnn_feature2_mem` source file is included, but it is not instantiated in the current `SRCNN` core. Layer 2 outputs are stored in `srcnn_feature1_mem` and read from the same memory during Layer 3.

## 4. Required External Data

Prepare the following nine files before running the simulation.

All files must contain **16-bit hexadecimal values compatible with `$readmemh`**.

| Type | File | Number of values |
| --- | --- | ---: |
| Layer 1 weights | `fixed_point_W1_hex.txt` | 72 |
| Layer 2 weights | `fixed_point_W2_hex.txt` | 576 |
| Layer 3 weights | `fixed_point_W3_hex.txt` | 72 |
| Layer 1 biases | `fixed_point_B1_hex.txt` | 8 |
| Layer 2 biases | `fixed_point_B2_hex.txt` | 8 |
| Layer 3 bias | `fixed_point_B3_hex.txt` | 1 |
| Input image 0 | `test_0_hex.txt` | 22,500 |
| Input image 1 | `test_1_hex.txt` | 22,500 |
| Input image 2 | `test_2_hex.txt` | 22,500 |

### Data Format

- Input images must be preprocessed Y-channel data in Q8.8 format, not PNG or JPEG files.
- Each image contains 150×150 = 22,500 values in row-major order.
- Each value is represented as a 16-bit hexadecimal word. One four-digit hexadecimal value per line is a suitable format.
- Negative values use 16-bit two's complement representation.
- Weights and biases must correspond to the SRCNN 8_8 model.
- Weight channel and kernel ordering must match the RTL memory access order.
- Input normalization and scaling must match the model's training and reference software. Converting arbitrary pixel values to Q8.8 alone is not sufficient.

### File Path Configuration

The source currently contains absolute Windows paths from the original development environment, beginning with:

`C:\DSD26_Termproject\...`

Update the `$readmemh` paths in the following modules:

| Module | Files to configure |
| --- | --- |
| `srcnn_weight_mem` | W1, W2, and W3 |
| `srcnn_bias_mem` | B1, B2, and B3 |
| `srcnn_input_mem` | test_0, test_1, and test_2 |

Copying the data files into the repository does not automatically update these paths.

If relative paths are used, ensure that the files can be located from the simulator's working directory.

## 5. Running the Simulation

1. Add the RTL files to **Design Sources** in a Vivado project.
2. Add the file containing `tb_SRCNN` to **Simulation Sources**.
3. Set **`tb_SRCNN`** as the simulation top.
4. Prepare the nine external data files and update the `$readmemh` paths.
5. Run **Behavioral Simulation** until the testbench finishes.

The testbench directly instantiates the `SRCNN` core and generates the clock, reset, and start signals.

### Output Files

The testbench writes the following files to the simulator's working directory:

- `rtl_output_test_0.txt`
- `rtl_output_test_1.txt`
- `rtl_output_test_2.txt`

Each file contains the output Y-channel values as 16-bit hexadecimal words.

Image visualization requires separate postprocessing to interpret the fixed-point values, apply the appropriate scaling, and reshape the output into a 150×150 array.

### Expected Checks

| Check | Expected value |
| --- | ---: |
| Output values per image | 22,500 |
| Total output values | 67,500 |
| Completion pulses | 3 |
| Outputs containing unknown values (`X`) | 0 |

These checks cover output counts and unknown-value detection. Numerical correctness should be verified separately against reference software outputs.

The current testbench does not calculate PSNR automatically.

## 6. FPGA Implementation Scope

The original project was taken through simulation, synthesis, implementation, and image output on an FPGA board.

However, the RTL files in this repository do not constitute a complete board deployment environment. Running the design on hardware also requires the target device configuration, clock and pin constraints, system block design and IP integration, and processor-side control and visualization software.

The current implementation is configured for three 150×150 images. Changing the image dimensions or image count requires reviewing memory sizes, address calculations, controller logic, and the testbench together.

## 7. Acknowledgments

This project was developed using skeleton and interface code provided in a Digital System Design course. My contribution focused on the SRCNN 8_8 accelerator's RTL design and implementation.

Provided source files, including `top_srcnn` and `uram_sdp`, contain their original copyright notices and license headers. Refer to the individual files for details.
