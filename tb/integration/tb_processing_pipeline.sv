`timescale 1ns/1ps
module tb_processing_pipeline;
    logic clk = 0, reset_n = 0;
    logic raw_valid = 0;
    logic signed [15:0] raw_x = 0, raw_y = 0, raw_z = 0;
    always #5 clk = ~clk;

    logic cal_valid;
    logic signed [15:0] cal_x, cal_y, cal_z;
    logic fxv, fyv, fzv;
    logic signed [15:0] filt_x, filt_y, filt_z;
    logic feature_valid;
    logic [33:0] magnitude_sq;
    logic [17:0] rate_of_change;
    logic [2:0] event_state;
    logic event_pulse;
    logic [15:0] event_count;

    axis_calibration cx(.clk, .reset_n, .in_valid(raw_valid), .sample_in(raw_x), .offset(16'sd0), .out_valid(cal_valid), .sample_out(cal_x));
    axis_calibration cy(.clk, .reset_n, .in_valid(raw_valid), .sample_in(raw_y), .offset(16'sd0), .out_valid(), .sample_out(cal_y));
    axis_calibration cz(.clk, .reset_n, .in_valid(raw_valid), .sample_in(raw_z), .offset(16'sd0), .out_valid(), .sample_out(cal_z));

    iir_lowpass_axis #(.ALPHA_SHIFT(1), .FRAC_BITS(4)) fx(.clk, .reset_n, .in_valid(cal_valid), .sample_in(cal_x), .out_valid(fxv), .sample_out(filt_x));
    iir_lowpass_axis #(.ALPHA_SHIFT(1), .FRAC_BITS(4)) fy(.clk, .reset_n, .in_valid(cal_valid), .sample_in(cal_y), .out_valid(fyv), .sample_out(filt_y));
    iir_lowpass_axis #(.ALPHA_SHIFT(1), .FRAC_BITS(4)) fz(.clk, .reset_n, .in_valid(cal_valid), .sample_in(cal_z), .out_valid(fzv), .sample_out(filt_z));

    vector_features vf(.clk, .reset_n, .in_valid(fxv && fyv && fzv), .x_in(filt_x), .y_in(filt_y), .z_in(filt_z), .out_valid(feature_valid), .magnitude_sq, .rate_of_change);

    event_fsm #(.DWELL_SAMPLES(2), .HOLD_SAMPLES(1), .RECOVERY_SAMPLES(1), .HYSTERESIS_CODES(2)) ef(
        .clk, .reset_n, .enable(1'b1), .sample_valid(feature_valid), .metric(magnitude_sq), .threshold_code(16'd20), .state(event_state), .event_pulse, .event_count
    );

    logic logger_valid;
    logic [33:0] logger_metric;
    logic [15:0] logger_seq = 0;
    logic [31:0] logger_record;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            logger_valid <= 0; logger_metric <= 0; logger_seq <= 0;
        end else begin
            logger_valid <= feature_valid;
            if (feature_valid) begin
                logger_metric <= magnitude_sq;
                logger_seq <= logger_seq + 1'b1;
            end
        end
    end
    assign logger_record = {logger_seq, logger_metric[15:0]};

    logic [3:0] rd_addr, write_ptr, trigger_addr;
    logic [31:0] rd_data;
    logic triggered, frozen;
    logic [4:0] valid_record_count;
    triggered_circular_buffer #(.RECORD_WIDTH(32), .DEPTH(16), .POST_SAMPLES(2)) u_buffer(
        .clk, .reset_n, .rearm(1'b0), .sample_valid(logger_valid), .trigger(event_pulse), .record_in(logger_record),
        .rd_addr, .rd_data, .write_ptr, .trigger_addr, .triggered, .frozen, .valid_record_count
    );

    task automatic fail(input string msg);
        begin $display("FAIL tb_processing_pipeline: %s", msg); $fatal(1); end
    endtask

    task automatic send_sample(input logic signed [15:0] x, input logic signed [15:0] y, input logic signed [15:0] z);
        begin
            @(posedge clk); raw_x <= x; raw_y <= y; raw_z <= z; raw_valid <= 1;
            @(posedge clk); raw_valid <= 0;
            repeat (6) @(posedge clk);
        end
    endtask

    initial begin
        rd_addr = 0;
        repeat (3) @(posedge clk); reset_n = 1;

        // First low sample arms the FSM after pipeline fill.
        send_sample(16'sd5, 16'sd0, 16'sd0);
        send_sample(16'sd5, 16'sd0, 16'sd0);

        // Large motion sustained long enough for 2-sample dwell.
        send_sample(16'sd100, 16'sd0, 16'sd0);
        send_sample(16'sd100, 16'sd0, 16'sd0);
        send_sample(16'sd100, 16'sd0, 16'sd0);
        send_sample(16'sd100, 16'sd0, 16'sd0);
        send_sample(16'sd100, 16'sd0, 16'sd0);

        if (event_count < 1) fail("pipeline never generated an event");
        if (!triggered) fail("logger did not accept aligned event trigger");

        // Continue until the two post-trigger records are retained and logger freezes.
        send_sample(16'sd0, 16'sd0, 16'sd0);
        send_sample(16'sd0, 16'sd0, 16'sd0);
        repeat (10) @(posedge clk);
        if (!frozen) fail("logger did not freeze after post-trigger window");
        if (valid_record_count == 0) fail("logger retained no records");

        $display("PASS tb_processing_pipeline"); $finish;
    end
endmodule
