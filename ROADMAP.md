# Roadmap

## Phase 0 — Requirements and architecture freeze

- [x] Preserve approved DE10-Lite / ADXL345 platform concept.
- [x] Freeze module interfaces, numeric widths, sensor baseline, event semantics, and logger size.
- [x] Document hardware-versus-simulation evidence rules.

## Phase 1 — Hardware-independent RTL baseline

- [x] 50 MHz reset/timing infrastructure.
- [x] SPI mode-3 byte engine.
- [x] ADXL345 DEVID check, initialization, and coherent six-byte XYZ read controller.
- [x] Saturating offset calibration.
- [x] Fixed-point IIR filtering.
- [x] Squared magnitude + rate-of-change feature extraction.
- [x] Hysteretic dwell/hold/recovery event FSM.
- [x] Triggered circular pre/post-event buffer.
- [x] LED/seven-segment status.
- [x] VGA 640×480 status baseline.
- [x] Main and minimal smoke-test top levels.

## Phase 2 — Automated RTL verification

- [x] Self-checking unit and integration testbenches written.
- [x] Icarus simulation runner written.
- [x] Verilator lint runner written.
- [x] GitHub Actions workflow written.
- [x] 14/14 self-checking simulations pass in GitHub Actions.
- [x] Strict Verilator RTL lint passes in GitHub Actions.

## Phase 3 — Toolchain / physical board smoke test

- [x] Quartus project-generation scripts written.
- [x] Official Terasic Golden Top pin-import script written.
- [x] 50 MHz SDC written.
- [ ] Confirm physical DE10-Lite and USB Type-B data cable.
- [ ] Install/verify current Quartus + MAX 10 support + USB-Blaster.
- [ ] Program switch-to-LED smoke design.
- [ ] Capture first hardware evidence.

## Phase 4 — Main hardware acquisition

- [ ] Compile/fitter main design with official vendor pin assignments.
- [ ] Program DE10-Lite and confirm ADXL345 DEVID/init success.
- [ ] Validate X/Y/Z orientation response.
- [ ] Inspect sample cadence and SPI transaction in SignalTap.

## Phase 5 — DSP / event / logger hardware validation

- [ ] Establish measured stationary offsets/noise.
- [ ] Enter measured offset constants or runtime calibration values.
- [ ] Validate filter response.
- [ ] Tune event threshold mapping only from physical evidence.
- [ ] Validate event dwell/hysteresis/hold/recovery.
- [ ] Prove pre/post-trigger buffer contents with SignalTap or readback evidence.

## Phase 6 — VGA and presentation

- [ ] Validate physical VGA timing/appearance if retained.
- [ ] Improve display only if it does not threaten core completion.
- [ ] Capture clean board/VGA photos.

## Phase 7 — Timing/resource closure

- [ ] Review all Quartus warnings.
- [ ] Record target clock and TimeQuest worst setup slack.
- [ ] Record logic/register/M9K/DSP/PLL utilization.
- [ ] Resolve timing issues before claiming completion.

## Phase 8 — Physical validation campaign

- [ ] Static orientation.
- [ ] Stationary noise.
- [ ] Step response.
- [ ] ~20-event repeatability run.
- [ ] Threshold sweep.
- [ ] Trigger-buffer verification.

## Phase 9 — Portfolio closeout

- [ ] Architecture/verification figures.
- [ ] Curated simulation waveforms and SignalTap captures with captions.
- [ ] Hardware result tables.
- [ ] 20–40 second demo.
- [ ] Resume bullet and interview story using actual measured results only.
