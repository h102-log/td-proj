# 검증: pixel_ui_technical_craft_godot.md (반박 시도)

> 검증일 2026-11-15. 1차 자료를 직접 받아 읽었다. Godot 문서 XML은 브랜치 4.1·4.2·4.3·4.4·4.5·4.6·4.7·master에서 받았다. 엔진 동작은 4.7 브랜치 C++/GLSL 소스로 확인했고, 문서 rst는 godot-docs `stable`(conf.py 기준 4.7)에서 받았다. GitHub 이슈는 `gh api`로 본문과 댓글 21개를 모두 읽었다. 폰트 사이트는 직접 열었다. 로컬 Galmuri7.ttf는 cmap을 직접 파싱해 다시 셌다.
> 판정 수: confirmed 15 · corrected 3 · refuted 0 · unverifiable 0

| # | 주장(요약) | 판정 |
|---|---|---|
| 1 | stretch mode viewport/canvas_items 문서 문구(4.3~4.7 동일) | confirmed |
| 2 | 픽셀 아트 데스크톱 권장(640×360·viewport·keep/expand·integer) | confirmed |
| 3 | 4.7부터 새 프로젝트 기본이 canvas_items | confirmed |
| 4 | use_oversampling·Viewport.oversampling(_override), 4.5에서 추가 | confirmed |
| 5 | 셰이더 정점 스냅이 canvas_transform 뒤 → 화면 픽셀 기준 | corrected |
| 6 | snap 두 설정 함께 쓰지 말 것, transforms만 켜기 권장 | confirmed |
| 7 | 픽셀 폰트: Nearest·Subpixel Disabled·디자인 크기 정수배 | confirmed |
| 8 | 임포트 기본값 차이(subpixel 4.4부터 4, hinting 4.7부터 3) | confirmed |
| 9 | INTEGER_ONLY 권장, 이미지·BMFont 임포터 기본은 2 | confirmed |
| 10 | StyleBoxTexture STRETCH/TILE_FIT 문구, NinePatchRect 기본 STRETCH | confirmed |
| 11 | Button focus 스타일박스 경고 | confirmed |
| 12 | StyleBoxFlat anti_aliasing·corner_detail=1 권고 | confirmed |
| 13 | #86563 4.5.beta5에도 열림, Calinou 발언 | corrected |
| 14 | Galmuri 변형별 px·OFL 1.1 | confirmed |
| 15 | Galmuri7 한글 수 충돌(사이트 11,172 vs README 4,358 vs 로컬 11,172) | confirmed |
| 16 | Neo둥근모 OFL·상업 이용·재판매 금지·16px 배수·볼드 금지 | confirmed |
| 17 | m5x7 CC0+attribution appreciated, m3x6 with attribution, 16·32·48 | confirmed |
| 18 | scale_mode는 4.2부터, GDQuest "requires 4.3"은 틀림 | corrected |

---

## 1. stretch mode 문구 — confirmed
- 4.3·4.4·4.5·4.6·4.7·master의 `display/window/stretch/mode` 설명에서 인용한 두 문장이 글자 그대로 같다. 차이는 둘이다. 4.6부터 `[b]`가 `[code]`로 바뀌었고, 4.7·master에서는 canvas_items 설명 끝에 "This is the default for projects created starting in Godot 4.7."가 붙었다. 4.2는 철자가 "esthetic"이다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/4.3/doc/classes/ProjectSettings.xml (900~905행), https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/ProjectSettings.xml (1087~1092행), https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/ProjectSettings.xml (1102~1107행), https://raw.githubusercontent.com/godotengine/godot/4.2/doc/classes/ProjectSettings.xml (842~847행)

## 2. 픽셀 아트 데스크톱 권장 — confirmed
- "Pixel art:" 목록에 다음이 있다. "640×360 is a good baseline"(1280×720·1920×1080·2560×1440·3840×2160), "Set the stretch mode to viewport", aspect `keep` 또는 `expand`, "Set the stretch scale mode to integer. This prevents uneven pixel scaling from occurring". note에는 "If you are OK with sprites being able to move or rotate in "sub-pixel" positions or wish to have a high resolution 3D viewport, you should use the canvas_items stretch mode"라고 적혀 있다. 이동만이 아니라 "move or rotate"다.
- 근거: https://raw.githubusercontent.com/godotengine/godot-docs/stable/tutorials/rendering/multiple_resolutions.rst (407~430행), https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

