# 마을다움을 만드는 배경 요소 — 미리 깔린 건물·폐허·못 짓는 구역·레벨에 따라 자라는 마을

> 표기: «(스크린샷 직접 봄: URL)»은 Steam appdetails API의 `path_full` 이미지를 내려받아 직접 본 관찰이다. «(검색 요약)»은 원문 페이지가 Cloudflare·403으로 막혀 검색 결과 요약으로만 확인한 것이라 원문 대조가 필요하다. «해석»은 Inferences 칸에만 쓴다.

## 1. 미리 깔린 배경 건물·폐허가 플레이 공간을 «마을»로 만드는 사례와, 장식 건물을 플레이어 건물과 헷갈리지 않게 한 방법

### Takeaway
조사한 게임 중 마을다움을 건물 «개수»로 낸 게임은 없었다. 대신 셋을 조합했다. (1) 플레이어가 짓지 않았지만 지켜야 하는 집과 터를 미리 깐다(Bad North, Kingdom). (2) 건물을 좁은 덩어리로 모으고 길·울타리로 테두리를 둔다(Thronefall). (3) 상호작용 없는 장식물을 따로 분류한다(Warcraft III doodad, Mindustry derelict 팀). 장식을 플레이어 물건과 구분하는 확인된 수단은 두 가지다. 하나는 «선택·클릭이 안 되는 별도 객체 종류»이고, 다른 하나는 «다른 팀 색·명도»다. 반대 사례도 있다. 장식이 상호작용 물체(나무)를 흉내 내자 플레이어가 오조작했고, 개발사가 그 장식을 지웠다(Kingdom Two Crowns).

### Cited Findings
**우리 화면 기준선 (직접 봄: C:/Users/bhy99/td-proj/art/trial/preview/village_mood_final/3_wide.png, 2_overview.png)**
- 갈색 흙바닥 위에 빨간 지붕 집 6채, 교회 1채, 생산 시설 몇 개가 서로 수 칸씩 떨어져 흩어져 있다. 집과 집, 집과 거점을 잇는 길은 없다. 포장된 곳은 거점 탑 아래에서 성벽까지 이어진 돌 광장 띠뿐이다. 줌아웃 화면에서 «불탄 옛 집터» 7곳은 흙 위의 검은 얼룩에 옅은 돌 점 몇 개로 보여서, 집터보다 덤불이나 얼룩에 가깝게 읽힌다(관찰).

