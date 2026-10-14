"""handoff A/B 실험 단계 1: 실제 인계 지점을 복제 환경으로 재현해 A(NAP)·B(메모 한 줄)의 계획을 받고, 검사·집계한다.

사전 등록: stage1_rubric.md(지점·환경·실행·채점표). 계획서: td-proj next/2026-10-14/r1.md §6 단계 1
  python stage1.py plan   <출력>          실행표 runs.json(지점×조건×회차를 시드로 섞은 순서, 중립 id)
  python stage1.py verify <출력> <키>     한 지점의 A·B 환경을 만들어 차이·드리프트·원격 차단을 본다(P5·P6·P7)
  python stage1.py run    <출력> <id>     환경을 새로 만들고 claude -p 로 실행한다
  python stage1.py check  <출력>          결정적 검사, 계획 글 추출·가림, 채점 지시문
  python stage1.py tally  <출력>          채점 결과(scores/, corrections.json) 집계와 판정, 사용자 확인 목록
<출력> = 저장소 밖 원자료 폴더(C:/Users/bhy99/handoff-ab/stage1)
"""
import hashlib, json, os, random, re, shutil, stat, string, subprocess, sys, time
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
HERE = Path(__file__).resolve().parent
TD = Path('C:/Users/bhy99/td-proj')
AB = Path('C:/Users/bhy99/handoff-ab')
RAW = AB / 'raw'                                  # 대화 기록·메모리 복사본(단계 0)
WORK = Path('C:/Users/bhy99/w')                   # 실행 경로: 이름에 실험·조건이 드러나지 않게(§2의 5)
HOME = Path.home() / '.claude'
PY = 'C:/Users/bhy99/AppData/Local/Programs/Python/Python314/python.exe'
SEED = 20261014
MODEL, EFFORT = 'claude-opus-5-5', 'xhigh'
LOCS = ['2026-10-13/r1', '2026-10-13-4/r1', '2026-10-13-5/r1']
PILOT = '2026-10-13-7/r1'
# 그 시점 작업 트리에만 있던(미커밋) archive 폴더와, 그때 이미 archive로 옮겨져 작업 트리에 없던 추적 파일.
# 근거: 앞 NAP의 mark done 시각(대화 기록)과 head의 next/ 트리 대조
EXTRA = {'2026-10-13/r1': ['2026-10-12-5'], '2026-10-13-4/r1': [], '2026-10-13-5/r1': ['2026-10-13-4'],
         PILOT: ['2026-10-13-4', '2026-10-13-5', '2026-10-13-6']}
GONE = {'2026-10-13/r1': ['next/2026-10-12/r1.md']}
S92 = '92d760ff-cd34-4317-ad09-baebb01b619b'
# 그 시점 미커밋 파일: 재개 세션의 첫 편집 직전 백업(file-history @v1), 또는 그 세션이 고치지 않고 커밋한 판
DIRTY = {'2026-10-13/r1': {
    'EVAL.md': f'fh:{S92}/021cb8f57ce1f7e9@v1', 'SPEC.md': f'fh:{S92}/1104662f2f820d30@v1',
    'tests/eval/gd/sell.gd': f'fh:{S92}/a040e5df1557da89@v1', 'tests/eval/test_sell.py': f'fh:{S92}/54b0026c4019a2a4@v1',
    'tests/eval/gd/show.gd': 'git:c46621f', 'tests/eval/test_show.py': 'git:c46621f'}}
# 그 시점 뒤(10/13 08:43)에 고쳐진 메모리: 파일은 고치기 전 백업, MEMORY.md 줄은 대화 기록에 남은 그때 문구
MEM_FILE = {'2026-10-13/r1': {'steam-release-goal.md': f'fh:{S92}/f92b389f751289e4@v1'}}
MEM_LINE = {'2026-10-13/r1': {'steam-release-goal.md': '- [스팀 출시 목표](steam-release-goal.md) — 개발 11/30 완료 목표'
                                                        '(밀리면 범위 대신 일정 연장), 스팀 등록·출시 12월, WBS.md 기준'}}
