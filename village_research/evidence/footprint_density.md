# 건물 크기(footprint)·밀도·군집 — 몇 채의 건물이 «마을»로 읽히게 하는 조건

> 갈래: Claude 가설 ①(1,620칸에 많아야 11채 → 밀도 낮음)·②(건물 그림이 한 칸 아이콘 크기) 확인·반증.
> 표기: «(스크린샷 직접 봄: URL)» = 스팀 appdetails의 path_full 이미지를 내려받아 직접 본 관찰. «(검색 요약 기준)» = WebSearch 요약으로만 확인하고 원문은 열지 않음. 위키는 MediaWiki API로 원문 wikitext를 읽었다.
> 우리 화면 측정: `art/trial/preview/village_mood_final/2_overview.png`(1920×940). 성벽이 화면 폭 1920px을 다 채우므로 60칸×16px×**2배**로 보고 잼(가정).

## 1. 집·생산 건물의 footprint는 몇 칸이고, 유닛 대비 몇 배인가? 집을 1칸으로 두는 게임이 있나?

### Takeaway
조사한 게임에서 집·생산 건물은 거의 다 **2×2 이상**(생산·중심 건물 3×3~4×4)이고, **1×1은 벽·길·포탑·전력탑 같은 «부품»** 자리다. 우리 집은 바닥 1칸·보이는 그림 16×24px, 주민 약 9×14px라서 **폭 기준 유닛의 약 1.8배**다. 비교작은 2~5배 이상이므로 가설 ②는 **확인**된다. 1칸 집의 유일한 사례(Kingdoms and Castles 오두막)는 주민이 칸보다 훨씬 작고, 집을 붙여 줄로 짓게 만드는 규칙이 있어서 성립한다.

### Cited Findings
**우리 게임(기준선)**
- 집 그림: 보이는 픽셀 16×24(가로 1칸, 세로 1.5칸), 바닥 1칸. 주민: 약 9×14px. 그래서 집/주민 비율은 폭 약 1.8배, 키 약 1.7배다. 병영 천막·작업장·교회도 눈대중으로 폭 1칸(14~17px), 높이 25~30px. (우리 화면 직접 잼: `art/trial/preview/village_mood_final/2_overview.png`, 6배로 확대해 픽셀을 셈)

