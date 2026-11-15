# 추가 레퍼런스: 정보가 빽빽한 도트 게임 UI (Into the Breach · Loop Hero · CrossCode · Sea of Stars)

> 표기 규칙: **[출처]** 는 개발자 발언·문서·리뷰가 직접 밝힌 사실, **[스크린샷 관찰]** 은 공식 Steam 스크린샷을 내려받아 직접 본 것(관찰자 해석 포함)이다. 색 코드는 JPEG 스크린샷 영역을 median-cut 6색으로 줄여 뽑은 **근사값**(압축 잡음 포함)이라 정확한 팔레트 값이 아니다.
>
> 내려받은 스크린샷(공식 Steam 스토어 이미지):
> - ITB-1 (전투 화면, 실제 파일 1280×720): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_6113590509c195f98fa64cd738df534762e0c358.1920x1080.jpg
> - ITB-2 (섬 지도·임무 브리핑, 1280×720): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_82cfc5241c4a093091fbd7d2e124a52a57930527.1920x1080.jpg
> - LH-1 (Loop Hero 원정 화면, 1920×1080, 화면에 "LOOP HERO v0.928" 표기 = 출시 전 빌드): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_500e7212653fa6586f7a84c89b4c60be4e425fbb.1920x1080.jpg
> - LH-2 (Loop Hero 건물 메뉴, 1920×1080): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_455789884ed94fd20410ac5a139e8c3bb8f6f369.1920x1080.jpg
> - CC-1 (CrossCode 타이틀, 실제 파일 1136×640): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/368340/ss_5bf282c8d5bef2f479b7e55aed91118245ad213b.1920x1080.jpg
> - SoS-1 (Sea of Stars 필드, 1920×1080 — UI가 거의 없어 UI 분석에는 쓸모없었음): https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1244090/ss_c250a7fd789b3cbab5ca8e99e3530cf933656ad1.1920x1080.jpg

## Q1. UI 호평과 설계 근거 문서가 가장 탄탄한 3~4개 게임은 무엇이고, 왜 골랐나

### Takeaway
설계 근거가 문서로 남은 게임은 **Into the Breach**(개발자 인터뷰·GDC 2019 포스트모템, UI 명료성 원칙을 직접 말함), **CrossCode**(개발 블로그가 9-slice·전환 애니메이션 구현을 공개, 네이티브 568×320이라 요청자 게임의 640×360과 가장 가깝다), **Loop Hero**(포스트모템의 손그림 UI 목업, 밀도 높은 관리형 화면, 픽셀 폰트 가독성 논란과 대체 폰트 제공) 셋이다. **Sea of Stars**는 UI 호평은 있지만 개발자의 UI 설계 발언을 찾지 못해 보조 사례로만 남긴다.

