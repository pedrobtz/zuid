import os, random, uuid, json, datetime
random.seed(11)
out=open("cases11.tsv","w")
def emit(fmt,text,**kw): out.write(f"{fmt}\t{text}\t{json.dumps(kw)}\n")
def rb(n, kind):
    if kind==0: return os.urandom(n)
    if kind==1: return bytes(n)
    if kind==2: return b"\xff"*n
    b=bytearray(os.urandom(n)); k=random.randrange(n); 
    for i in range(k): b[i]=random.choice([0,0xff])
    return bytes(b)
from ulid import ULID
from scru128 import Scru128Id
from scru64 import Scru64Id
from ksuid import Ksuid
from bson import ObjectId
from upid import UPID
for i in range(600):
    kind=i%4
    b=rb(16,kind)
    u=ULID.from_bytes(b); emit("ulid", str(u), ms=u.milliseconds, random=b[6:].hex())
    s=Scru128Id(int.from_bytes(b,"big")); emit("scru128", str(s), ms=s.timestamp, node=f"{s.counter_hi:06x}", sequence=s.counter_lo, random=f"{s.entropy:08x}")
    v=int.from_bytes(rb(8,kind),"big") % 36**12; s=Scru64Id(v); nb=random.randrange(1,24)
    emit("scru64", str(s), ms=s.timestamp*256, node=(s.node_ctr>>(24-nb)), sequence=s.node_ctr & ((1<<(24-nb))-1), node_bits=nb)
    kb=rb(20,kind); k=Ksuid.from_bytes(kb); emit("ksuid", str(k), ms=(int.from_bytes(kb[:4],"big")+1400000000)*1000, random=kb[4:].hex())
    ob=rb(12,kind); o=ObjectId(ob); emit("objectid", str(o), ms=int(o.generation_time.timestamp())*1000, random=ob[4:9].hex(), sequence=int.from_bytes(ob[9:],"big"))
    emit("xid_bytes", ob.hex(), ms=int.from_bytes(ob[:4],"big")*1000, node=ob[4:7].hex(), process=int.from_bytes(ob[7:9],"big"), sequence=int.from_bytes(ob[9:],"big"))
    # uuid: force version & variant
    ub=bytearray(b); ver=random.choice([1,2,3,4,5,6,7,8,0,9,15]); ub[6]=(ub[6]&0x0f)|(ver<<4); 
    if random.random()<0.85: ub[8]=(ub[8]&0x3f)|0x80
    U=uuid.UUID(bytes=bytes(ub)); kw={"version": ver}
    isrfc=(ub[8]&0xc0)==0x80
    var={uuid.RESERVED_NCS:"ncs",uuid.RFC_4122:"rfc",uuid.RESERVED_MICROSOFT:"microsoft",uuid.RESERVED_FUTURE:"future"}[U.variant]
    I=U.int
    if isrfc and ver==1:
        ticks=U.time; kw.update(ticks=ticks, sequence=U.clock_seq, node=f"{U.node:012x}")
    if isrfc and ver==6:
        ticks=((I>>96)<<28)|(((I>>80)&0xffff)<<12)|((I>>64)&0xfff); kw.update(ticks=ticks, sequence=U.clock_seq, node=f"{U.node:012x}")
    if isrfc and ver==7:
        kw.update(ms=I>>80, random=f"{(((I>>64)&0xfff)<<62)|(I&((1<<62)-1)):019x}")
    if isrfc and ver==4:
        r=((I>>80)<<74)|(((I>>64)&0xfff)<<62)|(I&((1<<62)-1)); kw.update(random=f"{r:031x}")
    if not isrfc: kw["version"]=None
    special = bytes(ub) in (bytes(16), b"\xff"*16)
    emit("uuid", str(U), variant=var, special=special, **kw)
    # upid
    up=UPID.from_str(UPID.from_prefix("ab").to_str()); 
    pb=rb(16,kind); 
    try:
        import upid as upm
        U2=UPID(pb); t=U2.to_str(); emit("upid", t, ms=U2.milliseconds, prefix=U2.prefix, hexb=pb.hex())
    except Exception as e:
        if i<3: print("upid err", e)
out.close()