**Warcraft: Orcs & Humans (16px 타일 — 우리와 같은 칸 크기)**
- 오픈소스 재구현 War1gus의 건물 정의: Farm 그림 48×48, Town hall·Barracks·Church·Lumber Mill 그림 64×64, Stormwind keep 80×80. 같은 파일 helpers에서 `TileSize = { size[1] / 16 - 1, size[2] / 16 - 1 }`로 바꾸므로 **Farm 2×2칸, 회관·병영·교회 3×3칸, 성 4×4칸**이다. 그림은 바닥보다 사방 반 칸씩(가로세로 합 1칸) 더 크다 — [war1gus buildings.lua](https://github.com/Wargus/war1gus/blob/master/scripts/buildings.lua), [war1gus helpers.lua](https://github.com/Wargus/war1gus/blob/master/scripts/helpers.lua)
- 같은 helpers에서 유닛은 `TileSize = { 1, 1 }, BoxSize = { 15, 15 }`이다. 그래서 농장은 유닛 폭의 2배, 병영은 3배다. 1×1 «건물»은 Road·Wall뿐(그림 16×16) — [war1gus helpers.lua](https://github.com/Wargus/war1gus/blob/master/scripts/helpers.lua), [war1gus buildings.lua](https://github.com/Wargus/war1gus/blob/master/scripts/buildings.lua)
- 참고: War1gus 정의는 원작 데이터를 옮긴 재구현이다. 원작 개발사 문서는 아니다.

**Dune II (OpenDUNE 소스의 구조물 표)**
- Construction Yard·Windtrap·Infantry Barracks·Light Factory·Silo·Radar Outpost는 2×2, Heavy Factory·Spice Refinery·Repair Facility는 3×2, Palace·Starport는 3×3이다. **1×1은 Concrete Slab·Wall·Cannon/Rocket Turret뿐** — [OpenDUNE structureinfo.c](https://github.com/OpenDUNE/OpenDUNE/blob/master/src/table/structureinfo.c)
- Dune II 타일이 16px이라는 점은 이번에 출처로 확인하지 못했다(미확인).

**Age of Empires II**
- House `Size = 2×2 tiles`, Barracks `3×3 tiles`, Town Center `4×4 tiles` — [AoE wiki House](https://ageofempires.fandom.com/wiki/House_(Age_of_Empires_II)), [Barracks](https://ageofempires.fandom.com/wiki/Barracks_(Age_of_Empires_II)), [Town Center](https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_II))
- Villager 정보 상자는 `Size = 0.2`다. 이것이 충돌 반경(타일 단위)이라면 주민 폭은 0.4칸이고 집은 그 약 5배다. 반경이라는 해석은 미확인 — [AoE wiki Villager](https://ageofempires.fandom.com/wiki/Villager_(Age_of_Empires_II))

**They Are Billions**
- «Tesla Towers … take up 1 cell», «colonist houses and most resource generation buildings take up 2×2 spaces», «The largest buildings are a whopping 4×4 cells» — [KeenGamer preview](https://www.keengamer.com/articles/previews/they-are-billions-preview/)

**Kingdoms and Castles (1칸 집의 사례)**
- Hovel `footprint = 1x1`, Cottage `1×2`. Hovel은 «half the size of a Cottage and one quarter the size of a Manor»라서 Manor는 2×2로 읽힌다. Hovel은 «5 Peasants per tile». 그리고 «They also require more roads since every house should be connected to a road» — [K&C wiki Hovel](https://kingdomsandcastles.fandom.com/wiki/Hovel), [Cottage](https://kingdomsandcastles.fandom.com/wiki/Cottage)
- 관찰: 오두막은 주민보다 폭으로 대략 5~10배 크다(주민은 칸보다 훨씬 작음). 오두막들이 지붕을 맞대고 줄지어 있고, 그 옆에 깃발 광장·길·밭이 붙는다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_c720d04f507059f75d1f5dc040e5123dcf36826b.1920x1080.jpg)

**Stardew Valley (16px 타일 픽셀아트, 농장 건물)**
- Coop: «placed anywhere with a 6x3 space free» — [Stardew fandom Coop](https://stardewvalley.fandom.com/wiki/Coop)
- Shed 바깥 7×3(21칸), Barn 바깥 7×4(28칸). 업그레이드해도 바깥 크기는 그대로다. 7×7이라고 적은 글도 있는데 위키와 어긋나 오류로 보인다(검색 요약 기준) — [Stardew wiki Shed](https://stardewvalleywiki.com/Shed), [BisectHosting barn guide](https://www.bisecthosting.com/it-it/blog/stardew-valley-barn-upgrades-livestock)
- 일반 픽셀아트 관행: 캐릭터는 흔히 «한 칸 폭 × 두 칸 높이», 도시 건설 강좌는 건물을 16×16 격자 단위로 잡는다(검색 요약 기준) — [Slynyrd Pixelblog 22](https://www.slynyrd.com/blog/2019/10/21/pixelblog-22-top-down-character-sprites)

**The Last Spell (픽셀아트 디펜스 + 낮에 마을 건설)**
- 2021년 가이드 기준: House 2타일, Temple 4타일, Inn 4타일, Mana Well 1타일. 벽은 1×1 차단물(검색 요약 기준, 정식판 수치는 미확인) — [steamah 건물 가이드](https://steamah.com/the-last-spell-buildings-detailed-list-guide/), [Pro Game Guides](https://progameguides.com/the-last-spell/can-you-rotate-buildings-in-the-last-spell/)
- 관찰: 생산 단계 화면에서 건물마다 받침(plinth)이 있고, 영웅보다 폭 4~5배다. 건물 사이를 울타리·통·수레·선로·자루가 채운다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg)

**Thronefall (격자 없음)**
- 관찰: 집은 병사보다 폭 약 2.5~3배, 본성(great hall)은 약 6배다. 집 둘레에 점선으로 된 «자리» 윤곽이 보인다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg)

**Rise to Ruins (픽셀아트, 마을 + 밤 디펜스)**
- 관찰: 주민은 폭 약 10~12px, 집·작업장 지붕은 60~100px라서 폭 기준 약 6~8배다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_ca30ef5b4cee617bd36017da2953777f19b151c2.1920x1080.jpg)

### Inferences
- 비교표(폭 기준 «집 또는 소형 생산 건물 ÷ 유닛»):

  | 게임 | 칸 | 집(소형) footprint | 생산·중심 | 1×1인 것 | 집/유닛 폭 |
  |---|---|---|---|---|---|
  | **우리** | 16px | **1×1**(그림 16×24) | 1×1 | 집·시설 전부 | **≈1.8** |
  | Warcraft I | 16px | Farm 2×2(그림 48×48) | 3×3~4×4 | 길·벽 | 2(농장)·3(병영) |
  | Dune II | (16px, 미확인) | — | 2×2~3×3 | 슬래브·벽·포탑 | — |
  | AoE II | — | 2×2 | 3×3~4×4 | 없음(벽 제외) | ≈5(반경 해석 시) |
  | They Are Billions | — | 2×2 | 최대 4×4 | 테슬라 탑 | — |
  | K&C | — | 1×1(Hovel)~2×2 | — | 오두막 | ≈5~10(관찰) |
  | Thronefall | 격자 없음 | — | — | — | ≈2.5~3(관찰) |
  | Rise to Ruins | 픽셀 | — | — | — | ≈6~8(관찰) |

- 이 표로 보면, 우리 마을에서 집·생산 건물은 비교작이 «벽 조각·포탑»에 쓰는 크기·비율로 그려져 있다. 그래서 «건물»이 아니라 «소품·아이콘»으로 읽힐 가능성이 크다. 가설 ② 확인.
- **같은 16px 칸에서 가장 가까운 선례는 Warcraft I**이다. 농장이 48×48 그림으로 2×2(32×32) 바닥을 덮는다. 우리 시설 캔버스도 이미 48×48이므로, «집 2×2 바닥 + 48px 높이», «생산 시설 3×2~3×3»이 WC1·Dune II와 같은 비례가 된다. 다만 캔버스·충돌·배치 격자를 함께 바꿔야 하는 설계 결정이다.
- 1칸 집을 유지하는 길도 있다(K&C형). 이 경우 (a) 주민을 칸보다 훨씬 작게 하거나, (b) 집을 붙여 짓게 유도하거나(K&C 이웃 보너스, 2번 항목), (c) 집 + 마당을 한 덩어리로 묶어 실질 면적을 키워야 한다(3번 항목). 우리 주민(≈0.6칸 폭)은 이미 크므로 (b)(c) 쪽이 현실적이다.
- 크기를 키워도 공간 문제는 거의 없다. 집 6채 2×2 + 시설 4채 3×3 = 60칸으로 마을 1,620칸의 3.7%다(2번 항목 표).

### Gaps
- Warcraft III 건물 경로맵(pathing) 크기·유닛 충돌 크기: Liquipedia가 429(요청 과다)로 막혀 확인하지 못함.
- Stronghold/Crusader 오두막(hovel) footprint: 검색 결과에 수치 없음.
- Diplomacy is Not an Option 집 크기: 팬 위키 House I 문서에 크기 항목이 없음. Northgard·Songs of Conquest는 칸 격자가 아니라 «자리» 단위라 칸 수 비교가 해당되지 않음.
- Stardew 농부 스프라이트 16×32px은 널리 알려진 값이지만 이번에 1차 출처로 확인하지 못함(미확인).
- The Last Spell 정식판 footprint, Rise to Ruins 건물 칸 수: 1차 출처 없음.

## 2. 건물 수가 적을 때(10채 안팎) 어떻게 마을처럼 보이게 하나 — 거리·덮는 비율·군집·구역·영역 좁히기·카메라

### Takeaway
비교작도 초반 마을의 건물 수는 적다(K&C 초기 «Hamlet» = 성채 + 오두막 2 + 길 2칸, Northgard 시작 타일 = 회관 + 4채, Songs of Conquest 작은 정착지 = 자리 3개, Bad North 섬 = 집 1~3채). 공통점은 **그 적은 수를 좁은 영역(한 타일·한 섬·성벽 안·본성 둘레)에 모은다**는 것이다. 우리는 11채가 1,620칸(약 1.8화면)에 흩어져 바닥 덮개가 **0.7%**다. 따라서 가설 ①은 **부분 확인**이다. 문제는 «수»보다 «수 ÷ 영역»과 «흩어짐»이다.

### Cited Findings
- **Kingdoms and Castles**: 1년 차 예시 화면은 «the keep, two hovels and two tiles of road»다. 시작 나무 12로 «two hovels … and two tiles of road»를 짓고 «place … the hovels near each other and next to the road»라고 권한다 — [K&C wiki Hamlet Guide](https://kingdomsandcastles.fandom.com/wiki/Hamlet_Guide)
- K&C: «Houses must be within three tiles of a roads … happier if they are within one tile of a road (+3)», «Peasants like having neighbours: you get a +3 bonus if the house is within two tiles of another house» — [K&C wiki Hamlet Guide](https://kingdomsandcastles.fandom.com/wiki/Hamlet_Guide)
- K&C 관찰: 2년 차 «A Small Village»(인구 44) 화면이다. 성채·오두막 약 10채·풍차·광장이 화면 폭의 약 1/4 안에 모였다. 집 사이 간격은 0~1칸, 밭이 그 옆에 붙는다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_c720d04f507059f75d1f5dc040e5123dcf36826b.1920x1080.jpg)
- **Northgard**: «Your Clan starts with one initial tile which contains the Town Hall, 4 additional buildings can be built on this tile», «Each tile has a varying building capacity, ranging from 2 to 4», 개발로 +1 — [Northgard wiki Tile](https://northgard.fandom.com/wiki/Tile)
- Northgard 관찰: 건물이 영역(타일) 단위로 모여 섬처럼 무리 짓는다. 무리 사이는 숲·바위다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg)
- **Songs of Conquest**: 정착지에는 고정 건물 목록 대신 small·medium·large «building plots»가 있다. 한 가이드 기준 Small Settlement는 소 2 + 중 1, Large Settlement는 소 3 + 중 2 + 대 1, Town은 소 7 + 중 3 + 대 2. 다른 기사는 «two building slots»로 시작한다고 해 판본마다 다르다(검색 요약 기준) — [CommonSenseGamer 가이드](https://commonsensegamer.com/songs-of-conquest-guide/), [GameBanshee preview](https://www.gamebanshee.com/xf84a), [Dot Esports](https://dotesports.com/general/news/songs-of-conquest-how-to-get-more-troops)
- Songs of Conquest 관찰: 성 둘레 자리들이 성벽 안 한 덩어리로 모여 있다. 바닥은 돌길·흙이다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/867210/ss_1547033ea1673abf58e8e76cc87f94f3f055c39a.1920x1080.jpg)
- **They Are Billions**: «you can only build structures inside the energy coverage of the colony», «The Command Center has energy coverage radius of 10 cells». 넓히려면 Tesla Tower가 필요하다 — [Numantian Games 개발 블로그](https://numantiangames.com/News/2017-10-02-they-are-billions-update-build-your-colony/)
- **Thronefall**: 전투·건설 맵 10개가 «hand-crafted maps with preset blueprints»다(검색 요약 기준) — [Gameluster review](https://gameluster.com/thronefall-review-holding-on-for-one-last-night/). 스팀 사용자 글에 따르면 집은 대개 본성 가까이 자리 잡혀 있다(검색 요약 기준, 플레이어 의견) — [Steam 토론](https://steamcommunity.com/app/2239150/discussions/0/4844274677391778281)
- Thronefall 관찰: 초반 맵에서 본성 + 집 4채 + 우물이 말뚝 울타리 안 작은 반경에 모였다. 집 사이 거리는 집 폭 1~2개다. 그 밖에 망루 3·풍차 + 밭 두 덩이가 길 따라 흩어져 있다. 한 화면에 마을 전체가 들어온다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg)
- **Bad North** 관찰: 플레이어가 짓지 않는 미리 놓인 집 1~3채가 작은 섬 위에 있다. 카메라가 섬 전체를 한 화면에 담는다. 집이 적어도 섬(영역) 자체가 작아 «마을»로 읽힌다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_8c3675db0a388f3717e530c93d0db27f526a5c0a.1920x1080.jpg, https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_7378fcbe0eeb7194b5a8a218c1c49b8f8056b968.1920x1080.jpg)
- **Stronghold Crusader HD** 관찰: 성벽으로 둘러싼 작은 구역 안에 건물 몇 채가 빽빽하다. 성벽 밖은 빈 모래땅이다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/40970/ss_b2da292b97471df65e7db87ef15b84ae53799be0.1920x1080.jpg)
- **AoE II**: «Houses are often built in clusters to save space for buildings and resource extraction» — [AoE wiki House](https://ageofempires.fandom.com/wiki/House_(Age_of_Empires_II))
- 마을 그림 요령 글: 건물을 지형·길에 맞춰 앉히고, 가게들이 작은 모임 공간을 마주 보면 «town center»처럼 읽힌다(검색 요약 기준, 게임 개발 1차 출처 아님) — [How To Draw A Village](https://dev.publishnews.com.br/draw-village)
- **우리 기준선**: 마을 60×27 = 1,620칸, 건물 최대 11채(집 6·병영·사격장·작업장·교회 + 거점). 지금 화면에서 집과 시설이 마을 전역에 띄엄띄엄 놓였다. 이웃한 집 사이는 대개 5~8칸이고, 광장 왼쪽 무리와 오른쪽 무리 사이는 12칸 이상이다(2배 화면에서 32px = 1칸으로 잼). (우리 화면 직접 봄: `art/trial/preview/village_mood_final/2_overview.png`, `3_wide.png`)

### Inferences
- 우리 마을 수치(계산값, 출처 없는 추론):
  - 지금 11채 × 1칸 = 11칸 → 마을 면적의 **0.7%**. 건물 한 채당 평균 약 147칸(≈12×12칸)의 빈 땅이다.
  - 기본 배율 한 화면은 640×360 ÷ 16 = 40×22.5칸 = 900칸이다. 마을은 그 1.8배라서, 고르게 퍼지면 한 화면에 건물 약 6채가 빈 흙 위에 떠 있는 꼴이다.
  - 크기·묶기 시나리오:

    | 시나리오 | 덮는 칸 | 마을 1,620칸 대비 | 핵심 구역 30×15(450칸) 대비 |
    |---|---|---|---|
    | A 지금(전부 1×1) | 11 | 0.7% | 2.4% |
    | B 집 2×2 · 시설 4채 3×3 | 6×4 + 4×9 = 60 | 3.7% | 13% |
    | C B + 마당(집 3×3, 시설 5×4 영역) | 6×9 + 4×20 = 134 | 8.3% | 30% |

  - They Are Billions 초반 건설 가능 영역(반경 10칸 → 약 314칸)에 2×2 집 + 1칸 간격을 넣으면, 10채 안팎으로 20~30%가 찬다(계산). Northgard는 한 타일에 회관 + 4채다. 이런 «한 덩어리»의 밀도는 C를 핵심 구역에 모은 경우(≈30%)와 비슷한 수준이다.
- 비교작이 적은 건물로 마을을 만드는 방법은 다섯 가지로 묶인다. ① 모으기(본성·회관 둘레, 이웃 2칸 이내), ② 영역 자체를 작게(섬·타일·성벽 안), ③ 건물마다 자리·마당을 둬 실질 면적 키우기, ④ 길·광장으로 잇기, ⑤ 카메라가 그 덩어리를 한 화면에 담기. 우리 마을은 ①②⑤가 비어 있다. 1,620칸 전체를 «마을»로 두면 11채로는 어떤 크기에서도 덮개 10%를 넘기 어렵다(시나리오 C도 8%).
- 그래서 «마을 영역을 줄이거나 핵심 구역을 정하는 것» + «건물 크기·마당 키우기»를 함께 해야, 비교작 같은 «덩어리» 밀도(대략 20~30%)에 닿는다. 이것은 추론이며, 마을다움이 몇 %부터 생기는지에 대한 출처 있는 기준은 찾지 못했다.

### Gaps
- «바닥 덮는 비율이 몇 %부터 마을로 읽히나»에 대한 연구·개발자 발언은 찾지 못함. 위 %는 우리 계산과 비교작 규칙에서 끌어낸 것.
- Thronefall 개발자가 집 배치·마을 가독성을 직접 말한 자료는 찾지 못함(인터뷰는 «가독성 있는 색»·접근성만 언급).
- Against the Storm의 집–화로(Hearth) 거리 규칙: 공식 위키가 403으로 막혀 미확인. 검색 요약상 «두 번째 화로를 지으면 집 지을 자리가 늘어난다»는 플레이어 글만 있음(미확인).

## 3. 본채 + 부속(헛간·창고·울타리·작업 마당)으로 이뤄진 «복합 건물» 사례와 효과

### Takeaway
여러 게임이 건물 하나를 «본채 + 땅에 깔리는 부속(밭·울타리 마당·작업물 더미)»으로 그린다. 그러면 같은 건물 수로도 바닥을 덮는 면적과 «사람이 일하는 흔적»이 몇 배로 는다. 대표 사례는 Manor Lords의 burgage plot(집 + 뒷마당 확장), Rise to Ruins의 울타리 작업 마당, Thronefall·K&C·AoE II의 «풍차/방앗간 + 밭»이다. 반대로 같은 모양 부지를 찍어 내면 «공장에서 찍은 것 같다»는 플레이어 비판이 나온다.

### Cited Findings
- **Manor Lords**: 스팀 소개문 «Assign areas for housing and watch your residents build their homes in accordance with the historical burgage plot system» — [Steam 상점](https://store.steampowered.com/app/1363080/). Vegetable Garden은 «Burgage plot Extension»으로 1단계 부지 안에 지을 수 있고, 부지가 클수록 생산이 는다. 두 집이 뒷마당 확장 하나를 함께 쓸 수도 있다(검색 요약 기준) — [VideoGamer wiki Vegetable Garden](https://videogamer.com/wiki/Manor-Lords/Vegetable-Garden)
- Manor Lords 관찰: 집마다 뒤로 긴 울타리 부지(텃밭)가 딸려 있다. 길 따라 늘어선 집 + 뒷마당의 띠가 마을 모양을 만든다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg)
- Manor Lords 비판: 같은 모양 부지에 같은 집이 같은 방향으로 찍혀 나온다는 불만이 있다. Foundation처럼 주민이 지정 구역 안에서 자리를 골라 집이 «organic»하게 자라는 방식을 더 낫다고 본다(검색 요약 기준, 플레이어 의견) — [Steam 토론](https://steamcommunity.com/app/1363080/discussions/0/4355619782840362614)
- **Rise to Ruins** 관찰(픽셀아트 디펜스 마을): 건물마다 나무 울타리로 둘러싼 작업 마당이 있고, 그 안에 통·장작·돌 더미·작업대가 놓인다. 건물 수는 10여 채지만 마당이 바닥의 큰 몫을 덮어 마을로 읽힌다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_ca30ef5b4cee617bd36017da2953777f19b151c2.1920x1080.jpg)
- **Thronefall** 관찰: 농장은 «풍차 1 + 밭 2판», 집은 점선 자리 윤곽 안에 놓인다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg)
- **Kingdoms and Castles**: 초반에는 «one farm per hovel»을 권하고, 농장·과수원은 길에서 3칸 안에 지어야 한다 — [K&C wiki Hamlet Guide](https://kingdomsandcastles.fandom.com/wiki/Hamlet_Guide). 관찰: 밭 판들이 집 무리 바로 옆에 붙는다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_c720d04f507059f75d1f5dc040e5123dcf36826b.1920x1080.jpg)
- **AoE II** 관찰: 방앗간·풍차 둘레에 밭이 둘러 붙고, 집은 밭 가장자리에 모인다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/813780/ss_ea0429a12f9d65f3e6b5384e0117fceef2109e45.1920x1080.jpg)
- **Stardew Valley** 관찰: 농가 + 헛간 + 닭장 + 울타리 + 밭이 한 덩어리로 화면을 채운다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_b887651a93b0525739049eb4194f633de2df75be.1920x1080.jpg)
- **The Last Spell** 관찰: 건물 받침 + 울타리 + 통·수레·자루·선로가 건물 사이 빈 땅을 메운다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg)
- **Islanders** 비평: 주민 애니메이션이 없어 섬에 «sense of life»가 부족하다는 지적이 있다 — [Wikipedia Islanders](https://en.wikipedia.org/wiki/Islanders_(video_game))

### Inferences
- 복합 건물은 두 가설을 동시에 줄이는 가장 값싼 수단으로 보인다(추론). 본채 그림은 그대로 1~2칸으로 두고, 바닥에 깔리는 2×2~5×4 «마당 데칼»(울타리·텃밭·작업물)만 더하면 덮개가 시나리오 A→C 수준(0.7%→8%대)으로 뛴다. 건물 높이·충돌을 바꾸지 않아도 된다.
- 우리 시설에 대응시킨 예(추론, 1차 출처 없음): 집 = 본채 + 텃밭·장작더미·작은 울타리, 병영 = 천막 + 훈련 허수아비 마당, 사격장 = 과녁 줄 + 화살 통, 작업장 = 목재 더미·작업대 마당, 교회 = 마당·묘지 울타리. Rise to Ruins처럼 «울타리로 둘러싼 마당»은 16px 픽셀아트에서도 이미 통하는 표현이다(관찰).
- Manor Lords 비판을 보면, 부속을 똑같이 찍어 내면 오히려 인공적으로 보인다. 그러니 변형 2~3개를 두거나 무작위 방향·부속 구성을 쓰는 편이 안전하다(추론).

### Gaps
- 복합 건물이 «마을다움» 평가를 얼마나 올리는지 정량 자료(플레이 테스트·설문)는 찾지 못함.
- Farthest Frontier·Foundation의 집 부속(정원·마당) 구조는 이번에 1차 확인하지 못함(Foundation은 플레이어 토론 요약에서만 언급).

## 4. 아무 데나 짓게 했을 때 흩어져 보이는 문제를 게임은 어떻게 막거나 줄이나

### Takeaway
게임들이 쓰는 장치는 강한 것부터 다음 순서다: **고정 자리**(Thronefall·Songs of Conquest) → **영역당 개수 제한**(Northgard) → **건설 반경**(They Are Billions 전력 10칸, StarCraft 파일론 6.5) → **근접 보너스·점수**(K&C 이웃 2칸·길 1칸, Islanders 점수 구) → **배치 간격 규칙**(They Are Billions) → **공간 절약 같은 창발적 이유**(AoE II). 고정 자리는 그림이 가장 확실하지만 자유도를 없앤다. 우리처럼 «빈 땅 어디나»를 유지하려면 근접 보너스·건설 반경 같은 «부드러운» 장치가 맞다(추론).

### Cited Findings
- **고정 자리 — Thronefall**: «Its structures were designed to be placed only in pre-set areas, allowing the developers to continue adding new types of buildings and features without drastically affecting the experience of any of the previous levels» — [Wikipedia Thronefall](https://en.wikipedia.org/wiki/Thronefall). 리뷰는 «nodes that can only accept one specific building each» 때문에 판마다 최적 빌드 순서가 굳어진다고 비판한다(검색 요약 기준) — [GameGeeker](https://gamegeeker.com/games/thronefall?market=GB)
- **고정 자리 — Songs of Conquest**: 정착지 둘레 small·medium·large plot에 무엇을 지을지 고른다(검색 요약 기준) — [GameBanshee preview](https://www.gamebanshee.com/xf84a)
- **영역당 개수 — Northgard**: 타일마다 건물 수용 2~4, 시작 타일은 회관 + 4 — [Northgard wiki Tile](https://northgard.fandom.com/wiki/Tile)
- **건설 반경 — They Are Billions**: 전력 범위 안에만 지을 수 있고, Command Center 반경은 10칸이다. 범위를 넓히는 Tesla Tower가 끊기면 건물이 멈춘다 — [Numantian Games 블로그](https://numantiangames.com/News/2017-10-02-they-are-billions-update-build-your-colony/)
- **건설 반경 — StarCraft**: «The pylon has a power radius of 6.5». 프로토스 건물은 psionic matrix와 연결이 끊기면 멈춘다 — [StarCraft wiki Pylon](https://starcraft.fandom.com/wiki/Pylon)
- **근접 보너스 — Kingdoms and Castles**: 집은 길에서 3칸 안에 지어야 하고, 길 1칸 안이면 +3, 다른 집 2칸 안이면 +3 행복 — [K&C wiki Hamlet Guide](https://kingdomsandcastles.fandom.com/wiki/Hamlet_Guide)
- **근접 점수 — Islanders**: 건물을 고르면 «translucent sphere»로 점수 반경이 보이고, «Buildings gain points from being placed near relevant structures, but lose points for incompatible ones». 놓기 전에 점수를 미리 보여 준다 — [Wikipedia Islanders](https://en.wikipedia.org/wiki/Islanders_(video_game))
- Islanders 비평: 아트 스타일 때문에 점수를 덜 받더라도 «in locations that looked pretty»에 놓게 된다는 리뷰가 있다 — [Wikipedia Islanders](https://en.wikipedia.org/wiki/Islanders_(video_game))
- **배치 간격 — They Are Billions**: «Most buildings cannot be next to other buildings as you need to have at least one cell in between», «colonist dwellings can be placed next to each other up to two rows», «the Market reduces the food consumed by the nearby colonist dwellings» — [Numantian Games 블로그](https://numantiangames.com/News/2017-10-02-they-are-billions-update-build-your-colony/)
- **창발 — AoE II**: 공간 절약 때문에 집을 모아 짓는다 — [AoE wiki House](https://ageofempires.fandom.com/wiki/House_(Age_of_Empires_II))
- **자동 배치 — Foundation(플레이어 언급)**: 주민이 지정 구역 안에서 자리를 골라 집이 «organic»하게 자란다(검색 요약 기준, 플레이어 의견) — [Manor Lords Steam 토론](https://steamcommunity.com/app/1363080/discussions/0/4355619782840362614)

### Inferences
- 우리 규칙(«마을 빈 땅 어디에나», 집 최대 6채)을 유지하면서 흩어짐을 줄이는 선택지를 덜 강제적인 것부터 정리하면(추론, 결정은 사용자 몫):
  1. **배치 미리보기 + 근접 보너스**(K&C·Islanders형): 거점 또는 다른 건물 2~3칸 안에 지으면 작은 이득(주민 행복·건설 속도 등)을 주고, 놓기 전에 반경을 보여 준다. 자유는 유지하면서 모으는 쪽이 이득이 된다.
  2. **건설 반경**(TAB·파일론형): 거점·기존 건물에서 N칸 안에만 지을 수 있게 한다. 마을이 거점에서 자라 나가는 모양이 자동으로 생긴다. 반경 10칸이면 약 314칸이라 시나리오 C 기준 덮개가 40%대가 된다(계산).
  3. **자리 격자·스냅**(약한 고정 자리): 마을 안에 2×2·3×3 «부지»를 미리 깔고 그 위에만 짓게 한다. Thronefall처럼 그림이 확실해지지만 «최적 자리가 굳는다»는 비판을 함께 받는다.
  4. 마을 영역 자체를 줄이기(60×27 → 거점 둘레 핵심 구역): 다른 갈래(길·마당·바닥)와 겹치는 결정이다.
- 우리 게임은 디펜스라서 «거점 가까이 모으면 한 번에 위험해진다»는 긴장을 근접 보너스와 짝지울 수 있다(추론). They Are Billions가 반경(전력망)과 간격 규칙을 함께 써서 «모으되 붙이지는 않게» 한 것이 참고가 된다.

### Gaps
- Warcraft III Undead의 Blight(역병 땅 위에만 건설) 규칙: Liquipedia 429, Wowpedia 동음이의 문서로 1차 확인 실패(미확인).
- Against the Storm 화로 범위와 집 배치의 관계: 공식 위키 403(미확인).
- Diplomacy is Not an Option·Stronghold의 배치 제한: 이번 조사에서 확인 못 함.
- (조사 기록) WebSearch 16회 사용(한도 25). 스크린샷은 스팀 appdetails로 16개 게임에서 6장씩 받아 640×360 접촉 시트로 봄. 원본 해상도로 본 것은 Thronefall·Kingdoms and Castles·Rise to Ruins·The Last Spell 4장(+확대 크롭)이고, 나머지 «직접 봄» 표기는 축소 시트에서 본 것이라 세부 비율은 재지 않음. 위키는 MediaWiki API, Warcraft I·Dune II는 오픈소스 재구현 소스(War1gus, OpenDUNE)를 읽음.
