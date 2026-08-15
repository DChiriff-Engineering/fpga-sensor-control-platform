`timescale 1ns/1ps
module tb_vga_timing_640x480;
    logic clk = 0, reset_n = 0, pixel_ce = 1;
    logic [9:0] pixel_x, pixel_y;
    logic active_video, hsync_n, vsync_n, frame_start;
    integer low_hsync_count;
    integer total_count;
    always #1 clk = ~clk;

    vga_timing_640x480 dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_vga_timing_640x480: %s", msg); $fatal(1); end
    endtask

    initial begin
        repeat (2) @(posedge clk); reset_n = 1;
        @(posedge clk); #0;

        low_hsync_count = 0;
        for (integer i=0; i<800; i=i+1) begin
            #1;
            if (!hsync_n) low_hsync_count = low_hsync_count + 1;
            @(posedge clk);
        end
        if (low_hsync_count != 96) begin
            $display("hsync low pixels=%0d", low_hsync_count);
            fail("horizontal sync width mismatch");
        end

        total_count = 800;
        while (!frame_start && total_count < 800*526) begin
            @(posedge clk); #1;
            total_count = total_count + 1;
        end
        if (!frame_start) fail("frame_start never asserted");
        if (pixel_x !== 0 || pixel_y !== 0) fail("frame did not wrap to origin");

        // Pixel (0,0) is visible; first porch pixel is not.
        if (!active_video) fail("origin should be active video");

        $display("PASS tb_vga_timing_640x480"); $finish;
    end
endmodule
