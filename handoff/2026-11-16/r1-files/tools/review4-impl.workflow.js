export const meta = {
  name: 'review4-impl',
  description: '플레이 후기 4 권장안 한 묶음: 워크트리에서 계획서대로 장부·평가 → 구현 → 세 관점 반박 검토 → 지적 고치기',
  phases: [
    { title: '장부·평가', detail: 'SPEC·EVAL·평가 코드를 먼저 쓴다(새·고친 평가는 빨강)' },
    { title: '구현', detail: '계획서대로 코드·데이터를 고쳐 초록으로, 화면 확인' },
    { title: '검토', detail: '세 관점 반박 검토(읽기·실행만)' },
    { title: '고치기', detail: '확인된 지적만 고치고 마무리 검증' },
  ],
}

const A = args
const S = '/tmp/claude-0/-home-user-td-proj/3a65bacf-d77b-5ad4-b30c-f51078f27e14/scratchpad'
const MAIN = '/home/user/td-proj'
const GATE = S + '/gate/gate.py'
const WT = A.wt
const SCR = A.scratch

const COMMON = `당신은 td-proj(Godot 4.7.2 GDScript 게임, SDD 장부 SPEC.md·EVAL.md) 저장소에서 일한다. 한국어로 일하고 결과도 한국어로 낸다.

공통 규칙
- 기준 문서: ${WT}/play_review/2026-11-15.md (플레이 후기 4 조사 기록). 사용자는 2026-11-16에 «권장안대로 진행»이라고 답했다: 항목마다 추천안(A)과 문서에 적힌 «Claude 기본값»대로 하고, 추천·기본값이 없는 질문은 지금 동작을 가장 덜 바꾸는 쪽으로 둔다.
- 계획서: ${A.plan} — 이 묶음(${A.key} «${A.title}», 후기 ${A.review})의 구현 계획서다. 코드를 읽고 쓴 뒤 독립 반박 검증을 거쳐 고쳐졌다(맨 위 «검증에서 고친 것»). 계획서의 결정표와 기본값이 곧 결정이다. 바꾸지 않는다.
- 계획서는 Godot·pytest를 돌리지 않고 썼다([추론] 표시). 실제 코드·실행 결과가 계획서와 다르면 계획서의 결정(뜻)을 지키는 가장 작은 수정으로 맞추고, 무엇이 달랐는지 보고에 적는다. 결정 자체를 바꿔야만 풀리는 문제면 바꾸지 말고 그 부분을 남긴 채 보고한다.
- 작업 트리: ${WT} (git 워크트리, HEAD ${A.base} = 주 브랜치의 지금 끝. .godot 가져오기 캐시와 .brain/brain.db는 이미 있다). 쓰기는 이 트리와 스크래치 ${SCR}/ 에서만 한다. ${MAIN} (주 체크아웃)는 읽기만 한다. 그곳에는 다른 묶음이 통합되고 있다.
- Godot은 PATH의 \`godot\`(4.7.2, Linux)이다. Godot을 돌리기 전에 ${WT}/.claude/skills/godot/SKILL.md를 읽는다(Windows 실행 파일 찾기 대신 \`godot\`을 쓴다). 창이 필요한 캡처는 \`xvfb-run -a -s "-screen 0 1920x1080x24" godot --path <트리> ...\`로 띄운다(소프트웨어 OpenGL로 그려진다. 소리는 더미 드라이버다). 일회성 스크립트는 반드시 \`timeout\`으로 감싼다(런타임 오류가 나면 프로세스가 끝나지 않는다).
- godot·pytest를 부르는 모든 Bash 명령의 맨 앞에 \`export XDG_DATA_HOME=${A.xdg};\`를 둔다(user:// 를 다른 병렬 작업과 나눈다. 셸 변수는 호출 사이에 남지 않는다).
- pytest는 \`python3 -m pytest -p no:cacheprovider\`다. 기계는 4코어이고 다른 묶음의 작업과 나눠 쓴다. 스위트 여럿을 한 pytest에 줄 때는 \`EVAL_JOBS=1\`을 앞에 둔다(conftest가 Godot을 둘씩 띄우지 않게). 스위트 하나에는 180초 제한이 있다(tests/eval/conftest.py). 제한에 걸려 떨어지면 기계가 붐빈 것이지 평가가 틀린 것이 아니다: 그 스위트만 다시 돌리고, 그래도 넘으면 \`godot --headless --path . -s res://tests/eval/gd/runner.gd -- <스위트> EV… EV…\`로 EV를 나눠 돌려 결과를 적는다.
- 난이도·밸런스 측정(봇 sweep, 승률·생존 비교)은 돌리지 않는다(프로젝트 CLAUDE.md). 기능 평가(pytest)·동치 확인·화면 캡처는 한다.
- git push·PR 만들기·브랜치 전환·커밋을 하지 않는다. 변경은 작업 트리에 그대로 둔다.
- \`godot --import\`를 돌렸다면 그 트리에서 \`git ls-files --others --exclude-standard -z -- '*.import' | xargs -0 rm -f\`로 미추적 .import를 지운다. 새 .gd의 .uid는 godot 스킬 절차대로 만든다. 지운 .gd의 .uid도 함께 지운다.
- 공개 함수·필드를 바꾸거나 이유 주석이 붙은 가지를 지우기 전에 ${WT}/.claude/skills/codebase-brain/SKILL.md를 읽고 \`sh .brain/query impact <대상>\`으로 영향과 «돌릴 테스트»를 뽑는다.
- 코드·주석·문서 글은 그 파일의 기존 말투(한국어 평서형)를 따른다. 모델 이름·식별자를 어디에도 적지 않는다.
- 확인하지 못한 것은 [추론]으로 표시한다. 빨간 테스트를 통과라고 쓰지 않는다. 막히면 우회하지 말고 무엇이 막혔는지 보고에 적는다.
${A.notes ? '\n이 묶음에만 해당하는 것\n' + A.notes + '\n' : ''}`

