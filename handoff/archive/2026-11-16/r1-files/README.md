# r1 첨부 — 플레이 후기 4(2026-11-15) 권장안 구현 이어가기

앞 세션은 클라우드 컨테이너에서 돌았고 스크래치 폴더는 사라진다. 다음 세션에 필요한 산출물을 여기 모았다. 작업지시서는 `handoff/2026-11-16/r1.md`다.

## 1. 파일

| 경로 | 무엇 |
|---|---|
| `p7/p7.patch` | P7(2칸 버킷 + 인구 손잡이) 구현. 기준 커밋 f76bcbe, 새 파일 5개 포함. **검토·고치기 전**이다 |
| `p7/p7_impl_report.md` | P7 구현 보고(계획과 다른 곳 `BUCKET_MIN` 16, 돌린 스위트, 동치 확인 내역) |
| `p7/p7_review_lenses.md` | P7에서 못 돌린 세 관점 검토 지시 |
| `plans/P6.md`·`P7.md`·`P8.md` | 독립 검증을 거친 구현 계획서. 절: 0 한눈에 · 1 결정표 · 2 동작 명세 · 3 코드 · 4 데이터 · 5 SPEC · 6 EVAL · 7 검증 · 8 겹치는 곳 · 9 위험·열린 질문 · 10 번호. 쓰인 때의 HEAD는 0238535다(그 뒤 P2·P5가 들어갔다) |
| `tools/gate.py` | specgate 대용 검사기(클라우드에는 specgate 플러그인이 없다). `python3 gate.py [--root 경로] [--write-lock] [--quiet]` |
| `tools/shift_refs.py` | §3.1 줄 참조 옮기기. `python3 shift_refs.py [--base REV] [--apply]` |
| `tools/lineage.py` | §3.1 참조 내력 추적. `python3 lineage.py --out <lineage.json>` (약 20초) |
| `tools/apply_tier1.py` | 내력 결과에서 글로 확인되는 어긋남만 옮긴다. `python3 apply_tier1.py <lineage.json> <출력 폴더> [--apply]`. 출력 폴더에 `remaining.json`을 쓴다 |
| `tools/apply_tier2.py` | 에이전트 결정(`(id, a) → final`)을 §3.1에 적용. `python3 apply_tier2.py <워크플로 출력.json>… [--apply] [--skip-low]` |
| `tools/show_refs.py` | §3.1 행의 참조마다 첫 줄·끝 줄 글을 찍는다. `python3 show_refs.py S373 I304` |
| `tools/p5_review_md.py` | `play_review/2026-11-15.md`의 «처리» 줄·요약 표를 고친 본보기 |
| `tools/review4-impl.workflow.js` | 묶음 하나를 워크트리에서 «장부·평가 → 구현 → 세 관점 검토 → 고치기»로 돌리는 Workflow 스크립트. 13줄의 `const S`는 앞 세션 스크래치 경로다(고쳐 쓴다). args: `{key, title, review, lines, wt, scratch, xdg, plan, base, split, idmap, notes, lenses:[{key,text}]}` |
| `tools/spec31-repair.workflow.js` | §3.1 2단계(묶음마다 에이전트 하나가 문장과 대조) Workflow 스크립트. args: `{scratch, pin, jobs:[{key, kind:"decide"|"verify", file, n}]}` |
| `repair/remaining.json` | §3.1에서 문장 대조가 필요한 참조 785개(커밋 aaf4950 기준) |
| `repair/t2/*.json` | 위 785개를 파일별로 나눈 묶음 11개(battle1~4·view1~3·hud1~2·rest1~2)와 1단계 검증 표본 3개(sample_*) |
| `repair/tier1_applied.json` | 1단계에서 옮긴 1,293곳(옛 값 → 새 값) |
| `repair/p5_ref_decide_output.json` | P5 대조 때 에이전트 넷이 손으로 조사한 결과. `result.battle|hud|rest.other` 413개 가운데 1단계에 안 든 197개는 남은 785개의 일부에 대한 조사 값이다 |
| `p3/README.md`·`c1.diff`~`c3.diff` | 보스 곡 후보 셋(`tools/audio/make.py`의 `song_boss`에 붙일 diff)과 설명. WAV는 사용자에게 보냈고 여기에는 없다 |
| `p4/README.md`·`mock.diff` | 초상·대시 시안 설명과 시안 코드(기준 5f34eab, `src/ui/battle_view.gd`·`controls.gd`·`hud.gd`·`skill_cell.gd`). 그림·GIF는 사용자에게 보냈고 여기에는 없다 |

