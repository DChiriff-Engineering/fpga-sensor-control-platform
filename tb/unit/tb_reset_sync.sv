`timescale 1ns/1ps
module tb_reset_sync;
    logic clk = 0;
    logic async_reset_n = 1;
    logic reset_n;

    always #5 clk = ~clk;

    reset_sync dut (
        .clk,
        .async_reset_n,
        .reset_n
    );

    task automatic fail(input string msg);
        begin $display("FAIL tb_reset_sync: %s", msg); $fatal(1); end
    endtask

    initial begin
        // Generate an actual high-to-low transition; a signal initialized low
        // at time zero does not guarantee a negedge event in every simulator.
        #1;
        async_reset_n = 1'b0;
        #1;
        if (reset_n !== 1'b0) fail("reset must assert asynchronously");

        // Release away from the sampling edge. Two clean rising edges are
        // required before the synchronized reset deasserts.
        @(negedge clk);
        async_reset_n = 1'b1;
        @(posedge clk); #1;
        if (reset_n !== 1'b0) fail("reset deasserted after only one synchronizer stage");
        @(posedge clk); #1;
        if (reset_n !== 1'b1) fail("reset did not deassert after two rising edges");

        // Reassert between clocks and verify the output responds immediately.
        #2;
        async_reset_n = 1'b0;
        #1;
        if (reset_n !== 1'b0) fail("asynchronous reassertion did not propagate immediately");

        $display("PASS tb_reset_sync");
        $finish;
    end
endmodule
