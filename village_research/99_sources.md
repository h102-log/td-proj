# 99. 출처와 방법

[README](README.md)로 돌아가기.

---

## 1. 만든 방법

조사일은 2026-10-25다. `anthropic-skills:deep-research`로 갈래 6개를 따로 조사하고, 보고서 하나로 묶은 뒤 주제별 파일 01~05로 나눴다.

### 1.1 조사 (갈래 6개, 갈래마다 에이전트 1개)

| 갈래 | 맡은 것 | 웹 검색 | 직접 본 이미지 | 메모 |
|---|---|---|---|---|
| footprint_density | 건물 크기·밀도·군집, 흩어짐을 막는 장치 (가설 ①②) | 16 | 원본 해상도 4장(Thronefall·K&C·Rise to Ruins·The Last Spell) + 축소 시트 | [evidence/footprint_density.md](evidence/footprint_density.md) |
| paths_ground | 길망, 건물 발밑 땅, 재질 위계, 바닥 깔기 (가설 ③의 길, ④) | 25 | 21편, 편당 최대 9장 | [evidence/paths_ground.md](evidence/paths_ground.md) |
| yards_props | 마당·울타리·밭·소품, 오해 방지 규칙, 소품 밀도 (가설 ③의 마당) | 25 | 19편 × 6장(원본 약 15장, 확대 크롭 4장) | [evidence/yards_props.md](evidence/yards_props.md) |
| life_signals | 주민 움직임, 연기·불빛·동물·소리, 단계 반응 | 23 | 8편 28장 | [evidence/life_signals.md](evidence/life_signals.md) |
| scenery_growth | 미리 깔린 집·폐허, 자유 배치 vs 정해진 자리, 자라는 둘레 | 19 | 30장 | [evidence/scenery_growth.md](evidence/scenery_growth.md) |
| perception_theory | Lynch·Alexander·환경 서사, 저해상도 아트 디렉션, 가독성 | 21 | Kakariko 원본 크기 잘라내기, Kenney Tiny Town 샘플, Rise to Ruins 2장 | [evidence/perception_theory.md](evidence/perception_theory.md) |
| 합계 | | **129** | | |

- 갈래마다 우리 시안 화면 `art/trial/preview/village_mood_final/2_overview.png`·`3_wide.png`를 먼저 보게 했다.
- 스크린샷은 Steam appdetails API(`store.steampowered.com/api/appdetails`)에서 받았다. 저장소에는 넣지 않았다.
- 노트들이 화면의 «원형 고리를 두른 어두운 덤불 같은 물체 6~7개»라고 적은 것은 아직 게임에 들어가지 않은 집터 시안 C′다. «성벽 위 횃불»은 시안의 화로다. 보고서(01~05)에는 정정해서 썼고, evidence는 원자료라 고치지 않았다.

### 1.2 보고서

보고서 에이전트 하나가 노트 6개를 읽고 썼다. 우리 게임 관련 사실 세 가지는 Claude가 저장소에서 다시 확인했다.
- 주민은 완성된 집마다 하나가 집 둘레 1.5칸 안을 떠돌고, 위치는 시각 t로만 구한다(`src/ui/battle_view.gd`의 `residents()`, S104).
- EV129는 «완성된 집 2채면 주민 위치 2개, 시간이 지나면 바뀌고, 늘 마을 칸 안»이다(`EVAL.md`).
- 바닥 굽기는 39ms이고 판 시작 때 한 번 돈다(`insights/2026-10-23_village_decor.md`).

### 1.3 이 조사가 하지 않은 것

- 주장별 이중 검증 단계는 돌리지 않았다. 원작 분위기 조사(`source_mood_research/`)에는 있었던 단계다. 그래서 중요한 수치는 표기((계산)·(눈대중)·(픽셀 집계)·(검색 요약))로 확인 수준을 드러냈다.
- Godot을 띄워 시안을 만들지 않았다. 시안은 다음 단계다.

---

## 2. 확인 못 한 것

