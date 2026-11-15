# 검증: ref_additional_games.md (Into the Breach · CrossCode · Loop Hero · Sea of Stars)

검증일 2026-11-15. 인용 출처를 직접 열어 확인했고, 게임별 사실은 두 번째 출처나 공식 Steam 스크린샷으로 대조했다. 스크린샷은 `scratchpad/shots/ref_additional_verify/`에 5장(itb1·itb2·lh1·lh2·cc1)을 받았다. 색은 JPEG 영역의 중앙값으로 뽑은 근사값이다.

요약: 확인 6 · 수정 9 · 반박 0 · 확인 불가 0. 개별 판정에는 확인 불가가 없지만 3번 안의 "first clue" 인용은 찾지 못했다(아래 3번).

| # | 판정 | 한 줄 |
|---|---|---|
| 1 | 확인 | 인용 두 개 모두 Game Developer 원문과 같다. 원 출처인 RPS 원문도 확인했다 |
| 2 | 확인 | "a thousand times more effective", "the most important decision we made about this", 세 문장 일화 모두 있다 |
| 3 | 수정 | 앞부분은 맞다. "The UI is just always our first clue…" 인용은 Game Developer에도 RPS 원문에도 없다 |
| 4 | 수정 | 하이브리드 폰트는 맞다. 다만 "짧은 라벨 = 픽셀"은 지나친 일반화다(타일 툴팁 제목·유닛 이름도 매끈한 산세리프) |
| 5 | 수정 | 바탕 #0c0f16, 강철 파랑 2px 직각 테두리, 드롭 섀도는 맞다. 툴팁 위치는 타일 정보 패널에만 해당하고, 근거는 ITB-2가 아니라 ITB-1이다 |
| 6 | 수정 | 네이티브 568×320(71:40)은 맞다. 2×·3×·4×는 내부 렌더 배율(Pixel Size)이고, 기본 화면 배율(Fit)은 정수 배율이 아니다 |
| 7 | 확인 | ig.NinePatch, 9구역, 3분할 버튼, 글줄 속 아이콘, 텍스트 미리 그리기 모두 원문에 있다 |
| 8 | 수정 | 0.5초와 KEY_SPLINES['EASE']는 예시 코드의 "DEFAULT" 전환 값이다. canvas를 쓴 이유는 본문이 아니라 개발자 lachsen의 댓글이다 |
| 9 | 확인 | 개발사 블로그 원문(2013-09-08)에 같은 문장이 있다. 2013년 개발 빌드 기준이다 |
| 10 | 확인 | 포스트모템의 세 내용 모두 있다. "아무도 모르는"은 원문의 "very few people"보다 세다 |
| 11 | 수정 | Phenixx는 난독증 친화 폰트만 말한다. 고해상도 폰트와 가독성 불만의 근거는 Steam 토론과 GOG 파일 목록이다 |
| 12 | 수정 | 사실은 맞지만 인용한 토론 URL이 틀렸다. 정식판 GOG 파일 목록에도 Roboto-Bold.ttf가 있다 |
| 13 | 수정 | 기본 설정에서만 "전부 픽셀"이다. 팔레트도 회색과 옥스블러드 두 색만이 아니다 |
| 14 | 수정 | 빨강(주황빛)인 것은 가진 양 숫자뿐이고 "/필요량"은 흰색이다. 레벨 숫자는 LH-1에서 본 것이다 |
| 15 | 수정 | 내용은 맞다. 다만 인용한 Can I Play That?에는 Locks가 없다. Locks는 RPGFan으로 확인했다 |

---

## 1. Into the Breach: "sacrifice cool ideas…" / "If it can be shown in a clear way…"
- **판정: 확인**
- Game Developer 원문: "As a game design principle, we would sacrifice cool ideas for the sake of clarity every time," says … Justin Ma. 그리고 "If it can be shown in a clear way, [then] yes, we can have that." — https://www.gamedeveloper.com/design/-i-into-the-breach-i-dev-on-ui-design-sacrifice-cool-ideas-for-the-sake-of-clarity-every-time-
- 이 기사는 Rock Paper Shotgun 인터뷰(Alex Wiltshire, "The Mechanic", 2018-03-05)를 요약한 것이다. RPS 원문 표현은 "**Just** as a game design principle, …"이고 "[then]" 없이 "If it can be shown in a clear way, yes, we can have that."이다. 이 말은 일반 UI 원칙이라기보다 **무기 설계를 덜어 낼 때** 나왔다("As for weapons, the solution was editing.") — https://www.rockpapershotgun.com/into-the-breach-interface-design

