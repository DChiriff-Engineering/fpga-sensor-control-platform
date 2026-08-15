# Verification Plan

Verification is layered so a passing RTL simulation is never confused with passing hardware.

## Evidence levels

1. **Unit simulation** — module behavior under deterministic inputs.
2. **Integration simulation** — valid/latency alignment and subsystem interaction.
3. **Lint / compile hygiene** — synthesizable RTL passes automated static checks.
4. **Quartus implementation** — fitter and TimeQuest evidence on `10M50DAF484C7G`.
5. **SignalTap** — internal physical-hardware behavior.
6. **Physical campaign** — board movement and repeatability experiments.

## Automated unit tests

| Testbench | Primary behavior | Important boundaries |
|---|---|---|
| `tb_reset_sync` | reset synchronization | asynchronous assertion, two-stage synchronous deassertion |
| `tb_sample_timer` | exact sample cadence | disable/re-enable phase reset |
| `tb_spi_byte_master` | SPI mode-3 byte shift | MSB-first loopback, idle-high clock |
| `tb_adxl345_controller` | DEVID/config/read sequencing | coherent XYZ reconstruction, CS ownership |
| `tb_adxl345_error` | controller failure handling | wrong DEVID, transfer timeout, fail-closed state |
| `tb_axis_calibration` | offset correction | positive/negative saturation |
| `tb_iir_lowpass_axis` | fixed-point IIR | first sample, known step values |
| `tb_vector_features` | M² and ROC | first-sample ROC, signed extreme square |
| `tb_event_fsm` | event state machine | exact threshold equality, hysteresis equality, repeated event |
| `tb_triggered_circular_buffer` | ring/trigger/freeze | wrap, exact post count, ignored writes while frozen, rearm |
| `tb_hex7seg` | active-low decode | representative 0/A/F glyphs |
| `tb_vga_timing_640x480` | VGA counters/sync | 96-pixel HS pulse, frame wrap |
| `tb_vga_status_renderer` | status visualization | blanking, axis bar, error/frozen status colors |

## Integration simulation

`tb_processing_pipeline` drives synthetic signed accelerometer samples through calibration, IIR, vector features, event FSM, and the aligned trigger logger. Acceptance requires:

- an above-threshold sustained motion sequence creates an event;
- the event reaches the logger on the same delayed record as the event-causing feature sample;
- the logger captures post-trigger data and freezes;
- the integration test terminates with no assertion/fatal failure.

## Automated CI acceptance

`.github/workflows/rtl-verification.yml` installs Icarus Verilog and Verilator on Ubuntu, runs every self-checking testbench, then lints the synthesizable main RTL.

The current verified baseline passed **13/13 unit tests, 1/1 integration test, and Verilator lint**. Verilator uses `--Wall`; only intentional unused diagnostic/readback signals are exempted. All other lint warnings are fatal to CI.

CI proves only the committed source under those tools. It does **not** substitute for Quartus fitting/TimeQuest or board testing.

## Quartus / TimeQuest acceptance

After official Terasic pins are imported:

- correct device: `10M50DAF484C7G`;
- `CLOCK_50` constrained to 20.000 ns;
- compilation/fitter completes without unexplained critical warnings;
- worst setup slack recorded from TimeQuest;
- timing pass/fail recorded, not inferred;
- logic utilization, registers, memory bits/M9K blocks, DSP blocks, and PLL usage recorded from reports.

No numeric result is pre-filled in this repository.

## SignalTap plan

Capture a coherent window containing at least:

- sensor controller state / SPI start/done;
- `GSENSOR_CS_N`, `GSENSOR_SCLK`, `GSENSOR_SDI`, `GSENSOR_SDO` where practical;
- `raw_valid`, raw X/Y/Z;
- filtered X/Y/Z;
- `magnitude_sq`;
- event state and `event_pulse`;
- logger write pointer, trigger address, triggered/frozen.

Each screenshot must include a caption stating the condition, signals, and what behavior it verifies.

## Physical test matrix

| ID | Test | Method | Acceptance/evidence |
|---|---|---|---|
| HW-T1 | Static orientation | board flat, then controlled ±X/±Y orientations | axis signs/magnitudes respond coherently; SignalTap/screenshots retained |
| HW-T2 | Stationary behavior | board motionless ~60 s | characterize real raw/filtered variation; no fabricated noise number |
| HW-T3 | Step response | rapid but safe board rotation | quantify sample/filter/event latency from evidence |
| HW-T4 | Trigger repeatability | ~20 comparable manual events | report accepted/missed events honestly |
| HW-T5 | Threshold sweep | repeat events at multiple switch settings | demonstrate configured threshold effect and hysteresis |
| HW-T6 | Buffer verification | trigger once and inspect history | prove records exist on both sides of trigger address |
| HW-T7 | VGA | connect compatible monitor/cable if available | stable visible status screen; photo/screenshot retained |

## Edge cases required before final closeout

- maximum positive/negative signed values;
- exact high-threshold equality;
- exact low/hysteresis equality;
- repeated trigger attempts while logger is frozen;
- rearm operation;
- reset/disable during an event sequence;
- wrong/missing accelerometer response where feasible;
- startup behavior before sensor initialization.