**기준이 없는 것**
- 덮개(건물·터가 덮는 땅 비율)가 몇 %부터 «마을»로 읽히는지 출처 있는 기준이 없다. 문서의 %는 모두 계산이다.
- 흙 계열 안에서 명도·질감만으로 구역을 가른 상용 사례가 없다.
- 완성된 건물을 가장 가까운 길에 자동으로 잇는 상용 1차 사례가 없다.
- «clutter budget»의 1차 출처가 없다. 가장 가까운 기준은 Blendo의 80/20(본인도 «vibe»라고 밝힘)과 관찰한 «건물당 소품 1묶음 2~5개»다.
- 피신 같은 연출이 마을을 «지킬 대상»으로 느끼게 한다는 설문이나 개발자 진술이 없다. 사례는 모두 기능(보호·화살·생산 정지)으로 설명된다.
- 동물·환경음이 마을다움을 높인다는 개발자 진술이 없다.
- 꾸밈만인 바닥 깔기 기능의 사용률 자료가 없다.

**막혀서 검색 요약으로만 본 것**
- Liquipedia(429): Warcraft III 건물 크기·Blight 규칙, StarCraft creep 세부.
- Against the Storm 위키(403): 화로 범위, 장식, 폐허.
- Manor Lords 위키(401·402), Stardew·Kingdoms and Castles 위키 일부(403), RimWorld 위키 일부(404), Fandom 일부(402).
- Nintendo Life의 Bad North 인터뷰, GameGeeker의 Thronefall 리뷰, polycount·Widelands·GameSpot, Riot의 «UI > 스킬 > 챔피언 > 환경» 위계 원문.

**조사하지 못한 것**
- Stronghold 오두막 크기와 성채 단계, Diplomacy is Not an Option 집 크기와 주민 행동.
- Thronefall 성 업그레이드가 화면을 바꾸는지, Thronefall에 걸어 다니는 주민이 있는지.
- Manor Lords·Farthest Frontier의 닳는 길 메커니즘, 2D 픽셀아트에서 닳는 길을 구현한 devlog.
- The Last Spell 화면의 울타리가 장식인지 플레이어가 지은 방벽인지.
- 전투 뒤 축하 연출, 빨래 소품 사례.
- Stardew Valley Pelican Town의 건물 대 빈 공간 비율.

**엇갈린 것**
- Clash of Clans Clan Castle 재건 비용: 위키는 Elixir 10,000, 다른 검색 결과는 Gold. evidence에 둘 다 적었다.
- 우리 집 그림 높이: 갈래마다 16×24px, 16×27px로 셌다(눈대중).

**추정으로 남긴 것**
- 입자 연기가 640×360 정수배 화면에서 번질 수 있다는 점. 띄워서 확인해야 한다.
- Kakariko 수치는 눈대중 경계 상자라 ±1칸 오차가 있다.

---

## 3. 갈래별 웹 출처

각 주장의 출처는 evidence 노트의 해당 문장에 달려 있다. 아래는 노트마다 뽑은 고유 URL이다(자동 추출).

### evidence/footprint_density.md (44개)

- https://github.com/Wargus/war1gus/blob/master/scripts/buildings.lua
- https://github.com/Wargus/war1gus/blob/master/scripts/helpers.lua
- https://github.com/OpenDUNE/OpenDUNE/blob/master/src/table/structureinfo.c
- https://ageofempires.fandom.com/wiki/House_(Age_of_Empires_II
- https://ageofempires.fandom.com/wiki/Barracks_(Age_of_Empires_II
- https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_II
- https://ageofempires.fandom.com/wiki/Villager_(Age_of_Empires_II
- https://www.keengamer.com/articles/previews/they-are-billions-preview/
- https://kingdomsandcastles.fandom.com/wiki/Hovel
- https://kingdomsandcastles.fandom.com/wiki/Cottage
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_c720d04f507059f75d1f5dc040e5123dcf36826b.1920x1080.jpg
- https://stardewvalley.fandom.com/wiki/Coop
- https://stardewvalleywiki.com/Shed
- https://www.bisecthosting.com/it-it/blog/stardew-valley-barn-upgrades-livestock
- https://www.slynyrd.com/blog/2019/10/21/pixelblog-22-top-down-character-sprites
- https://steamah.com/the-last-spell-buildings-detailed-list-guide/
- https://progameguides.com/the-last-spell/can-you-rotate-buildings-in-the-last-spell/
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_ca30ef5b4cee617bd36017da2953777f19b151c2.1920x1080.jpg
- https://kingdomsandcastles.fandom.com/wiki/Hamlet_Guide
- https://northgard.fandom.com/wiki/Tile
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg
- https://commonsensegamer.com/songs-of-conquest-guide/
- https://www.gamebanshee.com/xf84a
- https://dotesports.com/general/news/songs-of-conquest-how-to-get-more-troops
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/867210/ss_1547033ea1673abf58e8e76cc87f94f3f055c39a.1920x1080.jpg
- https://numantiangames.com/News/2017-10-02-they-are-billions-update-build-your-colony/
- https://gameluster.com/thronefall-review-holding-on-for-one-last-night/
- https://steamcommunity.com/app/2239150/discussions/0/4844274677391778281
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_8c3675db0a388f3717e530c93d0db27f526a5c0a.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_7378fcbe0eeb7194b5a8a218c1c49b8f8056b968.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/40970/ss_b2da292b97471df65e7db87ef15b84ae53799be0.1920x1080.jpg
- https://dev.publishnews.com.br/draw-village
- https://store.steampowered.com/app/1363080/
- https://videogamer.com/wiki/Manor-Lords/Vegetable-Garden
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg
- https://steamcommunity.com/app/1363080/discussions/0/4355619782840362614
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/813780/ss_ea0429a12f9d65f3e6b5384e0117fceef2109e45.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_b887651a93b0525739049eb4194f633de2df75be.1920x1080.jpg
- https://en.wikipedia.org/wiki/Islanders_(video_game
- https://en.wikipedia.org/wiki/Thronefall
- https://gamegeeker.com/games/thronefall?market=GB
- https://starcraft.fandom.com/wiki/Pylon

