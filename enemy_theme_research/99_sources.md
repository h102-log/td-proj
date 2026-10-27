# 99. 출처와 주장 대장

본문이 인용한 `[W-NN]`·`[A-NN]`·`[B-NN]`·`[C-NN]`·`[V…]`의 원장이다.

## 1. 만든 방법

| 단계 | 누가 | 결과 |
|---|---|---|
| 1차 deep-research 워크플로 | 검색 각도 5개(분열 수치 / 도약·훔치기·낚아채기 / 실패·수정 / 라운드 짜임 / 보스 예고) | 검색 결과 30개(W-01~30). 원문 읽기 22개가 모두 실패해 주장 추출 0, 3표 검증 단계에 가지 못했다. 그래서 W는 **검색 에이전트가 쓴 요약**이다 |
| 보충 A | Q1 나머지 기믹(늑대·공성·언데드·사망 폭발·감염·밤·주민 노리기) | 주장 25개, WebSearch 14번 |
| 보충 B | Q2 라운드 짜임·Q3 보스 | 주장 23개, WebSearch 14번 + GitHub 비공식 사본 4건 |
| 보충 C | Q5 원작·Q6 가독성 | 주장 16개, WebSearch 14번 |
| 반박 검증 V | 라인업 근거가 되는 핵심 주장 15개 | 원래 검색과 다른 각도로 WebSearch 16번 |
| 저장소 Q7 | 메인 세션 | `07_sim_mapping.md`. 코드·데이터·SPEC 판독 |

- **원문을 열지 못했다.** 이 환경의 네트워크 정책이 `*.fandom.com`·`bloonswiki.com`·`*.wiki.gg`·`namu.wiki`·`thewiki.kr`·`en.wikipedia.org`·`web.archive.org`·`lospec.com`·`reddit.com`·`novelupdates.com` 등을 막았다(에이전트 프록시 403, WebFetch `getaddrinfo ENOTFOUND`). 그래서 웹 주장의 «확인» 칸은 거의 모두 «검색 요약만»이다. 따옴표 안 문장은 검색 도구의 요약이 출처에서 옮겨 왔다고 보인 문장이고, 원문과 한 글자씩 대조하지 못했다.
- **GitHub 비공식 사본**: 보충 B는 GitHub 코드 검색으로 찾은 공개 저장소 4곳의 파일을 받아 직접 셌다. Slay the Spire 디컴파일 코드(`Voyage-for-the-ideal/aiplayspire`), Into the Breach 게임 Lua 스크립트 사본(`Win-KemaAlexArt/Into-the-Breach-Reference`), Plants vs. Zombies 디컴파일 재구현(`Patoke/re-plants-vs-zombies`), Kingdom Rush 1 웨이브 데이터가 든 모드 저장소(`DanQZ/KR1-Smarter-Soldiers-Mod`)다. 판 번호를 모르고 모드가 데이터를 고쳤을 수 있다. 이 조사 문서에는 코드 줄을 옮기지 않고 규칙·수만 적었다. 이 사본들은 이 작업 세션이 GitHub에서 다루기로 한 저장소 범위 밖이었다.
- 대장 표(4장)는 스크래치패드의 조사 파일에서 스크립트로 뽑았다. 조사 파일은 이 세션이 끝나면 남지 않으니, 이 표와 본문 인용이 기록이다.

## 2. 반박 검증 V 요약

라인업의 근거가 되는 주장을 반박하는 쪽으로 다시 검색했다. 판정은 확인(다른 출처가 같은 내용) / 부분 확인(맞지만 범위·수치를 고쳐야 함) / 엇갈림(출처끼리 다르고 가를 수 없음) / 반박 / 판단 불가(근거를 못 찾음)다. 본문은 부분 확인의 «고친 문장»을 따랐다.

| ID | 다룬 주장 | 판정 | 한 줄 |
|---|---|---|---|
| V1 | W-02·W-23 | 부분 확인 | Umbrella 3×3(8칸)·식물 훔치기는 확인. 과녁·3초 체공·450 피해는 둘째 출처 없음 |
| V2 | W-11·W-12 | 부분 확인 | 위키 «골드 없음 예외 목록»은 맞음. Spider Hatchling은 iOS·Flash에서 1골드라 «늘 0»이 아님. Gloomy·Spectral Knight는 둘째 출처 없음 |
| V3 | W-07 | 부분 확인 | 체력 60(Fortified 120)은 81라운드부터의 Super Ceramic 값. 일반 Ceramic은 10(20)·RBE 104(114). MOAB 616 = 200 + 4×104 |
| V4 | W-01 | 부분 확인 | 낙하·천천히 귀환·재탈취는 확인. 비행 유닛이 가져간 코어 «unrecoverable»은 둘째 출처 없음 |
| V5 | W-21 | 부분 확인 | 같은 서술이 팬 위키 한 곳에만 있고 1차 인터뷰는 못 찾음. «위키에 따르면»으로 한정 |
| V6 | W-10·W-28 | 부분 확인 | 맞을 때 Blue뿐 아니라 Spiked Slime도 냄. 1초/0.5초·1~3마리는 둘째 출처 없음 |
| V7 | W-14·B-01·B-02 | 부분 확인 | Easy/Hard 두 풀은 확인. 3/2회 개수·2회 안 재등장 금지는 다른 위키 문장에서 못 찾음(B의 검색 요약과 사본은 같음) |
| V8 | W-20 | 판단 불가 | 0.2.0e 노트에서 «예고가 흐린 사망 효과를 껐다»·«Volatile Crystals를 껐다» 문구를 못 찾음. 확인된 것은 0.2.0e Blood Cretin 웅덩이 6초 → 4초, 0.2.0 Hotfix 7의 Spectre 한정 끄기 |
| V9 | W-19 | 부분 확인 | Suppressor는 확인(가동률 50~75% 조건). Vampiric은 «반»이 아니라 «약 반»(WT III 35→15%) |
| V10 | W-04·W-22 | 엇갈림 | 같은 위키 페이지(옛 판) 안에 3명·2명이 함께 있음. Two Crowns 고유 수치 없음 |
| V11 | A-01 | 부분 확인 | 웅크릴 때 울음·덮칠 때 비명 예고는 있음(위키 + 팬 사이트). «약 1초»는 둘째 출처 없음 |
| V12 | A-21 | 판단 불가 | Abomination 폭발 수치를 못 찾음. Saurian Blazefang(200 물리)과 섞였을 수 있음 |
| V13 | W-26 | 확인 | 잠깐 무적·보상 없음(피해 집계는 됨) |
| V14 | W-29 | 확인 | 디렉터 인터뷰: «의도보다 자주 이동»이 버그 |
| V15 | C-12 | 엇갈림 | 팔레트·파란 이름은 확인. 무리 수는 2~4와 4~5로 갈림 |

