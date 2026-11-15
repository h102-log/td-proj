# 검증: low_res_ui_visual_principles.md 핵심 주장 17개

검증일 2026-11-15. 인용된 출처는 모두 직접 열어 봤다(WebFetch, 또는 curl로 받은 원문에서 문장 추출). 게임별 사실은 두 번째 출처나 원본 파일로 한 번 더 맞춰 봤다. 계산값은 WCAG 상대 휘도 식(sRGB 선형화, 0.2126/0.7152/0.0722)으로 Python에서 다시 계산했다. 스크린샷은 받지 않았다. 시각 사실을 다루는 주장이 없었다.

판정 요약: confirmed 11 · corrected 6 · refuted 0 · unverifiable 0

| # | 주장(요약) | 판정 |
|---|---|---|
| 1 | XAG 101 최소 글자 크기·200% 확대 | confirmed |
| 2 | XAG 101 간격 최소값 | confirmed |
| 3 | XAG 102 대비 값·큰 글자 정의·변하는 배경 | confirmed |
| 4 | WCAG 2.2 SC 1.4.11 3:1·식 | confirmed |
| 5 | XAG 103 색만으로 정보 금지·색 선택 | confirmed |
| 6 | Steam Deck 9 px/12 px/30 cm | confirmed |
| 7 | Xbox GDK 안전 영역·시스템 UI 띠 | **corrected** |
| 8 | GAG 28 px·4.5:1·외곽선 | **corrected** |
| 9 | Godot integer 배율·640x360 | confirmed |
| 10 | Galmuri 크기·4,358자·OFL 1.1 | confirmed |
| 11 | DEV 글 Godot 사례(36%·FontVariation) | **corrected** |
| 12 | Curious Fishing 현지화 | confirmed |
| 13 | Slynyrd 팔레트 규칙 | **corrected** |
| 14 | Sweetie 16 값·대비 계산 | confirmed |
| 15 | 패널 불투명도 계산 | **corrected** |
| 16 | Steam Deck OLED PPI·mm 계산 | confirmed |
| 17 | Material 2 8dp/4dp | confirmed |

---

## 1. XAG 101 최소 글자 크기 — confirmed
- 원문: "Console: ... 26 px at 1080p, 52 px at 4K", "PC/VR: ... 18 px at 1080p, 36 px at 4K". 크기는 "body height, which is the sum of the number of pixels in the descender space, the x-height space, and the ascender space"로 잰다.
- 원문: "Players should be able to resize text up to 200 percent of the minimum font sizes ... console text at 1080p should be able to be scaled from 26 px to 52 px".
- 출처: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101 (ms.date 2026-11-13 판)

## 2. XAG 101 간격 최소값 — confirmed
- 원문: line width "shouldn't be more than 80 characters or glyphs (or 40 if Chinese/Japanese/Korean)", 공백은 세지 않음. line spacing "at least a space-and-a-half (1.5)", "measured from the ascender of the first line of text to the ascender of the second line". 문단 간격 "at least 2 times larger than the line spacing". 자간 "at least 0.12 times larger than the font size". 낱말 간격 "at least 0.16 times".
- 조건: "For blocks of text that are more than two lines", 그리고 "If players aren't provided with these configurability options"일 때의 최소값이다(노트 본문은 이 조건을 적었다).
- 출처: 위와 같은 XAG 101

## 3. XAG 102 대비 — confirmed
- 원문 요약표: 표준 크기 글자·시각 요소 4.5:1, 큰 글자·큰 요소 3:1, 비활성 요소 글자 3:1, 고대비 모드 7:1, placeholder 4.5:1(큰 글자 3:1).
- 큰 글자: 콘솔 "52 px at 1080p / 104 px at 4K", PC/VR "36 px at 1080p / 72 px at 4K".
- 원문: "When text is displayed over a non-solid color background, the text contrast ratio should be measured between the text and the lowest contrasting area of the background."
- 출처: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102

## 4. WCAG 2.2 SC 1.4.11 — confirmed
- 원문: "a contrast ratio of at least 3:1 against adjacent color(s)". 문턱값이라 반올림하지 않는다: "2.999:1 would not meet the 3:1 threshold". 대비 = (L1 + 0.05) / (L2 + 0.05), L = 0.2126R + 0.7152G + 0.0722B(선형화한 값).
- 출처: https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html

