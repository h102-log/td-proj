# 99. 출처와 검증

본문이 인용한 `[R-NN]`의 원장이다.

## 1. 만든 방법

| 단계 | 누가 | 결과 |
|---|---|---|
| 저장소 판독 | 메인 세션 | 코드·데이터·SPEC·선행 조사(README §2.1). 기준 `main` `3c5fc84` |
| deep-research 워크플로 | 검색 각도 5개: ① 해외 하이브리드 디펜스의 출정·파밍 루프 ② 국내 유즈맵·랜덤 디펜스의 사냥터와 미션 보스 ③ 레이드 보스 패턴 문법·수치·난이도 단계 ④ 자발적 위험-보상과 템포·피로도 ⑤ 플레이테스트 재미 판정 지표 | 검색 결과 30개(R-01~R-30). 원문 읽기는 25개를 시도했고(5개는 예산 밖) **모두 실패**했다. 이 세션의 네트워크 정책이 namu.wiki·gamedeveloper.com·*.wiki.gg·*.fandom.com·bloonswiki.com·icy-veins.com·arxiv.org·en.wikipedia.org 등을 막았다. 그래서 주장 추출이 0이 되어 워크플로의 3표 반박 검증 단계가 돌지 않았다 |
| 보충 반박 검증 V | 보조 에이전트 둘. 본문이 기대는 핵심 주장 20개(V1~V20)를 처음과 다른 검색어(영어·한국어·다른 표현)로 다시 찾아 확인·반박 | **확인 6 · 부분 확인 12 · 판단 불가 2 · 반박 0**(§3). 부분 확인은 수치·판본·범위를 고쳐 본문에 반영했다. 두 에이전트가 함께 쓰는 검색 한도가 끝에 바닥나 V9는 메인 세션이 다음 턴에 한 번 더 찾았다 |

- 본문의 외부 사실은 **검색 요약 기준**이다. 반박 검증도 원문을 열지 못하고 검색 요약·스니펫으로 판정했다.
- 검색 결과 요약은 이 세션이 끝나면 남지 않는다. 이 표와 본문 인용이 기록이다.
- 국내 WC3 영웅 디펜스의 «사냥터» 규칙 원문은 한국어 검색(나무위키·인벤·루리웹·디시)에서 찾지 못했다. 선행 조사도 같았다(`game_design_research/99_appendix/open_questions.md`).
- 나무위키 복사·번역본(thewiki.kr·namu.moe·en.namu.wiki)과 그 문장을 옮긴 커뮤니티 글은 독립 출처로 세지 않았다.

## 2. 출처 목록

신뢰도: **높음** = 1차 자료(개발사 발표·슬라이드·논문)이거나 독립 출처 둘이 같은 말, **중간** = 위키·가이드·보도 한두 곳이 맞물림, **낮음** = 한 곳뿐(복사본 제외)이거나 포럼·사용자 글 한 건, 출처끼리 엇갈림. §3 판정을 반영했다.

