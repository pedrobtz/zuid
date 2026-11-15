import random, json
from sqids import Sqids
random.seed(5)
out=open("cases5.tsv","w")
sq=Sqids()
for target in list(range(500,520))+[1020,1024,1030,4000]:
    # build number lists whose id length lands near target
    for attempt in range(60):
        k=random.randrange(target//10-8, target//2)
        nums=[random.choice([0,1,5,random.randrange(100000), random.randrange(2**53)]) for _ in range(max(k,1))]
        s=sq.encode(nums)
        if abs(len(s)-target)<=3 or attempt>55:
            out.write(f"{s}\t{json.dumps(nums)}\n")
            # embed a blocked word in the middle/end -> expect invalid unless ref says canonical
            for w in ["fuck","sh1t","pussy"]:
                for pos in [0, len(s)//2, len(s)-len(w)]:
                    t=s[:pos]+w+s[pos+len(w):]
                    try:
                        n2=sq.decode(t); ok = bool(n2) and all(n<2**53 for n in n2) and sq.encode(n2)==t
                    except Exception: ok=False
                    out.write(f"{t}\t{json.dumps(n2) if ok else 'NA'}\n")
out.close()
