# 99. 출처와 검증

본문이 인용한 `[R-NN]`의 원장이다.

## 1. 만든 방법

| 단계 | 누가 | 결과 |
|---|---|---|
| 저장소 판독 | 메인 세션 | 코드·데이터·SPEC·선행 조사(README §2.1). 기준 `main` `3c5fc84` |
| deep-research 워크플로 | 검색 각도 5개: ① 해외 하이브리드 디펜스의 출정·파밍 루프 ② 국내 유즈맵·랜덤 디펜스의 사냥터와 미션 보스 ③ 레이드 보스 패턴 문법·수치·난이도 단계 ④ 자발적 위험-보상과 템포·피로도 ⑤ 플레이테스트 재미 판정 지표 | 검색 결과 30개(R-01~R-30). 원문 읽기는 25개를 시도했고(5개는 예산 밖) **모두 실패**했다. 이 세션의 네트워크 정책이 namu.wiki·gamedeveloper.com·*.wiki.gg·*.fandom.com·bloonswiki.com·icy-veins.com·arxiv.org·en.wikipedia.org 등을 막았다. 그래서 주장 추출이 0이 되어 워크플로의 3표 반박 검증 단계가 돌지 않았다 |
| 보충 반박 검증 V | 보조 에이전트 둘. 본문이 기대는 핵심 주장 20개(V1~V20)를 처음과 다른 검색어로 다시 찾아 확인·반박 | §3 |

- 본문의 외부 사실은 **검색 요약 기준**이다. 원문 문장을 직접 보지 못했다.
- 검색 결과 요약은 이 세션이 끝나면 남지 않는다. 이 표와 본문 인용이 기록이다.
- 국내 WC3 영웅 디펜스의 «사냥터» 규칙 원문은 한국어 검색(나무위키·인벤·루리웹·디시)에서 찾지 못했다. 선행 조사도 같았다(`game_design_research/99_appendix/open_questions.md`).

## 2. 출처 목록

신뢰도: **높음** = 1차 자료(개발사 발표·슬라이드·논문)이거나 독립 출처 둘이 같은 말, **중간** = 위키·가이드 한 곳 또는 보도가 개발자 발언을 옮김, **낮음** = 포럼·사용자 글 한 건, 출처끼리 엇갈림. §3 검증 결과를 반영했다.

