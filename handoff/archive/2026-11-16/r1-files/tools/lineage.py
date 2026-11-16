#!/usr/bin/env python3
"""SPEC §3.1 줄 참조의 내력 추적.
첫 부모 이력을 처음부터 따라가며 참조마다 «참 자리»(적힌 때의 코드가 지금 있는 줄)를 구한다.
- 커밋 C1→C2에서 참조 글이 그대로인데 코드가 그 위에서 늘거나 줄었으면: 어긋남이 생긴 것 → 참 자리만 옮긴다.
- 참조 글이 diff 덩이대로 옮겨졌으면: 맞게 옮긴 것 → 참 자리도 같이 옮긴다(이미 어긋나 있었으면 어긋난 채 평행 이동).
- 참조 글이 다른 값으로 바뀌었으면: 손으로 다시 적은 것 → 그 값을 참으로 믿는다(참 자리와 같으면 «바로잡힘»).
쓰기: python3 lineage.py [--root .] [--rev HEAD] --out 결과.json
"""
import sys, re, subprocess, json, argparse, functools
ap = argparse.ArgumentParser()
ap.add_argument('--root', default='.'); ap.add_argument('--rev', default='HEAD'); ap.add_argument('--out', required=True)
A = ap.parse_args()
def git(*a, ok=False):
    r = subprocess.run(['git', '-C', A.root, *a], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', errors='replace')
    if r.returncode != 0:
        if ok: return None
        raise SystemExit(f'git {a} 실패')
    return r.stdout
commits = git('rev-list', '--first-parent', '--reverse', A.rev).split()
REF = re.compile(r'([A-Za-z0-9_./\-]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?')

@functools.lru_cache(maxsize=4000)
def flines(c, p):
    t = git('show', f'{c}:{p}', ok=True)
    return None if t is None else t.split('\n')

def rows_at(c):
    t = git('show', f'{c}:SPEC.md', ok=True)
    if t is None: return {}
    L = t.split('\n')
    try: i31 = next(i for i, l in enumerate(L) if l.startswith('### 3.1'))
    except StopIteration: return {}
    out = {}
    for l in L[i31 + 1:]:
        if l.startswith('### ') or l.startswith('## '): break
        if not l.startswith('| ') or l.startswith('| ---') or l.startswith('| 문장'): continue
        sid = l.split('|')[1].strip()
        out[sid] = [(m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))) for m in REF.finditer(l.split('|', 2)[2])]
    return out

def hunks(c1, c2, p):
    hs = []
    t = git('diff', '-U0', '--no-renames', c1, c2, '--', p, ok=True) or ''
    for l in t.split('\n'):
        m = re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', l)
        if m: hs.append((int(m.group(1)), int(m.group(2) or 1), int(m.group(3)), int(m.group(4) or 1)))
    return hs

def mp(hs, n, end=False):
    off = 0
    for oa, ob, na, nb in hs:
        if ob == 0:
            if n > oa: off += nb
            continue
        if n < oa: break
        if n <= oa + ob - 1:
            if nb == 0: return (max(1, na + (0 if end else 1)), True)
            k = min(n - oa, nb - 1)
            return ((na + nb - 1) if end else (na + k), True)
        off += nb - ob
    return (n + off, False)

def touched(hs, lo, hi):
    for oa, ob, na, nb in hs:
        if ob == 0:
            if lo <= oa < hi: return True
        elif not (oa + ob - 1 < lo or oa > hi): return True
    return False

def shift(hs, r):
    p, lo, hi = r
    if not hs: return (r, False)
    nlo, t1 = mp(hs, lo); nhi, t2 = mp(hs, hi, end=True)
    if nhi < nlo: nhi = nlo
    return ((p, nlo, nhi), t1 or t2 or touched(hs, lo, hi))

def text(c, r):
    f = flines(c, r[0])
    if f is None or r[2] > len(f) or r[1] < 1: return None
    return [f[r[1] - 1].strip(), f[r[2] - 1].strip()]


def mk(r, c, ev=None):
    return dict(a=r, P={r: False}, m=r, t=r, born=c, born_r=r, born_txt=text(c, r), touched=False, ev=ev or [])

