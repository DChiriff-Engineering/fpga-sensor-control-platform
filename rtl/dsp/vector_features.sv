`timescale 1ns/1ps
module vector_features (
    input  logic clk,
    input  logic reset_n,
    input  logic in_valid,
    input  logic signed [15:0] x_in,
    input  logic signed [15:0] y_in,
    input  logic signed [15:0] z_in,
    output logic out_valid,
    output logic [33:0] magnitude_sq,
    output logic [17:0] rate_of_change
);
    logic signed [15:0] prev_x;
    logic signed [15:0] prev_y;
    logic signed [15:0] prev_z;
    logic have_previous;

    logic signed [31:0] x_square_s;
    logic signed [31:0] y_square_s;
    logic signed [31:0] z_square_s;
    logic [33:0] magnitude_comb;

    logic signed [16:0] dx;
    logic signed [16:0] dy;
    logic signed [16:0] dz;
    logic [16:0] abs_dx;
    logic [16:0] abs_dy;
    logic [16:0] abs_dz;
    logic [17:0] roc_comb;

    function automatic logic [16:0] abs17(input logic signed [16:0] value);
        begin
            abs17 = value[16] ? -value : value;
        end
    endfunction

    assign x_square_s = $signed(x_in) * $signed(x_in);
    assign y_square_s = $signed(y_in) * $signed(y_in);
    assign z_square_s = $signed(z_in) * $signed(z_in);
    assign magnitude_comb = {2'b00, x_square_s[31:0]}
                          + {2'b00, y_square_s[31:0]}
                          + {2'b00, z_square_s[31:0]};

    assign dx = {x_in[15], x_in} - {prev_x[15], prev_x};
    assign dy = {y_in[15], y_in} - {prev_y[15], prev_y};
    assign dz = {z_in[15], z_in} - {prev_z[15], prev_z};
    assign abs_dx = abs17(dx);
    assign abs_dy = abs17(dy);
    assign abs_dz = abs17(dz);
    assign roc_comb = {1'b0, abs_dx} + {1'b0, abs_dy} + {1'b0, abs_dz};

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            prev_x         <= '0;
            prev_y         <= '0;
            prev_z         <= '0;
            have_previous  <= 1'b0;
            out_valid      <= 1'b0;
            magnitude_sq   <= '0;
            rate_of_change <= '0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                magnitude_sq <= magnitude_comb;
                if (have_previous)
                    rate_of_change <= roc_comb;
                else
                    rate_of_change <= '0;
                prev_x        <= x_in;
                prev_y        <= y_in;
                prev_z        <= z_in;
                have_previous <= 1'b1;
            end
        end
    end
endmodule
