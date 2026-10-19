#!/bin/bash
# The request matrix and the edge cases of docs/benchmarks/STRIX_HALO.md for basal-2.0-4.5B, one engine at a time:
# strix, then gguf (Q8_0, llama.cpp Vulkan).
set -euo pipefail
cd "$(dirname "$0")/.."
source venv/bin/activate
unset OMP_NUM_THREADS MKL_NUM_THREADS OPENBLAS_NUM_THREADS POLARS_MAX_THREADS
export TMPDIR=$PWD/tmp
B=docs/benchmarks R=results/2.0
TOK=Remek/basal-2.0-4.5B
GGUF=$HOME/.cache/huggingface/hub/models--Remek--basal-2.0-4.5B-GGUF/snapshots/237294ca8fec0ae697f44ae0093995817c8ad578

run() {  # label port serve-args... ; then the matrix args come from $MATRIX
  local label=$1 port=$2; shift 2
  scripts/serve.sh $R/matrix "$label" "$port" "$@"
  cp $R/matrix/$label.startup.json $R/edge/$label.startup.json
  taskset -c 0-31 python $B/bench_matrix.py --url http://127.0.0.1:$port/v1/systemone --label "$label" \
      --out $R/matrix --tokenizer $TOK $MATRIX
  taskset -c 0-31 python $B/edge_check.py --url http://127.0.0.1:$port/v1/systemone --label "$label" --out $R/edge
  kill "$(cat logs/serve-$label.pid)"; wait "$(cat logs/serve-$label.pid)" 2>/dev/null || true
  sleep 5
}

mkdir -p $R/matrix $R/edge
ENGINES=${ENGINES:-"strix gguf"}
[[ " $ENGINES " == *" strix "* ]] && MATRIX="" run strix 8030 --mode strix --model $TOK
[[ " $ENGINES " == *" gguf "* ]] && MATRIX="" run gguf 8031 --mode gguf --model "$GGUF" --gguf "$GGUF/basal-2.0-4.5B-Q8_0.gguf"
# fp32 reference: does not fit in 32 GB here; answers are compared with @kardysm's ref-fp32 files
echo ALL DONE
