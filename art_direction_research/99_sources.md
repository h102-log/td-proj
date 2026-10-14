# 99. 출처와 검증 기록

확인 날짜는 모두 2026-10-14다. 조사는 deep-research 워크플로로 두 번 했다.

```
1차 (run wf_757ac36d-ca0) 레퍼런스 작품 → 01
검색   5갈래(a~e) 병렬 검색 → 출처 20개 수집
추출   주장 98개 → 검증 대상 25개(예산으로 8개 제외)
검증   주장마다 3표 반박 검증(반박 2표면 기각) → 확인 23 · 기각 2
종합   의미가 겹치는 주장을 합쳐 12개(R-01~R-12)

2차 (run wf_c4e59e02-35f) 시점·높이, 팔레트, 가독성 → 02~04
검색   5갈래 병렬 검색 → 출처 21개 수집
추출   주장 101개 → 검증 대상 25개(예산으로 9개 제외)
검증   같은 방식 → 확인 23 · 기각 2
종합   16개 → 주제별로 나눠 R-13~R-26
```

## 1. 주장 대장 (ID → 출처)

| ID | 작품 | 표결 | 성격 | 출처 |
|---|---|---|---|---|
| R-01 | 스타크래프트 1 | 3-0, 3-0, 3-0, 2-1 | 1차(블리자드 회고, 2017 리마스터 홍보기) | https://news.blizzard.com/en-us/starcraft/20719767 · https://news.blizzard.com/en-us/article/20726732/behind-the-scenes-of-starcraft-remastered · https://www.pcgamesn.com/starcraft-remastered/starcraft-design-retrospective-blizzard |
| R-02 | 디아블로 2 | 3-0, 3-0 | 1차(포스트모템 사본) | https://www.cs.hmc.edu/~markk/SWE_copies/postmortem__diablo_ii.html |
| R-03 | Age of Empires | 3-0, 3-0 | 1차(포스트모템) | https://www.gamedeveloper.com/game-platforms/the-game-developer-archives-postmortem-ensemble-s-age-of-empires- |
| R-04 | Dead Cells | 3-0, 3-0, 3-0 | 1차(아트 디렉터 글) + 포럼 | https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i- · https://steamcommunity.com/app/588650/discussions/0/1291817208492158139 |
| R-05 | Factorio | 3-0, 3-0 | 1차(공식 블로그, 2016) | https://factorio.com/blog/post/fff-146 |
| R-06 | three.js RenderPixelatedPass | 2-1, 3-0 | 1차(소스, dev 브랜치) | https://github.com/mrdoob/three.js/blob/dev/examples/jsm/postprocessing/RenderPixelatedPass.js |
| R-07 | The Last Spell | 3-0, 3-0, 3-0 | 1차(개발 블로그) | https://lastspell.com/?p=851 · https://lastspell.com/?p=1033 |
| R-08 | Kingdom | 3-0, 2-1 | 1차(인터뷰, 2014·2015) | https://cliqist.com/2014/05/19/thomas-van-den-berg-discusses-the-new-kingdom/ · https://80.lv/articles/kingdom-how-2-guys-created-a-side-scrolling-strategy/ |
| R-09 | Rise to Ruins | 3-0 | 공식(상점 문구) + 2차 | https://store.steampowered.com/app/328080/Rise_to_Ruins · https://en.wikipedia.org/wiki/Rise_to_Ruins |
| R-10 | They Are Billions | 2-1, 3-0 | 공식(발표 글) | https://numantiangames.com/News/2017-05-31-new-game-they-are-billions/ |
| R-11 | 공통 교훈 | 종합 | **추론** — 개별 사례는 검증됐고 묶은 판단은 검증 대상이 아니다 | R-01, R-03, R-04, R-05, R-06, R-07 |
| R-12 | 상위 레퍼런스 선정 | 종합 | **추론** | R-01~R-08 |
| R-13 | Factorio 45도 dimetric | 3-0, 3-0 | 1차(개발 블로그 FFF-133, 2016) + 포럼 | https://www.factorio.com/blog/post/fff-133 · https://forums.factorio.com/viewtopic.php?p=473901 |
| R-14 | 각도별 높이·깊이 배율, 가림 방향 | 종합 | **추론** — 정사영 기하 계산. 사례 출처 없음 | R-13, `SPEC.md:112`(S51) |
| R-15 | 젤다 ALBW 물체 기울이기 | 3-0, 3-0 | 2차 기사(Iwata Asks 4부와 대조) | https://gameinformer.com/b/news/archive/2013/11/20/the-trick-behind-the-legend-of-zelda-a-link-between-worlds-top-down-view |
| R-16 | Pillow quantize와 디더 옵션 | 3-0, 3-0 | 1차(공식 문서 12.3.0) | https://pillow.readthedocs.io/en/stable/reference/Image.html |
| R-17 | 디더링 방식별 대가 | 3-0 ×4 | 기술 블로그·개인 블로그 | https://surma.dev/things/ditherpunk/ · https://hackaday.io/project/19731-polapi-zero/log/59139-pillow-tweaking-ordered-dithering |
| R-18 | Fantasy 24 팔레트 | 3-0, 3-0 | 1차(Lospec 페이지·JSON) | https://lospec.com/palette-list/fantasy-24 · https://lospec.com/palette-list/fantasy-24.json |
| R-19 | Waldgeist, Lospec dark 태그 순위 | 3-0 | 1차(Lospec) | https://lospec.com/palette-list/tag/dark · https://lospec.com/palette-list/waldgeist |
| R-20 | Slynyrd 색 램프 제작법 | 3-0 | 블로그(저자 본인, 단일 출처, low) | https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes |
| R-21 | Godot CanvasModulate·노멀맵 조명 | 3-0, 3-0 | 1차(공식 문서 4.2, 4.7판에 같은 문장) | https://docs.godotengine.org/en/4.2/tutorials/2d/2d_lights_and_shadows.html |
| R-22 | Graveyard Keeper LUT 그레이딩 | 3-0 | 개발자 기술 글(같은 글의 두 판본) | https://slava.lazybeargames.com/graveyard-keeper-how-the-graphics-effects-are-made |
| R-23 | 외곽선 원칙, The Last Spell 외곽선 변경 이유 | 3-0 ×3 | 블로그 튜토리얼 + 1차(개발 블로그) | https://lospec.com/articles/pixel-art-outlines-part-2-using-color · https://lastspell.com/?p=851 |
| R-24 | SC2 팀 색 과다 | 3-0, 2-1 | 2차(커뮤니티 매니저 전달의 재전달) | https://www.gosugamers.net/news/7571-graphic-change-in-the-works-for-starcraft-ii |
| R-25 | Zach Gage Subway Legibility | 3-0 | 발표 원고 + 2차 요약 | http://stfj.net/DesigningForSubwayLegibility/ · https://gigazine.net/gsc_news/en/20180501-game-design-subway-legibility |
| R-26 | 시험 설정값 후보표의 권장안 | 종합 | **추론** | R-13~R-25 |