### evidence/life_signals.md (54개)

- https://eremitegames.com/villager-routines/
- https://eremitegames.com/hubs-system/
- https://wiki.hoodedhorse.com/Against_the_Storm/Breaks
- https://www.magicgameworld.com/?p=27271
- https://kingdomthegame.com/news/2019/3/26/citizens-more-active-during-winter-in-kingdom-two-crowns
- https://gog.com/forum/kingdom_two_crowns/kingdom_two_crowns_changelog
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/701160/ss_fb33eeb33590f492c39c714fd673e059599895a5.1920x1080.jpg
- https://www.gamespot.com/stronghold-crusader/user-reviews/2200-12624453/
- https://gog.com/forum/stronghold_series/stronghold_hd_seems_impossible_to_have_enough_food
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2140020/ss_56fc64a2d751072bc358035f499f57a794e8a870.1920x1080.jpg
- https://www.pcgamesn.com/pioneers-of-pagonia/wuselfaktor
- https://heise.de/-11260484
- https://news.ubisoft.com/en-us/article/54IHIBPSLbTyrtzQchvDQj/the-settlers-new-allies-out-now-on-pc
- https://www.gamedeveloper.com/business/5-tips-for-making-more-believable-open-world-cities
- https://www.rpgmaker.net/articles/326
- https://pantheonmmo.com/content/forums/topic/14132/what-makes-a-world-feel-alive
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg
- https://www.galaxus.ch/en/page/thronefall-a-fun-tactics-game-for-little-money-29122
- https://www.thesixthaxis.com/?p=442518
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/644930/ss_6df3b09ed1be7b6e7d3db4d89cddba9709c3cf1e.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/644930/ss_c886762978b9088bacd9d1b69681f5b2fe40ad8b.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1044720/ss_630013acd6eec95b55db558765faf85caeec6472.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/242920/ss_888a226267a065f2afa2a0d3a75200c2ec928ca7.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1272320/ss_8445452856adbc856f2ee9d1a4c5c36c1f04cbf9.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/701160/ss_55d314b0e9f6f52a34d03a5851fedbf3f13b3ff8.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_b11d1fc23cbf78bf154c7c3d8bed1be1859c2183.1920x1080.jpg
- https://wowpedia.fandom.com/wiki/Critter_(Warcraft_III
- https://warcraft.wiki.gg/wiki/Critters
- https://wildfiregames.com/forum/topic/309-sound-design-doc-master-list/
- https://timberborn.featureupvote.com/suggestions/221479/comment/770653
- https://www.asoundeffect.com/anno-1800-game-audio/
- https://www.anno-union.com/?p=9933
- https://www.adventuregamestudio.co.uk/forums/index.php?msg=427863
- https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- https://opengameart.org/node/16871
- https://en.wikipedia.org/wiki/Age_of_Empires_II
- https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_II
- https://ageofempires.fandom.com/wiki/King%27s_Palace
- https://forums.ageofempires.com/t/question-about-dont-ring-the-townbell/219723
- https://forums.crateentertainment.com/t/farthest-frontier-v1-1-1/154524
- https://farthestfrontier.com/?p=1210
- https://forums.crateentertainment.com/t/after-a-bandit-raid-townspeople-are-locked-in-buildings/154557
- https://steamcommunity.com/app/1044720/discussions/0/3376032962079735902/?ctp=2
- https://en.wikipedia.org/wiki/Bad_North
- https://gideonsgaming.com/bad-north-jotunn-edition-review/
- https://store.steampowered.com/app/688420
- https://steamcommunity.com/app/569480/discussions/0/2906376154316517572
- https://gog.com/game/kingdoms_castles
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2140020/ss_60637ca071b3493304355e3f2818bd191aee61cf.1920x1080.jpg
- https://www.digitec.ch/en/page/thronefall-dieses-game-ist-grosser-taktik-spass-fuer-kleines-geld-29122
- https://discmaster.textfiles.com/file/18455/2002_E3_PRESS_CD.ISO/Warcraft%20III%20Reign%20of%20Chaos%20E3%202002/Warcraft%20III%20documents%20E3%202002/Warcraft%20III%20Features.doc/Warcraft%20III%20Features.pdf
- https://warcraft.wiki.gg/wiki/Warcraft_III_units

