# Test Results

## Automated RTL verification

**Status:** PASS for the hardware-independent baseline.

GitHub Actions run **#8** (`31860253595`) on implementation commit `bbe2bfe2498c96835ad21fd46aa37c9ea577fab1` completed successfully. The workflow installs Icarus Verilog and Verilator on Ubuntu, executes every self-checking testbench, and then lints the synthesizable main RTL.

| Verification item | Result |
|---|---|
| Icarus unit simulations | **13 / 13 PASS** |
| Icarus integration simulation | **1 / 1 PASS** |
| Total self-checking simulations | **14 / 14 PASS** |
| Verilator RTL lint | **PASS** |

The Verilator gate runs with `--Wall`; only intentional unused diagnostic/readback signals are exempted with `-Wno-UNUSEDSIGNAL`. Other lint warnings remain fatal.

### Passing simulations

- `tb_adxl345_controller`
- `tb_adxl345_error`
- `tb_axis_calibration`
- `tb_event_fsm`
- `tb_hex7seg`
- `tb_iir_lowpass_axis`
- `tb_reset_sync`
- `tb_sample_timer`
- `tb_spi_byte_master`
- `tb_triggered_circular_buffer`
- `tb_vector_features`
- `tb_vga_status_renderer`
- `tb_vga_timing_640x480`
- `tb_processing_pipeline` (integration)

This evidence verifies committed RTL behavior under the modeled conditions. It does **not** establish successful Quartus fitting, timing closure, physical sensor behavior, SignalTap results, or board/VGA operation.

## Quartus implementation

_Not yet executed against the physical project/toolchain._

| Metric | Actual result |
|---|---|
| Target device | `10M50DAF484C7G` (configured in scripts; fitter run pending) |
| Target clock | 50 MHz / 20.000 ns constraint |
| Worst setup slack | Not yet available |
| Timing closure | Not yet available |
| Logic utilization | Not yet available |
| Registers | Not yet available |
| Memory / M9K | Not yet available |
| DSP blocks | Not yet available |
| PLLs | Not yet available |

## Physical hardware

_Not yet available._

No DE10-Lite programming, accelerometer response, SignalTap, VGA, or physical validation result is represented as complete here.