## 5. XAG 103 — confirmed
- 원문: "Color alone should never be used to represent information." 중요한 정보를 색으로 전하면 "at least one additional signifier such as shape, pattern, iconography, or text labels"를 함께 쓴다(«such as»라서 예시 목록이다).
- 원문: "If color is the primary method of communication for information (like if rare items have a blue highlight and legendary items have an orange highlight), the player should be able to configure those colors by using presets, or ideally, free choice of color."
- 출처: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103 (XAG 102도 "Avoid relying on color alone ... provide players the option to choose the color"라고 적는다)

## 6. Steam Deck Verified 글자 크기 — confirmed
- 원문: "Interface text must be easily readable at a distance of 12 inches/30 cm from the screen", "the smallest on-screen font character should never fall below 9 pixels in height at 1280x800", "While 9px is the absolute minimum text size for approval, we recommend aiming for 12px whenever possible", "We recommend supporting user-configurable text size and, when possible, contrast."
- 출처: https://partner.steamgames.com/doc/steamdeck/compat

## 7. Xbox GDK 안전 영역 — corrected
- 맞는 부분: 1080p에서 action-safe 1792x1016, title-safe 1720x1000. "96 pixels in from the left and right edges ... 40 pixels deep from the top and bottom"도 같은 문서에 있다.
- 틀린 부분 1, 퍼센트가 걸린 해상도: «안쪽 95%/90%»는 문서의 "4K" 소절에만 있다("When rendering at 4K, the action-safe area is the inner 95 percent ... title-safe area is the inner 90 percent", 3648x2052·3456x1944). 1080p 값은 95%/90%가 아니다. 1792x1016은 약 93.3%×94.1%, 1720x1000은 약 89.6%×92.6%이고, 1080p의 90%라면 1728x972가 된다.
- 틀린 부분 2, 시스템 UI 띠의 위치: 원문은 "**Within the action-safe area**, the right and left 32 pixels and the top and bottom 8 pixels might contain persistent system UI elements"이다. 이 띠는 화면 가장자리가 아니라 action-safe 경계(1080p에서 좌우 64 px, 상하 32 px 안쪽)에서 시작해 안쪽으로 32 px·8 px를 덮는다. 화면 끝에서 재면 좌우 64~96 px, 상하 32~40 px 구간이고, 바로 그래서 title-safe 경계가 96 px·40 px다.
- 출처: https://devdocs.xbox.com/build/core-features/graphics/overviews/screen-areas (curl로 받은 원문에서 문장 추출)

## 8. GAG 28 px·대비 — corrected
- 맞는 부분: 인용된 글자 크기 페이지에 "Amazon TV have 10-foot-UI guidelines that include text size recommendations, of 28px minimum when viewed on a 1080p screen", "use 28px as a minimum rather than a target, aim to exceed it wherever possible"가 있다. 등급은 Cognitive (Basic)·Vision (Basic)이다.
- 고칠 부분: 4.5:1, 단순한 고대비 배경, 외곽선·그림자 이야기는 인용된 글자 크기 페이지에 없다(원문에서 "contrast"·"4.5"·"outline"·"shadow"를 찾았지만 나오지 않았다). 이 내용은 GAG의 다른 페이지 «Provide high contrast between text and background»(Vision Basic)에 있다. 원문은 "Ideally place your text and UI elements on a plain high contrast background, or where that is not possible, use prominent outlines and shadows to separate them from the background", "a foreground/background contrast ratio of at least 4.5:1"이다.
- 출처: https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/ ; https://gameaccessibilityguidelines.com/provide-high-contrast-between-text-and-background/

## 9. Godot integer 배율 — confirmed
- 원문: "When set to integer, the value is rounded down to the nearest integer"(2.5 → 2.0). 예시는 640×360을 1366×768 창에 띄우면 "1280×720 (scale factor is 2×)", "The remaining space is filled with black bars on all four sides"다. 또 "640×360 is a good baseline, as it scales to 1280×720, 1920×1080, 2560×1440, and 3840×2160 without any black bars when using integer scaling."라고 쓴다.
- 출처: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

