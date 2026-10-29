# 작은 도트에서 늑대 수인(늑대머리 인간형)이 읽히게 하는 법

조사일 2026-10-29. 대상: 24px로 굽는 무장 늑대 수인(45° 내려다보는 카메라, S·E·N·W 4방향, 걷기 2위상·공격 1·누움 1, 32색 팔레트, 풀밭·흙 위, 밤엔 횃불 밖 남색 덮개).

표기
- **[사실]** 출처 링크가 있는 내용. 영어 원문은 옮겨 적지 않고 한국어로 풀어 썼다.
- **[관찰]** Claude가 브라우저로 링크의 그림을 직접 보고 적은 것. 그림은 내려받지 않았다. 사실이지만 눈으로 본 해석이 섞인다.
- **[추론]** 위 둘을 바탕으로 한 판단. 측정·검증 전이다.
- 프로젝트 파일 근거는 `파일:줄`로 적었다(`tools/art/kobold.py`, `tools/art/wolf.py`).

출처 품질: 1차 출처는 게임 소스(SPD·DCSS GitHub), 공식 위키 위키텍스트(Kingdom Rush Fandom API), Valve 논문, Fatshark 개발 블로그, 작가 본인 튜토리얼(Saint11·Slynyrd·Lospec skeddles)이다. bugnet·wayline 같은 블로그와 itch.io 댓글은 현업자 의견으로만 쓴다. Fandom 문서는 WebFetch가 402로 막혀 브라우저에서 위키 API로 읽었다.

---

## Q1. 게임별 사례 — 크기·시점·강조한 특징·색

### Takeaway
작은 늑대·하이에나 수인은 공통으로 **머리 위 귀 두 점, 앞으로 나온 주둥이, 밝은 주둥이·가슴과 어두운 등, 털 갈기(목·어깨 톱니)** 를 쓰고, TD(Kingdom Rush)는 여기에 **빛나는 눈과 깊은 숙임**을 더한다. 같은 «개 계열» 이름인 코볼트를 둔 DCSS는 코볼트를 **비늘·뿔·가는 꼬리**, 놀을 **갈기·갑옷·직립**으로 갈라 그렸다.

### Cited Findings

**Shattered Pixel Dungeon(SPD) — 놀(gnoll)**
- [사실] 놀 스프라이트 한 칸은 가로 12 × 세로 15px다. 정지 2fps, 달리기 4프레임 12fps, 공격 3프레임, 죽음 3프레임이다 — [GnollSprite.java](https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/master/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/GnollSprite.java)
- [사실] 게임 설명은 놀을 하이에나 닮은 인간형으로 규정한다. 변종을 털색·소지품으로 가른다: 망명자는 회색 털에 어깨 표식과 창, 공병(sapper)은 옅은 털에 가방, 트릭스터는 앞으로 숙이고 웃는 얼굴에 가방, 경비(guard)는 창·방패를 들었지만 **투구는 없다**, 노련한 브루트는 갑옷을 입는다 — [actors.properties](https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/master/core/src/main/assets/messages/actors/actors.properties)
- [관찰] [gnoll.png](https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/core/src/main/assets/sprites/gnoll.png)(256×64 시트)는 옆모습 한 방향(좌우 반전)이다. 털색만 다른 세 줄(황갈·회색·적갈)이 있다. 머리 위에 1~2px짜리 **뾰족 귀 두 개**가 서 있고, 주둥이가 옆으로 2~3px 나오며, 가슴·배가 밝다. 죽음 프레임은 납작하게 엎드린 덩어리다.
- [관찰] [brute.png](https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/core/src/main/assets/sprites/brute.png)(256×32)는 같은 놀 몸에 **회색 통 투구**를 씌웠다. 귀는 투구에 가려 안 보이고, 주둥이는 투구 밑으로 여전히 튀어나온다. 투구 자체가 «브루트» 표식이 된다.