## 2. 스크래치 차리기와 명령

```
S=<새 세션의 스크래치패드>; mkdir -p $S/gate $S/xdg/main $S/wt
cp handoff/2026-11-16/r1-files/tools/*.py $S/gate/
```

- Godot 4.7.2 `/usr/local/bin/godot`. pytest는 `python3 -m pytest -p no:cacheprovider`. 실행 앞에 `export XDG_DATA_HOME=$S/xdg/main;`(병렬 일꾼은 폴더를 따로).
- 전체 평가(머지 전 final 대용): `EVAL_FULL=1 python3 -m pytest -q -p no:cacheprovider` (4코어에서 약 370초. 배경으로 돌리고 로그를 스크래치에 받는다).
- 평가 하나: `godot --headless --path . -s res://tests/eval/gd/runner.gd -- <스위트> EV<n>`. 유닛 시험은 파일마다 따로 돈다(`runner.gd`는 파일 인자가 있어야 한다).
- `tests/eval/conftest.py`: 스위트 하나의 상한 180초, `EVAL_JOBS` 기본 2, `EVAL_FULL=1`이면 C(`MERGE_ONLY`)까지 돈다.
- 창 캡처: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . -s <스크립트>`.
- `godot --import` 뒤에는 `git ls-files --others --exclude-standard -z -- '*.import' | xargs -0 rm -f`.
- 워크트리를 만들면 `.godot`과 `.brain/brain.db`를 복사해 둔다.

## 3. 장부 규칙(이 작업에서 쓴 것)

- EVAL «근거 해시» = SPEC 그 문장 줄에서 앞의 `- `를 뗀 글의 sha256 앞 8자. 본표 해시 칸은 고치지 않는다. 문장이 바뀌면 «## 개정» 표 끝에 `| EV… | 새 해시 | 사유 | 날짜 |` 행을 더한다.
- 개정 행 묶기와 «→ 변경» 꼴은 저장소 `CLAUDE.md`의 «SDD 작업 시간 줄이기» 절 그대로다. «→ 변경» 한 줄의 꼴: ` → **2026-11-16 변경:** … (근거: 사용자 2026-11-15 플레이 후기 4 «원문», 2026-11-16 «권장안대로 진행» — \`play_review/2026-11-15.md\` N번 안 A)`.
- I 문장(§2.2)은 끝에 `` `[추론]` ``. 새 EV의 승인 칸은 `위임(사용자 2026-11-16 «권장안대로 진행»)`.
- EV를 지울 때는 본표 행·테스트 함수·그 EV의 개정 행까지 지운다(선례 커밋 2c36eb3). «기각» 표에는 넣지 않는다.
- `.specgate-eval.lock`은 `gate.py --write-lock`으로 다시 만든다.
- 묶음 하나의 커밋 셋: ① «… SPEC·EVAL — …, lock»(SPEC 문장·EVAL·WBS·평가 코드·lock) ② «구현 — …»(src·data·locale·tools·유닛 시험·`play_review` «처리» 줄) ③ «SPEC §3.1 대조 — …». 본보기는 P5의 a6ff135·bfaba36·4e74c56이다.
- 번호: 지금 마지막은 S373 · I304 · U44 · EV1132다.
  - P7(패치가 이미 쓴다): I305 · EV1133~EV1137
  - P6: S374 · I306~I308 · U45~U47 · EV1138~EV1148
  - P8: I309 · U48~U49 · EV1149~EV1154
  - 계획서의 «S+1»·«EV+1» 꼴은 이 절대 번호로 읽는다.

## 4. 묶음을 주 트리에 넣는 절차

1. `git apply --3way --index <패치>`. SPEC.md·EVAL.md 충돌(새 문장 자리, 본표 끝, 개정 표 끝)은 양쪽을 모두 남기고 새 EV 행은 번호 차례로 둔다. lock은 `git checkout --ours` 뒤 다시 만든다.
2. `python3 $S/gate/shift_refs.py --base HEAD` (미리 보기) → `--apply`. «손으로 볼 것»으로 찍힌 참조는 바뀐 코드에 걸친 것이다. `lineage.py` 결과와 `show_refs.py`로 가리키는 글을 확인해 고치고, 새 문장의 행을 표 끝에 더한다.
3. `python3 $S/gate/gate.py --write-lock` → `gate.py` 위반 0.
4. 전체 평가 → `play_review/2026-11-15.md`의 그 항목 «처리» 줄과 요약 표 → 커밋 셋 → `git push -u origin claude/confident-tesla-dh7yt7`.

## 5. §3.1 옛 어긋남(2026-11-16에 찾음)

- 사실: §3.1 줄 참조 5,020개 가운데 1,914개가 문장과 무관한 줄을 가리키고 있었다. 나란히 만든 PR이 병합될 때(2026-11-02 #276, 11-03 #282, 11-04 #289·#291, 11-07 #307 등) 한쪽 코드 변경 몫의 줄 옮김이 빠졌고, 그 뒤의 기계 옮김은 어긋난 값을 평행 이동했다. 검사기는 범위·파일만 본다.
- 1단계(커밋 aaf4950): 적힌 때의 첫 줄·끝 줄 글이 지금 자리의 글과 같거나 비슷한 1,293곳을 옮겼다. P5 때 에이전트가 손으로 조사한 값과 겹치는 263곳은 모두 같은 자리였다. 표본 반박 검증(`repair/t2/sample_*.json`)은 돌리지 못했다.
- 남은 것: 785곳(`repair/remaining.json`의 `feat` — C-low 498: 후보 자리의 글이 적힌 때와 많이 다르다 / OK-low 164: 도구는 맞다고 봤지만 글이 많이 다르다 / LIKELY-x 97 / C-sim-x 26). 항목의 `t`는 도구의 후보이고 틀릴 수 있다(에이전트 조사와 견주면 C-low에서 약 58%만 같았다). 문장을 읽고 정해야 한다.
- 코드 줄이 바뀐 뒤(P7 통합 뒤 등)에는 `lineage.py`와 `apply_tier1.py`를 다시 돌려 `remaining.json`을 새로 뽑는다(aaf4950에서 다시 뽑으면 783개가 나온다).

## 6. 끝 보고 때 사용자에게 알릴 것(계획서의 기본값으로 진행한 것)

- P5(들어감): 마우스로 둘을 고른 뒤 Enter 두 번이면 누른 적 없는 첫 카드 영웅이 셋째로 들어가 시작된다(기본값 «첫 카드 포커스») / 라운드 사이 창에 «영웅» 쪽(영웅 줄 셋 + 이관)을 남겼다 / 시작 골드 1000 그대로 / 전리품·제작은 영웅 여섯 몫 그대로 / 테스트 모드의 T 키 영웅 바꾸기가 없어졌다 / `.claude/skills/godot/SKILL.md`의 «입력 넣기» 예시 `"key Enter" "click 300 200" "wait 3"`이 낡았다(첫 Enter가 첫 카드를 고른다. 바꿀 글 `"click 166 80" "click 166 107" "click 166 133" "key Enter" "click 300 200" "wait 3"`. 고치지 않았다).
- P7: 옛 저장의 집 몫을 데이터 값(20)으로 맞춘다 / 거점 패널 머리 줄 «인구 n/m» → «n/m» / 위 띠 아래 인구 칸 52 → 58px·타워 칸 x 66 / U9는 «선택 대기» 그대로 수치만 / 계획에 없던 `BUCKET_MIN` 16 / P7만으로는 U9(150·300 편집기 30fps)에 못 미친다 / 아군 상한 31 → 153이라 판이 쉬워질 수 있다(재는 것은 사용자).
- P6: 자리 모양은 가로 줄 블록(문서 글은 BFS n칸) / «지나가기»(걷는 유닛이 선 아군을 지나감)는 승인된 문서 글과 다르고 S13에 닿아 U «선택 대기»로 둔다 / 같이 걷기로 빠른 유닛이 느린 유닛 속도에 묶인다 / 봇 결과가 달라질 수 있다.
- P8: 고치는 파일은 `src/sim/battle.gd` 하나, 기존 EV 개정 0. P6의 `_form_up`과 맞물린다.
- P3: 고리를 넘을 때 표본 하나가 튀는 것을 찾았다(QOA 길이가 128표본의 배수가 아닌 곡: 지금 보스 곡·타이틀 곡과 후보 셋. 전투 곡에는 없다). 고치면 타이틀 곡 파일도 바뀐다. 귀에 들리는지는 확인하지 못했다.
- P4의 질문 여섯과 기본값: 초상 안 C / 단색 영웅 실루엣 / `swing` / «끊겨 보인다» 해석 / 고른 영웅이 없을 때 표시 없음 / 초상에만.
