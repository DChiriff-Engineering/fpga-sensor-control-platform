# Roadmap

## Phase 0 — Requirements freeze
Define sampling behavior, filtering, thresholds, event capture, status outputs, and verification acceptance criteria.

## Phase 1 — Toolchain / board smoke test
Quartus + MAX 10 device support + USB-Blaster + basic switch→LED programming.

## Phase 2 — Accelerometer SPI subsystem
SPI master, initialization, X/Y/Z reads, signed sample formatting, hardware sanity check.

## Phase 3 — Synchronous processing pipeline
Calibration, fixed-point filter, derived motion metric, explicit valid/latency handling.

## Phase 4 — Event/control FSM
Threshold, hysteresis, dwell/hold/recovery, event counter.

## Phase 5 — Triggered buffer
Block-RAM circular capture with pre-trigger and post-trigger history.

## Phase 6 — Visualization / status
LED and seven-segment required; VGA is a should-have extension.

## Phase 7 — Verification and implementation evidence
Self-checking simulation, edge cases, SignalTap captures, timing closure, utilization.

## Phase 8 — Physical test campaign
Static orientation, stationary noise, step response, repeatability, threshold sweep, buffer verification.

## Phase 9 — Portfolio closeout
Architecture diagram, simulation evidence, hardware demo, timing/resource table, lessons learned.