**Dungeon Crawl Stone Soup(DCSS) 타일 — 놀·코볼트·늑대가 한 게임에 다 있음**
- [사실] 타일은 32×32 PNG 낱장이다 — [OpenGameArt Dungeon Crawl 32x32 tiles](https://opengameart.org/content/dungeon-crawl-32x32-tiles). 놀(gnoll·gnoll_sergeant·gnoll_shaman)과 코볼트(kobold 외 여러 변종)가 같은 폴더(`rltiles/mon/humanoids/`)에 있다 — [crawl/crawl 저장소](https://github.com/crawl/crawl/tree/master/crawl-ref/source/rltiles/mon/humanoids)
- [사실] 게임 설명에서 놀은 고블린보다 크고 장비가 좋은 친척으로 «조금 개를 닮았다», 코볼트는 «작고 잿빛이며 들개 같은 생김새와 성질»이다. 글로는 **둘 다 개 계열**이다 — [monsters.txt](https://raw.githubusercontent.com/crawl/crawl/master/crawl-ref/source/dat/descript/monsters.txt)
- [관찰] 그런데 그림은 확실히 갈린다. [gnoll.png](https://github.com/crawl/crawl/blob/master/crawl-ref/source/rltiles/mon/humanoids/gnoll.png): 정면 3/4, **겨자색 털에 하이에나 머리, 작고 둥근 귀, 목에서 등으로 흐르는 짙은 갈기**, 녹회색 옷·허리띠, 어깨가 넓고 꼿꼿이 선다. gnoll_sergeant는 **붉은 눈**과 보라 갑옷·파란 방패를 더했다. [kobold.png](https://github.com/crawl/crawl/blob/master/crawl-ref/source/rltiles/mon/humanoids/kobold.png): 옆 3/4, **잿빛 청록 매끈한 피부에 황갈 배, 길쭉한 도마뱀 주둥이·이빨, 붉은 눈, 이마의 작은 보라 뿔, 가늘고 끝이 뾰족한 긴 꼬리**, 앞으로 숙인 자세, 뒤로 꺾인 다리. kobold_brigand는 여기에 붉은 두건·회색 갑옷을 걸쳤다.
- [관찰] [wolf.png](https://github.com/crawl/crawl/blob/master/crawl-ref/source/rltiles/mon/animals/wolf.png)(네발 늑대): 옅은 회색, **등 위로 말려 올라간 굵은 꼬리**가 실루엣의 큰 몫이다.

**Kingdom Rush 시리즈(TD, 손그림 래스터·도트 아님, 위에서 비스듬히 본 3/4)**
- [사실] Werewolf(KR «Curse of Castle Blackburn»): 저주로 늑대인간 꼴에 갇힌 옛 전사. 속도 빠름, 초당 8 회복, 근접 40~60 — [Kingdom Rush Wiki: Werewolf](https://kingdomrushtd.fandom.com/wiki/Werewolf)(위키 API 위키텍스트로 확인)
- [사실] Lycan: 처음엔 약한 인간으로 들어와 체력 25%에서 크고 사나운 늑대인간으로 변한다. 속도는 인간일 때 보통, 변신 뒤 빠름 — [Kingdom Rush Wiki: Lycan](https://kingdomrushtd.fandom.com/wiki/Lycan)
- [사실] KR Origins의 놀은 하이에나 계열이다. Hyena는 놀이 기른 빠른 짐승이고, Gnoll Burner는 횃불을 던지며, Gnoll Gnawer는 이 게임 **첫 갑옷 적**이다 — [Hyena](https://kingdomrushtd.fandom.com/wiki/Hyena), [Gnoll Burner](https://kingdomrushtd.fandom.com/wiki/Gnoll_Burner), [Gnoll Gnawer](https://kingdomrushtd.fandom.com/wiki/Gnoll_Gnawer)
- [관찰] 도감 그림 [EnemySqr_WerewolfSM.png](https://kingdomrushtd.fandom.com/wiki/File:EnemySqr_WerewolfSM.png)·[EnemySqr_Werewolf.PNG](https://kingdomrushtd.fandom.com/wiki/File:EnemySqr_Werewolf.PNG): **짙은 청회색 털, 밝은 회색 주둥이·배, 노랗게 빛나는 눈, 크게 선 귀**, 등을 둥글게 말아 거의 네발로 달리는 낮은 자세, 선 자세에선 긴 발톱. 밝은 회색 돌길 위라 어두운 몸이 또렷하다.
- [관찰] [EnemySqr_LycanSM.png](https://kingdomrushtd.fandom.com/wiki/File:EnemySqr_LycanSM.png): 늑대인간 꼴은 **자갈색(보라 섞인 갈색) 털, 옅은 얼굴·가슴, 붉은 눈, 벌린 붉은 입**, 머리보다 높이 솟은 어깨 혹. 인간 꼴은 웃통 벗은 사내라 한눈에 다르다.
- [관찰] [KRO_EnemyBox_Gnoll_Reaver.png](https://kingdomrushtd.fandom.com/wiki/File:KRO_EnemyBox_Gnoll_Reaver.png): 녹갈·올리브 털의 **둥근 덩어리 몸, 머리·등의 삐죽한 갈기, 노란 눈**, 목이 없이 머리가 몸에 붙었다. 연두 풀밭·모래길 위에서 몸이 풀보다 어둡다. [KRO_EnemyBox_Gnoll_Gnawer.png](https://kingdomrushtd.fandom.com/wiki/File:KRO_EnemyBox_Gnoll_Gnawer.png): 갈색 털에 **고슴도치처럼 큰 갈기**, 해골 어깨받이·철퇴, 갑옷은 몸에만 있고 **머리는 맨머리**.
- [관찰] [EnemyBox_Werewolf.png](https://kingdomrushtd.fandom.com/wiki/File:EnemyBox_Werewolf.png)(Vengeance): 청록빛 털의 늑대인간들이 어두운 자줏빛 바닥 위에 있다.

**Shining Force(SEGA, 전술 RPG)**
- [사실] Zylo는 Shining Force 1과 리메이크에 나오는 선택 동료로 늑대 종족(wolfling) 전사다 — [검색 요약: Shining wiki Zylo](https://breezewiki.discard.no/shining/wiki/Zylo)(본문은 봇 차단으로 못 읽음)

**D&D·WoW(도트 아님, 이름 혼선의 뿌리)**
- [사실] D&D 코볼트는 초기판에서 털 없고 작은 뿔이 있는 존재로 묘사됐고, 1983 Mentzer Basic은 녹슨 갈색 비늘에 털 없는 «개 닮은 작은 사람»이라 했다. 그림은 작가마다 도마뱀 쪽·개 쪽으로 갈렸고, 이 판이 일본에 들어가 일본 게임·애니 코볼트는 개가 됐다. 3판(Wizards of the Coast)이 «파충류» 하위 유형과 도마뱀 생김새로 정리했다 — [Mythoi: Kobolds — Fairy, Lizard, Dog?](https://mythoi.substack.com/p/kobolds-fairy-lizard-dog)
- [사실] Warcraft의 코볼트는 쥐 닮은 작은 지하 인간형이고, 굴을 밝히려 **머리에 초를 얹는다** — [warcraft.wiki.gg Kobold](https://warcraft.wiki.gg/wiki/Kobold)(검색 요약)

### Inferences
- [추론] 사례 대부분이 **귀·주둥이·갈기·꼬리 중 둘 이상**을 겹쳐 쓴다. 하나만 쓰는 사례는 없었다. 24px에서도 최소 «선 귀 + 목 갈기» 둘은 겹쳐야 한다.
- [추론] SPD 12×15에서도 귀 1~2px, 주둥이 2~3px로 읽힌다. 우리 24px(대략 그 두 배)이면 귀 2~3px·주둥이 3~4px가 잡힌다. 다만 SPD는 옆모습 한 방향뿐이라 정면·뒷모습 근거로는 약하다.
- [추론] DCSS는 글로는 둘 다 개 계열인데 그림으로 갈랐다. 이름이 겹쳐도 **피부 질감(비늘↔털), 머리 장식(뿔↔귀), 꼬리 굵기, 자세(숙임↔직립), 장비(맨손↔갑옷)** 다섯 축으로 가를 수 있다는 실례다.
- [추론] KR은 늑대인간을 «빠름·회복», 놀을 «무리·갑옷» 역할로 쓰고, 그림도 그 역할에 맞췄다(늑대인간=낮게 숙여 달림, Gnawer=갑옷·큰 갈기).

### Gaps
- 질문에 든 Iron Marines, Battle Brothers, Wildermyth, Stoneshard, Tactics Ogre, Final Fantasy Tactics, Fire Emblem GBA, Moonlighter, Children of Morta, Legend of Keepers, Brogue, Dwarf Fortress 타일셋, Octopath Traveler는 찾아보지 못했다(검색·도구 예산). 이 가운데 늑대 수인 적이 실제로 있는지도 확인하지 않았다.
- Kingdom Rush 적의 **게임 안 실제 픽셀 높이**는 못 찾았다. 본 그림은 도감용 확대 장면이다.
- Shining Force 맵 스프라이트 크기(24×24라는 통설)와 Zylo 맵 그림은 출처를 못 찾았다.
- Breath of Fire(Bo·Bow), Golden Sun TLA(Garoh 마을 늑대인간), Trials of Mana(수인 왕국)도 3/4 시점 소형 늑대 인간형 예로 유력해 보이나 조사하지 않았다.

---

## Q2. 16~24px·뒷모습에서 살아남는 단서, 갑옷·투구 아래 귀·꼬리

### Takeaway
뒷모습에서는 주둥이가 사라지므로 **머리 위 귀 두 점(머리 윤곽을 «M» 꼴로 끊음), 목·어깨의 갈기 톱니, 굵고 끝이 밝은 꼬리, 등의 덧붙임(무기·가죽)** 이 대신 일한다. 사례들은 대체로 **머리를 맨머리로 두고 갑옷은 몸통·어깨에** 입혔고, 투구를 씌운 경우(SPD 브루트)는 귀를 포기하고 투구 모양을 새 표식으로 삼았다.

### Cited Findings
- [사실] Slynyrd: 작은 크기에선 머리가 전체 높이의 1/3~1/2을 차지하는 게 보통이고, 사실 비례는 막대 인형처럼 보인다. 4방향은 위·아래·옆 셋을 그리고 옆을 반전하되, 비대칭이거나 방향광이 강하면 반전하지 않는다 — [Pixelblog 22 – Top Down Character Sprites](https://www.slynyrd.com/blog/2019/10/21/pixelblog-22-top-down-character-sprites)
- [사실] Fatshark(Darktide): 플레이어 시선이 **머리·어깨**에 몰려 그 부분이 차이 인식에 가장 크게 작용했다. 그래서 늦게라도 용접 마스크·방독면 같은 머리 표식을 더했다. **등에 붙이는 덧붙임**은 앞·옆 실루엣을 다 바꿔서, 원거리 정예에는 늘 등 덧붙임을 달았다 — [Darktide 101: Enemy Character Art dev blog](https://devtrackers.gg/darktide/p/67a2496a-darktide-101-enemy-character-art-dev-blog)
- [사실] SPD 놀 경비는 창·방패를 들었지만 투구는 없다고 설명한다. 노련한 브루트는 신분 표시로 갑옷을 입는다 — [actors.properties](https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/master/core/src/main/assets/messages/actors/actors.properties)
- [관찰] SPD brute는 통 투구가 귀를 덮지만 주둥이는 투구 밖에 남는다(Q1). KR Gnoll Gnawer는 갑옷을 입고도 머리는 맨머리, 큰 갈기를 그대로 드러낸다(Q1).
- [관찰] DCSS 늑대 타일은 등 위로 말린 굵은 꼬리가 실루엣의 큰 몫이다(Q1).
- [사실] Valve TF2: 아홉 병과는 내부 음영 없이 실루엣만으로 구분되게 설계했고, 그 구분은 **몸 비례·무기·모자·신발·옷 주름**이 만든 윤곽선으로 냈다 — [Illustrative Rendering in Team Fortress 2 (NPAR 2007)](https://cdn.cloudflare.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf)
- [사실] 수인 종족의 귀가 투구를 뚫고 나오게 하려고 Skyrim 이용자들이 모델을 고치거나 수인용 투구 모드를 쓴다. 투구와 짐승 귀가 충돌하는 문제는 흔하다 — [Steam Workshop 토론](https://steamcommunity.com/workshop/filedetails/discussion/7405/613936039418287016)(검색 요약)
- [사실] 프로젝트의 코볼트에는 **뒤로 뻗은 뿔 한 쌍**이 있다(`tools/art/kobold.py:44`, 주석 «뒤로 뻗은 뿔»). 몸은 0.85배, 숙임 16°, 꼬리는 허리에서 뒤아래로 뻗는 캡슐(반지름 0.055→0.02)이다(`tools/art/kobold.py:18,20,40`).

### Inferences
- [추론] 카메라가 45° 위에 있어 머리 꼭대기는 **네 방향 모두에서** 보인다. 그래서 귀는 S·E·N·W 공통 단서가 될 수 있는 유일한 머리 부위다. 주둥이는 N에서 사라지고 E·W에서 가장 세다.
- [추론] **귀는 수직으로 세운 큰 삼각형**(24px 기준 높이 2~3px, 두 귀 사이 1px 이상 빈칸)이어야 한다. 코볼트 뿔이 뒤로 눕혀져 있으므로, 귀가 뒤로 누우면 N 방향에서 코볼트 뿔과 겹쳐 읽힌다.
- [추론] N(뒷모습) 단서 우선순위: ① 머리 윤곽의 귀 두 점 ② 목·어깨 갈기 톱니(밝은 털색이면 어두운 등과 명암차가 생김) ③ 다리 사이로 늘어진 **굵은 꼬리와 밝은 꼬리 끝**(라운드 2 네발 늑대가 이미 꼬리 끝을 `pale` 재질로 칠함, `tools/art/wolf.py:132-134`) ④ 등에 멘 무기나 가죽 망토(Darktide 등 덧붙임). 넷 중 둘 이상이 N 그림에 남아야 한다.
- [추론] 갑옷: 사례처럼 **머리는 맨머리(또는 귀 구멍이 난 반모·머리띠)**, 갑옷은 어깨받이·흉갑·허리띠로 둔다. 투구를 꼭 씌울 변종(정예 등)은 SPD 브루트처럼 투구 모양을 그 변종의 새 표식으로 받아들이고, 대신 주둥이·꼬리·갈기를 남긴다. 단, 우리 오크가 «뿔 투구»를 쓰므로 늑대 수인 투구는 뿔이 없어야 하고, 귀 구멍으로 귀를 내는 편이 덜 헷갈린다.
- [추론] 24px에서 꼬리를 다리 사이에 두면 걷기 2위상에서 다리와 뭉칠 수 있다. 꼬리를 살짝 옆으로 빼거나(좌우 비대칭) 끝색을 밝혀 다리와 명도를 달리하는 편이 안전하다. 비대칭이면 Slynyrd 말대로 E·W 반전을 쓰지 않아야 하는데, 이 프로젝트는 이미 4방향을 다 굽는다(`tools/art/wolf.py:3`).

### Gaps
- 늑대 수인·놀의 **뒷모습(N) 소형 스프라이트**를 실제로 보여 주는 게임 사례는 찾지 못했다(SPD는 옆모습뿐, DCSS는 단일 방향, KR 도감도 앞·옆). 뒷모습 단서는 추론이다.
- 귀를 투구 위로 낸 소형 도트 사례도 찾지 못했다.

---

## Q3. 도트 튜토리얼의 지침 — 실루엣·동물머리 인간형

### Takeaway
작가들은 공통으로 **실루엣을 먼저 잡고, 그 실루엣에 한눈에 알아볼 «강한 요소»를 하나 이상 넣고, 실제 크기에서 뭉개지는 디테일은 버리라**고 한다. 털은 가닥을 그리지 말고 몇 개의 톱니·물결 덩어리로 암시한다.

### Cited Findings
- [사실] Saint11(Pedro Medeiros) «Character Design 1/Silhouette»: 실루엣은 보는 이가 가장 먼저 알아채는 서막이다. 실루엣에 알아보기 쉬운 **강한 요소**를 넣는다(예: 납작한 머리·무한궤도). 뾰족한 모서리·긴 팔다리·복잡하고 날카로운 모양은 위험을 전한다. 작업 순서는 실루엣 스케치 → 디테일 → 애니메이션이고, 애니메이션도 실루엣으로 먼저 그리면 동작이 읽히는지 확인하기 쉽다 — [Silhouette.gif](https://saint11.art/img/pixel-tutorials/Silhouette.gif) (목록: [saint11.art 튜토리얼](https://saint11.art/blog/pixel-art-tutorials/))
- [사실] Slynyrd: 큰 스프라이트는 단색 신체 부위로 된 더미로 동작을 먼저 잡고 디테일을 나중에 얹는다. 작은 크기에선 머리를 크게(높이 1/3~1/2) — [Pixelblog 22](https://www.slynyrd.com/blog/2019/10/21/pixelblog-22-top-down-character-sprites)
- [사실] imonk(itch.io 털 튜토리얼): 털 가닥 하나하나는 아주 큰 스프라이트가 아니면 그릴 수 없고, **32px 안팎에선 가닥을 아예 안 그려도 된다**. 털 덩어리 안에 톱니·물결 몇 개만 넣으면 털로 읽힌다. 외곽을 온통 삐죽삐죽하게 그리고 안을 질감으로 채우던 초보 습관은 지금은 쓰지 않는다고 했다 — [Pixel Tutorial – Fur](https://itch.io/post/6047047)
- [사실] Lospec(skeddles): 외곽선은 대비를 늘려야지 줄이면 안 되며, 물체와 뒤 배경 **둘 다보다 어두워야** 한다. 선택적 외곽선(sel-out)은 배경색을 고려해야 하고, 어두운 배경에선 결국 검정만 통했다. 안쪽 선은 보는 이에게 가까운 부위의 색을 쓴다 — [Pixel Art Outlines Part 2: Using Color](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)
- [사실] Valve TF2: 실루엣 구분은 콘셉트 단계에서 «음영 없는 실루엣으로도 읽히는가»로 검증했다. 안쪽 옷 주름도 실루엣 모양을 되풀이하게 그려 실루엣을 강조했다. 높은 주파수 디테일은 되도록 뺀다 — [TF2 NPAR 2007](https://cdn.cloudflare.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf)
- [사실] Fatshark(Darktide): 적마다 고유 색을 주는 실험은 오히려 시끄럽고 덜 읽혔다. 개체마다 튀게 하는 대신 **적 종류·역할·교전 거리별로 가독성 우선순위**를 정했다 — [Darktide dev blog](https://devtrackers.gg/darktide/p/67a2496a-darktide-101-enemy-character-art-dev-blog)
- [사실] 현업 블로그들: 색조보다 모양이 혼전 속에서 읽힌다, 흑백으로 바꿔도 구분되는지 시험하라 — [bugnet: readable game art](https://bugnet.io/blog/readable-game-art-why-clarity-beats-detail); 가독성은 색이 아니라 명도 대비에서 온다, 그림자는 차갑게·밝은 면은 따뜻하게 — [wayline: Color and limited palettes](https://www.wayline.io/learn/pixel-art/2)(둘 다 현업 의견 수준)
- [사실] 작은 스프라이트는 무엇을 강조할지 먼저 정해야 한다는 튜토리얼이 있다 — [Wyv and Keep: Through the Magnifying Glass part two](https://www.moddb.com/games/wyv-and-keep-temple-of-the-lost-idol/tutorials/through-the-magnifying-glass-part-two)(검색 요약, 본문 403)

### Inferences
- [추론] «동물머리 인간형»에서 Saint11이 말한 «강한 요소»는 귀(위로 솟은 두 삼각형)와 갈기(목의 톱니 고리)다. 무기는 두 번째 강한 요소로, 종류(창·도끼 등)를 고블린 몽둥이·오크 장비와 겹치지 않게 고르면 실루엣이 하나 더 갈린다.
- [추론] 3D 원시형으로 굽는 우리 방식에선 imonk의 «톱니 몇 개»를 목둘레·뺨·꼬리에 작은 원뿔·납작 타원 몇 개로 넣는 것이 대응된다. 몸 전체를 삐죽하게 만들 필요는 없다. 라운드 2 알파 늑대 갈기 메모(어깨·등까지 덮으면 안장 무늬처럼 읽혔다, `tools/art/wolf.py:107`)도 같은 방향이다.
- [추론] 검수는 «단색 실루엣으로 바꾼 4방향 × 코볼트·고블린·늑대와 나란히»가 TF2·Saint11 방식에 맞는다. 프로젝트 `preview()`가 이미 «위 줄에 비교 대상»을 두는 틀이다(`tools/art/kobold.py:60-63`).

### Gaps
- MortMort·Brandon James Greer는 영상 위주라 이번에 내용을 확인하지 못했다.
- Saint11 «Outlines», «Illumination Techniques», «Top-Down Walk Cycle» GIF는 열지 않았다(주소는 `https://saint11.art/img/pixel-tutorials/Outlines.gif` 등).
- Lospec에서 «동물머리 인간형»만 다룬 튜토리얼은 찾지 못했다.

---

## Q4. 늑대 수인과 코볼트(도마뱀개)를 작게 가르는 법

### Takeaway
같은 «개 주둥이 인간형»이라 이름부터 섞이기 쉬우므로(D&D 역사·DCSS 글), 그림은 **질감(털 톱니 ↔ 매끈한 비늘), 머리 장식(위로 선 귀 ↔ 뒤로 누운 뿔), 꼬리(굵고 끝이 밝음 ↔ 가늘고 뾰족), 색온도(차분한 회갈 ↔ 채도 높은 빨강), 체급·자세(크고 꼿꼿 ↔ 마르고 깊이 숙임), 장비(무기·갑옷 ↔ 맨손)** 로 여러 축을 동시에 갈라야 한다.

### Cited Findings
- [사실] D&D 코볼트는 처음부터 «개 닮은» 주둥이와 비늘·뿔이 섞인 존재였고 3판에서 도마뱀 쪽으로 정리됐다. 일본 쪽 코볼트는 개가 됐다 — [Mythoi](https://mythoi.substack.com/p/kobolds-fairy-lizard-dog)
- [사실] DCSS 글에서 코볼트는 들개 같고 놀은 조금 개 같다. 이름·설명만으로는 둘 다 개 계열이다 — [monsters.txt](https://raw.githubusercontent.com/crawl/crawl/master/crawl-ref/source/dat/descript/monsters.txt)
- [관찰] DCSS 그림에서 코볼트=매끈한 잿빛 청록 피부·작은 뿔·가는 꼬리·숙인 자세, 놀=겨자색 털·짙은 갈기·갑옷·직립·넓은 어깨(Q1).
- [사실] Warcraft는 코볼트를 쥐 닮은 몸에 **머리 위 초**라는 소품으로 표식했다 — [warcraft.wiki.gg Kobold](https://warcraft.wiki.gg/wiki/Kobold)(검색 요약)
- [사실] 프로젝트 코볼트: 비늘 램프 `300f0a 550f0a 9b1a0a 9b1a0a ef692f`(짙은 빨강 바탕), 허리 천 `151a26 262d3d 3a4357`, **눈 `efac28`(호박색)**, 0.85배, 숙임 16°, 앞으로 든 맨손 발톱, 앞으로 뻗은 주둥이, 뒤로 뻗은 뿔, 꼬리 — `tools/art/kobold.py:1,12-14,18,20-21,40-44`
- [사실] 프로젝트 라운드 2 네발 늑대 색: 늑대 회갈 털 `684c3c 927e6a`+밝은 `a4aec2 d0d6e0`, 도약 늑대 녹슨 주황 `724113 a56243`, 밤 늑대 검남색 `151a26 262d3d 3a4357`+눈 `efd8a1`, 알파 잿빛 `3a4357 56607a`+흰 갈기·**눈 `efac28`** — `tools/art/wolf.py:23-30`
- [사실] 프로젝트 고블린은 0.8배·숙임 12°다(`tools/art/goblin.py:21,23`). 과제 설명상 고블린은 회색에 몽둥이, 높이 13px다.
- [사실] imonk: 작은 털은 몇 개의 톱니·물결로 암시한다 — [itch.io 털 튜토리얼](https://itch.io/post/6047047). 비늘을 작은 도트로 표현하는 지침은 찾지 못했다(검색 요약도 같은 결론).

### Inferences
- [추론] 축별 권장(24px, 우리 팔레트 기준)

| 축 | 늑대 수인 | 코볼트(현행) | 메모 |
|---|---|---|---|
| 머리 장식 | **위로 선** 큰 삼각 귀 2~3px, 귀 안쪽 1px 밝은 색 | 뒤로 누운 뿔 | 뒷모습에서 가장 큰 차이 |
| 목·어깨 | 밝은 털 갈기 톱니(1~2px 들쭉날쭉) | 매끈한 캡슐 | 털 ↔ 비늘을 실루엣으로 |
| 꼬리 | 굵고(코볼트 이상) 끝이 밝음, 아래로 늘어짐 | 가늘어지며 뾰족 | 라운드 2 늑대와 같은 꼬리 문법 |
| 색온도 | 회갈·잿빛(`392a1c 684c3c 927e6a`, `3a4357 56607a 7a86a0`), 밝은 주둥이·가슴(`a4aec2 d0d6e0` 또는 `efd8a1`) | 채도 높은 빨강(`9b1a0a ef692f`) | 늑대 수인에 빨강·녹슨 주황을 몸 큰 면적에 쓰지 않기 |
| 눈 | 코볼트·알파와 다른 색(예: `efd8a1` 옅은 노랑, 또는 붉은 `ef3a0c`) | `efac28` 호박 | 밤엔 눈만 보일 수 있어 눈색이 사실상 종족 표식 |
| 체급·자세 | 1.0배 이상, 숙임은 코볼트(16°)보다 얕게, 어깨가 넓음 | 0.85배·16° | 고블린 0.8배·12°와도 갈림 |
| 손 | 무기(창·도끼·언월도 등, 고블린 몽둥이와 다른 꼴) + 어깨·가슴 갑옷 | 맨손 발톱 | «무장» 자체가 구분자 |
| 주둥이 | 짧고 굵은 원통 + 검은 코끝 1px(늑대 `nose` 재질과 같게) | 길고 가는 주둥이 | E·W에서만 큰 차이 |

- [추론] 가장 위험한 겹침은 **N 방향**이다. 코볼트 뿔(뒤로 누움)과 늑대 귀(위로 섬)가 모두 머리 위 두 점으로 찍히므로, 귀는 반드시 머리 윤곽 위로 수직으로 솟아야 한다.
- [추론] 두 번째 위험은 **네발 늑대(라운드 2)와의 혼동**이다(과제 밖이지만 같은 무리로 나온다면). 직립·무기·갑옷이 이를 가르고, 같은 털색 계열을 공유하면 «같은 늑대 세력»으로 묶여 읽히는 장점이 있다(Darktide의 «같은 연대로 보이는 공통 바탕 + 덧붙임» 방식과 같은 원리, [Darktide dev blog](https://devtrackers.gg/darktide/p/67a2496a-darktide-101-enemy-character-art-dev-blog)).
- [추론] 알파 늑대가 이미 `efac28` 눈이라 «늑대 = 호박 눈»이 성립돼 있다면, 코볼트 쪽 눈색을 바꾸는 선택지도 있다. 어느 쪽을 바꿀지는 사용자 판단이다.

### Gaps
- 작은 도트에서 «비늘 질감 vs 털 질감»을 직접 비교한 튜토리얼은 찾지 못했다.
- 늑대 수인과 코볼트를 한 게임에서 나란히 둔 **소형 3/4 시점** 사례는 DCSS(32px 단일 방향) 말고 찾지 못했다.

---

## Q5. 어두운 털의 적이 어두운 바닥·밤에 읽히게 하는 법

### Takeaway
어두운 바탕에서 어두운 외곽선은 효과가 없으므로, 사례들은 **위쪽·가장자리에 밝은 테(림·백라이트)**, **빛나는 눈**, **밝은 주둥이·가슴·갈기 면적**으로 실루엣을 세운다. Darktide는 멀고 어두운 곳의 적에 가짜 림라이트를 켜고, TF2는 검은 외곽선 대신 림 하이라이트로 실루엣을 세운다.

### Cited Findings
- [사실] Saint11 «Darkness»: 먼저 큰 모양을 잡고, 명암을 넣고, 강한 광점을 만들고, **강한 림·백라이트**를 더한다. 어두운 그림에선 중요한 디테일에 집중하고 나머지는 배경에 섞어 상상에 맡긴다. 어두운 배경 위의 사물은 한 색으로 낮은 대비를 유지하기도 한다. 그림자·실루엣이 실물보다 더 무섭다. 광원 방향은 늘 일정하게 — [Darkness.gif](https://saint11.art/img/pixel-tutorials/Darkness.gif)
- [사실] Fatshark(Darktide): 어둡고 대비 낮은 환경에서 먼 적이 묻히자, 거리가 멀어지면 서서히 켜지는 **가짜 림라이트**를 적 셰이더에 넣었다. 일부러 적을 안 보이게 하는 정전 모디파이어에선 끈다 — [Darktide dev blog](https://devtrackers.gg/darktide/p/67a2496a-darktide-101-enemy-character-art-dev-blog)
- [사실] Valve TF2: 실루엣을 **검은 외곽선이 아니라 림 하이라이트로** 강조한다. 광원에서 멀어진 캐릭터를 위해 따로 «전용 림라이트» 항을 두었고, 이 항은 **위를 향한 면에만** 들어가게 했다(사람은 빛이 위에서 온다고 여기는 본능을 이용). 그림자는 검정이 아니라 차가운 색으로 간다 — [TF2 NPAR 2007](https://cdn.cloudflare.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf)
- [사실] Lospec(skeddles): 외곽선은 물체·배경 둘 다보다 어두워야 하고, 어두운 배경에서 짙은 빨강 외곽선도 묻혀 결국 검정만 통했다 — [Lospec Outlines Part 2](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)
- [사실] 그림자가 짙게 지는 물체엔 그림자를 만들지 않는 반대편 광원(백라이트·림라이트)을 써서 어두운 가장자리를 밝혀 가독성을 지키라는 현업 조언 — [itch.io 댓글(Devil's Workshop)](https://itch.io/post/9656067)
- [사실] 스프라이트 가장 바깥 픽셀이 받는 빛을 계산해 색을 바꾸는 림라이트 셰이더를 쓴 인디 사례 — [Pixel Beef devlog](https://pixel-beef.itch.io/xdasher/devlog/192949/4-things-we-did-to-add-light-and-depth-to-our-pixel-art-game); Godot용 2D 림라이트 셰이더도 있으나 댓글에 따르면 광원 방향을 반영하지 않는다 — [GodotShaders 2D Rim Light](https://godotshaders.com/shader/2d-rim-light/)
- [관찰] KR 늑대인간은 노랑(Werewolf)·빨강(Lycan) **빛나는 눈**과 밝은 주둥이·배를 가졌고, 어두운 청회색 몸이 밝은 회색 돌길과 명도로 갈린다(Q1). DCSS 놀 상사도 붉은 눈이다(Q1).
- [사실] 게임에서 눈을 어둠 속 단서로 쓰자는 논의는 플레이어 토론 수준이다(어둠 속 눈빛이 긴장을 주되 적을 다 드러내지 않는다는 의견 등) — [Steam The Forest 토론](https://steamcommunity.com/app/242760/discussions/2/1694920442959122476)(권위 있는 설계 출처는 못 찾음)
- [사실] 프로젝트 밤 늑대는 이미 검남색 털(`151a26 262d3d 3a4357`)에 밝은 눈(`efd8a1`)을 쓰고, 눈을 머리 겉면에 걸쳐 둔 이유가 «안에 두면 묻혀 안 보였다»이다 — `tools/art/wolf.py:27-28,119`

### Inferences
- [추론] 우리 외곽선은 «어두운 외곽선»이고 밤 덮개는 남색이다. 늑대 수인 털이 `151a26`~`3a4357`처럼 어두우면 외곽선·몸·밤 바닥이 한 명도로 붙어 실루엣이 사라진다. Lospec 규칙(외곽선은 배경보다 어둡게)은 밤 덮개 아래에선 지킬 수 없으므로, 실루엣은 **안쪽의 밝은 테**가 세워야 한다.
- [추론] 45° 위 카메라라 TF2식 «위를 향한 면 림»이 그대로 맞는다. 머리 꼭대기·귀 끝·어깨·갈기 윗면을 램프 최상단(`7a86a0`·`a4aec2`, 또는 갈기를 `d0d6e0`)으로 두면 귀와 갈기 톱니가 밤에도 남는다. 4단계 음영 굽기에서 «윗면 = 최밝음»이 되도록 광원을 위쪽에 두는 것으로 충분할 수 있다.
- [추론] 눈은 1~2px라도 밤에 남는 마지막 단서다. 몸 털이 어두운 변종일수록 눈을 램프 최밝음(`efd8a1`) 단색으로 두고, 코볼트 `efac28`과 다른 색이면 밤에도 종족이 갈린다(Q4).
- [추론] 풀밭(`39571c`·`2d472d`)과 흙(`684c3c`) 위에서는 회갈 털(`684c3c`)이 흙과 같은 값이 된다. 몸 주색을 `684c3c` 하나로 두지 말고, 밝은 주둥이·가슴·갈기 면적으로 흙과 명도를 갈라야 한다. KR 놀이 풀보다 어둡게 칠해진 것과 같은 방향이다(관찰).
- [추론] 밤 덮개가 눈·림까지 같이 어둡게 누른다면 위 그림 쪽 대책이 무력해질 수 있다. 덮개 구현이 «곱하기 색조»인지, 발광 픽셀을 따로 남길 수 있는지는 코드 쪽 확인 거리다.

### Gaps
- 프로젝트 밤 덮개의 구현 방식(CanvasModulate류 곱하기인지, 눈 같은 발광 픽셀을 예외로 둘 수 있는지)은 이 조사에서 보지 않았다.
- 도트 TD에서 «밤 맵 + 어두운 털 적»을 다룬 구체 사례(그림 포함)는 찾지 못했다. 근거는 3D 게임(TF2·Darktide)과 일반 도트 튜토리얼이다.
- «빛나는 눈»의 가독성 효과를 다룬 권위 있는 설계 글은 찾지 못했다(플레이어 토론뿐).
