import { customRandom } from './nodeenv/node_modules/nanoid/index.js'
import fs from 'node:fs'
const cases = JSON.parse(fs.readFileSync('p15.json', 'utf8'))
let bad = 0
for (const c of cases) {
  const buf = Buffer.from(c.random, 'hex'); let used = 0, ran_out = false
  const gen = customRandom(c.alphabet, c.size, (k) => { if (used + k > buf.length) { ran_out = true; throw new Error('out') } const b = buf.subarray(used, used + k); used += k; return b })
  let exp = []
  try { for (let i = 0; i < c.n; i++) exp.push(gen(c.size)) } catch (e) { exp = ['ERR zuid_type_error'] }
  const got = Array.isArray(c.ids) ? c.ids : [c.ids]
  if (JSON.stringify(exp) !== JSON.stringify(got)) { bad++; console.log('MISMATCH', JSON.stringify(c.alphabet).slice(0, 30), c.size, c.n, exp[0].slice(0, 40), got[0].slice(0, 40)) }
}
console.log('cases', cases.length, 'mismatches', bad)
