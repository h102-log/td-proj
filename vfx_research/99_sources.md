# 99. 출처와 방법

[README](README.md)로 돌아가기.

---

## 1. 만든 방법

조사일 2026-10-27. 네 단계로 만들었다.

### 1.1 deep-research 워크플로

| 항목 | 값 |
|---|---|
| 조사 갈래 | 5개: 참고 게임 사례, 도트 이펙트 제작 원칙, 장판·상태이상·위계, 코드 도트 이펙트(Godot), 무료 에셋 |
| 에이전트 | 101개 |
| 웹 검색 | 125회 |
| 가져온 출처 | 19개 |
| 뽑은 주장 | 94개. 이 가운데 25개를 검증했다(나머지는 예산에서 빠짐) |
| 검증 | 주장마다 3표(반박 2표면 기각). 확인 21, 기각 4 |

- 빈 곳: 1번 갈래(게임별 사례)와 2번 갈래(Saint11·Slynyrd 수치)는 출처를 가져오고 주장도 뽑았지만, 검증 예산 25개 안에 들지 못했다.

### 1.2 정리 단계에서 원문 직접 대조

예산에서 빠진 주장 가운데 1차 자료를 원문과 직접 맞췄다(이 폴더의 **대조**).
- Saint11 GIF 3장(S07~S09): 받아서 프레임을 뽑고, 그림 속 글을 읽고, 색을 셌다.
- 원문을 받아 인용문을 찾았다: Slynyrd 3편(S10~S12), Wargroove·Crawl 인터뷰(S13·S14), Riot VFX 업데이트 글(S05), ARPG 가독성 글(S06), 셰이더 3개(S16~S18), PICO-8 폭발 글(S20).
- 12개 모두 인용이 원문과 맞았다.

### 1.3 보충 조사 에이전트 둘

| 갈래 | 맡은 것 | 웹 검색 | 원본 메모 |
|---|---|---|---|
| A 코드 게임 | Mindustry·Arc·SPD 소스를 커밋 고정으로 받아 읽음 | 0 | [evidence/A_procedural.md](evidence/A_procedural.md) |
| B 스프라이트 게임 | StarCraft 원본 GRP·iscript 디코드, ITB·FFT·KR·Wargroove·HLD·HoT·VS 그림·스크린샷 측정 | 3 | [evidence/B_sprite_games.md](evidence/B_sprite_games.md) |

- 두 메모의 핵심 주장은 정리 단계에서 다시 확인했다.
  - A: `blastExplosion` 코드, `effectChance = 0.15`, `Drawf.circles`의 3px 회색 밑칠
  - B: Psionic Storm GRP를 따로 짠 디코더로 풀어 14프레임·색 인덱스 6개·최대 채움률 0.11
- B는 Spriters Resource·Fandom이 curl을 막아서 Claude in Chrome으로 열었다. Liquipedia는 둘 다 막혀(429) 쓰지 못했다.
- 남의 그림(SPD 아틀라스, SC 립, 게임 스크린샷, 합성 장면)은 세션 스크래치에서만 보고 저장소에 넣지 않았다.

### 1.4 우리 게임 실행 확인

- 2026-10-27, HEAD `adfd288`, 창 1280×720, 카메라 기본 줌. 일회성 스크립트(스크래치)로 영웅을 영입하고 전투에 들어가 이그니스 Q·W·E·R을 쓰고 찍었다. 그 가운데 블랙홀 그림 두 장을 넣었다: [img/now_ignis_e.png](img/now_ignis_e.png), [img/now_ignis_e_crop3x.png](img/now_ignis_e_crop3x.png).
- 같은 폴더에 다른 세션의 미커밋 변경(SPEC·EVAL·평가 파일)이 있었다. `src/`·`data/`·`art/`는 깨끗해서 화면은 HEAD 코드 그대로다.

### 1.5 이 세션의 웹 검색 합계

워크플로 125회 + 보충 3회 = **128회**.

## 2. 검증 표시