## 10. Galmuri 크기·음절 수·라이선스 — confirmed
- README 표 머리: "Galmuri14 (15px, 11pt) | Galmuri11 (12px, 9pt) | Galmuri11 Bold (12px, 9pt) | Galmuri11 Condensed (12px, 9pt) | Galmuri9 (10px, 7.5pt) | Galmuri7 (8px, 6pt)". Galmuri7의 한글 음절 각주는 "Only 4,358 Hangul Syllables included in Adobe-KR-0 and Adobe-KR-1"이다.
- 라이선스: README는 OFL.md를 링크만 한다. 같은 판 package.json에 `"license": "OFL-1.1"`이 있다.
- 독립 확인(원본 BDF, 같은 판 dist/): 한글 «가»(U+AC00) 글리프 BBX는 Galmuri14 14×14, Galmuri11 11×11, Galmuri9 9×9, Galmuri7 7×7이다. 라틴 «H» 높이도 각각 14·11·9·7이다. 이름 숫자는 실제 한글·대문자 높이(px)이고, README의 px 값은 그보다 1 px 큰 렌더 크기(em)다. 그래서 «이름 숫자 ≠ px»라는 주장은 맞다.
- 출처: https://cdn.jsdelivr.net/npm/galmuri@2.40.3/README.md ; https://cdn.jsdelivr.net/npm/galmuri@2.40.3/package.json ; https://cdn.jsdelivr.net/npm/galmuri@2.40.3/dist/Galmuri11.bdf (9·7·14도 같은 경로)

## 11. DEV 글의 Godot 사례 — corrected(내용은 원문과 일치, 출처의 성격과 후속 변경을 덧붙여야 함)
- 원문과 일치하는 부분: "Galmuri9 sits on a 10px grid. A 12px bitmap drawn at size 10 lands between pixels". 표는 "Fusion Pixel 12px 36% 19% / Fusion Pixel 10px 0% 0%"(크기 10/20)이다. "a FontVariation with 1.2x scale. It made things worse. The glyphs grew but the advance width did not, so characters overlapped."
- 덧붙일 점 1: 이 글에는 DEV의 AI 공개 등급 «Fully Autonomous»가 붙어 있다. 공개 제도 안내(제3자 사본)는 이 등급을 «주로 또는 전부 자동화 에이전트·LLM이 만든 글»로 설명한다. 36%·19% 수치는 한 스튜디오가 스스로 잰 값이고, 독립 재현은 없다.
- 덧붙일 점 2: 작성자가 11-09 댓글에서 방식을 바꿨다고 밝혔다. zh_CN에서는 한자 6,675자를 뺀 Galmuri9 사본을 쓰고 중국어는 Fusion Pixel로 넘기며, 이때 «the 12px cut first»라고 썼다. 본문의 «10px 컷 먼저»와 어긋난다. 따라서 «fallback은 주 폰트 격자를 공유해야 한다»는 교훈은 이 글 하나로 일반 규칙이 되지 못한다.
- 부분 독립 확인: Galmuri9 = 10 px는 README와 맞는다. Godot 문서는 FontVariation의 `variation_transform`이 "applied to the font outlines"라고만 설명하고 advance 이야기는 하지 않는다. 겹침 설명과 어긋나지는 않지만 명시적 근거도 아니다.
- 출처: https://dev.to/hssolution/adding-chinese-to-a-pixel-font-godot-game-4-things-that-broke-34eg ; https://docs.godotengine.org/en/stable/classes/class_fontvariation.html ; DEV AI 공개 등급 설명 사본 https://www.neura.market/directories/deepseek/blog/devto-4419574

## 12. Curious Fishing — confirmed
- 원문: "The game has a resolution of 128x128 pixels." 글꼴 표: Japanese PixelMplus, Simplified/Traditional Chinese·Korean은 Wen Quan Yi Bitmap Song. "The glyphs for most languages are 2x scaled, but the Chinese and Korean messages were too large so remain 1x." "I was expecting Chinese to have the largest text due to the density of its glyphs, but Korean turned out to be the difficult one. On the title screen I had to push up the waves to make enough space."
- 두 번째 근거: itch 페이지 태그가 PICO-8이다(PICO-8 고정 해상도 128×128).
- 출처: https://halfwayordinary.itch.io/curious-fishing/devlog/457088/12-localizing-a-low-resolution-pixel-art-game

