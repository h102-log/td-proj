# 마을다움을 만드는 시각 요소 — 지각 이론과 저해상도 아트 디렉션

조사일 2026-10-25. 표기 규칙: «사실»은 출처 URL을 붙였고, 내가 직접 본 이미지는 «(스크린샷 직접 봄: URL)», 내가 잰 숫자는 «(직접 측정)», 해석은 각 절의 Inferences에만 적었다. 원문을 못 열고 검색 요약으로만 본 것은 «(검색 요약만, 원문 미확인)»으로 표시했다.

우리 화면 기준값(직접 측정, `art/trial/preview/village_mood_final/2_overview.png`, 칸 32px로 찍힌 화면):
- 마을 영역(성벽 위, y<760)에서 가장 흔한 단일 색(흙 RGB 104,76,60)이 **93.5%**, 그다음 박석 회청색 3.6%. 나머지 색은 각각 0.4% 이하.
- 집 한 채의 그림 경계 상자 32×54px → 원 해상도로 약 **16×27px(폭 1칸)**. 걸어 다니는 주민과 폭 차이가 거의 없다.
- 1,620칸에 많아야 11채 → 약 147칸당 1채.

---

## Q1. 장소를 «정착지»로 인식하게 하는 요소 (Lynch, Alexander, 환경 서사, lived-in)

### Takeaway
이론들은 공통적으로 «건물 수»보다 **구조**를 본다. Lynch의 다섯 요소(paths·edges·districts·nodes·landmarks), Alexander의 «건물 사이 공간이 모양을 가졌는가(positive outdoor space)»·«집 묶음과 공유지(house cluster)», 환경 서사의 «여기서 사람이 무엇을 했는가(cause and effect)»가 핵심이다. 작은 2D 화면에 옮기기 쉬운 것은 edge·path·node·landmark와 Alexander의 집 묶음·마당 둘러싸기·작은 광장, 그리고 소품 한두 개로 남기는 생활 흔적이다.

