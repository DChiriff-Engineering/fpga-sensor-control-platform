#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build/sim"
mkdir -p "$BUILD"

mapfile -t RTL_FILES < <(find "$ROOT/rtl" -name '*.sv' -type f | sort)
mapfile -t TB_FILES < <(find "$ROOT/tb/unit" "$ROOT/tb/integration" -name 'tb_*.sv' -type f | sort)

pass=0
for tb in "${TB_FILES[@]}"; do
    top="$(basename "$tb" .sv)"
    out="$BUILD/$top.vvp"
    echo "[SIM] $top"
    iverilog -g2012 -Wall -s "$top" -o "$out" "${RTL_FILES[@]}" "$tb"
    vvp "$out"
    pass=$((pass + 1))
done

echo "All $pass self-checking simulations passed."
