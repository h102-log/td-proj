# 검증: ref_celeste_stardew_valley.md 핵심 주장 16개

> 방법: 인용 출처를 직접 열어 봤고, 게임별 사실은 독립된 두 번째 출처나 화면 증거로 다시 확인했다. 두 번째 출처로 쓴 것은 Everest 위키 저장소 원문(git clone), Celeste 공식 Steam 스크린샷 2장의 픽셀 측정, Stardew 위키 미러 원문(GitHub `nevir/kims-song` docs/wiki), 비공식 디컴파일 게임 코드(GitHub `veywrn/StardewValley` = 1.5, 2021-01 / `Dannode36/StardewValleyDecompiled` = 1.6), 모드 소스 코드다.
> stardewvalleywiki.com은 Cloudflare 403이라 직접 읽지 못했다(우회는 하지 않음). 그 위키 문장은 미러 원문과 검색 발췌로 확인했다.
> 스크린샷: Celeste Steam appdetails(appid 504230)에서 인용된 두 장(c1 `ss_1ad297…`, c3 `ss_0eab…`)이 공식 목록에 있음을 확인하고 내려받아 Pillow로 쟀다. 측정값은 JPEG 기준이다.

| # | 판정 | 요지 |
|---|---|---|
| 1 | confirmed | 320×180 |
| 2 | confirmed | UI 고해상도, 월드 6×6(c1 기준) |
| 3 | confirmed | Renogare, renogare64.fnt, FONT=Renogare,64 |
| 4 | confirmed | 한국어 Noto Sans CJK KR Medium 등 |
| 5 | confirmed | 패널 89%×27%, 포트레이트 216×216, 화자별 프레임 |
| 6 | corrected | 끝음절은 조건부 |
| 7 | confirmed | UI 스프라이트 시트 목록 |
| 8 | corrected | 위·아래 변 늘리는 열은 X 275(코드) |
| 9 | confirmed | UI 배율 75~150%(5% 단위), 줌과 별개 |
| 10 | corrected | «세 단»이 아니라 «주로 세 가지», tinyFont 따로 있음 |
| 11 | confirmed | SpriteFont / font_bold / BmFont |
| 12 | corrected | (86,22,12)는 비라틴 언어에서만 기본 색으로 칠함 |
| 13 | confirmed | FontPixelZoom / FontApplyYOffset / SmallFontLineSpacing 26 |
| 14 | corrected | 스레드 하나(2021-01 원글 + 2024-11 동조 1개) |
| 15 | corrected | 눈 피로는 UI가 아니라 게임 전체의 밝은 팔레트 얘기 |
| 16 | confirmed | 그림자 색은 코드 상수, SpriteFont는 통째 교체만 |

## 주장별

### 1. Celeste 게임 화면 해상도 320×180 — confirmed
- 인용 출처 원문: "Our screen resolution is tiny (320x180), and textures can be pretty dang big these days (4096x4096+)." — https://www.noelberry.ca/posts/celeste_lighting
- 독립 출처: 모드 README에 "`GameplayBuffers.Gameplay` and `GameplayBuffers.Level` are both converted to 1920x1080 instead of 320x180" — https://github.com/FancyFurret/celeste-motion-smoothing/blob/main/README.md ; "Celeste is pixel art scaled from 320x180" — https://ultrawidecheck.com/games/celeste

### 2. 대화 글자·포트레이트·장식은 고해상도, 월드는 6×6 — confirmed (단서 있음)
- c1 직접 관찰: 대화 글자는 안티에일리어싱된 산세리프이고 포트레이트는 매끈한 선의 일러스트다. 월드 행(y=700, 740)의 같은 색 구간 길이를 재 보니 6, 12, 18, 24…로 모두 6의 배수였다. 즉 아트 픽셀 하나가 6×6이다 — observed in screenshot https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg
- 독립 출처(Everest 위키 원문): "`HUD`: This entity will be rendered by the `HudRenderer`, a `HiresRenderer`…" (Celeste-Reference.md), "`Gui` atlas, for high-resolution overworld and UI textures, and the `Portraits` atlas for character dialog portraits" (Tutorials/Replacing-A-Texture.md), "The endscreen canvas is 1920x1080" (Chapter-Complete-Screen.md) — https://github.com/EverestAPI/Resources/wiki
- 단서: 6×6은 카메라를 당기지 않은 평상시 화면에서만 맞다. c3(Oshiro 장면)에서는 구간 길이가 12의 배수라 12×12다(컷신 줌). 노트 21행은 c1~c3 모두 6×6이라고 적었는데, 이건 틀렸다.

