module fpga_sensor_control_top (
    input  logic        CLOCK_50,
    input  logic [1:0]  KEY,
    input  logic [9:0]  SW,
    output logic [9:0]  LEDR,
    output logic [7:0]  HEX0,
    output logic [7:0]  HEX1,
    output logic [7:0]  HEX2,
    output logic [7:0]  HEX3,
    output logic [7:0]  HEX4,
    output logic [7:0]  HEX5,

    output logic        GSENSOR_CS_N,
    output logic        GSENSOR_SCLK,
    output logic        GSENSOR_SDI,
    input  logic        GSENSOR_SDO,

    output logic [3:0]  VGA_R,
    output logic [3:0]  VGA_G,
    output logic [3:0]  VGA_B,
    output logic        VGA_HS,
    output logic        VGA_VS
);
    logic reset_n;
    logic rearm;

    reset_sync u_reset_sync (
        .clk(CLOCK_50),
        .async_reset_n(KEY[0]),
        .reset_n(reset_n)
    );

    assign rearm = ~KEY[1];

    // ---------------------------------------------------------------------
    // Sensor timing and SPI acquisition
    // ---------------------------------------------------------------------
    logic sample_tick;
    logic sensor_initialized;
    logic sensor_error;
    logic sensor_busy;
    logic signed [15:0] raw_x;
    logic signed [15:0] raw_y;
    logic signed [15:0] raw_z;
    logic raw_valid;

    logic spi_start;
    logic [7:0] spi_tx_byte;
    logic [7:0] spi_rx_byte;
    logic spi_busy;
    logic spi_done;

    sample_timer #(
        .CLK_FREQ_HZ(50_000_000),
        .SAMPLE_RATE_HZ(100)
    ) u_sample_timer (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .enable(sensor_initialized && !sensor_error),
        .sample_tick(sample_tick)
    );

    spi_byte_master #(
        .CLK_DIV(25)
    ) u_spi_byte_master (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .start(spi_start),
        .tx_byte(spi_tx_byte),
        .rx_byte(spi_rx_byte),
        .busy(spi_busy),
        .done(spi_done),
        .sclk(GSENSOR_SCLK),
        .mosi(GSENSOR_SDI),
        .miso(GSENSOR_SDO)
    );

    adxl345_controller #(
        .STARTUP_CYCLES(50_000),
        .TIMEOUT_CYCLES(5_000)
    ) u_adxl345_controller (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .sample_request(sample_tick),
        .initialized(sensor_initialized),
        .sensor_error(sensor_error),
        .controller_busy(sensor_busy),
        .accel_x(raw_x),
        .accel_y(raw_y),
        .accel_z(raw_z),
        .sample_valid(raw_valid),
        .cs_n(GSENSOR_CS_N),
        .spi_start(spi_start),
        .spi_tx_byte(spi_tx_byte),
        .spi_rx_byte(spi_rx_byte),
        .spi_busy(spi_busy),
        .spi_done(spi_done)
    );

    logic [15:0] missed_sample_count;
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            missed_sample_count <= 16'd0;
        end else if (sample_tick && sensor_busy && missed_sample_count != 16'hFFFF) begin
            missed_sample_count <= missed_sample_count + 1'b1;
        end
    end

    // ---------------------------------------------------------------------
    // Calibration and fixed-point filtering
    // Hardware-derived offsets intentionally default to zero until measured.
    // ---------------------------------------------------------------------
    logic cal_valid_x, cal_valid_y, cal_valid_z;
    logic signed [15:0] cal_x, cal_y, cal_z;

    axis_calibration u_cal_x (
        .clk(CLOCK_50), .reset_n(reset_n), .in_valid(raw_valid),
        .sample_in(raw_x), .offset(16'sd0), .out_valid(cal_valid_x), .sample_out(cal_x)
    );
    axis_calibration u_cal_y (
        .clk(CLOCK_50), .reset_n(reset_n), .in_valid(raw_valid),
        .sample_in(raw_y), .offset(16'sd0), .out_valid(cal_valid_y), .sample_out(cal_y)
    );
    axis_calibration u_cal_z (
        .clk(CLOCK_50), .reset_n(reset_n), .in_valid(raw_valid),
        .sample_in(raw_z), .offset(16'sd0), .out_valid(cal_valid_z), .sample_out(cal_z)
    );

    logic filt_valid_x, filt_valid_y, filt_valid_z;
    logic signed [15:0] filt_x, filt_y, filt_z;

    iir_lowpass_axis #(.ALPHA_SHIFT(3), .FRAC_BITS(8)) u_filter_x (
        .clk(CLOCK_50), .reset_n(reset_n), .in_valid(cal_valid_x),
        .sample_in(cal_x), .out_valid(filt_valid_x), .sample_out(filt_x)
    );
    iir_lowpass_axis #(.ALPHA_SHIFT(3), .FRAC_BITS(8)) u_filter_y (
        .clk(CLOCK_50), .reset_n(reset_n), .in_valid(cal_valid_y),
        .sample_in(cal_y), .out_valid(filt_valid_y), .sample_out(filt_y)
    );
    iir_lowpass_axis #(.ALPHA_SHIFT(3), .FRAC_BITS(8)) u_filter_z (
        .clk(CLOCK_50), .reset_n(reset_n), .in_valid(cal_valid_z),
        .sample_in(cal_z), .out_valid(filt_valid_z), .sample_out(filt_z)
    );

    // ---------------------------------------------------------------------
    // Feature extraction and event detection
    // ---------------------------------------------------------------------
    logic feature_valid;
    logic [33:0] magnitude_sq;
    logic [17:0] rate_of_change;

    vector_features u_vector_features (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .in_valid(filt_valid_x && filt_valid_y && filt_valid_z),
        .x_in(filt_x),
        .y_in(filt_y),
        .z_in(filt_z),
        .out_valid(feature_valid),
        .magnitude_sq(magnitude_sq),
        .rate_of_change(rate_of_change)
    );

    logic [15:0] threshold_code;
    assign threshold_code = 16'd320 + {6'd0, SW};

    logic [2:0] event_state;
    logic event_pulse;
    logic [15:0] event_count;

    event_fsm #(
        .DWELL_SAMPLES(2),
        .HOLD_SAMPLES(10),
        .RECOVERY_SAMPLES(3),
        .HYSTERESIS_CODES(32)
    ) u_event_fsm (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .enable(sensor_initialized && !sensor_error),
        .sample_valid(feature_valid),
        .metric(magnitude_sq),
        .threshold_code(threshold_code),
        .state(event_state),
        .event_pulse(event_pulse),
        .event_count(event_count)
    );

    // ---------------------------------------------------------------------
    // One-stage record alignment: event_pulse is registered by the FSM at
    // the same edge that accepts feature_valid. Delay the associated record
    // one cycle so the trigger and event-causing sample enter the logger together.
    // ---------------------------------------------------------------------
    logic logger_valid;
    logic [23:0] sample_index;
    logic [23:0] logger_sample_index;
    logic signed [15:0] logger_x, logger_y, logger_z;
    logic [33:0] logger_metric;

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            logger_valid        <= 1'b0;
            sample_index        <= 24'd0;
            logger_sample_index <= 24'd0;
            logger_x            <= '0;
            logger_y            <= '0;
            logger_z            <= '0;
            logger_metric       <= '0;
        end else begin
            logger_valid <= feature_valid;
            if (feature_valid) begin
                logger_sample_index <= sample_index;
                logger_x            <= filt_x;
                logger_y            <= filt_y;
                logger_z            <= filt_z;
                logger_metric       <= magnitude_sq;
                sample_index        <= sample_index + 1'b1;
            end
        end
    end

    logic [111:0] logger_record;
    assign logger_record = {
        logger_sample_index,
        logger_x,
        logger_y,
        logger_z,
        logger_metric,
        event_state,
        3'b000
    };

    logic [7:0] logger_write_ptr;
    logic [7:0] logger_trigger_addr;
    logic logger_triggered;
    logic logger_frozen;
    logic [8:0] logger_valid_count;
    logic [111:0] logger_rd_data;

    triggered_circular_buffer #(
        .RECORD_WIDTH(112),
        .DEPTH(256),
        .POST_SAMPLES(64)
    ) u_triggered_buffer (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .rearm(rearm),
        .sample_valid(logger_valid),
        .trigger(event_pulse),
        .record_in(logger_record),
        .rd_addr(8'd0),
        .rd_data(logger_rd_data),
        .write_ptr(logger_write_ptr),
        .trigger_addr(logger_trigger_addr),
        .triggered(logger_triggered),
        .frozen(logger_frozen),
        .valid_record_count(logger_valid_count)
    );

    // ---------------------------------------------------------------------
    // Onboard status
    // ---------------------------------------------------------------------
    logic [7:0] sample_heartbeat;
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            sample_heartbeat <= 8'd0;
        else if (raw_valid)
            sample_heartbeat <= sample_heartbeat + 1'b1;
    end

    always_comb begin
        LEDR[0] = sensor_initialized;
        LEDR[1] = sensor_error;
        LEDR[2] = sample_heartbeat[5];
        LEDR[3] = (event_state == 3'd2) || (event_state == 3'd3);
        LEDR[4] = logger_triggered;
        LEDR[5] = logger_frozen;
        LEDR[6] = sensor_busy;
        LEDR[7] = (missed_sample_count != 16'd0);
        LEDR[8] = rearm;
        LEDR[9] = reset_n;
    end

    hex7seg u_hex0 (.value(event_count[3:0]),   .segments_n(HEX0));
    hex7seg u_hex1 (.value(event_count[7:4]),   .segments_n(HEX1));
    hex7seg u_hex2 (.value(event_count[11:8]),  .segments_n(HEX2));
    hex7seg u_hex3 (.value(event_count[15:12]), .segments_n(HEX3));
    hex7seg u_hex4 (.value({1'b0, event_state}), .segments_n(HEX4));

    always_comb begin
        if (sensor_error)
            HEX5 = 8'b1000_0110; // E
        else if (sensor_initialized)
            HEX5 = 8'b1000_1000; // A / active
        else
            HEX5 = 8'b1011_1111; // dash
    end

    // ---------------------------------------------------------------------
    // VGA should-have baseline. The whole design remains on CLOCK_50; a
    // 25 MHz clock-enable advances timing every other system-clock cycle.
    // ---------------------------------------------------------------------
    logic pixel_phase;
    logic pixel_ce;
    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic active_video;
    logic frame_start;

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n)
            pixel_phase <= 1'b0;
        else
            pixel_phase <= ~pixel_phase;
    end
    assign pixel_ce = pixel_phase;

    vga_timing_640x480 u_vga_timing (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .pixel_ce(pixel_ce),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active_video(active_video),
        .hsync_n(VGA_HS),
        .vsync_n(VGA_VS),
        .frame_start(frame_start)
    );

    vga_status_renderer u_vga_renderer (
        .active_video(active_video),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .x_value(filt_x),
        .y_value(filt_y),
        .z_value(filt_z),
        .event_state(event_state),
        .sensor_error(sensor_error),
        .logger_frozen(logger_frozen),
        .threshold_code(threshold_code),
        .red(VGA_R),
        .green(VGA_G),
        .blue(VGA_B)
    );
endmodule
