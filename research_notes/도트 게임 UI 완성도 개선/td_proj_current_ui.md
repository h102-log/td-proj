# td-proj 현재 UI 감사 — 도트 UI 완성도 개선 가이드용 근거 (2026-11-15)

- 범위: 코드·설정·자산, 그리고 저장소에 이미 있는 캡처만 읽었다. 게임 실행, 새 캡처, 테스트는 하지 않았다. 기준 커밋은 main `0e7952a`.
- 단위: 따로 적지 않으면 **기준 px**(640×360 좌표)다. 캡처 분석은 1280×720 캡처(창 2배)의 **화면 px**다.
- 캡처 수치는 python(PIL)으로 픽셀을 읽기만 해서 쟀다. 파일은 만들지 않았다.

---

## 0. 한눈에

| 항목 | 지금 상태 | 근거 |
|---|---|---|
| 렌더 구조 | 640×360 기준, `canvas_items` + `integer`. 맵과 HUD를 모두 루트 뷰포트에 창 해상도로 그린다. 도트 그림은 Nearest, 글자는 화면 해상도 벡터다 | project.godot:12-17, main.gd:62, SPEC.md:138 (S30) |
| 글꼴 | 저장소의 글꼴 파일은 `Galmuri7.ttf` 하나다. 맵 위 숫자 3곳에만 쓴다. HUD·메뉴 글자는 글꼴을 지정하지 않아 Godot 기본 글꼴(Open Sans SemiBold)로 그리고, 한글은 시스템 글꼴로 채운다 | battle_view.gd:247, hud_theme.gd:17-19, handoff/archive/2026-10-19-2/r7.md:106 |
| 패널 | 모두 코드로 만든 `StyleBoxFlat`이다. 테두리 1px, 모서리 직각, 그림자는 1px 하나뿐이다. Theme `.tres`, `StyleBoxTexture`, `NinePatchRect`는 0개다 | hud_theme.gd:36-52, grep 0건 |
| 색 | 테마 상수 11개: 차가운 남회색 4단 + 금색 강조 + 빨강 + 글자색 2 + 초록 + 테두리 2. 그 밖에 흩어진 hex가 32종이고, `Color.WHITE`·`BLACK`·`GREEN`도 쓴다 | hud_theme.gd:5-15 |
| 배치 | 대부분 Container 없이 `Rect2`·`Vector2` 좌표를 하드코딩한다. 간격은 1·2·3·4px이고, 화면 가장자리 여백은 0~4px이다 | hud.gd:75-80, hud_build.gd:46-47, hud_keep.gd:10 |
| 아이콘 | 두 갈래다. (a) ASCII 도트 배열을 코드에서 굽는다(`HudBuild.dots`). (b) 맵 스프라이트 시트를 잘라 칸 크기로 Nearest 축소한다(정수배 아님). 전용 UI 텍스처는 `gear.png`(96×24) 하나다 | hud_build.gd:180-205, SPEC.md:138 |

---

## 1. 화면·렌더 설정

| 설정 | 값 | 위치 |
|---|---|---|
| 기준 해상도 | 640×360 | project.godot:12-13 |
| 창 크기 덮어쓰기 | 1280×720 | project.godot:14-15 |
| stretch mode / scale mode | `canvas_items` / `integer` | project.godot:16-17 |
| 2D 꼭짓점 스냅 | `snap_2d_vertices_to_pixel=true` | project.godot:25 |
| 기본 텍스처 필터 | `default_texture_filter=0` (Nearest) | project.godot:26 |
| transform 스냅 | 지정 안 함(`snap_2d_transforms_to_pixel` 기본 false) | project.godot 전체 26줄 |
| `[gui]` 섹션 | **없음**. `gui/theme/custom`, `gui/theme/custom_font`, 기본 글꼴 크기, 글꼴 oversampling 모두 엔진 기본값이다 | project.godot 전체 26줄 |

