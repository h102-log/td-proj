# 마당·울타리·밭·생활 소품 — 건물에 붙는 방식과 오인 방지 규칙

조사 범위: 건물 둘레의 마당·울타리·밭·생활 소품(③ 가설). 방법: Steam appdetails API 스크린샷 19개 게임 × 6장을 내려받아 직접 보고(필요한 곳은 확대 크롭), 개발자 발언·위키·실무자 글로 보강했다. «(스크린샷 직접 봄: URL)»은 내가 이미지를 직접 보고 적은 관찰이고, 해석은 «해석»이라고 따로 표시했다. 우리 화면(art/trial/preview/village_mood_final/3_wide.png, 2_overview.png)도 먼저 봤다. 관찰 결과: 집 6채·시설 3채·교회가 고른 갈색 흙 위에 서로 떨어져 서 있고, 건물 발밑에는 땅 변화(다져진 흙·그림자 띠)도 건물끼리 잇는 길도 없다. 풀 덤불은 맵 전체에 고르게 흩어져 있고, 땅이 달라지는 곳은 가운데 돌길뿐이다. 그 밖에 어두운 덤불 더미에 옅은 점선 고리가 둘린 물체 6개가 보이는데, 무엇인지는 모른다.

## Q1. 건물을 지으면 마당·울타리·밭·소품이 어떻게 붙는가 (자동·플레이어 배치·미리 깔림 / 그림의 일부인가 별도 오브젝트인가 / 몇 칸까지 / 상태에 따라 바뀌는가)

### Takeaway
«마을 같다»고 읽히는 게임은 거의 모두 마당을 **건물 발자국(footprint)의 일부**로 처리한다. 방법은 셋이다. 자동 생성 울타리 경계(Foundation), 플레이어가 그리는 필지(Manor Lords), 건물마다 깔리는 다져진 땅 패치(Northgard·Rise to Ruins·AoE2). 소품은 대개 건물 그림·모델에 붙어 있고 건물에서 1칸 안쪽에 몰린다. 반면 **밭은 이 장르에서 대부분 독립된 게임 요소**다(AoE2 Farm, Thronefall Fields, Stronghold 농장, K&C 농장). 그래서 밭을 꾸밈으로 쓰면 «짓는 건물»로 읽힐 위험이 크다.

