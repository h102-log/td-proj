# 후보 — 비판자가 더 찾은 것(N-01~N-06)

[README](README.md)로 돌아가기. 후보마다 «지금 → 문제 → 제안 → 위험·SPEC → 근거 → 검증 메모» 순서다. 줄 번호는 main 6af05d1 기준이다(조사 스냅숏과 src가 같다). 판정·빈도·영향은 반박 검증(2단계) 값이고, 순위·묶음은 [01_packages.md](01_packages.md)를 따른다. 근거의 `IN/`·`sim/`·`ref/` 경로는 [evidence/](evidence/)에 옮겨 둔 측정 기록이다(스크립트는 `.gd.txt`).

| 후보 | 판정 | 빈도·영향·비용 | 순위 | 묶음 |
|---|---|---|---|---|
| N-01 고른 영웅이 쓰러져도 Q·W·E·R이 말없이 첫 생존 영웅에게 넘어가고, 즉시 칸(아이… | 확인 | 가끔·작음·S | 결정 대기 | P7 |
| N-02 ESC가 팝업(판매·철거·성곽·시설 구매·마을 레벨)을 닫지 않고 곧장 ESC 메뉴를 … | 일부 맞음 | 가끔·작음·S | 결정 대기 | P10 |
| N-03 창이 포커스를 잃어도 전투가 계속된다(자동 일시정지 없음). 보조 모니터 클릭·Alt+… | 확인 | 가끔·중간·S | 2순위 | P9 |
| N-04 대포 옮기기에 갈 수 있는 칸 표시가 없고, 못 가는 칸을 누르면 말없이 모드만 끝난다 | 확인 | 드묾·작음·S | 3순위 | P7 |
| N-05 단축키를 바꿀 수 없고 글자(keycode) 기준이라, AZERTY 자판에서는 Q·W·… | 확인 | 드묾·중간·M | 수정 기간(11/9~30)으로 미룬다 | P12 |
| N-06 기본 공격 대상이 칠 때마다 가장 가까운 적으로 바뀐다. 실비아 패시브 중첩(S153)… | 확인 | 가끔·작음·M | 재 보고 정함 | P5 |

### N-01 고른 영웅이 쓰러져도 Q·W·E·R이 말없이 첫 생존 영웅에게 넘어가고, 즉시 칸(아이아스 W·E, 실비아 W, 세라피나 R, 크로노스 E)은 누르는 순간 발동한다

판정 **확인** · 빈도 가끔 · 영향 작음 · 비용 S · 순위 결정 대기 · 묶음 P7

- **지금**: F3으로 세라피나를 골라 싸우다 세라피나가 쓰러진 뒤 R을 누르면, 첫 출전 영웅의 R이 나간다. 첫 영웅이 아이아스면 W·E는 누르는 순간 마나와 대기를 쓴다. 첫 영웅이 세라피나이고 다른 영웅이 쓰러진 경우에는 R(기적의 강림)이 바로 나간다. 조준 칸은 조준 상태가 되고, 칩에 뜨는 다른 영웅 이름만이 단서다.
- **문제**: 쓰러진 영웅을 고른 채 손버릇으로 누른 키가 다른 영웅의 즉시 스킬(궁극기 포함)을 낭비한다. S119(사용자)는 «고른 영웅이 없으면» 첫 영웅이라고 했는데, I126(Claude)이 «고른 영웅이 쓰러진 경우»까지 넓혔다. C-03의 HUD 테두리(고른 영웅 칸 실선)가 들어오면 테두리는 쓰러진 영웅에 있는데 다른 영웅이 쓰는 모순도 생긴다.
- **제안(검증 뒤 최소안)**: 원안이 거의 최소다. (1) controls.skill_key: `var h = _hero()` 바로 다음에 `if h and not h.alive:` → `skill_keyed.emit(h, slot)` → `return`을 넣고 206행은 그대로 둔다(고른 것이 없을 때만 S119 대체). (2) hud._skill_refuse 첫 분기: `if not h.alive: why = "%s 쓰러짐" % HEROES[h.kind].get_slice("(", 0)`. 숨은 칸의 reject()는 해가 없으니 토스트만 보면 된다. en.po에 한 줄 더한다(S193). (3) controls.gd:132는 `selected.any(func(u): return u.is_hero and u.alive)`. (4) I126을 개정하고, EV231의 측정·테스트도 «고른 채 쓰러진 뒤 E → 크로노스 skill_uses 0, 알림에 «쓰러짐»»으로 개정한다. EV231은 사용자 일괄 승인이라 승인을 다시 받아야 한다. 새 EV는 원안대로 둔다(아이아스 마나·W 대기 그대로). 동작을 바꾸지 않는 대안도 있다. I126을 두고, C-03의 테두리가 실제로 키를 받을 영웅(`h if h and h.alive else _first_alive()`)을 가리키게 한다. 알려 줄 뿐 낭비는 막지 못한다.
- **영향 판단**: 네 조건이 겹쳐야 낭비가 생긴다. 고른 영웅이 쓰러졌고, 다시 고르기 전에 키를 눌렀고, 첫 생존 영웅의 같은 칸이 즉시·토글 칸이며, 그 칸이 해금(W Lv2·E Lv3·R Lv5)되고 대기·마나가 찬 상태여야 한다. 조준 칸은 칩에 다른 영웅 이름이 뜨는 조준 상태가 될 뿐이고 우클릭·ESC로 취소된다. 잃는 것은 버프 스킬의 재사용 대기 한 번이다. 가장 나쁜 경우는 세라피나 R이 먼저 나가는 것이다.
- **위험**: UI(controls·hud)만 바꾼다. battle.cast의 대체(battle.gd:809)는 그대로이고, 봇은 b.cast를 직접 부른다(autoplay.gd:555-596). 그래서 결정론·저장 재생(EV306)·저장 형식(I156)·봇에는 영향이 없다. 잠긴 EV231이 반대 동작을 재므로 개정 승인이 필요하다. EV175(고른 것이 없을 때 첫 영웅)는 그대로 통과해야 한다. C-03 테두리와 짝이 맞아야 하고(테두리를 쓰러진 칸에 둘지), C-38(칩)이 들어오면 알림 경로를 바꾼다.
- **SPEC**:
  - I126(Claude 값·추론) — «고른 영웅이 쓰러져 있으면 스킬 키는 아무도 쓰지 않고 «<이름> 쓰러짐»을 알린다. 고른 영웅이 없을 때만 살아 있는 첫 영웅이 쓴다»로 개정한다. EV231(사용자 일괄 승인 2026-10-16)도 함께 개정한다. 원문: «고른 영웅이 쓰러져 있으면 고른 영웅이 없는 것으로 본다. 고른 영웅이 없을 때 Q·W는 살아 있는 출전 영웅 가운데 첫 영웅이 쓴다»
  - S119(사용자 결정) — 문장은 그대로 둔다. 고른 영웅이 있으니 넘기지 않는 것과 어긋나지 않는다. 원문: «영웅이 여러 명이면 Q·W는 플레이어가 고른 영웅이 쓴다. 고른 영웅이 없으면 첫 영웅이 쓴다.»
- **다시 볼 EV**: EV231, EV175
- **근거**:
  - [코드] src/ui/controls.gd:205-206 `h = h if h and h.alive else battle._first_alive()`: _hero()(controls.gd:253-257)는 쓰러진 영웅도 돌려주고, 여기서 첫 생존 영웅으로 바뀐다
  - [코드] src/ui/controls.gd:221-222 aim이 self·toggle인 칸은 조준 없이 battle.cast를 바로 부른다
  - [데이터] data/heroes/aias.tres:37·47(W·E self), sylvia.tres:36(W toggle), seraphina.tres:55(R self), chronos.tres:41(E self)
  - [코드] src/sim/battle.gd:809 cast도 같은 대체를 한다
  - [코드] src/ui/hud.gd:1037-1039 쓰러진 영웅 칸은 스킬 칸을 숨기고 «쓰러짐»만 보인다. 키가 다른 영웅에게 갔다는 표시가 없다
  - [코드] src/ui/controls.gd:131-133 쓰러진 영웅만 고른 채 우클릭해도 order_move는 아무것도 하지 않는데(battle.gd:743 `if u.alive`), hero_sent는 나가서 힌트 «move»가 끝난다(hints.gd:30)
  - [SPEC] SPEC.md:568 I126([추론]): «고른 영웅이 쓰러져 있으면 고른 영웅이 없는 것으로 본다»
  - [관찰] insights/2026-10-16_first_observation.md:116-117: 두 판 모두 2웨이브에 영웅 둘이 쓰러졌다
- **검증 메모**: controls.gd:204-209를 열었다. 205 `var h = _hero()`, 206에서 쓰러졌으면 battle._first_alive()로 바꾼다. _hero()(253-257)는 alive를 보지 않는다. skill_for 221-222는 aim이 self·toggle이면 바로 battle.cast를 부른다. 데이터 줄도 맞다(aias.tres:37 W self·:47 E self, sylvia.tres:36 W toggle, seraphina.tres:55 R self, chronos.tres:41 E self). battle.gd:809도 같은 대체를 하고, hud.gd:1036-1039는 쓰러진 칸의 스킬 칸을 숨긴다. controls.gd:131-133의 hero_sent는 쓰러진 영웅이 든 선택에서도 나가고(order_move는 battle.gd:743에서 건너뜀), hints.gd:30·95-99는 지금 힌트와 상관없이 «move»를 끝낸다. 쓰러짐은 다음 준비 단계까지 이어진다(battle.gd:272·437, S27). 그래서 남은 웨이브 내내 이 상태다. **후보가 놓친 것:** EVAL.md:241 EV231(I126, 일괄 승인 2026-10-16)이 바로 이 동작을 잰다. «아이아스를 F1로 고른 채 아이아스가 쓰러진 뒤 E를 눌러도 크로노스가 쓴다»(tests/eval/gd/heroes.gd:168-182). 그래서 원안은 잠긴 EV를 뒤집는다. 덧붙여 hud._skill_refuse(hud.gd:1072)는 바뀐 영웅을 받는다. 거부 토스트(대기·마나)도 다른 영웅 기준이라 헷갈린다. 관찰 근거 insights/2026-10-16_first_observation.md:116-117은 영웅 개편(10-18) 전, 하네스에서 돌린 초보 AI의 기록이다.

### N-02 ESC가 팝업(판매·철거·성곽·시설 구매·마을 레벨)을 닫지 않고 곧장 ESC 메뉴를 연다

판정 **일부 맞음(바로잡음)** · 빈도 가끔 · 영향 작음 · 비용 S · 순위 결정 대기 · 묶음 P10

- **지금**: 팝업이 닫히는 길은 넷이다. 맵 좌클릭(빈 땅이면 닫히고, 다른 것을 누르면 그것으로 바뀐다), 팝업 버튼 실행, 놓기 키(판매·철거·성곽·거점 팝업만 닫히고, 모드를 끄려면 같은 키를 한 번 더 눌러야 한다), F1~F3(시설 선택만 풀린다)이다. ESC는 팝업을 닫지 않고 바로 ESC 메뉴를 연다. ESC·«계속»으로 돌아와도 팝업은 그대로다.
- **문제**: «닫으려고» 누른 ESC가 메뉴를 연다. 장르 관례와 다르다. C-03이 들어오면 빈 땅 클릭이 영웅 선택을 지키게 되는데, 키보드로 팝업이나 시설 선택을 걷을 길은 여전히 없다. 시설을 고른 채면 우클릭이 계속 집결 지점을 옮긴다(C-13과 같은 함정).
- **제안(검증 뒤 최소안)**: controls에 `func has_popup() -> bool: return battle.state in ["prep", "battle"] and (not selling.is_empty() or not picked.is_empty() or fort != null or facility != null or village)`를 둔다. 단계 조건은 EV372 때문에 꼭 넣는다. KEY_ESCAPE 분기는 `if placing == "" and moving == null and aiming == "":` 일 때 selling=[]·picked=[]·fort=null·facility=null·village=false로 둔다. selected·missing은 건드리지 않는다. 그 아래에 기존 세 줄을 둔다. main.gd:127 조건에 `and not controls.has_popup()`를 더한다. EV는 원안대로다(fort를 고른 뒤 ESC → fort null·paused 거짓 → ESC 한 번 더 → paused 참). missing은 목록에서 뺀다.
- **영향 판단**: 결과는 뜻하지 않은 일시정지와 메뉴다. 시간도 멈춘다. ESC를 한 번 더 누르면 돌아온다(menus.gd:140-141). 손해 없이 거슬리기만 하고, 장르 관례(KR Esc 선택 해제, ref/notes.md:8 partly)와 다르다.
- **위험**: UI만 바꾼다. 결정론·EV306·I156·봇(autoplay는 controls를 쓰지 않음)에는 영향이 없다. EV372는 단계 조건이 없으면 깨진다. EV311·EV312·EV353은 새 판이거나 selected만 넣고 시작하므로 그대로다(hud.gd:1583-1597 확인). 전투 단계에 거점만 고르고 체력이 가득해 팝업 줄이 안 보일 때는 ESC가 보이지 않는 선택(정보 칸)만 지운다. C-03(빈 땅 클릭이 영웅 선택을 지킴)과 짝이고 서로 기대지 않는다.
- **SPEC**:
  - S183(사용자 결정) — 취소 대상에 «맵 위 팝업(판매·철거·성곽·시설 구매·마을 레벨)»을 더한다. 사용자 확인이 필요하다. 원문: «조준(S147)·놓기 모드·대포 옮기기 중에 누른 ESC는 지금처럼 그것만 취소하고 메뉴를 열지 않는다.»
  - I58(Claude 값·추론) — 닫히는 조건에 «ESC»를 더한다(2026-10-21 변경의 «닫히는 조건은 그대로다»도 고친다). 원문: «빈 곳을 클릭하거나, 놓기 모드에 들어가거나, 전투가 시작되면 사라진다.»
- **다시 볼 EV**: EV311, EV312, EV353, EV372
- **근거**:
  - [코드] src/ui/controls.gd:84-87 ESC는 placing·moving·aiming만 비운다
  - [코드] src/main.gd:126-130 그 셋이 비어 있으면 ESC는 pause()로 게임을 멈추고 메뉴를 연다
  - [코드] src/ui/hud.gd:445-523 selling·picked·fort·facility·village가 남아 있는 동안 맵 위 팝업이 계속 뜬다
  - [코드] src/ui/controls.gd:128-129 시설을 고른 채면 우클릭이 유닛 이동 대신 집결 지점을 옮긴다
  - [관례] control/ref/notes.md:8 Kingdom Rush Steam판 «Esc 선택 해제»(ironhide-12, partly)
  - [SPEC] SPEC.md:358 S183(사용자 2026-10-20): ESC가 «그것만 취소»하는 대상은 조준·놓기·대포 옮기기
- **검증 메모**: 맞는 부분: controls.gd:84-87의 ESC는 placing·moving·aiming만 비운다. main.gd:126-130은 그 셋이 비면 pause()를 부른다. 메뉴에서 ESC를 누르면 «계속»이다(menus.gd:130-141). 팝업 표시는 controls.selling·picked·fort·facility·village에서 나온다(hud.gd:445-552). controls.gd:128-129에서 시설을 고른 채 우클릭하면 집결 지점이 된다. S183 원문은 SPEC.md:358에서 확인했다. 틀린 부분: «닫는 길은 빈 땅 클릭뿐», «키보드로 걷을 길 없음». 놓기 키로 모드에 들어가면 판매·철거·성곽·거점 팝업이 닫히고(hud.gd:445·457·465·491), F1~F3(pick_hero, controls.gd:169-172)는 시설 선택을 풀며, 팝업 버튼을 실행해도 닫힌다(_apply hud.gd:1162-1166). missing은 팝업이 아니라 정보 줄이다. **새 위험:** facility는 단계가 바뀌어도 비지 않는다(controls.gd:56-61). EV372(tests/eval/gd/hud.gd:2152-2175)는 전투 단계에 병영을 고른 채 «lost»까지 가서 ESC를 누른다. 단계를 보지 않는 has_popup()이면 main이 메뉴를 막는다. 그런데 controls.handle은 prep·battle이 아니면 일찍 돌아가므로(controls.gd:66-69) 결국 아무 일도 없고 EV372가 깨진다.

### N-03 창이 포커스를 잃어도 전투가 계속된다(자동 일시정지 없음). 보조 모니터 클릭·Alt+Tab 동안 거점이 깎이고, 돌아오는 클릭이 맵 명령이 된다

판정 **확인** · 빈도 가끔 · 영향 중간 · 비용 S · 순위 2순위 · 묶음 P9

- **지금**: 다른 창을 누르거나 Alt+Tab·Win 키로 나가도 웨이브가 그대로 흐른다. 돌아와서 게임 창을 누른 클릭은 맵 입력으로 들어간다.
- **문제**: 영웅 셋을 직접 조작하는 실시간 게임이라 잠깐 한눈판 시간이 그대로 손해다. C-45(커서 가두기)는 전체화면에서 커서가 나가는 길만 막고, 창 모드·Alt+Tab·알림 창은 막지 못한다.
- **제안(검증 뒤 최소안)**: main.gd에 `static var pause_on_blur := OS.has_feature("template")`를 둔다. 내보낸 빌드만 켜는 것으로, S163(내보낸 빌드만 전체화면 시작)과 같은 관례다. _notification에는 `elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and pause_on_blur and view and menus and view.battle.state == "battle" and menus.page == "": pause()`를 넣는다. 이러면 tools/play/play.gd, --write-movie 캡처, 사용자가 다른 창을 쓰는 동안 Claude가 띄운 창 캡처를 하나도 고치지 않아도 된다. EV는 Main.pause_on_blur = true로 둔 뒤 main.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)을 보낸다. 전투면 paused 참·menus.page «pause», 준비면 거짓이다. 편집기 빌드에서도 체감시키려면 기본값을 true로 두되, play.gd에서 끄고 무비 모드 가드 `Engine.get_write_movie_path().is_empty()`를 더한다(원안 + 1줄).
- **영향 판단**: 영웅 셋을 실시간으로 다루는 게임이라 Alt+Tab·보조 모니터 클릭 동안 거점과 영웅이 깎인다. 1번 PC처럼 모니터가 둘이면 더 잦다. 단, 타워·용병·영웅 자동 공격은 계속 돌아 손실은 몇 초 분량이다.
- **위험**: main(UI)만 바꾼다. 결정론·EV306·I156·봇(headless)에는 영향이 없다. 기본값을 true로 두면 창으로 띄우는 개발 도구(play.gd 하네스, --write-movie, 화면 캡처)가 포커스를 잃는 순간 ESC 메뉴로 덮인다. 원안은 play.gd만 막는다. 기본값을 template으로 두면 이 위험이 없어지지만, 사용자가 편집기 빌드로 할 때는 체감하지 못한다. C-45(커서 가두기)를 보완할 뿐 대신하지 않는다.
- **SPEC**: 바뀌는 문장 없음(새 I 항목만)
- **근거**:
  - [코드] src/main.gd:114-116 _notification은 WM_CLOSE_REQUEST만 본다. src 전체에서 포커스 알림 처리는 0건이다(grep NOTIFICATION_·focus_exited)
  - [코드] src/main.gd:69-72 _process가 포커스와 상관없이 battle.step을 부른다
  - [코드] src/ui/camera.gd:31-33 포커스가 없으면 가장자리 스크롤만 멈춘다. 포커스를 보는 곳은 이것뿐이다
  - [코드] src/main.gd:86-89 pause()(ESC 메뉴 + 트리 멈춤)는 이미 있다
  - [후보] C-45의 current·problem: 1번 PC 전체화면에서 커서가 오른쪽 보조 모니터로 넘어가고, 거기를 누르면 포커스를 잃는데 «전투는 계속»
  - [메모] pc1-display: 주 모니터 4K + 보조 FHD
  - [추론, 실행 확인 안 함] Windows에서 비활성 창을 누른 첫 클릭도 게임에 전달된다. 그러면 놓기 모드에서는 그 칸에 짓고, 아니면 C-03처럼 선택이 풀린다
