# 게임과 절차 생성기의 중세 마을 길 배치 — 생성 규칙, 건설 게임, 픽셀아트 길 폭, 방어 게임, 자유 건설, 거점 위치

표기
- 출처 URL만 적은 것: 원문을 직접 열어 확인함.
- «(검색 요약)»: 검색 결과 요약만 봄. 원문 미확인.
- «(스크린샷 직접 봄: URL)»: 이미지를 내려받아 직접 봄. «섬네일 시트»는 4열 축소 모음으로만 본 것.
- «(픽셀 셈)»: 원본 맵을 16px 칸 단위로 색을 세어 잰 것. «(눈대중)»: 화면 좌표로 어림한 것.
- «(미확인)»: 확인 못 함. «(해석)»: 내 판단.
- 조사일 2026-10-26. 우리 맵 기준: 마을 60×27칸(0~26행), 성벽 27~29행, 정문은 남쪽 가운데 하나, 거점 (30,13).
- 이미 조사한 내용(닳는 길, 16px 경계, 바닥 깔기, 진격로 오독)은 `village_research/evidence/paths_ground.md`를 본다. 여기선 다시 쓰지 않는다.

## 1. 절차 생성기가 쓰는 규칙 — Watabou와 논문

### Takeaway
Watabou 도시 생성기는 «가운데 광장 → 문마다 큰길 하나 → 길 사이 블록을 필지로 쪼갬» 순서로 만든다. 큰길은 광장 모서리까지 가고 성채로는 가지 않는다. 길 폭은 큰길 2 : 보통 길 1 : 골목 0.6이고, 성벽 안쪽 가장자리도 큰길 폭으로 비운다. Parish & Müller(2001)는 «길에 직접 닿지 않는 필지는 버린다»와 «막다른 길은 예외»를 규칙으로 둔다.

### Cited Findings
- Watabou 생성 순서는 buildPatches → optimizeJunctions → buildWalls → buildStreets → createWards → buildGeometry다. 구역은 나선형으로 뿌린 점의 보로노이 셀이다. https://raw.githubusercontent.com/watabou/TownGeneratorOS/master/Source/com/watabou/towngenerator/building/Model.hx
- 광장: 원점에 가장 가까운 셀(0번)을 광장으로 쓰고 시장(Market)을 놓는다. 같은 출처.
- 성채(citadel): 도시 셀 바로 바깥 첫 셀(nPatches번)을 성채로 잡아 도시에 넣는다. 모양이 둥글지 않으면(compactness < 0.75) 도시 전체를 다시 만든다. 같은 출처.
- 큰길: 문마다 «광장의 가장 가까운 모서리»(광장이 없으면 중심)까지 A* 길을 낸다. 문 밖으로는 문 방향 먼 점에서 문까지 «도로(road)»를 낸다. 길들을 마디로 쪼개 겹침을 없애고 간선(artery)으로 이은 뒤, 꼭짓점을 다듬는다(smoothVertexEq(3)). 광장 안 마디는 길에서 뺀다. 같은 출처.
- 길찾기 그래프: 셀 경계선만 길이 될 수 있다. 성채와 성벽 꼭짓점은 막고(blocked), 문만 뚫는다. 비용은 경계선 길이다. https://raw.githubusercontent.com/watabou/TownGeneratorOS/master/Source/com/watabou/towngenerator/building/Topology.hx
- 문 고르기: 안쪽 구역 둘 이상이 만나는 성벽 꼭짓점만 후보다. 성채 쪽(reserved) 꼭짓점은 빠진다. 문 하나를 고르면 이웃 꼭짓점을 후보에서 지워 문끼리 붙지 않게 한다. 문 수는 정해져 있지 않다. 문이 아닌 성벽 꼭짓점에는 모두 탑을 세운다. https://raw.githubusercontent.com/watabou/TownGeneratorOS/master/Source/com/watabou/towngenerator/building/CurtainWall.hx
- 성채 자체 성벽: 도시 바깥과 닿은 꼭짓점을 reserved로 넘긴다. 건물은 셀을 큰길 폭의 2배(4.0)만큼 안으로 줄인 자리에 하나 세운다. https://raw.githubusercontent.com/watabou/TownGeneratorOS/master/Source/com/watabou/towngenerator/wards/Castle.hx
- 길 폭 상수: MAIN_STREET 2.0, REGULAR_STREET 1.0, ALLEY 0.6. 블록은 맞닿은 길 폭의 절반만큼 안으로 줄인다. 성벽에 닿은 변과 광장·간선에 닿은 변은 큰길 폭으로 줄인다. 나머지 변은 성 안이면 보통 길, 성 밖이면 골목 폭이다. https://raw.githubusercontent.com/watabou/TownGeneratorOS/master/Source/com/watabou/towngenerator/wards/Ward.hx
- 필지: 블록을 가장 긴 변 기준으로 재귀 이분한다. 자르는 위치·각도의 흔들림은 gridChaos, 크기 흔들림은 sizeChaos가 정한다. 큰 덩이를 자를 때만 골목 폭을 비운다. 다 쪼갠 필지의 4%(emptyProb 0.04)는 빈터로 남긴다. 같은 출처.
- 문 구역: 성벽이 있으면 문에 닿은 구역이 50% 확률로 문 구역(GateWard)이 된다. 성 밖 문 앞에도 문 구역이 붙는다. Model.hx(위 URL).
- 2020년 갱신으로 «성을 성벽에 붙일지, 마을 가운데 둘지» 고를 수 있게 됐다. https://forum.profantasy.com/discussion/comment/91909
- Village Generator는 «Parish-Müller 방식(또는 그 후속)»을 쓴다고 밝힌다. 길 폭(Wide/Narrow)과 진입로(driveway) 표시 옵션이 있다. 댓글에 «집 대부분이 길에 수직»이라는 지적이 있다. https://watabou.itch.io/village-generator
- Village Generator 1.6.4판부터 간선 교차로(십자·T자)에 선 마을을 요청할 수 있다. https://watabou.itch.io/village-generator/devlog/840277/164-crossroads-and-numbered-houses
- Parish & Müller 2001: 간선(highway)은 인구 중심을 잇고, 일반 길(street)은 간선 사이를 채워 모든 동네가 가까운 간선에 닿게 한다. 패턴 규칙은 격자(뉴욕), 방사(파리), 등고선(샌프란시스코) 셋이다. 새 마디 끝이 기존 길 반경 안이면 교차로로 붙인다. «교통망에서 막다른 길은 예외이고, 대부분 길은 다른 길과 만나거나 제자리로 돌아와 끝난다». 필지는 볼록한 직사각형으로 쪼개고, 너무 작거나 길에 직접 닿지 않는 필지는 버린다. https://cgl.ethz.ch/Downloads/Publications/Papers/2001/p_Par01.pdf
- Emilien 외 2012(마을 생성): 관심도 지도로 정착 씨앗과 그걸 잇는 길을 반복해서 놓는다. 새 길은 정착민을 끌고, 새 집은 길망을 늘린다. 그 다음 필지를 나누고 경사에 맞춰 집을 짓는다. 산골 촌락·어촌을 실제 자료와 비교했다. https://researchportal.ip-paris.fr/en/publications/procedural-generation-of-villages-on-arbitrary-terrains/ (초록만)
- Groenewegen 외 2009: 도시 크기·위치·역사 배경을 입력받아 토지이용 모델의 제약에 따라 구역(상업·공업·주거 등급)을 놓는다. (검색 요약)
- 실제 중세 도시 브리스톨: 네 큰길이 높은 십자가가 선 시장으로 모인다. 성은 동문 옆에 있었다. 계획 도시(planted town)는 격자가 흔하다. 큰길 한 구간을 넓혀 시장으로 쓰기도 한다. 능선·강가는 선형 마을이 된다. https://the-orb.arlima.net/encyclop/culture/towns/townint5.html