### Cited Findings
**Kevin Lynch, «The Image of the City»(1960)**
- 보스턴·저지시티·로스앤젤레스를 5년간 조사해, 사람들이 도시를 머릿속 지도(mental map)로 기억할 때 다섯 요소로 구성한다고 결론 냈다 — [Wikipedia: The Image of the City](https://en.wikipedia.org/wiki/The_Image_of_the_City)
- Paths: 거리·보도·길·운하처럼 이동하는 통로, "They arrange space and movement between space." / Edges: 실제 또는 지각된 경계(벽·건물·해안선·연석·도로) / Districts: 사람이 들어가고 나오는 중대형 2차원 영역으로 "common identifying characteristics"를 공유 / Nodes: 들어갈 수 있는 초점이 되는 장소, 성공한 node는 "seemed both to be unique in some way" 하면서 주변을 강화 / Landmarks: 들어갈 수 없는 기준점, "At least one aspect of them is unique or memorable" — [Wikipedia](https://en.wikipedia.org/wiki/The_Image_of_the_City)
- 게임 적용의 한계: Wellesley 연구 포스터는 Sable·A Short Hike 플레이어에게 길 설명을 시켰더니 Lynch 다섯 요소 중 2개만 확인됐고(완전한 자료가 있는 참가자 3명이라 결론 불충분), 게임 고유 단서로 방위·나침반 UI·NPC가 나왔다고 보고 (검색 요약만, PDF 텍스트 추출 실패로 원문 미확인) — [IOOW Poster](https://cs.wellesley.edu/~pmwh/mvmap/posters/open_world_elements/IOOW_Poster.pdf)

**Christopher Alexander 외, «A Pattern Language»(1977)의 마을 관련 패턴**
- 37 House Cluster: "People will not feel comfortable in their houses unless a group of houses forms a cluster, with the public land between them jointly owned by all the householders." 해법은 "very rough, but identifiable clusters of 8 to 12 households around some common land and paths". 3~5채 묶음도 작동하며, 공유지는 길 하나만큼 작아도 되고 초지만큼 커도 된다 — [APL 37](https://www.iwritewordsgood.com/apl/patterns/apl037.htm)
- 106 Positive Outdoor Space: "Outdoor spaces which are merely "left over" between buildings will, in general, not be used." 양(positive)의 공간은 부분적으로 둘러싸이고 볼록(convex)하며, 음(negative)의 공간은 경계가 흐리고 볼록하지 않다. 해법: 건물·나무·생울타리·담장·아케이드·덩굴 시렁 길로 각 바깥 공간을 어느 정도 둘러싸 «모서리를 돌아 새어 나가지 않는» 하나의 영역으로 만든다 — [APL 106](https://www.iwritewordsgood.com/apl/patterns/apl106.htm)
- 61 Small Public Squares: "when they are too large, they look and feel deserted." 1인당 약 300제곱피트를 넘으면 텅 비어 보이고, 해법은 "usually no more than 45 to 60 feet across, never more than 70 feet across". 가장자리의 활동 거점(activity pockets), 광장에 뚜렷한 모양을 주는 건물, 가운데의 무언가를 함께 요구 — [APL 61](https://www.iwritewordsgood.com/apl/patterns/apl061.htm)
- 126 Something Roughly in the Middle: "A public space without a middle is quite likely to stay empty." 분수·나무·조각·시계탑 같은 것을 자연스러운 동선 사이에 두되 "resist the impulse to put it exactly in the middle" — [APL 126](https://www.iwritewordsgood.com/apl/patterns/apl126.htm)
- 114 Hierarchy of Open Space: "people do not sit facing brick walls". 작은 공간이 등을 받쳐 주고 더 큰 공간을 내다보게 배치 — [APL 114](https://www.iwritewordsgood.com/apl/patterns/apl114.htm)
- 15 Neighborhood Boundary: "The strength of the boundary is essential to a neighborhood." 경계를 지나는 길목에 관문(gateway)을 두고, "the boundary comes alive in peoples' minds because they recognize the gateways." — [APL 15](https://www.iwritewordsgood.com/apl/patterns/apl015.htm)
- 30 Activity Nodes: "Community facilities scattered individually through the city do nothing for the life of the city." 길이 모이는 곳에 작은 광장을 두고 서로 돕는 시설을 그 둘레에 모은다 — [APL 30](https://www.iwritewordsgood.com/apl/patterns/apl030.htm)

**환경 서사(environmental storytelling)**
- Don Carson(2000): 이야기를 공간 자체에 심는다. 원인과 결과 연출 — "staged areas that lead the game player to come to their own conclusions about a previous event"(부서진 문, 폭발 흔적, 부서진 탈것). 관객이 «여기가 어디고 나는 누구인가»에 "in the first 15 seconds" 답하지 못하면 이미 실패. 빽빽한 디테일보다 "A large room with a single shaft of light illuminating a solitary prop is more effective". 나머지 소품은 "supporting players". 현실은 "far from geometrically perfect"하니 반복 줄에서 하나를 다르게 — [Game Developer, Carson 2000](https://www.gamedeveloper.com/design/environmental-storytelling-creating-immersive-3d-worlds-using-lessons-learned-from-the-theme-park-industry)
- Henry Jenkins «Game Design as Narrative Architecture»: 공간 이야기는 네 방식으로 작동 — "evoke pre-existing narrative associations", 사건이 벌어지는 무대, "embed narrative information within their mise-en-scene", 창발 서사의 자원. Evocative space는 "draw upon our previously existing narrative competencies" — [Jenkins, MIT](https://web.mit.edu/~21fms/People/henry3/games&narrative.html)
- Harvey Smith·Matthias Worch, GDC 2010 «What Happened Here? Environmental Storytelling»: 공간에 «내재된 역사감»을 만드는 기법, 도구는 소품·스크립트 사건·텍스처·조명·구도 — [GDC Vault](https://gdcvault.com/play/1012647/What-Happened-Here-Environmental). 슬라이드 요지: "Establish a discernible chain of events", "Echo the world at large", "Create characterization" (검색 요약만) — [slidetodoc](https://slidetodoc.com/level-design-workshop-what-happened-here-environmental-storytelling/). Smith: "It has to be possible to miss some things to make finding them meaningful" — [Nieman Storyboard 2011](https://niemanstoryboard.org/2011/01/14/harvey-smith-on-environmental-storytelling-and-embedding-narrative/)

**세트 드레싱·lived-in**
- 지나친 잡동사니는 보는 이를 압도하고, 너무 성긴 환경은 "empty and lifeless"하게 느껴진다. 디테일 밀도를 장소마다 달리하라(붐비는 시장 → 조용한 골목) — [MAGES, set dressing guide](https://mages.edu.sg/blog/guide-to-set-dressing-theme-creation-in-concept-art/) (교육기관 블로그, 업계 1차 자료 아님)
- GDC «Level Design Summit: Urban Planning» 세션은 도시계획이 «읽히고 구별되는 도시 공간»을 만드는 데 왜 중요한지 다룬다는 소개문 (검색 요약만; GDC Vault 점검 중이라 연사·연도 미확인) — [GDC Vault 1034528](https://gdcvault.com/play/1034528/Level-Design-Summit-Urban-Planning)

### Inferences
- 우리 화면을 Lynch 다섯 요소로 대 보면 **edge(성벽), path(정문~거점 박석길), node(박석 광장), landmark(거점 돌탑)는 이미 있다.** 비어 있는 것은 **district(구역 구분)** 하나다. 그런데 있는 네 요소가 모두 «군사·행정» 요소라, 전체가 «마을»보다 «요새 마당·연병장» 도식에 맞는다. 빠진 것은 도시 스케일이 아니라 **집 스케일(Alexander 층위)** — 집 묶음, 공유지, 마당, 집과 길을 잇는 샛길이다.
- Jenkins의 evocative space로 보면 «마을다움»은 플레이어 머릿속 마을 도식(지붕이 모여 있음, 울타리, 텃밭, 길이 집 문 앞까지 옴, 연기·빨래 같은 생활 흔적)과 맞아떨어지는지의 문제다. 지금 화면의 «흙 벌판 위 작은 아이콘 몇 개»는 «전장·공터» 도식에 더 가깝다.
- 사용자의 «마을로 느껴지지 않는다»는 판정은 Carson의 «첫 15초» 기준과 같은 종류의 즉각 판단이다. 즉 설명 없이 한눈에 읽혀야 한다.
- Alexander 30(시설이 흩어지면 아무것도 살리지 못함)과 37(집 묶음)은 «빈 땅 어디에나 짓기» 규칙과 정면으로 부딪힌다. 플레이어가 흩어 지으면 근접(proximity) 묶음이 생기지 않는다(Q3의 게슈탈트 참고).

### Gaps
- Lynch의 «imageability» 원문 정의를 1차 출처로 확보하지 못했다(Wikipedia·MIT 페이지에 문장 정의가 없음).
- 2D·픽셀 게임에서 «lived-in»을 직접 다룬 GDC 발표는 찾지 못했다. Smith·Worch 슬라이드 원본도 열지 못했다.
- Wellesley 포스터 원문(PDF)은 텍스트 추출에 실패해 검색 요약에 의존했다.

---

## Q2. 저해상도 픽셀아트 타일셋 관습 — 집 크기, 건물 대 빈 공간, 경계 처리

### Takeaway
16px 타일 관습에서 집 한 채는 **바닥 3×3~7×4칸, 그림은 대략 3~6칸 폭**이다(Kakariko 대표 6×5, Stardew Cabin 바닥 5×3, Kenney Tiny Town 3~4×3). 우리 집은 폭 1칸(16×27px)이라 면적으로 관습의 1/9~1/30이다. 반면 건물 **개수** 밀도는 Kakariko보다 오히려 높다. 결정적 차이는 Kakariko의 건물 바닥 점유가 약 9%뿐인데도 **나머지 땅이 생울타리 마당·포장길·밭·광장으로 거의 다 구획**되어 있다는 점이다. 우리 마을은 맨흙 한 색이 93.5%다.

### Cited Findings
- **ALttP Kakariko**(스크린샷 직접 봄: https://vgmaps.com/Atlas/SuperNES/LegendOfZelda-ALinkToThePast-LightWorld.png — 팬이 게임 타일로 이어 붙인 4096×4096 지도, 원 해상도로 896×960px(16px 칸 56×60칸) 잘라 봄):
  - 집 그림 크기(직접 측정, 눈대중 ±1칸): 작은 오두막 4×4칸, 보통 집 6×5칸, 큰 집 6×8칸·10×5칸. 잘라 낸 구역 안 건물 9채의 바닥 합은 약 294칸 = 구역의 **약 8.8%**.
  - 개수 밀도(직접 측정): 9채/3,360칸 ≈ **373칸당 1채**(우리 147칸당 1채보다 성김).
  - 가장 흔한 단일 색(맨풀)은 **31.8%**, 그다음 두 길 색이 11.9%·9.8%(직접 측정, 같은 방법으로 우리 흙은 93.5%). 풀 타일 안의 무늬 픽셀은 다른 색이라 맨풀 비율은 약간 낮게 잡힌다.
  - 관찰: 집마다 생울타리로 둘러싼 마당 안에 있음, 옅은 포장길이 격자로 모든 마당을 이음, 가운데 광장은 생울타리 고리 안에 풍향계 조각이 있고 주변에 벤치·좌판, 꽃나무 열·텃밭·통·표지판, 아래 오른쪽에 나무 관문, 바깥은 숲·절벽이 경계.
- **Kenney «Tiny Town»**: "Tile size 16 × 16" — [kenney.nl/assets/tiny-town](https://kenney.nl/assets/tiny-town). 샘플 그림(스크린샷 직접 봄: https://kenney.nl/media/pages/assets/tiny-town/e241a9f6c0-1674742338/sample.png): 집은 폭 3~4칸 × 높이 3칸(지붕 2줄 + 벽 1줄), 사람은 1칸. 집 사이를 나무 울타리·징검돌 길·나무·벌통·표지판이 채움(직접 측정, 눈대중).
- **Stardew Valley** 건물 바닥 크기(16px 타일): Cabin "Size 5x3", Coop "Footprint 6x3", Barn "Footprint 7x4", Well "Size 3x3", Silo "Size 3x3" — [Cabin](https://wiki.stardewvalley.net/Cabin), [Coop](https://wiki.stardewvalley.net/Coop), [Barn](https://wiki.stardewvalley.net/Barn), [Well](https://wiki.stardewvalley.net/Well), [Silo](https://wiki.stardewvalley.net/Silo). 그림은 바닥보다 위로 더 솟는다.
- **LimeZu «Serene Village Revamped»**: "RPG Tileset [16x16]", "24 different houses", 지붕은 빨강·초록·파랑 — [itch.io](https://limezu.itch.io/serenevillagerevamped). 집별 칸 수는 페이지에 없음.
- **Cup Nooble «Sprout Lands»**: 페이지에 타일 크기 표기 없음, "simple cute 16-bit pixel art farming asset pack", 미리보기에 울타리·건초·나무 상자·물통·밭 흙 — [itch.io](https://cupnooble.itch.io/sprout-lands-asset-pack)
- **Slynyrd(Raymond Schlitter) Pixelblog 51 «City Builder»**: "I determine the size based on 16x16px grid units", 건물 높이는 기초 위로 약간 넘어가도 되지만 "I do not break the foundation along the bottom or sides". "The size of the surrounding area is determined from the start based on a 16x16px grid"(필지를 처음부터 잡는다). 길은 "provide meaningful structure to the layout", 도시 가장자리에 "proper background around the boundaries of the city". 외곽선은 검정 대신 이웃 픽셀보다 약간 어두운 색 — [Pixelblog 51](https://slynyrd.com/blog/2024/7/25/pixelblog-51-city-builder)
- **LPC 스타일 가이드**(32px 타일 기준이라 규격은 다르지만 원칙 참고): "The camera angle is top-down, roughly 60 degrees", "Props should be colored so that they don't blend in with the surrounding background tiles (vary color, brightness, and saturation to provide contrast)", 외곽선은 "a darker version of the current color ... not black"(캐릭터만 검정에 가까운 외곽선), "Props should have shadows, or they will appear not to be part of the scene." — [LPC Style Guide](https://lpc.opengameart.org/static/LPC-Style-Guide/build/styleguide.html)
- **Rise to Ruins**(픽셀 마을 건설+방어, 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_20a099e9de89ca00f4cee6c060753065dfd57f23.1920x1080.jpg , https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_5c87844580091796814583e9408ce62a468c5392.1920x1080.jpg): 건물마다 바닥판·울타리 테두리(필지)가 있고 사이를 점무늬 작물 밭이 채운다. 건물이 드문 초반 화면에서도 필지와 밭 덕에 정착지로 읽힌다. 후반은 돌길·성벽·탑이 덧붙는다. 다만 전체적으로 잡음이 많아 가독성 모범은 아니다(관찰).

### Inferences
- **가설 ①(밀도 낮음)은 개수 기준으로는 반증, 점유 면적 기준으로는 지지.** 개수는 우리가 Kakariko보다 2.5배 촘촘하다. 그러나 건물 바닥 점유는 Kakariko 약 8.8% 대 우리 약 0.7~1%(11칸~16칸 남짓)로 10배 가까이 낮다. 따라서 «채 수를 늘리자»보다 «한 채가 차지하는 시각 면적과 그 주변 구획을 늘리자»가 이론·관습에 맞다.
- **가설 ②(집이 아이콘 크기)는 강하게 지지.** 관습에서 집은 사람의 3~6배 폭(Kakariko 6칸, Kenney 3~4칸)이라 «건축물 스케일»로 읽힌다. 우리 집은 사람과 폭이 비슷해 «유닛·아이콘 스케일»로 읽힌다. 48×48 캔버스는 폭 3칸까지 그릴 수 있는데 지금 그림은 1칸 폭만 쓰고 있다.
- **가설 ③(길·마당·울타리 없음)은 가장 강하게 지지.** 세 관습(Kakariko 생울타리 마당, Kenney 울타리·징검돌, Rise to Ruins 필지 테두리)이 모두 집을 «필지 단위»로 보여 준다. Slynyrd도 필지를 처음부터 잡으라고 한다.
- **가설 ④(바닥 흙 한 가지)도 지지.** Kakariko는 맨풀 32%, 길 22%, 나머지는 생울타리·텃밭·꽃나무·광장 등으로 나뉜다. 우리는 단일 흙색이 93.5%다.
- 경계 처리 관습은 세 가지다: 식생(숲·생울타리 — Kakariko), 울타리 — Kenney, 성벽과 필지 테두리 — Rise to Ruins. 우리 마을은 아래쪽 성벽 말고는 가장자리가 «흙이 계속 이어지는» 상태다(2_overview 관찰).

### Gaps
- Stardew Pelican Town 지도의 건물 대 빈 공간 비율은 재지 못했다(stardewvalleywiki.com이 403, 지도 이미지 확보 못 함).
- Eastward 마을, Cup Nooble·LimeZu 집의 칸 수는 확인 못 했다(페이지에 규격 없음).
- Kakariko 수치는 내 눈대중 경계 상자라 ±1칸 오차가 있다. «건물 대 빈 공간 비율»에 관한 업계 일반 수치는 찾지 못했다.

---

## Q3. 전략·RTS 아트 디렉션의 가독성 원칙과 «장식을 늘리면서 가독성 지키기»

### Takeaway
Blizzard·Riot·Relic 모두 «가독성 먼저»를 말한다. 실루엣, 큰 형태와 낮은 디테일, 그리고 **환경은 위계 맨 아래에 두고 명도 범위를 묶는다**. 픽셀아트 관습도 같다: «탑다운에서 땅은 대비를 낮추고, 대비는 튀어야 할 것(벽·나무 = 장애물)에만». 장식을 늘리면서 가독성을 지키는 방법은 장식을 **바닥 층의 다른 시각 문법**으로 만드는 것이다. 즉 외곽선 없이, 낮은 명도 대비로, 수직으로 솟지 않게, 땅 색 계열로, 뭉쳐서 둔다. Gemini가 짚은 네 함정은 모두 게슈탈트 «유사성·공통 영역» 원리로 설명된다.

### Cited Findings
**대형 스튜디오 발언**
- Samwise Didier(StarCraft II, 2008): "All the art in Starcraft II is going to be viewed in the top-down, three-quarter view," "we really put a lot of focus into the silhouettes of the units from that angle, so they're very distinct and iconic." "we try to keep the detail level a little bit lower – bigger shapes," "not as much little dots, nuts and bolts". 캐릭터가 "a little bit bigger and over-proportioned"인 이유도 플레이 시점 때문 — [Blizzplanet, Eurogamer 인터뷰 전재](https://www.blizzplanet.com/blog/comments/eurogamer_interviews_samwise_didier)
- 팀 색을 많이 넣어 유닛이 잘 읽히게 했더니 일부 밝은 색이 과포화돼 보여, 게임플레이에 맞게 조정하는 패스를 예정했다는 커뮤니티 보고 (검색 요약만, 원문 미확인) — [GosuGamers](https://www.gosugamers.net/news/7571-graphic-change-in-the-works-for-starcraft-ii)
- Jeremy Collins(Warcraft Arclight Rumble, 2022): "It starts with readability." 과제는 "how you allow players to get an immediate read on the game, especially from a top-down RTS camera angle". 실루엣을 지키고 무거운 재질 분할(material breakup)을 피함 — [PocketGamer.biz](https://www.pocketgamer.biz/translating-the-warcraft-aesthetic-to-mobile-arclight-rumble/)
- Riot(Summoner's Rift 개편, 2014): "controlling color and level of detail, clamping value ranges and reducing character occlusion" — [PCGamesN](https://pcgamesn.com/leagueoflegends/new-look-league-legends-summoners-rift-getting-some-major-work-done). 위계를 UI > 스킬 > 챔피언 > 환경 순으로 두고 환경은 뒤로 물러나게, 구역마다 "thoughtfully placed landmarks and subtle color cues"로 방향을 잡게 했다 (검색 요약만, Riot 개발 블로그 원문 미확인) — [Surrender@20](https://www.surrenderat20.net/2014/11/red-post-collection-defining-rifts.html)
- Zach Schlappi(Relic, Age of Empires IV, 2021): "We wanted to open it up so that it was easier to read the battlefield", 작은 물체의 디테일을 줄인 것은 "for better readability from your camera", 페인터리 텍스처로 "still readable and consistent on lower-end 1080p monitors", "We really used those accent colours to build the look and feel" — [MobileSyrup](https://mobilesyrup.com/2021/04/10/age-of-empires-iv-relic-developer-interview/)

**픽셀아트·정착지 게임 실무**
- nesdev 포럼(Bregalad): "For top-down games, avoid too much contrast on the ground", "contrast is reserved for elements that should "stand out" such as walls, trees, etc...", 자연물엔 무작위성을 넣고 "Make the tile gird as less noticeable as possible" — [nesdev](https://nesdev.nes.science/f21/t6892.xhtml)
- LPC: 소품은 배경 타일과 색·밝기·채도를 달리해 섞이지 않게, 그림자가 없으면 장면의 일부로 안 보임 — [LPC Style Guide](https://lpc.opengameart.org/static/LPC-Style-Guide/build/styleguide.html)
- Widelands(정착지 건설 게임) 포럼: 지형이 배치물보다 대비가 낮아야 하며, 지형 대비를 조금 낮추고 배치물 대비를 올리고 그림자를 강화했더니 «미묘하지만 분명한 가독성 향상» (검색 요약만, 원문은 봇 차단으로 미확인) — [Widelands forum](https://www.widelands.org/forum/post/35555)
- Polycount 환경 비평: 풀이 고르게 분포하면 잡음·대비가 생기니 바위가 땅과 만나는 곳 등 특정 위치에 뭉치라는 조언, 세로 그라데이션으로 나무를 땅에서 떼라는 조언 (검색 요약만, 원문 403) — [Polycount](https://polycount.com/discussion/comment/2797560)
- AoE 포럼: 예전 게임은 장식이 거의 없어 상호작용 물체를 강조할 필요가 없었고, AoE2 «cube mod»는 배경 잡동사니를 없애 자원을 단순한 큐브로 바꿔 매우 잘 읽힌다는 논의 (검색 요약만) — [AoE forum](https://forums.ageofempires.com/t/why-aomr-will-have-to-have-worse-readability/258795)
- Slynyrd Pixelblog 2: "A good texture may only need a few simple clusters." "Repeat these same clusters over and over but vary the pattern in which they are distributed." "If not treated with care, texture details will only add unnecessary noise." "A perfectly homogenous texture can appear unnatural and too busy" — [Pixelblog 2](https://slynyrd.com/blog/2018/2/15/pixelblog-2-texture)
- «Real meadows clump. Flowers evenly distributed across a field looks planted» (검색 요약만, 출처 성격 불명확한 갤러리 페이지) — [sprite-ai](https://www.sprite-ai.art/gallery/flowers)
- 회색조로 바꿔도 형태가 갈리는지 보는 명도 시험, 가장 강한 대비는 플레이어가 상호작용하는 것에 (검색 요약만) — [Bugnet](https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly)

**게슈탈트 묶음 원리**
- 근접(proximity): "objects or shapes that are close to one another appear to form groups." 유사성(similarity): 물리적으로 닮은 자극을 같은 대상의 일부로 본다 — [Wikipedia: Principles of grouping](https://en.wikipedia.org/wiki/Principles_of_grouping)
- 공통 영역(common region): 경계 안의 항목은 한 묶음으로 지각되고 "assumed to share some common characteristic or functionality", 경계는 "a strong visual cue that can overpower other grouping principles" — [NN/g, Harley 2020](https://www.nngroup.com/articles/common-region/)

**우리 쪽 기존 평가(브리프에 적힌 Gemini 지적)**
- 시설과 같은 짙은 외곽선의 꾸밈 → 클릭할 물건, 성벽과 같은 청회 돌 → 성벽 일부, 반듯한 네모 테두리 → 건설 슬롯, 솟은 벽 → 못 짓는 장애물 (출처: 이번 조사 브리프)

### Inferences
- Gemini의 네 함정은 이론으로 한 줄씩 설명된다. ① 같은 외곽선 → **유사성**으로 시설 묶음에 편입된다. ② 같은 청회 돌 → **유사성**으로 성벽 묶음에 편입된다. ③ 네모 테두리 → **공통 영역**이 «여기에 무엇이 들어간다»는 UI 문법(슬롯)을 만든다. ④ 솟은 벽 → 탑다운 관습상 대비와 높이는 장애물(벽·나무)에 예약돼 있다(nesdev). 즉 장식이 실패한 이유는 «장식이 많아서»가 아니라 **장식이 상호작용 물체의 시각 문법을 빌려 썼기 때문**이다.
- 그래서 «장식 늘리기와 가독성»의 긴장은 시각 문법을 갈라 풀 수 있다(해석). 마을 직물(울타리·마당·텃밭·길) 전용 규칙의 예:
  | 속성 | 시설·유닛(읽혀야 함) | 마을 직물(배경) |
  |---|---|---|
  | 외곽선 | 1px 짙은 남색 | 없음, 또는 자기 색보다 한 단계 어두운 색(Slynyrd·LPC) |
  | 높이 | 위로 솟음(48px) | 땅에 붙음, 솟아도 반 칸 이하 |
  | 명도 | 땅과 큰 차 | 땅과 작은 차(Riot의 «명도 범위 묶기», nesdev) |
  | 색 | 강조색 허용 | 땅 계열(회갈·탁한 초록), 성벽 청회 금지 |
  | 형태 | 또렷한 실루엣 | 불규칙·끊긴 선, 닫힌 직사각형 금지 |
  | 분포 | 플레이어가 둠 | 길가·벽 밑·집 둘레에 뭉침(Slynyrd·Polycount) |
- 명도 위계를 Riot식으로 적으면(해석): UI > 적·영웅 > 시설(외곽선) > 마을 직물 > 땅. 지금 화면은 «마을 직물» 층이 통째로 없다.
- 지금 화면의 풀꽃은 흙 전체에 고르게 흩어져 있다. Polycount·Slynyrd·sprite-ai 관습으로는 이것이 잡음이고, «손이 안 간 들판»의 신호이기도 하다(해석). 길가·담 밑·집 둘레에 뭉치면 같은 개수로도 «사람이 관리하는 땅»과 «그렇지 않은 땅»이 갈린다.

### Gaps
- «clutter budget»이라는 용어를 쓴 1차 자료(GDC·스튜디오 문서)는 찾지 못했다.
- StarCraft II·Warcraft III에서 «지형·장식 대 유닛 명도»를 수치로 밝힌 1차 자료는 못 찾았다(GameSpot 2007 기사는 403).
- Thronefall·Into the Breach 개발자가 건물 가독성을 직접 설명한 자료는 찾지 못했다(검색 결과는 리뷰뿐).

---

## Q4. 넓은 빈 땅을 «비었다»가 아니라 «광장·들·마당»으로 읽히게 하기

### Takeaway
Alexander는 «남은 땅은 쓰이지 않는다(106)», «너무 큰 광장은 텅 비어 보인다(61)», «가운데가 없는 공간은 비어 있게 된다(126)»고 말하고, 처방은 **둘러싸기, 쪼개기, 위계 주기, 가운데 무언가 두기**다. 저해상도 관습(Kakariko·Rise to Ruins)은 빈 땅을 맨땅으로 두지 않고 **마당·밭·길로 이름을 붙여** 채운다. 바닥 «결의 방향성»(밭이랑 등)을 다룬 이론 자료는 찾지 못했다.

### Cited Findings
- 남은 공간은 쓰이지 않으니 모든 바깥 공간을 양(positive)으로, 건물·나무·생울타리·담장으로 둘러싸 하나의 영역으로 — [APL 106](https://www.iwritewordsgood.com/apl/patterns/apl106.htm)
- 광장은 생각보다 훨씬 작게(45~60피트, 70피트 이하), 좁은 방향만 지키면 길쭉해도 됨, 가장자리 활동 거점과 모양을 잡는 건물, 가운데 무언가 — [APL 61](https://www.iwritewordsgood.com/apl/patterns/apl061.htm)
- 가운데 물건은 동선 사이 «떨어진 자리에», 정중앙 금지 — [APL 126](https://www.iwritewordsgood.com/apl/patterns/apl126.htm)
- 작은 공간이 큰 공간을 내다보는 위계 — [APL 114](https://www.iwritewordsgood.com/apl/patterns/apl114.htm)
- 공유지는 길 하나만큼 작아도 초지만큼 커도 된다 — [APL 37](https://www.iwritewordsgood.com/apl/patterns/apl037.htm)
- Kakariko(스크린샷 직접 봄, Q2와 같은 URL): 맨풀도 대부분 생울타리 마당 안에 있어 «마당»으로 읽힘. 광장은 생울타리 고리(약 9×10칸) 안에 풍향계가 있고 둘레에 벤치·좌판·꽃나무 열이 붙음. 밭·텃밭이 따로 구획됨(직접 측정, 눈대중).
- Rise to Ruins(스크린샷 직접 봄, Q2와 같은 URL): 건물 사이 빈 땅을 점무늬 작물 밭과 필지 바닥판이 채움.
- Slynyrd: 필지 크기를 처음부터 16px 격자로 잡고, 건물을 놓은 뒤 필지에 그림자를 드리움 — [Pixelblog 51](https://slynyrd.com/blog/2024/7/25/pixelblog-51-city-builder)
- 디테일 밀도를 장소마다 달리하라(붐비는 시장 → 조용한 골목) — [MAGES](https://mages.edu.sg/blog/guide-to-set-dressing-theme-creation-in-concept-art/)

### Inferences
- 우리 박석 광장은 크기(2_overview에서 약 7×10칸, 직접 측정)로는 Kakariko 광장과 비슷해 «너무 커서» 문제는 아니다. Alexander 61 기준으로 빠진 것은 **광장에 면한 건물 정면과 가장자리 활동 거점**이다. 지금은 광장 양옆이 맨흙이라 광장이 «길쭉한 포장 띠»로 읽힌다.
- 우물이 거점 오른쪽 옆, 길 사이에 있는 것은 Alexander 126의 «정중앙 금지»와 맞는다(해석).
- 진짜 문제는 광장이 아니라 **광장 양옆의 넓은 흙 두 덩어리(각 약 26×27칸 — 60칸 폭에서 광장 약 7칸을 뺀 반쪽)**다. 이 땅이 «아무도 안 쓰는 남은 땅(106의 negative space)»이다. 처방 후보는 Q5에 적었다.
- «들(밭)»은 정착지 도식의 강한 신호다(Rise to Ruins·Kakariko 텃밭). 밭이랑처럼 방향성 있는 결은 «사람이 갈았다»는 원인과 결과(Carson)로 읽힐 수 있다. 다만 이것을 직접 다룬 이론 근거는 찾지 못했으니 가설로만 둔다.

### Gaps
- 바닥 결의 방향성(밭이랑·길 결)이 «관리된 땅» 인식에 주는 효과를 다룬 자료를 찾지 못했다.
- «맨땅이 몇 %를 넘으면 비어 보이는가»에 대한 게임 쪽 수치는 없다. Alexander 61의 1인당 면적 기준은 실제 광장 기준이라 화면에 그대로 옮길 수 없다.

---

## Q5. Claude 가설 ①~④ 검토, 빠진 요소, 우리 상황에 대한 이론적 처방(해석)

### Takeaway
① 밀도는 **개수로는 반증, 면적으로는 지지**. ② 아이콘 크기, ③ 길·마당·울타리 없음, ④ 흙 한 가지는 **모두 지지**되며 그중 ③이 이론적으로 가장 무겁다. 가설에 없던 빠진 요소는 **district(구역 구분)**, **근접 묶음(cluster)**, **광장에 면한 정면과 가장자리 활동**, **생활 흔적**, **위·좌·우 가장자리의 경계·관문**이다. 처방의 중심은 «채 수를 늘리기»가 아니라 **집을 필지 단위로 보이게 하고 땅에 이름(마당·길·밭)을 붙이되, 그 층을 시설과 다른 시각 문법으로 그리는 것**이다.

### Cited Findings
- 가설 근거 수치(직접 측정): 우리 흙 단일 색 93.5%, 집 그림 약 16×27px, 147칸당 1채 / Kakariko 맨풀 31.8%·길 21.7%, 집 대표 6×5칸, 373칸당 1채, 건물 바닥 점유 약 8.8% (Q2 참고).
- 근거 원리: 남은 공간은 쓰이지 않음 [APL 106](https://www.iwritewordsgood.com/apl/patterns/apl106.htm), 집 묶음과 공유지 [APL 37](https://www.iwritewordsgood.com/apl/patterns/apl037.htm), 흩어진 시설은 아무것도 살리지 못함 [APL 30](https://www.iwritewordsgood.com/apl/patterns/apl030.htm), 경계와 관문 [APL 15](https://www.iwritewordsgood.com/apl/patterns/apl015.htm), 공통 영역이 근접·유사성을 이김 [NN/g](https://www.nngroup.com/articles/common-region/), 땅은 낮은 대비 [nesdev](https://nesdev.nes.science/f21/t6892.xhtml), 명도 범위 묶기 [PCGamesN/Riot](https://pcgamesn.com/leagueoflegends/new-look-league-legends-summoners-rift-getting-some-major-work-done), 원인과 결과 연출 [Carson](https://www.gamedeveloper.com/design/environmental-storytelling-creating-immersive-3d-worlds-using-lessons-learned-from-the-theme-park-industry).

### Inferences (모두 해석 — 우리 게임에 대한 처방 후보, 효과·호환성 순)
1. **집을 «필지 그림»으로 (③·② 동시 대응, 가장 효과 클 것으로 봄).** 점유는 1칸 그대로 두고, 같은 노드 아래 땅에 붙은 평평한 마당 패치(밟힌 흙이나 풀, 텃밭 이랑 두세 줄, 울타리 한두 토막, 장작더미)를 그려 시각 점유를 약 3×3칸으로 넓힌다. 근거는 APL 106·37, Rise to Ruins 필지, Kakariko 생울타리 마당, Slynyrd «필지를 처음부터». 함정 회피: 닫힌 네모가 아니라 한두 변만 울타리(공통 영역 → 슬롯 오독 방지), 외곽선 없음, 땅과 명도 차 작게. 트레이드오프: 플레이어가 집을 붙여 지으면 마당이 겹친다. 겹침 규칙(뒤 그림이 덮기 등)이 필요하다.
2. **바닥에 구역을 준다 (④·district 대응).** 흙 한 가지를 «길·마당·광장 둘레만 흙, 나머지는 탁한 풀밭이나 묵은 밭»으로 바꾼다. Kakariko 비율(맨바닥 1/3, 길 1/5, 나머지 구획)이 참고값이다. 땅 층끼리는 명도 차를 작게 두고 색상과 결로만 가른다(nesdev·Riot). 성벽 청회색은 쓰지 않는다.
3. **집에서 길로 이어지는 샛길 (path 연결망).** 각 건물 문 앞에서 가장 가까운 박석길·돌길까지 밟힌 흙길이 이어지면, 아무 데나 지어도 건물이 한 직물로 묶인다(Lynch path, Kakariko 격자길). 구현 비용(자동 경로 그리기)이 있으니 SPEC 판단이 필요하다.
4. **흩어 짓기를 근접 묶음으로 유도 (cluster).** 근접 원리상 11채가 1,620칸에 흩어지면 묶음이 안 생긴다. 규칙을 바꾸지 않고 아트로 할 수 있는 것은 «광장 둘레·성벽 안쪽 띠처럼 미리 정해 둔 마을 직물(울타리 열·밭)이 있는 곳에 지으면 자연스럽게 어울린다» 정도다. 규칙(건설 가능 구역 등)은 게임 디자인 결정이라 사용자 판단이 필요하다.
5. **광장 가장자리에 활동 거점.** 박석 광장 양옆에 좌판·수레·통·벤치 같은 낮은 소품을 뭉쳐 두면 광장이 «포장 띠»에서 «마을 광장»이 된다(APL 61). 소품은 외곽선 없이, 시설보다 낮게.
6. **가장자리와 관문 (edge).** 성벽 없는 위·좌·우 가장자리에 나무 열이나 생울타리를 둬 «마을 안/밖»을 가르고(APL 15, Kakariko 숲 경계), 정문에서 들어올 때 광장 입구 양옆에 문기둥이나 표지 같은 관문 표시를 둔다. 솟은 벽 모양은 장애물로 읽히니 낮은 식생으로 한다.
7. **풀꽃을 뭉친다.** 흙 전체에 고르게 흩은 풀꽃을 길가·담 밑·집 둘레·우물 둘레에 무더기로 모으고, 넓은 구역 안쪽은 비운다(Slynyrd·Polycount). 같은 개수로 «관리된 땅»과 «빈 땅»이 갈린다.
8. **생활 흔적 한두 개 (Carson·Jenkins).** 굴뚝 연기, 빨래줄, 우물가 물통, 장작 같은 «원인과 결과» 소품을 집 근처에만 소수 둔다. «무거운 사건, 가벼운 목소리»와 맞게 이미 있는 폐허 잔해와 대비되는 «버티며 사는» 흔적이 된다. Carson의 «한 줄기 빛 아래 소품 하나»처럼 적게 둔다.
9. **집 그림 크기 (②).** 관습상 집은 사람 폭의 3배 이상이다. 48×48 캔버스 안에서 지붕을 폭 2~3칸으로 넓히면 크기 문제는 상당히 풀린다. 다만 «땅에 닿는 면 1칸»이라는 현재 규칙과 충돌하고(옆 칸 클릭·겹침 판정), 1번 필지 그림으로도 시각 면적은 늘어난다. 그래서 2와 1을 먼저 시험하고 크기 변경은 그 결과를 보고 정하는 순서를 권한다. 이 순서는 내 판단이고 근거 자료는 없다.
- 판정 방법 제안: Carson의 «첫 15초» 기준대로, 바꾼 화면을 설명 없이 보여 주고 «무슨 장소냐»고 묻는 방식(사용자 직접 판정 또는 Gemini 검토). Gemini 함정 네 가지가 다시 나오는지 같은 질문으로 확인한다.

### Gaps
- 처방 1~9는 모두 이론·관습에서 끌어낸 해석이다. 우리 화면에서 실제로 효과가 있는지는 시험 그림으로만 확인할 수 있다.
- 마당 패치가 «건설 가능한 땅»을 줄여 보이게 하는지(플레이어가 거기에 못 짓는다고 오해하는지)는 이론으로 답할 수 없다. 시험이 필요하다.
- 건설 가능 구역이나 묶음 유도 같은 규칙 변경은 아트 범위 밖이라 다루지 않았다.

WebSearch 사용: 21회 (상한 25회)
