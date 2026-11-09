---
name: codebase-brain
description: td-proj의 코드 의존 그래프와 설계·장애 히스토리 검색(.brain). 정의된 파일 밖에서 쓰이는 함수·상수·시그널·필드(특히 src/sim/battle.gd, src/data/*_def.gd, tests/eval/gd/lib.gd)를 바꾸기 전에 N단계 영향(호출자·화면·도구·평가 스위트)과 «돌릴 테스트»를 뽑고, SPEC ID 주석·ponytail·[이유] 메모가 붙은 분기나 이유를 모르는 예외 처리를 지우거나 바꾸기 전에 그 이유(SPEC 문장·변경 이력·지키는 EV·도입 커밋)를 찾는다. SPEC 문장·EV의 내력, 과거 결정·장애를 낱말로 찾을 때도 쓴다. 파일 1~2개 안의 국소 수정(그 파일 안에서만 부르는 비공개 함수, 주석·문구만), data/ 수치 조정, 그림·소리 생성, SPEC·EVAL 장부 편집에는 쓰지 않는다.
---

# 세컨드 브레인 (.brain)

grep 여러 번으로 하던 «누가 이걸 쓰나(N단계)»와 «이건 왜 이렇게 되어 있나»를 질의 한 번으로 바꾼다.
색인은 `.brain/brain.db`(SQLite, 커밋하지 않음) 하나이고 저장소 파일은 읽기만 한다. 2026-11-09에 아래 명령을 모두 돌려 확인했다.

## 언제 부르나

부른다:
- 바꿀 심볼이 정의된 파일 밖에서 쓰인다 — 공개 함수·상수·시그널·안쪽 클래스(Enemy·Unit·Block…) 필드·데이터 정의 필드 → `impact`
- 지우거나 바꾸려는 분기에 SPEC ID 주석(S·I·U), `ponytail:`, `[이유]` 메모가 있거나, 왜 있는지 모르는 예외·특수 처리다 → 고치기 전에 `why`
- 어느 평가 스위트를 돌릴지 정해야 한다(CLAUDE.md «작업 중에는 바뀐 스위트만») → `impact`의 «돌릴 것»
- SPEC 문장·EV가 언제·왜 바뀌었고 어느 코드·테스트가 지키나 → `why S114`, `why EV372`
- 과거 결정·장애를 낱말로 찾는다 → `why 성문 핑퐁`

부르지 않는다(Grep 한 번이나 직접 읽기가 싸다):
- 파일 하나 안에서만 부르는 비공개 함수(`_x`)이고 호출이 그 파일 안에 있다
- 주석·화면 문구만, 또는 `data/*.tres` 수치만 바꾼다(난이도 측정은 사용자 몫 — CLAUDE.md)
- `tools/art`·`tools/audio` 생성 스크립트, 그림·소리, 문서만 고친다
- SPEC.md·EVAL.md 장부를 고친다(장부 규칙은 CLAUDE.md)

## 명령 (저장소 루트, Git Bash·Linux 같음)

```bash
sh .brain/query impact src/sim/battle.gd#repair_cost
sh .brain/why src/sim/battle.gd#repair_cost
sh .brain/why S114
sh .brain/why 성문 핑퐁
```

| 명령 | 하는 일 |
|---|---|
| `query impact <대상> [--all] [--depth N] [--follow-ambiguous]` | 거꾸로 BFS: 영향받는 코드 경로·레이어·미확인 연결·돌릴 테스트 |
| `query callers <대상>` | 한 단계 호출자만(엣지 종류·확실도·줄) |
| `query find <이름>` | 심볼 id 찾기(`%` 와일드카드) |
| `query unresolved [--category C] [--file F]` | 정적으로 못 정한 연결 목록(아래 표) |
| `why <대상 \| S·I·U·EV ID \| 낱말>` | SPEC 문장·변경 이력·지키는 EV·`git log -L` 커밋·설계 기록 |
| `build` | 전체 색인(약 3초). 질의는 색인이 오래되면 스스로 다시 만든다 |

- 대상: `경로#심볼`, `경로#안쪽클래스.멤버`(`src/sim/battle.gd#Enemy.guard`), `경로:줄`(둘러싼 함수), `경로`(파일 전체), 맨 이름(`repair_cost`, 여럿이면 후보를 보이고 종료 코드 2).
- 질의 하나는 0.2초 안팎이다. 색인이 오래됐으면(색인한 파일의 크기·시각, HEAD, 브레인 소스가 바뀜) 먼저 다시 만들고 stderr에 `[brain] 색인을 다시 만들었다`를 낸다.
- 파이썬은 `.brain/_py.sh`가 handoff 스킬의 nap.sh와 같은 순서(python3 → python → py -3)로 찾는다. FTS5가 되는 SQLite가 필요하다.

## 출력 읽기

확실도 — 엣지마다 붙는다. 확정이 아닌 것은 «맞을 가능성이 높은 추정»이지 보증이 아니다.

| 표시 | 뜻 |
|---|---|
| 확정 | 문법·타입으로 정해진다: 같은 클래스 안 호출, self/super, 별칭 상수(`const Battle := preload(...)`)·class_name, 타입 붙은 변수, `A.new()` |
| 추론 | 받는 쪽 타입을 짐작했다: 대입(`view.battle = Battle.new()`), 반환문(`return load("…battle.gd").new()`), 컨테이너 원소(`for e in b.enemies` ← `enemies.append(Enemy.new())`), 이름 지도, 프로젝트에 그 이름이 하나뿐 |
| 동적 | 문자열로 이어진다: `call("이름")`, `has_method`, `get("필드")`, 리플렉션 이름 대응, 코드 생성 덮어쓰기 |
| 가상호출 | 덮어쓴 함수: 부모 쪽 호출이 실행 중에 이 함수로 온다 |
| 미확인 | 후보가 여럿이라 정하지 못했다. 경로에 넣지 않고 [미확인·동적]에 지점만 보인다 |

- `[허브]`: 15개 파일 넘게에서 불리는 함수(`build`·`step`·`spawn_enemy`, lib.gd의 `battle`·`run` 등)와 테스트가 프레임을 돌리려 직접 부르는 엔진 콜백(`_process`·`_ready`). 허브 너머는 «허브 경유»로 수만 센다.
- [테스트] 1순위는 SPEC 연결이다: 대상 줄과 겹치는 SPEC §3.1 줄 참조 + 대상 주석의 ID → 그 문장을 지키는 EV. 2순위는 허브를 거치지 않고 3단계 안에서 닿는 평가·유닛이다. 둘을 «돌릴 것» 명령으로 낸다. 그 밖(허브 경유)은 커밋 전 전체 pytest가 맡는다(CLAUDE.md 순서 그대로).
- `⚠ 지키는 EV가 없는 문장`: 그 동작은 지우거나 바꿔도 평가가 못 잡는다. 사용자에게 알리거나 더 조심한다.
- `글 tests/eval/gd/locale.gd:… 폴더째 읽음(src/**)`: 그 평가는 호출이 아니라 소스 글을 읽는다(EV373 한글 리터럴 → en.po). 대상에 한글 리터럴이 있으면 «돌릴 것»에 locale이 붙는다.
- impact가 `tools/`(play 하네스·bench 등)를 보여 주면 그 도구도 같은 커밋에서 고친다. 난이도 측정(봇 sweep 등)은 돌리지 않는다(CLAUDE.md).

## 미확인 연결 — 정적 색인이 원리상 못 정하는 곳

`query unresolved`가 범주마다 센다. 억지로 잇지 않고 이 범주로 남긴다. 고칠 때는 아래 «확인하는 법»으로 사람이 본다.

| 범주 | 예 | 정적으로 못 정하는 이유 | 확인하는 법 |
|---|---|---|---|
| ambiguous | `h.hp`(h는 타입 없는 매개변수) | GDScript는 타입 표기가 선택이고, `hp`·`pos`·`kind`가 Enemy·Unit·Block·Villager에 다 있다. 호출 지점 인자에서 매개변수 타입을 거꾸로 넘기는 분석은 아직 없다 | 지점을 열어 받는 쪽을 본다. `--follow-ambiguous`로 그 위까지 따라간다 |
| engine-name | `d.keys()`·`x.size` | 프로젝트 함수(camera.gd#keys)와 엔진 메서드(Dictionary.keys) 이름이 같다 | 대부분 엔진이다. 프로젝트 쪽을 바꿀 때만 지점을 본다 |
| callable-invoke | `cond.call()`, `sort_custom(key)` | Callable에 무엇을 담았는지는 실행 흐름이 정한다 | 그 Callable을 만든 곳을 거슬러 읽는다 |
| dynamic-method · duck-typing | `call("x")`, `has_method("forge")` | 함수 이름이 문자열이다. 이름을 바꾸면 오류 없이 조용히 어긋난다 | 이름을 바꿀 때 `query unresolved --category duck-typing` |
| dynamic-load | `load("res://data/waves/%s.tres" % r)` | 경로가 실행 중 값으로 정해진다. glob(`data/waves/*.tres`)으로만 잇는다 | 그 폴더 파일을 바꾸면 impact가 «경로 틀로 불러옴»으로 보인다 |
| reflection | `Enemy._init`의 `set(key, stats[key])`, `_kinds`의 `get_property_list()` | 데이터 정의 필드(EnemyDef.guard)가 같은 이름의 런타임 필드(Enemy.guard)로 이름 문자열을 거쳐 옮겨진다 | impact가 «동적(이름 대응)»으로 잇는다. 필드 이름을 바꾸면 양쪽을 함께 바꾼다 |
| codegen | `tests/eval/gd/show.gd`의 `BARS_SRC` | 문자열로 GDScript를 만들어 `GDScript.new()`로 실행 중에 컴파일하고 부모 함수(battle_view.gd `hp_bar_rect`)를 덮어쓴다. 문자열 안은 코드가 아니라 글이다 | 덮어쓰인 함수의 서명을 바꾸면 그 문자열도 고친다. impact가 «동적(overrides) … codegen»으로 보인다 |
| string-key | `stage["castle"]`, 저장 사전 키 | 사전 키는 문자열이라 쓰는 곳과 읽는 곳을 잇지 못한다(1,259곳, 수만 센다) | 저장 형식(save.gd)·스테이지 사전 키를 바꿀 때 Grep으로 키 이름을 찾는다 |

그 밖에 색인이 보지 않는 연결: 시그널을 람다로 이은 곳은 이은 함수까지만, 노드 경로(`$Node`·`get_node`), pytest → Godot 실행(관례 `test_X.py` ↔ `gd/X.gd`·`ev번호`로 잇는다), `tools/play/send.py` ↔ `play.gd`(파일 주고받기).

## 색인 범위

| 넣은 것 | 이유 |
|---|---|
| `src`·`tests`·`tools`의 `.gd` 전부(심볼·엣지) | 영향이 실제로 번지는 곳. sim 변경 커밋의 84%가 UI를, 19%가 봇을 함께 고쳤다(2026-11-09, 커밋 119개) |
| `tests/eval/test_*.py`의 `gd("스위트", "EV")`, conftest의 `MERGE_ONLY` | EV → pytest 파일 → 돌릴 명령 |
| `.tres`·`.tscn`·`project.godot` | 데이터 정의 필드 → tres, 장면 → 스크립트 |
| SPEC.md·EVAL.md | 문장(변경 이력·근거)·§3.1 줄 참조·EV·개정 행 |
| git 커밋 전부(HEAD 조상) + `git log -L`(질의 때) | 도입·변경 커밋과 본문의 이유 줄 |
| `insights/`·`play_review/` 문서 | 결정 근거(제목마다 잘라 BM25) |

| 뺀 것 | 이유 |
|---|---|
| `art/`·`audio/`(PNG·WAV 약 1,300개) | 코드가 아니다. `res://` 참조만 엣지로 둔다 |
| `tools/art`·`tools/audio` 파이썬 생성기의 호출 그래프 | 그림·소리를 굽는 독립 도구다. 코드 상수와의 짝(예: main.gd `WALL_T` ↔ wall.py)은 주석에만 있다 |
| `*_research/`·`enemy_guide/` | 외부 조사 자료라 채택된 결정은 SPEC에 근거와 함께 있다 |
| `handoff/` | 세션 인수인계라 커밋·SPEC과 겹치고 낡는다 |

## 한계

- SPEC §3.1 줄 참조와 `git log -L`은 HEAD 판 줄 번호를 쓴다. 고친 파일(작업 트리 ≠ HEAD)은 색인이 HEAD 판도 읽어 맞춘다. HEAD에 없는 새 함수는 커밋 히스토리가 없다.
- 얕은 복제(shallow)면 오래된 커밋이 없어 `[도입]`이 틀린다. build가 경고한다: `git fetch --unshallow`.
- §3.1 참조는 사람이 고치는 장부다. 줄이 어긋난 행이 있으면 `[SPEC]`이 엉뚱한 문장을 붙일 수 있다. 커밋의 «§3.1 줄 참조 옮김» 뒤에는 맞다.
- 브레인 자체 테스트: `python -m pytest .brain/tests -q`(루트 `pytest`는 점(.)으로 시작하는 폴더를 모으지 않아 게임 테스트와 섞이지 않는다).
