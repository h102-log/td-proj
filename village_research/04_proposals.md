# 04. 10/31 전에는 건물에 붙는 그림부터, 규칙은 11월로 — (b) 옮길 제안과 비용

[README](README.md)로 돌아가기. 수치 표기((계산)·(눈대중)·(픽셀 집계)·(검색 요약))는 README 1장에 있다.


칸을 나눈 기준은 이렇다. 동결 전 칸에는 시뮬레이션·규칙·입력·저장을 바꾸지 않고, 이미 있는 상태(완성된 건물, 단계, 시각, 마을 레벨)만 읽어 그리는 변경을 넣었다. 그리기 코드 변경은 동결 전 칸에 들어간다. 지난 세션이 집터 시안을 «그림만», 주민 피신을 «코드»로 나눈 선례를 따랐다(`insights/2026-10-25_village_mood_mockup.md`). `WBS.md:233`은 조작 묶음 때문에 M4가 R5대로 밀린다고 적고 있어 실제 동결일은 10/31보다 늦을 수 있다. 덮개가 얼마나 늘어나는지는 아래와 같다. 모두 계산값이고 거점은 1칸으로 셌다.

| 시나리오 | 덮는 칸 | 마을 1,620칸 대비 | 거점 둘레 30×15칸에 모였을 때 |
|---|---|---|---|
| 지금(전부 1칸, 맨땅) | 11 | 0.7% | 2.4% |
| 1칸 유지 + 둘레 1칸 터(F1) | 약 99 | 약 6% | 약 22% |
| 1칸 유지 + 둘레 2칸 터 | 약 176~231 | 약 11~14% | — |
| 집 2×2·시설 3×3(L1) | 60 | 3.7% | 13% |
| L1 + 마당(집 3×3, 시설 5×4) | 134 | 8.3% | 30% |

표에서 보듯 **크기를 키우는 것(L1)보다 1칸을 유지한 채 터를 까는 것(F1)이 덮개를 더 늘린다**. 그리고 덮개가 비교작의 덩어리 수준에 닿는 것은 건물이 거점 둘레에 모였을 때뿐이다.

### 10/31 기능 동결 전 — 그림·꾸밈만

