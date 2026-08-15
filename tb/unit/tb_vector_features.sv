`timescale 1ns/1ps
module tb_vector_features;
    logic clk = 0, reset_n = 0, in_valid = 0;
    logic signed [15:0] x_in = 0, y_in = 0, z_in = 0;
    logic out_valid;
    logic [33:0] magnitude_sq;
    logic [17:0] rate_of_change;
    always #5 clk = ~clk;

    vector_features dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_vector_features: %s", msg); $fatal(1); end
    endtask

    task automatic drive(input logic signed [15:0] x, input logic signed [15:0] y, input logic signed [15:0] z);
        begin
            @(posedge clk); x_in <= x; y_in <= y; z_in <= z; in_valid <= 1;
            @(posedge clk); in_valid <= 0; #1;
            if (!out_valid) fail("out_valid missing");
        end
    endtask

    initial begin
        repeat (2) @(posedge clk); reset_n = 1;
        drive(16'sd3, 16'sd4, 16'sd12);
        if (magnitude_sq !== 34'd169) fail("first squared magnitude mismatch");
        if (rate_of_change !== 18'd0) fail("first ROC must be zero");

        drive(16'sd6, 16'sd4, 16'sd8);
        if (magnitude_sq !== 34'd116) fail("second squared magnitude mismatch");
        if (rate_of_change !== 18'd7) fail("ROC mismatch");

        drive(-16'sd32768, 16'sd0, 16'sd0);
        if (magnitude_sq !== 34'd1073741824) fail("signed extreme square mismatch");

        $display("PASS tb_vector_features"); $finish;
    end
endmodule