표결 메모:
- **R-01:** 원래 주장은 "처음 렌더한 골리앗이 납작해 보였다"였다. 원문은 "가늘게 뭉개졌다"는 뜻이라 고쳤다.
- **R-06:** 2-1 반대표는 '정수배' 표현의 뉘앙스에 관한 것이었다.
- **R-08:** '다크 판타지' 표현이 출처를 넘어서 2-1이 됐다. 본문에서는 그 표현을 뺐다.
- **R-10:** '도트' 조건에 맞지 않아 2-1이 됐다.
- **R-13:** 포럼의 38도는 측정자가 철회했고, 53도는 출처가 없어 쓰지 않았다.
- **R-16:** ORDERED를 넘기면 FS로 동작한다는 부분은 소스를 읽은 추론이다. 검증자가 실행해 확인한 것은 최근접 일치율 97.1%(무작위 16색 팔레트, 4096색)다.
- **R-18:** 색조 분포(따뜻한 색 19, 초록 2, 청록 3, 파랑·보라 0, 채도 최솟값 0.27)는 2026-10-14에 colorsys로 다시 계산해 일치를 확인했다.
- **R-24:** Sam Didier의 말을 Karune이 공식 포럼에 옮긴 것을 다시 전한 기사다. Battle.net 원문은 찾지 못했다.

## 2. 가져왔지만 검증된 주장이 없는 출처

| URL | 성격 | 갈래 |
|---|---|---|
| https://en.wikipedia.org/wiki/Pre-rendering | 2차 | a |
| https://steamcommunity.com/app/625960/discussions/0/4298195716594538602 | 포럼 | b |
| https://www.pcgamesn.com/thronefall/steam-full-launch | 2차 | c |
| https://en.wikipedia.org/wiki/Stronghold_(series) | 2차 | c |
| https://forums.factorio.com/viewtopic.php?p=473901 | 포럼 | d |
| https://warcraft.wiki.gg/wiki/Warcraft_2 | 2차 | d |
| https://godotshaders.com/shader/3d-pixel-art-outline-highlight-post-processing-shader/ | 블로그 | e |
| https://forum.godotengine.org/t/how-to-y-sort-player-with-3-4-view-tilemaplayer/83392 | 포럼 | 2차 주제 1 |
| https://opengameart.org/node/20643 | 포럼 | 2차 주제 2 |
| https://alexandertanasie.artstation.com/projects/w6qVqL | 블로그 | 2차 주제 3 |
| https://gamedeveloper.com/game-platforms/road-to-the-igf-subset-games-i-into-the-breach-i- | 1차(인터뷰) | 2차 주제 3 |
| https://www.chapterbrief.net/blog/tyrant-of-the-tower-defense-game-review | 블로그(웹툰 리뷰, 2026-08-31) | 2차 웹툰 |
| https://www.inews24.com/view/1993322 | 2차(게임화 기사, 2026-08-10) | 2차 웹툰 |

