`timescale 1ns / 1ps

module tb_SRCNN;

    reg clk;
    reg rstn;
    reg start;

    wire done;
    wire output_bram_wen;
    wire [16:0] output_bram_waddr;
    wire [15:0] L3_p_out;

    integer fp0, fp1, fp2;
    integer out_count;
    integer cnt0, cnt1, cnt2;
    integer done_count;
    integer x_count;
    integer timeout_cnt;

    SRCNN dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_start(start),
        .o_done(done),
        .output_bram_wen(output_bram_wen),
        .output_bram_waddr(output_bram_waddr),
        .L3_p_out(L3_p_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rstn = 1'b0;
        start = 1'b0;

        out_count = 0;
        cnt0 = 0;
        cnt1 = 0;
        cnt2 = 0;
        done_count = 0;
        x_count = 0;
        timeout_cnt = 0;

        fp0 = $fopen("rtl_output_test_0.txt", "w");
        fp1 = $fopen("rtl_output_test_1.txt", "w");
        fp2 = $fopen("rtl_output_test_2.txt", "w");

        #100;
        rstn = 1'b1;

        #50;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
    end

    always @(posedge clk) begin
        if (rstn) begin
            timeout_cnt <= timeout_cnt + 1;

            if (timeout_cnt > 300000000) begin
                $display("TIMEOUT!");
                $finish;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            done_count <= 0;
        end
        else if (done) begin
            done_count <= done_count + 1;

            $display("[%0t] DONE pulse detected -> %0d, out_count=%0d, waddr=%0d",
                     $time, done_count + 1, out_count, output_bram_waddr);

            if (done_count + 1 == 3) begin
                #100;

                $fclose(fp0);
                $fclose(fp1);
                $fclose(fp2);

                $display("======================================");
                $display("Simulation Done");
                $display("Done count   = %0d", done_count + 1);
                $display("Image0 count = %0d", cnt0);
                $display("Image1 count = %0d", cnt1);
                $display("Image2 count = %0d", cnt2);
                $display("Total count  = %0d", out_count);
                $display("X count      = %0d", x_count);
                $display("======================================");

                $finish;
            end
        end
    end

    always @(posedge clk) begin
        if (rstn && output_bram_wen) begin

            if (^L3_p_out === 1'bx) begin
                x_count <= x_count + 1;
                $display("[%0t] X detected! waddr=%0d out_count=%0d data=%h",
                         $time, output_bram_waddr, out_count, L3_p_out);
            end

            if (output_bram_waddr < 17'd22500) begin
                $fwrite(fp0, "%04h\n", L3_p_out);
                cnt0 <= cnt0 + 1;
            end
            else if (output_bram_waddr < 17'd45000) begin
                $fwrite(fp1, "%04h\n", L3_p_out);
                cnt1 <= cnt1 + 1;
            end
            else if (output_bram_waddr < 17'd67500) begin
                $fwrite(fp2, "%04h\n", L3_p_out);
                cnt2 <= cnt2 + 1;
            end
            else begin
                $display("[%0t] ERROR: output_bram_waddr out of range = %0d",
                         $time, output_bram_waddr);
            end

            out_count <= out_count + 1;

            if (output_bram_waddr == 17'd0)
                $display("===== IMAGE0 START by addr =====");

            if (output_bram_waddr == 17'd22500)
                $display("===== IMAGE1 START by addr =====");

            if (output_bram_waddr == 17'd45000)
                $display("===== IMAGE2 START by addr =====");

            if (output_bram_waddr == 17'd67499)
                $display("===== LAST OUTPUT WRITE ===== data=%h", L3_p_out);
        end
    end

endmodule