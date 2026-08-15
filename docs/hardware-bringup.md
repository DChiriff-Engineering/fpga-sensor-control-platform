# Hardware Bring-Up Guide

**Current state:** RTL/verification automation can be developed without the board. The steps below are intentionally not marked complete until executed on the physical DE10-Lite.

## Official resources

Use the current Terasic DE10-Lite resources page and System CD. At the time this repository baseline was prepared, Terasic listed DE10-Lite User Manual v1.7 (2025-04-01) and System CD v2.2.0. Software/tool download versions can change, so verify them again on the physical-work day.

- Terasic DE10-Lite resources: `https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1021&PartNo=4`
- Terasic download index: `https://download.terasic.com/downloads/cd-rom/de10-lite/`
- Analog Devices ADXL345: `https://www.analog.com/en/products/adxl345.html`

## Gate 1 — Physical prerequisites

Confirm before programming:

1. DE10-Lite board present and visually undamaged.
2. USB Type-B **data** cable present.
3. Board powers normally.
4. Host operating system identified.
5. VGA monitor/cable optional; not required for the core bring-up.

## Gate 2 — Toolchain

Install/verify:

- Intel Quartus Prime Lite with MAX 10 device support;
- USB-Blaster driver / JTAG access;
- Questa-Intel FPGA Starter Edition if desired for local simulation;
- current Terasic System CD / Golden Top project for authoritative pin mapping.

Do not infer success from installation alone. `jtagconfig` must enumerate the onboard programming cable/device.

## Gate 3 — Minimal switch-to-LED smoke test

From repository root, create the smoke project:

```text
quartus_sh -t scripts/create_smoke_project.tcl
```

Import official board pins from the Golden Top QSF:

```text
quartus_sh -t scripts/import_de10_lite_pins.tcl fpga_sensor_smoke <path-to-DE10_LITE_Golden_Top.qsf>
```

Compile:

```text
quartus_sh --flow compile fpga_sensor_smoke
```

Program the produced `.sof` through the Quartus Programmer/USB-Blaster.

**Exit criterion:** every `SW[n]` controls `LEDR[n]` on the physical board and reset/button behavior is understood. Photograph or screen-record this first end-to-end programming milestone.

## Gate 4 — Main project compilation

```text
quartus_sh -t scripts/create_main_project.tcl
quartus_sh -t scripts/import_de10_lite_pins.tcl fpga_sensor_control <path-to-DE10_LITE_Golden_Top.qsf>
quartus_sh --flow compile fpga_sensor_control
```

Before programming, record:

- Quartus version;
- selected device (`10M50DAF484C7G`);
- compile success/failure;
- fitter resource summary;
- TimeQuest worst setup slack and pass/fail;
- warnings requiring engineering review.

## Gate 5 — Sensor sanity

After programming the main bitstream:

1. verify sensor-ready LED/status rather than assuming SPI is working;
2. place board flat and note displayed state/event behavior;
3. rotate toward ±X/±Y and verify the internal axes change using SignalTap;
4. capture `spi_state`, `sample_valid`, raw XYZ, filtered XYZ, event state, trigger, and logger write pointer;
5. save screenshots with captions explaining what each proves.

## Gate 6 — Physical validation campaign

Proceed only after coherent sensor data is observed. Execute the tests in `docs/verification-plan.md`: static orientation, stationary noise, step response, repeatability, threshold sweep, and trigger-buffer verification.

No timing/resource/hardware-result values should be copied into README tables until the actual Quartus or hardware evidence exists.