| ID | 게임·주제 | 출처 | 성격 | 신뢰도 |
|---|---|---|---|---|
| R-01 | Kingdom Two Crowns 포탈 출정·반격 | https://kingdomthegame.fandom.com/wiki/Portal (같은 위키 Counterattack_wave·Knight), https://store.steampowered.com/news/posts/?feed=steam_community_announcements&appids=701160&enddate=1639242499 , https://gamerant.com/kingdom-two-crowns-how-destroy-portals/ , Steam 토론 | 팬 위키 + 공식 패치 공지 + 가이드 + 포럼 | 중간(패치 번호는 출처마다 1.1.12~1.1.14) |
| R-02 | Dome Keeper 두 단계 루프·타이머 긴장 | https://www.gamedeveloper.com/road-to-igf-2023/how-dome-keeper-focuses-on-systems-that-feed-into-one-another , https://domekeeper.wiki.gg/wiki/Dome_Keeper , 리뷰 https://www.shacknews.com/article/132448/dome-keeper-review , https://primagames.com/gaming/dome-keeper-review , GamingOnLinux, r/patientgamers | 개발 인터뷰(요지만 확인) + 위키 + 리뷰 | 중간 |
| R-03 | Dome Keeper 사이클·웨이브 무게 | https://domekeeper.wiki.gg/wiki/Technical_Terms , https://steamcommunity.com/app/1637320/discussions/0/5704402939715471022 | 위키·포럼 | 낮음 |
| R-04 | WC3 크리핑·크립재킹·영웅 디펜스 | https://warcraft.wiki.gg/wiki/Creep , https://classic.battle.net/war3/basics/creepjacking.shtml , https://www.gamespot.com/pc/strategy/warcraft3thefrozenthrone/news_6024576.html , https://www.hiveworkshop.com/resources/double-hero-defense.78379 | 위키 + Blizzard 옛 공식 전략 사이트 + 언론(2003 TFT 베타) + 유즈맵 소개 | 높음(레벨별 단계값 80→50%는 위키 한 곳) |
| R-05 | Loop Hero 귀환 보존율 | https://twinfinite.net/guides/loop-hero-return-to-camp-how/ , https://www.avclub.com/loop-hero-tips , https://www.gfinityesports.com/misc/loop-hero-death-what-happens-when-you-die/ | 언론 가이드 셋 | 높음 |
| R-06 | Majesty 2 현상금 깃발·마을 공백 불만 | https://www.gameindustry.com/reviews/game-review/finding-the-majesty-again/ , Metacritic 사용자 리뷰, Gamebanshee 비교 | 리뷰·사용자 리뷰 | 낮음~중간(검증 대상 아님) |
| R-07 | 원피스 랜덤 디펜스 스토리존·보스 약화·보잡 | https://namu.wiki/w/%EC%9B%90%ED%94%BC%EC%8A%A4%20%EB%9E%9C%EB%8D%A4%20%EB%94%94%ED%8E%9C%EC%8A%A4 , 스토리사(실패) 용례: https://www.fmkorea.com/5749273907 , https://www.inven.co.kr/board/maple/5746/305257 | 위키(판본 r145~r785의 검색 요약) + 포럼 | 낮음(«보스 최대 25% 약화»는 한 곳, 판본마다 규칙이 다름) |
| R-08 | 운빨존많겜 골렘 사냥·필드 보스·기절 캔슬 | https://namu.wiki/w/%EC%9A%B4%EB%B9%A8%EC%A1%B4%EB%A7%8E%EA%B2%9C (하위 문서 «게임 모드»), https://www.luckydefenseguides.com/hard-gameplay/ , https://www.luckydefenseguides.com/hell-mode/ | 위키 + 팬 가이드 | 중간(골렘 1분·실패 비패배·보스 60초 게임오버는 한 곳) |
| R-09 | SC2 랜덤 디펜스 미션 보스 | https://namu.wiki/w/%EC%8A%A4%ED%83%80%ED%81%AC%EB%9E%98%ED%94%84%ED%8A%B82%20%EB%9E%9C%EB%8D%A4%20%EB%94%94%ED%8E%9C%EC%8A%A4 , https://www.dogdrip.net/45254879 | 위키(판본 r18~r479) + 커뮤니티 글 한 건 | 중간(제한 4분은 한 곳) |
| R-10 | 프로젝트 디펜스(캐슬 디펜스 + 보스 레이드) | https://namu.wiki/w/%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%EB%94%94%ED%8E%9C%EC%8A%A4 | 위키 | 낮음(검증 대상 아님) |
| R-11 | 防守亿万年 개인 사냥터(练功房) | https://www.18183.com/xiazai/bd_24263.html | 다운로드 사이트 맵 소개 한 곳 | 낮음 |
| R-12 | 守护雅典娜 사냥방·거점 무적, 랜덤 다이스·아이마스 디펜스 협동 보스 | https://www.taptap.cn/moment/790527417117575001 , 나무위키 «아이마스 디펜스(유즈맵)»·«랜덤 다이스» | 플레이어 글 한 건 + 위키 | 낮음 |
| R-13 | Kingdom Rush 웨이브 조기 호출 | https://www.gamedeveloper.com/design/kingdom-rush---the-wonderful-campaign-level-design , https://steamcommunity.com/app/816340/discussions/0/1734342161871096889 , https://www.levelwinner.com/?p=114026 , https://www.trueachievements.com/a382017/daring-achievement , toucharcade 포럼 | 칼럼 + 가이드 둘 + 포럼 | 중간(보너스 골드·타이머 고리 확인, «남은 시간 비례»는 못 찾음) |
| R-14 | Risk of Rain 2 산의 성소 | https://riskofrain2.wiki.gg/wiki/Shrine_of_the_Mountain , gamepur·gamewith | 위키·가이드 | 중간(검증 대상 아님) |
| R-15 | Path of Exile Delirium | https://www.pcgamer.com/path-of-exile-delirium/ | 보도 | 중간(검증 대상 아님) |
| R-16 | They Are Billions 아이언맨 | https://www.player2.net.au/2019/07/they-are-billions-a-half-baked-console-experience/ , https://www.ausgamers.com/games/they-are-billions/review/ , https://www.moddb.com/news/they-are-billions-update-ready-for-the-survival , Steam 토론(2019~2024) | 리뷰 둘 + 개발사 소식 + 포럼 | 중간 |
| R-17 | Thronefall 변이 | https://steamcommunity.com/sharedfiles/filedetails/?id=3042795640 , Steam 토론 플레이어 글 | 커뮤니티 가이드 + 포럼 | 낮음(적 체력 +75%만 확인, 점수 +40%는 미확인) |
| R-18 | 명일방주 위기 협약 | https://gamepress.gg/arknights/node/16636 , https://ak.gamepress.gg/node/17981 , https://arknights.wiki.gg/wiki/Contingency_Contract | 커뮤니티 위키(초기 시즌, 구판 규칙) | 중간(검증 대상 아님) |
| R-19 | BTD6 보스 이벤트 | https://www.bloonswiki.com/Boss_Bloon_Event | 위키 | 중간(검증 대상 아님) |
| R-20 | WoW 공격대 찾기 기믹 축소 | https://blizzardwatch.com/2017/08/04/differing-raid-philosophies-make-balancing-extremes-difficult , https://mein-mmo.de/en/das-ende-des-afk-farmens-der-lfr-in-wow-wird-haerter,169070 , https://mein-mmo.de/en/raidfinder-lfr-ende-touristenmodus,170514 | 팬 뉴스 해설 + 개발자 Q&A를 옮긴 보도 | 중간(Legion 무렵 방침. 2012 «켜고 끄는 능력» 발언은 미확인) |
| R-21 | WoW 소프트·하드 인레이지 | https://www.icy-veins.com/wow/blade-lord-ta-yak-strategy-guide-normal-heroic , https://warcraft.wiki.gg/wiki/Ta%27yak , https://warcraft.wiki.gg/wiki/Enrage_(boss) | 공략 + 위키(둘 다 게임 툴팁을 옮김) | 중간(Ta'yak 확인. «대개 5~10분» 일반 범위는 미확인) |
| R-22 | FFXIV 공통 기믹 | https://ffxiv.consolegameswiki.com/wiki/Common_mechanics_and_markers , https://materiaraiding.pages.dev/resources/glossary | 커뮤니티 위키 + 레이드 용어집(서로 독립) | 높음 |
| R-23 | 명일방주 보스 페이즈(Al-Rafiq 등) | https://arknights.wiki.gg/wiki/Al-Rafiq | 커뮤니티 위키 한 곳 | 낮음(V15 판단 불가) |
| R-24 | 로스트아크 무력화·예고 색 | https://www.gamepressure.com/lost-ark/stagger/zbf7f8 , https://vulkk.com/2022/02/11/how-to-use-advanced-combat-mechanics-in-lost-ark/ , https://mobalytics.gg/lost-ark/boss-guides/legion-raids/brelshaza-3 , https://maxroll.gg/lost-ark/legion-raids/vykas-phase-1 | 팬 가이드 | 중간(«빨간 빛 = 피하기»는 일반 규칙 아님) |
| R-25 | Valve 플레이테스트, RITE | https://cdn.fastly.steamstatic.com/apps/valve/2009/GDC2009_ValvesApproachToPlaytesting.pdf , https://game.watch.impress.co.jp/docs/news/080132.html , https://measuringu.com/rite-method/ , Medlock 『Games User Research』 13장(OUP 2018) | 1차 발표 슬라이드 + 현장 보도 + 방법을 만든 사람의 서술 | 높음 |
| R-26 | EA EOMM·DDA | https://arxiv.org/pdf/1702.06820.pdf , https://ui.adsabs.harvard.edu/abs/2017arXiv170206820C/abstract , http://archives.iw3c2.org/www2017/proceedings/companion/p465.pdf | 논문(WWW 2017) | 높음 |
| R-27 | Cuphead 체력바·사망 화면 진행 막대 | https://gonintendo.com/comments/6169 , https://nintendoeverything.com/cuphead-lack-of-health-bars-explained/ , criticsatlarge.ca·keengamer.com 리뷰 | Edge 인터뷰를 옮긴 보도 둘(서로 독립 아님) + 리뷰 | 중간 |
| R-28 | 난이도와 동기의 생존분석 | https://cedric.cnam.fr/index2.php/publis/article/ALP17 | 논문(FDG 2017) | 중간(검증 대상 아님, 효과 크기 미확인) |
| R-29 | 행동 지표(fun meters)와 한계 | https://www.gameanalytics.com/blog/measuring-player-experience , https://howtomarketagame.com/2022/10/26/what-is-a-good-median-play-time-for-a-demo-benchmark/ | 업계 블로그 | 중간(검증 대상 아님) |
| R-30 | Supercell 프로토타입 폐기·Squad Busters | https://gamedeveloper.com/business/quality-is-worth-killing-for-supercell-s-ruthless-approach-to-production , https://www.pocketgamer.biz/pressure-to-launch-a-new-game-led-to-squad-busters-global-release/ , https://wnhub.io/news/other/item-11070 | 보도(GDC 2016 강연·CEO 연례 글 인용) | 중간~높음 |