### Inferences
(해석) 손으로 한 번 그릴 골격에 쓸 규칙 목록. 칸 단위로 옮겼다.
1. 광장은 마을 가운데쯤 한 곳이다. 정문 큰길은 광장 «모서리»에 닿고 광장을 꿰뚫지 않는다.
2. 큰길은 문 하나당 하나, 문에서 광장까지다. 셀 경계를 따라 찾은 길이라 자로 그은 직선이 아니다. 한두 번 꺾이고 꺾인 데를 둥글린 선이다. 우리 맵에선 정문(30,27)에서 광장까지를 완만한 S자나 한 번 꺾임으로 그린다.
3. 성 밖 들판 길은 문을 지나 같은 방향으로 이어진다. 성 안 큰길과 성 밖 도로는 문에서 한 줄로 만난다.
4. 폭 위계는 2 : 1 : 0.6이다. 16px 칸에서 0.6칸은 못 그리므로 큰길 2칸, 보통 길 1칸, 골목은 1칸이되 재질을 흙으로 낮춘다.
5. 성벽 안쪽 띠는 큰길 폭으로 비운다. 지금 박석 1줄을 2칸으로 넓힐 근거다. 이 길은 문과 탑을 모두 잇는 순환로다.
6. 길 사이 블록 깊이는 건물이 등을 맞댈 수 있게 잡는다. 우리 건물 깊이 2칸에 마당 1칸이면 블록 깊이 5~6칸이다.
7. 막다른 길을 만들지 않는다. 길은 교차로·광장·문·건물 문 앞에서 끝난다.
8. 성채(거점)는 길이 지나가지 못하는 땅이다. 큰길은 광장까지만 가고, 성채는 광장에서 짧은 길로 들어간다. 성채 문은 마을 쪽만 본다. 성채 둘레에는 빈 띠를 둔다.
9. 필지를 다 채우지 않는다(빈터 4%). 우리 마을은 플레이어가 지으므로 이건 저절로 성립한다.
10. 문 가까운 곳은 문 구역이다. 여관·마구간·작업장처럼 길손을 상대하는 건물이 문 안팎에 붙는 그림이 맞다.

### Gaps
- Watabou의 설계 설명 글(블로그·Reddit)은 못 열었다. Reddit은 도구에서 막혔다. 규칙은 공개 소스(옛 판)에서만 읽었다. README는 «물·옵션 UI 등 최신 기능이 빠졌다»고 적는다. https://github.com/watabou/TownGeneratorOS
- Village Generator의 길 생성 세부는 «Parish-Müller 방식» 한 줄뿐이다(미확인).
- Emilien 2012, Groenewegen 2009 본문은 서버 접속 실패로 못 읽었다.

## 2. 중세 마을 건설 게임 — 길이 마을 모양을 만드는 방식

### Takeaway
중세 건설 게임은 두 갈래다. Manor Lords·Kingdoms and Castles는 «길이 먼저, 집은 길을 따라»다. Banished·Ostriv·Against the Storm은 «집은 아무 데나, 길은 속도 보너스이거나 다니면 생긴다»다. 중세답게 읽히는 화면의 공통점은 휜 흙길, 길에 박공을 댄 집과 그 뒤로 긴 텃밭, Y자 갈림 사이의 작은 풀밭, 가장자리에 선 교회다.