- **검증 메모**: main.gd:114-116 _notification은 WM_CLOSE_REQUEST만 본다. src 전체에서 NOTIFICATION_·focus_exited·has_focus를 grep하면 main.gd:115와 camera.gd:32 둘뿐이다. main.gd:69-72 _process는 포커스와 상관없이 battle.step을 부르고, project.godot에도 관련 설정이 없다. pause()는 main.gd:86-89에 있다. menus.gd:26-27의 _dim은 ColorRect라 기본 mouse_filter가 STOP이다. C-45 problem에 «전투는 계속»이 있다. «비활성 창을 누른 첫 클릭이 게임에 들어간다»는 실행 기록이 없다(control/ 아래에 포커스 관련 기록 0건). 추론으로 남는다. 평가는 headless로 돈다(tests/eval/conftest.py:35). 그래서 포커스 알림은 평가에 닿지 않는다.

### N-04 대포 옮기기에 갈 수 있는 칸 표시가 없고, 못 가는 칸을 누르면 말없이 모드만 끝난다

판정 **확인** · 빈도 드묾 · 영향 작음 · 비용 S · 순위 3순위 · 묶음 P7

- **지금**: «옮기기»를 누르면 팝업이 바로 닫히고 칸 표시 없이 모드가 된다. 못 가는 칸(유닛·적이 선 칸, 마을 칸, 성문·출전 칸 등)을 누르거나 그때 놀고 있는 공병이 없으면, 아무 표시 없이 모드만 끝난다.
- **문제**: 옮기기는 전투 단계에만 된다(battle.gd:1699). 싸움터 가까운 칸에는 유닛·적이 서 있기 쉬워 거부가 잦다. 거부되면 대포를 다시 골라 팝업부터 다시 해야 한다. 판정은 놓기 모드(I128·I138)와 같은 규칙인데 표시만 빠졌다.
- **제안(검증 뒤 최소안)**: (1) controls.gd:110-114 좌클릭 분기: `var cell := Vector2i((event.position / cell_px).floor())` → `battle.move_cannon(moving, cell)` → `if moving.dest != cell: refused.emit(cell, "옮길 수 없는 칸"); return`. 결과로 판정하므로 placeable_cells와 중복이 없고 공병이 없는 경우도 잡는다. (2) hud.gd:420을 `if controls.moving and not refusing:`으로 바꾼다. 이게 없으면 이유가 보이지 않는다. (3) battle_view._marks: `var kind: String = controls.placing if controls.placing != "" else ("cannon" if controls.moving else "")`로 칠하기를 넓힌다. 격자선은 S169 때문에 넓히지 않는다. (4) en.po에 한 줄을 더한다. EV는 원안대로 둔다(적이 선 칸 → s.dest null·moving 유지·hint에 이유).
- **영향 판단**: 대포 옮기기는 전투 단계에만 쓰는 드문 조작이다(봇도 쓰지 않음). 거부되면 대포를 다시 골라 «옮기기»부터 다시 하는 정도로 손해가 작다.
- **위험**: UI만 바꾸고 move_cannon은 그대로다. 결정론·EV306·I156·봇에는 영향이 없다. 매 프레임 placeable_cells("cannon")을 부르는 비용은 놓기 모드와 같다(_taken을 한 번만 모음). EV105(성공 경로에서 모드 종료)는 그대로다. EV374(영어 칩 폭)에는 새 글을 넣어 확인한다. hud 글 순서를 바꿔도 놓기 거부(EV359)에는 영향이 없다.
- **SPEC**:
  - I138(Claude 값·추론) — 대포 옮기기(S91) 중에도 옮길 수 있는 칸을 같은 방식으로 칠한다. 원문: «놓기 모드(S45의 «건설할 것을 고르면»)에는 지금 그 지시가 받아들여지는 칸을 모두 엷게 칠한다.»
  - I128(Claude 값·추론) — 대포 옮기기 거부에도 ✕와 «옮길 수 없는 칸»을 보이고, 옮기기 모드는 이어 간다. 원문: «준비·전투 단계에 구조물 놓기가 어떤 이유로든 거부되면 그 칸에 빨간 ✕를 0.5초 그리고 안내 줄 글을 1.5초 첫 이유로 바꾼다.»
  - S169(사용자 결정) — 그대로 둔다. 격자선은 넓히지 않는다. 원문: «격자선은 놓기 모드(I138)에서만 그린다.»