### 3. 영어 글꼴 Renogare, 64px BMFont — confirmed
- 인용 출처 원문: "the vanilla English font (Renogare)", 파일명 `renogare64.fnt`, 대화 파일 줄 `FONT=Renogare,64`, BMFont로 만든 .fnt+png. 로그 `[PixelFont] Loading font: …\Content\Dialog\Fonts\korean.fnt` / `=> vanilla font file`이 바닐라도 .fnt를 쓴다는 것을 보여 준다 — https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue (저장소 원문 Mapping/Adding-Custom-Dialogue.md 144~222행)
- 보강: c1에서 두 줄 사이 간격이 약 64px(1080p)라 64 크기와 맞는다. Renogare를 지목한 다른 출처는 사용자 글뿐이라 약하다(https://itch.io/post/2145587 — 그 글도 Celeste가 Renogare라고 단정하지는 않는다).

### 4. 한국어 Noto Sans CJK KR Medium 등 — confirmed
- 인용 출처 원문: "select the font matching your language … Chinese: Noto Sans CJK SC Medium / Japanese: Noto Sans CJK JP Medium / Korean: Noto Sans CJK KR Medium / Russian: Noto Sans Med / Other languages: Renogare". 파일명은 chinese.fnt·japanese.fnt·korean.fnt·russian.fnt이고, "Noto Sans Medium (this is the font used by vanilla for Russian, Chinese, etc.)" — https://github.com/EverestAPI/Resources/wiki/Adding-Custom-Dialogue
- 주의: 이 목록은 «바닐라 글꼴에 글자를 덧붙일 때 고를 글꼴»이다. 바닐라 korean.fnt가 같은 원본에서 구워졌다는 건 이 안내에서 나온 강한 추론이다(.fnt 헤더를 직접 보지는 못했다).

### 5. 대화창 크기·색·포트레이트·화자별 테마 — confirmed
- c1 측정: 패널 테두리는 x≈100~1815, y≈48~340이다(폭 89%, 높이 27%). 포트레이트는 x 144~359, y 86~301로 정확히 216×216이다. 패널 바탕은 RGB 약 (31,20,26)=#1F141A이다. 본문에서 가장 밝은 픽셀이 약 (224,222,225)라 순백이 아닌 회백색이고, «Mountain»은 약 (130,240,255) 시안이다 — observed in screenshot https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_1ad297c2044cdcf450ee83e56350cafb590da755.1920x1080.jpg
- c3 측정: 패널 바로 바깥 x=85에는 파란 창문 (10,65,130)이 있는데 안쪽 x=140은 (14~18,0,0)으로 파란 기가 전혀 없다. 따라서 불투명하다. 바탕은 검붉은 마룬 (22~32,0,0)이고 모서리는 구리색 소용돌이 장식, 포트레이트는 오른쪽 끝이다 — observed in screenshot https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/504230/ss_0eab901ec5c364aa18225fa608ff9cbcc1f432bf.1920x1080.jpg
- 독립 출처: Portraits.xml의 포트레이트마다 `textbox` 속성("the path to the textbox texture relative to `Graphics/Atlases/Portraits/textbox`")이 있어, 화자별 대화창 그림이 데이터로 지정된다 — Everest 위키 Mapping/Custom-Portraits.md

### 6. 캐릭터별 FMOD 이벤트·음절 규칙 — corrected
- 인용 출처 원문(Kevin Regamey 트윗 요약): "We had one audio event per character", "the code-side sends the current character portrait info to FMOD … FMOD responds by sending the playhead to the appropriate emotion", "No syllable was allowed to play twice in a row", "once the text-draw ends in the game's UI, FMOD is notified that speech should conclude", 그 뒤 이벤트는 "plays an end syllable before returning, **or it returns immediately if on an emphasized syllable**" — https://shacknews.com/article/125697/devs-share-insight-into-celestes-dialogue-design-process
- 바로잡기: 글자 출력이 끝날 때 끝음절이 늘 나는 것은 아니다. 강조 음절 위에 있으면 끝음절 없이 바로 돌아간다.
- 독립 출처: 대사 이벤트는 `event:/char/dialogue/` 아래 캐릭터마다 하나씩 있고, 매개변수 `dialogue_portrait`(0~12)와 `dialogue_end`(0~1)가 있다 — Everest 위키 Coding/Character-Dialogues.md, Advanced-Custom-Audio.md

### 7. Stardew UI 스프라이트 시트 — confirmed
- 인용 출처: Cursors("A lot of UI elements"), Cursors2(1.5에서 더한 UI), Cursors_1_6, Maps/MenuTiles("Some of the assets for the pause menu, including the clothing slots"). 인벤토리 표에는 테두리(1번), 바탕 사각형(2번), 반지·신발·모자 칸(9번), 셔츠·바지·장신구 칸(10번), 아이템 칸 "cells"(12번)가 모두 MenuTiles로 적혀 있다. textBox·hoverBox도 목록에 있다 — https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor
- 독립 출처: 디컴파일 코드 `menuTexture = content.Load<Texture2D>("Maps\\MenuTiles")`(Game1.cs 3373행) — https://github.com/veywrn/StardewValley/blob/master/StardewValley/Game1.cs ; StardewUI 문서 "MenuBorder: Modified 9-slice sprite … based on menu tiles" — https://focustense.github.io/StardewUI/reference/stardewui/graphics/uisprites

### 8. 대화창 9-slice식 늘리기(X 274·289, Y 324·325) — corrected
- 인용 출처 원문: "the corners are always displayed in full and only certain parts are stretched", "Top and bottom borders: X 274 and 289 / Left border: Y 325 / Right border and separator…: Y 324", "The square in `Cursors` is stretched to fill the entire box" — https://stardewmodding.wiki.gg/wiki/Tutorial:_Making_a_UI_Recolor
- 독립 출처(1.5·1.6 디컴파일 `DialogueBox.drawBox`, 두 판 같음): 바탕은 `Rectangle(306, 320, 16, 16)`을 상자 크기로 늘린다. 위 변은 `(275, 313, 1, 6)`, 아래 변은 `(275, 328, 1, 8)`이고, 왼쪽 변은 `(264, 325, 8, 1)`, 오른쪽 변은 `(293, 324, 7, 1)`, 구분선은 `(278, 324, 9, 1)`이다. 모서리 넷은 4배 고정 크기로 그린다 — https://github.com/Dannode36/StardewValleyDecompiled (Stardew Valley/StardewValley.Menus/DialogueBox.cs 644~651·690행), https://github.com/veywrn/StardewValley/blob/master/StardewValley/Menus/DialogueBox.cs 631~638행
- 바로잡기: 모서리는 원형 그대로 두고 1px 열·행만 늘리며 바탕은 사각형 하나를 늘린다. 이 구조와 Y 324·325는 맞다. 그러나 코드에서 위·아래 변으로 늘리는 열은 X 275 한 열이다. 튜토리얼의 «X 274·289»는 코드와 맞지 않는다.

### 9. UI 배율 75~150%, 줌과 별개 — confirmed (출처 위치만 다름)
- 위키 원문(미러): "The player can scale the UI between 75% and 150%, separately from and alongside the zoom level. That adjusts the size of pixels shown on the screen for UI elements only." 이 문장은 인용된 «Migrate to 1.5» 페이지가 아니라 **Modding:Modder Guide/Game Fundamentals#UI_scaling**에 있다. «Migrate to 1.5»에는 "Stardew Valley 1.5 lets players change the UI scaling separate from the zoom level."만 있다 — https://github.com/nevir/kims-song/blob/main/docs/wiki/Modder_Guide/Game_Fundamentals.md , https://github.com/nevir/kims-song/blob/main/docs/wiki/Migrate_to_Stardew_Valley_1.5.md (원본 https://stardewvalleywiki.com/Modding:Modder_Guide/Game_Fundamentals 는 403)
- 독립 출처: 1.5 디컴파일 OptionsPage.cs 140~153행은 UI Scale을 `for (zoom2 = 75; zoom2 <= 150; zoom2 += 5)`로, 줌을 `75 … 200`으로 만든다 — https://github.com/veywrn/StardewValley/blob/master/StardewValley/Menus/OptionsPage.cs ; "scale the user interface and the background independently up to 150% and 200% zoom" — https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/

### 10. 글꼴 세 단(Small/Medium/Dialogue) — corrected
- 인용 출처 원문: "In game there're **mainly** three font types: Small, Medium, Dialogue font." 용도 설명은 노트와 같다 — https://github.com/Becks723/StardewMods/blob/master/FontSettings/README.md
- 바로잡기: 게임 코드에는 SpriteFont가 넷 더 있다. `dialogueFont`(=Fonts/SpriteFont1, README의 «Medium»), `smallFont`(Fonts/SmallFont), `tinyFont`(Fonts/tinyFont), `tinyFontBorder`(Fonts/tinyFontBorder)이고, 여기에 SpriteText(LooseSprites/font_bold)가 따로 있다(Game1.cs 374~380·2308~2320·3460행). 인벤토리 수량 숫자는 이 글꼴들이 아니라 `Utility.drawTinyDigits` 스프라이트 숫자로, 3×scaleSize 배율로 그린다(Object.cs 5117행) — https://github.com/veywrn/StardewValley
- 이름 함정: 코드의 `Game1.dialogueFont`는 «Medium»(SpriteFont1)이다. 대화창 글자는 SpriteText(font_bold)다.

### 11. SpriteFont1·SmallFont / font_bold / CJK BmFont — confirmed
- 인용 출처 원문: "they also use SpriteFonts for SpriteFont1 and SmallFont", 굵은 글꼴은 "Relies on integer sprite indexes on a single shared texture", "the BmFont type used for those languages' dialogue fonts is not supported" — https://github.com/ichortower/FontSmasher
- 독립 출처: "for the "dialog" font Stardew expects a 2D texture with glyphs in a uniform grid", "8px [mostly] uniform glyph width" (UdonFan, 2023-05-30) — https://forums.stardewvalley.net/threads/converting-dialog-font-to-a-spritefont.20446 ; 1.5 디컴파일 SpriteText.cs의 `using BmFont;`, `loadFont("Fonts\\Korean")` 등 — https://github.com/veywrn/StardewValley/blob/master/StardewValley/BellsAndWhistles/SpriteText.cs
- 덧붙임: 1.5 코드에서는 러시아어·태국어도 BmFont로 대화 글꼴을 쓴다(CJK만이 아니다). 노트가 인용한 Playstarbound 글(140480)은 지금 포럼 첫 화면으로 리디렉트되어 열리지 않는다.

### 12. 글자색 #221122, 대화 (86,22,12), 그림자 #CE9C5F·(221,148,84) — corrected
- 인용 출처: README 기본값 TextColor 34,17,34 / TextColorDialogue 86,22,12 / ShadowColorGame1 206,156,95 / ShadowColorUtility 221,148,84. README 자체는 이 값이 바닐라라고 밝히지 않는다 — https://github.com/Becks723/StardewMods/blob/master/FontSettings/README.md
- 독립 출처(코드): `Game1.textColor = new Color(34, 17, 34)`, `Game1.textShadowColor = new Color(206, 156, 95)`(Game1.cs 794·796행). `Utility.drawTextWithShadow`의 그림자는 `new Color(221, 148, 84)`다(Utility.cs 7576행). 같은 값을 쓰는 다른 모드 설정으로 https://github.com/aedenthorn/StardewValleyMods/blob/master/CustomTextColours/ModConfig.cs 가 있다.
- 바로잡기: (86,22,12)는 `SpriteText.getColorFromIndex(-1)`의 기본 색이다. 다만 비라틴 언어(한국어 포함)에서만 이 색으로 칠한다. 라틴 언어에서는 `Color.White`를 곱해 font_bold 텍스처 본래 색 그대로 그린다(SpriteText.cs 187~202행). 그래서 «대화 글자 = (86,22,12)»는 한국어판에는 맞지만 영어판은 텍스처 색에 달려 있다(텍스처 색은 확인 못 함).

### 13. FontPixelZoom·FontApplyYOffset·SmallFontLineSpacing — confirmed
- 위키 원문(미러): "FontPixelZoom: A factor by which to multiply the font size. The recommended baseline is 1.5", "FontApplyYOffset: (optional) Whether to shift the font up by four pixels (multiplied by the FontPixelZoom), to better align languages with larger characters like Chinese and Japanese. Default false.", "SmallFontLineSpacing: (optional) The line spacing value used by smallFont. Defaults to 26." — https://github.com/nevir/kims-song/blob/main/docs/wiki/Custom_languages.md (원본 https://stardewvalleywiki.com/Modding:Custom_languages 는 403)
- 독립 출처: 1.6 디컴파일 `StardewValley.GameData/ModLanguage.cs`에 `public bool FontApplyYOffset;`가 있다. 1.5 코드 `smallFont.LineSpacing = 26;`(한국어는 +16, 터키어는 +4) — https://github.com/Dannode36/StardewValleyDecompiled , https://github.com/veywrn/StardewValley/blob/master/StardewValley/Game1.cs 2310행
- 범위 주의: 이 필드들은 «사용자(모드) 언어»용이다. 기본 내장 한국어는 코드에서 `SpriteText.fontPixelZoom = 1.5f`로 정하고, 라틴은 3, 일본어 1.75, 중국어 1.5, 러시아어 3이다(SpriteText.cs 437~459행).

### 14. 인벤토리 수량 숫자 불만 2021~2024, 개발자 무응답 — corrected
- 인용 출처: 원글 darillium, 2021-01-16, 제목 "PC Inventory Font Size too small, anyway to increase it?", 본문 "too small, even with the largest UI scale". 댓글은 셋인데 Rozzett "Same problem here :c"(2024-11-27), 나머지 둘은 모드 추천이고 개발자 답은 없다. 스레드는 잠겨 있다 — https://steamcommunity.com/app/413150/discussions/0/5283252978685636205
- 바로잡기: «2021년부터 2024년까지 이어졌다»는 과장이다. 근거는 스레드 하나에서 원글(2021-01)과 동조 댓글 하나(2024-11)뿐이고, 개발자 무응답도 이 스레드 안에서만 확인된다.

### 15. 밝은 노랑-주황 UI가 눈 피로를 준다 — corrected
- 인용 출처 원문: "One of the things that made me personally wary of playing Stardew Valley was its bright color palette. While I'm sure plenty of players gravitate towards the default bright and cheerful graphics, many people experience eye fatigue or migraines when looking at a bright color palette." 다음 문장은 지도 색을 바꾸는 얘기다. UI 쪽 문장은 따로 있다: "For those who like light mode but struggle with the default bright yellow-orange interface, there's a beautiful, on-brand white and brown alternative." 그리고 "Dark User Interface offers a (you guessed it!) dark mode for the UI" — https://www.nicchan.me/blog/modding-stardew-valley-for-accessibility/
- 바로잡기: 눈 피로·편두통은 UI만이 아니라 게임 전체의 밝은 팔레트(그래픽·지도) 얘기다. UI를 두고는 «밝은 노랑-주황 인터페이스가 버거운 사람»에게 흰·갈색 UI 모드를 권하고, Dark User Interface를 접근성용 색 모드의 하나로 소개할 뿐이다.

### 16. 그림자 색은 코드 모드 필요, SpriteFont는 통째 교체만 — confirmed (인용 출처는 약함)
- 인용 출처: FontSmasher의 "No ability to edit or extend, only to replace wholesale using an XNB"(sprite/interface fonts)는 뒷부분을 뒷받침한다. 다만 FontSmasher는 그림자를 다루지 않는다. 노트가 쓴 포럼 글도 답글 하나("The actual mod is more than a CP mod though … I haven't found anything as simple as CP sprite replacing", Tinybillow 2022-11-13)뿐이라 단정이 아니다 — https://github.com/ichortower/FontSmasher , https://forums.stardewvalley.net/threads/change-font-dropshadow-in-mod.14454
- 실제 근거: 주황 그림자 두 색은 C# 상수다(`Game1.textShadowColor`, `Utility.drawTextWithShadow`의 `new Color(221,148,84)`). 콘텐츠(에셋) 교체로는 바뀌지 않고, 바꾸는 모드들은 SMAPI 코드 모드다(CustomTextColours, FontSettings — 설정 기본값에 "from `Game1.textShadowColor`" 주석이 있다: https://github.com/Becks723/StardewMods/blob/master/FontSettings/Framework/ModConfig.cs).

## 노트에서 덧붙여 본 다른 오류
노트 21행은 c1~c3 모두 «아트 픽셀 ≈ 6×6»이라 했지만 c3(Oshiro)는 컷신 줌으로 12×12다. 42행의 패널색 «#2A2026 안팎»은 실측 약 #1F141A(31,20,26)보다 밝게 잡았다. 61행의 «화자가 말할 때까지 무음 루프»는 Shacknews 문장("plays non-stop for the duration of a given character's conversation")과 맞지 않고, 끝음절은 조건부다. 81행 X 274·289는 코드상 X 275다. 84행 인용문은 «Migrate to 1.5»가 아니라 «Modder Guide/Game Fundamentals» 문장이다. 85행 150%/200% 충돌은 코드로 풀린다: UI 배율은 75~150%, 200%는 줌 상한이다. 102·117행 «폰트 셋/3단»은 tinyFont·tinyFontBorder를 빠뜨렸고, 코드의 `Game1.dialogueFont`가 실은 «Medium»이라는 이름 함정도 있다. 108행 Playstarbound 링크는 죽어서 포럼 첫 화면으로 리디렉트된다. 118행 추론과 121행 Gap: 내장 한국어는 FontPixelZoom 필드가 아니라 코드 상수 `SpriteText.fontPixelZoom = 1.5`(라틴 3), BmFont `Fonts\Korean`, smallFont 줄 간격 26+16=42를 쓴다(1.5 디컴파일 기준). 135행 «툴팁·호버 박스 = LooseSprites/hoverBox»는 코드와 다르다. 툴팁(`IClickableMenu.drawHoverText`)은 `Game1.menuTexture`(Maps/MenuTiles)의 `(0,256,60,60)`을 `drawTextureBox`로 그린다(1.6 IClickableMenu.cs 914·1352행). hoverBox를 실제로 쓰는 곳은 찾지 못했다. 95·97행 Gap 두 개는 디컴파일 코드로 풀린다: 메뉴 상자 소스 `(0,256,60,60)`이 확인됐고, `public const int pixelZoom = 4;`가 Game1.cs 79행에 있다. 164행 추론에 덧붙이면, 인벤토리 수량 숫자는 글꼴이 아니라 `drawTinyDigits` 스프라이트 숫자(3×scaleSize)라 «최소 글자 크기»보다 «숫자 스프라이트 배율»의 문제다. 끝으로, 디컴파일 저장소들은 비공식 미러라 판(1.5/1.6) 차이가 있을 수 있다. 여기 인용한 상수는 두 판에서 같은 줄을 대조한 것(DialogueBox)과 1.5 판 하나만 본 것(색·글꼴·옵션)이 섞여 있다.

## 덧붙임(2026-11-15, 보고서 검토 반영): Stardew UI 패널 색·반투명, Noto Sans CJK 라이선스

### Stardew 대화창 패널 색 — 스크린숏 측정
- 방법: Steam appdetails(appid 413150)의 공식 스크린숏 16장을 모두 받아 훑었다. UI가 보이는 것은 대화창 장면 두 장뿐이고(s4 Governor, s7 Abigail), 인벤토리·메뉴 화면은 없다. 두 장은 1920×1080이고, 같은 화면 자리의 30×6 영역 중앙값을 찍었다(JPEG 근사).
  - s4 https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_10628b4a811c0a925a1433d4323f78c7017dbbe4.1920x1080.jpg
  - s7 https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_30aeedc47e731232ade368831a598d6545346f70.1920x1080.jpg
- 글자 칸 바탕: 위·아래 가장자리 (236,166,96)에서 가운데 (252,197,114)로 밝아지는 세로 그라데이션(크림·주황). HSV 명도 93~99%, 채도 0.55~0.59.
- 초상 쪽 나무 판 (216,130,57), 이름표 (255,210,132). 바깥 테두리는 짙은 갈색 (128,48,0) 줄과 밝은 주황 (248,144,0~8) 줄이 주를 이룬다.
- 영어 대화 글자: 어두운 픽셀이 ≈(80~88,16~24,8)로 모인다. 위 12번의 (86,22,12)에 가깝다.
- 반투명: s4(뒤가 밝은 모래·풀밭)와 s7(뒤가 어두운 방·검은 바깥)에서 글자 칸 같은 자리의 값이 위아래 전 구간에서 같다(예: y=800에서 둘 다 (250~252,194~197,111~114)). 뒤 배경이 비치지 않으니 **불투명**이다. — observed in screenshot s4, s7
- 관찰하지 못한 것: 인벤토리·툴팁(MenuTiles) 패널의 RGB, 프레임의 광원 방향(베벨 여부).

### 메뉴 뒤 배경 어둡게 하기 — 1.5 디컴파일
- `GameMenu.draw`(GameMenu.cs 456~459행): `if (!Game1.options.showMenuBackground) b.Draw(Game1.fadeToBlackRect, …Viewport.Bounds, Color.Black * 0.4f);` 다음 `Game1.drawDialogueBox(…, drawOnlyBox: true)`로 상자를 그린다.
- `Options.setToDefaults()`(Options.cs 587행): `showMenuBackground = false`. 따라서 기본 설정에서 게임 메뉴(인벤토리 등)를 열면 뒤 월드 위에 검정 40%를 깔고 그 위에 상자를 그린다.
- `drawDialogueBox`는 상자 조각을 `menuTexture`에 tint `Color.White`로 그린다(Game1.cs 18612행 부근). 알파를 코드에서 낮추지 않으니 상자의 투명도는 텍스처 알파에 달려 있다(텍스처는 확인하지 않았다).
- 출처: https://github.com/veywrn/StardewValley/blob/master/StardewValley/Menus/GameMenu.cs , https://github.com/veywrn/StardewValley/blob/master/StardewValley/Options.cs , https://github.com/veywrn/StardewValley/blob/master/StardewValley/Game1.cs

### UI 배율과 정수배 — 1.5 디컴파일
- Game1.cs 2469~2475행: 월드 렌더 타깃 `screen`은 창 크기 × (1/`zoomLevel`), UI 렌더 타깃 `uiScreen`은 창 크기 ÷ `uiScale`로 만든다. UI는 이 타깃에 `pixelZoom = 4`로 그린 뒤 창 크기로 키우므로 UI 아트 1px = 화면 4 × uiScale px다(110%면 4.4). OptionsPage.cs상 UI 배율은 75~150%를 5% 단위로 고르므로 75·100·125·150%가 아니면 정수배가 아니다. UI와 월드의 도트 크기가 같은 것은 두 배율이 같을 때뿐이다(위 9번 버그 보고와 같은 구조).
- 출처: https://github.com/veywrn/StardewValley/blob/master/StardewValley/Game1.cs

### Noto Sans CJK 라이선스
- notofonts/noto-cjk 저장소 `Sans/LICENSE` 첫 줄: "This Font Software is licensed under the SIL Open Font License, Version 1.1." 상용(유료) 글꼴이 아니라 OFL 오픈 글꼴이다. — https://github.com/notofonts/noto-cjk/blob/main/Sans/LICENSE
