# FPGA Sensor-Control Platform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the hardware-independent implementation baseline for the approved DE10-Lite real-time accelerometer acquisition, fixed-point DSP, hysteretic event detection, triggered capture, status, and VGA platform.

**Architecture:** A 50 MHz synchronous SystemVerilog design uses a byte-oriented SPI master plus ADXL345 controller, a valid-qualified DSP pipeline, a sample-domain event FSM, a block-RAM-friendly triggered circular buffer, and independent display/status modules. Hardware-facing pin assignments are imported from Terasic's official DE10-Lite Golden Top QSF instead of being guessed or redistributed; simulation and lint run in CI, while Quartus timing/resource results and board validation remain explicitly pending.

**Tech Stack:** SystemVerilog-2012, Icarus Verilog, Verilator, Intel Quartus Prime Lite / MAX 10, Terasic DE10-Lite (10M50DAF484C7G), Analog Devices ADXL345.

## Global Constraints

- Approved target: Terasic DE10-Lite / Intel MAX 10 10M50 FPGA.
- Primary HDL: Verilog/SystemVerilog; implementation uses SystemVerilog-2012.
- Primary sensor: onboard ADXL345 accelerometer over 4-wire SPI.
- Core path: acquisition -> calibration -> fixed-point filter -> feature extraction -> hysteretic event FSM -> triggered circular capture -> status/VGA.
- No unsupported completion, timing, resource, SignalTap, or physical-hardware claims.
- No license file is added; existing no-license repository status is preserved.
- Stretch features must remain droppable and may not destabilize the core.

---

### Task 1: Freeze interfaces, numeric formats, and board/tool assumptions

**Files:**
- Modify: `docs/requirements.md`
- Modify: `docs/architecture.md`
- Create: `docs/design-decisions.md`
- Create: `docs/interface-control-document.md`
- Create: `docs/hardware-bringup.md`

- [ ] Document 50 MHz system clock and sample-valid dataflow.
- [ ] Freeze ADXL345 initialization: DEVID check, 100 Hz ODR, full-resolution ±4 g, measurement mode.
- [ ] Freeze signed 16-bit axis samples, saturating offset correction, integer-output IIR with fractional accumulator, and 34-bit squared-magnitude metric.
- [ ] Freeze event threshold mapping and sample-domain FSM semantics.
- [ ] Freeze 256-record circular capture with 64 post-trigger samples.
- [ ] Document vendor-QSF import strategy and physical-hardware gate.

### Task 2: Implement timing, reset, SPI, and accelerometer acquisition RTL

**Files:**
- Create: `rtl/common/reset_sync.sv`
- Create: `rtl/acquisition/sample_timer.sv`
- Create: `rtl/sensor/spi_byte_master.sv`
- Create: `rtl/sensor/adxl345_controller.sv`
- Test: `tb/unit/tb_sample_timer.sv`
- Test: `tb/unit/tb_spi_byte_master.sv`
- Test: `tb/unit/tb_adxl345_controller.sv`

- [ ] Write self-checking testbenches first.
- [ ] Implement exact-cycle sample timer.
- [ ] Implement mode-3 SPI byte transfer with controller-owned chip select.
- [ ] Implement DEVID verification, initialization writes, six-byte coherent XYZ burst read, and timeout/error state.
- [ ] Verify expected command sequence and signed XYZ reconstruction.

### Task 3: Implement fixed-point DSP and feature extraction

**Files:**
- Create: `rtl/dsp/axis_calibration.sv`
- Create: `rtl/dsp/iir_lowpass_axis.sv`
- Create: `rtl/dsp/vector_features.sv`
- Test: `tb/unit/tb_axis_calibration.sv`
- Test: `tb/unit/tb_iir_lowpass_axis.sv`
- Test: `tb/unit/tb_vector_features.sv`

- [ ] Verify saturation at signed 16-bit limits.
- [ ] Verify first-order IIR step behavior and valid propagation.
- [ ] Verify squared-magnitude and rate-of-change arithmetic at normal and signed-extreme inputs.

### Task 4: Implement hysteretic event/control FSM

