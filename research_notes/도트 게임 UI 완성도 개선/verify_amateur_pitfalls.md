# amateur_pixel_ui_pitfalls.md 사실 검증

검증일: 2026-11-15. 모든 출처는 직접 열어 확인했다(검색 요약만 본 항목 없음). Galmuri 항목은 npm 최신판(2.40.3) TTF 파일의 cmap을 직접 세어 확인했다. 스크린샷은 내려받지 않았다(이번 주장 가운데 상용 게임 화면을 봐야 판정할 수 있는 것이 없음).

판정 요약: 확인 9 · 수정 9 · 반박 0 · 확인 불가 0

| # | 판정 | 요지 |
|---|---|---|
| 1 | 확인 | Godot 픽셀 아트 = viewport + integer |
| 2 | 확인 | 픽셀 폰트 서브픽셀 Disabled·정수배 (단, 4.4부터 가져오기 기본값이 자동 처리) |
| 3 | 수정 | «파일마다»는 과장 — Import Defaults로 한꺼번에 기본값 지정 가능 |
| 4 | 확인 | 시스템 폰트 자동 대체·metrics·Fallbacks |
| 5 | 수정 | 설계 크기는 맞음. Galmuri7 4,358자는 README의 낡은 각주 — 현재 판은 11,172자 |
| 6 | 확인 | XAG 101 수치 (줄 간격은 조건부) |
| 7 | 확인 | XAG 102 수치 |
| 8 | 확인 | NinePatchRect 모드 (기본값은 STRETCH) |
| 9 | 수정 | 떨림은 Snap만으로가 아니라 Snap + 발판 위치 반올림으로 잡음 |
| 10 | 확인 | Defold 앵커 조언 |
| 11 | 수정 | 4.5 고유 현상이 아니라 한 사용자 보고, 답변은 프로젝트 stretch 설정 탓으로 봄 |
| 12 | 확인 | Roblox 비평 문구 전부 실재 |
| 13 | 확인 | 믹셀 글 |
| 14 | 수정 | 원문은 «can be very versatile, but sometimes…», «순흑» 아님 |
| 15 | 수정 | 오류 메시지 권고는 글쓴이가 아니라 인용한 Nick Babich의 말 |
| 16 | 확인 | Return 일지 |
| 17 | 수정 | 이전 버튼 모양은 글에 없음. 이동 범위는 1AP=파랑만 언급 |
| 18 | 수정 | «단독 실행 때 기본 테마»는 루트 Control에 테마를 거는 방식의 단서이지, 프로젝트 설정 방식이 아님 |

## 주장별 판정

### 1. Godot 픽셀 아트 stretch 권장 — 확인
- 문서 «Desktop game, pixel art» 목록: «Set the stretch mode to `viewport`.», «Set the stretch scale mode to `integer`. This prevents uneven pixel scaling from occurring, which makes pixel art not display as intended.»
- canvas_items: «everything is rendered directly at the target resolution… there is no longer a 1:1 correspondence between sprite pixels and screen pixels, which may result in scaling artifacts.»
- fractional: «this will lead to uneven pixel scaling which results in incorrect appearance of pixel art.» integer: «the value is rounded down to the nearest integer… The remaining space is filled with black bars on all four sides».
- 덧붙일 점: 같은 문서 Note는 «If you are OK with sprites being able to move or rotate in "sub-pixel" positions or wish to have a high resolution 2D viewport»라면 canvas_items를 써도 된다고 대안으로 둔다. 금지가 아니라 trade-off다.
- 출처: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

### 2. 픽셀 폰트 subpixel Disabled·정수배 — 확인
- 4.6 Using Fonts: «Fonts that have a pixel art appearance should have their subpixel positioning mode set to Disabled. Otherwise, the font may appear to have uneven pixel sizes.» «The font size must also be an integer multiple of the design size… the Control node using the font must be scaled by an integer multiple as well. Otherwise, the font may look blurry.»
- 덧붙일 점(문서끼리 어긋남): 튜토리얼은 기본값을 «Auto»라고 쓰지만, ResourceImporterDynamicFont 클래스 문서는 4.4부터 `subpixel_positioning` 기본값이 4 = «Auto (Except Pixel Fonts)»(«Disabled for the pixel style fonts (each glyph contours contain only straight horizontal and vertical lines)»)다. 4.3은 기본값 1(Auto)이고 이 옵션이 없다. 4.7은 hinting 기본값도 «Light (Except Pixel Fonts)»다. 그래서 4.4 이상에서는 외곽선이 가로·세로 직선뿐인 픽셀 폰트라면 가져오기 기본값만으로 서브픽셀이 꺼진다. 명시적으로 Disabled를 두는 것은 여전히 안전하다.
- 출처: https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html · https://docs.godotengine.org/en/4.6/classes/class_resourceimporterdynamicfont.html · https://docs.godotengine.org/en/4.4/classes/class_resourceimporterdynamicfont.html · https://docs.godotengine.org/en/4.3/classes/class_resourceimporterdynamicfont.html · https://docs.godotengine.org/en/stable/classes/class_resourceimporterdynamicfont.html

### 3. Default Font 프로젝트 설정은 기본 폰트에만 — 수정
- 앞부분 확인: «These project settings *only* affect the default project font (the one that is hardcoded in the engine binary). Custom fonts' properties are governed by their respective import options instead.» 기본 폰트는 Open Sans SemiBold.
- 고칠 점: 같은 페이지가 «You can use the Import Defaults section of the Project Settings dialog to override default import options for custom fonts.»라고 쓴다. 따라서 «파일마다 바꿔야 한다»는 과장이다. Import Defaults로 가져온 폰트 전체의 기본값을 정할 수 있고, 개별 파일은 Import 독에서 덮어쓴다. 포럼(Calinou)도 «The project setting only affects the default project font»라고 같은 구분을 한다.
- 출처: https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html · https://forum.godotengine.org/t/why-pixel-font-blurry-godot-4/735

### 4. 시스템 폰트 자동 대체 — 확인
- «The engine automatically uses system fonts as fallback fonts», CJK·이모지를 커스텀 폰트 없이 표시 가능, «different system fonts have different metrics». Advanced Import Settings 오른쪽 «Fallbacks»에서 Array[Font]를 펼쳐 Add Element.
- 출처: https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html

### 5. Galmuri 설계 크기·Galmuri7 범위 — 수정
- 설계 크기는 확인: README 표 머리글 «Galmuri14 (15px, 11pt) | Galmuri11 (12px, 9pt) | Galmuri11 Bold (12px, 9pt) | Galmuri11 Condensed (12px, 9pt) | Galmuri9 (10px, 7.5pt) | Galmuri7 (8px, 6pt)», OFL-1.1.
- README에는 Galmuri7 칸에 «Only 4,358 Hangul Syllables included in Adobe-KR-0 and Adobe-KR-1» 각주가 실제로 있다. 그러나 이 각주는 낡았다.
  - 공식 사이트 https://quiple.dev/font/galmuri (galmuri.quiple.dev가 301로 옮겨 감): «모든 폰트가 한글 완성자 11,172자를 지원합니다.»
  - npm 최신 galmuri 2.40.3의 `dist/Galmuri7.ttf` cmap(format 4)을 직접 세어 보니 U+AC00–U+D7A3 11,172자가 모두 0이 아닌 글리프에 매핑돼 있고, 빈 외곽선은 0개, 서로 다른 외곽선 본문은 10,740개였다. Galmuri9·11·14도 11,172자.
  - README 안에 쓰이지 않는 옛 각주(«Only 2,780 Hangul Syllables included in Adobe-KR-0»)도 남아 있어, 각주가 판 갱신을 따라가지 못한 것으로 보인다.
- 정확한 판: «Galmuri14=15px, Galmuri11(Bold·Condensed)=12px, Galmuri9=10px, Galmuri7=8px. 현재 판(2.40.3)은 Galmuri7을 포함한 모든 패밀리가 현대 한글 11,172자를 담는다(README의 4,358자 각주는 낡은 표기).»
- 출처: https://github.com/quiple/galmuri · https://raw.githubusercontent.com/quiple/galmuri/main/README.md · https://quiple.dev/font/galmuri · https://cdn.jsdelivr.net/npm/galmuri/dist/Galmuri7.ttf

### 6. XAG 101 최소 글자 크기 — 확인
- «Font size in the XAGs is body height — the pixel distance from the lowest descender to the highest ascender.» 표 «Minimum body height»: 콘솔 1080p 26px·4K 52px, PC/VR 1080p 18px·4K 36px. 표 아래 «These are minimum defaults at launch.»
- «Players can resize text up to 200% of the minimum without losing content, functionality, or meaning.»
- 줄 간격: «For blocks of text longer than two lines at standard font size» → «Prefer letting players configure…», «If configuration is not offered, meet these minimums» → «Line spacing (leading) | ≥ 1.5× within paragraphs, measured ascender-to-ascender». 즉 1.5배는 «플레이어가 설정을 바꿀 수 없을 때»의 최소값이고 문단 안 줄 간격이다.
- 출처: https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md

### 7. XAG 102 대비 — 확인
- 표: «Standard-size text or visual element | 4.5:1», «Large-scale text and visual elements | 3:1»(콘솔 1080p 52px, PC/VR 1080p 36px부터), «Text on inactive / disabled elements | 3:1», 고대비 모드 «≥ 7:1 for all UI elements»(«High-contrast mode should:»).
- «Measure text contrast against the lowest-contrasting part of a non-solid background.» «Allow players to put a solid background behind on-screen text, and adjust its opacity.»
- 덧붙일 점: 4.5:1 행은 «HUD»를 따로 쓰지 않고 «visual element»로 묶는다. 버튼·슬라이더·글리프는 «Non-text visual elements» 항목에 따로 나열된다. 비활성 3:1은 글자에만 해당한다.
- 출처: https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-102-contrast.md

### 8. NinePatchRect axis stretch — 확인
- STRETCH: «This may cause the texture to be distorted.» TILE: «This won't cause any visible distortion. The texture must be seamless for this to work without displaying artifacts between edges.» TILE_FIT: «This may cause the texture to be distorted, but less than AXIS_STRETCH_MODE_STRETCH.»(TILE_FIT도 seamless 필요)
- `patch_margin_left/right/top/bottom` 네 속성, 기본값 0.
- 덧붙일 점: `axis_stretch_horizontal`·`axis_stretch_vertical` 기본값은 둘 다 0 = STRETCH(노트의 Gaps 해소). 클래스 설명은 «tiling its edges and center»라고 쓰지만 기본값은 늘이기다.
- 출처: https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html

### 9. Unicopia 사례 — 수정
- 확인: 1280×720에서 640×360으로 내림, «scaling pixel art by non-integers is a catastrophe», 1.5배 스프라이트를 다시 그림, 2배 스프라이트는 paint.net에서 «carefully erasing their extra thick borders», 설정 «(Mode: viewport, Aspect: keep, Scale: 1, and Scale Mode: integer)», 엔진 Godot.
- 고칠 점: viewport/integer 설정은 배율 문제의 해법으로 나온다. 떨림(«minor, but noticeable jitter», 원인은 부동소수 물리 대 정수 픽셀)은 Snap 2D Transforms to Pixel이 첫 해법이었지만, 글쓴이는 곧 «a further problem»(움직이는 발판 위에서 플레이어가 흔들림)을 발견했고, 발판 위치를 매 프레임 강제로 반올림하고 플레이어 위치는 멈춰 있을 때만 반올림해서 잡았다. 움직이는 동안의 남은 흔들림은 «negligible»로 남겨 둠.
- 출처: https://squeakypig.itch.io/unicopia/devlog/787703/a-tale-about-chasing-a-pixel-perfect-tail

### 10. Defold 앵커 조언 — 확인
- «You need to avoid using any "center" or "edge" anchors for nodes, because they will render "off grid" and make the pixels wonky.» «You need to stick to the corners (north east, north west, etc)», «do the centering yourself in script using whole numbers, to keep everything on the pixel grid». 480×270 → 4배(1920×1080).
- 덧붙일 점: Defold 한 사람의 글이며 댓글 반론은 없음. Godot 문서도 픽셀 아트 + expand 비율에서는 «Configure Control nodes' anchors to snap to the correct corners»를 권한다.
- 출처: https://forum.defold.com/t/gui-for-pixel-art-games-heres-how/77704 · https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

### 11. TextureButton 1.1배 hover 트윈 — 수정
- 확인: Godot 4.5.1 stable, TextureButton, hover 때 `create_tween().tween_property(button, "scale", hover_scale, 0.1)`로 1.1배, 게임 안에서만 찌그러지고 에디터에서는 멀쩡.
- 고칠 점: 4.5 버전 고유 현상이 아니라 한 사용자 보고다. 답변(rpahut)은 «This is probably caused by the stretching mode you have configured for the game»이라 했고, 질문자는 «pixel perfect in godot»를 찾아보고 해결했다고 답했다. 정확한 판: «픽셀 아트를 1.1배 같은 비정수로 키우면 게임 픽셀 격자에 맞지 않아 찌그러진다(Godot 4.5.1 사용자 보고, 원인은 프로젝트 stretch·필터 설정).»
- 출처: https://forum.godotengine.org/t/help-with-pixel-deforming-when-changing-scale/129213

### 12. Roblox 비평 문구 — 확인
- 모두 실재: «Padding is inconsistent, so I would change that too.»(StodiusDev), «Make each button equal size, the border looks quite ugly…», «The picture icon and the "How to play" is not center-aligned.», «I would have around 3-4 colors, you have like 7-8.», «I'd say the problem here is that everything clashes.»(megukoo), «clumped stuff with different text sizes are really ugly»(greatneil80), «You should also stick to one style instead of multiple different styles.»
- 덧붙일 점: 여러 답글자의 말이고, 픽셀 아트 맥락이 아닌 Roblox UI 비평이다.
- 출처: https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763

### 13. 믹셀 글 — 확인
- «Mixels, 99.5% of the time make games look awful.», «mixels feel uncanny, strange, and just… unprofessional.», «Keep your pixel sizes the same throughout each layer of your game.», «The only time you should use mixels is when you're making a background layer… you still can't change the pixel size within the background.»
- 덧붙일 점: Flowlab 커뮤니티 사용자 sup3r87의 2022-11-08 «rant» 글(의견)이다. 인용 «awful… unprofessional»은 두 문장을 이어 붙인 것.
- 출처: https://community.flowlab.io/t/mini-rant-stop-using-mixels/38287

### 14. Lospec 외곽선 — 수정
- 원문: «Black outlines in pixel art can be very versatile, but sometimes they're a bit overpowering or too retro feeling.» 대안 «a darker shade of the object they're outlining», 선택적 외곽선 «Where the sprite is darkest, we'll use a dark color for the outline, and where it's lightest we'll use a lighter color.», «should always increase contrast, and never decrease it», «You have to take the background color into consideration when using selective outlining.»
- 고칠 점: 원문은 «순흑»이 아니라 «black outlines»이고, 단정이 아니라 «매우 쓸모 있지만 때로는(sometimes) 과하거나 너무 레트로하다»다.
- 출처: https://lospec.com/articles/pixel-art-outlines-part-2-using-color

### 15. Indieklem 버튼 — 수정
- 확인: Normal/Focus/Hover/Active 네 상태와 정의, «One screen, one main action», «Without a border, the UI element looks more like a link than a button… it's safer to use a visible border.», 글쓴이는 Disabled를 «which I don't recommend at all», «a disabled button doesn't give your players any feedback».
- 고칠 점: «specific error message»는 글쓴이의 말이 아니라 인용 블록 속 Nick Babich(uxplanet)의 말(«Instead of clicking a button and seeing a specific error message, users will scan the form…»)이다. 글쓴이 자신은 대안을 따로 제시하지 않는다.
- 출처: https://indieklem.substack.com/p/8-better-designed-buttons

### 16. Return 일지 — 확인
- «Originally, I wanted Return to have a completely 1-bit UI, meaning only 2 colors would be used.», «it also restricted the visual feedback that I was able to give the player», 체력·스태미나 바 구분이 «nearly impossible with two colors», «The large icons and overlays drastically took the player out of the atmosphere.», 2판은 «the same information as the first iteration but in a much more condensed state», «Stats above the player also hide/show when the player needs to see key information, such as gaining experience, losing health, etc.»
- 덧붙일 점: 원문은 «수치가 바뀔 때»가 아니라 «필요한 핵심 정보가 있을 때 보였다 숨는다»이고 예가 경험치 획득·체력 손실이다. 큰 아이콘을 «줄였다»는 원문의 «condensed»에 대한 해석이다.
- 출처: https://itch.io/devlog/384935/return-devlog-01-creating-effective-pixel-art-uigui.amp

### 17. Shardpunk UI 개편 — 수정
- 확인: «I made the buttons more round-ish, and reorganized the bottom parts of the screen.», «in the end I simply colored outlines of action buttons. So free actions are green; blue ones take 1 AP and orange ones: 2 APs.», «Also, to make the coloring consistent, the movement range is blue for moves that consume a single AP.»
- 고칠 점: 이전 버튼이 «각졌다»는 글에 없다(«more round-ish»만). 이동 범위는 1AP 이동이 파랑이라는 것만 적혀 있고, 2AP 이동 범위 색(주황 등)은 언급이 없다. «같은 규칙으로 통일»은 1AP=파랑 하나만 확인된다.
- 출처: https://bryqu.itch.io/shardpunk/devlog/69970/fleshing-out-the-ui

### 18. Godot 테마 미리보기 — 수정
- 확인: «The default theme itself is constant and cannot be changed, but its items can be overridden with a custom theme.», «GUI > Theme > Custom allows you to set a custom project-wide theme»(설정 경로 `gui/theme/custom`).
- 고칠 점: «individual scenes will still display using the default theme when previewing or running them directly»는 Note 안에서 «Instead of changing the project setting you can set the custom theme resource to the root-most control node of your entire UI branch»라는 대안 방식의 단서다. 프로젝트 설정(`gui/theme/custom`)으로 테마를 건 경우에 대한 말이 아니다. 문서는 그 방식의 해법으로 «set the same theme resource to the root control of each individual scene»을 든다. 정확한 판: «프로젝트 설정 대신 UI 가지의 루트 Control에만 테마를 걸면, 실행 중에는 잘 보이지만 개별 장면을 단독 미리보기·실행할 때는 기본 테마로 보인다. 프로젝트 설정 gui/theme/custom을 쓰면 이 문제가 없다(문서가 명시하지는 않지만 차이로 드는 것이 이것뿐).»
- 출처: https://docs.godotengine.org/en/latest/tutorials/ui/gui_skinning.html

## 노트 파일의 다른 오류

노트를 훑으며 본 다른 문제는 다음과 같다. §7 Cited Findings·Takeaway는 gui_skinning의 «단독 실행 때 기본 테마» 단서를 프로젝트 설정 방식에 붙여, `gui/theme/custom`을 걸어도 장면마다 루트 Control에 테마를 다시 지정해야 하는 것처럼 썼다(주장 18 참고. 그 처방은 루트 Control 방식일 때만 필요). §2 Takeaway의 «폰트 파일마다 import 설정(서브픽셀 끔, 안티앨리어싱 끔)»은 두 가지가 어긋난다. 문서는 픽셀 폰트에 안티앨리어싱을 끄라고 권하지 않고(권고는 bilinear 필터 끄기·Nearest와 서브픽셀 Disabled뿐, Antialiasing 절에는 픽셀 아트 조언이 없음), Import Defaults로 한꺼번에 기본값을 둘 수 있으며, 4.4부터 가져오기 기본값이 «Auto (Except Pixel Fonts)»라 4.6 튜토리얼의 «기본값 Auto» 서술 자체가 클래스 문서보다 낡았다. §2 Inferences의 «Galmuri7의 4,358자 밖»과 Gaps의 «Galmuri9·11·14가 11,172자를 담는지 미확정»은 현재 판(2.40.3) 기준으로 각각 틀렸고·해소됐다(네 패밀리 모두 11,172자). §5 Gaps의 «axis_stretch 기본값 미확인»은 STRETCH(0)로 해소되며, §5의 «모서리는 그대로 두고 가장자리·가운데를 타일링한다»는 클래스 설명 문구일 뿐 기본 동작은 늘이기다. §6 Inferences의 «포커스 테두리 대비 3:1 이상(XAG의 큰 요소 기준)»은 XAG 102 표상 맞지 않는다. 3:1은 1080p 콘솔 52px·PC 36px 이상의 «large-scale» 요소 기준이고, 가는 포커스 테두리는 «standard-size visual element»로 4.5:1에 해당한다. §1·§8의 Unicopia 요약은 «viewport + integer 배율로 바꾸고»를 떨림 해법과 한데 묶었지만, 원문에서 떨림 해법은 Snap 2D Transforms to Pixel과 발판 위치 반올림이다. §6의 Indieklem «구체적인 오류 메시지를 보이라고 한다»는 인용한 Nick Babich의 말이다. §3의 Lospec 인용은 «Black outlines… can be very versatile, but sometimes…»를 «순흑 외곽선» 단정으로 옮겼다. 그 밖에 Derek Yu 인용 세 개(«32 colors is a popular choice… 16 colors is also common», «our outline has been pure black, which gives the sprite an overall cartoony look», «Be careful not to anti-alias the outside of a sprite used for a game»)는 원문 그대로 확인했다.
