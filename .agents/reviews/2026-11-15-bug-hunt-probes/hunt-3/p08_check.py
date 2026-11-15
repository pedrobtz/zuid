import math
from decimal import Decimal
bad = 0; n = 0
for line in open("p08.tsv"):
    tag, order, epoch, unit, t, workers, vals = line.rstrip("\n").split("\t")
    parts = [(p.split(":")[0], int(p.split(":")[1])) for p in order.split(",")]
    tot = sum(w for _, w in parts)
    tick = math.floor((Decimal(t) - Decimal(epoch)) / Decimal(unit))
    ws = [int(x) for x in workers.split(",")]
    if vals.startswith("ERR"):
        print("note", tag, t, vals, "tick", tick); continue
    seq_w = dict(parts)["sequence"]; time_w = dict(parts)["time"]
    for i, s in enumerate(vals.split(",")):
        n += 1; v = int(s)
        if v < 0 or v >= 1 << tot: bad += 1; print("RANGE", tag, s); continue
        sh = tot; got = {}
        for name, w in parts:
            sh -= w; got[name] = (v >> sh) & ((1 << w) - 1)
        exp_tick = tick + (i >> seq_w); exp_seq = i & ((1 << seq_w) - 1)
        nodes = [got[nm] for nm, _ in parts if nm not in ("time", "sequence")]
        if tag == "twitter_rev": ok_nodes = nodes == [1, 30]
        else: ok_nodes = nodes == ws
        if got["time"] != exp_tick or got["sequence"] != exp_seq or not ok_nodes:
            bad += 1; print("MISMATCH", tag, t, s, got, "want tick", exp_tick, "seq", exp_seq, ws)
print("checked", n, "mismatches", bad)
