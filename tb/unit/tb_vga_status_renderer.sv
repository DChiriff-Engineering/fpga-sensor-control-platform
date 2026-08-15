`timescale 1ns/1ps
module tb_vga_status_renderer;
    logic active_video = 0;
    logic [9:0] pixel_x = 0, pixel_y = 0;
    logic signed [15:0] x_value = 0, y_value = 0, z_value = 0;
    logic [2:0] event_state = 0;
    logic sensor_error = 0, logger_frozen = 0;
    logic [15:0] threshold_code = 16'd320;
    logic [3:0] red, green, blue;

    vga_status_renderer dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_vga_status_renderer: %s", msg); $fatal(1); end
    endtask

    initial begin
        // Blanking interval must be black regardless of status.
        active_video = 0;
        sensor_error = 1;
        pixel_y = 10'd450;
        #1;
        if ({red,green,blue} !== 12'h000) fail("blanking interval produced visible color");

        // Normal visible background is dark blue.
        active_video = 1;
        sensor_error = 0;
        pixel_x = 10'd10;
        pixel_y = 10'd10;
        #1;
        if ({red,green,blue} !== 12'h001) fail("normal background color mismatch");

        // Positive X bar extends right from center and is red-dominant.
        x_value = 16'sd200;
        pixel_x = 10'd340;
        pixel_y = 10'd100;
        #1;
        if (red !== 4'hF || green !== 4'h2 || blue !== 4'h2) fail("positive X bar not rendered");

        // Error state overrides the lower status strip with red.
        sensor_error = 1;
        pixel_x = 10'd100;
        pixel_y = 10'd450;
        #1;
        if ({red,green,blue} !== 12'hF00) fail("sensor-error status strip not red");

        // Frozen capture is orange when there is no sensor error.
        sensor_error = 0;
        logger_frozen = 1;
        #1;
        if ({red,green,blue} !== 12'hF80) fail("frozen-capture status strip not orange");

        $display("PASS tb_vga_status_renderer");
        $finish;
    end
endmodule