## 2. Into the Breach: 시연 툴팁, "a thousand times more effective", "the most important decision", 세 문장 일화
- **판정: 확인**
- Game Developer: 툴팁은 "whichever of the player's units is most appropriate"로 무기를 보여 준다. RPS 원문: "complete with the actual unit wielding it", "make the tooltips dynamic so they'd always show the actual unit".
- RPS(Ma): "We'd watch a playtester investigate a weapon and they'd just be like, 'What' after reading three sentences and still didn't get it." / "I still think it's the most important decision we made about this … showing that little animation of them moving is a thousand times more effective."
- 맥락 보충: 그전 툴팁에도 그림이 있었다. 다만 일반 그림이라 실제 유닛이 나오지 않았고, 동적 툴팁은 Davis가 구현했다. 계기는 세 문장 일화와 Davis의 "the language to describe a weapon was getting overly complex"가 함께 든 것이다.
- 출처: 위 Game Developer, https://www.rockpapershotgun.com/into-the-breach-interface-design

## 3. Into the Breach: "restricted our game design options considerably", 고유 무기·발사 패턴 삭제, "first clue"
- **판정: 수정**
- 확인된 부분:
  - RPS(Ma): "Our requirement that the player has to understand what's going on in any situation restricted our game design options considerably."
  - Game Developer: Ma와 Davis가 "ended up cutting unique, interesting weapons and firing patterns because they weren't easy to convey to playtesters."
- 확인되지 않은 부분:
  - "The UI is just always our first clue to that realization."와 "UI로 전달하기 너무 복잡하면 본질적으로 혼란스럽고 불필요하다"는 Game Developer 본문에도, RPS 원문 전문(직접 받아 grep)에도 없다. 정확한 문구 검색 두 번에도 출처가 나오지 않았다. **이 인용은 지워야 한다.**
  - 노트 Q3의 "한 행동이 거는 상태 효과 수 제한"도 원문에 없다. 원문은 **타일 하나에 효과 하나만** 두려 했다는 내용이다("they tried to stick to tiles only carrying one effect at a time … it would be impossible to display both on the board at once").
- 원문에 있는 대체 사례: 다이아몬드형 3칸 사거리를 뺐다(여러 적의 공격 범위를 동시에 보이면 "who's attacking what"을 알 수 없었다). 별·삼각형 범위 무기를 뺐다. 밀기는 1칸으로 고정했다. "One and a half years ago the game was just an icon mess"(Davis).
- 출처: 위 두 URL

## 4. Into the Breach 하이브리드 폰트
- **판정: 수정(경미)**
- ITB-1·ITB-2에서 확인한 것:
  - **픽셀 디스플레이 폰트**: "End Turn", "POWER GRID", "GRID DEFENSE", "17%", "RESET USED", "UNDO MOVE", "ATTACK ORDER", "Bonus Objectives" 머리표, "Rust District", "BONUS OBJECTIVES", "WARNING!", "WIND STORM", 큰 숫자 "1"
  - **안티에일리어싱된 매끈한 산세리프**: "Chasm Tile" 제목과 그 설명, 대사 문장, "Vek Threat Detected!", "Kill at least 7 Enemies", "Destroy the Dam", "Victory in … turn", 유닛 이름 "Scarab"
- 수정할 점: 짧은 라벨이라고 모두 픽셀 폰트는 아니다. 정확히 나누면 **버튼·HUD 머리글·섹션 제목·큰 숫자는 픽셀 폰트, 툴팁(제목 포함)·목표 항목·유닛 이름·대사는 매끈한 산세리프**다.
- 보조 증거: ITB 1.2 리소스 목록에 커스텀 TTF(JustinFont8/10/11/12, Justin13/15)와 일반 벡터 폰트(Roboto-Bold/Regular, 일본어 NotoSans)가 함께 있다. 어떤 화면에 어떤 폰트를 쓰는지는 이 목록으로 알 수 없다. 산세리프의 이름도 확인하지 못했다.
- 출처: observed in screenshot https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_6113590509c195f98fa64cd738df534762e0c358.1920x1080.jpg, https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_82cfc5241c4a093091fbd7d2e124a52a57930527.1920x1080.jpg, https://gist.github.com/KnightMiner/d7889a8728b7b6b3c0ede8161ea15293

