# 01. 테마별 기믹 카드 (Q1)

라운드 테마마다 일반 적 1종, 변종 1~2종, 보스를 고를 때 쓰는 카드다. 결정은 하지 않았다.

**읽는 법**
- `[W-NN]`·`[A-NN]`·`[B-NN]`·`[C-NN]`은 [99_sources.md](99_sources.md)의 주장 ID다. **모든 웹 근거는 검색 결과 요약이다.** 이 환경의 네트워크 정책이 위키·백과 호스트를 막아 원문을 하나도 열지 못했다(README «조사 방법»). 검증 등급(✔ 교차 확인 / ○ 한 출처 / △ 출처끼리 엇갈림 / ✖ 기각)은 99의 주장 대장에 있다.
- 따옴표 안 영어는 검색 요약이 출처에서 옮겨 온 문장이다. 수치는 그 원문 그대로 두었고, 우리 게임용 제안 수치와 섞지 않았다.
- «(추론)»은 Claude의 해석이다. «우리 구현 크기»는 [07](07_sim_mapping.md)의 Claude 추정이다.
- 카드 칸 순서: ① 한 줄 규칙 ② 선례와 출처 ③ 예고 ④ 요구 대응·맡는 축 ⑤ 실패 위험(Q4, [04](04_failures.md)) ⑥ 우리 구현 크기(Q7) ⑦ 가독성 메모(Q6, [06](06_readability.md)).

**카드 목록**