- **다시 볼 EV**: EV105, EV374
- **근거**:
  - [코드] src/ui/controls.gd:110-114 moving 중 좌클릭은 결과와 상관없이 moving = null로 둔다
  - [코드] src/sim/battle.gd:1698-1700 move_cannon은 반환값이 없고, _buildable이 거짓이면(유닛·적이 선 칸, 마을 칸, 성문 칸 등, battle.gd:1455-1465) 그냥 돌아간다
  - [코드] src/ui/battle_view.gd:74-79·292-294 격자선과 놓을 수 있는 칸 칠하기는 placing일 때만 그린다
  - [코드] src/ui/controls.gd:262-265 구조물 놓기는 거부 이유를 refused로 알리지만(I128) 대포 옮기기에는 이 길이 없다
  - [코드] src/ui/hud.gd:420-421 안내 칩은 «대포 옮길 칸: 좌클릭»뿐이다. hud.gd:1180-1182 _start_move가 picked를 비운다
- **검증 메모**: controls.gd:110-114에서 moving 중 좌클릭은 결과와 상관없이 moving = null이다. battle.gd:1698-1705 move_cannon은 void다. 단계·종류·can_demolish·_buildable(1455-1465)에서 거부되면 말없이 돌아가고, 놀고 있는 공병이 없을 때(1701-1702)도 말없이 끝난다. 이 마지막 경우는 후보가 빠뜨렸다. placeable_cells는 1475-1486이다. battle_view.gd:74-79의 격자선과 292-294의 칸 칠하기는 placing일 때만 그리고, battle_view에 controls.moving 사용은 0건이다(grep). refused는 구조물 놓기에서만 낸다(controls.gd:262-265). 안내 칩은 hud.gd:420-421이다. 작은 차이: 팝업은 «옮기기»를 누르는 순간 이미 닫힌다(_start_move hud.gd:1180-1182). **원안 EV가 그대로는 실패한다:** hud.gd:413-421에서 refusing 글을 넣은 뒤 `if controls.moving:`이 «대포 옮길 칸…»으로 덮어쓴다. moving을 유지하면 hud.hint에 «옮길 수 없는 칸»이 남지 않는다.

