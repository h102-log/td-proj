# 길 네트워크와 바닥 재질 — 정착지를 «마을»로 읽히게 하는 바닥 (자동 길·건물 둘레·재질 구분·플레이어 바닥 깔기)

표기: «(스크린샷 직접 봄: URL)» = Steam appdetails의 path_full 이미지를 내려받아 직접 본 것. «(검색 요약)» = WebSearch 결과 요약으로만 확인하고 원문은 열지 못한 것(403·402·429·시간 초과). «(미확인)» = 근거를 찾지 못한 것. 우리 게임 사실은 저장소 파일 경로를 출처로 단다.

우리 화면 관찰(2026-10-25 판, `art/trial/preview/village_mood_final/2_overview.png`·`3_wide.png` 직접 봄): 60×27 마을 전체가 고른 갈색 흙에 작은 풀·자갈 점만 흩어져 있다. 집(빨간 지붕)·시설은 칸 하나 크기 아이콘처럼 서로 멀리 떨어져 서 있다. 정문에서 거점까지 청회색 박석 광장 하나가 유일한 «길»이다. 그 광장 한가운데를 적 예상 경로의 빨간 선(S142)이 지나간다.

## 1. 자동으로 생기는 길 — 통행으로 닳는 길(desire path), 건물→길 자동 연결, 2D 픽셀아트 구현

### Takeaway
«다니면 닳는 길»의 1차 출처 사례는 Foundation(3D)과 The Settlers IV(2D 스프라이트)다. Settlers IV는 운반꾼이 풀 위를 반복해서 걸으면 «먼지 길»이, 그 위를 더 걸으면 «포장 길»이 생긴다. 그러나 우리 주민은 집 둘레 1.5칸 안만 맴도는 연출이라, 지금 코드에 닳는 길을 붙이면 길이 아니라 집 둘레 얼룩만 생긴다. 우리에게 가장 싸고 확실한 방법은 «건물이 완성되면 그 건물에서 가장 가까운 광장·길까지 길을 그어 굽는 것»이다. 다만 이 방식의 상용 1차 사례는 찾지 못했다. 가장 가까운 사례는 길을 벽에 대면 문이 생기는 Tiny Glade(방향이 반대)다.

