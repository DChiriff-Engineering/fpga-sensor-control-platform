`timescale 1ns/1ps
module tb_adxl345_controller;
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
    integer delay_count = 0;
    logic [7:0] pending_rx = 0;

    always #5 clk = ~clk;

    adxl345_controller #(.STARTUP_CYCLES(2), .TIMEOUT_CYCLES(20)) dut (
        .clk, .reset_n, .sample_request,
        .initialized, .sensor_error, .controller_busy,
        .accel_x, .accel_y, .accel_z, .sample_valid,
        .cs_n, .spi_start, .spi_tx_byte,
        .spi_rx_byte, .spi_busy, .spi_done
    );

    function automatic logic [7:0] expected_tx(input integer idx);
        case (idx)
            0: expected_tx = 8'h80;
            1: expected_tx = 8'h00;
            2: expected_tx = 8'h31;
            3: expected_tx = 8'h09;
            4: expected_tx = 8'h2C;
            5: expected_tx = 8'h0A;
            6: expected_tx = 8'h2D;
            7: expected_tx = 8'h08;
            8: expected_tx = 8'hF2;
            default: expected_tx = 8'h00;
        endcase
    endfunction

    function automatic logic [7:0] expected_rx(input integer idx);
        case (idx)
            1:  expected_rx = 8'hE5;
            9:  expected_rx = 8'h34;
            10: expected_rx = 8'h12;
            11: expected_rx = 8'h78;
            12: expected_rx = 8'h56;
            13: expected_rx = 8'hBC;
            14: expected_rx = 8'h9A;
            default: expected_rx = 8'h00;
        endcase
    endfunction

    task automatic fail(input string msg);
        begin $display("FAIL tb_adxl345_controller: %s", msg); $fatal(1); end
    endtask

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            transaction_index <= 0;
            delay_count <= 0;
            spi_busy <= 0;
            spi_done <= 0;
            spi_rx_byte <= 0;
            pending_rx <= 0;
        end else begin
            spi_done <= 1'b0;
            if (!spi_busy && spi_start) begin
                if (spi_tx_byte !== expected_tx(transaction_index)) begin
                    $display("transaction %0d expected tx=%02x got=%02x", transaction_index, expected_tx(transaction_index), spi_tx_byte);
                    fail("unexpected SPI byte sequence");
                end
                pending_rx <= expected_rx(transaction_index);
                spi_busy <= 1'b1;
                delay_count <= 2;
            end else if (spi_busy) begin
                if (delay_count == 0) begin
                    spi_busy <= 1'b0;
                    spi_done <= 1'b1;
                    spi_rx_byte <= pending_rx;
                    transaction_index <= transaction_index + 1;
                end else begin
                    delay_count <= delay_count - 1;
                end
            end
        end
    end

    initial begin
        repeat (2) @(posedge clk);
        reset_n = 1;
        wait(initialized === 1'b1);
        #1;
        if (sensor_error) fail("sensor_error asserted during valid initialization");
        if (transaction_index != 8) fail("initialization transaction count mismatch");

        @(posedge clk);
        sample_request <= 1'b1;
        @(posedge clk);
        sample_request <= 1'b0;

        wait(sample_valid === 1'b1);
        #1;
        if (accel_x !== 16'sh1234) fail("X reconstruction mismatch");
        if (accel_y !== 16'sh5678) fail("Y reconstruction mismatch");
        if (accel_z !== 16'sh9ABC) fail("Z reconstruction mismatch");
        if (transaction_index != 15) fail("burst-read transaction count mismatch");
        if (cs_n !== 1'b1) fail("chip select not released after burst");

        $display("PASS tb_adxl345_controller");
        $finish;
    end
endmodule