### N-05 단축키를 바꿀 수 없고 글자(keycode) 기준이라, AZERTY 자판에서는 Q·W·E·R·A 자리가 흩어진다

판정 **확인** · 빈도 드묾 · 영향 중간 · 비용 M · 순위 수정 기간(11/9~30)으로 미룬다 · 묶음 P12

- **지금**: QWERTY에서는 Q·W·E·R이 한 줄이다. AZERTY(프랑스·벨기에)에서는 글자 Q가 QWERTY의 A 자리, W가 Z 자리에 있어 스킬 넷이 흩어지고, 이동 방식 키 A가 QWERTY의 Q 자리에 온다. 바꿀 방법이 없다.
- **문제**: 영어판으로 나가는 스팀에서 AZERTY 사용자는 스킬 키를 쓰기 어렵다. 한국어·영어(QWERTY) 사용자에게는 문제가 없다. 근거는 Godot 문서이고 실행으로 확인하지 않았다. 출시 전 우선순위는 낮다.
- **제안(검증 뒤 최소안)**: 11/30 이후로 미룬다. 최소안: controls.handle 머리에 `var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode`를 두고, match·SKILL_KEYS·PLACE_KEYS·F1 오프셋을 이 key로 바꾼다. 실제 입력에는 둘 다 들어 있으니 물리 자리로 고정되고, keycode만 넣는 테스트 헬퍼 14곳은 고치지 않아도 된다. 표기는 스킬 칸 글자·태그 A/H·건설 칸 [키]만 DisplayServer.keyboard_get_label_from_physical로 바꾼다. 힌트·툴팁 글(«Q로 영웅 스킬…», «F1») 속 키 글자는 나중에 다룬다. 리바인딩 화면은 만들지 않는다.
- **영향 판단**: AZERTY(프랑스·벨기에) 사용자만 겪는다. 대신 그들에게는 매 판 Q·W·E·R·A가 흩어져 OS 배열을 바꾸지 않는 한 우회할 길이 없다. 스팀 전체 비중은 작다(수치 미확인).
- **위험**: UI 입력·표기만 바꾼다. 결정론·EV306·I156에는 영향이 없고, 봇은 battle API를 직접 써서 영향이 없다. 헬퍼를 고치는 길을 고르면 11개 eval 스위트를 다시 돌린다. 대체 한 줄을 쓰면 테스트는 그대로다. 영어 글(en.po)에 박힌 키 글자는 AZERTY 표기와 어긋난 채 남는다. C-11(S 정지)이 들어오면 같은 표에 넣는다.
- **SPEC**:
  - I10(Claude 값·추론) — «단축키는 자판 자리(QWERTY 기준)로 정해지고, 화면 키 글자는 그 자판의 글자로 보인다»를 덧붙인다. 원문: «영웅 스킬은 키보드 단축키로도 쓸 수 있다.»
  - S193(사용자 결정) — 바꾸지 않는다. 다만 번역 글에 박힌 키 글자는 자판 배열에 따라 바뀐다는 메모가 필요하다. 원문: «게임 안의 글은 한국어와 영어 둘이다.»
