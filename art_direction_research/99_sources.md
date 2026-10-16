# 99. 출처와 검증 기록

확인 날짜는 R-26까지 2026-10-14, R-27부터 2026-10-16이다. 1·2차는 deep-research 워크플로로 했고, 검증 대상 주장마다 3표 반박 검증을 했다. R-27~R-29(림월드)는 처음에 이 워크플로 밖에서 단일 검색으로 더했다. 3차는 deep-research 스킬로 조사 4갈래와 보고서 작성을 했고, 주장마다 3표 반박 검증은 하지 않았다. 그래서 R-27부터는 표결 칸에 표 수 대신 확인한 방식(코드·문서·원문 확인, 단일 출처, 요약으로만 확인)을 적었다. R-27~R-29는 3차에서 디컴파일 코드로 다시 확인해 고쳤다.

```
1차 (run wf_757ac36d-ca0) 레퍼런스 작품 → 01
검색   5갈래(a~e) 병렬 검색 → 출처 20개 수집
추출   주장 98개 → 검증 대상 25개(예산으로 8개 제외)
검증   주장마다 3표 반박 검증(반박 2표면 기각) → 확인 23 · 기각 2
종합   의미가 겹치는 주장을 합쳐 12개(R-01~R-12)

2차 (run wf_c4e59e02-35f) 시점·높이, 팔레트, 가독성 → 02~04
검색   5갈래 병렬 검색 → 출처 21개 수집
추출   주장 101개 → 검증 대상 25개(예산으로 9개 제외)
검증   같은 방식 → 확인 23 · 기각 2
종합   16개 → 주제별로 나눠 R-13~R-26

3차 (deep-research 스킬, 2026-10-16) Godot 그리기 구조, 유닛 표현 → 05·06
조사   4갈래 — A1 Godot 공식 문서·엔진 소스, A2 성능 측정·실무 보고, B1 다수 유닛 게임의 유닛 표현(림월드 재확인), B2 3D→도트 파이프라인과 연출 수치
보고   갈래 노트 4개를 보고서 1편으로 합침
검증   주장마다 3표 반박 검증은 하지 않음. 갈래마다 원문·소스를 열어 인용했고, 검색 요약에서만 본 것은 따로 표시함
종합   R-27~R-29 고침, R-30~R-62 추가
```

## 1. 주장 대장 (ID → 출처)