## 13. Slynyrd 팔레트 규칙 — corrected
- +20°는 일반 규칙이 아니다. 저자가 Mondo 팔레트에 고른 값이고 상한에 가깝다: "For this palette I want 9 swatches per ramp with 20 degrees of positive hue shift between each swatch. I like a lot of hue shift ... but 20 is about as high as I go."
- 채도: "Saturation peaks around the middle and never fully goes to 100, or 0"은 저자가 "a few tendencies I follow"로 든 경향이다. 다른 곳에서는 "Saturation peaks in the middle swatch in this example, but this is not a hard rule. Generally, darker colors have more saturation", "You don't have to follow this general flow of S&B"라고 쓴다.
- straight ramp의 정의는 «명도만»이 아니다. "'straight ramps' that only transition brightness and saturation", 곧 hue를 옮기지 않고 명도·채도만 바꾸는 램프다. 평가도 "There is no law that says you can't do this but the resulting colors will lack interest and be difficult to harmonize with ramps of a different hue"이다.
- 맞는 부분: "As the colors reach high brightness levels it's important to decrease saturation", "The biggest mistake is combining high saturation and brightness, unless you want to burn some eyeballs."
- 출처: https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes

## 14. Sweetie 16 값·대비 — confirmed
- Lospec 목록(작성자 GrafxKid): 1번 #1a1c2c(가장 어두운 색), 13번 #f4f4f4(가장 밝은 색).
- 재계산: #f4f4f4/#1a1c2c 15.319:1, #ffcd75 11.426:1, #b13e53 2.955:1(3:1 미달). 노트의 나머지 값도 맞다: #38b764 6.52, #41a6f6 6.43, #94b0c2 7.42, #566c86 3.12. 노트에 없는 3:1 미달 색으로 #3b5dc9 2.88, #257179 2.98도 있다.
- 출처: https://lospec.com/palette-list/sweetie-16 ; 식은 W3C 1.4.11 Understanding

## 15. 패널 불투명도 — corrected
- sRGB 값 공간 블렌딩, 최악 배경 = 순백(흰 글자에는 실제로 가장 밝은 배경이 최악)이라는 가정으로 다시 계산했다. 정확한 문턱값:

  | 글자 / 패널 | 3:1 | 4.5:1 | 7:1 |
  |---|---|---|---|
  | #FFFFFF / #000000 | 41.62% | 53.47% | **65.08%** |
  | #FFFFFF / #1A1C2C | 46.91% | 60.27% | 73.38% |
  | #FFFFFF / #333C57 | 54.48% | 70.03% | 85.30% |
  | #F4F4F4 / #000000 | 44.53% | **56.06%** | 67.47% |
  | #F4F4F4 / #1A1C2C | 50.19% | 63.20% | **76.08%** |
  | #F4F4F4 / #333C57 | 58.30% | 73.44% | 88.46% |

