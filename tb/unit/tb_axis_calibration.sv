`timescale 1ns/1ps
module tb_axis_calibration;
    logic clk = 0, reset_n = 0, in_valid = 0;
    logic signed [15:0] sample_in = 0, offset = 0;
    logic out_valid;
    logic signed [15:0] sample_out;
    always #5 clk = ~clk;

    axis_calibration dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_axis_calibration: %s", msg); $fatal(1); end
    endtask

    task automatic check(input logic signed [15:0] s, input logic signed [15:0] o, input logic signed [15:0] expected);
        begin
            @(posedge clk); sample_in <= s; offset <= o; in_valid <= 1;
            @(posedge clk); in_valid <= 0; #1;
            if (!out_valid) fail("out_valid missing");
            if (sample_out !== expected) begin
                $display("expected=%0d actual=%0d", expected, sample_out);
                fail("calibration result mismatch");
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk); reset_n = 1;
        check(16'sd1000, 16'sd250, 16'sd750);
        check(16'sd32767, -16'sd1, 16'sd32767);
        check(-16'sd32768, 16'sd1, -16'sd32768);
        $display("PASS tb_axis_calibration"); $finish;
    end
endmodule
