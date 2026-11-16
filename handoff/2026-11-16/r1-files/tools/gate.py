#!/usr/bin/env python3
"""SDD 장부 검사(클라우드 대용: spec-verify·eval-verify가 없다).
쓰기: python3 gate.py [--root 경로] [--write-lock] [--quiet]
검사:
 1) EVAL 본표 EV마다 «마지막 개정 행 해시(없으면 표 해시)» == 지금 SPEC 근거 문장 해시
 2) SPEC §3.1 줄 참조: 파일이 있고 줄 범위가 파일 길이 안
 3) EV마다 tests/eval/gd/<스위트>.gd의 func evN과 test_*.py의 gd("스위트","EVN")
 4) 락(.specgate-eval.lock)을 같은 규칙으로 다시 만들어 저장된 락과 견줌(--write-lock이면 고쳐 씀)
"""
import sys, re, json, hashlib, argparse, datetime, glob, os
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument('--root', default='.')
ap.add_argument('--write-lock', action='store_true')
ap.add_argument('--quiet', action='store_true')
a = ap.parse_args()
R = Path(a.root).resolve()

def h(s):
    return hashlib.sha256(s.encode('utf-8')).hexdigest()[:8]
def fh(p):
    return h(p.read_text(encoding='utf-8').replace('\r\n', '\n').strip())

bad = []
spec = (R / 'SPEC.md').read_text(encoding='utf-8').replace('\r\n', '\n').split('\n')
ev_md = (R / 'EVAL.md').read_text(encoding='utf-8').replace('\r\n', '\n')
evl = ev_md.split('\n')

# SPEC 문장
sent = {}
for i, l in enumerate(spec):
    m = re.match(r'- ([SIU]\d+)\. ', l)
    if m:
        if m.group(1) in sent:
            # §3.2 재확인 목록의 U 재기재는 무시(첫 것이 문장)
            continue
        sent[m.group(1)] = l[2:].strip()
sh = {k: h(v) for k, v in sent.items()}

# EVAL 본표·개정 표
i_main = next(i for i, l in enumerate(evl) if l.startswith('| ID | 근거 |'))
i_rev = next(i for i, l in enumerate(evl) if l.startswith('| EV# | 새 해시 |'))
i_hold = next(i for i, l in enumerate(evl) if l.startswith('## 보류'))
rows = {}
order = []
for l in evl[i_main + 2:i_hold]:
    if not l.startswith('| EV'):
        continue
    c = [x.strip() for x in l.strip().strip('|').split('|')]
    # 측정 글에 '|'가 들 수 있다 — 앞 셋과 뒤 둘만 믿는다
    ev, basis, hsh = c[0], c[1], c[2]
    test = next((x for x in c if x.startswith('tests/')), '')
    if ev in rows:
        bad.append(f'EV 중복: {ev}')
    rows[ev] = dict(basis=basis, hash=hsh, test=test, line=l)
    order.append(ev)
revs = {}
for n, l in enumerate(evl[i_rev + 2:], i_rev + 3):
    if not l.startswith('| EV'):
        continue
    c = [x.strip() for x in l.strip().strip('|').split('|')]
    hs = c[1]
    if not re.fullmatch(r'[0-9a-f]{8}', hs):
        bad.append(f'개정 행 {n}: 해시 꼴이 아니다: {hs}')
    # 검사기는 그 행(사유 글 포함)의 EV 번호마다 같은 해시를 준다
    for ev in re.findall(r'EV\d+', l):
        revs[ev] = (hs, n)
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', c[-1]):
        bad.append(f'개정 행 {n}: 날짜 꼴이 아니다: {c[-1]}')

# 본표에 없는 EV를 가리키는 개정 행(지운 EV의 행이 남았다). 선례(2c36eb3)는 지운 EV의 개정 행을 남기지 않는다
for ev, (hs, n) in sorted(revs.items(), key=lambda kv: kv[1][1]):
    if ev not in rows:
        bad.append(f'개정 행 {n}: {ev}가 본표에 없다')

for ev in order:
    r = rows[ev]
    ids = re.findall(r'[SIU]\d+', r['basis'])
    if not ids:
        bad.append(f'{ev}: 근거가 없다: {r["basis"]}')
        continue
    eff = revs[ev][0] if ev in revs else r['hash']
    cur = [sh.get(x) for x in ids]
    if None in cur:
        bad.append(f'{ev}: 근거 {r["basis"]}가 SPEC에 없다')
    elif len(ids) == 1 and eff != cur[0]:
        bad.append(f'{ev}: 근거 {ids[0]} 해시 {cur[0]} ≠ 장부 {eff}' + (f'(개정 행 {revs[ev][1]})' if ev in revs else '(본표)'))
    elif len(ids) > 1 and eff not in cur and eff != h('\n'.join(sent[x] for x in ids)):
        bad.append(f'{ev}: 근거 {ids} 해시 {cur} ≠ 장부 {eff}')

# 테스트 파일 대응
gd_src = {}
py_src = {}
for ev in order:
    t = rows[ev]['test']
    if not t:
        bad.append(f'{ev}: 테스트 칸이 없다')
        continue
    p = R / t
    if not p.exists():
        bad.append(f'{ev}: 테스트 파일이 없다: {t}')
        continue
    if t not in py_src:
        py_src[t] = p.read_text(encoding='utf-8')
    if t.startswith('tests/eval/test_'):
        m = re.search(r'gd\("(\w+)",\s*"%s"\)' % ev, py_src[t])
        if not m:
            bad.append(f'{ev}: {t}에 gd("…","{ev}")가 없다')
            continue
        s = m.group(1)
        if s not in gd_src:
            q = R / 'tests' / 'eval' / 'gd' / f'{s}.gd'
            gd_src[s] = q.read_text(encoding='utf-8') if q.exists() else ''
        if not re.search(r'^func %s\(' % ev.lower(), gd_src[s], re.M):
            bad.append(f'{ev}: tests/eval/gd/{s}.gd에 func {ev.lower()}이 없다')

