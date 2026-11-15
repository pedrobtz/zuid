# Model differential: reference SCRU128/SCRU64 generators vs zuid pure calls over timestamp walks.
import random, subprocess, json, sys, os
import scru128, scru64
from scru64 import Scru64Generator
rnd = random.Random(7)
cases = []
def walk(n, start, steps):
    t = start; out = []
    for _ in range(n):
        t += rnd.choice(steps); t = max(t, 300); out.append(t)
    return out
stepsets = [[0], [0, 0, 1], [0, 1, -1, 5], [0, 0, 0, -3000, 2500, 1000, 999, 1001], [0, -9999, -10000, 10001, 1], [0, -10001, 20000], [0, -256, 256, -9984, -10239, -10240, -10241, 30000], [-1], [-200]]
for k in range(120):
    kind = rnd.choice(["scru128", "scru64"]); steps = rnd.choice(stepsets)
    n = rnd.choice([1, 2, 5, 40, 300]); ts = walk(n, rnd.choice([1000, 1_700_000_000_000, 2**40]), steps)
    rb = [rnd.getrandbits(8) for _ in range(n * (10 if kind == "scru128" else 3))]
    if k % 7 == 0: rb = [0xff] * len(rb)
    nb = rnd.choice([1, 8, 19, 20, 21, 22, 23]); reset = rnd.random() < 0.5
    cases.append(dict(kind=kind, ts=ts, rb=rb, nb=nb, node=rnd.getrandbits(nb), reset=reset))
# extra: counter_lo overflow -> counter_hi increment; counter_hi overflow -> timestamp+1
cases.append(dict(kind="scru128", ts=[5000] * 4, rb=[0xff] * 40, nb=1, node=0, reset=False))
cases.append(dict(kind="scru128", ts=[2**48 - 2] * 4, rb=[0xff] * 40, nb=1, node=0, reset=False))
cases.append(dict(kind="scru128", ts=[5000, 5000, 6000, 6000, 5999, 6001], rb=[0xff] * 60, nb=1, node=0, reset=False))
json.dump(cases, open("p12_cases.json", "w"))
subprocess.run(["Rscript", "p12_run.R"], check=True)
got = json.load(open("p12_out.json"))
class Rng:
    def __init__(self, rb): self.rb = rb; self.i = 0
    def getrandbits(self, k):
        r = self.rb[10 * self.i: 10 * self.i + 10]
        if k == 32: return int.from_bytes(bytes(r[0:4]), "big")
        # 24 bits: lo then hi. counter_lo is drawn before counter_hi within a call
        self.calls24 += 1
        return int.from_bytes(bytes(r[4:7] if self.which == "lo" else r[7:10]), "big")
class Mode:
    def __init__(self, rb, cs): self.rb = rb; self.i = 0; self.cs = cs
    def renew(self, counter_size, ctx):
        v = int.from_bytes(bytes(self.rb[3 * self.i: 3 * self.i + 3]), "big")
        guard = 1 if counter_size <= 4 else 0
        return v & (((1 << counter_size) - 1) >> guard)
bad = 0
for c, g in zip(cases, got):
    exp = []; err = None
    if c["kind"] == "scru128":
        # Reimplement the draw order by patching: use a subclass rng that knows which 24-bit draw it is.
        gen = scru128.Scru128Generator(rng=None)
        class R:
            def __init__(s): s.i = 0; s.n24 = 0
            def getrandbits(s, k):
                r = c["rb"][10 * s.i: 10 * s.i + 10]
                if k == 32: return int.from_bytes(bytes(r[0:4]), "big")
                raise RuntimeError("unexpected")
        # The reference draws counter_lo and counter_hi with getrandbits(24) in code order; emulate by inspecting state.
        class R2:
            def __init__(s): s.i = 0; s.gen = None
            def getrandbits(s, k):
                r = c["rb"][10 * s.i: 10 * s.i + 10]
                if k == 32: return int.from_bytes(bytes(r[0:4]), "big")
                import inspect
                line = inspect.stack()[1].code_context[0]
                if "_counter_lo" in line: return int.from_bytes(bytes(r[4:7]), "big")
                if "_counter_hi" in line: return int.from_bytes(bytes(r[7:10]), "big")
                raise RuntimeError(line)
        rng = R2(); gen = scru128.Scru128Generator(rng=rng)
        for i, t in enumerate(c["ts"]):
            rng.i = i
            try:
                v = gen.generate_or_reset_core(t, 10000) if c["reset"] else gen.generate_or_abort_core(t, 10000)
            except Exception as e:
                err = "overflow@%d" % (i + 1); break
            if v is None: err = "clock@%d" % (i + 1); break
            exp.append(str(v))
    else:
        mode = Mode(c["rb"], 24 - c["nb"]); gen = Scru64Generator("%d/%d" % (c["node"], c["nb"]), counter_mode=mode)
        for i, t in enumerate(c["ts"]):
            mode.i = i
            v = gen.generate_or_abort_core(t, 10000)
            if v is None:
                if c["reset"]:
                    v = gen.generate_or_reset_core(t, 10000)
                else: err = "clock@%d" % (i + 1); break
            exp.append(str(v))
    want = err if err else exp
    if want != g:
        bad += 1
        if isinstance(want, list) and isinstance(g, list):
            j = next((j for j in range(min(len(want), len(g))) if want[j] != g[j]), None)
            print("MISMATCH", c["kind"], "nb", c["nb"], "reset", c["reset"], "first diff at", j, "ts", c["ts"][max(0, (j or 0) - 2):(j or 0) + 2], "ref", want[j] if j is not None else len(want), "zuid", g[j] if j is not None else len(g))
        else: print("MISMATCH", c["kind"], "nb", c["nb"], "reset", c["reset"], "ref", str(want)[:80], "zuid", str(g)[:80], "ts", c["ts"][:6])
print("cases", len(cases), "mismatches", bad)