const LEDGER = `SPEC·EVAL 장부 규칙(이 워크트리의 SPEC.md·EVAL.md를 직접 고친다)
- 프로젝트 CLAUDE.md «SDD 작업 시간 줄이기»를 먼저 읽는다.
- 번호: ${A.idmap}. 계획서의 자리표를 이 절대 번호로 차례대로 바꿔 쓴다. 남는 번호는 비워 둔다. 모자라면 더 만들지 말고 보고한다(바로 뒤 번호는 다른 묶음이 쓴다).
- SPEC 문장은 한 줄이다(\`- S316. …\`). 바꿀 때는 지우지 않고 줄 끝에 덧붙인다: \` → **2026-11-16 변경:** …새 규칙… (근거: 사용자 2026-11-15 플레이 후기 4 «…사용자 말 원문…», 2026-11-16 «권장안대로 진행» — \`play_review/2026-11-15.md\` N번 안 A)\`. SPEC.md의 기존 «→ **2026-11-16 변경:**» 꼴(S316·S317·S322)을 찾아 말투와 꼴을 그대로 따른다.
- «→ 변경»은 중심 문장 하나에만 붙이고 «다른 문장의 ○○ 언급보다 이 문장이 우선한다»를 적는다. 규칙·수치·표가 실제로 달라지는 문장만 따로 고치고, 지나가며 언급만 하는 문장은 그대로 둔다(계획서 5장이 문장마다 정해 두었다).
- 새 I 문장(§2.2)은 끝에 \`[추론]\`을 달고 필요하면 (근거: …)를 붙인다. §2.2에는 «**플레이 후기 4** (2026-11-15, 기록 …)» 묶음 머리와 I302가 이미 있다. 새 문장의 자리는 계획서가 정한 곳이다.
- 해시: EVAL «근거 해시» = SPEC 그 문장 줄에서 앞의 \`- \`를 뗀 글의 sha256 앞 8자. EVAL 본표의 «근거 해시» 칸은 고치지 않는다(락 때 값이다). 근거 문장이 바뀐 EV는 «## 개정» 표 끝에 행을 더한다: \`| EV… | 새 해시 | 사유 | 2026-11-16 |\`.
- 개정 행 묶기: 같은 문장을 근거로 하고 해시만 바뀌는(측정과 테스트는 그대로) EV들은 한 행으로 묶는다(\`| EV263·EV264·EV265 | 새 해시 | 사유 | 2026-11-16 |\`). 사유 글에는 다른 EV 번호를 절대 쓰지 않는다(검사기가 그 행에 나온 EV 번호를 모두 그 행의 EV로 센다). 측정이나 테스트를 고친 EV는 EV마다 따로 행을 두고 무엇을 고쳤는지 적는다. 같은 EV가 여러 행에 나오면 마지막 행의 해시가 유효하다.
- 측정 글(본표의 «무엇을 어떻게 재나» 칸)이 달라지는 EV는 본표의 그 칸도 고친다. 측정 글과 테스트 코드가 같은 것을 재야 한다.
- 새 EV의 승인 칸은 \`위임(사용자 2026-11-16 «권장안대로 진행»)\`이다. 본표의 마지막 행(지금 EV1126) 뒤에 번호 차례로 넣는다. 새 평가는 tests/eval/gd/<스위트>.gd의 func evN과 tests/eval/test_<스위트>.py의 테스트를 함께 넣는다.
- EV를 지울 때는 선례(커밋 2c36eb3의 EV214·EV220)대로 본표에서 행을 지우고 테스트 함수(.gd·.py)를 함께 지운다. «기각» 표에는 넣지 않고(이 환경에는 specgate 검사기가 없어 «기각» 행을 받는지 확인할 수 없다), 그 EV의 «개정» 표 행도 지운다(묶음 행이면 그 번호만 뺀다). 지운 EV 번호와 까닭은 보고에 적는다.
- §3.1(문장 대조 표)의 줄 참조는 손대지 않는다. 통합할 때 도구로 한꺼번에 옮긴다. 대신 보고에 «§3.1에서 새로 지목할 것·없어질 것»을 파일#함수 이름으로 적는다.
- 검사: \`python3 ${GATE} --root ${WT}\` — EV 해시·테스트 대응·§3.1 범위·락을 본다. 장부를 다 고친 뒤 \`python3 ${GATE} --root ${WT} --write-lock\`으로 .specgate-eval.lock을 다시 만든다. HEAD에서는 위반 0이다. 줄이나 파일을 지워 생기는 §3.1 «범위 밖»·«파일 없음» 위반은 통합 때 풀리므로 남겨 두고 보고에 적는다. 그 밖의 위반은 0이어야 한다.
`