| # | 제안 | 내용 | 근거 | 비용(Claude 추정) | 걸리는 것 |
|---|---|---|---|---|---|
| F1 | **건물별 터·마당 묶음** | 건물을 짓기 시작하면 그 칸 둘레 약 3×3칸에 외곽선 없는 «다진 흙» 얼룩을 깐다. 지금 흙보다 한 단계 밝고 점이 적으며, 가장자리가 불규칙하다. 완성되면 건물 실루엣에 닿는 소품 묶음 하나를 얹는다. 집은 이랑 2~3줄 텃밭(1×2 이하) + 울타리 한두 토막(L자) + 장작더미, 병영은 밟힌 훈련 마당 얼룩, 사격장은 과녁 쪽으로 난 밟힌 줄, 작업장은 톱밥 얼룩 + 목재 더미, 교회는 판석 몇 장이다. 종류마다 변형 2~3개를 둔다 | AoE II Foundation Terrain, Northgard 얼룩, Rise to Ruins 작업 마당, Foundation 정원. 같은 모양을 찍어 내면 «공장에서 찍은 것 같다»는 Manor Lords 비판([Steam 토론](https://steamcommunity.com/app/1363080/discussions/0/4355619782840362614), 검색 요약) | 그림 10~15장(`tools/art/decor.py`). 코드는 `battle_view.gd`의 기존 소품 루프(103~108행, «시설이 선 칸은 감춤»)를 본뜬 구조물별 데칼 수십 줄. S202 변경, EVAL 1~2개. **1~1.5일** | 붙여 지은 건물의 터가 겹칠 때 그리는 순서, 광장 위 건물의 터 처리. 마당 칸에도 짓게 두고, 새 건물이 서면 그 칸 소품을 감춘다(S201·S202와 같은 규칙) |
| F2 | **굴뚝 연기** | 집 6채와 작업장 굴뚝 위로 1~2칸 높이 연기를 4~6프레임 스프라이트로 돌린다. 준비 단계에만 | 7편 중 6편. 2D로 가장 가까운 예는 They Are Billions. Godot 문서 «Additive sprites are much faster to render»([Godot](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html)) | 그림 1줄, 코드 20~40줄. **반나절** | 입자는 소수점 위치에 그려져 정수배 화면에서 번질 수 있다. 그래서 스프라이트 애니가 낫다고 본다(미확인, 띄워서 확인) |
| F3 | **주민 모임 지점·목적 있는 이동** | 6명 가운데 2~3명은 우물·광장 가장자리에 모여 서고, 1~2명은 집과 가장 가까운 생산 시설 사이를 오간다. 머무는 시간과 목적지를 섞는다 | Against the Storm 개발진 «gather in one place»([Eremite](https://eremitegames.com/villager-routines/)). 일 없는 농민이 모닥불 앞에 앉는 Stronghold([GOG 포럼](https://gog.com/forum/stronghold_series/stronghold_hd_seems_impossible_to_have_enough_food)) | `residents()`는 시각 t의 순수 함수라 시뮬레이션은 그대로다. S104 문구(«마을 안을 돌아다니는 모습»)와 EV129(위치 2개, 움직임, 마을 안)에 들어간다. 코드 **1일 안팎**(일하는 프레임은 빼고 시작) | 6명이면 루프가 금방 보이므로 상태 3~4개를 섞는다. 주민이 건물을 가로질러 걷는 것은 지금과 같다 |
| F4 | **풀꽃 뭉치기 + 우물을 광장 모서리로** | 고르게 흩은 풀·자갈을 성벽 밑·광장 가장자리·우물 둘레에 무더기로 모으고 넓은 안쪽은 비운다. 우물은 광장 모서리로 옮기고 박석 3~4조각을 덧댄다(10/23 재판정 1순위) | «Real meadows clump»류 관습(Polycount 검색 요약), «Repeat these same clusters … vary the pattern»([Slynyrd 2](https://slynyrd.com/blog/2018/2/15/pixelblog-2-texture)), APL 61 가장자리 활동 | `bake_ground` 조정. S202 변경. **반나절** | 우물을 정중앙에 두지 않는다(APL 126) |
| F5 | **건물→광장 흙길 가지** | 건물이 완성되면 문 칸에서 광장이나 이미 있는 가지까지 BFS로 길을 구하고, F1과 같은 다진 흙에 불규칙한 경계로 그린다. 정문→거점 축·성벽과 나란한 띠·성문에 닿는 길은 금지. 광장을 뿌리로 하는 나무 모양이 된다 | 길 = 활동(Foundation·Settlers IV·Manor Lords), Lynch path, Kakariko 격자 길. 경계는 듀얼 그리드(겹침 5장 + 바탕 1장 + 회전, [Excalibur.js](https://excaliburjs.com/blog/Dual%20Tilemap%20Autotiling%20Technique)) | BFS는 60×27에서 가볍다. 바닥 다시 굽기는 지금 39ms라 60fps 한 프레임(16.7ms, 계산)보다 길다. 전투 중 완성될 때 끊길 수 있으니 길만 그린 겹 텍스처를 `ImageTexture.update()`로 갱신한다([Godot](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html)). 경계 마스크 그림 16가지. **1.5~2일** | «완성된 건물을 가장 가까운 길에 저절로 잇는» 상용 1차 사례는 찾지 못했다. 파괴 뒤 길을 남길지·흐릴지도 정해야 한다. 재질이 싫으면 Q4 |
| F6 | **집터 C′의 자리** | 그대로 넣으면 비용이 거의 없다(이미 만든 그림). 다만 세 관찰자가 덤불·거름 더미로 읽어 마을다움에 보태는 몫은 작다. 싼 변형도 있다. 7곳을 바깥 가장자리 대신 광장 둘레 핵심 구역에 두고, 집이 서면 그 칸 집터를 감춘다. 그러면 규칙 없이도 «옛 터에 다시 세운 집»이 생긴다(해석, 검증 안 됨) | Kingdom 폐허 = 이야기형, 상호작용·방해 없음([Kingdom wiki](https://kingdomthegame.fandom.com/wiki/Ruins)) | 소품 층으로 옮기기 반나절. 새 S 번호 | 집터를 바깥에 흩으면 시선도 바깥으로 흩어진다. 모으기와 반대 방향이다 |

권하는 순서는 이렇다. F1과 F4를 한 시안으로 먼저 띄우고, F2·F3를 더한 다음, F5는 «기각된 흙길과 다른가»를 따로 판정받는다. 판정 방법은 Carson의 기준을 빌린다. 관객이 «여기가 어디인가»에 «in the first 15 seconds» 답하지 못하면 실패다 ([Game Developer, Carson](https://www.gamedeveloper.com/design/environmental-storytelling-creating-immersive-3d-worlds-using-lessons-learned-from-the-theme-park-industry)). 바꾼 화면을 설명 없이 보여 주고 «무슨 장소냐»를 묻는다. 이어서 이전과 같은 Gemini 두 단계(설명 없이 → 설명 뒤)로 함정 여섯이 다시 나오는지 본다. 1/4로 줄이거나 흐리게 본 화면에서 시설·유닛이 여전히 먼저 보이는지도 확인한다(Riot 위계). 숫자 대리 지표로는 «단일 흙색 비율»을 다시 잴 수 있다. 지금 93.5%, Kakariko 맨풀 31.8%다. 다만 목표치를 정할 근거는 없다.

### 11/9~30 수정·추가 기간 — 코드·규칙

| # | 제안 | 내용 | 근거 | 비용(Claude 추정) | 결정 |
|---|---|---|---|---|---|
| L1 | 건물 크기 키우기 | 집 2×2, 생산 시설 3×2~3×3 | Warcraft I·Dune II 비례 | 배치·충돌·길 찾기 막힌 칸(I5)·클릭 판정·시설 그림·EVAL 다수. **3~5일** | S173 변경 → Q1. F1을 먼저 보고 정하기를 권함 |
| L2 | 모아 짓게 하는 규칙 | 거점이나 다른 건물 2~3칸 안에 지으면 작은 이득(놓기 전에 반경을 미리 보여 줌) 또는 건설 반경 | K&C 이웃 +3, Islanders «translucent sphere» 미리보기([Wikipedia](https://en.wikipedia.org/wiki/Islanders_(video_game))), TAB 반경 10칸(≈314칸, 계산) | 규칙·미리보기 UI 1~2일 + 밸런스 | S43 «마을 어디나» → Q5. 디펜스라 모으면 한꺼번에 위험해진다. TAB처럼 «한 칸 띄우기»를 짝지을 수 있음 |
| L3 | 집터 재건 자리 | 집터 위에 집을 지으면 싸거나 바로 지어지고 «옛 집이 다시 선다» | Kingdom Rush 무너진 집 150금, CoC 폐허 성 재건, Kingdom 배 복원([wiki](https://kingdomthegame.fandom.com/wiki/Boat)) | 1~2일 | Q6. 집터를 핵심 구역에 모아 두면 흩어짐이 줄고, «슬롯처럼 읽힘»이 오해가 아니라 정답이 된다. 강제가 아니라 선택 보너스로 둬야 Thronefall의 «순서 고정» 비판을 피한다 |
| L4 | 주민 피신·복귀 | 전투가 시작되면 종소리가 한 번 울리고 주민이 집으로 뛰어 들어간다. 연기가 멎고 덧문이 닫힌다. 전투가 끝나면 주민이 나와 광장에 잠깐 모인다 | Town Bell([AoE wiki](https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_II)), 검색 요약), Shelter Inside([Crate 패치 노트](https://forums.crateentertainment.com/t/farthest-frontier-v1-1-1/154524)). Gemini 1·2차가 둘 다 다음 후보로 꼽음 | 1~2일 | 복귀를 «전투 단계 끝» 사건 하나에 묶는다. Farthest Frontier는 습격 뒤 주민이 집에 갇히는 버그를 보고받았다([Crate 포럼](https://forums.crateentertainment.com/t/after-a-bandit-raid-townspeople-are-locked-in-buildings/154557)). 전투 중 주민이 화면에서 빠지니 유닛과 헷갈릴 일도 사라진다 |
| L5 | 레벨 따라 자라는 둘레 | 레벨 2가 되면 광장을 넓히고 가지를 늘리고, 집터 일부를 치운다 | Kingdom 단계별 둘레, 순수 장식만(COSMETIC 텐트·Northgard 승수 깃발 [wiki](https://northgard.fandom.com/wiki/Town_Hall)) | 1일 | 레벨이 1~2뿐이라 효과가 작다. Kingdom처럼 공짜 방어물을 주면 밸런스가 바뀌므로 장식만 |
| L6 | 배경 집(플레이어가 짓지 않는 집) | 마을 몇 곳에 클릭되지 않는 집을 미리 둔다 | Bad North 지킬 집, WC3 «Huts are neutral buildings primarily used for map decoration»([wiki](https://warcraft.wiki.gg/wiki/Hut_(Warcraft_III))) | 1일 + 오해 판정 | 칸을 막으면 S43 규칙 변경이다. 막지 않으면 «위에 지으면 사라지는 집»이 어색하다. 구분은 외곽선 없음·명도 한 단계 낮춤·다른 지붕색(Mindustry derelict 팀 색 [#4d4e58](https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Team.java))으로 |
| L7 | 플레이어 바닥 깔기(WBS 7장 후보) | 건설 패널에 «바닥» 칸. 재질 2~3종, 왼쪽 드래그로 칠하고 오른쪽 드래그로 지움, 마을 0~26행만 | 아래 문단 | UI·저장·재질 쌍마다 경계 타일 15~16장. **3~5일** | Q8. 자동 층(F1·F5) 다음에 두기를 권함 |
| L8 | 동물·마을 환경음 | 닭 2~3마리·개 1마리를 성벽 안에만 둔다. 준비 단계에 닭·망치·웅성 소리 층을 깔고 전투에는 끈다 | WC3 critter([wiki](https://warcraft.wiki.gg/wiki/Critters)), Anno «audio design … breathe life into the world»([Anno Union](https://www.anno-union.com/?p=9933)) | 각 1일 | 동물·소리가 마을다움을 높인다는 개발자 진술은 찾지 못했다. 소리는 5.3과 함께 |
| L9 | 바탕을 풀로 되돌리기 | 바탕은 풀, 건물 터·길·광장만 흙 | 사례 근거가 가장 강함(Northgard·AoE II·Songs of Syx) | 1일 | S169 변경 → Q2 |

L7에는 근거를 따로 적는다. 경영·생존 장르의 바닥 깔기에는 거의 언제나 작은 보상이 붙어 있었다. RimWorld 바닥은 이동 속도·Beauty·청결을 바꾸고 다른 건설을 막지 않는다 ([RimWorld wiki](https://rimworldwiki.com/wiki/Floors)). Factorio Concrete는 걷기 속도 140%다 ([Factorio wiki](https://wiki.factorio.com/Concrete)). ONI 타일은 장식 점수와 달리기 속도를 준다 ([ONI wiki](https://oxygennotincluded.wiki.gg/wiki/Tiles)). 보상 없는 꾸밈 바닥이 크게 쓰인 곳은 꾸미기가 본 놀이인 게임이다. Animal Crossing의 커스텀 길(검색 요약)이나 «No management, combat or goals»를 내건 Tiny Glade가 그렇고 ([Steam](https://store.steampowered.com/api/appdetails?appids=2198150&l=english)), Tiny Glade는 출시 한 달에 616,528장이 팔렸다(개발사가 준 수치, 검색 요약, [GIGAZINE](https://gigazine.net/gsc_news/en/20241120-tiny-glade-600k-sold-reason)). TD·RTS 본류에서 꾸밈 바닥 깔기는 찾지 못했다. 그래서 «꾸밈만» 바닥 깔기는 꾸미기를 좋아하는 일부 플레이어만 쓸 기능이고, 모든 플레이어에게 보이는 «마을로 안 보임» 문제는 풀지 못한다(해석). 넣는다면 조건이 있다. 공짜이거나 아주 싸고, 드래그 몇 번에 끝나고, 우클릭으로 쉽게 지우고, 건설을 막지 않고, 경계가 자동으로 예뻐야 한다.