## 3. 보충 반박 검증 V

판정: 확인(다른 출처가 같은 내용) / 부분 확인(맞지만 고칠 점이 있음) / 엇갈림 / 반박 / 판단 불가(둘째 출처 없음). «본문 반영» 칸은 고친 내용이다.

| V | 주장 | 판정 | 본문 반영 |
|---|---|---|---|
| V1 | 원랜디: 누적 피해만큼 보스가 최대 25% 약해짐, 스토리 기한을 못 지키면 패배 | 판단 불가(25%는 나무위키와 복사본뿐). 스토리사는 확인 | «나무위키 한 곳, 판본마다 규칙이 다름»으로 표시. 11.0판 «스턴치를 다 깎으면 현재 체력 10% 감소»라는 다른 규칙도 적음 |
| V2 | 운빨존많겜: 골렘 1분·실패해도 게임오버 아님·행운석은 거의 골렘에서만, 보스 60초 게임오버, 어려움 기절 −50% | 부분 확인 | 행운석은 10웨이브 보스 빠른 처치·미션으로도 얻음. 기절 감소는 «하드 모드 기절 50% 감소(보스에만인지 불명)». 1분·게임오버 조건은 한 곳으로 표시 |
| V3 | SC2 랜디: 미션 보스를 원할 때 소환, 제한 4분 | 부분 확인 | F5 소환·등급 확인. 4분은 한 곳으로 표시. 등급은 10스테이지마다 하나씩 열림 |
| V4 | Kingdom Two Crowns: 4코인 출정, 포탈 체력 미회복, 반격 강화, 1.1.13 반격 완화 | 부분 확인 | 패치 번호를 «2021년 말 패치(1.1.12~1.1.14)»로 |
| V5 | WC3 TFT 크립 경험치 감소·5레벨부터 0, 크립재킹 공식 페이지 | 확인 | 단계값 80→50%는 위키 한 곳 |
| V6 | Loop Hero 100·60·30% | 확인 | 캠프 옆 칸 100%·불멸의 오브 예외를 덧붙임 |
| V7 | Dome Keeper 인터뷰: 채굴·방어 두 단계가 서로를 키움 | 부분 확인 | 직접 인용 대신 요지로 |
| V8 | They Are Billions: 수동 저장 없음, «웨이브마다 자동 저장» 요청 | 부분 확인 | «종료할 때 한 칸 자동 저장, 되돌리기 불가», 요청은 «수동 저장·아이언맨 아닌 모드», 백업 파일 우회 |
| V9 | Kingdom Rush 조기 호출 보너스(남은 시간 비례) | 부분 확인(메인 세션 검색 1회) | 보너스 골드(KR5는 주문 쿨다운도)와 아이콘 둘레 타이머 고리는 가이드로 확인. «남은 시간에 비례»는 못 찾았고, 플레이어 글은 오히려 «빨리 불러도 골드가 아주 적다, 빨리 부를수록 더 달라»고 한다. 본문의 «비례하게»는 우리 안(C4)으로만 둔다 |
| V10 | Thronefall «Challenge the Turtle God» 적 체력 +75%·점수 +40% | 부분 확인 | +75%만 확인, +40%는 미확인(AI 생성 페이지뿐) |
| V11 | WoW LFR: 기믹 수는 줄이고 남은 기믹은 위협적으로, «켜고 끄는 능력은 뺀다»(2012) | 부분 확인 | 시기를 Legion(2017 무렵)으로. 2012 발언은 지움 |
| V12 | Ta'yak 60초마다 +5%, 하드 인레이지 대개 5~10분 | 부분 확인 | Ta'yak 확인, 일반 범위는 지우고 «Ta'yak 약 8분»으로 |
| V13 | 로스트아크: 게이지는 스킬로만, 파랑 = 카운터·빨강 = 피하기, 시간 안에 무력화해야 넘어감 | 부분 확인 | «많은 보스», «무력화 효과가 있는 스킬에 맞으면 준다», 빨강 규칙 지움, «실패하면 보스마다 다른 벌칙» |
| V14 | FFXIV 흩어지기·쌓기·탑·탱크버스터 | 확인 | 탑은 인원이 모자라면 터져 파티 전체가 맞음(나눔은 쌓기형 탑만) |
| V15 | 명일방주 Al-Rafiq 30초 창 | 판단 불가(위키 한 곳) | «커뮤니티 위키 한 곳»으로 표시 |
| V16 | Cuphead 체력바 없음·사망 화면 진행 막대, 개발사 이유 | 부분 확인 | 이유 둘(1930년대 만화 느낌, 체력 숫자를 보다 신호를 놓침). 두 보도는 같은 인터뷰를 옮긴 것 |
| V17 | Valve GDC 2009: 가설·실험 루프, 관찰·발화·Q&A·설문 + 통계 | 확인 | «섞는다» 대신 «방법마다 장단점과 함께 견준다», 통계의 한계 문구 |
| V18 | EOMM: 연속 패배 조합에 따라 이탈 위험이 크게 달라짐 | 확인 | «약 2배(3연패 5.1%, 가장 안전한 조합 2.6~2.7%), EA 1:1 대전 게임 하나» |
| V19 | Supercell 10개 중 7·2 폐기, Squad Busters 베타 D1 61%·D7 38% | 부분 확인 | 2016 GDC 강연 기준, 2차 클로즈드 베타(2023-05) 수치, CEO 연례 글(2025-02) |
| V20 | RITE: AoE II 튜토리얼에서 소수 참가자마다 고침 | 확인 | 2002 논문·1999 AoE II 개발. «튜토리얼»과 참가자 수 세부는 지움 |

