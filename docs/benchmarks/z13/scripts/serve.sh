#!/bin/bash
# Start one basal-serve engine, wait for /health and record start-up time and the GTT (and VRAM carve-out) it adds,
# the way docs/benchmarks/STRIX_HALO.md measures them.
#   scripts/serve.sh <results dir> <label> <port> <basal-serve args...>
set -euo pipefail
cd "$(dirname "$0")/.."
out=$1 label=$2 port=$3; shift 3
dev=/sys/class/drm/card1/device
source venv/bin/activate
unset OMP_NUM_THREADS MKL_NUM_THREADS OPENBLAS_NUM_THREADS POLARS_MAX_THREADS
export TMPDIR=$PWD/tmp
mkdir -p "$out" logs
scripts/cool.sh
gtt0=$(cat $dev/mem_info_gtt_used)
vram0=$(cat $dev/mem_info_vram_used)
t0=$(date +%s.%N)
taskset -c 0-31 basal-serve --host 127.0.0.1 --port "$port" "$@" > "logs/serve-$label.log" 2>&1 &
pid=$!
echo $pid > "logs/serve-$label.pid"
until curl -sf "http://127.0.0.1:$port/health" > /dev/null; do
  kill -0 $pid 2>/dev/null || { echo "basal-serve $label died:"; tail -n 20 "logs/serve-$label.log"; exit 1; }
  sleep 0.1
done
t1=$(date +%s.%N)
gtt1=$(cat $dev/mem_info_gtt_used)
vram1=$(cat $dev/mem_info_vram_used)
python -I scripts/startup.py "$out/$label.startup.json" "$label" "$t0" "$t1" "$gtt0" "$gtt1" "$vram0" "$vram1"
