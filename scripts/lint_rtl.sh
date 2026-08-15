#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mapfile -t RTL_FILES < <(find "$ROOT/rtl" -name '*.sv' -type f | sort)

verilator --lint-only --sv --Wall -Wno-fatal \
    --top-module fpga_sensor_control_top \
    "${RTL_FILES[@]}"