| ID | 게임·주제 | 출처 | 성격 | 신뢰도 |
|---|---|---|---|---|
| R-01 | Kingdom Two Crowns 포탈 출정·반격 | https://kingdomthegame.fandom.com/wiki/Portal (같은 위키 Counterattack_wave·Knight), magicgameworld 팬 가이드, Steam 팁 | 팬 위키·커뮤니티 | 중간 |
| R-02 | Dome Keeper 두 단계 루프·타이머 긴장 | https://www.gamedeveloper.com/road-to-igf-2023/how-dome-keeper-focuses-on-systems-that-feed-into-one-another , 리뷰 https://www.shacknews.com/article/132448/dome-keeper-review , https://primagames.com/gaming/dome-keeper-review , GamingOnLinux, r/patientgamers | 개발자 인터뷰(원문 미열람) + 리뷰 | 중간 |
| R-03 | Dome Keeper 사이클·웨이브 무게 | https://domekeeper.wiki.gg/wiki/Technical_Terms , https://steamcommunity.com/app/1637320/discussions/0/5704402939715471022 | 위키·포럼 | 낮음~중간 |
| R-04 | WC3 크리핑·크립재킹·영웅 디펜스 | https://warcraft.wiki.gg/wiki/Creep , https://classic.battle.net/war3/basics/creepjacking.shtml , https://www.hiveworkshop.com/resources/double-hero-defense.78379 | 위키 + Blizzard 공식 전략 사이트 + 유즈맵 소개 | 중간 |
| R-05 | Loop Hero 귀환 보존율 | https://twinfinite.net/guides/loop-hero-return-to-camp-how/ , https://gamertweak.com/how-to-return-camp-loop-hero | 가이드(2021) | 중간 |
| R-06 | Majesty 2 현상금 깃발·마을 공백 불만 | https://www.gameindustry.com/reviews/game-review/finding-the-majesty-again/ , Metacritic 사용자 리뷰, Gamebanshee 비교 | 리뷰·사용자 리뷰 | 낮음~중간 |
| R-07 | 원피스 랜덤 디펜스 스토리존·보스 약화·보잡 | https://namu.wiki/w/%EC%9B%90%ED%94%BC%EC%8A%A4%20%EB%9E%9C%EB%8D%A4%20%EB%94%94%ED%8E%9C%EC%8A%A4 , 디시 원랜디 갤러리 | 위키(판본 r145~r785의 검색 요약) | 중간 |
| R-08 | 운빨존많겜 골렘 사냥·필드 보스·기절 캔슬 | https://namu.wiki/w/%EC%9A%B4%EB%B9%A8%EC%A1%B4%EB%A7%8E%EA%B2%9C , 하위 문서 «게임 모드» | 위키(판본 r221~r955) | 중간 |
| R-09 | SC2 랜덤 디펜스 미션 보스 | https://namu.wiki/w/%EC%8A%A4%ED%83%80%ED%81%AC%EB%9E%98%ED%94%84%ED%8A%B82%20%EB%9E%9C%EB%8D%A4%20%EB%94%94%ED%8E%9C%EC%8A%A4 | 위키(판본 r18~r479) | 중간 |
| R-10 | 프로젝트 디펜스(캐슬 디펜스 + 보스 레이드) | https://namu.wiki/w/%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8%20%EB%94%94%ED%8E%9C%EC%8A%A4 | 위키 | 중간 |
| R-11 | 防守亿万年 개인 사냥터(练功房) | https://www.18183.com/xiazai/bd_24263.html | 다운로드 사이트 맵 소개 한 곳 | 낮음 |
| R-12 | 守护雅典娜 사냥방·거점 무적, 랜덤 다이스·아이마스 디펜스 협동 보스 | https://www.taptap.cn/moment/790527417117575001 , 나무위키 «아이마스 디펜스(유즈맵)»·«랜덤 다이스» | 플레이어 글 한 건 + 위키 | 낮음 |
| R-13 | Kingdom Rush 웨이브 조기 호출 | https://www.gamedeveloper.com/design/kingdom-rush---the-wonderful-campaign-level-design , https://steamcommunity.com/app/816340/discussions/0/1734342161871096889 , toucharcade 포럼, levelwinner KR5 가이드 | 칼럼 + 포럼 | 중간 |
| R-14 | Risk of Rain 2 산의 성소 | https://riskofrain2.wiki.gg/wiki/Shrine_of_the_Mountain , gamepur·gamewith | 위키·가이드 | 중간 |
| R-15 | Path of Exile Delirium | https://www.pcgamer.com/path-of-exile-delirium/ | 보도 | 중간 |
| R-16 | They Are Billions 아이언맨 | https://www.player2.net.au/2019/07/they-are-billions-a-half-baked-console-experience/ , Steam 토론 | 리뷰 + 포럼 | 중간 |
| R-17 | Thronefall 변이 | https://steamcommunity.com/sharedfiles/filedetails/?id=3042795640 | 커뮤니티 가이드 | 낮음~중간 |
| R-18 | 명일방주 위기 협약 | https://gamepress.gg/arknights/node/16636 , https://ak.gamepress.gg/node/17981 | 커뮤니티 위키(초기 시즌) | 중간 |
| R-19 | BTD6 보스 이벤트 | https://www.bloonswiki.com/Boss_Bloon_Event | 위키 | 중간 |
| R-20 | WoW 공격대 찾기 기믹 축소 | https://mein-mmo.de/en/raidfinder-lfr-ende-touristenmodus,170514 , https://mein-mmo.de/en/das-ende-des-afk-farmens-der-lfr-in-wow-wird-haerter,169070 , https://www.engadget.com/2012-08-22-gamescom-raid-qanda-with-the-devs-nerfs-the-raid-finder-and-more.html | 보도(개발자 발언 옮김) | 중간 |
| R-21 | WoW 소프트·하드 인레이지 | https://www.icy-veins.com/wow/blade-lord-ta-yak-strategy-guide-normal-heroic , https://warcraft.wiki.gg/wiki/Enrage_(boss) , https://finalfantasy.fandom.com/wiki/Enrage_(term) | 공략·위키 | 중간 |
| R-22 | FFXIV 공통 기믹 | https://ffxiv.consolegameswiki.com/wiki/Common_mechanics_and_markers | 위키 | 중간 |
| R-23 | 명일방주 보스 페이즈(Al-Rafiq 등) | https://arknights.wiki.gg/wiki/Al-Rafiq , https://arknights.wiki.gg/wiki/Contingency_Contract | 위키 | 중간 |
| R-24 | 로스트아크 무력화·예고 색 | https://www.gamepressure.com/lost-ark/stagger/zbf7f8 , https://maxroll.gg/lost-ark/legion-raids/vykas-phase-1 , Mobalytics, Steam 토론 | 가이드 | 중간 |
| R-25 | Valve 플레이테스트, RITE | https://cdn.fastly.steamstatic.com/apps/valve/2009/GDC2009_ValvesApproachToPlaytesting.pdf , https://measuringu.com/rite-method/ | 1차 발표 슬라이드 + 2차 요약 | 높음 |
| R-26 | EA EOMM·DDA | https://arxiv.org/pdf/1702.06820.pdf , http://archives.iw3c2.org/www2017/proceedings/companion/p465.pdf | 논문 | 높음(수치 미확인) |
| R-27 | Cuphead 체력바·사망 화면 진행 막대 | https://gonintendo.com/comments/6169 , criticsatlarge.ca·keengamer.com 리뷰 | 보도·리뷰 | 중간 |
| R-28 | 난이도와 동기의 생존분석 | https://cedric.cnam.fr/index2.php/publis/article/ALP17 | 논문(FDG 2017) | 높음(효과 크기 미확인) |
| R-29 | 행동 지표(fun meters)와 한계 | https://www.gameanalytics.com/blog/measuring-player-experience , https://howtomarketagame.com/2022/10/26/what-is-a-good-median-play-time-for-a-demo-benchmark/ | 업계 블로그 | 중간 |
| R-30 | Supercell 프로토타입 폐기 | https://gamedeveloper.com/business/quality-is-worth-killing-for-supercell-s-ruthless-approach-to-production , pocketgamer.biz | 보도 | 중간 |

## 3. 보충 반박 검증 V

(보조 에이전트 결과를 받는 대로 채운다.)
