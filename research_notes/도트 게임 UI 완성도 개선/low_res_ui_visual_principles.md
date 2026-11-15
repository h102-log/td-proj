# 저해상도(640x360) 픽셀 UI의 레이아웃·색·글자 원칙

> 읽는 법: 이 노트에서 «게임 px»은 640x360 기준 뷰포트의 1픽셀, «기기 px»은 실제 화면 픽셀이다. 정수 배율에서 1 게임 px = 720p에서 2 기기 px, 1080p에서 3 기기 px, Steam Deck(1280x800)에서 2 기기 px다. 지침의 «1080p 기준 N px»은 화면 높이 대비 비율이므로 게임 px로는 N/3이고, 720p에서도 같은 값이 된다(비율이 같으니까). 숫자 환산과 계산은 모두 «Inferences»에 두었고, 원 출처가 말한 것만 «Cited Findings»에 두었다.

## 1. 저해상도의 격자·여백·안전 영역·HUD 비중·위계

### Takeaway
공식 가이드는 8단위 격자(세부는 4단위), 화면 가장자리 안전 영역(TV는 안쪽 90%가 title-safe)을 준다. 640x360으로 옮기면 «기본 단위 4 게임 px(세부 2 px), 화면 가장자리 여백은 PC 8 px 이상, TV·콘솔 대비면 좌우 32 px·상하 13~18 px»가 된다. HUD 면적 비중에 대한 공식 수치는 찾지 못했다.

