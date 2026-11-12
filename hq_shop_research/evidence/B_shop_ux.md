# B. 게임 상점 UI 편의와 UX 원칙 조사

조사일 2026-11-12. 대상: 성채를 누르면 열리는 탭형 유닛 상점(유닛 약 11종, 종마다 강화 2~3단, 준비 단계·전투 중 구매, 인구 한도, 640×360 기준 ×2/×3, 마우스+키보드).

## 조사 방법과 한계

- 이 세션은 네트워크 허용 목록이 비어 있어 WebFetch로 페이지를 열 수 없었다(liquipedia.net, dota2.fandom.com, nngroup.com 접속 거부 확인). 그래서 근거 대부분은 WebSearch 결과의 페이지 발췌로 모았고, 되도록 검색을 그 1차 사이트 도메인으로 한정했다.
- 예외 둘: WCAG 원문은 W3C의 GitHub 저장소(w3c/wcag)에서 직접 읽었다. Apple HIG는 공식 페이지 대신, HIG 본문을 담은 npm 패키지 미러(apple-hig-mcp@1.1.3, 2025-06 이후 본문)를 읽었다.
- 조사 막바지에 WebSearch 사용 한도(턴당 200회, 모든 에이전트 공유)가 다 차서 남은 몇 항목은 더 찾지 못했다(맨 끝 «확인 못 한 것»).
- 신뢰도 표기
  - `verified` — 공식·1차 출처(공식 패치노트·개발 블로그·공식 문서·공식 게임 위키·저자 본인의 글과 발표 자료·논문 초록)의 문장을 확인했다. 이번에는 «그 도메인으로 한정한 검색 결과에 인용된 해당 페이지 문장»으로 확인했고, WCAG만 원문을 직접 읽었다.
  - `likely` — 커뮤니티 위키(Liquipedia·Fandom·LoL Wiki·Arknights Terra Wiki 등), 2차 기사, 미러, 논문의 2차 요약, 또는 독립 출처 두 곳이 일치.
  - `unverified` — 포럼·팬 사이트 단일 출처, 출처끼리 엇갈림, 또는 확인 실패.
- 포럼·커뮤니티의 불만과 칭찬은 [플레이어 반응]으로 표시했다.

---

## 1부 — 게임별 상점 편의 기능

### Dota 2

1. **B-01** · Dota 2 — 탭과 분류
   - 상점은 Basic / Upgrades 두 탭이다. Basic 안에 Consumables·Attributes·Armaments·Arcane·Secret, Upgrades 안에 Common·Support·Caster·Weapons·Armor·Artifacts 묶음이 있다.
   - 출처: https://dota2.fandom.com/wiki/Head-up_Display , https://liquipedia.net/dota2/Head-up_Display
   - 신뢰도: `likely` (출처끼리 묶음 이름이 조금 다르고, Liquipedia 옛 문서는 Equipment·Miscellaneous를 씀)

2. **B-02** · Dota 2 (공식 7.00 HUD 소개) — 영웅 맞춤 기본 화면
   - 7.00부터 상점 기본 화면은 «영웅에 맞춰 단순화»되어 그 영웅의 표준 아이템과 대안 추천을 보이고, 모든 영웅이 자주 사는 아이템을 모은 빠른 선택 줄을 함께 둔다. 나머지는 한 번 클릭으로 전통 격자 화면에서 찾는다. 수량 제한 아이템은 남은 재고를 보이고, ALT를 누르면 상점 버튼에 바이백 금화의 여유·부족액을 보인다.
   - 출처: https://www.dota2.com/700/hud/
   - 신뢰도: `verified`

3. **B-03** · Dota 2 — 마우스 구매, Quick Buy, Sticky
   - 상점 아이콘 우클릭 = 즉시 구매(금화가 있으면). 조합 아이템을 우클릭하면 이미 가진 재료를 뺀 나머지 재료만 산다.
   - Shift+좌클릭 = Quick Buy 칸에 올림(기존 목록을 바꿈), Ctrl+Shift+좌클릭 = 목록 뒤에 덧붙임. Quick Buy 칸의 아이템은 우클릭이나 구매 단축키로 사고, 산 것은 목록에서 빠진다. 구매 단축키는 «살 수 있는 첫 항목»을 산다. 금화가 모이면 소리가 난다.
   - Sticky 칸(기본은 귀환 두루마리)은 따로 단축키로 산다.
   - 출처: https://dota2.fandom.com/wiki/Controls , https://dota2.fandom.com/wiki/Head-up_Display , https://steamcommunity.com/sharedfiles/filedetails/?id=3500249747 (2025 가이드)
   - 신뢰도: `likely` (기본 단축키 값 F4·F5·F8은 발췌마다 달라 `unverified`)

4. **B-04** · Dota 2 — 검색
   - 설정 «Shop Search Gets Focus On Open»(`dota_shop_search_autofocus`, 기본 꺼짐)을 켜면 상점을 열 때마다 검색창을 비우고 포커스를 줘서 바로 이름을 칠 수 있다. 2022-03 패치로 검색이 키워드를 더 잘 알아듣고, 찾은 능력치를 강조한다. 별명 검색도 된다(예: «GG» → Iron Branch).
   - 출처: https://liquipedia.net/dota2/Game_Settings , https://dota2.fandom.com/wiki/List_of_Console_Commands , https://liquipedia.net/dota2/March_24,_2022_Patch
   - 신뢰도: `likely`

5. **B-05** · Dota 2 — 되팔기 환불(되돌리기 구실)
   - 산 지 10초 안에 되팔면 전액 환불, 그 뒤나 아이템 능력을 쓴 뒤에는 50%. 소모품은 남은 횟수에 따라 값이 정해진다.
   - 출처: https://liquipedia.net/dota2/Archive:Items , https://liquipedia.net/dota2/TP
   - 신뢰도: `likely`

