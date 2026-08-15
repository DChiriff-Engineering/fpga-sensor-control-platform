# FPGA Real-Time Sensor Acquisition, DSP & Control Platform

**Status:** RTL implementation baseline complete; automated simulation/lint and physical DE10-Lite validation are the next gates.

A processor-free FPGA instrumentation platform for the Terasic DE10-Lite / Intel MAX 10. The design autonomously acquires the onboard ADXL345 accelerometer over SPI, applies fixed-point signal processing, detects motion events with a hysteretic sample-domain state machine, preserves triggered history in an inferred circular memory, and exposes live status through LEDs, seven-segment displays, and a simple VGA engineering view.

> No physical-hardware, timing-closure, resource-utilization, SignalTap, or measured-performance claims are made yet. Those results are added only after the corresponding evidence exists.

## Engineering objective

Build a small but complete FPGA instrumentation product rather than a classroom-style isolated module: explicit requirements, modular RTL, self-checking verification, board-aware project scaffolding, triggered capture, hardware-debug hooks, and a traceable path to Quartus timing/resource and physical validation.

## Signal path

```text
ADXL345 accelerometer
        |
        | 4-wire SPI, mode 3
        v
Register/init + coherent XYZ acquisition
        |
        | signed 16-bit samples + sample_valid
        v
Saturating offset correction
        v
Fixed-point first-order IIR (alpha = 1/8)
        v
+----------------------+----------------------+
| squared magnitude M² | rate-of-change metric|
+----------------------+----------------------+
        |
        v
Hysteretic event FSM
IDLE -> ARMED -> EVENT -> HOLD -> RECOVERY
        |
        v
256-record circular pre/post-trigger capture
        |
        +--> LEDs / 6 x seven-segment
        +--> 640x480 VGA status baseline
```

## Baseline configuration

- **Board:** Terasic DE10-Lite
- **FPGA:** Intel MAX 10 `10M50DAF484C7G`
- **System clock:** 50 MHz
- **HDL:** SystemVerilog-2012
- **Sensor:** onboard Analog Devices ADXL345
- **SPI:** 4-wire mode 3, MSB first, nominal 1 MHz SCLK
- **Sensor ODR:** 100 Hz
- **Sensor data format:** full resolution, ±4 g
- **Filter:** first-order fixed-point IIR, `alpha = 1/8`, eight fractional state bits
- **Event feature:** `M² = X² + Y² + Z²` (34 bits, no square root)
- **Threshold:** onboard switches mapped to a documented code-domain threshold
- **Logger:** 256 records, first-trigger capture, 64 post-trigger records
- **VGA:** 640×480 timing using a 25 MHz clock-enable in the 50 MHz domain

## Repository structure

```text
rtl/
├── common/          reset synchronization
├── sensor/          SPI byte engine + ADXL345 controller
├── acquisition/     100 Hz sample cadence
├── dsp/             calibration, IIR, vector features
├── control/         hysteretic event FSM
├── memory/          triggered circular buffer
├── display/         seven-segment + VGA timing/renderer
└── top/             main integration + switch/LED smoke top

tb/
├── unit/            self-checking module tests
└── integration/     processing/control/logger integration

constraints/         SDC timing constraints
scripts/             simulation, lint, Quartus creation/import/program scripts
quartus/             generated-project workspace guidance
docs/                requirements, architecture, interfaces, verification, bring-up
.github/workflows/    open-source RTL CI
```

## Verification strategy

The open-source CI path is designed to run every unit/integration test with Icarus Verilog and lint synthesizable RTL with Verilator. Testbenches cover:

- exact sample-timer cadence;
- SPI mode-3 byte transfer;
- ADXL345 DEVID/config/burst-read command sequencing;
- signed XYZ reconstruction;
- saturating offset correction;
- fixed-point IIR step behavior;
- squared magnitude and rate-of-change arithmetic;
- threshold equality, hysteresis, dwell, hold, recovery, repeated events;
- circular-buffer wrap, trigger address, exact post-trigger count, freeze/rearm;
- seven-segment decode;
- VGA sync timing;
- integrated DSP -> event -> logger behavior.

See [Verification Plan](docs/verification-plan.md), [Traceability](docs/traceability.md), and [Test Results](docs/test-results.md).

## Board pin strategy

The repository deliberately does **not** guess package pins or redistribute a copied Terasic board QSF. `scripts/import_de10_lite_pins.tcl` imports only the project-visible pin/I/O assignments from the official Golden Top QSF in the user's Terasic System CD. This makes the board mapping traceable to the vendor package and reduces transcription risk.

A separate `de10_lite_smoke_top` exists for the first physical milestone: each switch directly controls its corresponding LED. That smoke test must program successfully before the main accelerometer design is treated as a hardware target.

## Hardware-dependent evidence still required

- switch-to-LED physical smoke test;
- successful main Quartus compile/fitter run with imported vendor pins;
- actual TimeQuest worst setup slack / timing pass-fail;
- actual logic/register/M9K/DSP/PLL utilization;
- ADXL345 sensor response on the physical board;
- SignalTap captures of acquisition, DSP, FSM, and logger internals;
- static orientation, stationary noise, step response, trigger repeatability, threshold sweep, and buffer validation;
- physical VGA screenshot if VGA is retained in final scope;
- short demo video/GIF.

## Documentation

- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [Design Decisions](docs/design-decisions.md)
- [Interface Control Document](docs/interface-control-document.md)
- [Verification Plan](docs/verification-plan.md)
- [Traceability Matrix](docs/traceability.md)
- [Hardware Bring-Up](docs/hardware-bringup.md)
- [Test Results](docs/test-results.md)
- [Roadmap](ROADMAP.md)
- [Technical References](docs/references.md)

## Results

**Hardware results:** _Not yet available._

**Timing/resource results:** _Not yet available._

**SignalTap evidence:** _Not yet available._

Automated simulation/lint status will be recorded here only after the GitHub Actions workflow runs successfully on the committed RTL.

## Skills demonstrated by the implemented baseline

SystemVerilog · modular FPGA architecture · SPI protocol design · sensor register sequencing · fixed-point DSP · saturating arithmetic · FSM design · inferred block memory · pre/post-trigger capture · self-checking verification · VGA timing · Quartus automation · requirements traceability
