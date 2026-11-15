# 레퍼런스 분석: Celeste(2018)와 Stardew Valley(2016, 1.5·1.6 포함)의 UI 시각 설계

> 표기 규칙: «출처 사실»은 각 줄 끝의 링크에서 확인한 내용이다. «스크린샷 관찰»은 내가 Steam 공식 스크린샷(1920×1080)을 직접 보고 적은 것이라 출처 사실과 구분한다. 화면 픽셀 수치는 1920×1080 스크린샷 기준 눈대중 측정이다(±5px 안팎).
> 스크린샷 6장 상한을 Celeste 3장·Stardew 3장으로 썼는데, Stardew 3장은 HUD가 꺼진 풍경 샷이라 Stardew UI는 화면으로 확인하지 못했다(각 Gaps에 적음).
> Stardew 공식 위키(stardewvalleywiki.com)는 Cloudflare 403으로 본문을 직접 읽지 못해, 그 위키 내용은 검색 결과에 나온 발췌문으로만 인용했다(해당 줄에 «검색 발췌»로 표시).

## 1. Celeste — 저해상도 게임 화면 위의 메뉴·대화·포트레이트는 도트인가 고해상도인가, 어떤 폰트인가

### Takeaway
Celeste는 게임 월드를 320×180으로 그리고 정수배로 키우지만, 대화창·포트레이트·글자는 도트가 아닌 고해상도(1080p) 레이어로 따로 그린다. 영어 등 라틴 문자는 Renogare(BMFont 64px), 한국어는 Noto Sans CJK KR Medium으로 바꿔 쓴다 — 즉 «픽셀 월드 + 매끈한 고해상도 UI»를 의도적으로 섞고, UI 쪽은 끝까지 고해상도로 통일했다.