| ID | 작품 | 표결 | 성격 | 출처 |
|---|---|---|---|---|
| R-01 | 스타크래프트 1 | 3-0, 3-0, 3-0, 2-1 | 1차(블리자드 회고, 2017 리마스터 홍보기) | https://news.blizzard.com/en-us/starcraft/20719767 · https://news.blizzard.com/en-us/article/20726732/behind-the-scenes-of-starcraft-remastered · https://www.pcgamesn.com/starcraft-remastered/starcraft-design-retrospective-blizzard |
| R-02 | 디아블로 2 | 3-0, 3-0 | 1차(포스트모템 사본) | https://www.cs.hmc.edu/~markk/SWE_copies/postmortem__diablo_ii.html |
| R-03 | Age of Empires | 3-0, 3-0 | 1차(포스트모템) | https://www.gamedeveloper.com/game-platforms/the-game-developer-archives-postmortem-ensemble-s-age-of-empires- |
| R-04 | Dead Cells | 3-0, 3-0, 3-0 | 1차(아트 디렉터 글) + 포럼 | https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i- · https://steamcommunity.com/app/588650/discussions/0/1291817208492158139 |
| R-05 | Factorio | 3-0, 3-0 | 1차(공식 블로그, 2016) | https://factorio.com/blog/post/fff-146 |
| R-06 | three.js RenderPixelatedPass | 2-1, 3-0 | 1차(소스, dev 브랜치) | https://github.com/mrdoob/three.js/blob/dev/examples/jsm/postprocessing/RenderPixelatedPass.js |
| R-07 | The Last Spell | 3-0, 3-0, 3-0 | 1차(개발 블로그) | https://lastspell.com/?p=851 · https://lastspell.com/?p=1033 |
| R-08 | Kingdom | 3-0, 2-1 | 1차(인터뷰, 2014·2015) | https://cliqist.com/2014/05/19/thomas-van-den-berg-discusses-the-new-kingdom/ · https://80.lv/articles/kingdom-how-2-guys-created-a-side-scrolling-strategy/ |
| R-09 | Rise to Ruins | 3-0 | 공식(상점 문구) + 2차 | https://store.steampowered.com/app/328080/Rise_to_Ruins · https://en.wikipedia.org/wiki/Rise_to_Ruins |
| R-10 | They Are Billions | 2-1, 3-0 | 공식(발표 글) | https://numantiangames.com/News/2017-05-31-new-game-they-are-billions/ |
| R-11 | 공통 교훈 | 종합 | **추론** — 개별 사례는 검증됐고 묶은 판단은 검증 대상이 아니다 | R-01, R-03, R-04, R-05, R-06, R-07 |
| R-12 | 상위 레퍼런스 선정 | 종합 | **추론** | R-01~R-08 |
| R-13 | Factorio 45도 dimetric | 3-0, 3-0 | 1차(개발 블로그 FFF-133, 2016) + 포럼 | https://www.factorio.com/blog/post/fff-133 · https://forums.factorio.com/viewtopic.php?p=473901 |
| R-14 | 각도별 높이·깊이 배율, 가림 방향 | 종합 | **추론** — 정사영 기하 계산. 사례 출처 없음 | R-13, `SPEC.md:112`(S51) |
| R-15 | 젤다 ALBW 물체 기울이기 | 3-0, 3-0 | 2차 기사(Iwata Asks 4부와 대조) | https://gameinformer.com/b/news/archive/2013/11/20/the-trick-behind-the-legend-of-zelda-a-link-between-worlds-top-down-view |
| R-16 | Pillow quantize와 디더 옵션 | 3-0, 3-0 | 1차(공식 문서 12.3.0) | https://pillow.readthedocs.io/en/stable/reference/Image.html |
| R-17 | 디더링 방식별 대가 | 3-0 ×4 | 기술 블로그·개인 블로그 | https://surma.dev/things/ditherpunk/ · https://hackaday.io/project/19731-polapi-zero/log/59139-pillow-tweaking-ordered-dithering |
| R-18 | Fantasy 24 팔레트 | 3-0, 3-0 | 1차(Lospec 페이지·JSON) | https://lospec.com/palette-list/fantasy-24 · https://lospec.com/palette-list/fantasy-24.json |
| R-19 | Waldgeist, Lospec dark 태그 순위 | 3-0 | 1차(Lospec) | https://lospec.com/palette-list/tag/dark · https://lospec.com/palette-list/waldgeist |
| R-20 | Slynyrd 색 램프 제작법 | 3-0 | 블로그(저자 본인, 단일 출처, low) | https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes |
| R-21 | Godot CanvasModulate·노멀맵 조명 | 3-0, 3-0 | 1차(공식 문서 4.2, 4.7판에 같은 문장) | https://docs.godotengine.org/en/4.2/tutorials/2d/2d_lights_and_shadows.html |
| R-22 | Graveyard Keeper LUT 그레이딩 | 3-0 | 개발자 기술 글(같은 글의 두 판본) | https://slava.lazybeargames.com/graveyard-keeper-how-the-graphics-effects-are-made |
| R-23 | 외곽선 원칙, The Last Spell 외곽선 변경 이유 | 3-0 ×3 | 블로그 튜토리얼 + 1차(개발 블로그) | https://lospec.com/articles/pixel-art-outlines-part-2-using-color · https://lastspell.com/?p=851 |
| R-24 | SC2 팀 색 과다 | 3-0, 2-1 | 2차(커뮤니티 매니저 전달의 재전달) | https://www.gosugamers.net/news/7571-graphic-change-in-the-works-for-starcraft-ii |
| R-25 | Zach Gage Subway Legibility | 3-0 | 발표 원고 + 2차 요약 | http://stfj.net/DesigningForSubwayLegibility/ · https://gigazine.net/gsc_news/en/20180501-game-design-subway-legibility |
| R-26 | 시험 설정값 후보표의 권장안 | 종합 | **추론** | R-13~R-25 |
| R-27 | 림월드 일반 폰에는 걷기·공격 프레임이 없다. 이동은 칸 사이 위치 보간이고, 공격·피격은 위치 오프셋·붉은 점멸·무기 회전으로 보여 준다. 예외는 1.6판 Anomaly 특수 동작(키프레임 `AnimationDef`)과 `flyingAnimationFramePathPrefix`를 가진 비행 동물의 프레임 애니메이션. «둥둥 떠다닌다»는 불만은 커뮤니티 한 곳의 말 | 코드 확인(디컴파일 1.0·1.6 추정, 반박 표결 아님). 불만 문장은 단일 출처 | 디컴파일 코드 + 커뮤니티(Steam 토론), 확인 2026-10-16 | https://github.com/josh-m/RW-Decompile/blob/master/Verse/PawnTweener.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/Pawn_DrawTracker.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/PawnRenderer.cs · https://github.com/IlyaChichkov/RimworldDecompiled/blob/main/RimWorld/AnimationDefOf.cs · https://github.com/IlyaChichkov/RimworldDecompiled/blob/main/RimWorld/AnimationDefGenerator_Flying.cs · https://steamcommunity.com/app/294100/discussions/0/1815422173027253772 |
| R-28 | 림월드 방향 그림은 `_north`·`_east`·`_south`이고, `_west`가 없으면 동쪽을 뒤집는다(`_west`를 주면 그것을 쓴다). 해상도는 바닐라 원본 64 ppt, 최신 DLC와 대다수 모드 128 ppt | 방향은 코드 확인(디컴파일 1.0·1.6 추정, 반박 표결 아님). 해상도는 위키 단일 출처 | 디컴파일 코드 + 커뮤니티(모딩 위키, 작성 중 표시), 확인 2026-10-16 | https://github.com/josh-m/RW-Decompile/blob/master/Verse/Graphic_Multi.cs · https://github.com/IlyaChichkov/RimworldDecompiled/blob/main/Verse/Graphic_Multi.cs · https://rimworldwiki.com/wiki/Modding_Tutorials/Textures |
| R-29 | 림월드 건설은 설계도 → 골조(frame) → 완성 건물 순으로 바뀐다. 실패하면 골조를 지우고 설계도를 다시 놓으며 실패 글자를 띄운다. 골조는 바닥판과 네 모서리 표시 위에 진행도만큼 1/4칸 조각이 차오른다 | 코드 확인(디컴파일 1.0, 반박 표결 아님) | 디컴파일 코드, 확인 2026-10-16 | https://github.com/josh-m/RW-Decompile/blob/master/RimWorld/Blueprint_Build.cs · https://github.com/josh-m/RW-Decompile/blob/master/RimWorld/Frame.cs |
| R-30 | 림월드 피격·돌진. 체력을 깎는 피해(`harmsHealth`)면 16틱 동안 빨강에서 원래 색으로 선형 복귀한다. 충격이 있는 피해면 피해 방향으로 0.17칸, 막히면 0.1칸 밀리고 틱당 0.018칸씩 돌아온다(합계 상한 0.35칸). 근접 공격자는 대상 쪽으로 0.5칸(같은 칸이면 0.25) 돌진하되 0.35칸에서 잘린다. 1.6 추정판도 상수가 같다 | 코드 확인(디컴파일 1.0·1.6 추정, 반박 표결 아님) | 디컴파일 코드 | https://github.com/josh-m/RW-Decompile/blob/master/Verse/DamageFlasher.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/DamagedMatPool.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/JitterHandler.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/Pawn_DrawTracker.cs · https://github.com/IlyaChichkov/RimworldDecompiled/blob/main/Verse/JitterHandler.cs |
| R-31 | 림월드 쓰러짐·죽음. 같은 그림을 45~135° 또는 225~315°로 돌려 눕힌다. 깨어 있으면 주기적으로 꿈틀거리고, 쓰러진 동안 200틱마다 무력화 아이콘을 띄운다. 시체는 폰 렌더러로 그리고 부패 단계마다 텍스처를 바꾼다 | 코드 확인(디컴파일 1.0, 각도 규칙은 1.6 추정판도 같음, 반박 표결 아님) | 디컴파일 코드 | https://github.com/josh-m/RW-Decompile/blob/master/Verse/PawnDownedWiggler.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/PawnRenderer.cs · https://github.com/josh-m/RW-Decompile/blob/master/Verse/Corpse.cs · https://github.com/IlyaChichkov/RimworldDecompiled/blob/main/Verse/PawnDownedWiggler.cs |
| R-32 | 림월드 반응. Steam 리뷰 97.9% 긍정(248,159건). 몸 움직임 모드 Yayo's Animation (Continued) 현재 구독 668,880, 얼굴 모드 [NL] Facial Animation 804,384, 비교 기준 Harmony 3,328,886(2026-10-16 조회). Yayo's는 걷기를 새 프레임 없이 기울이기(기본 ±5.4°)와 0.025칸 흔들기로 만든다. 리뷰 «Despite lacking any real animations, the game does a very good job of visually and audibly keeping you informed» | API·원문 확인(반박 표결 아님). 리뷰 인용은 단일 출처 | Steam Web API + 모드 소스(커밋 f11c69a) + 리뷰 사이트 | https://store.steampowered.com/appreviews/294100?json=1&language=all&purchase_type=all · https://steamcommunity.com/sharedfiles/filedetails/?id=2877292196 · https://steamcommunity.com/sharedfiles/filedetails/?id=1635901197 · https://steamcommunity.com/sharedfiles/filedetails/?id=2009463077 · https://github.com/DRA-Mods/Yayos-Animation/blob/f11c69a/Source/AnimationCore.cs · https://gideonsgaming.com/2018/10/22/rimworld-review/ |
| R-33 | Godot 2D 그리기 비용(공식 bunnymark, Godot 4.8.dev, i5-12400, 2026-10-11 실행). Sprite2D 5,000개 렌더 CPU 0.36ms·GPU 0.35ms(RX 550). 노드 하나의 `_draw()`에서 `draw_texture()` 5,000회는 렌더 CPU 0.15ms. GT 1030에서는 Sprite2D 렌더 CPU 4.49ms. 렌더 CPU에는 process·physics 함수 시간이 들어가지 않는다 | 결과·소스 확인(반박 표결 아님) | 1차(공식 벤치마크 결과·소스·README) | https://github.com/godotengine/godot-benchmarks-results/blob/main/2026-10-11_232e6b14a.md · https://github.com/godotengine/godot-benchmarks/blob/main/benchmarks/rendering/bunnymark.gd · https://github.com/godotengine/godot-benchmarks |
| R-34 | Forward+·Mobile의 2D batching은 4.4에 들어왔다(Compatibility는 4.0부터). 1×1 Sprite2D 10,000개로 CPU에 부하를 건 리뷰 측정에서 935 → 1,632 FPS. 4.4 dev6 사용자 측정에서 `draw_texture()`·`draw_rect()`·`draw_line()`은 묶이고 `draw_arc()`·`draw_circle()`·`draw_polygon()`은 호출마다 draw call이 따로 생긴다 | 블로그·PR 확인(반박 표결 아님). `draw_*` 측정은 PR 댓글 하나라 단일 출처 | 1차(공식 블로그, PR) | https://godotengine.org/article/dev-snapshot-godot-4-4-dev-3/ · https://github.com/godotengine/godot/pull/92797 |
| R-35 | 배치를 끊는 조건(4.7.2 RD 2D 렌더러). polygon 명령과 mesh·multimesh·particles 명령은 늘 새 배치를 연다. 텍스처 상태(텍스처·filter·repeat), material, clip, 조명 사용 여부, 명령 종류가 바뀌어도 새 배치다. LCD가 아닌 modulate는 조건에 없다(소스에서 부재 확인). 4.4부터 CanvasItem 셰이더 instance uniform은 «does not break batching» | 소스·릴리스 페이지 확인(반박 표결 아님) | 1차(엔진 소스 4.7.2-stable, 공식 릴리스 페이지) | https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/renderer_canvas_render_rd.cpp · https://godotengine.org/releases/4.4/ |
| R-36 | 노드 비용. 공식 문서는 노드가 많아 문제가 되는 구간을 «from thousands to tens of thousands»로 적는다. Ezcha의 3D 실험은 12,800개 지점의 병목을 «mostly the `CollisionShape3D` nodes rather than the rendering»으로 적었다 | 문서·원문 확인(반박 표결 아님). Ezcha는 단일 사례(3D 실험, 게임 아님) | 1차(공식 문서 4.7) + 블로그 | https://github.com/godotengine/godot-docs/blob/4.7/tutorials/performance/cpu_optimization.rst · https://ezcha.net/news/5-16-26-rendering-a-million-objects-in-godot |
| R-37 | MultiMesh는 «a single draw primitive»라 인스턴스별 컬링이 없다. MultiMesh·MultiMeshInstance2D 레퍼런스에 인스턴스 정렬 기능이 없다(부재 확인). RD 렌더러는 MultiMesh 명령을 늘 단독 배치로 처리한다. MultiMeshInstance2D가 Sprite2D 여럿보다 빠를 수 있는 이유는 «large transparent areas»의 fill rate다 | 문서·소스 확인(반박 표결 아님) | 1차(공식 문서·레퍼런스·소스). 문서 페이지에 outdated 표시가 있고 예제는 3D뿐 | https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/MultiMesh.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/MultiMeshInstance2D.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/renderer_canvas_render_rd.cpp#L2742-L2746 |
| R-38 | RenderingServer. 4.2.1 포럼 측정에서 Sprite2D보다 256개에서 약 5%(2,000 대 2,100 FPS), 4,096개에서 약 8%(250 대 270 FPS) 빨랐다. 서버 캔버스 아이템은 «Once added, they can't be modified»이고 RID는 «allocated and freed manually». 3D 타워 디펜스 Elevation TD는 옮겨서 20~40 FPS를 되찾았지만, 메시가 «no errors in the error console» 상태로 사라지는 함정을 꼽았다 | 원문 확인(반박 표결 아님). 포럼·블로그는 각각 단일 출처 | 포럼 + 1차(공식 문서) + 블로그 | https://forum.godotengine.org/t/2d-rendering-performance/45719 · https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html · https://www.golden-tamarin.com/2024/10/08/godot-renderingserver/ |
| R-39 | AnimatedSprite2D는 재생 중인 노드마다 internal process를 돌리고, 프레임이 바뀌면 `frame_changed`를 낸다. `AtlasTexture`는 그리기를 원본 아틀라스에 위임한다 | 소스 확인(반박 표결 아님) | 1차(엔진 소스) | https://github.com/godotengine/godot/blob/4.7/scene/2d/animated_sprite_2d.cpp · https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/atlas_texture.cpp#L183 |
| R-40 | y 정렬 키는 각 캔버스 아이템 원점의 y(`ysort_xform.columns[2].y`)다. `is_equal_approx`로 같으면 수집 순서(트리 깊이 우선)로 정한다. 허용오차는 `CMP_EPSILON`(0.00001) × y의 절댓값이다. 4.4부터 physics interpolation과 픽셀 스냅(`(pos + 0.5).floor()`)을 적용한 뒤의 위치로 정렬한다 | 소스·PR 확인(반박 표결 아님) | 1차(엔진 소스 4.7.2·4.7, PR) | https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_canvas_cull.h#L117-L126 · https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_canvas_cull.cpp#L111-L165 · https://github.com/godotengine/godot/pull/93025 · https://github.com/godotengine/godot/blob/4.7/core/math/math_funcs.h |
| R-41 | 그리기 순서는 CanvasLayer > z_index > y다. «Nodes sort relative to each other only if they are on the same `z_index`.» 같은 layer 번호끼리의 앞뒤는 «non-deterministic». 엔진은 정렬된 목록을 순서대로 z 버킷에 붙인다. y 정렬 루트 자신도 로컬 y=0 항목으로 함께 정렬된다. y 정렬을 끈 자식의 자식은 그 자식의 y에 묶인다 | 문서·소스 확인(반박 표결 아님) | 1차(클래스 레퍼런스 4.7.2, 엔진 소스) | https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/CanvasItem.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/CanvasLayer.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_canvas_cull.cpp#L431-L461 |
| R-42 | TileMapLayer `y_sort_origin`은 «This allows, for example, to fake a different height level.» 성벽 위 유닛·벽 오르기·비행 표현의 공식 권장 패턴은 없다(부재 확인) | 문서 확인(반박 표결 아님) | 1차(클래스 레퍼런스 4.7.2) | https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/TileMapLayer.xml |
| R-43 | 열린 y 정렬 이슈 4건. #84086 y 정렬하지 않은 TileMap 레이어가 y 정렬 레이어 위에 그려진다. #99618 부모가 y 정렬이면 `show_behind_parent`가 동작하지 않는다. #97682 y 정렬을 켠 CanvasGroup에서 `self_modulate`가 동작하지 않는다. #89927 씬 컬렉션 타일이 레이어의 `y_sort_origin`을 무시한다 | 이슈 확인(상태는 2026-10-16 조회, 반박 표결 아님) | 공식 이슈 트래커 | https://github.com/godotengine/godot/issues/84086 · https://github.com/godotengine/godot/issues/99618 · https://github.com/godotengine/godot/issues/97682 · https://github.com/godotengine/godot/issues/89927 |
| R-44 | `_draw()` 쪽 문서 주의. 호출 순서대로 그려 «the latest shapes hiding earlier ones». 지역 변수로만 든 텍스처를 넘기지 말 것(«the drawing operation doesn't begin immediately»). `canvas_item_set_custom_rect()`는 «can reduce CPU load when drawing lots of 2D instances». 비트맵 글꼴은 카메라 줌에서 흐려지거나 깨지니 CanvasLayer에 두라고 안내한다 | 문서 확인(반박 표결 아님) | 1차(공식 문서·클래스 레퍼런스 4.7.2) | https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/CanvasItem.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/RenderingServer.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Camera2D.xml |
| R-45 | 픽셀아트 권장 설정은 «640×360 is a good baseline», stretch `viewport`, scale mode `integer`다. 4.7에서 새 프로젝트 기본값이 `canvas_items`로 바뀌었지만 «Existing projects are not affected». 정수 배율이면 Exclusive Fullscreen을 쓴다(일반 Fullscreen의 높이 1px 감소가 배율을 낮출 수 있다). 창이 기본 크기보다 작으면 잘리니 `Window.min_size`를 기본 크기로 둔다 | 문서·PR 확인(반박 표결 아님) | 1차(공식 문서, PR, 클래스 레퍼런스 4.7.2) | https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html · https://github.com/godotengine/godot/pull/118815 · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/ProjectSettings.xml |
| R-46 | 스냅 반올림의 변경과 줌에서의 해석. 4.3 PR #87297은 CanvasItem 위치만 반올림하도록 바꿨다. 4.4 PR #97260은 4.0~4.3 스냅이 «snapping to world space units instead of pixels», «as soon as you zoom or rotate it would break»였다며 캔버스 공간 반올림으로 고쳤다. 4.4 PR #93786은 뷰포트 반올림을 되살렸다. 4.7 소스를 읽은 다른 해석은 로컬 위치와 부모 누적 변환(카메라 포함)을 따로 반올림한다고 본다. 메인테이너 adamscott은 «there's a ceiling of what can be done» | PR·소스·토론 확인(반박 표결 아님). 줌에서의 동작은 해석이 갈린다 | 1차(PR, 엔진 소스) + 공식 저장소 토론 | https://github.com/godotengine/godot/pull/87297 · https://github.com/godotengine/godot/pull/97260 · https://github.com/godotengine/godot/pull/93786 · https://github.com/godotengine/godot/blob/4.7/servers/rendering/renderer_canvas_cull.cpp · https://github.com/godotengine/godot-proposals/discussions/9256 |
| R-47 | 스냅 관련 문서 경고. `snap_2d_transforms_to_pixel`과 `snap_2d_vertices_to_pixel`을 함께 쓰지 말 것(«movement may appear even less smooth», «Prefer only enabling this setting instead»). 두 설정 모두 Camera2D 스무딩과 쓰면 덜 부드럽다. Sprite2D `centered`는 «textures may appear deformed when centered». 일부 물체만 떨리는 원인은 «processed in different time sources» | 문서 확인(반박 표결 아님) | 1차(클래스 레퍼런스 4.7.2, 공식 문서 4.7) | https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/ProjectSettings.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Sprite2D.xml · https://github.com/godotengine/godot-docs/blob/4.7/tutorials/rendering/jitter_stutter.rst |
| R-48 | 열린 픽셀 이슈 2건. #71074 스냅이 카메라 스무딩 지터는 고치지만 «introduces sprite jittering». #116838 4.5 dev 5부터의 회귀로, 맵 X가 1,500px을 넘는 끝에서 화면이 흔들린다. 원인으로 Camera2D 오른쪽·아래 limit 수정(PR #105825)이 지목됐다 | 이슈 확인(상태는 2026-10-16 조회, 반박 표결 아님) | 공식 이슈 트래커 | https://github.com/godotengine/godot/issues/71074 · https://github.com/godotengine/godot/issues/116838 · https://github.com/godotengine/godot/pull/105825 |
| R-49 | 측정 API. `viewport_get_measured_render_time_cpu()`는 렌더 관련 작업만 재고 스크립트 `_process`는 넣지 않는다. GPU 사용률이 낮으면 전원 상태가 내려가 GPU 시간이 늘 수 있다. `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`은 «doesn't include culled objects». 실제 렌더러는 폴백으로 바뀔 수 있어 `get_current_rendering_method()`로 확인한다 | 문서 확인(반박 표결 아님) | 1차(클래스 레퍼런스 4.7.2) | https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Performance.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/RenderingServer.xml · https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/ProjectSettings.xml |
| R-50 | Kingdom Rush(팬이 추출한 KR5 데이터)는 방향을 좌우(반전)·아래·위 3세트로 둔다. hog_invader는 걷기 20·공격 24·사망 19, spiderling은 걷기 9·공격 15·사망 12프레임 | 원문 확인(반박 표결 아님) | 팬추출(비공식, 신뢰도 중하) | https://github.com/zidonghua2018/KingdomRushFL/blob/master/kr3/data/animations/hog_invader.lua · https://github.com/zidonghua2018/KingdomRushFL/blob/master/kr3/data/animations/spiderling.lua |
| R-51 | Dead Cells. «we still haven't found any solution for flickering pixels». 공격은 «essentially pose-to-pose animations»이고 움직임 느낌은 VFX에 맡겼다 | 원문 확인(반박 표결 아님) | 1차(아트 디렉터 글, R-04와 같은 글) | https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i- |
| R-52 | Factorio 바이터. 달리기 16·공격 11·사망 17·부패 24프레임을 16방향 모두 반전 없이 렌더한다. 2018 개편 때 달리기 루프를 이동 속도에 맞춰 «so they shouldn't slide around» 했다 | 원문 확인(반박 표결 아님) | 공식 데이터(factorio-data, 2026-10-16 조회) + 1차(공식 블로그 FFF-268) | https://github.com/wube/factorio-data/blob/master/base/prototypes/entity/biter-animations.lua · https://factorio.com/blog/post/fff-268 |
| R-53 | 좌우 반전 저장. StarCraft 1은 32방향 가운데 17방향만 그림이 있고 나머지는 `flag_horizontally_flipped`로 뒤집는다. Age of Empires 1·2는 «each animation has 10 keyframes and 5 directions»이고 나머지 3방향은 뒤집어 만든다 | 원문 확인(반박 표결 아님) | 재구현(OpenBW 소스, openage 문서). 개발사 자료가 아니다 | https://github.com/OpenBW/openbw/blob/master/bwgame.h · https://github.com/SFTtech/openage/blob/master/doc/media/slp-files.md |
| R-54 | StarCraft 1의 죽음 프레임은 회전하지 않는다(«do not rotate») | 원문 확인(반박 표결 아님). 단일 출처 | 커뮤니티 문서(GRP 모딩 튜토리얼 재게시, 원저자 미상), 신뢰도 중하 | https://m.cafe.daum.net/rpgguild/KCa/186 |
| R-55 | 반전의 이유와 대가. NES 젤다의 오른쪽 그림은 왼쪽 그림의 반전이고, 따로 만들지 않은 이유는 «memory was a highly limited resource». Tiny Swords 개발자는 반전하면 검·방패를 든 손이 바뀐다는 지적에 «it will add a lot of extra work since I'll need to reanimate not just the Idle, but all animations as well»이라고 답했다 | 원문 확인(반박 표결 아님). 둘 다 단일 출처 | 2차(팬 사이트 기사) + 포럼(itch.io 토론) | https://zeldauniverse.net/features/is-it-right-that-links-not-left-handed-in-breath-of-the-wild/ · https://itch.io/t/5057594/how-about-adding-left-facing-animations-for-units |
| R-56 | Nuclear Throne 피격 수치. 피격 애니메이션은 흰 프레임 1장 + 눈 커진 프레임 2장(30fps). 넉백은 프레임당 3px(320×240). 맞힐 때마다 10~20ms 정지. 한 발에 흔들림 +4 | 원문 확인(반박 표결 아님). 단일 출처 수치 | 2차(2013 RPS 인터뷰를 블로그가 옮김, 원 인터뷰는 열지 못함) | https://infovore.org/?p=5275 |
| R-57 | Celeste 공개 소스. 점프 늘어남 (0.6, 1.4). 정지(`Celeste.Freeze`)는 대시 0.05초, 폭발 0.1초, 결정 파괴 0.01초 | 소스 확인(반박 표결 아님) | 1차(개발자가 공개한 Player 클래스) | https://raw.githubusercontent.com/NoelFB/Celeste/master/Source/Player/Player.cs |
| R-58 | 화면 흔들림과 감속 정지. Eiserloh 강연을 따른 Bevy 예제는 trauma²와 1D Perlin 노이즈로 흔든다. Juicy Breakout 데모는 정지 0~320ms와 정지 중 속도 배율 0~1을 둔다 | 원문·소스 확인(반박 표결 아님). Eiserloh 강연 원문은 미확인 | 엔진 예제(강연 원문 아님) + 공개 소스(데모) | https://bevy.org/examples/camera/2d-screen-shake/ · https://raw.githubusercontent.com/grapefrukt/juicy-breakout/master/src/com/grapefrukt/games/juicy/Settings.as |
| R-59 | Sakurai의 히트스톱. 때린 쪽과 맞은 쪽이 «freeze for the exact same amount of time». 맞은 쪽은 정지 중 진동한다(지상에서는 좌우). 무리를 베는 Dynasty Warriors는 히트스톱을 거의 쓰지 않는다. 칠 때마다 멈추면 «reducing the overall game speed»이고, 오래 멈춘 둘은 «a chance for a third player to move in and strike»를 준다 | 원문 확인(반박 표결 아님) | 번역(Famitsu 칼럼 490~491회의 팬 번역) | https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ |
| R-60 | 연출 세기는 중요도에 맞춘다. Riot은 «the amount of attention an ability grabs should match its level of importance»(MOBA 맥락). Kao 외(2020)는 같은 액션 RPG를 연출 없음·중간·높음·극단으로 만들어 비교했고, 중간·높음이 없음·극단보다 나았다 | Riot은 원문 확인. Kao는 설문 논문의 요약으로만 확인(원 논문·표본 수 미확인). 반박 표결 아님 | 1차(Riot 개발 블로그) + 학술(설문 논문 안의 요약) | https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/ · https://arxiv.org/pdf/2011.09201 |
| R-61 | Folmer Kelly(«Don't Juice It or Lose It»)는 도트·제한 팔레트 게임에 그라데이션과 동적 조명을 얹는 것을 해로운 연출의 예로 들었다 | 요약 확인(반박 표결 아님). 강연 원문 미확인 | 2차(블로그 요약) | https://rpgplayground.com/research-making-a-juicy-game/ |
| R-62 | Lin 외(2022). Steam 상위 액션 게임 리뷰 분석에서 hit stop, 소리 일관성, 카메라 제어가 타격감에 크게 영향을 줄 수 있다고 했다 | 원문 확인(반박 표결 아님) | 학술(관찰 연구, 수치 조건 실험 아님) | https://arxiv.org/abs/2208.06155 |

표결 메모:
- **R-01:** 원래 주장은 "처음 렌더한 골리앗이 납작해 보였다"였다. 원문은 "가늘게 뭉개졌다"는 뜻이라 고쳤다.
- **R-06:** 2-1 반대표는 '정수배' 표현의 뉘앙스에 관한 것이었다.
- **R-08:** '다크 판타지' 표현이 출처를 넘어서 2-1이 됐다. 본문에서는 그 표현을 뺐다.
- **R-10:** '도트' 조건에 맞지 않아 2-1이 됐다.
- **R-13:** 포럼의 38도는 측정자가 철회했고, 53도는 출처가 없어 쓰지 않았다.
- **R-16:** ORDERED를 넘기면 FS로 동작한다는 부분은 소스를 읽은 추론이다. 검증자가 실행해 확인한 것은 최근접 일치율 97.1%(무작위 16색 팔레트, 4096색)다.
- **R-18:** 색조 분포(따뜻한 색 19, 초록 2, 청록 3, 파랑·보라 0, 채도 최솟값 0.27)는 2026-10-14에 colorsys로 다시 계산해 일치를 확인했다.
- **R-24:** Sam Didier의 말을 Karune이 공식 포럼에 옮긴 것을 다시 전한 기사다. Battle.net 원문은 찾지 못했다.
- **R-27~R-29:** 처음에는 단일 검색으로 더했다. 3차에서 디컴파일 소스 두 벌로 다시 확인했다. `josh-m/RW-Decompile`은 마지막 커밋이 «1.0 Decompile»이다. `IlyaChichkov/RimworldDecompiled`는 버전 표기가 없지만 Odyssey의 Gravship 파일이 있어 1.6판으로 추정한다. 1.7판은 확인하지 않았다. 그래서 표결 칸을 3표 결과처럼 채우지 않고 성격을 따로 적었다.
- **R-27:** 범위를 좁혔다. 1.6판에 Anomaly 키프레임 동작과 비행 동물 프레임이 있어 «애니메이션이 전혀 없다»는 틀리다. 불만 문장의 근거는 Steam 토론 한 곳뿐이라 반응 자료 R-32를 곁에 둔다.
- **R-28:** 방향은 확인했고 해상도를 고쳤다. 위키가 바닐라 원본을 64 ppt로 적었는데 처음 요약에서 빠졌다. 64·128 ppt의 근거는 위키 한 곳(작성 중 표시)뿐이다.
- **R-29:** 확인했고 진행 표시(1/4칸)를 더했다. 처음 근거였던 모드 변경 기록(https://steamcommunity.com/sharedfiles/filedetails/changelog/1372003680)은 코드로 대신했다.
- **R-30·R-31:** 틱 값을 초로 옮길 때 쓴 «1배속 = 초당 60틱»은 확인하지 않았다. 05·06은 틱 하나를 60fps의 프레임 하나로 옮겼다.
- **R-32:** 구독은 실사용이 아니다. Harmony 대비 약 20%는 대략적인 추정이다.
- **R-33:** 140개 환산(약 0.01ms)은 선형 가정이다. 결과 파일에 렌더러 표기가 없다.
- **R-38:** 포럼 측정은 4.2.1 C#(배칭 도입 전)이고 하드웨어·렌더러가 적혀 있지 않다. Elevation TD 글에는 전후 FPS와 하드웨어가 없다.
- **R-46:** 줌 2×·3×에서 스냅이 맞추는 단위는 PR #97260의 서술과 4.7 소스 해석이 갈린다. 4.1a 스파이크 X1로 판정한다([05](05_godot_rendering.md)).
- **R-50:** 저장소 경로는 kr3이지만 파일 머리의 `chunkname: @./kr5/...` 표기로 KR5 데이터로 본다.
- **R-60:** Kao 외(2020)는 설문 논문(arXiv 2011.09201) 안의 요약으로만 봤다.

## 2. 가져왔지만 검증된 주장이 없는 출처

| URL | 성격 | 갈래 |
|---|---|---|
| https://en.wikipedia.org/wiki/Pre-rendering | 2차 | a |
| https://steamcommunity.com/app/625960/discussions/0/4298195716594538602 | 포럼 | b |
| https://www.pcgamesn.com/thronefall/steam-full-launch | 2차 | c |
| https://en.wikipedia.org/wiki/Stronghold_(series) | 2차 | c |
| https://forums.factorio.com/viewtopic.php?p=473901 | 포럼 | d |
| https://warcraft.wiki.gg/wiki/Warcraft_2 | 2차 | d |
| https://godotshaders.com/shader/3d-pixel-art-outline-highlight-post-processing-shader/ | 블로그 | e |
| https://forum.godotengine.org/t/how-to-y-sort-player-with-3-4-view-tilemaplayer/83392 | 포럼 | 2차 주제 1 |
| https://opengameart.org/node/20643 | 포럼 | 2차 주제 2 |
| https://alexandertanasie.artstation.com/projects/w6qVqL | 블로그 | 2차 주제 3 |
| https://gamedeveloper.com/game-platforms/road-to-the-igf-subset-games-i-into-the-breach-i- | 1차(인터뷰) | 2차 주제 3 |
| https://www.chapterbrief.net/blog/tyrant-of-the-tower-defense-game-review | 블로그(웹툰 리뷰, 2026-08-31) | 2차 웹툰 |
| https://www.inews24.com/view/1993322 | 2차(게임화 기사, 2026-08-10) | 2차 웹툰 |

### 원작 웹툰 — 뽑았지만 검증하지 못한 주장 (미검증, 인용 금지)

아래는 2차 조사에서 출처를 읽고 뽑은 주장이다. 검증 예산(9개 제외)에 밀려 반박 검증을 거치지 않았다. 사실로 인용하지 않고, 사용자가 대표 컷을 고르거나 재조사할 때 단서로만 쓴다.

- ChapterBrief(무료 1~3화만 본 리뷰): 작화는 «clean, full-color digital linework with a strong sense of lighting». 1화 축하 장면은 모니터 빛 하나로 «blue-white wash». 분위기는 «slower and heavier». 다크 판타지라고 부르지는 않는다. 표지 alt 텍스트는 «besieged castle» 앞의 «gold-trimmed red military coat». 성벽 공방 장면 묘사는 없다.
- 아이뉴스24: 웹젠이 같은 원작의 공식 게임 «프로젝트D1»을 만든다. 원작 속 게임 세계가 도트 그래픽이라는 설정을 살려 «3D그래픽 배경에 도트그래픽 더한 '디오라마 픽셀아트'»를 쓴다. 장르는 «지휘 전략 RPG»다. 색감·시점 서술은 없다.
- 검색 결과 요약에만 나온 것(본문 미확인): 웹툰가이드 후속 기사(2026-09-02)가 정식 명칭을 «라스트 스테이지»로, 그래픽을 «언리얼엔진5 기반 3D 입체 그래픽 배경 위에 픽셀 단위의 도트 그래픽 캐릭터»로 보도했다. 나무위키·커뮤니티는 원작 정서를 «무너지는 것이 전제인 괴수 전선», «다크한 배경»으로 적었다.

## 3. 기각된 주장

| 표결 | 주장 | 출처 |
|---|---|---|
| 0-3 | Rise to Ruins의 방어 구조는 미로 벽 뒤에 타워를 줄지어 세운 '타워의 벽'이다 | https://store.steampowered.com/app/328080/Rise_to_Ruins |
| 1-2 | Never's End(Hypersect)는 실시간 3D 렌더에 도트 후처리를 더해 손 도트처럼 보이게 한다(GDC 2026 슬라이드) | https://www.ryanjuckett.com/how-we-draw-a-3d-sprite-world-gdc2026/ |
| 0-3 | (2차) Gage의 Three Reads는 정보를 세 층(직관적 정보 / 직관적이지 않지만 중요한 정보 / 나머지 세부)으로 나눈다. 적·아군 화면이면 1층 피아·적 종류, 2층 선택 유닛·건물 상태, 3층 버프 수치로 옮긴다 | https://gigazine.net/gsc_news/en/20180501-game-design-subway-legibility |
| 1-2 | (2차) Slynyrd 램프 안 규칙: 명도는 0에서 시작하지 않고 계속 오른다. 채도는 가운데가 가장 높고 0·100에 닿지 않는다. 채도와 명도를 함께 높게 잡는 것이 가장 큰 실수다 | https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes |

## 4. 미해결 질문

1. 스타크래프트 1과 Factorio의 실제 카메라 고도각과 타일 픽셀 크기는 얼마인가? Factorio는 정사각 격자를 비스듬히 내려다보는 시점이라 갈래 d에 가장 가까울 수 있다. 하지만 이번 출처에는 그 내용이 없다.
2. 정사각 격자 3/4 탑다운 시점의 다크 판타지 도트 게임은 무엇인가? 특히 몬스터가 성벽을 기어오르는 장면이나 비행 몬스터가 있는 작품은?
3. 16~32px에서 3D를 직접 래스터화하고 제한 팔레트로 양자화하면 손 보정 없이 형태가 읽히는가? 외곽선은 검정이 나은가, 컬러가 나은가?
4. 디아블로 1과, 3D를 도트로 렌더하는 다른 현대 인디 사례는 무엇인가?
5. (2차) 원작 웹툰의 성벽 공방 장면은 어떤 색감인가? 주조색, 밤·낮 장면 비율, 피·불빛 강조 정도가 없다. 사용자가 고른 대표 컷이나 재조사로 팔레트 판정 기준을 세워야 한다.
6. (2차) 정사각 격자 비스듬한 시점의 2D 게임은 성벽 위 유닛, 기어오르는 적, 성벽을 넘는 비행 적을 어떻게 그렸나? 건설 중·깎임·잔해·성문 개폐·버프 표시는 작은 화면에서 어떻게 읽히게 했나?
7. (2차) Godot 4.7에서 성벽 앞·위·뒤 유닛과 비행 유닛의 그리기 순서를 y_sort_enabled·z_index·TileMapLayer로 어떻게 나누나? 공식 문서로 확인해야 한다. → 2026-10-16: [05](05_godot_rendering.md)에서 답했다(R-40~R-42). 공식 권장 패턴이 없어 바닥선 정렬 규칙을 세웠다.
8. (2차) 16~32px 렌더 스프라이트에서 디더링 없음과 Bayer, 8방향과 16방향, 45도와 60도 중 무엇이 나은가? 외부 근거가 없어 10/21 시험에서 나란히 렌더해 판정한다.
9. (3차) 4방향과 8방향의 가독성을 비교한 연구나 사후 분석이 있나? 16px에서 45° 차이가 읽히나? 찾지 못했다. 4.0 시험의 M5로 직접 잰다([06](06_unit_expression.md)).
10. (3차) RTS·타워 디펜스는 군중 화면에서 히트스톱과 피격 번쩍임을 어떻게 쓰나? 1차 자료를 찾지 못했다.
11. (3차) 줌 2×·3×에서 Godot 4.7.2 스냅은 아트 픽셀과 뷰포트 픽셀 중 무엇에 맞춰 반올림하나? 해석이 갈린다(R-46). 4.1a 스파이크의 X1 캡처로 판정한다([05](05_godot_rendering.md)).
12. (3차) They Are Billions·Prison Architect·Bad North·Thronefall·Diplomacy is Not an Option은 유닛을 어떤 방식으로 움직이고, 방향·프레임을 몇 개 두나? 출처로 확인하지 못했다.