### Cited Findings
**자동 생성 — Foundation**
- 플레이어가 주거 구역(Residential zone)을 칠하면 «Villagers will automatically place housing foundations within this zone». 집 배치는 «determined automatically when its foundations are first placed», 그 모양은 «indicated by the boundary fence»이고 업그레이드 뒤에도 유지된다 — [Foundation Wiki: Housing](https://wiki.polymorph.games/foundation/Housing)
- 밀도 1·2단계 집은 «similar footprints and gardens bounded by the fence»를 갖는다. 3단계는 «will fill out the fence boundary almost entirely». 품질 1단계는 «wattle and daub with thatched roofs and woven wattle fencing»이다. 즉 업그레이드(건물 상태)에 따라 마당이 줄고 울타리 재질이 바뀐다 — [Foundation Wiki: Housing](https://wiki.polymorph.games/foundation/Housing)
- «Decorations and buildings can be placed within the garden areas of houses with no ill effects». 다만 1·2단계 집 «directly over»에 놓으면 집이 부서지고, 3단계 집은 «adjust its size and shape around» 그 물체에 맞춘다 — [Foundation Wiki: Housing](https://wiki.polymorph.games/foundation/Housing)
- 집 둘레에 낮은 엮음 울타리(wattle), 꽃밭, 통, 벤치, 이정표, 화로, 낮은 돌담이 놓여 있다. 이 소품들에는 외곽선이 없고, **선택된 건물 한 채에만 흰 실루엣 외곽선**이 생긴다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_dbc1c23ffd249f0c8b07aae6312f33aa63a0e8eb.1920x1080.jpg)

**플레이어가 그리는 필지 — Manor Lords**
- 집(burgage plot)은 «4 point plotting system that can curve along roads and other buildings»로 놓는다. «give all your villagers a little garden to grow veggies or raise chickens»가 가능하고, «Make a plot big enough and you can even build extensions, or workshops» — [Siliconera preview](https://www.siliconera.com/preview-manor-lords-is-a-small-scale-city-builder/)
- 뒷마당 확장은 필지 안에만 짓는다(«Apple Orchards are Backyard Extensions and can only be built inside your Burgage Plots»). 필지 길이를 늘려야 확장을 지을 수 있다(«extend the length of the plot points») — [Game8: Apple Orchard](https://game8.co/games/Manor-Lords/archives/452178)
- (2차 요약, 세부 미검증) 확장 종류는 채소밭·닭장·염소 우리·사과 과수원이다. 닭장 산출은 크기와 상관없고 채소밭은 크기에 비례한다. 두 집이 뒷마당 하나를 나눠 쓸 수도 있다 — [Game8 Manor Lords 가이드 목록](https://game8.co/games/Manor-Lords/archives/452175), [Steam 토론](https://steamcommunity.com/app/1363080/discussions/0/4362376656109053467/)
- 위에서 보면 집마다 낮은 울타리선(얇은 선)으로 필지가 나뉘고, 뒤쪽에 짙은 흙 두둑·작은 헛간·장작더미가 있다. 필지는 길을 따라 휘고 모양이 제각각이다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg)

**절차적 소품 자동 배치 — Tiny Glade**
- 개발자(ana-sthetic): 게임이 «procedurally places props near windows, doors and gates». 소품은 «selected at random»이고 «a wall it can align to» 같은 맥락을 본다. 정식판 소품은 25종(데모 9종)으로, 사과 바구니·벤치·건초더미·수레·«boxes full of other clutter»가 있다 — [Steam 토론(개발자 답변)](https://steamcommunity.com/app/2198150/discussions/0/4844273660400957331)
- 나중 업데이트로 «the ability to move the automatically spawned clutter»가 생겼다. 개발자는 «end the tyranny of bird nests»라고 썼다(자동 소품을 플레이어가 통제하고 싶어 했다는 뜻) — [80.lv](https://80.lv/articles/tiny-glade-to-feature-movable-clutter-unlimited-lighting-sources/)

**건물 둘레 땅 패치 + 그림에 붙은 소품 — Northgard, AoE2, Stronghold**
- Northgard: 모든 건물이 저마다 **옅고 불규칙한 다져진 땅 패치** 위에 선다. 패치는 건물 폭의 절반~1배쯤 바깥까지 번진다. 통·상자·목재 거치대·방패·수레 같은 소품은 그 패치 안에서 건물 벽에 붙어 몰려 있다. 따로 울타리를 두르지는 않는다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg). 소품이 건물 모델의 일부인지 별도 오브젝트인지는 (미확인)이다.
- Age of Empires II: DE: 밭(Farm)은 땅 높이의 평평한 작물 무늬 직사각형으로 방앗간 둘레에 깔린다. 집 발치의 항아리·상자는 건물 그림에 붙어 있고, 꾸밈용 폐허 기둥·석상은 흰 돌로 따로 떨어져 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/813780/ss_ea0429a12f9d65f3e6b5384e0117fceef2109e45.1920x1080.jpg)
- Stronghold: Definitive Edition: 밀·홉 농장은 작은 오두막과 그 앞 밭이 한 건물로 붙어 있다. 오두막 문간의 통·의자, 작업장 안 도구(벽을 잘라 내부를 보여줌)는 모두 건물 그림에 들어 있다. 식량 창고로 보이는 나무 단 위에 사과·치즈가 쌓여 **재고가 소품 모양으로 보인다**(해석: 소품이 정보 역할을 함) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2140020/ss_56fc64a2d751072bc358035f499f57a794e8a870.1920x1080.jpg)

**픽셀아트 탑다운 디펜스 마을 — Rise to Ruins, The Last Spell**
- Rise to Ruins: 건물마다 얇은 기둥·가로대 울타리(가로대 1~2px에 밝은 네모 기둥머리, 그림자 있음)가 발자국을 두른다. 통나무·돌덩이·통·상자 같은 작업 소품은 **울타리 안에만** 있다. 건물 둘레 풀은 조금 더 짙게 밟힌 얼룩이다. 소품에도 짙은 외곽선과 그림자가 있지만, 울타리 안이라 «건물의 일부»로 읽힌다(해석) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_ca30ef5b4cee617bd36017da2953777f19b151c2.1920x1080.jpg)
- Rise to Ruins 개발자: 땅에 떨어진 자원은 진짜 아이템이고 «they actually don't block building». 다만 그 밑의 «rough terrain»(그루터기·돌 부스러기)은 건설을 막는다. 즉 **땅 위에 흩어진 물체 = 줍는 아이템**이라는 규칙이 이 게임에 있다 — [Steam 토론(개발자)](https://steamcommunity.com/app/328080/discussions/0/133256758579816127)
- The Last Spell: 건물은 칸 격자에 맞춘 **네모난 돌·나무 받침판(base plate)** 위에 선다. 통·광차 레일·자루는 받침판 없이 땅에 바로 놓이고 격자에서 비스듬하다. 높은 나무 울타리도 서 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg)

**밭이 게임 요소인 경우 — Thronefall, Kingdoms and Castles**
- Thronefall 스토어 설명: «Expand your economy with Houses, Bridges, Gold Mines, Harbors, Mills and Fields. These buildings grant you gold every morning – if they survive.» — [Steam 스토어(appdetails)](https://store.steampowered.com/app/2239150/Thronefall/). 프리뷰: «mills allow you to build farms that earn gold each day» — [RoundTableCoop](https://roundtablecoop.com/?p=6227)
- Thronefall 화면: 방앗간마다 평평한 판자 줄무늬 밭 두 개가 붙어 있다. 건물 발자국 둘레에 흐린 점선 네모가 보인다(뜻은 미확인) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg)
- Kingdoms and Castles: 집들이 마당 없이 빽빽이 붙어 있고, 밭은 집과 떨어진 짙은 고랑 블록으로 따로 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_8edcd3c9cb93ee1e38df6ad676166ff567d4a7cb.1920x1080.jpg)