### evidence/paths_ground.md (72개)

- https://www.pcgamesn.com/foundation/medieval-city-builder-out-now
- https://www.galaxus.de/en/page/foundation-is-a-brilliantly-chaotic-and-creative-building-game-36583
- https://www.polymorph.games/foundation/news/?p=2093
- https://store.steampowered.com/api/appdetails?appids=690830&l=english
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_8ac9b67061d00c19127387b9a66305626e5e2ccb.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_2a8289eaca31fa5b81f379b42c47010bb8070f15.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_dbc1c23ffd249f0c8b07aae6312f33aa63a0e8eb.1920x1080.jpg
- https://docs.settlers-united.com/v/settler-iv-wiki-en/basics/terrain-and-roads
- https://en.wikipedia.org/wiki/Desire_path
- https://scribe.disroot.org/post/6814748
- https://store.steampowered.com/api/appdetails?appids=1044720&l=english
- https://forums.crateentertainment.com/t/v-0-9-7g-roads-being-upgraded-to-cobblestone-are-slower-than-dirt/145892
- https://store.steampowered.com/api/appdetails?appids=1363080&l=english
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/2a8486cf95c15af440a4857d6021bb15c057416c/ss_2a8486cf95c15af440a4857d6021bb15c057416c.1920x1080.jpg
- https://kingdomsandcastles.gamepedia.com/Road
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_c720d04f507059f75d1f5dc040e5123dcf36826b.1920x1080.jpg
- https://banished.fandom.com/wiki/Stone_road
- https://wiki.hoodedhorse.com/Against_the_Storm/Road
- https://steamcommunity.com/app/1336490/discussions/0/4040355128964997247
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c7a8ad6065ddaa4789935d28d99e24c940c2181c.1920x1080.jpg
- https://www.ubisoft.com/en-US/game/the-settlers/the-settlers/news-updates/7rrR3JyloYaRuTJWbtLP8Y
- https://www.destructoid.com/after-10-hours-in-the-tiny-glade-demo-im-still-not-bored/
- https://store.steampowered.com/api/appdetails?appids=2198150&l=english
- https://thunderstore.io/c/valheim/p/RAGEmedia/AntTrails/v/1.0.0/
- https://www.curseforge.com/minecraft/mc-mods/trample-grass
- https://wiki.gm4.co/wiki/Desire_Lines
- https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html
- https://excaliburjs.com/blog/Dual%20Tilemap%20Autotiling%20Technique
- https://github.com/pablogila/TileMapDual
- https://forum.godotengine.org/t/dual-grid-tile-system-implementation/115685
- https://docs.godotengine.org/en/stable/classes/class_imagetexture.html
- https://forums.ageofempires.com/t/i-need-help-with-making-a-map/244274
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/813780/ss_ea0429a12f9d65f3e6b5384e0117fceef2109e45.1920x1080.jpg
- https://www.hiveworkshop.com/threads/can-i-make-custom-splats.65230/
- https://www.hiveworkshop.com/threads/ubersplat-import-path-for-building-ground-texture.326827
- https://classic.hiveworkshop.com/war3/undead/basics.shtml
- https://warcraft.wiki.gg/wiki/Blight_(plague
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/e71a1c785c3864a22b2d507e3e511f2e15368812/ss_e71a1c785c3864a22b2d507e3e511f2e15368812.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1162750/0a5bfa61b602b5dc075e084fd2821dcc8a6cd470/ss_0a5bfa61b602b5dc075e084fd2821dcc8a6cd470.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1044720/ss_2d3e9332e534911c54bbf568612d7b70a222c9a3.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/644930/ss_6585e02470091ca84b8dcd3a3079976ad197fbcc.1920x1080.jpg
- https://www.slynyrd.com/blog/2019/8/27/pixelblog-20-top-down-tiles
- https://slynyrd.com/blog/2023/3/26/pixelblog-43-top-down-tiles-part-2
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_c16b9212e4494a6cc7bef79ad764d1b889f5bbd2.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1044720/fdcec53651ac574225cff07c652e0dc97963dc61/ss_fdcec53651ac574225cff07c652e0dc97963dc61.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1162750/b72ed0a143bf65bb6402169acd968e6324604732/ss_b72ed0a143bf65bb6402169acd968e6324604732.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1169040/ss_94e7f9f4e07b5fd7190ee650d35bdeefd7517e34.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_a3ddf22cda3bd722df77dbdd58dbec393906b654.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1621690/bca1feb5ec1bf64543f80c74effdcaed4216033c/ss_bca1feb5ec1bf64543f80c74effdcaed4216033c.1920x1080.jpg
- https://rimworldwiki.com/wiki/Floors
- https://oxygennotincluded.wiki.gg/wiki/Tiles
- https://stardewvalleywiki.com/Stone_Floor
- https://stardewvalleywiki.com/Gravel_Path
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_d836f0a5b0447fb6a2bdb0a6ac5f954949d3c41e.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_4fa0866709ede3753fdf2745349b528d5e8c4054.1920x1080.jpg
- https://wiki.factorio.com/Concrete
- https://necessewiki.com/Floors
- https://necessewiki.com/Stone_Path
- https://store.steampowered.com/api/appdetails?appids=1169040&l=english
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1169040/9f3337d66e14e35299e0c897a31c4967427964d4/ss_9f3337d66e14e35299e0c897a31c4967427964d4.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1621690/ss_1e162c49418038f8042c92810fe3c753449e204b.1920x1080.jpg
- https://www.gamerguides.com/animal-crossing-new-horizons/guide/your-island/terraforming/paths
- https://www.thegamer.com/animal-crossing-new-horizons-best-custom-paths-codes
- https://gigazine.net/gsc_news/en/20241120-tiny-glade-600k-sold-reason
- https://kingdomrushtd.fandom.com/wiki/Strategic_Point
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1272320/862e4f3a76539e7437e03ba441d9161f1a854cc4/ss_862e4f3a76539e7437e03ba441d9161f1a854cc4.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/246420/ss_502205852350bfd8d64070adf4c38f2ffdf86772.1920x1080.jpg
- https://dev.to/jasonguo/i-built-a-wwii-inspired-tower-defense-game-in-html5-the-hard-part-wasnt-the-towers-2b24
- https://nickjw001.itch.io/attack-of-the-tachobytes/devlog/427431/level-design-turret-enemy-movement

