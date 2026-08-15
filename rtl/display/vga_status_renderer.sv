`timescale 1ns/1ps
module vga_status_renderer (
    input  logic active_video,
    input  logic [9:0] pixel_x,
    input  logic [9:0] pixel_y,
    input  logic signed [15:0] x_value,
    input  logic signed [15:0] y_value,
    input  logic signed [15:0] z_value,
    input  logic [2:0] event_state,
    input  logic sensor_error,
    input  logic logger_frozen,
    input  logic [15:0] threshold_code,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
);
    logic [15:0] abs_x;
    logic [15:0] abs_y;
    logic [15:0] abs_z;
    logic [8:0] width_x;
    logic [8:0] width_y;
    logic [8:0] width_z;
    logic [8:0] threshold_x;

    function automatic logic [15:0] abs16(input logic signed [15:0] value);
        begin
            if (value == -16'sd32768)
                abs16 = 16'h7FFF;
            else
                abs16 = value[15] ? -value : value;
        end
    endfunction

    function automatic logic [8:0] cap_width(input logic [15:0] magnitude);
        logic [15:0] shifted;
        begin
            shifted = magnitude >> 2;
            if (shifted > 16'd220)
                cap_width = 9'd220;
            else
                cap_width = shifted[8:0];
        end
    endfunction

    always_comb begin
        abs_x = abs16(x_value);
        abs_y = abs16(y_value);
        abs_z = abs16(z_value);
        width_x = cap_width(abs_x);
        width_y = cap_width(abs_y);
        width_z = cap_width(abs_z);

        if ((threshold_code >> 2) > 16'd220)
            threshold_x = 9'd220;
        else
            threshold_x = threshold_code[10:2];

        red   = 4'h0;
        green = 4'h0;
        blue  = 4'h0;

        if (active_video) begin
            // Dark-blue engineering background and light grid.
            blue = 4'h1;
            if ((pixel_x == 10'd80)  || (pixel_x == 10'd160) ||
                (pixel_x == 10'd240) || (pixel_x == 10'd400) ||
                (pixel_x == 10'd480) || (pixel_x == 10'd560) ||
                (pixel_y == 10'd60)  || (pixel_y == 10'd120) ||
                (pixel_y == 10'd180) || (pixel_y == 10'd240) ||
                (pixel_y == 10'd300) || (pixel_y == 10'd360) ||
                (pixel_y == 10'd420)) begin
                red   = 4'h2;
                green = 4'h2;
                blue  = 4'h3;
            end

            // Center reference line.
            if (pixel_x == 10'd320) begin
                red   = 4'h5;
                green = 4'h5;
                blue  = 4'h5;
            end

            // Threshold markers around the center.
            if ((pixel_x == 10'd320 + threshold_x) ||
                (pixel_x + threshold_x == 10'd320)) begin
                red   = 4'h8;
                green = 4'h8;
                blue  = 4'h0;
            end

            // X-axis bar, y=90..129, red.
            if ((pixel_y >= 10'd90) && (pixel_y < 10'd130)) begin
                if ((!x_value[15] && pixel_x >= 10'd320 && pixel_x < 10'd320 + width_x) ||
                    ( x_value[15] && pixel_x <  10'd320 && pixel_x + width_x >= 10'd320)) begin
                    red   = 4'hF;
                    green = 4'h2;
                    blue  = 4'h2;
                end
            end

            // Y-axis bar, y=200..239, green.
            if ((pixel_y >= 10'd200) && (pixel_y < 10'd240)) begin
                if ((!y_value[15] && pixel_x >= 10'd320 && pixel_x < 10'd320 + width_y) ||
                    ( y_value[15] && pixel_x <  10'd320 && pixel_x + width_y >= 10'd320)) begin
                    red   = 4'h2;
                    green = 4'hF;
                    blue  = 4'h2;
                end
            end

            // Z-axis bar, y=310..349, cyan.
            if ((pixel_y >= 10'd310) && (pixel_y < 10'd350)) begin
                if ((!z_value[15] && pixel_x >= 10'd320 && pixel_x < 10'd320 + width_z) ||
                    ( z_value[15] && pixel_x <  10'd320 && pixel_x + width_z >= 10'd320)) begin
                    red   = 4'h2;
                    green = 4'hD;
                    blue  = 4'hF;
                end
            end

            // Status strip at bottom.
            if (pixel_y >= 10'd430) begin
                if (sensor_error) begin
                    red   = 4'hF;
                    green = 4'h0;
                    blue  = 4'h0;
                end else if (logger_frozen) begin
                    red   = 4'hF;
                    green = 4'h8;
                    blue  = 4'h0;
                end else if (event_state == 3'd2 || event_state == 3'd3) begin
                    red   = 4'hF;
                    green = 4'h0;
                    blue  = 4'hF;
                end else begin
                    red   = 4'h0;
                    green = 4'h7;
                    blue  = 4'h2;
                end
            end
        end
    end
endmodule
