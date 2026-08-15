`timescale 1ns/1ps
module tb_triggered_circular_buffer;
    localparam integer RECORD_WIDTH = 16;
    logic clk = 0, reset_n = 0, rearm = 0, sample_valid = 0, trigger = 0;
    logic [RECORD_WIDTH-1:0] record_in = 0;
    logic [2:0] rd_addr = 0;
    logic [RECORD_WIDTH-1:0] rd_data;
    logic [2:0] write_ptr, trigger_addr;
    logic triggered, frozen;
    logic [3:0] valid_record_count;
    always #5 clk = ~clk;

    triggered_circular_buffer #(
        .RECORD_WIDTH(RECORD_WIDTH), .DEPTH(8), .POST_SAMPLES(2)
    ) dut (.*);

    task automatic fail(input string msg);
        begin $display("FAIL tb_triggered_circular_buffer: %s", msg); $fatal(1); end
    endtask

    task automatic push(input logic [15:0] value, input logic trig);
        begin
            @(posedge clk); record_in <= value; trigger <= trig; sample_valid <= 1;
            @(posedge clk); sample_valid <= 0; trigger <= 0; #1;
        end
    endtask

    task automatic check_mem(input logic [2:0] addr, input logic [15:0] expected);
        begin
            rd_addr <= addr;
            @(posedge clk); #1;
            if (rd_data !== expected) begin
                $display("addr=%0d expected=%0d actual=%0d", addr, expected, rd_data);
                fail("memory contents mismatch");
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk); reset_n = 1;

        for (integer i=0; i<8; i=i+1) push(i[15:0], 1'b0);
        if (write_ptr !== 3'd0) fail("ring did not wrap after depth records");
        if (valid_record_count !== 4'd8) fail("valid count did not saturate at depth");

        push(16'd8, 1'b1); // trigger address 0
        if (!triggered || trigger_addr !== 3'd0 || frozen) fail("trigger bookkeeping incorrect");
        push(16'd9, 1'b0);  // post 1
        if (frozen) fail("froze before all post-trigger samples");
        push(16'd10, 1'b0); // post 2 -> freeze
        if (!frozen) fail("did not freeze after exact post-trigger count");

        push(16'd99, 1'b0); // ignored while frozen
        check_mem(3'd0, 16'd8);
        check_mem(3'd1, 16'd9);
        check_mem(3'd2, 16'd10);
        check_mem(3'd3, 16'd3);
        check_mem(3'd7, 16'd7);

        @(posedge clk); rearm <= 1;
        @(posedge clk); rearm <= 0; #1;
        if (triggered || frozen || write_ptr != 0 || valid_record_count != 0) fail("rearm did not reset capture state");

        $display("PASS tb_triggered_circular_buffer"); $finish;
    end
endmodule