const REPORT = `산출(마지막 메시지가 곧 보고다)
1. 바꾼 파일 목록과 파일마다 한 줄 요약
2. 계획서와 달랐던 것, 스스로 정한 것(이유)
3. SPEC 문장마다: 새로 넣었나/«→ 변경»을 붙였나/제자리에서 고쳤나, 새 해시
4. EV마다: 새 EV·지운 EV·측정이나 테스트를 고친 EV·해시만 바뀐 EV(개정 행 묶음)
5. 돌린 스위트와 결과(통과·실패·건너뜀 수를 출력 그대로)
6. gate 출력 마지막 줄들
7. 캡처·동치 확인의 경로와 눈으로 본 것
8. §3.1 메모(새로 지목할 것·없어질 것: 파일#함수 이름)
9. 사용자에게 알릴 것(계획서 9장의 열린 질문·위험 가운데 실제로 확인된 것)과 남은 위험·확인 못 한 것`

const FINDINGS = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          title: { type: 'string' },
          severity: { type: 'string', enum: ['blocker', 'major', 'minor'] },
          where: { type: 'string', description: '파일:줄 또는 SPEC/EV ID' },
          evidence: { type: 'string', description: '재현 명령·출력 또는 코드 인용' },
          suggestion: { type: 'string' },
        },
        required: ['title', 'severity', 'where', 'evidence', 'suggestion'],
      },
    },
    checked: { type: 'string', description: '무엇을 확인했고 무엇이 문제없었는지' },
  },
  required: ['findings', 'checked'],
}

