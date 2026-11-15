import sys, uuid, math, datetime
from ulid import ULID
import scru128, scru64, upid as upidmod
from ksuid import Ksuid
from bson import ObjectId
from typeid import TypeID
G = 0x01B21DD213814000
bad = 0; n = 0
def fail(*a):
    global bad; bad += 1; print("MISMATCH", *a)
for line in open("p07.tsv"):
    f = line.rstrip("\n").split("\t"); kind, s = f[0], f[1]; n += 1
    t = float(f[2]) if len(f) > 2 else None
    try:
        if kind in ("uuid7", "live_uuid7"):
            u = uuid.UUID(s); 
            if u.version != 7 or u.variant != uuid.RFC_4122: fail(line)
            ms = u.int >> 80
            if kind == "uuid7":
                r = bytes.fromhex(f[3])
                if ms != math.floor(t): fail("time", line, ms)
                if ((u.int >> 64) & 0xfff) != (int.from_bytes(r[:2], "big") & 0x7ff): fail("counter", line)
                if (u.int & ((1 << 62) - 1)) != (int.from_bytes(r[2:], "big") & ((1 << 62) - 1)): fail("rand_b", line)
            elif not (0 <= t - ms < 50): fail("live time", line, ms)
        elif kind == "typeid":
            ty = TypeID.from_string(s); u = ty.uuid; r = bytes.fromhex(f[3])
            if ty.prefix != "user_x" or (u.int >> 80) != math.floor(t) or u.version != 7: fail(line)
        elif kind in ("ulid", "live_ulid"):
            u = ULID.from_str(s)
            if kind == "ulid":
                if u.milliseconds != math.floor(t) or u.bytes[6:] != bytes.fromhex(f[3]): fail(line, u.milliseconds)
            elif not (0 <= t - u.milliseconds < 50): fail("live", line)
        elif kind in ("upid", "live_upid"):
            u = upidmod.UPID.from_str(s)
            if kind == "upid":
                if u.prefix != "abzz"[:len(u.prefix)] and u.prefix != "ab": fail("prefix", line, u.prefix)
                if abs(u.milliseconds - (math.floor(t) >> 8 << 8)) > 0: fail("time", line, u.milliseconds)
                if bytes(u)[5:13] != bytes.fromhex(f[3]): fail("random", line)
            else:
                if u.prefix != "user" or not (0 <= t - u.milliseconds < 256 + 50): fail("live", line, u.prefix, u.milliseconds)
        elif kind in ("scru128", "live_scru128"):
            u = scru128.Scru128Id.from_str(s)
            if kind == "scru128":
                r = bytes.fromhex(f[3])
                if u.timestamp != math.floor(t) or u.entropy != int.from_bytes(r[:4], "big") or u.counter_lo != int.from_bytes(r[4:7], "big") or u.counter_hi != int.from_bytes(r[7:10], "big"): fail(line, u.timestamp, u.counter_hi, u.counter_lo, u.entropy)
            elif not (0 <= t - u.timestamp < 50): fail("live", line)
        elif kind in ("scru64", "live_scru64"):
            u = scru64.Scru64Id.from_str(s)
            if kind == "scru64":
                nb = int(f[4]); cb = 24 - nb; r = int.from_bytes(bytes.fromhex(f[3]), "big")
                if u.timestamp != math.floor(t) >> 8: fail("ts", line, u.timestamp)
                if (u.node_ctr >> cb) != (1 << nb) - 1: fail("node", line)
                ctr = u.node_ctr & ((1 << cb) - 1)
                print("scru64 nb", nb, "seed", hex(r & ((1 << cb) - 1)), "ctr", hex(ctr))
            elif not (0 <= (int(t) >> 8) - u.timestamp <= 1) or (u.node_ctr >> 16) != 5: fail("live", line)
        elif kind in ("uuid1", "uuid6", "live_uuid1", "live_uuid6"):
            u = uuid.UUID(s); v = 1 if "1" in kind else 6
            if u.version != v or u.variant != uuid.RFC_4122: fail("ver", line)
            if v == 1: ticks = u.time
            else: ticks = ((u.int >> 80) << 12) | ((u.int >> 64) & 0xfff)
            if kind.startswith("live"):
                if not (0 <= t * 10000 - (ticks - G) < 500000): fail("live", line)
                if not (u.node >> 40) & 1: fail("multicast", line)
            else:
                from decimal import Decimal
                want = math.floor(Decimal(f[2]) * 1000) * 10 + G
                if ticks != want: fail("ticks", line, ticks, want)
                if u.clock_seq != int(f[3], 16) & 0x3fff: fail("clockseq", line)
                if u.node != int(f[4], 16): fail("node", line)
        elif kind in ("uuid4", "uuid8"):
            u = uuid.UUID(s); r = int(f[3], 16); v = int(kind[-1])
            mask = ~((0xf << 76) | (0x3 << 62)) & ((1 << 128) - 1)
            if u.version != v or u.variant != uuid.RFC_4122 or (u.int & mask) != (r & mask): fail(line)
        elif kind in ("ksuid", "live_ksuid"):
            k = Ksuid.from_base62(s); secs = int.from_bytes(bytes(k)[:4], "big") + 1400000000
            if kind == "ksuid":
                if secs != math.floor(t / 1000) or bytes(k)[4:] != bytes.fromhex(f[3]): fail(line, secs)
            elif not (0 <= t / 1000 - secs < 2): fail("live", line)
        elif kind in ("objectid", "live_objectid"):
            o = ObjectId(s); secs = int.from_bytes(o.binary[:4], "big")
            if kind == "objectid":
                r = bytes.fromhex(f[3])
                if secs != math.floor(t / 1000) or o.binary[4:] != r: fail(line, secs)
            elif not (0 <= t / 1000 - secs < 2): fail("live", line)
        elif kind in ("xid", "live_xid"):
            import base64
            raw = base64.b32hexdecode((s.upper() + "====")[:24] if False else (s.upper() + "0000")[:24] )[:12] if False else None
            alpha = "0123456789abcdefghijklmnopqrstuv"; v = 0
            for ch in s: v = v * 32 + alpha.index(ch)
            if v & 0xf: fail("xid tail bits", line)
            b = (v >> 4).to_bytes(12, "big"); secs = int.from_bytes(b[:4], "big")
            if kind == "xid":
                r = bytes.fromhex(f[3])
                if secs != math.floor(t / 1000) or b[4:7] != r[:3] or b[7:9] != (70000 % 65536).to_bytes(2, "big") or b[9:] != r[3:]: fail(line, b.hex())
            elif not (0 <= t / 1000 - secs < 2) or int.from_bytes(b[7:9], "big") != int(f[3]) % 65536: fail("live", line)
        else: fail("unknown kind", kind)
    except Exception as e:
        fail("EXC", repr(e), line)
print("checked", n, "mismatches", bad)