- **다시 볼 EV**: EV374, EV372, EV259, EV314, EV175, EV231
- **근거**:
  - [코드] src/ui/controls.gd:19-20 SKILL_KEYS·PLACE_KEYS와 :70-87 `match event.keycode`는 모두 keycode 기준이다(Godot 문서: keycode는 현재 자판 배열의 글자, physical_keycode는 US QWERTY 자리)
  - [코드] src/settings.gd:4-11와 src/ui/menus.gd:67-101 설정에 키 항목이 없다
  - [SPEC] S193(사용자) 영어 지원, 스팀 전역 출시
  - [코드] tests/eval/gd 10개 파일 19곳이 InputEventKey.keycode만 넣는다. physical_keycode를 넣는 곳은 tests/eval/gd/hud.gd:1310·save.gd:57·tools/play/play.gd:111뿐이다
- **검증 메모**: controls.gd:19-20의 SKILL_KEYS·PLACE_KEYS와 70-88의 `match event.keycode`가 모두 keycode 기준이다. main.gd:122·126(F11·ESC)도 keycode이지만, 이 두 키는 자판 배열이 달라도 자리가 같다. settings.gd:4-11과 menus.gd:67-101에는 키 항목이 없다. physical_keycode를 grep하면 hud.gd:1310·save.gd:57·play.gd:111·tests/unit/gd/test_map_viewport_input.gd:82가 나온다. **개수 정정:** keycode만 넣는 곳은 «10개 파일 19곳»이 아니라 eval 11개 파일에 한 줄씩 11곳이다(cannon:42, heroes:73, hire:31, house:20, kits:40, levels:33, menu:180, rounds:53, show:27, units:111, village:22). hud·menu 스위트의 _key는 save.gd를 물려받아 둘 다 넣는다. 여기에 unit 3곳(test_hero_skill_hits_nearby:12, test_map_viewport_input:81, test_place_mode:9)이 더 있다. AZERTY에서 키가 흩어진다는 것은 Godot 문서(keycode는 현재 배열의 Latin 글자)에 따른 것이고 실행으로 확인하지 않았다. QWERTZ는 Y·Z만 바뀌어 상관없다. 한국어 두벌식은 QWERTY 자리라 문제가 없다.