state = {}      # sid -> [slot]
drift_commits = {}
stats = dict(pairs=0, late=0, partial=0, healed=0, adjusted=0, approx=0, mechq=0, reauth=0, new=0)
log = []
for ci, c2 in enumerate(commits):
    if ci == 0:
        for sid, refs in rows_at(c2).items():
            state[sid] = [mk(r, c2) for r in refs]
        continue
    c1 = commits[ci - 1]
    names = set(n for n in git('diff', '--name-only', '--no-renames', c1, c2).split('\n') if n)
    spec_changed = 'SPEC.md' in names
    used = set(p for sl in state.values() for s in sl for p in (s['a'][0], s['t'][0]))
    ch = names & used
    if not spec_changed and not ch: continue
    stats['pairs'] += 1
    H = {p: hunks(c1, c2, p) for p in ch}
    gone = {p for p in ch if flines(c2, p) is None}
    R2 = rows_at(c2) if spec_changed else None
    new_state = {}
    pend = []   # (sid, j, old slot, a2) 짝 없는 것
    for sid in (R2 if R2 is not None else state):
        O = state.get(sid, [])
        for s in O:
            p = s['a'][0]
            if p in gone or p not in H or not H[p]:
                s['P2'] = dict(s['P']); s['sm'] = s['m']; s['st'] = s['t']; s['st_t'] = p in gone
            else:
                P2 = {}
                for v, tf in s['P'].items():
                    sv, tt = shift(H[p], v); P2[sv] = P2.get(sv, False) or tf or tt
                s['shifted'] = set(P2)
                P2.setdefault(s['a'], False)
                s['P2'] = P2
                s['sm'] = shift(H[p], s['m'])[0]
                s['st'], s['st_t'] = shift(H[p], s['t'])
        if R2 is None:
            for s in O:
                s['P'] = s['P2']; s['m'] = s['sm']; s['t'] = s['st']; s['touched'] = s['touched'] or s['st_t']
            new_state[sid] = O
            continue
        refs = R2[sid]
        res = [None] * len(refs); usedO = [False] * len(O); ptr = 0; where = {}
        for j, a2 in enumerate(refs):
            for i in range(ptr, len(O)):
                s = O[i]
                if a2 in s['P2']:
                    usedO[i] = True; ptr = i + 1; where[j] = i
                    ns = dict(a=a2, m=s['sm'], t=s['st'], born=s['born'], born_r=s['born_r'], born_txt=s['born_txt'], touched=s['touched'] or s['st_t'], ev=s['ev'])
                    if a2 == s['a'] and a2 != s['sm']:
                        ns['P'] = s['P2']                      # 글 그대로, 밀린 채 둠
                    else:
                        ns['P'] = {a2: False}
                        if a2 == s['sm']:
                            if a2 != s['a']: stats['late'] += 1
                        else:
                            ns['ev'] = s['ev'] + [('partial', c2[:7])]; stats['partial'] += 1
                            drift_commits[c2[:7]] = drift_commits.get(c2[:7], 0) + 1
                        ns['m'] = a2
                    res[j] = ns
                    break
        bounds = sorted(where.items())
        def gap(j):
            lo = -1; hi = len(O)
            for jj, ii in bounds:
                if jj < j: lo = ii
                elif jj > j: hi = ii; break
            return lo, hi
        taken = set()
        for j in range(len(refs)):
            if res[j] is not None: continue
            a2 = refs[j]; lo, hi = gap(j)
            cand = [i for i in range(len(O)) if not usedO[i] and lo < i < hi and i not in taken and O[i]['a'][0] == a2[0]]
            if cand:
                taken.add(cand[0]); pend.append((sid, j, O[cand[0]], a2))
            else:
                res[j] = mk(a2, c2); stats['new'] += 1
        new_state[sid] = res
    # 짝 없는 것 판정: 같은 커밋·같은 파일에서 같은 만큼 옮겨진 이웃이 있으면 기계 옮김으로 본다
    deltas = {}
    for sid, j, s, a2 in pend:
        if a2[2] - a2[1] == s['a'][2] - s['a'][1]:
            deltas.setdefault((a2[0], a2[1] - s['a'][1]), []).append(1)
    for sid, j, s, a2 in pend:
        base = dict(born=s['born'], born_r=s['born_r'], born_txt=s['born_txt'])
        tch = s['st_t'] or any(s['P2'].values())
        samelen = a2[2] - a2[1] == s['a'][2] - s['a'][1]
        d = a2[1] - s['a'][1]
        if a2 == s['st']:
            ns = dict(a=a2, P={a2: False}, m=a2, t=a2, touched=s['touched'] or s['st_t'], ev=s['ev'] + [('healed', c2[:7])], **base); stats['healed'] += 1
        elif tch and s['sm'] == s['st']:
            ns = dict(a=a2, P={a2: False}, m=a2, t=a2, touched=True, ev=s['ev'] + [('adjusted', c2[:7])], **base); stats['adjusted'] += 1
        elif tch:
            ns = dict(a=a2, P={a2: False}, m=a2, t=s['st'], touched=True, ev=s['ev'] + [('approx', c2[:7])], **base); stats['approx'] += 1
        elif samelen and d != 0 and len(deltas.get((a2[0], d), [])) >= 3:
            ns = dict(a=a2, P={a2: False}, m=a2, t=s['st'], touched=s['touched'], ev=s['ev'] + [('mech?', c2[:7], d)], **base); stats['mechq'] += 1
            drift_commits[c2[:7]] = drift_commits.get(c2[:7], 0) + 1
        else:
            ns = mk(a2, c2, [('reauth', c2[:7], list(s['st']), list(s['a']))]); stats['reauth'] += 1
        new_state[sid][j] = ns
    state = new_state
head = commits[-1]
def fmt(r): return f"{r[0]}:{r[1]}" + (f"-{r[2]}" if r[2] != r[1] else '')
out = []
for sid, sl in state.items():
    for k, s in enumerate(sl):
        out.append(dict(id=sid, k=k, a=fmt(s['a']), t=fmt(s['t']), path=s['a'][0], same=(s['a'] == s['t']), pending=(s['m'] != s['a']),
                        born=s['born'][:7], born_r=[s['born_r'][1], s['born_r'][2]], born_txt=s['born_txt'],
                        a_txt=text(head, s['a']), t_txt=text(head, s['t']), touched=s['touched'], ev=s['ev']))
json.dump(dict(head=head, stats=stats, drift_commits=drift_commits, refs=out), open(A.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(stats); print('refs', len(out), '어긋남', sum(1 for x in out if not x['same']))
print('부분 옮김·짐작 옮김이 생긴 커밋(많은 순):', sorted(drift_commits.items(), key=lambda kv: -kv[1])[:20])
