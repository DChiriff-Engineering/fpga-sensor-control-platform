`timescale 1ns/1ps
module tb_adxl345_error;
    logic clk = 0;
    logic reset_n = 0;
    logic sample_request = 0;
    logic initialized, sensor_error, controller_busy;
    logic signed [15:0] accel_x, accel_y, accel_z;
    logic sample_valid;
    logic cs_n, spi_start;
    logic [7:0] spi_tx_byte;
    logic [7:0] spi_rx_byte = 0;
    logic spi_busy = 0;
    logic spi_done = 0;

    integer transaction_index = 0;
    logic return_bad_devid = 1'b1;
    logic suppress_completion = 1'b0;

    always #5 clk = ~clk;

    adxl345_controller #(.STARTUP_CYCLES(2), .TIMEOUT_CYCLES(4)) dut (
        .clk, .reset_n, .sample_request,
        .initialized, .sensor_error, .controller_busy,
        .accel_x, .accel_y, .accel_z, .sample_valid,
        .cs_n, .spi_start, .spi_tx_byte,
        .spi_rx_byte, .spi_busy, .spi_done
    );

    task automatic fail(input string msg);
        begin $display("FAIL tb_adxl345_error: %s", msg); $fatal(1); end
    endtask

    // Byte-level mock. In bad-DEVID mode it returns 0x00 instead of 0xE5.
    // In timeout mode it accepts start but never asserts done.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_busy <= 1'b0;
            spi_done <= 1'b0;
            spi_rx_byte <= 8'h00;
            transaction_index <= 0;
        end else begin
            spi_done <= 1'b0;
            if (!spi_busy && spi_start) begin
                transaction_index <= transaction_index + 1;
                if (suppress_completion) begin
                    spi_busy <= 1'b1;
                end else begin
                    spi_busy <= 1'b1;
                end
            end else if (spi_busy && !suppress_completion) begin
                spi_busy <= 1'b0;
                spi_done <= 1'b1;
                if (transaction_index == 2)
                    spi_rx_byte <= return_bad_devid ? 8'h00 : 8'hE5;
                else
                    spi_rx_byte <= 8'h00;
            end
        end
    end

    initial begin
        // Case 1: a wrong DEVID must fail closed before configuration.
        repeat (2) @(posedge clk);
        @(negedge clk); reset_n = 1'b1;
        wait(sensor_error === 1'b1);
        #1;
        if (initialized) fail("wrong DEVID incorrectly initialized the sensor");
        if (controller_busy) fail("controller remained busy after entering error state");
        if (cs_n !== 1'b1) fail("chip select was not released after DEVID failure");
        if (sample_valid) fail("sample_valid asserted in error state");

        // Case 2: reset, then suppress completion of the first byte transfer.
        @(negedge clk); reset_n = 1'b0;
        suppress_completion = 1'b1;
        return_bad_devid = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk); reset_n = 1'b1;
        wait(sensor_error === 1'b1);
        #1;
        if (initialized) fail("timeout incorrectly initialized the sensor");
        if (cs_n !== 1'b1) fail("chip select was not released after timeout");

        $display("PASS tb_adxl345_error");
        $finish;
    end
endmodule
