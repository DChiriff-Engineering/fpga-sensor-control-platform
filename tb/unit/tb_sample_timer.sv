`timescale 1ns/1ps
module tb_sample_timer;
    logic clk = 0;
    logic reset_n = 0;
    logic enable = 0;
    logic sample_tick;
    integer tick_count = 0;
    integer cycle_since_tick = 0;

    always #5 clk = ~clk;

    sample_timer #(.CLK_FREQ_HZ(20), .SAMPLE_RATE_HZ(5)) dut (
        .clk, .reset_n, .enable, .sample_tick
    );

    task automatic fail(input string msg);
        begin $display("FAIL tb_sample_timer: %s", msg); $fatal(1); end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        reset_n = 1;
        enable = 1;

        repeat (12) begin
            @(posedge clk);
            #1;
            cycle_since_tick = cycle_since_tick + 1;
            if (sample_tick) begin
                tick_count = tick_count + 1;
                if (cycle_since_tick != 4) fail("tick spacing is not four clocks");
                cycle_since_tick = 0;
            end
        end
        if (tick_count != 3) fail("expected three ticks in twelve enabled cycles");

        enable = 0;
        repeat (3) @(posedge clk);
        #1;
        if (sample_tick) fail("tick asserted while disabled");

        enable = 1;
        cycle_since_tick = 0;
        repeat (4) @(posedge clk);
        #1;
        if (!sample_tick) fail("counter did not restart cleanly after disable");

        $display("PASS tb_sample_timer");
        $finish;
    end
endmodule
