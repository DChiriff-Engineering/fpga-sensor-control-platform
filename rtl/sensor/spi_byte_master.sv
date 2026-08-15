`timescale 1ns/1ps
module spi_byte_master #(
    // SPI SCLK = clk / (2 * CLK_DIV). At 50 MHz and CLK_DIV=25, SCLK=1 MHz.
    parameter integer CLK_DIV = 25
) (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       start,
    input  logic [7:0] tx_byte,
    output logic [7:0] rx_byte,
    output logic       busy,
    output logic       done,
    output logic       sclk,
    output logic       mosi,
    input  logic       miso
);
    localparam integer DIV_WIDTH = (CLK_DIV <= 1) ? 1 : $clog2(CLK_DIV);
    localparam logic [31:0] CLK_DIV_U = CLK_DIV;
    localparam logic [DIV_WIDTH-1:0] DIV_LAST = CLK_DIV_U[DIV_WIDTH-1:0] - 1'b1;

    logic [DIV_WIDTH-1:0] div_count;
    logic [7:0] tx_shift;
    logic [7:0] rx_shift;
    logic [2:0] bit_index;
    logic phase_rising;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rx_byte      <= 8'h00;
            busy         <= 1'b0;
            done         <= 1'b0;
            sclk         <= 1'b1; // mode 3: CPOL=1
            mosi         <= 1'b0;
            div_count    <= '0;
            tx_shift     <= 8'h00;
            rx_shift     <= 8'h00;
            bit_index    <= 3'd7;
            phase_rising <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!busy) begin
                sclk      <= 1'b1;
                mosi      <= 1'b0;
                div_count <= '0;
                if (start) begin
                    busy         <= 1'b1;
                    tx_shift     <= tx_byte;
                    rx_shift     <= 8'h00;
                    bit_index    <= 3'd7;
                    phase_rising <= 1'b0;
                end
            end else if (div_count == DIV_LAST) begin
                div_count <= '0;
                if (!phase_rising) begin
                    // Mode 3 changes data on the falling edge.
                    sclk         <= 1'b0;
                    mosi         <= tx_shift[7];
                    phase_rising <= 1'b1;
                end else begin
                    // Mode 3 samples data on the rising edge.
                    sclk     <= 1'b1;
                    rx_shift <= {rx_shift[6:0], miso};
                    if (bit_index == 3'd0) begin
                        rx_byte      <= {rx_shift[6:0], miso};
                        busy         <= 1'b0;
                        done         <= 1'b1;
                        mosi         <= 1'b0;
                        phase_rising <= 1'b0;
                    end else begin
                        tx_shift     <= {tx_shift[6:0], 1'b0};
                        bit_index    <= bit_index - 1'b1;
                        phase_rising <= 1'b0;
                    end
                end
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end
endmodule