### evidence/perception_theory.md (45개)

- https://en.wikipedia.org/wiki/The_Image_of_the_City
- https://cs.wellesley.edu/~pmwh/mvmap/posters/open_world_elements/IOOW_Poster.pdf
- https://www.iwritewordsgood.com/apl/patterns/apl037.htm
- https://www.iwritewordsgood.com/apl/patterns/apl106.htm
- https://www.iwritewordsgood.com/apl/patterns/apl061.htm
- https://www.iwritewordsgood.com/apl/patterns/apl126.htm
- https://www.iwritewordsgood.com/apl/patterns/apl114.htm
- https://www.iwritewordsgood.com/apl/patterns/apl015.htm
- https://www.iwritewordsgood.com/apl/patterns/apl030.htm
- https://www.gamedeveloper.com/design/environmental-storytelling-creating-immersive-3d-worlds-using-lessons-learned-from-the-theme-park-industry
- https://web.mit.edu/~21fms/People/henry3/games&narrative.html
- https://gdcvault.com/play/1012647/What-Happened-Here-Environmental
- https://slidetodoc.com/level-design-workshop-what-happened-here-environmental-storytelling/
- https://niemanstoryboard.org/2011/01/14/harvey-smith-on-environmental-storytelling-and-embedding-narrative/
- https://mages.edu.sg/blog/guide-to-set-dressing-theme-creation-in-concept-art/
- https://gdcvault.com/play/1034528/Level-Design-Summit-Urban-Planning
- https://vgmaps.com/Atlas/SuperNES/LegendOfZelda-ALinkToThePast-LightWorld.png
- https://kenney.nl/assets/tiny-town
- https://kenney.nl/media/pages/assets/tiny-town/e241a9f6c0-1674742338/sample.png
- https://wiki.stardewvalley.net/Cabin
- https://wiki.stardewvalley.net/Coop
- https://wiki.stardewvalley.net/Barn
- https://wiki.stardewvalley.net/Well
- https://wiki.stardewvalley.net/Silo
- https://limezu.itch.io/serenevillagerevamped
- https://cupnooble.itch.io/sprout-lands-asset-pack
- https://slynyrd.com/blog/2024/7/25/pixelblog-51-city-builder
- https://lpc.opengameart.org/static/LPC-Style-Guide/build/styleguide.html
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_20a099e9de89ca00f4cee6c060753065dfd57f23.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_5c87844580091796814583e9408ce62a468c5392.1920x1080.jpg
- https://www.blizzplanet.com/blog/comments/eurogamer_interviews_samwise_didier
- https://www.gosugamers.net/news/7571-graphic-change-in-the-works-for-starcraft-ii
- https://www.pocketgamer.biz/translating-the-warcraft-aesthetic-to-mobile-arclight-rumble/
- https://pcgamesn.com/leagueoflegends/new-look-league-legends-summoners-rift-getting-some-major-work-done
- https://www.surrenderat20.net/2014/11/red-post-collection-defining-rifts.html
- https://mobilesyrup.com/2021/04/10/age-of-empires-iv-relic-developer-interview/
- https://nesdev.nes.science/f21/t6892.xhtml
- https://www.widelands.org/forum/post/35555
- https://polycount.com/discussion/comment/2797560
- https://forums.ageofempires.com/t/why-aomr-will-have-to-have-worse-readability/258795
- https://slynyrd.com/blog/2018/2/15/pixelblog-2-texture
- https://www.sprite-ai.art/gallery/flowers
- https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly
- https://en.wikipedia.org/wiki/Principles_of_grouping
- https://www.nngroup.com/articles/common-region/

