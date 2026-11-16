#!/usr/bin/env python3
"""내력 추적(classified.json)에서 확실한 어긋남만 SPEC §3.1에 바로잡는다.
SURE: 적힌 때의 첫 줄·끝 줄 글이 참 자리의 글과 같고, 그 사이 코드가 한 번도 덩이에 걸리지 않았다.
LIKELY(골라서): 첫 줄·끝 줄 글이 같고 내력에 짐작(approx·adjusted·mech?)이 없으며 범위가 크게 늘지 않았다.
쓰기: python3 apply_tier1.py <lineage.json> <출력 폴더> [--apply]
  lineage.json은 lineage.py --out 으로 만든다. 출력 폴더에 remaining.json(문장 대조가 필요한 참조)과 tier1_applied.json을 쓴다.
"""
import json, re, sys, collections
ARGS = [a for a in sys.argv[1:] if not a.startswith('--')]
S_OUT = ARGS[1]
L = json.load(open(ARGS[0], encoding='utf-8'))['refs']
REF = re.compile(r'([A-Za-z0-9_./\-]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?')
cache = {}
def flines(p):
    if p not in cache: cache[p] = open(p, encoding='utf-8', errors='replace').read().split('\n')
    return cache[p]
def trim(p, lo, hi):
    f = flines(p)
    while hi > lo and f[hi - 1].strip() == '': hi -= 1
    while lo < hi and f[lo - 1].strip() == '': lo += 1
    return lo, hi
import difflib
def sim(a, b): return difflib.SequenceMatcher(None, a, b).ratio()
def feat(x):
    bt = x['born_txt']; tt = x['t_txt']
    if bt is None or tt is None: return 'none'
    evs = set(e[0] for e in x['ev'])
    m = REF.fullmatch(x['t']); ln = int(m.group(3) or m.group(2)) - int(m.group(2)) + 1
    lenb = x['born_r'][1] - x['born_r'][0] + 1
    clean = evs <= {'partial', 'healed'}
    if tt == bt and not x['touched']: return 'SURE'
    if tt == bt: return 'LIKELY' if clean and ln <= lenb * 1.5 + 3 else 'LIKELY-x'
    s = min(sim(tt[0], bt[0]), sim(tt[1], bt[1]))
    if s >= 0.6:
        if ln == lenb or clean: return 'C-sim'
        return 'C-sim-x'
    return 'C-low'
# 에이전트가 손으로 정한 값(가운데 딴 코드가 끼어 둘로 나눈 것)이 있으면 그것을 쓴다
OVER = {('S211', 'src/sim/battle.gd:99-102'): 'src/sim/battle.gd:104-105 · src/sim/battle.gd:109',
        ('S209', 'src/ui/hud.gd:170-172'): 'src/ui/hud.gd:176 · src/ui/hud.gd:181'}
pick = {}; why = collections.Counter(); skipped = []
for x in L:
    if x['same']: continue
    m = REF.fullmatch(x['t']); p, lo, hi = m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))
    k = feat(x); x['feat'] = k
    if k not in ('SURE', 'LIKELY', 'C-sim'):
        skipped.append(x); continue
    lo, hi = trim(p, lo, hi)
    t = OVER.get((x['id'], x['a']), f'{p}:{lo}' + (f'-{hi}' if hi != lo else ''))
    if t == x['a']: continue   # 끝의 빈 줄만 다른 것(이미 옮긴 참조)
    pick[(x['id'], x['k'])] = (x['a'], t, k)
    why[k] += 1
# 글이 적힌 때와 많이 다른데 «맞음»으로 남은 자리도 살펴볼 것에 넣는다
for x in L:
    if x['same'] and x['born_txt'] and x['a_txt'] and x['a_txt'] != x['born_txt'] and min(sim(x['a_txt'][0], x['born_txt'][0]), sim(x['a_txt'][1], x['born_txt'][1])) < 0.6:
        x['feat'] = 'OK-low'; skipped.append(x)
src = open('SPEC.md', encoding='utf-8').read().split('\n')
i31 = next(i for i, l in enumerate(src) if l.startswith('### 3.1'))
i32 = next(i for i, l in enumerate(src) if l.startswith('### 3.2'))
done = 0; miss = []; changed_rows = set()
for i in range(i31, i32):
    l = src[i]
    if not l.startswith('| ') or l.startswith('| ---') or l.startswith('| 문장'): continue
    sid = l.split('|')[1].strip()
    head, cellpart = l.split('|', 2)[0:2], l.split('|', 2)[2]
    k = [-1]
    def rep(m):
        global done
        k[0] += 1
        key = (sid, k[0])
        if key in pick:
            a, t, _ = pick[key]
            cur = m.group(0)
            norm = re.sub(r':(\d+)-\1$', r':\1', cur)
            if norm != a:
                miss.append((sid, k[0], cur, a)); return cur
            done += 1; changed_rows.add(sid)
            return t
        return m.group(0)
    new = REF.sub(rep, cellpart)
    src[i] = '|'.join(head) + '|' + new
print('고를 것', dict(why), '· 바꿈', done, '· 행', len(changed_rows), '· 안 맞음', len(miss), '· 남김', len(skipped))
for x in miss[:10]: print('  !', x)
json.dump(skipped, open(f'{S_OUT}/remaining.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
json.dump([dict(id=k[0], k=k[1], a=v[0], t=v[1], cls=v[2]) for k, v in pick.items()], open(f'{S_OUT}/tier1_applied.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
if '--apply' in sys.argv:
    open('SPEC.md', 'w', encoding='utf-8').write('\n'.join(src)); print('SPEC.md에 썼다')
