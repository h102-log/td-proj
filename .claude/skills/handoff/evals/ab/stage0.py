"""handoff A/B 실험 단계 0: 대화 기록·NAP에서 감사 재료를 만들고 분류 결과를 집계한다.

계획서: td-proj next/2026-10-14/r1.md §6 단계 0
  python stage0.py costs <원자료>                    §2 비용 수치를 다시 낸다
  python stage0.py prep    <원자료> <td-proj> <출력>   NAP 대응표·항목·대화 발췌를 만든다
  python stage0.py prompts <원자료> <td-proj> <출력>   분류 에이전트 지시문을 만든다
  python stage0.py tally   <출력>                       분류 결과 집계와 관문 G0
<원자료> = ~/.claude/projects/C--Users-bhy99-td-proj 의 복사본
"""
import glob, json, os, random, re, statistics as st, sys
from datetime import datetime, timedelta, timezone

sys.stdout.reconfigure(encoding='utf-8')
KST = timezone(timedelta(hours=9))
# 모델이 Skill 인자를 길게 지어 넣은 NAP는 사용자 발화 기준으로 바꾼다(a7889ffd 17:07 사용자 «2번은 handoff로 다음 새션에서 정하자»)
MEMO = {'2026-10-13-6/r1': '3.7(10/18) 전에 정할 것들 결정'}
RESUMED = re.compile(r'nap\.sh"?\s+mark resumed')
CHECK = re.compile(r'nap\.sh"?\s+check')


def ts(s):
    return datetime.fromisoformat(s.replace('Z', '+00:00'))


def kst(s):
    return ts(s).astimezone(KST).strftime('%m-%d %H:%M')


def text_of(c):
    if isinstance(c, str):
        return c
    return ' '.join(b.get('text', '') for b in c if isinstance(b, dict) and b.get('type') == 'text')