### evidence/scenery_growth.md (49개)

- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_8c3675db0a388f3717e530c93d0db27f526a5c0a.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_87ffd543439fb835b2ffac3ccec014fdd0c3e260.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_66e84cd65125d74fcad538bdc4c1585be8a957f1.1920x1080.jpg
- https://store.steampowered.com/app/688420/
- https://www.nintendolife.com/news/2018/05/feature_battling_the_viking_horde_with_bad_north_dev_plausible_concept
- https://gamesbeat.com/bad-north-shows-that-even-bloody-viking-battles-can-be-artsy-and-cute/
- https://www.pocketgamer.biz/interview/68638/indie-spotlight-plausible-concept-on-bad-north/
- https://80.lv/articles/using-wave-function-collapse-algorithm-for-dioramas
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_22bfb0694c5685106f990cb6ec7656e3762a6980.1920x1080.jpg
- https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall
- https://kingdomthegame.fandom.com/wiki/Town_center
- https://kingdomthegame.fandom.com/wiki/Vagrant_camp
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/701160/ss_fb33eeb33590f492c39c714fd673e059599895a5.1920x1080.jpg
- https://wowpedia.fandom.com/wiki/Doodad
- https://warcraft.wiki.gg/wiki/Hut_(Warcraft_III
- https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Team.java
- https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Rules.java
- https://wiki.hoodedhorse.com/Against_the_Storm/Glade_Events
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c5e7f55444d87f26921736f2d228c092f4dda5f2.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg
- https://northgard.fandom.com/wiki/Town_Hall
- https://news.xbox.com/en-us/?p=125332
- https://godotforums.org/d/31996-are-these-backgrounds-too-much
- https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly
- https://en.wikipedia.org/wiki/Thronefall
- https://gamegeeker.com/games/thronefall?market=GB
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_b11d1fc23cbf78bf154c7c3d8bed1be1859c2183.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_31158136c53ff471fc87465b2a8d1a5bd2acc709.1920x1080.jpg
- https://kingdomrushtd.fandom.com/wiki/Strategic_Point
- https://gamedeveloper.com/design/kingdom-rush---the-wonderful-campaign-level-design
- https://clashofclans.fandom.com/wiki/Obstacles/Home_Village
- https://store.steampowered.com/app/1363080/
- https://store.steampowered.com/app/1291340/
- https://store.epicgames.com/news/frostpunk-2-exclusive-interview-leave-your-fingerprint-on-a-frozen-world
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c7a8ad6065ddaa4789935d28d99e24c940c2181c.1920x1080.jpg
- https://ageofempires.fandom.com/wiki/Architecture_set
- https://clashofclans.fandom.com/wiki/Town_Hall
- https://clashofclans.fandom.com/wiki/Clan_Castle
- https://ggrecon.com/guides/manor-lords-upgrade-burgage-plots
- https://www.pcgamesn.com/manor-lords/burgage-plots-upgrade
- https://store.steampowered.com/app/606150/
- https://store.steampowered.com/app/2239150/
- https://steamcommunity.com/app/2239150/discussions/0/3880470997349139918
- https://kingdomthegame.fandom.com/wiki/Ruins
- https://store.steampowered.com/app/701160/
- https://kingdomthegame.fandom.com/wiki/Boat
- https://wiki.hoodedhorse.com/Against_the_Storm/Ruins
- https://steamcommunity.com/app/1336490/discussions/0/3547176090235611952