**건물 상태에 따른 변화**
- Against the Storm: 짓는 중인 건물은 나무 비계(scaffold) 틀로 보인다. 완성된 집 현관의 자루·상자는 모델 일부다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1336490/ss_c7a8ad6065ddaa4789935d28d99e24c940c2181c.1920x1080.jpg)
- Stronghold DE(성 안 화재) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2140020/ss_60637ca071b3493304355e3f2818bd191aee61cf.1920x1080.jpg)와 Kingdoms and Castles(용 공격으로 집이 불탐) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_af7361cb88294d6515bd7cb85b94c90dc3e070ec.1920x1080.jpg)에서는 피해를 불·연기로 보여준다. 마당 소품이 피해 때 따로 바뀌는지는 (미확인)이다.
- Manor Lords: 뒷마당 확장 종류(채소밭 등)에 따라 울타리 친 텃밭이 보인다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/541dce83a952beb779f2221cb107c6557f192439/ss_541dce83a952beb779f2221cb107c6557f192439.1920x1080.jpg)

### Inferences
- 공통 패턴(해석): 마당은 **별도 오브젝트가 아니라 건물 발자국의 확장**이다. 땅 패치든 울타리 경계든 필지든, 클릭 대상은 건물 하나뿐이다. 그래서 소품이 아무리 많아도 «따로 누를 물건»으로 읽히지 않는다. 우리 게임처럼 빈 땅 어디에나 짓는 구조라면 Northgard/Rise to Ruins식 «건물을 지으면 함께 깔리는 마당»이 가장 잘 맞는다. 플레이어가 소품을 따로 놓는 방식(Against the Storm 장식 범주, Foundation 장식)은 범위·UI 비용이 크고, Tiny Glade 사례처럼 통제 요구가 생긴다.
- 우리 화면에 없는 것(해석): 지금 집들은 «땅 위에 놓인 말»처럼 보인다. 위 모든 사례에 있는 **건물 발밑 땅 변화(다져진 흙·짙은 얼룩·받침)**가 우리에게는 없다. 비용이 가장 싼 첫 단계는 건물마다 불규칙한 «다져진 흙 패치»(평평한 데칼, 외곽선·그림자 없음)를 까는 것이다. 다음으로 그 안쪽, 건물에서 1칸 안에 소품 1묶음을 둔다.
- 거리(해석): 관찰한 사례에서 소품은 건물 벽에서 대체로 **1칸(건물 폭의 1/3~1/2) 안**에 있다. 땅 패치는 건물 폭의 0.5~1배 바깥까지 번진다(Northgard 관찰). 우리 칸(16px)으로 옮기면 «건물 둘레 1~2칸 띠»가 상한이다.
- 상태 연동(해석): 많이 쓰는 방식은 건설 중엔 비계/빈 받침(ATS), 업그레이드 땐 재질·마당 크기 변경(Foundation), 피해 땐 불·연기다. 마당 소품을 상태마다 따로 그리는 사례는 이번에 확인하지 못했다. 그러니 우리도 «건설 중엔 마당 패치만, 완성되면 소품» 정도면 충분하다.
- 밭(해석): 장르 관습상 밭은 «짓는 경제 건물»이다(AoE2·Thronefall·Stronghold·K&C). 그러니 기각된 «생활 마을» 시안처럼 밭을 **독립 블록**으로 깔면 «짓는 것/지은 것»으로 읽힐 위험이 장르 관습 때문에 생긴다. 다시 쓰려면 집 마당 안에 붙은 1×2칸 이하 텃밭 데칼로만 써야 한다는 것이 근거 있는 차이점이다.

