# 04. 실패·불만 사례와 개발사 수정 (Q4)

분열·부활·훔치기·낚아채기·장판·치유·소환·도주 같은 기믹이 «짜증»이 된 사례와, 개발사가 어떻게 고쳤는지 모았다. 기믹마다 «넣을 때 지킬 제약»을 뽑는 데 쓴다.

- 웹 근거는 모두 검색 요약이다(README «조사 방법»). 출처 성격(공식 패치 노트 / 위키 / 공략 / 포럼 한 건 / 리뷰)을 문장마다 적었다. **포럼 글 한 건이나 리뷰 한 건에 기댄 것이 많다.**
- 지난 조사의 실패 사례(KR5 Dragon Wars 즉사 면역 «벽», KR5 Abominor 타워 파괴 → 잔해 복구, BTD6 camo 탐지 경로 수정, Thronefall 범용 유닛 지배)는 `game_design_research/01_rules_architecture/04_enemy_counter_matrix.md` 4·6장과 `04_benchmarks/02_success_and_failure_factors.md`에 있다. 여기서는 반복하지 않는다.

## F1. 하드 카운터를 강제한 경우

| 사례 | 무엇이 문제였나 | 고친 것 | 근거 |
|---|---|---|---|
| Diablo IV Suppressor(장판) | 늘 켜진 장이 원거리·투사체 빌드를 막았다(2차 보도 요약) | "no longer is always on. It now has a 6 second duration"(가동률 50~75%), "can be cancelled if the monster with the affix is Stunned, Frozen, Knocked Down, or Dazed" | 공식 패치 노트 재게재 [W-19, V9 부분 확인] |
| Defense Grid 비행 운반자 | "If an air unit captures a core, it is unrecoverable" — 대공이 없으면 영구 손실 | 수정 기록은 찾지 못했다 | 다른 요약(Giant Bomb·HandWiki) [W-01]. 반박 검증에서 둘째 출처 없음 [V4] |
| PvZ 번지 좀비 | 막는 시설은 Umbrella Leaf 하나(3×3 보호) | 끊기(3초 머무는 동안 얼리기·마비)를 함께 열어 둠. 싫어한다는 포럼 글은 찾지 못함 | 위키 [W-02][W-23] |
| PvZ 장대 좀비 | 넘지 못하는 것은 Tall-nut 하나 | 싼 미끼로 도약을 빼거나 뛰기 전에 사격하는 길이 같이 있음 | 위키 [W-03] |
| BTD6 Vortex | 해골 표시마다 "stuns nearby towers" | 공략은 타워를 멀리 두라고 한다(가까이 두면 정답이 깨짐) | 위키 요약 [W-25] |

(추론) 개발사가 고친 방향은 둘이다. ① 늘 켜진 것을 «짧은 창»으로 바꾼다. ② 영웅의 기절·빙결 같은 끊기로 그 창을 닫게 한다. PvZ는 처음부터 «시설 하나 + 끊기»를 같이 열었다. 지난 조사의 CTR-10(«하드 체크마다 다른 축의 예비 경로»)과 같은 결론이다.

## F2. 분열·부활·소환 때문에 마무리가 늘어진 경우

| 사례 | 무엇이 문제였나 | 고친 것·막는 법 | 근거 |
|---|---|---|---|
| Slay the Spire Darkling | 동료가 살아 있으면 "revives with 50% HP". 처치 시 효과 카드는 마지막 개체를 죽일 때만 듣는다 | 개발사 수정은 찾지 못함. 공략은 한꺼번에 빨리 끝내라고 함. 한 사용자는 "super-lame" | 위키 + Steam 토론 [W-24] |
| BTD6 Bloonarius | 체력 1%마다 풍선을 뿌린다 | 뿌린 풍선은 "briefly immune to damage upon spawning and provide no cash when popped" | 위키 요약 [W-26, V13 확인] |
| BTD6 Lych | 해골 표시마다 영체(무적)가 된다 | "will immediately stop being ethereal as soon as all Lych-souls are popped" — 끝내는 목표를 따로 준다. 54.0(2026년 4월)에서 크게 고쳤지만 내용은 못 봄 | 위키 요약 [W-27] |
| Diablo II Fallen Shaman | 부활 상한이 "doesn't seem to be a limit" | 샤먼 먼저 잡기, 시체 없애기 | 커뮤니티 위키 [A-14][A-15] |
| Kingdom Rush 시리즈 | 죽음·소환에서 생긴 적이 많다 | 위키 Gold 페이지가 소환·산란된 적 여럿을 «골드 없음» 예외로 적는다. 판마다 다르다(KR1 Spider Hatchling은 iOS·Flash판 1골드) | 위키 [W-11][W-12, V2 부분 확인] |
| 우리 게임(1단계 전) | 오우거가 혼자 30초 넘게 병사를 지우며 걸었다(«체력 벽») | 보스 스킬 + 예고로 «대응 요구»를 만듦 | `insights/2026-10-22_boss_design.md` §1 |

