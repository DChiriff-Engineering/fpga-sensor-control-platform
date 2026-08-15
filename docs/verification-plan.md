# Verification Plan

## Unit-level simulation

- clock/sample timing;
- SPI transactions;
- accelerometer controller with mocked peripheral;
- calibration/filter arithmetic;
- magnitude/feature extraction;
- threshold/hysteresis boundaries;
- FSM transitions;
- circular buffer / trigger handling;
- VGA timing if VGA is implemented.

## Edge cases

- maximum positive/negative sample;
- exact threshold equality;
- repeated triggers;
- reset during event;
- missing/malformed sensor behavior where feasible.

## Hardware evidence

- physical sensor response;
- SignalTap internal captures;
- timing report;
- FPGA utilization;
- repeatable physical test matrix.

No requirement is considered verified until its acceptance criterion links to explicit evidence.
