import json
from sqids import Sqids
cases = json.load(open("p16.json")); bad = 0; errs = 0
for c in cases:
    kw = {}
    if c.get("alphabet"): kw["alphabet"] = c["alphabet"]
    if c.get("min_length"): kw["min_length"] = c["min_length"]
    if c.get("blocklist") is not None: kw["blocklist"] = c["blocklist"] if isinstance(c["blocklist"], list) else [c["blocklist"]]
    nums = [int(x) for x in (c["numbers"] if isinstance(c["numbers"], list) else [c["numbers"]])]
    try:
        exp = Sqids(**kw).encode(nums)
    except Exception as e:
        exp = "ERR " + type(e).__name__ + " " + str(e)[:50]
    got = c["id"]
    if exp != got:
        if exp.startswith("ERR") and got.startswith("ERR"): errs += 1; continue
        bad += 1
        if bad < 15: print("MISMATCH", nums[:5], kw.get("alphabet", "")[:20], kw.get("min_length"), str(kw.get("blocklist"))[:40], "ref", exp[:60], "zuid", got[:60])
print("cases", len(cases), "mismatches", bad, "both-error", errs)
