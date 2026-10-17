# 02. 상점 페이지와 첫 5분 — 잘된 디펜스 게임에서 배울 점

질문 2에 답한다. 비슷한 규모로 성공한 인디 디펜스 게임은 상점 페이지(캡슐·트레일러·스크린샷·태그)와 첫 5분 온보딩을 어떻게 짰나?

AI로 만들었는지와 상관없이 잘된 게임을 골랐다. 이 영역에서 AI 게임만 따로 배울 것은 없었다. 확인 날짜는 2026-10-18이다.

## 요약

- **상점 페이지:** 히트작 7개는 사용자 태그 1위가 거의 다 Tower Defense(6/7)다. 스크린샷 6~16장(중앙값 10), 트레일러 1개(중앙값), 짧은 설명 67~309자(중앙값 204)이고, 첫 문장에 무엇을 하는 게임인지를 담았다 [M2]. 7개 모두 AI 공개가 없다 [M2].
- **Valve 공식 입장:** 위시리스트, 상점 페이지 전환율, 스크린샷 수, 설명 길이는 노출 알고리즘 요인이 아니다. 구매·플레이가 강한 신호이고 태그가 중요하다 [N2-13] [N2-14] [Q2-f3]. 다만 Discovery Queue가 출시 직후 유입의 절반 가까이를 차지한다는 개발자들의 관찰이 있다 [Q2-d3] [N2-15].
- **첫 5분:**
  - Thronefall은 튜토리얼 뒤에도 팁으로 계속 가르친다 [N2-03]. 메타 진행으로 초보의 결정 마비를 줄이고 [N2-01], 초보용 기본 선택지는 일부러 조금 약하게 만든다 [N2-05].
  - Kingdom Rush 1레벨의 첫 웨이브는 병영 하나로 정확히 막히는 고블린 3마리다 [Q2-b1].
  - The King is Watching은 첫 판을 짧게 만들고 쉬운 건물부터 해금하도록 고쳤다 [N2-08].
- **데모:** 데모는 플레이테스트가 아니라 마케팅이다. 쉽게 만들고 중앙 플레이 시간 30~90분을 목표로 한다 [Q2-c1] [Q2-c5]. Next Fest는 출시 전 게임만, 한 번만 참가할 수 있다 [§5].

## 1. 상점 페이지 실측 (M2)

방법:
- appdetails API(미국 스토어, USD)와 appreviews API로 받았다(language=all, purchase_type=all).
- 태그는 상점 HTML의 표시 순서를 그대로 땄다.
- About 글자 수는 HTML을 걷어내고 직접 셌다.
- 픽셀아트 2개는 2024~26 출시이면서 Pixel Graphics 태그가 있는 후보 13개 중에서 골랐다. The King is Watching은 리뷰 수가 가장 많아서, Border Pioneer는 성 방어·픽셀·중세 태그가 모두 상위에 있어서 골랐다.

| 게임 | 출시 | 가격 | 스샷 | 영상 | 짧은 설명 | About | 리뷰 수 / 긍정% |
|---|---|---|---|---|---|---|---|
| Thronefall | 2024-10 (1.0) | $12.99 | 11 | 1 | 67자 | 1,919자 | 23,907 / 96.1 |
| Rogue Tower | 2022-01 | $14.99 | 13 | 1 | 158자 | 2,899자 | 5,934 / 82.6 |
| Kingdom Two Crowns | 2018-12 | $19.99 (확인일 할인 $1.99) | 6 | 8 | 288자 | 2,961자 | 41,188 / 90.0 |
| Bloons TD 6 | 2018-12 | $13.99 | 10 | 1 | 163자 | 3,059자 | 397,296 / 97.2 |
| Kingdom Rush | 2014-01 | $9.99 | 8 | 1 | 309자 | 1,682자 | 19,600 / 97.2 |
| The King is Watching (픽셀) | 2025-07 | $14.99 | 16 | 2 | 204자 | 1,530자 | 10,740 / 88.7 |
| Border Pioneer (픽셀) | 2025-02 | $14.99 | 6 | 4 | 259자 | 1,218자 | 1,939 / 86.5 |

