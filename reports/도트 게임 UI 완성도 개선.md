# 도트 게임 UI 완성도 개선

상용 도트 게임의 UI가 '완성돼' 보이는 이유는 특정 화풍이 아니라 **한 화면 안에서 규칙이 깨지지 않는 데** 있다.

**상용작에서 보이는 것.** 이번에 분석한 다섯 게임은 Dave the Diver(데이브 더 다이버), Eastward(이스트워드), Celeste(셀레스트), Stardew Valley(스타듀밸리), Into the Breach(인투 더 브리치)다. 이 게임들은 UI 해상도를 두 갈래로 다룬다. Stardew Valley처럼 UI까지 도트 스프라이트로 그리거나(배율은 월드 줌과 따로 두고, 5% 단위라 정수배가 아닌 설정도 있다), Celeste·Dave the Diver·Into the Breach·Eastward처럼 고해상도 UI를 의도적으로 얹는다. 얹는 쪽도 그 층 안에서는 해상도와 글꼴 역할을 고정한다. 다섯 중 넷(Stardew Valley 예외)은 정보 패널이 어둡다(반투명은 선택 사항이다). 글자는 순백·순흑을 피한다. 고채도 색은 뜻이 있는 곳에만 쓴다. 테두리·모서리 부품의 규칙은 한 게임 안에서 하나다(화자·상황별 변형도 같은 규칙 안에서 바꾼다). 한글 처리가 드러난 사례(Celeste 위키 안내, Stardew Valley 디컴파일, 보조 사례 Loop Hero의 파일 목록)는 한글에 별도 글꼴을 둔다.

**아마추어 티의 원인.** 그 반대에서 난다. 한 화면에 픽셀 크기가 여럿 섞이고(믹셀), 엔진 기본 글꼴과 OS 대체 글꼴이 보이고, 색이 많은데 뜻이 없고, 여백이 들쭉날쭉하다.

**td-proj의 빈곳과 고칠 순서.** 요청자 프로젝트(td-proj, Godot 4.7, 640×360 `canvas_items` 정수배) 코드와 대조하면 기반 설정(정수배 창, Nearest, 도트 글꼴 가져오기 설정)은 이미 상용 수준이다. 비어 있는 곳은 다음 다섯이다. HUD 글자는 Godot 기본 Open Sans와 OS 한글 대체 글꼴로 그려진다. 아이콘은 1배·1.6배·2배·비정수 축소가 섞여 있다. 패널은 1px `StyleBoxFlat` 한 종류이고 명도 대비가 1.2~1.7:1이다. 흩어진 색이 32종이다. 화면 끝 여백은 0~4px이다. 고칠 순서는 **글꼴 전략 결정 → HUD 도트 밀도 통일 → 색 상수 정리 → 테두리 문법 결정과 프레임 마감 → 여백 토큰**을 권한다. 다만 글꼴은 S30과 얽혀 있어(대조 참고) 선택지로 제시한다. 이 문제들과 «학생 작품 같다»는 피드백 사이의 인과는 검증하지 않았다.

> 단위: **기준 px** = 640×360 좌표의 1px. 정수배 창에서 1 기준 px는 720p에서 화면 2px, 1080p에서 3px, 1440p에서 4px, 4K에서 6px다. 게임 스크린숏의 색값은 JPEG 픽셀을 찍은 근사값이다.
>
> 고친 판: 2026-11-15 Gemini 검토의 지적 16개를 하나씩 검증해 11개를 일부 반영했다(기각 5). 판정 표는 연구 노트 `gemini_review_verdicts.md`에 있다.

## 1부. 레퍼런스 분석: 다섯 게임은 해상도보다 «규칙»을 통일한다

네 예시 게임에 하나를 더했다. 더한 게임은 **Into the Breach**다. 타워 디펜스와 가장 가까운 «턴제 전략 + 정보 밀도 최상» HUD이고, 개발자가 UI 원칙을 직접 밝혔기 때문이다. 보조 사례인 Loop Hero(자원·인벤토리를 한 화면에서 관리하는 도트 게임)와 CrossCode(568×320 액션 RPG, 9-slice·전환 구현을 블로그로 공개)는 분석 대상이 아니라 근거로만 쓴다. Shardpunk·Return 같은 인디 개발 일지는 2부·3부의 근거로 쓴다. 다섯 게임의 글꼴 이름·내부 해상도·팔레트 색 수는 Celeste·Stardew Valley와 Into the Breach 일부를 빼면 공개 자료로 확인되지 않는다. 확인 안 된 것은 그렇다고 적었다.

### Dave the Diver: 고해상도 HUD에 도트풍 글꼴 하나로 목소리를 맞춘다

