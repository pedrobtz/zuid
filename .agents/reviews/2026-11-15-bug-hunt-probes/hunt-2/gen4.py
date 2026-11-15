import random, string, sys, json
from sqids import Sqids
random.seed(4242)
out=open("cases4.tsv","w")
configs=[("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",0),
         ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",10),
         ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",255),
         ("abc",0),("abc",7),("0123456789abcdef",0),("0123456789abcdef",40),("ABCDEFGHIJKLMNOPQRSTUVWXYZ",0),
         ("".join(chr(c) for c in range(33,127)),0), ("fuckasdbith",0), ("fuckasdbith",5)]
MAX=2**53-1
def numgen():
    k=random.choice([1,1,1,2,3,5,10,40])
    return [random.choice([0,1,2,61,62,63,2**31-1,2**31,2**32,2**53-1,2**53-2,random.randrange(1000),random.randrange(MAX+1)]) for _ in range(k)]
def mutate(s, alpha):
    if not s: return random.choice(alpha)
    r=random.random(); i=random.randrange(len(s))
    if r<0.3: return s[:i]+random.choice(alpha)+s[i+1:]
    if r<0.45: return s[:i]+s[i+1:]
    if r<0.6: return s[:i]+random.choice(alpha)+s[i:]
    if r<0.7: return s+random.choice(alpha)
    if r<0.8: return "".join(random.choice(alpha) for _ in range(random.choice([1,2,3,4,5,8,20,60])))
    if r<0.9: return s[:i]+s[i].swapcase()+s[i+1:]
    return s[::-1]
for ci,(alpha,ml) in enumerate(configs):
    sq=Sqids(alphabet=alpha,min_length=ml)
    def ref(s):
        try:
            nums=sq.decode(s)
        except Exception as e:
            return None
        if not nums and s!="": return None
        if any(n>MAX for n in nums): return None
        try:
            if sq.encode(nums)!=s: return None
        except Exception: return None
        return nums
    cands=[""]
    for _ in range(400):
        nums=numgen()
        try: s=sq.encode(nums)
        except Exception as e: continue
        cands.append(s)
        for _ in range(5): cands.append(mutate(s,alpha))
    # words from blocklist-ish
    cands += ["fuck","Fuck","sex","ass","a55","pussy","aaaa","b0ob","nigga","1d10t","shit1","0rgasm"]
    for s in cands:
        r=ref(s)
        out.write(f"{ci}\t{s.encode().hex()}\t{'NA' if r is None else json.dumps(r)}\n")
json.dump(configs, open("cfg4.json","w"))
out.close()
