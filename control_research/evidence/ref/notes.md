# REF 갈래 조사 메모 — 같은 조작 구조 게임들의 조작감 관례 (2026-10-22)

WebSearch 15회 사용(상한 25). 스냅숏 코드만 읽었고 Godot은 띄우지 않았다(동시 실행 상한·sweep 겹침 회피).

## 1. 저장소 안 기존 조사에서 가져온 것(다시 검색 안 함)

- WC3: 영웅 초상 F키 한 번 = 선택, 빨리 두 번 = 카메라 [blizzard-03·verified] — ui_research/evidence/web_digest.md:115
- KR Steam판: 1·2 주문, Space 영웅, W 다음 웨이브, Esc 선택 해제 [ironhide-12·partly] — web_digest.md:242
- KR 병영 집결: 링 메뉴 집결 버튼 → 범위 타원 표시 → 범위 안·길 근처만 받고 아니면 invalid 표시 [ironhide-03·partly, 코드 대조] — web_digest.md:68, web.md:281-284
- KR 영웅: 영웅이나 초상을 누른 뒤 목적지 지정, KR5는 드래그 이동 [R2-G1-4] — game_design_research/04_benchmarks/01_game_cards.md:54
- Thronefall EA 1.1: 유닛은 명령 위치에 도착한 뒤에만 추격(«명령에 더 엄격히, 이동 중 한눈팔지 않게»), 데모 0.85 위치 고수 [R2-G1-10] — game_design_research/02_control_and_economy/01_control_layers.md:127
- Iron Marines PC: 빈 땅 우클릭 = 도착까지 공격 안 하는 이동, 적 우클릭 = 사거리 들면 멈춰 공격 [ironhide-17·unverified]; Space 영웅·Tab 다음 분대·S 분대 정지·M 빠른 시전 [ironhide-18·unverified] — web.md:322, 1107
- Iron Marines: 눌러 고르고 끌어서 목적지, 이동 중엔 지나가는 적 무시 [ironhide-16·likely] — web_digest.md:72
- Bad North PC: 스페이스 누르는 동안만 감속 [minimal-13·likely] — web_digest.md:252
- Dota 2: 레거시 키에서는 퀵캐스트 안 됨 [p_cooldown_hotkey-11·verified] — web_digest.md:238

## 2. 이번 검색·열람 원문 메모

### LoL — 선택 판정 (https://wiki.leagueoflegends.com/en-us/Targetable)
- selection radius: «the horizontally furthest point from the center of their model that other players' cursor is allowed to be». selection height도 따로.
- 커서에서 광선: 모델 → 가로·세로 선택 면 → 땅 순서로 본다. 우선순위 규칙은 없고 «처음 걸린 것».
- 값: 챔피언 대부분 100(이리·조이 등), 리신 102.78, 아우렐리온 솔 150. 선택 높이 85~302.78. 크기 변화와 무관.
- 커서를 올린 유닛 = 좁은 윤곽 + 왼쪽 위 대상 틀, 고른 유닛 = 넓은 윤곽. 스킬로 대상 지정하면 윤곽이 잠깐 맥박.
- «While an enemy unit is selected ... the cursor transforms into a sword.» «While an allied unit is selected, the cursor gem becomes blue.»
- Target Champions Only: 누르는 동안 커서가 챔피언만 고른다.

### LoL — 게임 반경 (https://wiki.leagueoflegends.com/en-us/Gameplay_radius)
- 챔피언 게임 반경 대부분 55~80, 표적 허수아비 65(대부분 챔피언과 같음). 선택 반경·높이·길찾기 반경은 크기와 무관.
- → 선택 반경(100)이 몸 반경(65)의 약 1.5배, 거기에 모델 자체와 선택 높이가 더해진다.

### LoL — 단축키·시전 방식 (https://wiki.leagueoflegends.com/en-us/Hotkeys)
- Normal cast: 키 → 표시 → 좌클릭 확정. 이동·공격·펫 이동 명령이나 Esc로 취소.
- Quick cast: 누르는 순간 커서 자리.
- Quick cast with indicator: «The ability's indicator will appear upon pressing and holding the button, and fire only when the button is released». 취소는 일반 시전과 같다.
- 카메라: Toggle Camera Lock 기본 Y. Select Self F1, Select Ally F2~F5로 카메라가 즉시 그 챔피언에게. Space로 자기 위 중심(문서 안에서 Y와 Space 설명이 섞여 있음).
- 2009 패치 노트: 정지 V, 홀드 H(옛 값). 지금 기본 S·A·Alt는 이 문서에서 확인 못 함 → 일반 지식.
- 검색 요약(원문 미확인): 이동 클릭은 초록 표시(색약 모드 파랑), 공격은 빨강(색약 모드 주황).

### LoL — 기본 공격·공격 이동 (https://wiki.leagueoflegends.com/en-us/Attack_Move)
- 공격 명령(기본 우클릭)으로 적에게 기본 공격.
- 선딜은 «Attacker is issued a different command»면 끊긴다. 선딜 완료 직전 1틱(0.033초) 유예 동안은 이동·홀드·정지로 못 끊는다.
- 공격 이동: 목적지로 가며 획득 범위 안 적을 찾는다. 일반 공격 이동은 사거리 표시가 보이고, 공격 이동 클릭은 안 보인다.
- 획득 범위는 가장자리끼리 잰다. 공격 속도 상한 3.003.