## 5. Into the Breach 패널·색·툴팁 위치
- **판정: 수정(경미)**
- 확인된 것:
  - 패널 바탕 중앙값은 네 곳(타일 툴팁, Victory 패널, Rust District 패널, 대사 상자) 모두 **#0c0f16**이다.
  - 테두리는 #475c79~#4a5a7e 강철 파랑이고, 1280×720 화면에서 2px, 직각이다.
  - ITB-2의 상단 바와 패널 아래에 부드러운 어두운 드롭 섀도가 있다.
  - 의미 색: 주황 = 전력 칸, 초록 = 완료 목표(취소선)·체력, 노랑 = WIND STORM 경고, 어두운 빨강 = RESET USED, 빨강 = 지역 제목.
  - ITB-1에서 분홍·빨강 빗금 칸 위에 분홍 외곽선 유닛과 밀기 화살표가 있다.
- 고칠 점:
  1. 빨강 빗금, 오른쪽 아래 툴팁, 비어 있는 가운데 전장은 인용한 ITB-2가 아니라 **ITB-1**에서 보인다.
  2. 오른쪽 아래 패널은 **타일 정보 패널**이다. 2번의 무기 시연 툴팁이 어디에 뜨는지는 이 스크린샷으로 확인하지 못했다. 그러니 "툴팁 = 오른쪽 아래 고정"이라고 일반화하면 안 된다. 정지 화면 한 장으로는 "고정"인지도 증명되지 않는다(커서와 떨어진 모서리에 있다는 점만 보인다).
  3. "빨강 빗금 = 적 공격 예정 칸"은 스크린샷만으로는 누가 노리는지 판별되지 않는다. RPS 원문은 빗금이 노리는 칸을 뜻한다고 쓴다("hatched lines denoting targeted tiles", 개발 초기 상황).
- 출처: observed in screenshot ITB-1·ITB-2(위 URL), https://www.rockpapershotgun.com/into-the-breach-interface-design

## 6. CrossCode 해상도 568×320 / 2×·3×·4× / 스크린샷 1136×640
- **판정: 수정**
- 확인된 것:
  - PCGamingWiki: "Native resolution is 568x320, a 71:40 aspect ratio resolution."
  - 두 번째 출처로 개발자 Regiden(Steam, 2017-12-29): "The native resolution is 568x320." / "It will be double/triple/quadrouble of the native resolution."
  - 공식 스크린샷 ss_5bf282c8…의 실제 파일 크기는 1136×640이다.
- 수정할 점: 1136×640·1704×960·2272×1280은 **Pixel Size 설정의 내부 렌더 해상도**다. 화면 배율은 Display Type이 정하는데, 기본인 **Fit과 Stretch는 비정수 배율이라 약간 번진다**. 픽셀 퍼펙트 정수 배율은 **모드(CrossCode-ScalingFix)를 써야** 된다(PCGamingWiki). 따라서 "정수 배율로 …을 쓴다"는 틀렸다. "내부 렌더를 2~4배로 키운 뒤 화면에 맞춰 (기본은 비정수로) 늘린다"가 맞다.
- 출처: https://www.pcgamingwiki.com/wiki/CrossCode (Resolution 절, API로 위키 원문 확인), https://steamcommunity.com/app/368340/discussions/0/1621724915795996872/

## 7. CrossCode NinePatch·3분할 버튼·글줄 아이콘·텍스트 사전 렌더
- **판정: 확인**
- 원문 문장:
  - "we added NinePatches to the engine. These allow us to define 9 areas of which a drawable piece is made of. The edges are drawn normally while the top, left, right, bottom and center pieces are stretched"
  - "the button-asset is actually only split into 3 parts … we only need to fill the horizontal space … The height always stays the same."
  - 코드에 `ig.NinePatch("media/gui/buttons.png", {…})`가 있다.
  - "We extended the basic font-class to be able to draw icons too and … pre-draw the text on a canvas which saves a huge amount of draw calls, especially in the menu."
- 글 정보: "CrossCode – How to GUI System", R.D., 2014-02-05.
- 출처: https://www.radicalfishgames.com/?p=1594

## 8. CrossCode 전환·레이아웃·canvas 이유
- **판정: 수정(경미)**
- 확인된 것:
  - 상태 offsetX/Y·alpha·scaleX/Y·angle이 있다.
  - "timeFunction: The bezier curve to use (We call them Key Splines here)"
  - "We basically copied the same system CSS uses."
  - "There are not complex layout systems or anything."
  - pos·align은 부모 기준이다.