집계: 확인 2 · 부분 확인 9 · 엇갈림 2 · 반박 0 · 판단 불가 2.

## 3. 기각·보류한 주장 (본문에서 근거로 쓰지 않음)

| 주장 | 왜 | 출처 |
|---|---|---|
| BTD6 «Ceramic 체력 60» | Super Ceramic 값이다. 일반 Ceramic은 10 | W-07 → V3 |
| Total War 방패 «정면 70%·측면 35%·후면 7%»가 기본값 | Directional Shield 속성을 가진 한 유닛의 예시다 | A-11·A-12 |
| PoE2 0.2.0e «예고가 흐린 사망 효과를 껐다»·«Volatile Crystals를 껐다» | 노트에서 문구를 못 찾음(판단 불가). 본문은 확인된 조치만 썼다 | W-20 → V8 |
| KRF Abomination «범위 200·250 True Damage» | 수치를 못 찾음(판단 불가). 본문에서는 «한 요약이 적었다»로만 남김 | A-21 → V12 |
| 원작 STAGE 0 여왕을 «다섯 번째 포격»에 잡음 | 지난 조사의 기각(R1-X2)과 부딪치고 웹툰 관찰과 다르다. 미확인 | C-09 |
| Vermintide Packmaster «잠깐 멈춘 뒤 건다»는 팁 | 스팸성 사이트, 다른 가이드와 어긋나 검색 에이전트가 버림 | W-06 |
| Diablo II 챔피언 «색이 따라오는 졸개 수를 뜻함»(Game Rant) | 다른 출처와 어긋남 | C-12 |
| PvZ 번지 좀비 «과녁 뒤 약 1초에 내려옴» | 출처마다 달라 확인 안 됨 | W-02 |

## 4. 확인하지 못한 것

- **원문 대조 전부.** 위 네트워크 제약 때문이다. 허용 호스트를 늘리면 W·A·C의 위키 문장을 다시 대조할 수 있다.
- **Q1**: 늑대 «무리 보너스»(근처 동족 수만큼 강해짐) 선례, WC3 늑대·트롤 재생·네크로맨서 수치, Stronghold·Total War 공성 망치, Dota Lycan Howl·밤 보너스, 땅속 이동 적의 다른 선례(PvZ Digger 후보), 불 번짐, 사망 폭발의 지연·예고 길이, 드래곤 퀘스트 킹 슬라임 합체, Clash of Clans Wall Breaker·WC3 Goblin Sapper·OMD 새퍼(폭파병), DINO·Bad North(주민을 노리는 적).
- **Q2**: 타워 디펜스 웨이브 설계 글의 «앞 단계 적을 섞는 비율» 일반론, Kingdom Two Crowns 전반, They Are Billions 캠페인 적 종류 수, Hades Heat가 조우를 바꾸는 법, ITB 섹터 = «지킨 섬 수 + 1»의 공식 확인.
- **Q3**: 출시 게임의 점프 내려찍기·돌진·덮치기 예고 길이 원문 수치, 디펜스 게임 공식 패치 중 «보스 졸개 체력 벽» 해법, BTD6 Dreadbloon·Phayze, Kingdom Rush Umbra, Moloch이 어느 판 보스인지, «놓치면 손해» 적에 대한 플레이어 반응 글.
- **Q4**: 낚아채기·붙잡기 기믹에 대한 직접적인 플레이어 반응(포럼 다수), 감염 상한·예산.
- **Q5**: 텍스트 출처의 «해가 지면 거미가 잠든다», 밤 수성전·밤에 강해지는 적, 양동·저주의 규칙, «난입 페널티»의 내용, 슬라임 군단의 기믹과 스테이지 번호, 영어 위키 정리.
- **Q6**: 늑대(네발) 도트의 방향 수 관례, 서바이버류의 정예·보스 표시, Diablo 3 정예 묶음 표시, 색 바꿈 변종이 안 읽히는 크기·어둠 문턱 수치, 도트 게임의 눈 발광 처리.

## 5. 주장 대장

칸: ID · 주장(짧게) · 대표 출처 · 성격 · 확인 · 연구자의 반박 검증(원 연구자가 쓴 것, 160자에서 자름) · V 판정. W는 워크플로 검색 에이전트의 요약이라 성격·확인 칸을 «검색 결과»로 두었다. 성격 칸이 비었거나 «…과 같음»인 것은 바로 앞 주장과 같은 출처다.