# 계획 파일 경로와 resume은 파일럿에서 더했다: plan 모드가 계획 파일 이름을 작업에서 지어 A는 «resume-…»이 된다
MASK = re.compile(r'[A-Za-z]:[\\/][^\s`]*?plans[\\/][\w.\-]+|next/[\w./\-]*|NAP|작업\s?지시서|인수\s?인계|드리프트'
                  r'|handoff|resume|재개|✅|⚠️?', re.I)


def sh(args, cwd=None):
    r = subprocess.run(args, cwd=cwd, capture_output=True)
    if r.returncode:
        raise RuntimeError(f'{args} → {r.returncode}: {r.stderr.decode("utf-8", "replace")}')
    return r.stdout


def git(cwd, *a):
    return sh(['git', *a], cwd).decode('utf-8', 'replace')


def content_hash(b):
    """nap.py content_hash 와 같다: 텍스트는 CRLF→LF 로 맞춘 뒤 sha1 앞 12자."""
    if b'\0' not in b[:8192]:
        b = b.replace(b'\r\n', b'\n')
    return hashlib.sha1(b).hexdigest()[:12]


def src_bytes(src, path=None):
    kind, ref = src.split(':', 1)
    return (HOME / 'file-history' / ref).read_bytes() if kind == 'fh' else sh(['git', 'show', f'{ref}:{path}'], TD)


def rmtree(p, under):
    p = Path(p)
    assert p.resolve().is_relative_to(under.resolve()) and p.resolve() != under.resolve(), p
    shutil.rmtree(p, onexc=lambda f, q, e: (os.chmod(q, stat.S_IWRITE), f(q)))


def nap(key):
    r = next(x for x in json.load(open(AB / 'stage0' / 'naps.json', encoding='utf-8')) if x['key'] == key)
    raw = Path(r['path']).read_bytes()
    fm = dict(re.findall(r'^(\w+): ?(.*?)(?:\s+#\s.*)?$', raw.decode('utf-8').split('\n---', 1)[0], re.M))
    return r, fm, raw


def project_dir(dest):
    return HOME / 'projects' / re.sub(r'[^A-Za-z0-9]', '-', str(dest))


def build(run):
    """§2: 빈 저장소에 head와 그 시점 main만 가져오고, 미커밋 파일·next/·메모리를 그 시점 판으로 맞춘다."""
    key, cond = run['key'], run['cond']
    r, fm, raw = nap(key)
    base = WORK / run['id']
    if base.exists():
        rmtree(base, WORK)
    dest = base / 'td-proj'
    dest.mkdir(parents=True)
    head = git(TD, 'rev-parse', fm['head']).strip()
    main = git(TD, 'rev-list', '--first-parent', '-1', f'--before={r["created"]}', 'origin/main').strip()
    git(dest, 'init', '-q', '-b', 'init')
    git(dest, 'fetch', '-q', '--no-tags', str(TD), f'{head}:refs/heads/{fm["branch"]}', f'{main}:refs/heads/main')
    git(dest, 'checkout', '-q', fm['branch'])
    with open(dest / '.git' / 'info' / 'exclude', 'a', encoding='utf-8') as f:
        f.write('/next/**/.*.files\n')
    for p, src in DIRTY.get(key, {}).items():
        (dest / p).write_bytes(src_bytes(src, p))
    manifest = Path(r['path']).with_name(f'.{Path(r["path"]).stem}.files')
    want = dict(l.split('  ', 1)[::-1] for l in manifest.read_text('utf-8').splitlines()[2:] if '  ' in l)
    got = {p: content_hash((dest / p).read_bytes()) for p in want}
    assert got == want, f'미커밋 파일이 NAP 해시 기록과 다르다: {got} != {want}'
    if cond == 'A':
        for p in GONE.get(key, []):
            (dest / p).unlink()
        for name in EXTRA[key]:
            shutil.copytree(TD / 'next' / 'archive' / name, dest / 'next' / 'archive' / name)
        target = dest / 'next' / r['created'][:10] / Path(r['path']).name   # 그 시점 경로
        target.parent.mkdir(parents=True, exist_ok=True)
        text = re.sub(rb'^status: \w+', b'status: active', raw, count=1, flags=re.M)
        target.write_bytes(re.sub(rb'^resumed: .*\r?\n', b'', text, count=1, flags=re.M))
        shutil.copy(manifest, target.parent / manifest.name)
    else:
        tracked = [t for t in git(dest, 'ls-files', '-z', 'next').split('\0') if t]
        git(dest, 'update-index', '--skip-worktree', *tracked)
        rmtree(dest / 'next', dest)
    mdir = project_dir(dest) / 'memory'
    if mdir.parent.exists():
        rmtree(mdir.parent, HOME / 'projects')
    mdir.mkdir(parents=True)
    for name in r['memory']:
        if name != 'MEMORY.md':
            src = MEM_FILE.get(key, {}).get(name)
            (mdir / name).write_bytes(src_bytes(src) if src else (RAW / 'memory' / name).read_bytes())
    lines = [MEM_LINE.get(key, {}).get(m.group(1), l) for l in (RAW / 'memory' / 'MEMORY.md').read_text('utf-8').splitlines()
             if (m := re.search(r'\]\(([^)]+\.md)\)', l)) and m.group(1) in r['memory']]
    (mdir / 'MEMORY.md').write_text('\n'.join(lines) + '\n', 'utf-8')
    return dest