| 테마 | 카드 |
|---|---|
| 슬라임 | [M01 죽으면 분열](#m01-죽으면-분열) · [M02 맞으면 졸개를 뱉음](#m02-맞으면-졸개를-뱉음) · [M03 끈끈이 장판·합체](#m03-끈끈이-장판합체) |
| 늑대 | [M04 장애물 도약](#m04-장애물-도약) · [M05 덮쳐 붙잡기](#m05-덮쳐-붙잡기) · [M06 빠른 무리·무리 보너스](#m06-빠른-무리무리-보너스) |
| 도적 | [M07 훔쳐 달아나기](#m07-훔쳐-달아나기) · [M08 원거리 저격·폭파병](#m08-원거리-저격폭파병) |
| 하늘 | [M09 낚아채기](#m09-낚아채기) |
| 공성 | [M10 공성 망치](#m10-공성-망치) · [M11 방향 방패](#m11-방향-방패) · [M12 재생과 속성 끊기](#m12-재생과-속성-끊기) |
| 예비 | [M13 언데드 부활](#m13-언데드-부활) · [M14 사망 폭발](#m14-사망-폭발) · [M15 감염·번짐](#m15-감염번짐) · [M16 밤에 커지는 습격](#m16-밤에-커지는-습격) · [M17 주민·경제를 노리는 적](#m17-주민경제를-노리는-적) · [M18 땅굴](#m18-땅굴) |

보스 기믹(내려찍기·소환·도주·순간이동)은 [03_boss.md](03_boss.md)에 있다.

---

## 슬라임

### M01 죽으면 분열

- **① 한 줄 규칙** 죽으면 작은 적 N마리가 그 자리에서 나온다. 자식은 더 갈라지지 않거나, 정해진 단계까지만 갈라진다.
- **② 선례와 출처**
  - BTD6 MOAB은 체력 "200 HP"(Fortified 400)이고 터지면 "4 Ceramic Bloons"를 낸다. MOAB의 RBE는 616이다 [W-07]. 일반 Ceramic은 체력 10(Fortified 20), RBE 104다. 같은 요약의 «체력 60(Fortified 120)»은 81라운드부터 나오는 Super Ceramic 값이다 [V3 부분 확인]. (계산) 616 = 200 + 4 × 104다. 껍데기 200은 전체의 약 32%이고, 자식 넷이 나머지 약 68%를 갖는다.
  - BTD6는 물량을 RBE로 센다. "The RBE of a single Bloon is the health of its outer layer plus the sum of the RBE of all its children, if any." BTD6 안에는 라운드의 RBE 표시가 없다 [W-08].
  - BTD6는 후반에 터뜨릴 때 주는 돈을 깎는다. 51~60라운드 50%, 61~85라운드 20%, 86~100라운드 10% 등이다. 다만 이 감액이 81라운드 뒤 프리플레이에 묶여 있다는 다른 쪽 서술과 어긋난다 [W-09].
  - Kingdom Rush Origins의 Gloomy는 스스로 복제하는 비행 적이다. "duplicates of the original one that spawns during a wave do not give any gold when killed"이다 [W-11]. Kingdom Rush 위키의 Gold 페이지는 소환·산란된 적 여럿(KR1 Necromancer가 부른 해골·해골 기사, Spider Matriarch 새끼, KRF Jungle Matriarch 새끼 등)을 «골드를 주지 않는 예외»로 적는다. 다만 KR1 Spider Hatchling은 iOS·Flash판에서 1골드를 준다 [W-12, V2 부분 확인]. Gloomy 복제본과 Spectral Knight(«they give no gold», 부모의 현상금도 줄였다는 요약)는 둘째 출처를 찾지 못했다 [W-11][W-12].
- **③ 예고** 선례 카드에 분열 예고는 없다. 분열은 죽는 순간 일어나고, 자식의 모양(작은 같은 종)이 곧 예고다(추론).
- **④ 요구 대응·맡는 축** 범위 화력이 주 담당이다. BTD6에서 RBE로 물량을 세는 것은 «자식까지 다 터뜨릴 총 피해»가 대응의 크기라는 뜻이다(추론). 우리 게임에서는 대포(`splash` 1.0)·이그니스 Q·아이아스 Q가 맡고, 단일 사격 타워·궁수는 자식 수만큼 손해를 본다(추론).
- **⑤ 실패 위험** 보상이 자식 수만큼 늘면 경제가 터진다. 선례는 «생겨난 적은 대체로 보상 0»(KR, 판마다 예외 있음) 또는 «후반 감액»(BTD6)으로 막았다 [W-09][W-11][W-12]. 분열은 처치해야 할 수를 늘려 마무리를 늘인다([04](04_failures.md) F2).
- **⑥ 우리 구현 크기** 하. 죽을 때 고리(`src/sim/battle.gd:2322`)와 `spawn_enemy`(860)가 있다. 다만 살아 있는 적이 260마리쯤이면 60fps 아래라([07](07_sim_mapping.md) 1.1) 개체 수 예산이 따로 든다. 자식 체력에도 라운드 배율이 곱해진다.
- **⑦ 가독성 메모** 자식은 같은 실루엣의 작은 판이다. 크기가 곧 «한 번 더 갈라지는가»를 알린다(추론, [06](06_readability.md)).

> **(추론) 우리 게임에 옮길 때의 제약 후보**
> - 웨이브 표의 수는 «자식까지 센 물량»으로 적는다(RBE식). 그래야 테마를 바꿔 끼워도 라운드 물량 예산(S133)이 같은 단위로 남는다.
> - 자식은 처치 보상 0(또는 아주 적게)으로 둔다. KR 위키의 예외 목록과 BTD6 Bloonarius가 같은 쪽이다.
> - 갈라지는 단계는 한 번이다. 살아 있는 적 수의 위쪽을 «부모 수 × (1 + 자식 수)»로 미리 셀 수 있다.

### M02 맞으면 졸개를 뱉음

- **① 한 줄 규칙** 맞을 때마다(또는 체력 문턱마다) 작은 같은 종을 뱉는다. 주로 보스용이다.
- **② 선례와 출처** Terraria King Slime은 "can spawn 1-3 Blue Slimes from his body upon taking damage"이다. Expert에서는 그 하나하나가 25% 확률로 Spiked Slime이다. 체력이 95% 아래로 떨어진 뒤부터 뱉는다는 서술이 있지만 한 출처뿐이다. 체력이 줄수록 "smaller and faster"가 된다. 뱉는 수의 상한은 찾지 못했다 [W-10][W-28]. 반박 검증에서 Blue·Spiked Slime을 낸다는 것은 확인했지만 «1~3마리»는 둘째 출처가 없었다 [V6]. BTD6 Bloonarius는 "each time it loses 1% of its health"마다 풍선을 뿌린다. 그 풍선은 "briefly immune to damage upon spawning and provide no cash when popped"이다 [W-26, V13 확인].
- **③ 예고** Bloonarius가 뿌린 풍선은 짙은 초록 진흙 표시가 붙는다 [W-26]. 졸개에 표시를 붙여 «보상 없는 것»을 알린다(추론).
- **④ 요구 대응·맡는 축** 보스를 치는 손(영웅·단일 사격)과 졸개를 치우는 손(범위 시설)이 둘 다 든다(추론).
- **⑤ 실패 위험** «체력 벽»과 늘어지는 마무리([03](03_boss.md)·[04](04_failures.md) F2). 선례는 졸개 보상 0과 «생겨난 직후 잠깐 무적»으로 졸개 사냥(파밍)을 막았다 [W-26].
- **⑥ 우리 구현 크기** 하~중. 체력 문턱 꼴은 분노(`raging`, 2529)와 고블린 족장 포효 소환 설계(보스 설계 §3.2)가 있다. «맞을 때마다»는 `damage`에 고리를 하나 더 단다.
- **⑦ 가독성 메모** 보스가 줄어들며 빨라지는 것(King Slime)은 체력 막대 없이도 남은 체력을 읽게 한다(추론).

### M03 끈끈이 장판·합체

- **① 한 줄 규칙** 죽은 자리에 아군을 느리게 하는 장판이 남는다 / 가까운 슬라임끼리 큰 슬라임이 된다.
- **② 선례와 출처** 이번 조사에서 직접 선례를 찾지 못했다. 가까운 것은 «한 축을 막는 장판»을 개발사가 고친 Diablo IV 1.3.1(2024-02-01)이다. Suppressor 장은 "no longer is always on. It now has a 6 second duration"이 되었고(가동률 50~75%), "can be cancelled if the monster with the affix is Stunned, Frozen, Knocked Down, or Dazed"가 되었다 [W-19, V9 부분 확인]. Path of Exile 2 0.2.0e는 Blood Cretin이 죽은 자리에 남기는 혈액 웅덩이를 6초에서 4초로 줄였다 [V8]. 합체(드래곤 퀘스트 킹 슬라임)는 검색 순위가 밀려 찾지 않았다.
- **③ 예고** 장판은 범위가 보여야 한다. Path of Exile 2 개발사가 사망 폭발의 "visibility of the area of effect"를 고쳤다는 요약이 있다(패치 번호는 확인 못 함) [W-20, V8].
- **④ 요구 대응·맡는 축** 장판 둔화는 정화(세라피나 W)가 푼다(추론). 합체는 범위 화력으로 먼저 줄이는 것이 답이다(추론).
- **⑤ 실패 위험** 늘 켜진 장판은 한 축(Diablo에서는 원거리 빌드)을 통째로 막는다. 개발사는 지속 시간을 두고 기절·빙결로 끊게 했다 [W-19].
- **⑥ 우리 구현 크기** 장판 하~중(적이 남기는 장판), 합체 중.
- **⑦ 가독성 메모** 수백 마리가 죽으며 장판을 남기면 바닥이 장판으로 덮인다. «겹치면 하나» 같은 상한이 있어야 읽힌다(추론).

---

## 늑대

### M04 장애물 도약

- **① 한 줄 규칙** 처음 만나는 장애물 하나를 뛰어넘는다. 뛴 뒤에는 느려지거나 다시 뛰려면 기다린다.
- **② 선례와 출처**
  - PvZ 장대 좀비는 "moves faster while holding its pole and can jump over the first plant it encounters"이다. 뛴 뒤에는 "slows down drastically after jumping"이다. Tall-nut은 넘지 못한다. 대응은 "use a Sunflower, Puff-shroom or other cheap plants to make them jump"(싼 미끼로 도약을 빼기), 뛰기 전에 사격으로 잡기, Tall-nut(하드 카운터)이다 [W-03].
  - Kingdom 시리즈의 Crown Stealer는 "will jump over walls and stop at nothing to get to the crown"이다. 플레이어는 "so fast that archers can hardly hit them"이라고 했다 [W-04].
  - They Are Billions 하피는 착지 공간이 있어야 하고 점프 쿨다운이 있다(이미 조사, `game_design_research/…/04_enemy_counter_matrix.md` 2.5).
- **③ 예고** PvZ 장대 좀비는 장대를 들고 있는 동안이 곧 «아직 안 뜀» 표시다(추론). 도약 직전 동작의 길이는 찾지 못했다.
- **④ 요구 대응·맡는 축** 두 갈래다. 하드는 «넘을 수 없는 벽»(Tall-nut)이고, 소프트는 «싼 미끼로 도약을 빼거나 뛰기 전에 잡기»다 [W-03]. 우리 게임에서는 성벽 위 병사가 착지 칸을 막고(CTR-06), 성 밖 타워가 뛰기 전에 잡는다(추론).
- **⑤ 실패 위험** 넘을 수 없는 벽이 하나뿐이면 그것이 정답이 된다(하드 카운터 강제, [04](04_failures.md) F1). PvZ는 미끼·사격이라는 다른 길을 함께 열어 두었다 [W-03].
- **⑥ 우리 구현 크기** 하. 기어오르기(`climb`)가 «성벽 앞 n초 → 성벽 위»라 시간만 줄이고 착지 조건을 더하면 된다. 다만 지금 코볼트(3초 기어오름)와 갈라 읽히게 해야 한다([07](07_sim_mapping.md) 2.2).
- **⑦ 가독성 메모** 도약 전 «웅크림» 자세 한 장이 예고다. 코볼트의 기어오르기와 실루엣이 달라야 한다(추론).

### M05 덮쳐 붙잡기

- **① 한 줄 규칙** 웅크렸다가 멀리 있는 한 명에게 뛰어들어 붙잡는다. 붙잡힌 쪽은 동료가 풀어 줘야 한다.
- **② 선례와 출처** Left 4 Dead Hunter는 "To do this, he has to crouch for a second beforehand"이다. 착지하면 "will pin them down and begin clawing them"이다 [A-01]. 붙잡은 동안 피해는 "5 Damage every half-second"(쉬움·보통·Versus·Survival), 10(Advanced), 15(Expert)이다. 높은 데서 덮치면 충격 피해가 최대 25다(높이냐 거리냐는 위키와 커뮤니티가 엇갈림) [A-02]. Versus에서 덮칠 때 근처 생존자를 약 1초(Survival은 약 2초) 비틀거리게 한다 [A-03]. 동료가 밀쳐(shove) 풀어 주고, 밀려난 Hunter는 약 1초 뒤 다시 덮칠 수 있다 [A-04].
- **③ 예고** 보이는 것은 웅크림이다 [A-01]. 반박 검증에서 소리 예고를 찾았다. 웅크릴 때 높은 울음이나 비명, 덮칠 때 큰 비명이다(위키 한 곳과 질 낮은 팬 사이트). «약 1초»는 둘째 출처가 없다 [V11 부분 확인].
- **④ 요구 대응·맡는 축** «혼자 다니지 않기»와 «동료가 풀어 주기»다. 우리 게임에서는 붙잡힌 궁수를 근처 병사·영웅 기절이 풀어 준다(추론).
- **⑤ 실패 위험** 조작을 빼앗는 기믹이다. Hunter 자체에 대한 플레이어 반응 자료는 찾지 못했다. 같은 계열(낚아채기·고정)의 반응은 [M09](#m09-낚아채기)와 [04](04_failures.md) F4에 있다.
- **⑥ 우리 구현 크기** 중. 보스 스킬 틀(예고·끊기)과 직선 예고가 있다. 성벽 3줄을 넘어 성 안에 내리는 이동과 «붙잡힘» 상태가 새로 든다([07](07_sim_mapping.md) 2.2).
- **⑦ 가독성 메모** 1초 웅크림은 16px에서 몸이 낮아지는 1~2px 차이다. 표적 표시(누구를 노리는지)가 따로 있어야 할 수 있다(추론).

### M06 빠른 무리·무리 보너스

- **① 한 줄 규칙** 체력이 낮고 아주 빠른 짐승이 떼로 온다. 근처 동족이 많을수록 세진다(무리 보너스).
- **② 선례와 출처** Kingdom Rush Wulf는 HP "28/35/42", 피해 "1–3", 속도 "Fast (2.5)", 현상금 5이고 "among the fastest enemies in Kingdom Rush"다. 회피 확률은 위키끼리 25%와 30%로 엇갈린다 [A-05]. Worg는 "essentially a stronger version of wulves"이고 HP "96/120/144", 마법 저항 "Medium (50%)"라 마법 타워가 잘 안 먹힌다 [A-06]. Kingdom Rush 캠페인 분석 글은 Farmlands에 새 적이 "only one new enemy type"(Wulves)이라고 적는다 [W-16]. Dota 2는 7.41에서 Lycan 늑대 수를 "from 3 to 2"로 줄였다 [A-07]. **무리 보너스(동족 수 비례)의 선례는 찾지 못했다.**
- **③ 예고** 해당 없음. 빠르기 자체가 위협이다.
- **④ 요구 대응·맡는 축** 근접 저지(병사)로 발을 묶는다. 마법 저항이 있으면 물리 시설이 낫다(추론, [A-06]).
- **⑤ 실패 위험** 무리 보너스는 근거가 없다. 넣는다면 우리 쪽 설계 가정이다.
- **⑥ 우리 구현 크기** 무리 출현 하~중(`wave_plan` 묶기), 무리 보너스 하(칸 버킷으로 세기).
- **⑦ 가독성 메모** 네발 짐승은 사람형 적과 실루엣이 다르다. 그래서 테마 구분이 쉽다(추론, [06](06_readability.md)).

---

## 도적

### M07 훔쳐 달아나기

- **① 한 줄 규칙** 자원(또는 지켜야 할 것)을 집어 들고 나가는 곳으로 달아난다. 도중에 잡으면 떨어뜨리고, 되찾을 수 있다.
- **② 선례와 출처**
  - Defense Grid는 외계인이 발전기에 닿으면 "steal power cores ... attempt to escape with the cores by making it to an exit location"이다. 운반자가 죽으면 "the cores are dropped, and will slowly float back to their central holder"이고, 돌아가는 도중 "can be grabbed by an alien"이다. "Only one power core needs to remain"이면 지지 않는다. 적 종류마다 드는 수가 다르다(Racer 1, Rumbler 3, Bulwark 2, Spire 3, 다른 요약 기준). "If an air unit captures a core, it is unrecoverable"이다 [W-01].
  - Kingdom Two Crowns의 Greed는 "can take coins from the monarch, and if the player has no remaining coins, the Greed can steal the monarch's crown, causing a game over"이다. 성벽이 지키지 않는 마을 주민의 동전·장비도 빼앗는다 [W-05]. Greedling은 물건을 들면 물러나고 "if a greedling carrying an item is killed, it vanishes, and drops the object on the ground, which can then be recovered"이다 [W-04].
  - 팬 위키에 따르면 Monster Hunter의 Melynx는 원래 훔친 뒤에도 계속 공격해 인벤토리를 비울 수 있었다. "After some personal testing, Ryozo Tsujimoto requested that this be changed such that a Melynx would immediately retreat after stealing a single item."이다. 위키가 출처를 밝히지 않아 1차 인터뷰는 확인하지 못했다 [W-21, V5].
  - 반박 검증은 Defense Grid의 «떨어짐 → 천천히 떠서 귀환 → 다른 적이 다시 주울 수 있음»을 확인했다. 운반량은 1~3개다. «비행 유닛이 가져가면 되찾을 수 없음»은 둘째 출처가 없다 [V4 부분 확인].
- **③ 예고** 들고 있는 것이 보인다(코어·동전). 들고 있는 동안이 곧 «아직 되찾을 수 있음»이다(추론).
- **④ 요구 대응·맡는 축** 나가는 길목의 사격과 발 묶기다. Defense Grid는 «떨어뜨린 것이 저절로 되돌아감»으로 플레이어의 회수 조작을 없앴다 [W-01]. 우리 게임에서는 성 밖 타워·궁수·실비아 덫·빠른 영웅이 맡는다(추론).
- **⑤ 실패 위험** 자원을 빼앗는 적은 개발사가 «한 번에 하나, 바로 퇴각»으로 묶었다 [W-21]. 하늘로 들고 가면 되찾을 수 없는 규칙(Defense Grid)은 «대공이 없으면 영구 손실»이라 하드 카운터가 된다 [W-01]. 자세한 것은 [04](04_failures.md) F3.
- **⑥ 우리 구현 크기** 상. 목표를 집·생산 시설로 바꾸고, 든 골드를 달고, 출현 줄로 도망가는 경로가 모두 새로 든다([07](07_sim_mapping.md) 2.3).
- **⑦ 가독성 메모** 든 것(금 자루)을 머리 위에 그리면 «잡을 놈»이 읽힌다. 금빛은 우리 무드보드에서 지휘관 색(금)과 겹칠 수 있다(추론, `source_mood_research/README.md` 무드보드).

### M08 원거리 저격·폭파병

- **① 한 줄 규칙** 성벽 밖에 멈춰 성벽 위를 쏜다 / 성문에 폭약을 놓고 도화선 뒤 터뜨린다.
- **② 선례와 출처** 이번 조사에서 새로 찾은 것은 없다. 성벽 너머 공격(TAB Venom·Giant)은 지난 조사에 있다(`04_enemy_counter_matrix.md` 2.5, CTR-06). Clash of Clans Wall Breaker·WC3 Goblin Sapper·OMD 새퍼는 검색 한도 때문에 찾지 않았다.
- **③ 예고** 근거 없음. (추론) 폭파병 도화선은 보스 예고 틀을 쓰는 첫 일반 적이 된다.
- **④ 요구 대응·맡는 축** (추론) 원거리 적은 성 밖으로 나가는 병사·영웅이, 폭파병은 성문 위 사격이 맡는다.
- **⑤ 실패 위험** (추론) 수백 마리의 일반 적이 모두 예고를 띄우면 보스 예고가 묻힌다([03](03_boss.md) 2장).
- **⑥ 우리 구현 크기** 원거리 상(적 사거리 + 아군을 노리는 투사체), 폭파병 중.
- **⑦ 가독성 메모** 원거리 적은 들고 있는 무기(석궁) 실루엣으로 갈린다(추론).

---

## 하늘

### M09 낚아채기

- **① 한 줄 규칙** 하늘에서 내려와 아군 하나를 들고 간다. 들고 가기 전이나 도중에 끊으면 풀려난다.
- **② 선례와 출처**
  - PvZ 번지 좀비는 "drops from the sky to drop a zombie or steal a random plant from the lawn"이다. 예고는 "An arrow with a bullseye appears in the sky and falls onto the intended target"이고, 고음의 외침과 함께 내려온다. "he hovers over his victim for 3 seconds, during which time he can be frozen, paralyzed, attacked, and/or killed"이다. 체력은 "absorbs 450 damage"다. Umbrella Leaf가 "protects itself and up to eight plants surrounding it"이다. 레벨 5-2 첫 등장 때 빼앗긴 식물을 다시 심으라는 안내가 나온다 [W-02][W-23]. 마커가 뜬 뒤 내려오기까지 «약 1초»는 출처마다 달라 확인되지 않았다 [W-02].
  - 반박 검증은 Bungee가 식물을 훔치는 것과 Umbrella Leaf의 3×3 보호를 확인했다. 과녁 표시·3초 머무름·450 피해는 둘째 출처가 없다(같은 위키일 수 있음) [V1 부분 확인].
  - Kingdom 시리즈의 Floater는 "a flying insect-like greed monster that can abduct and consume up to three townspeople"이다 [W-04]. 같은 위키 페이지(원작 Kingdom 계열의 옛 판) 뒤쪽에는 "once two subjects are captured, the floater turns back towards the nearest portal"이라고도 적혀 있다. Two Crowns 고유 수치는 찾지 못했다 [V10 엇갈림]. 리뷰어는 "the floaters (who steal soldiers and carry them away forever) still give me trouble"이라고 썼다 [W-22].
  - Vermintide 2 Packmaster(갈고리로 끌고 감)는 공략 사이트 한 곳의 요약뿐이다. "Packmasters can't be staggered or pushed (except with bombs or some hero abilities)"이다. 잡기 동작이 시작될 때 옆으로 피하라고 한다. 전용 경고음은 확인하지 못했다 [W-06].
- **③ 예고** PvZ: 표적 위 과녁 화살 → 내려옴 → 3초 머무름 [W-02]. Packmaster: 잡기 동작 [W-06].
- **④ 요구 대응·맡는 축** PvZ는 둘로 나눈다. 시설은 Umbrella Leaf(3×3 보호)이고, 끊기는 3초 안에 얼리기·마비다 [W-02][W-23]. (추론) 우리 게임에서는 «3초 머무름» 동안 끊기(아이아스·이그니스)·격추(궁수·타워)가 되고, 막는 시설은 아직 없다.
- **⑤ 실패 위험** «영원히 데려감»이 불만의 핵심이다 [W-22]. 공략 쪽 반응은 배치를 잘못하면 "frequent stealing of your plants"가 생긴다는 정도다. 번지 좀비를 싫어하는 포럼 글은 찾지 못했다 [W-23]. 자세한 것은 [04](04_failures.md) F4.
- **⑥ 우리 구현 크기** 상. 유닛의 «들림» 상태가 명령·성벽 위·블록 상태를 모두 풀어야 한다([07](07_sim_mapping.md) 2.4).
- **⑦ 가독성 메모** 표적 위 표시(과녁)가 예고다. 밤에는 숨은 적의 예고를 그리지 않으니(S213) 표적 쪽(아군)에 표시를 그려야 보인다(추론).

> **(추론) 우리 게임에 옮길 때의 제약 후보**
> - 들린 용병은 영구 손실이 아니다. 떨어뜨리거나, 운반자를 잡으면 그 자리에 돌아온다.
> - 표적 위에 머무는 시간(PvZ 3초)을 예고로 두고, 그동안 기절·빙결·격추로 끊긴다. 보스 공통 규칙(«예고 중 기절하면 취소»)과 같은 꼴이다.
> - 영웅은 들지 않는다(CTR-10: 영웅이 하드 체크의 유일한 해법도 피해자도 되지 않게).

---

## 공성

### M10 공성 망치

- **① 한 줄 규칙** 유닛을 무시하고 건물(성문)만 친다. 화살에 강하고 근접에 약하다.
- **② 선례와 출처** Age of Empires II 망치는 "-3 melee and 180 pierce armor and 175 hit points"이고 "useless against anything that isn't a building or siege engine"이다. "A Villager deals 6 damage per hit to you, killing you in 30 hits."이고 "The best ways to destroy them are with Mangonels or cavalry."다 [A-09]. 망치에 보병을 태우면 속도·공격이 오른다. 태우는 수는 Liquipedia 4명, TV Tropes 6명으로 엇갈린다. TV Tropes는 2023년 6월 패치로 4→6이 되었다고 쓴다 [A-10]. Stronghold·Total War 망치는 찾지 못했다.
- **③ 예고** 해당 없음. 느리게 다가오는 것 자체가 예고다(추론).
- **④ 요구 대응·맡는 축** AoE2에서는 원거리(화살)가 무력하고 근접·기병이 정답이다 [A-09]. (추론) 우리 게임에서는 «근접에 약함»이 «성문 밖으로 나가 치는 병사·영웅»을, «화살에 강함»이 «성벽 사격 무력»을 뜻한다. 대신 마법(장갑 무시)이 시설 쪽 예비 경로가 된다(CTR-10).
- **⑤ 실패 위험** 몸으로 막을 수 없으면 용병 저지가 통하지 않는다. 그러면 시설 쪽 예비 경로가 꼭 있어야 한다(CTR-10, 추론).
- **⑥ 우리 구현 크기** 하. 3라운드부터 땅 적이 가까운 성문을 먼저 노린다(`via`, S143). «몸으로 막은 유닛도 치지 않음» 칸만 더한다([07](07_sim_mapping.md) 2.5).
- **⑦ 가독성 메모** 크고 네모난 실루엣이라 무리 속에서 읽힌다(추론).

### M11 방향 방패

- **① 한 줄 규칙** 정면에서 오는 원거리 공격을 확률로 막는다.
- **② 선례와 출처** Total War: Warhammer의 일반 방패(Shielded)는 "blocking a percentage of small missiles hitting from the front"이고 "5 tiers"가 있다 [A-11]. 정면 판정 반각 60°(전체 120°), 1편 청동 30%·은 50%, 실제 막기 계산식은 모두 포럼 값이다 [A-11]. Warhammer III 5.0.0의 Directional Shield 속성은 "Units with the Directional Shield attribute have 360 degree missile block, but the unit's base missile block is multiplied as follows"이고 정면 1.0x·측면 0.5x·후면 0.1x다. 위키의 «70%(정면)·35%(측면)·7%(후면)»는 이 속성을 가진 **한 유닛의 예시**이지 방패 기본값이 아니다 [A-12]. 6.1 패치는 배율이 아니라 유닛별 막기 확률을 고쳤다(예 "Swordmasters of Hoeth - … Missile Block Chance %: 20 -> 30") [A-12].
- **③ 예고** 해당 없음.
- **④ 요구 대응·맡는 축** 옆·뒤에서 쏘거나 방패를 무시하는 공격이다(Shieldbreaker 효과 문서가 있다는 것만 확인) [A-12]. (추론) 우리 성은 성벽이 남쪽에 일자로 있고 적은 남쪽에서만 온다. 그래서 성벽 위 사격은 늘 정면이다. «정면 원거리 감소»는 사실상 «성벽 사격 감소»가 된다.
- **⑤ 실패 위험** (추론) 옆으로 돌 수 있는 것은 영웅·용병뿐이라, 방패 적은 «성 밖으로 나가라»는 요구가 된다. 시설만으로 버티는 플레이를 막는 소프트 체크다.
- **⑥ 우리 구현 크기** 중. 적에게 앞 방향이 없다. 경로의 다음 칸 쪽을 앞으로 셀 수 있다([07](07_sim_mapping.md) 2.5).
- **⑦ 가독성 메모** 방패를 든 실루엣이 곧 표시다. 지금 오크(장갑) 그림에 방패를 더하는 꼴이다(추론).

### M12 재생과 속성 끊기

- **① 한 줄 규칙** 체력이 계속 찬다. 특정 속성(불·산)에 맞으면 잠깐 재생이 멈춘다.
- **② 선례와 출처** D&D 5e 트롤은 "regains 10 hit points at the start of its turn"이다. 산이나 불 피해를 받으면 "the trait doesn't function at the start of the troll's next turn"이다. "The troll dies only if it starts its turn with 0 hit points and doesn't regenerate."다(요약이 의역이라고 밝힘) [A-13]. BTD6 Lych는 "1.5% of max HP every 9 seconds"를 회복하고, 12초마다 둘레의 타워 버프를 빨아 체력을 채운다 [W-27]. Diablo IV는 Vampiric 접사의 치유 상한을 월드 티어마다 약 반으로 줄이고(WT I 10→5%, II 20→10%, III 35→15%, IV 50→25%) 치유하는 투사체에 시각 효과를 더했다 [W-19, V9]. WC3 트롤 재생은 찾지 못했다.
- **③ 예고** Diablo IV는 치유가 보이게 했다 [W-19].
- **④ 요구 대응·맡는 축** 끊는 속성을 가진 수단이다. (추론) 우리 게임에서 불은 이그니스 Q(발화)와 베스퍼 R(화상)뿐이라, 재생 적은 영웅 둘에 묶인다. 시설에 불이 없으면 CTR-07·CTR-10과 부딪친다.
- **⑤ 실패 위험** 치유 상한이 없으면 화력이 낮은 빌드가 막힌다. Diablo IV는 상한을 줄였다 [W-19].
- **⑥ 우리 구현 크기** 하. `_heal`(1269)과 발화 fx(`ignis_q`)가 있다.
- **⑦ 가독성 메모** 재생 중 초록 반짝임, 불붙으면 끊김이 보여야 한다(추론).

---

## 예비 테마

### M13 언데드 부활

- **① 한 줄 규칙** 쓰러진 적이 다시 일어난다. 부활시키는 쪽을 잡거나 특정 수단으로 마무리해야 끝난다.
- **② 선례와 출처**
  - Diablo II Fallen Shaman은 쓰러진 Fallen을 되살린다. "there doesn't seem to be a limit to how many deaths a monster can suffer before it can't be revived anymore"(커뮤니티 위키)이고, "shamans are limited to their own subspecies' followers"다. "it is wise to dispatch the Shaman before attacking their Fallen underlings"이다 [A-14]. 대응은 샤먼 먼저 잡기, 꾀어내 따로 잡기, 시체 없애기(얼려 깨기, "Slain Monsters Rest in Peace" 접사)다 [A-15].
  - Dark Souls 카타콤의 해골은 주인 네크로맨서에 묶여 있다. 네크로맨서를 잡으면 "they will not respawn and the Skeletons they control will not revive even if killed without a Holy weapon"이다. 네크로맨서는 "only six of them"이다 [A-16]. 타격 무기는 맞을 때마다 해골을 무너뜨린다 [A-17].
  - Slay the Spire Darkling은 처음 0이 되면 2턴 동안 고를 수 없고, 그 뒤 "revives with 50% HP (if at least one Darkling is still alive)"이다. 한 Steam 사용자는 "super-lame"이라고 했다 [W-24].
  - BTD6 Lych는 해골 표시마다 «영체»가 되어 고를 수도 맞힐 수도 없고, "will immediately stop being ethereal as soon as all Lych-souls are popped"이다 [W-27].
  - Kingdom Rush의 Spectral Knight는 죽은 Fallen Knight에서 일어나고 골드가 없다 [W-12]. KR 묘지 단계는 인간형만 되살리는 것으로 보인다(Wulf 문서 «개과라서 되살아나지 않음» 메모에서 한 추론) [A-05].
- **③ 예고** 선례 카드에 부활 예고의 길이는 없다. Darkling은 쓰러진 몸이 «고를 수 없는 상태»로 남는 것이 예고다 [W-24].
- **④ 요구 대응·맡는 축** 개체 수는 «횟수 상한»이 아니라 **재료**로 막는다. 재료는 시전자(샤먼·네크로맨서), 시체, 같은 무리의 생존 조건이다 [A-14][A-16][W-24]. (추론) 우리 게임에서는 시전자를 노리는 원거리 시설·봉인, 시체를 지우는 범위 화력, 신성(교회·세라피나 정화)이 맡는다.
- **⑤ 실패 위험** 마무리가 늘어진다(F2). «처치 시 효과는 마지막 개체를 죽일 때만 들음»이 직관에 어긋난다는 반응이 있다 [W-24].
- **⑥ 우리 구현 크기** 중. 뼈 더미 상태와 다시 일어나는 시계, 웨이브 끝 판정이 든다([07](07_sim_mapping.md) 2.6).
- **⑦ 가독성 메모** 뼈 더미가 «아직 남은 적»으로 읽혀야 한다. 밤에는 숨은 적처럼 안 그리면 웨이브가 왜 안 끝나는지 모른다(추론).

### M14 사망 폭발

- **① 한 줄 규칙** 죽을 때 둘레를 터뜨려 가까운 아군(근접 병사)을 다치게 한다.
- **② 선례와 출처**
  - 한 검색 요약은 Kingdom Rush의 Abomination이 "On death, one will explode in an area (scope: 200) for 250 True Damage, which can easily destroy barracks troops"라고 적었다 [A-21]. **반박 검증에서는 이 수치를 찾지 못했다**(판단 불가). Frontiers에서 죽을 때 터져 병사를 잡는 적으로는 Saurian Blazefang이 있다. "When a Saurian Blazefang dies, its gun explodes, dealing 200 physical damage in a small radius"이고, 공략은 Assassin 병사도 "will almost certainly die from the death explosion"이라고 한다. 두 적의 수치가 섞였을 수 있다 [V12].
  - KR 악마 계열(Demon Spawn·Demon Hound·Demon Lord)도 "explode on death and deal big damage to your barracks troops"(TV Tropes 요약)이다. 폭발 피해 수치와 지연·예고는 찾지 못했다 [A-20].
  - Path of Exile 2: 한 요약은 0.2.0e 노트가 "many players have been reported being overwhelmed by monsters"라며 사망 폭발의 범위를 줄이고 "the visibility of the area of effect has also been improved"했으며, 엔드게임에서 "disabled a certain on-death effect where the telegraphing was not as clear as it should have been"이라고 했다 [W-20]. 반박 검증은 0.2.0e 노트에서 이 «껐다» 문구를 찾지 못했다. 찾은 것은 0.2.0e의 «Blood Cretin 사망 웅덩이 6초 → 4초»와, 앞선 0.2.0 Hotfix 7(2025-04-05)의 "temporarily disabled Volatile Boar as a Spectre, until we can make it not repeatedly explode without actually dying"(소환수 한정)이다 [V8 판단 불가].
- **③ 예고** 개발사가 사망 효과를 줄이거나 일부를 껐다 [V8]. 선례 카드에서 지연 길이는 찾지 못했다.
- **④ 요구 대응·맡는 축** 근접 병사가 마무리하지 않게 원거리 시설로 잡는다(추론).
- **⑤ 실패 위험** 수가 많을 때 사망 효과는 개발사가 줄이거나 끈다 [W-20, V8]. 근접 병사가 마무리하면 손해를 본다 [V12]. 우리 물량(웨이브 수백 마리)에서는 가장 조심할 기믹이다(추론, [04](04_failures.md) F5).
- **⑥ 우리 구현 크기** 하(죽을 때 고리).
- **⑦ 가독성 메모** 터질 범위를 죽기 전부터 몸에 보이는 표시(부푼 몸·빛)로 둔다(추론).

### M15 감염·번짐

- **① 한 줄 규칙** 적이 건물에 들어가면 그 건물이 적을 내보내는 곳이 된다.
- **② 선례와 출처** They Are Billions는 "Each building has a defense rating, which once it expires allows zombies to enter the building and infect it."이고 감염 건물은 "produces enemies equivalent to the number of workers/colonists occupying the building initially"다(예: Tent → 2) [A-18]. "a single zombie left unattended can trigger a colony collapse"이고, 플레이어는 "1 to 2, 2 to 10, 10 to 100" 연쇄를 겪었다고 쓴다. «감염 메커니즘을 고쳐야 한다»는 스레드가 있다 [A-19]. 감염 상한·예산은 찾지 못했다. 불 번짐 선례는 찾지 않았다.
- **③ 예고** 근거 없음.
- **④ 요구 대응·맡는 축** 성 안에 한 마리도 들이지 않기, 거주 건물 둘레 방어(추론).
- **⑤ 실패 위험** 연쇄 붕괴가 한순간에 판을 끝낸다 [A-19]. (추론) 우리 게임은 주민 ④(다침·죽음)가 들어오는 중이라, 감염은 주민 규칙과 함께 정해야 한다.
- **⑥ 우리 구현 크기** 중~상(구조물 상태 + 번짐).
- **⑦ 가독성 메모** 감염된 건물 표시가 필요하다(추론).

### M16 밤에 커지는 습격

- **① 한 줄 규칙** 정해진 밤에 평소보다 큰 습격이 온다.
- **② 선례와 출처** Kingdom Two Crowns 블러드문은 평소보다 훨씬 큰 Greed 습격이 오는 밤이다. 적을 다 잡아야 끝나고, 공격은 한 방향에서 온다. 회차가 쌓이면 구성이 바뀐다(greedling 위주 → floater 추가 → breeder·crown stealer 추가). 다음 밤은 쉰다(요약 문장, 원문 인용 없음) [A-22]. 주기는 출처마다 다르다(위키 «day V or VI» 뒤 6·8일 번갈아, 공략 «roughly every 10 days», 시즌마다 등). 시각 예고(붉은 하늘)는 찾지 못했다 [A-23]. **밤에만 개체가 강해지는 선례는 찾지 못했다.** (추론) 블러드문은 «개체를 세게»가 아니라 «수와 구성을 크게» 한다.
- **③ 예고** 소리(우르릉)는 스팀 댓글뿐이다 [A-23].
- **④ 요구 대응·맡는 축** 그 밤에 맞춘 보강(추론). 우리 게임은 웨이브마다 밤을 둘 수 있다(S210). 다음 웨이브가 밤이면 미리 알린다(S214).
- **⑤ 실패 위험** 근거 없음.
- **⑥ 우리 구현 크기** 하(`dark`에 수치를 곱함).
- **⑦ 가독성 메모** 밤에는 불빛 밖 적을 숨긴다(S213). 밤에 강해지는 적은 숨는 것과 겹쳐 두 겹으로 어렵다(추론).

### M17 주민·경제를 노리는 적

- **① 한 줄 규칙** 방어선이 아니라 주민·값진 것·경제 건물을 노리고, 챙기면 떠난다.
- **② 선례와 출처** Kingdom Two Crowns의 Greed는 "If the villagers are not protected by walls, the Greed can steal their coins and equipment"이다 [W-05]. RimWorld 포럼은 습격자가 "stealing items and kidnapping colonists are actually primary goals"라고 주장한다(위키가 틀렸다는 글). 반론도 있다 [A-24]. 플레이어 불만 스레드 제목은 "\"Raiders have decided to kidnap who they can and leave\" Fine, then quit attacking me!"다 [A-25].
- **③ 예고** 알림 문구(RimWorld)뿐이다 [A-25].
- **④ 요구 대응·맡는 축** 성벽으로 마을을 지키기 [W-05], 값진 것을 안쪽에(추론).
- **⑤ 실패 위험** 납치·약탈의 반응은 엇갈린다. 쉽다고 여기는 쪽과 싫어하는 쪽이 있다 [A-25].
- **⑥ 우리 구현 크기** 중. 주민 ④가 들어온 뒤에야 판정이 생긴다([07](07_sim_mapping.md) 2.6).
- **⑦ 가독성 메모** 노리는 대상(집)에 표시가 필요하다(추론).

### M18 땅굴

- **① 한 줄 규칙** 땅속으로 다니는 동안 사격을 받지 않는다.
- **② 선례와 출처** 이번 조사에서 KRF Dune Terror 말고 다른 선례를 찾지 못했다. Dune Terror는 지난 조사에 있다(`04_enemy_counter_matrix.md` 2.2, CTR-03).
- **③~⑦** 지난 조사와 [07](07_sim_mapping.md) 2.6(중)을 따른다.