### evidence/yards_props.md (40개)

- https://wiki.polymorph.games/foundation/Housing
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_dbc1c23ffd249f0c8b07aae6312f33aa63a0e8eb.1920x1080.jpg
- https://www.siliconera.com/preview-manor-lords-is-a-small-scale-city-builder/
- https://game8.co/games/Manor-Lords/archives/452178
- https://game8.co/games/Manor-Lords/archives/452175
- https://steamcommunity.com/app/1363080/discussions/0/4362376656109053467/
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg
- https://steamcommunity.com/app/2198150/discussions/0/4844273660400957331
- https://80.lv/articles/tiny-glade-to-feature-movable-clutter-unlimited-lighting-sources/
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/813780/ss_ea0429a12f9d65f3e6b5384e0117fceef2109e45.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2140020/ss_56fc64a2d751072bc358035f499f57a794e8a870.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_ca30ef5b4cee617bd36017da2953777f19b151c2.1920x1080.jpg
- https://steamcommunity.com/app/328080/discussions/0/133256758579816127
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg
- https://store.steampowered.com/app/2239150/Thronefall/
- https://roundtablecoop.com/?p=6227
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_8edcd3c9cb93ee1e38df6ad676166ff567d4a7cb.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c7a8ad6065ddaa4789935d28d99e24c940c2181c.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2140020/ss_60637ca071b3493304355e3f2818bd191aee61cf.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_af7361cb88294d6515bd7cb85b94c90dc3e070ec.1920x1080.jpg
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/541dce83a952beb779f2221cb107c6557f192439/ss_541dce83a952beb779f2221cb107c6557f192439.1920x1080.jpg
- https://www.surrenderat20.net/2014/06/update-to-summoners-rift-headed-to-pbe.html?m=1
- https://maxfreeman.carrd.co/
- https://lospec.com/articles/pixel-art-outlines-part-2-using-color
- https://blendogames.com/news/post/2025-07-02-skindeep_art/
- https://www.gamedeveloper.com/design/affordance-design-in-half-life-2
- https://docs.unity3d.com/Packages/com.unity.polyspatial.visionos@1.0/manual/HoverEffect.html
- https://s2editor-guides.readthedocs.io/New_Tutorials/04_Data_Editor/073_Footprints/
- https://sc2mapster.wiki.gg/wiki/Data/Actors/Doodad
- https://vaporlens.app/app/867210/songs_of_conquest.md
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/867210/ss_1547033ea1673abf58e8e76cc87f94f3f055c39a.1920x1080.jpg
- https://gigazine.net/gsc_news/en/20180501-game-design-subway-legibility
- https://en.wikipedia.org/wiki/Kingdom_Rush
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/246420/ss_502205852350bfd8d64070adf4c38f2ffdf86772.1920x1080.jpg
- https://www.pcgamesn.com/thronefall/steam-full-launch
- https://games.gg/thronefall/
- https://store.steampowered.com/app/1105670/The_Last_Spell/
- https://steamcommunity.com/app/1105670/discussions/0/3118160027741933562