- 주장의 4.5:1 값(54·61·71%)과 7:1의 74·86%는 맞다. 검은 패널 7:1은 65%가 아니라 **66%**다(65%에서 6.98:1로 미달, SC 1.4.11의 «반올림 없음» 원칙). 노트 표의 #F4F4F4/#000000 4.5:1은 56%가 아니라 57%(56%에서 4.49:1), #F4F4F4/#1A1C2C 7:1은 76%가 아니라 77%(76%에서 6.98:1)다.
- 가정의 근거: Godot `Viewport.use_hdr_2d`는 기본값이 false다. 켜면 "2D rendering will be performed on linear values". 기본 프로젝트라면 sRGB 값 블렌딩 가정이 맞는다. HDR 2D를 켜서 선형 공간에서 섞으면 4.5:1 문턱이 흰 글자 기준 약 82%(#000000)·83%(#1A1C2C)·86%(#333C57)로 크게 오른다(같은 식으로 계산).
- 인용 출처 XAG 102에는 이 계산이 없다. 대비 기준값만 그 문서에서 온다.
- 출처: https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102 ; https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html ; https://docs.godotengine.org/en/stable/classes/class_viewport.html (use_hdr_2d)

## 16. Steam Deck OLED 물리 크기 — confirmed
- 공식 사양: "7.4” diagonal", "1280 x 800 x RGB", HDR OLED.
- 재계산: √(1280²+800²)/7.4 = 203.98 PPI. ×2에서 1 게임 px = 0.249 mm. 24인치 1080p = 91.79 PPI, ×3에서 0.830 mm(27인치는 0.934 mm). 참고로 7인치(LCD)라면 215.6 PPI다.
- 출처: https://www.steamdeck.com/en/tech

## 17. Material 2 8dp/4dp — confirmed(«원문 미확인» 딱지를 뗄 수 있음)
- m2.material.io는 JS로 내용을 불러오는 사이트라, 사이트가 쓰는 page-data JSON을 직접 받아 원문을 확인했다.
- Understanding layout: "most measurements align to 8dp ... Components are sized in 8dp increments", "Smaller elements, such as icons, can align to a 4dp grid, while typography can fall on a 4dp baseline grid".
- Spacing methods: "All components align to an 8dp square baseline grid for mobile, tablet, and desktop", "Icons, type, and some elements within components can align to a 4dp grid", "Padding ... is measured in increments of 8dp or 4dp", "Type can be placed outside of the 4dp grid when it's centered within a component, such as a button or list item."
- 주의: 4dp 쪽은 "can align"이라 선택 사항이다. 이 문서는 M2 기준이다.
- 출처: https://m2.material.io/design/layout/understanding-layout.html (page-data: https://m2.material.io/page-data/Guidelines/5848886118973440.json) ; https://m2.material.io/design/layout/spacing-methods.html (page-data: https://m2.material.io/page-data/Guidelines/6373215592251392.json)

---

## 노트를 훑다 발견한 다른 오류
§1 Inference의 «상시 시스템 UI 띠(1080p 좌우 32·상하 8)는 약 11·3 게임 px»는 띠를 화면 가장자리에서 잰 것이라 틀렸다. 원문은 «action-safe 안쪽» 32·8 px이고, 화면 끝에서 재면 좌우 64~96 px(21~32 게임 px), 상하 32~40 px(11~13 게임 px)다. 같은 절의 «title-safe 90% = 576x324 → 상하 18 게임 px»는 4K에만 적힌 퍼센트를 쓴 값이다. GDK가 1080p에 명시한 96·40 px(32·13.3 게임 px)를 기준으로 삼는 편이 정확하다. §3 Takeaway의 «XAG 102 = WCAG 2.x AA와 같은 값»은 과장이다. 7:1은 WCAG AA가 아니라 AAA(1.4.6) 값이다. WCAG 1.4.3은 비활성 컴포넌트의 글자를 대비 요구에서 아예 빼지만 XAG는 3:1을 요구한다. 큰 글자 정의도 WCAG(18pt/14pt bold)와 XAG(px 기준)가 다르다(https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html — "Text or images of text that are part of an inactive user interface component ... have no contrast requirement"). §4 표에는 반올림 오류 세 칸이 있다(15번 참조: 65→66%, 56→57%, 76→77%). «Godot 2D가 sRGB에서 섞는지 미확인»이라는 Gap은 use_hdr_2d 기본값 false로 풀린다. §5의 «Galmuri 이름 숫자가 실제 높이인지 미확인»이라는 Gap도 BDF로 풀린다. 이름 숫자가 실제 한글 음절·대문자 높이다(Galmuri9 한글 9 px, Galmuri11 11 px). 그래서 «Galmuri9는 TV 최소(9~10)의 경계선»은 «한글 9 게임 px = 1080p 27 px: XAG 콘솔 26 px는 넘고 GAG 28 px에는 못 미침»으로 구체화할 수 있다. 라틴 본문 높이(어센더~디센더)는 Galmuri11이 약 13 px(H 11 + g 디센더 2), Galmuri9가 약 10 px다. §2의 «견본마다 색상을 +20° 옮기라»라는 명령형은 저자 개인 설정의 일반화다(13번 참조). §5의 DEV 사례에는 AI 생성 글 표시와 작성자의 후속 변경이 있으니 근거 수준을 낮춰 적어야 한다(11번 참조).
