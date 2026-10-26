# 99. 만든 방법·확인 못 한 것·출처

## 만든 방법

- 2026-10-26, 조사 갈래 셋을 나란히 돌렸다. 갈래마다 웹 검색 상한은 25회였다.
  - 중세 마을·소도시 길 모양: 검색 24회. 결과는 [evidence/history_village_town.md](evidence/history_village_town.md).
  - 성 안뜰·성곽 도시 길: 검색 17회. 평면도 9장을 직접 봤고(Gaillard·Conwy·Krak·Windsor·Eguisheim·Biertan·Nördlingen 1823·Bram 항공사진·Bram OSM), Bram은 OSM 길을 내려받아 반지름 히스토그램을 냈다. 결과는 [evidence/fortified_castle_town.md](evidence/fortified_castle_town.md).
  - 게임·절차 생성기: 검색 19회. Watabou 공개 소스 5개를 읽었다. 스크린샷은 Steam 섬네일 시트 14장(약 190컷)을 훑고 11장을 원본으로 봤다. ALttP 카카리코와 꿈꾸는 섬 마베 마을은 칸 단위로 픽셀을 셌다. 결과는 [evidence/games_generators.md](evidence/games_generators.md).
- 조사 도중 사용자가 «거점을 더 위로»를 물어 세 갈래 모두에 거점 위치 절을 더했다.
- 사용자가 붙인 조감도([03](03_reference_image.md))는 Claude가 보고 적었다. 저장소에 넣지 않았다.
- 우리 게임 사실은 `SPEC.md`(S37·S43·S169·S202·S203·S215·S216·S217), `src/main.gd:191`, `src/ui/battle_view.gd`, 캡처 `art/trial/preview/thick_castle/overview.png`에서 읽었다. Godot은 띄우지 않았다.
- [04](04_layout_plans.md)의 칸 스케치는 일회성 스크립트(scratchpad `sketch.py`)로 찍었다. 저장소에 넣지 않았다.
- 내려받은 이미지는 저장소 밖 scratchpad의 `plans\`·`shots_roads\`에 있다.

## 칸 환산

- 노트 둘의 가정이 다르다. 마을·소도시 노트는 **1칸 ≈ 2.5~3 m**로 잡았다(집 2×2칸 앞면 = 필지 앞면 하한 5~6 m). 성곽 노트는 **1칸 ≈ 4 m**로 잡았다(bastide 필지 앞폭 8 m = 2칸). 본문([01](01_medieval_grammar.md))은 둘을 합쳐 2.5~4 m 범위로 적었다.
- 어느 쪽이든 권장값(큰길 2~3칸, 골목 1칸, 시장 10~13칸)은 픽셀아트 사례의 «길 폭 = 건물 폭의 0.25~0.5배»와 겹친다.

## 바로잡은 것

- 조사 지시에 지금 광장 띠를 «폭 약 8칸»으로 적었다. 실제는 반폭 52px, 폭 약 6.5칸(104px)이다(`src/ui/battle_view.gd:1265`). evidence 노트 셋에는 «8칸»이 남아 있고, 본문(01~05)은 6.5칸으로 고쳤다. 결론(«길로는 넓고 광장으로는 좁고 길다»)은 같다.

## 확인 못 한 것

- 성이 성곽 도시 «가장자리»였던 비율의 통계는 없다. 결론은 사례 모음에서 나온 판단이다. 후보 문헌은 Creighton & Higham(2005) 『Medieval Town Walls』, Drage(1987) «Urban Castles»다.
- 게임에서 건물이 길 위에 놓일 때의 처리(길 삭제·건설 금지·밑으로 숨김)를 밝힌 1차 출처는 없다. [04](04_layout_plans.md) 3장 표는 해석이다.
- Manor Lords의 «필지가 길에 닿아야 하나», «집이 길 쪽으로 저절로 도나»는 공식 문장으로 확인하지 못했다(위키 401·403).
- Historic England «Medieval Settlements» IHA 원문은 403이라 HER 인용문으로만 봤다.
- Beresford 계획 도시 수, Boerefijn 논문 본문, 알베르티 원문은 검색 요약이나 초록으로만 봤다.
- 대장간이 문 가까이 있었다는 일반 근거는 찾지 못했다.
- 45° 내려다보기에서 남북 길과 동서 길이 다르게 보이는 문제는 다루지 않았다.
- 시장·길 폭으로 «마을로 읽힘»을 잰 연구는 없다. 확인 수단은 시안뿐이다.

## 핵심 출처

전체 URL은 evidence 노트에 있다. 결론을 떠받치는 것만 모았다.

**역사 — 골격·필지·시장**
- Historic England, Medieval Settlements IHA(HER 인용): https://her.northamptonshire.gov.uk/Designation/DNN19604
- Stratford-upon-Avon Bridge Street(필지 치수, Middle Row): https://www.stratfordsociety.co.uk/files/History_of_Bridge_Street.pdf
- 에드워드 1세 도시 설계 분석(Lilley 외, ADS) — Conwy·Caernarfon·Flint·Beaumaris·Rhuddlan·Winchelsea: https://archaeologydataservice.ac.uk/catalogue/adsdata/arch-433-1/dissemination/pdf/discussion/conwy/conwy_design_plan.pdf (같은 폴더의 다른 도시 PDF)
- bastide(길 폭·광장·필지): https://fr.wikipedia.org/wiki/Bastide_(ville) , https://en.wikipedia.org/wiki/Bastide
- Villingen 길 그물(길 등급·포장·계획): https://regionalia.blb-karlsruhe.de/files/16496/BLB_Maulhardt_Villinger_Strassennetz.pdf
- Boerefijn 2003(곧은 길 선호): https://bulletin.knob.nl/index.php/knob/article/view/558

**역사 — 성·성벽**
- Chester(Cross, 성벽 길, 모서리 정원): https://www.british-history.ac.uk/vch/ches/vol5/pt1/pp209-220
- Cricklade·Winchester 성벽 길(burh): https://intarch.ac.uk/journal/issue14/1/period1.htm
- Newcastle 성벽 안쪽 공간(1330): https://www.twsitelines.info/SMR/1568
- Villingen 성벽(Rondenweg): https://regionalia.blb-karlsruhe.de/files/16774/BLB_Jenisch_Stadtmauer_Villingen.pdf
- Stadtburg: https://de.wikipedia.org/wiki/Stadtburg , Urban castle: https://en.wikipedia.org/wiki/Urban_castle
- Bent entrance: https://en.wikipedia.org/wiki/Bent_entrance
- Circulade와 비판: https://fr.wikipedia.org/wiki/Circulade , Catafau 2016: https://aapo-66.com/wp-content/uploads/2025/06/A-CATAFAU-territori-i-societat-village-ecclesial-2016-1.pdf
- Conwy 평면도: https://commons.wikimedia.org/wiki/File:Conwy_town_wall_plan.jpg

**게임·생성기**
- Watabou TownGeneratorOS 소스: https://github.com/watabou/TownGeneratorOS
- Parish & Müller 2001: https://cgl.ethz.ch/Downloads/Publications/Papers/2001/p_Par01.pdf
- Manor Lords 공식 소개(Steam appdetails 1363080)
- ALttP 카카리코 맵: https://www.vgmaps.com/Atlas/SuperNES/LegendOfZelda-ALinkToThePast-LightWorld-KakarikoVillage.png
- Thronefall 스크린샷: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg
- Stronghold 배치 관행(플레이어 토론): https://steamcommunity.com/app/2140020/discussions/0/6450905019305158854