let ledger = ''
if (A.split) {
  ledger = await agent(`${COMMON}
## 일: ${A.key} 1단계 — SPEC·EVAL 장부와 평가 코드를 먼저 쓴다 (구현 코드는 손대지 않는다)

먼저 읽을 것
- 계획서 ${A.plan} 전체(특히 5장 SPEC, 6장 EVAL, 7장 검증). ${WT}/play_review/2026-11-15.md의 ${A.lines}줄과 1009-1093줄. ${WT}/CLAUDE.md.
- 계획서가 가리키는 SPEC 문장·EVAL 행·평가 .gd(tests/eval/gd/)·test_*.py와 그 평가가 쓰는 판 함수(src/). 평가의 측정 글을 쓰려면 코드가 실제로 어떻게 도는지 알아야 한다.

${LEDGER}
할 일
1. SPEC.md: 계획서 5장대로 새 문장을 넣고 «→ 2026-11-16 변경»을 붙인다(글은 계획서의 전문·초안을 쓰되, 실제 코드·데이터와 어긋나는 곳은 바로잡고 보고에 적는다). WBS 등 계획서가 함께 고치라고 한 문서도 고친다.
2. EVAL.md: 계획서 6장대로 새 EV 행, 지울 EV, 측정 글을 고칠 EV, 개정 행(묶기 규칙).
3. 평가 코드: tests/eval/gd/*.gd의 func evN과 tests/eval/test_*.py를 새로 쓰고·고치고·지운다. 구현이 아직 없으므로 새 평가와 고친 평가는 빨강이어야 하고(무엇 때문에 빨간지가 뜻한 대로인지 본다 — 문법 오류나 엉뚱한 까닭의 빨강은 고친다), 손대지 않는 평가는 그대로 초록이어야 한다. 구현 뒤에야 쓸 수 있는 이름(새 함수·새 칸)은 계획서 3장의 이름을 쓴다.
4. 유닛 시험(tests/unit/gd/)을 계획서가 새로 두라고 했으면 함께 쓴다.
5. \`python3 ${GATE} --root ${WT} --write-lock\` 뒤 gate를 다시 돌려 위반을 본다.
6. 바뀐 스위트를 돌려 빨강·초록 수를 적는다(스위트마다 무엇이 빨갛고 그것이 뜻한 것인지).
src/·data/·locale/·tools/의 구현 코드는 이 단계에서 고치지 않는다(다음 단계가 한다).

산출(마지막 메시지가 곧 보고다): 바꾼 파일, SPEC 문장별 처리와 새 해시, EV별 처리(새·지움·고침·해시만), 빨강 목록과 까닭, gate 출력 마지막 줄들, 계획서와 달랐던 것, 다음 단계(구현)가 알아야 할 것(평가가 기대하는 함수·칸 이름, 화면 좌표 등).`, { label: A.key + ' 장부·평가', phase: '장부·평가' })
  if (!ledger) return { key: A.key, error: '장부·평가 단계가 결과 없이 끝났다' }
}

