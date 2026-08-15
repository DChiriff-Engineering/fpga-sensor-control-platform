# FPGA Real-Time Sensor Acquisition, DSP & Control Platform

**Status:** Planned — architecture and execution plan established; implementation has not started.

A DE10-Lite / Intel MAX 10 engineering project designed to demonstrate modular RTL, real-time sensor acquisition, fixed-point signal processing, event/control logic, triggered data capture, verification, hardware debugging, and timing closure.

> No performance or completion claims are made yet. Results will be added only after simulation and hardware verification.

## Problem

Create a processor-free FPGA instrumentation pipeline that acquires three-axis motion data from the onboard accelerometer, conditions the data in fixed-point RTL, detects configurable events, captures pre/post-trigger history, and exposes system status for physical validation.

## Planned Signal Path

```text
Accelerometer
    ↓ SPI
Acquisition / sample timing
    ↓
Calibration
    ↓
Fixed-point filtering
    ↓
Feature extraction
    ↓
Hysteretic event FSM
    ↓
Triggered circular buffer
    ↓
LED / seven-segment / optional VGA
```

## Primary Engineering Goals

- modular Verilog/SystemVerilog architecture;
- reliable SPI sensor interface;
- explicit fixed-point numeric design;
- event detection with hysteresis and state-machine behavior;
- circular pre/post-trigger capture;
- self-checking simulation;
- SignalTap/on-chip debug;
- real timing/resource analysis;
- repeatable physical validation.

## Planned Documentation

- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Verification Plan](docs/verification-plan.md)
- [Roadmap](ROADMAP.md)

## Results

_Not yet available._

## Skills This Project Is Intended to Demonstrate

Verilog/SystemVerilog · FPGA architecture · SPI · fixed-point DSP · FSM design · block RAM · verification · SignalTap · timing analysis
