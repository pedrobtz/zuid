import json, base64, base58, uuid, shortuuid, math
C = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
def digits(n, base, alpha, width):
    s = ""
    while n: s = alpha[n % base] + s; n //= base
    return s.rjust(width, alpha[0])
def width(nbytes, base): 
    # smallest w with base^w >= 256^nbytes
    w = 0; cap = 1; lim = 256 ** nbytes
    while cap < lim: cap *= base; w += 1
    return w
def crock(b):
    n = int.from_bytes(b, "big"); w = math.ceil(len(b) * 8 / 5); return digits(n, 32, C, w) if len(b) else ""
B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"; B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
SU = shortuuid.get_alphabet()
def proquint(b):
    co = "bdfghjklmnprstvz"; vo = "aiou"; out = []
    for i in range(0, len(b), 2):
        v = int.from_bytes(b[i:i+2], "big")
        out.append(co[v >> 12] + vo[(v >> 10) & 3] + co[(v >> 6) & 15] + vo[(v >> 4) & 3] + co[v & 15])
    return "-".join(out)
B64S = "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"; B64U = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
bad = 0; cases = json.load(open("p17.json")); seen = {}
for c in cases:
    b = bytes.fromhex(c["hexin"]); n = int.from_bytes(b, "big")
    u = base64.urlsafe_b64encode(b).decode().rstrip("=")
    exp = dict(hex=b.hex(), base32=crock(b), base32rfc=base64.b32encode(b).decode().rstrip("="), base32hex=base64.b32hexencode(b).decode().rstrip("="),
               base36=digits(n, 36, B36, width(len(b), 36)), base58=base58.b58encode(b).decode(), base62=digits(n, 62, B62, width(len(b), 62)),
               base64url=u, base64sort="".join(B64S[B64U.index(ch)] for ch in u), alphabet=digits(n, 57, SU, width(len(b), 57)), alpha10=digits(n, 10, "0123456789", width(len(b), 10)))
    exp["base62sort"] = exp["base62"]
    exp["proquint"] = proquint(b) if len(b) % 2 == 0 else "ERR zuid_type_error"
    for k, v in exp.items():
        if c[k] != v:
            key = (k, len(b) in (0,)); 
            if seen.get(k, 0) < 3: print("MISMATCH", k, len(b), "ref", v[:50], "zuid", str(c[k])[:50])
            seen[k] = seen.get(k, 0) + 1; bad += 1
print("cases", len(cases), "mismatch cells", bad, seen)
# shortuuid cross-check for 16 bytes
for c in cases:
    b = bytes.fromhex(c["hexin"])
    if len(b) == 16:
        assert shortuuid.encode(uuid.UUID(bytes=b)) == c["alphabet"], (c["alphabet"], shortuuid.encode(uuid.UUID(bytes=b)))
print("shortuuid 16-byte agrees")