- 수정할 점:
  1. `time: 0.5`와 `timeFunction: KEY_SPLINES['EASE']`는 의사 코드 예시 속 **"DEFAULT"라는 이름의 전환** 값이다. 본문은 time을 "transition time TO this state in seconds"라고만 설명한다. "시스템 기본 전환 시간 0.5초"는 추론이다.
  2. "HTML 확대 시 흐려져 canvas로 블록 픽셀을 그렸다"는 본문이 아니라 **댓글**이다. lachsen(Felix Klein, Radical Fish 공동 창업자이자 디렉터·프로그래머)이 2014-03-25에 썼다. 개발자 본인의 말이므로 근거로는 유효하다.
- 출처: https://www.radicalfishgames.com/?p=1594, Felix "Lachsen" Klein의 역할은 https://itch.io/blog/53052/how-crosscode-modernizes-classic-design-an-interview-with-felix-of-radical-fish

## 9. CrossCode 상태 표시가 HUD에서 펼쳐짐
- **판정: 확인**
- 403으로 막힌 ModDB 대신 개발사 블로그 원문을 확인했다. "Weekly Update #31 Menu Progress"(2013-09-08)에 "On the upper left you see a more detailed status display … which actually expands dynamically from the smaller status HUD during gameplay."가 있다. 시작 메뉴 화면은 "an actual screenshot from the game"이고, 장비·상태 화면은 목업이다.
- 단서: 2013년 개발 빌드의 설명이다. 출시판에서도 그대로인지는 확인하지 않았다.
- 출처: https://www.radicalfishgames.com/?p=1102

## 10. Loop Hero 포스트모템
- **판정: 확인**
- 원문 문장:
  - "the oldest item will be destroyed when picking up a new one … This way the inventory will fill up, but not clutter." 카드도 "analogous to the inventory with the dropping/discarding mechanic"이다.
  - What Went Right: The Demo 절: "greatly helped us to improve the game, balance, and various aspects such as UI and UX."
  - What Went Wrong: Pre-release crunch 절: "Finlal once spent a whole day making a little shader of a light stripe going through the auto-pause gear …" 그리고 그 기능(자동 일시정지)을 "very few people even know about"이라고 했다.
- 미세 조정: 원문은 "아무도 모르는"이 아니라 "아는 사람이 아주 적은"이다. 잘 알려지지 않은 것은 셰이더가 아니라 자동 일시정지 **기능**이다. 원문은 이 일을 실수라기보다 과한 다듬기가 낳은 크런치의 예로 든다.
- 글 정보: Four Quarters, 2021-08-26.
- 출처: https://www.gamedeveloper.com/design/postmortem-loop-hero

## 11. Loop Hero 픽셀 폰트 가독성 지적, 고해상도·난독증 친화 대체 폰트
- **판정: 수정**
- Phenixx Gaming(Keiran McEwen, 2021-03-05)은 **난독증 친화 폰트만** 말한다. "99.99999% of pixel graphic games simply don't do: Dyslexic-friendly fonts"도 난독증 폰트에 대한 말이다. 고해상도 폰트도, 픽셀 폰트 가독성 불만도 이 리뷰에는 없다. 노트가 함께 인용한 Impulse Gamer 리뷰에는 폰트 언급이 전혀 없다.
- 실제 근거:
  - Steam 토론 "Please use text that is actually readable"(2021-02-10, 데모 시기). 픽셀 폰트를 읽기 어렵다는 불만과 "Clicking on Language -> High Resolution Fonts"라는 답이 있다. 고해상도 폰트는 "doesn't fit as well in the UI", "only 75% of the fonts actually change with it"이라는 반응도 있다.
  - Steam 토론 "Thank you to the Devs for the Dyslexia-friendly fonts"(2021-03-04)에 "The high-res font … that dyslexic font"라는 말이 있다.
  - GOG 빌드 파일 목록의 fonts 폴더에 `Roboto-Bold.ttf`와 `ADYS.otf`가 있다.
- 수정할 점: 고해상도 폰트 옵션은 **정식판보다 먼저 데모(2021-02)에 이미 있었다**.
- 출처: https://web.phenixxgaming.com/2021/03/05/loop-hero-pc-review, https://www.impulsegamer.com/loop-hero-review, https://steamcommunity.com/app/1282730/discussions/0/3117023981184793098/, https://steamcommunity.com/app/1282730/discussions/0/3112522283873831459, https://www.gogdb.org/manifest/571ad67fcf8b43b6f895f81a9a15d9f6

