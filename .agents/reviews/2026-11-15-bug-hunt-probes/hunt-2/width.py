import math
best=[]
for b in range(2,95):
    if b & (b-1)==0: continue
    l=math.log2(b)
    for n in range(1,65537):
        q=8*n/l; d=abs(q-round(q))
        best.append((d,b,n))
    # decode side: len*log2(b)/8 near integer
best.sort(); print(best[:8])
# exact check of the closest 200
bad=0
for d,b,n in best[:300]:
    w=math.ceil(8*n/math.log2(b))
    t=256**n
    if not (b**w>=t and b**(w-1)<t): bad+=1; print("BAD",b,n,w)
print("bad",bad)