### Gaps
- Warcraft III 인간 농장(울타리·작물이 건물 모델에 들어간 것으로 기억)은 출처를 확인하지 못했다 (미확인).
- Banished·Kingdoms and Castles의 집 마당·업그레이드 규칙은 위키를 찾지 못했다 (미확인). 스크린샷으로 보면 둘 다 마당 없이 빽빽하다.
- Against the Storm 장식(Decorations) 위키는 403으로 막혀 칸 수·범주를 확인하지 못했다.
- Manor Lords 공식 위키(wiki.gg 401, fandom 402)가 막혀 확장별 최소 크기는 (미확인)이다.
- Northgard·AoE2 소품이 모델 일부인지 별도 데코 오브젝트인지는 개발자 자료가 없다.

## Q2. 소품이 클릭할 물건·아이템·장애물·방벽으로 오해되지 않게 하는 시각 규칙

### Takeaway
확인된 원칙은 셋이다. ① 환경은 시각 위계의 맨 아래에 두고 색·디테일·명도 범위를 눌러 «배경»이 되게 한다(Riot, ANTONBLAST). ② 외곽선은 대비를 키우는 도구이므로 상호작용 대상에만 강하게 쓴다(Lospec, Foundation의 선택 시에만 생기는 외곽선). ③ 소품은 건물 발자국·받침 안에 묶어서 «독립 물체»로 보이지 않게 한다(Rise to Ruins 울타리, The Last Spell 받침판). 픽셀아트 개발자가 «소품 vs 클릭 대상»만 따로 다룬 1차 발언은 찾지 못했다.

