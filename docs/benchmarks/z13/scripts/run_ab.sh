#!/bin/bash
# The interleaved A/B of docs/benchmarks/STRIX_HALO.md (bench_ab.py): strix and gguf both up, basal-2.0-4.5B.
# strix starts first and alone (its weights pass through RAM on the way to GTT), then gguf.
#   OUT=results/2.0/ab-balanced scripts/run_ab.sh
set -euo pipefail
cd "$(dirname "$0")/.."
source venv/bin/activate
unset OMP_NUM_THREADS MKL_NUM_THREADS OPENBLAS_NUM_THREADS POLARS_MAX_THREADS
export TMPDIR=$PWD/tmp
OUT=${OUT:-results/2.0/ab}
TOK=Remek/basal-2.0-4.5B
GGUF=$HOME/.cache/huggingface/hub/models--Remek--basal-2.0-4.5B-GGUF/snapshots/237294ca8fec0ae697f44ae0093995817c8ad578
stop() { for e in strix gguf; do [ -f logs/serve-$e.pid ] && kill "$(cat logs/serve-$e.pid)" 2>/dev/null || true; done; }
trap stop EXIT
echo "platform profile: $(cat /sys/firmware/acpi/platform_profile)"
scripts/serve.sh $OUT strix 8030 --mode strix --model $TOK
scripts/serve.sh $OUT gguf 8031 --mode gguf --model "$GGUF" --gguf "$GGUF/basal-2.0-4.5B-Q8_0.gguf"
scripts/cool.sh
scripts/sample_power.sh > $OUT/power.tsv &
sampler=$!
trap 'kill $sampler 2>/dev/null; stop' EXIT
(cd docs/benchmarks && taskset -c 0-31 python bench_ab.py --a gguf=http://127.0.0.1:8031/v1/systemone \
    --b strix=http://127.0.0.1:8030/v1/systemone --out ../../$OUT/ab.json --tokenizer $TOK)
echo ALL DONE
