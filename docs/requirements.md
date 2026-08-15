# Requirements

The project-level requirements below preserve the approved handoff scope while separating **implementation state** from **verification state**. Hardware-dependent requirements remain open until evidence is produced on the physical DE10-Lite.

| ID | Requirement | Implementation | Verification |
|---|---|---|---|
| FPGA-001 | System shall acquire coherent three-axis ADXL345 accelerometer samples autonomously in FPGA logic. | RTL implemented | Sensor protocol/controller simulations PASS; hardware pending |
| FPGA-002 | Sampling shall occur autonomously at a documented 100 Hz baseline rate derived from the 50 MHz board clock. | RTL implemented | Sample-timer simulation PASS; hardware cadence pending |
| FPGA-003 | System shall apply fixed-point digital filtering to all three acquired axes. | RTL implemented | Calibration/IIR/integration simulations PASS; hardware pending |
| FPGA-004 | User shall configure the event threshold using onboard switches. | RTL implemented | Main RTL lint/integration path PASS; physical switch sweep pending |
| FPGA-005 | Event detection shall use hysteresis, consecutive-sample dwell, hold, and recovery behavior to prevent chatter. | RTL implemented | Event-FSM simulation PASS; hardware pending |
| FPGA-006 | System shall maintain rolling sample history in FPGA memory. | RTL implemented | Circular-buffer simulation PASS; Quartus RAM inference/hardware pending |
| FPGA-007 | Triggered capture shall preserve samples from before and after the first accepted event. | RTL implemented | Buffer + integration simulations PASS; physical proof pending |
| FPGA-008 | System shall expose acquisition/control status through LEDs and six seven-segment displays. | RTL implemented | Seven-segment simulation + RTL lint PASS; board observation pending |
| FPGA-009 | System should provide a simple real-time VGA engineering status display. | RTL baseline implemented | VGA timing/renderer simulations PASS; physical display pending |
| FPGA-010 | Critical RTL modules shall have automated self-checking verification. | Implemented | 14/14 simulations + strict Verilator lint PASS in CI |
| FPGA-011 | Final physical implementation shall use explicit 50 MHz timing constraints. | SDC implemented | Quartus TimeQuest pending |
| FPGA-012 | Final implementation shall document actual MAX 10 resource utilization and worst setup slack from Quartus. | Reporting structure defined | Pending Quartus fitter/TimeQuest |
| FPGA-013 | Hardware validation shall include sensor response, event behavior, trigger-buffer behavior, and at least one SignalTap capture. | Test campaign defined | Pending physical DE10-Lite |
| FPGA-014 | Unsupported timing, resource, or hardware-performance claims shall not be published. | Enforced by documentation/status conventions | Ongoing review |

## Acceptance philosophy

A requirement may be **implemented** without being **verified**. Simulation evidence closes modeled logic behavior; only Quartus/TimeQuest can close FPGA implementation timing/resource questions; only the physical board can close hardware behavior. The README and results documents preserve that distinction.
