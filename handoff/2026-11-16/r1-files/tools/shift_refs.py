#!/usr/bin/env python3
"""SPEC §3.1 줄 참조 옮기기.
쓰기: python3 shift_refs.py [--root 경로] [--base REV] [--apply]
base(기본 HEAD)와 작업 트리 사이에 바뀐 파일마다 `git diff -U0` 덩이로 옛 줄 → 새 줄을 구해
§3.1 표의 `경로:줄` · `경로:줄-줄` 참조를 옮긴다. 바뀐 덩이에 걸친 참조는 «손으로 볼 것»으로 찍는다.
--apply가 없으면 바꿀 내용만 보인다. SPEC.md 자신의 줄은 옮기지 않는다(§3.1은 SPEC.md를 가리키지 않는다).
"""
import sys, re, subprocess, argparse
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument('--root', default='.')
ap.add_argument('--base', default='HEAD')
ap.add_argument('--apply', action='store_true')
a = ap.parse_args()
R = Path(a.root).resolve()

def git(*args):
    return subprocess.run(['git', '-C', str(R), *args], stdout=subprocess.PIPE, text=True, encoding='utf-8', errors='replace', check=True).stdout

changed = [p for p in git('diff', '--name-only', a.base).split('\n') if p and p != 'SPEC.md']
hunks = {}
for p in changed:
    hs = []
    for l in git('diff', '-U0', a.base, '--', p).split('\n'):
        m = re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', l)
        if m:
            oa, ob, na, nb = int(m.group(1)), int(m.group(2) or 1), int(m.group(3)), int(m.group(4) or 1)
            hs.append((oa, ob, na, nb))
    hunks[p] = hs

def mp(p, n, end=False):
    """옛 줄 n → (새 줄, 덩이에 걸렸나)"""
    off = 0
    for oa, ob, na, nb in hunks[p]:
        if ob == 0:  # 순수 삽입: oa 줄 뒤에 nb줄
            if n > oa:
                off += nb
            continue
        if n < oa:
            break
        if n <= oa + ob - 1:  # 바뀐·지운 덩이 안
            if nb == 0:
                return (max(1, na + (0 if end else 1)), True)
            k = min(n - oa, nb - 1)
            return ((na + nb - 1) if end else (na + k), True)
        off += nb - ob
    return (n + off, False)

def touched(p, lo, hi):
    for oa, ob, na, nb in hunks[p]:
        if ob == 0:
            if lo <= oa < hi:  # 범위 안쪽에 삽입
                return True
        elif not (oa + ob - 1 < lo or oa > hi):
            return True
    return False

spec_p = R / 'SPEC.md'
raw = spec_p.read_bytes()
nl = '\r\n' if b'\r\n' in raw else '\n'
L = raw.decode('utf-8').replace('\r\n', '\n').split('\n')
i31 = next(i for i, l in enumerate(L) if l.startswith('### 3.1'))
i32 = next(i for i, l in enumerate(L) if l.startswith('### 3.2'))
moved = 0
review = []
pat = re.compile(r'([A-Za-z0-9_./\-]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?')
for i in range(i31, i32):
    l = L[i]
    if not l.startswith('| '):
        continue
    sid = l.split('|')[1].strip()
    def rep(m):
        global moved
        p, lo, hi = m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))
        if p not in hunks or not hunks[p]:
            return m.group(0)
        nlo, t1 = mp(p, lo)
        nhi, t2 = mp(p, hi, end=True)
        t = t1 or t2 or touched(p, lo, hi)
        if nhi < nlo:
            nhi = nlo
        new = f'{p}:{nlo}' + (f'-{nhi}' if m.group(3) else '')
        if t:
            review.append(f'{sid}(SPEC:{i + 1}): {m.group(0)} → {new}')
        if new != m.group(0):
            moved += 1
        return new
    L[i] = pat.sub(rep, l)
print(f'바뀐 파일 {len(changed)}: ' + ', '.join(f'{p}({len(hunks[p])}덩이)' for p in changed if hunks[p]))
print(f'옮긴 참조 {moved} · 손으로 볼 것 {len(review)}')
for r in review:
    print('  ?', r)
if a.apply:
    spec_p.write_bytes(nl.join(L).encode('utf-8'))
    print('SPEC.md에 썼다')
