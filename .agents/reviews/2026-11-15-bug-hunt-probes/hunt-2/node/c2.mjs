import { isCuid, createId, init } from '@paralleldrive/cuid2';
import fs from 'fs';
let seed=12345; const rnd=()=>{ seed=(seed*1103515245+12345)&0x7fffffff; return seed/0x7fffffff; };
const out=[]; const al="0123456789abcdefghijklmnopqrstuvwxyz";
const cands=["","a","1","ab","a1","1a","11","A1","aB","a-","a_", " a1","a1 ","a1\n", "a".repeat(32),"a".repeat(33),"1".repeat(32),"1".repeat(33),"a"+"1".repeat(31),"a"+"1".repeat(32), "é1", "aé"];
for (let i=0;i<300;i++){ const len=[2,3,10,24,31,32,33,34][Math.floor(rnd()*8)]; cands.push(init({length: Math.min(len,32)})()); let s=""; for(let k=0;k<len;k++) s+=al[Math.floor(rnd()*36)]; cands.push(s); const j=Math.floor(rnd()*len); cands.push(s.slice(0,j)+"AZ_-. ~"[Math.floor(rnd()*7)]+s.slice(j+1)); }
for (const c of cands) out.push(Buffer.from(c).toString('hex')+"\t"+(isCuid(c)?1:0));
fs.writeFileSync("../cases7.tsv", out.join("\n")+"\n");
