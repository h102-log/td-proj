# 지정한 §3.1 행들의 참조마다 첫 줄·끝 줄 글을 찍는다. 인자: 문장 번호들
import sys, re
L = open('SPEC.md', encoding='utf-8').read().split('\n')
cache = {}
def lines(p):
    if p not in cache: cache[p] = open(p, encoding='utf-8', errors='replace').read().split('\n')
    return cache[p]
for sid in sys.argv[1:]:
    row = next(l for l in L if l.startswith(f'| {sid} |'))
    print(f'## {sid}')
    for m in re.finditer(r'([①-⑳])|([A-Za-z0-9_./\-]+\.[A-Za-z0-9]+):(\d+)(?:-(\d+))?', row):
        if m.group(1): print(' ', m.group(1)); continue
        p, a, b = m.group(2), int(m.group(3)), int(m.group(4) or m.group(3))
        f = lines(p)
        s = f[a-1].strip()[:110]
        e = ('  …  ' + f[b-1].strip()[:70]) if b != a else ''
        print(f'   {p.split("/")[-1]}:{a}' + (f'-{b}' if b != a else '') + f'  | {s}{e}')