### 원작 웹툰 — 뽑았지만 검증하지 못한 주장 (미검증, 인용 금지)

아래는 2차 조사에서 출처를 읽고 뽑은 주장이다. 검증 예산(9개 제외)에 밀려 반박 검증을 거치지 않았다. 사실로 인용하지 않고, 사용자가 대표 컷을 고르거나 재조사할 때 단서로만 쓴다.

- ChapterBrief(무료 1~3화만 본 리뷰): 작화는 «clean, full-color digital linework with a strong sense of lighting». 1화 축하 장면은 모니터 빛 하나로 «blue-white wash». 분위기는 «slower and heavier». 다크 판타지라고 부르지는 않는다. 표지 alt 텍스트는 «besieged castle» 앞의 «gold-trimmed red military coat». 성벽 공방 장면 묘사는 없다.
- 아이뉴스24: 웹젠이 같은 원작의 공식 게임 «프로젝트D1»을 만든다. 원작 속 게임 세계가 도트 그래픽이라는 설정을 살려 «3D그래픽 배경에 도트그래픽 더한 '디오라마 픽셀아트'»를 쓴다. 장르는 «지휘 전략 RPG»다. 색감·시점 서술은 없다.
- 검색 결과 요약에만 나온 것(본문 미확인): 웹툰가이드 후속 기사(2026-09-02)가 정식 명칭을 «라스트 스테이지»로, 그래픽을 «언리얼엔진5 기반 3D 입체 그래픽 배경 위에 픽셀 단위의 도트 그래픽 캐릭터»로 보도했다. 나무위키·커뮤니티는 원작 정서를 «무너지는 것이 전제인 괴수 전선», «다크한 배경»으로 적었다.

## 3. 기각된 주장

| 표결 | 주장 | 출처 |
|---|---|---|
| 0-3 | Rise to Ruins의 방어 구조는 미로 벽 뒤에 타워를 줄지어 세운 '타워의 벽'이다 | https://store.steampowered.com/app/328080/Rise_to_Ruins |
| 1-2 | Never's End(Hypersect)는 실시간 3D 렌더에 도트 후처리를 더해 손 도트처럼 보이게 한다(GDC 2026 슬라이드) | https://www.ryanjuckett.com/how-we-draw-a-3d-sprite-world-gdc2026/ |
| 0-3 | (2차) Gage의 Three Reads는 정보를 세 층(직관적 정보 / 직관적이지 않지만 중요한 정보 / 나머지 세부)으로 나눈다. 적·아군 화면이면 1층 피아·적 종류, 2층 선택 유닛·건물 상태, 3층 버프 수치로 옮긴다 | https://gigazine.net/gsc_news/en/20180501-game-design-subway-legibility |
| 1-2 | (2차) Slynyrd 램프 안 규칙: 명도는 0에서 시작하지 않고 계속 오른다. 채도는 가운데가 가장 높고 0·100에 닿지 않는다. 채도와 명도를 함께 높게 잡는 것이 가장 큰 실수다 | https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes |

## 4. 미해결 질문

1. 스타크래프트 1과 Factorio의 실제 카메라 고도각과 타일 픽셀 크기는 얼마인가? Factorio는 정사각 격자를 비스듬히 내려다보는 시점이라 갈래 d에 가장 가까울 수 있다. 하지만 이번 출처에는 그 내용이 없다.
2. 정사각 격자 3/4 탑다운 시점의 다크 판타지 도트 게임은 무엇인가? 특히 몬스터가 성벽을 기어오르는 장면이나 비행 몬스터가 있는 작품은?
3. 16~32px에서 3D를 직접 래스터화하고 제한 팔레트로 양자화하면 손 보정 없이 형태가 읽히는가? 외곽선은 검정이 나은가, 컬러가 나은가?
4. 디아블로 1과, 3D를 도트로 렌더하는 다른 현대 인디 사례는 무엇인가?
5. (2차) 원작 웹툰의 성벽 공방 장면은 어떤 색감인가? 주조색, 밤·낮 장면 비율, 피·불빛 강조 정도가 없다. 사용자가 고른 대표 컷이나 재조사로 팔레트 판정 기준을 세워야 한다.
6. (2차) 정사각 격자 비스듬한 시점의 2D 게임은 성벽 위 유닛, 기어오르는 적, 성벽을 넘는 비행 적을 어떻게 그렸나? 건설 중·깎임·잔해·성문 개폐·버프 표시는 작은 화면에서 어떻게 읽히게 했나?
7. (2차) Godot 4.7에서 성벽 앞·위·뒤 유닛과 비행 유닛의 그리기 순서를 y_sort_enabled·z_index·TileMapLayer로 어떻게 나누나? 공식 문서로 확인해야 한다.
8. (2차) 16~32px 렌더 스프라이트에서 디더링 없음과 Bayer, 8방향과 16방향, 45도와 60도 중 무엇이 나은가? 외부 근거가 없어 10/21 시험에서 나란히 렌더해 판정한다.