| 게임 | 짧은 설명 첫 문장 | 사용자 태그 상위 |
|---|---|---|
| Thronefall | "A minimalist game about building and defending your little kingdom." | Tower Defense, Strategy, City Builder, Minimalist, Medieval, Action, Action RTS, Base Building |
| Rogue Tower | "Rogue Tower is a tower defense game with roguelike elements and a continuously expanding path which you can influence." | Tower Defense, Strategy, Roguelike, Casual, Procedural Generation, 3D, Minimalist, Base Building |
| Kingdom Two Crowns | "Gather coins, build defenses and reclaim your fallen Kingdom." | Tower Defense, Minimalist, City Builder, Building, Singleplayer, Base Building, Medieval, Strategy |
| Bloons TD 6 | "The Bloons are back and better than ever!" | Tower Defense, Strategy, Multiplayer, Singleplayer, Online Co-Op, Co-op, Family Friendly, Casual |
| Kingdom Rush | "Get ready for an epic journey to defend your kingdom against hordes of orcs, trolls, evil wizards…" | Tower Defense, Strategy, Singleplayer, 2D, Tactical, Fantasy, Casual, Action |
| The King is Watching | "The King is Watching is a roguelite kingdom builder." | Roguelike, Base Building, Tower Defense, RTS, Dark Fantasy, Fantasy, Strategy, Resource Management |
| Border Pioneer | "As the kingdom's most promising pioneer, embark on a legendary journey to tame the frontier!" | Tower Defense, Strategy, City Builder, Base Building, Medieval, Action, Pixel Graphics, RTS |

## 2. 공통점

사실 [M2]:
- 사용자 태그 1위가 Tower Defense인 게임이 6/7이다(예외는 The King is Watching, 3위). 7개 모두 Strategy가 상위 8에 있다.
- 스크린샷은 6~16장(중앙값 10)이다. 영상은 4개 게임이 1개이고, 나머지는 2, 4, 8개다.
- 짧은 설명의 첫 문장은 세 형태다.
  - "[게임명] is a [장르]": Rogue Tower, The King is Watching
  - 명령형 동사로 시작: Kingdom Two Crowns, Kingdom Rush, Border Pioneer
  - 명사구 정의: Thronefall
- 짧은 설명에 "kingdom"이 들어간 것이 5개, defend 계열 동사가 들어간 것이 5개다.
- About은 1,218~3,059자로 모두 업체 표본 중앙값(4,830자)보다 짧다 [Q2-f3].

추론:
- 히트작의 짧은 설명은 첫 문장 안에 '짓고 지킨다' 또는 장르 이름을 담는 쪽으로 모인다.
- 스크린샷 8~12장, 트레일러 1개가 무난한 기본값이다. 순위 요인은 아니고 관습이다 [N2-13].
- 업체 자료 [Q2-f5]는 TD 첫 스크린샷으로 빈 맵 대신 후반의 화려한 장면을 권한다. 의견이고 측정값이 아니다.

업체 자료(Steam Page Analyzer)의 수치는 참고만 한다. 결함 판정 기준을 공개하지 않은 AI 분석기이고, 판정기 개정으로 비율이 40포인트 넘게 바뀌었다고 스스로 밝혔다 [Q2-f4] [Q2-f6].
- Strategy 페이지 표본에서 흔한 결함은 약하거나 묻힌 첫 훅(70~80%), 썸네일 크기에서 안 읽히는 캡슐 글자(49~94%), 태그 칸 미사용(48~54%)이다 [Q2-f4].
- 2026년 TD 출시작은 '지금까지' 652개다. 그중 리뷰 1,000개에 이른 비율은 3.5%로, 스팀 최근 출시작 전체의 4.2%보다 낮다 [Q2-f1] [Q2-f2].

## 3. Valve 공식 — 노출 요인

출처: https://partner.steamgames.com/doc/marketing/visibility (확인 2026-10-18)

- 위시리스트는 'Popular Upcoming' 같은 예외를 빼면 알고리즘 노출 요인이 아니다 [N2-13].
- 상점 페이지 전환율은 요인이 아니다. 리뷰 점수도 Mixed(40%) 이상이면 요인이 아니다 [N2-13].
- 사람들이 사서 플레이하는지가 강한 신호다. 태그가 중요하다 [N2-14].
- Discovery Queue는 "나타날 수도 있다"고 한 줄 언급할 뿐, 작동 방식은 설명하지 않는다 [N2-14].

## 4. Discovery Queue — 개발자 관찰 (블로그)

