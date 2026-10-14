# 출처·재현

## 원자료 (저장소 밖, 커밋하지 않음)

| 경로 | 내용 |
|---|---|
| `C:/Users/bhy99/handoff-ab/raw/` | td-proj 대화 기록 원본 복사본(2026-10-14, 파일 380개, 119MB). Claude Code가 오래된 기록을 지우기 전에 남겼다 |
| `C:/Users/bhy99/handoff-ab/stage0/naps.json` | NAP 13개 대응표: 작성 세션, 재개 세션, `head`, 사용자 메모, 그 시점 메모리 |
| `C:/Users/bhy99/handoff-ab/stage0/items/` | NAP별 항목 목록 |
| `C:/Users/bhy99/handoff-ab/stage0/excerpts/` | 다음 세션 발췌(`_next`)와 앞 세션 사용자 발화(`_prior`) |
| `C:/Users/bhy99/handoff-ab/stage0/prompts/` | 분류 에이전트 지시문(모든 NAP가 같은 틀) |
| `C:/Users/bhy99/handoff-ab/stage0/class/` | 최종 분류. 기준 v3 분류에 사용자 확인(G0 결정 항목 6개)을 반영했다. 고친 항목의 note에 «사용자 확인 2026-10-14»와 근거를 남겼다 |
| `C:/Users/bhy99/handoff-ab/stage0/class_v1/`, `class_v2/` | 이전 기준의 결과와 그때의 기준 파일 |
| `C:/Users/bhy99/handoff-ab/stage0/class_v3/` | 사용자 확인 전 에이전트 원본(기준 v3). `class/`와는 6개 항목만 다르다 |
| `C:/Users/bhy99/handoff-ab/stage0/tally.md`, `sample20.md` | 집계와 표본 |

## 스크립트와 기준 (저장소 안)

| 경로 | 내용 |
|---|---|
| [`.claude/skills/handoff/evals/ab/stage0.py`](../.claude/skills/handoff/evals/ab/stage0.py) | `costs`(계획서 §2 비용 재현), `prep`(대응표·항목·발췌), `prompts`(지시문), `tally`(집계·G0·표본) |
| [`.claude/skills/handoff/evals/ab/stage0_rubric.md`](../.claude/skills/handoff/evals/ab/stage0_rubric.md) | 분류 기준 v3 |

## 다시 돌리는 법 (Git Bash)

```sh
P=/c/Users/bhy99/AppData/Local/Programs/Python/Python314/python.exe
S=.claude/skills/handoff/evals/ab/stage0.py
$P -I $S costs C:/Users/bhy99/handoff-ab/raw
$P -I $S prep C:/Users/bhy99/handoff-ab/raw C:/Users/bhy99/td-proj C:/Users/bhy99/handoff-ab/stage0
$P -I $S prompts C:/Users/bhy99/handoff-ab/raw C:/Users/bhy99/td-proj C:/Users/bhy99/handoff-ab/stage0
$P -I $S tally C:/Users/bhy99/handoff-ab/stage0
```

`costs`의 기대 출력은 다음과 같다(2026-10-14 확인).
- 작성 n=13: 도구 18 · 출력 17,770 · 컨텍스트 증가 30,847
- 재개 → 작업 시작 n=13: 도구 8 · 출력 5,360 · 컨텍스트 증가 19,667
- 재개 세션 전체: 요청 96 · 출력 103,818

`tally`의 기대 출력은 다음과 같다(2026-10-14, 사용자 확인 반영 뒤).
- N사실∧U 중앙값 2 → 사이
- 틀림∧U 합계 10 → 단계 2에서 S3 먼저

`tally`는 `sample20.md`도 다시 쓴다. 고친 6개가 표본에 없어서 내용은 같다.

## 알려진 자료 문제

- **인자 없는 `/handoff`:** `<command-args>` 태그가 없어 첫 분석이 작성 1건(92d760ff)을 놓쳤다. `stage0.py`에서 고쳤다.
- **실수로 부른 `/handoff`:** aec2f8b1 14:45의 호출은 도구 0회 뒤 바로 중단됐다. 비용 집계에서 뺐다.
- **모델이 지어 넣은 인자:** 2026-10-13-6 NAP의 Skill 인자는 모델이 쓴 긴 요약이다. 사용자 메모는 사용자 발화 기준(«3.7(10/18) 전에 정할 것들 결정»)으로 바꿨다(`stage0.py`의 `MEMO`).
- **메모리 생성 시각:** 파일 생성 시각은 `sed -i`가 새로 만들어 믿을 수 없다. 대화 기록에서 그 파일을 처음 쓴 시각을 썼다.