### Cited Findings
- Material Design(2판)은 대부분의 치수를 8dp 격자에 맞추고, 아이콘·글자·컴포넌트 안의 일부 요소는 4dp 격자에 맞춘다. 패딩은 8dp 또는 4dp 단위로 잰다. 버튼·목록 항목 안 가운데 정렬 글자는 4dp 격자에서 벗어나도 된다고 한다(검색 요약 기준, 원문 미확인) — [Material Design: Understanding layout](https://m2.material.io/design/layout); 4pt 격자를 기본으로 쓰자는 반론도 있다(업계 의견) — [uxdesign.cc: Goodbye 8-point grid](https://uxdesign.cc/goodbye-8-point-grid-hello-4-point-grid-1aa7f2159051)
- Xbox GDK의 화면 영역 정의: action-safe = 렌더링 화면 안쪽 95%, title-safe = 안쪽 90%. 1080p에서 action-safe는 1792x1016, title-safe는 1720x1000이다. 같은 문서에서 title-safe 경계를 «좌우 가장자리에서 96 px, 위아래에서 40 px»로도 적는다(1720x1000과 96 px 사이에 4 px 차이가 있어 문서 안에서도 숫자가 조금 어긋난다). «모든 중요한 내용·글자·UI는 title-safe 안에» 그려야 한다 — [Xbox devdocs: Screen areas](https://devdocs.xbox.com/build/core-features/graphics/overviews/screen-areas)
- 같은 문서: 1080p에서 좌우 32 px, 위아래 8 px에는 시스템 UI가 상시 겹칠 수 있으니 게임 UI를 두지 말 것 — [Xbox devdocs: Screen areas](https://devdocs.xbox.com/build/core-features/graphics/overviews/screen-areas)
- 옛 XNA 시절 문서는 HDTV title-safe를 안쪽 90%, 비HDTV는 85%로 두고, 호환을 위해 중요한 UI는 안쪽 85%에 두라고 권했다(현재 GDK 문서가 더 권위 있음) — [XNA: Xbox 360 Programming Considerations](https://learn.microsoft.com/en-us/previous-versions/windows/xna/bb203938(v=xnagamestudio.10))
- Godot `scale_mode = integer`는 배율을 내림해 정수로 만들고(2.5 → 2.0), 남는 공간은 네 변 모두 검은 띠로 채운다. 문서 예시: 640x360 뷰포트를 1366x768 창에 띄우면 1280x720(2배)로 그려지고 둘레에 띠가 생긴다 — [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- Godot 문서는 픽셀 아트 기준으로 «640x360은 1280x720, 1920x1080, 2560x1440, 3840x2160으로 (띠 없이) 정수 배율이 되는 좋은 기준»이라고 한다. `stretch aspect`가 `keep`이면 한 화면비에 띠를 두고, `expand`면 여러 화면비를 받아 기준 폭·높이 둘 다 고정하지 않는다 — [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- Steam Deck OLED 화면은 7.4인치, 1280x800 — [Steam Deck tech specs](https://www.steamdeck.com/en/tech). Valve는 1280x800(우선)이나 1280x720 지원을 권한다 — [Steamworks: Steam Deck compatibility](https://partner.steamgames.com/doc/steamdeck/compat)

### Inferences
- **기본 단위:** 8dp/4dp 체계를 640x360에 옮기면 «4 게임 px = 1080p에서 12 기기 px»가 기본 단위, 2 px가 세부 단위다. 여백·간격 토큰을 2·4·8·12·16 게임 px처럼 한정해 두면 화면마다 4·5·7 px가 섞이는 «들쭉날쭉한 여백»을 막을 수 있다. 1 px 차이도 3배 확대되면 3 기기 px로 눈에 띄므로, 저해상도에선 고해상도보다 여백 불일치가 더 잘 보인다.
- **640x360 안전 영역 환산(5% 기준):** title-safe 안쪽 90% = 576x324, 즉 좌우 32 게임 px·상하 18 게임 px 여백. GDK가 적은 1080p 기기 px 수치(좌우 96, 상하 40)를 3으로 나누면 좌우 32·상하 약 13 게임 px. action-safe(95%)는 좌우 16·상하 9 게임 px. 상시 시스템 UI 띠(1080p 좌우 32·상하 8)는 약 11·3 게임 px. PC 창 모드만 낸다면 TV 과주사(overscan) 위험은 없으므로 화면 가장자리 여백 8 게임 px(=1080p 24 기기 px) 정도가 실용적 최소, TV·Big Picture·콘솔까지 생각하면 핵심 HUD(골드·웨이브·체력)는 좌우 16~32·상하 9~18 px 안쪽에 둔다.
- **Steam Deck 띠:** 정수 배율 + `keep`이면 640x360 x2 = 1280x720이 1280x800 화면 가운데 놓이고 위아래 40 기기 px(=20 게임 px)씩 검은 띠가 생긴다. `expand`로 바꾸면 Deck에서 뷰포트가 640x400이 되어 2배로 꽉 차지만, 그러면 화면 끝에 붙인(anchor) HUD가 세로 40 게임 px 더 넓은 화면에서도 맞는지 따로 봐야 한다. 이 선택은 사용자 프로젝트의 stretch aspect 값에 따라 달라진다(이 노트에서는 확인하지 않음).
- **위계:** 640x360처럼 글자 크기 단계가 몇 개 없는(정수 크기 폰트) 환경에선 위계를 «크기»보다 «패널 명도 단계·색 강조·여백 덩어리(그룹 간 간격 > 그룹 안 간격, 예: 그룹 안 4 px / 그룹 사이 8~12 px)»로 만들어야 한다. Gestalt 근접성 원리를 정수 간격으로 옮긴 것이다(일반 디자인 원리, 이번 조사에서 1차 출처를 따로 가져오지는 않음).
- **HUD 비중 예시(계산만):** 상단 바 16 px = 화면 높이의 4.4%, 20 px = 5.6%, 하단 바 24 px = 6.7%. 위아래를 합쳐 40 px 미만(약 11%)이면 전장 시야를 크게 잡아먹지 않는다는 것은 추정치일 뿐이며 출처가 있는 기준이 아니다.

### Gaps
- HUD가 화면의 몇 %를 차지해야 하는지에 대한 공식·연구 수치는 찾지 못했다.
- Gestalt·시각 위계에 대한 게임 UI 전용 1차 출처(GDC 강연 등)는 이번 범위에서 가져오지 못했다.
- Material 3 최신 문서의 격자 수치는 직접 확인하지 않았다(2판 기준).

## 2. UI 팔레트 만들기 — 중립색, 강조색, 의미색, 색상 이동, 순흑 피하기

### Takeaway
픽셀 아트 팔레트 실무 지침은 «명도 램프마다 색상(hue)을 조금씩 옮기고(예: 단계마다 +20°), 채도는 가운데에서 최고, 밝을수록 채도를 낮추고, 높은 채도+높은 명도 조합을 피하라»다. UI는 이 램프에서 중립색(어두운 남색·회색 계열) 3~4단계 + 강조 1~2색 + 의미색(HP·골드·위험)을 뽑아 쓰고, 의미색은 어두운 패널 위에서 대비를 계산해 확인해야 한다(예: Sweetie 16의 빨강 #b13e53은 가장 어두운 색 위 대비 2.96:1로 3:1에도 못 미친다).

### Cited Findings
- 램프 안에서 견본마다 색상을 **+20°** 옮기라. «양의 방향 hue shift가 더 자연스럽고, 밝아질수록 따뜻해진다». 8개 램프를 45°씩 옮겨 360°를 채운다. 저자의 Mondo 팔레트는 램프당 9견본 — [Slynyrd Pixelblog 1: Color palettes](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes)
- 같은 글: 명도·채도만 바꾸는 «straight ramp»는 «밋밋하고 다른 색상의 램프와 어울리기 어렵다». 명도는 «검정을 원하지 않는 한 0에서 시작하지 않는다». 채도는 «가운데에서 최고, 100이나 0까지 가지 않는다». 밝아질수록 채도를 낮춰야 하며, «가장 큰 실수는 높은 채도와 높은 명도를 함께 쓰는 것» — [Slynyrd Pixelblog 1](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes)
- 같은 글: 정해진 색 수는 없다. Mondo는 128색, 게임 Thyrian Defenders용은 160색. 작은 프로젝트는 «작은 램프부터» 시작하라 — [Slynyrd Pixelblog 1](https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes)
- 널리 쓰이는 16색 팔레트 예: Sweetie 16(GrafxKid) = #1a1c2c, #5d275d, #b13e53, #ef7d57, #ffcd75, #a7f070, #38b764, #257179, #29366f, #3b5dc9, #41a6f6, #73eff7, #f4f4f4, #94b0c2, #566c86, #333c57 — [Lospec: Sweetie 16](https://lospec.com/palette-list/sweetie-16). 가장 어두운 색이 순흑이 아닌 남색(#1a1c2c), 가장 밝은 색이 순백이 아닌 #f4f4f4다(팔레트 값에서 바로 보이는 사실).
- 인디 UI 안내 글은 UI 에셋에 사진 같은 디더링보다 선명한 가장자리·일관된 간격을 권하고, UI 가독성을 위해 색 수를 8~24로 줄이라고 한다(출처 신뢰도 낮음, 검색 요약 기준) — [pixel art for indie game UI](https://image-to-pixel-art-com.pages.dev/pixel-art-for-indie-game-ui)

### Inferences
- **UI 팔레트 구성안:** 세계 팔레트에서 (a) 패널용 어두운 중립 3단계(배경·패널·테두리 그림자), (b) 밝은 중립 2단계(본문 글자·보조 글자), (c) 강조 1~2색(선택·포커스), (d) 의미색(HP 빨강, 골드 노랑, 마나·정보 파랑, 위험·경고, 희귀도 등급)을 뽑는다. 새 색을 따로 만들지 않고 세계 팔레트 램프에서 뽑으면 «UI만 붕 뜬» 느낌을 줄인다.
- **중립색에도 hue shift:** 9-slice 틀의 밝은 면·어두운 면도 같은 색 회색이 아니라, 어두울수록 푸른/보라 쪽, 밝을수록 따뜻한 쪽으로 옮긴 램프를 쓰면 Slynyrd가 말한 «straight ramp»의 밋밋함을 피한다.
- **순흑·순백:** Sweetie 16처럼 가장 어두운 색을 #1a1c2c 같은 남색으로 두면 순흑(#000000)보다 세계 그림과 어울리면서도 대비는 충분하다(#f4f4f4 대 #1a1c2c = 15.32:1, 아래 3절 계산). 다만 «순흑을 피하라»는 이번에 찾은 출처가 직접 규칙으로 말하지는 않았다(Slynyrd는 «검정을 원하지 않는 한»이라고만 함).
- **의미색 점검 계산(WCAG 식으로 직접 계산, 3절 출처의 식):** Sweetie 16에서 가장 어두운 #1a1c2c 위에 놓으면 #ffcd75(골드) 11.43:1, #38b764(초록) 6.52:1, #41a6f6(파랑) 6.43:1, #94b0c2(밝은 회색) 7.42:1, #566c86(회색) 3.12:1, #b13e53(빨강) **2.96:1**. 즉 «HP 빨강»을 글자색으로 그대로 쓰면 3:1(큰 글자·비텍스트 기준)도 못 넘는다. 빨강은 막대 채움색으로 쓰고 숫자는 밝은 색으로 쓰거나, 램프에서 한 단계 밝은 빨강/주황(#ef7d57 등)을 글자용으로 따로 둬야 한다.
- **채도 조절:** UI 패널은 세계보다 채도를 낮추고(배경 역할), 강조·의미색만 채도를 올리면 «모든 것이 원색으로 소리치는» 아마추어 인상을 줄인다. Slynyrd의 «고채도+고명도 금지»를 UI에 적용한 것이다.
- **흑백(명도) 테스트:** 화면을 흑백으로 바꿨을 때 패널·글자·강조가 명도만으로 구분되는지 본다. 이것은 4절의 대비 계산과 같은 것을 눈으로 확인하는 방법이다(1차 출처 없음, 실무 관행).

### Gaps
- 상용 게임이 UI 전용 팔레트를 몇 색으로 따로 두는지, 세계 팔레트와 공유하는지에 대한 개발자 1차 진술은 이번 범위에서 찾지 못했다(레퍼런스 분석 담당 노트 참조).
- saint11(Pedro Medeiros) 튜토리얼의 UI·팔레트 관련 수치는 직접 가져오지 못했다.

## 3. 대비와 접근성 — WCAG, Xbox XAG, Game Accessibility Guidelines, 색약

### Takeaway
게임 UI 대비의 사실상 기준은 «본문 글자·중요 요소 4.5:1, 큰 글자·큰 요소·비활성 3:1, 고대비 모드 7:1»(Xbox XAG 102 = WCAG 2.x AA와 같은 값)이다. 배경이 변하는 곳에선 «배경의 가장 대비 낮은 부분»에 대해 재야 한다. 색만으로 정보를 전하면 안 되고, 모양·아이콘·글자를 함께 써야 한다.

### Cited Findings
- XAG 102: 표준 크기 글자·중요 시각 요소는 배경 대비 **4.5:1** 이상, 큰 글자·큰 요소 **3:1**, 비활성 요소의 글자 **3:1**, 입력칸 placeholder 4.5:1(큰 글자 3:1), 고대비 모드는 모든 UI 요소 **7:1** 이상 — [Xbox Accessibility Guideline 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 102의 «큰 글자» 정의: PC 1080p 36 px(4K 72 px), 콘솔 1080p 52 px(4K 104 px) — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 102: «단색이 아닌 배경 위 글자의 대비는 글자와 배경의 가장 대비가 낮은 영역 사이에서 잰다»(Sea of Thieves 예: 밝은 청록과 어두운 청록 중 밝은 쪽으로 잼) — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 102: 로고 글자, 순수 장식 요소는 대비 요구가 없다. 이미지 안에 글자를 굽지 말라(로고 제외) — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- WCAG 2.2 SC 1.4.11 Non-text Contrast(AA): UI 컴포넌트·상태를 알아보는 데 필요한 시각 정보와 내용 이해에 필요한 그래픽 부분은 인접 색 대비 **3:1** 이상. 3:1은 문턱값이라 2.999:1은 미달. 상대 휘도 L = 0.2126R + 0.7152G + 0.0722B(선형화한 sRGB), 대비 = (L1+0.05)/(L2+0.05) — [W3C Understanding SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)
- Game Accessibility Guidelines(Basic): 웹 업계 기준을 그대로 적용해 전경/배경 대비 **4.5:1** 이상. «이상적으로는 글자·UI를 단순한 고대비 배경 위에 두고», 안 되면 «뚜렷한 외곽선과 그림자로 배경과 분리»하라. 글자 크기 다음으로 가장 흔한 UI 불만이 대비라고 함 — [GAG: Provide high contrast between text and background](https://gameaccessibilityguidelines.com/provide-high-contrast-between-text-and-background/)
- XAG 103: «색만으로 정보를 나타내서는 절대 안 된다». 색으로 전하는 중요 정보는 모양·패턴·아이콘·글자 중 적어도 하나를 함께 쓴다. 희귀도처럼 색이 주 수단이면(파랑=희귀, 주황=전설) 프리셋이나 자유 색 선택을 제공한다. 비활성(회색 처리) 상태도 자물쇠 아이콘·«사용 불가» 글자 등 다른 수단을 함께 쓴다 — [Xbox Accessibility Guideline 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- XAG 102: 빨강·초록 조준 아이콘 등은 일부 색약에게 구분이 어렵다. 색약 시뮬레이터(Color Oracle 등)는 개발 중 점검용이며 실제 색약 플레이어 테스트를 대신하지 못한다(XAG 103) — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102); [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- XAG 103 예: Grounded는 HUD 게이지를 색 + 기호(번개·물방울·닭다리·하트)로 구분하고, 재료 부족은 빨간 숫자 + 경고 삼각형 + «x0 Available» 글자를 함께 쓴다 — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)

### Inferences
- **640x360에서 «큰 글자»는 사실상 없다:** PC 큰 글자 36 px@1080p = 12 게임 px, 콘솔 52 px = 약 17 게임 px. 본문용 픽셀 폰트(8~12 px)는 거의 모두 «표준 크기»이므로 **글자는 4.5:1을 기본 목표**로 잡아야 한다. 3:1은 아이콘·게이지 테두리·버튼 외곽 같은 비텍스트 요소와 비활성 글자에만 쓴다.
- **직접 계산한 대비 예(위 WCAG 식):** #FFFFFF 대 #808080 = 3.95:1(본문 미달), #FFFF00 대 #FFFFFF = 1.07:1, 순빨강 #FF0000 대 순초록 #00FF00 = 2.91:1(빨강·초록은 휘도 차도 작음), #FF0000 대 #000000 = 5.25:1, #f4f4f4 대 #333c57 = 9.92:1, #f4f4f4 대 #1a1c2c = 15.32:1.
- **타워디펜스·마을 HUD 적용:** 아군/적, 희귀도, 웨이브 위험도처럼 색으로 가르는 정보에 아이콘 모양·테두리 모양·글자 라벨을 하나씩 더 붙인다(예: 희귀도 = 색 + 테두리 장식 단계, HP = 빨강 + 하트 아이콘 + 숫자).

### Gaps
- WCAG 1.4.3(4.5:1/3:1)과 큰 글자 정의(18pt/14pt bold), 1.4.6(7:1) 원문은 이번에 직접 열지 않았다. 같은 값이 XAG 102에 있으므로 XAG 102를 인용하면 된다.
- 픽셀 폰트처럼 획이 1 px인 글자에서 WCAG 대비가 체감 가독성과 얼마나 맞는지에 대한 연구는 찾지 못했다.

## 4. 반투명 패널 — 알파 vs 디더 vs 불투명, 배경 어둡게 하기, 바쁜 그림 위 글자

### Takeaway
접근성 가이드는 «글자 뒤에 불투명 배경(또는 불투명도 조절)», «외곽선·그림자»를 기본 처방으로 든다. 계산해 보면 검은 패널은 불투명도 약 54% 이상이어야 흰 글자가 어떤 배경 위에서도 4.5:1을 넘고, 남색(#1A1C2C) 패널은 61% 이상이 필요하다. 디더 반투명은 장식 층에는 맞지만 글자 뒤 패널에는 근거가 약하다.

### Cited Findings
- XAG 102 «대비를 높이는 일반 방법»: 화면 위 글자 뒤에 단색 배경을 두는 옵션 또는 그 배경의 불투명도 조절 옵션 제공, 글자·요소 색 선택, 고대비 모드, 글자·요소 둘레에 테두리 추가. 예: Minecraft는 텍스트 배경 불투명도 슬라이더를 둔다(스크린샷 속 값 100%, 채팅 글자 불투명도 79%) — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 101: Immortals Fenyx Rising은 게임플레이 화면 글자에 검은 외곽선을 둘러 뒤 배경 색과 상관없이 보이게 한다 — [Xbox Accessibility Guideline 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- XAG 102: For Honor는 기호에 검은 외곽선 + 그 바깥 흰 외곽선(이중 외곽선)을 둘러, 흰 선은 어두운 배경에서, 검은 선은 밝은 배경에서 보이게 한다. The Outer Worlds는 게이지에 흰 외곽선, 노란 글자에 불투명 배경을 둔다 — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 102: Eagle Island(2D 픽셀 플랫포머)는 배경 어둡게 하기 옵션(100%면 배경이 완전 검정)과 캐릭터·발판 흰 외곽선 옵션을 둔다 — [XAG 102](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)
- XAG 101: 글자 크기를 잴 때 외곽선 픽셀은 배경 대비 2:1 넘으면 글자 높이에 넣고, 2:1 미만이면 넣지 않는다 — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- Godot 셰이더 예제: 디더(screen-door) 반투명은 디더 픽셀이 화면 1픽셀 크기와 정확히 맞으면 카메라 이동 때 미끄러짐이 잘 안 보인다. 다른 셰이더 페이지는 디더 반투명을 전환 화면·배경·그림자 용도로 소개한다 — [Godot Shaders: Dithering / Screen Door Transparency](https://godotshaders.com/shader/dithering-screen-door-transparency/); [Godot Shaders: Double Dither](https://godotshaders.com/shader/double-dither-stylized-transparency-shadows-retro-masks/)
- 디더링 안내 글: 디더를 모든 곳에 쓰면 노이즈처럼 지저분해 보이고, 1:1 표시 크기에서 TV 잡음처럼 보이면 과한 것 — [Divoom: Pixel Art Dithering](https://divoom.com/blogs/setup-ideas/pixel-art-dithering-when-to-use-and-stop) (상업 블로그, 신뢰도 중간 이하)

### Inferences
- **패널 불투명도 최소값(WCAG 식으로 직접 계산, sRGB 공간 알파 블렌딩 가정, 최악의 배경 = 순백):**

  | 글자색 | 패널색 | 3:1 | 4.5:1 | 7:1 |
  |---|---|---|---|---|
  | #FFFFFF | #000000 | 42% | 54% | 65% |
  | #FFFFFF | #1A1C2C | 47% | 61% | 74% |
  | #FFFFFF | #333C57 | 55% | 71% | 86% |
  | #F4F4F4 | #000000 | 45% | 56% | 68% |
  | #F4F4F4 | #1A1C2C | 51% | 64% | 76% |
  | #F4F4F4 | #333C57 | 59% | 74% | 89% |

  즉 «툴팁·정보창처럼 글자를 담는 패널은 어두운 남색 기준 약 65~75% 이상 불투명(또는 완전 불투명)», «가벼운 HUD 띠는 글자에 1 px 외곽선을 더한 뒤 50% 안팎»이 근거 있는 출발점이다. Godot 2D가 기본으로 sRGB 공간에서 섞는지는 이번에 확인하지 않았다(HDR 2D를 켜면 달라질 수 있음).
- **모달 뒤 화면 어둡게 하기(scrim):** 위 표의 흰 글자 기준값과 같은 논리로, 모달 창 자체를 불투명하게 두면 scrim은 대비가 아니라 «초점 이동» 역할이라 40~60%면 충분하다는 것은 추정이다(공식 수치 미확인, Gaps 참고).
- **바쁜 픽셀 그림 위 글자:** 1 게임 px 외곽선은 1080p에서 3 기기 px 두께라 고해상도 게임의 외곽선보다 훨씬 두껍고 확실하다. 다만 외곽선 픽셀이 글자 높이에 더해지므로(XAG 101 측정 규칙) 8 px 폰트 + 외곽선이면 측정 높이 10 px가 된다. 대각선 4방향까지 채운 8방향 외곽선은 획이 뭉치기 쉬워, 작은 한글에는 아래쪽 1 px 그림자(drop shadow)나 4방향 외곽선이 더 깔끔할 수 있다(실무 관행, 1차 출처 없음).
- **디더 반투명:** 디더 패턴은 1 px 획의 픽셀 글자와 같은 공간 주파수라 글자와 경쟁한다. 글자 뒤 패널은 균일한 알파나 불투명, 디더는 화면 전환·그림자·장식 층에 쓰는 편이 안전하다(추론).

### Gaps
- Material Design scrim 불투명도(흔히 32%로 알려짐)는 공식 문서에서 확인하지 못했다. 검색에선 구현 예로 0.45, 0.5 같은 값만 나왔다.
- 상용 픽셀 게임 패널의 실제 불투명도 값은 확인하지 못했다(스크린샷 측정은 레퍼런스 분석 담당 범위).
- 픽셀 UI의 1 px 외곽선 vs 그림자 가독성을 비교한 1차 자료는 찾지 못했다.

## 5. 저해상도 글자 — 최소 크기, 줄·자간, 숫자 폰트, 제목/본문 짝, 한글

### Takeaway
XAG 101의 PC 최소 글자 크기(1080p 18 px, 어센더~디센더 높이)는 640x360에서 **6 게임 px**, 콘솔·TV(26 px)는 **약 9 게임 px**, GAG/Amazon TV(28 px)는 **약 9.3 게임 px**다. 한글은 어센더·디센더 구분 없이 음절 네모가 거의 전체 높이를 쓰므로, 상용 한글 픽셀 폰트 Galmuri 기준 본문 12 px(Galmuri11), 보조 10 px(Galmuri9)가 실용 범위이고, 8 px(Galmuri7)는 4,358음절만 담는다. 폰트는 설계 격자 크기의 정수배로만 써야 흐려지지 않는다.

### Cited Findings
- XAG 101 최소 기본 글자 크기(본문 높이 = 디센더 + x-height + 어센더 픽셀 합): 콘솔 1080p **26 px**(4K 52 px), PC/VR 1080p **18 px**(4K 36 px), 모바일 100 DPI 18 px·200 DPI 36 px·400 DPI 72 px(DPI에 비례) — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- XAG 101: 글자를 최소 크기의 200%까지 키울 수 있어야 하고(예: 콘솔 26→52 px), 아이콘·버튼 글리프 안의 글자도 최소 크기를 지켜야 한다. 플랫폼 화면 확대 기능은 작은 글자의 대책이 아니다 — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- XAG 101 글자 간격(두 줄 넘는 글 덩어리, 사용자 조절이 없을 때 최소): 한 줄 길이 80자 이하(**한·중·일은 40자** 이하, 공백 제외), 줄 간격 1.5 이상(첫 줄 어센더~둘째 줄 어센더로 잼), 문단 간격은 줄 간격의 2배 이상, 자간은 글자 크기의 0.12배 이상, 낱말 간격은 0.16배 이상 — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- XAG 101: 산세리프 서체 선택지를 하나 이상 두고, 장식 서체를 쓰면 장식 없는 서체 옵션도 두며, 지원 언어의 문자 집합을 모두 갖춘 폰트를 쓴다. 문장 단위 글은 전부 대문자 대신 문장식 대소문자로 표시할 수 있어야 한다(1~2단어 라벨은 예외). 정렬은 언어 방향에 맞춰 왼쪽/오른쪽(가운데·양쪽 정렬 아님) — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- GAG(Basic): Amazon TV 지침을 인용해 1080p 화면에서 **28 px 최소**, «목표가 아니라 최소로» 쓰라. 작은 픽셀 크기에선 글자 간 차이가 덜 뚜렷해져 난독증 등 인지 조건에도 불리하다. 모범 예: Guacamelee!, Lovers in a Dangerous Spacetime — [GAG: Use an easily readable default font size](https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/)
- Galmuri(SIL OFL 1.1) 크기: Galmuri14 = 15 px(11pt), Galmuri11 = 12 px(9pt, Bold·Condensed 포함), Galmuri9 = 10 px(7.5pt), Galmuri7 = 8 px(6pt). 이름 숫자와 px 값이 다르다. Galmuri7은 «Adobe-KR-0·Adobe-KR-1에 든 한글 음절 4,358자만» 담는다 — [Galmuri README (npm 2.40.3)](https://cdn.jsdelivr.net/npm/galmuri@2.40.3/README.md); [GitHub quiple/galmuri](https://github.com/quiple/galmuri)
- Godot 게임 개발 사례: 주 UI 폰트로 Galmuri9를 «10 px 격자»에 맞춰 쓰고, 중국어 보조 폰트(Fusion Pixel)를 fallback으로 붙였다. 12 px 컷을 10 px 크기로 그리면 «픽셀 사이에 떨어져» 회색 중간 픽셀이 36%(크기 20에서 19%) 생겼고, 10 px 컷은 0%였다. `FontVariation`으로 1.2배 키우기는 글리프만 커지고 advance가 그대로라 글자가 겹쳐 더 나빠졌다 — [DEV: Adding Chinese to a pixel-font Godot game](https://dev.to/hssolution/adding-chinese-to-a-pixel-font-godot-game-4-things-that-broke-34eg)
- 128x128 해상도 픽셀 게임 Curious Fishing 현지화 일지: 한국어·중국어(간·번체)는 Wen Quan Yi Bitmap Song, 일본어는 PixelMplus. 축하 연출 글리프는 대부분 언어를 2배로 키웠지만 «중국어와 한국어는 너무 커서 1배로 남겼다». «글리프 밀도 때문에 중국어가 가장 클 줄 알았는데 한국어가 어려웠다» — 한국어 제목 로고 자리를 위해 파도 그림을 올려야 했다 — [Curious Fishing devlog #12](https://halfwayordinary.itch.io/curious-fishing/devlog/457088/12-localizing-a-low-resolution-pixel-art-game)
- LanaPixel(11 px 표시용 현지화 픽셀 폰트) 관리자는 작은 크기 탓에 일부 CJK 글자가 «거의 읽을 수 없어» 매우 조심해 써야 하고, 번체(아마 간체도) 중국어는 더 큰 폰트를 쓰라고 권한다(검색 요약 기준, 원문 미확인) — [OpenGameArt: LanaPixel](https://opengameart.org/content/lanapixel-localization-friendly-pixel-font)
- 산돌 글꼴 이야기: 예전 픽셀 폰트는 용량 때문에 한글 2,350자만 지원했고, «쫣»·«뜏» 같은 복잡한 글자를 빼 외래어·의성어 표기가 어려웠다. 2023년 SD 픽셀 시리즈는 11,172자를 모두 만들었다. 픽셀 폰트는 «해상도가 낮은 화면에서 명료하게 표현할 수 있다는 강점» — [산돌구름 스토리 415](https://www.sandollcloud.com/story/415)

### Inferences
- **게임 px 환산(1080p 기준 px ÷ 3, 720p에서도 같은 값):**

  | 기준 | 1080p 기기 px | 640x360 게임 px |
  |---|---|---|
  | XAG PC/VR 최소(어센더~디센더) | 18 | 6 |
  | XAG 콘솔 최소 | 26 | 8.7 → 9 |
  | GAG / Amazon TV 최소 | 28 | 9.3 → 10 |
  | XAG PC «큰 글자» | 36 | 12 |
  | XAG 콘솔 «큰 글자» | 52 | 17.3 |

  라틴 픽셀 폰트로 말하면, 대문자 높이 5 px + 디센더 2 px(본문 높이 약 7~8 px)이면 PC 최소(6)를 넘고, TV·콘솔 최소(9~10)는 대문자 높이 7 px 안팎이 필요하다.
- **한글:** 한글 음절은 어센더·디센더가 따로 없고 네모 전체를 쓰므로 «본문 높이 ≈ 음절 높이»로 잴 수 있다. 그러면 Galmuri9(10 px em)는 PC 최소(6)를 넉넉히, TV 최소(9~10)는 경계선에서, Galmuri11(12 px em)은 TV 기준까지 넘는다(글리프 실제 높이는 em보다 1~2 px 작을 수 있어 실측 필요). 8 px(Galmuri7)는 PC 최소는 넘지만 음절이 4,358자뿐이라 번역문에 없는 글자가 나올 수 있다. 정리: **본문·툴팁 12 px(Galmuri11), 보조 라벨·HUD 숫자 옆 짧은 말 10 px(Galmuri9), 8 px 한글은 쓰지 않거나 고정 문구만** — 이 권고는 위 수치에서 끌어낸 추론이다.
- **한 줄 길이:** XAG의 한·중·일 40자 상한을 12 px 한글(advance 약 12 px 가정)로 옮기면 약 480 게임 px. 640 폭 화면에서 툴팁·대화창은 40자보다 훨씬 짧으니(예: 200 px 툴팁 ≈ 16자) 상한 문제보다 «줄바꿈이 잦아지는» 쪽이 실제 문제다.
- **줄 간격:** XAG 1.5배를 12 px 한글에 적용하면 줄 피치 18 px(글자 사이 빈 줄 6 px). 픽셀 게임에서는 이보다 촘촘한 경우가 많아, 최소 «줄 사이 빈 줄 = em의 1/4 이상(12 px 폰트면 3~4 px)», 두 줄 넘는 설명문은 1.5배 쪽으로 두는 것이 타협안이다(추론).
- **자간·낱말 간격:** 0.12배(12 px → 1.44 px), 0.16배(12 px → 1.9 px)는 정수로 올려 자간 1~2 px, 낱말 간격 2~3 px가 된다. 픽셀 폰트는 대개 글리프 안에 1 px 자간이 들어 있으니 추가 자간을 더하기 전에 실측한다.
- **숫자 폰트:** 골드·웨이브·스탯처럼 자주 바뀌는 숫자는 고정폭(tabular) 숫자여야 값이 바뀔 때 글자가 흔들리지 않는다. 픽셀 폰트 숫자는 보통 3~5 px 폭이라 고정폭이 쉽다. 숫자는 한글 본문보다 한 단계 굵거나 밝게 해 위계를 만든다(추론, 1차 출처 없음).
- **제목/본문 짝:** 640x360에서 크기 단계는 «정수 크기 폰트 2~3개(예: 10 / 12 / 15~16 px)»로 제한되므로, 제목은 크기보다 굵기(Bold 컷)·색·외곽선으로 구분하는 편이 정수 격자를 깨지 않는다. 장식 제목 폰트를 쓰면 XAG에 따라 본문은 장식 없는 서체로 둔다.
- **정수 격자:** 폰트 크기는 그 폰트 설계 격자의 정수배로만(예: Galmuri11은 12·24·36), Godot에서 한글·라틴 fallback 폰트도 같은 격자를 공유해야 한다(DEV 사례의 36% 회색 픽셀). 크기를 FontVariation 배율로 바꾸지 않는다.

### Gaps
- 한글 비트맵 글리프의 «최소 가독 픽셀 높이»를 정한 연구·표준은 찾지 못했다. 위 권고는 Galmuri 크기 체계와 XAG 환산에서 끌어낸 추론이다.
- Galmuri 이름 숫자(14/11/9/7)가 한글 글리프 실제 높이를 뜻하는지 README는 설명하지 않는다(미확인).
- Galmuri11/9가 한글 11,172자 전부를 담는지 정확한 수는 README 표에서 확인하지 못했다(지원 표시만 있음).
- 픽셀 게임에서 제목/본문 폰트 짝을 다룬 1차 자료는 찾지 못했다.

## 6. 플랫폼 최소 글자 크기 — Steam Deck, Xbox, 실제 물리 크기

### Takeaway
Steam Deck Verified는 «1280x800에서 가장 작은 글자가 9 px 이상(권장 12 px), 30 cm 거리에서 읽힐 것»을 요구한다. 640x360 x2에서는 최소 4.5 → **5 게임 px**, 권장 **6 게임 px**다. Deck에서 게임 px 하나는 약 0.25 mm라 24인치 1080p 모니터(약 0.83 mm)의 3분의 1 크기이므로, Deck 기준을 맞추면 데스크톱에서는 여유가 생긴다.

### Cited Findings
- Steam Deck 호환성 검토: «가장 작은 화면 글자는 1280x800에서 높이 9 px 밑으로 내려가면 안 된다». «인터페이스 글자는 화면에서 12인치/30 cm 거리에서 쉽게 읽혀야 한다». «9 px는 승인을 위한 절대 최소이며, 가능하면 12 px를 목표로 하길 권한다». 사용자가 글자 크기(가능하면 대비도)를 조절할 수 있게 하길 권한다 — [Steamworks: Steam Deck compatibility review](https://partner.steamgames.com/doc/steamdeck/compat)
- 같은 문서: Steam Machine은 화면 크기·종류에 따라 해상도·글자 크기가 달라 표시 시험을 하지 않는다 — [Steamworks: Steam Deck compatibility review](https://partner.steamgames.com/doc/steamdeck/compat)
- 같은 문서는 레터박스·16:10 처리·UI 배율에 대해서는 말하지 않는다(가져온 페이지 범위) — [Steamworks: Steam Deck compatibility review](https://partner.steamgames.com/doc/steamdeck/compat)
- Xbox: PC 18 px@1080p, 콘솔 26 px@1080p(XAG 101), title-safe 90%(GDK) — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101); [Xbox devdocs: Screen areas](https://devdocs.xbox.com/build/core-features/graphics/overviews/screen-areas)
- Steam Deck OLED: 7.4인치, 1280x800 — [Steam Deck tech specs](https://www.steamdeck.com/en/tech)

### Inferences
- **Valve 9 px의 해석 문제:** «가장 작은 글자 문자의 높이»가 소문자 x-height인지, 대문자·전체 글리프 높이인지 문서가 정의하지 않는다. 대문자/전체 높이로 읽으면 640x360 x2에서 5 게임 px(권장 6)로 대부분의 픽셀 폰트가 통과하지만, 소문자 높이로 읽으면 x-height 5 px(대문자 7 px 안팎) 폰트가 필요하다. 한글은 음절 높이 그대로이므로 10~12 px 한글 폰트는 어느 해석으로도 넉넉히 통과한다.
- **물리 크기(계산):** Steam Deck OLED 7.4" 1280x800 ≈ 204 PPI(LCD 7"이면 ≈ 216 PPI — LCD 화면 크기는 이번에 출처로 확인하지 않음). 2배 배율에서 1 게임 px ≈ 0.25 mm. 24" 1080p 모니터 ≈ 91.8 PPI, 3배 배율에서 1 게임 px ≈ 0.83 mm(27"이면 ≈ 0.93 mm). Deck은 30 cm, 모니터는 대략 50~70 cm에서 본다고 가정하면 각도로 봐도 Deck의 게임 px가 더 작다(모니터 시청 거리는 가정).
- **실행 기준(제안):** 최악 화면을 Steam Deck으로 두고 «가장 작은 라틴 글자 대문자 6 게임 px 이상(Valve 권장 12 px 상당), 한글 10 게임 px 이상», 본문·툴팁은 한글 12 px. 이 정도면 XAG PC(6 게임 px)도 함께 넘는다. TV·콘솔까지 노리면 본문 한글 12 px·라틴 대문자 7 px 이상.
- **글자 크기 옵션:** XAG(200% 확대)와 Valve(사용자 조절 권장) 모두 크기 조절을 권한다. 정수 픽셀 폰트에서는 «UI 배율 1x/2x 선택» 또는 «폰트 단계 12→15/16 px 교체»가 현실적이다. Godot의 `content_scale_factor`로 런타임 배율을 바꿀 수 있다 — [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)

### Gaps
- Nintendo Switch·PlayStation의 글자 크기 인증 기준은 공개 문서에서 찾지 않았다(대부분 NDA).
- Valve의 «Getting your game ready for Steam Deck» 권장 페이지(레터박스·16:10)는 이번에 열지 않았다.
- Steam Deck LCD 모델의 화면 크기(7인치)는 공식 페이지에서 확인하지 못했다.