## 12. Loop Hero fonts 폴더의 Roboto-Bold
- **판정: 수정(출처 교체)**
- 인용한 토론(…3112522283873831459)은 "Thank you to the Devs for the Dyslexia-friendly fonts"다. 여기에는 Roboto나 fonts 폴더 이야기가 **없다**.
- 실제 출처는 …3117023981184793098이다. "I replaced the hi-res font (Roboto Bold …) … copy paste the font of your choice into the fonts folder and rename it Roboto-Bold.ttf", 경로는 `…\Loop Hero Demo\fonts`(데모)다.
- 독립 출처: GOG 빌드 파일 목록(정식판 구성 파일: Loop Hero.exe, data.win, lang_*.ini)에도 `fonts/Roboto-Bold.ttf (170KB)`가 있다. 따라서 데모에만 있던 게 아니다.
- 출처: https://steamcommunity.com/app/1282730/discussions/0/3117023981184793098/, https://www.gogdb.org/manifest/571ad67fcf8b43b6f895f81a9a15d9f6

## 13. Loop Hero 전부 픽셀, 회색 프레임과 옥스블러드, 불투명, CRT
- **판정: 수정**
- 확인된 것(LH-1·LH-2):
  - 기본 화면은 텍스트까지 대문자 픽셀 폰트다.
  - 프레임 회색은 #757e7d(LH-2 바깥 프레임), #4f5354(LH-1 상단 바)다.
  - 옥스블러드는 #6c281b(건물 메뉴 바탕), #6e261a(VILLAGE 툴팁)다.
  - 패널은 불투명하고, 화면 모서리가 검은 CRT식 비네팅이 있다.
