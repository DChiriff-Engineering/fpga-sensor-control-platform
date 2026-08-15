`timescale 1ns/1ps
module tb_event_fsm;
    logic clk = 0, reset_n = 0, enable = 0, sample_valid = 0;
    logic [33:0] metric = 0;
    logic [15:0] threshold_code = 16'd10;
    logic [2:0] state;
    logic event_pulse;
    logic [15:0] event_count;
    always #5 clk = ~clk;

    event_fsm #(
        .DWELL_SAMPLES(2), .HOLD_SAMPLES(2), .RECOVERY_SAMPLES(2), .HYSTERESIS_CODES(4)
    ) dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_event_fsm: %s", msg); $fatal(1); end
    endtask

    task automatic sample(input logic [33:0] value);
        begin
            @(posedge clk); metric <= value; sample_valid <= 1;
            @(posedge clk); sample_valid <= 0; #1;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk); reset_n = 1; enable = 1;

        sample(34'd0); // IDLE -> ARMED
        if (state !== 3'd1) fail("did not enter ARMED");

        sample(34'd100); // equality is above threshold, dwell 1/2
        if (event_pulse) fail("event fired before dwell completed");
        if (state !== 3'd1) fail("left ARMED too early");

        sample(34'd100); // dwell 2/2 -> EVENT
        if (!event_pulse) fail("event pulse missing at threshold equality");
        if (state !== 3'd2) fail("did not enter EVENT");
        if (event_count !== 16'd1) fail("event counter mismatch");

        sample(34'd100); // EVENT -> HOLD
        if (state !== 3'd3) fail("did not enter HOLD");
        sample(34'd100); // hold 1/2
        if (state !== 3'd3) fail("HOLD duration too short");
        sample(34'd100); // hold 2/2 -> RECOVERY
        if (state !== 3'd4) fail("did not enter RECOVERY");

        // Low threshold is (10-4)^2 = 36; equality counts as recovered.
        sample(34'd36);
        if (state !== 3'd4) fail("RECOVERY duration too short");
        sample(34'd36);
        if (state !== 3'd1) fail("did not return to ARMED");

        // Verify a second accepted event increments exactly once.
        sample(34'd101);
        sample(34'd101);
        if (event_count !== 16'd2 || state !== 3'd2) fail("second event was not accepted cleanly");

        enable = 0;
        sample(34'd500);
        if (state !== 3'd0) fail("disable did not force IDLE");

        $display("PASS tb_event_fsm"); $finish;
    end
endmodule
