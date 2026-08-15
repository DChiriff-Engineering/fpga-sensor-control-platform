`timescale 1ns/1ps
module event_fsm #(
    parameter integer DWELL_SAMPLES    = 2,
    parameter integer HOLD_SAMPLES     = 10,
    parameter integer RECOVERY_SAMPLES = 3,
    parameter integer HYSTERESIS_CODES = 32
) (
    input  logic clk,
    input  logic reset_n,
    input  logic enable,
    input  logic sample_valid,
    input  logic [33:0] metric,
    input  logic [15:0] threshold_code,
    output logic [2:0] state,
    output logic event_pulse,
    output logic [15:0] event_count
);
    localparam logic [2:0] ST_IDLE     = 3'd0;
    localparam logic [2:0] ST_ARMED    = 3'd1;
    localparam logic [2:0] ST_EVENT    = 3'd2;
    localparam logic [2:0] ST_HOLD     = 3'd3;
    localparam logic [2:0] ST_RECOVERY = 3'd4;

    localparam logic [31:0] HYSTERESIS_CODES_U = HYSTERESIS_CODES;
    localparam logic [31:0] DWELL_SAMPLES_U = DWELL_SAMPLES;
    localparam logic [31:0] HOLD_SAMPLES_U = HOLD_SAMPLES;
    localparam logic [31:0] RECOVERY_SAMPLES_U = RECOVERY_SAMPLES;
    localparam logic [15:0] HYSTERESIS_CODE = HYSTERESIS_CODES_U[15:0];
    localparam logic [15:0] DWELL_LAST = (DWELL_SAMPLES <= 1) ? 16'd0 : DWELL_SAMPLES_U[15:0] - 1'b1;
    localparam logic [15:0] HOLD_LAST = (HOLD_SAMPLES <= 1) ? 16'd0 : HOLD_SAMPLES_U[15:0] - 1'b1;
    localparam logic [15:0] RECOVERY_LAST = (RECOVERY_SAMPLES <= 1) ? 16'd0 : RECOVERY_SAMPLES_U[15:0] - 1'b1;

    logic [15:0] dwell_count;
    logic [15:0] hold_count;
    logic [15:0] recovery_count;

    logic [15:0] low_threshold_code;
    logic [31:0] high_threshold_sq;
    logic [31:0] low_threshold_sq;

    always_comb begin
        if (threshold_code > HYSTERESIS_CODE)
            low_threshold_code = threshold_code - HYSTERESIS_CODE;
        else
            low_threshold_code = 16'd0;

        high_threshold_sq = threshold_code * threshold_code;
        low_threshold_sq  = low_threshold_code * low_threshold_code;
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state          <= ST_IDLE;
            event_pulse    <= 1'b0;
            event_count    <= 16'd0;
            dwell_count    <= 16'd0;
            hold_count     <= 16'd0;
            recovery_count <= 16'd0;
        end else begin
            event_pulse <= 1'b0;

            if (!enable) begin
                state          <= ST_IDLE;
                dwell_count    <= 16'd0;
                hold_count     <= 16'd0;
                recovery_count <= 16'd0;
            end else if (sample_valid) begin
                case (state)
                    ST_IDLE: begin
                        state       <= ST_ARMED;
                        dwell_count <= 16'd0;
                    end

                    ST_ARMED: begin
                        if (metric >= {2'b00, high_threshold_sq}) begin
                            if (DWELL_SAMPLES <= 1 || dwell_count >= DWELL_LAST) begin
                                state       <= ST_EVENT;
                                event_pulse <= 1'b1;
                                dwell_count <= 16'd0;
                                if (event_count != 16'hFFFF)
                                    event_count <= event_count + 1'b1;
                            end else begin
                                dwell_count <= dwell_count + 1'b1;
                            end
                        end else begin
                            dwell_count <= 16'd0;
                        end
                    end

                    ST_EVENT: begin
                        state      <= ST_HOLD;
                        hold_count <= 16'd0;
                    end

                    ST_HOLD: begin
                        if (HOLD_SAMPLES <= 1 || hold_count >= HOLD_LAST) begin
                            state          <= ST_RECOVERY;
                            hold_count     <= 16'd0;
                            recovery_count <= 16'd0;
                        end else begin
                            hold_count <= hold_count + 1'b1;
                        end
                    end

                    ST_RECOVERY: begin
                        if (metric <= {2'b00, low_threshold_sq}) begin
                            if (RECOVERY_SAMPLES <= 1 || recovery_count >= RECOVERY_LAST) begin
                                state          <= ST_ARMED;
                                recovery_count <= 16'd0;
                            end else begin
                                recovery_count <= recovery_count + 1'b1;
                            end
                        end else begin
                            recovery_count <= 16'd0;
                        end
                    end

                    default: state <= ST_IDLE;
                endcase
            end
        end
    end
endmodule
