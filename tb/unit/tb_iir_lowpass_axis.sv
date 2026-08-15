`timescale 1ns/1ps
module tb_iir_lowpass_axis;
    logic clk = 0, reset_n = 0, in_valid = 0;
    logic signed [15:0] sample_in = 0;
    logic out_valid;
    logic signed [15:0] sample_out;
    always #5 clk = ~clk;

    iir_lowpass_axis #(.ALPHA_SHIFT(3), .FRAC_BITS(8)) dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_iir_lowpass_axis: %s", msg); $fatal(1); end
    endtask

    task automatic drive_and_check(input logic signed [15:0] value, input logic signed [15:0] expected);
        begin
            @(posedge clk); sample_in <= value; in_valid <= 1;
            @(posedge clk); in_valid <= 0; #1;
            if (!out_valid) fail("out_valid missing");
            if (sample_out !== expected) begin
                $display("input=%0d expected=%0d actual=%0d", value, expected, sample_out);
                fail("IIR output mismatch");
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk); reset_n = 1;
        drive_and_check(16'sd800, 16'sd800); // first sample initializes state
        drive_and_check(16'sd0,   16'sd700);
        drive_and_check(16'sd0,   16'sd612); // 612.5 truncates toward arithmetic floor
        $display("PASS tb_iir_lowpass_axis"); $finish;
    end
endmodule