## 4. 보고서 반박 검토 (2026-11-09)

웹 근거(§3)와 따로, 보고서 자체를 코드에 대고 반박 검토했다.

- 방법: 워크플로(에이전트 9개). 렌즈 넷으로 찾고, 렌즈마다 반박 검증자가 지적을 코드로 다시 본 뒤, 완결성 비평이 빠진 것을 찾았다.
  - 렌즈: ① 코드 인용 정확성 ② A1·C1·C2와 기존 시스템의 충돌 ③ B1·B2와 기존 시스템의 충돌 ④ 지표·구성·CLAUDE.md 준수
  - 확인된 지적의 핵심 근거(약 25곳의 줄 번호와 코드 조각)는 Claude가 다시 grep·sed로 확인한 뒤 반영했다.
- 결과: 확인 43건(높음 8·중간 22·낮음 13), 빠진 점 8건(높음 2·중간 4·낮음 2), 기각 5건.

### 4.1 반영한 큰 고침

| 곳 | 고친 것 |
|---|---|
| 03 P2 | 스킬 id `mark` → `brand`. 효과 함수 `_mark`가 투석기·불화살 대상 고르기(`battle.gd:4488`)와 이름이 겹친다. 성벽 위 아군도 맞는다(`_blast`와 같게) |
| 03 원칙 1·§2.1 | 4~6라운드 보스는 모두 한밤에 나온다(4라운드도 약 170초에 나와 이미 어둠 1). 자리 예고(P1·P2)는 어둠 속 보스여도 그리고(S213 개정 후보), 토템은 불빛을 낸다 |
| 03 P5 | hard에 `siege`만 켜면 블록 자리가 빈 병사 하나에 막혀 선다. `ignore_units`를 함께 켠다 |
| 03 P1 | 빈 원의 피해는 성곽 조각을 잔해로 만들지 않는다(체력 1 아래로 내리지 않음) |
| 03 P4 | 봉인도 게이지에 더한다(봉인 취소로 우회되지 않게). 예고 시간은 기절 return 앞에서 센다 |
| 03 원칙 4 | 대본은 `script`와 차례 칸으로 정한다. 지금 skills 차례는 우선순위일 뿐이다 |
| 03 §2.1 | 라운드별 패턴은 종류를 나누지 않고 웨이브 파일의 `boss_skills` 덮어쓰기로(그림·HUD 툴팁 `ENEMIES[k]`·번역 키가 종류 이름에 묶여 있다) |
| 03 §2.3(새 절) | B1 보상 구조와 루프 결합: 즉시 이득 + `soak.bonus`. 미션 파일로 두지 않는 이유(미션은 라운드와 상관없이 뽑힌다) |
| 03 §3 | «도전 보스» → «시련 보스»(SPEC의 «도전» = 판 하나). 시련 웨이브는 낮. 시련 끝은 웨이브 끝 갈래(세금·대피 판정·숙련)를 타지 않음. 쓰러진 영웅은 부활 설정과 상관없이 복귀. 묶인 보스의 반격·sight, 둘레 짓기 금지, 시련판 패턴, `trial_done`은 KEYS 밖 `d.get`. 크기 중 → 중~상 |
| 02 | 실비아 R 저격 예외(가장 먼 적 = 균열), boss 칸 연쇄(음악·소리·오토·사다리), 보스 약화는 `_break`에도, 대기열이 비면 출현 멈춤, `rift_missed` 정의, 균열 몫 기록 `extra_dropped`(라운드 사이 저장), 미리 짓기·막힌 칸, 라운드 배율·비례 피해 단서, EV205·EV212·EV215 개정, 미션 뽑기 갈래, 1라운드 낮 웨이브, 그림 눈금, 판정표 «보상 체감» 행, 위험 체감 근거 |
| 04 C1 | 실비아 E 덫·속박 삭제(E는 바람의 렌즈, 속박을 거는 스킬은 없다). 달아남 갈래는 `_move`에서 `_target_of` 앞. 블록 자리(S159) 조건, 막혀 서는 경우 처리. 크기 하 → 하~중 |
| 04 C2 | 베스퍼 E 오토는 체력 높은 정예를 스스로 묶는다. 정예 표시는 boss 칸 대신 `marked` |
| README §0 | 우선순위 기준과 비율을 뒤집은 까닭을 적음. B1-b 5 → 4위, B2 4 → 5위, C2 7 → 6위, C3 6 → 7위. 1순위는 그대로 A1 |
| README §2.4 | 지표 대조를 사실대로(△ 칸과 이유). 손잡이 자리(C3 `data/contracts`, C4 `call_gold`, B2 `trial` 칸) |
| 01 §3 | 레이드 패턴 표에 세 면 칸. §1·§2의 «—»는 채우거나 «해당 없음: 이유». 출처 없는 Mateo 언급 삭제 |
| 빠진 맥락 | S133·S134(판마다 달라지는 것, 미구현), S252 Q3-1(전리품 6명 전체는 사용자 결정), S39(4방향 침입 계획), `handoff/`로 옮겨진 계획서 |

