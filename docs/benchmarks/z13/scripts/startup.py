import json
import sys

path, label, t0, t1, g0, g1, v0, v1 = sys.argv[1:]
rec = {"label": label, "startup_s": round(float(t1) - float(t0), 2), "gtt_gib": round((int(g1) - int(g0)) / 2**30, 1),
       "vram_gib": round((int(v1) - int(v0)) / 2**30, 1)}
open(path, "w").write(json.dumps(rec, indent=1) + "\n")
print(rec)
