# Requirements Traceability

| Requirement | Implementation | Automated evidence | Hardware evidence |
|---|---|---|---|
| FPGA-001 | `adxl345_controller`, `spi_byte_master` | `tb_adxl345_controller`, `tb_spi_byte_master` | ADXL345 SignalTap + orientation test pending |
| FPGA-002 | `sample_timer` | `tb_sample_timer` | measured sample cadence pending |
| FPGA-003 | `axis_calibration`, `iir_lowpass_axis` | calibration + IIR unit tests, pipeline integration | stationary/step tests pending |
| FPGA-004 | `threshold_code = 320 + SW` in top | integration compile/simulation | switch threshold sweep pending |
| FPGA-005 | `event_fsm` | `tb_event_fsm` | repeated-event/threshold tests pending |
| FPGA-006 | `triggered_circular_buffer` | buffer unit test | SignalTap memory/write-pointer evidence pending |
| FPGA-007 | `triggered_circular_buffer`, aligned logger stage | buffer + integration tests | pre/post-trigger physical proof pending |
| FPGA-008 | LED assignments + `hex7seg` | `tb_hex7seg`, lint | board status observation pending |
| FPGA-009 | VGA timing + renderer | `tb_vga_timing_640x480`, lint | physical monitor validation pending |
| FPGA-010 | `tb/unit`, `tb/integration`, CI scripts | GitHub Actions pending | n/a |
| FPGA-011 | `constraints/de10_lite.sdc` | source review | TimeQuest pending |
| FPGA-012 | results/reporting plan | none; values intentionally absent | Quartus fitter/TimeQuest pending |
| FPGA-013 | SignalTap + physical matrix | none | all physical campaign evidence pending |
| FPGA-014 | README/results wording and review gates | repository review | ongoing |
