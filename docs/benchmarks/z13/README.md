# `--mode strix` on a second Strix Halo: raw results

Raw results behind "A second machine: basal-2.0 on a ROG Flow Z13" in
[docs/benchmarks/STRIX_HALO.md](https://github.com/rkinas/basal/blob/main/docs/benchmarks/STRIX_HALO.md). Measured by
@piotrkowski on an ASUS ROG Flow Z13 (GZ302EA: Ryzen AI Max+ 395, Radeon 8060S, 32 GB, `balanced` platform profile, on
AC power), CachyOS, kernel 7.2.9, Mesa 26.2.4; PyTorch 2.12.0 + ROCm 7.2, Triton 3.7.0, transformers 5.17.0,
llama-cpp-python 0.3.36 built with Vulkan; basal at rkinas/basal@2e581da; models `Remek/basal-2.0-4.5B` (revision
e5ba914) and `basal-2.0-4.5B-Q8_0.gguf` from `Remek/basal-2.0-4.5B-GGUF` (revision 237294c).

| path | what |
|---|---|
| `results/matrix/` | `bench_matrix.py`, one engine at a time: `strix.json`, `gguf.json`, start-up and GTT (`*.startup.json`) |
| `results/edge/` | `edge_check.py`: `strix.json`, `gguf.json` |
| `results/ab-balanced/` | `bench_ab.py` with both servers up: `ab.json`; start-up, GTT and VRAM per server; `power.tsv`, every 0.5 s during the A/B: time, package power (amdgpu `PPT`, W), GPU clock (MHz), edge temperature (°C), GPU busy (%) |
| `report.md` | `report.py results/matrix results/edge` with @kardysm's fp32 reference files added to both folders |
| `scripts/` | the wrappers that started each server and ran the benchmarks |

The benchmark scripts themselves (`bench_matrix.py`, `edge_check.py`, `bench_ab.py`, `report.py`) are @kardysm's,
unchanged, from [kardysm/basal#3](https://github.com/kardysm/basal/pull/3) (commit 344c783). The fp32 reference
(`ref-fp32.json`) is not here: it does not fit in 32 GB, so `report.md` uses @kardysm's file from
`docs/benchmarks/results/2.0/` of that pull request (same model weights, same requests: the prompt-token counts of all
20 matrix shapes match). The start-up and GTT of the fp32 row in `report.md` are his too.

`scripts/` expects a working directory with @kardysm's `docs/benchmarks/` scripts, `basal/examples` from the engine
(they build the requests from it), a `venv/` with the software above, and the models in the Hugging Face cache. Order:
`ENGINES="strix gguf" scripts/run_all.sh` (matrix and edge cases; every server starts after the GPU cools below 55 °C),
then `OUT=results/2.0/ab-balanced scripts/run_ab.sh`. Servers and clients ran on all 32 threads (`taskset -c 0-31`),
with `OMP_NUM_THREADS` and similar unset.
