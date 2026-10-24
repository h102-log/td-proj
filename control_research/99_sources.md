# 출처와 방법

[README](README.md)로 돌아가기.

## 1. 만든 방법(Claude 세션, 2026-10-22 22:36 ~ 10-23)

조사하는 동안 다른 세션이 같은 작업 폴더에서 S196(PR #154)을 고치고 있었다. 그래서 그 순간의 작업 트리를 `git stash create`로 떠(`f7ea2fa`) 스크래치패드에 풀었고, 읽기와 실행은 모두 그 사본에서 했다. 조사가 끝난 뒤 main `6af05d1`과 비교했더니 `src/`·`SPEC.md`는 같았다. 달라진 것은 `EVAL.md`(EV381~385 추가)·`.specgate-eval.lock`·`tools/balance/sweep.py`·`next/2026-10-22/r6.md`뿐이다.

워크플로 두 개로 에이전트 17개를 썼다.

1. **조사(8개)**: 일곱 갈래가 따로 조사했다. 입력·선택(IN), 명령 → 몸 반응(SIM), 화면 확인(FB), 카메라(CAM), 실제 조작 관찰(LIVE), 장르 관례(REF), 결정·불만 이력(HIS)이다. 여기서 finding 97개와 fact 124개가 나왔다. 통합 에이전트가 이것을 후보 51개(C-01~C-51)로 합쳤다. 갈래끼리 사실이 엇갈린 곳은 통합 에이전트가 코드를 다시 읽어 판정했다(각 후보의 «갈래 사이 엇갈림»).
2. **검증(9개)**: 후보를 여섯 묶음으로 나누고, 묶음마다 검증자 하나가 반박하는 쪽으로 다시 봤다. 볼 것은 다섯이었다. 코드와 측정 기록으로 사실을 대조하고, 체감 빈도·영향을 매기고, 더 작은 변경이 있는지 찾고, 결정론·저장·잠긴 EV·봇에 미칠 위험을 보고, SPEC 원문과 충돌하는지 확인했다. 다음으로 비판자 하나가 빠진 면을 찾아 새 후보 N-01~N-06과 우려 14개를 냈다. 새 후보는 검증자 하나가 같은 방식으로 다시 봤다. 마지막으로 우선순위 에이전트가 WBS 일정을 보고 순위·묶음·질문을 정리했다.
3. **Claude 대조**: 문서를 쓰기 전에 1순위 시뮬레이션 버그(C-27·C-28)의 코드(`src/sim/battle.gd:2237-2249`), 사거리 원 부재(C-43, `battle_view.gd`에 범위를 그리는 곳 없음), WBS 날짜를 직접 읽어 확인했다. 캡처 10장도 직접 봤다.

Godot 실행:
- 조사 단계에서만 띄웠다. 갈래마다 한 번에 하나씩 띄웠다(IN·SIM·FB·LIVE 넷이 띄웠고, CAM·REF·HIS는 띄우지 않았다). PC 블루스크린 이력이 있어 검증 단계에서는 띄우지 않고 조사 단계의 기록만 대조했다.
- IN: 헤드리스 탐침 5개(`evidence/IN/probe*.gd.txt`). 결과는 `evidence/IN/probe_out.txt`.
- SIM: 헤드리스 측정 5개(`evidence/sim/measure*.gd.txt`). 결과는 `evidence/sim/out*.txt`. `out3_mod`·`out5_mod`는 C-27 두 줄을 넣은 사본(`battle_mod.gd`, 저장소에 넣지 않음)으로 잰 것이다.
- FB: 맵 뷰 캡처 2번, 토스트 측정 1번(`evidence/FB/`).
- LIVE: `tools/play` 하네스로 창을 띄워 2판(runA 339장, runB 40장)을 했다. 고른 10장은 `captures/`에 있다. 캡처 위 글은 LIVE 에이전트가 덧붙인 설명이다.
- 일회성 스크립트는 `.gd.txt`로 바꿔 넣었다. Godot이 스캔해 `.uid`를 만들지 않게 하려는 것이다. 스크립트 안의 경로는 스크래치패드 경로다.
- 판정 비율 계산: `evidence/IN/hitavg.py`·`bbox.py`, `evidence/ref/hitbox.py`(`art/units/heroes.json` + 시트 PNG).

## 2. 웹 출처

REF 갈래는 15회, CAM 갈래는 1회 검색했다. 원문 메모는 [evidence/ref/notes.md](evidence/ref/notes.md)에 있다.

- https://wiki.leagueoflegends.com/en-us/Targetable — 선택 반경·높이, Target Champions Only
- https://wiki.leagueoflegends.com/en-us/Gameplay_radius
- https://wiki.leagueoflegends.com/en-us/Hotkeys — 시전 방식 셋, 카메라 키
- https://wiki.leagueoflegends.com/en-us/Attack_Move — 공격 명령, 선딜 끊기
- https://news.blizzard.com/en-us/article/4552956/game-guide-basic-unit-controls — SC2 Move·Attack·Stop·Hold·Attack-Move
- https://news.blizzard.com/en-us/article/4552955/game-guide-special-control — SC2 Ctrl·더블클릭·Shift·부대 키
- https://us.forums.blizzard.com/en/sc2/t/mouse-confinelock-issue-affect-many-games/25941 — 커서 가두기
- https://liquipedia.net/dota2/Game_Options — Dota 2 설정
- https://www.gfinityesports.com/dota/dota-2-how-to-self-cast-with-quick-cast/ — 자기 시전
- https://www.magicgameworld.com/?p=124236 — WC3 키(대조 안 함)
- https://www.xboxtavern.com/bad-north-review
- https://en.wikipedia.org/wiki/Game_feel
- https://www.gamedeveloper.com/design/game-feel-the-secret-ingredient
- https://web.mit.edu/6.813/www/sp18/classes/10-more-efficiency/ — 피츠의 법칙·효율

저장소 안 조사도 썼다. `ui_research/evidence/web_digest.md:115`(WC3 F키 두 번, verified)가 그 예다.

## 3. 한계

- **사람이 해 본 관찰이 아니다.** 체감(«씹혔다», «굼뜨다»)은 코드·측정·10/16 AI 관찰 기록에서 끌어낸 추정이다. 사람 관찰이 없는 후보는 4장 «구현 전에 잴 것»에 적었다.
- 하네스는 가장자리 스크롤을 끄고, 드래그를 한 프레임에 끝낸다. OS 커서와 소리는 캡처되지 않는다. 게임 시간은 `wait`에서만 흐른다.
- 편집기 빌드다. 내보낸 빌드만의 동작과 경로 계산 시간은 재지 못했다.
- 4K 전체화면(6배) 물리 픽셀과 보조 모니터 동작(C-44·C-45·C-50)은 좌표 계산만 했다.
- 장르 관례 대부분은 일반 지식이다. 1차 자료로 확인한 것은 위 URL뿐이고, 확인하지 못한 것은 [09_conventions.md](09_conventions.md)에 «미확인»으로 적었다.
- 순위의 빈도·영향은 검증 에이전트의 판단이다. 넷(C-01·C-12·C-28·C-32)은 비판자 지적으로 고쳤고, 고친 이유는 각 후보 머리에 있다.
