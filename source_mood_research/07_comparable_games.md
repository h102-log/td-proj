# 07. 비슷한 느낌의 게임

[README](README.md)로 돌아가기.

원작의 정서를 이미 잘 내는 게임이 **어떤 수단으로** 그것을 내는지, 그 가운데 2D 도트·1인 개발 규모에서 따라 할 수 있는 것을 정리한다. 규칙 비교는 이전 조사(`game_design_research/04_benchmarks/01_game_cards.md`)에 있으니 되풀이하지 않는다.

이 장의 게임 사실은 검증 단계를 거치지 않았다. 문장마다 출처 링크를 단다. 스팀 리뷰 수치는 2026-10-23 열람 값이다. 이 갈래는 게임 화면을 직접 보지 않았다(기사·위키·상점 문구만).

---

## 1. 원작의 공식 게임

- 웹젠크레빅스가 «디펜스 게임의 폭군이 되었다: 라스트 스테이지»를 만든다. 지휘 전략 RPG, UE5 3D 배경 위 도트 캐릭터(«디오라마 픽셀아트»), 원작의 탐사·방어전·영지경영을 파티 조합·직접 지휘로 다시 짠다. 2027 출시 목표, 지스타 2026에서 약 15분 체험판 시연 [V40].
- 기존 게임과의 공식 콜라보는 찾지 못했다(검색 1회) ([games 메모](evidence/games.md) 6장).
- 공개된 기사들에 죽음·희생 요소를 살린다는 언급은 없다 [V40].
- (해석) 공식판의 중심은 «파티 RPG·역할 배치»라 우리(영지 방어)와 장르 중심은 다르다. 그러나 **도트 캐릭터 + 방어전 + 영지**는 겹친다. 원작 제목·인물명·고유 시스템명을 쓰면 비교되고 충돌하기 쉽다. 원작은 분위기 참고로만 쓴다(법적 판단은 이 문서 범위 밖) → [08 §5](08_for_our_game.md#5-피할-것).

---

## 2. 톤 기준

원작 톤은 **가벼운 인물·목소리 + 직관적이고 무거운 죽음**이다 [V35]. 이 기준으로 보면(해석):

| 가깝다 | 이유 |
|---|---|
| Bad North | 상점 문구가 «charming but brutal»(귀엽지만 잔혹한) [bad-north-steam] |
| Darkest Dungeon | 아트 디렉터가 «just a dash of cuteness»(약간의 귀여움)를 넣었다 [dd-80lv] |

| 먼 쪽 | 이유 |
|---|---|
| Battle Brothers | 일관된 그림다크, 가벼운 일상 쪽 정서가 없다 [bb-wiki] |
| Kingdom Rush | «detailed, cartoony», 평론은 가벼운 톤이 어려운 난이도를 상쇄한다고 봤다. 규칙 참고로는 핵심, 정서 참고로는 반례 [kr-wiki] |
| Diplomacy is Not an Option | 스스로 «tongue-in-cheek»(농담조)라 부르는 풍자 [dino-steam] |

---

## 3. 게임별 수단

원작 정서 요소 약칭: (a) 지휘관의 냉정한 결단·희생 선택, (b) 성벽 사수와 웨이브 공포, (c) 이름 있는 영웅의 성장·손실, (d) 몰려오는 물량, (e) 변경 영지 운영, (f) 시스템창이 보이는 세계.

| 게임 | 맞는 정서 | 정서를 내는 수단 | 팀 규모 |
|---|---|---|---|
| Darkest Dungeon (2016) | (c)(a)(f) | 고인 듯한 짙은 검정과 평면적 형태, «무서운 그림책» 느낌 [dd-80lv][dd-gd]. 성공과 실패를 모두 냉소적으로 논평하는 내레이터 [dd-steam][dd-wiki]. 영웅이 상태를 말하는 «바크» [dd-wiki]. 탑다운은 «머리 꼭대기만 보여» 공감이 어렵다며 옆 시점으로 바꿈 [dd-80lv] | 두 친구로 시작, Kickstarter 약 31.3만 달러 [dd-80lv][dd-wiki] |
| Frostpunk (2018) | (a)(e)(f) | 점점 무거워지는 법 선택(아동 노동·24시간 교대) [fp-wiki]. «숫자에도 공감할 수 있다» — 인구 상한으로 한 명의 죽음을 무겁게, 서사 문장은 1~2문장 [fp-inven]. 정답을 알려 주지 않는 지도자의 짐 [fp-ds]. 결말 판정 문장(«Was it worth it?», 플레이어 보고만) [fp-steamdisc]. 최소 팔레트라 «색 한 점이 눈 속의 온기» [fp-wiki] | 약 60명 [fp-wiki] |
| They Are Billions (2017~) | (b)(d) | 경보음 → 미니맵 해골 아이콘이 다가옴 → 진입 방향이 매번 다름 [tab-bittech]. 감염체 하나만 건물에 들어가도 안의 사람이 모두 감염 [tab-steam]. 모든 행동이 되돌릴 수 없음 [tab-gb] | 핵심 6명 + 30명. Unity로 약 400 유닛도 버거워 자체 엔진 [tab-gb] |
| Kingdom / Two Crowns (2015~) | (e)(b) | 레트로 픽셀아트와 칩튠이 분위기와 «유용한 시청각 신호»를 함께 줌 [kd-wiki]. 밤의 습격, 블러드문의 큰 무리 [kd-wiki]. 왕관을 잃어도 후계자가 폐허를 물려받음 [kd2-wiki] | 2인 팀(2015) [kd-wiki] |
| Thronefall (2023~) | (b)(e) | 낮에 짓고 밤에 «해가 뜰 때까지» 지킨다 [tf-steam]. 밤을 넘기면 다 복구되어 손실은 가볍다 [tf-wiki] | 2인 팀, Unity [tf-wiki] |
| Bad North (2018) | (c)(d)(a) | «Lose a commander and they're gone forever», «승리가 아니라 필사적 생존», «철수를 신중히» [bad-north-steam]. 불탄 집은 코인을 주지 않음 [bad-north-wiki] | 소규모 스튜디오 [bad-north-wiki] |
| The Banner Saga (2014) | (a)(c) | 약탈·아이템 구매·패배 후 재로드를 일부러 뺌 [bs-wiki]. «Not everyone will survive, but they will be remembered.» [bs-steam]. 손그림 로토스코핑과 오케스트라 [bs-wiki] | 핵심 4명 + 3명 [bs-wiki] |
| Battle Brothers (2017) | (c)(a)(e) | 술꾼·범죄자·불구 신병, 출신이 특성·이벤트를 좌우, 영구사망과 영구 장애 [bb-wiki][bb-steam] | — |
| XCOM: Enemy Unknown (2012) | (c) | 기지 바의 추모 벽, 계급에 따른 별명. «실제 결과가 있어야 실제로 성공했다고 느낀다»(Solomon) [xcom-kotaku] | — |
| Age of Darkness (2021~) | (b)(d) | 며칠마다 오는 «Death Night», 맵을 덮어 진입 방향을 숨기는 안개 «베일» [aod-sifter][aod-p2] | 확인 못 함 |
| Vampire Survivors (2022) | (d) | 1인 개발자가 «화면에 얼마나 많은 혼돈을 넣을 수 있는지» 시험 [vs-pt] | 1인 |

- (f) 시스템창이 보이는 세계를 직접 옮긴 게임 사례는 찾지 못했다([games 메모](evidence/games.md) 3.14). 대안으로 Darkest Dungeon의 냉소적 내레이터, Frostpunk의 판정 문장처럼 **감정 없는 시스템 문구가 비극을 담담히 알리는 어조**를 후보로 둔다(해석).

---

## 4. 정서 × 수단 대응

(해석)

| 정서 | 가까운 게임 | 수단 | 2D 도트·1인 난이도 |
|---|---|---|---|
| (a) 냉정한 결단 | Frostpunk, Banner Saga, Bad North | 짧은 텍스트 선택, 결산 끝 판정 한 줄, 재로드 금지, 철수 결정 | 쉬움(텍스트·규칙) |
| (b) 성벽·웨이브 공포 | They Are Billions, Kingdom, Thronefall, Age of Darkness | 경보음 + 다가오는 아이콘 + 매번 다른 방향, 밤 팔레트, «해 뜰 때까지», 방향을 숨기는 안개 | 쉬움~중간 |
| (c) 영웅 손실 | Darkest Dungeon, XCOM, Bad North, Banner Saga | 바크, 추모 목록·별명, «영원히 사라짐», «기억될 것» | 쉬움(텍스트 UI)~중간(초상) |
| (d) 물량 | They Are Billions, DINO, Age of Darkness | 수만 유닛 실시간은 어려움 → 소리·안개·가장자리로 «보이지 않는 다수» 암시 | 실제는 어려움, 암시는 쉬움 |
| (e) 변경 영지 | Kingdom, Thronefall, Frostpunk | 낮·밤 순환, 패배 뒤 계승 | 쉬움~중간 |
| (f) 시스템창 세계 | 직접 사례 없음 | 원작식 정산·카운트다운을 «시스템 목소리»로 | 쉬움(텍스트), 근거 약함 |
| 톤 | Bad North, Darkest Dungeon | 작고 귀여운 도트 인물 위에 피와 불 | 쉬움 |

---

## 5. 2D 도트·1인 개발에서

### 5.1 따라 할 수 있는 것 (비용 낮음)

(해석, 참고 게임의 팀 규모와 기술 사실에 비춰)

1. 결산 끝의 **판정 한 줄**(Frostpunk). 텍스트뿐이다.
2. **추모 목록**: 이름·별명·쓰러진 라운드·처치 수(XCOM, Darkest Dungeon 묘지).
3. **바크**: 짧은 말풍선 한 줄(Darkest Dungeon).
4. **웨이브 예고 셋**: 경보음, 화면 가장자리에서 다가오는 아이콘, 매번 바뀌는 방향(They Are Billions).
5. **팔레트 연출**: 낮·밤 전환, 특별한 밤의 색, 거의 단색 화면의 따뜻한 색 한 점, 짙은 검정 덩어리(Kingdom, Frostpunk, Darkest Dungeon).
6. **시간 목표**: «해가 뜰 때까지»(Thronefall).
7. **반복 경고로 복선**(Frostpunk의 발전기).
8. **귀여움과 잔혹함의 대비**(Bad North, Darkest Dungeon).

2·3·4·5는 2인 팀(Kingdom, Thronefall)이나 두 친구로 시작한 팀(Darkest Dungeon)이 이미 해냈다. 대부분 그림 양이 아니라 **텍스트·색·소리·규칙**에 기댄다.

### 5.2 어려운 것 (비용 높음)

- 전문 성우 내레이션(Darkest Dungeon) → 텍스트 내레이터로 대신한다.
- 오케스트라 녹음, 손그림 로토스코핑(Banner Saga).
- 수만 단위 실시간 유닛(They Are Billions 2만, DINO 2.5만 이상) [tab-steam][dino-steam]. Godot 2D에서 몇 마리까지 버틸지는 재 봐야 한다.
- 수백 명 시민 시뮬레이션과 개별 음성(Frostpunk).

### 5.3 선택에 따라

- **탑다운의 약점**: Darkest Dungeon 개발자는 머리 꼭대기만 보이면 인물 공감이 어렵다고 봤다 [dd-80lv]. 우리 게임은 45° 위에서 본 도트라서(`art_direction_research/README.md:67`), 초상·결산 화면 얼굴·바크로 인물을 따로 보여 주는 보완을 검토할 만하다(해석).
- **원작이 Darkest Dungeon에 비유된다는 독자 반응**은 검증하지 못했다(미확인) [V39]. 다만 원작 웹툰 자체가 다키스트 던전의 «<휘파람>» 밈을 인게임 화면에 쓴다 [V32].

---

## 6. 확인 못 한 것

- 공식 게임의 플랫폼, 분위기·연출에 관한 개발사 발언.
- Frostpunk 결말 판정 문구의 공식 원문(플레이어 보고만).
- Thronefall·Bad North 연출에 관한 개발자 발언.
- They Are Billions 웨이브 예고에 카운트다운이 있는지.
- Age of Darkness 팀 규모와 «7만 유닛» 원문.
- Godot 2D에서 1인 개발로 감당할 실제 동시 유닛 수.

상세: [evidence/games.md](evidence/games.md) 6장.

[bad-north-steam]: https://store.steampowered.com/app/688420/Bad_North_Jotunn_Edition/
[bad-north-wiki]: https://en.wikipedia.org/wiki/Bad_North
[dd-80lv]: https://80.lv/articles/red-hook-studios-talks-about-the-creation-of-darkest-dungeon
[dd-gd]: https://www.gamedeveloper.com/audio/road-to-the-igf-red-hook-studios-i-darkest-dungeon-i-
[dd-steam]: https://store.steampowered.com/app/262060/Darkest_Dungeon/
[dd-wiki]: https://en.wikipedia.org/wiki/Darkest_Dungeon
[fp-wiki]: https://en.wikipedia.org/wiki/Frostpunk
[fp-inven]: https://www.invenglobal.com/articles/6528/igc-2018-empathize-with-numbers-the-process-of-frostpunk-scenario-writing
[fp-ds]: https://www.dualshockers.com/frostpunk-interview-11-bit-studios/
[fp-steamdisc]: https://steamcommunity.com/app/323190/discussions/0/1696045708654961998
[tab-bittech]: https://bit-tech.net/previews/gaming/pc/they-are-billions-preview/1/
[tab-steam]: https://store.steampowered.com/app/644930/They_Are_Billions/
[tab-gb]: https://gamesbeat.com/the-making-of-early-access-hit-they-are-billions/
[kd-wiki]: https://en.wikipedia.org/wiki/Kingdom_(video_game)
[kd2-wiki]: https://en.wikipedia.org/wiki/Kingdom_Two_Crowns
[tf-steam]: https://store.steampowered.com/app/2239150/Thronefall/
[tf-wiki]: https://en.wikipedia.org/wiki/Thronefall
[bs-wiki]: https://en.wikipedia.org/wiki/The_Banner_Saga
[bs-steam]: https://store.steampowered.com/app/237990/The_Banner_Saga/
[bb-wiki]: https://en.wikipedia.org/wiki/Battle_Brothers
[bb-steam]: https://store.steampowered.com/app/365360/Battle_Brothers/
[xcom-kotaku]: https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627
[aod-sifter]: https://www.sifter.com.au/post/age-of-darkness-final-stand-is-a-brutal-beautiful-take-on-the-tower-defence-genre
[aod-p2]: https://www.player2.net.au/2025/03/age-of-darkness-final-stand-review-real-time-survival/
[vs-pt]: https://www.pockettactics.com/vampire-survivors/interview
[kr-wiki]: https://en.wikipedia.org/wiki/Kingdom_Rush
[dino-steam]: https://store.steampowered.com/app/1272320/Diplomacy_is_Not_an_Option/
