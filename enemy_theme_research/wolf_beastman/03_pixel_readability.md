# 24px에서는 귀 두 점과 명도 한 칸이 종족을 가른다

작은 늑대·하이에나 수인 사례는 공통으로 **머리 위 귀 두 점, 앞으로 나온 주둥이, 밝은 주둥이·가슴과 어두운 등, 목 갈기 톱니**를 겹쳐 쓴다. 45° 위 카메라에서는 귀만 네 방향 모두에 남는다. 코볼트와는 질감·머리 장식·꼬리·색온도·자세·장비 여섯 축을 함께 갈라야 한다. 밤에는 색보다 명도가 남는데, 지금 늑대와 도약 늑대는 명도가 같다. 원 노트: [evidence/pixel_readability.md](evidence/pixel_readability.md). 표기 **[관찰]**은 조사자가 브라우저로 그림을 직접 보고 적은 것이다.

## 작은 사례들은 넷 중 둘 이상을 겹친다

[사실·관찰] Shattered Pixel Dungeon의 놀 스프라이트는 한 칸이 12×15px다 ([GnollSprite.java](https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/master/core/src/main/java/com/shatteredpixel/shatteredpixeldungeon/sprites/GnollSprite.java)). 머리 위에 1~2px 뾰족 귀 둘이 서고, 주둥이가 옆으로 2~3px 나오며, 가슴·배가 밝다. 변종은 털색과 소지품으로 가른다. 통 투구를 쓴 brute는 귀가 가려지고 투구 자체가 표식이 된다 ([gnoll.png](https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/core/src/main/assets/sprites/gnoll.png), [brute.png](https://github.com/00-Evan/shattered-pixel-dungeon/blob/master/core/src/main/assets/sprites/brute.png), [actors.properties](https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/master/core/src/main/assets/messages/actors/actors.properties)).

[사실·관찰] Dungeon Crawl Stone Soup은 글로는 놀과 코볼트를 둘 다 «개 같은» 종족으로 쓴다 ([monsters.txt](https://raw.githubusercontent.com/crawl/crawl/master/crawl-ref/source/dat/descript/monsters.txt)). 그림은 확실히 갈랐다. 놀은 겨자색 털·짙은 갈기·직립·넓은 어깨, 코볼트는 매끈한 잿빛 청록 피부·작은 뿔·가는 꼬리·숙인 자세다 ([gnoll.png](https://github.com/crawl/crawl/blob/master/crawl-ref/source/rltiles/mon/humanoids/gnoll.png), [kobold.png](https://github.com/crawl/crawl/blob/master/crawl-ref/source/rltiles/mon/humanoids/kobold.png)).

[관찰] Kingdom Rush 도감 그림의 Werewolf는 짙은 청회색 털, 밝은 회색 주둥이·배, 노랗게 빛나는 눈, 크게 선 귀를 가졌다. Lycan은 붉은 눈이다 ([EnemySqr_Werewolf](https://kingdomrushtd.fandom.com/wiki/File:EnemySqr_Werewolf.PNG), [EnemySqr_LycanSM](https://kingdomrushtd.fandom.com/wiki/File:EnemySqr_LycanSM.png)). 갑옷 입은 Gnoll Gnawer도 머리는 맨머리로 큰 갈기를 드러낸다 ([KRO_EnemyBox_Gnoll_Gnawer](https://kingdomrushtd.fandom.com/wiki/File:KRO_EnemyBox_Gnoll_Gnawer.png)).

[추론] 사례 가운데 귀·주둥이·갈기·꼬리 중 하나만 쓴 것은 없었다. 24px이면 SPD의 두 배쯤이라 귀 2~3px, 주둥이 3~4px가 잡힌다. 최소 «선 귀 + 목 갈기» 둘은 겹친다.

## 머리 위 두 점은 방향으로 가른다

[추론] 45° 위 카메라라 머리 꼭대기는 S·E·N·W 모두에서 보인다. 귀는 네 방향 공통 단서가 될 수 있는 유일한 머리 부위다. 주둥이는 N에서 사라지고 E·W에서 가장 세다. 그런데 td-proj 적은 이미 머리 위에 두 점을 셋이나 쓴다.

| 적 | 머리 위 두 점 | 근거 |
|---|---|---|
| 고블린 | 옆으로 뻗은 뾰족 귀, 잿빛 피부 | `tools/art/goblin.py:41` |
| 코볼트 | 뒤로 뻗은 뿔, 붉은 비늘 | `tools/art/kobold.py:44` |
| 오크 | 투구에서 바깥 위로 벌어진 뿔, 끝이 크림(`efd8a1`) | `tools/art/orc.py:16`, `:42` |
| 늑대 수인(제안) | **머리 폭 안에서 곧게 선** 삼각 귀, 털색, 안쪽 1px 밝은 색 | [추론] |

[추론] 귀는 높이 2~3px, 두 귀 사이 1px 이상을 비운다. 뒤로 누우면 N에서 코볼트 뿔과, 바깥으로 벌어지면 오크 뿔과 겹친다.

[추론] 뒷모습(N) 단서 순서: ① 귀 두 점 ② 목·어깨 갈기 톱니(밝은 털이면 어두운 등과 명암차) ③ 굵고 끝이 밝은 꼬리(지금 네발 늑대도 꼬리 끝을 `pale` 재질로 밝게 칠함, `tools/art/wolf.py:131-134`) ④ 등에 멘 무기·망토. 넷 중 둘 이상이 N 그림에 남아야 한다. 꼬리를 다리 사이에 두면 걷기 2위상에서 다리와 뭉치므로 조금 옆으로 뺀다. 4방향을 다 굽고 반전은 쓰지 않으니(`wolf.py:3`) 좌우 비대칭이 된다.

[사실] Fatshark는 플레이어 시선이 머리·어깨에 몰려 그 부분이 차이 인식에 가장 크게 작용했다고 했다. 등에 붙인 덧붙임은 앞·옆 실루엣을 다 바꾼다 ([Darktide 101: Enemy Character Art](https://devtrackers.gg/darktide/p/67a2496a-darktide-101-enemy-character-art-dev-blog)).

## 코볼트와는 여섯 축을 함께 가른다

[사실] D&D 코볼트는 «개 닮은» 주둥이와 비늘·뿔이 섞인 존재였고, 3판에서 도마뱀으로 정리됐다. 일본 쪽 코볼트는 개가 됐다 ([Mythoi: Kobolds](https://mythoi.substack.com/p/kobolds-fairy-lizard-dog)). 이름부터 섞이기 쉬운 짝이다.

| 축 | 늑대 수인(제안) [추론] | 코볼트(현행) [사실] |
|---|---|---|
| 머리 장식 | 곧게 선 삼각 귀 | 뒤로 누운 뿔 (`kobold.py:44`) |
| 목·어깨 | 밝은 털 갈기 톱니 1~2px | 매끈한 캡슐 |
| 꼬리 | 굵고 끝이 밝음, 아래로 늘어짐 | 허리에서 뒤아래로 가늘어지는 캡슐 (`kobold.py:40`) |
| 색온도 | 회갈·모래·검정, 몸 큰 면적에 빨강 없음 | 채도 높은 빨강 `300f0a` `550f0a` `9b1a0a` `ef692f` (`kobold.py:12`) |
| 체급·자세 | 1.0배 이상, 고블린(12°)보다 얕게 숙임 | 0.85배, 16° 숙임, 두 팔을 앞으로 든다 (`kobold.py:18-21`) |
| 손 | 무기 + 흉갑 | 맨손 발톱, 공격은 두 팔 할퀴기 (`kobold.py:24-25`) |
| 눈 | 늑대·도약 `151a26`, 밤 `efd8a1`, 알파 `ef3a0c` | `efac28` (`kobold.py:14`) |

[사실] 2라운드 웨이브에는 늑대 4종만 나오고 코볼트 등 기존 5종은 3~6라운드에 나온다(`insights/2026-10-27_round2_wolf.md:54`, `data/waves/round_2.tres`만 늑대를 씀). 한 화면에서 겹칠 일은 적다. [추론] 그래도 플레이어는 라운드를 넘어 적 꼴로 규칙을 배운다. 코볼트와 도약 늑대는 둘 다 성벽에 오르는 적이라 꼴이 닮으면 규칙도 같다고 오해한다(기어오름 S107 대 뛰어오름+밀치기).

## 명도: 늑대와 도약 늑대가 붙어 있다

[계산] Rec.601 명도 Y. 음영 넷 평균(외곽선 제외). 현행은 `tools/art/wolf.py:23-30`.

| 대상 | 현행 램프 → 평균 | 제안 램프 → 평균 |
|---|---|---|
| 밤 늑대 털 | `151a26` `262d3d` `3a4357` `3a4357` → 51 | `151a26` `262d3d` `3a4357` `56607a` → 58 |
| 알파 털 | `262d3d` `3a4357` `56607a` `56607a` → 76 | `392a1c` `392a1c` `684c3c` `927e6a` → 76 |
| 늑대 털 | `392a1c` `684c3c` `927e6a` `927e6a` → 97 | 그대로 → 97 |
| 도약 늑대 털 | `724113` `a56243` `ab5c1c` `ab5c1c` → 101 | `724113` `a56243` `efb775` `efb775` → 143 |
| 알파 갈기 | `a4aec2` `d0d6e0` `d0d6e0` `d0d6e0` → 203 | 그대로 → 203 |
| 바닥 | 풀 `2d472d` 60 · `39571c` 71, 흙 `684c3c` 83 | — |
| 비교 | 코볼트 비늘 평균 75, 고블린 피부 `3a4357`~`a4aec2` 67~173, 오크 피부 `684c3c` `927e6a` 83·130 | — |

[추론] 제안은 «밤 < 알파 털 < 늑대 < 도약 < 알파 갈기» 사다리를 만든다. 알파 털 평균은 그대로지만 차가운 잿빛에서 따뜻한 회갈로 옮겨, 차가운 회색인 철판·고블린 피부와 색상으로 갈린다. 철판은 털보다 어두운 `151a26` `262d3d` `3a4357` 쪽으로 두면 «어두운 철 · 중간 털 · 밝은 갈기» 세 칸이 된다.

[추론] 늑대 털의 중간 칸 `684c3c`는 흙 타일과 같은 값이다. 털을 바꾸기보다 밝은 주둥이·가슴·목 갈기(`a4aec2` `d0d6e0`) 면적으로 흙과 가른다. KR 놀이 풀보다 어둡게, 밝은 배를 달고 칠해진 것과 같은 방향이다[관찰].

[추론] 밤 늑대 털의 맨 위 칸을 `3a4357`(67)에서 `56607a`(96)로 올리는 까닭은 낮의 풀(71)이다. 3웨이브에서 밤 늑대가 처음 나올 때는 낮이다(`insights/2026-10-27_round2_wolf.md:131`). 맨 위 칸이 풀보다 밝아야 윗면 테가 남는다.

## 밤에는 숨고, 불빛 안에서만 그림이 일한다

[사실] 어둠 속 불빛 밖 적은 몸·체력 막대·효과 테두리를 그리지 않는다(S213, `tests/eval/test_night.py` EV441). 예외가 둘이다. 숨은 밤 늑대는 눈빛 두 점(`f0e060`, 2px 간격)을 그린다(S240·I193 ④, `src/ui/battle_view.gd:23`, `:425-428`). 알파의 덮치기 예고는 숨어도 그린다(`battle_view.gd:295-298`, EV585). 덮개는 `0b1030` 색을 어둠 × 0.85 비율로 섞고, 불빛 가장자리는 4×4 디더로 풀린다(`battle_view.gd:181`, `:204-210`).

[추론] 그래서 스프라이트 그림이 밤에 일하는 곳은 **불빛 안과 그 가장자리**뿐이다. 어둠 1의 불빛 밖에서는 밤 늑대도 몸이 아니라 점 둘이다. 낮 그림의 눈(`efd8a1`, 명도 217)과 밤 점(`f0e060`, 214)은 명도가 같아 «낮에 본 눈 = 밤에 본 점»이 이어진다.

[사실] Valve는 TF2에서 실루엣을 검은 외곽선 대신 림 하이라이트로 세웠고, 광원에서 먼 캐릭터용 림 항을 **위를 향한 면에만** 넣었다 ([TF2 NPAR 2007](https://cdn.cloudflare.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf)). Lospec은 외곽선이 물체와 배경 둘 다보다 어두워야 하고 어두운 배경에선 결국 검정만 통했다고 한다 ([Lospec Outlines Part 2](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)). Saint11은 어두운 그림에서 강한 광점과 림·백라이트를 먼저 세우라고 한다 ([Darkness.gif](https://saint11.art/img/pixel-tutorials/Darkness.gif)).

[추론] 45° 위 카메라에는 TF2의 «윗면 림»이 그대로 맞는다. 머리 꼭대기·귀 끝·어깨·갈기 윗면이 램프 최상단이 되게 광원을 위에 두면, 불빛 가장자리에서도 귀와 갈기가 남는다.

## 3D 형체로 굽을 때의 메모

[사실] 사람형 공용 뼈대 `rig()`의 다리는 엉덩이 → 무릎 → 발목 두 마디(각 0.19)에 발 타원 하나다(`tools/art/hero.py:66-70`). 몸 크기는 `scaled()`가 발밑 기준으로 키운다(`hero.py:93`). 치마·망토 자락은 `flare()`가 있다(`hero.py:98`, 하피 깃털 자락이 씀 `harpy.py:42`).

[추론] 도약 늑대의 «긴 다리»는 마디를 늘리지 않아도 무릎을 깊게 굽힌 자세 + 길게 세운 발 캡슐로 흉내 낼 수 있다. 밤 늑대 망토는 `flare()`로 만든다. 갈기는 imonk 튜토리얼처럼 가닥 대신 목둘레의 작은 원뿔·납작 타원 몇 개로 «톱니»를 낸다 ([Pixel Tutorial – Fur](https://itch.io/post/6047047)). 네발 알파 때 «갈기가 어깨·등까지 덮으면 안장 무늬처럼 읽혔다»는 메모(`wolf.py:107`)도 같은 방향이다. 목·어깨에서 멈춘다.

[추론] 확인은 화면으로 한다. 단색 실루엣 4방향을 코볼트·고블린·오크 옆에 나란히 굽고, 회색조와 실제 크기로 본다. TF2의 «음영 없는 실루엣 검증», 현업 블로그의 «흑백으로 바꿔도 갈리나» ([bugnet: readable game art](https://bugnet.io/blog/readable-game-art-why-clarity-beats-detail))와 «확대본 말고 실제 크기로» ([bugnet: reads clearly](https://bugnet.io/blog/how-to-make-pixel-art-that-reads-clearly), 검색 요약)다. 프로젝트 `preview()`가 이미 위 줄에 비교 대상을 둔다(`kobold.py:60-63`).

## 빈 곳

- 늑대 수인·놀의 **뒷모습(N) 소형 스프라이트** 사례는 찾지 못했다. N 단서 순서는 추론이다.
- 투구 위로 귀를 낸 소형 도트 사례도 찾지 못했다.
- Kingdom Rush 적의 게임 속 실제 픽셀 높이는 모른다. 본 것은 도감 확대 그림이다.
- 도트 TD에서 «밤 맵 + 어두운 털 적»을 다룬 사례는 못 찾았다. 근거는 3D 게임(TF2·Darktide)과 일반 튜토리얼이다.
- 위 명도 사다리는 계산이다. 4단 음영 굽기에서 각 칸이 차지하는 면적은 굽어 봐야 안다.
