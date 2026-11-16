#!/usr/bin/env python3
"""2단계: 에이전트 결정(워크플로 출력 여러 개)을 SPEC §3.1에 적용한다.
쓰기: python3 apply_tier2.py <출력.json>... [--apply] [--skip-low]
결정은 (id, a) → final. 행에서 a와 같은 참조를 final로 바꾼다(빈 글이면 지운다, 행에 이미 있는 참조는 겹쳐 넣지 않는다).
"""
import json, re, sys, os, collections
files = [a for a in sys.argv[1:] if not a.startswith('--')]
apply = '--apply' in sys.argv; skip_low = '--skip-low' in sys.argv
REF = re.compile(r'[A-Za-z0-9_./\-]+\.[A-Za-z0-9]+:\d+(?:-\d+)?')
def norm(s): return re.sub(r':(\d+)-\1(?!\d)', r':\1', s.strip())
dec = []; ver = []
for f in files:
    d = json.load(open(f, encoding='utf-8'))
    for r in d.get('result', d):
        if r is None or r.get('result') is None: print('  ! 빈 결과', f, r and r.get('key')); continue
        if r['kind'] == 'verify': ver.append(r)
        else:
            for x in r['result']['decisions']: dec.append(dict(x, key=r['key']))
L = open('SPEC.md', encoding='utf-8').read().split('\n')
i31 = next(i for i, l in enumerate(L) if l.startswith('### 3.1'))
i32 = next(i for i, l in enumerate(L) if l.startswith('### 3.2'))
row = {l.split('|')[1].strip(): i for i, l in enumerate(L[:i32]) if i > i31 and l.startswith('| ') and not l.startswith('| ---') and not l.startswith('| 문장')}
def cell(i): return re.match(r'^\| (\S+) \|(.*)\|$', L[i]).group(2).strip()
def setcell(i, c):
    sid = L[i].split('|')[1].strip(); L[i] = f'| {sid} | {c} |' if c else f'| {sid} | |'
def tidy(c):
    c = re.sub(r'(?:\s*·\s*){2,}', ' · ', c)
    c = re.sub(r'([①-⑳])\s*·\s*', r'\1 ', c)
    c = re.sub(r'\s*·\s*(?=[①-⑳])', ' · ', c)
    c = re.sub(r'\s*·\s*$', '', c); c = re.sub(r'^\s*·\s*', '', c)
    return re.sub(r'  +', ' ', c).strip()
cache = {}
def nlines(p):
    if p not in cache: cache[p] = len(open(p, encoding='utf-8', errors='replace').read().split('\n')) if os.path.exists(p) else -1
    return cache[p]
st = collections.Counter(); probs = []; emptied = []
for d in dec:
    sid = d['id']; a = norm(d['a']); fin = ' · '.join(norm(f) for f in d['final'].split(' · ') if f.strip())
    if sid not in row: probs.append(f"{d['key']}: 행 없음 {sid}"); continue
    if skip_low and d['conf'] == 'low': st['low 건너뜀'] += 1; continue
    bad = False
    for f in REF.findall(fin):
        p, rng = f.rsplit(':', 1); lo = int(rng.split('-')[0]); hi = int(rng.split('-')[-1])
        if nlines(p) < 0 or hi > nlines(p) or lo > hi or lo < 1: bad = True
    if bad or (fin and REF.sub('', fin).replace('·', '').strip()):
        probs.append(f"{d['key']}: {sid} final 꼴·범위 문제 {d['final']!r}"); continue
    c = cell(row[sid]); refs = [norm(r) for r in REF.findall(c)]
    if a not in refs:
        if fin and all(f in refs for f in fin.split(' · ')): st['이미 반영'] += 1; continue
        probs.append(f"{d['key']}: {sid}에 a {a} 없음(final {fin!r})"); continue
    if fin == a: st['그대로'] += 1; continue
    others = [r for r in refs if r != a]
    keep = [f for f in fin.split(' · ') if f and f not in others] if fin else []
    pat = re.compile(re.escape(a) + r'(?:-' + a.rsplit(':', 1)[1] + r')?(?![\d\-])')
    c2 = tidy(pat.sub(' · '.join(keep), c, count=1))
    setcell(row[sid], c2)
    st['바꿈' if keep else '지움'] += 1
    if not REF.findall(c2): emptied.append(sid)
print(dict(st)); print('결정', len(dec), '· conf', dict(collections.Counter(d['conf'] for d in dec)), '· kind', dict(collections.Counter(d['kind'] for d in dec)))
for x in probs: print('  !', x)
print('참조가 하나도 안 남은 행:', sorted(set(emptied)))
for r in ver:
    v = r['result']; print(f"검증 {r['key']}: 본 것 {v['checked']} · 틀림 {len(v['wrong'])} · 애매 {len(v['doubts'])}")
if apply:
    open('SPEC.md', 'w', encoding='utf-8').write('\n'.join(L)); print('SPEC.md에 썼다')