def load(path):
    """사람 발화·handoff 호출·도구·응답 글·질문 답·사용량을 시간순 이벤트로 (assistant 메시지 id 중복 제거)."""
    ev, seen, asks = [], set(), set()
    for line in open(path, encoding='utf-8'):
        d = json.loads(line)
        ty, t = d.get('type'), d.get('timestamp')
        if ty == 'user' and not d.get('isMeta'):
            c = d['message']['content']
            if isinstance(c, list) and any(b.get('type') == 'tool_result' for b in c):
                for b in c:
                    if b.get('tool_use_id') in asks:
                        ev.append(dict(k='answer', ts=t, s=text_of(b.get('content', ''))))
                continue
            s = text_of(c)
            m = re.search(r'<command-name>(/[^<]+)</command-name>', s)
            if m:                                      # 인자가 없으면 <command-args> 태그도 없다
                a = re.search(r'<command-args>(.*?)</command-args>', s, re.S)
                s = f'{m.group(1)} {a.group(1) if a else ""}'.strip()
            elif not s.strip() or s.startswith('<') or s.startswith('This session is being continued'):
                continue
            ev.append(dict(k='human', ts=t, s=s))
            if s.startswith('/handoff'):
                ev.append(dict(k='handoff', ts=t, args=s[len('/handoff'):].strip()))
        elif ty == 'assistant':
            m = d['message']
            first = m.get('id') not in seen
            seen.add(m.get('id'))
            for b in m['content']:
                if b.get('type') == 'tool_use':
                    i = b['input']
                    if b['name'] == 'Skill' and i.get('skill') == 'handoff':
                        ev.append(dict(k='handoff', ts=t, args=str(i.get('args', ''))))
                    if b['name'] == 'AskUserQuestion':
                        asks.add(b['id'])
                    ev.append(dict(k='tool', ts=t, name=b['name'], inp=i))
                elif b.get('type') == 'text' and b['text'].strip():
                    ev.append(dict(k='text', ts=t, s=b['text']))
            if first:
                u = m.get('usage') or {}
                ev.append(dict(k='usage', ts=t, out=u.get('output_tokens', 0),
                               ctx=u.get('input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
                               + u.get('cache_read_input_tokens', 0)))
    return ev


def is_resume(e):
    return e['k'] == 'handoff' and e['args'].startswith(('resume', '재개'))


def is_write(e):
    return e['k'] == 'handoff' and not is_resume(e)


def is_work(e):
    """재개 뒤 '작업 시작' = mark resumed 또는 next/·.claude 밖 파일의 첫 편집."""
    if e['k'] != 'tool':
        return False
    if e['name'] == 'Bash':
        return bool(RESUMED.search(e['inp'].get('command', '')))
    p = e['inp'].get('file_path', '').replace('\\', '/') if e['name'] in ('Edit', 'Write') else ''
    return bool(p) and '/next/' not in p and '/.claude/' not in p


def phase(ev, i0, i1):
    seg = ev[i0 + 1:i1]
    us = [e for e in seg if e['k'] == 'usage']
    return dict(tools=sum(e['k'] == 'tool' for e in seg), out=sum(e['out'] for e in us),
                grow=(us[-1]['ctx'] - us[0]['ctx']) if us else 0)


def sessions(raw):
    for f in sorted(glob.glob(os.path.join(raw, '*.jsonl'))):
        yield os.path.basename(f)[:-6], load(f)


def costs(raw):
    writes, resumes, units = [], [], []
    for sid, ev in sessions(raw):
        anchors = [i for i, e in enumerate(ev) if e['k'] == 'handoff']
        for n, i0 in enumerate(anchors):
            i_next = anchors[n + 1] if n + 1 < len(anchors) else len(ev)
            if is_resume(ev[i0]):
                iw = next((i for i in range(i0, i_next) if is_work(ev[i])), None)
                if iw is not None:
                    resumes.append(phase(ev, i0, iw))
                    us = [e for e in ev if e['k'] == 'usage']
                    units.append((len(us), sum(e['out'] for e in us)))
            else:
                nh = next((i for i in range(i0 + 1, len(ev)) if ev[i]['k'] == 'human'), len(ev))
                checks = [i for i in range(i0, i_next) if ev[i]['k'] == 'tool' and ev[i]['name'] == 'Bash'
                          and CHECK.search(ev[i]['inp'].get('command', ''))]
                w = phase(ev, i0, max(checks[-1] + 1, nh) if checks else nh)
                if w['tools']:                         # 도구 0회 = 잘못 누르고 바로 중단한 호출(aec2f8b1 14:45)
                    writes.append(w)
    med = lambda xs: f'{st.median(xs):,.0f} ({min(xs):,}~{max(xs):,})'
    for name, rows in (('작성', writes), ('재개 → 작업 시작', resumes)):
        print(f'{name} n={len(rows)}: 도구 {med([r["tools"] for r in rows])} · 출력 {med([r["out"] for r in rows])}'
              f' · 컨텍스트 증가 {med([r["grow"] for r in rows])}')
    print(f'재개 세션 전체 n={len(units)}: 요청 {med([u[0] for u in units])} · 출력 {med([u[1] for u in units])}')


def nap_files(repo):
    for p in sorted(glob.glob(os.path.join(repo, 'next', 'archive', '*', 'r*.md'))):
        t = open(p, encoding='utf-8').read()
        m = re.match(r'---\n(.*?)\n---\n', t, re.S)
        if not m:
            continue                                   # 스킬 이전에 손으로 쓴 지시서(r1~r3)
        fm = dict(re.findall(r'^(\w+): ?(.*?)(?:\s+#\s.*)?$', m.group(1), re.M))
        key = os.path.relpath(p, os.path.join(repo, 'next', 'archive')).replace('\\', '/')[:-3]
        yield key, p, fm, t[m.end():]


def split_items(body):
    """본문을 항목(불릿·번호·표 데이터 행) 단위로. 이어지는 들여쓴 줄은 앞 항목에 붙인다."""
    lines, out, sec = body.splitlines(), [], ''
    for n, line in enumerate(lines):
        s = line.strip()
        if line.startswith('## '):
            sec = line[3:].strip()
            continue
        if not s or line.startswith('# ') or re.fullmatch(r'\|[\s\-:|]+\|', s):
            continue
        if s.startswith('|') and n + 1 < len(lines) and re.fullmatch(r'\|[\s\-:|]+\|', lines[n + 1].strip()):
            continue                                   # 표 머리글 행
        if re.match(r'(- |\* |\d+\. |\|)', s):
            out.append(dict(id=len(out) + 1, sec=sec, text=s))
        elif out:
            out[-1]['text'] += ' ' + s
    return out


def summ(name, i):
    if name == 'Bash':
        return i.get('command', '').replace('\n', ' ⏎ ')[:240]
    if name in ('Read', 'Edit', 'Write'):
        return i.get('file_path', '')
    if name == 'Grep':
        return f"{i.get('pattern', '')} @ {i.get('path', '')}"
    if name == 'Skill':
        return f"{i.get('skill')} {str(i.get('args', ''))[:200]}"
    if name == 'AskUserQuestion':
        return json.dumps(i.get('questions', ''), ensure_ascii=False)[:800]
    if name == 'ExitPlanMode':
        return i.get('plan', '')[:2000]
    if name == 'Agent':
        return i.get('description', '')
    return json.dumps(i, ensure_ascii=False)[:160]


def excerpt(ev, i0, i1, people_only=False):
    out = []
    for e in ev[i0:i1]:
        if e['k'] == 'human':
            out.append(f'[{kst(e["ts"])}] 사용자: {e["s"][:3000]}')
        elif e['k'] == 'answer':
            out.append(f'[{kst(e["ts"])}] 사용자(질문 답): {e["s"][:1500]}')
        elif people_only:
            continue
        elif e['k'] == 'text':
            out.append(f'[{kst(e["ts"])}] Claude: {e["s"][:1500]}')
        elif e['k'] == 'tool':
            out.append(f'[{kst(e["ts"])}] 도구 {e["name"]}: {summ(e["name"], e["inp"])}')
    return '\n'.join(out)


def memory_born(raw):
    """메모리 파일마다 대화 기록에서 처음 쓰인 시각. 기록에 없으면 None(분석 기간 전부터 있었음).
    Bash로 쓴 경우(echo >>, sed -i)도 있어 Bash 명령에 파일 이름이 나온 시각도 본다. 파일 생성 시각은 sed -i가 새로 만들어 믿을 수 없다."""
    names = [os.path.basename(p) for p in glob.glob(os.path.join(raw, 'memory', '*.md'))]
    born = {}
    for sid, ev in sessions(raw):
        for e in ev:
            if e['k'] != 'tool':
                continue
            if e['name'] in ('Write', 'Edit'):
                hits = [n for n in names if e['inp'].get('file_path', '').replace('\\', '/').endswith('/memory/' + n)]
            elif e['name'] == 'Bash':
                c = e['inp'].get('command', '')
                hits = [n for n in names if 'memory' in c and n in c and re.search(r'>|tee |sed -i|cp |mv ', c)]
            else:
                continue
            for n in hits:
                born[n] = min(born.get(n, e['ts']), e['ts'])
    return {n: born.get(n) for n in names}


def prep(raw, repo, out):
    evs = dict(sessions(raw))
    born = memory_born(raw)
    naps = sorted(nap_files(repo), key=lambda x: x[2]['created'])
    for d in ('items', 'excerpts'):
        os.makedirs(os.path.join(out, d), exist_ok=True)
    table, prev = [], None
    for key, path, fm, body in naps:
        created = datetime.fromisoformat(fm['created'])
        writer = fm['session']
        wev = evs[writer]
        iw = max(i for i, e in enumerate(wev) if is_write(e) and ts(e['ts']) <= created + timedelta(minutes=5))
        # 재개 세션 = 작성 시각 뒤 처음으로 mark resumed 를 실행한 세션
        cands = [(ts(e['ts']), sid) for sid, ev in evs.items() for e in ev
                 if e['k'] == 'tool' and e['name'] == 'Bash' and RESUMED.search(e['inp'].get('command', ''))
                 and ts(e['ts']) > created]
        resume = min(cands)[1] if cands else None
        fk = key.replace('/', '_')
        items = split_items(body)
        json.dump(items, open(os.path.join(out, 'items', fk + '.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        open(os.path.join(out, 'excerpts', fk + '_prior.txt'), 'w', encoding='utf-8').write(excerpt(wev, 0, iw + 1, people_only=True))
        if resume:
            rev = evs[resume]
            i0 = next(i for i, e in enumerate(rev) if is_resume(e))
            i1 = next((i for i in range(i0 + 1, len(rev)) if is_write(rev[i])), len(rev))
            open(os.path.join(out, 'excerpts', fk + '_next.txt'), 'w', encoding='utf-8').write(excerpt(rev, i0, i1))
        mem = sorted(n for n, b in born.items() if b is None or ts(b) < created)
        table.append(dict(key=key, path=path, created=fm['created'], head=fm['head'], dirty=fm['dirty'],
                          reason=fm['reason'], title=fm['title'], memo=MEMO.get(key, wev[iw]['args']), writer=writer,
                          resume=resume, prev=prev, memory=mem, items=len(items)))
        prev = key
    json.dump(table, open(os.path.join(out, 'naps.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for r in table:
        print(f"{r['key']:16} {r['created'][5:16]} head {r['head']} 항목 {r['items']:3} 작성 {r['writer'][:8]} "
              f"재개 {(r['resume'] or '-')[:8]} 메모리 {len(r['memory'])} 메모 {r['memo'][:30]!r}")


PROMPT = """handoff 스킬 실험의 단계 0 분류 작업이다. 맥락은 아래 파일에만 있다.

## 할 일
NAP `{key}`의 항목 {n}개를 분류 기준대로 분류하고, 결과 JSON을 파일 하나로 쓴다.

## 읽을 것 (순서대로)
1. 분류 기준(먼저 끝까지 읽는다): {rubric}
2. 항목 목록: {out}/items/{fk}.json
3. NAP 원문: {path}
4. 다음 세션 기록 발췌(used·wrong 판정용): {out}/excerpts/{fk}_next.txt
5. 앞 세션의 사용자 발화(항목 출처 확인용): {out}/excerpts/{fk}_prior.txt
6. 바로 앞 NAP(carried 판정용): {prev}

## 기준 정보
- 저장소: {repo}. 기준 커밋은 `{head}`이고, NAP는 {created} KST에 썼다.
- 사용자 메모(`/handoff` 인자): `{memo}`
- 그 시점 메모리 파일(폴더 {raw}/memory/): {memory}. 내용은 지금 판이라 그 뒤 수정이 섞였을 수 있다.
- 저장소는 기준 커밋으로만 조회한다(Git Bash):
  - `git -C {repo} grep -n -e '<패턴>' {head} -- . ':(exclude)next'`
  - `git -C {repo} show {head}:<경로>`
  - `git -C {repo} log --oneline -15 {head}`
  - 파일 바이트(CRLF 등)는 `git -C {repo} show {head}:<경로> | od -c | head` 로 본다. 이 PC의 grep은 CR을 못 잡는다.
- 파일 전체를 출력하지 않는다. `git grep -n`이나 `git show {head}:<경로> | sed -n '<시작>,<끝>p'`로 필요한 줄만 본다(비용 때문이다).

## 지킬 것
- 저장소와 다른 파일은 읽기만 한다. checkout·switch·stash·편집은 하지 않는다. 쓰는 파일은 출력 파일 하나뿐이다.
- R·M에는 근거(경로:줄·커밋·문서 경로·메모리 파일)를 반드시 적는다. 관련 자료만 있고 핵심 정보 자체가 없으면 N이다. N에는 origin(사실/생성)을 붙인다.
- 출력 파일: {out}/class/{fk}.json (JSON 배열, 항목 {n}개, id 순서 그대로)
- 끝나면 아래 두 줄로만 답한다.
  1. `R a / M b / G c / N d (사실 e·생성 f) / N사실∧U g / N생성∧U h / wrong i / wrong∧U j / carried k`
  2. 판단이 가장 어려웠던 항목 번호 3개와 각각 한 줄 이유"""


def prompts(raw, repo, out):
    """분류 에이전트 지시문을 NAP마다 prompts/<키>.txt로 쓴다(모든 NAP가 같은 틀)."""
    os.makedirs(os.path.join(out, 'prompts'), exist_ok=True)
    rubric = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'stage0_rubric.md').replace('\\', '/')
    for r in json.load(open(os.path.join(out, 'naps.json'), encoding='utf-8')):
        fk = r['key'].replace('/', '_')
        prev = (f"{repo}/next/archive/{r['prev']}.md" if r['prev'] else '없음(첫 NAP). carried는 모두 false')
        text = PROMPT.format(key=r['key'], n=r['items'], rubric=rubric, out=out, fk=fk, path=r['path'].replace('\\', '/'),
                             prev=prev, repo=repo, head=r['head'], created=r['created'][:16].replace('T', ' '),
                             memo=r['memo'] or '(없음)', raw=raw, memory=', '.join(r['memory']))
        open(os.path.join(out, 'prompts', fk + '.txt'), 'w', encoding='utf-8').write(text)
    print('prompts:', len(os.listdir(os.path.join(out, 'prompts'))))


def tally(out):
    """에이전트 분류(class/<키>.json)를 집계해 표와 관문 G0 판정을 낸다."""
    table = json.load(open(os.path.join(out, 'naps.json'), encoding='utf-8'))
    rows, nu, harm, lines = [], [], [], []
    for r in table:
        f = os.path.join(out, 'class', r['key'].replace('/', '_') + '.json')
        if not os.path.exists(f):
            print('분류 없음:', r['key'])
            continue
        cs = json.load(open(f, encoding='utf-8'))
        c = {k: sum(x['class'] == k for x in cs) for k in 'RMGN'}
        good_nu = [x for x in cs if x['class'] == 'N' and not x['wrong'] and x['used'] == 'U']
        fact_nu = [x for x in good_nu if x.get('origin') == '사실']   # G0 지표: 다음 세션이 다시 만들 수 없는 것
        bad = [x for x in cs if x['wrong'] and x['used'] == 'U']
        carried = [x for x in cs if x.get('carried')]
        wrong = [x for x in cs if x['wrong']]
        hedged = sum('⚠️' in x['text'] for x in wrong)     # ⚠️ 추정으로 표시됐던 것
        rows.append((r['key'], len(cs), c, len(fact_nu), len(good_nu) - len(fact_nu), len(wrong) - hedged, hedged,
                     len(bad), len(carried), sum(x['wrong'] for x in carried)))
        nu += [(r['key'], x) for x in good_nu]
        harm += [(r['key'], x) for x in bad]
    lines.append('| NAP | 항목 | R | M | G | N | N사실∧U | N생성∧U | 틀림(단정) | 틀림(⚠️) | 틀림∧U | 넘어옴 | 넘어온 것 중 틀림 |')
    lines.append('|---|---|---|---|---|---|---|---|---|---|---|---|---|')
    for k, n, c, f, g, w, h, b, ca, cw in rows:
        lines.append(f'| {k} | {n} | {c["R"]} | {c["M"]} | {c["G"]} | {c["N"]} | {f} | {g} | {w} | {h} | {b} | {ca} | {cw} |')
    med = st.median(r[3] for r in rows) if rows else 0
    verdict = ('고유 기여 미미 → 단계 1 축소(3곳 × A·B × 2회)' if med <= 1 else
               '단계 1 전체' if med >= 3 else '사이(1~3) → 남은 NAP를 더 분류할지 사용자에게 묻는다')
    lines.append(f'\nNAP {len(rows)}개, N사실∧U 중앙값 {med} → {verdict}')
    lines.append(f'틀림∧U 합계 {len(harm)} → ' + ('단계 2에서 S3 먼저' if len(harm) >= 2 else 'S3 순서 그대로'))
    lines.append('\n## N∧U 항목\n')
    lines += [f'- `{k}#{x["id"]}` [{x.get("origin", "")}·{x.get("type", "")}] {x["text"][:150]} — {x.get("used_evidence", "")[:150]}'
              for k, x in nu]
    lines.append('\n## 틀렸는데 다음 세션이 따른 항목\n')
    lines += [f'- `{k}#{x["id"]}` {"(⚠️ 추정) " if "⚠️" in x["text"] else ""}{x["text"][:150]} — {x.get("note", "")[:150]}'
              for k, x in harm]
    open(os.path.join(out, 'tally.md'), 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('\n'.join(lines[:len(rows) + 5]))
    # 단계 0의 6: 사용자가 확인할 표본 20개(시드 고정)
    pool = []
    for r in table:
        f = os.path.join(out, 'class', r['key'].replace('/', '_') + '.json')
        if os.path.exists(f):
            pool += [(r['key'], x) for x in json.load(open(f, encoding='utf-8'))]
    sample = random.Random(20261014).sample(pool, min(20, len(pool)))
    cell = lambda s, n: str(s)[:n].replace('|', '/').replace('\n', ' ')
    md = ['| # | 항목 | 분류 | 근거 | 틀림 | 썼나 | 쓴 근거 | 맞음? |', '|---|---|---|---|---|---|---|---|']
    md += [f"| {n} | `{k}#{x['id']}` {cell(x['text'], 90)} | {x['class']}{'·' + x['origin'] if x.get('origin') else ''} | "
           f"{cell(x.get('evidence', ''), 60)} | "
           f"{'예' if x['wrong'] else ''} | {x['used']} | {cell(x.get('used_evidence', ''), 60)} | |"
           for n, (k, x) in enumerate(sample, 1)]
    open(os.path.join(out, 'sample20.md'), 'w', encoding='utf-8').write('\n'.join(md) + '\n')


if __name__ == '__main__':
    cmd, *a = sys.argv[1:]
    {'costs': costs, 'prep': prep, 'prompts': prompts, 'tally': tally}[cmd](*a)