(추론) 막는 법은 넷이다. ① 생겨난 적의 보상 0(파밍 막기). ② 부활의 «재료»(시전자·시체·무리 생존)를 두고, 재료를 지우는 수단을 준다. ③ 끝내는 목표를 보이게 한다(Lych의 영혼). ④ 생겨난 직후 잠깐 무적으로 «태어나자마자 범위 피해에 증발»을 막는다(Bloonarius). ④는 오히려 마무리를 늘인다는 점에서 ①과 짝이다.

## F3. 보상·자원을 빼앗는 적

| 사례 | 무엇이 문제였나 | 고친 것·막는 법 | 근거 |
|---|---|---|---|
| Monster Hunter Melynx | 원래 훔친 뒤에도 계속 공격해 인벤토리를 비울 수 있었다 | "Ryozo Tsujimoto requested that this be changed such that a Melynx would immediately retreat after stealing a single item." Rise에서는 Felvine을 들고 있으면 늘 그것을 훔친다(미끼). 한 댓글은 둥지를 뒤지게 만든다며 "complete dogshit" | 팬 위키(개발 일화, 1차 인터뷰 못 찾음) + 댓글 한 건 [W-21, V5] |
| Kingdom Two Crowns Greed | 동전이 없으면 왕관을 빼앗아 게임 오버 | 왕관을 잃어도 "the player continues as a new monarch called the "heir"" | 위키 요약 [W-05] |
| Defense Grid | 리뷰어는 무리가 한 마리만 살아 있어도 떨어진 코어를 다시 집어 간다는 위험을 지적 | 떨어진 코어는 "slowly float back to their central holder" | 위키·리뷰 요약 [W-01] |
| Kingdom Two Crowns Floater | "the floaters (who steal soldiers and carry them away forever) still give me trouble" | 수정은 찾지 못함. 1.1.16 업데이트에 Greed 출현율을 고르는 난이도를 더함 | 리뷰 한 건 + 보도 [W-22] |
| RimWorld 납치 | 알림 "Raiders have decided to kidnap who they can and leave"에 대한 불만 스레드 | 모드로 «떠나지 않게» 바꾸는 사람도 있다. 반응이 엇갈린다 | 포럼 한 건 + 모드 [A-25] |

(추론) 개발사 쪽 제약은 셋이다. ① 한 번에 하나만 가져가고 바로 달아난다(Melynx). ② 떨어뜨린 것은 저절로 돌아오거나 줍기 쉽다(Defense Grid·Greedling [W-04]). ③ 잃어도 판이 끝나지 않는다(Kingdom 상속). 영구 손실이 불만의 핵심이다.

## F4. 조작을 빼앗는 기믹(붙잡기·낚아채기·기절)

| 사례 | 반응·대응 | 근거 |
|---|---|---|
| Kingdom Two Crowns Floater | 병사를 «영원히» 데려가는 것이 불만 | 리뷰 한 건 [W-22] |
| Vermintide 2 Packmaster | 잡기 동작이 시작될 때 옆으로 피한다. "Packmasters can't be staggered or pushed (except with bombs or some hero abilities)" — 끊기가 영웅 쪽에만 있다 | 공략 사이트 한 곳, 신뢰도 낮음 [W-06] |
| Left 4 Dead Hunter | 1초 웅크림 예고, 동료가 밀쳐 풀어 줌. L4D2에서 덮친 직후 밀쳐도 안 떨어지는 구간은 커뮤니티 플러그인이 고치려는 문제로 적혀 있다. 플레이어 반응 자료는 못 찾음 | 위키 + 포럼(모드) [A-01][A-04] |
| PvZ 번지 좀비 | 3초 머무름 동안 끊김. 싫어한다는 포럼 글은 못 찾음 | 위키 [W-23] |
| BTD6 Vortex | 타워 기절 → 배치를 바꾸라는 공략 | 위키 요약 [W-25] |

(추론) 근거가 얇다. 그래도 공통점은 둘이다. ① 예고(웅크림·과녁·3초)가 있고 그동안 끊을 수 있다. ② 빼앗긴 것을 되찾을 수 있다(동료가 풂). 영구 손실(Floater)만 불만으로 남았다.

