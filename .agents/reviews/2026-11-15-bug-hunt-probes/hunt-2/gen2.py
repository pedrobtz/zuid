import os, random, math, string, base64, base58
random.seed(777)
out = open("cases2.tsv","w")
HEX="0123456789abcdef"; CROCK="0123456789ABCDEFGHJKMNPQRSTVWXYZ"; RFC="ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"; RFCHEX="0123456789ABCDEFGHIJKLMNOPQRSTUV"
B36="0123456789abcdefghijklmnopqrstuvwxyz"; B58="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
B62="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
B64U="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"; B64S="-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
SHORT="23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
def width(n, base):
    # minimal d with base^d >= 256^n  (exact integers)
    if n == 0: return 0
    t = 256**n; d = int(8*n/math.log2(base)) - 2
    d = max(d,0)
    while base**d < t: d += 1
    return d
def enc_radix(b, alpha):
    base=len(alpha); d=width(len(b),base); v=int.from_bytes(b,"big"); s=[]
    for _ in range(d): s.append(alpha[v%base]); v//=base
    return "".join(reversed(s))
def dec_radix(s, alpha, fold=False):
    base=len(alpha); idx={c:i for i,c in enumerate(alpha)}
    if fold:
        for c,i in list(idx.items()): idx[c.lower()]=i; idx[c.upper()]=i
    L=len(s)
    n=None
    # find n with width(n)==L
    lo=int(L*math.log2(base)/8)
    for c in range(max(lo-2,0), lo+3):
        if width(c,base)==L: n=c
    if n is None: return None
    v=0
    for ch in s:
        if ch not in idx: return None
        v=v*base+idx[ch]
    if v >= 256**n: return None
    return v.to_bytes(n,"big")
def enc_bits(b, alpha, bits, lead):
    L=(8*len(b)+bits-1)//bits; v=int.from_bytes(b,"big")
    spare=L*bits-8*len(b)
    if not lead: v <<= spare
    return "".join(alpha[(v>>(bits*(L-1-i)))&((1<<bits)-1)] for i in range(L))
def dec_bits(s, alpha, bits, lead, fold=True, pad=False):
    idx={c:i for i,c in enumerate(alpha)}
    if fold:
        for c,i in list(idx.items()): idx[c.lower()]=i; idx[c.upper()]=i
    if pad:
        block = 8 if bits==5 else 4
        k=len(s)-len(s.rstrip("="))
        if k:
            if len(s)%block or k>=block: return None
            s=s[:len(s)-k]
            if (len(s)+block-1)//block*block != len(s)+k: return None
    L=len(s); n=L*bits//8
    if (8*n+bits-1)//bits != L: return None
    v=0
    for ch in s:
        if ch not in idx: return None
        v=(v<<bits)|idx[ch]
    spare=L*bits-8*n
    if lead:
        if v>>(8*n): return None
    else:
        if v & ((1<<spare)-1): return None
        v >>= spare
    return v.to_bytes(n,"big")
def dec58(s):
    for ch in s:
        if ch not in B58: return None
    return base58.b58decode(s)
CUSTOM = {"alphabet": SHORT}
forms = {
 "hex": (lambda b: b.hex(), lambda s: dec_bits(s.replace("-",""), HEX, 4, False)),
 "base32": (lambda b: enc_bits(b,CROCK,5,True), lambda s: dec_bits(s,CROCK,5,True)),
 "base32rfc": (lambda b: enc_bits(b,RFC,5,False), lambda s: dec_bits(s,RFC,5,False,pad=True)),
 "base32hex": (lambda b: enc_bits(b,RFCHEX,5,False), lambda s: dec_bits(s,RFCHEX,5,False,pad=True)),
 "base64url": (lambda b: enc_bits(b,B64U,6,False), lambda s: dec_bits(s,B64U,6,False,fold=False,pad=True)),
 "base64sort": (lambda b: enc_bits(b,B64S,6,False), lambda s: dec_bits(s,B64S,6,False,fold=False)),
 "base36": (lambda b: enc_radix(b,B36), lambda s: dec_radix(s,B36,True)),
 "base62": (lambda b: enc_radix(b,B62), lambda s: dec_radix(s,B62)),
 "base62sort": (lambda b: enc_radix(b,B62), lambda s: dec_radix(s,B62)),
 "alphabet": (lambda b: enc_radix(b,SHORT), lambda s: dec_radix(s,SHORT)),
 "base58": (lambda b: base58.b58encode(b).decode(), dec58),
}
# custom alphabets
for nm, al in [("alphabet:01","01"),("alphabet:0123","0123"),("alphabet:01234567","01234567"),("alphabet:abc","abc"),
               ("alphabet:"+string.printable[1:95].replace(" ",""), None), ("alphabet:0123456789","0123456789"),
               ("alphabet:"+B64U, B64U), ("alphabet:"+HEX, HEX), ("alphabet:!\"#$%&'","!\"#$%&'")]:
    al = al or nm.split(":",1)[1]
    forms[nm] = ((lambda al: lambda b: enc_radix(b,al))(al), (lambda al: lambda s: dec_radix(s,al))(al))
def mutate(s):
    alphabet=string.printable[:95]
    r=random.random()
    if not s: return random.choice(alphabet+"=")
    i=random.randrange(len(s))
    if r<0.15: return s[:i]+s[i].swapcase()+s[i+1:]
    if r<0.4: return s[:i]+random.choice(alphabet)+s[i+1:]
    if r<0.5: return s[:i]+s[i+1:]
    if r<0.6: return s[:i]+random.choice(alphabet)+s[i:]
    if r<0.7: return s+random.choice(["="," ","==","===","====","======","=======","========","\n"])
    if r<0.75: return s[:-1]+random.choice(alphabet)
    if r<0.8: return random.choice(["1","0","2","A","a","-","z","Z","~"])+s
    if r<0.85: return s.upper()
    if r<0.9: return s.lower()
    if r<0.95: return s[:1].replace(s[:1], random.choice("zZ~_-vV7Ff")) + s[1:]
    return s[:i]+"-"+s[i:]
sizes=[0,1,2,3,4,5,6,7,8,9,10,15,16,17,20,31,32,33,63,64,65,66,127,128,129,252,253,254,255,256,257,258,259,260,261,300,511,512,513,1000]
for form,(enc,dec) in forms.items():
    for n in sizes:
        for rep in range(6 if n<300 else 2):
            kind=random.random()
            if kind<0.15: b=bytes(n)
            elif kind<0.3: b=b"\xff"*n
            elif kind<0.45: b=bytes(random.randrange(n+1))+os.urandom(n); b=b[:n]
            else: b=os.urandom(n)
            s=enc(b)
            assert dec(s)==b,(form,n,s)
            cands=[s]
            for _ in range(8):
                m=mutate(s); cands.append(m)
                if random.random()<.3: cands.append(mutate(m))
            for c in cands:
                r=dec(c)
                out.write(f"{form.encode().hex()}\t{c.encode().hex()}\t{'NA' if r is None else 'E'+r.hex()}\n")
out.close()
