`timescale 1ns/1ps
module tb_spi_byte_master;
    logic clk = 0;
    logic reset_n = 0;
    logic start = 0;
    logic [7:0] tx_byte = 0;
    logic [7:0] rx_byte;
    logic busy, done, sclk, mosi;
    wire miso = mosi;

    always #5 clk = ~clk;

    spi_byte_master #(.CLK_DIV(2)) dut (
        .clk, .reset_n, .start, .tx_byte, .rx_byte,
        .busy, .done, .sclk, .mosi, .miso
    );

    task automatic fail(input string msg);
        begin $display("FAIL tb_spi_byte_master: %s", msg); $fatal(1); end
    endtask

    task automatic transfer(input logic [7:0] value);
        begin
            @(posedge clk);
            tx_byte <= value;
            start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            wait(done === 1'b1);
            #1;
            if (rx_byte !== value) fail("loopback byte mismatch");
            if (sclk !== 1'b1) fail("mode-3 clock did not return idle high");
            if (busy !== 1'b0) fail("busy remained asserted after done");
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        reset_n = 1;
        transfer(8'hA5);
        transfer(8'h3C);
        $display("PASS tb_spi_byte_master");
        $finish;
    end
endmodule