### Cited Findings
- Manor Lords 공식 소개: 건설 규칙은 «주요 교역로와 지형이 정착지 모양을 만든» 실제 중세 마을의 성장에서 따왔다. 가운데 시장에서 바깥으로, 주거·상업·공업 구역을 «땅의 생김새를 따라» 넓힌다. 주거 구역을 정하면 주민이 «역사적 버지지 필지(burgage plot) 제도»에 따라 집을 짓는다. «각 구역은 플레이어의 길과 할당한 공간에 따라 나뉘고» 집 크기가 그에 맞춰진다. 큰 집 뒤에 확장을 붙인다. https://store.steampowered.com/api/appdetails?appids=1363080
- Manor Lords 화면: 휘어진 흙길이 마을을 가로지른다. 집은 박공을 길에 대고 늘어서고, 집 뒤로 울타리 친 좁고 긴 텃밭이 길과 수직으로 뻗는다. 길이 갈리는 곳엔 삼각형 풀밭과 나무 무리가 남고, 순환로가 가운데 풀밭을 둘러싼다. 교회는 마을 뒤쪽 가장자리에 있다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1363080/bffe9f34abaae09855becd6e8ca2ddb9065b2ebb/ss_bffe9f34abaae09855becd6e8ca2ddb9065b2ebb.1920x1080.jpg)
- Manor Lords 플레이어 토론: 작은 길이 다닌다고 큰길로 자라지는 않는 것 같고, 버지지 필지가 이어질 때만 길이 올라간다는 관찰이 있다. 2024년 글은 «작은 길과 길의 무작위성이 마을 모습을 해친다»고 쓴다. https://steamcommunity.com/app/1363080/discussions/0/3386168507489829201
- Manor Lords 배치 요령(플레이어): 길로 블록을 먼저 두르고 그 안에 필지를 그린다. https://steamcommunity.com/app/1363080/discussions/0/4524512863775599726/
- Kingdoms and Castles: 길은 «길 양옆과 끝에서 3칸까지» 건설 가능 구역을 만든다. 성(Keep)·성벽 블록·전초 등 몇몇을 빼면 이 구역 안에만 지을 수 있다. 집은 길에 닿으면(모서리만 닿아도) 행복 +5, 닿지 않으면 −5다. 돌길은 50% 빠르다. (검색 요약: kingdomsandcastles.gamepedia.com/Road — fandom이 402로 막아 원문 못 봄)
- Kingdoms and Castles 화면: 길은 1칸 폭 격자다. 집은 길에 바짝 붙어 늘어선다. 성(keep과 성벽)은 강을 등진 마을 한쪽에 있다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/569480/ss_b352f28aa3450b0813fab1a4f94e9eadd87a0be8.1920x1080.jpg)
- Banished: 흙길은 무료에 약 17% 빠르고, 돌길은 약 37% 빠르다. 주민은 길을 조금 선호해서, 잘못 놓은 길은 대각 이동을 오히려 길게 만든다. 돌아가는 게 빠르면 길을 건너뛴다. 건물이 길에 닿아야 한다는 규칙은 위키에 없다. https://banished-wiki.com/wiki/Road
- Ostriv 개발자(2016): «흙길은 사람이 가장 많이 다니는 곳에 저절로 생긴다». 포장길은 편의·미관용이고 «배치가 합리적일 때만» 쓰인다. 건물 배치에 격자·각도 제한이 없다. https://forums.factorio.com/viewtopic.php?p=231277
- Ostriv 화면: 길을 따라 집이 붙고 집 뒤로 밭이 이어진다. 시장 광장은 건물이 둘러싼 맨땅이다. (스크린샷 직접 봄: Steam appid 773790 0·11·16번, 섬네일 시트)
- Against the Storm: 건물 입구가 길에 닿지 않아도 주민이 간다. 길은 통행이 많은 곳에만 권한다. 길 등급별로 5%·15%·25% 빠르다. (검색 요약: wiki.hoodedhorse.com/Against_the_Storm/Road — 원문 403)
- Farthest Frontier: 흙길로 시작해 나중에 자갈길(cobbled)을 연다. 집 등급은 «바람직함(desirability)»에 따른다. (검색 요약) 입구가 길을 봐야 하는지는 미확인.
- Kingdom Come: Deliverance II 디자이너 Ondřej Bittner: 지형 자료에서 시작한다. 언덕·골짜기·강은 별로 안 바뀌었기 때문이다. 19세기 중반 군사 지도는 «꽤 변하지 않은 마을들의 배치»를 담고 있어서 쓴다. 군대용이라 개별 건물·병참 지점·길까지 나온다. https://news.xbox.com/en-us/2025/02/04/building-an-authentic-bohemia-in-kingdom-come-deliverance-2/
- Kingdom Come: Deliverance 1: 라타이(Rattay)는 1403년 모습을 재현했다. 1편은 위성 지도에서 시작해 당시 건물을 재구성하고, 놀기 좋게 지형을 조금 다듬었다. (검색 요약)

### Inferences
(해석)
- «중세답게» 읽히는 신호는 넷이다. ① 길이 지형과 옛 통행을 따라 휜다. ② 집은 정면이나 박공을 길에 대고 바짝 붙고, 집 뒤가 마당·텃밭이다. ③ 갈림길은 Y자이고 그 사이에 작은 풀밭·나무가 남는다. ④ 큰 건물(교회·영주 집)은 길 끝이나 가장자리에 선다.
- 우리 마을은 플레이어가 아무 데나 짓는다. 그래서 ②는 골격만으로 못 만든다. 골격이 할 수 있는 건 ①③④와, 길가에 집이 붙을 «여지»를 남기는 것이다.
- Kingdoms and Castles의 «길에서 3칸» 규칙은 우리 건물 크기(2~3칸)에 맞는다. 골격 길 간격을 «길—블록 5~6칸—길»로 잡으면, 어디 지어도 길에서 3칸 안이 된다. 그림만으로 강제하진 않지만 «길가 마을»로 보이기 쉽다.
- Banished의 «잘못 놓은 길은 돌아가게 만든다»는 시뮬 얘기지만 그림에도 통한다. 마을 길은 실제로 오갈 법한 선(문→광장→거점, 광장→우물, 광장→교회)을 따라야 어색하지 않다.