### 4.2 기각한 지적

| 지적 | 기각 이유 |
|---|---|
| L2-02 종류 사전을 적끼리 같이 쓰는 함정 | 보고서의 rift 사전은 읽기만 하는 값이고, 같은 규칙이 코드에 이미 있다(`battle.gd:199`). 구현 메모로만 한 줄씩 남겼다(02 §2.2, 03 §2.3) |
| L2-09 경보 표식 4초·준비 단계 미리보기·우클릭 0.7칸 | 보고서는 표식이 열린 내내 남는다고 하지 않았다. 위치는 미니맵 점과 C 키 목록이 보여 준다. 미리 알리기는 따로 «정할 것»에 올렸다(빠진 점 C05). 0.7칸 고르기는 큰 보스에도 같은 한계다 |
| L2-10 테스트 모드에서 rifts의 at을 못 고친다 | 보고서는 `rift.tres`만 테스트 모드에서 고친다고 했다. at은 웨이브 데이터에 있어 CLAUDE.md의 «데이터 손잡이» 조건을 채운다 |
| L4-03 작업 순서 6번이 측정 관문이다 | CLAUDE.md의 «측정»은 봇 sweep·운영끼리 승률·생존 비교다. 재미 판정표는 사용자가 지표 ③으로 요청했고, 같은 꼴의 «사용자 후기 뒤 다음 PR» 관문이 선행 계획에도 있다(`insights/2026-10-31_growth.md:281`) |
| L4-09 C1·B2 묶임 크기를 상으로 | 07의 매김에서 «적의 새 목표·경로»가 곧 상은 아니다(도망 = 중, 공성 망치 = 하). C1은 이번 고침으로 하~중이 되었다 |