### Cited Findings
- Riot(Summoner's Rift 개편, Andrew «Riot Aeon» Brownell): «In Summoner's Rift today, the environment can compete visually with other game elements.» → «we're controlling color and level of detail, clamping value ranges». 위계는 UI → 스킬 → 챔피언·유닛 → 환경 순이다. «the environment should be the background, allowing particle effects and champions to pop off the screen» — [Surrender at 20 (Riot 데브 블로그 전재)](https://www.surrenderat20.net/2014/06/update-to-summoners-rift-headed-to-pbe.html?m=1)
- ANTONBLAST 환경 아티스트: 배경은 «a narrower range of brightness values»를 쓴다. 배경 층 게임 물체는 «tinted ... toward the background's colour palette and reduced their contrast»했다. 재질을 다 그리지 않고 암시만 해서 «less noisy in-game environments, giving more focus to important gameplay objects» — [Max Freeman 포트폴리오(ANTONBLAST)](https://maxfreeman.carrd.co/)
- Lospec: «an outline should always be darker than both the object AND the background behind it», «an outline should always increase contrast, and never decrease it». 외곽선은 뺄 수도 있다(«even in outline heavy styles you will need to do this sometimes») — [Lospec: Pixel Art Outlines Part 2](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)
- Blendo Games(Skin Deep): «There is a 'budget' for player attention, and it didn't make sense to spend it on a standard wall». 대비가 강하고 복잡한 벽지가 시선을 너무 끌어서 덜 바쁜 판으로 바꿨다 — [Blendo: Skin Deep Art Density](https://blendogames.com/news/post/2025-07-02-skindeep_art/)
- 어포던스: 물체가 지원하지 않는 행동을 암시하면 «false affordance»다. 플레이어가 무엇을 지각하느냐는 이전 게임 경험에 달렸다(같은 자물쇠도 Thief에선 따는 것, Half-Life에선 쏘는 것) — [Game Developer: Affordance design in Half-Life 2](https://www.gamedeveloper.com/design/affordance-design-in-half-life-2)
- 호버 강조는 «어느 물체가 입력을 받을지»를 알려 상호작용 가능함을 보여주는 데 쓰인다 — [Unity PolySpatial: Hover Effect](https://docs.unity3d.com/Packages/com.unity.polyspatial.visionos@1.0/manual/HoverEffect.html)
- Foundation: 흰 실루엣 외곽선은 선택한 건물에만 생긴다. 통·벤치·울타리·화로 같은 소품은 외곽선 없이 장면에 녹아 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_dbc1c23ffd249f0c8b07aae6312f33aa63a0e8eb.1920x1080.jpg)
- The Last Spell(픽셀아트): 상호작용하는 건물은 받침판 위에 있고 일부는 머리 위에 체력 막대·생산 아이콘이 뜬다. 땅에 그냥 놓인 통·레일에는 둘 다 없다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg)
- StarCraft II 에디터: 두들(doodad)은 기본이 장식이다. 길막기는 별도 «footprint»를 붙여야 생기고, 경로 층 선택지에 «None, No Building, Unpathable Terrain, Ground, Cliff»가 있다. 즉 «걸어갈 수는 있지만 건설은 못 하는» 장식이 엔진 개념으로 있다 — [S2 Editor Guides: Footprints](https://s2editor-guides.readthedocs.io/New_Tutorials/04_Data_Editor/073_Footprints/), [SC2Mapster: Doodad actor](https://sc2mapster.wiki.gg/wiki/Data/Actors/Doodad)
- 반례 — Songs of Conquest(픽셀아트 스타일 3D): 리뷰 요약에 «many reviewers finding it difficult to distinguish objects and units on the map», «an overabundance of detailed objects»가 나온다(Steam 리뷰를 모은 2차 집계라 신중히 볼 것) — [Vaporlens: Songs of Conquest](https://vaporlens.app/app/867210/songs_of_conquest.md). 마을 화면에서는 노란 외곽선으로 강조된 건물 한 채만 도드라진다(호버·선택 표시로 보임, 해석) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/867210/ss_1547033ea1673abf58e8e76cc87f94f3f055c39a.1920x1080.jpg)

### Inferences
우리 함정 4개(짙은 외곽선 → 클릭 물건, 청회 돌 → 성벽, 반듯한 네모 → 집터, 솟은 벽 → 장애물)에 맞춘 규칙이다(모두 해석).
1. **외곽선**: 소품에 시설의 1px 짙은 남색 외곽선을 쓰지 않는다. 땅에 붙은 것(패치·텃밭·흙길)은 외곽선 없이 바닥 색 안에서만 명도 차를 둔다. 서 있는 소품(통·장작)은 자기 색보다 한 단계 어두운 색 외곽(selout) 또는 외곽선 없음으로 그린다. 근거는 Lospec «외곽선은 대비를 키우는 도구», Foundation «외곽선은 선택 상태 신호». 남색 외곽선은 «누를 수 있는 시설»의 표지로 남겨 둔다.
2. **명도·채도**: 소품 명도 범위를 바닥(흙) 쪽으로 좁힌다(Riot «clamping value ranges», ANTONBLAST «narrower range»). 가장 밝은 색과 가장 진한 채도는 시설·유닛·아이템 몫으로 남긴다.
3. **재질 분리**: 성벽과 같은 청회 돌을 마당 소품에 쓰지 않는다. 마당 경계는 흙·나무·짚 같은 따뜻한 색으로만 한다. 우물이 «클릭 물건»으로 읽혔다면 같은 돌 재질 소품도 같은 문제를 겪는다.
4. **모양**: 닫힌 직사각형 테두리는 집터·구역 표지(Manor Lords 필지선, Foundation 구역 칠, Thronefall 점선 네모)와 겹친다. 그래서 마당 패치는 **가장자리가 불규칙한 얼룩**으로 하고 울타리는 한두 면만 두른 열린 L자로 한다.
5. **높이·그림자**: 그림자는 «높이 있음 = 막을 수 있음»으로 읽힌다(Rise to Ruins·The Last Spell 관찰). 땅 데칼은 그림자를 두지 않는다. 울타리는 유닛 키보다 확실히 낮게(유닛 키의 1/3 안팎) 그린다. 서 있는 소품은 반드시 건물 실루엣에 닿게 붙여 «건물 그림의 일부»로 읽히게 한다.
6. **흩뿌림 금지**: Rise to Ruins처럼 «땅 위 낱개 물체 = 줍는 아이템» 규칙이 있는 게임에서 혼자 떨어진 통·건초는 아이템으로 읽힌다. 소품은 마당 패치 안에 묶음으로만 둔다.
7. **반응 없음**: 소품은 호버 강조·커서 변화·클릭 반응을 주지 않는다. 클릭은 아래 건물·땅으로 그대로 넘긴다(Unity 문서: 호버 강조 = 입력 대상 신호). 마당 칸은 SC2 «No Building»처럼 «걸을 수 있음·짓기는 막음 또는 허용»을 하나로 정해 일관되게 지킨다. 허용한다면 Foundation처럼 새 건물을 지을 때 마당 소품을 지우는 규칙이 필요하다.

### Gaps
- 픽셀아트 RTS/디펜스 개발자가 «장식 소품을 클릭 대상과 구별하는 법»을 직접 말한 1차 자료는 찾지 못했다(검색 2회가 일반론만 반환).
- 그림자 = 높이·통행 불가 신호라는 규칙의 출처는 찾지 못했다. 관찰과 해석뿐이다.
- Zach Gage GDC 2018 «Three Reads» 슬라이드 원문(stfj.net)은 인증서 오류로 열지 못했다. 2차 요약만 있다: 첫째 읽기 = 한눈에 직관적, 둘째 = 중요하지만 덜 직관적, 셋째 = 세부 — [Gigazine 요약](https://gigazine.net/gsc_news/en/20180501-game-design-subway-legibility). 소품은 «셋째 읽기»에 둔다는 것이 해석이다.

## Q3. 요새·변경·전시(戰時) 마을 느낌을 내는 소품을 디펜스 게임이 어떻게 쓰고, 게임 요소와 어떻게 구별하나

### Takeaway
디펜스·전략 게임 사례에서 «전시» 소품은 두 길로 나뉜다. Kingdom Rush는 고정 건설 자리 덕에 **경로·자리 밖 가장자리**에 통·건초·수레·불탄 오두막·떨어진 무기를 마음껏 깐다. Thronefall은 군사처럼 보이는 것(망루·목책)을 **전부 실제 방어 시설로만** 두고 장식용 군사 소품은 거의 두지 않는다. 자유 배치에 «나무 울타리 = 아군 방벽» 혼동을 이미 겪은 우리에게 맞는 쪽은 후자의 원칙(«방어처럼 보이면 방어다»)이다. 전시 분위기는 **건물·성벽에 붙은 표식**(깃발·횃불·무기 거치대)으로 내는 것이 안전하다(해석).

### Cited Findings
- Kingdom Rush: 각 레벨은 «a number of pre-set roads, which the player can place defensive towers around» — [Wikipedia: Kingdom Rush](https://en.wikipedia.org/wiki/Kingdom_Rush)
- Kingdom Rush 화면(확대 크롭): 길과 탑 자리 밖 풀밭 가장자리에 통 묶음(3~4개씩), 건초 수레, 건초 블록, 지붕이 불탄 오두막 2채, 떨어진 창·도끼, 해골, 양, 작은 돌이 몰려 있다. 소품도 탑과 같은 만화풍 짙은 외곽선을 쓰지만 크기가 작고 흙빛·올리브 계열이다. 불탄 오두막은 탑보다 확실히 어둡고 채도가 낮다. 탑은 길 사이 둥근 풀섬 위에 따로 선다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/246420/ss_502205852350bfd8d64070adf4c38f2ffdf86772.1920x1080.jpg)
- Thronefall: 화면의 목책·망루·성은 모두 짓는 방어·경제 시설이고, 그 밖에 군사 소품은 보이지 않는다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg). 언론은 미니멀리즘을 «beautifully stark»라고 평했다 — [PCGamesN](https://www.pcgamesn.com/thronefall/steam-full-launch). «the minimalist art style keeps the visual read clean during chaotic night phases»(2차 소개 글) — [games.gg](https://games.gg/thronefall/)
- The Last Spell: 개발사 설명은 낮 단계를 «rebuild your Haven and position your defenses» 하는 시간으로 둔다 — [Steam 스토어](https://store.steampowered.com/app/1105670/The_Last_Spell/). 플레이어가 짓는 방어물에 «Catapults, traps, ballistas, watchtower, walls & barricades»가 있다 — [Steam 토론](https://steamcommunity.com/app/1105670/discussions/0/3118160027741933562). 화면에는 모래주머니·통·광차 레일·부서진 판자 울타리가 마을 곳곳에 깔려 있다. 이 울타리가 장식인지 플레이어가 지은 방벽인지는 화면만으로 가릴 수 없었다 (미확인) (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1105670/ss_21707800309517fb614cc65d26ff322f608da2c8.1920x1080.jpg)
- Northgard: 여러 건물 지붕·벽에 진영 색(초록) 천 깃발이 달려 있다. 깃발은 «우리 것» 표지로 건물 일부가 되고 독립 소품이 아니다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg)
- Songs of Conquest: 성벽 바깥 길가에 장대 횃불, 성 안에 깃발이 있고, 성벽·탑은 도시 그림 일부로 고정돼 있다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/867210/ss_1547033ea1673abf58e8e76cc87f94f3f055c39a.1920x1080.jpg)

### Inferences
- (해석) Kingdom Rush가 가장자리에 전시 소품을 많이 깔 수 있는 것은 **건설 자리가 고정**이라 «여기 지을 수 있나?»라는 질문이 생기지 않기 때문이다. 우리는 빈 땅 어디에나 짓는 구조라 같은 소품을 맨땅에 흩으면 «장애물인가·아이템인가·짓기를 막나»가 매번 생긴다. 기각된 «전시 보급»(상자·수레·말뚝) 시안이 실패한 것과 같은 이유다.
- (해석) 우리에게 맞는 전시 표식(모두 «건물·성벽에 붙는다»가 공통): 집·병영 박공에 진영 색 천 깃발(Northgard식). 병영 그림 안 벽에 기댄 창 거치대(병영 스프라이트 일부). 성벽 안쪽 횃불은 이미 있다. 사격장 마당 안의 짚 과녁 더미는 사격장 그림 일부여야 하며, 따로 서 있으면 사격장과 헷갈린다는 Gemini 지적과 부딪친다.
- (해석) «나무 울타리 = 아군 방벽» 오인을 피하는 차이점: 방벽은 유닛보다 키가 크고 길게 이어지며 들판(27행 아래)에 있다. 마당 울타리는 유닛 키의 1/3 안팎으로 낮고, 한 집의 한두 면만 짧게 두르고, 성벽 안쪽에만 있고, 집 벽에 닿아 끝난다. 다시 꺼낸다면 이 네 가지가 기각된 시안과의 근거 있는 차이다.

### Gaps
- Kingdom Rush·Thronefall 개발자가 «장식 소품 vs 건설 자리·방어물» 구분을 직접 말한 자료는 찾지 못했다(Kingdom Rush 검색 1회, Thronefall 인터뷰 원문 미확보).
- The Last Spell 장면의 울타리가 장식인지 플레이어 방벽인지 (미확인).
- Stronghold 무기고·창고의 재고 표시 방식은 검색으로 확인하지 못했다(스크린샷 관찰만 있음).

## Q4. 소품 밀도 예산(clutter budget) — 저해상도에서 얼마나 두면 «사는 곳»이고 얼마부터 시끄러운가

### Takeaway
수치화된 업계 기준은 찾지 못했다. 가장 가까운 실무 지침은 Blendo의 «대부분 평평하게, 촘촘한 디테일 주머니를 조금»(80/20, 본인도 «vibe»라고 밝힘)과 Riot의 «환경의 색·디테일·명도 범위를 누른다»이다. 관찰한 사례는 «건물마다 소품 한 묶음(2~5개)을 건물에 붙인다»로 모인다. 우리 마을에 그대로 적용하면 마당이 전체 마을 칸의 5~15%쯤이라 80/20 안에 넉넉히 들어간다(계산·해석).

### Cited Findings
- «The general guideline was to have something mostly be flat/undetailed, but include tight pockets of detail.» «high-density details should be used very sparingly.» 수치는 «It's intended to express a vibe»라고 밝혔다 — [Blendo: Skin Deep Art Density](https://blendogames.com/news/post/2025-07-02-skindeep_art/)
- Riot: «controlling color and level of detail, clamping value ranges, ... all of which makes for a cleaner gameplay space where critical information pops off the screen» — [Surrender at 20 (Riot 데브 블로그 전재)](https://www.surrenderat20.net/2014/06/update-to-summoners-rift-headed-to-pbe.html?m=1)
- ANTONBLAST: 재질을 암시만 해서 «less noisy» 환경을 만들고 게임 물체에 초점을 줬다 — [Max Freeman 포트폴리오](https://maxfreeman.carrd.co/)
- 반례: Songs of Conquest 리뷰 집계 «an overabundance of detailed objects», 물체·유닛 구분이 어렵다(2차 집계) — [Vaporlens](https://vaporlens.app/app/867210/songs_of_conquest.md)
- 관찰 — 건물당 소품 양:
  - Northgard: 건물마다 땅 패치 안에 소품 2~5개 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/466560/ss_eb6ecfd37f68dc5cadabf603c4ab890d2a545730.1920x1080.jpg)
  - Rise to Ruins: 울타리 마당 하나에 작업 소품 5~12개. 다만 저장·생산 기능을 보여주는 소품이다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/328080/ss_ca30ef5b4cee617bd36017da2953777f19b151c2.1920x1080.jpg)
  - Kingdom Rush: 같은 종류 2~4개씩 «묶음»으로 가장자리에 두고, 묶음 사이에는 빈 풀밭을 남긴다 (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/246420/ss_502205852350bfd8d64070adf4c38f2ffdf86772.1920x1080.jpg)

### Inferences
- (계산) 우리 마을은 60×27 = 1,620칸에 건물이 많아야 약 11채다. 건물마다 «건물 + 둘레 1칸» 마당(약 3×3칸 중 건물을 뺀 8칸 안팎)을 주면 마당은 약 88칸, 마을의 약 5%다. 둘레 2칸(약 4×4~5×4칸)이면 약 165~220칸, 10~14%다. 가운데 돌길·광장을 더해도 «디테일 20%» 안에 들어가므로, 마당만으로는 «시끄러워질» 위험이 낮다. 거꾸로 말하면 마당만으로 빈 흙땅 80% 이상이 채워지지는 않는다. 그 부분은 다른 갈래(길·지형·밀도)의 몫이다.
- (해석) 건물당 묶음은 **1개, 많아야 2개**, 묶음당 서 있는 소품은 2~4개로 둔다(Northgard·Kingdom Rush 관찰 범위). Rise to Ruins 수준(5~12개)은 소품이 재고·생산 정보를 보여줄 때만 정당하다. 우리 시설은 그런 정보를 소품으로 보여주지 않으므로 상한으로 삼지 않는다.
- (해석) 저해상도·줌아웃 기준: 3_wide(줌아웃)에서 집 하나가 화면에서 아주 작다. 2~3px 낱개 소품은 그 배율에서 점 잡음이 된다. 그러니 소품은 낱개보다 «묶음 하나 = 실루엣 하나»(예: 장작더미+통이 붙어 8×6px 덩어리)로 그린다. 맵 전체에 고르게 뿌린 지금의 풀 덤불처럼 균일 분포는 «무늬»로 읽히므로, 마당 소품은 건물 쪽으로 몰아 «사람이 산 흔적이 모인 곳»을 만든다(Blendo «tight pockets»).
- (해석) 검증 방법 제안: 1인치 스퀸트(흐리게 보기) 또는 1/4 축소 이미지에서 시설·유닛·아이템이 여전히 먼저 보이는지 확인한다(Riot 위계, Gage 첫째 읽기). 그 상태에서 «마당이 있는 집»이 «맨땅 위의 집»과 구별되는지도 함께 본다.

### Gaps
- 픽셀아트 RTS/디펜스에서 «칸당·화면당 소품 수» 같은 정량 기준은 찾지 못했다. 위 수치는 스크린샷 관찰과 우리 맵 계산이다.
- 저해상도(640×360)에서 소품 최소 크기 기준을 다룬 자료는 없었다.

WebSearch 사용: 25/25회 (WebFetch·curl은 따로 셈하지 않음). 내려받은 스크린샷: C:/Users/bhy99/AppData/Local/Temp/claude/C--Users-bhy99-td-proj/1de916d7-4a6e-45be-ba30-47d951a6e44d/scratchpad/shots_props/ (게임별 6장, _index.json에 URL). 1209340번은 잘못된 appid(Lords and Villeins 아님)라 쓰지 않았다.
