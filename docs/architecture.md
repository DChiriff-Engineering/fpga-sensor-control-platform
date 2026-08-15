# Architecture

## System context

The platform is a processor-free, 50 MHz synchronous SystemVerilog design for the Terasic DE10-Lite / Intel MAX 10 10M50DAF484C7G. The onboard Analog Devices ADXL345 is used in 4-wire SPI mode. The baseline sensor configuration is 100 Hz output data rate, full-resolution mode, ±4 g range, and measurement mode.

```text
50 MHz CLOCK_50
      |
      +--> reset synchronizer
      +--> 100 Hz sample timer
      |
      +--> SPI byte master <--> ADXL345 controller <--> onboard ADXL345
                                      |
                                      | signed X/Y/Z + sample_valid
                                      v
                               offset calibration
                                      |
                               1st-order IIR LPF
                                      |
                    +-----------------+------------------+
                    |                                    |
             squared magnitude                      rate of change
                    |                                    |
                    +-----------------+------------------+
                                      |
                              hysteretic event FSM
                                      |
                           event pulse / event count
                                      |
                         triggered circular capture
                                      |
                +---------------------+----------------------+
                |                     |                      |
              LEDs               seven-segment              VGA
```

## Module hierarchy

```text
fpga_sensor_control_top
├── reset_sync
├── sample_timer
├── spi_byte_master
├── adxl345_controller
├── axis_calibration x3
├── iir_lowpass_axis x3
├── vector_features
├── event_fsm
├── triggered_circular_buffer
├── hex7seg x5 + status glyph
├── vga_timing_640x480
└── vga_status_renderer
```

## Sensor acquisition

The ADXL345 controller owns chip-select and sequences byte transfers through a separate SPI byte engine. This isolates physical SPI timing from register/protocol behavior and allows the controller to be verified with a deterministic byte-level mock.

Startup sequence:

1. read `DEVID` (register `0x00`) and require `0xE5`;
2. write `DATA_FORMAT = 0x09` (full resolution, ±4 g, 4-wire SPI);
3. write `BW_RATE = 0x0A` (100 Hz output data rate);
4. write `POWER_CTL = 0x08` (measurement mode);
5. declare the sensor initialized;
6. on each sample request, issue one multi-byte read beginning at `DATAX0` (`0x32`) and capture six bytes coherently.

The SPI byte master uses mode 3 (CPOL=1, CPHA=1), MSB first, at a nominal 1 MHz SCLK from the 50 MHz system clock. Analog Devices documents mode 3 for ADXL345 4-wire SPI; 1 MHz is deliberately conservative relative to the device interface capability.

## Numeric pipeline

### Axis representation

ADXL345 output bytes are reconstructed as signed 16-bit two's-complement values. The full-resolution ±4 g configuration keeps the sensor's approximately 3.9 mg/LSB scale while allowing useful shock/motion headroom.

### Calibration

Each axis uses signed 16-bit runtime offset correction with saturation to `[-32768, 32767]`. The initial top-level offsets are zero. Actual calibration constants are hardware-evidence inputs and are not fabricated in RTL.

### Low-pass filter

Each axis uses a first-order IIR:

```text
y[n] = y[n-1] + (x[n] - y[n-1]) / 2^3
```

The implementation maintains eight fractional accumulator bits internally and presents a signed 16-bit integer output. With a 100 Hz sample rate, `alpha = 1/8` is a deliberately simple baseline that is easy to reason about, synthesize, and verify. It is a design choice, not an empirically optimized coefficient.

### Features

```text
M² = X² + Y² + Z²
ROC = |X-Xprev| + |Y-Yprev| + |Z-Zprev|
```

`M²` is 34 bits, avoiding a square-root block. The rate-of-change metric is 18 bits. The baseline event detector operates on `M²`; ROC is retained as a diagnostic/extension feature.

## Threshold mapping

The ten slide switches map to a raw magnitude threshold code:

```text
threshold_code = 320 + SW[9:0]
```

The comparator uses `threshold_code²`. The baseline thus begins above nominal 1 g gravity magnitude when all switches are low, reducing stationary false events. This mapping is intentionally code-domain based; a hardware session may refine it after actual orientation/noise data exist.

Hysteresis subtracts 32 raw codes from the active threshold before squaring the recovery boundary.

## Event FSM

```text
IDLE -> ARMED -> EVENT -> HOLD -> RECOVERY -> ARMED
```

- IDLE: acquisition not yet enabled.
- ARMED: wait for the configured number of consecutive samples at/above the high threshold.
- EVENT: one sample-domain state indicating an accepted event.
- HOLD: ignore immediate retriggers for a fixed sample count.
- RECOVERY: require consecutive samples at/below the hysteretic low threshold.

An `event_pulse` is emitted only on the ARMED-to-EVENT transition, and the event counter increments once per accepted event.

## Triggered circular capture

The baseline logger stores 256 records. Each 112-bit record contains:

```text
24-bit sample index
16-bit filtered X
16-bit filtered Y
16-bit filtered Z
34-bit squared magnitude
3-bit event state
3 reserved bits
```

Before a trigger, writes wrap continuously. On the first accepted event, the trigger address is retained and exactly 64 subsequent valid records are captured before the logger freezes. At 100 Hz, that corresponds to 0.64 s of post-trigger history and, once the ring is full, approximately 1.91 s of pre-trigger history.

## Displays

LEDs expose high-value state directly: sensor ready/error, sample activity, event state, event pulse, and capture freeze. Seven-segment displays show the event counter and FSM/sensor status.

The should-have VGA baseline uses standard 640×480 timing with a 25 MHz pixel-enable derived synchronously from the 50 MHz clock. It presents a deliberately simple engineering status visualization. Physical VGA timing/appearance remains unverified until board testing.

## Clock-domain policy

All logic remains in the `CLOCK_50` domain. Slow activity uses clock-enable pulses rather than internally generated clocks. The 25 MHz VGA rate is also implemented as a clock-enable, avoiding an unnecessary secondary clock domain.