### N-06 기본 공격 대상이 칠 때마다 가장 가까운 적으로 바뀐다. 실비아 패시브 중첩(S153)이 끊기고, 휘두르는 방향이 번갈아 바뀔 수 있다

판정 **확인** · 빈도 가끔 · 영향 작음 · 비용 M · 순위 재 보고 정함 · 묶음 P5

- **지금**: 실비아 사거리 4 안으로 적이 여럿 지나가면 더 가까운 적이 생길 때마다 대상이 바뀌어 중첩이 0으로 돌아간다. 플레이어가 대상을 정할 방법(C-10)도 없다. 양옆에 적이 붙은 근접 유닛은 밀릴 때마다 가까운 쪽이 바뀌어 휘두르는 방향이 오갈 수 있다(재지 않음).
- **문제**: 사용자가 승인한 패시브가 실전에서는 쌓이지 않을 수 있다. 롤·워크3의 자동 공격은 대상이 죽거나 사거리를 벗어날 때까지 그 대상을 유지하는데(일반 지식), 이와도 다르다. «휘적휘적»의 남은 원인일 수 있다는 것은 가설이다.
- **제안(검증 뒤 최소안)**: 먼저 잰다. headless 스크립트로 r6 배치에서 실비아 기본 타격 가운데 foe != u.mark 비율과 5중첩에서 친 타격 비율을 센다. 높으면 가장 작은 안을 쓴다. _nearest_enemy에 `keep = null` 인자를 더하고, 맨 앞에 `if keep and keep.alive and keep.pos.distance_to(from) <= reach and keep.pos.distance_to(center) <= zone and (keep.on_wall or not on_wall): return keep`를 둔다. 2215·2218에서는 `u.mark`를 넘긴다. mark는 실비아만 쓰므로 다른 유닛·영웅·타워(I29)의 동작이 바뀌지 않고, Q가 정한 mark도 지킨다. 모든 유닛이 대상을 유지하게(u.target) 넓히는 것은 측정 뒤 따로 정한다. EV: 실비아가 3칸 앞 적 A를 한 번 친 뒤 적 B를 2칸에 두면 다음 타격도 A이고 중첩이 1이다.
- **영향 판단**: 실비아를 낸 판에서 사거리 안에 적이 여럿 움직일 때만 생긴다. 중첩은 화면에 보이지 않아 플레이어가 알아채기 어렵다. 적이 6타 전에 죽으면 대상 유지와 상관없이 중첩이 의미가 없다. 근접 유닛의 방향이 오가는 것은 실제로 친 적을 보는 올바른 그림이다. «휘적휘적»의 원인이라는 것은 가설이다.
- **위험**: 시뮬레이션(battle.gd)을 바꾼다. 규칙은 결정적이라 결정론은 유지되지만 전투 결과가 바뀐다. EV306: target·mark는 저장하지 않는데(save.gd:13), 저장은 준비 단계에만 하고 mark는 웨이브 끝에 비우며 keep에 alive 조건이 있어 재생은 같다. 봇 논리는 대상 선택에 기대지 않지만, sweep 밸런스 수치는 움직인다. sweep을 도는 동안에는 final·봇 수정이 금지다. 실비아 EV273~275, 영웅 EV20·EV246·EV383~385를 다시 돌린다. C-10(focus)이 들어오면 focus가 keep보다 먼저다. battle.gd 줄이 밀리면 SPEC §3.1의 «파일:줄»(S15 → battle.gd:2201 등)도 같은 변경에서 옮긴다.
- **SPEC**:
  - S153(사용자 결정) — 바꾸지 않는다. 대상 유지는 문장대로 쌓이게 돕는다. 전투 수치가 바뀌니 사용자에게 한 줄 확인한다. 원문: «(개인) 기본 공격이 직전과 같은 적이면 중첩 +1(최대 5), 다른 적이면 0.»
  - I29(Claude 값·추론) — 그대로 둔다(타워는 keep을 쓰지 않음). 유닛 대상 유지는 새 I [추론]으로 둔다. 원문: «공격 타워는 사거리 안에서 가장 가까운 적을 쏜다.»
