# 웹·GitHub 조사 근거 요약 (verified·partly·likely만, 274개)
전체(근거·검증 메모·출처 포함)는 같은 폴더 evidence_web.md. partly는 «※» 뒤에 무엇이 다른지 적었다.

## 화면 배치 (layout)
- [blizzard-16·verified] (StarCraft II) StarCraft II의 아래 HUD는 왼쪽 아래에 미니맵, 오른쪽 아래에 명령 카드를 두는 배치다.
- [blizzard-17·verified] (StarCraft II) 자유의 날개 2.0.4 패치에서 '군대 선택' 버튼이 새로 생겼고, 놀고 있는 일꾼 버튼·모든 차원 관문 선택 버튼과 함께 미니맵 바로 위에 모였다.
- [pixel_minimal-01·verified] (Dome Keeper) Dome Keeper의 HUD는 화면 왼쪽 아래 모서리를 원점으로 한 6px 격자에 HudElement 모듈을 자동 배치한다. 각 요소의 자리는 크기(격자 칸 수), layoutPriority(배치 순서), layoutWeights(가로·세로로 멀어질 때의 비용)로 정해진다.
- [pixel_minimal-02·verified] (Dome Keeper) 웨이브 미터(layoutWeights (0,1), 우선순위 0)와 돔 체력 막대(layoutWeights (0,1), 우선순위 1)는 화면 아래 가장자리를 따라 가로로 놓인다. 자원 카운터(layoutWeights (5,0), 우선순위 2)는 왼쪽 가장자리를 따라 위로 쌓인다.
- [pixel_minimal-24·verified] (Loop Hero) Loop Hero의 게임 화면(GameMaker 룸)은 640×360 픽셀이다. 공개 스크린숏은 이를 정수 3배로 키운 1920×1080이다.
- [pixel_minimal-25·verified] (Loop Hero) 원정 중 장비 격자는 화면 오른쪽 위에 있고, 640×360 기준 (608, 27)이 비어 있는 오른쪽 위 칸이다. 모드는 그 칸에 25px 정사각 버튼(s_expsquarebutton, 보통·호버·눌림 3프레임)을 넣고 그 안에 13px 아이콘을 그린다.
- [pvz_frostpunk-02·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 씨앗 카드의 x좌표는 레벨의 칸 수만으로 정해지는 고정 공식(7칸 이하면 85+59×칸 번호, 8칸 81+54×, 9칸 80+52×, 10칸 79+51×)이어서, 해가 모자라거나 재충전 중이어도 카드가 사라지거나 자리가 밀리지 않는다.
- [pvz_frostpunk-15·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 전투 화면 위쪽 HUD는 왼쪽부터 씨앗 바, 바로 오른쪽 삽 칸(x=456+늘어난 바 폭), 오른쪽 끝 메뉴 돌 버튼(x=681, y=-10, 117×46) 순서로 한 줄에 놓이고, 그 아래 화면은 잔디밭이 차지한다.
- [blizzard-30·partly] (StarCraft II) StarCraft II의 아래 콘솔 그림은 폭이 고정된 조각 3개가 16:9 화면에서 맞물리도록 되어 있어, 더 넓은 화면에서는 조각 사이가 어두운 띠로 빈다. ※ 인용된 저장소 README를 직접 읽었다. 콘솔은 미니맵·정보·명령 3D 모델 조각 3개이고, 화면 높이에 맞춰 크기가 정해진다. 각각 왼쪽 끝·가운데·오른쪽 끝에 붙고, 날개가 16:9에서만 맞물려 더 넓으면 틈이 생긴다. 하지만 같은 README가 SC2는 원래 화면을 16:9로 제한해 더 넓은 모니터에서는 양옆이 검은 띠가 된다고 적었다. 틈은 그 제…
- [td_bars-bt-01·partly] (Bloons TD 6) BTD6의 타워 구매 상점은 게임 코드에서 «InGame.RightMenu.ShopMenu», 곧 오른쪽 메뉴에 속하며, 배경으로 «TowersSidePanelBg» 스프라이트를 쓴다. ※ ShopMenuExt.cs가 Il2CppAssets.Scripts.Unity.UI_New.InGame.RightMenu 네임스페이스의 ShopMenu를 쓰므로 RightMenu 소속은 맞다. sprite-references에 IngameUi[TowersSidePanelBg_01~05]도 있다. 그러나 스프라이트 목록은 어느 UI가 그 스프라이트를 쓰는지 알…
- [tab-01·likely] (They Are Billions) They Are Billions의 HUD는 화면 아래쪽 띠에 모여 있고, 그 왼쪽 끝에 미니맵이, 바로 옆에 게임 안 날짜·시각 시계와 일시정지 버튼이 붙어 있다.
- [castle-09·likely] (Stronghold Crusader (원작)) 원작 Stronghold 계열은 800×600과 1024×768 두 해상도만 쓰도록 만들어져서, 와이드 모니터에서는 화면이 늘어나거나 양옆에 검은 띠가 생긴다는 플레이어 보고가 있다.

## 자원·상태 표시 (resources_status)
- [ironhide-08·verified] (Kingdom Rush 시리즈 (Vengeance·Alliance 캡션 ) Kingdom Rush 시리즈에서 생명·골드·웨이브 수는 화면 위쪽 구석에 한 덩어리로 나란히 표시되고, Alliance에서는 하트가 생명, 해골이 현재 웨이브와 버텨야 할 전체 웨이브 수를 나타낸다.
- [blizzard-13·verified] (Warcraft III (Classic/Reforged)) WC3는 화면 오른쪽 위 줄에 금·나무와 나란히 인구를 '사용 중/최대'로 보여 주고, 인구 구간에 따라 유지비 글자(No/Low/High Upkeep)가 바뀐다.
- [td_bars-rt-01·verified] (Rogue Tower) 전투 화면 위 가운데에는 칸 세 개가 붙어 있는데, 왼쪽 칸은 «Tower: 20/20»(본진 체력, 칸으로 나뉜 초록 막대), 가운데 칸은 «Level / Score / Gold», 오른쪽 칸은 «Mana: 15/200 (+3/s)»(칸으로 나뉜 막대)를 보여 준다.
- [td_bars-bt-02·verified] (Bloons TD 6) 생명과 돈은 화면 왼쪽 위 맨 윗줄에 나란히 표시되고(2560×1440 기준 생명 x 80~270, 돈 x 440~670, y 4~96), 라운드 숫자는 위쪽 오른편(x 1912~2080, 화면 너비의 약 75~81%)에 표시된다.
- [td_bars-bt-03·verified] (Bloons TD 6) 라운드 표시는 작은 «ROUND» 제목 아래에 «6/100»처럼 «현재 라운드/마지막 라운드» 숫자로 나온다.
- [pixel_minimal-11·verified] (Dome Keeper) 돔 체력 막대는 왼쪽 하트 아이콘 뒤로, 최대 체력 41당 1px씩 길어진다. 피해를 받으면 0.2초 흰색 섬광이 일고, 수리 예정량은 별도 구간으로 맥동하며, 최대치를 넘는 수리분은 다른 구간으로 깜박인다.
- [pixel_minimal-16·verified] (Kingdom Two Crowns) Kingdom Two Crowns에서 군주가 지닌 코인 주머니가 담을 수 있는 동전 수는 주머니 안 동전 프리팹의 크기에 묶여 있다. 커뮤니티 모드 BetterPayableUpgrade는 동전 크기를 0.668배로 줄여 주머니에 약 100개가 들어가게 한다.
- [pixel_minimal-18·verified] (Kingdom Two Crowns) StaminaBar 모드는 탈것 바로 아래 세계 좌표 위치에 막대를 그린다. 남은 스태미나(청록), 배부름 지속 시간(노랑, 이때는 스태미나가 줄지 않음), 지침 상태 지속 시간(빨강, 이때는 달릴 수 없음)을 보여 주고, N 키로 끄고 켠다.
- [pvz_frostpunk-07·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 해 수치는 씨앗 바 왼쪽 칸 (34,78)에 검은 숫자로 가운데 맞춰 그려지고, 해가 모자란 카드를 누르면 70틱 동안 10틱 간격으로 빨강과 검정을 번갈아 깜박인다.
- [td_bars-md-11·partly] (Mindustry) 코어 자원은 화면 위 가운데의 반투명 검은 배경 위에 «아이콘+숫자» 쌍으로 한 줄에 4개씩 표시되고, 한 번이라도 코어에 들어온 자원만 나타나며, 마우스를 올리면 자원 이름과 줄이지 않은 정확한 수가 툴팁으로 뜬다. ※ 소스를 직접 대조함. 위 가운데 coreinfo, black6 배경, 아이콘+formatAmount 숫자, 4개마다 줄바꿈, 코어에 한 번 들어온 자원만 표시(usedItems), !mobile, coreitems 설정은 모두 맞다. 다만 툴팁은 둘로 나뉜다. 아이콘에 올리면 자원 이름만, 숫자에 올리면 정확한 수만 뜬다. 하나의 툴팁에 이름과 수가 함께 …
- [pixel_minimal-12·partly] (Dome Keeper) 자원 카운터는 철·물·모래 아이콘과 숫자를 2열 격자로 놓는다. 어느 자원이든 100 이상이 되면 폭을 격자 4칸에서 5칸으로 넓히고 숫자를 오른쪽 정렬로 바꾼다. ※ 현재 판 Inventory.gd를 확인했다. 최댓값이 100 이상이면 element_size.x를 5로, 숫자를 오른쪽 정렬로 바꾼다. 100 미만이면 4와 왼쪽 정렬이다. 바뀔 때 request_rebuild를 보내고, GridContainer는 columns=2다. 그러나 옛 판(HammadArifeen)은 clamp(0,99)로 숫자를 99에서 자르고…
- [ironhide-19·likely] (Iron Marines) Iron Marines는 화면 왼쪽 위에 유닛 생산 자원 Etherwatts를 초록 막대로, 지금 출전할 수 있는 유닛 수(명령 포인트)를 해병 아이콘으로 보여 준다.
- [tab-04·likely] (They Are Billions) 오른쪽 아래 콜로니 상태 패널은 주민·노동자·식량·에너지의 남은 공급량과 금·나무·돌·철·석유의 재고·저장 한도·생산량을 두 열로 나눠 늘 보여 준다.
- [aoe_northgard-06·likely] (Age of Empires IV) 스팀 토론의 AoE IV 이용자에 따르면 '놀고 있는 일꾼' 버튼은 화면 아래 인구 수 표시 바로 위에 있고 왼쪽 클릭으로 누를 수 있다.
- [aoe_northgard-17·likely] (Northgard) Northgard 자원 줄은 자원마다 현재 양 옆에 틱당 증감(+/−)을 함께 보여 주며, 한 달은 6틱이다.
- [castle-06·likely] (Stronghold / Stronghold Crusader) 화면 오른쪽(오른쪽 아래) 패널에 있는 서기의 책(scribe's book)은 인기도, 금고(골드), 인구 세 가지 수치를 늘 보여 주고, 인구는 '현재/최대' 분수로 표시한다.
- [castle-25·likely] (Diplomacy is Not an Option) HUD는 나무·돌·철·식량·금·가용 인구·놀고 있는 일꾼·영혼 수정 같은 핵심 자원을 항상 화면에 띄워 두고, 인구는 '현재/최대'(마을 회관과 집의 수용량 기준)로 표시한다.

## 건설 메뉴 (build_menu)
- [ironhide-01·verified] (Kingdom Rush (원작)) Kingdom Rush 원작에서 빈 건설 자리를 클릭하면 그 자리에 궁수·병영·마법사·포병 4가지 타워 선택지가 뜨고, 어느 자리에나 4종 중 아무것이나 지을 수 있다.
- [tab-11·verified] (They Are Billions) 사령부 건설 메뉴는 먼저 주거·자원·에너지·산업·군사·방어 같은 범주 버튼으로 나뉘고, 범주를 누르면 그 범주의 건물 버튼이 나오는 2단계 구조다.
- [aoe_northgard-05·verified] (Age of Empires IV) AoE IV에서 일꾼을 고르면 건설 명령이 시대별 묶음으로 나뉜다. 먼저 시대 키(Q=1시대, W=2시대, E=3시대)로 그 시대 건물 묶음을 열고, 이어서 격자 키로 건물을 고른다.
- [aoe_northgard-22·verified] (Northgard) Northgard 영역 정보에는 집 모양 아이콘 옆에 '1/5'처럼, 그 영역에 지은 건물 수와 지을 수 있는 최대 수가 함께 표시된다.
- [td_bars-md-01·verified] (Mindustry) PC판 Mindustry의 건설 메뉴는 화면 오른쪽 아래 구석에 붙은 패널 하나로, 왼쪽에 블록 격자, 오른쪽에 50px 아이콘 범주 탭을 2열로 쌓은 세로 열이 나란히 놓인다.
- [td_bars-rt-02·verified] (Rogue Tower) 타워 건설 바는 화면 아래 가운데에 놓인 카드 모양 버튼들이며, 카드 한 장에 타워 이름(위)·아이콘(가운데)·금화 비용(아래, 예: 발리스타 55g)이 함께 적혀 있다.
- [p_cooldown_hotkey-13·verified] (Beyond All Reason (오픈소스 RTS)) BAR 격자 건설 메뉴의 각 칸은 단축키 글자를 오른쪽 위에, 금속·에너지 비용 두 줄을 오른쪽 아래에 오른쪽 정렬로 그리며, 지을 수 없는 칸은 아이콘을 0.4 밝기로 어둡게 하고 비용과 단축키 글자도 회색으로 바꾼다.
- [p_wave_menu-08·verified] (파이 메뉴 연구 (Callahan 외 1988)) Callahan·Hopkins·Weiser·Shneiderman의 CHI '88 논문 «An Empirical Comparison of Pie vs. Linear Menus»는 항목을 원둘레에 같은 반지름 거리로 늘어놓는 파이 메뉴가 Fitts 법칙의 거리를 고정하고 목표 크기를 키워 선형 메뉴보다 목표 찾는 시간과 오류율을 줄이며, 주관적 선호는 대체로 같다고 보고했다.
- [p_wave_menu-12·verified] (Mindustry) Mindustry는 화면 오른쪽 아래에 고정 건설 패널을 둔다. 오른쪽 열에는 분류 아이콘(50px, 2열)을, 그 왼쪽에는 고른 분류의 블록 아이콘(46px, 한 줄 4개)을 놓고, 블록에 마우스를 올리면 패널 위 정보 칸에 아이콘, 이름과 단축키, 재료마다 '보유/필요' 수량, 빨간 X 아이콘과 설치 불가 이유를 줄을 나눠 띄운다.
- [p_wave_menu-13·verified] (Beyond All Reason) Beyond All Reason의 기본 «Grid menu» 위젯은 건설 목록을 3줄×4칸 고정 격자로 그리고 각 칸을 키보드 자리에 맞췄다. 격자 1줄은 Z X C V, 2줄은 A S D F, 3줄은 Q W E R이고, 분류 4개(경제·전투·유틸리티·생산)도 Z·X·C·V에 묶여 있으며 다음 쪽은 B로 넘긴다.
- [p_wave_menu-14·verified] (SimCity (Unix판, Don Hopkins)) Don Hopkins가 만든 Unix판 SimCity는 화면에 늘 떠 있는 도구 팔레트를 파이 메뉴와 같은 구조(최상위 항목과 Zone·Build 하위 메뉴)로 배치해서, 고정 팔레트가 파이 메뉴의 '지도' 역할을 하게 했다.
- [ironhide-02·partly] (Kingdom Rush 시리즈 (KR·Frontiers·Origins 모) Emily Miles에 따르면 Kingdom Rush 시리즈는 타워 구매와 업그레이드를 두 번째 탭으로 확정하게 하고, 첫 탭 뒤 화면의 다른 곳을 누르면 돈을 쓰지 않고 취소된다. ※ Emily Miles 블로그 본문은 검색 한도 때문에 확인하지 못했다. 반면 데스크톱(Steam Love2D) 코드에서 TowerMenuButton은 마우스를 올리면(on_enter) 툴팁·사거리·건물 미리보기를 보여 주고, 한 번 클릭하면(on_click, tw_upgrade) 바로 짓는다. 확인 단계가 없다. 두 번째 탭 확정은 모바일판 동작일 뿐이고,…
- [aoe_northgard-21·partly] (Northgard) Northgard에서 자기 영역(타일) 아무 곳이나 누르면 화면 오른쪽에 그 영역의 '건설·주민' 메뉴가 뜬다. ※ Northgard PC용 AutoHotkey 스크립트(2022~2026년 판)의 주석은 이렇게 적었다. '유닛·건물·땅 구역을 고르면 아래쪽 메뉴가 뜬다.' 건설 메뉴는 오른쪽에 있다(1920 폭 기준 x 약 1696~1867). 스크립트는 건설 메뉴가 닫혀 있으면 B 키로 연다. 그러니 영역을 누르면 뜨는 것은 아래쪽 메뉴(구역 정보·주민 배치 쪽으로 보…
- [pvz_frostpunk-01·partly] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) PvZ의 씨앗 카드 바(씨앗 은행)는 화면 왼쪽 위 (0,0)에 그려지고, 칸 수는 기본 6칸에 상점 슬롯 업그레이드 구매 수를 더한 값(갖고 있는 씨앗 수가 상한)이다. ※ (이번 회차 WebSearch는 한도 소진으로 한 번도 실행되지 않아, GitHub에 있는 다른 디컴파일들로 대조했다.) '기본 6칸 + 상점 슬롯 업그레이드, 갖고 있는 씨앗 수가 상한'은 맞다. Patoke 코드뿐 아니라 따로 만든 0.9.9 매칭 디컴파일(bluisblu/pvz)과 윈도폰 디컴파일에도 mPurchases[21]+6, min(GetSee…
- [p_disabled_modal-09·partly] (Mindustry 건설 메뉴 숨김/회색 규칙) Mindustry 건설 메뉴는 연구로 아직 해금되지 않은 블록을 목록에서 뺀다. 해금된 블록 가운데 코어 재료가 모자라면 아이콘을 회색으로, 설치 자체가 불가능하면 진회색으로 칠하고, 설치 불가 블록은 목록 끝으로 정렬한다. ※ getUnlockedByCategory는 unlocked()인 블록만 고르고, !isPlaceable()인 블록을 끝으로 정렬한다. 버튼은 재료가 모자라면 gray, !isPlaceable()이면 darkGray다. 하지만 Block.java에서 isPlaceable()은 isVisible() && !isBanned() && supportsEnv()이므로,…
- [p_wave_menu-09·partly] (마킹 메뉴 항목 수 한계 (Kurtenbach·Buxton 1993)) Kurtenbach·Buxton(INTERCHI '93)의 계층 마킹 메뉴 실험을 정리한 자료들에 따르면, 오류율을 10% 미만으로 지키려면 한 단에 8항목이면 2단까지, 4항목이면 4단까지가 한계이고, 대각선 항목이 상하좌우 항목보다 오류가 많다. ※ orbit/research.md와 datum CONTEXT_MENU_RESEARCH.md 두 곳 모두 '오류 10% 미만이려면 8항목은 2단, 4항목은 4단까지'라고 적었다. 대각선(off-axis) 항목의 오류가 더 많다는 것은 datum에만 있다. 서지 초록은 '폭과 깊이의 한계를 실험'까지만 말한다. 논문 본문은 확인하지 못했다(웹 검색 불가). 상세…
- [p_wave_menu-10·partly] (파이 메뉴의 화면 가장자리 문제) Don Hopkins의 Micropolis 설계 문서에 따르면, 전통적인 파이 메뉴 툴킷은 메뉴가 화면 가장자리에 걸리면 메뉴를 화면 안으로 옮기고 마우스 커서도 같은 거리만큼 강제로 옮겼으며(warp), 커서를 옮길 수 없는 환경에서는 이 방식이 깨진다. ※ virtual-pointer 문서 §4.1에 '고전 파이 툴킷은 메뉴를 화면 안으로 옮기고 OS 커서를 같은 거리만큼 warp'한다는 내용과 그것이 깨지는 조건이 있다. clampMenuToViewport의 '엉뚱한 쐐기를 미리 고를 수 있다'와 allowPartialOffscreenMenu도 문서 그대로다. 반대 증거도 있다. Hopkins가 만든 Uni…
- [p_wave_menu-15·partly] (Thronefall) Thronefall은 미리 정해진 자리에만, 자리마다 정해진 한 종류의 건물만 짓게 한다. 다른 개발자의 조사 문서에 따르면 New Game Network 리뷰는 '건물을 어디에 둘지 정할 수 없다'고 썼고, OpenCritic은 이 정해진 배치를 '큰 한계'로 꼽았다. ※ 자리 고정 방식은 디컴파일 BuildSlot이 뒷받침한다. 슬롯마다 이름(LOCIDENTIFIER_NAME), level, upgrades, OnUpgradeChoiceComplete가 있고 건물 종류를 고르는 구조가 없다. 업그레이드 Choice 문자열(Knights·Spearmen·Flails 등)도 맞다. 리뷰 인용(NGN의 'You don't get…
- [aod-04·likely] (Age of Darkness: Final Stand) B 키를 누르면 성채(Keep)를 클릭하지 않고도 바로 건설 메뉴가 열리고, 성문은 배치하는 동안 Tab 키로 방향을 돌린다.
- [castle-04·likely] (Stronghold Crusader) 성벽을 고른 뒤 본 화면에서 왼쪽 마우스 버튼을 누른 채 끌면 길이가 정해지고, 버튼을 놓을 때 성벽이 놓인다.
- [minimal-04·likely] (Thronefall) Thronefall에서 건설 지점에 다가가면 그 자리에 지을 건물의 윤곽선이 나타나고, 건물 위에 비용 수만큼 빈 점선 원(코인 칸)이 떠서 비용을 보여 준다.
- [minimal-05·likely] (Thronefall) Thronefall에서 코인을 쓰면 코인이 주머니에서 날아가 건물 위 빈 칸을 하나씩 채우고, 칸이 모두 차면 건설이나 업그레이드가 끝난다.

## 선택·명령 패널 (selection_command_panel)
- [tab-03·verified] (They Are Billions) 하단 중앙의 가장 넓은 영역에는 선택한 유닛·건물의 속성과 쓸 수 있는 명령이 나오고, 선택이 바뀌면 내용이 통째로 바뀌며, 건설 명령도 사령부(Command Center)를 선택해야 이 자리에 뜬다.
- [blizzard-01·verified] (Warcraft III (Classic/Reforged)) Warcraft III의 명령 카드는 화면 아래 바에 있는 12칸(CommandButton_0~11, 3줄×4칸) 고정 격자이고, 유닛을 고를 때마다 같은 칸들에 그 유닛의 명령이 다시 채워진다.
- [aoe_northgard-26·verified] (Northgard) 스팀 가이드에 따르면 Northgard에서 E 키는 군사 유닛 전체(워밴드)를 고르고, Ctrl+숫자로 부대를 지정해 숫자 키로 다시 부를 수 있으며, 가이드는 워치프를 따로 1번에 지정해 두라고 권한다.
- [td_bars-md-07·verified] (Mindustry) 왼쪽 Shift(명령 모드)를 누르는 동안에는 오른쪽 아래 건설 격자가 있던 바로 그 자리에, 같은 너비의 유닛 명령 패널이 대신 들어간다.
- [td_bars-rt-10·verified] (Rogue Tower) 기본 게임에서는 체력·방어·보호막 레벨을 타워마다 하나씩 클릭해 그 패널에서 금화로 사야 해서, 한 모더가 F1로 여는 «타입별 타워 목록 + 같은 타입 일괄 업그레이드 + 그 타워로 카메라 이동(Ver)» 패널을 따로 만들었다.
- [td_bars-bt-05·verified] (Bloons TD 6) 타워를 클릭하면 업그레이드 패널이 타워 반대편에 열린다. 화면 가운데보다 왼쪽에 놓은 타워면 오른쪽에, 오른쪽에 놓은 타워면 왼쪽에 열린다.
- [ironhide-03·partly] (Kingdom Rush (원작)) Kingdom Rush에서 병영 타워를 선택하면 집결할 수 있는 범위가 원으로 표시되고, 그 안을 클릭해 병사 집결 지점을 전투 중 아무 때나 옮길 수 있다. ※ 코드상 병영을 선택해도 원이 바로 뜨지 않는다. 링 메뉴의 집결 버튼(tw_rally)을 누르면 GUI_MODE_RALLY_TOWER로 바뀌고 rally_range가 원(실제로는 타원)으로 표시된다. 지점은 범위 안이면서 길 노드 근처(NF_RALLY, rally_terrains)여야 받아들여진다. 아니면 invalid 표시가 뜬다. 원 안 아무 곳이나 되…
- [blizzard-28·partly] (StarCraft II) StarCraft II에서 미니맵 위 놀고 있는 일꾼 아이콘에는 그 수가 표시되고, F1은 놀고 있는 일꾼 하나를 고르며(Ctrl+F1은 전부), F2는 군대 전체를 고른다. ※ IdleWorker=F1, ArmySelect=F2('조종 중인 모든 전투 유닛 선택')는 확인했다. 놀고 있는 일꾼 버튼은 미니맵 바로 위에 있다. 다만 게임 툴팁은 F1을 '거듭 누르면 놀고 있는 일꾼들을 차례로 돈다'고 설명해, '다시 누르면 카메라가 그 일꾼으로 간다'와 다르다. Ctrl+F1 전체 선택과 아이콘의 숫자 표시는 확인하지 못했다.
- [td_bars-rt-09·partly] (Rogue Tower) 타워를 클릭하면 열리는 타워 패널에는 Range·Fire Rate·Base Damage·체력/방어/보호막 배수 수치, «Upgrade»와 «Cost», 표적 우선순위(Progress, NearDeath, MostHealth 등), «Copy (Q)»/«Paste (E)», «Demolish»가 들어 있다. ※ translations L868-899에 Demolish, Base Damage, Health/Armor/Shield Multiplier, Upgrade, Cost, Range, Fire Rate, Copy (Q), Paste (E), Target Priority와 Progress~Marked가 한 덩어리로 있다. 문자열은 맞다. 하지만 이것들이 모두 타워…
- [td_bars-bt-06·partly] (Bloons TD 6) 업그레이드 패널 안에는 위에서부터 표적 바꾸기 좌우 화살표(높이 약 29%), 위·가운데·아래 업그레이드 경로 3칸(약 37~46%, 51~59%, 65~72%), 판매 버튼(약 81~87%)이 세로로 쌓여 있다. ※ locations.py의 세로 위치는 맞다. 표적 화살표 y≈0.29, 위·가운데·아래 경로 0.370~0.462 / 0.512~0.586 / 0.649~0.723, 판매 0.808~0.870이다. 그러나 x 3.3~12.2%는 '현재 업그레이드 이름' OCR 글자 영역이지 패널이나 경로 칸 전체 너비가 아니다. 표적 화살표가 x 0.044와 0.185, …
- [ironhide-16·likely] (Iron Marines) Iron Marines는 유닛을 눌러 선택하고 끌어서 목적지를 정하며, 이동 중인 유닛은 지나가는 적을 무시하고 도착한 뒤에야 교전한다.
- [aoe_northgard-02·likely] (Age of Empires IV) AoE IV 선택 패널은 유닛 하나를 고르면 화면 아래 가운데 속성 칸에 공격·방어·원거리 방어·체력을 보여 주고, 두 개 이상 고르면 개별 속성 대신 고른 유닛들의 묶음 표시로 바뀐다.
- [aoe_northgard-27·likely] (Northgard) Northgard에서 적을 공격하려면 군사 유닛을 고른 뒤 싸울 타일을 누르면 되고, 적 영역에서는 타일 하나를 정리해야 그다음 타일로 나아갈 수 있다.
- [castle-02·likely] (Stronghold Crusader (HD/DE)) 지은 성문루(gatehouse)를 클릭하면 아래 패널에 성문을 손으로 열고 닫는 메뉴('open Gate' 등)가 뜨고, 도개교가 붙어 있으면 같은 메뉴로 도개교도 다룬다.
- [castle-13·likely] (Stronghold Crusader: Definitive Edition ) DE 가을 업데이트는 무기 공방 건물 UI를 고쳐서, Shift+클릭하면 같은 종류 건물 전체의 생산 무기를 한 번에 바꿀 수 있다는 사실을 패널에 분명히 보이게 했다.
- [castle-19·likely] (Diplomacy is Not an Option) 메인 패널에는 건설, 수리, 모든 성문 닫기, 모든 성문 열기, 시장, 고용 통계, 연구 버튼이 함께 있다.

## 못 쓰는 상태 (disabled_locked_state)
- [blizzard-08·verified] (Warcraft III (Classic/Reforged)) WC3에서는 시전자의 마나가 모자란 기술 아이콘이 파랗게 물들어 보인다.
- [blizzard-23·verified] (StarCraft II) StarCraft II 데이터 편집기에서 버튼의 Requirements 설정은 조건을 채우지 못했을 때 그 버튼을 숨길지, 보이되 회색으로 비활성화할지를 정한다.
- [td_bars-md-03·verified] (Mindustry) 건설 격자에는 해금된 블록만 나오고(잠긴 블록은 아예 숨김) 놓을 수 있는 블록이 앞쪽으로 정렬되며, 코어 자원이 모자라면 아이콘이 회색, 놓을 수 없는 블록이면 짙은 회색으로 칠해진다.
- [td_bars-md-05·verified] (Mindustry) 블록을 못 놓는 이유(«Unit can't build», «Banned», «Limit: N Buildings» 등)는 버튼에 붙지 않고, 정보 칸 맨 아래에 빨간 X 아이콘과 함께 한 줄로 펼쳐질 때만 나타난다.
- [td_bars-bt-14·verified] (Bloons TD 6) 업그레이드 칸 배경 스프라이트는 Blue·Green·Red·Grey 네 가지 색과 «Tier5Locked», «ParagonLocked» 같은 잠김 변형으로 따로 준비되어 있다.
- [pvz_frostpunk-08·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 못 쓰는 카드(재충전 중, 해 부족, 조건 미충족)를 클릭하면 매번 버저 소리가 나고, 처음 하는 모험 모드 1레벨에서는 이유를 알려 주는 안내 문구(ADVICE_SEED_REFRESH, ADVICE_CANT_AFFORD_PLANT)가 뜬다.
- [pvz_frostpunk-14·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 준비 단계인 씨앗 고르기 화면 아래쪽 (154,545) 156×42 'Let's Rock' 시작 버튼은 씨앗 바 칸이 다 찰 때까지 비활성 그림과 진회색(64,64,64) 글자로 있고, 칸이 다 차면 흰 글자로 바뀌어 눌린다.
- [p_disabled_modal-01·verified] (IBM Carbon Design System - Disabled stat) Carbon은 의존성·선행 조건 때문에 잠시 못 쓰는 컴포넌트는 '기본 비활성'으로 화면에 남겨 두고(완전히 사라지면 안 됨) 컴포넌트 불투명도 50%, 글자 25%, 호버 변화 없음, not-allowed 커서로 그리게 하며, 권한이 없어 계속 못 쓰는 경우에만 '숨김'으로 아예 빼라고 정한다.
- [p_disabled_modal-02·verified] (OpenRA (오픈소스 C&C/Red Alert 엔진) 생산 팔레트) OpenRA는 생산 항목의 선행 조건 앞에 '~'를 붙이면 그 조건이 안 될 때 생산 팔레트에서 아이콘을 숨기고, '~'가 없으면 아이콘을 제자리에 둔 채 어둡게(NotBuildable 팔레트로 cantBuild 덧그림) 그린다. 그래서 숨길지 비활성으로 둘지를 항목마다 데이터로 고른다.
- [p_disabled_modal-03·verified] (GitHub Primer / GOV.UK / Shopify Polaris) GitHub Primer는 disabled 버튼이 키보드 포커스를 받지 못해 발견되지 않으므로 되도록 쓰지 말라고 한다. 대신 흐리게 보이되 포커스·호버·클릭은 받는 'inactive' 버튼을 써서, 호버나 포커스에는 툴팁을, 클릭에는 못 하는 이유와 해결 경로를 담은 대화창을 띄우라고 한다.
- [p_disabled_modal-05·verified] (0 A.D. 건설 패널) 0 A.D. 건설 패널은 38×38 아이콘 버튼을 한 줄 10칸의 고정 격자에 놓는다. 선행 조건이 안 되거나 수량 한도에 닿으면 아이콘을 회색조에 검정 127/255(약 50%)로 덮고, 자원만 모자라면 모자란 총량에 비례한 불투명도(50~125/255)의 빨간색으로 덮어, 두 가지 비활성을 색으로 나눈다.
- [p_pixel_ui-14·verified] (Godot 4 버튼 비활성 표시) Godot 4 Button은 비활성 상태 전용 StyleBox(disabled)와 font_disabled_color(기본 RGBA 0.875, 0.875, 0.875, 0.5), icon_disabled_color(기본 알파 0.4)를 따로 가지며, TextureButton은 texture_disabled를 지정하지 않으면 비활성일 때도 texture_normal을 그대로 보여 준다.
- [pvz_frostpunk-05·partly] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 해가 모자라거나 선행 식물 조건(예: 개틀링 완두는 리피터 위에만)을 못 채운 카드는 자리와 그림, 비용 숫자를 그대로 둔 채 카드 전체를 회색도 128(약 절반 밝기)로 어둡게만 그린다. ※ 해가 모자라거나 선행 조건을 못 채우면 aGrayness=128로 카드 전체를 반 밝기로 그리고, 자리·그림·비용 숫자는 그대로다. 윈도폰판 GetGraynessAndDarkness도 같다. 하지만 detail의 '재충전 흐림과 해 부족 흐림은 서로 다른 표시'는 반만 맞다. 재충전 중인 카드도 전체가 128로 어두워지고, 그 위에 위쪽 64 막이 하나 더…
- [p_disabled_modal-04·partly] (OpenRA / The Battle for Wesnoth - 못 쓰는 항) 못 쓰는 항목을 누르면 OpenRA 생산 팔레트는 ClickDisabledSound 효과음을 내고, Wesnoth 징집 창은 못 뽑는 유닛을 골라 '징집'을 누를 때 그 이유 문구를 잠깐 떴다 사라지는 메시지(show_transient_message)로 보여 준다. ※ OpenRA 부분은 맞다. 클릭이 처리되지 않으면 HandleEvent가 ClickDisabledSound를 재생하고, 이 소리는 mods/common/metrics.yaml에 정의돼 있다. Wesnoth도 징집 창에서 못 뽑는 유닛을 고르고 OK를 누르면 show_transient_message(err)를 부른다. 그러나 transient_message.…
- [tab-13·likely] (They Are Billions) 건물은 사령부와 테슬라 타워가 만드는 에너지 범위 안에만 지을 수 있고, 건물을 배치하려 할 때나 에너지 지도 보기를 켰을 때 지을 수 있는 칸이 초록으로 칠해진다.
- [aoe_northgard-09·likely] (Age of Empires IV) AoE IV의 '시대 올리기' 버튼은 화면 아래 가운데에 있다. 현재 시대를 로마 숫자로 보여 주고, 다음 시대로 올릴 수 있게 되면 빛난다.

## 툴팁 (tooltip)
- [blizzard-22·verified] (StarCraft II) StarCraft II에서 명령 버튼에 커서를 올리면 툴팁에 명령 이름과 그 뒤 괄호 속 단축키 글자가 나오고, 본문은 버튼마다 데이터에 정해 둔 설명 글이다.
- [td_bars-md-04·verified] (Mindustry) 블록에 마우스를 올리거나 블록을 고르면 격자 바로 위 정보 칸에 아이콘·이름·단축키 조합과 자원별 «보유/필요» 수가 뜨고, 보유량이 필요량의 절반 미만이면 빨강, 필요량 미만이면 강조색(노랑), 충분하면 흰색으로 표시된다.
- [td_bars-rt-11·verified] (Rogue Tower) 2022년 QoL 모드가 «마우스를 올리면 타워 사거리 원/사각형 표시», «건설 모드에서 사거리 표시», «표적 우선순위별 타워 색칠»을 추가 기능으로 내놓았다.
- [pvz_frostpunk-06·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 씨앗 카드에 마우스를 올리면 연노랑(255,255,200) 바탕에 검은 테두리 툴팁이 뜨고, 식물 이름 줄과 따로 빨간(255,0,0) 경고 줄 하나가 나오며, 경고 줄은 재충전 중이면 [WAITING_FOR_SEED], 해 부족이면 [NOT_ENOUGH_SUN], 조건 미충족이면 [REQUIRES_REPEATER]처럼 한 가지 이유만 보여 준다.
- [p_disabled_modal-08·verified] (Mindustry 건설 정보 칸(PlacementFragment)) Mindustry PC판은 화면 오른쪽 아래 건설 패널 위 정보 칸에 고른 블록의 아이콘, 이름, 단축키 조합을 쓴다. 재료마다 '보유/필요' 숫자를 보유가 필요량의 절반 미만이면 진홍(scarlet), 모자라면 강조색, 충분하면 흰색으로 칠하고, 설치할 수 없는 이유(건설 유닛 아님, 금지됨, 설치 한도)는 빨간 X 아이콘과 함께 따로 한 줄로 띄운다.
- [p_disabled_modal-11·verified] (툴팁 표시 지연 값 (Godot 4 / 0 A.D. / OpenRA / ) 툴팁이 뜨기까지의 지연은 Godot 4 기본값이 0.5초(ProjectSettings gui/timers/tooltip_delay_sec)인데, 0 A.D.는 전투 화면 툴팁을 0.1초(메뉴는 0.5초)로, OpenRA는 마우스가 멈춘 뒤 0.2초로 잡아 실시간 전투 화면에서는 더 짧게 쓴다.
- [p_disabled_modal-12·verified] (고정·중첩 가능한 툴팁의 전제 (WCAG 1.4.13 / Material) WCAG 2.1 1.4.13은 호버로 뜨는 추가 내용이 세 조건을 지키라고 정한다. 포인터를 그 위로 옮겨도 사라지지 않고(hoverable), 트리거를 떼거나 닫을 때까지 남으며(persistent), 포인터를 움직이지 않고도 닫을 수 있어야(dismissible) 한다. Material(MDC Web)의 '지속형 리치 툴팁'은 클릭으로 열고, 내용 위나 바깥으로 마우스를 옮겨도 남아 있다가 바깥을 클릭하면 닫힌다.
- [p_pixel_ui-15·verified] (Godot 4 툴팁·단축키 표시) Godot 4 Control은 tooltip_text가 있으면 마우스가 잠시(기본 0.5초, gui/timers/tooltip_delay_sec) 멈췄을 때 PopupPanel과 Label로 된 툴팁을 띄우고, Button은 shortcut_in_tooltip(기본 true)으로 지정된 Shortcut을 그 툴팁에 자동으로 붙이며, _make_custom_tooltip을 덮어쓰면 아무 Control(아이콘·비용 줄 등)이나 툴…
- [blizzard-09·partly] (Warcraft III (Classic/Reforged)) WC3 게임 데이터(war3skins.txt)에는 툴팁 전용 금·나무·마나·인구(supply) 비용 아이콘과 가로 구분선 그림이 종족 스킨마다 따로 정해져 있다. ※ war3skins.txt를 직접 읽어 보니 ToolTipGold/Lumber/Stones/Mana/SupplyIcon과 ToolTipHorizontalSeparator가 있다. 하지만 이 키들은 [Default] 구역에만 있고 경로도 Human 것이다. [Human]·[Orc]·[NightElf]·[Undead] 구역에는 없다. '종족 스킨마다 따로 정해져…
- [blizzard-10·partly] (Warcraft III (Classic/Reforged)) WC3 명령 버튼 툴팁의 이름 줄에서는 단축키 글자가 노란색으로 표시되고, Reforged에서는 모든 명령 툴팁 끝에 단축키가 자동으로 붙는다. ※ 노란 단축키 글자는 확인했다. 원작 CommandStrings.txt의 이름 줄이 'Tip=|cffffcc00M|rove', 'Cancel (|cffffcc00ESC|r)'처럼 단축키 글자를 노란색 코드로 감싼다. 'Reforged에서 모든 툴팁 끝에 단축키가 자동으로 붙는다'는 인용된 README 말고는 독립 근거를 찾지 못했다.
- [p_disabled_modal-06·partly] (0 A.D. 건설 버튼 툴팁 구성) 0 A.D. 건설 버튼 툴팁은 이름, 분류, 오라, 설명, 비용(자원 아이콘+숫자), 주둔·인구 보너스, 수량 한도 순으로 줄을 쌓는다. 그리고 맨 끝에 못 쓰는 이유를 빨간 굵은 글씨(sans-bold-13, red)로 'Requires <기술명>'과 'Insufficient resources: <자원 아이콘> <모자란 양>' 형태로 붙인다. ※ 큰 틀은 맞다. 툴팁은 이름, 분류, 오라, 설명, 비용, (자원 하역지·주둔·포탑), 인구 보너스, '우클릭으로 상세' 안내, 수량 한도, 경기 한도 순으로 쌓이고, 그 뒤에 Requires 줄과 Insufficient resources 줄이 온다. filter로 빈 줄을 빼고 '\n'으로 잇는다. objection 형식은 sans-bold-13에 red…
- [p_disabled_modal-07·partly] (OpenRA 생산 툴팁 레이아웃) OpenRA 생산 툴팁은 폭 200px 상자 왼쪽 위에 굵은 이름과 그 옆 노란색(FFFF00) 괄호 단축키를 두고, 아래에 작은 글씨 'Requires <선행 건물>.' 줄과 설명을 둔다. 오른쪽 열에는 16×16 아이콘과 함께 비용·제작 시간·전력을 세로로 놓고, 돈이 모자라면 비용 숫자를, 전력이 모자라면 시간과 전력 숫자를 빨갛게 바꾼다. ※ 대부분 맞다. 이름은 Bold, 단축키 라벨은 FFFF00에 '(키)'이고, Requires는 TinyBold, 오른쪽 열에 16×16 아이콘과 함께 비용·시간·전력이 놓인다. 비용 색은 GetColor 람다 'GetCashAndResources() >= cost'로 정한다. 전력은 초과 시, 시간은 저전력(LowPowerModifier>100) 시 빨간색…
- [ironhide-13·likely] (Kingdom Rush 5: Alliance) Kingdom Rush 5: Alliance는 메인 메뉴의 백과사전을 빼고, 전투 중 적을 클릭한 뒤 화면 아래쪽에 뜨는 그 적의 초상화를 누르면 상세 정보를 보게 했다.
- [aoe_northgard-18·likely] (Northgard) Greedy Goblin 블로그(2019)는 Northgard 자원 줄이 식량을 설명 없이 '4' 같은 숫자로만 보여 줘서 실제 생산량을 플레이어가 직접 셈해 봐야 한다고 비판했다.
- [pixel_minimal-19·likely] (Kingdom Two Crowns) Kingdom Two Crowns의 튜토리얼 안내는 HUD 글상자가 아니라 게임 세계 안에 나타나는 조상 유령 NPC가 맡는다(GhostHintTrigger). 2.0 업데이트에서 이 유령을 끌 수 있게 했고 덜 거슬리게 바꿨다.

## 영웅 초상화·스킬 (hero_portrait_skills)
- [blizzard-03·verified] (Warcraft III (Classic/Reforged)) WC3는 영웅이 생기면 화면 왼쪽 위에 그 영웅의 초상화 아이콘을 놓고 F키를 매기며, 초상화에 마우스를 올리면 그 키가 보이고, 키를 한 번 누르면 영웅이 선택되고 빠르게 두 번 누르면 카메라가 그 영웅으로 간다.
- [blizzard-18·verified] (StarCraft II) StarCraft II: 군단의 심장 캠페인에서 케리건의 1단계 능력 '동력 폭발(Kinetic Blast)'은 Q 단축키로 쓰며, 에너지 50을 쓰고 재사용 대기가 10초다.
- [td_bars-bt-12·verified] (Bloons TD 6) 영웅·타워 능력 버튼은 화면 왼쪽 아래 가장자리에 가로로 늘어서고(1080p 기준 첫째 x≈9.9%, 둘째 x≈14.4%, 높이 y≈95.7%), 숫자키 1~0으로 차례대로 쓸 수 있다.
- [p_cooldown_hotkey-09·verified] (World of Warcraft 소환수 행동 단추) WoW 소환수(펫) 행동 단추는 왼쪽 클릭이면 기술을 쓰고 그 밖의 클릭(오른쪽 클릭)이면 자동 시전을 켜고 끄며(TogglePetAutocast), 자동 시전이 가능한 기술에만 AutoCastOverlay를 보이고 켜짐 여부는 별도로 그린다.
- [blizzard-04·partly] (Warcraft III (Classic/Reforged)) WC3 왼쪽 위 영웅 초상화는 그 영웅이 피해를 입는 동안 붉게 깜박이고, 레벨이 올라 쓸 기술 점수가 생기면 초상화에 깜박이는 표시가 붙는다. ※ 기술 점수 표시는 확인했다. war3skins의 HeroBarPointModel(HeroLevel.mdx)이 초상화 위에 '파란' 링을 맥동시키고 파란 불꽃을 띄운다(OpenWar3가 모델을 분석함). Tasyen 문서에는 남은 점수 상자(Unspent-SkillPointsBox)도 있다. 반면 '피해를 입는 동안 붉게 깜박인다'는 Battle.net 안내…
- [blizzard-05·partly] (Warcraft III (Classic/Reforged)) WC3에서 자동 시전이 되는 기술 아이콘은 네 귀퉁이에 노란 꺾쇠 테두리가 있고, 그 아이콘을 우클릭하면 자동 시전이 켜지면서 테두리가 주황색으로 빛난다. ※ 우클릭으로 켜고 끄는 것은 맞다(TipStrings Tip3: 'Modal skills can be turned on or off by right-clicking'). 다만 켜졌을 때 모습은 테두리가 가만히 주황색으로 빛나는 것이 아니다. war3skins의 CommandButtonAutocast(UI-ModalButtonOn.mdx)가 크림색에서 금색으로…
- [ironhide-10·likely] (Kingdom Rush 5: Alliance) Kingdom Rush 5: Alliance는 영웅 2명을 함께 데려가며, 화면 왼쪽 아래 영웅 그림을 클릭하거나 숫자키 4·5로 영웅을 고르고, 두 영웅의 궁극기가 주문 칸의 두 번째·세 번째 자리를 차지한다.
- [aod-14·likely] (Age of Darkness: Final Stand) 영웅은 나이트메어를 처치해 경험치를 얻어 레벨이 오르고, 레벨이 오르면서 패시브·액티브 스킬이 차례로 열린다.

## 재사용 대기·마나 (cooldown_mana)
- [blizzard-24·verified] (StarCraft II) StarCraft II에서 재사용 대기 중인 능력 아이콘 위에는 시계처럼 도는 덮개가 겹쳐져 남은 대기 시간을 보여 준다.
- [td_bars-bt-13·verified] (Bloons TD 6) BTD6 게임 UI에는 능력 재사용 대기를 그리는 «CooldownClockBg / CooldownClockFill / CooldownClockWhite» 시계 채움 스프라이트 세트가 있다.
- [pvz_frostpunk-04·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 재충전 시간은 식물 정의표에 식물마다 들어 있으며, 완두콩·해바라기는 750, 호두는 3000, 체리 폭탄은 5000 단위로 등급이 나뉜다.
- [p_cooldown_hotkey-03·verified] (World of Warcraft (리테일·클래식)) WoW 행동 단추 아이콘은 쓸 수 없는 이유를 색으로 나눈다: 쓸 수 있으면 원색(1,1,1), 마나 부족이면 파란 틴트(0.5,0.5,1.0), 그 밖의 사용 불가면 회색(0.4,0.4,0.4)이고, 대상이 사거리 밖이면 아이콘은 그대로 두고 오른쪽 위 단축키 글자를 빨강(RED_FONT_COLOR)으로 바꾼다.
- [p_cooldown_hotkey-05·verified] (World of Warcraft (리테일)) WoW 리테일은 재사용 대기의 남은 시간 숫자를 '행동 단축바' 설정의 체크 상자(CVar countdownForCooldowns)로 켜고 끄게 하며, 이 값이 꺼져 있으면 행동 단추 Cooldown 위젯의 숫자를 숨긴다(SetHideCountdownNumbers).
- [p_cooldown_hotkey-06·verified] (World of Warcraft Cooldown 위젯 API) WoW Cooldown 위젯 API는 기준값에 따라 남은 시간 글자 형식을 바꾼다: 기준 초보다 적게 남으면 소수 한 자리('8.7'), 축약 기준보다 적으면 단위 없는 분:초('1:31')로 쓰고, 전체 대기 시간이 최소값보다 짧으면 숫자를 아예 띄우지 않는다(SetMinimumCountdownDuration).
- [p_cooldown_hotkey-10·verified] (Dota 2) Dota 2는 마나가 모자란 기술을 쓰려 하면 'Not Enough Mana', 재사용 대기 중이면 'Recharging...' 오류 문구를 띄우고, Alt+클릭으로 기술 상태를 팀에 알리면 'Not Enough Mana ( Need N more )'나 'On Cooldown ( N seconds remain )'처럼 모자란 마나와 남은 초를 숫자로 적는다.
- [p_cooldown_hotkey-14·verified] (OpenRA·Beyond All Reason) OpenRA와 BAR는 진행 정도를 아이콘 위에 원형으로 도는 덮개로 그린다: OpenRA는 생산·지원 능력 아이콘에 'clock' 애니메이션을 겹치고 경과 비율에 맞는 프레임을 고르며, BAR는 건설 칸에 남은 비율만큼 어두운(0.08 회색, 불투명도 0.6) 둥근 사각 부채꼴을 위쪽에서부터 반시계 방향으로 그린다.
- [ironhide-11·partly] (Kingdom Rush (원작) / Origins) Kingdom Rush의 주문(불의 비·증원)은 비용 없이 쓰고 주문마다 재사용 대기가 따로 돌며, 불의 비를 고르면 맵 위에 붉은 조준 표식이 떠서 떨어질 자리를 클릭으로 정한다. ※ 코드상 주문은 골드 비용이 없다. 버튼마다 cooldown_view가 따로 돌고(power_fireball_control cooldown=80, 증원은 별도 값), 선택하면 GUI_MODE_POWER_1이 되어 맵에서 지점을 클릭한다. Origins의 세 주문(번개·증원·영웅 주문)은 krli #493에서 확인된다. '붉은' 조준 표식은 확인하지 못했다. …
- [blizzard-06·partly] (Warcraft III (Classic/Reforged)) Warcraft III: Reforged 2.0.0 패치부터 재사용 대기 중인 버튼 위에 남은 시간 숫자가 기본으로 표시되고, 옵션에서 끌 수 있다. ※ 숫자를 켜고 끄는 옵션 자체는 있다. 2.0 시기 문자열(독일어)에 SHOW_COOLDOWN_TIMER('재사용 대기 숫자 카운트다운 표시')가 있다. 그런데 1.35까지의 Reforged 우크라이나어 globalstrings에서도 같은 키가 '1.32 WebUI Strings' 구역에 이미 들어 있다. 그래서 옵션은 2.0.0보다 앞선 1.32 무렵부터 …
- [pvz_frostpunk-03·partly] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 재충전 중인 카드는 카드 위쪽을 '남은 비율 × 68px + 2px' 높이만큼 진한 회색(64,64,64)으로 덮어 그리고, 시간이 지나면 덮인 부분이 위로 줄어들어 밝은 부분이 아래에서 위로 차오른다. ※ 위쪽을 68*비율+2 높이만큼 (64,64,64)로 덮어 그리고, 덮인 부분이 위로 줄어드는 것은 코드와 같다. 그런데 DrawSeedPacket은 thePercentDark>0이면 카드 전체에도 먼저 (128,128,128)을 입힌다. 그래서 재충전 중에는 차오른 아래쪽도 반 밝기이고, 다 차야 원래 밝기로 돌아온다. '밝은 부분이 차오른다'는 이 점에서…
- [p_cooldown_hotkey-01·partly] (World of Warcraft (리테일)) WoW 리테일 행동 단추의 기본 재사용 대기는 아이콘 안쪽(사방 3px 안)을 덮는 Cooldown 위젯이 그리며, 검정 불투명도 0.64의 막이 아이콘 위를 쓸어 가며 줄어들고, 가장자리 밝은 선(drawEdge)과 끝날 때 반짝임(drawBling)은 꺼져 있다. ※ WebSearch 한도가 다 차서 검색은 한 번도 돌지 못했다. 그래서 GitHub 원본을 직접 읽어 확인했다. Gethe live의 ActionButtonTemplate.xml에서 일반 cooldown은 아이콘 기준 사방 3px 안쪽, drawBling=false, drawEdge=false, SwipeTexture 검정 a=0.64가 맞다. 다른 미러인…
- [p_cooldown_hotkey-02·partly] (World of Warcraft (리테일)) WoW 행동 단추는 대기 종류마다 막을 다르게 그린다: 충전형 기술의 재충전(chargeCooldown)은 어두운 막 없이(drawSwipe=false) 가장자리 선만 돌고 숫자를 숨기며, 기절·침묵 같은 행동 불가(lossOfControlCooldown)는 짙은 빨강(0.17,0,0, 불투명도 0.64) 막과 전용 가장자리 텍스처(UI-HUD-ActionBar-LoC)를 쓴다. ※ 원본과 맞는 부분: chargeCooldown은 drawSwipe=false, hideCountdownNumbers=true다. lossOfControlCooldown은 막 색 (0.17,0,0,a=0.64)에 EdgeTexture Interface\Cooldown\UI-HUD-ActionBar-LoC를 쓰고 숫자를 숨긴다. ActionButton_Appl…
- [p_cooldown_hotkey-15·partly] (OpenRA) OpenRA의 생산·지원 능력 아이콘은 진행 중이면 가운데에 남은 시간 글자(검은 외곽선)를, 끝나면 'READY'(기본은 금색과 번갈아 깜빡임), 멈추면 'ON HOLD'를 겹쳐 쓰고, 지금 만들 수 없는 항목에는 어두운 덮개를 씌운다. ※ 생산 팔레트(ProductionPaletteWidget)는 주장과 같다. DrawTime 기본 true, 가운데에 FormatTime을 쓰고 DrawTextWithContrast로 검은 외곽선을 두른다. 완료되면 ReadyText를 쓰고, 기본 AlternatingColor라서 흰색과 Gold를 번갈아 보인다. 일시정지면 HoldText를 쓴다. 지금 만들…
- [ironhide-20·likely] (Iron Marines) Iron Marines에서 영웅이 죽으면 영웅 아이콘 둘레에 재사용 대기 막대가 돌고, 막대가 다 차면 영웅을 다시 전장에 내보낼 수 있다.
- [ironhide-21·likely] (Iron Marines) Iron Marines의 Dropgun은 자원이나 시설 없이 재사용 대기만 차면 쓰는 버튼으로, 아이콘을 누른 뒤 맵 위 목표 지점을 고르면 그곳에 떨어지며 떨어진 자리의 적에게 피해를 준다.

## 웨이브 미리보기·출현 지점 (wave_preview_spawn)
- [ironhide-06·verified] (Kingdom Rush 시리즈) Kingdom Rush에서 웨이브를 일찍 부르면 원래 도착까지 남은 초만큼 골드를 받고, 주문 재사용 대기도 그만큼 줄어든다.
- [td_bars-md-08·verified] (Mindustry) 화면 왼쪽 위 웨이브 상태 칸에는 «Wave 3/30»(승리 웨이브가 정해진 경우), «N Enemies Remaining», 다음 웨이브까지 «Wave in 1:05» 형식의 카운트다운이 줄마다 표시된다.
- [td_bars-md-13·verified] (Mindustry) 수호자(보스)가 든 웨이브가 10·5·2·1웨이브 앞으로 다가오면 경고 아이콘이 붙은 토스트로 «Guardian approaching in N waves»를 띄우고, 보스가 나오면 위 가운데에 320×60 크기의 보스 체력 막대를 보여 준다.
- [td_bars-rt-08·verified] (Rogue Tower) Rogue Tower의 경로는 직선(S)·좌(L)·우(R)·갈림길(SL/SR/LR/SLR)·포털(P) 타일이 «Expand»할 때마다 이어 붙는 방식이며, 모드 제작자는 «확장한 순서대로 타일이 나타난다»고 설명한다.
- [pvz_frostpunk-09·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 레벨 진행 막대는 화면 오른쪽 아래(800×600 기준 x=600, y=575)에 있고, 진행할수록 막대가 오른쪽에서 왼쪽으로 채워지며 좀비 머리 아이콘이 채워진 끝을 따라 왼쪽으로 움직이고, 그 아래에 '레벨 진행' 표지 그림이 붙는다.
- [pvz_frostpunk-10·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 깃발 웨이브는 10웨이브마다 오고(처음 하는 모험 모드에서 웨이브가 10개 안 되는 레벨은 그 레벨 웨이브 수마다), 진행 막대 위 그 웨이브 비율 자리에 깃대와 깃발이 그려지며, 지나간 깃발은 14px 올라간 모습으로 바뀐다.
- [p_wave_menu-02·verified] (Mindustry) Mindustry 웨이브 표의 오른쪽 끝에는 폭 40px짜리 재생(▶) 아이콘 버튼이 붙어 있어 누르면 다음 웨이브를 바로 부르고, 이 버튼은 맵에 적이 0마리이며 적 생성이 끝난 때만 눌리며, 그 밖에는 아이콘이 투명해지고 글자 칸이 그 자리까지 넓어진다.
- [p_wave_menu-03·verified] (Mindustry) Mindustry는 맵 위의 적 출현 지점마다 «드롭 존» 반경을 회색과 밝은 회색 사이로 깜박이는 점선 원으로 그리는데, 플레이어가 그 반경에서 11칸 안쪽까지 다가올 때만 거리에 따라 서서히 나타난다.
- [p_wave_menu-05·verified] (Thronefall) Thronefall은 얼리액세스 1.1 업데이트에서 일시정지 메뉴에 «Upcoming Night Info»를 넣었다. 다음 밤에 공격해 올 적의 요약을 보여 주고, 적마다 짧은 설명도 읽을 수 있게 했다.
- [p_wave_menu-06·verified] (Thronefall) Thronefall의 밤(전투)은 타이머로 저절로 시작되지 않는다. 플레이어가 «Call Night» 동작(조작 설정 이름 «Start Night»)을 일정 시간 누르고 있어야 시작되며, 낮 시간이 지나면 밤이 저절로 오는 것은 «Durststein Speedrun» 같은 일부 모드뿐이다.
- [p_wave_menu-07·verified] (Bloons TD 6) BTD6 PC용 모드 Useful Utilities는 1.3.4(2025-07-30)에서 게임 안 «Bloons» 차트를 추가했다. 이 차트는 이번 라운드에 들어올 풍선을 보여 주고 다른 라운드의 풍선도 볼 수 있게 하며, 1.3.5부터는 라이브 모드에서 현재 라운드 풍선이 다 나오면 다음 라운드 풍선으로 저절로 넘어간다.
- [ironhide-04·partly] (Kingdom Rush Frontiers / Alliance) Kingdom Rush Frontiers와 Alliance에서 다음 웨이브는 맵 위 해골 아이콘으로 표시되며, 한 번 누르면 다가오는 적 정보가 보이고 두 번 누르면 웨이브를 일찍 부른다. ※ Steam Love2D 코드(KR1~3 공용, Frontiers 포함)에서 WaveFlag는 각 경로 입구(level.locations.entrances) 옆에 뜬다. 마우스를 올리면 incoming_tooltip(적 이름×수)이 보이고, 한 번 클릭하면 바로 웨이브를 부른다(on_click→send_next_wave). '한 번=정보, 두 번=호출'은 모…
- [tab-06·partly] (They Are Billions) 큰 무리(swarm)가 나타나기 전에 'Zombie swarm detected near the colony from the X'(X는 동서남북 중 하나) 창이 뜨고, 무리가 생길 때까지 남은 게임 시간 카운트다운이 함께 나오며 음악이 바뀐다. ※ 예고 시점은 게임 데이터로 확인된다. TABSAT의 SaveReader.cs에 담긴 세이브 값(StartTimeH/StartNotifyTimeH)을 보면 일반 무리는 시작 8시간 전(Easy 312/304, Hard 1210/1202), 최종 무리는 24시간 전(2208/2184)에 예고된다. 100일·80일·50일 설정 모두 간격이 같다. TABSAT 문…
- [pixel_minimal-06·partly] (Dome Keeper) 웨이브 미터의 시간 막대 길이는 웨이브 간격 4초당 1px(secondsPerPixel = 4)로 정해진다. 채움 막대는 다음 웨이브까지의 쿨다운 진행에 비례해 늘어나고, 막대 왼쪽에 웨이브 번호(최대 99)가 붙는다. ※ 맞는 점: secondsPerPixel=4이고 막대 최대 길이는 floor(웨이브 간격/4)px다. 웨이브 번호는 min(99, cycle+1)이고 라벨이 HBox 맨 앞(왼쪽)에 있다. repellent를 사면 DelayBar가 붙는다. 틀린 점: 채움 막대 goalRectSize=(max-1)×wavecooldown/간격이다. Monsters.gd에서 …
- [pvz_frostpunk-13·partly] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 레벨 시작 컷신에서 카메라가 오른쪽 길거리로 이동하면, 이번 레벨 모든 웨이브에 나올 좀비 종류가 길에 서 있고, 종류마다 마릿수는 '그 종류 수 × 미리보기 정원 ÷ 전체 수'(최소 1)로 정해진다(정원은 보통 10, 일부 레벨 15·18). ※ 정원 10/15/18, '수×정원÷전체(최소 1)' 공식, 깃발 좀비 제외, 팬 1500~3500은 윈도폰 디컴파일 CutScene에서도 똑같이 확인된다. 그러나 '종류마다 이 공식'은 틀린 부분이 있다. 2×2 좀비(거대 좀비 등)와 잠보니는 비율과 상관없이 한 마리씩만 놓는다. 번지 좀비는 1마리로 고정된다. 예티는 Stormy Night가 아니면, 봅…
- [p_wave_menu-01·partly] (Mindustry) Mindustry는 화면 왼쪽 위 웨이브 표에 «Wave N»(승리 웨이브가 정해져 있으면 «Wave N/M»), 남은 적 수(«N Enemies Remaining»), 다음 웨이브까지 남은 시간(«Wave in 1:05» 같은 분:초, 진행 중이면 «Wave in progress»)을 한 줄씩 나눠 보여 준다. ※ WebSearch 예산이 다 떨어져 웹 교차 확인은 못 했다. GitHub 원본 코드로만 확인했고 master와 v146 릴리스가 같다. «Wave N»과 «Wave N/M»(winWave>1일 때), 남은 적 수, 분:초 카운트다운, 수호자 경고(10·5·2·1 웨이브 전 토스트)는 맞다. 틀린 점은 «Wave in progress»가 웨이브가 진행 중일…
- [p_wave_menu-04·partly] (Kingdom Rush) Kingdom Rush의 웨이브 호출 버튼은 1920×1080 화면 기준 지름 약 72~80px의 원형 해골 배지다. 출현 입구 옆에 입구마다 하나씩 놓이고, 주황 테두리 링이 대기 시간이 줄어드는 만큼 줄어드는 카운트다운 게이지 역할을 하며, 누르면 다음 웨이브가 바로 시작되고 남은 시간에 비례한 보너스 골드를 준다. ※ STYLE_BIBLE §5.4와 §8.9의 내용과는 맞는다. 하지만 지름 72~80px, 주황 링(#E8701C), 좌표는 이 한 문서의 스크린샷 측정뿐이고 다른 뒷받침이 없다. 링이 줄어드는 카운트다운 게이지라는 점과 '1초당 약 1골드'는 측정한 절이 아니라 메커니즘 추정 절(§8)에서 나온다. 원문에는 '웨이브 번호에 따라 달라짐(scaled by w…
- [ironhide-07·likely] (Kingdom Rush Origins / Vengeance) Kingdom Rush Origins와 Vengeance에서는 웨이브가 오기 전 경로에 표식(배너)이 떠서, 적이 어느 방향으로 행군할지 미리 알려 준다.
- [tab-07·likely] (They Are Billions) 다음 무리가 오기까지 남은 시간(다음 침공 타이머)은 팝업이 아니라 화면 왼쪽 아래에 늘 떠 있다.
- [aod-08·likely] (Age of Darkness: Final Stand) 다음 Death Night까지 남은 시간을 보여 주는 카운트다운 타이머가 있고, 다섯 번째 Death Night가 끝나면 10분짜리 최종 웨이브 타이머가 돌기 시작한다.
- [aod-09·likely] (Age of Darkness: Final Stand) 나이트메어 무리의 출발지는 지도에 드러나는 거대한 수정(크리스탈)으로 표시되어 대략의 공격 방향을 알 수 있지만, 플레이어들은 밤안개 가장자리가 옅게 보이는 정도의 단서로는 부족하다며 공격 직전의 방향 표시를 요구했다.
- [aoe_northgard-19·likely] (Northgard) Northgard는 화면 왼쪽 아래 미니맵 바로 위에 달력 막대를 둔다. 막대는 한 칸이 한 달이고, 겨울 구간은 하얀 눈 덮인 칸으로 칠해진다.
- [aoe_northgard-20·likely] (Northgard) Northgard 달력은 다가오는 재난(눈보라·지진·쥐 떼 등)을 일어날 달의 칸에 아이콘(느낌표)으로 표시하고, 보통 3달 전에 미리 알린다.
- [castle-16·likely] (Diplomacy is Not an Option) 미니맵에 뿔 달린 투구 아이콘이 다음 적 웨이브가 나올 지점을 표시하고, 후반 웨이브는 여러 지점에서 나오므로 투구도 여러 개가 된다.
- [minimal-01·likely] (Thronefall) Thronefall의 낮(건설) 단계에는 맵의 각 적 출현 지점에 작은 빨간 아이콘이 떠서, 그날 밤 그 지점에서 나올 적 유닛 수를 미리 보여 준다.
- [minimal-02·likely] (Thronefall) Thronefall의 출현 지점 예고 아이콘은 적을 근접·원거리·비행으로 나눈 종류 아이콘과 종류별 수를 함께 보여 준다.

## 경보·화면 밖 (alerts_offscreen)
- [blizzard-11·verified] (Warcraft III (Classic/Reforged)) WC3에서 스페이스바를 누르면 카메라가 마지막 알림(공격 경보·유닛 완성 등)이 난 위치로 가고, 다시 누르면 이전 알림들을 최대 8개까지 거슬러 차례로 돈다.
- [blizzard-25·verified] (StarCraft II) StarCraft II에서 스페이스바를 누르면 카메라가 마지막 경보(예: '기지가 공격받고 있습니다')가 난 곳으로 가고, 다시 누르면 이전 경보들을 차례로 돈다.
- [blizzard-27·verified] (StarCraft II) StarCraft II에서는 내 유닛이 공격받으면 미니맵의 그 자리에 붉은 경보 표시가 맥동하듯 깜박인다.
- [td_bars-md-12·verified] (Mindustry) 코어가 피해를 입으면 위 가운데 자원 표시 바로 아래에 «< Core is under attack! >» 글자가 주황과 빨강 사이로 깜빡이며 약 4초(240틱) 떠 있고, 이 글자를 누르면 카메라가 마지막으로 맞은 코어로 옮겨 간다.
- [pixel_minimal-08·verified] (Dome Keeper) 웨이브가 진행되는 동안 키퍼가 조종석(스테이션)에 없으면, 웨이브 미터의 적 아이콘 섬광이 0.1초 켜지고 0.9초 꺼지기를 반복하며 켜질 때마다 alarm 효과음이 울린다. 키퍼가 조종석에 있으면 섬광은 계속 켜져 있다.
- [pixel_minimal-09·verified] (Dome Keeper) 웨이브 경보 업그레이드(물 1)를 사면, 키퍼가 돔에서 150px 넘게 떨어져 있을 때 경고가 나온다. 웨이브까지 남은 시간이 1.5 + (6 + 거리×0.01) × 보정값 초 아래로 내려가는 순간 경고음 3회와 아이콘 점멸이 나온다. 보정값은 그동안 늦게 또는 일찍 돌아온 기록에 따라 플레이어마다 0.5~2.0 사이에서 조정된다.
- [pixel_minimal-10·verified] (Dome Keeper) 귀환 경로 업그레이드(물 1)는 경고 시점에 키퍼 위치에서 돔까지의 경로선을 맵 위에 0.4초에 걸쳐 투명도 0.6까지 서서히 그린다. 키퍼가 돔에 들어오거나 웨이브가 끝나면 선을 지운다.
- [pvz_frostpunk-11·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 깃발 웨이브 직전에 화면 가운데 높이(y=330)에 빨간(255,0,0) HouseOfTerror 28 글꼴로 [ADVICE_HUGE_WAVE] 글자가 페이드 인으로 떠서 750틱 동안 머물고, 이 750틱 카운트다운이 끝나야 그 웨이브 좀비가 나온다.
- [pvz_frostpunk-12·verified] (Plants vs. Zombies (PC GOTY, 디컴파일 소스)) 웨이브 경보는 소리로도 겹쳐 나온다: 큰 웨이브 카운트다운 725틱에 HUGE_WAVE 효과음, 깃발 웨이브가 나올 때 사이렌, 첫 웨이브에 AWOOGA 경적이 울리고, 마지막 웨이브에는 UI보다 위 층에 FINAL_WAVE 애니메이션을 띄운 뒤 60틱 뒤 FINALWAVE 효과음이 난다.
- [p_alerts_camera-02·verified] (OpenRA (Red Alert 모드)) OpenRA의 DamageNotifier는 내 건물이 공격받으면 미니맵(레이더)에 빨간 핑을 250틱(기본 속도 40ms/틱이면 10초) 동안 띄우고, 음성 알림과 «Base under attack.» 글줄을 낸 뒤, 다음 알림까지 최소 30000ms를 기다린다.
- [p_alerts_camera-10·verified] (Beyond All Reason (Point Tracker·Mapmark) Beyond All Reason의 Point Tracker 위젯은 아군이 찍은 지도 표시(point)를 플레이어 색 십자선으로 그리고, 그 자리가 화면 밖이면 십자선 중심을 화면 가장자리에 붙여(clip 공간 −1~1로 clamp) 방향을 보여 주며, 같은 표시를 미니맵에도 그리고, 330게임프레임 동안 점점 투명하게 만든다.
- [p_alerts_camera-11·verified] (Mindustry (타워 디펜스·RTS 혼합)) Mindustry는 설정 «Enemy Indicators»를 켜면 카메라 화면 90% 크기 사각형 밖에 있는 적 유닛마다 팀 색의 짧은 선을 플레이어에게서 14 단위 떨어진 자리에 그 적 방향으로 그리고, 안개(fog) 규칙이 켜진 판에서는 그리지 않는다.
- [p_alerts_camera-12·verified] (Mindustry) Mindustry는 내 코어가 피해를 입으면 HUD 위쪽 가운데에 반투명 검은 띠와 «< Core is under attack! >» 글자를 240틱(초당 60틱이면 4초) 동안 띄우고 글자색을 주황과 진홍 사이로 맥박처럼 바꾸며, 일시정지 중에는 숨긴다.
- [blizzard-12·partly] (Warcraft III (Classic/Reforged)) WC3는 내 유닛이나 마을이 공격받으면 경보 음성과 함께 미니맵에 붉은 핑을 띄우고, 카메라 중심에서 정해진 알림 거리(기본 1250) 안에서 일어난 공격에는 경보를 띄우지 않는다. ※ 원작 Units/MiscData.txt에 'AttackNotifyDelay=30.0'(공격 알림 사이 간격, 초)과 'AttackNotifyRange=1250'이 있어 숫자와 위치는 맞다. war3skins에는 종족별 UnderAttack/TownAttack 소리 칸이 있다. 다만 1250이 '카메라 중심에서의 거리'로 경보를 억제하는 값이라는 해석과 붉은…
- [aoe_northgard-13·partly] (Age of Empires IV) AoE IV는 '마지막 사건(알림)으로 카메라 이동'을 기본 Space 키에 묶어 두었고, 보조 키는 숫자패드 Enter다. ※ Space는 맞다. 두 키 프로필의 기본값 영역에 focus_event_cue=Space가 있다. 하지만 보조 키 자리는 두 프로필 모두 비어 있다. 같은 영역에서 다른 명령은 보조 키가 기록돼 있으니, 지금 기본값에는 숫자패드 Enter 보조 키가 없을 가능성이 크다. 2021년 공개 목록과 현재 판이 다를 수 있다.
- [aoe_northgard-23·partly] (Northgard) Northgard는 공격·건물 관련 알림을 화면 왼쪽에 아이콘으로 띄운다. 군사 경로·명성(renown) 팝업은 옵션 > 게임플레이에서 팝업 대신 이 알림 아이콘으로 바꿀 수 있다. ※ 틀린 점은 찾지 못했고, 이 판정은 왼쪽 위치를 확인 못 했다는 뜻이다. 옵션 부분은 게임 텍스트로 확인했다. 게임플레이 > 일반에 'Set Fame and Military popup to notifications' 항목이 있다. 공격·건물 알림이 화면 왼쪽에 아이콘으로 뜬다는 위치는 확인하지 못했다.
- [p_alerts_camera-04·partly] (0 A.D.) 0 A.D.의 AttackDetection은 내 개체가 공격받으면 미니맵 핑 메시지·화면 알림(type "attack")·'attacked' 소리를 내되, 앞선 알림 지점에서 160m 안에서 난 공격은 60초 동안 새로 알리지 않고, 80m 안에서 난 공격은 억제 중인 사건의 위치만 새것으로 바꾼다. ※ 웹검색이 불가해 원본 코드로 대조했다. 수치(80/160/60000), 가축의 낮은 우선순위와 승격, attacked_capture·_gaia 소리 묶음은 맞다. 틀린 부분이 둘 있다. (1) 미니맵 핑(MT_MinimapPing)은 억제와 상관없이 OnGlobalAttacked에서 공격마다 보낸다(L51, AttackAlert보다 먼저). 억제되는 것은 …
- [p_alerts_camera-08·partly] (Beyond All Reason (Recoil/Spring 엔진 RTS)) Beyond All Reason은 '공격받음' 음성을 대상별로 나눠 재생 간격을 사령관 10초, 사령관 체력 20% 미만(ComHeavyDamage) 10초, 공장·경제 건물 30초, 일반 유닛·방어 탑 60초로 두고, 상위 경보가 울리면 하위 경보의 간격 타이머도 처음부터 다시 센다. ※ 웹검색이 불가해 원본 코드로 대조했다. delay 값(Commander 10, ComHeavyDamage 10, Factory·Economy 30, Units·Defense 60), 피해 5 미만 무시, 적 allyTeam 공격만 센다는 점, 체력 20% 미만이면 ComHeavyDamage로 대체된다는 점, SC2 Alert enum은 맞다. 틀린 부분이 …
- [tab-10·likely] (They Are Billions) 기본 설정에서는 지금 보고 있는 화면 밖의 사건에만 경보가 뜨고, 설정의 'Show Visible Alerts'(기본값 꺼짐)를 켜면 화면 안의 사건에도 경보가 뜨지만, 플레이어들은 경보가 일관되게 뜨지 않는다고 지적했다.
- [aod-11·likely] (Age of Darkness: Final Stand) 방어 시설이 공격받으면 미니맵에 'Defence is under attack' 아이콘이 뜨고, 성채(Keep)가 공격받으면 'Keep under attack'이라는 별도 UI가 표시된다.
- [aod-13·likely] (Age of Darkness: Final Stand) 베테랑 플레이어의 피드백 스레드는 경보를 믿기 어렵고 전투 중에 놓치기 쉽다고 했고, 인도네시아 리뷰(Esportsnesia)는 갑작스러운 공격 알림이 더 눈에 띄어야 한다고 평가했다.

## 미니맵 (minimap)
- [tab-08·verified] (They Are Billions) 무리가 맵에 생기면 미니맵에 노란 해골 아이콘으로 표시되지만, 플레이어들은 이 아이콘이 이리저리 튀고 무리가 갈라져도 해골이 하나뿐이라고 불평했다.
- [blizzard-26·verified] (StarCraft II) StarCraft II에서 Alt+G를 누른 뒤 클릭하면 미니맵에 핑이 찍히고, 본 화면에서 Ctrl+Alt+클릭으로도 미니맵에 신호를 보낼 수 있다.
- [td_bars-md-14·verified] (Mindustry) 미니맵은 화면 오른쪽 위의 140px 정사각 칸이며, 우클릭한 지점으로 카메라가 옮겨 가고, 좌클릭하면 큰 지도 화면이 열리며, 마우스 휠로 확대·축소된다.
- [pixel_minimal-17·verified] (Kingdom Two Crowns) 인기 모드 OverlayMap(M 키)은 화면 위쪽에 지도 레이어를 덧그린다. 성·성벽·관심 지점은 기호와 3색(빨강 미해금·파괴, 파랑 건설 중, 초록 안전)으로 표시하고, 놀고 있는 주민·일꾼·궁수·농부 수와 시각, 섬 번호, 보석·동전 수를 'Coins: N' 같은 글자로 띄운다.
- [p_alerts_camera-05·verified] (0 A.D.) 0 A.D. 미니맵은 공격 알림을 받은 개체의 점을 pingduration 50초 동안 흰색으로 깜박이고(blinkduration 1.7초 주기), 깜박이는 점을 다른 점들 위에 그린다.
- [p_alerts_camera-07·verified] (Stratagus (Warcraft II 데이터용 오픈소스 엔진)) Stratagus는 내 유닛이 공격받으면 미니맵에 빨간 원을 미니맵 짧은 변의 1/3 반지름으로 그렸다가 그릴 때마다 1px씩 줄여 없애고(동시에 최대 8개), «<유닛> attacked» 메시지를 남기며, 도움 요청 음성은 2초에 한 번까지만, 같은 구역(±14칸)에서는 2분에 한 번까지만 낸다.
- [blizzard-02·partly] (Warcraft III (Classic/Reforged)) WC3 화면 왼쪽 아래 미니맵 바로 옆에는 아군/적 색 전환(Alt+A), 대형 이동 전환(Alt+F), 지형 표시 같은 작은 토글 버튼이 붙어 있고, 리플레이에서는 이 버튼들이 회색으로 꺼진다. ※ 원작 GlobalStrings.fdf에 미니맵 버튼 툴팁이 있다. Minimap Signal(Alt-G), Toggle Minimap Terrain(Alt-T), Set Ally Color Mode(Alt-A), Minimap Creep Display(Alt-R), Toggle Formation Movement(Alt-F)이고, 핑은 미니맵이나 본 화면을 …
- [aoe_northgard-03·partly] (Age of Empires IV) AoE IV 미니맵 옆 구석의 명령 패널에는 아군에게 보내는 핑 3종(알림·공격·방어)이 있고, 기본 단축키는 Ctrl+E·Ctrl+R·Ctrl+T를 누른 뒤 왼쪽 클릭이다. ※ 키는 맞다. 서로 다른 두 사용자의 AoE4 키 프로필(.rkp)의 fullyRemappable 기본값 영역에 ping_question=Control+E, ping_attack=Control+R, ping_defend=Control+T가 같게 들어 있다. 미니맵 확대 단계 키(minimap_cycle_zoom_level)도 M이다. 다만 첫 핑의 내부 이름…
- [tab-02·likely] (They Are Billions) 미니맵은 탐험한 땅만 보여 주고, 자기 콜로니는 초록, 적은 빨강으로 찍으며, 적은 건물이나 유닛이 보고 있을 때만 나타난다.

## 일시정지·배속 (pause_speed)
- [td_bars-md-09·verified] (Mindustry) 웨이브 건너뛰기 버튼은 상태 칸 오른쪽에 붙은 너비 40의 재생(▶) 아이콘이며, 남은 적이 0이고 생성 중이 아닐 때만 누를 수 있고, 그 밖에는 아이콘이 투명해지면서 글자 칸이 그 자리까지 넓어진다.
- [td_bars-bt-08·verified] (Bloons TD 6) Space 키 하나가 «시작/빨리 감기»를 함께 맡아서, 라운드가 멈춰 있을 때 한 번 누르면 라운드가 시작되고 한 번 더 누르면 빨리 감기가 켜진다.
- [td_bars-bt-09·verified] (Bloons TD 6) 빨리 감기의 기본 배속은 3배이다.
- [td_bars-bt-10·verified] (Bloons TD 6) BTD6 게임 UI 스프라이트에는 GoBtn, FastForwardBtn, FastForwardGlowBtn, NextRoundbtn이 따로 있다.
- [td_bars-bt-11·verified] (Bloons TD 6) BTD6 설정에는 다음 라운드를 자동으로 시작하는 «Autostart», 드래그 앤 드롭 배치, «Nudge» 모드 토글이 있다.
- [pixel_minimal-27·verified] (Loop Hero) 원정 중 일시정지 메뉴(o_menu)는 원정 내내 존재하다가, 일시정지 상태(global.menu_open)일 때만 화면 안으로 미끄러져 들어온다.
- [p_disabled_modal-15·verified] (게임 일시정지 화면 배경 (0 A.D. / Mindustry / Godo) 세 게임 모두 일시정지 화면은 전체 화면을 검정 반투명으로 덮지만 불투명도는 다르다. 0 A.D.는 검정 185/255(약 73%) 위, 화면 40% 높이 가운데에 'Game Paused'와 'Click to Resume Game'을 쓴다. Mindustry 기본 대화창은 검정 90% 배경(stageBackground)을 깔고 일시정지 대화창이 열리면 게임 상태를 paused로 바꾼다. Godot 공식 2D 플랫포머 데모는 전…
- [tab-05·likely] (They Are Billions) 스페이스바로 게임을 멈춘 상태에서도 건물 배치, 군대 명령, 정보 확인을 할 수 있고, 멈춘 동안 배치한 건물은 정지를 풀어야 짓기 시작한다.
- [aod-07·likely] (Age of Darkness: Final Stand) 일시정지는 난이도에 묶여 있어서 최고 난이도 Nightmare와 사용자 설정의 가장 긴 게임 길이에서는 꺼지고, 일시정지가 되는 판에서는 시간과 적이 멈춘 채로 카메라 이동·선택·건설·명령을 할 수 있다.
- [minimal-11·likely] (Bad North) Bad North에서는 부대를 고르는 순간 시간이 크게 느려지고, 목적지를 고르는 동안 느린 상태가 이어지며, 이동 명령을 내리면 다시 정상 속도로 돌아간다.
- [minimal-12·likely] (Bad North) Bad North에는 정식 일시정지 버튼이 없고(PC Gamer) 빨리감기 기능도 없으며, 스팀 토론에서 플레이어들이 빨리감기와 자동 일시정지를 요청했다.
- [minimal-14·likely] (Bad North) Bad North는 창 포커스를 잃으면 자동으로 일시정지하고, 공식 패치 1.05 노트에 따르면 NoAutoPause 명령줄 인자로 이 기능을 끌 수 있다.

## 모달·팝업 (modal_popup)
- [pixel_minimal-14·verified] (Dome Keeper) 게임이 끝나면 HUD 전체가 0.3초 큐빅 트윈으로 화면 아래로 미끄러져 사라진다(Level.moveHudOut). 조종석·전투 팝업도 0.3초 트윈으로 화면 아래 가장자리에서 들어오고 나간다.
- [p_disabled_modal-10·verified] (The Battle for Wesnoth 징집 창) Wesnoth 징집 창은 지금 뽑을 수 없는 유닛도 목록에 남기되, 초상은 회색조(~GS)로, 이름과 비용 숫자는 비활성 색으로, 금화 아이콘도 회색조로 바꾼다. 그 줄에 마우스를 올리면 'You do not have enough gold to recruit this unit.' 같은 이유를 툴팁으로 띄운다.
- [td_bars-rt-04·partly] (Rogue Tower) 업그레이드 카드를 고를 때는 화면 가운데에 카드 6장이 가로 한 줄로 맵 위에 겹쳐 뜨고, 카드마다 위에 제목, 가운데에 큰 단색 아이콘, 아래에 한두 줄 설명이 놓인다. ※ 스크린샷에서 카드 6장이 가로 한 줄로 맵 위에 겹쳐 있다. 위에 제목, 가운데에 큰 단색 아이콘, 아래에 1~3줄 설명이 있고, 배경 어둡게 처리는 보이지 않는다. 그러나 6장은 고정값이 아니다. 영구 업그레이드 'Card Draw I~III'의 설명이 'Draw an additional card when you draw upgrade cards'(tra…
- [p_disabled_modal-14·partly] (모달 스크림 불투명도 (Material 2·3 / Fluent 2 / B) 모달 대화창 뒤에 화면 전체를 덮는 스크림의 불투명도는 Material 2(MDC Web)가 on-surface 색 32%, Material 3(material-web)가 scrim 색 32%(모달 내비게이션 서랍도 32%)다. 이와 달리 Microsoft Fluent 2는 검정 40%(밝은 테마)·50%(어두운 테마), Bootstrap 5.3은 검정 50%다. ※ 주요 수치는 모두 코드와 같다. MDC dialog의 $scrim-color는 on-surface, opacity는 0.32다. material-web dialog의 .scrim은 sys scrim 색에 opacity 32%다. Fluent의 colorBackgroundOverlay는 밝은 테마 blackAlpha40, 어두운 테마 blackAlpha50이…
- [castle-12·likely] (Stronghold Crusader: Definitive Edition) FireFly Studios는 출시 전 설명에서, DE의 메뉴 대부분을 패널 방식으로 바꿔 중간에 거치던 화면 일부를 없애면서도 원작 느낌은 지켰다고 했다.

## 단축키 (hotkeys)
- [blizzard-19·verified] (StarCraft II) StarCraft II의 Grid 단축키 프로필은 명령 카드의 각 칸을 키보드에서 같은 자리에 있는 키 하나(모두 15키)에 묶는다.
- [aoe_northgard-04·verified] (Age of Empires IV) AoE IV의 기본 단축키 방식은 '격자 키(Grid Keys)'다. 화면 아래 가운데에서 약간 왼쪽에 있는 명령 격자의 칸 위치가 키보드 왼쪽 키 배치와 대응하고, 칸의 아이콘이 바뀌어도 같은 칸은 같은 키로 눌린다.
- [aoe_northgard-07·verified] (Age of Empires IV) AoE IV 기본 단축키에서 마침표(.)는 놀고 있는 경제 유닛(일꾼·교역 수레·어선 등)을 하나씩 돌며 고르고, Ctrl+마침표는 놀고 있는 일꾼을 한꺼번에 고른다.
- [aoe_northgard-24·verified] (Northgard) PC판 Northgard는 Space 키를 '알림으로 이동'에 묶어 두었다.
- [aoe_northgard-28·verified] (Northgard) PC판 Northgard에는 G로 주민, H로 정찰병, U로 놀고 있는 유닛·일꾼을 고르는 선택 단축키가 있다.
- [td_bars-md-06·verified] (Mindustry) 데스크톱에서는 숫자키 1~0을 0.4초 안에 두 번 눌러 «범주 고르기 → 블록 고르기»를 하고, 쉼표·마침표로 이전·다음 범주로 넘어가며, 정보 칸의 블록 이름 아래에 «Key: [1,3]» 같은 조합이 회색으로 표시된다.
- [td_bars-md-10·verified] (Mindustry) 기본 키 배치에서 웨이브 건너뛰기 키는 비어 있고(unset), Space는 일시정지, C는 메뉴(HUD) 전체 켜기·끄기, M은 미니맵에 묶여 있다.
- [td_bars-rt-06·verified] (Rogue Tower) 전투 화면 오른쪽 위에는 «P or Esc: Pause game / Hold shift: Smooth cam & fast tower placement / H: Hide UI / C: Recenter camera / T: Show damage & tower stats» 단축키 안내가 글자로 늘 떠 있다.
- [td_bars-bt-07·verified] (Bloons TD 6) PC판 기본 단축키는 타워마다 글자 키 하나(Dart Q, Boomerang W, Bomb E, Tack R … 영웅 U), 업그레이드 경로 위·가운데·아래에 쉼표·마침표·슬래시, 표적 바꾸기에 Tab, 판매에 Backspace를 쓴다.
- [pixel_minimal-26·verified] (Loop Hero) 인벤토리의 장비를 우클릭하면 그 장비가 잠기고(핀) 인벤토리 맨 앞으로 옮겨진다.
- [p_disabled_modal-13·verified] (단축키 표시 위치 (Polaris / Unciv / OpenRA / Mi) Shopify Polaris는 아이콘만 있는 버튼과 단축키가 있는 버튼에 툴팁을 달고, 단축키는 툴팁 본문 옆 접미(suffix)로 보이라고 한다. Unciv(오픈소스 문명 5 리메이크)는 단축키 툴팁을 버튼 오른쪽 위 모서리에 살짝 걸쳐 띄우고, 키보드가 없는 기기에서는 자동으로 숨긴다.
- [p_cooldown_hotkey-07·verified] (World of Warcraft (리테일)) WoW 리테일의 '빠른 단축키 설정(Quick Keybind)' 모드에서는 행동 단추에 마우스를 올리고 키(또는 마우스 휠·추가 마우스 단추)를 누르면 바로 그 키가 묶이고, 툴팁에 동작 이름과 지금 키, 그리고 'Esc로 해제' 또는 '지정 안 됨·키를 누르세요' 안내가 뜬다.
- [p_cooldown_hotkey-11·verified] (Dota 2) Dota 2 단축키 설정에서 'Use Legacy Keys'를 켜면 Dota 1처럼 영웅마다 기술 단축키가 달라지고 Quickcast가 동작하지 않으며, 레거시가 아닌 기본 설정에서 유닛마다 다른 기술 단축키를 쓰려면 'Unit Specific Hotkeys'를 따로 켜야 한다.
- [p_cooldown_hotkey-12·verified] (Beyond All Reason (오픈소스 RTS)) Beyond All Reason의 기본 'Grid' 단축키 프로필은 건설 메뉴 3×4 칸을 화면 위 줄부터 Q W E R / A S D F / Z X C V에 묶고, 범주 선택은 Z X C V, 다음 쪽은 B에 두어 화면의 칸 배치와 키보드 배치를 일치시킨다.
- [p_alerts_camera-01·verified] (OpenRA (C&C/Red Alert 오픈소스 재구현)) OpenRA는 스페이스바(ToLastEvent, «Jump to last radar event»)를 누르면 카메라 중심을 마지막으로 보이게 생긴 레이더 핑 위치(RadarPings.LastPingPosition)로 곧바로 옮긴다.
- [p_alerts_camera-06·verified] (Stratagus (Warcraft II 데이터용 오픈소스 엔진, War) Stratagus는 스페이스바(«center on last action»)를 누를 때마다 위치가 붙은 최근 사건 메시지(최대 10개)를 하나씩 돌아가며 그 칸으로 화면 중심을 옮기고 «Event: …» 문구를 띄운다.
- [ironhide-12·partly] (Kingdom Rush 시리즈 Steam판) Kingdom Rush Steam판은 1·2로 두 주문을, Space로 영웅을 고르고, W(또는 Enter)로 다음 웨이브를 부르며, Esc(또는 P)로 일시정지·메뉴를 연다. ※ Love2D Steam 코드에서 pow_1='1', pow_2='2'(Origins는 3도 있음)다. 영웅은 Space 또는 4(2번째 5)이고, 다음 웨이브는 W 또는 Return이다. Esc는 무언가 선택돼 있으면 선택 해제, 아니면 일시정지 메뉴다. krli #82(W), #1141(Space·4), #400(Origins의 1·3·Space), #1…
- [tab-12·partly] (They Are Billions) 명령 버튼은 5×3 격자로 놓이고, 얼리 액세스 시기에는 건설 단축키가 없어서 플레이어들이 버튼 위치를 Q·W·E 같은 격자 키에 연결하는 AutoHotkey 스크립트를 따로 만들었다. ※ 5×3 격자는 세 곳에서 확인된다. b-adkins는 i_size=5, j_size=3, ryuyandev는 너비/5·높이/3으로 칸을 나누고, QoL 모드는 QWERT/ASDFG/ZXCVB에 대응시킨다. 그러나 '건설 단축키가 없었다'는 부분은 부정확하다. b-adkins 스크립트 주석에 'top-level menus already have hotkeys…
- [blizzard-07·partly] (Warcraft III (Classic/Reforged)) Warcraft III: Reforged에서는 옵션 → 입력 → 미리 정한 키 배치에서 Grid를 고르면 명령 카드 칸 위치대로 키가 묶이고, 2.0.4 패치에서 QWERTY가 아니거나 영어가 아닌 자판에서도 격자 단축키가 동작하도록 고쳤다. ※ Grid 부분은 확인했다. Reforged 문자열에 PRESET_KEYBINDINGS(Classic/Grid/Custom)가 있고, Grid 설명은 '명령 카드의 각 칸을 특정 키에 묶고 모든 유닛 카드에 적용'이다. 2.0 시기 문자열에는 '입력 메뉴에서 키 배치를 Custom으로 바꿔야 이 메뉴가 열린다'는 안내와 SHOW_COMMAND_BUTTON_H…
- [blizzard-20·partly] (StarCraft II) StarCraft II의 옵션 → 게임플레이에서 '명령 단축키 글자(Command Hotkey Text)'를 켜면 단축키가 툴팁이 아니라 각 명령 버튼 위에 직접 표시된다. ※ 기능은 있다. GameButton.SC2Layout의 명령 버튼 템플릿 왼쪽 위에 CommandHotkeyFrame(HotkeyLabel과 배경)이 있어 버튼 위에 단축키를 그린다. 옵션 이름 'Command Hotkey Text'와 메뉴 위치는 확인하지 못했다. 옛 게임 문자열은 SimpleCommandCard 같은 설정을 Gameplay 옵션에 두었지만…
- [p_cooldown_hotkey-04·partly] (World of Warcraft (리테일)) WoW 리테일 행동 단추는 단축키 글자를 오른쪽 위(TOPRIGHT, -5,-5)에 32×10 크기의 오른쪽 정렬 작은 회색 숫자 글꼴(NumberFontNormalSmallGray)로 두고, 개수·충전 수는 오른쪽 아래(BOTTOMRIGHT, -5,5)에 두며, 단축키 글자는 GetBindingText(key, 1)의 줄임 표기를 쓴다. ※ XML에는 HotKey가 TOPRIGHT(-5,-5), 32×10, justifyH=RIGHT, NumberFontNormalSmallGray로, Count가 BOTTOMRIGHT(-5,5)로 적혀 있다. 하지만 XML 주석이 'Reanchored in script'다. 실제로 UpdateHotkeys는 키보드·마우스 바인딩이면 크기를 (단추 너비-8)×1…
- [p_cooldown_hotkey-08·partly] (WoW·Dota 2·OpenRA 단축키 설정) WoW·Dota 2·OpenRA의 단축키 설정은 이미 다른 동작에 쓰인 키를 고르면 그 동작의 이름을 알려 준다: WoW는 기존 동작에서 키를 떼어 내고 그 동작 이름이 든 문구를 띄우고, Dota 2는 'Already Bound to {기존 동작}' 경고를, OpenRA는 'This is already used for "{동작}" in the {context} context' 안내와 덮어쓰기(Override) 단추를 보인다. ※ Dota 2: dota_settings_bindhotkey_alreadybound_warning = 'Already Bound to {s:existing_binding}'. OpenRA: label-duplicate-notice 'This is already used for "{key}" in the {context} context'과 Override, C…
- [p_alerts_camera-03·partly] (0 A.D.) 0 A.D.는 기본 단축키 스페이스바(hotkey.camera.lastattackfocus)를 «Focus the camera on the last notified attack»으로 정해 두고, 누르면 focusAttack(g_LastAttack)를 불러 마지막으로 알린 공격 위치에 카메라를 맞춘다. ※ 웹검색이 불가해 원본 코드로 대조했다. default.cfg L243 lastattackfocus="Space"(설명 'Focus the camera on the last notified attack')와 camera.xml의 focusAttack(g_LastAttack)을 확인했다. F5~F8 camera.jump, Ctrl+F5~F8 jump.set도 …
- [p_alerts_camera-09·partly] (Beyond All Reason) Beyond All Reason 기본 단축키는 Grid 배치에서 F5, Legacy 배치에서 F3에 lastmsgpos(«Moves the camera to show the position of the last message»)를 묶어 마지막 메시지 위치로 카메라를 옮긴다. ※ 웹검색이 불가해 원본 코드로 대조했다. 단축키는 맞다. Grid는 Any+f5, Legacy는 Any+f3, Grid 60%는 meta+5, Legacy 60%는 meta+3이 lastmsgpos이고, interface.json 설명 문구도 일치한다. 틀린 부분은 해석이다. 네 프리셋(Grid, Grid60, Legacy, Legacy60) 모두 "fake…
- [aod-03·likely] (Age of Darkness: Final Stand) PC 기본 키 설정에서 키보드 왼쪽 아래 블록 Q·W·E·R·A·S·D·F·Z·X가 '상황 버튼(Context Button)' 1~10번에 하나씩 연결되어, 선택 대상에 따라 바뀌는 명령 버튼을 자리 순서대로 누른다.
- [castle-20·likely] (Diplomacy is Not an Option) 기본 단축키는 건설 메뉴 C, 연구 Z, 시장 L, 모든 성문 열기 '.', 모든 성문 닫기 '/'이고, 선택한 건물을 짓는 수정키는 Ctrl이다.
- [minimal-13·likely] (Bad North) PC판 Bad North에서는 스페이스바를 누르고 있는 동안에만 시간이 느려지며(켜고 끄는 토글이 아님), 스팀 토론에서 이를 토글로 바꿔 달라는 요청이 나왔다.

## 글자·아이콘 크기 (font_icon_size)
- [td_bars-md-02·verified] (Mindustry) 블록 버튼은 글자 없이 아이콘만 있는 46px 정사각형이며 한 줄에 4개씩 놓이고, 블록이 4개보다 적은 범주에서는 빈 칸을 채워 패널 너비를 유지한다.
- [td_bars-rt-12·verified] (Rogue Tower) Rogue Tower 설정에는 «UI Scale», «Show damage numbers», «Show condition messages» 항목이 있다.
- [pixel_minimal-03·verified] (Dome Keeper) HUD 루트 노드는 4배로 확대되어(scale 4,4) 1920×1080 기준 화면 위에 그려진다. 따라서 HUD의 도트 공간은 480×270이고, 6px 격자 한 칸은 실제 화면에서 24px이다.
- [pixel_minimal-04·verified] (Dome Keeper) Dome Keeper HUD 아이콘의 높이는 8px 안팎이다. 웨이브 적 아이콘(hostile.png)은 10×8, 체력 하트 배경은 10×8, 웨이브 막대 조각은 4×8이고, 자원 아이콘은 24×24 원본을 0.333배로 줄여 약 8px로 쓴다.
- [pixel_minimal-28·verified] (Loop Hero) Loop Hero 옵션 화면 왼쪽 위에는 글꼴을 Pixel fonts, High-res fonts, Dyslexia-friendly fonts 셋 중에서 고르는 체크 항목이 있고, 각 항목 이름은 그 글꼴로 미리 그려진다.
- [pixel_minimal-29·verified] (Loop Hero) High-res fonts를 켜면 메인 메뉴 버튼 글자(Continue, Select save slot, Options menu, Trophies, Exit)가 도트 글꼴에서 매끈한 고해상도 글꼴로 바뀐다. 버튼 판 스프라이트와 아이콘은 도트 그대로 남는다.
- [p_pixel_ui-03·verified] (Galmuri 한글 도트 글꼴 크기 체계) Galmuri README의 크기표는 Galmuri14=15px(11pt), Galmuri11=12px(9pt), Galmuri9=10px(7.5pt), Galmuri7=8px(6pt)이고, 배포 TTF의 unitsPerEm도 각각 1500·1200·1000·800이라 도트 한 칸이 정확히 100단위다.
- [p_pixel_ui-04·verified] (Galmuri 글리프 실측(BDF)) Galmuri 배포 BDF를 직접 읽어 보면 한글 '가'의 잉크 크기·전진폭·줄 높이(ascent+descent)가 Galmuri14는 14×14·15px·21px, Galmuri11은 11×11·12px·16px, Galmuri9는 9×9·10px·12px, Galmuri7은 7×7·8px·10px이다.
- [p_pixel_ui-06·verified] (Godot 4 도트 글꼴 크기·필터 규칙) Godot 글꼴 문서는 도트 느낌의 글꼴이 흐려지지 않게 하려면 Default Texture Filter를 Nearest로 바꾸고, 글꼴 크기를 그 글꼴 설계 크기의 정수배로, 그 글꼴을 쓰는 Control의 scale도 정수배로 둬야 한다고 쓰며, Godot의 글꼴 크기 단위는 pt가 아니라 px라고 경고한다.
- [p_pixel_ui-07·verified] (Godot 기본 글꼴과 벡터 글꼴 렌더링) Godot 문서에 따르면 글꼴을 따로 지정하지 않은 Control은 Open Sans SemiBold(벡터 글꼴)로 그려지고, 기본 안티앨리어싱인 Grayscale은 작은 크기에서 글자를 흐리게 만들 수 있으며, gui/theme/default_font_* 설정은 이 기본 글꼴에만 적용된다.
- [p_pixel_ui-11·verified] (도트 아이콘 크기 관행(16×16)) Shattered Pixel Dungeon 소스는 아이템 스프라이트를 16×16(ItemSpriteSheet.SIZE=16), 아이템 위에 겹치는 보조 아이콘을 8×8, 버프 아이콘을 작은 것 7px·큰 것 16px로 정해 두며, Godot 편집기 아이콘 지침도 아이콘을 16×16으로 그리고 선을 픽셀에 맞추라고 한다.
- [pixel_minimal-05·partly] (Dome Keeper) HUD 숫자(웨이브 번호, 자원 수)는 픽셀아트 고정폭 글꼴 Mononum.ttf(FontHudPixelartMonospaced)로 그린다. 팝업·메뉴의 Normal 글꼴은 Kollektif.ttf(대체 NotoSans)이며 1080p 기준 24px(Normal)·18px(Small)이다. 한국어 등은 언어별 글꼴 리소스로 바꿔 끼운다. ※ WaveMeter·Inventory 라벨이 FontHudPixelartMonospaced(Mononum.ttf)를 쓰는 것을 확인했다(라벨 설정 48px, 노드 0.333배). FontNormal이 Kollektif에 NotoSans 대체이고 NormalFontSettings가 24px인 것도 맞다. 한국어 remap(res://gui/fonts/korea…
- [p_pixel_ui-05·partly] (Godot 4 도트 글꼴 가져오기 설정) Godot 문서와 Godot 4.7로 만든 TakWolf의 도트 글꼴 예제는 TTF/OTF 도트 글꼴을 가져올 때 안티앨리어싱 Disabled(1비트 래스터), 힌팅 None, 서브픽셀 배치 Disabled를 쓰라고 하며, 예제의 .import 파일은 antialiasing=0, hinting=0, subpixel_positioning=0, generate_mipmaps=false, allow_system_fallback=fa… ※ TakWolf 예제 쪽은 맞다. README에 'Built with Godot 4.7'과 'antialiasing, hinting, and subpixel positioning disabled, mipmaps off, system font fallback disabled ... without oversampling'이 있다. ko.otf.import도 an…
- [p_pixel_ui-08·partly] (도트 글꼴 외곽선·그림자(Godot)) Godot 문서는 HUD처럼 배경색을 미리 알 수 없는 글자에 외곽선(Font Outline Color·Outline Size)과 그림자를 권하는데, 그림자는 Label과 RichTextLabel에만 있고 가장자리가 늘 딱딱하며, 이슈 #88373은 작은 도트 글꼴에서 외곽선 크기가 6보다 작으면 안쪽 픽셀이 채워지지 않는다고 보고한다. ※ 문서 부분은 원문과 같다. 배경색을 모를 때 HUD에 외곽선과 그림자를 쓰라는 내용(Font Outline Color·Outline Size), 그림자는 'only available in Label and RichTextLabel'이고 'always have a hard edge'라는 내용, MSDF Pixel Range를 외곽선의 2배 이상으로 하라는 내…
- [p_pixel_ui-12·partly] (Shattered Pixel Dungeon 글자 렌더링(고해상도 글자 혼) Shattered Pixel Dungeon은 화면을 정수 배율로 키우면서도(최소 2배, 가로 모드 최소 가상 해상도 240×160, 데스크톱 전체 UI 360×200) 글자는 RenderedTextBlock을 '글자 크기×배율'로 화면 해상도에서 그린 뒤 1/배율로 줄여 얹어서, 도트 그림 위에 화면 해상도 글자를 쓴다. ※ PixelScene.java 숫자는 맞다: MIN_WIDTH_L/HEIGHT_L=240/160, MIN_WIDTH_FULL/HEIGHT_FULL=360/200(full desktop UI), maxDefaultZoom=max(2,...), gate(2,...). renderTextBlock은 size*round(defaultZoom*scale)로 만들고 z…

## 시각 위계 (visual_hierarchy)
- [td_bars-bt-15·verified] (Bloons TD 6) 한 BTD6 봇 제작자는 돈 숫자를 OCR로 읽으면 눈 덮인 맵처럼 배경이 복잡한 곳에서 자주 틀렸고, 업그레이드 패널 글자는 배경이 늘 같아 안정적으로 읽혔다고 적었다.
- [pixel_minimal-15·verified] (Dome Keeper) HUD는 요소들이 차지한 6px 칸들의 바깥 둘레를 따라, 이웃 칸 조합(15가지)에 맞는 테두리 스프라이트를 자동으로 붙인다. 테두리를 포함한 HUD의 색은 팔레트 스왑(Style.init) 시스템으로 월드 팔레트에 맞춰 바뀐다.
- [pixel_minimal-30·verified] (Loop Hero) Loop Hero 옵션 화면의 분류 탭 3개는 글자 없는 그림 버튼(모니터 등)이고, 선택된 탭 이름(VIDEO)은 탭 아래 검은 띠에 한 번만 표시된다. 오른쪽 위 언어 선택도 국기 버튼 14개로 하고, 선택된 언어 이름(ENGLISH)은 그 아래에 따로 표시된다.
- [p_pixel_ui-13·partly] (Godot 4 Theme·타입 변형) Godot 4에서는 gui/theme/custom에 Theme 리소스 하나를 지정하면 모든 Control이 기본 테마보다 그 테마의 글꼴·글꼴 크기·색·StyleBox를 먼저 쓰며, 타입 변형(type variation)으로 Button을 바탕으로 일부 항목만 바꾼 'GrayButton' 같은 버튼 종류를 만들 수 있다. ※ 문서 부분은 맞다. gui_skinning.rst에 'GUI > Theme > Custom ... checked first. Only if it doesn't have the item the default theme is checked'가 있다. 다만 노드의 theme 속성이 프로젝트 테마보다 먼저다. 부모에서 자식으로 퍼지는 것, 팝업 루트에 다른 테마를…
- [tab-15·likely] (They Are Billions) 리뷰어들은 정보 전달을 문제로 짚었다: The Outer Haven은 게임 규칙 설명이 일시정지 메뉴의 긴 글에만 있다고 했고, Metacritic 사용자는 건물 설명에 어떤 자원을 쓰는지 나오지 않는다고 했으며, PlayStation LifeStyle은 콘솔판 메뉴 글자가 읽기 어렵다고 평가했다.
- [aoe_northgard-29·likely] (Northgard) 2017년 PC 첫인상 리뷰(Nerdy Bookahs)는 Northgard UI가 '깔끔하고 직관적이며 다루기 쉽다'고 평가했고, The Xbox Hub 콘솔 리뷰는 메뉴와 UI가 '급할 때도 찾아가기 복잡하지 않다'고 평가했다.
- [castle-26·likely] (Diplomacy is Not an Option) The Drastik Measure 리뷰는 UI가 눈에 띄게 혼잡해 도시와 병력 관리가 어렵다고 단점에 넣었고, Gertlush Gaming 리뷰는 메뉴 상당수가 여러 번 클릭해 들어가야 해서 오래 하거나 급할 때 헷갈린다고 평가했다.
- [minimal-08·likely] (Thronefall) Siliconera는 Thronefall을 '아름답게 단순한(Beautifully Simplistic) RTS'로, Gameindustry.com은 '최소주의(Minimalist) 기지 건설'로 평가했다.
- [minimal-21·likely] (Bad North) Creative Review는 Bad North의 미술 양식을 '최소주의적이면서 독특하다'고 평가했고, Vice는 이 게임을 'Clean, Pretty'한 전략 게임이라고 불렀다.
- [pixel_minimal-23·likely] (Kingdom (2015 원작)) 원작 Kingdom은 거칠지만 일관되게 거친 손 도트 위에 실시간 조명·반사·셰이더를 얹어 화면을 하나로 묶었다. 저해상도라 이 효과들의 성능 부담이 거의 없다고 개발진이 설명했다.
- [p_glance-01·likely] (Zach Gage — Designing for Subway Legibil) Zach Gage는 GDC 2018 발표(원고 «Designing for Subway Legibility»)에서 지하철에서 어깨 너머로 보는 사람도 설명 없이 화면만 보고 무슨 일이 벌어지는지 알 수 있어야 하고, 스크린샷과 GIF에 맥락 설명이 거의 필요 없어야 한다는 기준을 내놓았다.
- [p_glance-02·likely] (Zach Gage — Three Reads) Zach Gage는 같은 Subway Legibility 발표에서 «Three Reads»를 한눈에 읽히는 게임을 만드는 핵심 도구로 꼽았다.

## 단계적 공개 (progressive_disclosure)
- [blizzard-21·verified] (StarCraft II) StarCraft II 2.0.4 패치는 초보자용 '간단한 명령 카드' 옵션을 넣었는데, 이 옵션을 끄면 오른쪽 아래 명령 카드에 모든 명령이 보이고 켜면 일부 명령(예: 순찰)이 빠진 간소한 카드가 보인다.
- [td_bars-rt-03·verified] (Rogue Tower) 레벨 1 스크린샷의 아래쪽 건설 바에는 발리스타 카드 한 장만 있고, 다른 타워 종류는 «Tower - Radar», «Tower - Mortar» 같은 업그레이드 카드를 골라야 생긴다.
- [pixel_minimal-32·verified] (Loop Hero) 전투 중 적의 상세 수치를 화면에 띄우는 커뮤니티 모드 BattleInfo가 있다. 이 모드는 글자 크기(기본 0.5배), 소수 자릿수(기본 2), 글자 위치 오프셋을 options.ini에서 조절하게 한다.
- [td_bars-md-15·partly] (Mindustry) 튜토리얼 힌트는 한 번에 하나만 화면 왼쪽 가운데의 반투명 검은 상자(PC에서 너비 400)에 뜨고, 그 행동을 해내면(예: 웨이브 2 이후 Space로 일시정지) 사라지며, 아래에 «Skip» 버튼이 붙고 설정으로 모두 끌 수 있다. ※ 소스를 직접 대조함. 힌트는 한 번에 하나(current)이고, t.left() 위치, Styles.black5 배경, 너비는 PC 400·모바일 270이다. 완료되면 사라지고 'Skip' 버튼이 붙으며, hints 설정(기본 true)으로 끌 수 있다. 플레이 시간 8000ms 조건도 있다. 다만 예로 든 '웨이브 2 이후 Space 일시정지' 힌트(de…
- [pixel_minimal-07·partly] (Dome Keeper) 웨이브 시간 막대(철 2), 웨이브 번호(물 1), 돔 체력 막대(철 1), 자원 카운터(물 1)는 처음부터 보이지 않는다. 돔 업그레이드를 사야 HUD에 붙는다. 월드 수정자 worldmodifierhud는 이 넷을 미리 주고, worldmodifiernowavemeter는 웨이브 미터를 없앤다. ※ 맞는 점: 네 업그레이드의 비용이 철2·물1·철1·물1이고, worldmodifierhud가 넷을 준다(upgrades.yaml). 옛 판도 비용이 같다. 틀린 점: worldmodifiernowavemeter는 eraseupgradelimits:[wavemeter]로 domewavemeter(시간 막대)와 그 뒤 경보·경로 업그레이드만 막는다. 적 아이콘…
- [aoe_northgard-10·likely] (Age of Empires IV) AoE IV에서는 시대 올리기 요구 조건(자원 + 랜드마크 건설)을 기술 트리에서, 또는 일꾼을 고른 뒤 유닛 카드의 '시대 아이콘'에서 언제든 확인할 수 있다.
- [p_disclosure-04·likely] (Thronefall — 복잡도를 조금씩 얹기) GameDiscoverCo 분석에 따르면 Thronefall은 1~3인 팀이 범위를 일부러 작게 두고, 기존 시스템 위에 복잡도를 조금씩 얹는 방식으로 만들었다.
- [p_disclosure-09·likely] (Bad North — 능동 스킬 해금) Bad North는 처음에는 분대 위치 지정만 할 수 있고, 지휘관을 업그레이드해 병과가 정해지면 병과마다 능동 스킬 하나(보병 Plunge, 궁수 Volley, 창병 Pike Charge)를 코인으로 해금한다.

## 카메라·가림 (camera_occlusion)
- [blizzard-15·verified] (Warcraft III (Classic/Reforged)) Warcraft III: Reforged 2.0.0 패치에서 옵션으로 HUD 크기를 바꿀 수 있게 되었고, Classic 모드 HUD에는 양옆 테두리를 없애는 옵션이 생겼다.
- [td_bars-rt-07·verified] (Rogue Tower) 화면 가운데 위쪽, 자원 칸 바로 아래에 W·A·S·D 방향 화살표 안내가 겹쳐 그려지며, QoL 모드 제작자는 이 WASD 표시를 끄는 기능을 할 일 목록(WIP)에 올렸다.
- [pixel_minimal-13·verified] (Dome Keeper) 1인 플레이에서 웨이브 중 키퍼가 돔 안에 있으면 카메라 줌이 2로 물러나 1920×1080 기준 세계 960×540px가 보인다. 평시 돔 안(goalCameraZoom)과 광산(keeper.zoominmine)에서는 기본 줌 4로 480×270px가 보인다.
- [pixel_minimal-21·verified] (Kingdom Two Crowns) KingdomMod 미리보기 스크린숏(1920×1080)에서 유닛이 걷는 지면 줄은 화면 높이의 약 58% 지점에 있다. 그 아래 약 40%는 수면 반사, 위쪽은 하늘이며, 모드의 지도·통계·동전 글자는 모두 위쪽 하늘 띠와 오른쪽 위 모서리에만 놓인다.
- [p_alerts_camera-13·verified] (0 A.D. HUD 크기 (비교: OpenRA RA 사이드바, BAR)) 0 A.D.의 전투 HUD는 화면 크기와 상관없이 고정 픽셀 크기로, 아래 가운데 1024px 너비 안에 미니맵 200×200·선택 정보 228×200·좌우 패널(높이 166px)을 두고 맨 위에 높이 36px 자원 줄을 두며, Alt+G로 HUD 전체를 숨길 수 있다.
- [p_alerts_camera-14·verified] (RTS 카메라 경계 (OpenRA, 0 A.D., BAR)) OpenRA는 카메라 화면의 가장자리가 아니라 화면 중심(CenterLocation)만 맵 경계 사각형 안에 가두므로 맵 맨 끝 칸도 화면 한가운데까지 끌어올 수 있고, 0 A.D.도 카메라 초점(pivot)만 맵 가장자리에서 2타일 안쪽으로 가둔다.
- [p_alerts_camera-15·verified] (Godot 4 Camera2D (우리 엔진)) Godot 4의 Camera2D limit_top·limit_bottom 등은 카메라가 보여 주는 화면 사각형의 가장자리가 그 값을 넘지 않게 막고(한계 폭이 화면보다 좁으면 가운데로 맞춤), offset은 이 제한을 계산한 뒤에 더해지므로 화면을 한계 밖으로 밀 수 있다.
- [blizzard-14·partly] (Warcraft III (Classic/Reforged)) 원작 WC3의 아래 콘솔을 두고 블리자드 포럼의 한 사용자는 화면의 거의 50%를 덮는다고, 와이드스크린 모드 제작자는 큰 TV에서 화면의 1/3을 덮는다고 평가했다. ※ 1/3 쪽은 비슷한 독립 근거가 있다. 다른 와이드스크린 모드(W3TrueWidescreen) README가 큰 화면에서 원래 콘솔이 '높이의 1/3'을 차지한다고 적었다. 다만 '화면 1/3'이 아니라 '높이 1/3'이다. 포럼 사용자의 '거의 50%'와 PC Gamer·TechRadar 보도는 검색할 수 없어 확인하지 못했다.
- [td_bars-bt-04·partly] (Bloons TD 6) 타워 상세(업그레이드) 패널이 왼쪽에 열리면 왼쪽 위 생명·돈 표시가 화면 절반쯤 오른쪽으로 옮겨지고, 오른쪽에 열리면 맨 오른쪽 위 라운드 표시가 가운데 칸으로 밀려난다. ※ BloonsPlus replay.py에 왼쪽 패널이 열리면 lives·cash 좌표를 바꾸고, 오른쪽 패널이 열리면 round를 가운데 칸(505-612/960 ≈ 53~64%)으로 옮기는 분기가 있다. 방향은 맞다. 그러나 '화면 절반쯤'은 주석의 표현이고, 같은 코드의 좌표로 보면 lives는 약 3~10%에서 23.5~32.5%로, money는 약 1…

## 기타 (other)
- [pixel_minimal-31·verified] (Loop Hero) Loop Hero 비디오 옵션에는 CRT 셰이더 켜기·끄기 항목(V-sync와 함께)이 있다. 그래픽 개발자 Garrett Gunnell(Acerola)은 이 CRT 셰이더를 연구해 Unity 후처리 효과로 다시 만들었다.
- [p_pixel_ui-01·verified] (Godot 4 해상도 설정(기준 해상도 640×360)) Godot 공식 문서는 도트 게임의 기준 해상도로 640×360을 권하고, 이 크기는 정수배로 키우면 1280×720·1920×1080·2560×1440·3840×2160 화면을 검은 띠 없이 꽉 채운다고 쓴다.
- [p_pixel_ui-09·verified] (Godot 4 9-slice(NinePatchRect·StyleBoxTe) Godot 4의 NinePatchRect와 StyleBoxTexture는 작은 텍스처를 3×3으로 나눠 모서리는 그대로 두고 가장자리와 가운데만 늘이거나(STRETCH, 기본) 반복해서(TILE·TILE_FIT) 어떤 크기의 패널이든 만들며, 나누는 선은 픽셀 단위 여백(patch_margin_*·texture_margin_*)으로 정한다.
- [p_pixel_ui-10·verified] (Shattered Pixel Dungeon·Mindustry 9-slic) 도트 게임 소스 두 곳은 창과 버튼 테두리를 아주 작은 9-slice 조각으로 그린다: Shattered Pixel Dungeon의 Chrome.java는 WINDOW를 20×20 조각에 여백 6, TOAST를 9×9에 여백 4, RED_BUTTON과 GREY_BUTTON을 6×6에 여백 2로 정의하고, Mindustry는 button.9.png, button-over.9.png, button-down.9.png, button…
- [castle-03·partly] (Stronghold Crusader) 손으로 열어 둔 성문도 적 유닛이 가까이 오면 저절로 닫힌다. ※ 독립 근거: UCP 2 현지화 파일(o_responsivegates_descr)에 원본 Crusader 1에서 적이 사거리 200 안에 들어오면 성문이 '스스로 닫히고', 적이 모두 떠나고 1200틱 뒤 다시 열린다는 설명이 있다. 그래서 자동 닫힘 자체는 뒷받침된다. 다만 '손으로 열어 둔 성문도' 닫힌다는 부분은 이 자료에 없고 확인하지 못했다. Cru…
- [td_bars-rt-05·partly] (Rogue Tower) 업그레이드 카드는 정해진 라운드 간격마다 뽑는데, 영구 업그레이드(Card Draw)를 사면 간격이 «3라운드마다»에서 «2라운드마다», «매 라운드»로 짧아진다. ※ 간격 문자열 'every 3 rounds'(L33), 'every 2 rounds'(L1187), 'every round'(L34)는 있다. 그러나 업그레이드 이름이 틀렸다. 'Card Draw I~III'는 뽑는 카드 수를 1장 늘리고(L30), 간격을 줄이는 것은 'Draw Frequency I·II'(L31-32)이다. Draw Frequency는 2…
- [p_pixel_ui-02·partly] (Godot 4 늘이기 모드(viewport vs canvas_items)) Godot 문서에 따르면 canvas_items 늘이기 모드는 목표 해상도로 직접 그리기 때문에 스프라이트 픽셀과 화면 픽셀이 1:1로 맞지 않아 확대 아티팩트가 생길 수 있고, 문서는 도트 게임에 viewport 모드(기준 해상도로 먼저 그린 뒤 통째로 확대)를 권한다. ※ 핵심은 원문과 맞다. canvas_items 항목에는 'no longer a 1:1 correspondence between sprite pixels and screen pixels, which may result in scaling artifacts'가 있고, viewport 항목에는 'Recommended for games that use a pixel…
- [aoe_northgard-08·likely] (Age of Empires IV) AoE IV 시즌 1 업데이트(2022)로 HUD에 '전역 생산 대기열'이 생겼다. 맵 곳곳의 건물이 대기 중인 유닛·업그레이드가 칸으로 보이고, 칸을 누르면 그 건물이 선택되며 카메라가 옮겨 가고, Ctrl+클릭하면 가장 최근에 넣은 항목이 취소된다.
