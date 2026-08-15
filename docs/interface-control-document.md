# Interface Control Document

This document defines the stable internal interfaces for the initial RTL baseline. All signals are synchronous to `CLOCK_50` unless explicitly identified as physical I/O.

## Reset

`reset_sync`

| Signal | Dir | Description |
|---|---|---|
| `clk` | in | 50 MHz system clock |
| `async_reset_n` | in | board pushbutton reset, active low |
| `reset_n` | out | asynchronously asserted, synchronously deasserted reset |

## Sample timer

`sample_timer`

| Signal | Dir | Description |
|---|---|---|
| `enable` | in | enables cadence counter |
| `sample_tick` | out | one-clock pulse every `CLK_FREQ_HZ/SAMPLE_RATE_HZ` clocks |

Baseline parameters: 50,000,000 Hz / 100 Hz = 500,000 clocks per sample.

## SPI byte master

`spi_byte_master`

| Signal | Dir | Description |
|---|---|---|
| `start` | in | one-clock request to transfer one byte |
| `tx_byte[7:0]` | in | MSB-first transmit byte |
| `rx_byte[7:0]` | out | received byte, valid when `done=1` |
| `busy` | out | transaction active |
| `done` | out | one-clock completion pulse |
| `sclk` | out | SPI mode-3 clock, idle high |
| `mosi` | out | ADXL345 SDI |
| `miso` | in | ADXL345 SDO |

Chip select is intentionally not part of this module; the sensor controller must hold CS low across a multi-byte burst.

## ADXL345 controller

`adxl345_controller`

### Upstream control

- `sample_request`: one-clock request; ignored until initialization completes or while busy.
- `initialized`: asserted after successful DEVID check and initialization writes.
- `sensor_error`: sticky until reset if DEVID is wrong or a byte transaction times out.

### Sample interface

- `accel_x`, `accel_y`, `accel_z`: signed 16-bit reconstructed sensor samples.
- `sample_valid`: one-clock pulse after all six burst-read data bytes are assembled.

### SPI-engine interface

- outputs: `spi_start`, `spi_tx_byte`, `cs_n`;
- inputs: `spi_busy`, `spi_done`, `spi_rx_byte`.

## Calibration

`axis_calibration`

```text
sample_out = saturate16(sample_in - offset)
```

`out_valid` follows each accepted `in_valid` sample by one clock.

## IIR filter

`iir_lowpass_axis`

```text
state += ((sample_in << FRAC_BITS) - state) >>> ALPHA_SHIFT
sample_out = state >>> FRAC_BITS
```

`out_valid` follows accepted `in_valid` by one clock. Three instances operate independently but remain aligned because they receive the same `in_valid`.

## Vector features

`vector_features`

Inputs: three signed 16-bit filtered axes and `in_valid`.

Outputs:

- `magnitude_sq[33:0]` = `X²+Y²+Z²`;
- `rate_of_change[17:0]` = sum of absolute per-axis differences from the preceding valid sample;
- `out_valid` one clock after `in_valid`.

## Event FSM

`event_fsm`

Inputs:

- `enable`;
- `sample_valid`;
- `metric[33:0]`;
- `threshold_code[15:0]`.

Outputs:

- `state[2:0]`;
- `event_pulse` one clock on accepted event;
- `event_count[15:0]` saturating event counter.

All timing parameters are expressed in valid samples, not system-clock cycles.

## Triggered logger

`triggered_circular_buffer`

Inputs:

- `sample_valid`;
- `trigger`;
- `record_in[RECORD_WIDTH-1:0]`;
- synchronous `rd_addr`.

Outputs:

- `rd_data`;
- `write_ptr`;
- `trigger_addr`;
- `triggered`;
- `frozen`;
- `valid_record_count`.

The first trigger is accepted. Later triggers are ignored until reset/rearm.

## Top-level board ports

The top-level uses Terasic-style logical port names so vendor pin assignments can be imported directly:

```text
CLOCK_50
KEY[1:0]
SW[9:0]
LEDR[9:0]
HEX0..HEX5[7:0]
GSENSOR_CS_N
GSENSOR_SCLK
GSENSOR_SDI
GSENSOR_SDO
VGA_R/G/B[3:0]
VGA_HS
VGA_VS
```

The pin-import script is authoritative for physical package locations.