const impl = await agent(`${COMMON}
## 일: ${A.key} «${A.title}» 구현 (후기 ${A.review})${A.split ? ' — 2단계: 코드·데이터' : ''}

먼저 읽을 것
- 계획서 ${A.plan} 전체. ${WT}/play_review/2026-11-15.md의 ${A.lines}줄과 1009-1093줄. ${WT}/CLAUDE.md.
- 계획서 3·4장이 가리키는 코드·데이터·번역 파일.
${A.split ? `
앞 단계(장부·평가)가 이 워크트리에 SPEC·EVAL·평가 코드를 이미 써 두었다(\`git -C ${WT} status --short\`, \`git -C ${WT} diff HEAD --stat\`). 그 보고:
<앞 단계 보고>
${ledger}
</앞 단계 보고>

할 일
1. 계획서 3장(코드)·4장(데이터·번역·그림·소리)대로 구현해 새·고친 평가를 초록으로 만든다. 도구(tools/)·봇도 계획서대로.
2. 평가 코드나 측정 글이 틀렸으면(계획서의 [추론]이 실제와 달랐다 등) 평가를 구현에 억지로 맞추지 말고, SPEC 문장이 말하는 규칙을 기준으로 어느 쪽이 틀렸는지 가려 고친다. 측정 글·테스트·개정 행·락을 함께 맞춘다.
3. 계획서 7장의 검증(작업 중 돌릴 스위트, 화면 확인, 동치·회귀 확인)을 한다.
` : `
${LEDGER}
할 일
1. 계획서 5·6장대로 SPEC·EVAL·평가 코드를 쓰고, 3·4장대로 구현한다. 새·고친 평가가 구현 전에 빨갛고 구현 뒤 초록인 것을 확인한다.
2. 계획서 7장의 검증(작업 중 돌릴 스위트, 화면 확인, 동치·회귀 확인)을 한다.
`}
테스트
- 작업 중에는 바뀐 스위트만(계획서 7장과 codebase-brain이 뽑은 «돌릴 것»). 화면 배치·그림 평가(C, tests/eval/conftest.py의 MERGE_ONLY)에 닿는 스위트는 \`EVAL_FULL=1\`로 한 번 돌린다.
- 전체 pytest는 이 단계에서 돌리지 않는다(고치기 단계 끝에 한 번 돈다).
- 평가 하나만: \`godot --headless --path . -s res://tests/eval/gd/runner.gd -- <스위트> EV<n>\` → «PASS EV<n>».
- 장부를 고쳤으면 \`python3 ${GATE} --root ${WT} --write-lock\` 뒤 gate를 다시 돌린다.

화면 확인
- 계획서 7장의 장면을 xvfb로 캡처해 PNG를 ${SCR}/에 두고 Read 도구로 직접 열어 눈으로 확인한다. tools/play 하네스(${WT}/tools/play)나 스크래치 SceneTree 스크립트(${SCR}/에 둔다)를 쓴다. 사용자 저장(user://)은 XDG로 나뉘어 있으므로 건드릴 일이 없다.

${REPORT}`, { label: A.key + ' 구현', phase: '구현' })
if (!impl) return { key: A.key, ledger, error: '구현 단계가 결과 없이 끝났다' }

const reviews = await parallel(A.lenses.map(l => () => agent(`${COMMON}
## 일: ${A.key} 구현을 반박 검토한다 (고치지 않는다 — 읽기·실행만)

대상: ${WT} (워크트리, HEAD ${A.base} 위의 미커밋 변경). \`git -C ${WT} diff HEAD\`와 \`git -C ${WT} status --short\`로 변경을 본다. 이 트리의 추적 파일을 고치지 않는다(스크래치 파일은 ${SCR}/review/에 둔다. 옛 동작과 견줄 때는 \`git -C ${WT} archive ${A.base} | tar -x -C <스크래치 폴더>\`로 HEAD 판을 풀고 .godot을 복사해 쓴다. 다 쓰면 지운다).
기준: 계획서 ${A.plan}(결정표·동작 명세·SPEC 초안·EVAL 초안)과 ${WT}/play_review/2026-11-15.md ${A.lines}줄.

${LEDGER}
구현 보고(주장일 뿐이다 — 믿지 말고 확인한다):
<보고>
${impl}
</보고>

${l.text}

결함이라고 볼 근거가 재현되거나 코드로 보일 때만 지적으로 낸다. 취향·문체 지적은 내지 않는다. 계획서의 결정을 뒤집자는 제안은 지적이 아니다(다만 결정이 사용자 근거가 있는 SPEC 문장과 부딪히는데 SPEC에 드러나지 않았다면 지적이다). 지적마다 재현 명령·출력이나 코드 인용을 붙인다. 문제없이 확인한 것도 checked에 적는다.`, { label: A.key + ' 검토: ' + l.key, phase: '검토', schema: FINDINGS })))