- 맵은 SubViewport 없이 루트 뷰포트에 바로 그린다(main.gd:62, S30 2026-10-25 변경). `map_viewport()` SubViewport는 벤치 전용이다(main.gd:84-96).
- 최소 창 크기는 기준의 2배다(main.gd:231). 창은 작업 영역에 들어가는 가장 큰 정수배로 정한다(main.gd:240-248). 내보낸 빌드는 처음에 전체화면으로 뜬다(main.gd:232-234, S163). 그래서 실제 배율은 1080p에서 3배, 1440p에서 4배, 4K에서 6배다.
- 카메라 줌은 `[1, 2, 3]`이고 기본은 2배다(camera.gd:10, 27). 기본 화면에서 맵 아트 1px = 2 기준 px이고, 창 2배일 때는 4 화면 px다. 줌 중간값은 정수 화면 배율만 지난다(camera.gd:111).
- 설계 결정 S30(SPEC.md:138) 요약:
  - 2026-10-19 «HUD만 고해상도»: 4K에서 기준 해상도로 그린 글자가 6배로 커지며 뭉개졌기 때문이다.
  - 2026-10-21: HUD 아이콘은 도트 그림을 정수배·Nearest로 그리고 글자만 화면 해상도로 그린다. 대역 아이콘(시설·용병 그림을 잘라 쓴 것)은 «칸에 맞춰 Nearest로 줄인다(정수배가 아니다)». ✓✕▶●⚙ 같은 기호도 글꼴이 아니라 그림으로 그린다.
  - 2026-10-25: 맵도 창 해상도로 그린다.

## 2. 글꼴

### 2.1 저장소에 있는 글꼴

- `art/fonts/Galmuri7.ttf`가 유일한 글꼴 파일이다. `.otf`·`.fnt`·비트맵 글꼴 이미지는 없다. (`art/trial/preview/font_digits.png`는 시안 미리보기 그림이지 글꼴이 아니다.)
- 라이선스: Galmuri7 v2.40.4, Lee Minseo(quiple), SIL OFL 1.1이다(CREDITS.md:7, art/fonts/Galmuri-OFL.txt:1-3).
- 가져오기 설정(art/fonts/Galmuri7.ttf.import):
  - `antialiasing=0` (:16)
  - `generate_mipmaps=false` (:17)
  - `disable_embedded_bitmaps=true` (:18)
  - `multichannel_signed_distance_field=false` (:19)
  - `allow_system_fallback=false` (:22)
  - `hinting=0` (:25)
  - `subpixel_positioning=0` (:26)
  - `oversampling=0.0` (:28)
  - `fallbacks=[]` (:30)
  - 도트 글꼴 권장 설정과 같다(ui_research/evidence/web.md:1174 TakWolf 예제 비교).
- 쓰는 곳은 맵 위뿐이고, 모두 8px이다:
  - preload: battle_view.gd:247
  - 영웅 레벨 숫자: battle_view.gd:533
  - 출현 지점 적 수(검은 상자 위): battle_view.gd:626-629
  - 보라 대본 예고 숫자(1px 그림자 포함): battle_view.gd:3890-3891
- 한글 범위: PIL로 그려 보니 «가»·«힣»·«뷁»·«웨»의 마스크가 `.notdef`와 다르다. 따라서 한글 음절을 가진다(11,172자 전부인지는 fontTools가 없어 세지 못했다).

### 2.2 HUD·메뉴 글자

- `HudTheme.make()`는 `Theme.new()`에 `default_font_size`만 준다(hud_theme.gd:17-19). 저장소 어디에도 `FontFile`·`SystemFont`·`FontVariation`·`add_theme_font_override`가 없다(grep 0건). 따라서 HUD·메뉴는 Godot 기본 글꼴 **Open Sans SemiBold**(벡터)로 그린다.
  - 이 사실은 앞선 조사가 문서·소스로 확인해 두었다: ui_research/evidence/web.md:1162-1164.
- Open Sans에 없는 한글은 시스템 글꼴로 채운다. 어느 글꼴인지는 확인된 적이 없다: handoff/archive/2026-10-19-2/r7.md:106 «어느 글꼴로 채우는지는 확인하지 않았다. 플레이어 PC마다 달라질 수 있으니 글꼴 파일을 게임에 함께 넣는다» — 이 제안은 아직 HUD에 반영되지 않았다.
- 글꼴에 없는 기호는 그림으로 대신한다: hud_keep.gd:38 «글꼴에 ↶ 글자가 없어 그림으로 그린다»(S30의 ✓✕▶●⚙ 규칙과 같은 이유).
- 글자 크기(기준 px):
  - HUD 루트 10(hud.gd:298), 메뉴 12(menus.gd:26). Godot 기본값은 16이다.
  - 코드에서 크기를 따로 준 곳: **7px 17곳, 8px 29곳(맵 4곳 포함), 9px 15곳, 10px 6곳, 12px 1곳**. 다섯 단계다.
  - 7px 한글:
    - hud.gd:1097·1116 «웨이브»
    - hud_keep.gd:101 안내 줄 «클릭 1명 · Shift+클릭 5명 · …»
    - hud_keep.gd:255 카드 이름(병사·방패병…)
    - hud_keep.gd:309 강화 띠
    - 이 넷은 앞선 조사의 «한글은 8 밑으로 쓰지 않는다»(ui_research/README.md:728, 설계 판단)와 어긋난다.
