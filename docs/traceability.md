# Requirements Traceability

| Requirement | Implementation | Automated evidence | Hardware evidence |
|---|---|---|---|
| FPGA-001 | `adxl345_controller`, `spi_byte_master` | `tb_spi_byte_master`, `tb_adxl345_controller`, `tb_adxl345_error` — PASS | ADXL345 SignalTap + orientation test pending |
| FPGA-002 | `sample_timer`, `reset_sync` | `tb_sample_timer`, `tb_reset_sync` — PASS | measured sample cadence pending |
| FPGA-003 | `axis_calibration`, `iir_lowpass_axis` | calibration + IIR unit tests + pipeline integration — PASS | stationary/step tests pending |
| FPGA-004 | `threshold_code = 320 + SW` in top | main RTL lint + processing integration — PASS | switch threshold sweep pending |
| FPGA-005 | `event_fsm` | `tb_event_fsm` — PASS | repeated-event/threshold tests pending |
| FPGA-006 | `triggered_circular_buffer` | `tb_triggered_circular_buffer` — PASS | Quartus RAM inference + SignalTap evidence pending |
| FPGA-007 | `triggered_circular_buffer`, aligned logger stage | buffer + `tb_processing_pipeline` — PASS | pre/post-trigger physical proof pending |
| FPGA-008 | LED assignments + `hex7seg` | `tb_hex7seg` + strict RTL lint — PASS | board status observation pending |
| FPGA-009 | VGA timing + renderer | `tb_vga_timing_640x480`, `tb_vga_status_renderer` + lint — PASS | physical monitor validation pending |
| FPGA-010 | `tb/unit`, `tb/integration`, CI scripts | 14/14 simulations + Verilator lint — PASS | n/a |
| FPGA-011 | `constraints/de10_lite.sdc` | source-controlled constraint present | TimeQuest pending |
| FPGA-012 | results/reporting plan | values intentionally absent until reports exist | Quartus fitter/TimeQuest pending |
| FPGA-013 | SignalTap + physical matrix | physical test plan documented | all physical campaign evidence pending |
| FPGA-014 | README/results wording and review gates | repository review/status separation | ongoing |