- **다시 볼 EV**: EV273, EV274, EV275, EV20, EV246, EV383, EV384, EV385, EV306
- **근거**:
  - [코드] src/sim/battle.gd:2215·2218 서 있는 영웅·용병은 매 틱 _nearest_enemy로 대상을 다시 고르고 직전 대상(u.target)은 보지 않는다. :2258-2261에서 칠 때마다 u.target = foe
  - [코드] src/sim/battle.gd:2289-2291 실비아 약점 포착: foe가 u.mark와 다르면 중첩이 0이 된다
  - [SPEC] SPEC.md:294 S153 패시브(사용자 2026-10-18 기획서): «직전과 같은 적이면 중첩 +1(최대 5), 다른 적이면 0. 5중첩이면 양수 방어력 35% 무시»
  - [코드] src/ui/battle_view.gd:496·525 공격 자세는 x.target 쪽을 본다. 대상이 바뀌면 다음 휘두름은 다른 쪽을 향한다
  - [측정 공백] next/2026-10-22/r6.md §0의 측정은 «대상이 아닌 쪽을 봄»만 셌고 대상이 바뀐 횟수는 재지 않았다
- **검증 메모**: battle.gd:2215·2218은 매 틱 _nearest_enemy로 대상을 고르고 u.target을 보지 않는다. 2258-2261은 칠 때 u.target = foe다. 2290-2291에서 foe가 u.mark와 다르면 중첩이 0이 된다. S153 원문은 SPEC.md:294, 공격 자세 방향은 battle_view.gd:496·525다. 대상이 바뀌는 횟수나 5중첩 도달률은 control/sim/out*.txt·IN·live 어디에도 재지 않았다(grep). 그래서 «쌓이지 않는다»는 정도는 확인되지 않았다. **원안 정정:** ① Q가 mark를 정한다(battle.gd:1247-1248, «첫 적은 직전 대상이 되고 중첩 3 이상»). keep을 u.target으로 주면 Q가 준 mark가 다음 기본 공격에서 버려진다. ② 새 대상의 첫 타격은 중첩 0이다(I148, EV273). 그래서 원안 EV «A를 한 번 친 뒤 … 다음 타격도 A이고 중첩이 2»는 틀렸고 1이 맞다. ③ battle.gd:2201 주석의 «영웅은 걷는 동안에도 친다»는 S196 뒤로 낡았다. ④ save.gd:13 SKIP에 target·mark가 있고, mark는 웨이브가 끝나면 비운다(battle.gd:1083).