## 3. 4.7 새 프로젝트 기본 canvas_items — confirmed
- 문서(4.7·master XML)에는 "This is the default for projects created starting in Godot 4.7."가 있고 4.6 XML에는 없다. 소스로도 확인했다. 4.7 `EditorNode::get_initial_settings()`가 새 프로젝트의 project.godot에 `display/window/stretch/mode = "canvas_items"`와 `display/window/stretch/aspect = "expand"`를 쓴다. 4.6에는 이 두 줄이 없다.
- 덧붙일 점: 엔진 수준 기본값은 4.7에서도 `"disabled"`다(`GLOBAL_DEF_BASIC(... "display/window/stretch/mode" ...), "disabled")`, XML `default="disabled"`). 그래서 이 키가 없는 기존 프로젝트는 계속 disabled로 돈다. 새 프로젝트의 aspect 기본도 expand로 바뀌었다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/4.7/editor/editor_node.cpp (8346~8353행), https://raw.githubusercontent.com/godotengine/godot/4.6/editor/editor_node.cpp (8180~8185행), https://raw.githubusercontent.com/godotengine/godot/4.7/core/config/project_settings.cpp (1787행), https://raw.githubusercontent.com/godotengine/godot/4.6/doc/classes/ProjectSettings.xml

## 4. 오버샘플링 — confirmed
- 4.5·4.6·4.7·master의 `gui/fonts/dynamic_fonts/use_oversampling`(default true) 설명: "If set to true and display/window/stretch/mode is set to "canvas_items", font and DPITexture oversampling is enabled in the main window." 4.3·4.4에서는 설명이 비어 있다.
- `Viewport.oversampling`(bool, 기본 true)과 `oversampling_override`(기본 0.0, "If greater than zero, this value is used as the font oversampling factor, otherwise oversampling is equal to viewport scale.")는 4.5 XML부터 있다. 4.3·4.4 Viewport.xml에는 두 멤버가 없다(grep 0건).
- 근거: https://raw.githubusercontent.com/godotengine/godot/4.5/doc/classes/Viewport.xml (378~383행), https://raw.githubusercontent.com/godotengine/godot/4.4/doc/classes/Viewport.xml, https://raw.githubusercontent.com/godotengine/godot/4.3/doc/classes/Viewport.xml, https://raw.githubusercontent.com/godotengine/godot/4.5/doc/classes/ProjectSettings.xml (1198~1200행), https://raw.githubusercontent.com/godotengine/godot/4.3/doc/classes/ProjectSettings.xml (1046~1047행)

## 5. 셰이더 정점 스냅 → 화면 픽셀 기준 — corrected
- 셰이더 코드는 맞다. canvas.glsl 287~290행은 `vertex = (canvas_data.canvas_transform * vec4(vertex, 0.0, 1.0)).xy;` 다음에 `if (canvas_data.use_pixel_snap) { vertex = floor(vertex + 0.5); ... }`를 둔다. 노트가 Gaps로 남긴 부분(스트레치 변환이 canvas_transform에 들어가는가)도 소스로 확인했다. `Viewport::_update_global_transform()`가 `stretch_transform * global_canvas_transform`을 RenderingServer에 넘긴다(viewport.cpp 1276~1279행). `_canvas_get_transform()`은 `xf = p_viewport->global_transform`에 캔버스 변환을 곱한다(renderer_viewport.cpp 53~80행). 이것이 `state_buffer.canvas_transform`이 되고(renderer_canvas_render_rd.cpp 684행), `use_pixel_snap`은 `snap_2d_vertices_to_pixel`에서 온다(706행). 따라서 **`snap_2d_vertices_to_pixel`의 스냅은 화면(렌더 타깃) 픽셀 기준**이 맞다.
- 바로잡을 점: 이 결론을 "픽셀 스냅" 전반으로 넓히면 틀린다. 나머지 두 스냅은 **부모 좌표 단위**에서 반올림한다. canvas_items+정수 배율에서는 그 단위가 기본 해상도, 곧 아트 픽셀이다.
  - `gui/common/snap_controls_to_pixels`(기본 true)는 Control의 로컬 위치를 `xform[2] = (xform[2] + Vector2(0.5, 0.5)).floor()`로 부모 좌표에서 반올림한다(control.cpp 760~761행). 회전이 없을 때만 적용된다.
  - `snap_2d_transforms_to_pixel`은 각 CanvasItem의 `self_xform.columns[2]`를 부모 좌표에서 반올림한다(renderer_canvas_cull.cpp 361~363행). 카메라·캔버스 변환 이동도 스트레치를 곱하기 전에 `ceil`로 반올림한다(renderer_viewport.cpp 57~80행).
  - 정리하면, 조상의 스케일·회전이 1·0이면 Control과 Node2D의 **위치**는 이미 아트 격자(2배에서 짝수 화면 픽셀)에 놓인다. 화면 픽셀(아트 반 픽셀) 단위로 어긋날 수 있는 것은 노드 안에서 그리는 내용이다(가운데 정렬 글자의 내부 오프셋, 분수 크기 Control의 사각형 끝, `draw_*`의 소수 좌표, 스케일·회전 트윈 중인 노드).