- 수정할 점:
  1. "전부 픽셀"은 **기본 설정에서만** 맞다. 게임에는 고해상도 폰트(Roboto-Bold)와 난독증 폰트 옵션이 있고, CRT 필터도 끌 수 있다(Steam 토론 "I turned off the CRT filter").
  2. 두 스크린샷 모두 화면에 "LOOP HERO v0.928"이 찍힌 출시 전 빌드다(노트는 LH-1만 표시).
  3. 팔레트가 "회색과 옥스블러드 한 색"만은 아니다. 아이템 칸 바탕은 희귀도별 파랑·주황·금색이고, HP 바는 초록, 부족 숫자는 주황빛 빨강, 해금선은 노랑이다. 또 LH-2 오른쪽 열의 GYMNASIUM 툴팁 바탕은 옥스블러드가 아니라 **회색(#777c7f)**이다.
- 출처: observed in screenshot https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_500e7212653fa6586f7a84c89b4c60be4e425fbb.1920x1080.jpg, https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1282730/ss_455789884ed94fd20410ac5a139e8c3bb8f6f369.1920x1080.jpg, https://steamcommunity.com/app/1282730/discussions/0/3112522283873831459

## 14. Loop Hero 비용 배지·부족분 빨강·레벨 숫자·오른쪽 열 툴팁
- **판정: 수정(경미)**
- 확인된 것(LH-2를 확대해 봄):
  - 비용은 자원 아이콘과 검은 배지 속 숫자를 세로로 쌓는다.
  - 부족한 항목은 "가진 양/필요량" 꼴로 바뀐다(10/11, 3/6, 12/14, 3/4, 2/4).
  - 툴팁(VILLAGE, GYMNASIUM)은 두 장 모두 오른쪽 열에 있다.
- 수정할 점:
  1. 빨강인 것은 **가진 양 숫자뿐**이다. "/11" 같은 필요량은 흰색이다. 색은 주황빛 빨강이다(JPEG 표본 약 #d97c52). 충분한 자원은 필요량만 흰 숫자 하나로 나온다.
  2. 아이템 칸 모서리(왼쪽 아래)의 레벨 숫자는 인용한 LH-2가 아니라 **LH-1**의 인벤토리에 있다. LH-2 오른쪽 자원 격자의 숫자는 오른쪽 아래에 있고 **개수**다.
- 출처: observed in screenshot LH-2·LH-1(위 URL)

## 15. Sea of Stars의 Locks 아이콘, 남은 턴 수, 개발자 UI 발언 없음
- **판정: 수정(출처 교체)**
- 인용한 Can I Play That?에는 "Enemies have icons above their heads, letting players know their weaknesses and how many turns are left until they attack."만 있다. **Locks와 차지 공격을 끊는 피해 유형은 이 출처에 없다.**
- Locks 내용은 RPGFan으로 확인했다: "enemies charging special moves display a series of locks to break through by using certain attack types", 사진 설명 "four locks above the enemy's head, three crescent moons and one sword", "if you manage to break all of them, the move is canceled".
- 개발자 UI 설계 발언은 나도 찾지 못했다(RPG Site, MobileSyrup 등은 다른 주제).
- 출처: https://caniplaythat.com/2023/11/01/sea-of-stars-accessibility-review/, https://www.rpgfan.com/review/sea-of-stars/

---

## 노트 전체를 훑으며 본 다른 오류

- **잘못 붙은 출처**
  - 20행의 GDC Vault 링크 `…/play/1026333/contactUs`는 비정상 URL로 보인다.
  - 49행 "지도 하나가 한 화면에 다 들어간다"를 인용한 IGF 기사(Road to the IGF)에는 그런 문장이 없다. 텔레그래프·퍼즐 이야기만 있다.
  - 24·66행이 함께 인용한 Impulse Gamer 리뷰에는 폰트 이야기가 전혀 없다.
  - 67행의 Roboto-Bold 토론 URL이 틀렸다(12번).
  - 94행 "잠금을 모두 깨면 기술이 취소된다"는 RPGFan으로 맞다. 다만 팬 위키는 다른 효과(다음 시전의 턴 수 감소)를 적었다고 검색 요약에 나와 버전 차이가 있을 수 있다.
  - 95행 Sequent Flare는 원문이 "extra visual flare"(하늘로 별이 솟는 연출)라고 적었으니 "섬광"보다 "추가 시각 효과"가 정확하다.
- **원문에 없는 내용**
  - 119행의 "한 행동이 거는 상태 효과 수 제한"은 원문에 없다. 실제는 "타일 하나에 효과 하나"다.
  - 같은 행의 "first clue" 인용은 출처를 찾지 못했다(3번).
  - 72행 "옥스블러드로 툴팁 패널 … 바탕"은 LH-2 툴팁이 회색이라 일부만 맞다.
- **추론이 기대는 전제**
  - 29·102행의 "CrossCode는 정수 배율 구성과 같은 문제를 풀었다"는 출시판 기본 화면이 정수 배율이 아니라는 점(6번)을 감안해 낮춰야 한다.
- **보고서에 넣을 만한 발견**
  - GOG 파일 목록을 보면 Loop Hero의 fonts 폴더에 `NotoSansKR-Medium.otf`(그리고 JP·SC·TC)가 있다.
  - Into the Breach 1.2 리소스에도 일본어용 `fonts/jp/NotoSans_<크기>.font`와 `_2x.font`(8~24 크기별로 미리 만든 폰트 파일)가 따로 있다.
  - 즉 두 "픽셀 UI" 게임 모두 **CJK 글자에는 직접 그린 픽셀 폰트 대신 Noto Sans 계열**을 쓰는 것으로 보인다. 한글 UI를 쓰는 요청자 게임에 직접 닿는 사례다. 다만 어느 화면에 쓰이는지는 파일 목록에서 나온 추정이다.

## 덧붙임(2026-11-15, 보고서 검토 반영): ITB 1.2 리소스 목록의 «추가»·«바뀜» 구분

- `gh api gists/d7889a8728b7b6b3c0ede8161ea15293`로 gist 두 파일(Lua.md, Resources.md)을 받아 읽었다. Resources.md의 목록은 "Everything is added unless otherwise noted"로 시작하는 **1.2 변경 목록**이다.
- fonts 항목: `Justin13.ttf`·`Justin15.ttf`·`JustinFont8/10/11/11Bold/12/12Bold.ttf`·`c&c.ttf`는 "(changed)", `JustinFont7.ttf`·`num_font.ttf`는 "(deleted)", `Roboto-Bold.ttf`·`Roboto-Regular.ttf`와 `fonts/jp/NotoSans_<크기>(_2x).font`, `fonts/zh-Hans/black_<크기>(_2x).font`는 표시가 없으니 1.2에서 **추가**된 것이다.
- 따라서 JustinFont 계열은 1.2 전부터 있었고, Roboto는 1.2에서 더해졌다. 1.2 이전 화면의 산세리프가 Roboto라고 볼 근거는 없다. 위 4번의 «커스텀 TTF와 일반 벡터 폰트가 함께 있다»는 «JustinFont 계열은 바뀜, Roboto·일본어 NotoSans는 추가»로 읽어야 한다.
- 출처: https://gist.github.com/KnightMiner/d7889a8728b7b6b3c0ede8161ea15293
