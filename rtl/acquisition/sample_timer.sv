module sample_timer #(
    parameter integer CLK_FREQ_HZ    = 50_000_000,
    parameter integer SAMPLE_RATE_HZ = 100
) (
    input  logic clk,
    input  logic reset_n,
    input  logic enable,
    output logic sample_tick
);
    localparam integer PERIOD_CYCLES = CLK_FREQ_HZ / SAMPLE_RATE_HZ;
    localparam integer COUNTER_WIDTH = (PERIOD_CYCLES <= 1) ? 1 : $clog2(PERIOD_CYCLES);

    logic [COUNTER_WIDTH-1:0] counter;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter     <= '0;
            sample_tick <= 1'b0;
        end else begin
            sample_tick <= 1'b0;
            if (!enable) begin
                counter <= '0;
            end else if (counter == PERIOD_CYCLES - 1) begin
                counter     <= '0;
                sample_tick <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule
