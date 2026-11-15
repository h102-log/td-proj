# 도트(픽셀 아트) 게임 UI가 «아마추어·학생 작품»처럼 보이는 원인과 실무자들의 고침 방법

> 표기 규칙: 영어 인용은 원문 그대로 옮겼다. 원문 페이지를 직접 읽지 못하고 검색 요약으로만 본 항목은 «(검색 요약 기준)»으로 표시했다. 맨 끝 «Inferences»는 출처를 조합한 추론이며, 대상 게임 설정(Godot 4.x, 기준 640×360, stretch `canvas_items` + integer 2배, nearest 필터, snap 2D vertices 켬, 한/영 UI)에 맞춰 적었다.

## 1. 픽셀 격자 문제 — 믹셀(mixels), 정수가 아닌 배율, 서브픽셀 위치, 회전·확대한 스프라이트, 블러, 게임 화면과 다른 밀도로 그린 UI

### Takeaway
«아마추어 티»의 첫째 원인은 화면 안에서 픽셀 크기가 하나가 아닌 것이다(믹셀). 원인은 크게 세 가지다. 서로 다른 해상도로 그린 에셋을 섞는 것, 1.5배 같은 정수가 아닌 배율, 격자 밖 위치(가운데 정렬·트윈·회전)다. 실무자들은 기준 해상도 하나를 정해 모든 것을 그 격자에 그리고, 정수 배율과 정수 좌표만 쓰는 것으로 고친다.

### Cited Findings
- 믹셀의 정의는 «the practice of making pixel art where you change the pixel size for certain parts»이고, 글쓴이는 «Mixels, 99.5% of the time make games look awful… uncanny, strange, and just… unprofessional»이라고 평한다. 처방은 «Keep your pixel sizes the [same] throughout each layer of your game»이다. 예외는 배경뿐이며, 배경 안에서도 픽셀 크기는 하나로 맞춘다. — [Flowlab 포럼, "Mini rant: stop using mixels"](https://community.flowlab.io/t/mini-rant-stop-using-mixels/38287)
- 실제 사례: 한 개발자는 16×16 타일, 32×32 집·적, 64×64 플레이어, 96×96 식물을 섞어 썼다. Unity에서 키우자 «Some pixels appear huge, others tiny», «It looks like I threw different resolution games in a blender»가 됐다. 그래서 전부 32×32로 통일하고, 16×16은 nearest로 2배 키운 뒤 디테일을 덧그리고, 64×64 플레이어는 32×32로 다시 그리기로 했다. — [itch.io blog, "Day 16: confronting the elephant pixels in the room"](https://itch.io/blog/1026541/day-16-confronting-the-elephant-pixels-in-the-room)
- r/PixelArt의 «New vs old UI in my game» 스레드에서 한 댓글은 «details added in a different resolution than the overall thing»(전체와 다른 해상도로 덧붙인 디테일)을 가장 큰 불만으로 꼽았다(검색 요약 기준. 스레드 원문은 접속이 막혀 읽지 못함). — [r/PixelArt 스레드 미러](https://lr.in.psf.lt/r/PixelArt/comments/1dx12px/new_vs_old_ui_in_my_game_any_thoughts/lbyl58k/?context=3)
- Godot 공식 문서는 정수가 아닌 배율이 «uneven pixel scaling which results in incorrect appearance of pixel art»를 낳는다고 경고한다. 비교 그림의 설명은 «Line widths in the logo and text varies wildly»이고, integer 배율은 «This prevents uneven pixel scaling from occurring»으로 설명한다. — [Godot Docs, Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- 같은 문서는 픽셀 아트에 «Set the stretch mode to `viewport`»를 권한다. `canvas_items` 모드에 대해서는 «everything is rendered directly at the target resolution», «there is no longer a 1:1 correspondence between sprite pixels and screen pixels»라서 «may result in scaling artifacts»가 생길 수 있다고 하고, 이 모드에서는 스프라이트가 서브픽셀 위치로 움직이거나 회전할 수 있다고 적는다. scale_mode `integer`는 «the value is rounded down to the nearest integer»(남는 자리는 검은 띠)다. — [Godot Docs, Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- 640×360 기준 사례: 한 Godot 개발자는 1280×720 기준에서 그림이 작아 보여 640×360으로 내렸다. 1.5배로 키운 스프라이트는 «scaling pixel art by non-integers is a catastrophe»라며 다시 그렸다. 2배로 키운 스프라이트는 검은 외곽선까지 두 배로 두꺼워져 원래 크기 스프라이트와 어긋났고, 그래서 «carefully erasing their extra thick borders»로 고쳤다. 설정은 stretch mode viewport, aspect keep, scale 1, scale mode integer였다. 서브픽셀 떨림은 «Snap 2D Transforms to Pixel»을 켜서 잡았다. 회전하는 보석은 «looked glitchy»라 결국 보간 셰이더로 타협했다. — [Unicopia devlog, "A tale about chasing a pixel perfect tail"](https://squeakypig.itch.io/unicopia/devlog/787703/a-tale-about-chasing-a-pixel-perfect-tail)
- 정렬 함정: 한 Defold 개발자는 HUD를 기준 해상도 480×270에서 픽셀 아트로 만들고 4배로 키운다. 그는 가운데·가장자리 앵커가 «render 'off grid'»해서 «the pixels wonky»가 된다며, 노드를 모서리 앵커에 두고 «do the centering yourself in script using whole numbers»하라고 쓴다. — [Defold 포럼, "GUI for Pixel art games - here's how"](https://forum.defold.com/t/gui-for-pixel-art-games-heres-how/77704)
- 버튼 크기 애니메이션: Godot 4.5 사용자는 TextureButton을 1.1배로 트윈하자 픽셀 아트가 찌그러졌다고 보고했다(검색 요약 기준). — [Godot Forum, "Help with pixel deforming when changing scale"](https://forum.godotengine.org/t/help-with-pixel-deforming-when-changing-scale/129213). 다른 스레드는 직사각형 크기를 애니메이션하면 가장자리가 흔들린다며, 가장자리가 정수 픽셀에 떨어져야 깨끗하게 그려진다고 설명한다(검색 요약 기준). — [Godot Forum, "Why UI edges are shaking from animation?"](https://forum.godotengine.org/t/why-ui-edges-are-shaking-from-animation/139822)
- Defold 답변은 nearest 필터에서 천천히 키우는 애니메이션을 하면 화면 픽셀이 프레임마다 다른 아트 픽셀로 건너뛰어 «dodder»(흔들림)가 생긴다고 설명한다(검색 요약 기준). — [Defold 포럼, dodder/wobbling](https://forum.defold.com/t/how-to-get-rid-of-dodder-woobling-while-animating-position-scale-zoom/64780)

### Inferences
- 대상 게임은 `canvas_items` + integer 2배라 화면 1픽셀이 아트 0.5픽셀이다. 그래서 Control 위치·크기가 홀수 화면 픽셀(=반 아트 픽셀)에 떨어지면 그 요소만 한 줄 어긋나 믹셀처럼 보일 수 있다. 홀수 폭 요소를 짝수 폭 부모 안 가운데에 두는 경우, 컨테이너가 자동으로 계산한 여백, 트윈 중간값이 주로 이렇게 된다. snap 2D vertices는 정점만 붙이므로 Label의 글자 배치·크기 트윈까지 막아 주는지는 확인하지 못했다(Gaps). 점검 방법: 1280×720 캡처를 nearest로 0.5배 줄여 다시 2배 하고 원본과 비교하면, 반 픽셀에 걸린 요소가 드러난다.
- UI 전용 아트를 2배(1280×720 기준)로 그리거나, 1배로 그린 테두리 옆에 2배로 키운 아이콘을 두면 Unicopia의 «두꺼워진 외곽선» 문제가 UI에서 그대로 생긴다. UI 아트도 640×360 격자 하나로 그린다.
- hover 때 1.05~1.1배로 키우는 «통통 튀는» 트윈은 픽셀 UI에서 격자를 깨뜨리는 대표 원인이다. 대안: 미리 그린 상태별 프레임으로 바꾸기, 1 아트픽셀만큼 이동(눌림), 색 바꾸기, 2배·3배처럼 정수 단계로만 키우기.

### Gaps
- Godot 4.x `canvas_items` 모드에서 Label 글리프 위치에도 `snap_2d_vertices_to_pixel`이 걸리는지 공식 문서로 확인하지 못했다(문서는 서브픽셀 위치가 «가능하다»고만 함).
- Reddit 스레드 원문(댓글 전체)은 접속이 막혀(reddit.com 차단, 미러 SSL 오류) 직접 인용하지 못했다.

## 2. 폰트 문제 — 엔진 기본 폰트, 작은 크기의 안티앨리어싱 벡터 폰트, 원래 크기가 아닌 픽셀 폰트, 너무 많은 서체, 한글 대체 글꼴, 크기·굵기 불일치

### Takeaway
픽셀 화면 위에 매끈한 벡터 글자(엔진 기본 Open Sans 또는 운영체제 대체 글꼴)가 올라가거나, 픽셀 폰트를 원래 크기의 정수배가 아닌 크기로 쓰면 바로 «덜 다듬어진» 인상이 난다. Godot에서는 폰트 파일마다 import 설정(서브픽셀 끔, 안티앨리어싱 끔)과 정수배 크기를 지켜야 한다. 한글은 픽셀 폰트에 없는 글자가 시스템 글꼴로 자동 대체되는 것이 가장 큰 함정이다.

### Cited Findings
- Godot 기본 프로젝트 폰트는 Open Sans SemiBold다(폰트를 지정하지 않으면 쓰임). 폰트 크기 단위는 pt가 아니라 px다. — [Godot Docs, Using Fonts (4.6)](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html)
- 같은 문서의 픽셀 폰트 규칙:
  - «Fonts that have a pixel art appearance should have their subpixel positioning mode set to Disabled. Otherwise, the font may appear to have uneven pixel sizes.»
  - «should have bilinear filtering disabled»(Default Texture Filter를 Nearest로).
  - «The font size must also be an integer multiple of the design size (which varies on a per-font basis)… the Control node using the font must be scaled by an integer multiple as well. Otherwise, the font may look blurry.»
  
  — [Godot Docs, Using Fonts (4.6)](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html)
- 작은 크기에서는 «grayscale antialiasing may result in fonts looking blurry»이고, MSDF는 «Fonts at small sizes will not look as clear as rasterized fonts, due to the lack of hinting»이다. 그래서 작은 UI 글자에는 MSDF가 맞지 않는다. — [Godot Docs, Using Fonts (4.6)](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html)
- 프로젝트 설정 GUI > Theme > Default Font Antialiasing·Hinting·Subpixel Positioning은 «only affect the default project font (the one that is hardcoded in the engine binary)»다. 그래서 따로 가져온 TTF는 파일마다 Import 독에서 바꿔야 한다. — [Godot Docs, Using Fonts (4.6)](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html). 포럼 답변도 같은 차이를 짚고, 서브픽셀을 끄니 해결됐다는 사용자와 GitHub 이슈 #74694(서브픽셀을 꺼도 렌더링이 틀어짐)를 언급한다(검색 요약 기준). — [Godot Forum, "Why pixel font blurry Godot 4"](https://forum.godotengine.org/t/why-pixel-font-blurry-godot-4/735)
- 대체 글꼴: «The engine automatically uses system fonts as fallback fonts, which makes it possible to display CJK characters and emoji without having to load a custom font», «different system fonts have different metrics». 직접 지정하려면 Advanced Import Settings > Fallbacks에서 Add Element로 폰트를 넣는다. Godot는 BMFont(.fnt) 비트맵 폰트도 지원한다. — [Godot Docs, Using Fonts (4.6)](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html)
- 한글 픽셀 폰트 Galmuri(OFL-1.1)의 설계 크기: Galmuri14 = 15px, Galmuri11·Bold·Condensed = 12px, Galmuri9 = 10px, Galmuri7 = 8px. 표에는 모든 패밀리가 한글 음절을 지원한다고 나오지만, Galmuri7은 «Only 4,358 Hangul Syllables included in Adobe-KR-0 and Adobe-KR-1»라는 각주가 붙어 있다. Galmuri11 Bold에는 가나·한자가 없다. — [GitHub quiple/galmuri](https://github.com/quiple/galmuri)
- 서체 수: «Using more than 3 different fonts makes a website look unstructured and unprofessional»(웹 기준 규칙. 글쓴이는 게임은 다르다고 하면서도 따로 상한을 두지 않음). 위계는 «Font size», «Contrast», «Reading order» 세 가지로 만든다. 줄 간격은 «130%-150%», 한 줄 길이는 50~80자다. 이미지 위 글자에는 «add a background with opacity under the text»를 먼저 권하고, 그림자는 덜 효과적인 대안으로 둔다. — [Indieklem, A Good Interface #13 typography](https://indieklem.substack.com/p/13-the-basics-of-typography-in-game)
- 같은 글쓴이의 크기 기준: «text should be at least 16px», 12px 글자는 다크 패턴에나 쓰는 크기, 인접한 버튼 사이는 «at least 8 px», 마우스 환경 버튼 크기는 «44px / 48px». 기준 해상도는 밝히지 않았다. — [Indieklem, A Good Interface #6](https://indieklem.substack.com/p/6-whats-the-right-size)
- Xbox 접근성 지침 XAG 101의 최소 글자 크기는 «body height»(가장 낮은 디센더부터 가장 높은 어센더까지)로 잰다. 콘솔은 1080p에서 26px·4K에서 52px, PC/VR은 1080p에서 18px·4K에서 36px다. 그 밖의 요구: 최소 크기의 200%까지 키울 수 있을 것, 산세리프 서체를 하나 이상 둘 것, 장식 서체에는 평이한 대안을 줄 것, 지원하는 모든 언어의 글자를 갖출 것, 두 줄이 넘는 글은 줄 간격 1.5배 이상. — [Xbox Accessibility Guidelines 101 Text display](https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md)
- 커뮤니티 비평: «clumped stuff with different text sizes are really ugly», «The buttons should be the same size with the same sized text», «the text scale. It looks messy and hard to read». — [Roblox DevForum, "…my GUIs need to be more neat"](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)
- UI 개편 사례: Kobold Crawler는 모노스페이스 글꼴을 «begone monospace!»라며 버리고 «A nicer text engine»으로 바꿨다(새 폰트 이름은 밝히지 않음). — [Kobold Crawler devlog "New UI Look!"](https://itch.io/devlog/793572/new-ui-look.amp)
- 글꼴 관련 가장 흔한 오류로 «제목용 장식 서체를 본문 UI에 쓰는 것»이 꼽힌다. 처방은 제목용 하나와 본문용 하나, 합쳐 2~3개로 줄이는 것이다(검색 요약 기준). — [h-idris, Typography for game UI](https://h-idris.com/blog/game-ui-typography.html)

### Inferences
- 대상 게임의 한글 함정: 쓰는 픽셀 폰트에 없는 음절(예: Galmuri7의 4,358자 밖, 또는 영문 전용 픽셀 폰트 위의 한글 전체)은 Godot가 운영체제 글꼴(Windows라면 맑은 고딕 계열로 추정)로 자동 대체한다. 그러면 한 줄 안에 각진 픽셀 글자와 안티앨리어싱된 매끈한 글자가 섞이고, 기준선과 높이도 어긋난다(«different metrics»). 대체 글꼴은 Fallbacks에 픽셀 한글 폰트로 명시하고, 실제 문자열 전체(.po)로 빠진 글자가 없는지 검사하는 편이 안전하다.
- `canvas_items` 2배에서는 글자가 1280×720 해상도로 그려진다. 그래서 벡터 폰트를 쓰면 «아트보다 두 배 촘촘한 글자»(밀도 불일치)가 되고, 픽셀 폰트도 설계 크기의 정수배가 아니거나 서브픽셀이 켜져 있으면 획 굵기가 들쭉날쭉해진다. 예를 들어 Galmuri11이라면 크기를 12(필요하면 24)로만 쓰고 13·14 같은 중간값은 쓰지 않는다.
- XAG 101을 640×360 격자로 환산하면(1080p = 3배): PC 최소 body height 18px은 아트 6px, 콘솔 26px은 약 8.7px이다. 1280×720(2배) 창에서 Indieklem의 «16px»은 아트 8px에 해당한다. 그래서 8px 설계 폰트(Galmuri7)를 1배로 본문에 쓰면 기준선 근처이고, 10~12px 설계 폰트(Galmuri9·11)가 본문용으로 안전하다는 추정이 나온다. body height와 Galmuri가 말하는 «px» 크기가 같은 값인지는 확인하지 못했다(Gaps).

### Gaps
- Galmuri9·11·14가 현대 한글 11,172자를 모두 담는지 README 표만으로는 확정하지 못했다(«지원»으로만 표시됨).
- Godot가 Windows에서 실제로 어떤 시스템 글꼴로 한글을 대체하는지는 공식 문서에 없다.
- Galmuri 각 패밀리의 실제 body height(어센더~디센더 픽셀 수)는 찾지 못했다.

## 3. 색 문제 — 채도 높은 원색, 순흑·순백, 명도 위계 없음, 너무 많은 색, 게임과 따로 노는 UI 팔레트, 대비 낮은 글자

### Takeaway
색에서 아마추어 티가 나는 길은 두 가지다. 하나는 서로 어울리지 않는 색이 너무 많은 것(«everything clashes»)이고, 다른 하나는 글자·아이콘이 배경과 명도 대비가 부족한 것이다. 실무 처방은 이렇다. 팔레트를 줄여 하나로 묶고, 순흑(#000000) 대신 해당 색의 어두운 색을 외곽선에 쓰고, 채도가 끝까지 올라간 색 띠를 피하고(색상 이동, hue shift), 글자는 4.5:1 이상 대비를 확보한다.

### Cited Findings
- 커뮤니티 비평: «a ton of different colors that don't mix well won't look appealing… everything clashes», «I would have around 3-4 colors, you have like 7-8», «You should also stick to one style instead of multiple different styles», «the contrast isn't great». — [Roblox DevForum, "…my GUIs need to be more neat"](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)
- 팔레트 크기: «32 colors is a popular choice for pixel art palettes, but 16 colors is also common.» — [Derek Yu, Pixel Art Tutorial](https://www.derekyu.com/makegames/pixelart.html)
- «Reducing the amount of colors and unifying the palette is often quite effective.» 같은 글은 «super (fully) saturated colors»로 긴 색 띠를 만드는 것에 반대하고, 색상 이동을 권한다(«In nature, the hue of a color often changes as it goes from light to dark»). — [Arne Niklas Jansson, androidarts Pixel Art tutorial](https://www.androidarts.com/pixtut/pixelart.htm)
- 외곽선 색: 순흑 외곽선은 «very versatile, but sometimes they're a bit overpowering or too retro feeling»이다. 대안은 «a darker shade of the object they're outlining»이고, 선택적 외곽선(어두운 쪽은 어두운 선, 밝은 쪽은 밝은 선)도 있다. 외곽선은 «should always increase contrast, and never decrease it», «You have to take the background color into consideration». — [Lospec, skeddles, "Pixel Art Outlines Part 2: Using Color"](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)
- «our outline has been pure black, which gives the sprite an overall cartoony look.» — [Derek Yu, Pixel Art Tutorial](https://www.derekyu.com/makegames/pixelart.html). 검은 선을 과하게 쓰면 주변 색이 어두워지고 좁은 픽셀 공간을 잡아먹는다(«Excessive black lining might arise from some sort of compulsion to mark and separate every detail»). — [androidarts](https://www.androidarts.com/pixtut/pixelart.htm)
- XAG 102 대비 기준: 일반 크기 글자·요소 4.5:1, 큰 글자·요소 3:1(큰 글자 = 1080p 콘솔 52px, PC 36px), 비활성 요소 글자 3:1, 고대비 모드 7:1. 대상에는 HUD 요소·버튼·슬라이더·글리프가 포함된다. 무늬 있는 배경 위 글자는 «Measure text contrast against the lowest-contrasting part of a non-solid background»로 재고, 단색 뒤판(불투명도는 플레이어가 조절)이나 글자 테두리를 둔다. — [Xbox Accessibility Guidelines 102 Contrast](https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-102-contrast.md)
- 색으로 정보 구분: Shardpunk는 행동 버튼의 외곽선 색을 AP 비용별로 나눴다(무료 초록, 1AP 파랑, 2AP 주황). 이동 범위도 1AP는 파랑으로 «to make the coloring consistent». 배경색이나 아이콘 색을 바꿔 보다가 «simply colored outlines»로 정했다. — [Shardpunk devlog "Fleshing out the UI"](https://bryqu.itch.io/shardpunk/devlog/69970/fleshing-out-the-ui)
- 반대 사례: Return의 개발자는 UI를 처음에 1비트(두 색)로 하려 했다. 그러자 «it also restricted the visual feedback that I was able to give the player», 체력 바와 스태미나 바를 구분하기가 «nearly impossible»했다. 팔레트를 줄이는 것과 정보 구분 사이에 한계선이 있다는 사례다. — [Return Devlog 01](https://itch.io/devlog/384935/return-devlog-01-creating-effective-pixel-art-uigui.amp)
- 순흑 #000000 외곽선은 «harsh», 주변 색을 바래 보이게 하고 «coloring book» 느낌을 준다는 주장도 있다(상업 도구 사이트의 가이드라 신뢰도 낮음). — [pixelpaletteswap, Common Palette Mistakes](https://pixelpaletteswap.pages.dev/guides/common-palette-mistakes.html)

### Inferences
- «UI 팔레트가 게임 팔레트와 따로 논다»는 문제를 따로 다룬 권위 있는 글은 못 찾았다. 다만 Derek Yu·androidarts의 «팔레트 하나로 묶기»와 Roblox 비평의 «한 가지 스타일 고수»를 합치면, UI 패널·테두리 색을 게임 타일·캐릭터 팔레트에서 골라 쓰는 쪽이 일관성 원칙에 맞는다.
- 정보가 빽빽한 디펜스 HUD에서는 강조색(골드·위험·선택)을 2~3개로 정하고 뜻을 고정하는 것(Shardpunk식 «비용 = 색»)이 «색이 너무 많다»와 «구분이 안 된다»를 함께 피하는 절충이다.

### Gaps
- 순백(#FFFFFF) 글자나 패널을 피하라는 근거 있는 출처는 찾지 못했다(순흑 외곽선에 관한 글만 있음).
- 픽셀 게임에서 UI 반투명 패널 불투명도 수치를 권하는 출처는 찾지 못했다(XAG는 «플레이어가 조절»만 요구).

## 4. 레이아웃 문제 — 여백 부족, 들쭉날쭉한 간격, 어긋난 정렬, 어수선한 HUD, 모든 요소가 같은 무게, 늘어난 패널

### Takeaway
비평에서 가장 자주 나오는 말은 «Padding is inconsistent», «not center-aligned», «Make each button equal size»다. 간격과 크기를 정해진 단계로 묶고, 중요도에 따라 위계를 두고, 늘 보일 필요가 없는 정보는 상황에 따라서만 보여 주는 것이 공통 처방이다.

### Cited Findings
- 비평 원문: «Padding is inconsistent», «Make each button equal size», «The picture icon and the "How to play" is not center-aligned», «make sure to space out the buttons», «The spacing and orientation of your frames and buttons could use some improvement», 늘어난 카메라 버튼은 ImageType을 Fit으로 바꾸라는 조언. — [Roblox DevForum, "…my GUIs need to be more neat"](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)
- 일관성: 버튼·폰트·아이콘·조작 방식이 화면마다 바뀌면 플레이어가 자기 클릭을 의심하게 된다. 처방은 «Maintain visual and functional consistency», 서체·간격·조작 방식에 대한 스타일 가이드, 뒤로 가기 버튼처럼 같은 요소는 모든 메뉴에서 같은 자리에 두기. 과부하 처방은 필수 정보(체력·목표·능력)를 앞세우고 부가 정보는 «accessible but unobtrusive»하게 두는 것, 첫 10분에 UI를 다 보여 주지 않는 것(점진적 공개)이다. 화면 절반을 덮는 HUD는 몰입을 깬다. — [itch.io blog, "Why your UI design is pushing players away"](https://itch.io/blog/1040432/why-your-ui-design-is-pushing-players-away)
- 위계: «One screen, one main action». 주 버튼은 보조·3순위 버튼보다 시각적으로 강해야 한다. — [Indieklem, A Good Interface #8](https://indieklem.substack.com/p/8-better-designed-buttons)
- 간격 단계: 들쭉날쭉한 간격은 시각적 긴장을 만든다. 4px이나 8px 같은 고정 간격 단계를 쓰라는 권고가 있고, 모든 요소가 같은 무게면 시선이 머물 곳이 없다는 지적도 있다(여러 블로그를 묶은 검색 요약 기준, 개별 원문 미확인). — [generalistprogrammer, Game UI Design best practices](https://generalistprogrammer.com/tutorials/game-ui-design-best-practices); [Wayline, bad menus](https://www.wayline.io/blog/bad-menus-decimate-indie-game-success)
- 개편 사례 Return: 첫 UI는 큰 아이콘과 겹침 표시가 «drastically took the player out of the atmosphere». 2판은 같은 정보를 «a much more condensed state»로 줄였다. 플레이어 머리 위 수치는 경험치를 얻거나 체력을 잃는 등 값이 바뀔 때만 나타나게 했다. — [Return Devlog 01](https://itch.io/devlog/384935/return-devlog-01-creating-effective-pixel-art-uigui.amp)
- 개편 사례 Tenril: 마나 바를 시간 다이얼 위로 옮기고(낮밤에 따라 얻는 힘과 «directly correlate»), 체력·스태미나 바를 그 옆에 모았다. 관련 있는 정보를 한데 묶은 것이다. — [Tenril devlog "In-Game UI Rework"](https://itch.io/devlog/571846/in-game-ui-rework.amp)
- 개편 사례 Shardpunk: 하단 영역을 다시 배치하고, 무기 과부하 경고를 아래에서 위로 옮겨 «making it more exposed»했다. 인벤토리에 툴팁을 더했다. — [Shardpunk devlog](https://bryqu.itch.io/shardpunk/devlog/69970/fleshing-out-the-ui)

### Inferences
- 640×360 격자라면 간격 단계를 아트 픽셀 기준 2·4·8(화면 4·8·16)처럼 짝수로 잡는다. 그러면 2배 렌더에서 반 픽셀이 생기지 않고(1장 추론), 비평의 «Padding is inconsistent»도 수치로 점검할 수 있다.
- 정보가 많은 장르(골드·웨이브·유닛 수치·툴팁)는 «늘 보이는 것 / 바뀔 때만 보이는 것 / 열어야 보이는 것» 세 층으로 나누는 것이 Return·itch 글의 처방과 맞는다.

### Gaps
- 픽셀 게임 HUD의 여백 최소값(아트 픽셀 단위)을 수치로 권하는 전문가 출처는 찾지 못했다.

## 5. 도트 아트워크 문제 — 들쭉날쭉한 외곽선 두께, 베개 셰이딩, 잡음 많은 테두리 질감, 9-slice 대신 늘린 프레임, 계단(jaggies)·겹선(doubles), 아이콘마다 다른 스타일·빛 방향

### Takeaway
UI 아트에서 아마추어 티는 대개 «한 화면 안의 규칙 위반»에서 난다. 외곽선 굵기, 빛 방향, 아이콘 그림체가 서로 다른 경우다. 9-slice 프레임은 늘이지 말고 모서리를 고정한 채 가장자리를 타일링해야 한다. 늘이면 테두리 픽셀이 뭉개지거나 두께가 달라진다.

### Cited Findings
- Godot NinePatchRect: «Also known as 9-slice panels, NinePatchRect produces clean panels of any size based on a small texture». 모서리는 그대로 두고 가장자리·가운데를 타일링한다. `axis_stretch_horizontal/vertical` 값은 다음과 같다.
  - STRETCH: «This may cause the texture to be distorted.»
  - TILE: «won't cause any visible distortion… The texture must be seamless»
  - TILE_FIT: 각 타일이 온전히 보이도록 늘이며, 왜곡은 STRETCH보다 적다.
  
  `patch_margin_*` 네 값은 따로 정할 수 있고, `draw_center`를 끄면 테두리만 그린다. — [Godot Docs, NinePatchRect](https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html)
- 늘어난 이미지 사례: «the stretched camera button needs its ImageType set to Fit», 스타일이 다른 아이콘 하나(«the twitter icon looks out of place»), 흰 테두리를 빼라는 조언(«the border looks quite ugly», «remove the white border of the buttons»). Roblox는 픽셀 아트 맥락이 아니라는 점에 주의. — [Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)
- 외곽선 두께: 2배로 키운 스프라이트는 검은 외곽선도 두 배가 되어 옆의 1배 스프라이트와 어긋난다. 그래서 외곽선을 지워 다시 그렸다. — [Unicopia devlog](https://squeakypig.itch.io/unicopia/devlog/787703/a-tale-about-chasing-a-pixel-perfect-tail)
- 베개 셰이딩: «Pillow shading can look a bit like a pillow, with a soft radial gradient ramping up towards the center of the form»이고, 형태가 밋밋해 보이게 한다. 선 품질: «Quickly drawn pixel lines will probably look jaggy and disorderly», 1,1,2,3처럼 고르게 늘거나 주는 계단을 권한다. — [androidarts](https://www.androidarts.com/pixtut/pixelart.htm)
- 계단(jaggies): «it's impossible to avoid them entirely unless your pixel art is made only of the simplest shapes», 곡선에서는 «jaggies crop up when the length of the line segments don't grow or shrink in a consistent manner». 빛 방향은 하나로 정한다(«a single light source above the orc and slightly in front of it»). 안티앨리어싱 주의: «Be careful not to anti-alias the outside of a sprite used for a game.» — [Derek Yu, Pixel Art Tutorial](https://www.derekyu.com/makegames/pixelart.html)
- 겹선(doubles)은 선에 남은 군더더기 픽셀로 90° 모서리를 만들어 그림을 덜 깔끔하게 하고, 마무리 단계에서 «fix corners → fix jaggies» 순서로 정리한다. 베개 셰이딩은 «where is the light coming from in this picture?»에 답하지 못하면 의심하라는 점검법이 있다(검색 요약 기준, 출처 페이지 미확인). — [Pixel Grimoire, How to start making pixel art #4](https://medium.com/pixel-grimoire/how-to-start-making-pixel-art-4-f57f51dcfa02)
- 테두리 질감 잡음: UI 에셋은 직선과 도형이 많으므로 «crisp edges and consistent spacing, not photo-like dithering»이 필요하고, UI 색은 8~24색 정도가 적당하다는 실무 팁이 있다. 단 출처는 상업 사이트 가이드라 신뢰도가 낮다(검색 요약 기준). — [image-to-pixel-art guide](https://image-to-pixel-art-com.pages.dev/pixel-art-for-indie-game-ui)
- 버튼 외형: 테두리가 없으면 버튼이 «looks more like a link than a button»하니 «it's safer to use a visible border». 둥근 모서리는 친근한 인상, 각진 모서리는 어두운 게임에 어울린다. 그림자를 넣으면 눌리는 물리 버튼처럼 보인다. — [Indieklem, A Good Interface #8](https://indieklem.substack.com/p/8-better-designed-buttons)

### Inferences
- Godot에서 픽셀 프레임은 StyleBoxTexture나 NinePatchRect의 patch margin을 정수 아트 픽셀로 잡는다. 가장자리에 무늬(리벳·나뭇결)가 있으면 TILE을 쓰고 이음매가 없게 그린다. 늘이는 STRETCH는 단색 가장자리일 때만 안전하다. NinePatchRect의 기본 axis stretch가 STRETCH라는 점은 이번 조회에서 직접 확인하지 못했다(Gaps).
- 패널 크기가 9-slice 타일 단위의 배수가 아니면 TILE_FIT이 타일을 늘이므로 결국 비정수 확대가 된다. 패널 크기를 타일 크기 배수로 맞추면 피할 수 있다.
- 아이콘은 같은 캔버스 크기(예: 16×16), 같은 외곽선 규칙, 같은 빛 방향(예: 왼쪽 위)을 문서 한 장에 정해 두면 «하나만 튀는 아이콘»을 막을 수 있다. Roblox 비평의 «looks out of place»를 Derek Yu의 단일 광원 원칙으로 일반화한 것이다.

### Gaps
- 픽셀 UI 프레임의 «잡음 많은 질감»을 다룬 권위 있는 교육자 글(saint11·Slynyrd·MortMort)은 이번 검색에서 찾지 못했다. saint11의 9-slice 튜토리얼도 확인하지 못했다.
- NinePatchRect·StyleBoxTexture `axis_stretch`의 기본값은 이번 조회 결과에 나오지 않았다.

## 6. 상호작용·피드백 문제 — 버튼 상태(hover/pressed/disabled/focus) 누락, 전환·소리 없음, 키보드·패드 포커스 부실, 반대로 격자를 깨는 과한 트윈(«juice»)

### Takeaway
상태가 하나뿐인 버튼(누르든 올리든 그대로)은 «작동만 하는 프로그래머 UI»의 전형이다. 최소한 Normal / Hover / Focus / Pressed(Active)를 구분해 그리고, 포커스는 hover와 같은 모습으로 확실히 보이게 한다. 다만 픽셀 UI에서는 크기 트윈·튀어 넘치는 이징이 오히려 격자를 깨므로 프레임 교체나 정수 픽셀 이동으로 표현한다.

### Cited Findings
- 버튼 네 상태: Normal(«indicates that the component is interactive and enabled»), Focus(키보드 등으로 강조), Hover, Active(«indicates that the user has pressed the button»). 상태 전환을 애니메이션의 12원칙으로 움직이는 예시가 있다(Normal·Hover·Active에 걸쳐 13프레임). 글쓴이는 비활성 버튼에 반대한다(«a disabled button doesn't give your players any feedback»). 대신 구체적인 오류 메시지를 보이라고 한다. 예시 버튼은 «48px by 16px». — [Indieklem, A Good Interface #8](https://indieklem.substack.com/p/8-better-designed-buttons)
- 비활성 요소를 쓴다면 XAG 102는 비활성 글자에도 3:1 대비를 요구한다. — [XAG 102](https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-102-contrast.md)
- 패드 포커스: Unreal 개발자들은 포커스 외곽선이 거의 보이지 않거나 기본 버튼에 포커스 표시가 아예 없다고 보고한다. 포커스는 받는데 hover 모습이 안 나오는 문제도 있어, 매 틱 포커스와 hover 상태를 직접 조회하는 우회가 제시된다. 마우스 사용자와 패드 사용자가 같은 피드백을 받도록 포커스를 hover와 같은 모습으로 맞추자는 의견도 있다(검색 요약 기준). — [Unreal Forums, buttons not showing hovered state with gamepad](https://forums.unrealengine.com/t/why-do-my-buttons-not-show-a-hovered-state-when-using-a-gamepad/733563)
- Microsoft의 지침은 포커스 표시를 «the border around the UI element that currently has focus»로 정의하고, 사용자가 길을 잃지 않게 한다고 설명한다(검색 요약 기준). — [Microsoft Learn, Game Bar widget UI](https://learn.microsoft.com/en-us/gaming/game-bar/designguide/widgetui)
- 과한 트윈: TextureButton을 1.1배로 hover 트윈하면 픽셀이 찌그러진다(Godot 4.5). — [Godot Forum](https://forum.godotengine.org/t/help-with-pixel-deforming-when-changing-scale/129213). TRANS_BACK·TRANS_BOUNCE는 설계상 목표를 지나쳤다 돌아오므로 잘림이 생기면 값을 고정하거나 완만한 곡선을 쓰라는 글도 있다(검색 요약 기준). — [bugnet, Godot tween overshoot](https://bugnet.io/blog/fix-godot-tween-trans-bounce-overshoot-clipping)
- 회전 연출: 회전하는 보석이 «looked glitchy»해서 결국 보간 셰이더를 넣었고, 글쓴이는 이것이 제한 팔레트 규칙을 깼다고 인정한다. — [Unicopia devlog](https://squeakypig.itch.io/unicopia/devlog/787703/a-tale-about-chasing-a-pixel-perfect-tail)

### Inferences
- 픽셀 UI의 눌림 표현은 버튼 면을 아트 1픽셀 아래로 내리고 그림자를 1픽셀 줄이는 «프레임 교체»가 격자를 지키면서 촉감을 준다. Indieklem의 «그림자로 물리 버튼 흉내»와 1장의 «정수 좌표» 원칙을 합친 것이다.
- 패드·키보드 조작을 지원한다면 Godot `focus` StyleBox를 hover와 같은 외형으로 그리고, 포커스 테두리 대비를 3:1 이상(XAG의 큰 요소 기준) 확보하는 것이 점검 항목이 된다.
- 소리 피드백(클릭·hover 효과음)이 «완성도» 인상에 주는 영향을 수치나 사례로 다룬 출처는 이번에 찾지 못했다(Gaps).

### Gaps
- 버튼 효과음·전환 애니메이션 유무가 «아마추어 인상»에 주는 영향을 다룬 출처는 찾지 못했다.
- Godot 4 Button의 focus 상태 기본 동작(기본 테마의 focus StyleBox 모양)은 확인하지 못했다.

## 7. «프로그래머 UI»·임시 UI 티 — Godot·Unity 기본 테마 외형, 엔진 그라데이션·글로·그림자

### Takeaway
Godot에서 «기본 테마가 그대로 보인다»는 증상은 두 갈래다. 하나는 기본 폰트 Open Sans SemiBold, 다른 하나는 테마를 연결하지 않은 장면이다. 프로젝트 전체 테마(`gui/theme/custom`)를 걸고 장면을 하나씩 단독 실행해 확인해야 한다. 여러 스타일을 섞는 것과 기본 위젯 장식(테두리 두께·둥근 모서리 같은 기본값)을 그대로 쓰는 것도 «덜 다듬어진» 신호로 지적된다.

### Cited Findings
- Godot 기본 프로젝트 폰트는 Open Sans SemiBold다. — [Godot Docs, Using Fonts (4.6)](https://docs.godotengine.org/en/4.6/tutorials/ui/gui_using_fonts.html)
- 기본 테마 자체는 상수라 바꿀 수 없고, 사용자 테마로 덮어써야 한다. `gui/theme/custom`으로 프로젝트 전체 테마를 지정할 수 있다. 다만 «Individual scenes will still display using the default theme when previewing or running them directly»이므로, 장면마다 루트 Control에 같은 테마를 지정한다. 특정 맥락(팝업 안 버튼 등)에는 테마 변형을 쓴다(검색 요약 기준). — [Godot Docs, Introduction to GUI skinning](https://docs.godotengine.org/en/latest/tutorials/ui/gui_skinning.html)
- Godot 4.6부터 에디터 기본 외형이 PassiveStar의 minimal theme 기반 중성 회색으로 바뀌었고, 옛 외형은 «Classic»으로 남았다. 이것은 에디터 테마이지 게임 UI가 아니다(검색 요약 기준). — [GameFromScratch, Godot 4.6 gets a new look](https://gamefromscratch.com/godot-4-6-gets-a-new-look/)
- 커뮤니티 비평에서 기본 위젯 장식을 겨냥한 말: «Rarely anyone uses Border size anymore… the gui's are really blocky», «roundify is useless now, just use the new UICorners», «stick to one style instead of multiple different styles». — [Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)
- Kobold Crawler 개편은 모노스페이스 기본 글자를 버리고 버튼·파티 HUD에 «specific textures»를 입혀 «jump out a bit more»하게 만든 것이 핵심이었다. — [Kobold Crawler devlog](https://itch.io/devlog/793572/new-ui-look.amp)

### Inferences
- 대상 게임에서 Open Sans가 한 번이라도 보이면(툴팁·디버그 패널·확인 창 등) 테마나 폰트 연결이 빠진 장면이라는 신호다. 장면을 하나씩 단독 실행해 캡처하면 바로 찾을 수 있다.
- 엔진 StyleBoxFlat의 그림자(shadow_size)·둥근 모서리(corner_radius)·안티앨리어싱 테두리는 픽셀 격자와 맞지 않는 매끈한 곡선과 흐린 그림자를 만든다. 그래서 픽셀 게임에서는 «프로그래머 UI» 신호가 되기 쉽다. 이 부분은 원리상 추론이며, 직접 다룬 출처는 찾지 못했다.

### Gaps
- «Godot 기본 테마처럼 보인다»를 콕 집어 비평한 r/godot 스레드를 원문으로 확인하지 못했다(Reddit 접근 차단).
- 엔진 글로·그라데이션·드롭섀도가 픽셀 UI에서 아마추어 인상을 준다는 전문가 출처는 찾지 못했다.

## 8. 인디 개발 일지의 실제 UI 개편 전후 사례 — 무엇이 바뀌었고 댓글은 무엇이 차이를 만들었다고 했나

### Takeaway
공개된 개편 일지에서 반복해서 바뀌는 것은 다섯 가지다. 픽셀 크기를 하나로 통일하고, 정수 배율로 바꾸고, 기본·모노스페이스 글꼴을 버리고, 색을 뜻별로 고정하고, 관련 정보를 묶고 상황에 따라서만 보이게 한다. 댓글 비평은 대부분 간격·정렬·크기 통일·색 개수를 짚는다. 다만 Reddit 원문 댓글은 직접 읽지 못해, 비평 원문은 Roblox DevForum 스레드가 가장 풍부한 출처다.

### Cited Findings
- **Unicopia(Godot, 640×360)**: 비정수(1.5배) 스프라이트를 다시 그렸다. 2배 스프라이트의 두꺼워진 외곽선을 지웠다. viewport + integer 배율로 바꾸고 Snap 2D Transforms to Pixel을 켰다. 움직이는 발판은 매 프레임 위치를 반올림했다. — [Unicopia devlog](https://squeakypig.itch.io/unicopia/devlog/787703/a-tale-about-chasing-a-pixel-perfect-tail)
- **«Day 16» 개발자(Unity)**: 16·32·64·96px로 섞인 스프라이트를 32×32 하나로 통일하고, Photoshop에서 Aseprite로 옮겼다. 일지에 댓글은 없었다. — [itch.io blog Day 16](https://itch.io/blog/1026541/day-16-confronting-the-elephant-pixels-in-the-room)
- **Return**: 1비트 UI를 포기했고(정보 구분 불가), 큰 아이콘·겹침 표시를 줄였으며(분위기를 깸), 수치는 바뀔 때만 보이게 했다. — [Return Devlog 01](https://itch.io/devlog/384935/return-devlog-01-creating-effective-pixel-art-uigui.amp)
- **Shardpunk: Verminfall**: 각진 버튼을 «more round-ish»하게 바꿨고, AP 비용별 외곽선 색을 정했고, 이동 범위 색도 같은 규칙으로 맞췄다. 경고를 화면 위로 옮기고 툴팁을 더했다. 목표는 «The main goal of the milestone was making the UI look nicer». — [Shardpunk devlog](https://bryqu.itch.io/shardpunk/devlog/69970/fleshing-out-the-ui)
- **Kobold Crawler**: 모노스페이스 글꼴을 교체했고, 버튼·파티 HUD에 전용 텍스처를 입혔다. — [Kobold Crawler devlog](https://itch.io/devlog/793572/new-ui-look.amp)
- **Tenril**: 서로 관련 있는 바(마나·시간·체력·스태미나)를 시간 다이얼 주변에 모았고, 설정 메뉴를 «cleaner»하게 다시 디자인했다. — [Tenril devlog](https://itch.io/devlog/571846/in-game-ui-rework.amp)
- **비평 스레드(Roblox DevForum)**: 다음 일곱 가지를 짚었다.
  - 색: 3~4색이면 될 것을 7~8색 씀
  - 간격: «Padding is inconsistent»
  - 크기: 버튼과 글자 크기 통일
  - 정렬: 가운데 정렬 어긋남
  - 테두리: 흰 테두리 제거
  - 아이콘: 스타일이 튀는 아이콘
  - 대비: 부족
  
  — [Roblox DevForum](https://devforum.roblox.com/t/when-people-review-my-game-they-say-my-guis-need-to-be-more-neat/684763)
- **r/PixelArt «New vs old UI in my game»**: 다른 해상도로 덧붙인 디테일(믹셀)이 주된 불만이었다(검색 요약 기준). — [r/PixelArt 미러](https://lr.in.psf.lt/r/PixelArt/comments/1dx12px/new_vs_old_ui_in_my_game_any_thoughts/lbyl58k/?context=3)

### Inferences
- 개편 사례들의 공통 순서를 정리하면 «격자 통일(해상도·배율·좌표) → 글꼴 교체 → 색에 뜻 부여 → 정보 묶기·상황별 표시 → 버튼 질감·상태»다. 격자 문제를 먼저 고치지 않으면 뒤의 작업이 티가 나지 않는다는 점이 Unicopia·Day 16 사례에서 드러난다.

### Gaps
- Steam 뉴스의 대형 UI 개편 공지(상용 픽셀 게임)는 이번 조사 범위 안에서 찾지 못했다.
- Reddit(r/gamedev·r/IndieDev·r/PixelArt·r/godot)의 «why does my UI look amateur» 류 스레드 댓글 원문은 reddit.com 접근 차단과 미러 SSL·DNS 오류로 읽지 못했다.
- 개편 일지의 전후 스크린샷은 텍스트로 추출되지 않아, 테두리 두께·팔레트 같은 시각적 변화는 확인하지 못했다(스크린샷 직접 분석은 하지 않음).