### SC2 — 기본 유닛 조작 (https://news.blizzard.com/en-us/article/4552956/game-guide-basic-unit-controls)
- Move: 가는 길의 적을 무시, 공격받아도 반응 안 함.
- Stop: 지금 행동을 모두 멈춘다(원거리 유닛을 세워 바로 쏘게).
- Hold Position: 제자리, 사거리 안만 쏜다. 쫓게 하기 싫으면 Stop 말고 Hold.
- Attack(-Move): 가는 길의 적과 싸운다. «by far the safest way to move units».
- 빈 땅 우클릭 = Move. 적 우클릭 = Attack 명령과 같다. 대상을 빗맞혀 땅을 찍으면 Move.

### SC2 — 특수 조작 (https://news.blizzard.com/en-us/article/4552955/game-guide-special-control)
- Ctrl+좌클릭 = 같은 종류 여럿, 더블클릭 = 화면 안 같은 종류 전부.
- Shift+좌클릭 = 더하기·빼기. Shift를 누른 채 명령 = 대기열(웨이포인트).
- 부대 키 빨리 두 번 = 카메라가 그 부대로. Backspace = 본진 돌기. Space = 마지막 알림 자리(최대 8개 돌기). F1 놀고 있는 일꾼, Ctrl+F1 전부.
- 빈 땅 좌클릭이 선택을 푸는지는 이 글에 없다 → 확인 못 함.

### WC3 — 카메라 (https://www.magicgameworld.com/?p=124236)
- 방향키로 화면 스크롤, 휠 버튼 누른 채 스크롤. 부대 번호 두 번 = 카메라. (키 안내 사이트 하나, 게임 안 대조 못 함)
- WC3 초록 확인 원·빨강 대상 깜박임은 검색 2회로 원문을 못 찾음 → 일반 지식, 미확인.

### Dota 2 — 설정 (https://liquipedia.net/dota2/Game_Options, 원문 429로 못 열고 검색 요약만)
- Double Tap Ability to Self Cast(+두 번 누름 제한 시간), Quickcast on key down/release, Smart Double Tap(Alt+키 = 두 번 누름), Quick Attack·Quick Move.
- https://www.gfinityesports.com/dota/dota-2-how-to-self-cast-with-quick-cast/ 도 같은 내용(검색 결과 제목만).

### 게임필·지각
- MIT 6.813 (https://web.mit.edu/6.813/www/sp18/classes/10-more-efficiency/): 지각 처리기 주기 T_p ≈ 100ms [50~200ms]. «Two stimuli within the same PP cycle appear fused», 이 융합이 인과 지각에 강하게 작용한다.
- Swink 정의(https://en.wikipedia.org/wiki/Game_feel): «realtime control of virtual objects in a simulated space, with interactions emphasised by polish». 위키 본문에 100ms 수치는 없다.
- Swink 2007 가마수트라 글(https://www.gamedeveloper.com/design/game-feel-the-secret-ingredient): Response = «How the system processes, modifies, and responds to player input in real time». 100·240ms 수치는 이 글에 없다. 100ms·240ms는 2차 자료(바이로이트대 강의 PDF, 접속 거부)에서만 봄.

### 실패·빈손 검색
- Kingdom Rush 영웅 이동 표시(검색 1회): 관련 원문 없음.
- Iron Marines 우클릭(검색 1회): 키 목록만(Space 영웅, Tab 다음 분대, S 정지, Ctrl+1~5).
- Bad North 이동 미리보기(검색 1회): 분대를 고르면 게임이 느려지고 갈 수 있는 칸 격자가 덮인다(https://www.xboxtavern.com/bad-north-review 요약). 호버 목적지 미리보기는 확인 못 함.
- LoL 우클릭 누르고 있기(검색 1회): 저품질 자료뿐. 일반 지식으로만 둔다.
- 이동 마커 색 관례 일반(검색 1회): 원문 없음.

## 3. 코드에서 직접 잰 것

`hitbox.py`(이 폴더): heroes.json·heroes.png의 정지(남) 프레임 불투명 픽셀.

| 종류 | 그림 높이 | 발밑 위 | 클릭 칸(발밑 ±8px) 안 | 조준 0.7칸 원 안 |
|---|---|---|---|---|
| aias | 19 | 16 | 67.5% | 83.8% |
| sylvia | 16 | 13 | 71.9% | 90.4% |
| seraphina | 16 | 14 | 66.0% | 84.0% |
| vesper | 17 | 15 | 60.0% | 77.0% |
| ignis | 18 | 16 | 61.8% | 80.3% |
| chronos | 16 | 14 | 69.2% | 91.6% |
| soldier | 15 | 13 | 65.0% | 84.3% |
| archer | 17 | 14 | 70.9% | 89.2% |
| armored | 17 | 15 | 54.8% | 75.6% |
| boss | 21 | 18 | 37.6% | 49.2% |

- 클릭 칸 값은 영웅이 칸 가운데에 정확히 섰을 때다. 칸 사이에 서 있으면 판정 칸이 발밑에서 최대 8px 어긋난다.
- 몸 반지름 0.3칸 = 4.8px(hero_def.gd:9). 판정 칸 반폭 8px는 몸 반지름의 1.67배로 롤(100/65 ≈ 1.5)과 비슷하지만, 위쪽(머리)으로는 늘어나지 않는다. 롤은 모델 자체와 선택 높이 85~302를 더한다.