- Jonas Tyroller의 두 게임(Will You Snail?, Thronefall)은 출시 초기 상점 조회의 50% 이상이 Discovery Queue에서 왔다 [Q2-d3].
- 위시리스트가 많은 게임은 첫날 약 2만 회 노출을 받고, 성과가 좋으면 다음 날 두 배 이상 받는다. 저자도 '성과가 좋다'의 기준은 모른다고 썼다 [Q2-d4].
- 75개 게임 설문에서는 출시 2주 동안 Discovery Queue가 상점 방문의 절반 가까이를 차지했다 [N2-15].
- 출시 전 Discovery Queue에 처음 오를 때 직전 7일 위시리스트는 1,500~4,000 구간에 몰렸다(14개 게임) [N2-16].
- 공식 문서 [N2-13]와 긴장이 있다. 블로그가 본 위시리스트와 노출의 상관은 출시 직후 판매를 거쳐 생긴 것일 수 있다(추론, 확인 안 됨).
- Thronefall의 숫자 [Q2-d1] [Q2-d2] [Q2-d6]:
  - 출시 시 위시리스트 약 20만(글 작성 시점 50만 이상)
  - 1년 안에 리뷰 약 1.5만
  - 출시 동시접속 약 7,000
- 저자는 '어떤 게임을 만드느냐가 가장 큰 마케팅 결정'이라고 하고, 스팀이 짓고 만드는 전략 장르를 좋아한다고 본다 [Q2-d5].

## 5. 데모와 Next Fest

GMTK(Mark Brown, 단어 게임 Word Play, 2025-06) [Q2-c1]~[Q2-c7]:
- 데모 길이는 Steamworks의 'median time played'로 확인하고, 중앙값 30~90분을 목표로 한다.
- Next Fest 약 2주 전에 데모를 먼저 냈더니, 페스티벌 시작 전에 위시리스트가 약 25,000 쌓였다.
- 무료 데모는 지루하면 바로 꺼진다. 첫인상과 만족스러운 오프닝을 의도해서 만든다.
- 데모 난이도는 쉬운 쪽으로 둔다. 데모는 플레이테스트가 아니라 마케팅이다.
- 정식판 일부만 넣는다(퍼크 120개 중 약 25개). 잠긴 모드는 자물쇠와 'available in the full release' 표시로 보여 준다. 따로, 데모 안에 상점 페이지로 가는 버튼을 둔다.

Thronefall [F-10]: 2022년 6월 Next Fest 데모로 관심이 급증했다. 약 1,000개 참가작 중 팔로워 증가 15위(+2,043), 데모 최고 동시접속 11위(860)였다.

공식 규정(https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest, 확인 2026-10-18) [N2-17]:
- 미출시 게임만, 한 게임당 한 번만 참가할 수 있다.
- 회차가 끝나기 전에 출시하면 안 된다.
- 상점 페이지가 공개돼 있어야 하고, 시작 때까지 공개 데모가 있어야 한다.
- 처음 며칠은 명시 목록을 빼고 모든 자리에서 노출을 무작위로 섞는다.

| 회차 | 기간 | 등록 마감 | 출처 |
|---|---|---|---|
| 2026년 10월 | 10/19~10/26 | 8/31 (마감됨) | [N2-18] |
| 2027년 2월 | 2/22~3/1 | 1/10. 1/25까지 내면 프레스 프리뷰 대상, 2/8까지 모든 항목 제출. 출시는 3/1 이후 | [N2-19] |
| 2027년 6월 | 6/14~6/21 | – | [N2-19] |

## 6. 첫 5분 온보딩

### Thronefall (개발사 공지, 1차)

- 메타 진행의 주된 목적은 새 플레이어의 결정 마비와 복잡도를 줄이는 것이다 [N2-01].
- 튜토리얼은 앞서 해보기 내내 초기 상태 그대로였다. 편의 기능(부대 선택 단축키)을 가르치지 않아 많은 플레이어가 놓쳤다. 콘텐츠 일부만 해금하고 캠페인을 끝내는 사람도 많았다. 개발사는 의도한 바가 아니었다고 썼다 [N2-02].
- 1.7에서 '튜토리얼 뒤에 이어지는 튜토리얼'인 팁 시스템을 넣었다 [N2-03].
  - 팁은 한 번만 뜨거나, 그 기능을 써 볼 때까지만 뜬다.
  - 팁 개수를 제한했다.
  - 무기 해금은 캠페인 레벨 클리어에 묶어, 새 플레이어가 필요한 때 받게 했다.
- 1.73에서 팁과 툴팁을 따로 끌 수 있게 했다 [N2-04].
- Jonas는 망설이는 초보가 고를 무난한 기본 선택지를 범용적으로 만들되, 일부러 약간 약하게 둔다 [N2-05].
- 팟캐스트 요약(2차) [N2-06]:
  - 초반 레벨은 개발자에게 '바보같이 쉬운' 수준으로 맞췄다.
  - 적이 금을 떨어뜨리게 해 경제 곡선을 평탄하게 했다.

### Kingdom Two Crowns (1차)

- 게임 세계 안의 '유령' NPC가 튜토리얼을 안내한다.
- 2.0에서 유령을 끌 수 있게 했고, 덜 거슬리게 바꿨다 [N2-07].