**Files:**
- Create: `rtl/control/event_fsm.sv`
- Test: `tb/unit/tb_event_fsm.sv`

- [ ] Implement IDLE -> ARMED -> EVENT -> HOLD -> RECOVERY sequence.
- [ ] Require configurable consecutive samples above threshold.
- [ ] Apply code-domain hysteresis on recovery.
- [ ] Verify equality boundaries, repeated events, disable/reset, dwell, hold, and recovery.

### Task 5: Implement triggered circular capture

**Files:**
- Create: `rtl/memory/triggered_circular_buffer.sv`
- Test: `tb/unit/tb_triggered_circular_buffer.sv`

- [ ] Infer synthesizable memory from a parameterized record array.
- [ ] Continuously overwrite history until first trigger.
- [ ] Preserve trigger address and exactly `POST_SAMPLES` later records.
- [ ] Freeze without overwriting evidence until reset/rearm.
- [ ] Verify wrap-around and pre/post-trigger preservation.

### Task 6: Implement onboard status and VGA should-have baseline

**Files:**
- Create: `rtl/display/hex7seg.sv`
- Create: `rtl/display/vga_timing_640x480.sv`
- Create: `rtl/display/vga_status_renderer.sv`
- Test: `tb/unit/tb_hex7seg.sv`
- Test: `tb/unit/tb_vga_timing_640x480.sv`

- [ ] Verify active-low seven-segment decode.
- [ ] Implement 640x480 timing from a 25 MHz pixel-enable derived synchronously from 50 MHz.
- [ ] Verify total timing and sync widths in simulation.
- [ ] Render a deliberately simple engineering status view; do not claim physical VGA validation.

### Task 7: Integrate the platform and add smoke top

**Files:**
- Create: `rtl/top/fpga_sensor_control_top.sv`
- Create: `rtl/top/de10_lite_smoke_top.sv`
- Test: `tb/integration/tb_processing_pipeline.sv`

- [ ] Wire ADXL345 acquisition to DSP, event FSM, logger, seven-segment, LEDs, and VGA.
- [ ] Map switches to a documented event threshold range.
- [ ] Keep physical sensor interrupt lines optional/unrequired.
- [ ] Add a minimal switch-to-LED smoke top for first-board programming.
- [ ] Verify processing/control/logger integration using synthetic samples independent of physical SPI.

### Task 8: Add Quartus scaffolding and vendor-pin import

**Files:**
- Create: `constraints/de10_lite.sdc`
- Create: `scripts/create_main_project.tcl`
- Create: `scripts/create_smoke_project.tcl`
- Create: `scripts/import_de10_lite_pins.tcl`
- Create: `scripts/program_main.tcl`

- [ ] Configure family `MAX 10` and device `10M50DAF484C7G`.
- [ ] Add all RTL and the 50 MHz SDC.
- [ ] Import only used location/I/O assignments from the user's official Terasic Golden Top QSF.
- [ ] Avoid guessing or vendoring Terasic pin files.
- [ ] Provide repeatable build/program commands for the later physical session.

### Task 9: Add automated verification and CI

**Files:**
- Create: `scripts/run_sim.sh`
- Create: `scripts/lint_rtl.sh`
- Create: `.github/workflows/rtl-verification.yml`

- [ ] Compile/run every unit and integration test with Icarus Verilog `-g2012`.
- [ ] Run Verilator lint on synthesizable RTL.
- [ ] Fail CI on any self-checking test failure.
- [ ] Keep Quartus/hardware results out of CI claims.

### Task 10: Publish recruiter-readable status and traceability

**Files:**
- Modify: `README.md`
- Modify: `ROADMAP.md`
- Modify: `docs/verification-plan.md`
- Create: `docs/test-results.md`
- Create: `docs/traceability.md`

- [ ] Distinguish RTL/simulation completion from hardware verification.
- [ ] Map requirements to modules and tests.
- [ ] Record CI evidence only after the workflow passes.
- [ ] Leave timing/resource/SignalTap/physical-result fields visibly pending instead of inventing values.
