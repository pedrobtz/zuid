import os, random, string, hashlib
from multiformats import CID, multibase, multihash, varint
random.seed(99)
out=open("cases3.tsv","w")
bases=["base16","base16upper","base32","base32upper","base32pad","base32padupper","base32hex","base32hexupper","base32hexpad","base32hexpadupper","base36","base36upper","base58btc","base64","base64pad","base64url","base64urlpad",
       "base2","base8","base10","base32z","base58flickr","identity","proquint","base45"]
def mutate(s):
    alphabet=string.printable[:95]
    r=random.random(); i=random.randrange(len(s))
    if r<0.15: return s[:i]+s[i].swapcase()+s[i+1:]
    if r<0.35: return s[:i]+random.choice(alphabet)+s[i+1:]
    if r<0.45: return s[:i]+s[i+1:]
    if r<0.55: return s[:i]+random.choice(alphabet)+s[i:]
    if r<0.65: return s+random.choice(["="," ","==","\n","a","1"])
    if r<0.75: return random.choice("fFbBcCvVtTkKzmMuUQ")+s[1:]
    if r<0.85: return s[0]+s   # repeated prefix
    if r<0.9: return s[:-1]
    return s[0]+ random.choice(["0","1","a","A"])*random.randrange(1,4)+s[1:]
def ref(s):
    try:
        c=CID.decode(s)
        return bytes(c)
    except Exception as e:
        return None
def emit(s,tag=""):
    if "\x00" in s or any(ord(ch)>126 for ch in s) or "\t" in s or "\r" in s or "\x0b" in s or "\x0c" in s: return
    r=ref(s)
    out.write(f"{s.encode().hex()}\t{'NA' if r is None else r.hex()}\t{tag}\n")
codecs=[0x55,0x70,0x71,0x72,0x0129,0x0200,0x51,0x78,0x85,0x0202]
hashes=[("sha2-256",32),("sha2-512",64),("sha1",20),("identity",None),("sha3-256",32),("blake3",32),("md5",16),("keccak-256",32),("blake2b-256",32),("sha2-384",48),("sha3-224",28)]
for it in range(1500):
    hn,hl=random.choice(hashes)
    dl = hl if hl else random.choice([0,1,2,5,11,16,32,40,127,128,129,300])
    if random.random()<0.1 and hl: dl=random.choice([hl-1,hl+1,0])
    digest=os.urandom(dl)
    code=multihash.get(hn).code
    mh=varint.encode(code)+varint.encode(dl)+digest
    codec=random.choice(codecs)
    if random.random()<0.15:
        raw=mh if (hn=="sha2-256") else b"\x12\x20"+os.urandom(32)
        import base58
        s=base58.b58encode(raw).decode()
        cands=[s, "z"+s, "f"+raw.hex(), "b"+multibase.encode(raw,"base32")[1:]]
    else:
        raw=varint.encode(1)+varint.encode(codec)+mh
        if random.random()<0.05: raw=varint.encode(random.choice([0,2,3]))+raw[1:]
        if random.random()<0.05: raw=b"\x81\x00"+raw[1:]   # non-minimal varint
        if random.random()<0.05: raw=raw+b"\x00"
        b=random.choice(bases)
        try: s=multibase.encode(raw,b)
        except Exception: continue
        cands=[s]
    for s in cands:
        emit(s,"gen")
        for _ in range(4):
            if len(s): emit(mutate(s),"mut")
out.close()
