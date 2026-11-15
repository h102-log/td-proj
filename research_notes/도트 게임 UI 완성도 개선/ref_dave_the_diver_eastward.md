# 레퍼런스 분석: Dave the Diver(MINTROCKET/Nexon, 2023)·Eastward(Pixpil/Chucklefish, 2021)의 UI 비주얼

> 표기 규칙
> - **[출처]**: 출처 문서가 직접 말한 사실·인용.
> - **[관찰]**: 내가 공식 Steam 스크린숏을 내려받아 보고 확인한 것. "observed in screenshot <URL>" 형식으로 표시. 색값은 JPEG 픽셀을 찍어 본 값이라 압축 오차(±10 정도)가 있다.
> - Dave 스크린숏 3장은 URL 이름이 `1920x1080`이지만 실제로 받은 파일은 1280×720이었다. Eastward 3장은 1920×1080.
> - 사용한 스크린숏 6장
>   - D1(식당 영업 HUD): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg
>   - D2(잠수 장면, HUD 없음): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_3a459e9ea8b54c3864379fcad38bff3ae7fe4e8c.1920x1080.jpg
>   - D3(컷신, HUD 없음): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_d1c0a418890d7dce6fc1ef88e0ab038c12ca69d7.1920x1080.jpg
>   - E1(컷신, 레터박스): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_2c7516dbcfba035a359a2eb7257356809a3f5eaa.1920x1080.jpg
>   - E2(던전 전투 HUD, 샘 조작 중으로 보임): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg
>   - E3(야외 전투 HUD, 존 조작 중): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg
> - 이 6장에는 Eastward의 대화창·메뉴·인벤토리, Dave의 스마트폰 메뉴·일시정지 화면이 들어 있지 않다. 그 부분은 문헌 출처만 있고 관찰은 없다(각 Gaps 참고).

## 1. 렌더링 방식 — UI가 월드와 같은 픽셀 격자인가, 고해상도 오버레이인가

### Takeaway
Dave the Diver는 **고해상도(화면 해상도) UI를 픽셀 아트 월드 위에 얹는** 방식이고, 대신 제목·숫자에 '픽셀풍 디스플레이 폰트'를 써서 픽셀 세계와 톤을 맞춘다. Eastward는 UI도 픽셀 느낌을 유지하지만 **월드보다 더 잘게 쪼갠 픽셀(작은 입자)과 매끈한 요소를 섞고**, 화면 전체에 CRT류 후처리를 덮어 UI와 월드를 한 질감으로 묶는다. 두 게임 모두 "UI를 월드와 똑같은 저해상도 격자에 억지로 맞추지 않는다".