### Gaps
- Manor Lords 위키(Hooded Horse·wiki.gg)와 개발자 일지는 401·403으로 못 열었다. «필지가 길에 닿아야 하는지», «집이 길 쪽으로 저절로 도는지»는 공식 문장으로 확인 못 했다(미확인). 공식 소개문의 «길에 따라 나뉜다»까지만 확인했다.
- Farthest Frontier·Ostriv의 집-길 규칙 세부는 미확인이다.
- KCD 라타이·탈름베르크 레벨 디자인에 대한 개발자 발언은 못 찾았다.

## 3. 2D 탑다운 픽셀아트 마을의 길 폭, 갈림길, 길 끝, 문 앞

### Takeaway
젤다 계열은 길이 좁다. 꿈꾸는 섬(LA DX) 마베 마을은 흙길 1칸이고, 신들의 트라이포스(ALttP) 카카리코는 보통 길 2칸, 큰길 3칸이다. 길 폭은 건물 폭의 0.25~0.5배가 흔하다. 8칸 넘는 바닥은 길이 아니라 광장이나 시장 통로로 쓰인다. 문 앞은 길이 바로 닿거나, 디딤돌이나 1칸 줄기로 잇는다.

| 게임·장소 | 큰길 | 보통 길·오솔길 | 건물 폭 | 길 ÷ 건물 | 근거 |
|---|---|---|---|---|---|
| ALttP 카카리코 | 3칸(박석+가운데 흙 1칸+박석) | 2칸 박석 | 집 약 6칸 | 0.33~0.5 | 픽셀 셈 |
| LA DX 마베 마을 | 없음 | 흙길 1칸 | 집 3~4칸 | 0.25~0.33 | 픽셀 셈 |
| Stardew 대장간 앞 | 문 앞 박석 2칸 | 숲 흙길 약 2칸 | 대장간 약 5칸, 오두막 약 8칸 | 0.25~0.4 | 눈대중(문 1칸 ≈ 64px) |
| Fields of Mistria 겨울 광장 | 차도 약 4칸 + 인도 2~3칸 | — | 건물 10칸 이상 | 약 0.36(px 비) | 눈대중 |
| Moonlighter 마을 | 흙길 약 3칸 | — | 상점 약 6~7칸 | 약 0.43(px 비) | 눈대중 |
| Chained Echoes 시장 | 노점 사이 통로 약 9칸 | — | 노점 약 6칸 | 약 1.5(광장) | 눈대중(640×360 원본 가정) |