### Cited Findings
**통행으로 생기는 길**
- Foundation: «Paths are made by your villagers based on what they're doing» 그래서 «you'll start to see your settlement slowly take shape based on how its people live their lives.» (PCGamesN, Ken Allsop, 2025-02-01) — [PCGamesN](https://www.pcgamesn.com/foundation/medieval-city-builder-out-now)
- Foundation 리뷰: 주민이 같은 길을 계속 다니면 땅에 길이 생긴다. 쓰지 않게 되면(예: 길 끝의 집을 헐면) 다시 흐려진다. 주민이 울타리를 무시하고 남의 마당을 가로지르기도 한다 (검색 요약) — [Galaxus](https://www.galaxus.de/en/page/foundation-is-a-brilliantly-chaotic-and-creative-building-game-36583)
- Foundation 1.0(2025-01-31)에 «our new paved road mechanic, tailored to support your most developed areas»가 들어왔다. «A new paint tool is now available to give you full control of where you wish paved roads to be created.» 즉 흙길은 저절로 생기고, 포장은 플레이어가 칠한다 — [Polymorph Games](https://www.polymorph.games/foundation/news/?p=2093)
- Foundation 상점 글: «Organic development with our unique Painting tool: Guide your villagers by defining areas for building homes, decide where to pave roads and set patrols…» — [Steam appdetails 690830](https://store.steampowered.com/api/appdetails?appids=690830&l=english)
- Foundation 화면: 칠하기(PAINT) 메뉴에 Woodcutting·Hunting·Residential·Patrolling·Road Paving·Resource Removal이 있다. 구역이 색 띠로 마을 위에 칠해진다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_8ac9b67061d00c19127387b9a66305626e5e2ccb.1920x1080.jpg). 초기 야영지 둘레 풀밭에는 맨흙 얼룩이 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_2a8289eaca31fa5b81f379b42c47010bb8070f15.1920x1080.jpg). 집들 사이에는 흙길이 나 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_dbc1c23ffd249f0c8b07aae6312f33aa63a0e8eb.1920x1080.jpg)
- The Settlers IV: Dusty path는 «Created when carriers repeatedly walk over grass.»이고 이동이 칸당 9틱에서 8틱으로 빨라진다. Paved road는 «Created when carriers repeatedly walk over dusty paths.»이고 7틱이다. 둘 다 나무 심기는 막고 곡식은 막지 않는다. 길이 나는 땅은 Grass뿐이다 — [Settlers United wiki](https://docs.settlers-united.com/v/settler-iv-wiki-en/basics/terrain-and-roads)
- 현실의 desire path는 지름길로 생기며, 같은 자리를 15번만 지나도 뚜렷한 길이 될 수 있다는 연구가 인용된다 (검색 요약) — [Wikipedia: Desire path](https://en.wikipedia.org/wiki/Desire_path)
- Manor Lords가 주민 통행으로 길을 «스스로 그린다»는 말은 Lemmy 댓글 하나뿐이다 (미확인, 검색 요약) — [Lemmy 글](https://scribe.disroot.org/post/6814748)
- Farthest Frontier에 닳는 길 메커니즘이 있는지는 확인하지 못했다(검색 2회 실패, 미확인). 상점 글은 «Develop roads, transport wagons…»다 — [Steam appdetails 1044720](https://store.steampowered.com/api/appdetails?appids=1044720&l=english). 플레이어 측정(옛 판 0.9.7g)으로는 자갈길이 흙길보다 약 10% 빠르다 (검색 요약) — [Crate 포럼](https://forums.crateentertainment.com/t/v-0-9-7g-roads-being-upgraded-to-cobblestone-are-slower-than-dirt/145892)

**플레이어가 길을 놓는 게임(대조군)**
- Manor Lords: «Each area will be subdivided based on your roads and the allotted space, and homes will scale accordingly.» 주거 구역을 정하면 주민이 burgage plot 제도대로 집을 짓는다 — [Steam appdetails 1363080](https://store.steampowered.com/api/appdetails?appids=1363080&l=english). 화면에서는 흙길을 따라 집이 늘어서고 집 뒤로 텃밭 필지가 붙는다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg). 성벽 안 눈밭에는 밟혀 생긴 듯한 흙 자국이 탑 쪽으로 나 있다(밟아서 생긴 것인지는 미확인) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/2a8486cf95c15af440a4857d6021bb15c057416c/ss_2a8486cf95c15af440a4857d6021bb15c057416c.1920x1080.jpg)
- Kingdoms and Castles: 일반 길도 맨땅보다 빠르고, Stone Road는 «50% faster travel»이다 (검색 요약, 위키 원문 402) — [KaC Wiki: Road](https://kingdomsandcastles.gamepedia.com/Road). 초기 촌락에서는 노란 길 칸이 집·밭을 잇는다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_c720d04f507059f75d1f5dc040e5123dcf36826b.1920x1080.jpg)
- Banished: 돌길은 약 37% 빠르다 (검색 요약) — [Banished Wiki: Stone road](https://banished.fandom.com/wiki/Stone_road)
- Against the Storm: 공식 위키에 따르면 건물에 길이 닿을 필요는 없지만 길 위에서 더 빨리 걷는다. 개발자는 생산 건물 입구를 길·창고 쪽으로 두라고 권했다 (검색 요약, 위키 원문 403) — [ATS Wiki: Road](https://wiki.hoodedhorse.com/Against_the_Storm/Road), [Steam 토론](https://steamcommunity.com/app/1336490/discussions/0/4040355128964997247). 화면에서는 건물 사이에 돌 테두리를 두른 흙길이 보인다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c7a8ad6065ddaa4789935d28d99e24c940c2181c.1920x1080.jpg)
- The Settlers 7: «without a road, a building will not be able to function». 흙길은 재료가 들지 않고 자갈길은 돌이 든다. 건물이 길에 달라붙는(snapping) 배치다. 자동 도로 건설의 근거는 찾지 못했다 (검색 요약) — [Ubisoft 소식](https://www.ubisoft.com/en-US/game/the-settlers/the-settlers/news-updates/7rrR3JyloYaRuTJWbtLP8Y)
- Tiny Glade: 길을 건물 벽에 대면 길 폭에 맞는 문·아치가 저절로 생긴다 (검색 요약) — [Destructoid](https://www.destructoid.com/after-10-hours-in-the-tiny-glade-demo-im-still-not-bored/). 상점 글은 «Draw a path through a building?»·«sheep waddle through your paths»·«the game adorns your glades with procedural detail»이다 — [Steam appdetails 2198150](https://store.steampowered.com/api/appdetails?appids=2198150&l=english)

**구현 기법(닳는 길·자동 길을 2D 타일로)**
- Valheim 모드 AntTrails는 지나간 칸에 조금씩 흙을 더해 «a path fades in rather than appearing»처럼 길이 서서히 드러나게 한다. 단계는 «Faint scuffing» → 문턱의 절반에서 «visible bare track» → 문턱(`StepsToPath` 기본 25)에서 «Full dirt path»다. 미완성 칸은 계속 새고, 완성된 길은 30일 방치하면 0.3 흔적까지 흐려진다. 400회 이상 쓰인 칸은 회당 1% 확률로 돌길이 되고 돌은 사라지지 않는다 — [Thunderstore AntTrails](https://thunderstore.io/c/valheim/p/RAGEmedia/AntTrails/v/1.0.0/)
- Minecraft 모드 Trample Grass는 밟힌 칸을 감시 목록에 올리고, 다시 밟힐 때마다 확률로 흙으로 바꾼다. Desire Lines는 걷거나 달릴 때 확률로 풀→흙→거친 흙으로 바꾼다 (검색 요약) — [Trample Grass](https://www.curseforge.com/minecraft/mc-mods/trample-grass), [GM4 Desire Lines](https://wiki.gm4.co/wiki/Desire_Lines)
- Godot 4 TileSet terrain은 terrain set마다 Match Corners and Sides·Match Corners·Match Sides 가운데 한 방식을 쓴다. «The peering bits determine which tile will be placed depending on neighboring tiles.» 문서에 방식별 필요 타일 수는 없다 — [Godot docs: Using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- 듀얼 그리드: 논리 격자 위에 반 칸 어긋난 표시 격자를 얹는다. «the corners of the mesh tile land on the centers of the four neighbors.» 예제는 겹침 타일 5장과 바탕 1장에 회전을 더해 47장 blob 세트를 대신한다(Justin Young, 2025-08-24). 출처로 Jess::Codes «Draw Fewer Tiles - by using a Dual-Grid system!»와 Oskar Stålberg «Beyond Townscapers»를 든다 — [Excalibur.js blog](https://excaliburjs.com/blog/Dual%20Tilemap%20Autotiling%20Technique)
- Godot용 TileMapDual은 자동 타일에 필요한 타일을 47장에서 15장으로 줄인다고 한다. 지형이 셋 이상이면 층을 여러 개 쓴다. Godot 포럼의 한 구현은 큰 맵에서 그릴 타일을 정하는 비용을 주된 한계로 꼽았다 (검색 요약) — [TileMapDual GitHub](https://github.com/pablogila/TileMapDual), [Godot Forum](https://forum.godotengine.org/t/dual-grid-tile-system-implementation/115685)
- Godot `ImageTexture.update()`: «Use this method over set_image() if you need to update the texture frequently, which is faster than allocating additional memory for a new texture each time.» 크기·형식은 기존 이미지와 같아야 한다 — [Godot docs: ImageTexture](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html)

**우리 게임 사실**
- 주민은 연출이다. 완성된 집마다 하나가 «집 둘레 1.5칸 안을 떠돌고», 시뮬레이션에 상태를 두지 않고 시각 t로 위치를 구한다(sin 합성 궤적) — `src/ui/battle_view.gd:1218-1228`
- 마을 바닥은 판 시작 때 한 번 굽는다. 꾸밈을 더한 뒤 굽기 시간이 20ms에서 39ms가 됐다 — `insights/2026-10-23_village_decor.md`
- 들판에는 정문에서 맵 아래끝까지 흙길이 나 있고, 다른 출현 지점의 오솔길이 이 큰길로 합류한다(S201) — `SPEC.md:402`
- 기각된 시안 B «생활 마을»의 흙길은 건물과 상관없이 고정된 가는 직선 둘이었다. 성벽 바로 위로 마을 폭 전체를 가로지르는 선과, 정문에서 거점으로 올라가는 선이다. 여기에 밭·통이 함께 놓였다 (직접 봄: `art/trial/preview/village_decor_overview.png`). 10/23 재판정 시안 3b도 거점 발치에서 좌우 끝까지 폭 6px의 옅은 흙길(927e6a 점)을 그었고, 고르지 않았다 — `insights/2026-10-23_village_decor.md`

### Inferences
- 사례는 네 갈래로 나뉜다. ① 통행으로 닳는 길(Foundation, Settlers IV) ② 플레이어가 놓고 속도 보상을 받는 길(KaC·Banished·ATS·Settlers 7·Foundation 포장) ③ 길이 집 배치를 정하는 방식(Manor Lords 필지) ④ 길이 건물 쪽 문을 만드는 방식(Tiny Glade). «건물을 지으면 가장 가까운 길까지 저절로 잇는» 방식의 1차 사례는 이번 조사에서 나오지 않았다.
- 우리 주민은 집 둘레 1.5칸만 맴돈다. 그래서 닳는 길 카운터를 그대로 붙이면 집마다 약 3×3칸의 둥근 닳은 자리만 생기고, 건물 사이 길은 생기지 않는다. 결과는 2번 질문의 «건물 둘레 바닥»과 같다. 위치가 시각의 결정적 함수이므로 누적할 필요도 없이 그 궤적 넓이를 처음부터 칠한 것과 같다. 건물 사이 길까지 얻으려면 주민이 집→광장·우물·일터를 오가도록 연출을 바꿔야 한다. 시뮬레이션은 그대로지만 S104의 표현은 바뀐다.
- 우리 조건에서 가장 싼 길은 «건물 완성(또는 착공) 때 문 칸에서 가장 가까운 길·광장 칸까지 BFS로 경로를 구해 그 칸을 길로 표시하고, 바닥을 다시 굽는 것»이다. 60×27 격자에서 BFS 한 번은 가볍다. 다시 굽기는 지금 39ms라 건설·파괴 순간에만 돌면 부담이 작을 것으로 본다(측정 안 함). 바뀐 주변만 고쳐 `ImageTexture.update()`로 올리는 길도 있다. 건물이 많아야 11채이므로 가지도 11개 이하다. 광장을 뿌리로 하는 나무 모양 길망이 생긴다.
- 기각된 «생활 마을»·3b와 다른 점(근거 포함):
  - 그때의 길은 건물과 무관한 고정 직선이었다. 이번 길은 건물마다 하나씩 생기고 그 건물 문에서 끝나 «누가 왜 다니는 길인지»가 화면에 드러난다. Foundation·Settlers IV·Manor Lords 모두 길이 사람의 활동이나 집 배치와 묶여 있다.
  - 그때의 가로선은 성벽과 나란한 띠였다. 이미 성벽 일부로 오해받은 «성벽 안쪽 돌길»과 같은 함정이다(5번 참조).
  - 그때의 세로선은 정문→거점 축, 곧 적 예상 경로와 겹쳤다(5번 참조).
  - 그때는 같은 흙색 위에 가는 점선이라 대비가 약했다. 이번에는 명도·질감으로 구분한다(3번 참조).
  - 다만 사용자가 «다져진 흙길»이라는 재질 자체를 싫어했을 가능성은 이번 조사로 배제할 수 없다. 시안을 볼 때 확인할 점이다.
- Settlers IV의 «먼지 길 → 포장 길» 2단계는 «마을이 자란다»를 바닥으로 보여 주는 장치다. 라운드나 마을 레벨에 따라 길 재질을 흙에서 자갈·박석으로 올리는 연출로 옮길 수 있다. 이것은 다른 갈래(자라는 마을)와 묶일 수 있는 추정이다.

### Gaps
- Manor Lords·Farthest Frontier·Northgard에 통행으로 닳는 길이 있는지 공식 출처로 확인하지 못했다. 검색에서 게임 문서가 나오지 않았다.
- «건물 완성 → 가장 가까운 길까지 자동 연결»의 상용 사례(공식 문서·devlog)를 찾지 못했다.
- Foundation의 길 생성·소멸 규칙(통행 횟수 문턱, 흐려지는 속도)은 리뷰 요약뿐이다. 개발사 devlog는 찾지 못했다.
- 2D 픽셀아트 게임의 닳는 길 구현기(devlog)는 찾지 못했다. 구현 근거는 모드(AntTrails 등)와 일반 자동 타일 자료뿐이다.

## 2. 건물 둘레 바닥 변화 — «건물이 땅을 바꾸는» 표현과 비용

### Takeaway
RTS 쪽에서는 건물 밑과 둘레의 땅을 바꾸는 것이 기본값에 가깝다. AoE2는 모든 지상 건물이 둘레에 흙을 깔고, WC3는 건물마다 바닥 텍스처(ubersplat)를 지정하며, Northgard는 길 없이 건물마다 맨땅 얼룩만으로 마을을 만든다. 공통점은 «사람이 손댄 땅»이 «손대지 않은 땅»(대개 풀)과 대비된다는 것이다. 우리 마을은 바닥 전체가 이미 흙이라 이 대비 신호가 없다.

### Cited Findings
- AoE2 DE: «around the buildings I've placed, there's little patches of Dirt 2.» 답글: «Pretty much all Land Buildings does this by default.» 끄려면 데이터 모드에서 «You want to edit the "Foundation Terrain" in the buildings.» (2023-11-23) — [AoE 포럼](https://forums.ageofempires.com/t/i-need-help-with-making-a-map/244274)
- AoE2 DE 화면: 풀밭 위 집마다 흙·박석 자국이 깔리고, 성벽 가까운 도심일수록 자국이 이어져 포장된 땅처럼 보인다. 밭은 따로 이랑 무늬다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/813780/ss_ea0429a12f9d65f3e6b5384e0117fceef2109e45.1920x1080.jpg)
- Warcraft III: 건물의 «Art - Ground Texture» 필드에 네 글자 코드를 넣으면 SplatData/UberSplatData.slk의 바닥 텍스처(ubersplat)를 고른다. 새 코드 행을 더해 맞춤 텍스처를 쓸 수 있다 (검색 요약, Hive 원문 403) — [Hive Workshop](https://www.hiveworkshop.com/threads/can-i-make-custom-splats.65230/), [Hive Workshop](https://www.hiveworkshop.com/threads/ubersplat-import-path-for-building-ground-texture.326827)
- Warcraft III Undead의 Blight: 완성된 Necropolis·Haunted Gold Mine이 만들고, Necropolis가 가장 많이 만든다. 땅을 «rotted soil»로 바꾼다. 다른 언데드 건물은 Blight 위에만 지을 수 있다. «Blight can be dispelled by your enemies once the building that generated it has been destroyed or unsummoned.» — [Hive Workshop classic: Undead basics](https://classic.hiveworkshop.com/war3/undead/basics.shtml). 위키는 Blight를 StarCraft Zerg의 creep과 비슷한 핵심 메커니즘으로 설명한다 (검색 요약) — [Warcraft Wiki: Blight](https://warcraft.wiki.gg/wiki/Blight_(plague))
- StarCraft creep의 세부 규칙(건물이 creep 위에만 서는지, 근원이 죽으면 줄어드는지)은 Liquipedia가 429로 막혀 확인하지 못했다 (미확인)
- Northgard: 풀밭 위 건물마다 불규칙한 옅은 맨땅 얼룩이 깔려 있다. 붙어 있는 건물의 얼룩은 하나로 합쳐져 넓은 공터가 된다. 길은 따로 없다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg). 설원 지도에서도 건물마다 흙 얼룩이 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/e71a1c785c3864a22b2d507e3e511f2e15368812/ss_e71a1c785c3864a22b2d507e3e511f2e15368812.1920x1080.jpg)
- Songs of Syx(2D 탑다운): 마을 땅은 풀밭을 도려낸 갈색 흙이고, 그 경계선이 건물 무리를 따라 굽는다. 집이 빽빽하고, 남은 흙이 골목이 된다. 밭은 이랑 무늬로 따로 구분된다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1162750/0a5bfa61b602b5dc075e084fd2821dcc8a6cd470/ss_0a5bfa61b602b5dc075e084fd2821dcc8a6cd470.1920x1080.jpg). 흙이 자동으로 생기는지 플레이어가 길로 까는지는 확인하지 못했다 (미확인)
- Farthest Frontier: 초기 마을에서 집 둘레 땅이 닳아 맨흙이 드러나고 그 사이를 흙길이 잇는다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1044720/ss_2d3e9332e534911c54bbf568612d7b70a222c9a3.1920x1080.jpg)
- They Are Billions: 콜로니 건물 둘레 땅이 어두운 돌 포장처럼 보인다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/644930/ss_6585e02470091ca84b8dcd3a3079976ad197fbcc.1920x1080.jpg). 건물 장식(decal)인지 지형인지는 미확인
- 우리: 시설 9종은 칸 폭(16px)에 위로 솟는 48×48 도트이고 땅에 닿는 면은 1칸이다(S173) — `SPEC.md:110`. 마을 칸은 모두 흙이다(S169) — `SPEC.md:106`

### Inferences
- 이 표현의 효과는 둘로 본다.
  - 건물의 땅 면적이 커 보인다. 1칸 아이콘을 2×2~3×3칸 «터»로 키운다. 다른 갈래의 가설 ②(건물이 아이콘 크기)를 바닥 쪽에서 돕는다.
  - 건물이 몰린 곳에서 얼룩이 합쳐져 «마을 중심»이 저절로 생긴다(Northgard·AoE2 화면).
- 우리 바닥은 이미 전부 흙이다. 그래서 흙 얼룩을 깔아도 보이지 않는다. 대비를 만드는 길은 둘이다.
  - S169를 그대로 두는 안: 손대지 않은 흙은 지금처럼 어둡고 풀포기·자갈이 있게 둔다. 건물 터와 길은 한 단계 밝고 매끈한 «다진 흙»이나 다른 재질(박석·나무 판·흙마당)로 한다. 명도와 질감으로 가른다.
  - S169를 되돌리는 안: 바탕을 풀로 바꾸고 건물·길만 흙으로 한다. Northgard·AoE2·Songs of Syx가 모두 이 방식이다. 사례로는 가장 강한 근거지만, 2026-10-20 사용자 결정(«마을 전체 흙»)을 뒤집으므로 사용자 판단이 먼저다.
- 비용 추정(구현 전, 측정 안 함):
  - 시설 종류별 터 그림 4~5장(집·생산 3종·교회)을 `decor.png`에 더한다.
  - 건설 시작이나 완성 때 그 칸 둘레를 다시 굽는다.
  - 파괴 때 지울지 남길지 정해야 한다. WC3 Blight처럼 남기면 «전쟁 흔적» 분위기가 더해진다.
  - 1번의 «건물→광장 길»과 같은 다시 굽기 경로를 쓸 수 있다.
- 터 얼룩은 건물이 있을 때만 그린다. 빈 땅에 미리 그리면 «여기 지으라»는 건설 슬롯으로 읽힌다(5번).

### Gaps
- StarCraft creep 세부 규칙(1차 출처 미열람).
- WC3 ubersplat 그림이 실제로 어떻게 생겼는지와 건설 중·파괴 뒤 처리 방식은 원문(Hive)이 막혀 확인하지 못했다.
- Northgard 맨땅 얼룩이 건설 단계에 따라 바뀌는지는 공식 출처가 없다(화면 관찰뿐).

## 3. 바닥 재질 구분과 16px 픽셀아트 블렌딩·경계 관습

### Takeaway
사례 화면은 대체로 «사람 손이 많이 간 곳일수록 단단한 재질»이라는 위계를 보인다. 광장은 다듬은 돌, 큰길은 자갈·흙, 마당은 밟힌 흙, 밭은 이랑, 바깥은 풀이나 거친 땅이다. 16px 블렌딩은 바탕 무늬를 네 변으로 이어지게 그린 뒤 «깎아서» 변·모서리 타일을 만든다. 재질 쌍마다 듀얼 그리드 15~16장, 또는 겹침 5장에 회전을 쓰는 방식이 가장 싸다.

### Cited Findings
- Slynyrd Pixelblog 20(16×16 탑다운 3/4 시점): «a grass texture made up of only one tile becomes monotonous.» 흙과 풀의 연결 타일은 바쁜 마른흙 무늬와 단순한 풀 가장자리를 짝짓는다. «Include clusters that overlap the edges and loop around the tile to help hide the seams.» «Avoid touching key clusters with other key clusters…» 색은 적게 쓰고, 무늬 안 강한 대비는 노이즈가 되므로 피하고, 이웃 무늬끼리 대비를 맞추라고 한다 — [Slynyrd Pixelblog 20](https://www.slynyrd.com/blog/2019/8/27/pixelblog-20-top-down-tiles)
- Slynyrd Pixelblog 43: «Step one with any tileset is the base repeating texture, which must loop well on all four sides.» «After that, all side and corner variants can be made by shaving off portions of the base texture.» 모든 조합을 따로 굽지 않고 층으로 쌓는 쪽을 택한다: «I think the compromise of having a few extra layers to manage is worth the trade off.» — [Slynyrd Pixelblog 43](https://slynyrd.com/blog/2023/3/26/pixelblog-43-top-down-tiles-part-2)
- 듀얼 그리드·Godot terrain 자료는 1번 «구현 기법» 참조 — [Excalibur.js](https://excaliburjs.com/blog/Dual%20Tilemap%20Autotiling%20Technique), [Godot docs](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- 재질 구역 화면 사례(모두 스크린샷 직접 봄):
  - Foundation: 우물 둘레 광장만 돌 포장이고 나머지는 흙·풀이다 — https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_c16b9212e4494a6cc7bef79ad764d1b889f5bbd2.1920x1080.jpg
  - Farthest Frontier 후반 도시: 포장 큰길과 둥근 정원 광장이 집 마당과 구분된다 — https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1044720/fdcec53651ac574225cff07c652e0dc97963dc61/ss_fdcec53651ac574225cff07c652e0dc97963dc61.1920x1080.jpg
  - Songs of Syx: 흙 골목과 다른 밝은 포장 광장 — https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1162750/b72ed0a143bf65bb6402169acd968e6324604732/ss_b72ed0a143bf65bb6402169acd968e6324604732.1920x1080.jpg
  - Necesse(2D 픽셀): 회색 돌길이 밭·집 둘레를 네모나게 감싼다 — https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1169040/ss_94e7f9f4e07b5fd7190ee650d35bdeefd7517e34.1920x1080.jpg
  - Stardew Valley(2D 픽셀): 농가 앞 모래빛 흙마당과 풀밭의 경계가 둥글고 불규칙하다 — https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_a3ddf22cda3bd722df77dbdd58dbec393906b654.1920x1080.jpg
  - Core Keeper(2D 픽셀): 기지 안은 벽돌·나무 바닥, 바깥은 자연 바닥 — https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1621690/bca1feb5ec1bf64543f80c74effdcaed4216033c/ss_bca1feb5ec1bf64543f80c74effdcaed4216033c.1920x1080.jpg
- 우리:
  - 성벽·광장 돌 색은 같은 청회색(56607a)이다(S202) — `SPEC.md:403`
  - Gemini 재판정은 광장이 «울퉁불퉁한 회색 돌무늬 바닥»으로 읽힌다고 했다. 턱·그림자·옆면이 없고, 틈새로 흙이 비치고, 가장자리 돌이 흙과 맞물려서다. 그래도 청회색이 성벽과 같아 «성벽 꼭대기 보행로·안쪽 비탈»으로도 보인다고 했다. Gemini는 따뜻한 회갈색(시안 1b, 927e6a)을 권했다 — `insights/2026-10-23_village_decor.md`
  - 마을 흙은 684c3c, 어두운 점은 392a1c다 — `insights/2026-10-23_village_decor.md`

### Inferences
- 우리 마을에 옮길 재질 위계 후보(Claude 해석):
  - 손대지 않은 흙: 지금 바닥.
  - 다진 흙: 길·건물 터. 한 단계 밝고 점이 적다.
  - 박석: 광장. 이미 있고, 색만 회갈색으로 옮기는 안이 재판정에서 나왔다.
  - 시설별 마당 재질 하나씩: 작업장은 나무 부스러기·판, 교회는 다듬은 판석, 집은 텃밭 이랑.
  - 재질은 4종 안팎으로 묶는다. 쌍마다 경계 타일이 필요해서다.
- 경계 처리:
  - 우리 바닥은 런타임에 이미지로 굽는다(`bake_ground`). 그래서 TileMap 없이 굽기 코드 안에서 듀얼 그리드식 «꼭짓점 4개 → 16가지 마스크»를 계산해 그리면 된다.
  - 경계 타일은 Slynyrd 방식대로 바탕 무늬를 깎아 만들거나, 가장자리 덩어리가 칸 밖으로 넘치는 불규칙 마스크로 만든다.
  - 직선 경계는 성벽·건설 격자와 닮으므로 피한다.
- 색은 성벽(청회색)과 같은 색상 계열을 피하고 흙과 같은 따뜻한 계열 안에서 명도로 가른다. 지금 광장의 «성벽 일부» 오독은 형태가 아니라 색에서 남았다(재판정).

### Gaps
- 16px 탑다운에서 흙·흙(같은 색상, 명도만 다른) 경계를 처리한 상용 사례는 찾지 못했다. 사례는 대부분 풀↔흙처럼 색상이 다른 쌍이다.
- Slynyrd 글은 길(road)·데칼을 다루지 않는다(글이 그렇게 밝힘). 길 전용 픽셀아트 관습 자료는 찾지 못했다.

## 4. 플레이어가 바닥 타일을 직접 까는 기능

### Takeaway
경영·생존 장르의 바닥 깔기는 거의 언제나 작은 기능 보상과 묶여 있다. 이동 속도(Rimworld·ONI·Factorio·KaC·Stardew 농장·Necesse), 아름다움·장식 점수(Rimworld·ONI), 잡초 억제(Stardew) 같은 것이다. 보상 없이 꾸밈만인 바닥 깔기가 크게 쓰인 사례는 Animal Crossing·Tiny Glade처럼 «꾸미기가 본 놀이»인 게임이다. TD·RTS 본류에서 꾸밈 바닥 깔기는 찾지 못했다. 방어 요소가 있는 혼합 장르(Factorio·Rimworld·Necesse·KaC)에는 있지만 모두 기능이 붙어 있다.

### Cited Findings
- Rimworld: 바닥은 다른 건설을 막지 않는다. 타일당 비용·작업량·Beauty는 다음과 같다.
  - Gold tile 70 Gold·800 ticks·+11
  - Silver tile +4
  - Carpet 7 Cloth·+2
  - Smooth stone 2,800 ticks·+2
  - Stone tile 4 Stony·1,100 ticks·+1
  - Wood floor 3 Wood·85 ticks·0
  - Concrete −1
  - 거의 모든 바닥이 맨땅보다 빨리 걷게 하고(Straw matting만 93%), 키 큰 풀·덤불이 자라지 못하게 하며, 방 청결도를 높인다. 제거는 Remove floor 명령이다
  - — [RimWorld Wiki: Floors](https://rimworldwiki.com/wiki/Floors)
- Oxygen Not Included: Tile은 장식 +5×1·달리기 +25%, Plastic Tile은 +5×1·+50%, Metal Tile은 +15×3·+50%, Carpeted Tile은 +20×4·−25%다. 카펫은 스트레스도 줄인다 — [ONI Wiki: Tiles](https://oxygennotincluded.wiki.gg/wiki/Tiles)
- Stardew Valley: 길(pathing)은 «located outside on The Farm»일 때만 Player Speed +0.1이다. 많이 다니는 자리에 풀·나무가 자라지 못하게 한다. 번개에 밀리거나 잡초에 부서질 수 있다 (검색 요약, 위키 원문 403) — [Stardew Wiki: Stone Floor](https://stardewvalleywiki.com/Stone_Floor), [Gravel Path](https://stardewvalleywiki.com/Gravel_Path)
- Stardew 화면: 농장 입구에서 밭 사이로 플레이어가 깐 듯한 자갈 판석 길이 이어지고, 돌담이 밭을 두른다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_d836f0a5b0447fb6a2bdb0a6ac5f954949d3c41e.1920x1080.jpg). 마을 쪽 화면에는 풀밭 사이로 모래빛 흙길이 난다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_4fa0866709ede3753fdf2745349b528d5e8c4054.1920x1080.jpg)
- Factorio: Concrete는 걷기 속도 «140%»다. 덮인 땅의 오염 흡수를 0으로 만든다. 놓을 범위는 Numpad +/−로 조절한다. 다른 바닥 위에 놓으면 옛 바닥을 자동으로 걷어 낸다 — [Factorio Wiki: Concrete](https://wiki.factorio.com/Concrete)
- Necesse(2D 픽셀, 정착지 습격이 있음): 바닥을 놓으면 «they destroy Terrain tiles and drop any floors they replace.» Stone Path는 «Gives a small speed boost»이고 Workstation에서 돌 2개로 만든다 — [Necesse Wiki: Floors](https://necessewiki.com/Floors), [Stone Path](https://necessewiki.com/Stone_Path). 상점 글에 «If you don't like raiders showing up at your settlement, turn them off»가 있다 — [Steam appdetails 1169040](https://store.steampowered.com/api/appdetails?appids=1169040&l=english). 눈 덮인 정착지에서는 플레이어가 깐 회색 돌길이 집·밭 사이를 격자로 잇고 길가에 횃불이 선다. 정착민 10명 규모(화면 목록 «Settlers (10)»)인데도 «마을»로 읽힌다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1169040/9f3337d66e14e35299e0c897a31c4967427964d4/ss_9f3337d66e14e35299e0c897a31c4967427964d4.1920x1080.jpg)
- Core Keeper: 기지에 깐 벽돌·나무 바닥이 화면에 보인다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1621690/ss_1e162c49418038f8042c92810fe3c753449e204b.1920x1080.jpg). 바닥 이동 속도 보너스는 검색으로 확인하지 못했다 (미확인)
- Kingdoms and Castles·Banished·Foundation 포장 길은 1번 참조(속도 보너스·고급 주거 지원)
- Animal Crossing: New Horizons: 기본 길 종류가 적어 커뮤니티 제작 «custom design» 길(돌 타일·헤링본·벽돌·보드워크 등)이 널리 공유된다. 한 가이드는 이를 «one of the most powerful decorating tools»라 부른다. 바닥 위에 얹는 방식이라 발에 차이거나 발소리가 다를 수 있다 (검색 요약) — [GamerGuides](https://www.gamerguides.com/animal-crossing-new-horizons/guide/your-island/terraforming/paths), [TheGamer](https://www.thegamer.com/animal-crossing-new-horizons-best-custom-paths-codes)
- Tiny Glade(목표·보상 없는 꾸미기): «No management, combat or goals» — [Steam appdetails 2198150](https://store.steampowered.com/api/appdetails?appids=2198150&l=english). 출시 한 달에 616,528장이 팔렸고 DAU는 34,496이다(개발사가 GameDiscoverCo에 준 수치) (검색 요약) — [GIGAZINE](https://gigazine.net/gsc_news/en/20241120-tiny-glade-600k-sold-reason)
- TD·RTS 화면에서는 바닥 깔기를 보지 못했다. Kingdom Rush는 길이 지도에 미리 그려져 있고 타워 자리가 고정이다(Strategic Point/Holder) (검색 요약) — [Kingdom Rush Wiki](https://kingdomrushtd.fandom.com/wiki/Strategic_Point). Thronefall은 풀밭에 흙길 하나가 기지 쪽으로 나 있다. 미리 깔린 길인지 플레이어가 놓는 길인지는 미확인이다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg). Diplomacy is Not an Option 스크린샷의 붓 UI(BRUSH TYPE·ZONES·LANDSCAPE·OBJECT ERASERS)는 재생 버튼·지도 다시 만들기 아이콘과 함께 있어 맵 편집기로 보인다. 본편 기능 근거로 쓰지 않는다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1272320/862e4f3a76539e7437e03ba441d9161f1a854cc4/ss_862e4f3a76539e7437e03ba441d9161f1a854cc4.1920x1080.jpg)
- 우리: 나중 후보 «플레이어가 바닥 타일(돌길·나무 바닥 등)을 직접 까는 기능. 꾸밈만이고 시뮬레이션은 그대로다(사용자 2026-10-20)» — `WBS.md:150`

### Inferences
- 동기: 사례 대부분이 바닥에 «깔 이유»(속도·아름다움·청결·오염)를 붙인다. 꾸밈만일 때는 꾸미기를 좋아하는 플레이어만 깔 것으로 본다. 쓰는 사람은 크게 쓰고(Animal Crossing·Tiny Glade), 나머지는 안 쓸 것이다. 그러면 «마을이 마을로 안 보인다»는 기본 문제를 이 기능으로 풀 수 없다. 모든 플레이어에게 보이는 기본 길(1번 자동 길·2번 건물 터)이 먼저다. 플레이어 바닥은 그 위의 선택 꾸밈으로 두는 순서가 맞다고 본다(Claude 해석).
- 보상 없이 쓰게 하는 조건(추정):
  - 공짜이거나 아주 싸다.
  - 준비 단계에서 드래그 몇 번으로 끝난다(Factorio 범위 조절, Foundation 칠하기).
  - 지우기가 쉽다(Rimworld Remove floor, 우클릭 드래그).
  - 건설을 막지 않는다(Rimworld처럼 바닥 위에 시설을 지을 수 있다).
  - 결과가 바로 예쁘다. 경계 자동 타일이 필수다.
- UI 후보:
  - 건설 패널에 «바닥» 칸을 하나 둔다. 재질 2~3종(박석·나무 판·흙마당)을 고른다.
  - 왼쪽 드래그로 칸을 칠하고 오른쪽 드래그로 지운다. 마을 0~26행에서만 칠할 수 있다.
  - 칠하는 동안 격자를 보이는 것은 지금 놓기 모드(I138) 규칙과 맞춘다.
- 꾸밈만이라는 결정을 바꿔 작은 기능(예: 주민·적 이동 속도)을 붙이면 사용률은 오를 것이다. 대신 시뮬레이션이 바뀌어 길 찾기·밸런스에 닿는다. 사용자 결정(2026-10-20)과 충돌하므로 제안하지 않고 트레이드오프로만 적는다.

### Gaps
- 꾸밈만 바닥 기능의 실제 사용률·플레이 시간 자료는 찾지 못했다(Tiny Glade 판매량은 게임 전체 수치다).
- TD·RTS 본류 게임에서 플레이어가 꾸밈 바닥을 까는 사례는 찾지 못했다(화면 몇 장에 없다는 것은 약한 근거다).
- Rimworld 바닥의 놓기 UI(영역 드래그 여부)는 위키 페이지에 없었다.

## 5. 길·바닥이 «건설 슬롯»·«성벽 일부»·«진격로»로 오해되지 않게 하는 방법

### Takeaway
TD 장르에서 «성문으로 들어가는 흙길»은 곧 적이 걷는 길이라는 관습이 강하다(Kingdom Rush). 우리 들판에도 정문까지 흙길(S201)이 있고, 적 예상 경로(빨간 선)가 정문→광장→거점으로 지난다. 그러니 마을 길은 이 축을 잇는 모양을 피하고, 광장에서 옆으로 갈라져 건물 문에서 끝나야 한다. 성벽 일부로 읽히지 않으려면 청회색과 성벽에 나란한 띠를 피한다. 건설 슬롯으로 읽히지 않으려면 빈 땅에 홀로 놓인 네모·동그라미 바닥을 피하고, 터 얼룩은 건물이 선 뒤에만 그린다.

### Cited Findings
- Kingdom Rush: 모래빛 흙길이 화면 아래에서 위쪽 성벽 성문까지 이어진다. 적은 그 길을 따라 걷고, 타워는 길 옆 풀섬 위에 선다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/246420/ss_502205852350bfd8d64070adf4c38f2ffdf86772.1920x1080.jpg). 타워 자리는 고정된 Strategic Point(Holder)이고 일부는 덤불·잔해로 막혀 돈을 내고 치운다 (검색 요약) — [Kingdom Rush Wiki](https://kingdomrushtd.fandom.com/wiki/Strategic_Point)
- TD 개발기들: 보이는 흙길과 적이 실제로 걷는 선이 어긋난 것이 가장 큰 초기 문제였고, 플레이테스터가 «적이 길에서 벗어난다»고 지적했다. 건설 칸 위치를 알리려고 판 시작 때 점선 네모를 깜박이자는 제안도 있었다 (검색 요약) — [DEV Community](https://dev.to/jasonguo/i-built-a-wwii-inspired-tower-defense-game-in-html5-the-hard-part-wasnt-the-towers-2b24), [itch.io devlog](https://nickjw001.itch.io/attack-of-the-tachobytes/devlog/427431/level-design-turret-enemy-movement)
- Rimworld 바닥은 다른 건설을 막지 않는다 — [RimWorld Wiki: Floors](https://rimworldwiki.com/wiki/Floors)
- Northgard: 건물 터 얼룩만 있고 길은 따로 없다. 그래서 길이 «통로·진로»로 읽힐 여지가 없다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg)
- 우리:
  - 적 예상 경로는 출현 지점에서 거점까지 엷은 빨간 선으로 늘 그린다(S142) — `SPEC.md:167`. 화면에서는 이 선이 정문→광장 한가운데→거점으로 지난다 (직접 봄: `art/trial/preview/village_mood_final/3_wide.png`)
  - 들판의 흙길은 정문에서 맵 아래끝까지 난 큰길이다(S201) — `SPEC.md:402`
  - 3라운드부터 땅 적은 가장 가까운 성문을 먼저 노린다. 쪽문은 양 끝 (0,27)·(59,27)이다(S203·I177) — `SPEC.md:407`, `SPEC.md:681`
- 이전 평가(우리, Gemini 2026-10-23):
  - 성벽과 같은 청회색 돌길이 성벽 일부·성벽 위 보행로로 읽혔다.
  - 공터에 혼자 놓인 우물은 «채집지·건설 슬롯»으로 오해될 수 있다고 했다.
  - 광장은 턱·그림자·옆면이 없고, 틈새로 흙이 비치고, 가장자리가 흙과 맞물려서 «바닥에 박힌 포장»으로 읽혔다.
  - 들판 꾸밈 시안에서는 나무 울타리·부서진 말뚝이 아군 방벽과, 건초더미·수레가 아이템과 헷갈려 빠졌다.
  - — `insights/2026-10-23_village_decor.md`, `WBS.md:227`

### Inferences
- **진격로 오독 막기**:
  - 정문→거점 축(이미 광장)과 쪽문→안쪽 방향으로는 새 길을 내지 않는다.
  - 마을 길은 광장 좌우에서 갈라져 건물 문으로 가는 가지 모양으로 한다.
  - 들판 큰길과 같은 재질·같은 폭으로 성문에 닿게 하지 않는다. 들판 흙길이 성문을 지나 마을로 이어져 보이면 Kingdom Rush 관습대로 «적이 들어올 길»로 읽힌다.
  - 기각된 시안 B의 세로선이 바로 이 축이었다.
- **성벽 일부 오독 막기**:
  - 성벽과 나란한 긴 띠를 만들지 않는다. 시안 B의 가로선, 지금 성벽 안쪽 돌길이 그런 띠다.
  - 청회색 계열을 쓰지 않는다.
  - 턱·그림자·옆면 없이 흙이 비치는 «박힌 바닥» 표현을 유지한다(재판정에서 효과가 확인됨).
- **건설 슬롯 오독 막기**:
  - 기하학적인 네모·동그라미 바닥을 빈 땅에 홀로 두지 않는다. Kingdom Rush식 고정 자리로 읽힌다.
  - 터 얼룩은 건물이 선 뒤에만 그린다.
  - 플레이어 바닥은 건설을 막지 않게 하고(Rimworld), 놓기 모드 격자 강조와 다른 색으로 그린다.
  - 길 끝이 반드시 건물 문에서 끝나면 «아직 아무것도 없는 길 끝 = 지을 자리»로 오해될 여지가 줄어든다.
- 이런 가지형·불규칙 경계 길은 우리 게임의 다른 요소(성벽=직선, 적 경로=빨간 선, 건설 격자=정사각 칸)와 모양이 겹치지 않는다. 그래서 오독을 줄이는 데 형태가 색만큼 중요하다고 본다(Claude 해석, 검증은 시안을 띄워 Gemini·사용자 판정으로).

### Gaps
- 바닥 표현이 진격로·건설 슬롯으로 오독되는지를 측정한 사용자 연구·GDC 자료는 찾지 못했다. 근거는 TD 관습(화면 관찰)과 우리 이전 Gemini 평가뿐이다.
- Kingdom Rush 빈 타워 자리(Holder)의 생김새는 이번에 확인하지 못했다(본 스크린샷에서는 모든 자리가 타워로 차 있었다).
- 조사 메타: WebSearch 25회 사용(상한 25). 내려받은 스크린샷은 Steam appdetails 21개 게임, 게임당 최대 9장이다(`C:/Users/bhy99/AppData/Local/Temp/claude/C--Users-bhy99-td-proj/1de916d7-4a6e-45be-ba30-47d951a6e44d/scratchpad/shots_paths/`). 위키·리뷰 여러 곳(Stardew·KaC·ATS·Hive·Liquipedia·Galaxus)은 403·402·429·시간 초과로 원문을 열지 못해 검색 요약으로만 적었다.