- 외곽선 글자: 건설 격자·선택 패널 Label에 검정 `outline_size 3`을 쓴다(hud_build.gd:165-166, hud_select.gd:65-66). 그 밖의 HUD 글자에는 외곽선도 그림자도 없다.

## 3. 테마·패널

- **Theme 리소스(.tres)는 0개다.** 테마는 코드 한 곳(hud_theme.gd:17-33)에서 만든다. 정의하는 것은 넷이다:
  - `PanelContainer/panel`
  - `Button`의 normal·hover·pressed·hover_pressed·focus·disabled
  - `Label/font_color`
  - 변형 `BarCell`(Button 상자에서 안쪽 여백만 0)
- `box()`(hud_theme.gd:36-44)는 새 `StyleBoxFlat`을 만든다. 안쪽 여백은 Godot 기본 테마의 같은 칸 값을 복사하고(:37-40), 배경색·테두리색을 넣고, 테두리 1px를 준다(:43). 모서리 반지름은 지정하지 않는다. `StyleBoxFlat` 기본값이 0이라 **모든 패널이 직각**이다.
- `framed()`(hud_theme.gd:47-52)는 «두 겹 테두리»를 만든다(S241): 안쪽 테두리 `MAP_RIM #6b7280`, 바깥 `shadow_size 1` `MAP_EDGE #0b0c10`. 쓰는 곳:
  - 건설 격자(hud_build.gd:48), 정보 칸(hud_build.gd:73)
  - 힌트(hints.gd:53)
  - 거점 패널(hud_keep.gd:89)
  - 선택 패널(hud_select.gd:35-36)
- `StyleBoxFlat`을 직접 만드는 곳(같은 1px 직각 상자):
  - 건설 칸 3상태(hud_build.gd:121-131)
  - hud_keep.gd:193·243·337
  - hud_select.gd:89
  - test_panel.gd:149
  - 안내 칩: 검정 65%, 테두리 없음, 좌우 여백 4(hud.gd:424-428)
- **`StyleBoxTexture`·`NinePatchRect`·`patch_margin`은 src·tools·data·tests 모두 0건이다.** 텍스처로 만든 프레임은 하나도 없다.
- 커스텀 그리기:
  - 맵(battle_view.gd): `draw_rect` 39곳, `draw_string` 4곳, `draw_texture*` 21곳
  - 스킬 칸 `_paint`(skill_cell.gd:73-): 대기 막, 금색 꺾쇠 4×1·1×4, 맥박 테두리
  - 미니맵: `draw_rect` 5곳
  - HUD 패널 바탕은 `_draw`로 그리지 않고 Panel + StyleBoxFlat이다.
- 메뉴(menus.gd):
  - 구조: `CenterContainer > PanelContainer > VBox` 버튼(:30-35)
  - 제목 화면(:49-58)은 «새 게임·이어하기·(테스트 모드)·설정·종료» 버튼뿐이다. **로고·게임 이름·배경 그림이 없다.** 배경은 단색 `Color(0.08, 0.08, 0.1)`이다(:46).
  - 설정 화면은 `CheckButton`(:185-186), `HSlider`(:81·:98·:200), `OptionButton`(:114·:127)을 쓴다. HudTheme가 이 타입들을 정의하지 않으므로 스위치 아이콘·슬라이더·팝업 목록은 Godot 기본 테마 모양일 것이다(코드에서 한 추론이고, 화면은 보지 않았다).

## 4. UI 색

### 4.1 테마 상수(hud_theme.gd:5-15)

| 상수 | 값 | 역할 | HSV 채도/명도 | PANEL 위 대비 |
|---|---|---|---|---|
| PANEL | `#14161c` α0.92 | 패널 바탕 | .29 / .11 | — |
| CELL | `#23262f` | 칸 바탕 | .26 / .18 | 1.20:1 |
| LINE | `#3a3f4b` | 칸 테두리 | .23 / .29 | 1.72:1 |
| HOVER / MAP_RIM | `#6b7280` | 호버 테두리, 아래 패널 안쪽 테두리 | .16 / .50 | 3.74:1 |
| MAP_EDGE | `#0b0c10` | 바깥 1px | — | — |
| TEXT | `#e8e8e8` | 글자 | 0 / .91 | 14.8:1 |
| DIM | `#9aa0aa` | 보조 글자 | .09 / .67 | 6.9:1 |
| ACCENT | `#ffd37f` | 강조 하나(금) | .50 / 1.0 | 12.8:1 |
| DANGER | `#ef3a0c` | 위험·이유 | **.95** / .94 | 4.55:1 (CELL 위 3.8:1) |
| GOOD | `#7cc85a` | 체력·세금 | .55 / .78 | 8.8:1 |