## 5. A′ 반박 검토 (2026-11-09)

§4 뒤 사용자 판단으로 1순위가 A1에서 A′로 바뀌었다(README 머리). §4.1의 «1순위는 그대로 A1»은 그때의 기록이다. 새로 쓴 05(A′)·README·인사이트를 따로 반박 검토했다.

- 방법: 워크플로(에이전트 5개). 렌즈 넷으로 찾고, 완결성 비평이 빠진 것을 찾았다. 렌즈마다 반박 검증자를 두지 않았다. 그 대신 지적마다 근거 줄을 Claude가 grep·sed로 다시 열어 확인했다.
  - 렌즈: ① 코드 근거 정확성 ② 판 단계·저장·HUD 충돌 ③ 사용자 의도·원작 적합성·더 싼 길 ④ 문서 관례·일관성·CLAUDE.md
- 결과: 지적 58건(높음 8·중간 28·낮음 22, 렌즈끼리 겹침 포함)과 빠진 점 11건(높음 1·중간 5·낮음 5)이 나왔다. 근거 줄은 모두 맞았다. 지적 하나(L3-10)의 일부만 기각했다.

### 5.1 반영한 큰 고침

| 곳 | 고친 것 |
|---|---|
| 05 §2.5 대가 | 원정은 전투 단계라 치유 스킬(세라피나 Q·W·R, 아이아스 R)과 오토가 돌고, 스킬 대기가 준다(`battle.gd:1408`·`:4335-4339`). 준비 단계에는 대기가 멈추므로, 그대로면 원정이 «대기 되돌리기»와 «공짜 치료»가 된다. 그래서 «돌아올 때 체력은 떠날 때보다 높아지지 않는다», «쓴 스킬은 대기가 가득, 쓰지 않은 스킬은 그대로»를 넣었다(Claude 안). 라운드 사이에 출전에서 빠졌던 영웅은 가득 찬 채 돌아온다는 사실(S138)도 바로잡았다 |
| 05 §2.3 집 | 추천을 O1 → O1′로 바꿨다(집은 멈추고, 횃불이 그 준비 단계의 정비 시계). O1에서는 기다리는 데 값이 없어 «더 갈까, 돌아갈까»가 서지 않는다. O1′은 사용자 말의 «시간마다 웨이브가 들어온다»도 낸다(S18 변경이라 사용자 결정) |
| 05 §2.3 공통 | 집과 던전은 서로 고르지 않는다. 궁수 용병(사거리 5·인식 6)·투석기(11)·불화살(9)이 물 한 열을 넘는다(`_act` `:4287`, `_mark` `:3532`). 세라피나 R 기적은 맵 전체를 고친다(`:2032-2035`). 집 명령은 판 API가 받고, 철거·대포 옮기기·대피령은 전투 단계에만 열려 원정 중에 새로 열린다 |
| 05 §2.3 O2 | «지금 틀로 된다»를 «안 된다»로 고쳤다. 판 단계·어둠·웨이브 끝·집계가 판에 하나다(`:790`·`:681`·`:453`). 크기는 A′ + 하~중 → A′ + 상 |
| 05 §2.1 | 웨이브 끝 판정(`:681`)은 원정 중 보지 않고, 끝은 따로 판정한다. 집계는 사본으로 되돌린다(미션 «영웅이 쓰러지지 않는다»). 원정 전에 쓰러져 있던 영웅은 가지 않는다. 원정권 채우기·`restart`, 1라운드는 원정권 없음(튜토리얼), 원정 때 (가)·(나)·(다)를 더했다 |
| 05 §2.7 클리어 | 추천을 W1 → W1′로 바꿨다(재도전을 다 쓰면 마왕이 성으로). W1은 마왕전이 판 패배와 이어져 «원정 실패는 판 패배가 아니다»의 예외다. 마왕층 조건(연 층 수와 상관없이 열고 연 층만큼 약화)과 마왕 단계(지금은 바로 `won`)를 더했다 |
| 05 §2.4 층 | 층 보스는 시련판 패턴으로 쓰고, 보스 스킬 머릿수(count 3)는 원정대에 맞춰 덮는다. `UNSEEN_TELLS`에 slam·leap·cleave가 없다. 어둠 속 적은 고를 수 없다(S213·S300). 새로 생기는 적(분열·투하·2페이즈)도 묶는다. 처치 보상·경험치는 0으로 덮는다. 라운드 체력 배율(S144)이 곱해진다. 상자는 줍는 칸(Claude 안). 지형 행 |
| 05 §2.6 정찰 | 옛 I-2의 «어느 출현 지점이 먼저 오는지»는 늘 같은 차례라 정보가 아니다(`:831`). 그래서 I-2를 «남은 웨이브 미리보기»로 바꾸고 I-4(미리 겪기)를 더했다. 출현 지점 배지·가장자리 표식도 지점별 수를 보인다 |
| 05 §7 | 행을 더했다: 성곽 동쪽 그림(맵 오른끝 = 성곽 오른끝), 바닥 난수, 호위 경계(`:845`), HUD가 전투 단계를 웨이브로 읽는 곳, 소리, 힌트, 마왕 단계. 맵 폭을 박은 EV는 EV453만이 아니다(EV442·EV724, 경계가 물 칸이면 EV468). EV373 검사 범위도 넣었다 |
| README·02·인사이트 | 사용자 말을 «» 안에 줄여 옮기던 것을 요지로 바꾸고 원문은 05 머리를 가리킨다(«시간마다 웨이브가 들어온다»가 빠졌었다). «원작이 같은 문제를 같은 수단으로» → «비슷한 수단, 2차 전언». 22화 댓글·«???» 가림·«왕중왕»·공식 게임과의 거리를 더했다. 동쪽 숲과 동문, `_light_up` 줄 번호, 깨진 링크도 고쳤다 |

