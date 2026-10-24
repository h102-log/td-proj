# 다른 게임의 조작 관례

[README](README.md)로 돌아가기. 1단계 REF 갈래가 정리했다. «일반 지식, 미확인»이라고 적힌 것은 1차 자료로 확인하지 못한 것이다. 원문 메모·URL은 [evidence/ref/notes.md](evidence/ref/notes.md).

- LoL — 선택 반경은 몸 반경과 따로이고 대부분 100(몸 반경은 대개 55~80), 선택 높이 85~302.78. 호버는 좁은 윤곽, 고른 유닛은 넓은 윤곽, 적 위 칼 커서, Target Champions Only 키, 겹치면 커서 광선에 처음 걸린 것 — https://wiki.leagueoflegends.com/en-us/Targetable , https://wiki.leagueoflegends.com/en-us/Gameplay_radius
- LoL — 시전 방식 셋(일반, 퀵캐스트, 표시기 퀵캐스트: 누르는 동안 표시·떼면 시전). 카메라 고정 토글 Y, F1 자기 선택 시 카메라 이동, Space 자기 중심(문서 안 Y·Space 설명이 섞임) — https://wiki.leagueoflegends.com/en-us/Hotkeys
- LoL — 적 공격 명령(기본 우클릭), 선딜은 다른 명령으로 끊기고 완료 직전 1틱(0.033초)만 유예, 공격 이동은 목적지로 가며 획득 범위 안 적을 찾음 — https://wiki.leagueoflegends.com/en-us/Attack_Move
- LoL — 이동 클릭 초록·공격 빨강 표시(검색 요약만, 원문 미확인). S 정지·A 공격 이동·Alt 자기 시전·우클릭 누른 채 이동은 일반 지식, 미확인.
- StarCraft II 공식 — 빈 땅 우클릭 = Move(길의 적 무시), 적 우클릭 = Attack(쫓아 부술 때까지), Stop = 모든 행동 멈춤, Hold Position = 제자리에서 사거리 안만, Attack-Move = «by far the safest way to move units» — https://news.blizzard.com/en-us/article/4552956/game-guide-basic-unit-controls
- StarCraft II 공식 — Ctrl+좌클릭 같은 종류 여럿, 더블클릭 화면 안 같은 종류, Shift+좌클릭 더하기·빼기, Shift+명령 대기열, 부대 키 두 번 = 카메라, Space = 마지막 알림 자리 — https://news.blizzard.com/en-us/article/4552955/game-guide-special-control
- StarCraft II — Confine mouse cursor 옵션, 여러 모니터에서 끄면 커서가 넘어간다는 사용자 보고 — https://us.forums.blizzard.com/en/sc2/t/mouse-confinelock-issue-affect-many-games/25941
- Warcraft III — 영웅 초상 F키 한 번 선택·두 번 카메라(ui_research/evidence/web_digest.md:115 blizzard-03 verified). 방향키 스크롤·휠 버튼 스크롤(https://www.magicgameworld.com/?p=124236, 키 안내 사이트 하나, 미대조). 땅 우클릭 초록 확인 원·공격 빨강 깜박임은 일반 지식, 미확인.
- Dota 2 — Double Tap Ability to Self Cast, Quickcast on key down/release, Smart Double Tap(Alt+키) — https://liquipedia.net/dota2/Game_Options(원문 429, 검색 요약만). 레거시 키에서는 퀵캐스트 미동작(web_digest.md:238 verified).
- Kingdom Rush — Steam판 Space = 영웅 선택, Esc = 해제(web_digest.md:242 partly). 집결 지점이 범위 밖이면 invalid 표시(web.md:283 partly). PC판 타워 버튼 호버 시 사거리·건물 미리보기(web.md:196).
- Rogue Tower QoL — 건설 모드에서 사거리 표시(ui_research web.md:427).
- Thronefall — EA 1.1부터 유닛은 명령 위치에 도착한 뒤에만 추격(이동 중 한눈팔지 않게) — game_design_research/02_control_and_economy/01_control_layers.md:127 [R2-G1-10]. S196 «걷는 영웅은 순수 이동»과 같은 방향.
- Iron Marines PC — 빈 땅 우클릭 = 도착까지 공격 안 하는 이동, 적 우클릭 = 사거리 들면 멈춰 공격(web.md:322 unverified). Space 영웅, Tab 다음 분대, S 분대 정지, Ctrl+1~5 부대(web.md:1107 unverified).
- Bad North — 분대 선택 시 감속·갈 수 있는 칸 격자(검색 요약), PC는 스페이스를 누르는 동안만 감속(web_digest.md:252 likely).
- 인지 — 지각 처리기 주기 약 100ms(50~200ms), 같은 주기 안 두 자극은 하나로 붙고 인과로 느껴짐 — https://web.mit.edu/6.813/www/sp18/classes/10-more-efficiency/
- Swink 게임 필 — «realtime control of virtual objects in a simulated space, with interactions emphasised by polish», Response = 입력을 실시간으로 처리·반응하는 방식 — https://en.wikipedia.org/wiki/Game_feel , https://www.gamedeveloper.com/design/game-feel-the-secret-ingredient (100ms·240ms 수치는 원문에 없음)