**Bad North — 미리 놓인 집을 지키는 구조**
- 섬마다 작은 흰 벽·갈색 지붕 집이 1~3채 미리 놓여 있다. 집은 섬 지형(흰 절벽·풀)과 같은 파스텔 팔레트를 쓰고, 플레이어가 짓는 건물은 아예 없다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_8c3675db0a388f3717e530c93d0db27f526a5c0a.1920x1080.jpg, https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_87ffd543439fb835b2ffac3ccec014fdd0c3e260.1920x1080.jpg).
- 비 오는 섬에서는 지붕 없는 흰 돌담·탑 잔해(폐허)가 절벽처럼 지형의 일부로 쓰인다. 그 한가운데에 지붕 있는 집 한 채가 있다. 지붕이 있으면 «살아 있는 집», 없으면 «지형·폐허»로 구분돼 보인다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_66e84cd65125d74fcad538bdc4c1585be8a957f1.1920x1080.jpg).
- 공식 설명: "Defend your idyllic island kingdom against a horde of Viking invaders, as you lead the desperate exodus of your people", "charming but brutal", "A stronger, smarter defense leads to greater rewards." — [Steam 상점 설명](https://store.steampowered.com/app/688420/)
- 스테이지 끝에 지켜 낸 집이 자원(코인)이 되어 캐릭터 업그레이드에 쓰인다(Richard Meredith). Meredith는 이 게임을 base building과 자원 관리를 뺀 RTS로 설명한다 — [Nintendo Life 인터뷰](https://www.nintendolife.com/news/2018/05/feature_battling_the_viking_horde_with_bad_north_dev_plausible_concept) (검색 요약)
- Oskar Stålberg: "This beautiful home of yours is all bloody now.", "We want to give that feeling of, you won, but it's still a sad victory.", "the island is pretty bloody and on fire." — [GamesBeat](https://gamesbeat.com/bad-north-shows-that-even-bloody-viking-battles-can-be-artsy-and-cute/)
- Stålberg: "Small diorama-like environments have been a thread throughout all my art", "these little compact little worlds where you can see everything at once". Meredith: "Minimalism is the thread that runs through just about everything in the game" — [PocketGamer.biz](https://www.pocketgamer.biz/interview/68638/indie-spotlight-plausible-concept-on-bad-north/)
- 섬은 손으로 만든 타일셋을 Wave Function Collapse로 조립해 만든다(2018 Everything Procedural 발표) — [80.lv](https://80.lv/articles/using-wave-function-collapse-algorithm-for-dioramas) (검색 요약)

**Thronefall — 작은 덩어리 + 경계 + 길**
- 첫 맵에서 성(Castle Center), 집 5~6채, 창고형 건물이 절벽과 강 사이 좁은 터에 몰려 있다. 그 앞을 나무 말뚝 울타리(palisade)가 꺾이며 감싸고, 흙길 하나가 성 앞에서 울타리 문을 지나 들판으로 이어진다. 울타리 밖 넓은 초원은 비어 있지만 «마을 밖 들판»으로 읽힌다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg).
- 플레이어 건물(성·집·탑·울타리·풍차)은 모두 주황 목재 계열 한 가지 색이고, 지형(청록 바닥·회백 바위·연두 침엽수·하늘색 강)은 차가운 색이다. 건물 발밑에는 실선 사각형이 아니라 아주 옅은 점선 테두리가 있다. 바닥 곳곳에는 작은 상자 모양 표식이 흩어져 있는데, 무엇인지는 확인하지 못했다(관찰, 표식의 정체는 미확인) (스크린샷 직접 봄: 위 URL, https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_22bfb0694c5685106f990cb6ec7656e3762a6980.1920x1080.jpg).
- Paul Schnepf: "we tried to create a high legibility while maintaining an appealing atmosphere", "the silhouette of objects is the element that communicates the most information to players", "We took great care to make things as distinguishable from each other as we could", "putting an outline around objects", "We went for a very limited color palette" — [Game Developer](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)

**Kingdom Two Crowns — 미리 깔린 캠프·터·폐허**
- 새 왕국을 시작하면 군주는 «불 꺼진 모닥불 둘레의 떠돌이 둘과 건물 윤곽 몇 개(a few building outlines)»를 만난다. 모닥불에 값을 치르면 그 윤곽이 자동으로 도구 상점이 된다 — [Kingdom Wiki: Town center](https://kingdomthegame.fandom.com/wiki/Town_center)
- 숲속 떠돌이 캠프(텐트+모닥불)는 «환경 구조물(environment structure)»로 분류된다. 양옆 나무를 베어 그 땅이 평지가 되면 캠프가 사라진다 — [Kingdom Wiki: Vagrant camp](https://kingdomthegame.fandom.com/wiki/Vagrant_camp); 숲 그늘 속 작은 텐트와 모닥불이 보인다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/701160/ss_fb33eeb33590f492c39c714fd673e059599895a5.1920x1080.jpg)
- **반대 사례(장식이 상호작용 물체를 흉내 낸 경우)**: Norse Lands의 떠돌이 캠프 스프라이트에는 원래 장식용 나무가 그려져 있었다. 플레이어가 이를 숲의 일부로 착각해 마지막 «진짜» 나무를 베었고 캠프가 사라졌다. 1.1.14(2021-12-10)에서 그 장식 나무를 지웠다 — [Kingdom Wiki: Vagrant camp](https://kingdomthegame.fandom.com/wiki/Vagrant_camp)

**Warcraft III — 장식 건물을 «다른 종류의 객체»로 분리**
- Doodad는 unit·region·terrain과 다른 객체 종류이고 "Usually one cannot interact with a doodad, the exception being destructables (i.e. trees)" — [Wowpedia: Doodad](https://wowpedia.fandom.com/wiki/Doodad)
- "Huts are neutral buildings primarily used for map decoration, although in single player missions some can reveal items when destroyed." — [Warcraft Wiki: Hut (Warcraft III)](https://warcraft.wiki.gg/wiki/Hut_(Warcraft_III)) (centaur tent, draenei hut, troll hut 등 변종)

**Mindustry — 버려진 건물을 «팀 색»으로 구분**
- 소스 코드에 `derelict` 팀이 따로 있고 색은 짙은 회청색 `#4d4e58`이다 — [Team.java](https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Team.java)
- 규칙 `derelictRepair = true` 주석: "Whether blocks can be repaired by clicking them." derelict 팀에는 `protectCores = false`, `checkPlacement = false`가 적용된다 — [Rules.java](https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Rules.java)

**Against the Storm — 숲속 공터의 폐허·이벤트**
- 공터(Glade)를 열면 폐허·생존자 캠프·은닉물 같은 구조물이나 생물을 만난다. 대부분 선택지가 두 개이고 조사에는 늘 비용이 든다 — [Hooded Horse Wiki: Glade Events](https://wiki.hoodedhorse.com/Against_the_Storm/Glade_Events) (검색 요약). 숲 공터 한가운데의 이벤트 오브젝트(마차·짐승)를 누르면 오른쪽에 Threats/Requirements/Rewards 창이 뜬다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c5e7f55444d87f26921736f2d228c092f4dda5f2.1920x1080.jpg)

**Northgard·Frostpunk·Dome Keeper**
- Northgard: 영역 경계를 점선·초록선으로 바닥에 그리고, 그 안에 건물을 듬성듬성 놓는다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg). Town Hall은 처음부터 있는 유일한 건물이고 다시 지을 수 없다 — [Northgard Wiki: Town Hall](https://northgard.fandom.com/wiki/Town_Hall)
- Frostpunk: 설계 출발점은 "a large, circular crater with a center-placed steam generating machine"였다. "Buildings are growing around the generator in circles too, streets are circular"(Kuba Stokalski, Lead Designer, 2019-09-20) — [Xbox Wire](https://news.xbox.com/en-us/?p=125332)
- 내려받은 Frostpunk 첫 스크린샷은 시즌패스 광고 이미지여서 관찰에 쓰지 않았다. Dome Keeper·Mindustry 스크린샷은 동굴·공장 화면이라 마을 배경 사례가 아니었다(관찰).

**가독성 일반론(실무자 휴리스틱, 연구 아님)**
- 실무 글들은 공통으로 배경의 명도·채도를 낮추고, 상호작용 물체는 다른 명도대·실루엣·채도로 띄우라고 권한다. 확인 방법으로는 흐리게 보기(squint)나 흑백으로 보기를 든다 — [Godot Forums 스레드](https://godotforums.org/d/31996-are-these-backgrounds-too-much), [bugnet: pixel art that reads clearly](https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly) (둘 다 검색 요약, 근거 강도 낮음)

### Inferences
- 사례들의 공통점은 마을다움이 건물 수보다 «밀도와 테두리»에서 나온다는 것이다. Thronefall 첫 맵은 우리 최대치(11채)와 비슷한 7~8채인데도 마을로 읽힌다. 건물이 좁게 모여 있고, 울타리 선과 흙길 하나가 «안과 밖»을 가르기 때문이다. 우리 화면은 60×27칸 전체가 «안»이라 같은 수의 건물이 흩어지면 밀도가 생기지 않는다. 이 둘의 차이가 사용자 판정(«건물 몇 채와 빈 흙땅»)의 주된 원인으로 보인다.
- Bad North와 Kingdom은 «플레이어가 짓지 않은 집·캠프·터»를 처음부터 깔아서 마을을 만든다. 우리 게임에 옮기면 «배경 집(상호작용 없음)»을 마을 가장자리나 성벽 안쪽 몇 군데에 미리 두는 방법이 된다. 플레이어 건물이 11채뿐이어도 화면의 집 수가 늘어난다.
- 장식 건물을 플레이어 건물과 구분하는 방법을 사례에서 뽑으면 이렇다. ① 클릭·선택이 아예 안 되는 별도 객체 종류(WC3 doodad). ② 플레이어 건물이 쓰지 않는 색 계열·명도(Mindustry derelict의 짙은 회청색, Thronefall의 «플레이어 건물=주황 목재, 지형=찬색» 분리). ③ 상태로 구분(Bad North: 지붕 없는 돌담=지형, 지붕 있는 집=지킬 대상). ④ 상호작용 물체를 흉내 내지 않기(Kingdom 장식 나무 사고). 이전 Gemini 평가의 함정(짙은 외곽선=클릭할 물건)은 Schnepf의 «물체에 외곽선을 둘렀다»는 말과 맞아떨어진다. 외곽선을 플레이어 물건에만 남기고, 배경 집은 외곽선 없이 명도를 한 단계 낮추는 쪽이 사례와 일치한다.
- 불탄 집터가 흐릿한 이유도 사례로 짐작할 수 있다. Bad North 폐허가 «폐허»로 읽히는 것은 납작한 얼룩이어서가 아니라 «지붕 없는 벽 그루터기»라는 실루엣 때문이다. 납작한 바닥 장식만으로는 줌아웃(1280×720) 화면에서 실루엣이 생기지 않는다. 다만 Bad North 폐허는 실제로 길을 막는 지형이다. 그래서 이전 평가의 «솟은 벽=장애물» 함정과 같은 방향의 증거이기도 하다(지형 장애물로 읽히는 것이 의도와 맞을 때만 유효).

### Gaps
- Bad North에서 집 배치 규칙(섬 생성 때 집이 어디에 몇 채 놓이는지)을 설명한 개발 자료는 찾지 못했다. Nintendo Life 원문은 403으로 막혀 검색 요약에만 기댔다.
- Thronefall 바닥의 작은 상자 모양 표식이 빈 건설 자리인지는 확인하지 못했다(위키 thronefall.wiki.gg가 Cloudflare로 막힘).
- Against the Storm의 폐허 이벤트가 화면에서 어떻게 표시되는지(머리 위 표식 여부)는 검색 요약에만 근거한다(미확인).
- Dome Keeper·Mindustry 캠페인 맵에 «마을» 성격의 미리 깔린 배경 건물이 있는지는 확인하지 못했다. Mindustry derelict 블록이 화면에서 실제로 어떻게 그려지는지(어두운 틴트 등)도 코드상 팀 색 말고는 확인하지 못했다.

## 2. 자유 건설(아무 칸) vs 정해진 자리(build slot·plot) vs 혼합 — 적은 건물로 마을다움을 내는 데 어느 쪽이 유리한가

### Takeaway
정해진 자리 쪽에만 «완성된 마을 모습을 디자이너가 고를 수 있다»는 직접 발언이 있다(Thronefall Jonas Tyroller). 다만 대가로 «최적 건설 순서가 하나로 굳는다»는 비판도 나온다. 자유 건설로 마을다움을 낸 게임들은 공통으로 «플레이어가 정한 구역을 게임이 자동으로 잘게 나누고 꾸미는» 장치를 둔다(Manor Lords의 burgage 자동 분할, Townscaper의 자동 장식, Frostpunk의 동심원 규칙). 순수한 «아무 칸 자유 배치 + 적은 건물»로 마을다움을 냈다는 근거는 찾지 못했다.

### Cited Findings
**정해진 자리**
- Jonas Tyroller(Thronefall): "you can only build predefined buildings on predefined built slots, which opens up tons of level design possibilities for us." / "we took away the player's ability to choose what to build and where" / "We can force players to build buildings in risky positions, which makes for way more interesting decisions." / "We automatically prevent players from building three walls around the spawn point of the enemies." / "We can limit the amount of buildings and units of the player without needing anything like a supply count." / **"We can choose how the finished castle should look like"** — [Game Developer](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- Wikipedia는 같은 기사를 인용해 «구조물은 미리 정한 구역에만 놓이도록 설계되어, 앞 레벨을 크게 바꾸지 않고 새 건물 종류를 넣을 수 있었다»고 정리한다 — [Wikipedia: Thronefall](https://en.wikipedia.org/wiki/Thronefall)
- 비판: 건설은 «한 가지 특정 건물만 받는 노드»에서만 가능하다. 그래서 레벨마다 «매우 특정한 최적 건설 순서»가 생긴다 — [GameGeeker 리뷰](https://gamegeeker.com/games/thronefall?market=GB) (검색 요약)
- Thronefall의 완성된 성 모습을 보면 원형 석벽이 성·집 덩어리를 감싸고, 탑이 벽 마디마다 서 있다. 계획된 요새 마을 모양이다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_b11d1fc23cbf78bf154c7c3d8bed1be1859c2183.1920x1080.jpg, https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_31158136c53ff471fc87465b2a8d1a5bd2acc709.1920x1080.jpg)
- Kingdom Rush: Strategic Point는 «탑을 지을 수 있는 미리 정한 자리»다 — [Kingdom Rush Wiki: Strategic Point](https://kingdomrushtd.fandom.com/wiki/Strategic_Point). 길 근처 일부 자리로 제한해서 값싼 탑을 마구 짓지 못하게 한다 — [Game Developer: Kingdom Rush level design](https://gamedeveloper.com/design/kingdom-rush---the-wonderful-campaign-level-design) (검색 요약)
- Kingdom Two Crowns의 광장(두 안쪽 성벽 사이)에는 town center, 상점 2개, 바위 더미 2개(또는 궁수탑), 풀밭 4곳이 고정으로 들어간다 — [Kingdom Wiki: Town center](https://kingdomthegame.fandom.com/wiki/Town_center)

**혼합(자유 배치 + 수량·구역 제한)**
- Northgard: 시작 지역(main tile)의 건물 수용량은 5다(Town Hall 포함). 영역마다 건물 수 상한이 있어서, 자유 배치이지만 구역 단위로 묶인다 — [Northgard Wiki: Town Hall](https://northgard.fandom.com/wiki/Town_Hall)
- Clash of Clans: 마을은 자유 배치지만, 시작할 때 나무·통나무·바위 같은 obstacle 약 40개가 무작위로 놓여 있고 최대 45개까지 다시 생긴다. "Obstacles are structures that obstruct the placement of a village's Buildings." 적은 Gold·Elixir로 치울 수 있다 — [CoC Wiki: Obstacles/Home Village](https://clashofclans.fandom.com/wiki/Obstacles/Home_Village)

**자유 배치 + 자동 분할·자동 장식**
- Manor Lords: "gridless city-building experience with full freedom of placement and rotation". 그러면서도 "Assign areas for housing and watch your residents build their homes in accordance with the historical burgage plot system. Each area will be subdivided based on your roads and the allotted space, and homes will scale accordingly. Build extensions behind larger homes…", "Spreading outward from a central marketplace" — [Steam 상점 설명](https://store.steampowered.com/app/1363080/)
- Townscaper: "plop down colored blocks of houses on the irregular grid, and watch Townscaper's underlying algorithm automatically turn those blocks into cute little houses, arches, stairways, bridges, and lush backyards, depending on their configuration." — [Steam 상점 설명](https://store.steampowered.com/app/1291340/)
- Frostpunk: 건물과 거리가 발전기 둘레 동심원을 따라 자란다(위 Xbox Wire). Frostpunk 2는 외곽 확장부가 이 엄격한 동심원 규칙을 따르지 않는다고 소개한다 — [Epic Games Store 인터뷰](https://store.epicgames.com/news/frostpunk-2-exclusive-interview-leave-your-fingerprint-on-a-frozen-world) (검색 요약)
- Against the Storm: 집·작업장 사이를 흙길과 포장길이 잇고, 건설 중인 건물은 나무 비계로 보인다. 빈 땅도 텃밭·덤불·짐더미로 채워져 있다(스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c7a8ad6065ddaa4789935d28d99e24c940c2181c.1920x1080.jpg)

### Inferences
- 적은 건물로 마을다움을 내는 데는 «정해진 자리» 또는 «혼합»이 유리하다는 쪽에 근거가 몰린다. 정해진 자리에서는 디자이너가 건물 사이 간격·길·울타리를 미리 맞출 수 있다(Tyroller의 «완성된 성의 모습을 고를 수 있다»). 자유 배치 게임이 마을다움을 내려면 «게임이 대신 메워 주는 층»이 필요했다. Manor Lords의 자동 분할·뒷마당, Townscaper의 자동 아치·계단, CoC의 시작 장애물 40개가 그 층이다.
- 우리 게임은 «아무 빈 땅 자유 건설 + 최대 11채»여서 위 두 축(디자이너가 정한 배치, 게임이 대신 메우는 층)이 모두 비어 있다. 슬롯 시스템으로 바꾸지 않고 혼합을 택하는 방법이 사례에서 보인다. 예: 마을 안에 «옛 집터/길/울타리» 같은 배경을 미리 깔아 플레이어가 자연스럽게 그 근처에 짓게 하는 반(半)슬롯(Kingdom의 «건물 윤곽», Kingdom Rush의 «잔해로 막힌 자리»). 또는 지은 건물에서 거점 광장까지 흙길이 저절로 생기게 하는 자동 연결(Manor Lords·Townscaper식).
- 이전 Gemini 평가의 «반듯한 네모 테두리 → 건설 슬롯으로 읽힘» 함정은 반대로 쓸 수 있다. 정말로 «여기 지으면 옛 집을 다시 세운다»는 선택 가능한 자리로 만들면, 슬롯처럼 읽히는 것이 오해가 아니라 정답이 된다(4절의 폐허 → 재건과 연결). 다만 Thronefall 리뷰가 지적한 «최적 순서 고정» 위험이 있으니, 강제 슬롯이 아니라 «선택 보너스 자리» 수준이 안전해 보인다.

### Gaps
- 자유 건설과 슬롯을 «마을다움»으로 직접 비교한 개발자 발언·리뷰는 찾지 못했다. Tyroller 발언도 레벨 디자인·밸런스가 주목적이고, 외형은 그중 한 줄이다.
- Thronefall에서 빈 슬롯이 어떻게 표시되는지(바닥 표식의 모양)는 공식 자료로 확인하지 못했다.
- Rock Paper Shotgun·Eurogamer의 Thronefall 기사는 가져오기가 막혀 왕국 외형에 대한 리뷰어 평가를 확인하지 못했다.

## 3. 마을 레벨·업그레이드·라운드 진행에 따라 배경이 자라는 사례 — 무엇이 자라고, 어떤 효과가 있었나

### Takeaway
레벨에 따라 자라는 것은 대체로 넷이다. ① 중심 건물 그림 자체(AoE·CoC·Kingdom). ② 공짜로 생기는 성벽·탑(Kingdom 3·5·7단계). ③ 순수 장식(Kingdom 3단계의 작은 텐트, Northgard 승수별 깃발). ④ 일반 집의 크기·뒷마당(Manor Lords). 우리 게임처럼 «거점 그림만 바뀌는» 구조는 Northgard·CoC와 같은 최소형이다. Kingdom은 단계마다 성벽·탑·텐트까지 «둘레»를 함께 키운다. 효과(플레이어 반응)를 수치로 보고한 자료는 찾지 못했다.

### Cited Findings
**Kingdom Two Crowns — 단계별로 둘레가 함께 자람** — [Kingdom Wiki: Town center](https://kingdomthegame.fandom.com/wiki/Town_center)(표: Template:Town upgrades)
- 0 불 꺼진 모닥불 → 1 Campfire(3코인: 망치·활 상점 열림) → 2 Village tents(6) → 3 Wooden fortifications(9: **가장 안쪽 가시 울타리를 공짜로 지음**, 낫 상점) → 4 Town hall(12: Banker) → [돌 기술 필요] 5 Stone fortifications(15: **안쪽 성벽이 공짜로 돌벽이 되고 안쪽 감시탑이 공짜로 섬**) → 6 Castle keep(18) → [철 기술 필요] 7 Iron keep(20: **안쪽 탑이 지붕 있는 3연탑, 안쪽 벽이 철벽으로 공짜 업그레이드**, 폭탄·대장간).
- 순수 장식 변화: «유럽 배경의 작은 텐트는 이제 Wooden fortifications(3단계)부터 나타난다»(1.1.13, COSMETIC으로 분류).
- 업그레이드마다 쿨다운이 있고, 단계가 오를수록 길어진다.

**Age of Empires / Age of Mythology — 시대가 바뀌면 건물 그림이 바뀜** — [Age of Empires Wiki: Architecture set](https://ageofempires.fandom.com/wiki/Architecture_set)
- "most buildings also change appearance depending of the Age the player is in." AoE1에서 Town Center와 House는 시대마다 고유한 모습이다(일부 건물은 여러 시대에 같은 모델).
- AoM: "All building models change on Age-ups except when attaining the Wonder Age." 그리스는 Archaic=나무 지붕널, Classical=점토 기와, Heroic=imbrex·tegula 점토 기와, Mythic=대리석 기와.

**Clash of Clans — 중심 건물 그림 + 폐허 시작**
- Town Hall은 레벨 1~18마다 다른 그림을 쓴다(위키 상단의 레벨별 이미지 목록) — [CoC Wiki: Town Hall](https://clashofclans.fandom.com/wiki/Town_Hall)
- Clan Castle은 «Ruin»에서 레벨 1~14까지 각기 다른 그림이다 — [CoC Wiki: Clan Castle](https://clashofclans.fandom.com/wiki/Clan_Castle)

**Northgard — 메타 진행에 따른 장식**
- Town Hall 업그레이드는 고급 건물 해금, 인구 증가율 +20%, 인구 상한 +2다. 고유 Town Hall 스킨은 Conquest를 깨면 열린다. "Town Halls also have decorative banners outside based on how many wins the player has with that clan"(0–9, 10–24, 25–49, 50+승) — [Northgard Wiki: Town Hall](https://northgard.fandom.com/wiki/Town_Hall)

**Manor Lords — 일반 집이 자람**
- 집 크기는 할당된 땅과 길에 맞춰 정해지고("homes will scale accordingly"), 큰 집 뒤에는 extension(채소밭, 닭·염소)을 붙일 수 있다 — [Steam 상점 설명](https://store.steampowered.com/app/1363080/)
- 업그레이드 조건이 위치마다 다르다(시장에 가까운 집이 먼저 물자를 받음). 1→2레벨에는 우물·교회 등이 필요하다 — [GGRecon](https://ggrecon.com/guides/manor-lords-upgrade-burgage-plots), [PCGamesN](https://www.pcgamesn.com/manor-lords/burgage-plots-upgrade) (검색 요약. PCGamesN 본문에는 «1레벨과 2레벨 집이 섞인 8채» 사진 캡션만 있고, 외형 차이를 설명한 문장은 없다)

**Townscaper·Frostpunk·Moonlighter**
- Townscaper: 블록 배치 형태에 따라 아치·계단·다리·뒷마당이 자동으로 생긴다(2절 인용).
- Frostpunk: 도시가 발전기 둘레 동심원으로 자란다(1절 인용).
- Moonlighter(2D 픽셀 탑다운): "restore the prosperity of this small commercial hamlet. Help establish new businesses and watch them grow in the idyllic community of Rynoka." — [Steam 상점 설명](https://store.steampowered.com/app/606150/) (가게가 들어서는 자리와 방식은 미확인)

**Thronefall**
- Castle Center에서 업그레이드를 연구한다(Steam 설명: "Research upgrades with the Castle Center, Blacksmith and Royal Forge"). 플레이어 글에는 Castle Builder·Commander 같은 성 업그레이드 이름이 나온다 — [Steam 상점](https://store.steampowered.com/app/2239150/), [Steam 토론(2023)](https://steamcommunity.com/app/2239150/discussions/0/3880470997349139918) (검색 요약). 성 업그레이드로 성 모습이 바뀌는지는 미확인.

### Inferences
- 우리 구조(마을 레벨이 라운드를 넘어 이어지고, 거점 탑 그림만 바뀜)는 CoC·Northgard형 «중심 건물만 바뀜»에 해당한다. 사례 중 «마을이 자란다»를 화면 전체로 느끼게 한 것은 Kingdom이다. Kingdom은 레벨업과 함께 둘레의 울타리·탑·텐트를 공짜로 세운다. 우리 게임에서 대응하는 후보는 다음과 같다. 마을 레벨이 오르면 ① 거점 광장 돌바닥이 넓어지고 ② 광장에서 뻗는 길이 늘고 ③ 우물·깃발·장작더미 같은 상호작용 없는 장식과 배경 집이 늘며 ④ 불탄 집터 일부가 «치워진 터 → 다시 선 집»으로 바뀐다. 모두 플레이어 건물 수(최대 11채)와 상관없이 화면 밀도를 올린다.
- Kingdom은 성벽·탑을 «공짜로» 준다. 이것은 장식이 아니라 실제 방어물이라 밸런스에 영향이 있다. 우리 쪽에서 밸런스를 건드리지 않으려면 «순수 장식만 자란다»(Kingdom의 COSMETIC 작은 텐트, Northgard 깃발)로 범위를 좁히는 편이 안전하다.
- AoM 그리스처럼 «지붕 재료가 시대마다 바뀐다»는 방식은 플레이어 집 스프라이트를 마을 레벨별로 바꾸는 것에 해당한다. 그림 수가 레벨 수만큼 곱해지므로 비용이 크다. 마을 레벨이 지금 1~2뿐이라면 거점 + 둘레 장식으로 충분할 수 있다(비용 비교는 근거 없음, 해석).

### Gaps
- Stronghold 시리즈의 성채(keep) 단계가 업그레이드로 외형이 바뀌는 구조인지는 확인하지 못했다(조사 안 함, 미확인).
- 마을이 자라는 연출이 플레이어 만족·리텐션에 준 효과를 측정한 개발자 발언·데이터는 찾지 못했다.
- Thronefall 성 업그레이드의 시각 변화, Kingdom 각 단계 그림의 구체적 차이(텐트 수·깃발 등)는 이미지 파일을 직접 보지 못해 확인하지 못했다.
- Heroes of Might and Magic III의 도시 화면(지은 건물이 그림 속 정해진 자리에 나타나는 방식)은 근거가 약한 검색 결과뿐이라 제외했다.

## 4. 폐허·과거 흔적을 «못 짓는 곳»이 아니라 «이야기 있는 바닥»으로 읽히게 한 사례, 그리고 폐허 → 재건 구조

### Takeaway
폐허를 다루는 방식은 셋으로 나뉜다. (a) 순수 이야기형: 상호작용 없음, 건설 방해 없음, 앞에 보상 상자 하나(Kingdom ruins). (b) 막힌 자리형: 폐허·잔해가 건설 자리를 덮고 있어 금으로 치우면 자리가 된다(Kingdom Rush의 «ruined homes», CoC obstacle). (c) 재건형: 폐허를 고치면 그 건물이 살아난다(CoC Clan Castle 폐허, Kingdom 난파선, Against the Storm 폐허, Mindustry derelict). 무거운 사건을 가볍게 보여 주는 톤에는 Kingdom(«지나간 옛 왕국의 잔해») 문장과 Bad North(«이겼지만 슬픈 승리») 발언이 가장 가깝다.

### Cited Findings
**(a) 이야기형**
- Kingdom: "The ruins seem to be the dilapidated remains of a castle keep, leftover from a previous Kingdom long past … ruins are more of a generic visual reference. The ruins can not be repaired or interacted with nor do they interfere with any buildings." 폐허 앞에는 닫힌 상자가 하나 있어 코인(Two Crowns는 12코인)이나 보석을 준다. 숲을 베어도 폐허는 사라지지 않는다 — [Kingdom Wiki: Ruins](https://kingdomthegame.fandom.com/wiki/Ruins)
- Kingdom Two Crowns 공식 설명: "Echoes of bygone eras speak of past greatness", "through secluded forests and ancient ruins to seek treasures" — [Steam 상점](https://store.steampowered.com/app/701160/)
- Bad North: 비 오는 섬의 흰 돌 폐허는 지형처럼 쓰이고, 그 가운데 지켜야 할 집이 있다(1절, 스크린샷 직접 봄). 개발자는 전투 뒤 섬이 «피범벅에 불타는» 모습으로 «이겼지만 슬픈 승리»를 의도했다고 말했다([GamesBeat](https://gamesbeat.com/bad-north-shows-that-even-bloody-viking-battles-can-be-artsy-and-cute/)).

**(b) 막힌 자리형 — 폐허를 치우면 건설 자리**
- Kingdom Rush: 일부 Strategic Point는 잔해로 막힌 채 시작하고, 금을 내야 치울 수 있다. Alliance에서는 잔해가 «시각적으로 다르고, 캠페인이 진행되며 환경이 바뀔수록 비싸진다»: 베어 낸 나무(60금), 돌무더기(100), 거미줄(30), 촉수·고철 더미·**무너진 집(ruined homes, Inner Sanctuary)**(150). Genesis에서는 부서진 Dwarven Crane이 잔해 덮인 자리를 남긴다(50금). 어떤 자리는 잠든 Crystal Golem이 덮고 있다가 특정 웨이브에 깨어나 자리가 열린다 — [Kingdom Rush Wiki: Strategic Point](https://kingdomrushtd.fandom.com/wiki/Strategic_Point)
- Clash of Clans: obstacle(나무·바위 등) 약 40개로 시작하고, 이것이 건물 배치를 막는다. 소량 자원으로 치운다 — [CoC Wiki: Obstacles/Home Village](https://clashofclans.fandom.com/wiki/Obstacles/Home_Village)

**(c) 재건형 — 폐허 → 기능하는 건물**
- Clash of Clans: "Players begin the game with a ruined Clan Castle. While it is in ruins, it is surrounded by Obstacles (plants and stones) and cannot be moved. Rebuilding a Clan Castle requires 10,000 Elixir but does not require a free Builder or any time." 재건하면 클랜 기능이 열린다 — [CoC Wiki: Clan Castle](https://clashofclans.fandom.com/wiki/Clan_Castle) (다른 검색 결과에는 Gold 10,000으로 나와 비용 표기가 엇갈린다)
- Kingdom New Lands/Two Crowns: "On every island, not far away from the encampment, are the broken remnants of a ship." 10코인으로 복원을 시작하고 선체 조각 59개(개당 2코인)를 일꾼이 붙인다. 첫 섬은 조각이 공짜, 둘째 섬은 40개 공짜다 — [Kingdom Wiki: Boat](https://kingdomthegame.fandom.com/wiki/Boat)
- Kingdom: 시작 시 «건물 윤곽(building outlines)»이 모닥불을 켜면 상점으로 자동 승격된다(3절) — [Kingdom Wiki: Town center](https://kingdomthegame.fandom.com/wiki/Town_center)
- Against the Storm: 공터의 폐허(Ruins)는 repair·salvage·cleanse·burn down 중 하나를 고른다. 고치면 그 건물과 생산물을 쓸 수 있고 일반 건물처럼 일꾼을 배치한다. 청사진이 없으면 철거한 뒤 다시 지을 수 없다. salvage는 자원을 주고, 드물게 청사진도 준다. 유령이 지키는 Haunted ruins는 «유일한 건물»이라 재건하거나 파괴한다 — [Hooded Horse Wiki: Ruins](https://wiki.hoodedhorse.com/Against_the_Storm/Ruins) (검색 요약. 기록 시점 판 1.9.5 기준). 플레이어 중에는 공터 안에 버려진 건물이 있을 수 있어 청사진 선택을 미루는 사람도 있다 — [Steam 토론](https://steamcommunity.com/app/1336490/discussions/0/3547176090235611952) (검색 요약)
- Mindustry: derelict 블록은 클릭해서 수리할 수 있다(`derelictRepair`: "Whether blocks can be repaired by clicking them.") — [Rules.java](https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Rules.java)

### Inferences
- 지금 시안(납작한 «불탄 옛 집터»)은 (a) 이야기형인데, 존재감이 약하다. Kingdom 폐허가 이야기형으로 성립하는 데는 세 요소가 있다. 실루엣이 있는 잔해(무너진 성채), 앞에 놓인 «한 번 열 수 있는 상자» 하나, 그리고 «지나간 옛 왕국의 잔해»라는 위키 설명처럼 공유되는 맥락이다. 우리 집터에 «한 번만 줍는 작은 보상»(예: 첫 라운드에만 반짝이는 골드 조각)을 하나 얹으면 클릭 오해 없이 시선을 끄는 근거가 생긴다. 이는 Kingdom 방식의 이식이고 우리 게임에서 검증된 것은 아니다.
- (b)·(c)는 이전 Gemini 평가에서 함정으로 지적된 «슬롯처럼 보임»을 기능으로 바꾸는 길이다. Kingdom Rush는 «무너진 집»이 건설 자리를 덮게 하고, 그 잔해를 장소마다 다르게 그렸다. 우리 경우 «불탄 집터 위에 집을 지으면 옛 집이 다시 선다(약간 싸거나 바로 지어짐)»는 혼합 규칙이 후보가 된다. 플레이어가 집을 집터 쪽에 모으게 되고, 2절의 밀도 문제와 4절의 이야기 문제를 함께 다룬다. 단점은 이것이 새 규칙이라 UI·밸런스 작업이 생긴다는 점이다.
- 마을 레벨과 엮는 방법(3절의 Kingdom처럼)으로는, 레벨업 때 집터 몇 곳이 자동으로 «치워진 터»나 «다시 선 배경 집»으로 바뀌는 연출이 있다. 라운드를 넘어 이어지는 마을 레벨을 «과거 습격의 흔적이 복구되어 간다»로 보여 주는 장치다. 무거운 사건(불탄 터)을 가벼운 목소리(복구되는 마을)로 푸는 분위기 기준과도 맞는다(해석).
- 반대로 집터를 계속 «못 짓는 곳»으로 두면, Bad North 폐허처럼 길을 막는 지형으로 읽혀야 일관된다. 그러면 이전 평가의 «솟은 벽=장애물» 읽힘이 오히려 맞는 신호가 된다. 집터를 «지을 수 있는 바닥 장식»으로 둘지, «못 짓는 지형»으로 둘지, «재건 자리»로 둘지가 시각 표현보다 먼저 정해야 할 결정으로 보인다.

### Gaps
- 폐허를 «이야기 있는 바닥»으로 읽히게 하려고 무엇을 바꿨는지 설명한 개발자 글(예: 시안 비교, 플레이테스트 결과)은 찾지 못했다. 위 사례들은 결과물 관찰과 위키 설명이다.
- Against the Storm 폐허·글레이드 이벤트 페이지와 Stardew Valley Community Center(폐허 → 복원의 2D 탑다운 사례) 위키는 Cloudflare로 막혀 원문을 보지 못했다. Stardew는 노트에서 뺐다.
- Kingdom Rush «ruined homes» 잔해 그림이 실제로 어떻게 생겼는지(배경 집과의 구분 방식)는 위키 이미지를 직접 보지 못해 미확인이다.
- 조사 메타: WebSearch 19회 사용(상한 25). Steam appdetails 11개(스크린샷까지 8개: Thronefall 2239150, Bad North 688420, Kingdom Two Crowns 701160, Against the Storm 1336490, Northgard 466560, Frostpunk 323190, Dome Keeper 1637320, Mindustry 1127400 / 설명 텍스트만 3개: Townscaper 1291340·Manor Lords 1363080·Moonlighter 606150)는 curl로 받았다. 위키 본문은 MediaWiki API(fandom·warcraft.wiki.gg·GitHub raw)로 읽었다. 스크린샷 30장은 C:/Users/bhy99/AppData/Local/Temp/claude/C--Users-bhy99-td-proj/1de916d7-4a6e-45be-ba30-47d951a6e44d/scratchpad/shots_scenery/img/ 에 있다. Cloudflare·403으로 막힌 곳: wiki.hoodedhorse.com, thronefall.wiki.gg, stardewvalleywiki.com, nintendolife.com, gamespot.com, gamegeeker.com, eurogamer.net, rockpapershotgun.com.