### 5.2 기각한 지적

| 지적 | 기각 이유 |
|---|---|
| L3-10의 일부: 묶임 AI를 상으로, README 크기 정의에 07의 «적의 새 목표·경로» 보기를 옮긴다 | §4.2(L4-09)와 같은 이유다. 07의 매김에서 «적의 새 목표·경로»가 곧 상은 아니다(도망 = 중, 공성 망치 = 하). 같은 지적의 나머지(MVP가 §7의 줄을 줄이지 않는다, 중 넷이면 약 4일)는 반영했다 |

## 6. 보스방 사다리 조사와 반박 검증 (2026-11-09)

사용자 판단(«오펜스에서는 컨트롤이 필요한 강력한 보스를 잡는거», 05 머리)과 붙여 넣은 지시로 05를 «보스방 사다리»로 다시 썼다. 워크플로 셋으로 했다.

- **읽기(에이전트 7개).** 하위 시스템 여섯 곳을 병렬로 읽고, 완결성 비평 하나가 빠진 사실을 채웠다. 05 본문의 «영웅 조사»·«장비 조사»는 이 산출물이다.
  - 보스 스킬: 적 정의 칸, 보스 스킬 9개, 보스 CC, 피해 파이프라인, 예고 그림
  - 영웅 기술: 6명 매트릭스, 끊기 수단, 오토 갈래, 조합 20개
  - 원정 배관: 판 단계, Unit 필드, 재도전 스냅숏, 옛 05 §7 행 분류(인용 줄은 모두 HEAD에서 맞았다)
  - 장비·골드: GearDef, 강화·전리품, 라운드 수입
  - 맵: 맵 안 보스방 자리, 동쪽 확장 비용, 카메라
  - 기존 설계: 03 B1·시련 틀, 05 정할 것, SPEC 영향
- **설계(에이전트 6개).** 관점이 다른 설계안 셋을 만들고, 렌즈 셋으로 심사했다. 05의 «설계안 A·B·C»와 «구현 비용 심사»가 이것이다.
  - 설계안: A 재사용 우선, B 레이드 체험 우선, C 조합·오토 견고성 우선
  - 심사 렌즈와 점수: 구현 비용(A 8·B 5.5·C 6.5), 체험(A 5·B 7·C 7), 요구 준수(A 6·B 6.5·C 7.5)
  - 뼈대는 A(판 단계 `raid`, 맵 안 보스방, 되돌리기 하나)다. 시계는 B(횃불 자루 = 시도 한 번의 광폭)에서 가져왔다. 견고성 규칙은 C(영웅 자리를 겨눈 패턴만 피하기 창, 철수 = 진입 몸, 재도전 때 비울 목록)에서 가져왔다. 슈퍼아머는 A·B다.
  - 심사가 바로잡은 사실: 슬라임 킹은 디펜스 1라운드 보스다(`src/main.gd:21`, `data/waves/test_stage.tres`). 2라운드 원정대는 Lv5다(아래 셈). 골드는 대가가 되지 못한다.