### Cited Findings
- 개발자(Noel Berry) 글: "Our screen resolution is tiny (320x180), and textures can be pretty dang big these days (4096x4096+)." — [Noel Berry, Remaking Celeste's Lighting](https://www.noelberry.ca/posts/celeste_lighting) (검색 발췌; 같은 글의 [Medium 판](https://medium.com/@NoelFB/remaking-celestes-lighting-3478d6f10bf))
- Noel Berry(리드 프로그래머)는 PICO-8판(128×128)에서 "we increase the resolution a bunch… Celeste is at least six times bigger"라고 말함 — [Software Engineering Daily 대담 녹취](https://softwareengineeringdaily.com/wp-content/uploads/2024/06/SED1691-EXOK-Games.txt)
- 아트 디렉터 Pedro Medeiros: 레트로 기기에서 돌 수 있다는 팬 주장은 불가능하다며, 게임이 "a resolution similar to Game Boy Advance games"로 돌긴 한다고 언급 — [Wired 기사 미러](https://wirednews.pages.dev/story/modern-pixel-art-games) (미러 사이트라 신뢰도 중간)
- 폰트(모딩 위키, Everest): 영어 기본 폰트는 Renogare — "the vanilla English font (Renogare)". Noto Sans Medium은 "the font used by vanilla for Russian, Chinese, etc." — [EverestAPI Wiki: Adding Custom Dialogue](https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue)
- 같은 문서의 언어별 BMFont 원본 폰트: Chinese = Noto Sans CJK SC Medium, Japanese = Noto Sans CJK JP Medium, **Korean = Noto Sans CJK KR Medium**, Russian = Noto Sans Med, 그 밖의 언어 = Renogare. 폰트 파일명은 `chinese.fnt`·`japanese.fnt`·`korean.fnt`·`russian.fnt`·`renogare64.fnt`, 크기 지정은 `FONT=Renogare,64` — 즉 64px로 구운 BMFont 비트맵 폰트(.fnt + png 페이지) — [EverestAPI Wiki: Adding Custom Dialogue](https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue)
- 로그에 "[PixelFont] Loading font:"가 찍힘(엔진 클래스명이 PixelFont이지만 실제 글꼴은 위 TTF에서 구운 64px 비트맵) — [EverestAPI Wiki: Adding Custom Dialogue](https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue)
- Renogare는 상용 라이선스 폰트라는 사용자 증언(비공식) — [itch.io 게시글](https://itch.io/post/2145587)
- 포트레이트 작화: 게임 아티스트 Amora가 포트레이트를 그렸다는 언급(미사용 엄마 포트레이트에 나중에 전화기를 그려 넣음) — [The Cutting Room Floor: Celeste](https://tcrf.net/Celeste)
- 스크린샷 관찰: 월드 타일·캐릭터는 한 «아트 픽셀»이 화면 약 6×6px 블록으로 보이는 정수배 확대인 반면, 대화 글자는 안티에일리어싱된 매끈한 산세리프, 포트레이트는 부드러운 선의 고해상도 일러스트, 대화창 모서리 장식도 그라데이션이 있는 고해상도 그림이다 — observed in screenshot [c1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg), [c2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1012b11ad364ad6c138a25a654108de28de56c5f.1920x1080.jpg), [c3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_0eab901ec5c364aa18225fa608ff9cbcc1f432bf.1920x1080.jpg)
- 스크린샷 관찰: 대화 본문 줄 간격이 약 64px(1080p)로, 위의 64px 폰트 크기와 맞는다. 화면 높이 대비 약 5.9% — observed in screenshot [c1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg)

### Inferences
- Celeste의 «고급감»은 UI를 픽셀 월드와 같은 해상도로 억지로 맞추지 않고, 고해상도 UI를 한 층으로 통째로 분리해 **그 안에서는 일관되게** 고해상도(글자·포트레이트·프레임 장식 모두)로 마감한 데서 나온다. 섞더라도 «한 패널 안에서 해상도가 섞이지 않게» 하는 것이 요점이다.
- 1080p에서 64px 줄 높이 = 640×360 기준으로 약 21px. 질의자 게임(640×360, 2배)에 Celeste식 대화 글자 크기를 옮기면 기준 해상도에서 약 20~22px 줄 높이가 된다(산술 추정).
- 한글 지원 관점: Celeste조차 한글은 손그림 도트가 아니라 Noto Sans CJK KR Medium을 비트맵으로 구워 썼다. 즉 «한글은 상용 TTF를 큰 크기로 구워 쓰는 것»이 상용 선례다.
- Godot 4의 stretch mode `canvas_items`는 텍스트를 최종 창 해상도로 래스터화하므로(Godot 동작에 대한 내 이해, 이 노트에서 출처 확인은 안 함 — 다른 연구자 담당 범위일 것) Celeste식 «매끈한 글자 + 도트 월드»를 비교적 쉽게 낼 수 있다. 다만 그 경우 프레임·아이콘도 같은 계열로 통일해야 Celeste처럼 보인다.

### Gaps
- 메뉴(타이틀·챕터 선택·저널·일시정지·옵션) 화면은 이번에 받은 공식 스크린샷 3장에 없어 직접 관찰하지 못했다. 이 화면들도 고해상도 레이어라는 것은 대화창 관찰로부터의 추정이다.
- 메뉴 제목용 폰트가 Renogare 외에 따로 있는지(예: 큰 제목용 별도 폰트) 확인하지 못했다.
- 공식 개발자(Noel Berry·Maddy Thorson·Pedro Medeiros·Amora Bettany)가 «UI만 고해상도로 둔 이유»를 직접 설명한 글·강연은 찾지 못했다.
- 포트레이트 원본 픽셀 크기·애니메이션 프레임 수는 Everest 위키의 포트레이트 문서가 비어 있어 확인 못 함.

## 2. Celeste — 대화창·포트레이트 프레이밍, 팔레트, 텍스트 효과

### Takeaway
대화창은 화면 폭 거의 전체를 덮는 어두운 단색(따뜻한 검보라·검붉은색) 패널에 장식 모서리와 상단 중앙 장식을 얹고, 정사각 포트레이트를 한쪽 끝에 붙인 구조다. 화자마다 프레임 테마(색·장식)를 바꾸고, 키워드는 색으로, 강조 문장은 크기·흔들림으로 표현한다.

### Cited Findings
- 스크린샷 관찰(Madeline·Granny 장면): 대화창은 x≈105~1815, y≈48~340(1080p) — 화면 폭의 약 89%, 높이의 약 27%. 바탕은 거의 불투명한 어두운 갈보라색(#2A2026 안팎으로 보임)에 옅은 대각선 긁힘 질감. 네 모서리에 회갈색 덩굴/갈고리 모양 장식 브래킷, 위쪽 가운데에 매듭 장식. 포트레이트는 왼쪽 안쪽에 약 216×216px 정사각(테두리 없이 프레임 안에 바로 붙음). 본문은 밝은 회백색(순백 아님), 남은 공간에서 가운데 정렬. 키워드 «Mountain»만 청록(시안) 색. 오른쪽 아래에 작은 흰 ▼ 진행 표시 — observed in screenshot [c1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg)
- 스크린샷 관찰: 같은 프레임이 화면 아래쪽에도 놓인다(장면에 따라 위/아래 배치). 분홍·남색의 채도 높은 배경 위에서도 패널이 불투명해 글자 대비가 유지된다 — observed in screenshot [c2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1012b11ad364ad6c138a25a654108de28de56c5f.1920x1080.jpg)
- 스크린샷 관찰(Oshiro 장면): 화자가 바뀌면 프레임 테마가 바뀐다 — 바탕은 검붉은 마룬, 얇은 구리색 외곽선, 모서리는 구리/청동색 바로크풍 소용돌이 장식. 포트레이트는 오른쪽 끝, ▼ 표시는 포트레이트 왼쪽. 둘째 줄 «Celestial Resort Hotel!»은 첫 줄보다 약 1.4배 크게, 첫 줄 «the world-renowned» 글자들은 기준선이 들쭉날쭉해 글자별 흔들림(웨이브) 효과가 걸린 것으로 보인다 — observed in screenshot [c3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_0eab901ec5c364aa18225fa608ff9cbcc1f432bf.1920x1080.jpg)
- 대화 태그 `[THEO left normal]`이 "Dialogue Portrait and Dialogue Box"를 고른다(즉 포트레이트와 박스가 화자·좌우·표정 단위로 묶여 데이터로 지정됨) — [EverestAPI Wiki: Adding Custom Dialogue](https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue)

### Inferences
- «아마추어 티»를 줄이는 Celeste의 수법: (1) 대화 패널을 불투명한 저채도 어두운 색으로 깔아 화려한 월드와 분리, (2) 본문은 순백 대신 약간 눌린 밝은 회색, (3) 강조는 한 가지 채도 높은 액센트색(시안)만, (4) 장식은 모서리·상단 중앙에만 몰아 넣고 변은 단순한 직선. 장식 밀도를 국소화한 것이 핵심.
- 화자별 프레임 테마는 «UI가 세계관 일부»라는 인상을 준다. TD/마을 경영 게임에서는 진영·건물·보스별로 패널 액센트(모서리 장식·외곽선 색)만 바꾸는 식으로 응용 가능.

### Gaps
- 패널 정확한 불투명도·hex 값은 JPEG 압축 스크린샷에서 눈대중으로 본 값이라 신뢰도 낮음.
- 텍스트 효과(웨이브·흔들림) 종류의 공식 목록(대화 파일 명령어)은 확인하지 못했다.

## 3. Celeste — 메뉴 모션·사운드, 어시스트/옵션 메뉴의 가독성

### Takeaway
Celeste 대화의 «완성도 있는 느낌»은 소리 설계가 크게 떠받친다: 캐릭터마다 FMOD 음성 이벤트를 두고 포트레이트(감정)에 맞춰 음절을 바꾼다. 메뉴는 선택마다 소리 신호가 나고, 어시스트 모드는 일시정지 메뉴에서 언제든 켜며 낱낱의 옵션으로 조절한다.

### Cited Findings
- 대화 음성: 캐릭터별 FMOD 오디오 이벤트 하나가 화자가 말할 때까지 무음 루프, 게임이 현재 포트레이트 정보를 FMOD로 보내면 해당 감정 구간으로 재생 위치를 옮김. 음절은 감정별로 빠른 음절 20·강조 음절 10·문장 끝 10개로 녹음, "No syllable was allowed to play twice in a row, and emphasized syllables had a lower probability of playing." 글자 출력이 끝나면 FMOD에 알려 끝음절을 재생 — [Shacknews (Power Up Audio의 Kevin Regamey 설명 요약)](https://shacknews.com/article/125697/devs-share-insight-into-celestes-dialogue-design-process)
- 메뉴 탐색 시 선택마다 소리 신호가 난다("navigating menus provide an audio cue for each selection") — [Family Gaming Database: Celeste 접근성](https://www.familygamingdatabase.com/accessibility/Celeste) (검색 발췌)
- 어시스트 모드 화면은 보조 기능과 게임 변수 조절을 함께 제공하고, 도입 화면 문구가 «깔보지 않는(unpatronising)» 어조라는 평가 — [Game Accessibility Guidelines: Celeste assist mode](https://gameaccessibilityguidelines.com/celeste-assist-mode)
- 어시스트 모드로 게임 속도·스태미나·공중 대시 수·무적 등을 바꿀 수 있음 — [Game Developer: Celeste's remarkably granular assist options](https://gamedeveloper.com/design/check-out-i-celeste-s-i-remarkably-granular-assist-options) (검색 발췌)

### Inferences
- 메뉴 커서 이동·확정·취소마다 서로 다른 짧은 효과음을 두는 것, 대화 글자 출력에 화자별 «말소리(babble)»를 붙이는 것이 시각 디자인보다 싸게 완성도를 올리는 수단이다.
- 대화 출력 종료 이벤트를 소리 시스템이 받는 구조(«글자 다 나옴 → 끝음절»)처럼 UI 상태와 사운드를 연결하면 «살아 있는 UI» 느낌이 난다.

### Gaps
- 메뉴 항목 선택 시 시각 모션(흔들림·슬라이드·색 변화)에 대한 출처는 찾지 못했다.
- 옵션/어시스트 메뉴의 글자 크기·대비를 수치로 다룬 자료 없음.

## 4. Stardew Valley — 네이티브 도트 UI와 프레임(9-slice) 체계, 줌·UI 배율

### Takeaway
Stardew는 UI까지 전부 도트 스프라이트 시트로 그린다(Cursors·Cursors2·Cursors_1_6·MenuTiles 등). 프레임은 모서리를 원형 그대로 두고 변과 바탕 칸만 늘리는 9-slice식이며, 1.5부터 «월드 줌»과 «UI 배율(75~150%)»을 따로 조절한다.

### Cited Findings
- UI 텍스처 목록: `LooseSprites/Cursors`(대화창·인벤토리 탭·버튼 등 다수 UI), `LooseSprites/Cursors2`(1.5에서 추가된 UI), `LooseSprites/Cursors_1_6`(1.6에서 추가된 UI), `Maps/MenuTiles`(일시정지 메뉴 자산 — 인벤토리 테두리·아이템 칸·장비 슬롯), `LooseSprites/textBox`, `LooseSprites/hoverBox`, `LooseSprites/dialogboxgreen`, `LooseSprites/chatBox`, `LooseSprites/letterBG`, `LooseSprites/JunimoNote`, `LooseSprites/Billboard`, `Minigames/TitleButtons` 등 — [Stardew Modding Wiki: Tutorial: Making a UI Recolor](https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor)
- 프레임 그리는 방식: 대화창은 "the corners are always displayed in full and only certain parts are stretched to fit the screen" — 위/아래 변은 소스 X 274·289 열, 왼쪽 변은 Y 325 행, 오른쪽 변과 구분선은 Y 324 행을 늘림. "The square in `Cursors` is stretched to fill the entire box." 인벤토리도 "The square in `MenuTiles` is stretched to fill the entire box." — [Stardew Modding Wiki: Tutorial: Making a UI Recolor](https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor)
- 바닐라 스프라이트는 대부분 16×16, NPC 월드 스프라이트는 16×32 — [Stardew Valley Forums: Sprite size](https://forums.stardewvalley.net/threads/sprite-size-first-time-modding-sv.7128/latest)
- 게임 아트는 «4픽셀 아트 격자» 기준(True Zoom 모드 설명: 그 격자가 물리 픽셀에 깨끗이 맞으면 포인트 필터링을 씀) — [CurseForge: True Zoom](https://www.curseforge.com/stardewvalley/mods/true-zoom) (검색 발췌, 간접 근거)
- 1.5부터 UI 배율을 줌과 별도로 조절: "The player can scale the UI between 75% and 150%, separately from and alongside the zoom level. That adjusts the size of pixels shown on the screen for UI elements only." — [Modding: Migrate to Stardew Valley 1.5](https://wiki.stardewvalley.net/Modding:Migrate_to_Stardew_Valley_1.5) (검색 발췌)
- 옵션 문서: UI Scale은 5% 단위, 기본 100%, 최소 75%, 최대 150% — [Stardew Valley Wiki: Options](https://stardewvalleywiki.com/Option) (검색 발췌); 옛 개정판엔 최대 200%로 적혀 있어 충돌 — [위키 개정 차이](https://stardewvalleywiki.com/Special:MobileDiff/37852...174041) (검색 발췌; 현재값은 150%가 유력)
- 접근성 블로그: "You can scale the user interface and the background independently up to 150% and 200% zoom." — [Nic Chan, Modding Stardew Valley for accessibility](https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/)
- 버그 보고: 박물관·건물 배치 표시가 줌이 아닌 UI 배율을 따라 어긋남, 두 값이 같으면 해결 — [Stardew Valley Forums: Indicators off-center when UI adjusted 1.5](https://forums.stardewvalley.net/threads/5407/)

### Inferences
- Stardew 방식은 질의자 게임(640×360, 정수배, nearest)과 같은 계열이다: UI도 월드와 같은 픽셀 격자에 있는 스프라이트로 그리고, 프레임은 «모서리 고정 + 변·바탕 늘리기». Godot의 `NinePatchRect`(또는 `StyleBoxTexture`)로 그대로 재현 가능하다. 변을 «늘리기(stretch)»로 둘 때는 변 소스가 1px 폭 반복 무늬여야 깨지지 않는다(Stardew가 단일 열/행만 늘리는 이유로 보임 — 추정).
- UI 배율을 월드 줌과 분리한 것은 «UI 글자·아이콘은 월드보다 크게 보여야 읽힌다»는 요구를 반영한다. 640×360 단일 캔버스 게임에서는 HUD를 별도 `CanvasLayer`로 두고, 필요하면 UI만 다른 정수배로 키우는 구조가 대응책이 될 수 있다(추정; Godot 동작은 별도 확인 필요).
- 같은 화면에 서로 다른 배율의 픽셀이 섞이면(UI 배율 ≠ 줌) 배치 표시가 어긋나는 버그가 생겼다 — 좌표계를 둘로 나누면 위치 변환을 반드시 한곳에 모아야 한다.

### Gaps
- `IClickableMenu.drawTextureBox`/`Game1.menuTexture`의 정확한 소스 사각형(흔히 알려진 (0,256,60,60) 등)은 공식 문서로 확인하지 못했다(위키 403, 검색 결과 없음).
- Stardew 메뉴 프레임의 실제 모양(이중 테두리·나무 질감 등)과 인벤토리 칸 크기·간격을 스크린샷으로 확인하지 못했다(받은 3장이 UI 없는 풍경 샷).
- `Game1.pixelZoom = 4`라는 상수는 출처로 확인하지 못했다(위 «4픽셀 격자»는 간접 근거).

## 5. Stardew Valley — 폰트(SpriteText·SmallFont·대화 폰트), 그림자, 한국어 처리

### Takeaway
라틴 문자 기준 Stardew는 폰트 셋을 쓴다: 손으로 그린 비트맵 «굵은 대화 폰트»(`LooseSprites/font_bold`, 제목·대화), XNB SpriteFont인 «중간» 폰트(SpriteFont1, 아이템 이름·퀘스트·옵션)와 «작은» 폰트(SmallFont, 설명·툴팁). 본문 글자색은 순흑이 아닌 짙은 자주빛 검정(34,17,34)이고 그림자는 주황 갈색(206,156,95)이다. 한국어 등 CJK는 font_bold 대신 BMFont로 만든 별도 대화 폰트를 쓰고 «FontPixelZoom»으로 크기를 맞춘다.

### Cited Findings
- 폰트 구분: Small — "Used for item descriptions, tooltips." Medium — "Bigger one. Used for item names, quest paragraphs, options." Dialogue — "Stored in `Content/LooseSprites/font_bold`. Used for titles and dialogues." — [Becks723 FontSettings README](https://github.com/Becks723/StardewMods/blob/master/FontSettings/README.md)
- SpriteFont1·SmallFont는 SpriteFont(교체만 가능, "No ability to edit or extend, only to replace wholesale using an XNB"), 굵은(대화) 폰트는 "Relies on integer sprite indexes on a single shared texture"(= 한 장 텍스처의 글리프 스프라이트 시트, 즉 손그림 비트맵 폰트) — [FontSmasher (GitHub)](https://github.com/ichortower/FontSmasher)
- CJK: "the BmFont type used for those languages' dialogue fonts is not supported"(FontSmasher 기준), CJK의 SpriteFont1·SmallFont는 지원되며 "their default sprite fonts are very different from the latin ones" — [FontSmasher (GitHub)](https://github.com/ichortower/FontSmasher)
- 다른 언어에는 font_bold.xnb 같은 파일이 없고 "a native font created by BMfont application"을 쓴다는 모더 관찰 — [Playstarbound 포럼: Font_bold.xnb recreate?](https://community.playstarbound.com/threads/font_bold-xnb-recreate.140480/)
- 사용자 언어 데이터 필드: `FontPixelZoom` = 폰트 크기에 곱하는 배율, `FontApplyYOffset` = 중국어·일본어처럼 큰 글자 언어를 맞추려 폰트를 4px(× FontPixelZoom) 위로 올림, `SmallFontLineSpacing` = smallFont 줄 간격, 기본 26 — [Stardew Valley Wiki: Modding:Custom languages](https://stardewvalleywiki.com/Modding:Custom_languages) (검색 발췌, 1.5.5+)
- 게임 폰트 객체로 SpriteFont·smallFont·TinyFont가 언급됨(언어 모드가 하나만 바꾸면 깨진다는 토론) — [Stardew Valley Wiki: Modding talk:Custom languages](https://stardewvalleywiki.com/Modding_talk:Custom_languages) (검색 발췌)
- 기본 글자색(모드 설정 기본값으로 노출된 게임 값): TextColor R34 G17 B34(#221122, "game most common text color"), TextColorDialogue R86 G22 B12(#56160C), ShadowColorGame1 R206 G156 B95(#CE9C5F, "most common text shadow color 1"), ShadowColorUtility R221 G148 B84(#DD9454) — [Becks723 FontSettings README](https://github.com/Becks723/StardewMods/blob/master/FontSettings/README.md)
- 플레이어가 글자 그림자를 «주황색»으로 인식하고 바꾸고 싶어 함("change the drop shadow of the text from that orange"), 단순 스프라이트 교체로는 못 바꾸고 코드 모드가 필요 — [Stardew Valley Forums: Change font dropshadow in mod?](https://forums.stardewvalley.net/threads/change-font-dropshadow-in-mod.14454)
- 폰트 교체 수요: 폰트 설정 모드 [Font Settings (Nexus 12467)](https://www.nexusmods.com/stardewvalley/mods/12467), [Cobalt Sans (Font Replacement) (Nexus 38902)](https://www.nexusmods.com/stardewvalley/mods/38902)가 존재(검색 결과 제목 기준)

### Inferences
- «순흑 글자 + 무채색 그림자» 대신 «짙은 자주빛 검정 글자 + 따뜻한 주황갈색 그림자»를 쓴 것이 Stardew UI가 크림·나무색 패널과 어울리는 핵심 이유로 보인다. 그림자 색이 패널 바탕보다 약간 어두운 같은 계열 색이라, 그림자가 «검은 테두리»가 아니라 «양각/음각 질감»처럼 읽힌다.
- 용도별로 폰트 크기 3단(굵은 제목/대화 · 중간 이름/옵션 · 작은 설명/툴팁)을 고정한 위계가 정보 밀도 높은 화면을 정리한다. 질의자 게임의 HUD(골드·웨이브·유닛 스탯·툴팁)에도 3단 이하로 크기를 제한하는 것이 응용점.
- 한국어: Stardew도 한글은 손그림 도트가 아니라 BMFont로 만든 폰트에 배율(FontPixelZoom)을 곱해 라틴 도트 폰트와 크기를 맞춘다. «라틴은 도트 폰트, 한글은 별도 폰트 + 크기/오프셋 보정»이 상용 선례이며, 언어별 줄 간격·세로 오프셋 손잡이를 따로 두는 설계를 시사한다.

### Gaps
- 한국어판이 쓰는 실제 폰트 이름·원본 크기·FontPixelZoom 값은 확인하지 못했다(위키 본문 403).
- 1.6에서 폰트 체계가 바뀌었는지 확인하지 못했다.
- 코드상의 정확한 필드명(`Game1.textColor`, `Game1.textShadowColor` 등)은 공식 문서로 확인하지 못했다 — 위 색 값은 모드 README의 «게임 기본값» 표기에 의존(신뢰도 중상).
- 라틴 굵은 폰트 글리프의 원본 픽셀 크기(약 8px 폭이라는 포럼 언급이 검색 요약에 있었으나 어느 글인지 특정 못 해 제외).

## 6. 두 게임의 UI 팔레트 — 월드 팔레트와의 연결, 액센트색, 반투명·그림자·툴팁·인벤토리 칸

### Takeaway
Celeste는 채도 높은 월드 위에 저채도 어두운 불투명 패널 + 한 가지 액센트색(시안)으로 대비를 확보한다. Stardew는 따뜻한 노랑-주황·크림·나무 갈색 계열 UI를 쓰고 글자색·그림자까지 그 계열로 맞췄는데, 이 «밝은 노랑-주황 UI»가 일부 플레이어에게 눈 피로를 준다는 비판이 있어 다크 UI 모드가 인기다.

### Cited Findings
- Stardew 기본 UI를 "the default bright yellow-orange interface"로 묘사, 밝은 팔레트가 일부에게 눈 피로·편두통을 준다는 지적, 대안으로 «Dark User Interface» 모드(UI 다크 모드)와 갈색·흰색 UI 모드 소개 — [Nic Chan, Modding Stardew Valley for accessibility](https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/)
- 같은 글: 바닐라는 색으로 작물 숙성도를 표시해 색각 이상 플레이어가 구분하기 어렵고, 오브젝트 상태 구분이 어렵다는 지적 — [Nic Chan](https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/)
- UI 리컬러는 플레이어가 게임을 꾸미는 대표 방식이라는 모딩 위키 서술(=UI 팔레트 교체 수요가 큼) — [Stardew Modding Wiki: Tutorial: Making a UI Recolor](https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor) (검색 발췌)
- 툴팁·호버 박스는 별도 텍스처 `LooseSprites/hoverBox`, 인벤토리 칸·테두리는 `Maps/MenuTiles` — [Stardew Modding Wiki: Tutorial: Making a UI Recolor](https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor)
- Stardew 글자·그림자 색: #221122 / #CE9C5F / #DD9454, 대화 글자 #56160C — [Becks723 FontSettings README](https://github.com/Becks723/StardewMods/blob/master/FontSettings/README.md)
- Celeste 패널: 어두운 갈보라(기본)·검붉은 마룬(호텔 주인) 불투명 패널, 회백색 본문, 시안 키워드 — observed in screenshot [c1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg), [c3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_0eab901ec5c364aa18225fa608ff9cbcc1f432bf.1920x1080.jpg)
- Stardew 월드 팔레트 관찰: 채도 높은 노랑 흙길·초록 풀·주황 지붕, 실내는 따뜻한 나무 갈색과 주황 테두리 벽 — observed in screenshot [s1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_b887651a93b0525739049eb4194f633de2df75be.1920x1080.jpg), [s3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_6422d297347258086b389e3d5d9c0e0c698312e4.1920x1080.jpg)

### Inferences
- 두 게임 모두 UI 글자를 «순흑/순백»으로 두지 않았다(Stardew #221122, Celeste 회백색). 순색 대신 팔레트 쪽으로 기운 무채색이 상용 마감의 공통점.
- 두 접근은 정반대다: Celeste = «월드와 대비되는 어두운 UI», Stardew = «월드와 같은 계열의 따뜻한 UI». 정보 밀도 높은 TD/경영 HUD에서는 Stardew식 동색 계열이 화면과 섞여 정보가 묻힐 위험이 있고(Stardew조차 다크 UI 모드 수요), Celeste식 어두운 저채도 패널이 가독성 쪽으로 안전하다는 추론이 가능하다.
- 상태 표시를 색 하나에만 맡기면 색각 이상 사용자 비판이 나온다 → 아이콘·모양 보조 표시를 같이 둘 것.

### Gaps
- Stardew 메뉴 패널·툴팁의 실제 RGB, 반투명 사용 여부, 패널 뒤 그림자 유무, 인벤토리 칸 크기·간격을 화면이나 문서로 확인하지 못했다.
- Celeste 일시정지 메뉴 뒤 배경 어둡게 하기(dim) 정도·반투명 여부 확인 못 함.
- 두 게임의 UI 팔레트 색 수(몇 색으로 제한했는지)에 대한 개발자 진술 없음.

## 7. 알려진 비판과 인기 UI 모드가 드러내는 것

### Takeaway
Stardew에 대한 대표 UI 불만은 «작은 글자(특히 인벤토리 수량 숫자)가 최대 UI 배율에서도 안 읽힌다»와 «밝은 노랑-주황 UI가 눈이 피곤하다»이며, 정보 표시 보강 모드(UI Info Suite 2)가 널리 쓰인다. Celeste UI에 대한 비판은 찾지 못했고, 접근성 쪽은 오히려 칭찬받는다.

### Cited Findings
- PC판 인벤토리 아이템 수량 숫자가 "too small, even with the largest UI scale"이라는 2021년 글, 2024년에도 "Same problem here" 동조, 개발자 응답 없음 — [Steam 토론](https://steamcommunity.com/app/413150/discussions/0/5283252978685636205)
- UI Info Suite 2: "helpful information about things around you designed to help you be aware of what's going on without feeling like you're cheating" — [UIInfoSuite2 (GitHub)](https://github.com/tqdv/UIInfoSuite2) (검색 발췌)
- 다크 UI 모드 수요(Dark User Interface, 다크 테마 모드 등) — [Nic Chan](https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/); 1.6 대응 다크 테마 — [Nexus mods/24090](https://www.nexusmods.com/stardewvalley/mods/24090) (검색 발췌, 모드 이름 미확인)
- 글자 그림자 색을 바꾸려면 콘텐츠 교체가 아니라 코드 모드가 필요 — [Stardew Valley Forums](https://forums.stardewvalley.net/threads/change-font-dropshadow-in-mod.14454)
- 바닐라 SpriteFont는 편집·확장 불가, 통째로 교체만 가능 — [FontSmasher (GitHub)](https://github.com/ichortower/FontSmasher)
- Celeste 접근성: 어시스트 모드 도입 화면 문구가 깔보지 않는 어조로 칭찬받음 — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/celeste-assist-mode)

### Inferences
- «가장 작은 글자(수량 숫자·툴팁)»가 완성도·가독성 불만의 첫 표적이다. 도트 게임은 아이콘 위 숫자를 아주 작은 도트 숫자로 넣기 쉬운데, 상용 대작도 여기서 비판받았다 → 최소 글자 크기 하한을 정하고, 숫자 뒤에 대비용 외곽선/그림자를 넣는 것이 체크리스트 항목이 될 수 있다.
- 색(글자색·그림자색)·폰트를 코드에 하드코딩하면 나중에 바꾸기 어렵다(Stardew 모더의 불편) → 테마 리소스/상수 한곳에 모아 두는 설계(Godot `Theme`)가 유지보수와 접근성(다크 모드·큰 글자) 대응에 유리.
- 정보 보강 모드의 인기는 «필요한 정보가 화면에 없다»는 신호다. TD/경영 게임 HUD에서는 무엇을 상시 표시하고 무엇을 툴팁에 넣을지 위계를 정하는 것이 시각 마감만큼 중요.

### Gaps
- ConcernedApe(Eric Barone)가 UI 디자인 의도·참고 대상을 직접 밝힌 인터뷰는 찾지 못했다.
- Celeste UI에 대한 비평가·플레이어의 구체적 칭찬/비판(예: 메뉴 가독성) 출처는 찾지 못했다.
- Game UI Database(gameuidatabase.com)·Interface In Game은 이미지 위주라 이번 텍스트 조사에서 활용하지 못했다.
