import os, random, sys, base64, string, uuid
random.seed(12345)
out = open("cases1.tsv", "w")
def emit(fmt, text, res):
    out.write(f"{fmt}\t{text.encode('utf-8').hex()}\t{'NA' if res is None else res.hex()}\n")

def mutate(s, alphabet=string.printable[:95]):
    r = random.random()
    if not s: return random.choice(alphabet)
    i = random.randrange(len(s))
    if r < 0.2: return s[:i] + s[i].swapcase() + s[i+1:]
    if r < 0.5: return s[:i] + random.choice(alphabet) + s[i+1:]
    if r < 0.6: return s[:i] + s[i+1:]
    if r < 0.7: return s[:i] + random.choice(alphabet) + s[i:]
    if r < 0.75: return s + random.choice([" ", "\n", "=", "\t"])
    if r < 0.8: return random.choice([" ", "+", "0", "-"]) + s
    if r < 0.85: return s.upper()
    if r < 0.9: return s.lower()
    if r < 0.95: return s[:i] + random.choice("ILOUilou") + s[i+1:]
    return s[:i] + random.choice("zZ~7") * (len(s)-i)

def run(fmt, gen, ref, n=400, nmut=6):
    for _ in range(n):
        s = gen()
        cands = [s]
        for _ in range(nmut):
            m = mutate(s); cands.append(m); 
            if random.random() < .3: cands.append(mutate(m))
        for c in cands:
            if "\x0b" in c or "\x0c" in c or "\r" in c: continue
            try: r = ref(c)
            except Exception as e: r = None
            emit(fmt, c, r)

# ULID
from ulid import ULID
run("ulid", lambda: str(ULID.from_bytes(os.urandom(16))), lambda s: ULID.from_str(s).bytes)
for s in ["7ZZZZZZZZZZZZZZZZZZZZZZZZZ","80000000000000000000000000","00000000000000000000000000"]:
    try: r = ULID.from_str(s).bytes
    except Exception: r=None
    emit("ulid", s, r)
# TypeID
from typeid import TypeID
def tgen():
    pl = random.choice([0,1,2,5,62,63,64])
    pre = "".join(random.choice("abcxyz_") for _ in range(pl))
    u = uuid.UUID(bytes=os.urandom(16))
    import base32_crockford
    suf = base32_crockford.encode(u.int).lower().rjust(26,"0")
    return (pre + "_" if pl else "") + suf
def tref(s):
    t = TypeID.from_string(s)
    return t.uuid.bytes
run("typeid", tgen, tref)
# UPID
from upid import UPID
def ugen():
    return UPID.from_prefix(random.choice(["user","a","ab","abc","z234","2222","zzzz", ""])).to_str()
def uref(s): return UPID.from_str(s).b
run("upid", ugen, uref)
# SCRU128
from scru128 import Scru128Id
def sgen(): 
    return str(Scru128Id(int.from_bytes(os.urandom(16),'big')))
run("scru128", sgen, lambda s: Scru128Id.from_str(s).__int__().to_bytes(16,"big"))
for s in ["f5lxx1zz5pnorynqglhzmsp33","f5lxx1zz5pnorynqglhzmsp34","F5LXX1ZZ5PNORYNQGLHZMSP33","zzzzzzzzzzzzzzzzzzzzzzzzz"]:
    try: r = Scru128Id.from_str(s).__int__().to_bytes(16,"big")
    except Exception: r=None
    emit("scru128", s, r)
# SCRU64
from scru64 import Scru64Id
def s64gen():
    return str(Scru64Id(random.randrange(36**12)))
run("scru64", s64gen, lambda s: int(Scru64Id.from_str(s)).to_bytes(8,"big"))
# KSUID
from ksuid import Ksuid
def kgen(): return str(Ksuid.from_bytes(os.urandom(20)))
run("ksuid", kgen, lambda s: bytes(Ksuid.from_base62(s)))
for s in ["aWgEPTl1tmebfsQzFP4bxwgy80V","aWgEPTl1tmebfsQzFP4bxwgy80W","000000000000000000000000000","zzzzzzzzzzzzzzzzzzzzzzzzzzz"]:
    try: r = bytes(Ksuid.from_base62(s))
    except Exception: r=None
    emit("ksuid", s, r)
# ObjectId
from bson import ObjectId
run("objectid", lambda: os.urandom(12).hex(), lambda s: ObjectId(s).binary)
# UUID
def uuref(s):
    return uuid.UUID(s).bytes
run("uuid_py", lambda: str(uuid.UUID(bytes=os.urandom(16))), uuref)
out.close()