| 표시 | 뜻 |
|---|---|
| **3표** | 워크플로 검증에서 3표로 확인 |
| **대조** | 정리 단계에서 원문·원본 파일을 직접 열어 맞춤 |
| **소스 확인** | 보충 에이전트가 코드 줄·원본 파일로 확인(핵심만 다시 대조) |
| (추론) | 우리가 끌어낸 것. 사실이 아니다 |

## 3. 출처 목록

| ID | 출처 | 종류 | 검증 | URL |
|---|---|---|---|---|
| S01 | Riot, «Clarity in League» (bananaband1t, 2021-03-12) | 1차 | 3표 | https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/ |
| S02 | Riot Beardilocks, «Anatomy of a League of Legends missile — Part 2» (RealtimeVFX, 2020-05-25) | 1차 | 3표 | https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062 |
| S03 | LoL VFX Style Guide (2017, PDF 37쪽). 원래 주소는 리다이렉트된다 | 1차 | 3표(검증자가 PDF 6~7쪽 확인) | https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/ |
| S04 | VFX Apprentice, «10 League of Legends VFX Design Tips» | 2차(S03 요약) | 3표 | https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips |
| S05 | Riot, «Behind the Scenes of VFX Updates» | 1차 | 대조 | https://www.leagueoflegends.com/en-au/news/dev/dev-behind-the-scenes-of-vfx-updates/ |
| S06 | Game Developer, «Designing for Difficulty: Readability in ARPGs» | 블로그 | 대조 | https://www.gamedeveloper.com/game-platforms/designing-for-difficulty-readability-in-arpgs |
| S07 | Pedro Medeiros(Saint11), «Explosions Part 1» GIF | 1차(아티스트) | 대조(프레임·색 측정) | https://saint11.art/img/pixel-tutorials/Explosion.gif |
| S08 | Saint11, «Impact» GIF | 1차 | 대조 | https://saint11.art/img/pixel-tutorials/Impact-export.gif |
| S09 | Saint11, «Motion Blur» GIF | 1차 | 대조 | https://saint11.art/img/pixel-tutorials/MotionBlur.gif |
| S10 | Slynyrd, «Pixelblog 31: Shmup Design Part 1» (2020-12-14) | 1차(아티스트) | 대조 | https://www.slynyrd.com/blog/2020/12/14/pixelblog-31-shmup-sprite-design |
| S11 | Slynyrd, «Pixelblog 1: Color Palettes» (2018-01-10) | 1차 | 대조 | https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes |
| S12 | Slynyrd, «Pixelblog 9: Melee Attacks» (2018-09-08) | 1차 | 대조 | https://www.slynyrd.com/blog/2018/9/8/pixelblog-9-melee-attacks |
| S13 | Game Developer, Wargroove 인터뷰(Chucklefish) | 인터뷰 | 대조 | https://gamedeveloper.com/design/an-inside-look-at-i-wargroove-s-i-wicked-design-choices |
| S14 | Game Developer, «Creating the striking pixel art of Crawl» | 개발자 글 | 대조 | https://www.gamedeveloper.com/design/game-design-deep-dive-creating-the-striking-pixel-art-of-i-crawl-i- |
| S15 | Godot 문서, «Custom drawing in 2D» | 1차 | 3표·대조 | https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html |
| S16 | godotshaders, «Double Dither» (CC0) | 코드 | 대조 | https://godotshaders.com/shader/double-dither-stylized-transparency-shadows-retro-masks/ |
| S17 | godotshaders, «Arbitrary Color Reduction and Palette Ordered Dithering» (MIT) | 코드 | 대조 | https://godotshaders.com/shader/arbitrary-color-reduction-ordered-dithering/ |
| S18 | godotshaders, «Simple Pixelated Fire shader» (MIT) | 코드 | 대조 | https://godotshaders.com/shader/simple-pixelated-fireshader/ |
| S19 | GodotCon Amsterdam 2026, «Procedural Pixel Art: Retro VFX with Shaders» (Julian Rogawski) | 1차(초록만) | 3표 | https://talks.godotengine.org/godotcon-ams-2026/talk/NSNXFT/ |
| S20 | Natureba devlog, «How to create a blow up effect with Pico-8» | 블로그 | 대조 | https://lucasmncastro.itch.io/natureba/devlog/722044/how-to-create-a-blow-up-effect-with-pico-8 |
| S21 | Foozle, «Pixel Magic Sprite Effects» (CC0) | 배포 페이지 | 3표 | https://foozlecc.itch.io/pixel-magic-sprite-effects |
| S22 | DevWizard, «Pixel Art Spells» (CC0) | 배포 페이지 | 3표 | https://opengameart.org/content/pixel-art-spells |
| S23 | nerijs, «PVFX Foundry» (CC0) | 배포 페이지 | 3표 | https://nerijs.itch.io/pvfx-foundry |
| S24 | ansimuz, «Gothicvania Magic Pack 9» (CC0) | 배포 페이지 | 3표 | https://opengameart.org/content/gothicvania-magic-pack-9 |
| S25 | CodeManu, «Free Pixel Effects Pack» (라이선스 표기 어긋남) | 배포 페이지 | 3표 | https://codemanu.itch.io/pixelart-effect-pack |
| S26 | BDragon1727, «Free Effect and Bullet 16x16» (상업은 기부 조건) | 배포 페이지 | 3표 | https://bdragon1727.itch.io/free-effect-and-bullet-16x16 |