### Cited Findings
- [출처] Dave the Diver는 "2D 픽셀과 3D 아트를 함께 사용"하며, 리드 게임 디자이너 우찬희는 "2D의 아케이드 같은 액션과 3D의 공간감을 동시에 느낄 수 있다는 점이 매력적"이었다고 말했다. 이 Unity 사례 글에는 UI·폰트·해상도·PPU 이야기는 없다. — [Unity 코리아 사례 연구](https://unity.com/kr/resources/dave-diver)
- [출처] 80.lv의 Dave 기사도 2D/3D 혼합(URP, Cinemachine)만 다루고 UI·폰트·픽셀 해상도 언급은 없다. — [80.lv](https://80.lv/articles/dave-the-diver-developer-on-mixing-2d-3d-using-unity-urp/)
- [출처, 신뢰도 낮음 — 개인 블로그 해석] Dave는 캐릭터는 픽셀, 수중 배경은 고해상도 페인팅, UI는 "modern flat design"이며 UI 레이어는 가독성을 위해 벡터 그래픽을 쓴다는 분석. 개발자 발언이 아니다. — [halabaojia 블로그](https://halabaojia.pages.dev/collection/20251124-dave-the-diver-pixel-hd-hybrid-visual-design)
- [관찰] D1의 HUD는 월드 픽셀 격자에 맞춰져 있지 않다. 퀘스트 본문("Go into the Depths", "Serve Morray Curry!")은 안티에일리어싱된 매끈한 산세리프, 우상단 시계 다이얼은 매끈한 원형 벡터, 패널 테두리는 720p 기준 1~2px의 가는 선이다. 반면 금액 "6,000", 퀘스트 제목 "Going Deeper", 해시태그 "#bancho_sushi", 하단 탭 라벨(Menu·Research·Staff…)은 각진 **픽셀풍 굵은 디스플레이 폰트**를 크게 찍어 선명하게 보인다. 즉 "제목·숫자 = 픽셀풍, 본문 = 고해상도 산세리프" 이원 구성. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] D2는 3D 지형(픽셀처럼 각진 텍스처)과 픽셀 스프라이트 다이버가 함께 있고 HUD가 없다(스토어용 연출 컷으로 보임). — observed in screenshot [D2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_3a459e9ea8b54c3864379fcad38bff3ae7fe4e8c.1920x1080.jpg)
- [출처] Pixpil 공동창업자 Tommo Zhou: "Interestingly Eastward is a 3D game with a 2D perspective!", 아티스트 Moran이 Aseprite로 기본 에셋을 만들고, 자체 엔진에서 "shader textures and lighting systems"로 분위기를 내며, 에셋마다 bump map을 "hand painted ... one by one" 한다. UI·폰트 언급은 없다. — [Game Developer](https://www.gamedeveloper.com/art/eastward-s-creators-share-insights-on-making-pixel-art-adventures)
- [출처] Eastward는 Pixpil 자체 엔진과 오픈소스 MOAI를 결합해 2D 아트에 3D 효과를 입혔다. — [Red Bull 인터뷰(검색 요약)](https://www.redbull.com/my-en/eastward-interview)
- [출처] 7.GAME의 Eastward 미술 비하인드 기사: "以小颗粒表现弱化了画面的锯齿感"(작은 입자로 표현해 계단 현상을 약화), "在保留像素艺术独特颗粒感的基础上", 전통 픽셀의 입자감과 외곽선이 주는 "迟钝和笨重"(둔하고 무거운 느낌)을 시각적으로 줄였다; "对话框的文字也有像素设计的巧思"(대화창 글자에도 픽셀 디자인의 공을 들였다); 엔진은 "具备CRT滤镜等功能的'Gii'游戏引擎"(CRT 필터 등을 갖춘 Gii 엔진). 프로듀서 Tommo 언급. — [Sohu/7.GAME](https://www.sohu.com/a/511158455_121119410)
- [관찰] E2의 우상단 재화 아이콘(소금통)은 월드 픽셀보다 훨씬 잘게 나뉜 도트 격자(LCD/도트 매트릭스 느낌)로 그려져 있고, 옆의 숫자 "0388"은 안티에일리어싱된 매끈한 숫자다. 하트 10개도 가장자리가 매끈해 월드 픽셀 격자에 붙어 있지 않다. 캐릭터 초상은 2색 만화/하프톤 일러스트. — observed in screenshot [E2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg)
- [관찰] E2·E3 화면 전체에 색수차(RGB 번짐)와 약한 흐림·비네팅 같은 후처리가 깔려 있어, 해상도가 다른 UI와 월드가 한 질감으로 묶여 보인다. — observed in screenshot [E2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg), [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)

### Inferences
- 두 상용작 모두 "UI를 월드와 같은 저해상도 격자에 1:1로" 그리지 않는다. Dave는 아예 고해상도로 가고 폰트 하나로 픽셀 톤만 빌리며, Eastward는 픽셀 감성을 유지하되 월드보다 잘게 쪼갠 입자를 쓴다. → 640×360 기준 화면에서 UI를 전부 같은 1배 픽셀로만 만들면 정보량이 많을 때 글자가 뭉개지고 '학생 작품' 느낌이 나기 쉽다는 진단의 근거가 된다(이는 내 추론).
- 혼합할 때 일관성의 열쇠는 "규칙"이다: Dave는 '제목·숫자 = 픽셀풍 폰트, 본문 = 매끈한 산세리프'를 모든 HUD에 같은 규칙으로 적용했고, Eastward는 전체 화면 후처리로 이질감을 덮었다.

### Gaps
- 두 게임의 내부 렌더 해상도(월드 기준 해상도, Dave의 PPU, Eastward의 기준 해상도)는 공식 자료로 확인하지 못했다. 중국어 검색 요약에 "PC판이 흐리다, 소재가 720p" 라는 Steam 평이 언급됐지만 원문 출처를 확인하지 못해 사실로 쓰지 않는다.
- Dave의 UI가 실제로 벡터(SVG 계열)인지, 고해상도 비트맵인지는 개발자 자료가 없다(블로그 추정뿐).
- NDC(넥슨 개발자 콘퍼런스) 2023/2024에서 Dave UI를 다룬 세션은 검색으로 찾지 못했다.

## 2. UI 색 팔레트 — 패널색, 강조색, 채도, 복잡한 장면 위 가독성

### Takeaway
Dave는 **거의 검은 무채색 패널 + 장면 테마에서 뽑은 고채도 강조색 1~2개(금색·마젠타·시안)** 조합으로, 네온 식당 장면 위에서도 정보가 튀게 만든다. Eastward는 **어두운 남색 반투명 슬래브 + 크림색 글자 + 조작 캐릭터별 강조색(존=주황, 샘=청록/파랑)** 으로 보이며, 화려한 월드보다 HUD 채도를 한 단계 낮게 둔다.

### Cited Findings
- [관찰] D1 금액 패널 내부는 거의 순흑(RGB ≈ 4,4,4), 하단 탭 바는 검붉은 검정(≈ 9,0,1 ~ 23,0,10). 강조색: 동전 금색(≈ 204,143,1), 퀘스트 제목 노랑, 두 번째 퀘스트 제목 시안, 프로필 패널 테두리 마젠타(식당 네온 장식과 같은 색), "Time Skip" 버튼 노랑 테두리, 새 콘텐츠 배지 빨강 원 "N", 정보 배지 노랑 "i". 본문 글자는 흰색~연한 청회색. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] D1 손님 머리 위 주문 말풍선은 흰색/연회색 둥근 말풍선 + 요리 아이콘, 떠오르는 대사 "This looks good!"은 흰 글자에 어두운 외곽선이라 배경이 어떤 색이든 읽힌다. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] E3 Ammo/Bomb 패널 바탕은 어두운 남색(≈ 16~33, 27~42, 49~57), 글자는 연한 크림색, 아래 밑줄은 탁한 크림(≈ 144,140,105). 찬 하트는 주황빨강(≈ 251,77,8), 빈 하트는 바탕과 거의 같은 짙은 남색(≈ 15,26,44)에 밝은 외곽선. 재화 숫자 "0569"는 주황(≈ 174,81,50). — observed in screenshot [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)
- [관찰] E2에서는 초상이 청록 2색, 재화 숫자가 파랑, 에너지 게이지가 시안/주황이다. E3(존)에서는 초상이 빨강/파랑 2색, 숫자가 주황이다. 조작 캐릭터에 따라 HUD 강조색이 바뀌는 것으로 보인다(스크린숏 2장 비교로 본 추정). — observed in screenshot [E2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg), [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)
- [출처] Eastward 미술은 "采用高纯度的色彩 契合复古情调"(고채도 색으로 레트로 정서에 맞춤), "游戏整体色调 丰富而统一"(전체 색조가 풍부하면서 통일), 따뜻한 야외 장면과 지하 도시의 네온광을 많이 쓴다. — [Sohu/7.GAME](https://www.sohu.com/a/511158455_121119410)

### Inferences
- 두 게임 공통: 패널은 **어둡고 채도 낮은 중성색**(검정·남색·짙은 갈색), 색은 **강조에만** 쓴다. 고채도 원색을 패널 바탕에 쓰지 않는다. 월드가 고채도일수록 UI 바탕은 더 어둡게 눌러 대비를 확보한다.
- 강조색은 아무 원색이 아니라 **장면/브랜드에서 뽑은 색**(Dave의 네온 마젠타·금색, Eastward의 캐릭터 색)이라 UI가 세계의 일부처럼 보인다.
- "비어 있음/비활성"은 회색이 아니라 **패널 바탕과 같은 계열의 어두운 색 + 외곽선**으로 표현(Eastward 빈 하트) → 색 수를 늘리지 않는다.

### Gaps
- 두 게임의 공식 UI 팔레트(색 수, 색 코드)를 밝힌 개발자 자료는 찾지 못했다. 위 색값은 JPEG 샘플링 근사치다.
- Eastward 대화창·메뉴의 색은 스크린숏이 없어 확인하지 못했다.

## 3. 테두리·프레임 — 모서리, 외곽선 두께, 베벨/그림자, 9-slice 흔적, 일관성

### Takeaway
Dave는 **가는 1선 외곽선(강조색) + 사선으로 깎은 평행사변형/둥근 모서리, 베벨·두꺼운 그림자 없음**이라는 플랫한 프레임 문법을 모든 HUD 패널에 반복한다. Eastward HUD는 **프레임 없이 반투명 슬래브 + 가는 밑줄**, 게이지는 **가는 선으로 그린 아이소메트릭 상자** 같은 장식적이되 얇은 선 위주다.

### Cited Findings
- [관찰] D1 금액 패널과 프로필 패널은 좌우 변이 기울어진 평행사변형(사선 깎기)이고, 테두리는 1선(금액=올리브금색, 프로필=마젠타). 퀘스트 패널은 모서리가 살짝 둥근 사각형에 갈색-올리브 가는 테두리. "Time Skip"은 노랑 외곽선 알약(pill) 버튼. 베벨, 이중 테두리, 굵은 그림자는 보이지 않는다. 하단 컨트롤러 표시 LB/RB는 기울어진 회색 키캡 모양, A/B/X/Y는 작은 회색 원. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] E3의 Ammo/Bomb는 테두리 없는 어두운 반투명 사각 슬래브에 글자 아래 가는 크림색 밑줄 하나만 있다. E2·E3 에너지 게이지 2개는 가는 흰 선으로 그린 입체(아이소메트릭) 상자 안에 색이 차는 형태, 초상은 밝은 외곽선으로 오려 낸 번개 모양 실루엣. — observed in screenshot [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg), [E2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg)

### Inferences
- 두 게임 모두 "두껍고 장식 많은 RPG 나무/돌 프레임"을 HUD에 쓰지 않는다. 외곽선은 가늘고 하나이며, 형태(사선·알약·둥근 모서리)로 개성을 낸다. 같은 화면 안 패널들이 같은 선 굵기·같은 모서리 문법을 공유한다(Dave).
- 9-slice로 늘리기 쉬운 형태(단색 바탕 + 1선 테두리 + 모서리 처리)라는 점은 관찰로 추정할 수 있지만, 실제로 9-slice를 썼는지는 확인 불가.

### Gaps
- 9-slice 사용 여부, 패널 모서리 반경·선 두께의 정확한 값, Eastward 대화창/메뉴 프레임 모양은 확인하지 못했다. Game UI Database·Interface In Game에서 두 게임 페이지를 찾지 못했다(interfaceingame.com/games/eastward/ 는 404).

## 4. 폰트 — 라틴·한글(Dave)·중국어(Eastward), 픽셀/벡터, 크기, 외곽선·그림자, 숫자 폰트

### Takeaway
두 게임 모두 UI 폰트 이름은 공식적으로 확인되지 않았다. 관찰상 Dave는 **픽셀풍 굵은 디스플레이 폰트(제목·숫자·탭 라벨) + 매끈한 산세리프(본문)** 2종 체계이고, Eastward HUD는 **가는 획의 각진 픽셀풍 라벨 + 매끈한 숫자**를 쓰며 숫자의 앞자리 0을 어둡게 처리한다.

### Cited Findings
- [출처, 신뢰도 중하 — 폰트 안내 블로그] Dave the Diver의 인게임 UI 폰트는 공개 문서가 없고, 로고는 커스텀 레터링이며 인터넷의 "Dave the Diver font"는 팬 재현물이다. — [Made Good Designs](https://madegooddesigns.com/dave-the-diver-font/)
- [관찰] D1: "6,000"·"Going Deeper"·"#bancho_sushi"·"0/500"·하단 탭 라벨은 각진 굵은 픽셀풍 글꼴(이탤릭 변형 포함, 해시태그는 기울임). 본문 체크리스트 문장은 매끈한 산세리프. 하단 탭 라벨은 흰 글자 + 어두운 외곽선. 떠오르는 손님 대사는 작은 흰 글자 + 어두운 외곽선. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] E3: "Ammo 26 / Bomb 10" 라벨은 획이 가늘고 각진 픽셀풍 글꼴(월드 픽셀보다 획이 가늘다). 재화 "0569"는 매끈한 숫자로, 앞자리 "0"은 어둡고 유효 숫자만 밝다(E2 "0388"도 동일). 게이지 퍼센트 "72.1%"·"0.0%"는 아주 작은 기울임 글씨. — observed in screenshot [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg), [E2](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_cde0e802a2ce50572e16be8422479d5b54181577.1920x1080.jpg)
- [출처] Eastward 대화창 글자에도 픽셀 디자인의 공을 들였다("对话框的文字也有像素设计的巧思"). 구체적 폰트명은 없다. — [Sohu/7.GAME](https://www.sohu.com/a/511158455_121119410)

### Inferences
- 고정 자릿수 카운터(0569)는 자릿수 변화로 레이아웃이 흔들리지 않게 하면서, 앞자리 0을 어둡게 해 실제 값을 바로 읽게 한다 — 골드·웨이브 카운터가 많은 HUD에 바로 옮길 수 있는 기법.
- "제목·숫자용 개성 폰트 1종 + 본문용 가독 폰트 1종"으로 역할을 고정하는 것이 상용작 패턴. 폰트 종류를 화면마다 바꾸거나 3종 이상 섞는 것은 반대 신호.
- 복잡한 배경 위 떠 있는 글자(월드 위 말풍선·데미지 숫자 등)에는 어두운 외곽선을 둔다(Dave).

### Gaps
- Dave 한국어판·Eastward 중국어판의 한글/한자 폰트명, 크기(pt/px), 픽셀 폰트인지 여부는 찾지 못했다. 나무위키·Steam 토론 등에 있을 수 있으나 확인하지 못했다.
- 두 게임 대화창 글자 크기·줄 간격은 스크린숏이 없어 측정하지 못했다.

## 5. 반투명·어둡게 한 패널 — 대화창, HUD 오버레이, 일시정지, 배경 어둡게/흐림/디더링

### Takeaway
두 게임 HUD는 **어두운 반투명 패널**을 쓰되 모든 패널이 반투명은 아니다(Dave의 금액 패널은 사실상 불투명). Eastward는 스토리 장면에서 **상하 레터박스로 화면을 좁혀 집중**시키고, 마을에서는 HUD를 최소화한다. 일시정지 메뉴의 배경 처리(블러·디밍)는 확인하지 못했다.

### Cited Findings
- [관찰] D1 퀘스트 목록 패널은 짙은 갈색 반투명(샘플 ≈ 38~64, 21~40, 13~14)으로 뒤쪽 나무 기둥·조명 번짐이 비친다. 금액 패널은 거의 순흑이라 불투명에 가깝다. 하단 탭 바는 게임 영역과 분리된 어두운 띠. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] E3 Ammo/Bomb, E2 우상단 재화 띠는 어두운 남색 반투명 슬래브(뒤 배경이 희미하게 비침). — observed in screenshot [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)
- [관찰] E1 컷신은 1920×1080 화면에서 위 79px·아래 80px 검은 레터박스(각 약 7.4%)를 두고 HUD를 숨긴다. D3(Dave 컷신)도 상하 검은 띠가 있다. — observed in screenshot [E1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_2c7516dbcfba035a359a2eb7257356809a3f5eaa.1920x1080.jpg), [D3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_d1c0a418890d7dce6fc1ef88e0ab038c12ca69d7.1920x1080.jpg)
- [출처, 플레이어 체험기 — 출시 전 48시간 데모 기준] Eastward는 일반 2D 어드벤처의 "立绘+下方对话框"(초상 일러스트 + 화면 아래 대화창) 대신 캐릭터 자체 애니메이션과 "漫画式的对话框"(만화식 말풍선)를 쓰며, "这也是HUD设计需要简洁的原因"(그래서 HUD가 간결해야 한다). 스토리 강조를 위해 "在上下方增加黑边"(상하 검은 띠)하거나 카메라를 옮기거나 확대한다. 마을(대댐 시)에서는 생명력 바와 우상단 재화만 보이고, 전투 가능한 맵에 들어가야 전체 상태 바가 뜬다. — [TapTap 체험기](https://www.taptap.cn/moment/15230291522095848)

### Inferences
- 반투명은 "정보 목록처럼 넓은 패널"에만, 작은 핵심 숫자 패널은 불투명에 가깝게(Dave) — 넓은 패널이 장면을 가리는 부담은 줄이고 핵심 숫자 대비는 지킨다.
- **상황별 HUD(contextual HUD)**: 안전 구역에서는 최소 정보만, 전투에서만 전체 정보(Eastward). 정보가 많은 TD/마을 경영 게임에서도 "지금 필요한 정보만" 원칙이 적용 가능.
- 스토리/보스 등장 연출에는 레터박스로 HUD를 걷고 화면 비율을 바꿔 "모드 전환"을 알린다.

### Gaps
- 두 게임의 일시정지/메뉴 화면에서 배경을 얼마나 어둡게 하는지, 블러·디더링을 쓰는지 확인하지 못했다(해당 스크린숏 없음, 문헌 없음).
- 반투명 패널의 정확한 불투명도(알파 값)는 알 수 없다.

## 6. 아이콘·정보 밀도·경영/스탯 정보 배치·UI 모션과 피드백

### Takeaway
Dave는 경영 정보를 **화면 네 귀퉁이와 하단 탭 바로 밀어내고 중앙은 비워 두며**, 메뉴 전체를 **"스마트폰 앱"이라는 익숙한 은유**로 묶어 정보량을 관리한다. 새 콘텐츠는 빨간 "N" 배지, 선택 탭은 밝게·비선택은 어둡게 한다. 피드백 측면에서는 약 20분 분량의 픽셀 애니메이션 보상 컷이 있다. Eastward는 HUD 자체를 최소화하고 정보를 왼쪽 아래 한 덩어리 + 오른쪽 위 재화로 모은다.

### Cited Findings
- [출처, 분석 글] Dave는 메뉴를 스마트폰 안에 넣었고, 플레이어가 이미 폰 사용법을 알기 때문에 메뉴 탐색 학습 부담이 줄어든다는 분석. 처음에는 많은 앱이 잠겨 있어 앞으로 열릴 콘텐츠를 미리 보여 준다. 앱 목록: Weapon Shop, iDiver, Cooksta, To-Do, Call, Mail, FarmNow, Calendar, Management, Marinca, Weather, Music, Minigames, Album, Tips, Game Settings, Ecowatcher, FishMon, Calculator. — [Naavik](https://naavik.co/deep-dives/dave-the-diver-nexons-approach-to-fun-first/)
- [출처, 분석 글] 스토리·부가 시스템 보상으로 약 20분 분량의 픽셀 아트 애니메이션이 있고, Cooksta 등급을 올리거나 요리를 개발·강화하거나 무기를 만들거나 VIP를 대접하면 그날 처음 한 번 짧은 연출이 나온다. 디렉터 황재호가 "using a mobile lens"로 설계 결정을 했다고 말했다(팟캐스트 14분 무렵이라고 인용, 원음 미확인). — [Naavik](https://naavik.co/deep-dives/dave-the-diver-nexons-approach-to-fun-first/)
- [관찰] D1 정보 배치: 좌상단 = 금액 + 퀘스트 2개, 중앙 상단 = 프로필 초상 + Cooksta 좋아요 진행바 "0/500", 우상단 = 날짜 "Tue 10. 25" + 날씨 아이콘 + 하루 단계 시계 다이얼 + "Time Skip" 버튼 안내, 우측 = 조리 진행 바 2개, 하단 = 폰 아이콘 + 5개 탭(Menu·Research·Staff·Ingredients·Interior, 각각 아이콘 위·라벨 아래) + LB/RB 탭 전환 표시. 화면 중앙(카운터·손님)은 HUD가 비어 있다. 하단 탭은 선택된 "Menu"만 밝고 나머지 아이콘은 한 톤 어둡다. 새 항목은 빨간 원 "N", 알림은 노란 원 "i". 버튼 프롬프트(A/B/X/Y)가 해당 동작 옆에 붙는다. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] D1 하단 탭 아이콘(초밥, 냄비, 직원, 생선, 신사)은 음영이 들어간 일러스트형 아이콘으로, 단색 실루엣 아이콘이 아니다. — observed in screenshot [D1](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1868140/ss_783e1f6c2d4c358fb494d055c47c0e888922abd5.1920x1080.jpg)
- [관찰] E2·E3 HUD는 왼쪽 아래(초상 + 게이지 2 + 하트 10 + Ammo/Bomb)와 오른쪽 위(재화)의 두 덩어리뿐이고 나머지 화면은 비어 있다. 하트는 찬 것/빈 것을 색으로만 구분. — observed in screenshot [E3](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/977880/ss_d33bc97134437987ed89194d04b39f2e4658df20.1920x1080.jpg)
- [출처, 체험기] Eastward HUD 초상에 대해 "如果人物头像可以随着血量改变会很有意思"(초상이 체력에 따라 바뀌면 재밌겠다), 존의 초상이 "非常有斗志"(투지가 넘쳐 보인다) — 초상이 감정 표현 요소로 쓰인다는 플레이어 인상. — [TapTap 체험기](https://www.taptap.cn/moment/15230291522095848)

### Inferences
- 정보가 많은 경영 화면의 해법은 "화면 가장자리 + 하단 탭 + 메뉴는 별도 은유(폰) 속으로". 중앙 플레이 영역에는 월드 안 말풍선(주문 아이콘)처럼 **대상 바로 위에 붙는 작은 아이콘**만 둔다.
- 선택/비선택을 밝기로, 새 것을 작은 고채도 배지로 표시하는 등 **상태 표현 규칙이 몇 개 안 되고 반복된다**.

### Gaps
- Dave 스마트폰 화면, 레시피·직원 관리 창 등 밀도 높은 메뉴 화면의 실제 레이아웃은 스크린숏이 없어 관찰하지 못했다.
- 두 게임의 UI 트윈(열림/닫힘 애니메이션 시간, 숫자 카운트업 등)은 영상 분석 없이는 확인 불가.

## 7. 개발자 발언(UI 결정 이유)과 평론·플레이어 평

### Takeaway
UI 자체를 다룬 공식 개발자 발언은 두 게임 모두 거의 없다. Dave는 "스마트폰 은유"와 "모바일 관점 설계"가 분석 글로 알려졌고, PC·Steam Deck에서 UI 크기를 키우는 업데이트가 나올 만큼 **UI 크기·조작성 불만**이 있었다. Eastward는 픽셀 아트 칭찬은 일관되지만 **대화창 분량·스킵 불가, 요리 메뉴 등 UI 불편**이 반복 비판된다.

### Cited Findings
- [출처, 검색 요약] Dave의 대규모 QoL 업데이트에서 PC·Steam Deck용으로 UI 크기를 조정하고 인벤토리 정렬, 메뉴 탐색 개선을 넣었다(본문은 불러오지 못함). — [PC Gamer](https://www.pcgamer.com/dave-the-diver-gets-a-major-quality-of-life-update-and-the-players-love-it-tears-in-my-eyes-one-dedicated-fan-says); [TechRadar](https://www.techradar.com/gaming/charming-indie-dave-the-diver-receives-huge-quality-of-life-update)
- [출처, 검색 요약] 리뷰: Dave의 인터페이스는 "functional and intuitive"하고 화면을 어지럽히지 않고 필요한 정보를 보여 준다. UI 요소가 사라지는 버그가 가끔 보고됐다. — [Exputer 리뷰](https://exputer.com/reviews/dave-the-diver/)
- [출처, 검색 요약] Steam 한국어 커뮤니티 팁 글: 스시집 직원 배치 창에서 아래쪽 서빙 메뉴가 마우스로 클릭되지 않아 방향키(WASD)로 옮겨 골라야 했다 — 마우스 조작 불편 사례. — [Steam 커뮤니티](https://steamcommunity.com/app/1868140/discussions/0/3496509339504519566/?l=koreana)
- [출처, 검색 요약] 모바일판 리뷰: 메뉴가 "more cumbersome than the actual gameplay at times". — [Boss Rush](https://bossrush.net/2026/10/game-review-dave-the-diver-makes-a-splash-on-mobile/)
- [출처] 디렉터 황재호는 픽셀 아트를 쓴 이유 중 하나로 "fun and adventure"의 세계를 픽셀 아트의 엉뚱함으로 전하고 싶었다고 말했다(검색 요약; UI 직접 언급 아님). — [GamingBible 인터뷰](https://www.gamingbible.com/features/dave-the-diver-game-director-interview-338705-20231103)
- [출처] Eastward 미술 스타일을 정하는 데 초기 반년을 썼고, 캐릭터는 일본 셀화풍을 참고했다. — [Sohu/7.GAME](https://www.sohu.com/a/511158455_121119410)
- [출처, 검색 요약] Eastward 리뷰: 대화는 선택지가 없고 "can't be efficiently skipped"(Entertainium); 대화창을 연타로 넘기는 순간이 "friction the game never overcomes"(GamesHub); 대화를 버튼으로 빨리 넘길 수 없다(Maxi-Geek, 다만 비주얼·조작은 장점으로 꼽음); NME 리뷰 제목은 "doesn't know when to stop talking", 동적 조명·HD 디테일로 SNES 고전보다 화려하다고 평가. — [Entertainium](https://entertainium.co/2021/10/15/eastward-review/); [GamesHub](https://www.gameshub.com/news/reviews/eastward-game-review-a-gorgeous-homage-to-a-beloved-era-4463/); [Maxi-Geek](https://www.maxi-geek.com/con/eastward-review); [NME](https://www.nme.com/reviews/game-reviews/eastward-review-an-artful-ode-to-classic-jrpgs-that-doesnt-know-when-to-stop-talking-3045111)
- [출처, 신뢰도 낮음 — 소규모 리뷰 사이트] Eastward 요리 메뉴가 "clunky", "UI quirks"를 단점으로 꼽음. — [Best Game Collections](https://bestgamecollections.com/eastward-review-dense-pixel-charm-flaws/)
- [출처] Lost in Cult의 "The Making of Eastward: Design Works" 다큐/아트북이 있지만, Chucklefish 공지 글에는 UI 내용이 없다. — [Chucklefish 블로그](https://chucklefish.org/blog/the-making-of-eastward-design-works-part-1/)

### Inferences
- 상용작에서도 "UI가 작다·마우스로 안 눌린다" 같은 **크기·입력 문제**가 출시 뒤 패치 대상이 됐다 → 비주얼 완성도와 별개로 UI 크기·클릭 영역·입력 방식 일관성이 체감 품질을 크게 좌우한다.
- 대화·텍스트가 많은 게임은 스킵/빨리 넘기기 같은 텍스트 흐름 제어가 없으면 비주얼이 좋아도 UI 비판을 받는다(Eastward).

### Gaps
- NDC·GDC에서 두 게임 UI를 주제로 한 발표는 찾지 못했다. Inven·디스이즈게임·게임메카·게임샷의 Dave UI 관련 기사도 찾지 못했다.
- Dave QoL 업데이트의 날짜·버전, UI 크기 조정의 구체적 수치는 기사 본문을 불러오지 못해 확인하지 못했다.
- Eastward: Design Works 아트북·다큐에 UI 설명이 있는지 확인하지 못했다.
