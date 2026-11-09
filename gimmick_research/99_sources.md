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