| ID | 주장(짧게) | 대표 출처 | 성격 | 확인 | 연구자의 반박 검증 | V 판정 |
|---|---|---|---|---|---|---|
| W-01 | Defense Grid: The Awakening (Wikipedia) - 파워 코어 훔쳐 도주, 떨어뜨리면 되돌아감 | https://en.wikipedia.org/wiki/Defense_Grid:_The_Awakening | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V4 부분 확인 |
| W-02 | Bungee Zombie - Plants vs. Zombies Wiki (wiki.gg) | https://plantsvszombies.wiki.gg/wiki/Bungee_Zombie | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V1 부분 확인 |
| W-03 | Vaulting Zombies (Pole Vaulting Zombie) - Plants vs. Zombies Wiki | https://plantsvszombies.wiki.gg/wiki/Vaulting_Zombies | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-04 | Floaters - Kingdom Wiki (Fandom); 관련 문서 Crown Stealers, Greedling | https://kingdomthegame.fandom.com/wiki/Floaters?oldid=5758 | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V10 엇갈림 |
| W-05 | Kingdom Two Crowns (Wikipedia) - Greed의 동전·왕관 훔치기 | https://en.wikipedia.org/wiki/Kingdom_Two_Crowns | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-06 | Warhammer: Vermintide 2 - Dealing with Special Enemies (Packmaster) | https://www.magicgameworld.com/?p=16275 | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-07 | MOAB (BTD6) - Bloons Wiki (bloonswiki.com) | https://www.bloonswiki.com/MOAB_(BTD6) | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V3 부분 확인 |
| W-08 | Red Bloon Equivalent (RBE) - Bloons Wiki | https://www.bloonswiki.com/RBE | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-09 | Late Game and Freeplay (BTD6) - Bloons Wiki (Fandom) | https://bloons.fandom.com/wiki/Late_Game_and_Freeplay_(BTD6) | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-10 | King Slime - Official Terraria Wiki | https://terraria.wiki.gg/wiki/King_Slime | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V6 부분 확인 |
| W-11 | Gloomy - Kingdom Rush Wiki (Origins) | https://kingdomrushtd.fandom.com/wiki/Gloomy | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V2 부분 확인 |
| W-12 | Gold - Kingdom Rush Wiki (bounty exceptions list) | https://kingdomrushtd.fandom.com/wiki/Gold | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V2 부분 확인 |
| W-13 | The Structure of Fun: Learning from Super Mario 3D Land's Director (Game Developer/Gamasutra, Koichi Hayashida interview) | https://www.gamedeveloper.com/design/the-structure-of-fun-learning-from-i-super-mario-3d-land-i-s-director | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-14 | Slay the Spire Wiki: Exordium / Monsters (encounter pool rules) | https://slaythespire.wiki.gg/wiki/Exordium | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V7 부분 확인 |
| W-15 | Kingdom Rush Wiki: stage pages (Gray Ravens, Nightfang Swale, Dwarven Gate) and Encyclopedia | https://kingdomrushtd.fandom.com/wiki/Gray_Ravens | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-16 | Kingdom Rush - the wonderful Campaign level design (Game Developer blog) | https://www.gamedeveloper.com/design/kingdom-rush---the-wonderful-campaign-level-design | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-17 | Monster Train Wiki: ring combats and boss pools | https://monster-train.fandom.com/wiki/Clipped_Guard | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-18 | Giant Bomb: Gradual Enemy Introduction (concept page) | https://giantbomb.com/wiki/Concepts/Gradual_Enemy_Introduction | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-19 | Diablo IV Official Patch 1.3.1 Notes (Icy Veins republication of Blizzard notes, 2024-02-01) | https://www.icy-veins.com/d4/news/official-patch-1-3-1-notes/ | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V9 부분 확인 |
| W-20 | Path of Exile 2 0.2.0e official patch notes (mein-mmo republication, 2025-04) | https://mein-mmo.de/en/the-big-update-of-path-of-exile-2-changes-the-endgame-more-than-expected-official-patch-notes,1217370/4/ | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V8 판단 불가 |
| W-21 | Melynx — Monster Hunter Wiki (item-stealing Lynian; developer-requested cap) | https://www.monsterhunterwiki.org/wiki/Melynx | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V5 부분 확인(출처 한정) |
| W-22 | Review: Kingdom Two Crowns expands its reign to the Nintendo Switch (Comics Beat) | https://www.comicsbeat.com/review-kingdom-two-crowns-expands-its-reign-to-the-nintendo-switch | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V10 엇갈림 |
| W-23 | Bungee Zombie — Plants vs. Zombies Wiki | https://plantsvszombies.wiki.gg/wiki/Bungee_Zombie | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V1 부분 확인 |
| W-24 | Darkling — Slay the Spire Wiki (Life Link revive) | https://slay-the-spire.fandom.com/wiki/Darkling | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-25 | Vortex (BTD6) - Bloonswiki | https://www.bloonswiki.com/Vortex_(BTD6) | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-26 | Bloonarius (BTD6) - Bloonswiki | https://www.bloonswiki.com/Bloonarius_(BTD6) | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V13 확인 |
| W-27 | Lych (BTD6) - Bloonswiki (with Lych Soul / Version 54.0 notes) | https://www.bloonswiki.com/Lych_(BTD6) | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| W-28 | King Slime - Official Terraria Wiki | https://terraria.wiki.gg/King_Slime | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V6 부분 확인 |
| W-29 | Monster Hunter Wilds beta's frequently moving monsters were a bug, director says (VGC) | https://www.videogameschronicle.com/news/monster-hunter-wilds-betas-frequently-moving-monsters-were-a-bug-director-says/ | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | V14 확인 |
| W-30 | /dev: Clarity in League (Riot Games) + VFX Style Guide (2017) | https://riotgames.com/en/news/dev-clarity-in-league | 검색 결과(워크플로) | 검색 요약만 | 같은 검색 안의 비교만 | — |
| A-01 | Hunter: 덮치기 전에 «1초 웅크림»이 보이는 예고 | https://left4dead.fandom.com/wiki/The_Hunter | 위키 | 검색 요약만 | 함(#13). 웅크림 1초를 뒤집는 출처는 나오지 않았다. 소리 예고는 다시 못 찾았다. L4D2 위키가 Hunter의 "amplified scream"을 외형 개편 설명에서 지나가듯 언급한다는 요약만 있었다. | V11 부분 확인 |
| A-02 | Hunter: 고정 피해는 난이도별 0.5초당 5/10/15, 낙하 충격 피해 최대 25 | https://left4dead.fandom.com/wiki/The_Hunter | 위키. 거리 | 검색 요약만 | 같은 검색(#1) 안에서 출처끼리 엇갈림. 한 가이드는 "the greater the distance of the Pounce, the more impact damage"라고 한다(거리 기준). 위키 본문은 "great height"라고 한다(높이 기준). 위키 토론 페이지와 포럼은 수 | — |
| A-03 | Hunter: 착지할 때 주변 생존자를 1초(Survival 2초) 비틀거리게 함 | https://left4dead.fandom.com/wiki/The_Hunter | 위키 | 검색 요약만 | 안 함 | — |
| A-04 | Hunter: 동료가 밀쳐서 떼어 냄, L4D2에서는 떼어 내기 어려운 구간이 생김(커뮤니티 플러그인 기준) | https://left4deadwiki.com/wiki/The_Hunter | 위키. [L4D2]Hunter_pounce_alignment_fix https: | 검색 요약만 | 함(#13). «L4D2가 deadstop을 없앴다»는 공식 근거는 못 찾았다. 그 말은 커뮤니티 표현으로 남는다. «약 1초 밀칠 수 없는 구간»은 L4D1식 정렬을 되돌리는 플러그인이 «고치려는 문제»로 적은 것이다. 그러니 L4D2 바닐라의 부작용이었다(추론). | — |
| A-05 | Kingdom Rush Wulf: 가장 빠른 적 무리, 회피 수치는 위키끼리 다름 | https://kingdomrushtd.fandom.com/wiki/Wulf | 위키. 비교: Wulf https: | 검색 요약만 | 같은 검색(#2) 안에서 위키끼리 엇갈림. 회피(dodge) 확률이 한 페이지는 25%, 다른 페이지는 30%다. 어느 쪽이 본 위키인지 요약이 밝히지 않았다. | — |
| A-06 | Kingdom Rush Worg: «강한 Wulf» + 마법 저항 50%로 마법 탑 무력화 | https://kingdomrushtd.fandom.com/wiki/Worg | 위키. Winter Wolf https: | 검색 요약만 | 안 함. 다만 Wulf 속도 "Fast (2.5)"와 Worg 속도 "Fast (2)"는 둘 다 «Fast»인데 숫자가 다르다. 같은 단위인지 확인하지 못했다. | — |
| A-07 | Dota 2 Lycan: 늑대 소환을 7.41에서 3마리→2마리로 줄임(개발사 수정) | https://liquipedia.net/dota2/Lycan/Changelogs | 위키(공식 패치 노트 옮김). 비교: https: | 검색 요약만 | 안 함. Howl·Feral Impulse 최대 레벨 4→3 변경도 요약에 나왔지만 날짜가 분명하지 않았다(요약도 «미확인»으로 둠). | — |
| A-08 | Dota 2 Lycan Feral Impulse: 공격력·체력 재생 보너스 수치와 변경 | https://liquipedia.net/dota2/Lycan/Changelogs | 위키. Lycan Dota 2 https: | 검색 요약만 | 두 출처(Liquipedia·Dotacoach)의 재생 수치가 같다. 별도 검색은 안 함. | — |
| A-09 | AoE2 공성 망치: 화살은 거의 무효, 근접에 약함, 건물·공성 병기만 상대 | https://ageofempires.fandom.com/wiki/Battering_Ram_(Age_of_Empires_II | 위키. Battering Ram Counters https: | 검색 요약만 | 안 함 | — |
| A-10 | AoE2 망치 수비대(garrison): 4명 vs 6명, 2023년 6월 패치로 바뀜 | https://liquipedia.net/ageofempires/Battering_Ram | 팬 정리 | 검색 요약만 | 같은 검색(#4) 안에서 엇갈림 확인. Liquipedia 4, TV Tropes 6. TV Tropes는 2023년 6월 패치로 4→6이 됐다고 설명한다. Liquipedia가 옛 값일 수 있다(추론). | — |
| A-11 | Total War 방패: 정면에서 오는 작은 투사체만 일정 확률로 막음, 각도·수치는 포럼값 | https://totalwarwarhammer.fandom.com/wiki/Shielded | 위키. 각도 | 검색 요약만 | 함(#14). 공식 노트에서 일반 방패의 각도나 등급 수치는 찾지 못했다. 120°·계산식·30/50%는 포럼값으로 남는다. #5 요약이 «정면 70%·측면 35%·후면 7%»를 기본값처럼 적었지만, #14 결과 그것은 Directional Shield라는 별도 속성을 가진 한 유닛의  | — |
| A-12 | Total War: WARHAMMER III 5.0.0 «Directional Shield»: 360° 막기 × 방향 배율, 6.1에서 개별 유닛 수치 조정 | https://www.totalwar.com/news/total-war-warhammer-iii-update-500 | 공식 패치 노트. Directional Shield https: | 검색 요약만 | 함(#14). 5.0 이후 방향 배율 1.0/0.5/0.1을 바꾼 패치 노트는 찾지 못했다. 6.x 노트 전문은 보지 못했다(요약도 «6.1 이후 확인 필요»). 막기 무시 효과 Shieldbreaker (effect) 위키 문서 https://totalwarwarhammer.fando | — |
| A-13 | D&D 5e 트롤: 턴마다 10 재생, 산·불을 맞으면 다음 턴 재생 끊김, 0 HP로 턴을 시작하고 재생 못 해야 죽음 | https://www.aidedd.org/dnd/monstres.php?vo=troll | SRD 옮긴 사이트(규칙서 원문 기반). 타이밍 해석: D&D 5E (2014) - Troll regeneration https: | 검색 요약만 | 안 함. 포럼 글은 «한 턴에 산·불을 맞으면 다음 턴 시작의 재생 한 번만 막는다»는 라운드 단위 해석을 확인해 준다. 2014판 기준이며, 2024판 차이는 보지 않았다. | — |
| A-14 | Diablo II Fallen Shaman: 부활 횟수 상한이 없어 보임, 같은 아종만 살림 | https://diablo.fandom.com/wiki/Fallen_Shaman_(Diablo_II | 위키. 보조: On the matter of Fallen Shaman https: | 검색 요약만 | 검색어에 "limit how many times"를 넣어 상한이 있다는 쪽도 찾았지만, 고정 상한을 말하는 출처는 나오지 않았다. 요약은 «대부분 팬 위키·포럼이고 공식 문서가 아님»이라고 덧붙였다. 별도 반박 검색은 안 함. | — |
| A-15 | Diablo II 부활 대응: 샤먼 먼저 잡기, 떼어 놓고 잡기, 시체 없애기 | https://diablo.fandom.com/wiki/Fallen_Shaman_(Diablo_II | 위키. 시체 규칙: Diablo 2 Resurrected - Death Mechanics https: | 검색 요약만 | 안 함 | — |
| A-16 | Dark Souls 카타콤: 해골마다 주인 네크로맨서가 있음, 네크로맨서를 잡거나 신성 무기로 잡아야 안 일어남 | https://darksouls.wikidot.com/necromancer | 위키. Skeleton https: | 검색 요약만 | 같은 검색(#8) 안에서 확인. 스팀 댓글 하나가 «화톳불에서 쉬면 부활이 다시 시작된다»고 주장한다. 위키와 공략에서는 확인되지 않는다(요약 판단). 별도 검색은 안 함. | — |
| A-17 | Dark Souls 부활 해골: 다른 대응과 변형 | https://darksouls.fandom.com/wiki/Skeleton | 위키. Divine Ember 경로: DARK SOULS 스팀 토론(후보 https: | 검색 요약만 | 안 함 | — |
| A-18 | They Are Billions: 좀비는 사람을 바로 바꾸지 않고 건물을 감염시킴, 쏟아지는 수는 거주 인원과 같음 | https://theyarebillions-archive.fandom.com/wiki/Infected | 위키 | 검색 요약만 | 같은 검색(#9) 안에서 확인. 스팀 사용자 한 명이 "zombies killed them (they don't infect them), instead, they infect the buildings when they can break into them"라고 썼다. 배경 설명의 «유닛이 | — |
| A-19 | They Are Billions: 연쇄 감염과 붕괴, 감염 건물은 기능 정지, 플레이어 반응 | https://theyarebillions-archive.fandom.com/wiki/Infected | 위키. 플레이어: Infection mechanic needs to be adjusted https: | 검색 요약만 | 같은 검색 안에서만. 한 플레이어가 «주민이 변하기 전에 지연을 두자»고 제안했지만 위키에는 그런 지연 설명이 없다. 요약은 «최신 패치 노트는 확인 안 함»이라고 했다. | — |
| A-20 | Kingdom Rush 악마 계열: 죽을 때 터져 근처 병사(병영 유닛)를 다치게 함 | https://kingdomrushtd.fandom.com/wiki/Demon_Lord | 위키. Kingdom Rush | 검색 요약만 | 안 함 | — |
| A-21 | Kingdom Rush Frontiers Abomination: 죽을 때 범위 200에 고정 피해 250 | https://kingdomrushtd.fandom.com/wiki/Abomination/Frontiers | 위키 | 검색 요약만 | 안 함. 폭발까지의 지연이나 예고(시각·소리)는 요약에 없다(못 찾음). | V12 판단 불가 |
| A-22 | Kingdom Two Crowns 블러드문: 수가 많아지는 밤, 다 잡아야 끝남, 다음 밤은 휴전 | https://kingdomthegame.fandom.com/wiki/Blood_Moon | 위키. Waves https: | 검색 요약만 | 안 함 | — |
| A-23 | 블러드문 주기와 예고: 출처끼리 엇갈림, 예고 신호는 불확실 | https://kingdomthegame.fandom.com/wiki/Blood_Moon |  | 검색 요약만 | 같은 검색(#11) 안에서 네 출처를 비교했다. 주기가 «6/8일 번갈아»(위키), «약 10일»(서드파티), «시즌마다»(PSNProfiles), «3년째 시즌당 2번»(스팀)으로 엇갈린다. 해마다 잦아진다는 점은 대체로 같다(추론). | — |
| A-24 | RimWorld 습격자: 납치·약탈이 주목표, 고가치 구역을 노림 | https://steamcommunity.com/app/294100/discussions/0/6431726046908774788/ | 포럼 한 건 | 검색 요약만 | 같은 검색 안에서 다른 플레이어 반론이 나왔다: "the raiders won't actually take any valuable items unless they are in the middle of your stockpile". 위키 본문은 열어 보지 못해 «위키가 틀렸다»는 주장을  | — |
| A-25 | RimWorld 플레이어 반응과 모드: «납치하고 떠난다» 알림에 대한 불만 | https://steamcommunity.com/app/294100/discussions/0/6197556602766342291/ | 포럼 한 건. Raiders Will Never Be Satisfied https: | 검색 요약만 | 안 함 ## 기믹별 정리 표의 «대응 축» 칸은 이 게임 축(시설·근접 저지 용병·영웅)에 짝지은 것으로, 전부 (추론)이다. ### 1. 늑대·짐승 무리 \| 항목 \| 내용 \| 주장 \| \|---\|---\|---\| \| ① 발동 \| Hunter: 웅크린 뒤 덮쳐 한 명을 고 | — |
| B-01 | Slay the Spire — 막마다 «약한 풀 → 강한 풀» 자리 규칙 | https://github.com/Voyage-for-the-ideal/aiplayspire/blob/HEAD/cardcrawl/dungeons/Exordium.java | 디컴파일 게임 코드(GitHub 한 건) | 원문 열어 봄 (GitHub 사본) | 검색 #12. 위키 요약 "the first 2 monster encounters (3 for Act 1) are randomly selected from an "Easy Pool", while the rest of the fights for that Act are randomly se | V7 부분 확인 |
| B-02 | Slay the Spire — 같은 조우 반복 금지와 «쉬운 판 바로 뒤 어려운 판» 금지 | B-01과 같은 사본의 AbstractDungeon.java | 디컴파일 게임 코드 | 원문 열어 봄 (GitHub 사본) | 검색 #12. 위키 요약 "a Hard Pool Louse fight cannot follow an Easy Pool Louse fight", 정예는 "The same elite can appear multiple times in an act, but cannot be encounter | V7 부분 확인 |
| B-03 | Slay the Spire — 보스는 막마다 후보 3, 처음엔 안 본 보스부터 | B-01과 같음 | 디컴파일 게임 코드 | 원문 열어 봄 (GitHub 사본) | 안 함 | — |
| B-04 | Into the Breach — 섬(테마)과 섹터(자리)를 코드에서 따로 둔다 | https://github.com/Win-KemaAlexArt/Into-the-Breach-Reference/blob/HEAD/scripts/game.lua | 게임 Lua 스크립트 사본(GitHub 한 건) | 원문 열어 봄 (GitHub 사본). 단, `Game:GetSector()`는 C++ 쪽이라 «sector = 지금까지 지킨 섬 수 + 1»은 코드로 확인하지 못했다(추론). | 검색 #1. Steam 토론 요약 "one player reported that the islands get more difficult the more other islands you cleared"와 «얼음 섬을 첫 섬으로 고르면 쉬웠다»는 답글 — 추론과 맞다. 다만 요약은 "I f | — |
| B-05 | Into the Breach — 섹터별 «5마리 중 약한 적 수·강화형 수» 표 | B-04와 같은 저장소 scripts/spawner.lua | 게임 Lua 스크립트 사본 | 원문 열어 봄 (GitHub 사본) | B-04와 묶음(검색 #1) | — |
| B-06 | Monster Train — 고리(자리)마다 풀, 3·6·8번째는 고정 보스 | https://monster-train.fandom.com/wiki/Battle | 위키 | 검색 요약만 | 안 함. 고리별 적 풀이 Covenant에 따라 어떻게 바뀌는지는 요약에 없었다("I didn't find an authoritative, per-ring breakdown"). | — |
| B-07 | Hades — 구역 순서 고정, 구역마다 적 목록, 정예는 «갑옷 + 강화 공격» 변종 | https://hades.wiki.fextralife.com/Enemies |  | 검색 요약만 | 안 함. Heat(난이도 계약)가 조우 구성을 어떻게 바꾸는지는 못 찾음. | — |
| B-08 | Rogue Tower·Thronefall — 웨이브 번호로 해금 + 무작위 구성 / 맵마다 고정 표 | https://steamcommunity.com/app/1843760/discussions/0/3187989920095145106/ |  | 검색 요약만 | 안 함. Kingdom Two Crowns는 검색 한도 안에서 다루지 못했다(못 찾음). | — |
| B-09 | Plants vs. Zombies — 웨이브마다 «점수 예산»을 두고 종류는 가중치로 뽑는다 | https://github.com/Patoke/re-plants-vs-zombies/blob/HEAD/Lawn/Board.cpp | 디컴파일 재구현 코드(GitHub 한 건) | 원문 열어 봄 (GitHub 사본). 같은 레벨을 다시 할 때마다 구성이 달라지는지(시드 `GetLevelRandSeed`에 `mBoardRandSeed`가 섞임)는 끝까지 따라가 보지 않았다(추론: 달라진다). | 검색 #13(B-11과 묶음). 레벨 선택 화면 요약 "the first, third, sixth, and eighth levels will show the new zombie encountered on the thumbnail" — 코드 표에서 센 «새 좀비 레벨 = x-1·x-3·x | — |
| B-10 | Kingdom Rush 1 — 단계 수 대 적 종류 수 | https://github.com/DanQZ/KR1-Smarter-Soldiers-Mod/tree/HEAD/kr1/data/waves | 모드 저장소에 든 게임 데이터 사본(GitHub 한 건) | 원문 열어 봄 (GitHub 사본). 모드가 웨이브를 고쳤는지, Flash판과 같은지는 확인 못 함. | 검색 #2. 나무위키 요약 "A Korean-language wiki lists 30 numbered entries for the original game's enemies, plus a second set of enemies from the expansion-era content" — | — |
| B-11 | Plants vs. Zombies — 50레벨 대 26종, 레벨당 허용 1~8종 | https://store.epicgames.com/vi/p/plants-vs-zombies-game-of-the-year-edition-e8b166 |  | 26종·50레벨은 검색 요약만, 레벨별 허용 수는 원문 열어 봄 (GitHub 사본) | 검색 #13. «레벨마다 새 좀비»는 요약이 부정했다("should be treated as unverified or incorrect"). 코드 표도 50레벨 중 새 종류가 나오는 레벨은 1, 3, 6, 8, 11, 13, 16, 18, 21(오리 튜브), 23, 26, 28, 31, | — |
| B-12 | Slay the Spire — 막당 조우 수(종류 수의 대용) | B-01과 같음 | 디컴파일 게임 코드 | 원문 열어 봄 (GitHub 사본) | B-01과 묶음(검색 #12). 종 수는 못 셈. | — |
| B-13 | They Are Billions — 감염체는 걷는 놈·뛰는 놈·특수 셋으로 나뉜다(종류 수는 못 찾음) | https://they-are-billions.fandom.com/wiki/Infected |  | 검색 요약만 | 안 함 | — |
| B-14 | Kingdom Rush 1 — 새 적이 처음 나오는 단계에서 차지하는 몫 | B-10과 같음 | 게임 데이터 사본 | 원문 열어 봄 (GitHub 사본) | 안 함 | — |
| B-15 | Kingdom Rush 1 — 테마 순도: 본편은 섞고, 뒤에 붙은 단계일수록 순하다 | B-10과 같음 | 게임 데이터 사본 | 원문 열어 봄 (GitHub 사본). 무리 나누기는 내가 이름으로 했다(예: 늑대·가고일을 어느 무리에도 넣지 않음). | 안 함 | — |
| B-16 | Plants vs. Zombies — 새 좀비 레벨은 «기본 2종 + 새 1종», 무대 끝 레벨에서 섞는다 | B-09와 같은 저장소 Challenge.cpp `gZombieAllowedLevels` | 디컴파일 재구현 코드 | 원문 열어 봄 (GitHub 사본). x-5·x-10 같은 특수 레벨(컨베이어·미니게임)은 따로 빼지 않았다. | B-11과 묶음(검색 #13) | — |
| B-17 | Diablo 3 Treasure Goblin — 포탈 여는 시간 6초냐 10초냐(판마다 다름) | https://diablo.fandom.com/wiki/Treasure_Goblin |  | 검색 요약만 | 같은 검색 안에서 6초와 약 10초가 엇갈림. 요약은 판(패치) 차이일 수 있다고 봤고, 패치 노트로는 확인하지 않았다. 플레이어 반응(놓쳤을 때 감정)은 못 찾음. | — |
| B-18 | 소환 졸개로 늘어지는 보스전 — 공식 패치 사례는 못 찾음, 단편만 | https://github.com/GranSkreaReforged/GSOOffline/pull/46 |  | 검색 요약만 | 안 함 | — |
| B-19 | Kingdom Rush 1 보스 웨이브의 짜임 — 본편 보스는 혼자, 뒤 단계 보스는 큰 호위와 함께 | https://kingdomrushtd.fandom.com/wiki/The_Juggernaut |  | 웨이브 짜임은 원문 열어 봄 (GitHub 사본), Juggernaut 스킬 수치는 검색 요약만 | 검색 #14 안에서 Juggernaut 체력이 엇갈림: "8000/10000/12000 depending on the difficulty"(위키) 대 "SuperCheats lists 10000". 난이도별 값과 한 값의 차이로 보인다(추론). | — |
| B-20 | Kingdom Rush 보스가 «그 단계 테마를 키운» 꼴인가 | https://wikily.gg/kingdom-rush/enemies/veznan |  | 검색 요약만(보스 스킬), 테마 무리 몫은 원문 열어 봄 (GitHub 사본) | 검색 #9와 #14가 엇갈림. #9는 Vez'nan을 "Genesis finale"(분신 셋)로, #14는 원작 Vez'nan(탑에서 묶기·포탈)으로 설명했다. 시리즈마다 같은 이름 보스가 다르게 짜였으니 판을 밝혀 써야 한다. | — |
| B-21 | 보스 예고 길이 — Kingdom Rush는 «초 단위 주기»로 적혀 있다 | B-19 |  | 검색 요약만 | 안 함 | — |
| B-22 | 예고(telegraph) 길이 수치 — 출시 게임 원문 수치는 못 찾음, 개발 문서·블로그만 | https://github.com/rickeyjohnson/solo-leveling-awakening/issues/111 |  | 검색 요약만 | 안 함. 요약도 "Each cited figure is a single project's choice, not a published standard."라고 했다. | — |
| B-23 | Terraria King Slime — 순간이동 조건은 있으나 예고 길이 수치는 없음 | https://terraria.wiki.gg/wiki/King_Slime |  | 검색 요약만 | 안 함 --- ## 질문별 정리 ### Q2-1. 판마다 테마 순서·조합이 바뀌어도 난이도 곡선을 지키는 법 | — |
| C-01 | 스테이지마다 «군단» 하나가 오고, 보상 마석이 그 군단 이름을 단다 | https://namu.wiki/w/%EB%94%94%ED%8E%9C%EC%8A%A4%20%EA%B2%8C%EC%9E%84%EC%9D%98%20%ED%8F%AD%EA%B5%B0%EC%9D%B4%20%EB%90%98%EC%97%88%EB%8B%A4/%EC%8A%A4%ED%85%8C%EC%9D%B4%EC%A7%80 | 나무위키(2차, 소설 기준) | 검색 요약만(검색 2·4) | 따로 반박 검색을 하지는 않았다. 다만 검색 2에서 섞임 사례가 나왔다(C-04). STAGE 9는 군단 대신 정체 가린 1체에 다른 군단이 난입한다(C-06). 그래서 «한 군단»은 기본이고 예외가 둘 있다. | — |
| C-02 | 군단 안은 2~5종: 다수 기본 + 소수 정예 + 보스 | 위 나무위키 | 나무위키 | 검색 요약만(검색 1·4). 레벨이 판본마다 다를 수 있다고 요약이 덧붙였다. 기존 조사는 STAGE 0 레벨을 웹툰과 나무위키가 반대로 적는다고 했다(01 §4.3). | 하지 않음. | — |
| C-03 | 변종은 «역할·재질·원소·털색» 한 축으로 갈린다 | 위 나무위키 스테이지 문서 | 나무위키 | 검색 요약만(검색 2) | 하지 않음. | — |
| C-04 | 예외 1: 흡혈귀 군단은 다른 종(구울)을 대량으로 섞는다 | 위 나무위키 | 나무위키 | 검색 요약만(검색 2) | C-01의 반례로 쓴다. | — |
| C-05 | 흡혈귀의 약점은 은제 무기, 마무리는 전격 | https://namu.wiki/w/%EB%94%94%ED%8E%9C%EC%8A%A4%20%EA%B2%8C%EC%9E%84%EC%9D%98%20%ED%8F%AD%EA%B5%B0%EC%9D%B4%20%EB%90%98%EC%97%88%EB%8B%A4/%EB%93%B1%EC%9E%A5%EC%9D%B8%EB%AC%BC | 나무위키 | 검색 요약만(검색 3) | 하지 않음. 흡혈귀가 햇빛·낮에 약한지는 찾지 못했다. | — |
| C-06 | 예외 2: 정체 가린 1체 + 다른 군단 난입, 다음 스테이지에 «난입 페널티» | 위 나무위키 스테이지 문서 | 나무위키 | 검색 요약만(검색 2). 페널티가 무엇을 깎는지는 못 찾음. | 하지 않음. | — |
| C-07 | 낮밤 기믹: «해가 지면 거미가 잠든다»는 웹툰만, 텍스트로는 «잠든 듯한 거미»뿐 | https://www.scribd.com/document/740404746/I-Became-the-Tyrant-of-a-Defense-Game-02-M | 비공식 사본(번역본 업로드로 보임) | 검색 요약만(검색 6) | 했다(검색 3·6·7). 결과는 셋이다. ① 텍스트 출처에서 «해가 지면 잠든다»는 확인 못 함. ② «잠든 듯, 건드리면 깬다»는 다른 장면에서 나온다. ③ 원작 수성전이 밤에 벌어지거나 밤에 적이 강해지는 기믹은 찾지 못함. 기존 조사도 무료분 본 전투가 «모두 낮»이라고 적는다(R | — |
| C-08 | 달 주기는 늑대 쪽 이명과 아군 특성으로만 나온다 | https://namu.wiki/w/%EB%94%94%ED%8E%9C%EC%8A%A4%20%EA%B2%8C%EC%9E%84%EC%9D%98%20%ED%8F%AD%EA%B5%B0%EC%9D%B4%20%EB%90%98%EC%97%88%EB%8B%A4/%EB%93%B1%EC%9E%A5%EC%9D%B8%EB%AC%BC?uuid=49db36f3-f778-405b-a32b-9f42ff96e6b4 | 나무위키 | 검색 요약만(검색 2·7) | 했다(검색 7, «밤 야습 야간 전투 만월 웨어울프 양동»). STAGE 10 늑대 군단이 밤·만월에 왔다거나 그때 강해졌다는 서술은 못 찾음. 양동 작전과 저주의 구체 내용도 못 찾음. | — |
| C-09 | STAGE 0 보스를 «다섯 번째 포격»에 잡았다는 요약은 미확인으로 둔다 | 나무위키 등장인물 | 나무위키 | 검색 요약만(검색 3) | 기존 조사가 «보스 처치를 특성 조합과 마나 대포의 결합, 여러 번 포격으로 일반화한 주장»을 0-3으로 기각했다(`01_battlefield_to_rules.md` §2.3, R1-X2). 이번 요약은 그 기각과 부딪친다. 웹툰 7화 직접 관찰은 «데미안이 쏜 포탄이 여왕 이마에 맞는 | — |
| C-10 | 슬라임 군단의 우두머리는 바람 연합 마법으로 부서졌다(스테이지 번호 불확실) | 위 나무위키 스테이지 | 나무위키 | 검색 요약만(검색 4). STAGE 7인지 8인지 요약이 확정하지 못했다. | 하지 않음. 슬라임이 분열하는지, 물리에 강한지 같은 기믹은 못 찾음. | — |
| C-11 | They Are Billions 특수 감염체는 크기와 행동으로 갈린다(시각 설계 글은 없음) | https://they-are-billions.fandom.com/wiki/Infected_Giant | 팬 위키 | 검색 요약만(검색 8) | 하지 않음. | — |
| C-12 | Diablo II 챔피언·유니크는 «무작위 팔레트 + 이름 색 + 무리»로 표시한다 | https://diablo.fandom.com/wiki/Champion_monsters | 팬 위키 | 검색 요약만(검색 11) | C-13(팔레트 스왑 한계)의 반대쪽 사례로 찾은 것이다. 상용 대작이 색 바꿈 변종을 정예 표시로 실제로 쓴다. 다만 이름 글씨·체력바 표기가 함께 붙는다. Game Rant는 색이 «how many minions accompany the mob»을 뜻한다고 적어 다른 출처와 어긋난다 | V15 엇갈림(무리 수만) |
| C-13 | 팔레트 스왑은 모양을 못 바꾸므로 두 번째 단서를 겹친다 | https://www.framesprite.com/guides/enemy-sprite-palette-swap-variants | 튜토리얼 | 검색 요약만(검색 10) | 했다(검색 11 → C-12). 색 바꿈이 통하는 대작 사례도 이름 글씨와 무리를 함께 써서, 이 주장을 뒤집지 않는다. 작은 크기·어둠에서 색 바꿈이 «몇 px부터» 안 읽히는지 수치는 못 찾음. | — |
| C-14 | 네발 짐승 걷기: 최소 4프레임, 도트 실용 상한 8, 뒷다리는 반대쪽 앞다리 한 걸음 뒤 | http://finalbossblues.com/walk-cycles-p1/ | 튜토리얼 | 검색 요약만(검색 12). 시바견 튜토리얼의 URL은 특정 못 함. | 방향 수 쪽으로 두 번(검색 13·14) 시도했으나 답이 오지 않았다. 늑대 방향 수 관례는 «못 찾음». | — |
| C-15 | 슬라임: 방향 없이 대기 4~5 + 뜀 5~6, 착지 눌림은 짧게, 공중 정지는 잘 안 읽힌다 | https://yyhboom.itch.io/slime-enemy-animated-pixel-art-sprite-16x24-idle-hop-4-colors/devlog/1633634/slime-enemy-animated-pixel-art-sprite-16x24-idle-hop-4-colors | 에셋 판매 페이지 두 건, 튜토리얼, 작가 글 한 건 | 검색 요약만(검색 13) | 하지 않음(«방향을 안 둔다»는 에셋 두 건의 관찰일 뿐이다. 방향 있는 슬라임 사례를 따로 찾지 못했다). | — |
| C-16 | 어두운 장면: 적에게만 림 라이트를 더한다(거리 따라 켜기), 발광 눈은 따로 둔다 | https://www.playdarktide.com/news/darktide-101-enemy-character-art | 개발사 공식 글 한 건, 개인 저장소 PR 한 건, 레벨 디자인 책, 튜토리얼 | 검색 요약만(검색 14) | 하지 않음. 다만 같은 검색의 외곽선 가이드는 «순검정을 피하고 몸의 가장 어두운 색보다 한 단계 어둡게»를 권한다. 기존 조사(04 §1)는 «바깥 외곽선은 물체·배경 둘 다보다 어두워야 하고, 배경이 검정에 가까우면 사실상 최암색이나 검정뿐»이라고 적었다. 밤의 어두운 바탕에서는 두 | — |

모두 94개
