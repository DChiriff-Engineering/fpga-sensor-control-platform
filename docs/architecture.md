# Architecture

## Module hierarchy

```text
top_level
├── clock_reset
├── sensor_interface
│   ├── spi_master
│   └── accelerometer_controller
├── acquisition
│   ├── sample_timer
│   ├── sample_formatter
│   └── sample_valid_control
├── dsp
│   ├── calibration
│   ├── low_pass_filter
│   ├── magnitude_estimator
│   └── rate_of_change
├── event_detection
│   ├── threshold_comparator
│   ├── hysteresis
│   └── event_fsm
├── data_logger
│   ├── circular_buffer
│   └── trigger_controller
├── user_interface
│   ├── switches_buttons
│   ├── seven_segment
│   ├── led_pwm
│   └── vga_renderer
└── diagnostics
    ├── status_registers
    └── counters
```

## Numeric design principle

Fixed-point arithmetic will be explicit. Derived motion magnitude can use:

`M² = X² + Y² + Z²`

and compare `M²` against `threshold²`, avoiding unnecessary square-root logic.

Detailed word lengths and pipeline latency will be documented after sensor-format confirmation.