### The King is Watching (2025, 픽셀, 1차)

- 데모 피드백(자원 수집이 답답하다)에 튜토리얼과 툴팁 설명을 보강하겠다고 답했다 [N2-09].
- 이후 튜토리얼 끝에 게임의 분위기와 한 판의 구조를 소개하는 보스전을 넣었다 [N2-08].
- 가장 낮은 난이도의 보스를 2명에서 1명으로 줄여 첫 판을 짧게 했고, 쉬운 건물부터 해금되게 했다 [N2-08].

### Kingdom Rush (2013, 제3자 분석)

- 1레벨이 튜토리얼이다. 첫 웨이브는 고블린 3마리로, 병영 하나의 병사 3명이 정확히 막는다 [Q2-b1].
- 길 옆 고정 건설 지점만 쓰게 한다 [Q2-b2].
- 다음 웨이브를 일찍 부르면 남은 초만큼 골드를 준다 [Q2-b3].
- 레벨마다 이후 레벨에서 다시 쓰일 공통 개념에 집중한다 [Q2-b4]. 모든 게임에는 쉬어 가는 레벨이 필요하다(예: 5레벨) [Q2-b5].
- 별 업그레이드(메타 진행)가 특정 웨이브를 '모욕적으로 쉽게' 만든 사례가 있다 [Q2-b6].

### Plants vs. Zombies (GDC 2012 George Fan 강연, 내용은 2차 노트로만 확인)

- 튜토리얼을 별도 메뉴가 아니라 게임플레이 안에 넣었다 [Q2-a1].
- 화면 텍스트는 한 번에 약 8단어다 [Q2-a2].
- 약 5레벨마다 새 요소 하나를 넣는다 [Q2-a3]. 첫 상점 방문에서는 하나만 살 수 있다 [Q2-a4].
- 같은 곳에서 계속 막힐 때만 힌트를 주고, 마지막에는 무엇을 하라고 알려 준다 [Q2-a5].
- 삽 튜토리얼은 네 번째 시도에서 Wall-nut 볼링 미니게임이 됐다 [Q2-a6].
- Rogue Tower 공식 공지 17건에는 튜토리얼이나 온보딩 언급이 없다 [N2-10].

## 7. 작은 게임의 범위와 가격 — Thronefall

- 2023-08 앞서 해보기로 $7에 나와, 약 두 달 만에 31.5만 장을 팔았다. 환불률 6.9%, 총매출 150만 달러를 조금 넘었다(개발사 제공 수치) [F-09].
- 1~3인 팀이라 범위를 일부러 작게 두고, 기존 시스템에 복잡도를 조금씩 얹었다 [Q2-e1].
- 기자는 싸고 작은 게임이 '왜 돈을 내야 하나'라는 의심을 넘지 못해 실패하는 일이 많다고 봤다 [Q2-e2]. Thronefall은 출시 몇 달 만에 플레이어의 35% 넘게가 5시간 이상 플레이했다 [Q2-e3].
- 정식 출시 때 가격을 올리기로 했고 [Q2-e5], 현재 $12.99다 [M2].

## 8. 출시 절차 공식 규정 (WBS 8장 관련)

| 항목 | 공식 문구 | 출처 |
|---|---|---|
| 커밍순 기간 | 새 제품은 출시 전 최소 2주 동안 Coming Soon 페이지를 띄워야 한다. 페이지 공개를 원하는 날보다 최소 7영업일 전에 심사를 요청한다 | [N2-20] |
| 상점 심사 기간 | 보통 3~5영업일 | [N2-21] |
| 등록비 후 대기 | **문서끼리 다르다.** Steam Direct 안내는 30일, 온보딩 문서는 21일('처음 몇 개 타이틀')이다 | [N2-22] |
| 등록비 | 제품당 $100. 조정 총수익이 $1,000을 넘으면 돌려받는다 | [N2-23] |

## 9. 한계

- 조사 도중 세션 전체의 웹 검색 한도가 바닥났다. 그래서 Rogue Tower 개발자 인터뷰, Kingdom 원작자(Noio)의 설계 글, Ironhide의 GDC 발표는 찾지 못했다.
- PvZ 강연 내용은 2차 노트로만 확인했다. 강연이 GDC 2012 세션이라는 것만 1차로 확인했다 [Q2-a0].
- Jonas의 Thronefall 개발 영상 [N2-12]과 팟캐스트 [N2-11]는 제목만 확인했다.
- 픽셀아트 후보는 빠짐없이 훑지 못해 더 큰 히트작을 빠뜨렸을 수 있다.