def state(dest):
    """next/ 밖 작업 트리 상태(편집 검사용)와 next/ 상태(스킬 상태 변경은 따로 적는다)."""
    out = lambda *a: git(dest, *a)
    return dict(head=out('rev-parse', 'HEAD').strip(), branch=out('branch', '--show-current').strip(),
                status=out('status', '--porcelain=v1', '-uall', '--', '.', ':(exclude)next'),
                diff=hashlib.sha1(sh(['git', 'diff', 'HEAD', '--', '.', ':(exclude)next'], dest)).hexdigest()[:12],
                next=out('status', '--porcelain=v1', '-uall', '--', 'next'))


def guard_files(rid):
    """격리 훅을 실행 경로 쪽 중립 위치에 둔다. 훅이 막으면 모델이 훅 명령줄을 보므로, 실험 자료 경로가 드러나지 않게 한다."""
    g = WORK / '_hook'
    g.mkdir(parents=True, exist_ok=True)
    code = (HERE / 'stage1_guard.py').read_text('utf-8')     # 설명 글은 빼고 둔다(파일럿에서 모델이 훅 파일을 읽었다)
    code = re.sub(r'^#.*\n', '', re.sub(r'\A""".*?"""\n', '', code, flags=re.S), flags=re.M)
    (g / 'hook.py').write_text(code, 'utf-8')
    log = g / f'{rid}.jsonl'
    log.unlink(missing_ok=True)
    hook = dict(type='command', command=PY, args=['-I', str(g / 'hook.py'), str(log)])
    (g / f'{rid}.json').write_text(json.dumps(dict(hooks=dict(PreToolUse=[dict(matcher='*', hooks=[hook])]))), 'utf-8')
    return g / f'{rid}.json', log


def keep_plan_files(rd):
    """plan 모드가 ~/.claude/plans/ 에 쓴 계획 파일을 실행 폴더로 옮긴다. 실행이 만든 파일이라 원래 자리에서는 지운다."""
    seen = []
    for line in open(rd / 'stream.jsonl', encoding='utf-8'):
        e = json.loads(line)
        for b in (e.get('message') or {}).get('content') or [] if e.get('type') == 'assistant' else []:
            p = (b.get('input') or {}).get('file_path', '') if b.get('type') == 'tool_use' else ''
            if re.search(r'\.claude[\\/]plans[\\/]', p) and p not in seen:
                seen.append(p)
    for n, p in enumerate(seen):
        if Path(p).exists():
            shutil.move(p, rd / f'planfile{n}.md')


