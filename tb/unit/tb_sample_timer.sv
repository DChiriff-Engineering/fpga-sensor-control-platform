`timescale 1ns/1ps
module tb_sample_timer;
    logic clk = 0;
    logic reset_n = 0;
    logic enable = 0;
    logic sample_tick;

    always #5 clk = ~clk;

    sample_timer #(.CLK_FREQ_HZ(20), .SAMPLE_RATE_HZ(5)) dut (
        .clk, .reset_n, .enable, .sample_tick
    );

    task automatic fail(input string msg);
        begin $display("FAIL tb_sample_timer: %s", msg); $fatal(1); end
    endtask

    task automatic expect_cycle(input logic expected_tick, input string label);
        begin
            @(posedge clk);
            #1;
            if (sample_tick !== expected_tick) begin
                $display("%s expected_tick=%0b actual_tick=%0b", label, expected_tick, sample_tick);
                fail("sample_tick did not match expected cadence");
            end
        end
    endtask

    initial begin
        // Drive controls away from the DUT's active edge so the test has no
        // reset/enable scheduling race with the sequential implementation.
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset_n = 1;
        enable = 1;

        // PERIOD_CYCLES = 20 / 5 = 4. Expect a one-cycle pulse every fourth
        // enabled rising edge, beginning four full enabled clocks after start.
        repeat (3) expect_cycle(1'b0, "first period pre-tick");
        expect_cycle(1'b1, "first period tick");
        repeat (3) expect_cycle(1'b0, "second period pre-tick");
        expect_cycle(1'b1, "second period tick");
        repeat (3) expect_cycle(1'b0, "third period pre-tick");
        expect_cycle(1'b1, "third period tick");

        // Disable on a falling edge. The DUT resets phase and must not tick.
        @(negedge clk);
        enable = 0;
        repeat (3) expect_cycle(1'b0, "disabled");

        // Re-enable on a falling edge and verify phase starts over cleanly.
        @(negedge clk);
        enable = 1;
        repeat (3) expect_cycle(1'b0, "restart pre-tick");
        expect_cycle(1'b1, "restart tick");

        $display("PASS tb_sample_timer");
        $finish;
    end
endmodule
