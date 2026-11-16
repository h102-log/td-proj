export const meta = {
  name: 'spec31-repair',
  description: 'SPEC §3.1 옛 어긋남 바로잡기: 글이 바뀐 참조를 문장과 대조해 최종 값을 정하고(읽기만), 기계로 옮긴 참조 표본을 반박 검증한다',
  phases: [{ title: '대조', detail: '묶음마다 한 에이전트' }],
}
const S = args.scratch
const PIN = args.pin
const COMMON = `
너는 td-proj(/home/user/td-proj, Godot 4 GDScript 타워 디펜스 게임) 저장소의 SPEC.md §3.1 «문장 대조» 표를 바로잡는 일을 돕는다.
**저장소 파일을 고치지 않는다. git 상태를 바꾸지 않는다(커밋·stash·checkout·reset 금지).** pytest·Godot·측정은 돌리지 않는다. 읽기·grep·sed·git show/log/diff만 쓴다.
스크립트·메모는 **네 전용 폴더 ${S}/repair/t2/work_KEY/** 에만 쓴다(다른 일꾼과 파일이 섞이지 않게 반드시 이 폴더).

## 배경
- §3.1 표(SPEC.md의 «### 3.1 문장 대조»부터 «### 3.2» 앞)는 \`| 문장 번호 | 코드 위치 |\` 행이다. 코드 위치 칸은 그 SPEC 문장을 구현한 코드 줄을 \`경로:줄\`·\`경로:첫줄-끝줄\`로 적어 \` · \`로 잇는다(①②③ 표지가 있는 행도 있다).
- 문제: 2026-11 초에 나란히 만든 PR들이 병합될 때(2026-11-02 #276, 11-03 #282, 11-04 #289·#291, 11-07 #307 등) 줄 옮김이 일부 빠져, 많은 참조가 문장과 무관한 줄을 가리키게 됐다. 그 뒤의 기계 옮김은 어긋난 값을 평행 이동만 했다.
- 내력 추적 도구가 첫 부모 이력 357커밋을 따라가 참조마다 «적힌 때의 범위가 지금 어디인가»(참 자리 후보)를 구했다. 글로 확인되는 1,293곳은 이미 기계로 옮겨 커밋했다(${PIN}). 지금 코드와 SPEC.md는 커밋 ${PIN}의 것이고, 네가 일하는 동안 바뀌지 않는다.
- SPEC 문장: \`grep -n '^- S54\\. ' SPEC.md\`처럼 찾는다(한 줄. 끝에 «→ **날짜 변경:** …»이 덧붙고 뒤의 변경이 앞 글보다 우선한다). §3.1 행: \`grep -n '^| S54 |' SPEC.md\`.
- 옛 코드: \`git show <커밋>:<경로> | sed -n 'a,bp'\`. 그 행이 커밋마다 어땠는지: \`git show <커밋>:SPEC.md | grep '^| S54 |'\`. 코드 조각이 언제 바뀌었는지: \`git log --oneline -S'<글>' -- <경로>\`, \`git log -L<a>,<b>:<경로>\`(느릴 수 있다).
- 코드에는 문장 번호가 주석으로 붙은 곳이 많다(\`# …(S54)\`, \`(I303 ①)\`). \`grep -n 'S54' <경로>\`가 좋은 단서다. 다만 번호가 없는 코드를 가리키는 참조도 많다.
`
const DEC_SCHEMA = {
  type: 'object',
  properties: {
    decisions: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          a: { type: 'string', description: '목록의 a 값 그대로' },
          final: { type: 'string', description: '최종 참조 글. 여럿이면 " · "로 잇는다. 지우면 빈 글. 그대로면 a와 같은 글' },
          kind: { type: 'string', enum: ['same', 'moved', 'rescoped', 'replaced', 'deleted'] },
          conf: { type: 'string', enum: ['high', 'mid', 'low'] },
          why: { type: 'string' },
        },
        required: ['id', 'a', 'final', 'kind', 'conf', 'why'],
      },
    },
    notes: { type: 'string' },
  },
  required: ['decisions', 'notes'],
}
const VER_SCHEMA = {
  type: 'object',
  properties: {
    checked: { type: 'integer' },
    wrong: {
      type: 'array',
      description: '새 값이 틀린 것(문장을 받치지 않는 줄이거나, 범위가 어긋나 있다)',
      items: { type: 'object', properties: { id: { type: 'string' }, old: { type: 'string' }, new: { type: 'string' }, should: { type: 'string' }, why: { type: 'string' } }, required: ['id', 'old', 'new', 'should', 'why'] },
    },
    doubts: {
      type: 'array',
      description: '틀렸다고 단정은 못 하지만 더 나은 값이 있거나 애매한 것',
      items: { type: 'object', properties: { id: { type: 'string' }, new: { type: 'string' }, suggest: { type: 'string' }, why: { type: 'string' } }, required: ['id', 'new', 'why'] },
    },
    notes: { type: 'string' },
  },
  required: ['checked', 'wrong', 'doubts', 'notes'],
}
function decidePrompt(j) {
  return `${COMMON.replace(/KEY/g, j.key)}
## 너의 몫 — 참조 ${j.n}개의 최종 값을 정한다
목록: ${j.file} (JSON 배열, ${j.n}개). 항목 칸:
- id: 문장 번호 · a: 지금 SPEC.md에 적힌 참조 · t: 도구가 구한 참 자리 후보(틀릴 수 있다)
- feat: 부류
  - C-low: a가 어긋났다고 도구가 본 것. 후보 t의 첫 줄·끝 줄 글이 적힌 때의 글과 많이 다르다(코드가 고쳐졌거나, 내력 추적이 틀렸다).
  - C-sim-x: 글은 비슷하지만 범위 길이가 달라졌고 내력에 짐작이 섞였다.
  - LIKELY-x: 첫 줄·끝 줄 글은 같지만 범위가 크게 늘었거나 내력에 짐작이 섞였다.
  - OK-low: 도구는 a가 맞다고 봤지만(a = t), a 자리의 글이 적힌 때의 글과 많이 다르다. 손으로 다시 적은 것을 도구가 믿은 경우와, 어긋남을 못 잡은 경우가 섞여 있다.
- born: 도구가 «이 참조가 적혔다»고 본 커밋 · born_r: 그때의 [첫줄, 끝줄] · born_txt: 그때의 [첫 줄 글, 끝 줄 글]
- a_txt / t_txt: 지금 코드에서 a / t 범위의 [첫 줄 글, 끝 줄 글] · touched: 내력 도중 그 범위의 코드가 고쳐졌다 · ev: 내력 사건(partial = 일부만 옮김, approx·adjusted = 덩이에 걸려 짐작, mech? = 기계 옮김으로 짐작, reauth = 손으로 다시 적음, healed = 바로잡힘)

### 항목마다 하는 일
1. SPEC 문장을 읽고(변경 글까지), 그 행의 다른 참조와 함께 이 참조가 문장의 어느 구절을 받치려던 것인지 정한다.
2. 적힌 때의 코드를 읽는다: \`git show <born>:<경로> | sed -n '<born_r 첫줄-2>,<끝줄+2>p'\`. 그것이 문장의 구절을 받치는 코드로 말이 되는지 본다.
   - 말이 되면 그것이 «원래 지목»이다.
   - 말이 안 되면(문장과 무관한 줄) born이 틀린 것이다. 그 행의 이력을 더 거슬러(\`git log --first-parent --format=%h -- SPEC.md\`로 커밋을 얻어 \`git show <커밋>:SPEC.md | grep '^| <id> |'\`) 그 자리 값이 문장과 맞던 마지막 때를 찾거나, 문장의 뜻으로 지금 코드에서 직접 찾는다.
3. 원래 지목이 지금 코드 어디에 있는지 찾는다. 후보 t를 먼저 읽어 보고(\`sed -n\`), 아니면 함수 이름·주석·글로 grep한다. 범위는 원래와 같은 단위로 잡는다(함수 전체였으면 지금 함수 전체 — 앞 주석 줄부터 함수 끝 줄까지, 한 줄이었으면 그 한 줄). 끝에 빈 줄을 넣지 않는다.
4. final을 정한다.
   - 같은 코드가 남아 있다 → 그 범위. a와 같으면 kind same, 다르면 moved(범위가 늘거나 줄면 rescoped).
   - 코드가 다시 쓰였지만 문장의 같은 구절을 받친다 → 지금 코드의 범위(kind replaced). 사이에 딴 코드가 끼어 갈라졌으면 \` · \`로 나눠 적는다.
   - 그 구절을 받치던 코드가 없어졌고(없앤 기능: 의뢰 2026-11-07, 마나 2026-11-01, 영입 비용·리롤·언제든 영입 창 2026-11-16 등) 대신 받칠 지금 코드도 없다 → final 빈 글(kind deleted). 문장의 그 구절이 지금도 살아 있는 규칙이면 지금 그것을 구현한 코드를 찾아 넣는다.
   - 같은 행에 final과 똑같은 참조가 이미 있으면(\`grep '^| <id> |' SPEC.md\`로 확인) 겹치지 않게 final을 빈 글로 하고 why에 «행에 이미 있다»고 적는다.
5. final의 첫 줄·끝 줄을 지금 파일에서 \`sed -n\`으로 찍어 확인한다. 줄 번호는 반드시 직접 확인한 값이어야 한다(짐작 금지). 범위가 파일 길이를 넘으면 안 된다.
6. conf: high = 원래 지목과 지금 자리를 둘 다 글로 확인했다 / mid = 코드가 다시 쓰여 판단이 들어갔다 / low = 원래 지목을 확정하지 못했다(이때는 가장 그럴듯한 값을 주되 why에 대안을 적는다).

### 지킬 것
- decisions는 목록의 ${j.n}개 모두를 담고 (id, a) 짝이 목록과 같아야 한다. 끝에 스크립트로 수와 짝을 검사한다.
- 같은 (id, a)가 목록에 두 번 있으면(행 안 중복 참조) 둘 다 넣고 같은 final을 준다.
- 파이썬으로 born 코드·a·t의 글을 한꺼번에 찍는 도우미를 먼저 만들어 쓰면 빠르다. 그래도 항목마다 문장과의 대조는 직접 한다.
- notes에 방법, 확신이 낮은 항목, 눈에 띈 다른 문제(같은 행의 다른 참조가 틀려 보이는 것 등)를 적는다.`
}
function verifyPrompt(j) {
  return `${COMMON.replace(/KEY/g, j.key)}
## 너의 몫 — 기계로 옮긴 참조 표본 ${j.n}개를 반박 검증한다
커밋 ${PIN}은 §3.1 참조 1,293곳을 기계로 옮겼다(\`git show ${PIN} --stat\`, 바뀐 행은 \`git diff ${PIN}~1 ${PIN} -- SPEC.md\`). 기준은 «적힌 때의 첫 줄·끝 줄 글이 새 자리의 글과 같다(또는 비슷하다)»였다. 문장과의 뜻 대조는 하지 않았다.
표본: ${j.file} (JSON 배열, ${j.n}개). 칸: id · old(옮기기 전 값) · new(지금 SPEC.md의 값) · cls(SURE = 글 같고 사이 코드가 안 바뀜 / LIKELY = 끝점 글 같고 안쪽만 바뀜 / C-sim = 끝점 글이 조금 바뀜) · born(적힌 커밋)·born_r·born_txt.
**틀린 것을 찾는 것이 목적이다.** 표본마다:
1. SPEC 문장을 읽는다. 2. 지금 코드에서 new 범위를 읽는다(\`sed -n\`). 3. 그 코드가 문장의 구절을 받치는지 판단한다. 4. old 범위도 읽어, old가 오히려 맞았던 것은 아닌지 본다. 5. 범위의 처음·끝이 함수·가지의 경계와 맞는지(한두 줄 모자라거나 남는지, 끝이 빈 줄인지) 본다.
- 새 값이 문장과 무관한 코드를 가리키면 wrong에 넣고 should에 맞는 값을 적는다(직접 줄을 확인한다).
- 받치기는 하지만 범위가 어색하거나(딴 코드가 끼었다, 함수의 일부만) 더 나은 값이 있으면 doubts에 넣는다.
- 문장이 그 뒤 «→ 변경»으로 바뀌어 적힌 때의 코드가 이제 문장과 맞지 않는 경우(낡은 지목)도 doubts에 넣는다.
checked에는 실제로 다 본 수를 적는다(${j.n}개 모두 본다). notes에 방법과 전체 인상(틀린 비율)을 적는다.`
}
phase('대조')
const res = await parallel(args.jobs.map(j => () =>
  agent(j.kind === 'verify' ? verifyPrompt(j) : decidePrompt(j), { label: `${j.kind === 'verify' ? '검증' : '대조'}:${j.key}`, phase: '대조', schema: j.kind === 'verify' ? VER_SCHEMA : DEC_SCHEMA })
    .then(r => ({ key: j.key, kind: j.kind, result: r }))))
return res