### Cited Findings
- ALttP 카카리코(원본 1024×1024 = 64×64칸) 칸별 색 셈: 마을을 두르는 순환로는 박석 2칸이다(서쪽 열 6~7, 동쪽 열 57~58, 남쪽 행 59~60, 북쪽 행 4~5). 큰길은 «박석-흙-박석» 3칸이다(남북 큰길 열 32~34, 동서 큰길 행 19~21과 32~34, 북쪽 큰 집으로 오르는 계단길 열 27~29). 가운데 광장 구역은 약 30×16칸(열 18~47, 행 19~34)이고, 3칸 길이 둘러싸며 세 칸(풍향계 정원, 나무 정원, 좌판 터)으로 나눈다. 집은 생울타리 친 약 10×10칸 블록 안 뒤쪽에 서고, 문은 남쪽 길을 본다. 문에서 길까지는 디딤돌 점선이다. 마을 밖 들판 길은 흙 2칸이고 마을 경계에서 박석으로 바뀐다. (픽셀 셈; 스크린샷 직접 봄: https://www.vgmaps.com/Atlas/SuperNES/LegendOfZelda-ALinkToThePast-LightWorld-KakarikoVillage.png)
- LA DX 마베 마을(원본 맵 x 0~640, y 1024~1664를 40×40칸으로 셈): 흙길은 거의 전부 1칸이다. 직각으로 꺾는 ㄱ자·계단꼴이다. 집마다 문에서 아래로 1칸 줄기가 나와 가로 길에 붙는다. 포장 광장 둘(풍향계 광장, 전화 오두막 광장)은 약 7×6~7칸 테두리다. 마을 출입은 절벽 틈과 계단으로 한다. (픽셀 셈; 스크린샷 직접 봄: https://www.vgmaps.com/Atlas/GB-GBC/LegendOfZelda-Link'sAwakeningDX-Koholint.png)
- Stardew Valley 대장간: 문 바로 앞에서 박석 2칸이 오른쪽 작업 마당 앞으로 이어진다. 문(1칸)과 박석 앞뜰이 맞닿는다. 왼쪽 강가 흙길은 약 3칸이고 가장자리가 풀로 들쭉날쭉하다. (눈대중; 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_5e327e4cfc49d8137f8014e728eae3c0e6be2dca.1920x1080.jpg)
- Stardew 숲길: 흙길 약 2칸이 Y자로 갈리고 갈림목에 표지판이 선다. 길은 울타리 안 흙마당(목장)으로 넓어진다. (눈대중; 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/413150/ss_4fa0866709ede3753fdf2745349b528d5e8c4054.1920x1080.jpg)
- Fields of Mistria 겨울 광장: 십자로다. 차도 약 4칸 양옆에 연석 1줄과 인도 2~3칸이 있다. 교차로 모서리는 45도로 깎였고 한가운데에 원형 무늬 포장이 있다. 모서리마다 나무·가로등이 선다. 집 문은 인도에 닿는다. (눈대중; 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2142790/f2592c4bdf482b43e2dacb9880c0f80b032602f2/ss_f2592c4bdf482b43e2dacb9880c0f80b032602f2.1920x1080.jpg)
- Fields of Mistria 강가 집: 문에서 아래 계단까지 짙은 흙빛 닳은 띠(약 2.5칸)가 곧게 내려간다. 띠는 계단 폭(약 3.5칸)과 줄을 맞춘다. (눈대중; 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2142790/9933944638583f30c37fc4a51977de639f86624c/ss_9933944638583f30c37fc4a51977de639f86624c.1920x1080.jpg)
- Moonlighter 마을: 길은 모래빛 흙길 약 3칸이고 가장자리에 풀 술이 난다. 집 문에서 길까지는 디딤돌 몇 개만 놓았다. 광장은 돌 포장에 연석을 두르고 모서리를 둥글렸으며 가운데에 원형 단이 있다. 길(흙)과 광장(돌)을 재질로 가른다. (눈대중; 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/606150/ss_af36aa1ca2e534a999938cff0eb04409668f5b10.1920x1080.jpg)
- Chained Echoes 시장: 바닥 전체가 흙·자갈 광장이고, 노점이 두 줄로 마주 보며 가운데 통로를 만든다. 가장자리에 회색 돌이 닳아 드러난 얼룩이 있다. (눈대중; 스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1229240/ss_a683aed9b1e2500b3aa7bb5f3d5d7a58f744dca8.1920x1080.jpg)
- Eastward 역 앞: 길 대신 풀밭 위 밝은 흙 얼룩(구름 모양)으로 다닌 자리를 보인다. 중세풍은 아니다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_bf8d65929d363f1b62f632d934eda94ef5188049.1920x1080.jpg)
- Sea of Stars: Steam 스크린샷 27장에 마을 길을 잴 만한 장면이 없다. 전투·던전·실내 위주다. (스크린샷 직접 봄: appid 1244090 섬네일 시트)

### Inferences
(해석)
- 우리 건물 폭은 2~3칸이다. 위 비율 0.25~0.5를 곱하면 골목 1칸, 큰길 1~1.5칸이다. 16px에선 큰길 2칸, 골목 1칸이 무난하다. Watabou의 2 : 1과도 맞는다.
- 지금 정문→거점 «폭 8칸 박석 띠»는 집 폭(2칸)의 4배다. 사례에서 이 폭은 길이 아니라 광장(마베 7×6, 카카리코 30×16)이나 시장 통로(Chained Echoes 9칸)다. 그래서 띠 전체가 «길게 늘인 광장»이나 «진격로»로 읽힌다.
- 두 갈래가 있다. (a) 큰길을 2~3칸으로 줄이고 광장은 따로 한 곳에만 둔다. (b) 띠를 «큰길을 넓힌 시장»으로 보고 남기되, 가장자리에 좌판·우물·나무를 놓아 «머무는 곳»으로 만든다. (b)는 ORB의 «큰길 한 구간을 넓혀 시장으로 쓴다»와 맞다(1절).
- 카카리코의 «박석-흙-박석» 3칸 큰길은 그대로 쓸 만하다. 박석 큰길 가운데에 바퀴 자국 흙 1칸을 둔다. 큰길과 보통 길이 폭과 재질 둘 다로 갈린다.
- 문과 길을 잇는 방식은 셋이다. 길이 문에 바로 닿음(Stardew 대장간), 디딤돌(카카리코·Moonlighter), 1칸 줄기(마베). 아무 데나 짓는 우리 구조엔 디딤돌·1칸 줄기가 싸다(5절).
- 사례의 길은 문·계단·광장·마을 밖에서 끝난다. 아무 데도 아닌 곳에서 끊긴 길은 없다.
- 갈림길에는 표지판·나무·가로등·원형 포장 같은 «점 표시»를 둔다(Stardew, Mistria).

### Gaps
- Pelican Town 전체 맵은 위키가 Cloudflare로 막아 못 셌다. Stardew 수치는 스크린샷 두 장 눈대중이다.
- Mistria·Moonlighter의 원본 해상도는 모른다. 그래서 칸 수와 함께 «길 ÷ 건물» px 비율을 적었다.
- 위 게임들은 대부분 3/4 정면 시점이다. 45° 내려다보기인 우리에서 남북 길과 동서 길이 다르게 보이는 문제는 다루지 않았다.

## 4. 방어 게임의 마을 안 길 — 적의 길과 생활 길

### Takeaway
방어 게임은 대개 마을 안 생활 길을 그리지 않는다. Thronefall은 마을 밖에서 성까지 흙길 하나만 있고, 집은 길가가 아니라 성 둘레에 모인다. They Are Billions·Diplomacy is Not an Option·Bad North는 길망 없이 맨땅으로 처리한다. 적이 오는 길은 «길 그림»보다 진입 지점 예고·성벽·문으로 알린다.

### Cited Findings
- Thronefall 화면: 흙길 한 줄이 지도 끝에서 성 중심(Castle Center) 문 앞까지 온다. 목책이 그 길을 가로질러 선다. 집과 작업장은 길가가 아니라 성 둘레에 모이고, 밭·풍차·망루는 목책 밖에 있다. 성은 절벽을 등진 뒤쪽에 있다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg)
- Thronefall 다른 맵: 성은 물가 높은 대지 위 구석에 있다. 바깥 성벽 고리가 멀리 돌고, 그 사이에 밭·풍차·집·탑이 퍼진다. 마을 안 길은 보이지 않는다. (스크린샷 직접 봄: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_b11d1fc23cbf78bf154c7c3d8bed1be1859c2183.1920x1080.jpg)
- Thronefall 리뷰: 밤마다 정해진 적이 여러 진입 지점 중 하나로 들어오고, 밤 전에 어디서 올지 지도에 보여 준다. 너무 오밀조밀하면 적이 성에 쉽게 닿고, 너무 넓히면 병력이 얇아진다. (검색 요약: https://www.thesixthaxis.com/?p=442518 외)
- Stronghold(플레이어 관행, Definitive Edition 토론): 곡물창고·빵집·무기 공방·풍차는 성벽 안 성채(keep) 가까이 둔다. 나무꾼·사냥막·채석장·대부분의 밭은 성벽 밖 «소모품»이다. 시장과 오두막은 표지판(사람과 적이 지도에 들어오는 지점)에서 먼 구석에 둔다. 사방 성벽은 드물고, 성벽 하나와 작은 성문으로 살상 지대(kill zone)를 만들고 옆길은 막는다. https://steamcommunity.com/app/2140020/discussions/0/6450905019305158854
- Kingdom Two Crowns: 옆으로 흐르는 한 줄 지도다. 섬마다 마을 양쪽에 작은 포털이 있고, 섬이 진행될수록 양쪽 포털 수가 는다. (검색 요약: kingdomthegame.fandom.com/wiki/Islands_in_Two_Crowns) 화면에선 땅 한 줄이 곧 길이다. (스크린샷 직접 봄: appid 701160 섬네일 시트)
- They Are Billions·Diplomacy is Not an Option·Bad North 화면: 마을 안에 따로 그린 길망이 없다. 건물 사이는 맨땅이나 닳은 흙이다. 성벽과 성문이 흐름을 정한다. (스크린샷 직접 봄: appid 644930·1272320·688420 섬네일 시트)
- 이미 조사: Kingdom Rush·Northgard에서 길이 진격로·건설 슬롯으로 읽히는 문제는 `village_research/evidence/paths_ground.md` 5절.

### Inferences
(해석)
- 우리 «정문→광장→거점» 큰길은 실제 중세 큰길(문→시장)과 겹치고, 적의 예상 경로와도 겹친다. 이 겹침 자체는 사실적이다. 문제는 «적이 이 길로만 온다»는 오독이다(paths_ground 5절).
- 그래서 생활 길은 큰길과 재질·폭이 다른 «망»으로 깔아야 한다. 성벽 안쪽 순환로, 광장에서 사방으로 가는 보통 길, 우물·교회로 가는 골목이다. 큰길 하나만 덩그러니 있으면 진격로로 읽히고, 길망 속 한 줄이면 마을 길로 읽힌다.
- Thronefall처럼 «집이 성 둘레에 모이는» 그림은 방어 게임에서 자연스럽다. 우리도 거점 둘레에 주거가 모이고, 큰길가와 문 근처엔 문 구역(여관·마구간·작업장)이 서는 그림이 맞다.
- Stronghold 관행(귀한 것은 안쪽, 소모품은 바깥, 사는 곳은 적이 드는 곳에서 먼 구석)은 6절 거점 위치와 같은 논리다.

### Gaps
- Thronefall에서 적이 길을 따라 걷는지(길이 진격 경로인지 장식인지)는 미확인이다. 리뷰엔 «진입 지점»만 있다.
- Stronghold 공식 자료(성채 위치 규칙)는 못 찾았다. 관행은 플레이어 토론뿐이다.
- They Are Billions·DINO에 길 기능이 있는지는 미확인이다. 스크린샷만 봤다.

## 5. 플레이어가 아무 데나 짓는 구조에서 길 다루기

### Takeaway
사례는 세 갈래다. (A) 길을 먼저 깔고 건물을 길에 묶는다(Manor Lords, Kingdoms and Castles). (B) 건물은 자유롭고, 길은 속도 보너스이거나 다니면 생긴다(Banished, Ostriv, Against the Storm, Foundation). (C) 길과 건설 자리를 미리 고정한다(Thronefall로 보임, Kingdom Rush). 바닥이 그림뿐이고 건물이 아무 데나 서는 우리에겐 (A)의 «골격»과 (B)의 «문 앞 이음»을 섞는 쪽이 싸다.

### Cited Findings
- A — Manor Lords: 주거 구역은 길과 할당 공간에 따라 나뉜다. https://store.steampowered.com/api/appdetails?appids=1363080
- A — Kingdoms and Castles: 길에서 3칸 안에만 짓는다(성 등 예외). 길에 닿은 집 행복 +5, 아니면 −5. (검색 요약)
- A — Emilien 2012: 길이 정착민을 끌고 집이 길을 늘린다. https://researchportal.ip-paris.fr/en/publications/procedural-generation-of-villages-on-arbitrary-terrains/
- A — Parish & Müller 2001: 길에 직접 닿지 않는 필지는 버린다. https://cgl.ethz.ch/Downloads/Publications/Papers/2001/p_Par01.pdf
- B — Banished: 길은 선택이고 속도만 준다(17%·37%). https://banished-wiki.com/wiki/Road
- B — Ostriv: 흙길은 많이 다니는 곳에 저절로 생긴다. https://forums.factorio.com/viewtopic.php?p=231277
- B — Against the Storm: 입구가 길에 닿지 않아도 된다. (검색 요약)
- B — Foundation·Settlers IV의 닳는 길: 이미 조사(paths_ground 1절).
- C — Thronefall: 집·밭·탑이 지도의 정해진 자리에 선 것으로 보인다. (스크린샷 직접 봄; 고정 자리인지는 미확인)
- 문 앞 이음의 예: 디딤돌(카카리코·Moonlighter), 1칸 줄기(마베), 문 앞 박석(Stardew). 3절 출처.
- 건물이 길 위에 서는 경우: Watabou와 Parish & Müller는 필지를 길에서 안으로 줄여 만들므로 구조상 생기지 않는다. 게임에서 «건물을 놓으면 길이 밑으로 숨는지, 금지되는지»를 밝힌 1차 출처는 못 찾았다.

### Inferences
(해석) 우리 조건: 바닥 꾸밈은 시뮬과 무관, 건물 2×2~3×2칸, 마을 아무 데나.

| 방식 | 그림 | 장점 | 단점 |
|---|---|---|---|
| ① 골격만 깔고 건물이 길을 덮음 | 길 칸 위에 건물을 그냥 그린다 | 가장 싸다. 시뮬 무관 | 길이 집 밑으로 들어가 «집이 길을 막은» 그림. 큰길 위에 지으면 큰길이 끊겨 보임 |
| ② 골격 + 발자국 아래 길을 흙 마당으로 | 이미 있는 흙 마당 얼룩이 길 칸을 덮는다 | 기존 마당 얼룩 재사용. 길이 마당에 «흡수»됨 | 큰길 한가운데 마당이 생기면 어색 |
| ③ 골격 + 문 앞 디딤돌·1칸 줄기 | 건물 문에서 가장 가까운 길까지 | 아무 데나 지어도 «집이 길을 본다» 신호가 생김 | 경로 그리기 로직 필요. 줄기가 길면 지저분하니 일정 길이를 넘으면 생략 |
| ④ 큰길·광장 칸 건설 금지 | — | 큰길과 광장이 늘 살아 있음 | 건설 규칙이 바뀜 = 시뮬 변경. 그림 범위를 넘는 결정 |
| ⑤ 건물이 길 쪽으로 돌아섬 | 문 방향별 스프라이트 | 가장 중세답다(Manor Lords의 길 향한 박공) | 건물마다 2~4방향 그림 필요. 45° 시점이라 비쌈 |

- 조합 제안(해석): ① 또는 ②를 기본으로 한다. 큰길·광장 위 건설을 ④로 막을지는 사용자가 정할 일이다. 여유가 있으면 ③(디딤돌)만 더한다. ⑤는 아트 비용 때문에 뒤로 미룬다.
- 골격 간격을 «길—블록 5~6칸—길»로 잡으면 어디 지어도 문에서 길까지 3칸 이하다. ③의 줄기가 짧아지고, Kingdoms and Castles의 3칸 규칙과 같은 효과를 그림으로 낸다.

### Gaps
- 건물이 길 위에 놓일 때의 게임별 처리(길 삭제·건설 금지·밑으로 숨김)를 밝힌 위키나 개발자 글은 못 찾았다. Banished·Kingdoms and Castles 위키 원문은 fandom 402로 막혔다.
- Thronefall이 고정 자리인지 원문 확인을 못 했다.

## 6. 거점 위치 — 가운데냐, 문 반대편 끝이냐

### Takeaway
생성기와 실제 중세 도시에서 성(성채)은 대개 가운데가 아니라 가장자리·높은 곳에 서고, 가운데에는 시장 광장이 온다. 문에서 온 큰길은 광장으로 모이고, 성은 광장 너머 성벽 쪽에 붙는다. 방어 게임도 적이 한쪽에서 오면 성을 뒤쪽 끝(절벽·물가)에 두고 그 사이에 마을을 펼친다. 적이 양쪽에서 오면 가운데에 둔다(Kingdom Two Crowns).

### Cited Findings
- Watabou: 가운데 셀은 광장(시장)이다. 성채는 도시 셀 «바로 바깥 첫 셀», 즉 가장자리에 놓고 성벽 선에 걸친다. 성채 쪽 성벽에는 문을 내지 않는다(reserved). 성채의 문은 도시 바깥과 닿은 꼭짓점을 빼고 고른다. 큰길은 문에서 광장으로 가고 성채로 가지 않는다. 성채는 길찾기에서 막힌 땅이다. Model.hx, CurtainWall.hx, Topology.hx, Castle.hx(1절 URL)
- Watabou 2020: «성을 성벽에 붙일지 마을 가운데 둘지» 고르는 옵션이 생겼다. https://forum.profantasy.com/discussion/comment/91909 (공개 소스의 옛 판은 성벽 쪽만 만든다 — 코드 읽기)
- 실제 도시 브리스톨: 성은 동문 옆에서 반도로 드는 뭍길을 막았다. 네 큰길은 시장으로 모였다. https://the-orb.arlima.net/encyclop/culture/towns/townint5.html
- 코프 캐슬(Dorset): 옛 마을 핵은 성문 밖 남쪽 고원에 있고, 성문 바로 밖 시장 광장이 마을의 중심이다. 볼소버(Derbyshire): 성을 세운 직후 계획 도시로 깔았고 핵에 시장이 있다. 뉴캐슬: 성은 가파른 둑 꼭대기에 있고 큰길 셋이 거기서 북으로 뻗는다. (검색 요약: dorsetcouncil.gov.uk Corfe Castle 역사 경관 문서, her.derbyshire.gov.uk/Monument/MDR6283, sitelines.newcastle.gov.uk/SMR/11101)
- Thronefall: 성 중심이 절벽·물을 등진 뒤쪽 끝에 있다. 입구 쪽부터 길 → 목책 → 집 무리 → 성 순서다. 다른 맵에서도 성은 구석 대지 위에 있고, 바깥 성벽과의 사이에 밭·집이 펼쳐진다. (스크린샷 직접 봄: 4절 Thronefall 두 URL)
- Kingdoms and Castles: 성은 강을 등진 마을 한쪽에 있다. (스크린샷 직접 봄: 2절 URL) 성(Keep)은 길 구역 규칙의 예외라 아무 데나 놓는다. (검색 요약)
- Stronghold 관행: 귀한 생산은 성채 옆 성벽 안에, 사는 곳(오두막)과 시장은 적이 드는 표지판에서 먼 구석에 둔다. 성벽 하나와 문 하나로 살상 지대를 만든다. https://steamcommunity.com/app/2140020/discussions/0/6450905019305158854
- Kingdom Two Crowns: 마을 양쪽에 포털이 있다. 마을 중심(Town Center)은 가운데에 있고 성벽이 양쪽으로 자란다. (검색 요약; 섬네일로 한 줄 지도 확인)

### Inferences
(해석) 우리 맵: 정문은 남쪽 27~29행 가운데, 거점 (30,13)은 문에서 약 14행 위, 그 뒤(북)로 13행이 남는다.
- 지금처럼 적이 남쪽 정문 하나로만 들어오면 Thronefall·Stronghold형이다. 이 형에선 거점을 문 반대편(북쪽) 가까이 두고, «문 — 문 구역 — 큰길 — 광장 — 거점» 순서로 마을이 그 사이에 펼쳐진다. 사용자 말(«더 위로 가야 마을이 형성될지도»)과 맞는다.
- 지금 (30,13)은 Watabou에서 «가운데 = 광장» 자리다. 거점이 광장 자리를 차지해서 시장이 설 곳이 없는 그림이 된다. 대안은 거점을 북쪽으로 올리고, 지금 거점 근처를 광장(시장·우물)으로 두는 것이다. 그러면 정문 큰길이 광장 모서리에 닿고, 광장에서 짧은 길이 거점으로 간다(1절 규칙 1·8).
- 반대 해석도 있다. 나중에 사방 성벽에 문을 여럿 내면 적이 여러 쪽에서 온다. 그때는 Kingdom Two Crowns형으로 가운데가 맞다. 즉 «북쪽 끝»은 «문 하나» 전제의 결론이다. 사방 성벽 계획이 «문 여럿»까지 가는지가 갈림길이고, 이건 사용자가 정할 일이다.
- 절충: 거점을 북쪽 성벽에 붙이지 않고 북쪽 1/3쯤(대략 6~9행)에 둔다. 뒤에 작은 성채 마당이 남고 앞에 광장과 마을이 펼쳐진다. 북쪽 성벽에 바짝 붙이면 Watabou·브리스톨처럼 «성벽 일부인 성채»가 된다. 그러면 Watabou 규칙상 그 성벽 구간엔 문을 낼 수 없으니, 나중에 북문을 낼 계획과 부딪친다.
- 주의: 거점 좌표는 바닥 그림과 달리 시뮬(적 경로 길이)에 닿는다. 그림만의 결정이 아니다. 좌표는 데이터 한 곳에 손잡이로 둔다(프로젝트 규칙).

### Gaps
- Stronghold 캠페인 맵들의 성채 위치를 모은 자료는 없다. 관행만 있다.
- Kingdom Two Crowns·Kingdoms and Castles 위키 원문은 못 열었다.
- 실제 도시 예(코프·볼소버·뉴캐슬)는 검색 요약만 봤다.

## 조사 메타
- WebSearch 19회(그중 1회는 reddit 도메인 거부로 결과 없음). 상한 25회 안.
- 원문을 연 것: Watabou 소스 5개(Model·CurtainWall·Topology·Ward·Castle), GitHub README, profantasy 포럼, itch 2쪽, Parish & Müller PDF(본문 텍스트 추출), Steam 토론 3개, Steam 상세 설명(Manor Lords 등 API), Banished 위키, Xbox Wire, ORB, factorio 포럼(Ostriv 개발자), ip-paris 초록.
- 스크린샷: Steam 섬네일 시트 14장(약 190컷)을 훑었다. 원본 크기로 직접 본 것은 11장(Stardew 2, Chained Echoes 1, Fields of Mistria 2, Moonlighter 1, Eastward 1, Thronefall 2, Manor Lords 1, Kingdoms and Castles 1). 맵 이미지 3장(ALttP 카카리코, LA DX 코홀린트 전체와 마베 확대). 칸 단위 픽셀 셈 2곳(카카리코, 마베). Banished·Farthest Frontier 스크린샷은 받았지만 보지 않았다.
- 열지 못한 URL: manorlords.wiki.gg(401), wiki.hoodedhorse.com의 Manor Lords·Against the Storm(403), store.epicgames.com 뉴스(403), videogamer 위키(내용 없음), kingdomsandcastles·banished·kingdomthegame fandom(402), hal.archives-ouvertes.fr(봇 차단), perso.liris.cnrs.fr/egalin/Articles/2012-villages.pdf(접속 거부), graphics.tudelft.nl EG09 PDF와 학위논문(접속 거부·시간 초과), diglib.eg.org(403), gamedev.net Ostriv 글(403), stardewvalleywiki.com(Cloudflare), reddit(도구 차단).
- 내려받은 이미지는 저장소 밖 scratchpad에 있다: `C:\Users\bhy99\AppData\Local\Temp\claude\C--Users-bhy99-td-proj\1dd6d343-9443-47fd-a52b-c1c28cecc0ac\scratchpad\shots_roads\`