def runs_of(out):
    t = json.load(open(Path(out) / 'runs.json', encoding='utf-8'))
    return t['runs'] + t['pilot']


def plan(out):
    rng = random.Random(SEED)
    runs = [dict(key=k, cond=c, rep=n) for k in LOCS for c in 'AB' for n in (1, 2)]
    rng.shuffle(runs)
    pilot = [dict(key=PILOT, cond=c, rep=0) for c in 'AB']
    ids = set()
    for r in runs + pilot:
        while (i := ''.join(rng.choice(string.ascii_lowercase + string.digits) for _ in range(4))) in ids:
            pass
        ids.add(i)
        r['id'] = i
    Path(out).mkdir(parents=True, exist_ok=True)
    json.dump(dict(runs=runs, pilot=pilot), open(Path(out) / 'runs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for r in runs + pilot:
        print(r['id'], r['key'], r['cond'], r['rep'])


def verify(out, key):
    """P5·P6·P7: A·B 환경의 작업 트리 차이는 next/뿐, A 드리프트 CLEAN, 원격 없음(push 실패), 메모리 위치."""
    dests = {c: build(dict(key=key, cond=c, id=f'verify-{c}')) for c in 'AB'}
    cmp = subprocess.run(['diff', '-rq', '-x', '.git', '-x', 'next', str(dests['A']), str(dests['B'])], capture_output=True)
    print('A·B 차이(next/·.git 밖):', cmp.stdout.decode('utf-8', 'replace').strip() or '없음')
    for c, d in dests.items():
        s = state(d)
        print(f'{c}: {s["branch"]} @ {s["head"][:7]} · 상태\n{s["status"]}{s["next"]}'.rstrip())
        print(f'{c}: 메모리', sorted(os.listdir(project_dir(d) / 'memory')))
    dr = subprocess.run(['sh', str(HOME / 'skills' / 'handoff' / 'scripts' / 'nap.sh'), 'drift', '--root', str(dests['A'])],
                        capture_output=True)
    print('A 드리프트:', dr.stdout.decode('utf-8', 'replace').strip())
    push = subprocess.run(['git', 'push'], cwd=dests['B'], capture_output=True)
    print('B git push:', push.returncode, push.stderr.decode('utf-8', 'replace').strip()[:120])
    print('B 원격:', git(dests['B'], 'remote', '-v').strip() or '없음')


def run(out, rid):
    r = next(x for x in runs_of(out) if x['id'] == rid)
    memo = nap(r['key'])[0]['memo']
    dest = build(r)
    rd = Path(out) / 'runs' / rid
    if rd.exists():
        shutil.move(rd, rd.with_name(f'{rid}.prev{int(time.time())}'))
    rd.mkdir(parents=True)
    prompt = '/handoff resume' if r['cond'] == 'A' else f'다음 작업: {memo}. 진행해.'
    deny = ['AskUserQuestion', 'Bash(git push:*)', 'Bash(gh:*)'] + (['Skill(handoff)'] if r['cond'] == 'B' else [])
    settings, guard = guard_files(rid)
    cmd = [shutil.which('claude'), '-p', prompt, '--model', MODEL, '--effort', EFFORT, '--permission-mode', 'plan',
           '--permission-prompts', 'none', '--disallowedTools', *deny, '--settings', str(settings),
           '--output-format', 'stream-json', '--verbose']
    env = {k: v for k, v in os.environ.items() if not k.startswith(('CLAUDE', 'AI_AGENT'))}
    before, t0 = state(dest), time.time()
    with open(rd / 'stream.jsonl', 'wb') as so, open(rd / 'stderr.txt', 'wb') as se:
        p = subprocess.run(cmd, cwd=dest, stdout=so, stderr=se, env=env)
    meta = dict(run=r, prompt=prompt, cmd=cmd[1:], rc=p.returncode, secs=round(time.time() - t0), dest=str(dest),
                before=before, after=state(dest))
    if guard.exists():
        shutil.move(guard, rd / 'guard.jsonl')
    keep_plan_files(rd)
    for line in open(rd / 'stream.jsonl', encoding='utf-8'):
        e = json.loads(line)
        if e.get('type') == 'system' and e.get('session_id'):
            meta['session'] = e['session_id']
            src = project_dir(dest) / f'{e["session_id"]}.jsonl'
            if src.exists():
                shutil.copy(src, rd / 'session.jsonl')
            break
    json.dump(meta, open(rd / 'meta.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(rid, r['key'], r['cond'], 'rc', p.returncode, f'{meta["secs"]}s')


def parse(rd):
    """stream-json → 계획 글·도구 호출·거부·사용량.

    계획 글 = 첫 Stop 훅 피드백 전(훅이 없으면 끝까지)의 응답 글 가운데 마지막 도구 호출 뒤의 것. 그 뒤는 훅에 대한 답이다.
    마지막 도구 호출 뒤 글이 300자 미만이면(계획 뒤에 도구를 더 부른 경우) 그 전 글 중 가장 긴 것을 쓴다.
    -p 의 plan 모드에는 ExitPlanMode가 없다(파일럿 확인). 있으면 그 plan도 붙인다.
    """
    texts, cut, exit_plan, tools, res, seen, out_tok, init, hooked = [], None, '', [], {}, set(), 0, {}, 0
    for line in open(rd / 'stream.jsonl', encoding='utf-8'):
        e = json.loads(line)
        if e.get('type') == 'system' and e.get('subtype') == 'init':
            init = e
        elif e.get('type') == 'assistant':
            m = e['message']
            if m.get('id') not in seen:
                seen.add(m.get('id'))
                out_tok += (m.get('usage') or {}).get('output_tokens', 0)
            for b in m['content']:
                if b.get('type') == 'tool_use':
                    tools.append((b['name'], b['input']))
                    if cut is None:
                        texts.append(None)            # 도구 호출 자리 표시
                    if b['name'] == 'ExitPlanMode':
                        exit_plan = b['input'].get('plan', '')
                elif b.get('type') == 'text' and b['text'].strip() and cut is None:
                    texts.append(b['text'])
        elif e.get('type') == 'user':
            c = e['message']['content']
            if any(t.startswith('Stop hook feedback') for t in
                   ([c] if isinstance(c, str) else [b.get('text', '') for b in c if b.get('type') == 'text'])):
                hooked += 1
                cut = cut if cut is not None else len(texts)
        elif e.get('type') == 'result':
            res = e
    tail = []
    for t in reversed(texts):
        if t is None:
            break
        tail.insert(0, t)
    plan_txt = '\n\n'.join(tail)
    if len(plan_txt) < 300:
        plan_txt = max((t for t in texts if t), key=len, default=plan_txt)
    plan_txt = (exit_plan + '\n\n' + plan_txt).strip() if exit_plan else plan_txt
    return dict(plan=plan_txt, final=res.get('result') or '', tools=tools, result=res, requests=len(seen),
                out=out_tok, init=init, hooked=hooked)


def rubric():
    """stage1_rubric.md §5 → {키: (상황, [(ID, 항목, 출처)])}, 공통 기준 글."""
    t = (HERE / 'stage1_rubric.md').read_text('utf-8')
    sec = t[t.index('## 5. 채점표'):t.index('## 6. 채점과 판정')]
    common = sec[sec.index('항목마다'):sec.index('정답의 출처는')].strip()
    locs = {}
    for blk in re.split(r'^### ', sec, flags=re.M)[1:]:
        m = re.match(r'`([^`]+)`', blk)
        if not m:
            continue
        sit = re.search(r'^상황: (.*)$', blk, re.M).group(1)
        items = re.findall(r'^\| (g\d-\d) \| (.*?) \| (.*?) \|$', blk, re.M)
        locs[m.group(1)] = (sit, items)
    return locs, common


JUDGE = """handoff 실험 단계 1의 채점이다. 너는 어떤 조건에서 나온 계획인지 모른다. 아래 채점표만으로 판정한다.

## 할 일
계획 글 `{plan}`을 읽고, 아래 항목마다 충족(1) 또는 불충족(0)을 정해 `{score}`에 JSON으로 쓴다.
«[가림]»은 채점과 무관한 표지를 가린 자리다. 계획 글 밖의 파일(저장소 등)은 읽지 않는다.

## 그 시점 상황
{sit}

## 판정 기준
{common}

## 채점표
| ID | 항목 | 출처(정답의 근거, 계획 글에는 없을 수 있다) |
|---|---|---|
{rows}

## 출력
`{score}` 한 파일만 쓴다:
{{"id": "{rid}", "items": {{"<ID>": {{"v": 0 또는 1, "quote": "<판정 근거가 된 계획 글 인용 80자 이내, 없으면 빈 문자열>", "why": "<한 줄>"}}, ...}}}}
항목 {n}개를 모두 넣는다. 끝나면 `{rid}: 충족 x/{n}` 한 줄로만 답한다."""


def check(out):
    locs, common = rubric()
    rows = []
    for r in runs_of(out):
        rd = Path(out) / 'runs' / r['id']
        if not (rd / 'meta.json').exists():
            continue
        meta, p = json.load(open(rd / 'meta.json', encoding='utf-8')), parse(rd)
        g = rd / 'guard.jsonl'
        edits = (meta['before']['status'], meta['before']['diff']) != (meta['after']['status'], meta['after']['diff'])
        skills = [i.get('skill') for n, i in p['tools'] if n == 'Skill']
        res = p['result']
        row = dict(id=r['id'], key=r['key'], cond=r['cond'], rep=r['rep'], rc=meta['rc'], secs=meta['secs'],
                   done=res.get('subtype') == 'success', plan_len=len(p['plan']), final_len=len(p['final']),
                   edits=edits, next_changed=meta['before']['next'] != meta['after']['next'], skills=skills,
                   guard=len(g.read_text('utf-8').splitlines()) if g.exists() else 0,
                   denials=[d.get('tool_name') for d in res.get('permission_denials', [])],
                   requests=p['requests'], out=(res.get('usage') or {}).get('output_tokens'), turns=res.get('num_turns'),
                   hooked=p['hooked'],
                   tools=len(p['tools']), cost=res.get('total_cost_usd'))
        rows.append(row)
        files = [f.read_text('utf-8') for f in sorted(rd.glob('planfile*.md'))]   # plan 모드 계획 파일(파일럿 확인)
        text = '\n\n'.join([p['plan']] + [f'## 계획 파일\n\n{f}' for f in files]).strip()
        row['plan_len'] = len(text)
        (rd / 'plan.md').write_text(text, 'utf-8')
        if r['key'] in locs:
            jd = Path(out) / 'judge'
            jd.mkdir(exist_ok=True)
            (jd / f'{r["id"]}.md').write_text(MASK.sub('[가림]', text), 'utf-8')
            sit, items = locs[r['key']]
            (jd / f'{r["id"]}.prompt.txt').write_text(JUDGE.format(
                plan=(jd / f'{r["id"]}.md').as_posix(), score=(Path(out) / 'scores' / f'{r["id"]}.json').as_posix(),
                sit=sit, common=common, rid=r['id'], n=len(items),
                rows='\n'.join(f'| {i} | {t} | {s} |' for i, t, s in items)), 'utf-8')
    json.dump(rows, open(Path(out) / 'checks.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for x in rows:
        print(' '.join(f'{k}={x[k]}' for k in ('id', 'key', 'cond', 'rep', 'rc', 'done', 'edits', 'next_changed',
                                                 'skills', 'guard', 'denials', 'requests', 'out', 'secs', 'plan_len', 'final_len')))


EXT = ('2026-10-13/r1', 'g3-1')                   # 판정 밖, 따로 보고(§6의 5)


def tally(out):
    locs, _ = rubric()
    runs = json.load(open(Path(out) / 'runs.json', encoding='utf-8'))['runs']
    fix = json.load(open(Path(out) / 'corrections.json', encoding='utf-8')) if (Path(out) / 'corrections.json').exists() else {}
    v = {}                                        # (id, item) → 0/1 (사용자 고침 우선)
    for r in runs:
        f = Path(out) / 'scores' / f'{r["id"]}.json'
        if f.exists():
            for i, x in json.load(open(f, encoding='utf-8'))['items'].items():
                v[(r['id'], i)] = fix.get(f'{r["id"]}:{i}', x['v'])
    by = {}
    for r in runs:
        items = [i for i, _, _ in locs[r['key']][1] if (r['key'], i) != EXT]
        if all((r['id'], i) in v for i in items):
            by.setdefault((r['key'], r['cond']), []).append(sum(v[(r['id'], i)] for i in items) / len(items))
    print('| 지점 | A | B | A−B |\n|---|---|---|---|')
    diffs = []
    for k in LOCS:
        a, b = by.get((k, 'A')), by.get((k, 'B'))
        if a and b:
            diffs.append(sum(a) / len(a) - sum(b) / len(b))
            print(f'| {k} | {" · ".join(f"{x:.2f}" for x in a)} | {" · ".join(f"{x:.2f}" for x in b)} | {diffs[-1]:+.2f} |')
    if len(diffs) == len(LOCS):
        d = sum(diffs) / len(diffs)
        print(f'\nA−B = {d:+.3f} → ' + ('효과 있음' if d >= 0.25 else 'G1 «경계 인계에서 무용»' if d <= 0.10 else '쓸모없음(사이, 입증 책임)'))
    harm = []
    for k, (_, items) in locs.items():
        for i, _, _ in items:
            if i.startswith('g5'):
                va = [v.get((r['id'], i)) for r in runs if r['key'] == k and r['cond'] == 'A']
                vb = [v.get((r['id'], i)) for r in runs if r['key'] == k and r['cond'] == 'B']
                if 0 in va and 0 not in vb:
                    harm.append(k)
    print(f'해로움(g5를 A만 어긴 지점): {harm or "없음"} → ' + ('해로움' if len(harm) >= 2 else '해로움 아님'))
    ext = {c: sum(v.get((r['id'], EXT[1]), 0) for r in runs if r['key'] == EXT[0] and r['cond'] == c) for c in 'AB'}
    print(f'g3-확장({EXT[0]} {EXT[1]}): A {ext["A"]}/2, B {ext["B"]}/2 → '
          + ('단계 2에서 S1을 빼지 않는다' if ext['A'] > ext['B'] else 'S1 보호 조건 아님'))
    # 사용자 확인 목록(§6의 2): 갈린 항목 전부 + 무작위 20%
    key_of = {r['id']: r['key'] for r in runs}
    hits = lambda k, i, c: sum(v.get((r['id'], i), 0) for r in runs if r['key'] == k and r['cond'] == c)
    split = {(k, i) for k, (_, items) in locs.items() for i, _, _ in items if hits(k, i, 'A') != hits(k, i, 'B')}
    allv = sorted(v)
    sample = random.Random(SEED).sample(allv, round(len(allv) * 0.2)) if allv else []
    review = sorted({(rid, i) for rid, i in allv if (key_of[rid], i) in split} | set(sample))
    json.dump([f'{rid}:{i}' for rid, i in review], open(Path(out) / 'review.json', 'w', encoding='utf-8'), indent=1)
    print(f'사용자 확인: 갈린 항목 {len(split)}개(지점·항목), 표본 {len(sample)}개 → 판정 {len(review)}개(review.json)')


if __name__ == '__main__':
    cmd, out, *rest = sys.argv[1:]
    {'plan': lambda: plan(out), 'verify': lambda: verify(out, rest[0]), 'run': lambda: run(out, rest[0]),
     'check': lambda: check(out), 'tally': lambda: tally(out)}[cmd]()
