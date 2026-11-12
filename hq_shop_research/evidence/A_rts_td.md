# A. RTS·TD 유닛 구매(생산) 메뉴 — 탭·범주와 유닛별 업그레이드 조사

작성 2026-11-12. 웹 조사만 했다(코드 저장소는 건드리지 않음).

## 조사 방법과 한계

- 이 세션의 네트워크는 제한 모드(허용 호스트 없음)라 WebFetch로 페이지 본문을 열 수 없었다. www.gamespot.com, ea.com이 DNS 단계에서 막혔다. 그래서 근거는 모두 WebSearch 결과에 나온 발췌와 요약이다. 페이지 전체를 읽으려면 세션 네트워크 설정에서 해당 호스트를 허용해야 한다.
- 조사 끝 무렵 WebSearch 호출 상한(턴당 200회, 에이전트끼리 공유)에 걸려 몇 항목은 더 확인하지 못했다(아래 «확인 못 한 것»).
- 신뢰도 기준(이 문서에서):
  - `verified`: 1차·권위 출처(공식 개발 일지·패치 노트·공식 지원 문서·개발사 공지·매뉴얼·오픈소스 이슈 트래커, 또는 관리가 잘 된 위키 warcraft.wiki.gg·bloonswiki·tabs.wiki.gg·Liquipedia)의 해당 문장을 검색 결과 발췌에서 직접 봤다. 페이지 전체는 못 읽었다.
  - `likely`: 2차 출처(가이드·리뷰·포럼·팬 위키), 1차 출처라도 검색 요약이 의역이라 문장을 특정하지 못한 것, 또는 독립 출처 둘이 일치하는 것.
  - `unverified`: 포럼 글 하나뿐이거나 사전 지식에 기댄 것.
- «(2차·여론)» 표시는 포럼·리뷰에서 온 불만이나 칭찬이다.

## 확인 못 한 것

- SC2에서 Shift+훈련으로 5개를 넣는 동작: 출처를 못 찾았다.
- WC3 대기열 7칸, 업그레이드 등급(예: 1/3)을 아이콘·툴팁에 어떻게 보이는지.
- BTD6 일반 모드의 «돈 부족» 표시(가격 빨강/회색), 타워 패널의 화면 위치와 스크롤.
- TABS 예산 막대의 위치, Clear 버튼 모양, 전투 배치 Undo.
- DINO·Age of Darkness의 건설·훈련 메뉴 범주 구성.
- Iron Marines의 생산 버튼 UI 자체.
- 마지막으로 쓴 탭을 기억하는지: 어느 게임에서도 출처를 못 찾았다.
- AoE IV 생산 건물 그리드에서 유닛 행과 기술 행의 정확한 배치.

## 주장 목록

### 1. Command & Conquer 3 / Red Alert 3 / C&C Remastered

1. **A-01** · C&C3 Tiberium Wars — 화면 오른쪽 사이드바는 전통 C&C side bar와 Generals식 command bar를 합친 것이다. 생산 탭은 5범주: Production Structures, Defensive Structures, Infantry, Vehicles, Aircraft. 설계 목표는 «전장 어디서든» 탭으로 생산 대기열을 다루는 것.
   - 출처: https://www.gamespot.com/articles/command-and-conquer-3-tiberium-wars-designer-diary-3-introducing-the-new-interface/1100-6159834/ (EA Designer Diary #3) · https://worthplaying.com/article/2006/10/17/news/37076-command-conquer-tiberium-wars-user-interface-details-screens/ · https://gamesradar.com/c-c-3-tiberium-wars-producer-speaks/3
   - 신뢰도: verified

2. **A-02** · C&C3 — 범주 탭 아래에 생산 건물마다 Sub-tab이 하나씩 생긴다(Barracks가 2채면 sub-tab 2개). sub-tab마다 그 건물의 대기열을 따로 다룬다. sub-tab을 더블클릭하면 카메라가 그 건물로 간다. 프로듀서: «사이드바와 sub-tab만 보고 전장에서 무엇이든 지을 수 있게».
   - 출처: https://www.gamespot.com/articles/command-and-conquer-3-tiberium-wars-designer-diary-3-introducing-the-new-interface/1100-6159834/ · https://gamesradar.com/c-c-3-tiberium-wars-producer-speaks/3
   - 신뢰도: verified

