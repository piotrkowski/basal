## gguf → strix per request shape

`--mode gguf` (llama.cpp in process, Vulkan, Q8_0) against `--mode strix` (PyTorch + Triton kernels for gfx1151, bf16). p50 of 2 timed passes, unique states.

| state | questions | prompt tokens | gguf | strix | speed-up |
|---|---|---|---|---|---|
| S | 1 | 201 | 151 ms | **370 ms** | 0.41× |
| S | 2 | 386 | 177 ms | **193 ms** | 0.92× |
| S | 5 | 1,508 | 330 ms | **317 ms** | 1.04× |
| S | 10 | 2,741 | 643 ms | **376 ms** | 1.71× |
| S | 20 | 4,692 | 968 ms | **558 ms** | 1.74× |
| M | 1 | 669 | 455 ms | **310 ms** | 1.47× |
| M | 2 | 1,322 | 502 ms | **820 ms** | 0.61× |
| M | 5 | 5,252 | 641 ms | **387 ms** | 1.66× |
| M | 10 | 8,825 | 957 ms | **591 ms** | 1.62× |
| M | 20 | 15,456 | 1.31 s | **754 ms** | 1.74× |
| L | 1 | 2,109 | 1.49 s | **893 ms** | 1.67× |
| L | 2 | 4,202 | 1.51 s | **855 ms** | 1.77× |
| L | 5 | 16,772 | 1.68 s | **934 ms** | 1.79× |
| L | 10 | 27,545 | 2.08 s | **1.22 s** | 1.71× |
| L | 20 | 48,576 | 2.54 s | **1.45 s** | 1.75× |
| XL | 1 | 6,163 | 5.42 s | **3.11 s** | 1.74× |
| XL | 2 | 12,310 | 5.94 s | **3.25 s** | 1.83× |
| XL | 5 | 49,204 | 6.60 s | **3.57 s** | 1.85× |
| XL | 10 | 80,247 | 7.19 s | **4.08 s** | 1.76× |
| XL | 20 | 141,818 | 7.86 s | **4.57 s** | 1.72× |

| clients (single questions) | gguf dec/s · p50 | strix dec/s · p50 | throughput |
|---|---|---|---|
| 1 | 6.3/s · 158 ms | **5.5/s** · 185 ms | 0.88× |
| 4 | 7.5/s · 532 ms | **7.7/s** · 527 ms | 1.02× |
| 8 | 7.9/s · 1.00 s | **10.8/s** · 734 ms | 1.37× |
| 16 | 8.1/s · 1.95 s | **12.6/s** · 1.26 s | 1.56× |
| 32 | 8.2/s · 3.86 s | **12.9/s** · 2.45 s | 1.58× |
| 64 | 8.1/s · 7.85 s | **12.8/s** · 5.01 s | 1.57× |

## Start-up and memory

| engine | start-up | GTT after start |
|---|---|---|
| gguf | 3.0 s | 3.8 GiB |
| **strix** | 33.1 s | 10.1 GiB |
| eager fp32 (reference) | 4.8 s | 17.9 GiB |

## Latency per request, all engines (p50; bold: fastest)

| state | q | branches | gguf | **strix** |
|---|---|---|---|---|
| S | 1 | 1 | **151 ms** | 370 ms |
| S | 2 | 2 | **177 ms** | 193 ms |
| S | 5 | 8 | 330 ms | **317 ms** |
| S | 10 | 13 | 643 ms | **376 ms** |
| S | 20 | 23 | 968 ms | **558 ms** |
| M | 1 | 1 | 455 ms | **310 ms** |
| M | 2 | 2 | **502 ms** | 820 ms |
| M | 5 | 8 | 641 ms | **387 ms** |
| M | 10 | 13 | 957 ms | **591 ms** |
| M | 20 | 23 | 1.31 s | **754 ms** |
| L | 1 | 1 | 1.49 s | **893 ms** |
| L | 2 | 2 | 1.51 s | **855 ms** |
| L | 5 | 8 | 1.68 s | **934 ms** |
| L | 10 | 13 | 2.08 s | **1.22 s** |
| L | 20 | 23 | 2.54 s | **1.45 s** |
| XL | 1 | 1 | 5.42 s | **3.11 s** |
| XL | 2 | 2 | 5.94 s | **3.25 s** |
| XL | 5 | 8 | 6.60 s | **3.57 s** |
| XL | 10 | 13 | 7.19 s | **4.08 s** |
| XL | 20 | 23 | 7.86 s | **4.57 s** |

## Cost of one more question (1 → 20 questions, per added question)

| state | gguf | **strix** |
|---|---|---|
| S | 43 ms | 10 ms |
| M | 45 ms | 23 ms |
| L | 55 ms | 29 ms |
| XL | 129 ms | 77 ms |

## Concurrency (single questions over short states, unique per request)

| clients | gguf | **strix** |
|---|---|---|
| 1 | 6.3/s · 158 ms | 5.5/s · 185 ms |
| 4 | 7.5/s · 532 ms | 7.7/s · 527 ms |
| 8 | 7.9/s · 1.00 s | 10.8/s · 734 ms |
| 16 | 8.1/s · 1.95 s | 12.6/s · 1.26 s |
| 32 | 8.2/s · 3.86 s | 12.9/s · 2.45 s |
| 64 | 8.1/s · 7.85 s | 12.8/s · 5.01 s |

## Agreement with the fp32 reference

Reference: `--mode eager --dtype float32 --soam off --max-batch 1` (every prompt computed separately in fp32), on 17 requests (S-q1, S-q2, S-q5, S-q10, S-q20, M-q1, M-q2, M-q5, M-q10, M-q20, L-q1, L-q2, L-q5, L-q10, L-q20, XL-q1, XL-q2). A decision is the top option of a question or the yes/no of one label of a multi-label question.

| engine | same decision | mean \|Δp\| | max \|Δp\| |
|---|---|---|---|
| gguf | 142/144 | 0.0064 | 0.068 |
| **strix** | 142/144 | 0.0047 | 0.028 |

## strix against gguf (whole matrix)

| comparison | same decision | mean \|Δp\| | max \|Δp\| |
|---|---|---|---|
| gguf (Q8_0) vs strix (bf16) | 184/188 | 0.0076 | 0.074 |

## Edge cases

12 requests: mixed PL / EN questions over one state, 10 options, the same question three times, a JSON state, `facts: auto`, long option texts, a 5-level score, an 8-label multi with min / max, an `act` with a cost matrix, an English-only request, a 2-character state, `option_keys` show vs hide. Sent one after another, then all at once (the server batches them).

| engine | errors | concurrent = sequential decisions | concurrent vs sequential, max \|Δp\| | duplicate questions, max \|Δp\| | multi within min/max | act action | vs fp32: same decision | vs fp32: max \|Δp\| |
|---|---|---|---|---|---|---|---|---|
| gguf | none | 26/26 | 0.0460 | 0.0e+00 | True | human | 26/26 | 0.042 |
| **strix** | none | 26/26 | 0.0318 | 0.0e+00 | True | human | 26/26 | 0.027 |
| eager fp32 (reference) | none | 26/26 | 0.0000 | 0.0e+00 | True | human | – | – |