- 패널·칸·테두리 세 단계가 명도로 거의 갈리지 않는다(1.2~1.7:1). 패널 넷은 모두 색상 218~225°의 차가운 남회색이다.
- `#6b7280`은 Tailwind CSS `gray-500`과 같은 hex다(우연일 수 있지만 웹 UI 기본 회색과 같은 값이다).

### 4.2 흩어진 색과 순색

- HUD 스크립트(battle_view 제외 src/ui + menu·main)에 hex 리터럴이 **42종** 있다. 테마 hex 10종을 빼면 **32종**이 파일마다 따로 정의되어 있다. 많은 순서로 hud_keep 12, hud_minimap 8.
- 그 밖에 `Color.WHITE` 12회, `Color.BLACK` 7회, `Color.GREEN` 1회, 실수 `Color()` 7종(회색 0.4·0.7, 검정 α0.5·0.6·0.65·0.7, 메뉴 배경)이 있다.
- **순색·순흑백**:
  - `Color.GREEN`(#00ff00): 체력바 버튼 그림(hud.gd:550, `Color.BLACK`과 함께)과 **맵 위 영웅·용병·적 체력 막대 전부**(battle_view.gd:4796-4798, 검정 바탕 :4792)
  - `Color.WHITE`: 건설 격자 비용 글자(hud_build.gd:154), 거점 막대 번쩍임(hud.gd:1042)
  - `Color.BLACK`: 외곽선, 페이드(hud.gd:628), 가장자리 표식 바탕(hud.gd:1224)
- 채도가 높은 미니맵 점: FOE `#ff3b3b`(채도 .77, 명도 1.0), ALLY `#3ce0d8`, STRUCTURE `#8fd8ff`(hud_minimap.gd:13-16).
- **아트 팔레트와의 관계**: 맵·유닛·장비 아이콘은 `tools/art/palettes.json`의 `f24p`(Fantasy 24 + 보충 8색)를 쓴다(battle_view.gd:86-95 `PX`, tools/art/gear.py:2). HUD 테마 11색 가운데 f24p에 있는 것은 DANGER `#ef3a0c` 하나다. HUD hex 42종 가운데 f24p 색은 7종이고, 대부분 커서(hud_cursor.gd:7)와 영입 투구(hud_shop.gd:27)다.
- `data/`에는 색 정의가 없다(grep 0건).
- 캡처 실측(hq_shop_research/img/now_battle.png):
  - 위 띠 최빈색: `#23262f`·`#161a1d`·`#3a3f4b`·`#0e0f13`·`#7cc85a`
  - 맵 풀 최빈색: `#2d472d`·`#392a1c`·`#684c3c`

## 5. 레이아웃

- 장면 파일은 `menu.tscn`·`main.tscn` 두 개이고 노드가 하나씩이다. HUD 전체를 코드로 만든다. 루트는 전체 화면 Control에 테마 10px을 단 것이다(hud.gd:294-299).
- 배치 방식: 위 띠·건설 격자·거점 패널·선택 패널은 «컨테이너가 아니라 자식을 좌표로 바로 놓는다»(hud_build.gd:1, hud_keep.gd:1).

| 파일 | position 대입 | size·최소 크기 대입 | Rect2 | HBox/VBox/Grid | MarginContainer |
|---|---|---|---|---|---|
| hud.gd | 47 | 42 | 24 | 10/7/1 | 0 |
| hud_keep.gd | 28 | 27 | 1 | 0/1/0 | 0 |
| hud_select.gd | 10 | 10 | 0 | 0/0/0 | 0 |
| hud_build.gd | 8 | 7 | 6 | 3/1/0 | 0 |

- 화면 지도(기준 px):
  - **위 띠** [0,0,640,28](hud.gd:300-302). 칸 자리 `BAR`(hud.gd:75-78, «임시값»): 상태 4~100, 임무 104, 공병 130, 영웅 156·264·372(폭 104), 진행 480~616, 메뉴 620~636. 칸 높이 24, 위 여백 2, 칸 사이 4·2·6·4·4·4·4px.
  - **띠 바로 아래**:
    - 인구 [4,30,52,12], 타워 [60,30,52,12](hud.gd:79-80)
    - 안내 칩 (134,30)(hud.gd:421)
    - 토스트 (436,30) 200×16(hud_toast.gd:19-26)
    - 보스 막대 [220,31,200,14](hud.gd:85)
  - **왼쪽 열**:
    - 전체 오토 (3,210) 60×26(hud_auto.gd:19-20)
    - 영입 (3,238)(hud_shop.gd:21-22)
    - 대피령 (3,266)(hud_evac.gd:27-28)
    - 체력바 버튼 [65,266,24,24](hud.gd:117)
    - 미니맵 (2,295) 약 62×65(hud_minimap.gd:20-21·41-42)
  - **아래**:
    - 거점 패널 [92,262,216,98](hud_keep.gd:10)
    - 선택 패널 (312,288) 196×72(hud_select.gd:33-34)
    - 건설 격자 (510,288) 130×72(hud_build.gd:46-47) — **오른쪽·아래 화면 끝에 0px로 붙는다**. 선택 패널과 격자 사이는 2px이다.
  - **오른쪽**: 상황 태그 x 608, y 182+26i, 24×24(hud.gd:395-396), 자동 수리 [582,182,24,24](hud.gd:119).
  - **창**: 영입·라운드 사이는 (16,34) 폭 608, 결과 창은 [170,110,300,110](hud.gd:246·764).
- 자주 나오는 간격:
  - 칸 사이 2: 건설 `STEP 22 = 20+2`(hud_build.gd:14), 거점 카드 `STEP 42 = 40+2`(hud_keep.gd:13)
  - 패널 안쪽 `PAD 4`(hud_build.gd:12)
  - 컨테이너 separation 0~3(hud_tip.gd, hud_build.gd 정보 칸), 2(hud.gd:506), 8(hud.gd:478·498)
  - 장비 줄 1px — «창이 화면 안에 든다»를 위해서다(hud.gd:507)
- 넘침 처리: 7곳에서 `clip_text`로 자른다(예: hud_build.gd:93 «폭 130을 넘기지 않는다»).
- 자리·크기 값에 «임시값» 주석이 많다: hud.gd 14곳, hud_alert 4, hud_keep 4, hud_build 2, hud_cursor 2 등.

## 6. UI 아트 자산

- **전용 UI 텍스처**: `art/gear/gear.png` 96×24 하나다. 장비 아이콘 6종이 16×16과 8×8로 들어 있다. `tools/art/gear.py`가 f24p 팔레트로 그리고, 바깥에 외곽선 `151a26`을 두르며, 안티앨리어싱은 없다(gear.py:1-3).
- **(a) 코드 ASCII 도트**: `HudBuild.dots(rows, colors)`(hud_build.gd:200-205)가 문자열 배열을 `Image.set_pixel` → `ImageTexture`로 굽는다.
  - 호출 수: hud.gd 21곳, hud_keep 8, hud_alert 2, hud_build 2, battle_view 4, 그 밖에 1곳씩.
  - 상수 예: SCROLL·COIN·FLAG·MENU·PLAY·CROWN·COG·FANG·SCALE·TUSK·SKULL·MOON·ARROW·ATTACK·STOP·SHIELD·HAMMER·UP·HP_PIC(hud.gd:87-118), BELL·HELM·CORNERS·GATE·LOCK·GLASS·TORCH·SLASH·UNDO·ICONS.
  - 대부분 1~3색이고 외곽선이 없으며, 색은 HudTheme 상수(TEXT·ACCENT·DANGER)다.
- **(b) 맵 스프라이트 잘라 쓰기**: `HudBuild.icon(kind)`(hud_build.gd:180-198).
  - 원본: `facility.png`(1056×192, 칸 96×96), `keep.png`(320×80, 칸 80×80), `heroes.png`(868×15656, 캔버스 24~32)
  - 잘라서 used rect로 여백을 덜고, TextureRect `STRETCH_KEEP_ASPECT_CENTERED`로 칸에 맞춘다(hud_build.gd:144-147).
  - 도착 크기: 건설 칸 16×16, 초상 22×22(hud.gd:338), 위 띠 거점 10×10(hud.gd:1012), 공병 12×12(hud.gd:311).
- **화면에 보이는 도트 배율**(기준 px 기준; 창 2배면 화면 px는 2배):

| 배율 | 예 |
|---|---|
| 1배 | COIN 6×6(hud.gd:1022), FLAG 6×6(:1028), SCROLL 12×12(:306), MENU 8×7(:386), PLAY 4×7(:1056), SKULL·MOON 7×7(:1074-1075), 장비 16·8 |
| 2배 | ATTACK·STOP·SHIELD 10→20(:397), HAMMER 7×6→14×12(:412), CROWN 등 8→16(:485), HP_PIC 10→20(:550), CORNERS 10→20(hud_auto.gd:30) |
| **1.6배** | BELL 10→16(hud_evac.gd:9·34-39), HELM 10→16(hud_shop.gd:7·29-32), `STRETCH_SCALE` |
| 축소(정수 아님) | 시설 96칸→16, 거점 80칸→10, 영웅 24~32→22, 팝업 아이콘 `icon_max_width 10`(hud.gd:900) |
| 맵(기본 줌 2) | 아트 1px = 2 기준 px |

- 생성기: `tools/art/*.py`(atlas·keep·facility·gear·tiles 등)는 맵·유닛 그림용이다. **UI 프레임·9-slice 텍스처 생성기는 없다.**
- 커서는 f24p 색 도트로 그리고 창 배율로 키운다(hud_cursor.gd:7, main.gd:250-252).

## 7. 기존 캡처 관찰

- art/ 밖의 PNG는 38장이다. 가장 새것은 `hq_shop_research/img/*.png` 11장(커밋 2026-11-12, 1280×720 = 창 2배)이다. 나머지는 play_review(10-27·10-29), control_research(10-24 커밋), vfx_research(10-27)다.
- **11-12 뒤 main(거점 패널 구현 #351·#352)을 찍은 캡처는 없다.**
- 제목 화면·설정·ESC 메뉴·영입 창·결과 창 캡처도 없다.
- 캡처의 빨강·노랑 테두리 설명 상자(«⑦ 전투 중에도…», «A안 — …»)는 조사 문서용 주석이지 게임 UI가 아니다.

### 7.1 본 캡처 6장

1. `hq_shop_research/img/now_battle.png` — 전투 단계 거점 팝업(11-12 당시 실제 화면)
2. `hq_shop_research/img/now_prep_buy_tip.png` — 준비 단계 거점 팝업 + 툴팁 «불마법사 구매»
3. `hq_shop_research/img/a_panel_prep.png` — 시안 A. 이후 S365 거점 패널로 구현되었고, 자리 [92,262,216,98]이 hud_keep.gd:10과 같다
4. `hq_shop_research/img/a_panel_battle.png` — 시안 A, 전투 중
5. `hq_shop_research/img/c_window_prep.png` — 시안 C(채택 안 됨). 영입 창과 같은 가운데 창 꼴
6. `vfx_research/img/now_ignis_e_crop3x.png` — 10-27 맵 위 숫자·범위 원 3배 확대

### 7.2 눈으로 본 것

- **프레임**:
  - 모든 패널이 거의 검은 남회색 직사각형에 회색 1px(화면 2px) 테두리, 직각 모서리다. 하이라이트·베벨·안쪽 그림자·질감·장식 모서리가 없다.
  - 위 띠는 640 폭 한 장에 칸 8개가 2~6px 간격으로 붙어 있다. 칸 테두리(`#3a3f4b`)와 띠 바탕이 비슷한 어둠이라 칸 경계가 약하다.
  - 아래 패널(거점·선택·건설 격자)은 회색 두 겹 테두리이고 화면 끝에 붙어 있다.
- **글자**:
  - HUD 글자(«남은 적 36», «인구 2/4», «거점 체력 100/100», 툴팁 4줄)는 매끈하게 안티앨리어싱된 고딕체(한글은 시스템 고딕으로 보임)다. 획이 화면 1~2px로 가늘다.
  - 같은 화면의 도트 그림은 화면 4px 블록(맵 줌 2)이나 2px 블록(1배 HUD 아이콘)이다. **글자가 그림보다 2~4배 고운 픽셀 밀도로 보인다.**
  - 맵 위 Galmuri7 숫자(crop3x의 «10»)는 맵 도트와 같은 블록 글자다.
- **아이콘**:
  - 건설 격자 칸의 시설 아이콘은 96px 그림을 16px로 줄인 것이라 형태가 작고 뭉개진다. 흐린 칸(0.35)은 더 알아보기 어렵다.
  - 칸 위에 흰 비용 숫자와 검정 외곽선이 그림을 덮는다.
  - 대피령 종·영입 투구는 1.6배라 도트 굵기가 고르지 않다.
  - 오토의 금색 꺾쇠(2배)와 동전(1배)은 깨끗하지만 서로 굵기가 다르다.
- **색**:
  - HUD는 차가운 남회색 + 금색 테두리(«전투 시작», 고른 탭·카드) + 빨강 + 밝은 연두 막대다.
  - 맵은 따뜻한 풀·흙·청회 돌(f24p)이다.
  - 시안 A·C의 탭·카드는 금색·흰색·회색 글자가 섞여 있고, 창 안 글자는 4~5단계 회색으로 위계를 낸다.
- **밀도**: 위 띠, 왼쪽 열(버튼 셋 + 미니맵), 아래 패널 셋이 화면 가장자리에 붙어 있다. 패널 안 여백은 2~4px이고, 카드·칸이 촘촘하다.

### 7.3 캡처 수치(now_battle.png, 1280×720)

| 영역 | 2×2 블록이 고르지 않은 비율 | 서로 다른 색 수 | 가로 같은 색 줄 길이(화면 px) |
|---|---|---|---|
| 맵 풀(아트) | 0.0% | 5 | 4·8·12…(모두 4의 배수) |
| 맵 돌바닥(아트) | 0.0% | 6 | — |
| 위 띠 테두리 | 0.0% | 4 | — |
| 글자 «남은 적 36» | 34.3% | 178 | **1px 줄이 77.9%** |
| 글자 «인구 2/4» | 23.3% | 141 | 1px 줄 75.3% |
| 팝업 글자 «공병 15» | 29.4% | 170 | — |
| 영웅 초상 1(대역 축소) | 33.8% | 28 | 1·2·3·5px가 섞임 |
| 건설 칸 아이콘(대역 축소) | — | — | 1px 줄 50.8% |
| 영입 투구 1.6배 | — | — | 3·6·7px(홀수가 섞임 = 3.2px 블록) |
| 오토 꺾쇠 2배 | — | — | 16·32(4의 배수) |
| 동전 1배 | — | — | 2·4 |

→ 맵·테두리·정수배 아이콘은 격자가 맞는다. 글자·대역 아이콘·1.6배 아이콘은 기준 픽셀 격자보다 고운 화면 픽셀로 그려진다.

---

## 8. 흔한 도트 UI 함정과 대조한 관찰 (가설)

모두 가설이다. 각 항목에 근거를 붙였다. «아마추어 같다»는 피드백과의 인과는 검증하지 않았다.

- **H1. 글자와 그림의 픽셀 밀도가 다르다.** 근거:
  - S30(SPEC.md:138)이 «글자만 화면 해상도»로 정했다.
  - HUD 글꼴 지정이 없다(hud_theme.gd:17-19).
  - 캡처에서 글자는 1px 줄이 75~78%이고 색이 141~178종이다. 아트는 4px 블록, 5~6색이다(§7.3).
  - 창 배율이 3·4·6배로 커질수록 차이도 커진다(main.gd:231-248).
  - 단, 사용자가 의도한 결정이다(4K 뭉개짐 해결). 앞선 조사는 «난잡함의 원인은 글꼴이 아니다»라고 결론 냈다(ui_research/README.md:117-123). 가이드에서는 «Galmuri 등 도트 글꼴로 통일 vs SPD식 고해상도 글자를 의식적으로 고르기» 트레이드오프로 다뤄야 한다(ui_research/evidence/web.md:1183).
- **H2. 한 화면에 도트 크기가 4~5가지다.** 근거: 1배·2배·1.6배·정수 아닌 축소 아이콘과 맵 줌 2배가 같은 화면에 있다(§6 표). 캡처 줄 길이 2·3.2·4px와 1px 섞임(§7.3).
- **H3. 큰 스프라이트를 줄인 대역 아이콘이 뭉개진다.** 근거:
  - 96×96 시설 그림을 16×16으로 Nearest 축소한다(hud_build.gd:179-198·144-147).
  - 80×80 거점 그림을 10×10으로 줄인다(hud.gd:1012).
  - 캡처에서 형태가 작고 뭉개지며, 줄 길이 1px가 50.8%다.
  - 코드 스스로 «전용 아이콘이 생기기 전 대역»이라고 적었다(SPEC.md:138, hud_build.gd:179).
- **H4. 엔진 기본값 느낌이 남아 있다.** 근거:
  - HUD 글꼴이 Godot 기본 Open Sans + OS 한글 폴백이다(§2.2).
  - 설정 화면 CheckButton·HSlider·OptionButton은 테마 밖이다(menus.gd:81·114·185).
  - 제목 화면에 로고·그림 없이 버튼만 있다(menus.gd:46-58).
  - 패널 안쪽 여백은 Godot 기본 테마 값을 복사한다(hud_theme.gd:3·37-40).
  - 테두리 회색 `#6b7280`이 Tailwind gray-500과 같은 값이다.
- **H5. 프레임 마감이 «평평한 1px 상자» 한 종류뿐이다.** 근거:
  - StyleBoxTexture·NinePatchRect가 0건이고, 모서리 직각, 그림자 1px가 전부다(hud_theme.gd:36-52).
  - PANEL·CELL·LINE의 명도 대비가 1.2~1.72:1이라 덩어리와 칸이 잘 갈리지 않는다(§4.1).
  - 캡처에서 위 띠 칸 경계가 약하다.
- **H6. HUD 색이 아트 팔레트 밖에 있다.** 근거:
  - 테마 11색 가운데 f24p 색은 1개다. 차가운 중성 회색(색상 218~225°)이고, 맵은 따뜻한 f24p다(§4.2).
  - 흩어진 hex가 32종이다.
  - 순색 `#00ff00` 체력 막대(battle_view.gd:4798, hud.gd:550), 채도 .95 DANGER, 채도 .77 미니맵 적 점이 있다.
- **H7. 여백과 숨 쉴 자리가 부족하다.** 근거:
  - 화면 끝 여백이 0~4px이다(건설 격자는 오른쪽·아래 0, hud_build.gd:46-47).
  - 칸 사이 2px, 장비 줄 1px(hud.gd:507), 컨테이너 separation 0~3.
  - 크기를 하드코딩해서 글이 늘면 잘린다(`clip_text` 7곳).
  - 자리 값 다수가 «임시값»이다.
- **H8. 글자 크기 단계가 많고 작다.** 근거: 7·8·9·10·12 다섯 단계이고, 한글 7px가 4곳 이상이다(§2.2). 앞선 조사의 «한글 8 이상» 규칙(ui_research/README.md:728)과 어긋난다.
- **H9. 작은 칸에서 외곽선 글자가 그림을 덮는다.** 근거: `outline_size 3` 검정 외곽선 + `Color.WHITE` 비용 숫자(hud_build.gd:154·165-166). 캡처의 건설 격자에서 숫자가 아이콘 아래 절반을 가린다.
- **H10. 아이콘 그림체가 섞여 있다.** 근거: HUD 기호는 1~2색 평면 ASCII 도트이고 외곽선이 없다(hud.gd:87-118). 장비 아이콘·초상·시설 대역은 다색 음영 + `151a26` 외곽선 스프라이트다(tools/art/gear.py:2).

### 이미 갖춘 것

가이드가 이미 된 것을 다시 권하지 않게 적어 둔다.

- 정수배 창 배율과 Nearest 필터, 꼭짓점 스냅(project.godot:16-26, main.gd:240-248)
- 도트 글꼴의 올바른 가져오기 설정(Galmuri7.ttf.import)
- 색 상수 한 곳(hud_theme.gd)과 강조색 하나 규칙
- 정해진 자리의 HUD(S185)
- 공용 툴팁(hud_tip.gd)
- 기호를 그림으로 그리는 규칙(S30)
- 원인별 비활성 표시(흐림 0.35, 비용 색 3단계)

## 9. 앞선 UI 조사와의 관계

- `ui_research/README.md`(2026-10-20)는 **배치·정보 구조**를 다뤘다: 일곱 가지 문제, 추천안 «위 한 줄 띠 + 오른쪽 아래 건설 패널», 규칙 20개, 크기·색 표(4.9). 그 결론 대부분이 지금 코드에 들어가 있다.
- `ui_research/gemini/`(10-21)는 시안 평가, `hq_shop_research/`(11-12)는 거점 구매 UI를 다뤘다.
- **시각 마감**(프레임 텍스처·9-slice, HUD 색을 아트 팔레트에 맞추기, HUD 글꼴 통일, 아이콘 전용 시트)은 어느 조사도 주제로 다루지 않았다. 이번 가이드가 메울 빈칸이다.

## 10. 확인 못 한 것

- Windows에서 HUD 한글을 실제로 채우는 시스템 글꼴 이름(맑은 고딕으로 추정하지만 미확인)과, 다른 PC에서의 차이
- 최신 main(0e7952a) 화면 — 11-12 뒤 캡처가 없다(거점 패널 구현, 마을 레벨 해금, 보스 사다리 수정 반영 화면)
- 제목·설정·ESC·영입·결과 창의 실제 모습(캡처 없음). CheckButton 등이 실제로 Godot 기본 모양인지
- 3·4·6배(전체화면)에서의 글자·아이콘 모습. 캡처가 모두 2배다
- Galmuri7의 한글 전체 커버리지(표본 4자만 확인)
- Godot 4.7의 글꼴 oversampling이 canvas_items에서 정확히 어떻게 동작하는지(문서 미확인. 캡처로는 화면 해상도 래스터로 보인다)