### Cited Findings
- **Into the Breach (Subset Games, 전략·턴제, 정보 밀도 최상)**: 공동 디자이너 Justin Ma가 UI 설계에 대해 "As a game design principle, we would sacrifice cool ideas for the sake of clarity every time."라고 말했다 — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- Subset Games 공동 창업자 Matthew Davis가 GDC 2019에서 "'Into the Breach' Design Postmortem"을 발표했고, 영상은 GDC 공식 YouTube에 무료로 공개됐다(검색 요약 기준, 영상 내용은 직접 보지 못함) — [GDC Vault 세션 페이지](https://www.gdcvault.com/play/1026333/contactUs), [GDC 뉴스](https://www.gdconf.com/news/get-inside-look-making-breach-gdc-2019), [Game Developer 영상 소개](https://www.gamedeveloper.com/design/video-how-subset-games-designed-i-into-the-breach-i-)
- **CrossCode (Radical Fish Games, 액션 RPG, 메뉴·HUD 밀도 높음)**: 개발사가 블로그 글 "CrossCode – How to GUI System"에서 GUI 그리기(NinePatch)·전환 애니메이션 구조를 공개했다 — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- CrossCode의 네이티브 해상도는 568×320(71:40, 16:9에 거의 같음)이고, 정수 배율로 2×=1136×640, 3×=1704×960, 4×=2272×1280을 쓴다(PCGamingWiki 내용을 미러 페이지 검색 요약으로 확인. 2018년 Steam 토론 하나는 570×320이라 적었으나 반올림으로 보임) — [PCGamingWiki](https://www.pcgamingwiki.com/wiki/CrossCode), [Steam 토론](https://steamcommunity.com/app/368340/discussions/1/1729837292642203950)
- **Loop Hero (Four Quarters, 덱빌딩+관리, 자원·인벤토리·카드가 한 화면)**: 포스트모템에 지도·인벤토리·카드 시스템을 담은 손그림 첫 목업("First game mockup with decryption")이 실려 있다 — [Game Developer 포스트모템](https://www.gamedeveloper.com/design/postmortem-loop-hero)
- Loop Hero는 픽셀 폰트 가독성 지적을 받았고, 리뷰에 따르면 정식판에 고해상도 대체 폰트와 난독증 친화 폰트가 들어갔다 — [Phenixx Gaming 리뷰](https://phenixxgaming.com/2021/03/05/loop-hero-pc-review), [Impulse Gamer 리뷰](https://www.impulsegamer.com/loop-hero-review)
- **Sea of Stars (Sabotage Studio, 턴제 JRPG)**: 전투 UI가 "sleek"하고 게임의 외형에 잘 맞는다는 평이 있다. 다만 이 출처는 짧은 클립 소개 기사다 — [Twinfinite](https://twinfinite.net/ps4/sea-of-stars-video-combat-ui/)
- Sea of Stars의 UI 설계나 아트 디렉션을 다룬 개발자 인터뷰는 검색으로 찾지 못했다. 찾은 인터뷰는 대부분 레벨 디자인이나 향수 이야기다 — [MobileSyrup 인터뷰](https://mobilesyrup.com/2023/09/11/sea-of-stars-level-design-sabotage-studio-thierry-boulanger-interview/), [RPG Site 인터뷰](https://www.rpgsite.net/interview/14807-developer-debrief-chatting-with-the-mind-behind-sea-of-stars)

### Inferences
- 요청자 게임(타워 디펜스·마을 관리, 640×360, 정보가 많은 HUD)에 가장 가까운 것은 **Into the Breach**(전략·적 의도 표시·툴팁 밀도)와 **Loop Hero**(자원·건물·인벤토리 관리 화면)다. **CrossCode**는 장르보다 기술 조건이 가장 가까운 사례다. 568×320 네이티브에 정수 배율이라 640×360·정수 배율 구성과 같은 문제(작은 캔버스 안에 9-slice 프레임과 픽셀 텍스트 넣기)를 풀었다.
- 세 게임은 UI 해상도 전략이 서로 달라 비교 축이 된다. Into the Breach는 하이브리드(픽셀 아트 + 매끈한 본문 폰트), Loop Hero는 전부 픽셀(대체 고해상도 폰트는 옵션), CrossCode는 네이티브 픽셀 GUI다(아래 Q2).

### Gaps
- 후보 목록의 Chained Echoes, Dead Cells, Hyper Light Drifter, Shovel Knight, Moonlighter, Kingdom Two Crowns, Dome Keeper, Octopath Traveler는 조사 시간 한도로 다루지 못했다. 이들의 UI 설계 근거 문서가 더 나은지 비교하지 못했다.
- GDC 2019 Into the Breach 포스트모템 영상과 슬라이드 원문은 보지 못했다(Vault 페이지가 열리지 않았고 영상은 텍스트 도구로 볼 수 없음). UI 관련 세부 발언이 더 있을 수 있다.
- Game UI Database(gameuidatabase.com)의 해당 게임 페이지는 열어 보지 못했다.

## Q2. 게임별 분석: 네이티브 픽셀 vs 고해상도 UI, 팔레트, 프레임·테두리, 폰트, 반투명 패널, 아이콘, 정보 위계와 밀도, 모션·피드백

### Takeaway
정보가 많은 세 게임 모두 **게임 필드는 가운데 비워 두고 UI는 화면 가장자리의 고정 구역(상단 바·측면 열·모서리)에 둔다.** 패널은 **어둡고 불투명한 단색 바탕에 얇은 단색 테두리**를 쓰고(반투명은 확인되지 않음), 채도 높은 색은 **의미(위험·자원·부족·완료)에만** 남긴다. 상세 정보는 커서를 따라다니는 말풍선 대신 **고정 위치의 정보 패널**(ITB 오른쪽 아래, Loop Hero 오른쪽 열)에 띄운다. 폰트 전략은 갈린다. ITB는 짧은 라벨만 픽셀 디스플레이 폰트로 쓰고 문장은 매끈한 산세리프로 쓴다. Loop Hero는 전부 픽셀 폰트지만 가독성 불만을 받아 대체 폰트를 넣었다.

### Cited Findings

#### Into the Breach: [출처]
- 기능 채택 기준: "If it can be shown in a clear way, [then] yes, we can have that." 플레이어가 모든 상황을 이해해야 한다는 요구가 "restricted our game design options considerably"였다고 했다 — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- 초기에는 "You could just see all these damage indicators all over the map" 같은 상태였고, 팀은 알아봤지만 새 플레이어에게는 불명확했다. 외부에 보여 준 뒤에는 "who was doing what"을 분명히 해야 했다 — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- 무기 툴팁은 **애니메이션으로** 무기 효과를 보여 주고, 가장 적절한 유닛으로 시연한다. Ma는 이것이 설명문보다 "a thousand times more effective"이고 이 문제에서 "the most important decision we made"였다고 했다. 플레이테스터가 무기 설명 세 문장을 읽고도 이해하지 못한 일이 계기였다 — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- 적이 다음 행동을 미리 알려 준다(telegraph). 그래서 매 판이 풀어야 할 퍼즐처럼 된다 — [Game Informer 리뷰](https://gameinformer.com/games/into_the_breach/b/pc/archive/2018/02/26/game-informer-review-into-the-breach), [Game Developer IGF 기사](https://www.gamedeveloper.com/game-platforms/road-to-the-igf-subset-games-i-into-the-breach-i-)
- 지도 하나가 한 화면에 다 들어가 지형을 한눈에 파악할 수 있다(검색 요약에서 본 문장, 원문 위치는 확인하지 못함. 아래 스크린샷 관찰과 일치) — [Game Developer IGF 기사](https://www.gamedeveloper.com/game-platforms/road-to-the-igf-subset-games-i-into-the-breach-i-)
- 리뷰: "there aren't any extraneous elements that distract from the UI" — [Newsweek](https://www.newsweek.com/entertainment/video-games/breach-mods-soundtrack-mobile-nintendo-860670)
- UI 폰트 이름은 공개 자료에서 찾지 못했다(검색에 걸린 것은 로고 서체 추정뿐) — [HyperPix(로고 서체 추정, 비공식)](https://hyperpix.net/fonts/into-the-breach-font/)

#### Into the Breach: [스크린샷 관찰] (ITB-1, ITB-2)
- **해상도 방식(하이브리드)**: 지형·유닛·초상화는 픽셀 아트다. UI 텍스트는 두 종류다. (a) "End Turn", "POWER GRID", "GRID DEFENSE", "Bonus Objectives", "Rust District", "WIND STORM", "RESET USED" 같은 **짧은 라벨·제목·숫자는 각진 픽셀풍 디스플레이 폰트**, (b) "Chasm Tile / Ground units pushed in will be destroyed.", 대사 상자 문장, "Victory in 1 turn" 같은 **문장은 안티에일리어싱된 둥근 산세리프**다. 이 산세리프는 픽셀 격자를 따르지 않는 고해상도 텍스트로 보인다 — observed in screenshot ITB-1, ITB-2
- **팔레트**: 패널 바탕은 거의 검은 남색(근사 #0c0f16, 패널 면적의 60~75%)이다. 테두리는 채도 낮은 강철 파랑·회색 1~2px 선이다. 채도 높은 색은 의미에만 쓴다. 주황 = 파워 그리드 칸, 초록 = 완료한 보너스 목표(취소선)와 체력 칸, 빨강·분홍 빗금 = 적 공격 예정 칸, 빨강 = 위협 지역 제목, 노랑 = 경고("WIND STORM"), 흐린 빨강 = 써 버린 버튼("RESET USED") — observed in screenshot ITB-1, ITB-2(색 근사는 영역 양자화)
- **프레임·테두리**: 모서리는 둥글리지 않은 직각이다. 장식 없는 얇은 단색 외곽선이 기본이고, 일부 패널에만 깎인 모서리 탭(예: "Bonus Objectives" 사다리꼴 머리표, 접기 화살표 탭)이 있다. 임무 브리핑 패널은 텍스트 칸과 지도 미리보기 칸이 하나의 외곽선으로 이어진 L자 결합형이다 — observed in screenshot ITB-1, ITB-2
- **반투명**: 패널은 **불투명**으로 보인다. ITB-2의 패널 아래에는 부드러운 어두운 드롭 섀도가 있다. 반투명 유리 패널은 보이지 않는다 — observed in screenshot ITB-2
- **아이콘**: 단색 선 아이콘(별 = 보너스, 번개 = 전력, 방패형 = 경고)을 텍스트 앞에 붙인다. 구분선 가운데에 작은 대문자 라벨을 넣는 섹션 머리("— BONUS OBJECTIVES —", "— WARNING! —")가 있다 — observed in screenshot ITB-2
- **정보 위계·밀도**: 네 모서리에 나눠 둔다. 왼쪽 위 = 자원(파워 그리드 칸·방어율 %)과 가장 큰 버튼 "End Turn" + 비활성 회색 "UNDO MOVE". 왼쪽 열 = 조종사·메크 초상 3장과 작은 체력 칸. 왼쪽 아래 = 선택 유닛 이름·초상. 오른쪽 위 = 승리까지 남은 턴("Victory in **1** turn", 숫자만 크게)과 보너스 목표. 오른쪽 아래 = 마우스를 올린 칸의 정보 패널(제목 + 한 줄 설명). 가운데 전장은 아무것도 가리지 않는다. 8×8 지도 전체가 한 화면에 들어간다 — observed in screenshot ITB-1
- **비활성·사용함 상태**: 비활성 버튼은 회색 글자, 쓴 버튼은 채도를 낮춘 빨강 글자로 바꾸고 패널 형태는 그대로 둔다 — observed in screenshot ITB-1

#### Loop Hero: [출처]
- 포스트모템의 첫 손그림 목업에 지도·장비·HP/LVL 바·스탯·인벤토리·카드 영역이 번호 주석과 함께 있다. 화면 영역 구성이 초기 목업 단계에서 정해졌다 — [Game Developer 포스트모템](https://www.gamedeveloper.com/design/postmortem-loop-hero)
- 인벤토리가 차면 새 아이템을 주울 때 가장 오래된 아이템이 사라진다. "This way the inventory will fill up, but not clutter." 카드 손패도 같은 규칙이다(규칙으로 화면 혼잡을 막은 사례) — [Game Developer 포스트모템](https://www.gamedeveloper.com/design/postmortem-loop-hero)
- 베타 피드백이 "UI and UX" 개선에 크게 도움이 됐다. 막판 크런치에 패널을 다시 그리는("redraw this panel") 작업이 있었다. 아티스트 한 명은 자동 일시정지 톱니바퀴의 빛 줄무늬 셰이더에 하루를 썼는데, 그 기능은 "very few people even know about" — [Game Developer 포스트모템](https://www.gamedeveloper.com/design/postmortem-loop-hero)
- 픽셀 폰트가 읽기 어렵다는 플레이어 지적이 있었다. 리뷰는 정식판의 고해상도 대체 폰트와 난독증 친화 폰트를 칭찬했다("Loop Hero does what is so simple but 99.99999% of pixel graphic games simply don't do: Dyslexic-friendly fonts") — [Phenixx Gaming 리뷰](https://phenixxgaming.com/2021/03/05/loop-hero-pc-review), [Impulse Gamer 리뷰](https://www.impulsegamer.com/loop-hero-review)
- 2021년 Steam 토론에 따르면 게임 fonts 폴더에 고해상도 폰트 파일 Roboto-Bold가 들어 있었고, 사용자들이 이를 다른 폰트로 바꿔 끼웠다(비공식 수정, 데모 기준) — [Steam 토론](https://steamcommunity.com/app/1282730/discussions/0/3112522283873831459)
- Family Gaming Database는 Loop Hero 접근성 기능 17개를 기록했고 "Large Text"가 포함된다 — [Family Gaming Database](https://www.familygamingdatabase.com/accessibility/Loop+Hero)

#### Loop Hero: [스크린샷 관찰] (LH-1, LH-2)
- **해상도 방식(전부 픽셀)**: 프레임·버튼·아이콘·**텍스트까지** 모두 픽셀 아트로 보인다. 제목("EXQUISITE MIRROR", "VILLAGE", "BUILDING MENU", "GYMNASIUM")은 장식적인 대문자 픽셀 폰트, 본문("FIRST, THEY'LL FEED YOU…", "· HEALS 40 HP UPON ENTERING.")은 더 작은 대문자 픽셀 폰트다. 전부 대문자다 — observed in screenshot LH-1, LH-2
- **팔레트**: 바탕은 거의 검정이고, 프레임은 회색 돌·금속 계열(근사 #787f7e, #5f6360, #454948, 하이라이트 #adafa7)이다. 강조색은 **짙은 적갈색(옥스블러드)** 하나로 툴팁 패널과 건물 메뉴 바탕에 쓴다(근사 #6c261a~#722b20). 연결선과 선택 테두리에 노랑·금색을 조금 쓴다. 전체가 채도를 낮춘 제한 팔레트다 — observed in screenshot LH-1, LH-2(색 근사는 영역 양자화)
- **프레임·테두리**: 두꺼운 돌·금속 베벨 프레임이다. 위·왼쪽은 밝고 아래·오른쪽은 어두운 일관된 광원이고, 모서리를 깎은 팔각형 버튼, 오른쪽 열 상단의 해골 장식 같은 모서리 장식이 있다. 같은 프레임 부품이 크기만 바뀌어 반복되는 것으로 보아 9-slice식 재사용으로 보인다(관찰자 추정) — observed in screenshot LH-1, LH-2
- **반투명**: 모든 패널이 불투명하다. 화면 전체에 CRT식 비네팅·주사선 느낌의 필터가 얇게 덮여 있다(가장자리가 어두워짐) — observed in screenshot LH-1, LH-2
- **정보 위계·밀도**: 상단 바 = 체력·시간 바, 배속, 현재 단계 라벨("PLANNING", 가운데 큰 글자), 자원 수, 라운드·적 레벨. 오른쪽 열 = 장비 칸, HP 숫자 바("447 / 591"), 4×3 인벤토리 격자, 그 아래 고정 툴팁 패널(제목 → 짧은 맛글 → 구분 장식 → "·" 글머리 효과 목록). 아래쪽 = 카드 손패 가로 한 줄(그림 + 이름 라벨). 왼쪽 위 = 선택 아이템 이름. 가운데 지도는 비워 둔다 — observed in screenshot LH-1
- **숫자 배지**: 아이템 칸 왼쪽 아래 모서리에 레벨 숫자를 겹친다. 건물 메뉴의 비용은 "자원 아이콘 + 어두운 바탕 배지 속 숫자"로 세로로 쌓는다. **부족한 자원은 숫자만 빨강**("10/11", "12/14", "3/6")이고 충분하면 흰색이다 — observed in screenshot LH-2
- **선택 표시**: 고른 건물 카드에 밝은 점선·장식 테두리를 한 겹 더 두른다. 건물 사이 해금 관계는 굵은 노랑 연결선으로 그린다 — observed in screenshot LH-2

#### CrossCode: [출처]
- GUI는 블록 픽셀을 그려야 하는데 HTML+CSS로는 "incredible hard"하고 확대한 HTML 이미지·텍스트는 흐려져서 canvas로 그린다 — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- **9-slice**: GUI 상자는 `ig.NinePatch` 클래스로 "define 9 areas of which a drawable piece is made of". 모서리는 늘리지 않고 변과 가운데만 요소 크기에 맞게 늘린다. 버튼은 가로로만 늘면 되므로 **3분할** 변형을 쓴다. 설정 값은 width·height·left·top·right·bottom이다 — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- **폰트**: 기본 폰트 클래스를 확장해 **글줄 안에 아이콘을 그린다**. 텍스트는 canvas에 미리 그려 두고 쓴다("saves a huge amount of draw calls"). 폰트 제작 방법은 글에 없다 — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- **모션**: 요소마다 상태(offsetX/Y, alpha, scaleX/Y, angle)와 이름 붙은 전환을 둔다. 전환 기본 시간은 0.5초이고, 베지어 이징("Key Splines", 기본 `KEY_SPLINES['EASE']`)으로 상태 사이를 보간한다. "We basically copied the same system CSS uses." — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- **반투명**: 요소마다 alpha 상태(기본 1)가 있고 부모에서 자식으로 globalAlpha가 곱해진다. 구체적 반투명 UI 사례는 글에 없다 — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- **레이아웃**: 일부러 단순하게 만들었다. 부모 기준 상대 위치에 왼·오·위·아래·가운데 정렬만 있다("There are not complex layout systems or anything.") — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- 메뉴의 상태 표시 패널은 플레이 중의 작은 상태 HUD에서 **동적으로 펼쳐져** 커진다(검색 결과 발췌, 원문 페이지는 403으로 열지 못함) — [CrossCode Weekly Update 31](https://www.moddb.com/games/crosscode/news/weekly-update-31-menu-progress)
- 장비 메뉴 애니메이션은 탐색 중 메뉴 요소가 어색하거나 엉뚱한 자리에 있는 것처럼 보이지 않게 맞추느라 시간이 많이 들었다(검색 발췌) — [CrossCode Weekly Update 36](https://www.moddb.com/news/weekly-update-36-time-for-some-changes)

#### CrossCode: [스크린샷 관찰] (CC-1)
- 공식 스크린샷 파일이 1136×640, 곧 네이티브 568×320의 정확히 2배라서 정수 배율로 캡처된 것과 일치한다. 타이틀의 "Press to start"는 픽셀 폰트이고 그 아래 1px 가로 구분선과 외곽선만으로 그린 패드·키보드 아이콘이 있다. 장식을 줄인 선 위주 구성이다 — observed in screenshot CC-1
- (전투 HUD·메뉴 스크린샷은 내려받기 한도로 보지 못했다.)

#### Sea of Stars: [출처] (보조 사례, 개발자 UI 발언 없음)
- 적 머리 위의 "Locks" 아이콘이 차지 공격을 끊으려면 어떤 피해 유형이 필요한지 보여 준다(검 아이콘 = 베기, 망치 아이콘 = 타격). 잠금을 모두 깨면 적의 기술이 취소된다 — [Analog Stick Gaming 리뷰](https://www.analogstickgaming.com/game-reviews/2023/8/28/sea-of-stars), [Sea of Stars 팬 위키](https://seaofstars.fandom.com/wiki/Combat), [RPGFan 리뷰](https://www.rpgfan.com/review/sea-of-stars/)
- 적 아이콘은 약점과 **행동까지 남은 턴 수**도 보여 준다. 타이밍 입력 성공을 섬광으로 보여 주는 유물(Sequent Flare)이 있다 — [Can I Play That? 접근성 리뷰](https://caniplaythat.com/2023/11/01/sea-of-stars-accessibility-review/)

### Inferences
- **"고정 구역 + 가운데 비우기"**: ITB와 Loop Hero 모두 UI를 가장자리 고정 구역에 몰고 플레이 필드를 가리지 않는다. 툴팁도 따라다니는 말풍선 대신 고정 패널로 띄운다. 타워 디펜스처럼 필드를 계속 봐야 하는 장르에서 아마추어 UI가 흔히 빠지는 "필드 위에 떠다니는 패널" 문제를 피하는 직접 사례다.
- **색은 의미 전용, 크롬은 무채색**: ITB는 패널 크롬을 거의 단색 남흑으로 두고 빨강(위협)·주황(자원)·초록(완료·체력)·노랑(경고)만 의미에 쓴다. Loop Hero는 회색 프레임 + 옥스블러드 한 가지 강조 + 부족분만 빨강 숫자다. 둘 다 "UI 크롬은 채도가 낮고, 채도는 정보에 쓴다"는 같은 규칙으로 읽힌다(관찰 기반 추론).
- **반투명은 필수가 아니다**: 세 게임 모두 확인된 패널은 불투명이다(ITB는 드롭 섀도로 분리). 반투명 패널이 '완성도'의 조건은 아니라는 반례로 쓸 수 있다.
- **폰트 해상도 전략 두 갈래**: (1) ITB식 하이브리드 — 짧은 라벨·숫자는 픽셀 디스플레이 폰트, 문장(툴팁·대사)은 매끈한 고해상도 산세리프. (2) Loop Hero식 전부 픽셀 + 고해상도 대체 폰트 옵션. 한글 픽셀 폰트는 작은 크기에서 획이 뭉치기 쉬우므로 요청자 게임(한·영)에는 (1)이나 (2)의 '대체 폰트 옵션'이 현실적인 선택지로 보인다. Godot 4 `canvas_items` 모드에서 폰트가 실제 창 해상도로 래스터되는지는 다른 조사자의 Godot 동작 확인과 맞춰 봐야 한다(이 노트에서는 검증하지 않음).
- **640×360에서 네이티브 픽셀 GUI가 가능하다는 선례**: CrossCode는 568×320 캔버스 안에서 9-slice 상자 + 3분할 버튼 + 글줄 속 아이콘 + 0.5초 이징 전환으로 메뉴를 만들었다. 요청자의 640×360은 이보다 가로 72px, 세로 40px 넓다.
- **모션은 "어디서 왔는지" 보여 주기**: CrossCode의 HUD → 메뉴 펼침, ITB의 애니메이션 툴팁은 정적 텍스트 대신 움직임으로 관계와 효과를 설명한다. 아마추어 UI의 '갑자기 튀어나오는 패널'과 대비된다.

### Gaps
- Into the Breach의 UI 폰트 이름, 렌더 기준 해상도(픽셀 아트 배율)는 공개 출처로 확인하지 못했다. 스크린샷이 1280×720이라는 것만 확인했고, 픽셀 아트가 2배로 보이는 것은 눈대중 관찰이다.
- Loop Hero의 네이티브 해상도, 기본 픽셀 폰트 이름, 현재 버전의 폰트 옵션 메뉴 이름은 확인하지 못했다. Roboto-Bold는 2021년 Steam 토론 한 곳에서만 봤다.
- CrossCode의 폰트 제작 방식·이름, UI 색 팔레트, 전투 HUD 시각 구성은 출처도 스크린샷도 없다(타이틀 화면만 봄).
- Sea of Stars의 메뉴·전투 UI 시각 특성(프레임·폰트·반투명)은 UI가 담긴 스크린샷을 받지 못해 관찰하지 못했다. 개발자 UI 발언도 없다.
- 색 코드는 JPEG 영역 양자화 근사값이다. 실제 팔레트 값이나 팔레트 크기는 어느 게임도 출처로 확인하지 못했다.

## Q3. 디자이너가 직접 밝힌 구체적 교훈은 무엇인가

### Takeaway
가장 직접적인 교훈은 Into the Breach의 **"UI로 분명히 보여 줄 수 없으면 기능을 뺀다"**와 **"설명문 대신 움직이는 시연 툴팁"**이다. CrossCode는 **9-slice·3분할 재사용 부품, 단순한 상대 레이아웃, 기본 0.5초 이징 전환**이라는 구현 원칙을 남겼다. Loop Hero는 **규칙 설계로 화면 혼잡을 막고**, 픽셀 폰트 가독성 비판에 **대체 폰트로 답한** 사례다.

### Cited Findings
- Into the Breach — 명료성 우선: "we would sacrifice cool ideas for the sake of clarity every time." / "If it can be shown in a clear way, [then] yes, we can have that." — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- Into the Breach — UI를 설계의 경보로 쓴다: 명료성 때문에 디자인에 여러 제한(예: 한 행동이 거는 상태 효과 수 제한)을 걸었고, 아이디어가 UI로 전달하기에 너무 복잡하면 본질적으로 혼란스럽고 불필요하다는 뜻이며 "The UI is just always our first clue to that realization."이라고 했다(이 두 문장은 같은 기사 검색 발췌로 봤고, 본문 요약에서는 "restricted our game design options considerably"와 전달이 어려운 고유 무기·발사 패턴을 뺐다는 내용으로 확인했다) — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- Into the Breach — 시연 툴팁: 무기 효과를 애니메이션으로 보여 주는 툴팁이 설명문보다 "a thousand times more effective"이고 이 문제에서 "the most important decision"이었다. 세 문장짜리 설명을 읽고도 이해하지 못한 플레이테스터가 계기였다 — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- Into the Breach — 개발자 눈에 자명한 정보 표시("damage indicators all over the map")가 새 플레이어에게는 불명확했고, 외부 플레이테스트에서 "who was doing what"을 보이게 고쳐야 했다 — [Game Developer](https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-)
- CrossCode — 확대한 HTML 이미지·텍스트는 흐려지므로 블록 픽셀을 유지하려고 canvas에 직접 그렸다. 상자는 NinePatch(모서리 고정), 버튼은 3분할이다. 레이아웃은 일부러 단순하게("not complex layout systems") 했고, 전환은 CSS식 상태 + 이징(기본 0.5초)이다 — [Radical Fish Games 블로그](https://www.radicalfishgames.com/?p=1594)
- CrossCode — 메뉴 애니메이션은 요소가 "어색하거나 엉뚱한 자리"로 보이지 않게 맞추느라 시간이 오래 걸렸다(검색 발췌) — [CrossCode Weekly Update 36](https://www.moddb.com/news/weekly-update-36-time-for-some-changes)
- Loop Hero — 인벤토리는 가득 차도 오래된 것부터 사라져 "fill up, but not clutter". 베타 피드백이 UI/UX 개선에 크게 도움이 됐다. 아무도 모르는 장식 셰이더에 하루를 쓴 일을 '잘못된 점' 쪽에 적었다 — [Game Developer 포스트모템](https://www.gamedeveloper.com/design/postmortem-loop-hero)
- Loop Hero — 픽셀 폰트가 읽기 어렵다는 반응에 고해상도·난독증 친화 대체 폰트를 넣었고, 리뷰는 이를 대부분의 픽셀 게임이 하지 않는 일로 꼽았다 — [Phenixx Gaming 리뷰](https://phenixxgaming.com/2021/03/05/loop-hero-pc-review), [Steam 토론](https://steamcommunity.com/app/1282730/discussions/0/3112522283873831459)

### Inferences
- 요청자 게임에 옮기면 이렇다. (1) 화면에 분명히 그릴 수 없는 수치·상태(예: 겹치는 버프 여러 개)는 UI 문제이기 전에 설계 문제일 수 있다. (2) 영웅·용병 스킬 툴팁은 문장보다 짧은 시연이나 칸 표시(사거리·범위 하이라이트)가 효과적이다. (3) 상자·버튼을 9-slice/3분할 부품 몇 개로 통일하면 프레임 두께·모서리 모양이 화면마다 달라지는 문제(아마추어 티의 흔한 원인)를 구조적으로 막는다. (4) 패널 등장·전환에 일관된 이징과 짧은 시간을 쓴다.
- '학생 작품 같음'이라는 평에는 Into the Breach 사례가 시사점을 준다. 개발자 자신은 이해하는 표시(데미지 숫자 난립 등)가 외부인에게는 혼란이었다. 외부 플레이어 관찰로 "누가 무엇을 하는지"가 보이는지 확인하는 단계가 필요하다(측정 방식은 요청자 몫).

### Gaps
- Sea of Stars 개발진의 UI 아트 디렉션 발언(UI 아티스트 인터뷰 등)은 찾지 못했다.
- Into the Breach GDC 2019 포스트모템의 UI 관련 슬라이드·발언 원문은 확인하지 못했다.
- Loop Hero 개발자가 폰트 결정(기본 픽셀 폰트 선택, 대체 폰트 추가 이유)을 직접 설명한 자료는 찾지 못했다. 이 부분은 리뷰·커뮤니티 출처뿐이다.