- 근거: https://raw.githubusercontent.com/godotengine/godot/4.7/servers/rendering/renderer_rd/shaders/canvas.glsl , https://raw.githubusercontent.com/godotengine/godot/4.7/scene/main/viewport.cpp , https://raw.githubusercontent.com/godotengine/godot/4.7/servers/rendering/renderer_viewport.cpp , https://raw.githubusercontent.com/godotengine/godot/4.7/servers/rendering/renderer_rd/renderer_canvas_render_rd.cpp , https://raw.githubusercontent.com/godotengine/godot/4.7/servers/rendering/renderer_canvas_cull.cpp , https://raw.githubusercontent.com/godotengine/godot/4.7/scene/gui/control.cpp

## 6. snap 두 설정 — confirmed
- 4.3~master 모두 같다. transforms 쪽 설명: "It is not recommended to use this setting together with snap_2d_vertices_to_pixel, as movement may appear even less smooth. Prefer only enabling this setting instead." vertices 쪽 설명: "... Prefer only enabling that setting instead."(that = transforms). 두 설정 모두 "This property is only read when the project starts"이고, "less smooth movement, especially when Camera2D smoothing is enabled"라고 적혀 있다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/ProjectSettings.xml (2883~2894행), https://raw.githubusercontent.com/godotengine/godot/4.3/doc/classes/ProjectSettings.xml (2346~2356행)

## 7. 픽셀 폰트 지침 — confirmed
- "Fonts that have a pixel art appearance should have bilinear filtering disabled by changing the Rendering > Textures > Canvas Textures > Default Texture Filter project setting to Nearest." / "The font size must also be an integer multiple of the design size (which varies on a per-font basis), and the Control node using the font must be scaled by an integer multiple as well." / "Fonts that have a pixel art appearance should have their subpixel positioning mode set to Disabled." 비트맵 폰트에는 subpixel 설정이 필요 없다는 단서도 있다.
- 근거: https://raw.githubusercontent.com/godotengine/godot-docs/stable/tutorials/ui/gui_using_fonts.rst (171~178행, 324~329행), https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html

## 8. 동적 폰트 임포트 기본값 — confirmed
- XML default: subpixel_positioning은 4.3에서 1, 4.4·4.5·4.6·4.7·master에서 4다. hinting은 4.3~4.6에서 1, 4.7·master에서 3이다. 임포터 소스의 enum 문자열로 번호의 뜻도 확인했다. 4.3은 hinting "None,Light,Normal" 기본 1, subpixel "Disabled,Auto,One Half,One Quarter" 기본 1이다. 4.4는 subpixel에 "Auto (Except Pixel Fonts)"(4번)가 더해지고 기본이 4다. 4.7은 hinting "None,Light,Normal,Light (Except Pixel Fonts),Normal (Except Pixel Fonts)" 기본 3이다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/4.3/doc/classes/ResourceImporterDynamicFont.xml , https://raw.githubusercontent.com/godotengine/godot/4.4/doc/classes/ResourceImporterDynamicFont.xml , https://raw.githubusercontent.com/godotengine/godot/4.6/doc/classes/ResourceImporterDynamicFont.xml , https://raw.githubusercontent.com/godotengine/godot/4.7/doc/classes/ResourceImporterDynamicFont.xml , https://raw.githubusercontent.com/godotengine/godot/4.7/editor/import/resource_importer_dynamic_font.cpp (128~129행), https://raw.githubusercontent.com/godotengine/godot/4.3/editor/import/resource_importer_dynamic_font.cpp (120~121행)

## 9. 비트맵 폰트 배율 모드 — confirmed
- TextServer.xml: `FIXED_SIZE_SCALE_INTEGER_ONLY`(1) "This is the recommended option for pixel art fonts.", `FIXED_SIZE_SCALE_ENABLED`(2) "recommended option for non-pixel art fonts". ResourceImporterImageFont.xml 48행과 ResourceImporterBMFont.xml 21행은 `scaling_mode default="2"`이다. 임포터 소스(master)의 기본값도 `TextServer::FIXED_SIZE_SCALE_ENABLED`이고, 에디터 표시 이름은 "Disabled, Enabled (Integer), Enabled (Fractional)"이다. 따라서 Import 독에서는 "Enabled (Integer)"를 고르면 된다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/TextServer.xml (2395~2402행), https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/ResourceImporterImageFont.xml , https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/ResourceImporterBMFont.xml , https://raw.githubusercontent.com/godotengine/godot/master/editor/import/resource_importer_imagefont.cpp (77행), https://raw.githubusercontent.com/godotengine/godot/master/editor/import/resource_importer_bmfont.cpp (69행)

## 10. 9-slice 늘이기 모드 — confirmed
- StyleBoxTexture: STRETCH "This results in visible distortion unless the texture size matches the stylebox's size perfectly." TILE_FIT "the texture may be slightly stretched to make the nine-patch texture tile seamlessly." NinePatchRect description: "it tiles the texture's edges horizontally or vertically, tiles the center on both axes, and leaves the corners unchanged." 그러나 `axis_stretch_horizontal/vertical` default="0"(STRETCH)이다. StyleBoxTexture의 두 축 기본값도 0이다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/NinePatchRect.xml (7행, 29~33행), https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/StyleBoxTexture.xml (58~62행, 112~119행)

## 11. Button focus — confirmed
- "The focus StyleBox is displayed over the base StyleBox, so a partially transparent StyleBox should be used ... A StyleBox that represents an outline or an underline works well for this purpose. ... disabling the focus visual effect will harm keyboard/controller navigation usability, so this is not recommended for accessibility reasons."
- 근거: https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/Button.xml (155~157행)

## 12. StyleBoxFlat 안티에일리어싱 — confirmed
- `anti_aliasing` default="true", "This is only noticeable when using rounded corners or skew." Note: "When using beveled corners with 45-degree angles (corner_detail = 1), it is recommended to set anti_aliasing to false to ensure crisp visuals and avoid possible visual glitches." corner_detail 1은 "chamfered corners"다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/master/doc/classes/StyleBoxFlat.xml (97~99행, 126~129행)

## 13. GitHub #86563 — corrected(정밀화)
- 사실관계는 맞다. 이슈는 2023-12-27에 올라왔다(4.2.1·4.1.3 재현). Calinou(author_association MEMBER)는 2024-01-01에 "It seems to be related to how font oversampling works, possibly rounding in an incorrect manner"라고 썼고, 2025-01-20에 "I can still reproduce this as of 4.4.beta1"이라고 썼다. 2025-08-12 사용자가 "Currently the newest version is 4.5.beta5"라며 고쳐졌는지 묻자 Calinou는 "No, not yet."이라고 답했다. 2025-09-18에는 "Control scaling should only be used for animation purposes, not for persistent scaling."이라고 썼다.
- 바로잡을 점:
  1. 이슈는 "4.5.beta5 시점"에만 열려 있던 것이 아니다. 오늘(2026-11-15) API 조회에서도 `state: open`, `closed_at: null`, 라벨 bug·confirmed·topic:rendering·topic:gui이다. 마지막 댓글은 2026-01-20이다.
  2. Calinou는 2025-09-18에 원인 추정을 바꿨다. "I assume there's some kind of race condition that makes oversampling pick a slightly lower scale factor than actually needed when resizing the window"라고 쓰면서, 한 번만 리사이즈해도 생기니 다른 원인일 수 있다고 덧붙였다.
  3. "Control scaling ..." 문장은 Control 노드(와 부모)의 `scale` 속성을 (1,1)로 두라는 맥락이다. 스트레치 배율을 두고 한 말이 아니다.
- 근거: https://github.com/godotengine/godot/issues/86563 , https://api.github.com/repos/godotengine/godot/issues/86563 , https://api.github.com/repos/godotengine/godot/issues/86563/comments

## 14. Galmuri 크기·라이선스 — confirmed
- README 표 머리: "Galmuri14 (15px, 11pt) | Galmuri11 (12px, 9pt) | Galmuri11 Bold (12px, 9pt) | Galmuri11 Condensed (12px, 9pt) | Galmuri9 (10px, 7.5pt) | Galmuri7 (8px, 6pt)". GitHub 라이선스 SPDX는 OFL-1.1이다. 공식 사이트도 "SIL 오픈 폰트 라이선스 1.1"이라고 적는다.
- 근거: https://github.com/quiple/galmuri (README), https://quiple.dev/font/galmuri

## 15. Galmuri7 한글 수 — confirmed(충돌은 풀림)
- 세 사실 모두 맞다. 공식 사이트에 "모든 폰트가 한글 완성자 11,172자를 지원합니다."가 있다. README(main, 오늘 받음)의 Galmuri7 Hangul Syllables 칸에는 `[^han-1]: Only 4,358 Hangul Syllables included in Adobe-KR-0 and Adobe-KR-1.` 각주가 아직 붙어 있다. 로컬 `art/fonts/Galmuri7.ttf`를 다시 파싱하니 cmap format 4에서 U+AC00–D7A3 11,172/11,172가 매핑되어 있고, 이름 테이블 버전은 "Version 2.404"였다.
- 충돌의 원인: 릴리스 v2.40.0(2025-08-08) 노트에 "G7, GM7: 모든 한글 음절을 추가했습니다."가 있다. 뒤이은 v2.40.1~v2.40.3(2025-08-08~13)에서 G7의 "일부 한글 음절의 모양"을 고쳤다. 따라서 README 각주는 v2.40.0 이전 상태가 남은 것이고, v2.40.0 이상(로컬 2.404 포함)은 11,172자를 모두 담는다. 노트 Gaps의 "4,358자만 손으로 다듬었는지" 의문은 릴리스 노트로 보아 v2.40.0에서 나머지를 '추가'한 것이다. 품질 차이는 여전히 확인하지 않았다.
- 근거: https://quiple.dev/font/galmuri , https://github.com/quiple/galmuri (README 20행 각주), https://github.com/quiple/galmuri/releases/tag/v2.40.0 , https://api.github.com/repos/quiple/galmuri/releases

## 16. Neo둥근모 — confirmed(인용처 보정)
- guides.html에는 "글꼴의 크기는 16픽셀의 배수로 맞추어 주시기 바랍니다."와 "볼드체나 이탤릭체 등의 글꼴 스타일을 적용하지 마세요."가 있다. 라이선스 문구는 guides.html이 아니라 첫 화면과 README에 있다. 첫 화면: "Neo둥근모, Neo둥근모 Code 및 Neo둥근모 Pro는 SIL Open Font License 1.1 하에 배포됩니다. 따라서 상업적, 또는 비 상업적 용도로 자유롭게 사용, 수정, 임베드, 및 재배포할 수 있습니다. 단, 이 글꼴을 유료로 재판매하는 행위는 금지됩니다." README: "상업적 또는 비 상업적 용도로 어디서든 자유롭게 이용하실 수 있으며". README의 이 문장은 Neo둥근모·Code만 명시하고, 첫 화면은 Pro까지 포함한다.
- 근거: https://neodgm.dalgona.dev/guides.html , https://neodgm.dalgona.dev/ , https://github.com/neodgm/neodgm (README "라이선스" 절)

## 17. m5x7·m3x6 — confirmed
- m5x7 페이지: 라이선스 "Creative Commons Zero v1.0 Universal", "free to use but attribution appreciated", "use font size 16, 32, 48, etc". m3x6 페이지: "free to use with attribution", "use font size 16, 32, 48, etc". m3x6 페이지에서는 CC 라이선스 칸을 찾지 못했다.
- 근거: https://managore.itch.io/m5x7 , https://managore.itch.io/m3x6

## 18. integer scale_mode 도입 버전 — corrected
- 결론(4.2가 맞음)은 맞다. 4.2 브랜치 ProjectSettings.xml 851~854행에 `display/window/stretch/scale_mode`("integer" … "crisp pixel art appearance")가 있다. 4.2 `core/config/project_settings.cpp` 1373행에도 `GLOBAL_DEF_BASIC(... "display/window/stretch/scale_mode", ..., "fractional,integer"), "fractional")`가 있다. 4.1 XML에는 없다(0건). 문서에도 "Since Godot 4.2, the Stretch Scale Mode setting allows you to constrain ..."가 있다.
- 바로잡을 점: GDQuest 인용이 틀렸다. 페이지(4.4 기준 가이드) 원문은 "Since Godot 4.3, the engine has a handy feature called integer scaling."이고, "Integer scale mode requires Godot 4.3 or later"라는 문장은 페이지 HTML에 없다. GDQuest가 도입 시점을 4.3으로 적은 것은 틀린 서술이 맞지만, 인용은 원문대로 고쳐야 한다.
- 근거: https://raw.githubusercontent.com/godotengine/godot/4.2/doc/classes/ProjectSettings.xml , https://raw.githubusercontent.com/godotengine/godot/4.1/doc/classes/ProjectSettings.xml , https://raw.githubusercontent.com/godotengine/godot/4.2/core/config/project_settings.cpp , https://raw.githubusercontent.com/godotengine/godot-docs/stable/tutorials/rendering/multiple_resolutions.rst (312행), https://www.gdquest.com/library/pixel_art_setup_godot4/

---

## 노트를 훑으며 본 다른 오류

가장 큰 문제는 §4 Inference 3, (a′), §5 Takeaway·Inference다. 이 부분은 "canvas_items에서는 어느 쪽 스냅이든 화면 픽셀 기준이라 아트 격자를 보장하지 않는다", "좌표 x.5에 놓인 라벨·패널·아이콘은 아트 반 픽셀 어긋난다", "엔진 스냅은 화면 픽셀 기준이니 위치 반올림을 코드에서 해야 한다"고 단정하지만, 4.7 소스와 맞지 않는다(위 5번). `snap_controls_to_pixels`(기본 true)는 Control 위치를, `snap_2d_transforms_to_pixel`은 CanvasItem 위치를 부모 좌표(기본 해상도 단위)에서 반올림한다. 그래서 조상이 스케일·회전되지 않았다면 Control 노드의 위치와 위치 트윈은 이미 정수 아트 픽셀에 놓인다. 화면 픽셀 단위로 어긋나는 것은 노드 안 그리기 오프셋, 분수 크기, 스케일 트윈이다. `tween_method(... v.round())` 권고는 Node2D(transforms 스냅이 꺼진 요청자 설정)나 사용자 `draw_*`에서만 의미가 있다. 요청자 설정은 `snap_2d_vertices_to_pixel=true`만 켜고 transforms는 끈 상태다. 문서가 권하는 쪽(transforms만)과 반대라는 점도 노트가 더 분명히 짚어야 한다. 둘째, §4 Cited의 GDQuest 인용 "Integer scale mode requires Godot 4.3 or later"는 원문에 없는 문장이다(원문 "Since Godot 4.3, the engine has a handy feature called integer scaling."). 셋째, #86563은 2026-11-15 현재도 열려 있다. Calinou의 최신 원인 추정은 반올림이 아니라 리사이즈 때 오버샘플링 배율을 약간 낮게 고르는 경합(race condition) 가능성이다. 넷째, Galmuri7 4,358자 충돌은 v2.40.0(2025-08-08) 릴리스 노트 "G7, GM7: 모든 한글 음절을 추가했습니다."로 풀리므로 Gaps에서 빼도 된다. 다섯째, Neo둥근모 라이선스·재판매 문구의 출처는 guides.html이 아니라 neodgm.dalgona.dev 첫 화면과 GitHub README다. 4.7 새 프로젝트는 stretch mode뿐 아니라 aspect도 `expand`로 만든다는 점(editor_node.cpp)도 덧붙일 만하다. 나머지 스폿체크(NinePatchRect mouse_filter 기본 2, Label line_spacing 3·shadow_offset 1/1·shadow_outline_size 1·font_shadow_color 투명, ThemeDB fallback_font_size 16, SubViewportContainer stretch_shrink 예시, "font shadows always have a hard edge", RIDF antialiasing·oversampling 4.3/4.5 문구, 로컬 project.godot 값)는 모두 원문과 일치했다.

## 덧붙임(2026-11-15, 보고서 검토 반영): GitHub #88373

- 보고서 F7이 인용한 이슈인데 위 노트에 없어서 `gh api repos/godotengine/godot/issues/88373`로 확인했다.
- 제목 "Font outline is inconsistent with small pixel fonts", 2024-02-15 Shadowblitz16 작성, `state: open`, 라벨은 `bug`·`topic:gui` 둘뿐(`confirmed` 없음), 댓글 0개.
- 본문: 시험 판 v4.2.1.stable.mono, "Font outline are inconsistent for small pixels fonts...", "anything less then 6 doesn't render inner pixels...". 재현 프로젝트 첨부.
- 정리: 사용자 한 명의 보고이고 엔진 측 확인(confirmed)이 없다. 4.7에서 재현되는지는 확인하지 않았다.
- 출처: https://github.com/godotengine/godot/issues/88373