**렌더링.** 식당 영업 HUD는 월드 픽셀 격자에 묶이지 않은 고해상도 오버레이다. 공식 Steam 스크린숏(실제 파일 1280×720)에서 금액 패널의 올리브색 테두리는 화면 1~2px로 가늘다. 시계는 매끈한 원형 다이얼이다 ([D1 스크린숏](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)). 그런데 HUD 글자는 **거의 모두 각지고 굵은 도트풍 디스플레이 글꼴**이다. "6,000", 퀘스트 제목, "#bancho_sushi", "0/500", "Tue 10. 25", "Time Skip", 하단 탭 라벨, 월드 위 손님 반응 "This looks good!"까지 그렇다. 매끈한 산세리프는 퀘스트 체크리스트 두 줄뿐이다. 역할 분담은 «HUD의 기본 목소리는 도트풍, 긴 문장만 산세리프»다. 여기서 «도트풍»은 월드 픽셀 격자에 묶이지 않은 HUD 위의 각진 디스플레이 글꼴을 말한다. 청각장애 플레이어용 접근성 리뷰는 이 게임의 글이 «pixelated font style»을 버려 읽기 쉽다고 평했다 ([Game Accessibility Nexus](https://www.gameaccessibilitynexus.com/blog/2024/02/13/dave-the-diver-deaf-game-review)). 리뷰가 말한 «pixelated»는 격자에 맞춘 도트 글꼴을 뜻하는 것으로 읽히므로 위 관찰과 어긋나지 않는다(추론, 메뉴 화면은 보지 못했다). 글꼴 이름은 공개 자료로 확인되지 않는다.

**팔레트.** 바탕은 무채색에 가까운 어둠이다. 금액 패널 안은 RGB (4,4,4) 수준의 거의 순흑이다. 하단 탭 바는 (21,0,5)~(26,0,13)의 검붉은 검정이다. 그 위에 금색 동전, 노랑·시안 퀘스트 제목, 식당 네온과 같은 마젠타 프로필 테두리, 노랑 알약 버튼, 빨간 «N» 배지가 얹힌다. 색 수가 적은 것은 아니다. 같은 화면에 청록 조리 진행 바(바탕 ≈ 1,72,94), 파랑 시계 구간, 주황 게이지, 분홍→주황 그라데이션 폰 아이콘도 있다 ([D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)). 핵심은 색 개수를 줄이는 것이 아니라 **배치**다. 바탕은 어둡게 누르고, 색은 강조에 쓰며, 그 색은 장면 테마에서 뽑는다.

**테두리·반투명.** 사각 패널에는 베벨·이중 테두리·두꺼운 그림자가 없다. 테두리는 1선이고, 개성은 형태로 낸다. 금액 패널은 오른쪽 변만 기운 사다리꼴이고, 그 밖에 둥근 모서리와 알약 모양이 있다. 예외는 금속 베젤 음영을 그린 시계 하나다. 테두리 있는 금액·프로필 패널은 불투명한 검정이다. 테두리 없는 날짜 알약과 넓은 퀘스트 패널(짙은 갈색 ≈ 38~64, 20~40, 13~14)은 반투명이라 뒤의 등불이 비친다(스크린숏 한 장에서 본 것) ([D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)).

**배치·메뉴.** 정보는 상단 띠, 우측 가장자리, 하단 탭 바에 둔다. 카운터와 손님이 있는 중앙에는 대상 위에 붙는 주문 말풍선과 버튼 프롬프트만 둔다. 선택한 탭만 밝고 나머지는 한 톤 어둡다. 메뉴 전체는 앱 19개가 든 «스마트폰» 은유로 묶었다. 이 은유가 메뉴 탐색을 배우는 부담을 덜어 준다는 분석이 있다 ([Naavik](https://naavik.co/deep-dives/dave-the-diver-nexons-approach-to-fun-first/)). UI 크기에 대한 비판은 2부 10에서 다룬다.

**가져올 점.** 고해상도 HUD를 쓰더라도 **«짧은 라벨·숫자 = 도트풍 글꼴, 긴 문장 = 매끈한 글꼴»처럼 글꼴 역할을 고정**하고, 모든 패널에 같은 선 굵기와 같은 모서리 문법을 반복한다. 장면이 화려할수록 패널 바탕은 거의 검게 누른다. 그리고 상용 히트작도 UI 크기 때문에 비판받았다(2부 10 참고).

### Eastward: 상황에 따라 HUD를 걷어 내고, HUD 띠에 전용 질감을 입힌다

**렌더링.** Eastward의 HUD도 월드 격자에 붙어 있지 않다. 재화 숫자 0569·0388과 하트 10개는 가장자리가 매끈하다. 재화 띠와 Ammo/Bomb 슬래브에는 바탕·아이콘·숫자 전체에 LCD 화면 같은 잔 격자 질감이 깔려 있고, 이 격자는 띠 바깥 월드에는 없다 ([E2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg), [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)). 매체 기사는 이 게임이 작은 입자로 계단 현상을 줄였고 «대화창 글자에도 픽셀 디자인의 공을 들였다»고 전한다. 팀이 CRT 필터 등을 갖춘 자체 엔진 Gii를 썼다고 발표에서 말했다는 내용도 같은 기사에 있다 ([Sohu/七点GAME](https://www.sohu.com/a/511158455_121119410)). CRT 기능 자체는 독립 출처로 확인되지 않았다. HUD 띠에만 LCD 격자 질감을 깔아 HUD를 하나의 «화면 장치»처럼 보이게 한 것으로 읽힌다(추론). 월드 쪽(등불 등)에는 색수차가 보이지만 비네팅은 장면 조명과 구분되지 않았고, 후처리가 HUD까지 덮어 둘을 묶는지는 스크린숏으로 확인되지 않았다.

**팔레트·글꼴.** HUD 슬래브는 어두운 남색 반투명((20,28,41)~(34,40,56))이다. 라벨 "Ammo"·"Bomb"은 연한 크림색이고 수치 26·10은 노랑이다. 밑줄은 연노랑(≈ 252,234,150)에 짙은 빨강(≈ 136,0,9) 구간이 붙은 두 색 선이다. 찬 하트는 주황빨강(≈ 251,77,8)이다. 빈 하트는 바탕과 거의 같은 짙은 남색(≈ 15,26,44)에 밝은 외곽선을 둔 것이다. 재화 카운터 "0569"는 **앞자리 0만 어둡게**((71,37,51) 부근) 하고 유효 숫자만 밝은 주황으로 둔다 ([E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)). 라벨 글꼴은 확대하면 계단 없는 가는 획의 스퀘어형, 곧 디지털 계기판풍이다. 글꼴 이름은 미확인이다. 조작 캐릭터에 따라 강조색이 바뀌는 것처럼 보이지만, 스크린숏 두 장을 비교해 얻은 추정일 뿐이다.

**테두리·반투명·상황별 HUD.** HUD에는 프레임이 없다. 테두리 없는 슬래브에 밑줄을 긋고, 에너지 게이지는 가는 흰 선의 아이소메트릭 상자로 그린다. 2019년 12월 한정 시연 체험기는 이 게임이 «초상 일러스트 + 하단 대화창» 대신 캐릭터 애니메이션과 만화식 대화창을 쓰며, 그래서 HUD가 간결해야 한다고 썼다. 같은 글에 따르면 마을에서는 생명력 바와 우상단 재화만 보이고, 전투 가능한 맵에 들어가야 전체 상태 바가 뜬다 ([TapTap 체험기](https://www.taptap.cn/moment/15230291522095848)). 출시판 컷신은 1920×1080 화면의 위 79px·아래 80px(각 약 7.3~7.4%)을 검은 띠로 덮고 HUD를 숨긴다 ([E1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_2c7516dbcfba035a359a2eb7257356809a3f5eaa.1920x1080.jpg)). 640×360으로 환산하면 위아래 약 26~27 기준 px다.

**가져올 점.** **상황별 HUD**가 첫째다. 안전한 곳에서는 최소한만 보이고, 전투에서만 전부 보인다(2019 데모 체험기 기준, 출시판 마을 화면은 보지 못했다). 둘째는 앞자리 0을 어둡게 한 **4자리 카운터**다(스크린숏 두 장에서 본 것이고, 자릿수가 고정인지는 추정이다). 자릿수가 고정이라면 값이 바뀌어도 레이아웃이 흔들리지 않는다. 셋째는 «비어 있음»을 새 회색이 아니라 바탕 계열의 어둠 + 외곽선으로 그려 색 수를 늘리지 않는 것이다.

### Celeste: 320×180 월드 위에 1080p 대화창을 한 층으로 올린다

**렌더링.** Celeste의 화면 해상도는 320×180이다 ([Noel Berry](https://www.noelberry.ca/posts/celeste_lighting)). 평상시 1080p 스크린숏에서 아트 픽셀 하나는 정확히 6×6이고, 컷신 줌에서는 12×12다. 대화 글자는 안티에일리어싱된 산세리프이고 포트레이트는 매끈한 선의 일러스트다 ([c1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg)). 모딩 위키 원문에 따르면 HUD 엔티티는 «HudRenderer, a HiresRenderer»가 그린다. 아틀라스도 «Gui atlas, for high-resolution overworld and UI textures»와 포트레이트 아틀라스를 따로 둔다 ([EverestAPI Wiki](https://github.com/EverestAPI/Resources/wiki)). 픽셀 월드 위에 고해상도 UI를 **층째로** 분리해 올린 구조다.

**글꼴.** 영어 글꼴은 Renogare를 64px로 구운 BMFont(`renogare64.fnt`, `FONT=Renogare,64`)다. 같은 위키는 바닐라 글꼴에 글자를 덧붙일 때 쓸 원본으로 **한국어 Noto Sans CJK KR Medium**을 안내하고, 중국어·일본어도 Noto Sans CJK 계열을 안내한다 ([EverestAPI Wiki: Adding Custom Dialogue](https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue)). 바닐라 `korean.fnt`가 같은 원본에서 구워졌다는 것은 이 안내에서 나온 강한 추론이다. 1080p에서 대화 줄 간격은 약 64px이고, 640×360으로 환산하면 약 21 기준 px다.

**패널·팔레트·장식.** 대화창은 x≈100~1815, y≈48~340으로 **화면 폭 89%·높이 27%**를 덮는다. 포트레이트는 정확히 216×216이다. 바탕은 RGB (31,20,26) ≈ #1F141A의 불투명한 검보라다. 본문에서 가장 밝은 픽셀은 (224,222,225)로, 순백이 아닌 회백색이다. 키워드 «Mountain»만 (130,240,255) 시안이다 ([c1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg)). 화자가 바뀌면 프레임도 바뀐다. 호텔 주인 Oshiro 장면은 검붉은 마룬 (22~32,0,0) 바탕에 구리색 소용돌이 모서리다. 이 장면에서는 패널 바로 바깥의 파란 창문 (10,65,130)이 안쪽에 전혀 비치지 않아 불투명함이 확인된다 ([c3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_0eab901ec5c364aa18225fa608ff9cbcc1f432bf.1920x1080.jpg)). 화자별 대화창 그림은 `Portraits.xml`의 포트레이트마다 `textbox` 속성으로 지정한다. 즉 데이터로 고른다 ([EverestAPI Wiki: Custom Portraits](https://github.com/EverestAPI/Resources/wiki/Custom-Portraits)). 장식은 네 모서리와 위쪽 가운데에 몰려 있고, 변은 단순하다.

**가져올 점.** 고해상도 UI를 고른다면 **글자·포트레이트·프레임 장식까지 층 전체를 고해상도로 마감**한다. 한 패널 안에 해상도가 섞이면 안 된다. 바탕은 어두운 불투명 패널, 본문은 회백색, 강조는 한 색으로 하고 장식은 모서리에 모은다.

### Stardew Valley: UI까지 도트로 그리고, 단면 1px 띠만 늘이는 9-slice를 쓴다

**렌더링·프레임.** Stardew Valley는 UI도 도트 스프라이트 시트로 그린다. 대화창·버튼은 `LooseSprites/Cursors`에 있고(1.5·1.6에서 더한 것은 `Cursors2`·`Cursors_1_6`), 인벤토리 테두리·칸·장비 슬롯은 `Maps/MenuTiles`에 있다 ([Stardew Modding Wiki](https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor)). 비공식 디컴파일 코드에는 `pixelZoom = 4` 상수가 있다. 대화창을 그리는 `DialogueBox.drawBox`는 모서리 넷을 4배 고정 크기로 그린다. 변은 폭 1px짜리 열·행만 늘인다. 위 변 (275,313,1,6), 아래 변 (275,328,1,8), 왼쪽 (264,325,8,1), 오른쪽 (293,324,7,1)이다. 바탕은 16×16 사각형 하나를 늘인다 ([1.6 디컴파일](https://github.com/Dannode36/StardewValleyDecompiled), [1.5 DialogueBox.cs](https://github.com/veywrn/StardewValley/blob/master/StardewValley/Menus/DialogueBox.cs)). 메뉴 상자와 툴팁은 `MenuTiles`의 (0,256,60,60)을 `drawTextureBox`로 그린다 ([1.6 디컴파일 IClickableMenu.cs](https://github.com/Dannode36/StardewValleyDecompiled)). 단면이 일정한 1px 띠를 늘이면 왜곡이 생길 수 없다. **도트 9-slice의 교과서**다. 1.5부터 UI 배율을 월드 줌과 따로 75~150%(5% 단위)로 조절할 수 있다 ([위키 미러](https://github.com/nevir/kims-song/blob/main/docs/wiki/Modder_Guide/Game_Fundamentals.md), [OptionsPage.cs](https://github.com/veywrn/StardewValley/blob/master/StardewValley/Menus/OptionsPage.cs)). 1.5 디컴파일에서 UI는 «창 크기 ÷ UI 배율» 크기의 렌더 타깃에 그린 뒤 창 크기로 키운다([Game1.cs](https://github.com/veywrn/StardewValley/blob/master/StardewValley/Game1.cs) 2473~2475행). 그래서 UI 아트 1px은 화면 4 × UI 배율 px이고(110%면 4.4), 75·100·125·150%가 아니면 정수배가 아니다. UI와 월드의 도트 크기가 같은 것도 두 배율이 같을 때뿐이다.

**글꼴·글자색.** 글자색은 순흑이 아니라 짙은 자주빛 검정 (34,17,34) = #221122이다. 그림자는 주황 갈색 (206,156,95) = #CE9C5F이고, `Utility.drawTextWithShadow`는 (221,148,84)를 쓴다. 모두 코드 상수다(1.5 디컴파일 [Game1.cs](https://github.com/veywrn/StardewValley/blob/master/StardewValley/Game1.cs)·Utility.cs). 그림자가 크림·나무색 패널과 같은 계열이라 «검은 테두리»가 아니라 양각처럼 읽힌다(추론). 대화와 제목은 손으로 그린 비트맵 글꼴 SpriteText(`font_bold`)가 맡는다. 이 글꼴은 대체로 8px 균일 폭 격자다 ([Stardew 포럼](https://forums.stardewvalley.net/threads/converting-dialog-font-to-a-spritefont.20446)). 나머지는 SpriteFont 넷(`dialogueFont` = SpriteFont1, `smallFont`, `tinyFont`, `tinyFontBorder`)이 맡는다. 인벤토리 수량 숫자는 글꼴이 아니라 스프라이트 숫자(`drawTinyDigits`)다. 한국어는 라틴용 손그림 SpriteText 대신 별도 BmFont `Fonts\Korean`을 쓴다(그 글꼴의 이름과 도트 여부는 확인하지 못했다). `SpriteText.fontPixelZoom`을 1.5(라틴은 3)로 두며, `smallFont` 줄 간격을 26에서 42(+16)로 늘린다(1.5 디컴파일 [SpriteText.cs](https://github.com/veywrn/StardewValley/blob/master/StardewValley/BellsAndWhistles/SpriteText.cs)·Game1.cs). 즉 별도 글꼴에 배율과 줄 간격 보정을 따로 둔다. 이 배율은 각 글꼴 원본에 곱하는 값이라, 1.5와 3을 화면 글자 크기의 비율로 읽으면 안 된다. 라틴 SpriteText는 칸이 8×16이라 3배면 높이 48px이다. 일본어는 `Fonts\Japanese`(`Japanese.fnt`, size 24·lineHeight 24)에 배율 1.75를 곱한다. 한국어 `Fonts\Korean`의 원본 크기는 확인하지 못했다.

**팔레트·반투명·비판.** 공식 Steam 스크린숏 16장 가운데 UI가 보이는 것은 대화창 두 장뿐이다(인벤토리 화면은 없다). 대화창 글자 칸은 위아래 (236,166,96)에서 가운데 (252,197,114)로 밝아지는 크림·주황 세로 그라데이션이고(HSV 명도 93~99%), 초상 쪽 나무 판은 (216,130,57), 바깥 테두리는 짙은 갈색 (128,48,0) 줄과 밝은 주황 (248,144,0~8) 줄이다. 영어 대화 글자는 ≈(80~88,16~24,8)의 적갈색이다. 뒤가 밝은 모래밭인 장면과 어두운 방인 장면에서 글자 칸 값이 같으니 대화창은 불투명이다 ([s4](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_10628b4a811c0a925a1433d4323f78c7017dbbe4.1920x1080.jpg), [s7](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_30aeedc47e731232ade368831a598d6545346f70.1920x1080.jpg)). 게임 메뉴는 기본 설정(`showMenuBackground` 끔)에서 뒤 월드 위에 `Color.Black * 0.4`, 곧 검정 40%를 깔고 그 위에 상자를 그린다(1.5 디컴파일 [GameMenu.cs](https://github.com/veywrn/StardewValley/blob/master/StardewValley/Menus/GameMenu.cs) 456~459행, Options.cs 587행). 인벤토리·툴팁 패널의 RGB와 프레임의 광원 방향은 확인하지 못했다. 따뜻한 노랑-주황 UI는 월드와 잘 섞인다. 다만 접근성 글은 «default bright yellow-orange interface»가 버거운 사람을 위해 흰·갈색 UI 모드와 Dark User Interface 모드를 소개한다 ([Nic Chan](https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/)). 인벤토리 수량 숫자가 작다는 불만도 있다(2부 10 참고).

**가져올 점.** td-proj와 같은 계열(UI도 도트 스프라이트)이다. 다만 UI 배율이 5% 단위라 정수배는 보장되지 않는다. 프레임은 **고정 모서리 + 단면 1px 띠**로 그리고, 글자·그림자 색도 패널 계열에 맞추고, 가장 작은 숫자는 따로 챙긴다. 반면 월드와 같은 계열의 밝은 UI는 정보가 빽빽한 HUD에서 정보를 묻을 수 있다(추론). 그 UI가 버거운 사람을 위한 다크 UI 모드도 소개된다.

### Into the Breach: «분명히 보여 줄 수 없으면 뺀다»는 전략 HUD

**원칙.** 공동 디자이너 Justin Ma는 «we would sacrifice cool ideas for the sake of clarity every time», «If it can be shown in a clear way, yes, we can have that»이라고 말했다 ([Rock Paper Shotgun](https://www.rockpapershotgun.com/into-the-breach-interface-design), [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)). 이 말은 무기 설계를 덜어 내는 맥락에서 나왔다. 화면에 분명히 그릴 수 없는 사거리·효과는 설계에서 뺐다. Matthew Davis는 «One and a half years ago the game was just an icon mess»라고 회고했다. 무기 툴팁은 실제 유닛이 그 무기를 쓰는 짧은 애니메이션을 보여 준다. Ma는 이것이 «a thousand times more effective»이고 «the most important decision we made about this»라고 했다. 계기는 설명 세 문장을 읽고도 «What»이라고 반응한 플레이테스터였다 ([RPS](https://www.rockpapershotgun.com/into-the-breach-interface-design)).

**렌더링·글꼴.** 화면은 하이브리드다. 지형·유닛·초상은 도트로 그린다. 버튼·HUD 머리글·섹션 제목·큰 숫자("End Turn", "POWER GRID", "17%", "RESET USED", "WARNING!")는 도트 디스플레이 글꼴이다. 툴팁(제목 포함)·목표 항목·유닛 이름·대사는 안티에일리어싱된 산세리프다 ([ITB-1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_6113590509c195f98fa64cd738df534762e0c358.1920x1080.jpg), [ITB-2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_82cfc5241c4a093091fbd7d2e124a52a57930527.1920x1080.jpg)). 1.2 업데이트의 리소스 변경 목록에는 커스텀 TTF(JustinFont8/10/11/12, Justin13/15)가 «바뀜»으로, Roboto-Bold/Regular와 일본어용 NotoSans가 «추가»로 나온다. 어느 화면에 어느 글꼴을 쓰는지는 이 목록으로 알 수 없다 ([리소스 목록](https://gist.github.com/KnightMiner/d7889a8728b7b6b3c0ede8161ea15293)).

**팔레트·테두리·반투명.** 패널 바탕은 측정한 네 곳(타일 툴팁, Victory 패널, 지역 패널, 대사 상자)이 모두 **#0c0f16**이다. 테두리는 #475c79~#4a5a7e 강철 파랑으로, 1280×720에서 2px다. 640×360으로 환산하면 1 기준 px이고 모서리는 직각이다. 패널은 불투명하고, ITB-2에서는 부드러운 드롭 섀도로 바탕과 분리한다. 채도 높은 색은 뜻에만 쓴다. 주황은 전력 칸, 초록은 완료 목표와 체력, 노랑은 WIND STORM 경고, 어두운 빨강은 써 버린 RESET, 빨강은 지역 제목이다. 비활성 UNDO MOVE는 회색 글자로, 써 버린 버튼은 채도를 낮춘 빨강 글자로 바꾸되 패널 모양은 그대로 둔다. 자원과 End Turn은 왼쪽 위, 조종사 초상은 왼쪽 열, 승리까지 남은 턴은 오른쪽 위(숫자만 크게), 마우스를 올린 칸의 정보는 오른쪽 아래 패널에 둔다. 가운데 전장은 비워 둔다 ([ITB-1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_6113590509c195f98fa64cd738df534762e0c358.1920x1080.jpg)).

**가져올 점.** 패널 크롬은 거의 단색인 남흑에 1 기준 px의 차가운 테두리로 조용히 두고, 색은 **의미표**로 관리한다. 사거리·위협처럼 화면에 분명히 그릴 수 없는 정보는 UI가 아니라 설계에서 줄인다. 영웅·용병 스킬 설명은 문장보다 시연이나 칸 하이라이트로 보여 준다.

### 비교표와 공통 패턴: 어두운 패널, 눌린 흰색, 뜻에만 쓰는 원색

| 게임 | UI 렌더링 | 패널 바탕 | 테두리 마감 | 글꼴 | 반투명 | 가져올 점 |
|---|---|---|---|---|---|---|
| Dave the Diver | 월드 위 고해상도 오버레이 | 거의 순흑(4,4,4)·검붉은 검정, 넓은 패널은 짙은 갈색 | 1선, 사다리꼴·알약·둥근 모서리, 베벨 없음(시계만 예외) | HUD 대부분 도트풍 디스플레이(월드 격자 아님), 긴 문장만 산세리프(이름 미확인) | 테두리 있는 숫자 패널 불투명, 날짜 알약·퀘스트 목록 반투명 | 글꼴 역할 고정, 같은 선 문법 반복 |
| Eastward | 월드 격자와 분리, HUD 띠에만 LCD 격자 질감 | 어두운 남색 | 프레임 없음, 밑줄·가는 선 상자 | 스퀘어 계기판풍 라벨 + 매끈한 숫자(이름 미확인) | HUD 슬래브 반투명, 컷신은 레터박스 | 상황별 HUD, 앞자리 0 어둡게 |
| Celeste | 월드 320×180(6×6), UI는 고해상도 별도 층 | #1F141A 검보라, 화자별 마룬 | 모서리·위쪽 가운데에만 장식, 화자별 테마 | Renogare 64px BMFont, 한국어는 글자 추가용 원본으로 Noto Sans CJK KR Medium 안내(위키) | 불투명 | 고해상도면 층 전체를 고해상도로 |
| Stardew Valley | 네이티브 도트(`pixelZoom` 4), UI 배율 75~150%(5% 단위, 비정수 가능) | 대화창 크림·주황 (236,166,96)~(252,197,114), 나무 판 (216,130,57) | 고정 모서리 + 1px 띠 늘이기 | 손그림 비트맵 + SpriteFont, 한국어 BmFont × 1.5(글꼴 이름 미확인) | 대화창 불투명, 메뉴 뒤 월드는 검정 40%로 어둡게 | 1px 단면 9-slice, 글자·그림자 색을 패널 계열로 |
| Into the Breach | 하이브리드(도트 아트 + 산세리프 문장) | #0c0f16 | 강철 파랑 1 기준 px, 직각, 드롭 섀도 | 도트 디스플레이(버튼·머리글·숫자) + 산세리프(툴팁·대사) | 불투명 | 색 = 의미, 가운데 비우기 |

다섯 게임을 겹쳐 보면 **해상도 전략은 갈리지만 «한 층 안의 일관성»은 갈리지 않는다.** UI를 도트 스프라이트로만 그린 것은 Stardew Valley 하나다(배율은 월드와 따로 둔다. 보조 사례인 Loop Hero와 CrossCode도 기본값은 전부 도트다). 나머지 넷은 고해상도 요소를 섞는다. 다만 섞는 방식이 정해져 있다. Celeste는 층 전체를 고해상도로 했고, Dave the Diver와 Into the Breach는 글꼴 역할을 고정했고, Eastward는 HUD 띠에 전용 질감을 입혔다(화면 후처리로 이질감을 덮는다는 것은 추론). 같은 패널 안에서 해상도가 아무렇게나 섞이는 경우는 관찰되지 않았다.

색에서도 패턴이 겹친다. 정보 패널 바탕은 Celeste #1F141A, Into the Breach #0c0f16, Dave the Diver의 거의 순흑, Eastward의 남색처럼 **HSV 명도 2~22%의 어둠**이다. 어두워서 색 기운이 약하게 보일 뿐, HSV 채도는 0(Dave the Diver 금액 패널 (4,4,4))부터 1.0(Dave the Diver 탭 바 (21,0,5))까지 넓다(Celeste 0.35, Into the Breach 0.45, Eastward 0.51). 반투명은 완성도의 조건이 아니다. Into the Breach·Celeste·Loop Hero와 Stardew Valley의 대화창은 글자 패널을 불투명하게 두었다. 글자는 Celeste의 (224,222,225), Stardew Valley의 #221122처럼 순백·순흑에서 한 걸음 물러난 색이다. 고채도 색은 의미나 강조에만 남긴다. 예외는 Stardew Valley의 밝은 동색 계열 UI(대화창 HSV 명도 93~99%)인데, 이 UI가 버거운 사람을 위한 다크 UI 모드가 소개된다.

한글·CJK 처리도 같은 방향이다. Celeste와 Stardew Valley는 한글에 별도 글꼴을 둔다(1부 Celeste·Stardew Valley 글꼴 문단). 보조 사례인 Loop Hero의 GOG 빌드 fonts 폴더에도 `NotoSansKR-Medium.otf`가 있다(어느 화면에 쓰는지는 파일 목록에서 낸 추정) ([GOG 파일 목록](https://www.gogdb.org/manifest/571ad67fcf8b43b6f895f81a9a15d9f6)). 다만 한글 글꼴을 화면이나 파일 헤더로 직접 확인한 사례는 없다(Dave the Diver 한국어판과 Eastward 중국어판은 글꼴 정보도 찾지 못했다). 가장 작은 UI 요소가 먼저 비판받는다는 점도 겹친다(2부 10 참고).

## 2부. 진단: 아마추어 티는 «한 화면 안의 규칙 위반»에서 난다

아래 1~9는 모두 같은 원리로 아마추어처럼 읽힌다. 사람의 눈은 화면에서 반복되는 규칙(픽셀 크기, 선 굵기, 색의 뜻, 간격)을 «재질»로 읽는다. 그래서 규칙이 하나만 깨져도 그 요소가 다른 출처에서 덜 다듬어진 채 붙어 온 것처럼 보인다. 10은 일관성이 아니라 가장 작은 글자·숫자의 하한을 다루는 항목이다.

### 1) 한 화면에 픽셀 크기가 여럿이다 (믹셀)

도트 게임에서 가장 자주 지적되는 결함은 부위마다 픽셀 크기가 다른 «믹셀»이다. 한 커뮤니티 글은 믹셀을 «uncanny, strange, and just… unprofessional»이라고 했다(개인 의견 글) ([Flowlab 포럼](https://community.flowlab.io/t/mini-rant-stop-using-mixels/38287)). 16·32·64·96px 스프라이트를 섞어 쓴 한 개발자는 결과를 «It looks like I threw different resolution games in a blender»라고 적고 전부 32×32로 통일했다 ([itch.io Day 16](https://itch.io/blog/1026541/day-16-confronting-the-elephant-pixels-in-the-room)). **왜 아마추어로 읽히나:** 도트 그림에서는 픽셀 격자 자체가 재질이다. 픽셀 크기가 섞이면 출처가 다른 에셋을 오려 붙인 콜라주로 보인다. UI에서 믹셀은 대개 세 경로로 생긴다. 큰 스프라이트를 칸 크기로 비정수 축소한 대역 아이콘, 1.5배·1.6배처럼 정수가 아닌 확대, 그리고 도트 그림 위에 화면 해상도 벡터 글자를 얹는 것이다. 1부의 고해상도 게임들은 이 세 번째를 «층 단위 규칙»으로 통제했다. 규칙 없이 섞인 것과 의도적인 하이브리드는 다르다.

### 2) 비정수 배율, 반 픽셀 위치, 크기 트윈이 격자를 깬다

Godot 문서는 정수가 아닌 배율이 «uneven pixel scaling which results in incorrect appearance of pixel art»를 낳는다고 경고한다. 비교 그림 설명은 «Line widths in the logo and text varies wildly»다 ([Godot: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)). 640×360으로 내린 한 Godot 개발자는 1.5배 스프라이트를 «scaling pixel art by non-integers is a catastrophe»라며 다시 그렸다. 2배로 키운 스프라이트는 외곽선까지 두꺼워져 일일이 지웠다 ([Unicopia devlog](https://squeakypig.itch.io/unicopia/devlog/787703/a-tale-about-chasing-a-pixel-perfect-tail)). hover 때 TextureButton을 1.1배로 트윈하자 게임 안에서 찌그러졌다는 보고도 있다(Godot 4.5.1 사용자 보고, 답변은 원인을 stretch 설정으로 봄) ([Godot Forum](https://forum.godotengine.org/t/help-with-pixel-deforming-when-changing-scale/129213)). Defold 쪽 글은 가운데·가장자리 앵커가 «render "off grid"»한다며 모서리 앵커에 두고 가운데 정렬은 정수로 직접 하라고 권한다 ([Defold 포럼](https://forum.defold.com/t/gui-for-pixel-art-games-heres-how/77704)).

Godot 4.7의 `canvas_items` + 정수배 구성에서는 사정이 조금 다르다. 엔진 소스상 `gui/common/snap_controls_to_pixels`(기본 true)는 Control의 로컬 위치를 부모 좌표, 곧 기준 px 단위로 반올림한다. 그래서 조상이 확대·회전되지 않았다면 **Control 노드의 위치는 이미 아트 격자 위에 있다** ([control.cpp](https://raw.githubusercontent.com/godotengine/godot/4.7/scene/gui/control.cpp)). 반면 `snap_2d_vertices_to_pixel`은 스트레치 변환을 곱한 뒤 **화면 픽셀**에 맞춘다 ([canvas.glsl](https://raw.githubusercontent.com/godotengine/godot/4.7/servers/rendering/renderer_rd/shaders/canvas.glsl)). 따라서 아트 반 픽셀(2배에서 화면 1px)만큼 어긋날 수 있는 것은 노드 안에서 그리는 내용이다. Button 글자의 세로 가운데 오프셋, TextureRect의 가운데 배치(`STRETCH_KEEP_CENTERED`·`STRETCH_KEEP_ASPECT_CENTERED`), 크기가 분수인 Control의 사각형 끝, `draw_*`의 소수 좌표, 확대·회전 트윈 중인 노드가 그렇다. Label 글자의 가로·세로 가운데와 Button 글자의 가로 가운데·아이콘 위치는 엔진이 정수로 내린다([label.cpp](https://raw.githubusercontent.com/godotengine/godot/4.7/scene/gui/label.cpp), [text_paragraph.cpp](https://raw.githubusercontent.com/godotengine/godot/4.7/scene/resources/text_paragraph.cpp), [button.cpp](https://raw.githubusercontent.com/godotengine/godot/4.7/scene/gui/button.cpp)). 단, 폴백 글꼴을 단 Label은 사슬 안 글꼴끼리 줄 높이(ascent+descent) 차가 홀수면 그 절반을 ascent에 더해 기준선이 0.5 기준 px에 놓일 수 있다(`label.cpp:502-506`). **왜 아마추어로 읽히나:** 선 굵기가 프레임마다 1·2px로 출렁이면 디자인이 아니라 렌더링 버그로 보인다.

### 3) 엔진 기본값이 그대로 보인다

Godot에서 글꼴을 지정하지 않은 Control은 Open Sans SemiBold로 그려진다 ([Godot: Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)). 글꼴에 없는 글자는 시스템 글꼴로 자동 대체되는데, 문서도 «different system fonts have different metrics»라고 경고한다. 한 줄 안에서 기준선과 높이가 어긋날 수 있다는 뜻이다. 프로젝트 테마가 덮지 않은 위젯(체크 버튼, 슬라이더, 드롭다운 목록)은 기본 테마 모양으로 남는다. 비평 스레드에도 기본 위젯 장식을 겨냥한 말이 나온다(«the gui's are really blocky») ([Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)). 한 인디 개편 사례는 모노스페이스 기본 글자를 «begone monospace!»라며 버리고 버튼과 파티 HUD에 전용 텍스처를 입혔다 ([Kobold Crawler devlog](https://itch.io/devlog/793572/new-ui-look.amp)). **왜 아마추어로 읽히나:** 개발자와 게이머는 엔진의 기본 외형을 알아본다. 기본값이 보이면 «아직 임시 UI»라는 신호가 된다. 플레이어 PC마다 대체 글꼴이 달라지면 같은 빌드도 다르게 보인다.

### 4) 글꼴과 글자 크기에 규칙이 없다

Godot 문서는 도트 글꼴의 크기가 «an integer multiple of the design size»여야 하고 그 글꼴을 쓰는 Control도 정수배로 확대해야 한다고 적는다. 그렇지 않으면 «the font may look blurry»다 ([Godot: Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)). 게임 UI 타이포그래피 글은 웹 규칙으로 서체가 셋을 넘으면 «unstructured and unprofessional»해 보인다고 소개한다(글쓴이는 게임은 다르다고 덧붙인다) ([Indieklem #13](https://indieklem.substack.com/p/13-the-basics-of-typography-in-game)). 비평 스레드에는 «clumped stuff with different text sizes are really ugly», «The buttons should be the same size with the same sized text»라는 말이 나온다 ([Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)). 한글은 저해상도에서 특히 까다롭다. 128×128 게임 Curious Fishing의 현지화 일지는 대부분 언어의 축하 글자를 2배로 키웠지만 «중국어와 한국어는 너무 커서 1배로 남겼다»고 썼다. 제목 화면에서는 한국어 로고 자리를 만들려고 파도 그림을 올렸다 ([Curious Fishing devlog](https://halfwayordinary.itch.io/curious-fishing/devlog/457088/12-localizing-a-low-resolution-pixel-art-game)). **왜 아마추어로 읽히나:** 크기 단계가 많으면 위계가 아니라 «그때그때 맞춘 값»으로 보인다. 정수배가 아닌 도트 글자는 획 굵기가 들쭉날쭉해 흐릿해 보인다.

### 5) 색이 많고, 원색이고, 뜻이 없다

비평 스레드는 «I would have around 3-4 colors, you have like 7-8», «everything clashes»라고 짚었다 ([Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)). 도트 아트 교육자 Arne Jansson은 «Reducing the amount of colors and unifying the palette is often quite effective»라고 쓰고, 채도를 끝까지 올린 색으로 긴 색 띠를 만드는 데 반대한다 ([androidarts](https://www.androidarts.com/pixtut/pixelart.htm)). Slynyrd는 «The biggest mistake is combining high saturation and brightness, unless you want to burn some eyeballs»라고 썼다. 명도·채도만 바꾸고 색상(hue)을 옮기지 않은 램프는 «lack interest and be difficult to harmonize»라고 했다 ([Slynyrd Pixelblog 1](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes)). 검은 외곽선도 «can be very versatile, but sometimes they're a bit overpowering or too retro feeling»이다 ([Lospec](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)). 반대 방향의 한계도 있다. Return의 개발자는 1비트(두 색) UI를 시도했다가 체력 바와 스태미나 바를 구분할 수 없어 포기했다 ([Return devlog](https://itch.io/devlog/384935/return-devlog-01-creating-effective-pixel-art-uigui.amp)). 색만으로 정보를 전하는 것도 문제다. Xbox 접근성 지침은 «Color alone should never be used to represent information»이라고 쓴다 ([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)). **왜 아마추어로 읽히나:** 월드 팔레트 밖에서 온 UI 색은 화면 위에 떠 보인다. 고채도 원색이 넓게 깔리면 모든 요소가 같은 크기로 소리친다.

### 6) 명도 위계가 없어 덩어리가 갈리지 않는다

패널 바탕, 칸 바탕, 칸 테두리의 명도가 거의 같으면 버튼과 배경을 구분하기 어렵다. WCAG 2.2 SC 1.4.11은 UI 컴포넌트와 그 상태를 알아보는 데 필요한 시각 정보가 인접 색과 **3:1** 이상 대비를 가져야 한다고 정한다. 문턱값이라 2.999:1도 미달이다 ([W3C](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)). 글자는 Xbox 지침 기준 **4.5:1**이고, 단색이 아닌 배경 위에서는 배경의 가장 대비 낮은 부분에 대고 잰다 ([XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)). Game Accessibility Guidelines는 글자 크기 다음으로 흔한 UI 불만이 대비라고 쓴다 ([GAG](https://gameaccessibilityguidelines.com/provide-high-contrast-between-text-and-background/)). 위계의 원칙으로는 «One screen, one main action»이 있다. 주 버튼이 보조 버튼보다 시각적으로 강해야 한다는 뜻이다 ([Indieklem #8](https://indieklem.substack.com/p/8-better-designed-buttons)). **왜 아마추어로 읽히나:** 모든 요소의 무게가 같으면 시선이 머물 곳이 없다. 대비가 낮은 화면은 덜 끝낸 시안처럼 보인다.

### 7) 여백, 정렬, 크기가 들쭉날쭉하다

비평에서 가장 흔한 말은 «Padding is inconsistent», «Make each button equal size», «not center-aligned»다 ([Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)). 일관성을 다룬 글은 같은 요소(뒤로 가기 버튼 등)를 모든 메뉴에서 같은 자리에 두라고 한다. 또 필수 정보는 앞에, 부가 정보는 «accessible but unobtrusive»하게 두고 UI를 점진적으로 공개하라고 권한다 ([itch.io blog](https://itch.io/blog/1040432/why-your-ui-design-is-pushing-players-away)). Into the Breach가 «icon mess»에서 출발했다는 회고도 같은 문제다. **왜 아마추어로 읽히나:** 저해상도에서는 1 기준 px 차이가 화면 2~3px로 커진다. 그래서 고해상도 UI보다 여백 불일치가 더 잘 보인다(추론). 패널이 화면 끝에 붙어 있으면 숨 쉴 자리가 없어 답답해 보인다.

### 8) 프레임과 아이콘의 도트 규칙이 제각각이다

Godot의 NinePatchRect·StyleBoxTexture는 기본값이 늘이기(STRETCH, 0)다. STRETCH는 «This may cause the texture to be distorted»라서 무늬 있는 변을 늘이면 테두리 픽셀이 뭉개진다 ([NinePatchRect](https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html)). 같은 화면의 외곽선 굵기가 다르거나(Unicopia의 2배 외곽선), 빛 방향이 다르거나, 그림체가 다른 아이콘이 하나 끼면 그 아이콘만 튄다. 비평 스레드의 «the twitter icon looks out of place»가 그런 경우다. Derek Yu는 광원을 하나로 정하고 게임용 스프라이트의 바깥쪽에 안티에일리어싱을 넣지 말라고 쓴다 ([Derek Yu](https://www.derekyu.com/makegames/pixelart.html)). androidarts는 형태 중심을 향해 둥글게 밝아지는 «베개 셰이딩»이 형태를 밋밋하게 만든다고 쓴다. **왜 아마추어로 읽히나:** 상용작의 프레임은 한 장의 아틀라스에서 나온 부품 묶음처럼 보이는데, 아마추어 UI의 프레임은 화면마다 따로 만든 것처럼 보인다.

### 9) 상태와 움직임이 없거나, 움직임이 격자를 깬다

누르든 올리든 모양이 그대로인 버튼은 «작동만 하는 프로그래머 UI»의 전형이다. 버튼에는 최소한 Normal·Hover·Focus·Active 네 상태가 있어야 한다 ([Indieklem #8](https://indieklem.substack.com/p/8-better-designed-buttons)). Godot 문서는 focus 표시를 끄면 «will harm keyboard/controller navigation usability»라고 경고한다 ([Button.xml](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/Button.xml)). 반대로 0.9→1.0 확대 팝업이나 튀어 넘치는 이징은 2)의 격자 문제를 다시 만든다. CrossCode는 568×320 캔버스에서 요소마다 상태(위치·알파·배율·각도)와 이름 붙은 전환을 두고, 이징 곡선으로 보간했다. 개발사는 «We basically copied the same system CSS uses»라고 설명했다 ([Radical Fish Games](https://www.radicalfishgames.com/?p=1594)). **왜 아마추어로 읽히나:** 반응이 없는 UI는 고장 났는지 의심하게 만든다. 격자를 깨는 반응은 싸구려 효과로 보인다.

### 10) 가장 작은 글자와 숫자가 읽히지 않는다

이 항목은 한 화면 안의 규칙 위반이 아니라 절대 하한이다. 상용작도 걸리는 결함이라, 아마추어와 상용작을 가르는 신호라는 근거는 없다. 상용작도 가장 작은 UI 요소 때문에 비판받았다. Stardew Valley는 PC 인벤토리 수량 숫자가 «too small, even with the largest UI scale»이라는 Steam 글을 받았다(2021-01 원글과 2024-11 동조 댓글 하나) ([Steam 토론](https://steamcommunity.com/app/413150/discussions/0/5283252978685636205)). 이 숫자는 글꼴이 아니라 `drawTinyDigits` 스프라이트라 숫자 스프라이트 배율의 문제다. Dave the Diver는 2023년 8월 업데이트로 기본 UI 크기를 바꾼 뒤에도(사용자 배율 옵션은 없다) 2024년 2월 접근성 리뷰에서 «Fixed UI size», «Much of the UI is small and hard-to-see with no options to readjust them»이라는 평을 받았다 ([Gamepressure](https://www.gamepressure.com/newsroom/dave-the-diver-will-soon-receive-a-major-update/z15c7b), [Game Accessibility Nexus](https://www.gameaccessibilitynexus.com/blog/2024/02/13/dave-the-diver-deaf-game-review)). Loop Hero에는 데모 시기에 도트 글꼴이 읽기 어렵다는 불만 글이 있었다. 크기가 아니라 가독성 불만이다. 그 글에는 이미 «Language → High Resolution Fonts» 옵션이 있다는 답이 달렸고, 정식판 fonts 폴더에도 `Roboto-Bold.ttf`와 난독증 친화 글꼴 `ADYS.otf`가 들어 있다 ([Steam 토론](https://steamcommunity.com/app/1282730/discussions/0/3117023981184793098/), [GOG 파일 목록](https://www.gogdb.org/manifest/571ad67fcf8b43b6f895f81a9a15d9f6)). 셋 모두 가장 작은 UI 요소(수량 숫자 스프라이트, 작은 UI, 도트 글꼴 가독성) 때문에 비판받은 셈이다. 기준 수치도 있다. Steam Deck 검수는 1280×800에서 가장 작은 글자가 높이 9px 밑으로 내려가면 안 된다고 요구하고, 가능하면 12px를 목표로 하라고 권한다 ([Steamworks](https://partner.steamgames.com/doc/steamdeck/compat)). Xbox 지침의 PC 최소 글자 높이(디센더~어센더)는 1080p에서 18px다 ([XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)). **왜 아마추어로 읽히나:** 플레이어가 UI를 가장 오래 들여다보는 곳이 숫자다. 거기서 눈을 찡그리게 되면 다른 마감이 좋아도 «덜 다듬었다»는 인상이 남는다(추론).

## 3부. 개선 체크리스트

체크리스트는 기준 px로 잰다. 접근성 지침의 1080p 수치는 3으로 나누면 기준 px가 된다. 720p에서도 비율이 같으므로 결과는 같다. 자주 쓰는 환산은 다음과 같다.

| 출처 기준 | 원래 값 | 640×360 기준 px |
|---|---|---|
| XAG 101 PC 최소 글자 높이 | 18px @1080p | 6 |
| XAG 101 콘솔 최소 | 26px @1080p | 8.7 |
| GAG(Amazon TV) 최소 | 28px @1080p | 9.3 |
| XAG 102 PC «큰 글자» 문턱 | 36px @1080p | 12 |
| Steam Deck 절대 최소 / 권장 | 9 / 12px @1280×800(2배) | 4.5 / 6 |
| Xbox GDK title-safe 가장자리 | 좌우 96·상하 40px @1080p | 32 / 13.3 |

출처: [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101), [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102), [GAG](https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/), [Steamworks](https://partner.steamgames.com/doc/steamdeck/compat), [Xbox Screen areas](https://devdocs.xbox.com/build/core-features/graphics/overviews/screen-areas). 640×360에서는 대부분의 HUD 글자가 «큰 글자» 문턱(12 기준 px) 아래다. 그러니 **글자는 4.5:1을 기본 목표**로 잡는다.

### [레이아웃/여백]

- [ ] **L1. 여백·간격 값을 2·4·8·12·16 기준 px로 한정한다.**
  - 통과 기준: 이웃 요소 사이 간격, 화면 끝까지의 거리, 안쪽 여백, separation, content margin이 이 토큰 중 하나다(3·5·6·7px 간격은 0개). `position`은 이 토큰의 합으로 계산하고, 크기는 정수 기준 px다.
  - 1 기준 px 예외 두 가지: (가) 눌림처럼 내용을 1px 옮기는 상태 차이(A8의 `content_margin` ±1). (나) 화면 높이 상한 때문에 재서 필요하다고 확인된 촘촘한 목록의 줄 사이(예: td-proj 장비 줄, SPEC I293 ④). 예외 값은 이름 붙인 상수에 두고, 그 밖의 1px 간격은 0개다.
  - 점검: 이웃 Rect 사이의 거리를 계산해 토큰 밖 값을 센다. 2배 캡처 위에 4 기준 px 격자를 겹쳐 본다.
  - 근거: Material Design은 치수를 8dp 격자에 맞추고, 아이콘·글자는 4dp 격자에 맞출 수 있다(can align) ([Material Design](https://m2.material.io/design/layout/spacing-methods.html)). 640×360으로 옮기면 기본 단위 4, 세부 단위 2가 된다(환산).
  - Godot: 간격 값을 Theme 상수(`BoxContainer`의 `separation`, `MarginContainer`의 `margin_*`)나 상수 파일 한 곳에 둔다.
- [ ] **L2. 그룹 안 간격 < 그룹 사이 간격.**
  - 통과 기준: 예를 들어 그룹 안 4, 그룹 사이 8~12 기준 px. 관련된 정보(골드와 수입, 체력과 방어)는 한 덩어리로 묶는다.
  - 점검: 화면을 흐리게 만든 캡처에서 덩어리가 의도한 수만큼 보이는지 본다.
  - 근거: Gestalt 근접성을 정수 간격으로 옮긴 것이다(추론). Tenril은 연관된 바를 한데 모았다 ([Tenril devlog](https://itch.io/devlog/571846/in-game-ui-rework.amp)).
- [ ] **L3. 화면 가장자리 여백은 8 기준 px 이상.**
  - 통과 기준: PC 창·전체화면에서 HUD 패널 바깥 모서리와 화면 끝 사이가 8 이상. TV나 Big Picture를 노리면 핵심 수치는 좌우 32·상하 13 안쪽에 둔다(GDK title-safe 환산). 화면 폭 전체를 덮는 띠(위 띠, Dave the Diver의 하단 탭 바 같은 것)는 예외로 하되, 띠 안의 내용(글자·아이콘)이 화면 끝에서 8 이상 떨어진다.
  - 점검: 각 HUD 덩어리의 Rect를 표로 뽑아 0·4·8·12…와 대조한다.
  - 근거: 8은 실용 최소값으로 낸 추론이다. title-safe는 [Xbox GDK](https://devdocs.xbox.com/build/core-features/graphics/overviews/screen-areas)에서 왔다.
- [ ] **L4. HUD는 가장자리 고정 구역에 두고, 필드 위에는 대상에 붙은 작은 표시만 둔다.**
  - 통과 기준: 필드 가운데를 상시 덮는 패널이 0개. 툴팁·상세 정보는 고정 패널에 뜨거나 대상에 붙는다.
  - 점검: 전투 중 캡처에서 필드 중심부를 덮은 면적을 본다.
  - 근거: Dave the Diver·Into the Breach(1부)와 Loop Hero([LH-1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_500e7212653fa6586f7a84c89b4c60be4e425fbb.1920x1080.jpg)) 모두 가운데를 비운다.
- [ ] **L5. 화면마다 주 행동은 하나, 그 버튼이 가장 강하다.**
  - 통과 기준: 각 화면(준비·전투·영입·결과)에서 강조색 채움 버튼이 1개 이하.
  - 점검: 화면별 캡처에서 ACCENT 채움 버튼 수를 센다.
  - 근거: [Indieklem #8](https://indieklem.substack.com/p/8-better-designed-buttons).
- [ ] **L6. HUD 요소를 «늘 보임 / 바뀔 때만 보임 / 열어야 보임» 세 층으로 나눈다.**
  - 통과 기준: 모든 HUD 요소가 셋 중 한 층에 배정돼 있다. 마을·준비 단계에서는 전투 전용 정보가 숨는다.
  - 근거: Eastward의 상황별 HUD(2019 데모 체험기 기준), Return의 «필요할 때만 보였다 숨는» 머리 위 수치 ([TapTap](https://www.taptap.cn/moment/15230291522095848), [Return devlog](https://itch.io/devlog/384935/return-devlog-01-creating-effective-pixel-art-uigui.amp)).
- [ ] **L7. 가운데 정렬이 반 픽셀에 놓이지 않고, 한 줄의 아이콘과 글자는 세로 가운데가 맞으며, 크기는 정수 기준 px다.**
  - 통과 기준(가로): Label 글자와 Button 글자의 가로 가운데, Button 아이콘은 엔진이 정수로 내리므로 가운데 정렬을 그대로 둔다. `(부모 폭 − 내용 폭)`이 홀수면 좌우 여백이 1 기준 px 다를 뿐이고, 왼쪽 정렬로 바꾸지 않는다.
  - 통과 기준(공통): 엔진이 정수로 내리지 않는 곳(TextureRect의 `STRETCH_KEEP_CENTERED`·`STRETCH_KEEP_ASPECT_CENTERED`, Button 글자의 세로 가운데, `draw_*`로 직접 계산한 자리)만 홀짝을 맞추거나 `floor()`·`round()`로 정수를 넣는다. Control 크기에 소수가 없다.
  - 통과 기준(세로): 한 줄에 놓인 아이콘의 높이와 숫자·대문자 글리프 높이의 홀짝을 맞춘다. 못 맞추면 남는 1 기준 px을 위·아래 어느 쪽에 둘지 화면 전체에서 하나로 정한다.
  - 점검: 2배 캡처를 (0,0)에서 시작하는 2×2 블록으로 나눠, 블록 안 색이 고르지 않은 비율이 0%인지 본다(연구 노트 `td_proj_current_ui.md` §7.3 방식). 또는 같은 색 줄의 시작 x가 모두 짝수인지 본다. 1 화면 px 어긋나도 줄 길이는 그대로라, 줄 길이만 봐서는 어긋남을 못 잡는다. 세로는 같은 캡처에서 아이콘과 글자 위·아래의 빈 줄 수를 센다.
  - Godot: Control 위치는 `snap_controls_to_pixels`가 반올림한다. Label 가로 가운데(`label.cpp:525`), Button 글자 가로(`text_paragraph.cpp:907`의 `floor`), Button 아이콘(`button.cpp:413` `floor()`)도 엔진이 정수로 내린다. 직접 맞출 곳은 TextureRect 가운데 배치(`texture_rect.cpp:62,77`), Button 글자 세로(`button.cpp:461` `/ 2.0f`), `draw_*` 좌표다(2부 2). Label의 세로 가운데는 남는 높이를 `int vbegin`으로 내리므로, 남는 높이가 홀수면 위 여백이 아래보다 1 기준 px 작다. 글꼴 지표도 영향을 준다. Galmuri11(12px)은 글자 가운데가 줄 상자(ascent+descent) 가운데보다 0.5 기준 px, Galmuri14(15px)는 1 기준 px 위에 있다(Galmuri7·9는 0). 보정은 노드 y를 밀지 말고 FontVariation의 `spacing_top`·`spacing_bottom`(정수 px)으로 한다. 폴백 글꼴을 쓰면 같은 방법으로 사슬 안 글꼴의 줄 높이를 같게 맞춘다(2부 2).
- [ ] **L8. 같은 종류의 버튼·칸은 같은 크기이고, 두 언어 모두 잘리지 않는다.**
  - 통과 기준: 같은 역할의 버튼 폭·높이가 같다. 한국어·영어에서 가장 긴 문자열이 안쪽 여백 4 이상을 남기고 들어간다. `clip_text`로 잘리는 번역문이 0개.
  - 점검: `.po`에서 가장 긴 문자열을 뽑아 해당 칸에 넣고 캡처한다.
  - 근거: [Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763), 한국어가 가장 자리를 먹었다는 [Curious Fishing](https://halfwayordinary.itch.io/curious-fishing/devlog/457088/12-localizing-a-low-resolution-pixel-art-game) 사례.
- [ ] **L9. 첫인상 화면(제목·설정)이 게임의 얼굴을 갖는다.**
  - 통과 기준: 제목 화면에 게임 이름(로고)과 배경 그림이 있다. 설정 화면의 체크 버튼·슬라이더·드롭다운이 HUD와 같은 테마다.
  - 점검: 각 장면을 단독 실행해 캡처한다.
  - 근거: 2부 3의 «엔진 기본값» 신호.

### [색상/명도]

- [ ] **C1. UI 팔레트를 표 하나로 고정한다.**
  - 통과 기준: 어두운 중립 2~3단(바탕·칸·바깥 그림자), 중간 중립 1단(테두리·hover), 밝은 중립 2단(본문·보조 글자), 강조 1~2색, 의미색(체력·골드·위험·정보·희귀도)이 상수 한 곳에 있다. 그 밖의 hex 리터럴과 `Color.WHITE`·`BLACK`·`GREEN` 같은 이름 색이 UI 코드에 0개. 단 modulate 항등(곱하기 1)으로 쓰는 `WHITE`와 화면 페이드 막으로 쓰는 `BLACK`은 제외한다.
  - 점검: `Color("`·`Color.`를 grep해 상수 파일 밖의 것을 센다.
  - Godot: Theme 리소스(`.tres`)의 색 항목이나 상수 스크립트 하나에 둔다.
- [ ] **C2. (권장) UI 색을 월드 팔레트 파일에 함께 둔다.**
  - 권장 기준(추론): UI 중립색과 강조색을 맵·유닛과 같은 팔레트 파일(td-proj는 `tools/art/palettes.json`)에 등록한다. 월드 램프에 맞는 색이 없으면 그 파일에 UI 전용 램프를 더해도 된다. 중립 램프의 색상을 명도에 따라 조금씩 옮기면(어두울수록 푸른·보라 쪽, 밝을수록 따뜻한 쪽) 덜 밋밋하지만 필수는 아니다.
  - 예외: C4·C9의 글자 대비나 A6의 외곽선 대비를 팔레트 안의 색으로 맞출 수 없으면 UI 전용 색을 더한다. 패널 바탕에는 아트 외곽선(td-proj `151a26`)과 명도가 거의 같은 색을 쓰지 않는다. 지금 PANEL `14161c`(1.04:1)도 여기에 걸린다. 외곽선이 바탕과 갈리는지는 A6대로 캡처로 확인한다.
  - 근거: 팔레트를 하나로 묶으라는 [androidarts](https://www.androidarts.com/pixtut/pixelart.htm), [Derek Yu](https://www.derekyu.com/makegames/pixelart.html), 그리고 straight ramp가 밋밋하다는 [Slynyrd](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes). Slynyrd도 색상을 옮기지 않는 램프에 «There is no law that says you can't do this»라고 덧붙여 규칙으로 두지 않았다. UI 팔레트를 월드와 공유하라고 직접 말한 권위 있는 출처는 없어 추론이고, 그래서 통과·미달이 아니라 권장으로 둔다. Slynyrd가 자기 팔레트에 쓴 견본당 +20° 이동은 저자 설정이고 상한에 가깝다.
- [ ] **C3. 칸·버튼의 경계는 인접 색과 3:1 이상.**
  - 통과 기준: 버튼을 알아보게 하는 테두리나 채움이 바로 옆 색(패널 바탕)과 3:1 이상. 3:1 미만이면 테두리 대신 명도 차가 큰 채움이나 하이라이트로 덩어리를 가른다.
  - 점검: WCAG 상대 휘도 식으로 상수 쌍을 계산한다(스크립트 한 번).
  - 근거: [WCAG 2.2 SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).
- [ ] **C4. 글자 대비는 가장 나쁜 배경에 대고 4.5:1 이상.**
  - 통과 기준: 본문·숫자 4.5:1, 비활성 글자 3:1, 가는 포커스 테두리 4.5:1(XAG 102의 «standard-size … visual element» 행을 적용한 해석), 고대비 모드를 둔다면 7:1.
  - 점검: 단색 배경이면 계산하고, 맵 위 글자는 그 아래 가장 밝은 아트 색에 대고 계산한다.
  - 근거: [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102). 7:1은 WCAG에서는 AA가 아니라 AAA(1.4.6) 값이다.
- [ ] **C5. 글자를 담는 반투명 패널은 최소 불투명도를 지킨다.**
  - 통과 기준(밝은 글자, 최악 배경 = 순백, sRGB 블렌딩):

    | 글자 / 패널 | 4.5:1 | 7:1 |
    |---|---|---|
    | td-proj TEXT #E8E8E8 / PANEL #14161C | 65% | 77% |
    | 후보 본문 #D0D6E0 / 바탕 #151A26 | 71% | 83% |
    | #FFFFFF / #000000 | 54% | 66% |
    | #FFFFFF / #1A1C2C | 61% | 74% |
    | #FFFFFF / #333C57 | 71% | 86% |
    | #F4F4F4 / #000000 | 57% | 68% |
    | #F4F4F4 / #1A1C2C | 64% | 77% |

    지금 td-proj 패널(α0.92)은 TEXT 기준 두 문턱을 모두 넘는다. 후보 행은 아래 대조의 «색 후보» 문단 값이다.

  - 근거: 연구 노트에서 WCAG 식으로 직접 계산해 검증한 값이다. 문턱은 반올림하지 않는다. Godot `Viewport.use_hdr_2d` 기본값 false(sRGB 공간 블렌딩)를 가정했다. HDR 2D를 켜면 4.5:1 문턱이 82~86%로 오른다 ([Viewport](https://docs.godotengine.org/en/stable/classes/class_viewport.html)).
  - 덧붙임: 반투명은 필수가 아니다. 글자 패널은 불투명하게 두고 반투명은 넓은 장식 띠에만 써도 된다(1부 공통 패턴). 디더(screen-door) 반투명은 1px 획의 도트 글자와 경쟁하므로 글자 뒤에는 쓰지 않는다(추론).
- [ ] **C6. 순색과 «높은 채도 + 높은 명도» 조합을 큰 면적에 쓰지 않는다.**
  - 통과 기준: 패널·막대 바탕·테두리에 `#00FF00`·`#FF0000`·순백·순흑이 0개. 본문 글자는 순백에서 물러난 회백색(Celeste ≈ 224, Sweetie 16 #f4f4f4), 가장 어두운 바탕은 순흑 대신 남·보라 기운의 어둠(#1F141A, #0c0f16, #1a1c2c)이다. 고채도는 작은 강조점에만 남긴다.
  - 근거: [Slynyrd](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes), [Sweetie 16](https://lospec.com/palette-list/sweetie-16), 1부 측정값.
- [ ] **C7. 색 하나에 뜻 하나를 붙이고, 그 뜻을 표로 적는다.**
  - 통과 기준: «주황 = 자원, 초록 = 완료·체력, 노랑 = 경고, 빨강 = 위협»처럼 의미표가 있고, 같은 색이 다른 뜻으로 쓰이는 곳이 0개.
  - 점검: 의미표의 각 hex를 grep해 다른 뜻으로 쓰인 곳을 센다.
  - 근거: Into the Breach의 의미색 배치. Shardpunk는 행동 비용을 외곽선 색으로 고정했다(무료 초록, 1AP 파랑, 2AP 주황) ([Shardpunk devlog](https://bryqu.itch.io/shardpunk/devlog/69970/fleshing-out-the-ui)).
- [ ] **C8. 색으로 전하는 정보에는 모양·아이콘·글자를 하나 더 붙인다.**
  - 통과 기준: 아군/적, 부족/충분, 희귀도, 위험도가 색을 빼도 구분된다. 예를 들어 부족한 비용은 «빨간 숫자 + 경고 아이콘»으로 보인다. Loop Hero는 부족할 때 «가진 양/필요량» 꼴로 바꾸고 가진 양만 붉게 칠한다 ([LH-2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_455789884ed94fd20410ac5a139e8c3bb8f6f369.1920x1080.jpg)).
  - 근거: [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103). Grounded는 재료 부족을 빨간 숫자 + 경고 삼각형 + «x0 Available»로 함께 보인다.
- [ ] **C9. 빨강·파랑 의미색을 글자색으로 쓰기 전에 대비를 따로 잰다.**
  - 통과 기준: 글자용 빨강은 4.5:1을 넘는 한 단계 밝은 빨강·주황을 따로 둔다. 어두운 빨강은 막대 채움에만 쓴다.
  - 근거: td-proj의 DANGER #ef3a0c는 칸 CELL #23262f 위에서 3.80:1로 4.5:1에 못 미친다(WCAG 식 계산값). 아래 대조의 C4 행 참고.
- [ ] **C10. 흑백 캡처에서도 위계가 남는다.**
  - 통과 기준: 화면을 흑백으로 바꿔도 바탕 < 칸 < 테두리·글자 < 강조의 명도 순서가 보인다.
  - 점검: 2배 캡처를 그레이스케일로 바꿔 본다(실무 관행, 1차 출처 없음).

### [폰트/가독성]

- [ ] **F1. 글꼴 전략을 하나 고르고, 엔진 기본 글꼴과 OS 대체 글꼴을 화면에서 없앤다.**
  - 선택지 A(전부 도트): HUD·메뉴 글자를 도트 글꼴(예: Galmuri)로 통일한다. Stardew Valley·Loop Hero 기본값 계열이다. `canvas_items`에서는 글꼴이 창 배율로 오버샘플링되므로(`gui/fonts/dynamic_fonts/use_oversampling` 기본 true), 설계 크기의 정수배로 쓰면 4K 6배에서도 6×6 블록이 된다(문서 동작에서 낸 추론, 4K 캡처로 확인 필요). 창 크기를 바꿀 때 글자가 흐려지는 열린 버그도 있으니 배율마다 캡처로 본다 ([#86563](https://github.com/godotengine/godot/issues/86563)).
  - 선택지 B(규칙 있는 하이브리드): 숫자·짧은 라벨·버튼은 도트 글꼴, 두 줄 넘는 설명문은 **게임에 함께 넣은** 고해상도 글꼴(예: Celeste 위키가 안내하고 Loop Hero 파일에 든 Noto Sans CJK KR / Noto Sans KR 계열)로 한다. Dave the Diver·Into the Breach 계열이다.
  - 통과 기준: 어느 쪽이든 Open Sans SemiBold가 보이는 화면이 0개이고, 모든 글꼴이 `allow_system_fallback = false`인 상태에서 `.po` 전 문자열에 두부(□)가 0개.
  - 점검: `locale/en.po`의 msgid(한국어)·msgstr(영어) 전 글자에 `Font.has_char()`를 돌리는 스크립트로 빠진 글자 0개를 확인한다.
  - Godot: Theme의 `default_font`, 프로젝트 설정 `gui/theme/custom`(또는 `gui/theme/custom_font`). 대체 글꼴은 Advanced Import Settings의 Fallbacks에 직접 넣는다 ([Godot: Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)).
- [ ] **F2. 도트 글꼴은 설계 크기의 정수배로만 쓴다.**
  - 통과 기준: Galmuri7 = 8, Galmuri9 = 10, Galmuri11 = 12, Galmuri14 = 15(또는 그 2배) ([Galmuri](https://github.com/quiple/galmuri)). Neo둥근모는 16의 배수 ([neodgm 가이드](https://neodgm.dalgona.dev/guides.html)), m5x7은 16·32·48 ([m5x7](https://managore.itch.io/m5x7)). 글꼴 크기 7·9·13·14 같은 중간값과 Control의 비정수 `scale`이 0개.
  - Godot: TTF 도트 글꼴은 Antialiasing Disabled, Hinting None, Subpixel Positioning Disabled, MSDF·Mipmaps 끔으로 가져온다. 4.4부터 subpixel 기본값이 «Auto (Except Pixel Fonts)»이고 4.7은 hinting 기본값도 «Light (Except Pixel Fonts)»라 기본값만으로도 맞을 수 있지만, 값을 명시하는 편이 안전하다 ([ResourceImporterDynamicFont](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/ResourceImporterDynamicFont.xml)). 여러 글꼴은 Project Settings의 Import Defaults로 한꺼번에 맞출 수 있다. BMFont·이미지 글꼴은 `scaling_mode`를 «Enabled (Integer)»로 바꾼다. 기본값은 분수 배율이다 ([TextServer](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/TextServer.xml)). `FontVariation`으로 크기를 키우지 않는다. `variation_transform` 배율은 글리프만 키우고 전진폭(advance)은 그대로라 글자가 겹쳤다는 개발 사례가 있다([DEV](https://dev.to/hssolution/adding-chinese-to-a-pixel-font-godot-game-4-things-that-broke-34eg), AI 작성 표시가 붙은 글 하나). 줄 위아래의 정수 px 보정(`spacing_top`·`spacing_bottom`, L7)에는 FontVariation을 쓴다.
- [ ] **F3. 글자 크기는 2~3단계(+ 숫자 전용 1단계)로 묶는다.**
  - 통과 기준: 예를 들어 8 / 10 / 12, 또는 10 / 12 / 15. 제목과 본문의 구분은 크기를 더 늘리지 않고 굵기(Galmuri11 Bold)·색·밝기로 한다.
  - 근거: Stardew Valley도 주로 셋(Small·Medium·Dialogue)에 작은 숫자용이 따로 있다. 640×360에서 정수 크기 단계가 몇 개 없다는 데서 끌어낸 추론이다.
  - Godot: 크기는 `theme_type_variation`(예: `LabelSmall`·`LabelTitle`)에 `font_size`로 두고, 노드마다 `add_theme_font_size_override`를 거는 곳은 0개로 만든다.
- [ ] **F4. 가장 작은 글자의 하한을 정한다.**
  - 통과 기준: 라틴 대문자 높이 6 기준 px 이상. 이 값은 Steam Deck 권장 12px@2배와 같고, 디센더를 더한 본문 높이로 재면 XAG PC 18px@1080p(6 기준 px)도 넘는다. 한글은 글리프 높이 7 기준 px(Galmuri7, 1080p 21px로 XAG PC 18px 통과) 이상이고, 이 크기는 짧은 고정 라벨에만 쓴다. 툴팁·설명은 Galmuri9(글리프 9 = 1080p 27px, XAG 콘솔 26px 통과) 이상, 두 줄 넘는 글은 Galmuri11(글리프 11 = 1080p 33px, GAG 28px 통과)로 쓴다. 선택지 B의 벡터 한글도 같은 글리프 높이 하한(가장 작은 라벨 7, 툴팁 9, 두 줄 넘는 글 11 기준 px)을 따르고, «가» 높이가 그 값 이상이 되는 `font_size`를 캡처로 정한다. 여기서 높이는 `font_size` 값이 아니라 글리프의 실제 높이다.
  - 점검: 캡처에서 «가»·«H»의 화면 px 높이를 창 배율로 나눈다.
  - 근거: Galmuri 이름의 숫자가 실제 한글·대문자 글리프 높이다(BDF 실측, «가» = 14·11·9·7px). 현재 판(v2.40.0 이상)은 Galmuri7까지 한글 11,172자를 모두 담는다. README의 «4,358자» 각주는 낡은 표기다 ([Galmuri 릴리스 v2.40.0](https://github.com/quiple/galmuri/releases/tag/v2.40.0), [공식 사이트](https://quiple.dev/font/galmuri)).
- [ ] **F5. 두 줄 넘는 글은 줄 간격과 줄 길이를 지킨다.**
  - 통과 기준: 줄 피치가 글자 크기의 1.5배 이상(12px 글꼴이면 18). 촘촘한 HUD는 최소 «글자 사이 빈 줄 ≥ em의 1/4»(추론). 패널 폭 안에서 낱말 중간 줄바꿈이 없다. 영어 문장은 전부 대문자로 쓰지 않는다(1~2단어 라벨은 예외).
  - 근거: [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101). 설정 옵션이 없을 때의 최소값이다. XAG의 한글 한 줄 40자 상한은 12px 글자로 약 480 기준 px라, 약 200px 툴팁(≈16자)에서는 상한보다 잦은 줄바꿈이 실제 문제다(연구 노트 계산).
  - Godot: 줄바꿈은 `autowrap_mode = AUTOWRAP_WORD_SMART`로 둔다. 4.7 Label의 `line_spacing` 기본값은 3이다 ([Label.xml](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/Label.xml)). 피치 = 글꼴 줄 높이 + `line_spacing`이니, 12px 글꼴로 피치 18을 맞추려면 캡처로 줄 높이를 재서 `line_spacing`을 정한다. Theme에서 한 번 정한다.
- [ ] **F6. 자주 바뀌는 숫자는 자릿수 폭을 고정한다.**
  - 통과 기준: 골드·웨이브·체력 숫자가 값이 바뀌어도 옆 요소를 밀지 않는다. 숫자 칸은 고정 폭에 오른쪽 정렬한다.
  - 근거: Galmuri 숫자는 비례폭이다('0' 전진폭 8/6/5px, '1' 6/4/4px, Galmuri11/9/7, 프로젝트 앞선 조사 `ui_research/evidence/web.md`의 BDF 실측). Eastward는 4자리 카운터에 앞자리 0을 어둡게 했다(1부, 스크린숏 두 장에서 본 것이고 자릿수가 고정인지는 추정).
  - Godot: 숫자 Label에 `custom_minimum_size`로 고정 폭을 주고 `HORIZONTAL_ALIGNMENT_RIGHT`로 둔다. 아니면 숫자를 스프라이트로 그린다.
- [ ] **F7. 바쁜 그림 위 글자는 바탕판, 1px 그림자, 외곽선 중 하나로 분리한다.**
  - 통과 기준: 맵 위 숫자·라벨이 C4의 4.5:1을 만족한다. 우선순위는 단색 바탕판 > 1 기준 px 딱딱한 그림자 > 외곽선이다. 그림자 색은 바탕 계열의 어두운 색으로 한다(Stardew Valley #221122 글자 + #CE9C5F 그림자).
  - 근거: [GAG](https://gameaccessibilityguidelines.com/provide-high-contrast-between-text-and-background/)와 [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)는 외곽선과 그림자를 함께 들 뿐 순서를 매기지 않는다. 바탕판을 먼저 두는 것은 [Indieklem #13](https://indieklem.substack.com/p/13-the-basics-of-typography-in-game)이 글자 아래 바탕판을 먼저 권하고 그림자를 덜 효과적인 대안으로 둔 데서 왔다. 그림자를 외곽선보다 앞에 둔 것은 작은 한글 획이 8방향 외곽선에 뭉친다는 추론이다(실무 관행, 1차 출처 없음). 대비 2:1을 넘는 외곽선 픽셀은 글자 높이에 포함해 잰다(XAG 101).
  - Godot: Label 그림자는 «always have a hard edge»다 ([Godot: Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)). `shadow_offset` 기본값은 (1,1)이지만 `font_shadow_color` 기본값은 투명이라 색을 줘야 보인다. 작은 도트 글꼴에서 `outline_size`가 6보다 작으면 안쪽 픽셀이 채워지지 않는다는 열린 이슈가 있다(사용자 한 명의 보고, confirmed 라벨 없음, 4.2.1, 4.7 재현 여부 미확인) ([#88373](https://github.com/godotengine/godot/issues/88373)). 외곽선을 쓴다면 캡처로 확인한다.
- [ ] **F8. 숫자가 아이콘을 덮지 않는다.**
  - 통과 기준: 비용·개수·레벨은 아이콘 모서리 배지나 아이콘 옆 칸에 두고, 아이콘 면적의 4분의 1 이상을 가리지 않는다(제안값).
  - 근거: Loop Hero는 레벨 숫자를 아이템 칸 왼쪽 아래 모서리에 두고([LH-1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_500e7212653fa6586f7a84c89b4c60be4e425fbb.1920x1080.jpg)), 비용은 «자원 아이콘 + 어두운 배지 속 숫자»로 쌓는다([LH-2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_455789884ed94fd20410ac5a139e8c3bb8f6f369.1920x1080.jpg)).
- [ ] **F9. 한국어·영어 두 판을 모두 캡처해 비교한다.**
  - 통과 기준: 두 언어에서 기준선·줄 높이·칸 넘침이 같은 규칙을 지킨다. 영어 전용 도트 글꼴(m5x7 등)을 따로 쓰면 언어별 레이아웃을 따로 확인한다.
  - 근거: Galmuri는 ASCII·Latin-1·Latin Ext-A를 함께 가져 한 글꼴로 두 언어를 쓸 수 있다.

### [도트 아트워크 디테일(9-slice 등)]

- [ ] **A1. HUD 층의 도트 크기는 하나다.**
  - 통과 기준: HUD 아트가 모두 «아트 1px = 1 기준 px»(또는 모두 같은 정수배)다. 1.5배·1.6배 확대와 큰 스프라이트의 비정수 축소가 0개. 맵 줌(월드 층)과 HUD 밀도는 따로 둔다. Stardew Valley가 UI 배율과 줌을 나눈 것과 같다.
  - 점검: 2배 캡처에서 아이콘마다 가장 짧은 같은 색 줄 길이를 잰다. 모두 같아야 한다(전부 1배면 모두 2 화면 px이고, 1·3px 줄은 0%). 어긋남은 L7 점검으로 따로 본다.
  - Godot: 아이콘 `TextureRect`의 크기는 원본 × 정수로 두고, `STRETCH_SCALE`로 원본의 정수배가 아닌 크기(10 → 16 같은)를 주지 않는다.
- [ ] **A2. 전용 아이콘 시트를 만들고 그림 규칙 한 장을 정한다.**
  - 통과 기준: 기본 16×16 캔버스(상태 보조 아이콘 8×8), 같은 외곽선 규칙(두께 1px, 색 규칙), 같은 광원(예: 왼쪽 위), 같은 색 수 상한. «하나만 튀는 아이콘»이 0개.
  - 근거: 광원 하나([Derek Yu](https://www.derekyu.com/makegames/pixelart.html)), 튀는 아이콘 비평([Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)). 16×16 + 8×8 보조 아이콘은 Shattered Pixel Dungeon 소스의 관행이다(프로젝트 앞선 조사 `ui_research/evidence/web.md`).
- [ ] **A3. 베벨·장식 프레임은 9-slice 텍스처로 그린다.**
  - 통과 기준(A5에서 (나)를 고르거나 장식 프레임을 쓸 때. (가)를 고르면 `StyleBoxFlat`을 두고 A7만 지킨다):
    - `texture_margin`(모서리 여백)이 반복되지 않는 테두리 아트(외곽선 + 하이라이트 + 안쪽 그림자 + 모서리 장식) 전체를 덮는다.
    - 변 띠는 진행 방향으로 단면이 일정하다. 그러면 STRETCH와 TILE이 같은 결과를 내 왜곡이 없다. Stardew Valley가 1px 열·행만 늘이는 이유다.
    - 무늬 있는 변(리벳·나뭇결)은 TILE로 두고, 패널 크기를 `모서리 × 2 + n × 무늬 주기`로 맞춘다.
    - TILE_FIT은 타일을 «slightly stretched»하므로 쓰지 않는다.
  - 점검: 패널 폭을 1 기준 px씩 바꿔 가며 캡처해, 변 픽셀이 끊기거나 늘지 않는지 본다.
  - Godot: Theme 안의 `StyleBoxTexture`(Panel·Button·PanelContainer·툴팁에 그대로 들어간다)로 만든다. `axis_stretch_*` 기본값이 STRETCH(0)라는 점에 주의한다 ([StyleBoxTexture](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html), [NinePatchRect](https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html)). NinePatchRect는 한두 번 쓰는 장식 판에만 쓴다. CrossCode는 상자를 9분할로, 높이가 고정된 버튼을 3분할로 만들었다 ([Radical Fish Games](https://www.radicalfishgames.com/?p=1594)).
- [ ] **A4. 프레임은 «묶음»으로 만든다.**
  - 통과 기준: 한 아틀라스(A5에서 (가)를 고르면 Theme 하나)에서 기본 패널 / 보조 패널 / 툴팁 / 버튼 normal·hover·pressed·disabled·focus가 나오고, 외곽선 색과 모서리 모양(예: 직각, 또는 텍스처에 그린 1px 깎은 모서리)이 묶음 전체에서 같다.
  - Godot: Button은 `normal`·`hover`·`pressed`·`hover_pressed`·`disabled`·`focus`를 따로 받는다. `focus`는 기본 상자 위에 겹쳐 그려지므로 외곽선만 있는 반투명 상자가 맞다 ([Button.xml](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/Button.xml)). 변형은 `theme_type_variation`(예: `PanelSub`, `PanelTooltip`, `LabelTitle`)으로 나눈다 ([Theme type variations](https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html)).
- [ ] **A5. 테두리 문법을 하나 고른다.**
  - 통과 기준: (가) Into the Breach·Dave the Diver식 «얇은 단색 1px 선 + 형태로 개성», 또는 (나) Loop Hero식 «위·왼쪽 밝고 아래·오른쪽 어두운 일관된 광원의 베벨 프레임»([LH-1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_500e7212653fa6586f7a84c89b4c60be4e425fbb.1920x1080.jpg)·[LH-2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_455789884ed94fd20410ac5a139e8c3bb8f6f369.1920x1080.jpg) 관찰) 가운데 하나를 HUD 전체에 적용한다. Stardew Valley도 나무 프레임이지만 광원 방향은 화면으로 확인하지 못했다. 장식은 모서리와 위쪽 가운데에 모은다(Celeste).
  - 점검: 화면별 캡처에서 패널마다 테두리 굵기·색·모서리 모양을 표로 적어, 두 문법이 섞인 곳을 센다.
  - 근거: 1부 관찰. 어느 쪽이 «더 프로답다»는 근거는 없고, 섞지 않는 것이 핵심이라는 것은 추론이다.
- [ ] **A6. 외곽선은 1 아트 px로 통일하고, 색은 대상의 어두운 색으로 한다.**
  - 통과 기준: UI 아트의 외곽선 굵기가 모두 같다. 모든 것을 순흑으로 두르지 않고, 대상의 어두운 색이나 선택적 외곽선(어두운 쪽은 어두운 선, 밝은 쪽은 밝은 선)을 쓴다. 외곽선은 대비를 높여야 하며 낮추면 안 된다.
  - 근거: [Lospec](https://lospec.com/articles/pixel-art-outlines-part-2-using-color).
- [ ] **A7. `StyleBoxFlat`을 남긴다면 도트에 맞게 설정한다.**
  - 통과 기준: `StyleBoxFlat`은 `corner_radius_*` = 0만 쓴다. 깎은 모서리가 필요하면 `StyleBoxTexture`(A3)로 모서리 픽셀을 그려 넣는다.
  - 근거: 문서는 45° 깎은 모서리(`corner_detail = 1`)에서 «crisp visuals»를 위해 안티에일리어싱을 끄라고 권한다 ([StyleBoxFlat.xml](https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/StyleBoxFlat.xml)). 다만 이것은 화면 해상도와 같은 UI 기준이다. `canvas_items` 정수배 화면에서는 경사 변이 화면 px로 그려져 아트 격자보다 고운 계단이 생긴다. StyleBoxFlat은 텍스처가 아니라 꼭짓점을 이은 삼각형으로 그리기 때문이다([style_box_flat.cpp](https://raw.githubusercontent.com/godotengine/godot/4.7/scene/resources/style_box_flat.cpp)의 `canvas_item_add_triangle_array`). 꼭짓점은 위치·반경이 정수면 이미 아트 격자 위에 있으므로, 꼭짓점을 맞춰도 계단은 아트 px 굵기가 되지 않는다. `shadow_size` 그림자는 `shadow_color`에서 투명으로 번지는 링으로 그려진다(같은 소스). 그래서 1 기준 px 그림자(td-proj S241의 바깥 1px, `shadow_size 1`)는 2배 이상 화면에서 단색 선이 아니라 옅어지는 띠로 보일 수 있으니 캡처로 확인한다.
- [ ] **A8. 움직임은 형태를 바꾸지 않는 방식으로 한다.**
  - 통과 기준: 비정수 `scale` 트윈과 회전이 0개. 팝업은 «4~8 기준 px 아래에서 올라오기 + 알파 페이드», 2~3장짜리 프레임 애니메이션, 1배↔2배 정수 확대 가운데 하나로 한다. 눌림은 내용을 1 기준 px 내리는 프레임 교체로 한다(`content_margin_top` +1, `bottom` −1, L1 예외 (가)).
  - Godot: Control 위치 트윈은 `snap_controls_to_pixels`가 반올림하지만, Node2D·`draw_*`에서는 보간값을 `round()`해서 넣는다. Calinou(Godot 멤버)는 Control `scale`을 영구 배율로 쓰지 말라고 했다(애니메이션 용도는 허용) ([#86563](https://github.com/godotengine/godot/issues/86563)). 픽셀 UI에서는 그 애니메이션도 정수 배율로 제한한다(추론).
- [ ] **A9. 게이지 채움은 정수 폭으로 한다.**
  - 통과 기준: 채움 폭 = `floor(비율 × 폭)`. 9-slice 게이지의 최소 폭은 모서리 × 2 이상이다(추론).
  - Godot: `draw_rect`로 그리는 막대는 폭에 `floor()`를 씌운다. `TextureProgressBar`는 캡처로 끝 픽셀을 확인한다.
- [ ] **A10. 디더·질감은 장식 층에만 둔다.**
  - 통과 기준: 글자 뒤 패널 가운데 칸은 단색이고, 디더·잡음 질감은 테두리 장식이나 화면 전환에만 쓴다.
  - 점검: 글자가 있는 패널의 가운데 칸을 캡처에서 잘라 색 수를 센다(1색이어야 한다).
  - 근거: 디더를 모든 곳에 쓰면 TV 잡음처럼 지저분해진다는 실무 글(신뢰도 중간 이하)과, 디더 패턴이 1px 획 글자와 같은 공간 주파수라는 점에서 낸 추론이다.

### 먼저 고칠 순서

공개된 인디 개편 일지들(Unicopia·Day 16·Kobold Crawler·Shardpunk·Return·Tenril)에서 바뀐 것을 묶으면 격자 통일·글꼴 교체·색에 뜻 부여·정보 묶기·버튼 질감의 다섯 갈래다. 이 순서를 그대로 밟은 일지는 없다. 격자를 먼저 고쳐야 나머지가 티가 난다는 것은 Unicopia·Day 16 사례에서 낸 추론이다. td-proj에 맞추면 다음 순서를 권한다.

1. **F1·F2 글꼴 전략 결정과 기본 글꼴 제거.** 화면에서 가장 넓게 밀도가 어긋난 곳이 글자다. 아래 대조 참고. 한글이 커지므로(툴팁 8 → Galmuri9 10, «웨이브» 7 → 8) 같은 단계에서 L8 넘침 점검(두 언어 최장 문자열 캡처)을 함께 한다. 위 띠 칸(높이 24, «웨이브» 자리 26×11)과 `clip_text` 7곳은 크기가 고정이라 글자가 커지면 넘치거나 잘릴 수 있다. 같은 캡처에서 아이콘+숫자의 세로 가운데(L7 세로)도 본다.
2. **A1·A2 HUD 도트 밀도 통일과 전용 아이콘 시트.** 1.6배 아이콘과 비정수 축소 대역부터 바꾼다.
3. **C1·C3·C6·C9 색 상수 정리.** 두 단계로 나눈다.
   - 3a. **테두리 대비(C3).** `LINE`에서 테두리용 상수를 먼저 나누고 테두리만 3:1 이상으로 올린다. `LINE`은 막대 바탕·신뢰 점·빈 칸 점선도 겸하므로 `LINE`째 바꾸지 않는다(대조의 C3 행). 아이콘 시트와 무관하고 바꿀 hex가 평가 파일에 박혀 있지 않으니, 2단계(A1·A2 도트 밀도 통일과 아이콘 시트)보다 먼저 해도 된다. 다만 위 띠·툴팁·토스트 테두리는 S241이 «그대로다»라고 정한 곳이라, 바꾸려면 사용자 결정과 SPEC 문장 개정이 필요하다.
   - 3b. **hex 정리와 순색 교체(C1·C6·C9).** 흩어진 hex 32종과 순색을 걷어 낸다. 테마 상수는 한 파일이지만 SPEC·평가 개정이 따른다(아래 대조의 넷째 참고).
4. **A5 테두리 문법 결정과 프레임 마감.** (나)를 고르면 A3·A4대로 9-slice 묶음을 아틀라스 하나와 Theme `.tres` 하나로 만든다. (가)를 고르면 `StyleBoxFlat`을 두고 3a의 테두리 색을 쓴다(C3).
5. **L1·L3·L7 여백 토큰, 가장자리 여백, 정렬.**
6. **L6·A8 상황별 HUD와 움직임.**
7. **L9 제목 그림과 게임 이름.** 사용자가 먼저 게임 이름을 정한다(지금은 `config/name="td-proj"`). 착수 전에 제목·설정 화면을 캡처해 대조 표의 가설을 확인한다.

제목·설정·ESC 화면의 나머지(L9)는 따로 단계를 두지 않는다. 이 화면들은 `menus.gd:26`에서 `HudTheme.make(12)`를 받으므로 1·3·4단계가 그대로 들어간다. 기본 모양으로 남는 부품(CheckButton 스위치 아이콘, HSlider, OptionButton 화살표, PopupMenu)은 3·4단계에서 `make()`를 고칠 때 함께 넣는다.

## td-proj 대조: 기반 설정은 맞고, 글꼴·아이콘 밀도·프레임이 비어 있다

아래는 연구 노트 `td_proj_current_ui.md`(main `0e7952a` 기준 코드·설정·기존 캡처 감사)를 체크리스트에 대 본 것이다. `project.godot`, `src/ui/hud_theme.gd`, `src/` 글꼴 참조, 표에 인용한 `battle_view.gd`·`hud_build.gd`·`hud_evac.gd`·`hud_shop.gd`·`hud.gd`의 줄, SPEC S73·S199·S209·S241과 평가 파일의 `ef3a0c`는 이번에 직접 다시 확인했다. 표는 체크리스트 네 갈래 순서(L→C→F→A)이고, «첫 수정» 칸은 바로 손댈 파일:줄과 값의 예다. 대비 수치는 WCAG 식으로 직접 계산했다. 캡처 수치는 기존 캡처 `hq_shop_research/img/now_battle.png`(11-12, 2배)에서 잰 것이다. 11-12 이후 화면(거점 패널 #351·#352)과 제목·설정·결과 창은 캡처가 없으므로, 그 화면에 관한 서술은 **가설**이다. 각 문제와 «아마추어 같다» 피드백 사이의 인과도 가설이다.

| 체크 | 지금 상태(근거) | 판정 | 첫 수정(파일:줄 → 바꿀 값) |
|---|---|---|---|
| 기반: 렌더 | 640×360, `canvas_items` + `integer`, Nearest, 정수배 창, 처음엔 전체화면(1080p 3배·4K 6배) (`project.godot:12-17,26`, `main.gd:231-248`) | 통과 | — |
| 기반: 도트 글꼴 가져오기 | `Galmuri7.ttf.import`: antialiasing 0, hinting 0, subpixel 0, system fallback false, MSDF·mipmaps 끔 | 통과 | — |
| L1 간격 | 위 띠 칸 사이가 4·2·6·4·4·4·4px(`hud.gd:75-78`, «임시값»)이다. 장비 줄은 1px이고, 이 값은 SPEC I293 ④가 정했다. 유물 다섯 줄과 미션 판정·전리품 줄이 함께 있어도 라운드 사이 창 아래끝이 356 이하여야 하는데(I136, EV1073), 캡처로 잰 아래끝이 354라 여유가 2px뿐이다(`gimmick_research/05_dungeon_expedition.md:1211`). 선택 패널 «여럿» 모드는 24×20 칸이 7개씩 3줄이고, 칸마다 바로 아래에 2px 체력 막대가 붙어 한 줄 높이가 22px다. 칸 사이는 3px, 막대 끝에서 다음 줄까지는 1px, 위 여백 3·아래 여백 1이다(`hud_select.gd:92-93,104-105`). 컨테이너 separation은 0~3·8. 패널 안쪽 여백은 Godot 기본 테마 값을 복사한다(`hud_theme.gd:37-40`) | **미달** | `hud.gd:76` 공병 칸 x 130 → 132(위 띠 칸 사이가 모두 4가 된다). 장비 줄 1px는 L1 예외 (나)로 두고 이름 붙인 상수로 옮긴다. 선택 패널 «여럿» 모드를 위아래 여백 4·줄 사이 2로 놓으면 4+22×3+2×2+4 = 78로 6px 넘친다. 칸 높이를 2px 줄이면(버튼 18 + 막대 2) 4+20×3+2×2+4 = 72에 맞는다. 가로는 칸 사이 2·좌우 여백 8이면 8+24×7+2×6+8 = 196으로 맞는다. 패널 안쪽 여백은 토큰 값으로 정해 `hud_theme.gd` `box()`에서 준다 |
| L3 가장자리 | 아래 패널 셋(거점 [92,262,216,98], 선택 (312,288) 196×72, 건설 격자 (510,288) 130×72)이 아래 끝에 0px로 붙고, 건설 격자는 오른쪽 끝에도 붙는다(`hud_keep.gd:10`, `hud_select.gd:33-34`, `hud_build.gd:46-47`). 미니맵 (2,295), 왼쪽 열 버튼 x 3. 위 띠 [0,0,640,28](`hud.gd:300-302`)은 화면 폭 띠라 예외지만, 띠 안 상태 칸 x 4, 메뉴 칸 끝 636 → 오른쪽 4px | **미달** | 아래 패널 셋과 왼쪽 열을 화면 끝에서 8 떨어지게 다시 놓는다(자리를 정한 SPEC 문장도 함께). 위 띠 칸은 양 끝 4 → 8(칸 폭을 합쳐 8 줄여야 들어간다. 예: 진행 칸 136 → 128) |
| L4 고정 구역 | HUD가 위 띠·왼쪽 열·아래 패널 셋의 고정 자리에 있다(S185), 공용 툴팁(`hud_tip.gd`) | 통과 | — |
| L8 넘침 | `clip_text` 7곳(예: `hud_build.gd:93`) | 확인 필요 | 두 언어 최장 문자열을 넣어 캡처한다(L8 점검). 글꼴을 바꾸면 바로 다시 본다 |
| L9 첫인상 | 제목 화면은 단색 `Color(0.08,0.08,0.1)` 배경에 버튼만 있고 로고·그림이 없다(`menus.gd:46-58`). 버튼 상자는 HudTheme을 물려받는다(`menus.gd:26` `HudTheme.make(12)`). 설정의 CheckButton 스위치 아이콘·HSlider·OptionButton 화살표·PopupMenu 목록만 기본 모양일 것이다(`menus.gd:81,114,185`, 화면 미확인 = 가설) | **미달**(가설 포함) | `menus.gd:46` 단색 배경 → 제목 그림·게임 이름(먼저 고칠 순서 7). `hud_theme.gd` `make()`에 CheckButton·HSlider·OptionButton·PopupMenu 항목을 더한다 |
| C1 팔레트 | 테마 상수 11개(`hud_theme.gd:5-15`) 밖에 hex 32종, `Color.WHITE` 12회, `BLACK` 7회, `GREEN` 1회가 흩어져 있다 | **미달** | hex 32종을 `hud_theme.gd` 상수로 옮긴다(많은 순 `hud_keep.gd` 12종, `hud_minimap.gd` 8종) |
| C2 월드 팔레트 | 테마 11색 중 아트 팔레트 f24p에 있는 색은 DANGER 하나다 | 권장 미충족(아래 후보 참고) | `hud_theme.gd:5-15` 값을 아래 «색 후보»로 바꾼다(SPEC·평가는 «넷째» 참고) |
| C3 경계 대비 | CELL #23262f / PANEL #14161c = 1.20:1, LINE #3a3f4b / CELL = 1.43:1, LINE / PANEL = 1.72:1. HOVER #6b7280 / CELL = 3.13:1 | **미달**(평상시 칸 경계), hover만 통과 | 테두리용 상수를 `LINE`에서 먼저 나누고, 그 색만 바탕 대비 3:1 이상으로(후보 `7a86a0`은 바탕 `151a26` 위 4.76:1). `LINE`째 바꾸지 않는다. `LINE`은 보스·진행 막대 바탕(`hud.gd:621,1076`), 신뢰 점 꺼짐(`hud_evac.gd:83`), 빈 영웅 칸 점선(`hud.gd:1567`)도 겸해서, `7a86a0`으로 바꾸면 막대 바탕/DANGER 채움이 2.65 → 1.09:1, 신뢰 점 켜짐(ACCENT)/꺼짐이 7.47 → 2.59:1로 떨어진다. 버튼과 건설 칸 테두리는 평상시 `LINE` → hover `HOVER` → 눌림 `ACCENT`로 밝아지므로(`hud_theme.gd:21`, `hud_build.gd:117,127`), 새 테두리색이 HOVER(`6b7280`)보다 밝으면 HOVER도 함께 올린다. 아래 패널(건설 격자·정보 칸·선택·힌트·거점)은 `framed()`가 테두리를 이미 `6b7280`(PANEL 위 3.74:1)으로 바꾼다. 다만 `framed()`는 테두리가 `LINE`일 때만 바꾸므로(`hud_theme.gd:48`), 테두리 상수를 나누면 이 비교도 함께 바꾼다. 안 그러면 아래 패널이 `6b7280`을 잃어 EV571이 깨진다. 새 상수로 올릴 곳은 칸·버튼(테마 Button, 건설 칸, 선택 패널 칸, 거점 탭·카드), 기본 PanelContainer 테두리를 쓰는 창, 인구 칸(`hud.gd:322`), 거점 설명 상자(`hud_keep.gd:104`)다. 이 가운데 위 띠·툴팁·토스트 테두리(`hud.gd:302`, `hud_tip.gd:30`, `hud_toast.gd:24`)까지 바꾸는 것만 S241의 «위 띠·툴팁·토스트는 그대로다»를 바꾸는 사용자 결정이다 |
| C4 글자 대비 | TEXT / CELL 12.3:1, DIM / CELL 5.7:1은 통과. DANGER #ef3a0c는 불투명 PANEL 위 4.55:1, α0.92 패널이 밝은 배경 위일 때 최악 3.67:1, CELL 위 3.80:1 | **미달**(DANGER 글자) | 막대 채움은 두고, 글자용 밝은 위험색 상수를 따로 둔다(C9). DANGER 글자 예: `hud_build.gd:91`(이유 줄), `hud.gd:701`(인구 상한) |
| C5 반투명 | PANEL α0.92는 최악(흰) 배경에서도 TEXT 11.9:1이다. 안내 칩(검정 65%, `hud.gd:424-428`)도 글자색이 테마 기본 TEXT라면 5.7:1로 통과한다. 단 DIM 글자를 얹으면 2.7:1 | 통과(DIM을 얹을 때만 주의) | — |
| C6 순색 | 맵 위 영웅·용병·적·보스 체력 막대가 `Color.GREEN` #00ff00 + 검정 바탕이고(`battle_view.gd:4792-4798`), 체력바 버튼 그림도 같은 순색이다(`hud.gd:550`). DANGER 채도 .95, 미니맵 적 점 #ff3b3b | **미달** | `battle_view.gd:4798` `Color.GREEN` → `HudTheme.GOOD`(7cc85a), `hud.gd:550`의 `"g"`도 같게(S73, «넷째» 참고) |
| C7 색 하나에 뜻 하나 | `ef3a0c` 하나가 적 팀 색(`battle_view.gd:307`, S166), 위험 글자(`hud_build.gd:91`), 막대 25% 밑(`battle_view.gd:241`, `hud.gd:1042`), 인구 상한 글자(`hud.gd:701`), 미션 실패 표시(`hud.gd:1112`)를 겸한다 | **미달** | 적 팀 색과 막대 채움은 두고, 글자 쪽(위험·상한·실패)은 C9의 글자용 색으로 나눈다 |
| C8 색 + 다른 신호 | 건설 칸 비용 3단계(TEXT / WARN e0c040 / DANGER)가 칸 위에서는 글자색으로만 갈린다(`hud_build.gd:112`). 마우스를 올리면 정보 칸에 «골드 N 모자람» 줄이 뜬다(`hud_build.gd:260-261`) | **미달**(칸 위) | 부족할 때 칸에 Loop Hero식 «가진 양/필요량» 꼴이나 경고 점을 붙인다 |
| F1 글꼴 | `src/`에서 글꼴을 쓰는 곳은 `battle_view.gd:247`의 Galmuri7(맵 위 숫자) 하나다. `HudTheme.make()`는 `default_font_size`만 준다(`hud_theme.gd:17-19`). 따라서 HUD·메뉴는 Open Sans SemiBold로 그려지고 한글은 OS 글꼴로 채워진다. OS 글꼴 이름은 미확인(맑은 고딕 추정 = 가설) | **미달** | `hud_theme.gd:17-19` `make()`에 `t.default_font`를 지정한다(선택지 A면 Galmuri, B면 함께 넣은 한글 글꼴 + 숫자용 도트 글꼴) |
| F1 밀도 | 캡처에서 HUD 글자 «남은 적 36»은 화면 1px 줄이 77.9%, 색 178종이다. 같은 HUD의 1배 아이콘(동전)은 줄 길이 2·4 화면 px다 | 선택지 A 기준 **미달**. 선택지 B면 숫자·짧은 라벨만 미달 | F1 첫 수정을 따른다 |
| F2·F3 크기 | 코드에서 따로 준 크기가 7px 17곳, 8px 29곳, 9px 15곳, 10px 6곳, 12px 1곳이다. 여기에 글자가 넘치면 한 단계 줄이는 `_fit`·`_fit_button`(`hud_keep.gd:642-647`, S193·I299 ①)이 6을 더해 여섯 단계다. 6·7·9는 Galmuri 어느 설계 크기의 정수배도 아니다(선택지 A를 고를 때) | **미달**(크기 여섯 단계, F3) | 크기를 Theme 변형 2~3개로 묶는다(F3 Godot). 넘칠 때 한 단계 줄이는 것도 override 대신 아래 단계 변형으로 바꾼다(6은 F4 하한 밑이다). 선택지 A면 7 → 8, 9 → 10이다. 그러면 줄이는 네 곳(`hud_keep.gd:554,562,571,609`)은 가장 작은 단계 8에서 더 내려갈 단계가 없으니, 글자를 줄이지 말고 영어 문구를 줄여 칸에 맞춘다(S193 «HUD 칸 크기·자리를 바꾸지 않고») |
| F4 한글 하한 | 한글 `font_size` 7(Open Sans + OS 대체 글꼴이라 한글 글리프 높이는 7 기준 px 미만): `hud.gd:1097·1116`(웨이브), `hud_keep.gd:101·255·309`. 프로젝트 자체 규칙 «한글은 8 밑으로 쓰지 않는다»(`ui_research/README.md:728`)와도 어긋난다 | **미달** | 위 다섯 곳을 8 이상으로(선택지 A면 Galmuri7 = 8) |
| F7·F8 | 건설 칸 비용은 `Color.WHITE` + 검정 `outline_size 3`(`hud_build.gd:154,165-166`)이다. 캡처에서 숫자가 아이콘 아래 절반을 가린다 | **미달** | `hud_build.gd:154-157` 비용 Label을 칸 모서리 배지로 옮기고 글자색은 `HudTheme.TEXT`로 |
| A1 도트 크기 | 1배(COIN·FLAG), 2배(ATTACK·CROWN), **1.6배**(종 `hud_evac.gd:9,34-39`, 투구 `hud_shop.gd:7,29-32`), 비정수 축소(시설 96→16 `hud_build.gd:144-147`, 거점 80→10 `hud.gd:1012`)가 한 화면에 있다. 캡처에서 투구는 3·6·7px 줄(3.2px 블록), 건설 아이콘은 1px 줄 50.8%다 | **미달** | `hud_evac.gd:38` `bell.size` 16×16 → 20×20(2배) 또는 10×10(1배), `hud_shop.gd:29-32` 투구도 같게 |
| A2 아이콘 규칙 | ASCII 도트 아이콘(1~3색, 외곽선 없음, `hud.gd:87-118`)과 외곽선 `151a26`을 두른 다색 스프라이트(`tools/art/gear.py`)가 섞여 있다. 전용 UI 텍스처는 `gear.png` 96×24 하나다 | **미달** | `tools/art/gear.py`처럼 HUD 아이콘 시트 생성기를 두고 대역 아이콘(`hud_build.gd:180-198`)을 바꾼다 |
| A3 프레임 | 모든 패널이 1px `StyleBoxFlat` 직각 상자이고 «두 겹»은 `shadow_size 1`이다(`hud_theme.gd:36-52`). `StyleBoxTexture`·`NinePatchRect`·Theme `.tres`가 0개이고, `tools/art/`에 UI 프레임 생성기가 없다. 문법은 1부 Into the Breach(#0c0f16, 1 기준 px 테두리, 직각, 드롭 섀도)와 같은 (가)다 | (가)를 고르면 통과 후보. 남은 일은 테두리 대비(C3, 지금 LINE / PANEL 1.72:1 → Into the Breach 2.81:1, 칸 경계는 3:1)와 형태 개성. (나)를 고르면 미달 | (가): 테두리용 상수를 `LINE`에서 나눠 그 색만 올린다(`LINE`째 바꾸면 안 되는 이유는 C3 행). (나): `tools/art/`에 프레임 생성기를 두고 `StyleBoxTexture`로 바꾼다 |
| A4 상태 수 | normal·hover·pressed·hover_pressed·focus·disabled를 모두 정의했고, focus는 투명 바탕 + 강조 테두리(외곽선형)다(`hud_theme.gd:20-23`) | 통과 | — |
| A9 게이지 | 맵 위 막대 채움 폭이 `bar.size.x * b.hp / b.max_hp`라 정수가 아니다(`battle_view.gd:4793`) | **미달** | `battle_view.gd:4793` 폭에 `floor()`를 씌운다 |

**이미 상용 수준인 것.** 정수배 창과 Nearest, 도트 글꼴 가져오기 설정, 강조색을 하나로 정한 규칙, 정해진 HUD 자리, 기호를 글꼴 대신 그림으로 그리는 규칙(S30), 원인별 비활성 표시(흐림 0.35 + 정보 칸 이유 줄), 창의 정수 배율로 키우는 12×12 도트 커서 4종(S278), 0.2초 지연 뒤 조작 바로 아래에 붙어 뜨고 커서를 따라가지 않는 툴팁(S187)은 체크리스트 기준을 이미 만족한다. 다시 손댈 필요가 없다. 비용 색 3단계는 색으로만 갈려 C8 미달이고, 색 상수는 테마 밖에 흩어진 hex가 많아 C1 미달이다(위 표).

**색 후보(계산값, 결정은 사용자 몫).** `tools/art/palettes.json`의 f24p에는 지금 HUD와 색상이 가까운 차가운 중립 램프 `151a26 · 262d3d · 3a4357 · 56607a · 7a86a0 · a4aec2 · d0d6e0`이 들어 있다. 이 램프로 바탕 `151a26`, 칸 `262d3d`, 테두리 `7a86a0`, 본문 `d0d6e0`, 보조 `a4aec2`를 잡으면 대비는 다음과 같다. 테두리는 바탕 위 4.76:1, 칸 위 3.77:1로 C3을 통과한다. 본문은 바탕 위 11.9:1, 칸 위 9.4:1이다. 보조 글자는 칸 위 6.2:1로 C4를 통과한다. 강조 후보 `efd8a1`은 바탕 위 12.4:1이다. 글자용 위험색으로는 지금 DANGER `ef3a0c`(바탕 위 4.37:1, 미달)보다 f24p 주황 `ef692f`(5.57:1)가 맞고, `ef3a0c`는 막대 채움으로 돌린다(C9). 이 램프는 풀·흙 색이 아니라서, `hud_theme.gd:2`의 근거 주석 «풀·흙 색은 쓰지 않는다»와 충돌하지 않는다.

다만 이 후보도 체크리스트를 다 지키지는 않는다. ① `ef692f`는 칸 `262d3d` 위에서 4.41:1이라 C4 미달이다. 위험 글자는 바탕 위에만 쓰거나, 칸 위에서는 경고 아이콘을 붙인다(C8). 아니면 f24p 밖에서 한 단계 밝은 주황을 하나 더한다. f24p의 붉은·주황 계열(색상 0~50°, 채도 0.4 이상)에서 칸 위 4.5:1을 넘는 것은 노랑-주황 `efac28`(6.95:1)과 살구색 `efb775`(7.67:1)뿐이다(계산값). ② 이 램프는 색상이 약 218~223°로 거의 고정이라 C2가 권하는 색상 이동은 없다. C2는 권장이라 미달은 아니고, 원하면 밝은 끝을 따뜻하게 옮긴다. ③ 바탕 `151a26`은 장비 아이콘 외곽선 색(`tools/art/gear.py`)과 같아서, 그 패널 위에서는 아이콘 외곽선이 사라진다(A6 «외곽선은 대비를 높여야 한다»에 어긋남). 바탕을 바꾼다(C2 예외). `151a26`은 장비 아이콘만이 아니라 유닛 그림 전반의 외곽선이라(`tools/art/chronos.py`·`hero.py`·`goblin.py` 등) 아이콘 외곽선만 바꿔서는 풀리지 않는다. `151a26`은 이 램프의 가장 어두운 단이니, 바탕을 램프 밖 색으로 정하면 위의 대비 값과 C5 표의 «후보» 행도 새 바탕으로 다시 계산한다. 지금 PANEL `14161c`도 `151a26`과 1.04:1이라 같은 문제가 이미 있고, 팔레트를 공유해서 생기는 문제는 아니다. ④ 칸/바탕은 1.26:1로 지금(1.20:1)과 거의 같아 칸 덩어리는 명도만으로 갈리지 않는다. 대신 테두리 `7a86a0`이 칸 위 3.77:1·바탕 위 4.76:1이라 C3은 테두리로 통과한다. 칸 채움을 지금 PANEL 대비 3:1로 올리는 길(예: `5b637a`, 3.02:1)은 보조 글자가 그 위에서 3:1 밑(DIM `9aa0aa` 2.27:1, 후보 `a4aec2` 2.68:1)이 되어 C4에 못 미친다.

**근거 결정과 부딪치는 곳(확인 필요).** 첫째, **글꼴(F1)은 S30과 얽혀 있다.** S30은 2026-10-19 «HUD만 고해상도»로 정해졌다. 4K 전체화면에서 기준 해상도로 그린 글자가 6배로 커지며 뭉개졌기 때문이다. 2026-10-21에는 «글자만 화면 해상도로 그린다»가 덧붙었다(`SPEC.md:138`). 앞선 조사는 «난잡함의 원인은 글꼴이 아니다»라고 결론 냈다(`ui_research/README.md` 1.3). 선택지 A(Galmuri 정수배)도 `canvas_items` 오버샘플링으로 화면 해상도에서 래스터화되므로, 기준 해상도 글자를 6배로 키울 때 생긴 4K 뭉개짐은 다시 생기지 않을 것으로 본다. 2배 캡처에서 맵 위 Galmuri7 숫자가 이미 맵 도트와 같은 블록 글자로 찍혀 있다는 것(`vfx_research/img/now_ignis_e_crop3x.png`)이 근거다. 다만 4K 캡처로 확인하지는 않았으므로 추론이다. 하지만 글자의 생김새가 바뀌므로 S30의 의도를 바꾸는 결정이다. 선택지 B(함께 넣은 고해상도 한글 글꼴 + 숫자용 도트 글꼴)는 S30의 문구에 더 가깝다. 어느 쪽이든 «Open Sans + OS 대체 글꼴»을 없애는 부분은 S30과 충돌하지 않는다. 이미 2026-10-19 인수인계 메모가 «글꼴 파일을 게임에 함께 넣는다»고 제안했지만 반영되지 않았다(`handoff/archive/2026-10-19-2/r7.md:106`). 둘째, **스냅 설정은 바꾸지 않기를 권한다.** Godot 문서는 `snap_2d_transforms_to_pixel`만 켜라고 권한다. 그러나 td-proj는 S30 2026-10-25 «위치 반올림을 뺀다»는 사용자 결정에 따라 `snap_2d_vertices_to_pixel`만 켰다(`project.godot:25`). HUD Control 위치는 `snap_controls_to_pixels`가 이미 기준 px로 반올림하므로, UI 마감 때문에 이 결정을 뒤집을 필요는 없다. 셋째, **대역 아이콘의 비정수 축소(A1)는 S30 2026-10-21이 «전용 아이콘이 생기기 전까지» 허용한 임시 조치**다. 전용 아이콘 시트(A2)를 만들면 S30이 스스로 정한 다음 단계를 밟는 셈이다. 1.6배 종·투구는 이 허용 범위 밖이다. 넷째, **색 교체는 사용자 결정과 평가를 함께 바꾼다.** 하단 패널 안쪽 테두리 `6b7280`은 사용자가 시안 셋 가운데 고른 값이다(S241). 미니맵 테두리는 안쪽 색을 맵 가장자리 성벽 점 `9aa0aa`(DIM)와 갈리게 정했다(S209 2026-10-28). 유닛 막대를 초록으로 둔 근거는 «빨강 `ef3a0c`가 적 팀 색과 같아 유닛 막대에 쓰면 뜻이 겹친다»이고(S73 2026-10-27), 구조물·성곽·거점 막대 색은 S199가 `7cc85a`·`e0c040`·`ef3a0c`로 정했으며 위 띠 거점 막대(S190)도 같은 색을 쓴다. `ef3a0c`는 SPEC 7개 문장과 평가 파일 7개(`tests/eval/gd/`의 `hud.gd`·`keep.gd`·`debuff.gd`·`night.gd`·`towercap.gd`·`troll.gd`·`wolfart.gd`)에 박혀 있다. 그러니 C6·C9와 위 색 후보는 이 문장들을 바꾸는 결정이고, 평가 파일도 함께 고쳐야 한다. 테두리 후보 `7a86a0`은 맵 성벽 돌 조각 색 `STONE`(`battle_view.gd:243`, «F24+ 성벽 돌색»)과 같으니, 하단 패널이 성벽 위에 올 때도 캡처로 본다. 다섯째, **간격 토큰(L1)은 I293 ④의 장비 줄 1px와 부딪친다.** I293 ④는 유물 다섯 줄과 미션 판정·전리품 줄이 함께 있어도 라운드 사이 창 아래끝이 356 이하가 되도록 장비 칸의 줄 사이를 1px로 정했다(EV1073). 그래서 이 값은 L1의 1px 예외 (나)로 두고 이름 붙인 상수로 옮긴다. 지금 아래끝이 354라 여유가 2px뿐이어서, 줄 사이를 토큰 값으로 넓히려면 I293 ④와 창 높이(I136)를 함께 다시 정해야 한다.

**확인하지 못한 것.** HUD 한글을 채우는 실제 시스템 글꼴 이름, 3·4·6배 전체화면에서 글자·아이콘이 어떻게 보이는지(캡처가 모두 2배), 11-12 이후 main 화면, 제목·설정·ESC·영입·결과 창은 캡처로 확인하지 못했다. 체크리스트의 «점검» 칸대로 관찰 하네스로 장면별 캡처를 찍으면 위 가설을 사실로 바꿀 수 있다.

## 결론

이번 조사에서 가장 쓸모 있는 발견은 «아마추어 티»의 대부분이 **그림 실력이 아니라 시스템의 부재**라는 점이다. 다섯 상용작에서 공통으로 관찰된 것은 화풍이 아니라 한 층 안의 일관된 규칙, 곧 글꼴마다 정해진 역할, 색마다 정해진 뜻, 반복되는 선·모서리 문법이다. 프레임을 아틀라스 하나의 부품으로 묶는 것은 Stardew Valley·CrossCode에서 확인된 방식이고, 나머지 게임은 확인하지 못했다. 이 규칙들은 Godot에서 Theme 리소스 하나, 팔레트 표 하나, 아이콘 시트 하나로 구현되고, A5에서 (나)를 고르면 9-slice 아틀라스 하나가 더해진다. td-proj는 렌더 기반(정수배, Nearest, 도트 글꼴 가져오기)을 이미 갖췄다. 그래서 개선 작업은 화면을 새로 그리는 일이 아니라 흩어진 값(글꼴 크기 여섯 단계, hex 32종, 1.6배 아이콘, 0~4px 여백)을 이 자산들로 모으는 일에 가깝다.

남는 갈림길은 글꼴 하나다. 상용작에도 «전부 도트»(Stardew Valley), «규칙 있는 하이브리드»(Dave the Diver, Into the Breach), «UI 층 전체 고해상도»(Celeste)가 모두 있다. 그러니 어느 쪽이 맞는지가 아니라 **의도 없이 엔진 기본값과 OS 글꼴이 섞인 지금 상태를 벗어나는 것**이 핵심이다. 월드 층(카메라 줌 1~3배)과 HUD 층의 도트 밀도를 따로 다뤄도 된다는 점도 중요하다. Stardew Valley가 UI 배율과 줌을 나눴듯, 맞춰야 할 것은 맵과 HUD 사이가 아니라 HUD 안이다.