6. **B-06** · Dota 2 — Buyback Protection(금화 남기기 보호)
   - HUD에서 켜고 끄는 토글이다. 켜 두면 «사고 나면 바이백할 금화가 모자라게 되는» 구매를 막는다. 2025-06-16에 단축키가 생겼다. 더블클릭이나 우클릭 메뉴의 «Purchase Item»으로 사면 보호를 무시한다(일부러 넘는 길을 따로 둠).
   - 출처: Liquipedia 변경 기록(발췌로는 정확한 문서를 특정 못 함: https://liquipedia.net/dota2/Gold/Changelogs , https://liquipedia.net/dota2/Hotkeys ), 무시 경로: https://www.dota2.com/summerscrub2026
   - 신뢰도: `likely` (무시 경로 문장은 공식 페이지로 `verified`)

7. **B-07** · Dota 2 (공식 뉴스) — 신규 플레이어용 안내 상점
   - 신규용 상점은 «무엇을 살지 안내하고, 추천 아이템을 하나 살 때마다 다음 선택지를 드러낸다».
   - 출처: https://www.dota2.com/newsentry/2995430596679058277
   - 신뢰도: `verified`

8. **B-08** · Dota 2 — 확인 못 한 것과 [플레이어 반응]
   - 못 사는 아이템 표시: 2차 가이드 하나가 «금화 여부에 따라 기본 상점 아이템 테두리가 금색»이라고만 적었다. 마지막 탭을 기억하는지는 못 찾았다.
   - [플레이어 반응] Shift+클릭 Quick Buy가 «우클릭 메뉴로 고르는 것보다 훨씬 빠르다»는 칭찬, Quick Buy와 Sticky를 헷갈린다는 글, 같은 아이템 여러 개를 넣으면 하나가 사라진다는 버그 보고.
   - 출처: https://hawk.live/posts/how-to-buy-items-in-dota-2 , https://dev.dota2.com/showthread.php?t=85193 , https://steamcommunity.com/app/570/discussions/0/616189742751666670/ , https://steamcommunity.com/app/570/discussions/0/6960928795824755816/
   - 신뢰도: `unverified`

### League of Legends

9. **B-09** · LoL (공식 패치노트) — «2023 개편»은 못 찾았고, 실제 상점 개편은 패치 10.23(2020-11)
   - 2023년 상점 개편 자료는 찾지 못했다. Recommended / All Items 구조와 Quickbuy 패널을 들인 개편은 패치 10.23(2020-11, 2021 프리시즌)이다(번호 «10.23»과 헷갈린 것으로 보임).
   - 공식 목표: ① 데이터 기반의 간결한 Recommended, ② All Items 사용성 개선, ③ 아이템 세트 사용·가져오기 유지. All Items를 열면 내 챔피언의 클래스 탭이 자동으로 골라지고, Recommended 하위 탭은 그 챔피언이 즐겨 가는 완성템과 재료를 보인다. Quickbuy 패널은 물약·엘릭서·와드·장화처럼 자주 사는 것을 빨리 사게 한다.
   - 출처: https://www.leagueoflegends.com/en-us/news/game-updates/patch-10-23-notes/
   - 신뢰도: `verified`

10. **B-10** · LoL — 기본 탭과 추천 사용률
    - 10.25에서 상점 기본 탭이 All Items → Recommended로 바뀌었다. Riot 개발 글: 약 68%가 Recommended를 주 탐색 방법으로 쓴다. All Items는 «숙련자가 가장 적은 클릭으로 찾고 사는 원스톱 상점»으로 설계했다.
    - 출처: https://wiki.leagueoflegends.com/en-us/V10.25 , https://www.leagueoflegends.com/en-us/news/dev/preseason-2021-gameplay-plans/ ; 68% 수치는 https://www.leagueoflegends.com/en-gb/news/dev/quick-gameplay-thoughts-jan-29/ 또는 https://www.leagueoflegends.com/en-us/news/dev/dev-a-look-back-at-league-in-2020/ (발췌로는 어느 글인지 특정 못 함)
    - 신뢰도: `likely` («원스톱 상점» 문장은 `verified`)

11. **B-11** · LoL — All Items의 묶음·필터·입력
    - All Items는 가격순 대신 등급별로 묶어 기본·시작 아이템을 한곳에 모았다(개발 블로그). 왼쪽 능력치 필터를 여러 개 겹칠 수 있고 «Clear Filters»로 한 번에 끈다.
    - 구매 = 아이콘 우클릭 한 번 또는 좌클릭 두 번. 우클릭으로 팔기도 한다. 상점이 열린 동안 Ctrl+L(또는 Ctrl+Enter) = 검색창 포커스, 검색은 이름·설명·능력치를 알아본다. Ctrl+Tab = 탭 순환. 상점 열기 기본값 P.
    - 출처: https://www.leagueoflegends.com/en-us/news/dev/preseason-item-shop-update/ , https://wiki.leagueoflegends.com/en-us/Shop
    - 신뢰도: `likely` (등급별 묶음 문장은 `verified`)

12. **B-12** · LoL — Undo(되돌리기) 규칙
    - 상점 왼쪽 아래 Undo 버튼은 구매·판매를 역순으로 되돌리고, 쓴 금화·받은 금화를 그대로 되돌린다(벌칙 없음). 횟수 제한은 없지만 상점 범위를 벗어나거나, 전투에 들어가거나, 아이템이 인벤토리로 분배되거나, 특정 스킬·소모품을 쓰면 끊긴다. 쓸 수 없을 때는 회색으로 보인다. 처음 들어온 것은 3.11(2013).
    - 출처: https://wiki.leagueoflegends.com/en-us/Shop , https://www.pcgamer.com/league-of-legends-adds-undo-button-to-pbe , https://www.gameskinny.com/news/league-of-legends-new-undo-button/
    - 신뢰도: `likely`

13. **B-13** · LoL — 아이템 세트(저장 프리셋)
    - 컬렉션의 Items 탭에서 아이템 세트를 만들고 고치고 지운다. 이름·챔피언·맵을 정해 두면 그 조건의 게임에서 상점에 뜬다(세트가 여럿이면 제목 드롭다운으로 고름).
    - 출처: https://wiki.leagueoflegends.com/en-us/Item_set
    - 신뢰도: `likely`

14. **B-14** · LoL — 10.23 직후 [플레이어 반응]
    - 가장 큰 불만은 새 아이템 아이콘이었다: 색이 서로 비슷하고 너무 세밀해 낮은 해상도에서 구분이 어렵다, 색약 모드가 새 상점 아이템과 잘 안 맞는다, 상점 창이 너무 크다. 요구: 창 확대·축소, 산 아이템을 늘 보이기, 이미 신화 아이템을 가졌다는 더 분명한 표시. 몇 주 뒤 리뷰는 «초기 오류를 여럿 고쳐 대체로 긍정적»이라고 평했다.
    - 출처: https://www.gamepressure.com/newsroom/lol-players-demand-changes-in-item-shop/z82886 , https://dotesports.com/?p=343385
    - 신뢰도: `unverified` (기사가 정리한 플레이어 반응)

15. **B-15** · LoL (공식 개발 글) — 아이콘 가독성과 상점 크기 대응
    - 아이콘 재디자인의 «가장 중요한 목표는 가독성»: 작은 크기에서도 알아보게 실루엣과 색을 서로 다르게. 2020-11-20 글: 작은 크기 위주로 아이콘을 여러 차례 다듬고, 배경 디테일을 줄이고 전경·배경 대비를 키우며, 비슷한 아이템(Spellthief's Edge·Hailblade)은 색과 실루엣을 바꾼다. 상점 크기 조절 슬라이더(옵션)를 넣었고 드래그로 크기 조절은 11.1에 들어왔다.
    - 출처: https://www.leagueoflegends.com/en-us/news/dev/preseason-item-shop-update/ , https://www.leagueoflegends.com/en-gb/news/dev/quick-gameplay-thoughts-nov-20/ , https://www.leagueoflegends.com/en-us/news/dev/dev-a-look-back-at-league-in-2020/
    - 신뢰도: `verified`

### Clash of Clans

16. **B-16** · CoC — 2016-10 군대 훈련 개편
    - 모든 병력·주문 훈련을 전용 탭 하나씩으로 모았다(탭 이름 Army / Train Troops / Brew Spells / Quick Train은 기사 기준). 군대 두 벌을 한꺼번에 채울 수 있다. Quick Train: 군대 계획 3개를 저장해 한 번 탭으로 훈련하고, 직전에 쓴 군대를 한 번 탭으로 다시 훈련한다.
    - 출처: https://forum.supercell.com/showthread.php/1284310-Army-Training-Revamp-Quick-Train , https://toucharcade.com/2016/10/05/clash-of-clans-revamping-army-training-quick-train/ , https://www.player.one/clash-clans-october-update-sneak-peek-new-army-quick-train-feature-revealed-supercell-560874 , https://clashofclans.fandom.com/wiki/Barracks
    - 신뢰도: `verified` (Supercell 공식 포럼 공지) / 탭 이름은 `likely`

17. **B-17** · CoC (공식 패치노트) — Quick Train 다듬기
    - 저장 군대는 추가한 순서대로 훈련(같은 종류는 묶음) — v11.866.6. «쓴 것만 다시 훈련»(Clan War Leagues 업데이트). 저장 군대·직전 군대를 클랜 채팅이나 링크로 공유하고 내 슬롯끼리 복사(2021-06). 군대 캠프 자리가 모자라도 막지 않고 되는 만큼 부분 훈련(TH16, 2023).
    - 출처: https://supercell.com/en/games/clashofclans/blog/news/optional-update-v11-866-6-2/ , https://forum.supercell.com/showthread.php/1771268-Clash-of-Clans-Clan-War-Leagues-Update-Patch-Notes!-NOW-IT-S-TIME-FOR-WAR! , https://supercell.com/en/games/clashofclans/blog/game-updates/quality-of-life-improvements-june21/ , https://supercell.com/en/games/clashofclans/blog/release-notes/full-patch-notes-th16/
    - 신뢰도: `verified`

18. **B-18** · CoC — 훈련 화면 조작
    - 병력 카드 탭 = 1기 추가, 누르고 있으면 계속 추가(커뮤니티 튜토리얼). 대기열의 병력마다 빨간 «−»가 있어 하나씩 뺀다(그 병력의 진행분은 잃음). 여럿 빼려면 «−»를 병력마다 꾹 눌러야 해 느리다는 불만이 있다. 대기열에서 끌어 순서를 바꾼다. 훈련된 군대 탭에는 범주(병력·주문·공성 무기)마다 휴지통 버튼이 있다(공식). 훈련 화면 안의 정보(i) 버튼은 확인 못 했다.
    - 출처: https://clashofclans.fandom.com/f/p/2432169775464731326 , https://forum.supercell.com/showthread.php/1756616-Quicker-way-to-remove-troops-from-training-queue , https://supercell.com/en/games/clashofclans/blog/news/home-village-changes-2/
    - 신뢰도: `likely` (휴지통은 `verified`, 꾹 눌러 계속 훈련과 i 버튼은 `unverified`)

19. **B-19** · CoC (공식) — 2025 «Clash Anytime»: 훈련 시간 없앰, Army Recipe
    - 병력·주문·공성 무기의 훈련 시간과 영웅 회복을 없앴다. 군대 훈련 화면을 새 UI로 바꾸고 Quick Train 자리를 Army Recipe(저장 구성)가 대신했다(옛 저장 군대 자동 변환은 기사 기준). 뒤 업데이트에서 군대 훈련 화면 셋째 탭 Cookbook에 마을회관 레벨에 맞춘 Starter Armies(추천 레시피)를 넣었다(TH4부터). 전투 전마다 군대 점검 화면이 뜨므로 Edit Army를 Battle 버튼 안으로 옮겼다.
    - 출처: https://supercell.com/en/games/clashofclans/blog/release-notes/welcome-to-clash-anytime-update/ , https://supercell.com/en/games/clashofclans/blog/news/troop-training-the-wait-is-over/ , https://supercell.com/en/games/clashofclans/blog/release-notes/welcome-to-lets-get-crafty-update/ , https://supercell.com/en/games/clashofclans/blog/news/weve-revamped-the-clash-of-clans-user-interface/ , https://sportskeeda.com/mobile-games/clash-clans-march-2025-update-new-army-screen-recipe-explained
    - 신뢰도: `verified` (자동 변환은 `likely`)

### Arknights

20. **B-20** · Arknights — 8개 직군
    - 직군은 Vanguard·Guard·Defender·Sniper·Caster·Medic·Supporter·Specialist 8개다. 직군은 주로 놓을 수 있는 칸(근접·원거리·둘 다)을 정한다. Vanguard는 배치 비용이 낮고 DP를 회복하는 스킬을 가진다.
    - 출처: https://arknights.wiki.gg/wiki/Operators , https://arknights.fandom.com/wiki/Operator
    - 신뢰도: `likely` (직군 아이콘 자체를 다룬 문서는 검색 한도로 못 봄)

21. **B-21** · Arknights — 배치 막대의 상태 표시
    - 화면에 현재 DP 계수기와 Deployment Limit(동시에 맵에 둘 수 있는 아군 수)를 보인다. DP가 모자란 오퍼레이터 아이콘은 반투명해진다. 맵을 떠나 재배치를 기다리는 동안 아이콘이 빨개지고 남은 재배치 시간이 카운트다운된다. 재배치 시간은 직군·분과마다 다르다(예: 빠른 재배치 Executor 18초; 위키 발췌에 기본 70초·일부 80초).
    - 출처: https://arknights.wiki.gg/wiki/Operation , https://arknights.wiki.gg/wiki/Attribute/Redeployment_time , https://arknights.wiki.gg/wiki/Executor_(branch)
    - 신뢰도: `likely`

22. **B-22** · Arknights — 비용 규칙
    - DP 비용은 직군·분과·희귀도에 따라 다르다. 다시 배치하면 첫 재배치에 1.5배, 그 뒤 2배(상한 99). 후퇴시키면 현재 비용의 절반(내림)을 돌려받고, 쓰러지면 돌려받지 못한다.
    - 출처: https://arknights.wiki.gg/wiki/Attribute/Cost , https://gamepress.gg/arknights/node/47071
    - 신뢰도: `likely`

23. **B-23** · Arknights — 배치 막대 정렬(확인 못 함)
    - «비용순 정렬»이 기본인지 확인하지 못했다. 확인된 것: 대기 구역은 최대 12칸, SilverAsh the Reignfrost 재능은 대기 중인 오퍼레이터를 DP 비용 순으로 «다시 정렬»한다, 몇몇 스킬이 «대기 구역 맨 오른쪽 오퍼레이터»를 가리킨다(칸 위치 자체가 뜻을 가짐).
    - 출처: https://arknights.wiki.gg/wiki/SilverAsh_the_Reignfrost , https://arknights.wiki.gg/wiki/Matsukiri , https://arknights.wiki.gg/wiki/Stationary_Security_Service
    - 신뢰도: `unverified`

### TFT / Dota Underlords

24. **B-24** · TFT — 상점 기본
    - 상점은 챔피언 5장, 값 = 등급(1~5) 골드. 새로고침 2골드(D), 경험치 사기 4골드(F), 커서 아래 챔피언 팔기 E. 상점에서 벤치로 끌어 사고 상점으로 끌어 판다(클릭 구매는 이번 발췌로 확인 못 함). 잠그면 다음 라운드 시작에 자동 새로고침되지 않는다(지금 못 사는 것을 다음에 사려고).
    - 1성 챔피언은 산 값 그대로 되팔린다 → 잘못 산 것을 바로 무를 수 있다. 벤치가 가득 차도, 이미 가진 챔피언을 업그레이드시키는 사본은 자리 없이 살 수 있다.
    - 출처: https://wiki.leagueoflegends.com/en-us/TFT:Tactician , https://wiki.leagueoflegends.com/en-us/TFT:Arena , https://wiki.leagueoflegends.com/en-us/TFT:Champion
    - 신뢰도: `likely`

25. **B-25** · TFT 11.5 (공식 패치노트) — 실수 방지
    - PC에서 1라운드에는 팔기 단축키를 껐다: 하나뿐인 유닛을 잘못 팔고 PvE에 지는 일을 막으려고. 같은 패치에서 공동 선택(carousel) 라운드 동안 상점을 꺼 두었다(11.4B에 먼저 반영).
    - 출처: https://teamfighttactics.leagueoflegends.com/en-au/news/game-updates/teamfight-tactics-patch-11-5-notes/ , https://wiki.leagueoflegends.com/en-us/TFT:V11.5
    - 신뢰도: `verified`

26. **B-26** · TFT — 등급 색과 그 한계
    - 팬 사이트 기준 1~5코스트 = 회색·초록·파랑·보라·금색(공식 출처로는 못 찾음).
    - Riot의 공식 수정 추적 페이지(Follow the Fix, Clarity 분류)에 «챔피언 초상 테두리의 대비와 두께를 키워 희귀도 색을 색약 플레이어 포함 더 쉽게 구분하게» 하는 항목이 보류(Pending)로 올라 있고, 2성 챔피언을 크기·색으로 구분하기 어렵다는 항목도 있다. 18.6: PC 상점의 경험치 사기·새로고침 버튼 hover 상태를 더 잘 보이게 했다.
    - 출처: https://www.magicgameworld.com/teamfight-tactics-tft-champion-rarity/ , https://followthefix.teamfighttactics.leagueoflegends.com/en-us/ , https://teamfighttactics.leagueoflegends.com/en-us/news/game-updates/teamfight-tactics-patch-18-6/
    - 신뢰도: 색 대응은 `unverified` / Follow the Fix 항목은 `verified`

27. **B-27** · Dota Underlords — 상점
    - 상점은 영웅 5장, 준비 단계 시작마다 새로고침, 손으로 새로고침 2골드, 다른 플레이어에게 지면 무료 새로고침 1회. 잠그면 다음 라운드 시작에 새로고침되지 않는다. 영웅 값 = 등급 골드(1등급 1골드…). 등급별 테두리 색은 못 찾았다. 가이드상 잠금 Q·새로고침 R 단축키는 `unverified`.
    - 출처: https://dotaunderlords.fandom.com/wiki/Shop , https://dotaunderlords.fandom.com/wiki/Gold , https://naguide.com/?p=9737
    - 신뢰도: `likely`

### «N개 사기» 관례

28. **B-28** · Age of Empires IV (공식 Xbox Wire) / AoE II / StarCraft II
    - AoE IV: 생산 건물을 고른 채 Shift + 유닛 단축키(또는 버튼 클릭) = 그 유닛 5기를 대기열에 넣는다.
    - AoE II: Shift-클릭으로 5기(포럼). 대기열에서 Shift-클릭으로 5기 빼기는 요청만 보이고 구현은 확인 못 함. StarCraft II의 Shift ×5는 확인 못 함.
    - 출처: https://news.xbox.com/en-us/2021/10/22/age-of-empires-iv-hotkeys-revealed/ , https://forums.ageofempires.com/t/remove-five-units-at-once-from-queue-using-shift-click/72278
    - 신뢰도: AoE IV `verified` / AoE II·SC2 `unverified`

29. **B-29** · Factorio (공식 위키)
    - 레시피 좌클릭 = 1개 제작, 우클릭 = 5개, Shift+좌클릭 = 할 수 있는 만큼 전부. 제작 대기열에서도 같은 짝으로 취소한다(좌 1, 우 5, Shift 전부).
    - 출처: https://wiki.factorio.com/Crafting , https://wiki.factorio.com/Controls
    - 신뢰도: `verified`

30. **B-30** · Stardew Valley (공식 위키)
    - 상점에서 Shift+클릭 = 5개, 누르고 있으면 5개씩 계속 산다. Ctrl+Shift = 25개(1.5.5부터).
    - 출처: https://stardewvalleywiki.com/Controls , https://stardewvalleywiki.com/Pierre's_General_Store
    - 신뢰도: `verified`

31. **B-31** · Terraria (공식 위키)
    - NPC 상점에서 오른쪽 버튼을 누르고 있으면 사는 개수가 늘고, 오래 누를수록 빨라진다(가속). 왼쪽 Shift를 함께 누르면 10개 묶음(데스크톱 1.4.5.4에서 추가, 묶음 구매 속도도 올림).
    - 출처: https://terraria.wiki.gg/wiki/Game_controls , https://terraria.wiki.gg/wiki/NPCs
    - 신뢰도: `verified`

32. **B-32** · RimWorld (위키)
    - 수량 버튼에 Ctrl = ×10, Shift = ×100, Ctrl+Shift = ×1000. 거래 화면·캐러밴 짐 꾸리기·작업 지시 수량에 공통이다.
    - 출처: https://rimworldwiki.com/wiki/Controls
    - 신뢰도: `likely`

33. **B-33** · 누르고 있으면 반복 (Microsoft UI 문서·NN/g)
    - Microsoft RepeatButton: 누르고 있는 동안 Click을 되풀이한다. Delay = 반복 시작 전 대기(ms), Interval = 반복 간격(ms), UWP 기본값은 둘 다 250. 카운터를 올리고 내리는 데 쓰라고 권한다.
    - NN/g 입력 스테퍼 지침: 버튼을 길게 누르면 빠르게 연속 증감하게 하고, 데스크톱에서는 화살표 키도 받게 한다.
    - 출처: https://learn.microsoft.com/en-us/uwp/api/windows.ui.xaml.controls.primitives.repeatbutton.delay?view=winrt-22621 , https://learn.microsoft.com/en-us/uwp/api/windows.ui.xaml.controls.primitives.repeatbutton.interval?view=winrt-22621 , https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/buttons , https://www.nngroup.com/articles/input-steppers/
    - 신뢰도: `verified`

34. **B-34** · 확인창 vs 즉시 구매 (Apple HIG·Xbox Accessibility Guideline 115)
    - Apple HIG Alerts: 흔하고 되돌릴 수 있는 동작에는 파괴적이어도 경고창을 띄우지 말라. 드물고 되돌릴 수 없는 파괴적 동작에만 띄워라.
    - XAG 115: 구매·아이템 판매·저장 덮어쓰기 같은 영구적·파괴적 동작에는 검토·확인·되돌리기 수단을 줘라(Fallout 76의 두 단계 상인 구매가 예). v2.0(2021-02-16)에서 «파괴적 동작 확인에 버튼 길게 누르기를 요구하지 말거나 대안을 줘라»를 더했다.
    - 출처: https://developer.apple.com/design/human-interface-guidelines/alerts (미러로 읽음), https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/115 , https://learn.microsoft.com/en-us/xbox/accessibility/xag-version-history
    - 신뢰도: XAG `verified` / Apple `likely` (미러)

---

## 2부 — UX 원칙

### 힉의 법칙과 메뉴의 넓이·깊이

35. **B-35** · Hick–Hyman 법칙과 적용 범위
    - 선택지 수 n에 따라 결정 시간이 RT = a + b·log2(n)으로 늘어난다(Hick 1952, Hyman 1953). 메뉴에서 이 로그 관계는 «어디 있는지 아는» 숙련자에게 맞고, 처음 보는 사람은 항목을 하나씩 훑으므로 항목 수에 비례(선형)해 늘어난다. Cockburn·Gutwin·Greenberg(CHI 2007) 메뉴 성능 모델: 초보 = 시각 탐색(선형), 숙련 = Hick–Hyman 결정, 여기에 Fitts 포인팅과 초보→숙련 전이를 더함.
    - 출처: https://lawsofux.com/hicks-law/ , https://researchr.org/publication/CockburnGG07 (DOI 10.1145/1240624.1240723)
    - 신뢰도: `likely` (원 논문 미열람)

36. **B-36** · 메뉴 넓이·깊이 실험들
    - Miller(1981): 항목 64개를 64¹·2⁶·4³·8²로 나눈 실험에서 8²(8개씩 2단계)가 가장 빠르고 오류가 적었고, 깊어질수록 느려졌다.
    - Kiger(1984): 2⁶·4³·8²·16×4·4×16 비교, 넓고 얕은 구조가 더 빠르고 선호됐다(4×16·16×4·8²끼리는 비슷).
    - Larson·Czerwinski(CHI 1998, 512개): 깊이가 성능을 해쳤고(2단계가 3단계보다 빠름), 다만 가장 넓은 구조보다 중간 넓이(16×32)가 나았다.
    - Landauer·Nachbar(CHI 1985): 정렬된 항목에서 선택 시간은 넓이의 로그에 비례해 늘었다.
    - 출처: https://scilit.com/publications/12d56c9b7e468c11221b4ed0f6916d8b (Miller), https://scilit.com/publications/640f34f509dbaf2e79a7e980ddb8224b (Kiger), https://www.microsoft.com/en-us/research/publication/web-page-design-implications-memory-structure-scent-information-retrieval/ , https://hcibook.com/e3/online/menu-breadth , https://ktisis.cut.ac.cy/bitstream/20.500.14279/2872/6/Zaphiris2000-Depth_Vs_Breath.pdf
    - 신뢰도: `likely` (Larson·Czerwinski의 «깊이는 해롭고 중간이 가장 넓은 구조보다 나음»은 초록 문장으로 `verified`)

37. **B-37** · NN/g — 평평한 구조 vs 깊은 구조
    - 깊은 구조는 대체로 적당히 넓은 구조보다 쓰기 어렵다. 깊으면 맨 위 라벨이 막연해진다. 숨긴 내비게이션은 사용자를 좌절시켰다. 늘 보이는 내비게이션과, 내용에 맞는 넓이·깊이를 권한다.
    - 출처: https://www.nngroup.com/articles/flat-vs-deep-hierarchy/
    - 신뢰도: `verified`

38. **B-38** · 탭 개수와 메뉴 단계 지침 (Material·Apple)
    - Material 3 Tabs: 한 번에 탭 4개를 넘기지 말 것(5개 이상이면 비좁음). 고정 탭은 같은 폭, 라벨은 짧게, 아이콘만인 탭과 글자만인 탭을 섞지 말 것, 탭은 같은 계층의 내용을 묶는다.
    - Apple HIG Tab bars: 탭이 적을수록 다니기 쉽다, 넘치는 «More» 탭은 피하라, 탭 제목은 되도록 한 단어. Apple Menus: 하위 메뉴는 한 단계로 제한하고, 하위 메뉴 항목이 약 5개를 넘으면 새 메뉴를 고려하라.
    - 출처: https://m3.material.io/components/tabs/guidelines , https://m2.material.io/components/tabs , https://developer.apple.com/design/human-interface-guidelines/tab-bars , https://developer.apple.com/design/human-interface-guidelines/menus
    - 신뢰도: Material `verified` / Apple `likely` (미러)

### 피츠의 법칙

39. **B-39** · NN/g — Fitts의 법칙
    - 가리키는 시간은 목표까지의 거리와 목표 크기로 정해진다: 목표를 크게(빨라지고 오류도 줄어듦), 가깝게. 마우스 조작에서 화면 가장자리는 커서가 넘어가지 못하는 벽이라 한 방향으로 무한히 큰 목표처럼 군다(macOS 메뉴 막대가 위 가장자리에 붙은 까닭).
    - 출처: https://www.nngroup.com/articles/fitts-law/
    - 신뢰도: `verified`

40. **B-40** · Tognazzini (AskTog) — 모서리와 «prime pixel»
    - 화면 네 모서리는 두 방향으로 무한한 «마법의 픽셀»이다. 가장 가까운 목표는 커서가 지금 있는 픽셀(prime pixel)이어서, 팝업 메뉴는 커서 자리에 떠서 이동 거리를 없앤다. 가장자리·모서리 효과는 커서가 그 끝에서 실제로 멈출 때만 생긴다는 단서도 달았다.
    - 출처: https://www.asktog.com/columns/022DesignedToGiveFitts.html , https://asktog.com/atc/principles-of-interaction-design/
    - 신뢰도: `verified`

41. **B-41** · 파이 메뉴 vs 줄 메뉴 (Callahan 외, CHI '88)
    - 파이 메뉴가 목표 찾는 시간이 짧고 오류율이 낮았다(저자 회고로 약 15% 빠름). 주관적 선호는 비슷했다.
    - 출처: https://sites.umiacs.umd.edu/node/16962 (DOI 10.1145/57167.57182), https://www.osnews.com/story/30371/pie-menus-a-30-year-retrospective/
    - 신뢰도: `likely`

### 닐슨의 사용성 휴리스틱

42. **B-42** · NN/g 10 휴리스틱 가운데 상점에 닿는 것
    - #1 시스템 상태 보이기(지금 상태가 보이면 무슨 일이 일어났고 다음에 뭘 할지 안다). #3 사용자 통제와 자유(쉽게 빠져나오고 되돌릴 수 있으면 자신감이 생긴다). #5 오류 예방(오류가 나기 쉬운 조건을 없애거나, 그런 조건을 검사해 실행 전에 확인 기회를 준다; 부주의에서 오는 slip과 잘못 이해한 mistake를 구분). #6 회상보다 인식(라벨 붙은 보이는 아이콘이 외운 단축키보다 쉽다). #7 유연성과 효율(초보에게는 안 보이는 가속기가 숙련자를 빠르게 한다).
    - NN/g는 이 휴리스틱이 게임에도 그대로 적용된다고 따로 정리했다(피드백 예: 체력 막대, 정보 과부하 경고).
    - 출처: https://www.nngroup.com/articles/ten-usability-heuristics/ , https://www.nngroup.com/articles/usability-heuristics-applied-video-games/
    - 신뢰도: `verified`

43. **B-43** · NN/g — 확인창은 아끼고 되돌리기를 앞에
    - 일상 동작에 확인창을 달면 사람들이 읽지 않고 습관적으로 넘긴다. 기본값 «예»는 피한다. 좋은 확인창도 모든 실수를 막지 못하니 되돌리기를 우선한다. 확인창은 영향이 큰 동작에만.
    - 출처: https://www.nngroup.com/articles/confirmation-dialog/ , https://www.nngroup.com/articles/user-mistakes/ , https://www.nngroup.com/articles/serial-task-switching/
    - 신뢰도: `verified`

### Celia Hodent (The Gamer's Brain)

44. **B-44** · Hodent — 게임 사용성 기둥 목록
    - GDC Europe 2014 발표(Developing UX Practices at Epic Games)와 이후 책 The Gamer's Brain(2017)에서 게임 사용성 휴리스틱을 일곱으로 추렸다: signs & feedback, clarity, form follows function, consistency, minimum workload, error prevention & recovery, flexibility. 닐슨과 Laitinen의 것을 줄여 고쳤다고 밝혔다. 틀은 Good UX = Usability + GameFlow(2014)에서 Game UX = Usability + Engage-ability(동기·감정·몰입)로 이어진다.
    - 출처: https://celiahodent.com/ux-practices-epic-games/ , https://media.gdcvault.com/gdceurope2014/Presentations/828961_Celia_Hodent.pdf , https://interaction19.ixda.org/download/talk-the-ux-of-fortnite-celia-hodent.pdf
    - 신뢰도: `verified` (책 본문은 못 읽음)

45. **B-45** · Hodent — 기둥별 권고
    - Signs & feedback: 이끄는(inviting) 신호는 눈길을 끌어 안내하고, 알리는(informative) 신호는 읽기 쉽되 너무 눈길을 끌지 않게.
    - Clarity: 기호가 뜻한 대로 지각되고 글은 읽기 쉽게.
    - Form follows function: 모양이 기능을 말해야 한다. 장식이 기능처럼 보이는 «거짓 행동유도»를 피한다(장식용 불꽃을 발전기로 오인한 Fortnite 예).
    - Consistency: UI와 피드백을 한결같이 해서 다시 배우지 않게. 다만 서로 다른 기능까지 똑같아 보이게 하는 것은 좋지 않다. 빨강은 즉각적인 위협에만 쓴다(사소한 알림에 쓰면 피해 피드백이 약해짐).
    - Minimum workload: 인지 부담(기억·주의)과 물리 부담(클릭·버튼 수)을 줄인다. 의도한 부담이 아니면 없앤다.
    - Error prevention & recovery: 의도한 도전이 아닌 오류는 막고, 나면 빨리 회복하고 원인을 알게 한다.
    - Flexibility: 조작·UI·카메라·도움말을 모두 바꿀 수 있게(접근성과 연결).
    - 인식 예: 무기 아이콘에 탄약 종류를 그려 기억 대신 알아보게 했다.
    - 출처: https://celiahodent.com/ux-practices-epic-games/ , https://media.gdcvault.com/gdceurope2014/Presentations/828961_Celia_Hodent.pdf , https://www.creativebloq.com/features/how-neuroscience-and-ux-impacts-video-game-design , https://uxdesign.cc/usability-heuristics-and-competition-in-games-707cac36ff12
    - 신뢰도: `verified` (Error prevention 설명 문장은 2차 글이라 `likely`)

### 공간 일관성과 근육 기억

46. **B-46** · Mitchell·Shneiderman (1989) — 동적 vs 정적 메뉴
    - 63명, 과제 24개. 가장 자주 고른 항목이 늘 맨 위로 오는 동적 메뉴를 먼저 쓴 사람이 정적 메뉴보다 유의하게 느렸고(첫 묶음), 두 번째 묶음에서는 차이가 없었다. 81%가 정적 메뉴를 더 좋아했다.
    - 출처: https://umiacs.umd.edu/node/17115 (DOI 10.1145/67243.67247)
    - 신뢰도: `verified` (초록 기준)

47. **B-47** · Findlater·McGrenere (CHI 2004) — 정적·적응형·사용자 조정형 메뉴
    - 27명. 정적 메뉴가 적응형(시스템이 바꿈)보다 유의하게 빨랐고, 사용자가 직접 고치는 adaptable 메뉴는 조건에 따라 적응형보다 빨랐다. 다수가 adaptable을 가장 좋아했다.
    - 출처: https://www.cs.ubc.ca/labs/edapt/papers/findlater2004.pdf (DOI 10.1145/985692.985704)
    - 신뢰도: `verified` (초록 기준)

48. **B-48** · Gajos 외 (AVI 2006), Scarr 외 (CHI 2012)
    - 자주 쓰는 항목을 따로 마련한 영역에 «복사»하고 원래 자리는 그대로 두는 split 인터페이스가 비적응형보다 유의하게 빨랐다. 항목을 «옮기는» 방식은 불안정하다는 불평을 들었다.
    - CommandMaps: 명령 대부분을 한 화면에 늘 같은 배치로 보이면 숙련자는 메뉴·리본보다 유의하게 빨라졌다(초보는 비슷).
    - 출처: https://www.eecs.harvard.edu/~kgajos/papers/2006/kgajos-avi06.pdf , https://www.eecs.harvard.edu/~kgajos/papers/2006/kgajos-avi06-slides.pdf , https://hci.cs.umanitoba.ca/publications/details/improving-command-selection-with-commandmaps
    - 신뢰도: `likely`

49. **B-49** · NN/g — 공간 기억
    - 공간 기억은 안정된 배치와 반복 연습이 있어야 생긴다. 실험적 적응형 인터페이스 대부분이 실패한 까닭은 공간 기억을 깨기 때문이다. Office가 최근 사용 순으로 다시 정렬하는 메뉴를 시도했지만 «놓아둔 자리에 아무것도 없어서» 매번 다시 훑어야 했고 배울 수 없었다. 공간 기억을 깨지 않는 적응은 자주·최근 항목을 위한 별도 영역이다(원래 자리에도 그대로 둠, 예: Office 글꼴 목록 위의 최근 글꼴).
    - 출처: https://www.nngroup.com/articles/spatial-memory/
    - 신뢰도: `verified`

50. **B-50** · NN/g·Apple — 못 쓰는 항목은 숨기지 말고 흐리게
    - NN/g 드롭다운 지침: 쓸 수 없는 선택지는 지우지 말고 회색으로. 지우면 공간 일관성을 잃고 배우기 어려워진다. hover로 왜 못 쓰는지, 어떻게 쓸 수 있게 되는지 짧게 알린다. 맥락 메뉴도 숨기기보다 비활성화를 권한다.
    - Apple: 탭 막대 버튼은 내용이 없을 때도 끄거나 숨기지 말라(그러면 불안정하고 예측하기 어려워 보임), 빈 섹션은 이유를 설명하라. 메뉴의 못 쓰는 항목은 흐리게 보이고, 모든 항목을 못 쓰더라도 메뉴는 열리게 하라.
    - 출처: https://www.nngroup.com/articles/drop-down-menus/ , https://www.nngroup.com/articles/contextual-menus-guidelines/ , https://developer.apple.com/design/human-interface-guidelines/tab-bars , https://developer.apple.com/design/human-interface-guidelines/menus
    - 신뢰도: NN/g `verified` / Apple `likely` (미러)

### 색 부호화와 접근성

51. **B-51** · Game Accessibility Guidelines — 색만으로 정보 전달 금지 (Basic)
    - «Ensure no essential information is conveyed by a fixed colour alone»: 색은 글·기호·무늬·모양 같은 다른 수단을 거드는 보조로 쓴다. 적록 구분 어려움은 남성의 약 8~10%. 색약 시뮬레이터로 대비를 확인한다(빨강이 어둡게 보이는 경우가 흔함). 제때 기호를 알아보기 어려운 경우에는 색을 바꿀 수 있게 하고, 흔한 색각 유형 프리셋과 사용자 지정을 함께 권한다. 예: Hue 색약 모드는 색 영역에 기호를 더하고, GTA IV 지도는 색 대신 아이콘으로 지점을 구분한다.
    - 출처: https://gameaccessibilityguidelines.com/ensure-no-essential-information-is-conveyed-by-a-fixed-colour-alone/ , https://gameaccessibilityguidelines.com/hue-colorblind-mode/ , https://gameaccessibilityguidelines.com/grand-theft-auto-iv-map/
    - 신뢰도: `verified`

52. **B-52** · WCAG 2.2 SC 1.4.1 Use of Color (Level A)
    - 원문: «Color is not used as the only visual means of conveying information, indicating an action, prompting a response, or distinguishing a visual element.»
    - 출처: https://www.w3.org/TR/WCAG22/#use-of-color (원문 파일: https://github.com/w3c/wcag/blob/main/guidelines/sc/20/use-of-color.html )
    - 신뢰도: `verified` (원문 직접)

53. **B-53** · XAG 103·Microsoft Game Publishing Guide·Apple HIG
    - XAG 103: 색만으로 정보를 나타내지 말 것. 기호에는 글 라벨을 함께(느낌표 + 글).
    - 출판 지침의 접근성 기준: 색으로 나타낸 핵심 정보는 모양·무늬·아이콘·글 라벨 같은 추가 표지를 하나 이상 갖거나, 플레이어가 색을 바꿀 수 있어야 한다.
    - Apple HIG: 색만으로 전달하지 말고 모양·아이콘을 더하라. 적록·청주황 조합이 특히 어렵다. 게임 캐릭터 같은 색 구성을 바꿀 수 있게 하라.
    - 출처: https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103 , https://learn.microsoft.com/en-us/gaming/game-publishing/concepts/metadata-accessibility , https://developer.apple.com/design/human-interface-guidelines/accessibility
    - 신뢰도: XAG·출판 지침 `verified` / Apple `likely` (미러)

### 최소 목표 크기

54. **B-54** · WCAG 2.2 SC 2.5.8 (AA)·2.5.5 (AAA)
    - 2.5.8: 포인터 목표는 24×24 CSS px 이상. 더 작으면 «각 목표 중심에 지름 24px 원을 그렸을 때 다른 목표·원과 겹치지 않아야» 하는 간격 예외 등 예외 다섯 가지. 작업반은 터치만이 아니라 마우스·트랙패드 등 모든 포인터 입력에 걸리는 문턱이라 터치용 큰 값 대신 24px를 골랐다.
    - 2.5.5: 44×44 CSS px 이상. 이해 문서는 «자주 쓰는 컨트롤, 쉽게 되돌릴 수 없는 동작, 화면 가장자리 가까운 컨트롤, 연속 작업의 일부»라면 더 크게 하라고 권한다.
    - 출처: https://www.w3.org/TR/WCAG22/#target-size-minimum , https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html , https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html (원문 파일: https://github.com/w3c/wcag )
    - 신뢰도: `verified` (원문 직접)

55. **B-55** · Apple HIG — 컨트롤 크기와 간격
    - 표(기본 / 최소): iOS·iPadOS 44×44 / 28×28 pt, macOS 28×28 / 20×20, tvOS 66×66 / 56×56, visionOS 60×60 / 28×28, watchOS 44×44 / 28×28. 간격도 크기만큼 중요하다: 테두리(bezel)가 있는 요소는 둘레 약 12pt, 없는 요소는 보이는 가장자리 둘레 약 24pt 여백. Apple 디자인 팁: 손가락으로 정확히 누르게 최소 44×44pt.
    - 출처: https://developer.apple.com/design/human-interface-guidelines/accessibility , https://developer.apple.com/design/tips/ , https://developer.apple.com/forums/thread/739201
    - 신뢰도: 44×44는 `verified` / 표·여백 수치는 `likely` (미러)

56. **B-56** · Material Design — 48dp
    - 터치 목표 최소 48×48dp(물리 약 9mm), 목표 사이 8dp 이상. 마우스 같은 포인터 목표는 44×44dp 이상. 보이는 아이콘은 24dp여도 둘레 여백으로 48dp 목표를 만들면 된다. 고밀도 배치는 접근성 기준에 못 미치므로 사용자가 골라 켜게 한다.
    - 출처: https://m2.material.io/design/usability/accessibility.html , https://m3.material.io/foundations/designing/structure , https://support.google.com/accessibility/android/answer/7101858 , https://m2.material.io/design/layout/applying-density.html
    - 신뢰도: `verified`

57. **B-57** · 게임 전용 지침 (GAG·XAG)
    - GAG(Basic, Motor) «Ensure interactive elements / virtual controls are large and well spaced, particularly on small or touch screens»: 터치 이상값 2.4cm, 작은 폰 최소 0.96cm을 출발점으로 삼는다. 붙어 있으면 더 크게. 마우스·아날로그 스틱 커서에도 같은 문제가 있다. 인터페이스 크기 조절 허용은 별도 지침.
    - XAG 107(모바일 절, v3.1 2022-10): 모든 터치 목표의 크기·간격·위치를 플레이어가 바꿀 수 있게. 기본 최소 폰 15×15mm, 태블릿 24×24mm(발췌 한 곳은 폰 24mm로 엇갈림). 이웃 컨트롤이 잘못 눌리지 않게 띄운다.
    - XAG 112/113: 초점 이동 순서는 화면의 시각 흐름을 따르고, 초점 표시는 늘 화면 안에서 보이게(테두리·크게·굵은 글씨).
    - 데스크톱 마우스 게임용 수치 기준은 못 찾았다.
    - 출처: https://gameaccessibilityguidelines.com/ensure-interactive-elements-virtual-controls-are-large-and-well-spaced-particularly-on-small-or-touch-screens/ , https://gameaccessibilityguidelines.com/allow-interfaces-to-be-resized/ , https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107 , https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112 , https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113
    - 신뢰도: GAG `verified` / XAG 107 수치는 `likely` (발췌끼리 엇갈림) / XAG 112·113 `verified`

### 탭

58. **B-58** · NN/g — Tabs, Used Right
    - 탭은 중요도가 고르지 않은 내용에 쓴다(기본 탭이 가장 주목받고 나머지는 무시되기 쉬우므로, 기본이 아닌 탭에는 꼭 필요한 내용이 아닌 보조 내용을). 탭끼리 비교해야 하면 쓰지 않는다(왔다 갔다 하는 기억·조작 비용). 라벨은 보통 1~2 단어. 선택된 탭은 뚜렷하게, 선택 표시를 둘 이상(밑줄·굵거나 진한 글자·크기·아이콘) — 탭이 둘뿐일 때 특히. 탭은 발견성이 낮다.
    - 출처: https://www.nngroup.com/articles/tabs-used-right/
    - 신뢰도: `verified`

59. **B-59** · Apple·Material — 탭의 상태와 고정성, 그리고 «마지막 탭 기억»
    - Apple Tab bars: 탭 막대는 섹션 사이를 빠르게 오가며 «각 섹션 안의 현재 탐색 상태를 보존»한다. 다른 섹션으로 가도 탭 막대를 보이게 둔다(숨기면 어디 있는지 잊음). 탭은 동작(action)이 아니라 이동에 쓴다. 새 정보는 배지로 알린다.
    - Material: 탭은 같은 계층의 내용을 묶고, 고정 탭은 모바일에서 잘림 없이 모두 보여야 한다.
    - «마지막 탭을 기억하라»는 직접 지침은 못 찾았다(Apple의 «상태 보존»이 가장 가깝다). 게임 쪽에서는 LoL이 기억 대신 고정 기본 탭(Recommended)을 택했다(B-10).
    - 출처: https://developer.apple.com/design/human-interface-guidelines/tab-bars , https://m3.material.io/components/tabs/guidelines , https://m2.material.io/components/tabs
    - 신뢰도: Apple `likely` (미러) / Material `verified` / «마지막 탭 기억»은 `unverified`

---

## 설계에 쓸 원칙 (작은 탭형 유닛 상점)

전제: 유닛 약 11종(금화), 종마다 강화 2~3단(웨이브 사이에만), 준비 단계와 전투 중 구매(시간이 흐르고 영웅 조작이 이어짐), 성채 옆에 바로 생겨 집결지로 걸어감, 인구 한도, 640×360 기준 ×2/×3, 마우스+키보드. 아래 수치(시간 창·묶음 수·반복 간격 등)는 출발값이고, 난이도에 닿는 것은 data 쪽 손잡이로 둔다.

1. **자리를 고정한다** (B-46~B-50)
   - 11종의 탭 소속, 탭 안 칸 위치, 탭 순서를 판 안에서도 판 사이에서도 바꾸지 않는다. 살 수 있는 것부터, 자주 산 것부터 다시 정렬하지 않는다.
   - 못 사는 칸(금화 부족·인구 가득·잠김)도 그 자리에 두고 흐리게 + 이유를 보인다. 숨기지 않는다.
   - «최근·추천»을 두려면 원래 칸은 그대로 두고 별도 줄에 복사로 둔다.

2. **패널은 늘 같은 화면 자리에 연다** (B-39, B-40, B-42 #1)
   - 같은 위치·같은 크기(예: 아래 가장자리 띠)로 연다. 성채 클릭은 여는 방법 가운데 하나로 두고, 카메라를 따라 움직이는 성채 옆에 패널을 띄우지 않는다(공간 기억, 그리고 성채 옆 생성 장면을 가리지 않게).
   - 성채 옆 팝업은 여는 클릭과 첫 구매까지 거리가 짧은 장점이 있지만(prime pixel), 자리가 매번 달라지고 생성 지점을 가린다.
   - 가장자리의 «무한 너비» 이점은 커서가 그 끝에서 멈출 때(전체화면·커서 가둠)만 생긴다. 창 모드라면 가장자리에 붙인다고 빨라지지 않는다(B-40에서 추론).

3. **탭은 3개 이하, 고정 순서** (B-35~B-38, B-58)
   - 11종이면 4·4·3. 아이콘 + 한 단어 라벨을 모든 탭에 똑같이(아이콘만·글자만 섞지 않음). 선택된 탭은 표시 둘 이상(패널 몸통과 이어진 모양 + 밝은 글자나 밑줄). 탭 버튼은 끄거나 숨기지 않는다.
   - 근거상 11개는 한 단계로도 충분하다: 기준 640px 폭에 32px 카드 11장 + 4px 간격 = 392px라 한 줄에 다 들어간다. 탭을 쓰면 다른 탭 유닛을 살 때마다 클릭이 한 번 더 든다. 그러니 전투 중 섞어 사는 유닛끼리는 같은 탭에 둔다(탭을 오가며 비교해야 하면 탭이 맞지 않다는 NN/g 기준).

4. **같은 판 안에서는 마지막 탭으로 다시 연다** (B-59, B-10)
   - Apple의 «섹션 상태 보존»을 따른다. 새 판은 첫 탭. 직접 지침이 없어 근거가 약한 규칙이다.

5. **구매 입력** (B-28~B-33, B-17)
   - 좌클릭 = 1기 즉시 구매, 확인창 없음.
   - Shift+좌클릭 = 5기(AoE IV·Stardew 관례). 배수 관례가 게임마다 달라서(Shift가 ×5·×10·×100) 카드 툴팁에 «Shift ×5»처럼 적는다.
   - 꾹 누르기 = 반복 구매: 약 250ms 뒤 시작, 간격 약 250ms(RepeatButton 기본값). 가속은 선택.
   - 묶음 구매는 금화·인구 한도 안에서 되는 만큼만 사고, «3/5 구매 — 인구 가득»처럼 결과를 띄운다(CoC 부분 훈련).

6. **확인창 대신 되돌리기** (B-05, B-12, B-24, B-34, B-43)
   - 전투 중 유닛 구매에는 «직전 구매 되돌리기»를 둔다: 산 뒤 짧은 시간 안이고, 그 유닛이 성채 옆 생성 구역을 떠나기 전·싸우기 전이면 전액 환불(LoL Undo, Dota 10초, TFT 1성 되팔기). 못 쓰는 동안 버튼은 흐리게(LoL).
   - 웨이브 사이 강화는 다음 웨이브가 시작하기 전까지 전액 되돌릴 수 있게(LoL: 상점을 떠나기 전까지).
   - 확인창은 넣지 않는다. 드물고 되돌릴 수 없는 동작에만 쓴다.

7. **상태를 늘 보인다** (B-42 #1, B-21, B-03, B-45)
   - 패널에 금화, 인구(현재/한도), 카드마다 값을 늘 보인다.
   - 성공하면 소리 + 카드 반짝 + 성채 옆 생성 표시. 실패하면 커서 가까이에 이유(«금화 20 부족», «인구 가득», «웨이브 사이에만»).

8. **못 사는 이유를 색만으로 말하지 않는다** (B-50~B-53, B-21)
   - 금화 부족 = 값 글자색 바꿈 + 동전 아이콘 빗금 + 부족액 숫자. 인구 가득 = 인구 칸 강조 + 카드에 인구 아이콘. 잠김 = 자물쇠. 전투 중 강화 불가 = 모래시계 아이콘이나 글.

9. **범주 색은 모양과 함께** (B-14, B-15, B-26, B-51~B-53)
   - 탭(범주)마다 색 + 아이콘 모양 + 라벨. 카드에도 범주 아이콘을 넣는다.
   - 강화 단계는 칸 수(●●○)나 숫자로 보인다. 색만으로 단계를 나타내지 않는다.
   - 16px 아이콘에서도 유닛마다 실루엣이 달라야 한다(LoL 아이콘 불만과 Riot 대응). 색 조합은 적록·청주황 시뮬레이터로 확인한다.

10. **크기는 가장 낮은 배율(×2)에서 맞춘다** (B-54~B-57)
    - 환산(OS 배율 100% 가정): WCAG 2.5.8의 24px = ×2에서 기준 12px, ×3에서 8px. 2.5.5의 44px = ×2에서 기준 22px.
    - 구매 카드의 누르는 영역은 기준 22×22px 이상(자주 쓰는 컨트롤이라 AAA 쪽). 탭·되돌리기·닫기 같은 작은 버튼은 12×12px 이상, 되도록 16. 칸 사이는 2px 이상 띄운다.
    - OS 배율이 150%면 같은 문턱이 1.5배로 오른다.

11. **키보드** (B-42 #6·#7, B-45 Flexibility)
    - 이미 쓰는 키(1–0, -, =, Q W E R A S H T B V C, F1–F3)는 상점이 열려 있어도 다른 뜻으로 바꾸지 않는다(전투 중 영웅 조작이 이어지므로).
    - 빈 키에서 꼭 필요한 셋만 준다: 상점 열기·닫기, 탭 순환(예: Tab / Shift+Tab), 직전 구매 반복. 칸별 구매 키는 나중 순위(예: Y U I O). 후보 키가 정말 비어 있는지는 실제 키맵으로 확인해야 한다.
    - 카드에 단축키 글자를 적어, 외우지 않아도 알아보게 한다.

12. **빠른 재구매** (B-03, B-13, B-16, B-19)
    - «직전 구매 반복» 키 하나가 먼저다. 준비 단계에는 «지난 웨이브 구성 다시 사기» 버튼(정해진 순서로, 모자라면 되는 만큼). 저장 프리셋 여러 칸은 나중 순위.

13. **강화 표시** (B-50, B-59)
    - 강화 단계는 각 유닛 카드 안, 같은 자리에 보인다. 전투 중에는 강화 버튼을 숨기지 말고 흐리게 + «웨이브 사이에만». 강화를 따로 탭으로 둔다면 그 탭도 전투 중 열리게 두고, 읽기 전용 + 이유 표시.

14. **실수 방지** (B-06, B-12, B-25)
    - 되돌릴 수 없는 동작(판매·해산 같은 것이 있다면)은 구매와 같은 키나 이웃 칸에 두지 않는다. 시작 직후처럼 오조작이 치명적인 때는 그 단축키를 잠시 끈다(TFT 11.5).
    - 선택 기능: «강화용 금화 남기기» 토글(Dota Buyback Protection 꼴). 켜면 남길 금액 아래로 떨어지는 전투 중 구매를 막고, 더블클릭하면 무시하고 산다.

15. **추천은 자리를 바꾸지 않는 표시로** (B-07, B-10, B-19)
    - 처음 하는 사람용 추천은 별도 탭이 아니라 원래 카드 위의 작은 표시로 보인다. LoL은 추천 탭이 약 68%의 주 경로였고, Dota·CoC도 처음에는 추천·안내를 먼저 보인다.

---

## 확인 못 한 것

- LoL «2023 상점 개편» 자료: 못 찾음. 해당 구조는 패치 10.23(2020-11)에서 왔다.
- Dota 2: 못 사는 아이템의 표시 방식, 마지막 탭 기억 여부, 기본 단축키 값.
- Clash of Clans: «꾹 눌러 계속 훈련»(커뮤니티 글뿐), 훈련 화면의 정보(i) 버튼.
- Arknights: 배치 막대가 기본으로 비용순인지, 직군 아이콘 문서(검색 한도로 못 봄).
- TFT: 등급 색 대응(팬 사이트뿐), 클릭 구매(발췌에는 끌기만), 잠금 단축키. Dota Underlords 등급 색.
- StarCraft II의 Shift ×5. 일반 관례로서의 «Ctrl-클릭 ×10»(RimWorld의 Ctrl ×10만 확인).
- «마지막 탭을 기억하라»는 직접 지침.
- Hodent 책 본문(본인 블로그·발표 자료로 대신함).
- 데스크톱 마우스 게임용 수치 크기 기준(XAG는 모바일 터치 수치만 있음).