const all = reviews.flatMap((r, i) => r ? (r.findings || []).map(f => ({ ...f, lens: A.lenses[i].key })) : [])
const checked = reviews.map((r, i) => `- [${A.lenses[i].key}] ${r ? r.checked : '(검토 결과 없음 — 이 관점은 확인되지 않았다)'}`).join('\n')
log(`${A.key} 검토 지적 ${all.length}건 (blocker ${all.filter(f => f.severity === 'blocker').length} · major ${all.filter(f => f.severity === 'major').length} · minor ${all.filter(f => f.severity === 'minor').length})`)

const fix = await agent(`${COMMON}
## 일: ${A.key} 검토 지적을 확인하고, 맞는 것만 고친 뒤 마무리 검증을 한다

작업 트리: ${WT} (워크트리, HEAD ${A.base} 위의 미커밋 변경이 ${A.key} 구현이다).
기준: 계획서 ${A.plan}과 아래 장부 규칙.

${LEDGER}
구현 보고:
<보고>
${impl}
</보고>

검토 지적(세 관점):
<지적>
${JSON.stringify(all, null, 1)}
</지적>
검토가 확인한 것:
${checked}

할 일
1. 지적마다 스스로 재현·확인한다. 맞으면 고치고, 틀리면 왜 틀린지 적는다. 계획서의 결정과 부딪히는 제안은 따르지 않는다. 고치면서 평가를 구현에 억지로 맞추지 않는다.
2. SPEC 문장을 고치면 해시가 바뀐다. 개정 행의 해시를 다시 맞추고 \`python3 ${GATE} --root ${WT} --write-lock\`을 다시 돌린다.
3. 마무리 검증(모두 출력 그대로 보고):
   - 계획서 7장의 «작업 중 돌릴 것»과 바뀐 파일에 닿는 스위트(차례로, \`EVAL_JOBS=1\`).
   - 끝에 전체 한 번: \`EVAL_FULL=1 python3 -m pytest -q -p no:cacheprovider\`(약 6~8분, Bash timeout을 900000으로 준다). 마지막 줄을 그대로 적는다. 빨간 것이 있으면 까닭을 가려 고치고 그 스위트를 다시 돌린다(전체를 다시 돌리지는 않는다 — 다만 고친 것이 여러 스위트에 닿으면 닿는 스위트를 모두 다시 돌린다).
   - 유닛 시험 전체: \`godot --headless --path . -s res://tests/unit/gd/runner.gd\`(끝 줄).
   - \`python3 ${GATE} --root ${WT}\`.
4. \`git -C ${WT} status --short\`와 \`git -C ${WT} diff HEAD --stat\`를 붙인다. 미추적 .import·.pytest_cache가 남지 않았는지 본다.

산출(마지막 메시지가 곧 보고다): 지적별 판정(고침/기각과 이유), 마지막 변경 파일 목록, 검증 출력, SPEC 문장별 최종 상태(새 해시), EV 목록(새·지움·고침·해시만, 개정 행), §3.1 메모(새로 지목할 것·없어질 것: 파일#함수 이름), 사용자에게 알릴 것(열린 질문과 기본값, 사용자가 정한 글이 바뀌는 곳), 남은 위험.`, { label: A.key + ' 고치기', phase: '고치기' })

return { key: A.key, ledger, impl, findings: all, checked, fix }