보충 조사의 출처(코드 줄 permalink, 원본 파일)는 각 메모 끝에 있다. 주요한 것은 다음과 같다.

| 무엇 | 출처 |
|---|---|
| Mindustry 소스 `b873c01e` | https://github.com/Anuken/Mindustry |
| Arc 소스 `7445105c` | https://github.com/Anuken/Arc |
| Shattered Pixel Dungeon 소스 `57a4e06a` | https://github.com/00-Evan/shattered-pixel-dungeon |
| StarCraft GRP·팔레트 | https://www.npmjs.com/package/@dada78641/bwmapgfx |
| StarCraft images.dat·iscript.bin | https://github.com/Buizz/EUD-Editor-3 |
| StarCraft 합성 방식 | https://github.com/openbw/openbw/blob/master/ui/ui.h |
| StarCraft remap 이름 | https://github.com/poiuyqwert/PyMS/blob/master/PyMS/Data/Remapping.txt |
| Into the Breach 위키(상태·타일) | https://intothebreach.fandom.com/wiki/Status_Effects · https://intothebreach.fandom.com/wiki/Tiles |
| Kingdom Rush 위키(상태) | https://kingdomrushtd.fandom.com/wiki/Afflictions |
| 스팀 스크린샷(store appdetails) | ITB 590380, KR 246420·458710·816340·1367550, Wargroove 607050, HLD 257850, HoT 2218750, VS 1794680 |

## 4. 기각·미확인

- 워크플로에서 기각된 주장 넷
  - Foozle 팩이 32×32 10종이라는 크기 주장
  - Gothicvania 팩이 약 64×64·6~12프레임이라는 주장
  - DevWizard 팩이 흑백으로 그려 엔진에서 칠하도록 의도됐다는 주장
  - BDragon1727 팩을 «수정 자유»라서 다시 칠해 써도 된다는 해석
- 추출만 되고 쓰지 않은 것(원문 미대조)
  - Valve GDC 2008 TF2 «Stylization with a Purpose»
  - GDC «Visual Effects Bootcamp»(Riot·Blizzard)
  - Path of Exile 포럼 «Visual Clarity»
  - HLD 스팀 토론(480×270·발광)
  - HoT 스팀 토론(불투명도 슬라이더)
  - HLD 480×270은 보충 B가 스크린샷으로 따로 쟀다.
- 확인 못 한 것
  - 게임별 실제 재생 길이: ITB 타일 애니메이션, FFT 프레임 구성, KR 상태 프레임
  - SC 오버레이 일부의 픽셀 크기: Stasis·Matrix·Irradiate·Maelstrom
  - 무료 팩 zip 안의 실제 그림·라이선스 파일
  - GodotCon 발표의 실제 내용(녹화·슬라이드)