## F5. 사망 효과·장판이 많아 화면이 읽히지 않는 경우

| 사례 | 고친 것 | 근거 |
|---|---|---|
| Path of Exile 2 | 확인된 것: 0.2.0e에서 Blood Cretin 사망 웅덩이 6초 → 4초, 0.2.0 Hotfix 7(2025-04-05)에서 "temporarily disabled Volatile Boar as a Spectre, until we can make it not repeatedly explode without actually dying"(소환수 한정). 확인 못 한 것: 한 요약이 0.2.0e 노트라며 옮긴 "disabled a certain on-death effect where the telegraphing was not as clear as it should have been", "disabled the Volatile Crystals Modifier" | 패치 노트 정리(공략·보도) [W-20, V8 판단 불가] |
| Diablo IV 1.3.1 Vampiric | 치유 상한을 월드 티어마다 약 반으로(WT III 35→15%, IV 50→25%), 치유하는 투사체에 시각 효과를 더함 | 공식 패치 노트 재게재 [W-19, V9] |
| League of Legends | "visual impact should match gameplay impact". 효과와 맞지 않는 판정 범위가 흔한 불만이다 | 개발사 글 [W-30] |
| Kingdom Rush Frontiers | 죽을 때 터져 병사를 잡는 적. Saurian Blazefang은 "200 physical damage in a small radius"이고 Assassin도 "will almost certainly die from the death explosion". Abomination의 «250 True Damage»는 반박 검증에서 찾지 못했다 | 위키 요약 [A-21, V12 판단 불가] |

(추론) 우리 물량(웨이브 수백 마리)에서는 사망 효과가 가장 위험하다. 개발사는 시간을 줄이고, 일부는 껐다. 사망 폭발·장판을 넣으면 범위가 죽기 전부터 보여야 하고, 일반 적의 효과는 보스 예고보다 작아야 한다.

## F6. 감염·연쇄로 한순간에 무너지는 경우

They Are Billions는 "a single zombie left unattended can trigger a colony collapse"이고, 플레이어는 "1 to 2, 2 to 10, 10 to 100" 연쇄를 썼다. «감염 메커니즘을 고쳐야 한다»는 스레드가 있고, 한 플레이어는 주민이 변하기 전에 지연을 두자고 제안했다. 개발사 수정은 찾지 못했다(위키 + 포럼 각 한 건) [A-19].

## F7. 도망치는 적

Monster Hunter Wilds 베타에서 몬스터가 "were sometimes running off after only being attacked a few times, frustrating some players"였다. 디렉터는 "wasn't actually a design intention to have them be so rapidly moving"이라며 버그라고 했다. MH World·Wilds의 Steam 스레드는 사냥의 절반이 쫓기라며 불만을 적었고, 옹호하는 쪽은 도주가 체력 문턱에 묶이고 추적 수단이 있다고 했다(보도 + 포럼) [W-29, V14 확인]. Diablo 3 Treasure Goblin은 달아나다 멈춰 포탈을 열고 그동안 맞지 않으면 보상 없이 사라진다. 패치로 «더 오래 멈추게» 바뀌었다고 한다 [B-17].

(추론) 도주는 «한 번, 문턱에 묶여, 어디로 가는지 보이게» 해야 불만이 적다.

## 기믹별 «넣을 때 지킬 제약» 후보 (모두 추론, 설계 제안)

| 기믹 | 제약 후보 | 근거 |
|---|---|---|
| 분열 | 자식은 보상 0, 분열은 한 번, 웨이브 표는 자식까지 센 물량 | F2, [W-08][W-11][W-12] |
| 부활 | 재료(시전자·시체)를 두고 재료를 지우는 수단(범위·정화)을 준다. 끝내는 목표가 보인다 | F2 |
| 소환(보스) | 졸개 보상 0, 문턱 두세 번만 | F2, 보스 설계 §3.2 |
| 훔치기 | 한 번에 하나, 바로 달아남, 잡으면 그 자리에 떨어지고 저절로 돌아옴, 잃어도 판이 안 끝남 | F3 |
| 낚아채기·붙잡기 | 예고(표적 표시) 동안 끊김, 들린 유닛은 되찾을 수 있음, 영웅은 들리지 않음 | F3·F4 |
| 장판·사망 폭발 | 늘 켜지지 않음(짧은 창), 범위가 미리 보임, 기절로 끊김, 일반 적 효과는 작게 | F1·F5 |
| 감염 | 번지기 전에 지연, 한 번에 한 칸 | F6 |
| 도주 | 한 번, 체력 문턱에 묶임, 가는 곳이 보임 | F7 |