- **반박 검증(에이전트 9개).** 렌즈 넷(§2.1~§2.4 인용, §2.5~§3 인용, §4~§8 인용, 계산·일관성·요구 준수)으로 찾았다. 렌즈마다 반박 검증자를 하나씩 두고, 완결성 비평 하나를 더했다.
  - 결과: 지적 40건(높음 3·중간 15·낮음 22)이 나왔다. 확인 31건, 일부 맞음 9건이고 기각은 0건이다. 비평은 9건(높음 2)이다. 모두 반영했다.
  - 큰 고침
    - 고리를 2칸으로 했다. `_shove`가 도착 칸만 봐서 넉백 1.5가 1칸 고리를 건너뛴다(`battle.gd:4426-4442`).
    - 자루는 `_pull()` 한 곳에서만 깎는다(첫 시도에 두 자루가 타던 모순).
    - 대본은 `_ready` 조건을 기다리지 않는다. 강타가 반경 밖 원정대를 기다리며 멈추던 빈칸이다.
    - 레이드 경감 이름을 `ward`로 바꿨다. `guard`는 S301 방패 칸이다.
    - HUD `raid` 갈래를 MVP에 넣었다. `hud.gd:948`·`:1022`가 없는 키를 읽는다.
    - 원정대가 셋보다 적을 때 `need`를 줄인다. 페이즈는 오르기만 한다.
    - 유물 효과는 `relic_fx`에 둔다. fx는 웨이브 끝마다 비워진다.
    - 옛 저장의 보스방 구조물을 다룬다. 카메라 묶기는 `pan` 범위로 한다.
    - S181(저장 때)을 따로 고친다.
  - 숫자 고침
    - CC 없는 창 기회 넷 → 셋
    - 판 길이 20분 → 약 24분(+ 마왕 9분)
    - 오토 A+I+V 60% → 68%(베스퍼 늪이 봉인을 다시 걸어 1/60 → 1/10)
    - 용암 45% → 창 안 67%·창 밖 5.4%
    - 마왕 «마지막 주문» 70 → 100
    - 4층 바위 1.3 → 1.4
  - 줄 번호 고침: `_target_of` `:3433-3482`, `_clear_line` `:3699`, `enemy_def.gd:15`, 아이아스 R `_cast_bulwark` `:1881-1894`

**05에 쓴 수치의 근거(계산, 데이터 값)**

| 수치 | 셈과 근거 |
|---|---|
| 2라운드 원정대 Lv5 | 1라운드 처치 경험치 457. 슬라임 96 × xp 3(`data/enemies/slime.tres:12`), 큰 슬라임 24 × xp 7(`big_slime.tres:14`), 킹 1(기본 `enemy_def.gd:15`). Lv5 누적 170(`data/levels.tres:7`). 갈라진 슬라임은 xp 0(`battle.gd:1148`) |
| A+I+V 묶기 63% | 기절 가동률 합: 아이아스 Q 1.5/6, 이그니스 W 1.5/9, 이그니스 R 2/65, 베스퍼 R 5.6/60 = 54.1%. 요새화 패시브 20%와 합집합이면 1 − 0.459 × 0.8 = 63.3%(대기·지속은 `data/heroes/*.tres`) |
| 라운드 수입 약 940~1,370 | 웨이브 수 × `reward` × 0.1(`main.gd:282`, `data/waves/*.tres`, `data/enemies/*.tres`). 2~6라운드 처치 골드 942·≤997·1,169·1,290·1,372 |
| 강화비 20~150 | `data/hire.tres:14` `gear_cost`, 상한 `forge_cap` 2(`:15`) |
| 조합 초당 피해 D | Lv5(×1.4)·장비 없음·방어 0에서 기본 공격 + 대기마다 스킬 피해의 어림(설계안 A·C). C+Se+Sy 약 28, C+Sy+V 약 30, A+I+V 약 40, C+I+Sy 약 46, A+C+Se·A+Se+Sy 약 21. 측정이 아니다 |
| 용암 67% | 이그니스 R 운석 셋 × 용암 5초 × 초당 최대 체력 3% × 창 1.5(`ignis.tres` R, `battle.gd:1770`) |
| 아이아스 Q 빗나감 | 반경 2를 보스 중심까지 잰다(`_cast_shield_bash` `:1831`). 킹 반지름 2.0 + 영웅 0.3 = 2.3 > 2 |
| 근접 재접근 2.5칸 | 길 끝에서 인식 범위 안 적에게 다가간다(`battle.gd:4315`, `_nearest_enemy(u.pos, u.sight, …)`, 중심 거리). 영웅 sight 2.5(`hero_def.gd:13`) |
| 2배 줌 20×10.4칸 | `hud.gd:124` 640×332, `CELL` 16, `camera.gd:10`·`:27` |
