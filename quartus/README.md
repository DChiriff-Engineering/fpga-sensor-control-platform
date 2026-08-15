# Quartus workspace

Quartus project files in this directory are generated locally by the repository scripts and are intentionally not treated as authoritative source.

Create the main project:

```text
quartus_sh -t scripts/create_main_project.tcl
```

Create the minimal first-hardware smoke project:

```text
quartus_sh -t scripts/create_smoke_project.tcl
```

Then import physical pin assignments from the official Terasic DE10-Lite Golden Top QSF using `scripts/import_de10_lite_pins.tcl`.

Generated Quartus databases, reports, `.sof` images, and local project files should not be committed as source. Curated timing/resource summaries and screenshots belong under `results/` or `figures/` only after they are produced and reviewed.