# §3.1 줄 참조
i31 = next(i for i, l in enumerate(spec) if l.startswith('### 3.1'))
i32 = next(i for i, l in enumerate(spec) if l.startswith('### 3.2'))
nlines = {}
refs = 0
rowids = []
for n, l in enumerate(spec[i31:i32], i31 + 1):
    if not l.startswith('| ') or l.startswith('| 문장') or l.startswith('| ---'):
        continue
    c = l.strip().strip('|').split('|')
    sid = c[0].strip()
    rowids.append(sid)
    for path, a1, b1 in re.findall(r'([A-Za-z0-9_./\-]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?', l):
        refs += 1
        p = R / path
        if path not in nlines:
            if not p.exists():
                nlines[path] = -1
            else:
                try:
                    nlines[path] = len(p.read_text(encoding='utf-8').replace('\r\n', '\n').rstrip('\n').split('\n'))
                except Exception:
                    nlines[path] = 10 ** 9
        if nlines[path] < 0:
            bad.append(f'§3.1 {sid}(SPEC:{n}): 파일이 없다: {path}')
            continue
        lo, hi = int(a1), int(b1 or a1)
        if lo < 1 or hi < lo or hi > nlines[path]:
            bad.append(f'§3.1 {sid}(SPEC:{n}): {path}:{a1}{"-" + b1 if b1 else ""} 범위 밖(파일 {nlines[path]}줄)')
    for path in re.findall(r'(?:^|[ ·|])((?:src|data|tools|tests|locale|art|audio)/[A-Za-z0-9_./\-]+\.[A-Za-z0-9]+)(?![:\w])', l):
        if not (R / path).exists():
            bad.append(f'§3.1 {sid}(SPEC:{n}): 파일이 없다: {path}')
dup = {x for x in rowids if rowids.count(x) > 1}
if dup:
    bad.append(f'§3.1 중복 행: {sorted(dup)}')

# 락
lock_p = R / '.specgate-eval.lock'
old = json.loads(lock_p.read_text(encoding='utf-8'))
tests = {}
for p in sorted([R / 'tests/eval/conftest.py'] + [Path(x) for x in glob.glob(str(R / 'tests/eval/gd/*'))] + [Path(x) for x in glob.glob(str(R / 'tests/eval/test_*.py'))]):
    if p.is_file():
        tests[p.relative_to(R).as_posix()] = fh(p)
basis_ids = []
for ev in order:
    for x in re.findall(r'[SIU]\d+', rows[ev]['basis']):
        if x not in basis_ids:
            basis_ids.append(x)
new = {
    'approvedAt': old.get('approvedAt'),
    'evalMd': h(ev_md.strip()),
    'tests': tests,
    'sentences': {x: sh[x] for x in basis_ids if x in sh},
}
diff = []
if new['evalMd'] != old['evalMd']:
    diff.append(f'evalMd {old["evalMd"]} → {new["evalMd"]}')
for k in ('tests', 'sentences'):
    for x in sorted(set(old[k]) | set(new[k])):
        if old[k].get(x) != new[k].get(x):
            diff.append(f'{k}[{x}] {old[k].get(x)} → {new[k].get(x)}')
    if list(old[k].keys()) != list(new[k].keys()) and set(old[k]) == set(new[k]):
        diff.append(f'{k}: 키 차례만 다르다')

print(f'문장 {len(sent)} · EV {len(order)} · 개정 EV {len(revs)} · §3.1 행 {len(rowids)}·참조 {refs} · 락 tests {len(tests)}·sentences {len(new["sentences"])}')
if diff and a.write_lock:
    # 저장된 락의 키 차례를 지키고 새 키는 뒤에 붙인다
    out = {'approvedAt': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.') + '%03dZ' % (datetime.datetime.now().microsecond // 1000), 'evalMd': new['evalMd']}
    for k in ('tests', 'sentences'):
        d = {}
        for x in old[k]:
            if x in new[k]:
                d[x] = new[k][x]
        for x in new[k]:
            if x not in d:
                d[x] = new[k][x]
        out[k] = d
    raw = lock_p.read_bytes()
    nl = '\r\n' if b'\r\n' in raw else '\n'
    txt = json.dumps(out, ensure_ascii=False, indent=2)
    if raw.endswith(b'\n'):
        txt += '\n'
    lock_p.write_bytes(txt.replace('\n', nl).encode('utf-8'))
    print(f'락을 고쳐 썼다({len(diff)}곳)')
    if not a.quiet:
        for d_ in diff[:60]:
            print('  락:', d_)
elif diff:
    print(f'락이 지금 트리와 다르다({len(diff)}곳) — 장부를 다 고친 뒤 --write-lock')
    if not a.quiet:
        for d_ in diff[:60]:
            print('  락:', d_)
else:
    print('락: 지금 트리와 같다')
if bad:
    print(f'위반 {len(bad)}')
    for b in bad[:200]:
        print('  ✗', b)
    sys.exit(1)
print('위반 0')