3. **A-03** · C&C3 — 업그레이드는 생산 탭에 섞지 않았다. UI 요소 목록의 «Purchase Upgrades» 버튼이 «선택한 유닛이나 건물의» 업그레이드를 산다(선택 기반). «Contextual tab»은 선택된 유닛·건물을 모두 나열한다. 업그레이드마다 연구 건물이 정해져 있다(예: Kane's Wrath GDI Scanner Packs $500, Researched at Command Post).
   - 출처: https://www.gamespot.com/articles/command-and-conquer-3-tiberium-wars-designer-diary-3-introducing-the-new-interface/1100-6159834/ · https://gamesradar.com/c-c-3-tiberium-wars-producer-speaks/3 · https://cncnz.com/games/kanes-wrath/gdi-structures/
   - 신뢰도: likely («별도 업그레이드 탭이 없다»는 UI 요소 목록에서 추론한 것)

4. **A-04** · C&C3 / Kane's Wrath — 기본 단축키: `~` Contextual tab, E 구조물, R 방어(Support), T 보병, Y 차량, U 항공, Tab = 다음 sub-tab. Kane's Wrath 매뉴얼은 Structure·Support structure·Infantry·Vehicle·Aircraft 탭과 Next/Previous subtab(TAB / CONTROL+TAB)을 적고, Settings의 Hot Keys 탭에서 바꿀 수 있다고 한다. 다른 가이드는 Z·X·Shift+E 같은 배치를 적어서 판본이나 설정에 따라 다를 수 있다.
   - 출처: https://www.supercheats.com/pc/walkthroughs/commandandconquer3tiberiumwars-walkthrough01.txt · https://manualmachine.com/electronicarts/kaneswrath/7073164-user-manual · https://gameplay.tips/guides/command-conquer-3-tiberium-wars-beginners-tips-with-keybinds-customization-advice.html
   - 신뢰도: likely

5. **A-05** · C&C Remastered (+C&C3) — 사이드바 아이콘을 좌클릭하면 생산·훈련. 우클릭 1회 = 보류(진행도 유지), 다시 좌클릭 = 재개, 우클릭 1회 더 = 취소하고 환불. Shift를 누른 채 클릭하면 대기열에 5개를 더하거나 뺀다. 구조물은 한 번에 하나만 짓고, 다 되면 아이콘을 다시 눌러 맵에 놓는다. C&C3도 빌드 버튼에서 대기열·일시정지·취소를 한다(2006 프리뷰).
   - 출처: https://help.ea.com/en/articles/command-and-conquer/command-and-conquer-remastered/how-to-play/ · https://strategywiki.org/wiki/Command_%26_Conquer/Controls (Remastered 기본 바인딩) · https://gamesradar.com/c-c-3-tiberium-wars-producer-speaks/3
   - 신뢰도: verified

6. **A-06** · C&C Remastered — 사이드바 개편에서 «가장 많이 요청된 개선 중 하나»가 스크롤을 줄이는 것이었다. 그래서 사이드바에 빌드 버튼 18개가 한꺼번에 들어가게 설계했다.
   - 출처: https://ea.com/games/command-and-conquer/command-and-conquer-remastered/news/remaster-update-sidebar-preview (EA 원문, 직접 열람 불가) · https://cncnz.com/cc-remastered-update-sidebar-and-full-production/ (원문 인용)
   - 신뢰도: verified

7. **A-07** · C&C Remastered — 사이드바 위쪽에 탭 4개: Buildings / Infantry / Vehicles(지상·항공·해상) / Support Powers. 원작의 «구조물은 한 번에 하나» 건설 규칙 때문에 건물은 한 탭에 모았다. 같은 개편을 Red Alert 사이드바에도 적용했다. (2차·여론) 커뮤니티 반응은 갈렸다. Support Powers를 따로 뺀 데 반대하는 글, RA2식 Buildings/Defenses/Infantry/Vehicles를 원하는 글이 있었다.
   - 출처: https://www.neowin.net/news/command--conquer-remastered-now-in-full-production-ui-updates-shared/ · https://cncnz.com/cc-remastered-update-sidebar-and-full-production/ · https://forums.cncnet.org/topic/9912-remaster-update-first-look-at-the-sidebar/
   - 신뢰도: likely

8. **A-08** · C&C Remastered — 기본 탭 단축키: W 구조물, E 보병, R 차량, T Superweapons(Support Powers). 게임 안에서 단축키를 바꿀 수 있고 새 사이드바도 지원한다.
   - 출처: https://strategywiki.org/wiki/Command_%26_Conquer/Controls · https://defkey.com/cc-remastered-collection-shortcuts
   - 신뢰도: likely

9. **A-09** · Red Alert 3 — 오른쪽 사이드바에서 기지 건설과 유닛 생산을 모두 한다. 튜토리얼 «Establishing a Base»의 지시: «Conyard를 선택하거나 깜빡이는 Production Tab을 클릭하라». 탭을 깜빡여 다음 할 일을 알리고, 생산 건물을 선택해도 그 탭이 열린다. 세 진영 모두 같은 방식으로 사이드바 탭에서 생산한다.
   - 출처: https://cnc.fandom.com/wiki/Transcript:Establishing_a_Base
   - 신뢰도: likely (공식 튜토리얼을 팬 위키가 옮긴 것)

10. **A-10** · Red Alert 3 — 탭 단축키 Vehicle Y, Aircraft U, Navy I. Tab = 유닛 서브그룹 순환. C&C3의 E/R/T/Y/U 배치에 Navy(I)를 더한 6탭 구조로 보인다(구조물·방어·보병 키는 확인 못 함).
    - 출처: https://strategywiki.org/wiki/Command_%26_Conquer:_Red_Alert_3/Controls
    - 신뢰도: likely

11. **A-11** · Red Alert 3 — 업그레이드 성격의 Top Secret Protocols(TSP)는 생산 탭과 떨어진 별도 패널이다. 인터페이스 가운데의 TSP 버튼으로 연다(콘솔판은 링 메뉴 6시 방향). 전투 중 Security Point를 벌고, 프로토콜 하나에 1점이다(돈이 아님. C&C3 업그레이드와 다른 점). 버튼 둘레의 게이지가 다음 점수까지의 진행도, 버튼 위 숫자가 지금 가진 점수다. 1.11 패치에서 세 진영의 프로토콜 순서를 다시 배열했다.
    - 출처: https://cnc.fandom.com/wiki/Transcript:Support_Powers · https://StrategyWiki.org/wiki/Command_%26_Conquer:_Red_Alert_3/Empire_of_the_Rising_Sun_Top_Secret_Protocols · https://www.trueachievements.com/game/Command-and-Conquer-Red-Alert-3/walkthrough/3 · https://cncnz.com/features/technical-support-help-guides/red-alert-3-v101-v112-patch-history/
    - 신뢰도: likely

### 2. Age of Empires II DE / Age of Empires IV

12. **A-12** · AoE II DE — Shift+클릭하면 유닛 5개를 한 번에 대기열에 넣는다. 같은 종류 건물 여러 채를 선택하고 Shift+클릭하면 5개가 건물들에 나뉜다.
    - 출처: https://ageofempires.com/learn-to-play/control-resources-aoe2 · https://forums.ageofempires.com/t/need-step-by-step-procedure-for-shift-queueing-in-aoe2-de/103235
    - 신뢰도: likely (공식 페이지 발췌가 검색마다 달랐다)

13. **A-13** · AoE II DE — 대기열 아이콘을 Shift+클릭하면 5개씩 뺀다(Shift+유닛 클릭 = 5개 추가와 짝). (2차·여론) 이 동작이 진행 중인 유닛까지 취소하는 버그 보고가 있고, «5개 대신 그 종류를 전부 빼자»는 제안도 있다.
    - 출처: https://forums.ageofempires.com/t/shift-cancelling-queue-can-cancel-the-task-in-progress/211529 · https://forums.ageofempires.com/t/remove-five-units-at-once-from-queue-using-shift-click/72278
    - 신뢰도: likely

14. **A-14** · AoE II DE / AoM Retold — 건물 하나의 대기열 상한은 15다. AoE2 DE: Castle에 Tarkan 15개가 차면 Stable+Castle을 같이 선택한 대기열이 Stable로 더 들어가지 않는 버그(개발팀 인지). AoM Retold로 보이는 보고(Fortress·Myrmidon): «건물 훈련 상한 15»에 닿으면 유닛 버튼이 회색이 되는데 14개에서 회색이 되는 버그.
    - 출처: https://forums.ageofempires.com/t/rts-tournaments/73281 · https://forums.ageofempires.com/t/queuing-tarkans-together-from-stable-castle-stops-adding-tarkans-to-stables-if-castle-is-at-15-tarkans-queued/228556 · https://forums.ageofempires.com/t/fortress-greyed-out-units-when-only-14-queued/274757
    - 신뢰도: likely

15. **A-15** · AoE II — 생산 건물 패널에 유닛과 기술이 함께 있다. 예: Barracks에 Militia 계열 유닛과 Arson(Feudal), Squires(Castle), Gambesons(Castle). 건물 대기열은 유닛과 기술이 같이 쓴다. Barracks 2채를 선택하면 한 채가 기술을 연구하고 다른 채가 유닛 5개를 받으며, 기술은 여러 채로 나뉘지 않는다. 자동 무료 연구로 바뀐 Tracking은 Barracks 패널에서 아예 빠졌다(공식 밸런스 변경).
    - 출처: https://ageofempires.fandom.com/wiki/Infantry_unit_(Age_of_Empires_II) · https://forums.ageofempires.com/t/undesired-multi-queue-behavior/61884 · https://forums.ageofempires.com/t/bug-technologies-are-not-multi-queue-supported/65117 · https://www.forgottenempires.net/age-of-empires-ii-definitive-edition/balance-changelog
    - 신뢰도: likely

16. **A-16** · AoE 시리즈 — 대기열에 든 개수를 유닛 버튼 위에 숫자로 보이고, 값은 대기열에 넣는 순간 빠진다(Rise of Rome 매뉴얼). (2차·여론) AoE2 DE 콘솔판에서 «대기 수와 진행도가 아이콘 위에 안 보인다»는 버그 보고에 «사실상 플레이 불가»라는 반응이 붙었다. 아이콘 위의 개수·진행도가 핵심 정보라는 방증.
    - 출처: https://marine.manualsonline.com/manuals/mfg/microsoft_xbox/the_rise_of_rome_expansion.html?p=5 · https://forums.ageofempires.com/t/on-ps5-queuing-units-no-longer-displays-the-total-number-of-units-queued-over-the-icon-of-the-unit-queued-it-also-does-not-display-the-progress-over-the-icon-either/278093 · https://forums.ageofempires.com/t/villagers-any-build-queued-now-showing-quantity/250636
    - 신뢰도: likely

17. **A-17** · AoE II DE — 화면 왼쪽 위 Global queue가 훈련·연구 중인 것을 모아 보인다(«건물을 하나하나 누르지 않아도 된다»). (2차·여론) «DE가 더한 최고의 QoL 기능 중 하나»라는 평. 불만: 같은 종류가 섞이면 일부 유닛을 숨긴다, «대기 중인 유닛·기술을 전부 보여 달라», «Global queue 항목에 X를 달아 바로 취소하게 해 달라».
    - 출처: https://www.pcworld.com/article/3402536/age-of-empires-ii-definitive-edition-preview.html · https://forums.ageofempires.com/t/global-queue-hides-many-units/284548 · https://forums.ageofempires.com/t/global-production-queue-items-x-visual-for-canceling-qol-improvement/289877
    - 신뢰도: likely

18. **A-18** · AoE II DE — 돈이 모자라면 버튼에 빨간 glow가 붙는다. 공식 업데이트 미리보기: «Stone Gate 버튼이 살 수 없을 때 빨간 glow가 없던 문제 수정». 인구 상한 때문에 뽑지 못하는 유닛의 global queue 아이콘에도 빨간 glow(2023-07 패치 노트, 비공식 사이트 전재). (2차·여론) 최근 패치 뒤 빨강 = 돈 부족, 노랑 = 건설 상한으로 예전과 뜻이 뒤바뀌었다. «음식 몇 개 모자란 마을 사람에 빨강을 띄우면 '불가'처럼 보인다. 돈 부족은 '느림'일 뿐»이라는 불만. 유닛 아이콘은 빨개지는데 그 유닛을 뽑는 건물 아이콘은 안 빨개진다는 보고도 있다.
    - 출처: https://ageofempires.com/news/a-sneak-peek-at-new-content-coming-to-age-of-empires-ii-definitive-edition · https://devtrackers.gg/aoe/p/bd384905-a-sneak-peek-at-new-content-coming-to-age-of-empires-ii-definitive-edition · https://forums.ageofempires.com/t/building-menu-ui-changes-red-yellow-highlights/275418 · https://forums.ageofempires.com/t/building-icon-limited-restricted-no-logner-red-out-to-show-its-limited-still-shows-available/250540
    - 신뢰도: likely

19. **A-19** · AoE II DE — Grid 단축키(DE 옵션): 마을 사람을 고른 뒤 Q = 경제 건설 메뉴, W = 군사 건설 메뉴, 다음 키로 건물. Town Center에서 Q = 마을 사람. 왼손 블록 qwer/asdf/zxcv. (2차·여론) «건물 선택 키만 규칙이 달라 패턴이 깨진다», grid인데 아래 줄에 옛 키가 표시되는 버그, 경제·군사 grid가 뒤바뀌는 버그.
    - 출처: https://diamondlobby.com/age-of-empires-2/hotkey-guide-aoe2/ (검색 결과의 DE 단축키 튜토리얼로 추정) · https://forums.ageofempires.com/t/deciding-on-hotkeys/62861 · https://forums.ageofempires.com/t/grid-hotkeys-feel-alien-coming-from-other-franchises-criticism-and-a-brief-history-of-grid-in-other-games/184268 · https://forums.ageofempires.com/t/incorrect-hotkeys-showing-in-bottom-row-with-grid-hotkeys/198431
    - 신뢰도: likely

20. **A-20** · AoE IV — Shift+생산 단축키(또는 Shift+클릭) = 같은 유닛 5개. 공식 패치 노트: Fully Remappable 배치에서 Shift+생산 명령의 묶음 대기열을 고쳤고, Shift가 Grid Keys를 방해하는 문제는 다음 패치에서 고친다고 했다. (2차) 건물은 여전히 한 번에 하나씩 만든다.
    - 출처: https://www.pcgamesn.com/age-of-empires-4/hotkeys-keyboard-shortcuts · https://ageofempires.com/news/age-of-empires-iv-patch-20249 (해당 문장이 이 패치인지 특정 못 함) · https://forums.ageofempires.com/t/batch-training-not-in-the-game/181929
    - 신뢰도: likely

21. **A-21** · AoE IV — Season One(2022-04, «Festival of Ages»)에 Global Build Queue를 넣었다: «대기 중인 모든 유닛과 업그레이드를 늘 한눈에». 같은 업데이트에 특정 종류 건물 전부를 순환·선택하는 키, 카메라 위치 저장, 생산 대기열 항목 취소 같은 전역 단축키.
    - 출처: https://www.ageofempires.com/news/age-of-empires-iv-season-one-update-release-notes/ · https://player.one/age-empires-iv-season-one-update-features-global-build-queue-and-improved-146736 · https://www.neowin.net/news/age-of-empires-iv-season-one-is-live-with-mod-tools-ranked-play-and-much-more/
    - 신뢰도: likely

22. **A-22** · AoE IV — Barracks는 «근접 보병 생산 겸 업그레이드 건물»이다. 유닛 등급 Spearman → Hardened → Veteran → Elite를 생산 건물에서 올린다. (2차·여론) «업그레이드 등급이 올라도 아이콘은 그대로고 이름 앞에 'Elite'·'Hardened'만 붙는다», «대장간 메뉴를 0.3초 열었다 닫으면 업그레이드가 몇 등급인지 못 알아본다». 유닛 카드에 업그레이드마다 pip 하나씩 달자는 제안.
    - 출처: https://ageofempires.fandom.com/wiki/Barracks_(Age_of_Empires_IV) · https://ageofempires.fandom.com/wiki/Ayyubids/Tree · https://forums.ageofempires.com/t/ui-icons-traffic-signs/134362?page=7 · https://forums.ageofempires.com/t/it-feels-really-boring-and-unimpressive-when-upgrading-military/173222 · https://forums.ageofempires.com/t/are-icons-way-too-indistinctive/173394?page=2
    - 신뢰도: likely

23. **A-23** · AoE IV — 단축키 프로필은 Grid Keys와 Fully Remappable 둘로 완전히 나뉜다. Fully Remappable로 처음 바꾸면 기본값은 Grid Keys와 같고, 이후 아무 키나 다시 지정할 수 있지만 동시에 켜질 수 있는 키끼리의 충돌은 검사하지 않는다. (2차·여론) alt·shift·마우스 버튼은 못 바꾼다, Fully Remappable이 grid보다 더 헷갈린다는 불만.
    - 출처: https://support.ageofempires.com/hc/en-us/articles/7473968190356-Fully-Remappable-Keys · https://aoe4world.com/explorer/patches/patch-5.0.17718.0-season-two · https://forums.ageofempires.com/t/remappable-hotkeys-are-not-remappable-and-massive-disappointment/208496?page=2
    - 신뢰도: verified (프로필 사실). (2차·여론) 부분은 likely

### 3. StarCraft II

24. **A-24** · SC2 — Command card는 5×3 grid(15칸)다. Grid 단축키 배치는 아래 줄로 손을 뻗는 일을 줄이려고 쓴다.
    - 출처: https://tl.net/forum/sc2-strategy/404476-fleet-keys-refined-hotkey-systems · https://tl.net/blogs/410021-errors-in-the-starcraft-2-hotkey-system
    - 신뢰도: likely

25. **A-25** · SC2 — 생산 대기열은 5칸. Reactor를 달면 두 개를 동시에 만들고 대기열이 8칸으로 는다(Reactor 효과는 Tech Lab이 필요 없는 유닛에만). 5개 넘게 든 채 Reactor가 부서지면 대기열이 5로 줄고 6~8번째 값은 돌려준다.
    - 출처: https://liquipedia.net/starcraft2/Tech_Reactor (캠페인 전용 Tech Reactor 페이지: 대기열 8, 파괴 시 5로 축소) + 멀티플레이 Reactor를 설명한 2차 사이트
    - 신뢰도: likely

26. **A-26** · SC2 (Terran) — 연구 버튼은 생산 건물 카드가 아니라 부속 건물 Tech Lab의 카드에 따로 있다. 예: Barracks Tech Lab 연구 Combat Shield(C), Stimpack(T), Concussive Shells(G). Factory·Starport Tech Lab의 연구는 또 따로. 유닛 생산은 Barracks 카드에서.
    - 출처: 검색 결과의 커뮤니티 Terran 단축키표(https://gist.github.com/1232554 로 추정) · https://tl.net/forum/starcraft-2/254779-creating-your-own-custom-hotkey-setup
    - 신뢰도: likely

27. **A-27** · SC2 — Tab = 선택 안의 서브그룹(유닛·건물 종류) 순환, Shift+Tab = 반대 방향. 공식 가이드는 생산 건물(Barracks·Factory·Starport)을 한 부대 번호에 묶고 Tab으로 오가며 생산하라고 권한다.
    - 출처: https://news.blizzard.com/en-us/article/6640645/game-guide-simplified-controls · https://news.blizzard.com/en-us/article/4552955/game-guide-special-control
    - 신뢰도: verified

28. **A-28** · SC2 — 생산 단축키를 누르고 있으면 OS 키 반복으로 계속 대기·변태한다. «Z를 누르고 있으면 보급이 막히거나 돈이 떨어질 때까지 애벌레가 전부 저글링이 된다. 돈이 모자라면 살 수 있는 만큼만.» 첫 개는 바로, 나머지는 키 반복 속도로 나온다. 능력용 «rapid fire»는 «Choose ability or A.I. Target» 단축키에 같은 키를 대체 키로 넣어 만든다. (2차·여론) 당황해서 키를 누르고 있다가 과잉 생산하는 실수를 경고.
    - 출처: https://tl.net/forum/starcraft-2/246707-holding-down-hotkeys?view=all · https://tl.net/forum/sc2-strategy/446530-rapid-fire-hotkey-trick · https://us.forums.blizzard.com/en/sc2/t/rapid-fire-question/18856
    - 신뢰도: likely

29. **A-29** · SC2 — 유닛 정보창의 무기·방어 아이콘 구석에 현재 업그레이드 등급 숫자(1/2/3)가 붙고, 마우스를 올리면 오른 능력치가 노란색으로 보인다(포럼 묘사). Blizzard는 Protoss 지상 무기 업그레이드 세 등급의 아이콘을 등급 구별이 쉽도록 바꾼 적이 있고, 아이콘이 등급을 따라 바뀌지 않던 버그를 여러 번 고쳤다.
    - 출처: https://www.sc2mapster.com/forums/development/data/162107-show-upgrade-level-in-unit-ui?comment=1 · https://games.softpedia.com/progChangelog/StarCraft-II-Patch-Changelog-72770.html (패치 노트 미러)
    - 신뢰도: likely

30. **A-30** · SC2 — 보급이 모자란 채 생산하려 하면 종족 조언자가 음성으로 이유를 말한다(Protoss: «You must construct additional pylons»).
    - 출처: https://tvtropes.org/pmwiki/pmwiki.php/Main/ConstructAdditionalPylons · https://starcraft.fandom.com/wiki/File:Pylon_SC2_DevRend4.png (StarCraft Wiki 설명문)
    - 신뢰도: likely

### 4. Warcraft III

31. **A-31** · WC3 — Human Barracks 카드에 유닛(Footman, Rifleman, Knight)과 그 유닛 전용 업그레이드(Defend, Long Rifles, Animal War Training)가 함께 있다. Knight는 본진이 Castle이어야 뽑을 수 있다.
    - 출처: https://warcraft.wiki.gg/wiki/Barracks_(WC3_Human) · https://strategywiki.org/wiki/Warcraft_III:_Reign_of_Chaos/Human_buildings
    - 신뢰도: verified

32. **A-32** · WC3 — Patch 1.10(2003): «업그레이드와 유닛을 같은 대기열 사슬에 넣을 수 있다», «건물도 대기열에 넣을 수 있다»(지을 자리에 자리표시 그림을 띄움). 연구와 훈련이 건물 하나의 대기열을 같이 쓴다.
    - 출처: https://warcraft.wiki.gg/wiki/Warcraft_III/Patch_1.10 · https://www.neowin.net/news/warcraft-iii-patch-v110-released/ (Blizzard 변경 목록 전재)
    - 신뢰도: verified

33. **A-33** · WC3 — Blacksmith의 3단 업그레이드는 등급마다 이름·요구 본진·연구 시간이 다른 별개 항목이다: Iron Forged Swords(추가 요구 없음, 60초) → Steel Forged Swords(Keep, 75초) → Mithril Forged Swords(Castle, 90초). 높은 등급은 본진 단계로 잠긴다. (게임 안에서 같은 칸 버튼이 다음 등급으로 바뀌는지는 확인 못 함)
    - 출처: https://warcraft.wiki.gg/wiki/Blacksmith_(Warcraft_III)
    - 신뢰도: verified

34. **A-34** · WC3 — 대기열 7칸(생산 중 1 + 대기 6)과 업그레이드 등급(예: 1/3) 표시 방식은 출처로 확인하지 못했다. Hive 포럼에 «첫 6개가 끝나기 전에 7개 이상 넣으면…» 정도의 언급만 있다.
    - 출처: https://www.hiveworkshop.com/threads/cancelling-units.245391
    - 신뢰도: unverified

### 5. Bloons TD 6

35. **A-35** · BTD6 — 일반 타워는 Primary / Military / Magic / Support 4범주다. Hero는 따로이고 한 판에 하나만. 범주는 평소엔 정리용이지만, 일부 모드는 Support를 뺀 세 범주 중 하나만 쓰게 제한한다. Primary: Dart, Boomerang, Bomb, Tack, Ice, Glue, Desperado. Military: Sniper, Sub, Ace, Buccaneer 등. Magic: Wizard, Super, Ninja, Alchemist, Druid 등. Support: Banana Farm, Spike Factory, Village, Engineer.
    - 출처: https://www.bloonswiki.com/Tower_category · https://www.giantbomb.com/games/3030-68981/
    - 신뢰도: verified

36. **A-36** · BTD6 — 범주는 타워 초상의 배경색으로 구별한다(«아이콘 색으로 표시»). 위키 메모로 확인되는 것: Primary = 파랑(Agents가 Primary와 같은 파랑), Support = 주황(Items가 Support와 같은 주황). Military = 초록, Magic = 보라는 약한 출처 하나에서만.
    - 출처: https://www.bloonswiki.com/Tower_category · https://www.giantbomb.com/games/3030-68981/
    - 신뢰도: likely

37. **A-37** · BTD6 (PC) — 기본 단축키가 범주마다 키보드 한 줄이다: Q–Y Primary, Z–N Military, A–G Magic, H–K Support, U Hero. Shift를 누른 채 놓으면 같은 타워를 이어서 또 놓는다. v44.0부터 새 타워에는 기본 키를 주지 않고 단축키 메뉴에 빈 칸만 둔다. 대부분의 키를 다시 지정할 수 있다.
    - 출처: https://steamcommunity.com/app/960090/discussions/0/1638661595056416109 (2019 단축키 Q&A) · https://www.bloonswiki.com/Hotkeys · https://www.bloonswiki.com/Update_history:Bloons_TD_6/Version_44.0 · https://steamdb.info/patchnotes/15192119 · https://www.magicgameworld.com/?p=27335
    - 신뢰도: likely

38. **A-38** · BTD6 (PC) — 타워를 선택한 상태에서 `,` `.` `/`(또는 숫자 1 2 3) = 업그레이드 경로 1/2/3, Backspace = 판매, Tab = 타겟 우선순위 바꾸기.
    - 출처: https://www.bloonswiki.com/Hotkeys · https://steamcommunity.com/app/960090/discussions/0/1638661595056416109 · https://www.magicgameworld.com/?p=27335
    - 신뢰도: likely

39. **A-39** · BTD6 — 업그레이드는 3경로 × 5단. 한 경로만 5단까지, 다른 한 경로는 2단까지(예: 5-2-0). 두 경로를 고르면 셋째 경로는 바로 잠긴다(«closed», 게임 코드 함수 이름 IsUpgradePathClosed). 경로 안에서는 앞 단을 사야 다음 단을 산다. 5단 위에 매우 비싼 Paragon이 있다.
    - 출처: https://www.bloonswiki.com/Upgrades · https://bloons.fandom.com/wiki/Crosspathing/Engineer_Monkey · https://www.github.com/doombubbles/ultimate-crosspathing/issues/111
    - 신뢰도: verified (규칙). «closed» UI 표기는 likely

40. **A-40** · BTD6 — 판 밖에서 타워별 Monkey XP로 업그레이드를 연다(순서는 자유, 경로 아래로 갈수록 XP가 비쌈). 판 안에서는 아직 안 연 업그레이드가 잠긴 상태로 보인다. 검색 요약에 «타워가 잠긴 업그레이드를 제대로 표시하지 않던 UI 문제»를 v25.0에서 고쳤다는 언급이 있었다(URL은 확보 못 함).
    - 출처: https://www.bloonswiki.com/List_of_upgrades_in_BTD6 (XP to unlock 열) · https://www.bloonswiki.com/Tower_XP · https://bloons.fandom.com/wiki/Monkey_Knowledge_(BTD6)
    - 신뢰도: likely

### 6. Totally Accurate Battle Simulator (TABS)

41. **A-41** · TABS — 유닛 목록의 축은 진영(faction)이다. 진영마다 기본 유닛 7개(리뷰: 처음엔 12진영 × 7유닛, Steam판은 100개 넘음). Workshop 커스텀 진영은 툴바에 탭으로 들어가고, 다른 진영들 사이 아무 데로나 끌어 옮길 수 있다. (2차) 캠페인에서 진영 바의 «+»(진영 추가) 버튼이 안 보이는 버그.
    - 출처: https://tabs.wiki.gg/wiki/Workshop · https://tabs.wiki.gg/wiki/Faction · https://tabs.wiki.gg/wiki/Stone_Age_(Faction) · https://bit-tech.net/reviews/totally-accurate-battle-simulator-review/1 · https://steamcommunity.com/app/508440/discussions/0/3149682775484102584
    - 신뢰도: likely

42. **A-42** · TABS — 레벨마다 정해진 예산 안에서 유닛을 산다. 유닛마다 가격이 있다(예: Tribal Clubber 70, Protector 80). The Challenge 캠페인은 예산을 낮춰 고르는 고민을 키운다. 처음으로 가격 10000을 넘긴 캠페인도 있다. Battle/Campaign Creator에서 플레이어 예산과 쓸 수 있는 유닛을 제한할 수 있다.
    - 출처: https://tabs.wiki.gg/wiki/Stone_Age_(Faction) · https://tabs.wiki.gg/wiki/The_Challenge · https://tabs.wiki.gg/wiki/Levels · https://tabs.wiki.gg/wiki/Workshop
    - 신뢰도: verified (예산·가격 규칙). 화면의 예산 막대 위치는 확인 못 함

43. **A-43** · TABS (PC) — 좌클릭 = 배치, 우클릭을 누르고 있으면 유닛 제거. «Clear Units» 동작은 있으나 기본 키가 없다. Undo(Z)/Redo(Y)는 공식 FAQ상 Map Creator에만 있고, 전투 배치 Undo는 찾지 못했다.
    - 출처: https://www.magicgameworld.com/?p=126074 · https://gameplay.tips/guides/8990-totally-accurate-battle-simulator.html · https://landfall.se/map-creator-faq
    - 신뢰도: likely

### 7. Diplomacy is Not an Option / Age of Darkness: Final Stand

44. **A-44** · Diplomacy is Not an Option — 화면의 패널 하나가 지금 선택한 것의 선택지를 보이고, 건설 메뉴도 그 패널에 뜬다(유닛을 선택하면 명령). 단축키: C = Build Menu, Ctrl = 선택한 건물 계속 짓기(modifier), X = 자동 수리 켜고 끄기. 빈 인구가 없으면 일꾼이 필요한 건물도, 군사 유닛 훈련도 못 한다(집을 미리 지어 두라는 조언). 시작 병력 Swordsman 3, Archer 3.
    - 출처: https://techraptor.net/gaming/guides/diplomacy-is-not-option-guide-for-beginners · https://magicgameworld.com/?p=106384 · https://kosgames.com/?p=17236 · https://gameplay.tips/guides/diplomacy-is-not-an-option-how-to-start-guide-build-order-combat-units-tech-and-spells.html
    - 신뢰도: likely (메뉴 범주 구성은 확인 못 함)

45. **A-45** · Age of Darkness: Final Stand — Training Hall은 한 번에 병사 하나만 훈련한다. 가이드는 거점마다 Hall을 여러 채 두라고 권한다. 패치: Training Hall이 «지금 훈련 중인 유닛의 아이콘»을 보이게 했고, «연구 전에 유닛을 훈련할 수 있던 문제»를 고쳤다(연구로 유닛을 해금). 유닛은 전투로 레벨이 오른다. 단축키: Enter = Keep 선택, T = 스킬 트리, G = 전체 수리.
    - 출처: https://steamdb.info/patchnotes/11962268 · https://steamdb.info/patchnotes/12166681 (SteamDB 패치 노트 미러, 어느 버전 문장인지 특정 못 함) · https://kosgames.com/age-of-darkness-final-stand-beginners-guide-15197/ · https://www.gameskinny.com/tips/age-of-darkness-final-stand-tips-and-tricks-guide/ · https://www.gamenguides.com/age-of-darkness-final-stand-pc-keyboard-controls
    - 신뢰도: likely

### 8. Kingdom Rush 시리즈

46. **A-46** · Kingdom Rush / Frontiers / Origins / Vengeance — 전투 중 타워 승급은 금화로 한다. Barracks는 Militia → Footmen → Knights 3단 뒤 4단에서 전문 타워 둘 중 하나를 고른다(Vengeance는 이 갈림을 없앰). 최종 단 타워의 능력은 단계마다 금화(예: 할인이 붙으면 250금화 단계가 187). 판 밖 업그레이드 트리는 KR1~3은 별(star), Vengeance·Alliance는 Upgrade Point(캠페인에서만, 대개 스테이지당 3점, 트리마다 5개). 웨이브가 시작된 뒤 팔면 타워·승급·능력에 쓴 금화의 60%를 돌려준다.
    - 출처: https://kingdomrushtd.fandom.com/wiki/Upgrades · https://wikily.gg/kingdom-rush/upgrades · https://wikily.gg/kingdom-rush/towers · https://tvtropes.org/pmwiki/pmwiki.php/Characters/KingdomRushTowers
    - 신뢰도: likely

47. **A-47** · Kingdom Rush — Barracks 병사는 플레이어가 정한 rally point(깃발)로 가서 길을 막는다. rally 거리에 한계가 있고(Militia 145 → 승급 후 174), 쓰러진 병사는 Barracks에서 다시 나온다(10초 → 8초). 판 밖 업그레이드 Improved Deployment(별 2개): rally 범위 +20%, 훈련 시간 단축.
    - 출처: https://wikily.gg/kingdom-rush/towers/militia-barracks · https://wikily.gg/kingdom-rush-6-genesis/classic-towers/militia-barracks (수치가 어느 작품 페이지인지 특정 못 함) · https://kingdomrushtd.fandom.com/wiki/Upgrades
    - 신뢰도: likely

48. **A-48** · Kingdom Rush — 초반 스테이지에서는 일부 타워 승급이 잠겨 있고, 스테이지 페이지마다 잠긴 목록이 있다. Classic 계열 모드는 스테이지마다 승급을 하나씩 늘린다(진행에 따라 메뉴가 넓어진다).
    - 출처: https://wikily.gg/kingdom-rush/game-modes
    - 신뢰도: likely

49. **A-49** · Kingdom Rush Vengeance — 스테이지 전에 타워 18종 가운데 5종을 loadout으로 고른다. (2차·여론) Steam 리뷰 요약: 타워 스킬 트리가 잘못 설계돼 쓰기 불편하다, 타워 선택 버그가 있다.
    - 출처: https://www.gameskinny.com/tips/kingdom-rush-vengeance-tower-overview-guide/ · https://vaporlens.app/app/1367550/kingdom_rush_vengeance_tower_defense
    - 신뢰도: likely

50. **A-50** · Kingdom Rush 6: Genesis (2026) — 데모에는 타워마다 경험치로 오르는 Level System이 있었다(뒤처진 타워는 경험치 2배 Catch-Up). Ironhide 공지 «To our community»: 데모 피드백을 받아 «개별 타워 레벨 시스템은 없어진다. 완전히.» 대신 «전통적인 전역(global) 업그레이드 시스템»을 넣고 «UI도 크게 고친다». 2026-07-28 보도자료도 «global upgrade system, redesigned UI»를 곧 알리겠다고 했다. 2026-09-24 출시.
    - 출처: https://www.ironhidegames.com/News/Details/487 · https://www.ironhidegames.com/News/Details/502 · https://www.gamedeveloper.com/press-release/ironhide-celebrates-15-years-of-kingdom-rush-with-the-introduction-of-classic-mode-in-kingdom-rush-6-genesis · https://www.gamedeveloper.com/press-release/ironhide-announces-kingdom-rush-6-genesis-td-steam-demo-mobile-pre-orders-new-trailer-and-september-24-launch-date
    - 신뢰도: verified

51. **A-51** · Kingdom Rush 6: Genesis — 타워 레벨은 전투 중 금화로 산다. IV레벨에서 스킬 3개를 각 3단계까지 금화로 올린다. Ultimate는 판 밖 Upgrades room에서 연다: 그 타워 트리의 마지막 업그레이드를 사면 그 종류 타워 전부에 켜진다. 예: Gold Prospectors 건설 120, IV까지 800, 스킬 전부 1500.
    - 출처: https://wikily.gg/kingdom-rush-6-genesis/towers/gold-prospectors · https://wikily.gg/zh-tw/kingdom-rush-6-genesis/towers/gold-prospectors · https://wikily.gg/kingdom-rush/towers/archer-tower
    - 신뢰도: likely (스킬 3×3과 Ultimate 부분은 번체 중문 페이지 하나에 기댐)

### 9. Iron Marines

52. **A-52** · Iron Marines (2017) — 기지를 점령하면 분대가 나오는 지점이 생기고 Etherium을 만든다. Etherium으로 분대와 포탑을 산다(기지에 따라 포탑을 여러 개). 분대 계열은 Army / Empyrean / Mechs. 보통 분대 3~4개를 굴리고, 분대는 전투 밖에서 인원이 다시 찬다. Dropgun도 유닛으로 쳐서 빈 Command Point·Etherium 광맥을 점령할 수 있다. 판 밖에서는 미션에서 번 credits·tech points로 유닛을 업그레이드한다(스테이지를 다시 해서 벌 수 있음).
    - 출처: https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/IronMarines · https://gameslikefinder.com/review/iron-marines/ · https://www.pocketgamer.com/iron-marines/iron-marines-tips-and-tricks-a-beginners-guide-to-successful-space-ops · https://148apps.com/iron-marines/iron-marines-guide-beginner-tips-and-tricks · https://wikipedia.com/wiki/Iron_Marines
    - 신뢰도: likely (생산 버튼 UI 자체는 확인 못 함)

53. **A-53** · Iron Marines Invasion (2023) — (2차·여론) 칭찬: «유닛 종류를 즉석에서 바꿀 수 있어 좋다». 불만: 특정 유닛을 집어 공격시키기 어렵고 «내 유닛들 사거리가 어디까지인지 거의 알 수 없었다», 부대를 그룹 단위로만 다뤄야 해 답답하다.
    - 출처: https://www.commonsensemedia.org/app-reviews/iron-marines-invasion · https://sportskeeda.com/esports/iron-marines-invasion-pc-review-an-enjoyable-port-already-satisfying-mobile-rts · https://attackofthefanboy.com/reviews/iron-marines-invasion-review/
    - 신뢰도: likely

### 10. 기타 (Thronefall, Northgard, Stronghold, 0 A.D., 설계 글)

54. **A-54** · Thronefall — Barracks에서 유닛 종류 4개 가운데 하나를 고른다. 레벨마다 4/8/12명(+4씩). 건설 4골드, 승급 8골드 → 16골드. Gladiator School perk로 강화. 유닛 종류는 메타 레벨로 열린다(Flails 6, Hunters 19, Berserks 25). 본진 승급은 2회, 7·20코인(2023 가이드).
    - 출처: https://throne-fall.github.io/game-content/buildings/barracks.html · https://throne-fall.github.io/game-content/units (팬 위키) · https://steamah.com/?p=115731
    - 신뢰도: likely

55. **A-55** · Northgard — 군사 유닛은 종류마다 전용 건물에서 마을 사람을 하나씩 전환해 만든다(Training Camp → Warrior, Axe Thrower Camp, Shield Bearer Camp, Archery Camp, Skirmisher Camp 등). 군사 캠프 하나마다 Warband 상한 +2, Warband가 커질수록 유닛 비용이 오른다. 집 하나 = 인구 +5.
    - 출처: https://northgard.fandom.com/wiki/Warrior · https://northgard.fandom.com/wiki/Training_Camp?oldid=3844 · https://strategywiki.org/wiki/Northgard/Buildings · https://www.gameskinny.com/tips/northgard-guide-tips-and-tricks-for-getting-started-with-your-first-settlement/
    - 신뢰도: likely

56. **A-56** · Stronghold DE / Crusader II — Barracks에서 모병하려면 빈 농민 + 금화 + Armoury에 쌓인 무기·갑옷이 필요하다(용병은 금화만). Crusader II Barracks도 attire·금화·농민이 필요하다. 못 뽑는 아이콘의 모양은 확인 못 함.
    - 출처: https://bloxodes.com/wiki/stronghold-definitive-edition/units · https://www.gamepressure.com/strongholdcrusader2/military/z26d80
    - 신뢰도: likely

57. **A-57** · 0 A.D. (오픈소스 RTS) — 자원이 모자라면 아이콘에 빨간 overlay를 덮고 툴팁에 모자란 자원량을 적는다(«Insufficient resources» 문구를 빨갛게). 선행 조건이 없으면 회색(비활성). 인구가 모자라면 «insufficient resources» 툴팁과 같은 꼴에 인구 아이콘을 넣은 툴팁을 띄운다(#1659). 기술도 같은 식으로 점점 붉어지고, 둘 중 하나만 고르는 기술 쌍은 빨간 X로 보인다(#1849). 자원 부족으로 버튼을 비활성하면 우클릭(대기열 빼기 등)까지 막히는 문제가 보고됐다(#5269). 생산 건물 선택 중 Shift+클릭은 기본 5개 묶음(HotKeys 위키).
    - 출처: https://wildfiregames.com/forum/topic/16001-show-icons-as-red-if-not-enough-resources/ · https://trac.wildfiregames.com/ticket/1659 · https://trac.wildfiregames.com/ticket/1849 · https://trac.wildfiregames.com/ticket/5269 · https://trac.wildfiregames.com/wiki/HotKeys?version=84
    - 신뢰도: verified (Shift ×5 부분만 likely)

58. **A-58** · 설계 글 (Brandon Casteel «Wayward Strategy», 2020, Game Developer·TeamLiquid 전재) — 연구·업그레이드는 RTS의 표준 관문 장치다. StarCraft·WarCraft는 연구가 유닛을 영구히 바꾸고, C&C는 건물을 놓는 것이 기술 트리를 넓힌다. 경쟁전 초반에는 업그레이드 하나가 생산 건물 하나나 유닛 몇 기 값이라 맞바꿈 결정이 된다.
    - 출처: https://waywardstrategy.com/2020/06/08/the-tapestry-of-rts-design-upgrades-and-research/ · https://www.gamedeveloper.com/design/some-thoughts-about-research-and-upgrades-in-rts-games · https://tl.net/blogs/560236-thoughts-on-research-and-upgrades-in-rts
    - 신뢰도: likely

## 반복되는 패턴

- **탭 축.** RTS는 «무엇을, 어디서 만드나»(생산 건물·역할)로 나눈다: C&C3 5탭(A-01), RA3 6탭(A-10), Remastered 4탭(A-07), Northgard는 유닛 종류마다 건물(A-55). TD·샌드박스는 역할이나 진영으로 나눈다: BTD6 4범주+배경색(A-35·A-36), TABS 진영 탭(A-41). 탭은 4~6개, 한 탭 안 버튼은 스크롤 없이 한 화면에 둔다(Remastered 18칸 A-06, SC2 15칸 A-24).
- **업그레이드 자리는 세 가지.** ① 유닛 버튼 옆, 같은 패널·같은 대기열(WC3 A-31·A-32, AoE A-15·A-22). ② 따로 있는 건물·부속(SC2 Tech Lab A-26, WC3 Blacksmith A-33, C&C3 선택 건물 A-03). ③ 따로 있는 업그레이드 패널이나 판 밖 화면(RA3 TSP A-11, KR·BTD6 메타 트리 A-40·A-46·A-51). 여러 등급짜리는 등급마다 잠금 조건이 붙는다(A-33). 등급을 아이콘 위 숫자로 보이면 알아보기 쉽고(A-29), 이름 접두어만 바뀌면 비판받는다(A-22).
- **개별 레벨업보다 종류 전체 업그레이드.** KR6는 데모 피드백 뒤 타워별 레벨을 버리고 전역 업그레이드로 돌아갔다(A-50). KR6 Ultimate도 «그 종류 전부에 켜진다»(A-51).
- **묶음 구매는 Shift = 5.** C&C(A-05), AoE2(A-12), AoE IV(A-20), 0 A.D.(A-57). 대기열에서도 Shift = 5개 빼기(A-05·A-13). 누르고 있기 = OS 키 반복(A-28)은 과잉 생산 위험이 있다. 대기열 상한은 5(SC2, Reactor 8)·15(AoE2)이고, 차면 버튼이 회색이 된다(A-14).
- **취소·환불.** C&C는 우클릭 1회 보류, 2회 취소+환불(A-05). 대기열이 넘치면 자동 환불(A-25). KR 판매는 60%(A-46).
- **못 삼·잠김 표시.** 빨강 = 돈 부족(A-18·A-57), 회색 = 선행 조건 없음(A-57), 노랑 = 상한(A-18), 잠금 = 판 밖 해금이 필요(A-40·A-48). 이유는 툴팁의 모자란 양(A-57)이나 음성(A-30)으로 알린다. «조금 모자람»을 «불가»처럼 보이면 불만이 나온다(A-18).
- **버튼 위 정보.** 대기 개수·진행도를 아이콘 위에 겹쳐 그린다(A-16). 포인트 수와 진행 고리(A-11). 전역 대기열 요약은 호평(A-17·A-21).
- **단축키.** 탭마다 글자 키 + Tab으로 하위 탭 순환(A-04·A-08·A-10), 위치 그리드(A-19·A-23·A-24), 범주 = 키보드 한 줄(A-37). BTD6는 새 항목에 기본 키를 더 주지 않는다(A-37).
- **알림.** 탭 깜빡임(A-09), 버튼 위 카운터(A-11). 마지막 탭을 기억하는지는 어느 게임에서도 출처를 못 찾았다.
- **인구 상한.** 생산을 막고 이유를 음성·툴팁으로 알린다(A-30·A-57). 상한을 올리는 건물(+2)과, 클수록 비싸지는 유닛 비용(Northgard A-55).
