# 99. 만든 방법·확인 못 한 것·출처

[README](README.md)로 돌아가기.

## 만든 방법

- 2026-11-17, 사용자의 «마을을 활용할 만한 요소에 어떤 게 있을까? 다른 디펜스 장르 조사해 봐» 요청으로 조사했다. 조사·검증·종합은 워크플로(여러 서브에이전트)로 했다.
- **원문은 열지 못했다.** 이 클라우드 세션의 네트워크 정책이 gamedeveloper.com·pcgamer.com·위키 같은 외부 사이트를 막았다(WebFetch `ENOTFOUND`, 프록시 403). 허용 목록에 사이트를 더하는 환경 변경도 거부됐다. 그래서 모든 근거는 **WebSearch 결과에 보인 글귀**다. 검색 도구가 원문을 요약·다듬었을 수 있고, 글귀와 URL의 짝을 검색 요약이 정확히 주지 않은 경우가 있다(그런 주장은 내용 칸에 «URL 짝은 추정»이라고 적혀 있다).
- WebSearch는 한 턴에 200회 한도가 있어 조사를 여러 라운드로 나눴다. 첫 라운드에서 한도가 차 They Are Billions·Diplomacy 갈래와 검증 대부분이 비었고, 다음 라운드에서 다시 했다.
- 갈래는 14개다(아래 «출처»의 소제목). 갈래마다 조사 에이전트 하나가 주장 15~16개를 냈다(DS·EM 15개, 나머지 16개). GV·GT 두 갈래는 첫 집계에서 «마을이 곧 방어선»과 «준비 단계 결정 템포» 근거가 얇아 보충했다.
- 검증: 주장마다 다른 에이전트가 따로 다시 검색했다(1차). 1차가 «확인»이 아니면 원래 출처가 아닌 곳부터 찾는 2차 검증을 따로 돌렸다. 1·2차가 엇갈리면(한쪽만 반박) 결정표를 한 번 더 받는다. 판정 합치기는 다음과 같다.
  - 1차 확인 → **확인**. 1차 일부만 맞음 → **정정**(2차가 반박하면 결정표). 1차 반박 → 2차도 반박이거나 근거 없음이면 **기각**, 2차가 확인·일부면 결정표. 1차 근거 없음 → 2차 판정을 따른다(둘 다 근거 없음이면 **미검증**).
- 결과: 주장 222개 가운데 확인 157, 정정 54, 미검증 11, 기각 0.
- 본문(01~05)은 확인·정정 주장만 근거로 쓴다. 미검증 주장은 쓸 때 «(미검증)»을 붙인다. 정정 주장은 정정 내용대로 쓴다.
- 우리 게임 사실은 저장소 맥락 정리 에이전트가 `SPEC.md`·`data/structures/*.tres`·`src/sim/battle.gd`·`src/ui/battle_view.gd`·`villager_jobs_research/`·`village_research/`·`road_research/`·`hq_shop_research/`·`gimmick_research/`·`game_design_research/`·`play_review/2026-11-15.md`·`insights/`에서 읽었다. Godot은 띄우지 않았다.

## 확인 못 한 것

조사 에이전트가 찾으려 했지만 근거를 못 찾았다고 적은 것이다(갈래마다 앞의 몇 개).

- **TF** Thronefall
  - Game Developer 인터뷰 본문을 열지 못했다. 건물이 부서져도 크게 벌받지 않게 한 관대한 설계라는 발언은 검색 결과에서 확인하지 못했다.
  - 개발자가 자원 채집(경영)을 뺀 이유를 직접 말한 대목을 찾지 못했다. 자원을 한 종류로 줄였다는 요약만 확인했다. GameDiscoverCo 심층 기사(«went minimal») 본문도 찾지 못했다.
  - 부서진 건물이 다음 날 공짜로 복구되는지, 다시 지으려면 값을 내야 하는지 확인하지 못했다.
  - 적이 경제 건물을 먼저 노리는지(적 AI의 표적 규칙) 근거를 찾지 못했다. 부서진 건물은 수입이 없고 빨간 X로 표시된다는 것까지만 확인했다.
- **KG** Kingdom Two Crowns / New Lands
  - 네트워크 정책으로 페이지 원문을 열지 못해 모든 주장이 검색 결과 요약과 발췌에 기댄다. 일부 evidence_quote는 원문 발췌가 아니라 검색 요약 문장이다(Subjects, Miscellaneous Structures, Statues, Push Square).
  - 인용과 URL을 잇는 근거가 검색 요약에서 추정한 것인 주장이 있다. 피의 달 → TV Tropes, Greed 약탈 → Wikiwand, 폭탄 → Magic Game World, 개발 의도 → Game Developer(Gamereactor일 수도 있다).
  - Town Center 단계별 동전 비용(특히 Tier 6·7)은 위키 표가 깨져 있어 확인하지 못했다. Banker를 여는 단계도 출처마다 다르다(Tier 1 대 Tier 4).
  - 농장 수확 동전(4 대 6), 겨울에 농부가 낫을 버리는지 지니는지가 위키 판마다 달라, 지금 판 기준을 확인하지 못했다.
- **TAB** They Are Billions / Age of Darkness: Final Stand
  - They Are Billions 테슬라 탑의 정확한 에너지 반경(칸 수)과 «건물이 범위 안에 완전히 들어가야 하는지»를 찾지 못했다.
  - They Are Billions 시장·은행 보너스 비율이 판마다 어떻게 바뀌었는지(시장 20% 또는 30%) 공식 근거로 확인하지 못했다. «집이 반경 안에 완전히 들어가야 보너스» 주장도 검증되지 않았다.
  - 실마리에 있던 «22×25 칸에 집 100채» 같은 최적 격자 수렴 사례는 이번 검색에서 다시 확인하지 못했다.
  - They Are Billions 생존 모드 final swarm이 며칠째 오는지(설정별) 근거를 찾지 못했다. 캠페인 맵별 날짜(61·64일 등)만 보였다.
- **DS** Diplomacy is Not an Option / Stronghold / Manor Lords
  - DINO(Door 407)에서 막사가 농민 한 명을 소비해 병사 한 명을 만드는지(일손이 줄어드는지) 직접 근거를 찾지 못했다. 검색 3번 모두 일반 가이드만 나왔다.
  - Finger Guns 리뷰가 건물 업그레이드 단계와 자원 조합을 칭찬했다는 실마리는 이번 검색 결과로 확인하지 못했다.
  - DINO에서 집 하나가 하루 2명을 받는다는 Steam 포럼 내용은 보였지만, 어느 스레드인지 짝을 찾지 못해 주장으로 쓰지 않았다.
  - Stronghold 공포 요소(Fear Factor)의 방향과 수치가 출처마다 엇갈려 확정하지 못했다(좋은 것은 인기도를 올리고 생산을 늦춘다, 공포 건물은 생산을 2~3배로 늘린다는 설명이 섞여 있었다).
- **RD** Bad North / Kingdoms and Castles / Farthest Frontier / Cataclismo / RimWorld
  - Bad North 개발자(Plausible Concept)가 집·동전 설계 의도를 밝힌 인터뷰를 찾지 못했다. 인터뷰 목록(Nintendo UK, Nintendo Life, Creative Review)만 보였고 집·동전 이야기는 결과에 없었다.
  - Bad North에서 집이 엄폐물이 되는지, 해변 가까이 놓인 집 때문에 섬마다 방어 난이도가 달라지는지(실마리 파일의 주장)는 이번 검색으로 다시 확인하지 못했다.
  - Bad North의 업그레이드 비용(일반 6·베테랑 12·엘리트 20 동전)은 업적 가이드 요약에만 보였고, 공식 근거를 찾지 못해 주장에서 뺐다.
  - Kingdoms and Castles에서 용이 무엇을 노리는지(집·성·주민), 돌 성벽이 용을 못 막는다는 리뷰 글귀가 어느 매체 것인지는 출처 URL을 특정하지 못했다.
- **CS** Frostpunk / Against the Storm / Northgard
  - Against the Storm 주춧돌(cornerstone)의 정확한 규칙(한 번에 몇 개 중 고르는지, 몇 년마다 고르는지)은 확인하지 못했다. Player.One의 «only one cornerstone can be active per year» 표현은 모호하다. 위키에서는 «List of annual Cornerstones» 쪽 제목만 보였다.
  - Against the Storm 의뢰(orders)의 구체 규칙과 보상 구조는 이번 검색에서 근거를 찾지 못했다.
  - Against the Storm 최신판에서 공터 적대도가 고정값으로 바뀌었다는 개발자 업데이트는 요약에 보였지만, 정확한 수치와 판 번호는 확인하지 못했다.
  - Smoldering City 레벨 상한 12→15, 줄 해금 조건이 레벨뿐이라는 변경(2022년 3월 얼리 액세스 11차 업데이트), 진행 포인트가 Cataclysm 때 초기화되지 않는다는 점은 보였지만 글귀와 URL(progression-update와 steamdb 가운데 어디인지)을 확실히 짝짓지 못해 주장에서 뺐다.
- **TD** 경제·지원 타워가 있는 타워 디펜스 (Bloons TD 6, Plants vs. Zombies, Mindustry, The Riftbreaker, Dome Keeper)
  - seeds.json 30개 항목에는 맡은 다섯 게임(Bloons TD 6, Plants vs. Zombies, Mindustry, The Riftbreaker, Dome Keeper)에 해당하는 항목이 없었다. 모두 새로 검색했다.
  - Bloons TD 6: Ninja Kiwi가 Banana Farm·파밍 설계 의도를 밝힌 인터뷰나 패치 노트 원문을 못 찾았다. 스팀 커뮤니티의 «파밍이 지루하다/필수다» 논쟁 글 원문도 결과에 안 나왔다(레딧 댓글 하나만 확인했다). Monkey Wall Street 가격은 페이지마다 달라 쓰지 않았다. Banana Farm·Monkey Village 기본 가격도 확인하지 못했다.
  - Plants vs. Zombies: «You can always get rid of some of these later when you have the sun and need the space»(해바라기를 나중에 치워 칸을 비운다) 문장은 결과에 보였다. 하지만 검색 요약이 «fan wiki»로만 표기해 어느 페이지인지 특정하지 못해 주장에서 뺐다. Sunflower 수치 주장의 출처(bu…
  - Mindustry: 적 유닛이 드릴·컨베이어 같은 생산 시설을 우선 노리는지 확인하지 못했다. Graphite Press 수치(초당 Coal 1.33 → Graphite 0.66)는 출처 페이지를 특정하지 못했다. Fandom 위키에는 정보가 구판이라는 경고가 있었다.
- **HB** 판 사이 허브·마을 (Darkest Dungeon, Loop Hero, Arknights, Wildfrost)
  - Tyler Sigman의 GDC 2016 «Darkest Dungeon: A Design Postmortem»이 햄릿·골드 경제를 다루는지 확인하지 못했다. 영상 설명만 나왔고 글 정리본은 찾지 못했다.
  - Red Hook이 Darkest Dungeon II에서 1편 햄릿(건물 업그레이드 구조)을 뺀 직접 이유는 찾지 못했다. 예전 Hope/XP 방식에 대한 발언만 찾았다.
  - Darkest Dungeon 햄릿 건물의 레벨별 비용, Abbey 스트레스 해소 부작용, Districts(Crimson Court)의 실제 효과 수치는 결과에 보이지 않았다.
  - Darkest Dungeon Tavern에서 도박장에 한 주 더 머무는 부작용과 퀴크로 막히는 활동을 찾았지만, 주장 수 제한 때문에 넣지 않았다(https://darkestdungeon.wiki.gg/wiki/Tavern).
- **ML** 주민이 전투에 끼는 구조 (Age of Empires 마을 종, Warcraft III, 피신·민병)
  - 이 세션은 WebFetch·curl을 쓰지 않아 원문 페이지를 열지 못했다. evidence_quote는 WebSearch 결과 요약에 보인 글귀이며, 검색 도구가 원문을 다듬었을 수 있다.
  - Warcraft III Burrow가 식량(인구 상한) 건물 역할도 한다는 점은 이번 검색 결과에 나오지 않아 주장으로 쓰지 않았다(우리 집=인구+피신 구조와 가장 닮은 지점이라 다시 확인할 가치가 있다).
  - AoE 마을 종, Warcraft III Call to Arms·Burrow의 설계 의도를 밝힌 개발자 인터뷰·포스트모템·GDC 자료는 찾지 못했다.
  - AoE II 마을 회관 화살 공식(기본 화살 수, 주민 1명당 +1)은 공식 문서로 확인하지 못했고 팬 위키·스팀 토론만 있다.
- **EM** «다 지은 뒤 공허» 문제와 해법
  - 검색 15회를 다 썼고, 도시 건설 게임의 후반 공허를 직접 다룬 GDC 강연은 찾지 못했다.
  - 유지비·쇠퇴·수리(건물이 낡아 수리가 필요한 규칙)를 둔 디펜스·마을 하이브리드 사례는 근거를 찾지 못했다. Thronefall의 «되살린 경제 건물은 그날 수입 없음»만 가까운 예다.
  - Against the Storm 개발자가 후반 반복을 직접 말한 글은 없었다. 실마리의 Devlog 7 «결정 마비·정착지가 비슷해짐(메타 후반)»은 확인하지 못했고, 해금이 적은 초반에 배치가 비슷해질 수 있다는 내용만 보였다.
  - Kingdom Two Crowns에서 포털을 부술수록 Greed가 세지는지는 스팀 사용자 관찰뿐이고 개발자·위키 확인이 없다. 후반 반복 비판 문구가 GameGeeker의 어느 리뷰인지도 검색 요약만으로 확정하지 못했다.
- **SP** 공간 퍼즐·인접 보너스와 그 실패
  - WebSearch 결과가 원문 발췌가 아니라 요약으로 와서, evidence_quote는 결과에 보인 글귀 그대로지만 원문 페이지와 한 글자씩 대조하지 못했다. 요약이 글귀와 URL을 짝지어 주지 않은 경우(Islanders Wikipedia 게이지 문장, Anno Union 행복 문장, CivFanatics 최적해 문장, High Ground 창고 문장)는 가장 그럴듯한 결과 URL에 붙…
  - Islanders에서 점수 문턱을 넘으면 건물 묶음(pack) 두 개 중 하나를 고른다는 규칙을 직접 확인하지 못했다. 개발자 인터뷰의 «업그레이드 선택지 둘» 문장만 찾았다.
  - Islanders 건물별 점수 수치(예: 양조장이 홉밭마다 +5)는 팬 가이드에서만 보여 판(버전)을 확인하지 못해 쓰지 않았다.
  - Civ VI 인접 보너스 단계(Major +2·Standard +1·Minor +0.5)와 «구역을 놓으면 숲·열대우림이 사라진다» 규칙은 결과에 보였지만, 출처가 개발자 문서가 아닌 자동화 라이브러리 문서라 주장으로 쓰지 않았다. 어느 확장팩 기준인지도 확인 못 했다.
- **RV** 마을·기지 요소에 대한 플레이어·평론 반응
  - Bad North: 건물이 클수록 골드를 더 준다는 규칙은 이번 결과에서 확인되지 않았다. 집에서 병력을 보충하다 집이 부서지면 그 부대를 영영 잃는다는 서술은 있었지만 어느 리뷰(pushsquare·godisageek·nintendolife 등)인지 요약이 밝히지 않아 주장에서 뺐다. Jotunn Edition에서 골드가 공용 풀로 바뀌었다는 것도 출처가 불분명하다.
  - Kingdom Two Crowns: '후반 방어 미션이 기계적인 잡일로 전락하고 다섯 섬이 거의 똑같다'는 글귀가 결과에 있었다. 하지만 어느 리뷰 것인지(gamegeeker로 추정) 확인하지 못했다. '경제 성장과 방어 준비 사이의 긴장이 재미'라는 호평도 출처가 이름으로 나오지 않았다.
  - Thronefall: '건물 종류가 더 많아야 반복을 피한다', '타워마다 업그레이드 2단계·단계마다 선택지 4개', '성 중심 업그레이드로 노드가 늘어난다'는 내용이 나왔다. 하지만 리뷰 이름이 없고, 두 번째 검색은 '더 많은 건물을 요구한 리뷰는 못 찾았다'고 해 서로 어긋났다.
  - Farthest Frontier: 후반에 할 게 없다는 리뷰는 찾지 못했다. 오히려 생산 사슬의 미세 관리로 후반이 고되다는 평이 나왔는데, 이것도 출처가 불분명하다. 스팀 'Very Positive (10,952 reviews)' 수치도 어느 페이지 것인지 확인하지 못했다.
- **GV** 보충: 마을 건물이 곧 방어선
  - Cataclismo에서 집 같은 내부 건물이 적의 길을 막는지, 적이 어떤 건물을 먼저 부수는지 근거를 못 찾았다. 리뷰 평가만 확인했다.
  - Diplomacy is Not an Option에서 적이 건물을 노리는 우선순위와 길 찾기 규칙을 못 찾았다. 리뷰의 AI 비판만 확인했다. 적이 벽을 갉는 동안 기다리는 게 지루하다는 리뷰 글귀는 출처 URL을 짝짓지 못했다.
  - Stronghold(Crusader·Definitive Edition)의 안쪽 성벽·성채·살상 구역 설계와 적의 건물 표적 규칙은 근거를 못 찾았다. Stronghold 2 미리보기의 한 문장과 일반 성 건축 자료만 나왔다. PC Gamer의 «Stronghold: Warlords wants to improve the series' issues with walls and unit forma…
  - Thronefall에서 적이 가장 가까운 건물을 노리는지, 벽이 적을 붙잡는지를 공식 자료로 확인하지 못했다. 팬 공략(shapes.inc)에만 이 관찰이 있다.
- **GT** 보충: 준비 단계의 결정 템포와 설계 이론
  - Rogue Tower가 웨이브마다 카드 셋 중 하나를 고르게 하는지 결과로 확인하지 못했다. 카드 400장 이상과 길이 계속 늘어난다는 점만 보였다. Indie Hellzone 리뷰가 «좋은 판 하나가 너무 오래 걸린다»며 빨리 감기를 요청했다는 요약이 있었지만 주장으로 넣지 않았다.
  - Bad North에서 집을 지키면 동전을 받아 섬 사이에 지휘관을 업그레이드하는 구조(마을이 표적이 되는 경제)를 다룬 근거를 찾지 못했다. 검색된 개발자 인터뷰(PocketGamer.biz, Medium)는 그 메커닉을 다루지 않았다.
  - Cataclismo 개발사 Digital Sun의 준비 단계 템포 설계 의도 인터뷰를 찾지 못했다. 리뷰 반응만 있다.
  - «준비 단계 경영이 길어지면 디펜스 템포를 깬다»를 정면으로 다룬 설계 글이나 GDC 강연을 찾지 못했다. Cataclismo 리뷰가 간접 근거일 뿐이다.

## 출처

주장 ID는 본문의 [ID]와 같다. 판정: 확인·정정·미검증·기각. 정정 주장은 첫 줄에 조사 때의 원래 문장을 두고, 바로 아래 «정정:» 줄에 검증자가 고친 내용을 적었다. 두 검증이 따로 고쳤으면 « / »로 이어 둘 다 적었다. 본문은 «정정:» 줄을 따른다.

### TF — Thronefall

- **TF-01** (확인 · Thronefall · 메커닉) 집은 밤마다 1골드를 준다. 밤 전투에서 부서진 집은 다음 날 아침 골드를 주지 않는다. — [how to get more gold in thronefall](https://rofluno.pages.dev/posts/how-to-get-more-gold-in-thronefall)
- **TF-02** (확인 · Thronefall · 메커닉) Mill을 지으면 Fields를 지을 수 있게 된다. 작은 생산 사슬이다. — [Thronefall Wiki – Mill](https://throne-fall.github.io/game-content/buildings/mill.html)
- **TF-03** (확인 · Thronefall · 메커닉) Gold mine은 첫 밤에 8골드를 주고, 그 판이 끝날 때까지 밤마다 1골드씩 줄어든다. — [how to get more gold in thronefall](https://rofluno.pages.dev/posts/how-to-get-more-gold-in-thronefall)
- **TF-04** (확인 · Thronefall · 메커닉) Harbor는 밤마다 배가 1척씩 늘어 최대 5척까지 쌓인다. 수입은 배 수에 따라 정해진다. — [how to get more gold in thronefall](https://rofluno.pages.dev/posts/how-to-get-more-gold-in-thronefall)
- **TF-05** (확인 · Thronefall · 메커닉) Fortified Houses 퍽은 집 체력을 크게 올리고, 2단계 집이 적에게 화살을 쏘게 한다. — [Leveling system – Thronefall Wiki](https://throne-fall.github.io/about/leveling.html)
- **TF-06** (정정 · Thronefall · 메커닉) Castle Center는 두 번 업그레이드할 수 있다. 업그레이드할 때마다 4갈래 가운데 하나를 고른다. — [Castle Center – Thronefall Wiki](https://throne-fall.github.io/game-content/buildings/castle-center.html)
  - 정정: 위키에 나오는 갈래는 Builder's Guild, Castle-Up, Godly Curse(찍은 대상이 모든 피해를 50% 더 받음), 플레이어 체력 +50%·+75% 갈래다. Royal Training·Royal Mastery는 검색에서 확인되지 않았다. Royal Mint·Castle Fortifications는 갈래가 아니라 Castle Center를 강화하는 퍽이다.
- **TF-07** (정정 · Thronefall · 메커닉) Castle Center 갈래 중 Builder's Guild는 밤마다 집 하나를 공짜로 업그레이드한다. — [Thronefall – Building and Upgrade Tips](https://gameplay.tips/guides/thronefall-building-and-upgrade-tips.html)
  - 정정: 위키 기준으로 Builder's Guild는 아침마다 1단계 집 하나를 2단계로 자동 업그레이드한다(1단계 집이 있을 때만). 밤에 업그레이드할 수 있던 버그는 패치로 고쳐졌다. Castle-Up은 밤마다 성벽·탑 업그레이드 값을 1씩 깎는다(최소 1, 처음 짓는 값은 그대로). 그래서 할인은 쌓여 가는 방식이다. 이것은 위키 설명이고 패치 노트로는 확인하지 못했다. / Builder's Guild: 밤이 끝난 뒤 매일 아침 레벨 1 집 하나를 레벨 2로 공짜로 올린다(올릴 집이 있을 때만, 대장간은 제외라는 패치 기록 있음). Castle-Up은 같은 단계의 경쟁 선택지가 아니라 레벨 3 성 업그레이드이고, 탑·성벽 업그레이드 값을 밤마다 1씩 깎는다(최소 1).
- **TF-08** (정정 · Thronefall · 개발자 의도) 개발자는 무엇을 어디에 지을지 고르는 자유를 뺐다. 언제, 어떤 순서로 지을지만 남겼다. — [Mastering minimalism and layering complexity with strategy game Thronefall (Game Develope…](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
  - 정정: 확인된 것은 «정해진 건물을 정해진 슬롯에만 지어 레벨 디자인 여지가 열렸다»까지다. «언제·어떤 순서만 남았다»는 표현과 좌절 감소 목적은 원문으로 확인되지 않았다. / 개발자가 뺀 것은 «어디에 무엇을 놓을지»(자리·건물 종류 고정)다. 짓는 순서 말고도 업그레이드 갈래, 병영 유닛 종류, 무기·퍽 같은 고르기는 남아 있다. «언제·순서만 남았다»는 표현은 원 기사 한 곳에서만 나온다.
- **TF-09** (정정 · Thronefall · 설계론) 개발자는 선택지를 일부러 뺐다. 세세한 유닛 명령을 없애고 사서 쓰는 자원을 한 종류로 줄였다. — [Mastering minimalism and layering complexity with strategy game Thronefall (Game Develope…](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
  - 정정: 확인된 것: 사서 쓰는 자원이 골드 하나뿐이고, 개발자(Schnepf)가 미니멀리즘을 스튜디오의 일관된 방향이라고 말했다. 확인 못 한 것: 유닛 명령을 일부러 뺐다는 개발자 발언.
- **TF-10** (확인 · Thronefall · 개발자 의도) Jonas Tyroller는 경제가 눈덩이처럼 불어나는 문제를 풀려고 적이 골드를 떨구게 했다. — [Building a best-selling game with a tiny team (The Pragmatic Engineer)](https://newsletter.pragmaticengineer.com/p/thronefall)
- **TF-11** (정정 · Thronefall · 개발자 의도) Tyroller는 스팀 토론에서 적 골드를 늘리면 플레이어의 경제 선택이 덜 중요해진다고 답했다. 두 수입 사이의 트레이드오프라는 것이다. — [Economy of this game is wack. :: Thronefall General Discussions](https://steamcommunity.com/app/2239150/discussions/0/5971271658111960813/)
  - 정정: 답글 내용(적 골드↔경제 선택 트레이드오프, 눈덩이처럼 무너지는 경제)은 글타래에 있다. 그러나 작성자가 Jonas Tyroller라는 것은 확인되지 않았으니 개발자 발언이라고 단정하지 말 것.
- **TF-12** (정정 · Thronefall · 메커닉) 판에서 일정 점수를 넘기면 레벨이 오른다. 레벨이 오르면 새 퍽·무기·업그레이드나 영구 업그레이드가 열린다. — [Leveling system – Thronefall Wiki](https://throne-fall.github.io/about/leveling.html)
  - 정정: 지금 판 기준으로 무기·변이(mutator)·건물 업그레이드는 캠페인 레벨을 깨면 열린다. 퍽만 예전처럼 XP 레벨업으로 열린다(SteamDB 패치 노트 14977238). 위키의 «레벨업으로 무기가 열린다»는 설명은 그 패치 전 내용일 수 있다. / 1.7 패치부터 XP 레벨업으로 열리는 것은 퍽이다. 무기·변이·건물 업그레이드는 캠페인 레벨을 깨서 연다(예: Nordfels를 깨면 Spear, 마지막 레벨을 뺀 레벨마다 다음 무기). 위키의 «레벨업으로 퍽·무기·업그레이드»는 그 이전 설명이다.
- **TF-13** (정정 · Thronefall · 개발자 의도) 2024년 10월 정식 출시(1.0)에서 퍽·변이·적·무기, 영웅 유닛, 로그라이크 무한 모드, 미니 모드가 더해졌다. — [The full version of indie super hit Thronefall is out on PC & Switch (press release)](https://gamespress.westeu-v2.propressroom.com/The-full-version-of-indie-super-hit-Thronefall-is-out-on-PC-Switch)
  - 정정: 검색 요약에서는 미니 모드가 1.0이 아니라 2025년 Update 2.11(개발자가 마지막 콘텐츠 업데이트라고 함)에 들어왔다고 나온다. 보도자료 본문을 직접 보지 못해 1.0에 미니 모드가 있었는지는 확정하지 못했다. 영웅 유닛을 확인해 준 출처는 찾지 못했다. / 보도자료의 목록은 앞서 해보기 시작 때와 비교한 정식판 내용이다. Eternal Trials(1.3)는 정식 출시 뒤가 아니라 앞서 해보기(1.x) 때 업데이트로 보인다. 정식 출시 때는 시즌 4가 더해졌다. 미니 모드 12개는 2.11 최종 업데이트(PC 전용)에서 더해졌다. 무한 모드 개편(더 큰 전장, 더 완만한 템포)은 확인하지 못했다.
- **TF-14** (확인 · Thronefall · 반응) Gameluster 리뷰는 경제와 방어 업그레이드 사이에서 고르는 경제 루프가 몰입감 있다고 칭찬했다. — [Thronefall Review – Holding On For One Last Night (Gameluster)](https://gameluster.com/thronefall-review-holding-on-for-one-last-night/)
- **TF-15** (확인 · Thronefall · 반응) Fingerguns의 앞서 해보기 리뷰는 건물 자체의 업그레이드를 더 넓힐 여지가 있는 부분으로 짚었다. — [Thronefall Early Access Review (PC) – To Arms (Fingerguns)](https://fingerguns.net/games/2023/08/05/thronefall-early-access-review-pc-to-arms/)
- **TF-16** (확인 · Thronefall · 실패 사례) 스팀 부정 리뷰 하나는 고정 슬롯이 전장을 꾸미는 재미를 거의 다 없앤다고 비판했다. — [Steam Community :: Thronefall (negative reviews, top rated)](https://steamcommunity.com/app/2239150/negativereviews/?l=english&browsefilter=toprated)

### KG — Kingdom Two Crowns / New Lands

- **KG-01** (확인 · Kingdom New Lands / Kingdom Two Crowns · 메커닉) Town Center는 New Lands에서 6단계, Two Crowns에서 7단계까지 오르고, 단계마다 새 상인·건물·방어물이 열린다. — [Kingdom Wiki – Town center](https://kingdomthegame.fandom.com/wiki/Town_center)
- **KG-02** (확인 · Kingdom New Lands / Kingdom Two Crowns · 메커닉) 위키는 안쪽 성벽·탑을 짓거나 올리지 말고 돌·철 기술부터 얻은 뒤 Town Center를 올리라고 권한다. — [Kingdom Wiki – Town center](https://kingdomthegame.fandom.com/wiki/Town_center)
- **KG-03** (확인 · Kingdom Two Crowns · 메커닉) 떠돌이(vagrant)는 동전을 하나 받으면 주민(peasant)이 되어 왕국 중심에서 일을 기다린다. 도구를 사 주어야 직업이 생긴다. — [Kingdom Two Crowns – Subjects (Magic Game World)](https://www.magicgameworld.com/?p=27271)
- **KG-04** (확인 · Kingdom Two Crowns · 메커닉) 떠돌이 야영지 바로 옆 나무를 베면 그 야영지가 영구히 사라진다. — [Kingdom Two Crowns – Miscellaneous Structures (Magic Game World)](https://www.magicgameworld.com/?p=27298)
- **KG-05** (확인 · Kingdom Two Crowns · 메커닉) 성벽이 지켜 주지 못하는 주민은 Greed에게 동전과 도구를 빼앗기고, 그러면 다시 모집해야 한다. — [Kingdom Two Crowns (Wikiwand)](https://wikiwand.com/en/articles/Kingdom_Two_Crowns)
- **KG-06** (정정 · Kingdom Two Crowns · 메커닉) 피의 달(Blood Moon)에는 Greed가 해가 떠도 물러나지 않고 공격을 이어 가며, 음악으로 미리 알 수 있다. — [Kingdom (TV Tropes)](https://tvtropes.org/VideoGame/Kingdom)
  - 정정: 확인된 것: 해가 떠도 공격이 이어진다(TV Tropes). 포탈 파괴 직후 몇 초 안에 피의 달이 오고, 자연히 오는 피의 달보다 웨이브가 크다(yekbot). 확인 못 한 것: 피의 달 음악 예고. 위키에서 찾은 소리 신호는 한쪽 웨이브를 알리는 «우르릉» 소리뿐이었다. / 피의 달 밤은 해당 웨이브의 Greed를 모두 물리칠 때까지 끝나지 않는다(밤이 이어진다). 낮까지 밀고 들어오는 것은 floater·breeder 쪽이고, 방어가 약할 때 특히 그렇다고 위키는 적는다. 피의 달은 전용 음악과 경고음으로 미리 알 수 있다.
- **KG-07** (확인 · Kingdom New Lands · 메커닉) New Lands에서 배로 다음 섬에 가면 주머니의 금화는 이어지지만, 왕국은 새 땅에서 처음부터 다시 시작한다. — [Kingdom Wiki – Ship](https://kingdomthegame.fandom.com/wiki/Ship)
- **KG-08** (정정 · Kingdom Two Crowns · 메커닉) Two Crowns에서는 왕이 떠난 섬의 건물이 썩어 가고, 오래 비울수록 더 많이 부서지거나 등급이 내려간다. — [Kingdom Wiki – Islands in Two Crowns](https://kingdomthegame.fandom.com/wiki/Islands_in_Two_Crowns)
  - 정정: 왕이 이미 가 본 섬을 하루 비울 때마다 그 섬에 하루치 썩음이 쌓인다. yekbot 가이드에 따르면 썩는 것은 성벽과 궁수뿐이다. 궁수는 약 1일, 성벽은 Tier 1 2일에서 Tier 5 20일까지 버틴다. 그러니 «건물 전반이 부서진다»는 과장일 수 있다. 2.3.2 패치 노트에 «Adjustments to decay mechanic»이 있어 수치는 지금 판과 다를 수 있다. 2021년 섬 초기화 버그 수정은 확인하지 못했다.
- **KG-09** (확인 · Kingdom Two Crowns · 개발자 의도) 개발진은 Infinity Blade의 후손 서사에서 썩음(decay) 설계를 가져와, 왕관을 잃어도 지은 것의 대부분이 남게 했다. — [Kingdom Two Crowns and the practical intersection of pixel art and roguelike design (Game…](https://www.gamedeveloper.com/design/-i-kingdom-two-crowns-i-and-the-practical-intersection-of-pixel-art-and-roguelike-design)
- **KG-10** (확인 · Kingdom Two Crowns · 메커닉) Two Crowns의 조각상은 보석으로 열고 동전을 한 번 내면, 왕이 죽을 때까지 모든 섬에서 효과가 이어진다. — [Kingdom Two Crowns – Statues (Magic Game World)](https://www.magicgameworld.com/kingdom-two-crowns-statues/)
- **KG-11** (확인 · Kingdom Two Crowns · 메커닉) Two Crowns에서 겨울(16일) 동안 농부는 밭을 갈지 못하고 베리 채집으로 돌아선다. 왕국이 이미 너무 크면 채집이 훨씬 덜 나온다. — [Kingdom Wiki – Farmers (old revision)](https://kingdomthegame.fandom.com/wiki/Farmers?oldid=9104)
- **KG-12** (확인 · Kingdom Two Crowns · 실패 사례) 스팀 토론에서 플레이어들은 겨울을 «15일 동안 자리 비우기»라 부르며 할 일이 없는 구간이라고 비판했다. — [Winter or in other words: 15 days of afking :: Kingdom Two Crowns General Discussions](https://steamcommunity.com/app/701160/discussions/0/2806204040002647046/)
- **KG-13** (확인 · Kingdom Two Crowns · 개발자 의도) 개발진은 2019년 Winter Update Beta 1.0.3에서 겨울 사냥을 넣어, 주민이 겨울에도 할 일을 갖게 했다. — [Citizens more active during winter in Kingdom Two Crowns (Kingdom official news)](https://www.kingdomthegame.com/news/2019/3/26/citizens-more-active-during-winter-in-kingdom-two-crowns)
- **KG-14** (확인 · Kingdom Two Crowns · 반응) GameGeeker 리뷰는 적 출현 패턴을 익히고 나면 방어전이 기계적 작업이 되어 긴장이 사라진다고 비판했다. — [Kingdom Two Crowns review (GameGeeker)](https://gamegeeker.com/games/kingdom-two-crowns-701160/review?market=DE)
- **KG-15** (정정 · Kingdom Two Crowns · 반응) Push Square는 7/10을 주고 «잘 다듬어진, 훌륭히 단순한» 전략 게임이라 칭찬했지만, 상호작용이 적고 속도가 느린 점을 단점으로 꼽았다. — [Review: Kingdom Two Crowns - Enjoyably Minimalist Strategy (Push Square)](https://www.pushsquare.com/reviews/ps4/kingdom_two_crowns)
  - 정정: 확인된 것: 제목 «Enjoyably Minimalist Strategy», 7/10, 잘 다듬어지고 훌륭히 단순하며 더 많은 플레이어가 참여하게 하는 영리한 변화를 넣었다는 평. 확인 못 한 것: 상호작용이 적고 속도가 느리다는 Push Square의 단점 문구. 다른 평론가가 «너무 느긋하게 느껴질 수 있다»고 쓴 것만 나왔다.
- **KG-16** (확인 · Kingdom Two Crowns · 메커닉) Two Crowns의 후반 공세는 폭탄을 호위해 Cliff Portal 안 심장까지 옮기고 동전 5개를 더 내 불을 붙이는 것이다. — [Kingdom Two Crowns – How to Destroy a Cliff Portal? (Magic Game World)](https://www.magicgameworld.com/kingdom-two-crowns-how-to-destroy-a-cliff-portal/)

### TAB — They Are Billions / Age of Darkness: Final Stand

- **TAB-01** (정정 · They Are Billions · 메커닉) They Are Billions에서 금은 사실상 일꾼 집에서만 나오고, 집을 짓고 업그레이드하고 다른 건물로 받쳐 줘야 금이 늘어난다. — [They Are Billions gold how to get (Twinfinite)](https://twinfinite.net/guides/they-are-billions-gold-how-get/)
  - 정정: 금은 주로 주민(집)에게서 나오고 주민이 많을수록 늘어난다. 사령부와 금 광맥 위 채석장도 금을 낸다. 은행은 범위 안 집의 금 수입을 올린다(2017~2019년 자료 기준). / 금은 주로 주민 집(텐트·오두막·석조 주택)에서 나오고, 은행·시장 같은 건물이 그 수입을 늘린다. 금 매장지 위에 지은 채석장도 금을 캔다. 집이 유일한 출처는 아니다. Twinfinite 글은 2017~2018년 무렵 글이다.
- **TAB-02** (확인 · They Are Billions · 메커닉) They Are Billions의 집은 천막→오두막→석조 집 세 단계이고, 오두막은 목재 작업장, 석조 집은 석재 작업장 연구로 열리며 석재 작업장은 목재 작업장에서 열린다. — [List of buildings and their statistics | They Are Billions Game guide (GamePressure)](https://gamepressure.com/they-are-billions/list-of-buildings-statistics/zcaaee)
- **TAB-03** (확인 · They Are Billions · 메커닉) They Are Billions의 은행은 반경 안 집들의 금 생산을 올리며, 가이드 하나는 반경 12칸에 30%라고 쓴다. — [They Are Billions Steam discussions (bank/market)](https://steamcommunity.com/app/644930/discussions/0/2549465882928928182)
- **TAB-04** (확인 · They Are Billions · 개발자 의도) Numantian Games 개발 블로그는 시장이 주변 집의 식량 소비를 줄인다고 밝혔다. — [They Are Billions Update: Build Your Colony (Numantian Games blog)](https://numantiangames.com/News/2017-10-02-they-are-billions-update-build-your-colony/)
- **TAB-05** (확인 · They Are Billions · 메커닉) They Are Billions에서 테슬라 탑은 건설 가능 영역을 넓히고, 집·제재소·연구소 같은 핵심 건물은 에너지가 있어야 지을 수 있다. — [They Are Billions energy how to get (Twinfinite)](https://twinfinite.net/guides/they-are-billions-energy-how-get/)
- **TAB-06** (확인 · They Are Billions · 메커닉) They Are Billions에서 감염체 하나가 건물에 들어가면 안의 주민이 모두 감염체가 되고, 그들이 다른 건물을 감염시켜 번진다. — [They Are Billions on Steam](https://store.steampowered.com/app/644930/They_Are_Billions/)
- **TAB-07** (확인 · They Are Billions · 개발자 의도) Numantian Games 개발 노트는 벽이 감염체를 막지만 부서질 수 있으니 벽을 여러 겹 고리로 둘러 다음 고리에서 막으라고 권한다. — [They Are Billions Update: Defend Your Colony (Numantian Games blog)](https://numantiangames.com/News/2017-09-14-they-are-billions-update-defend-your-colony/)
- **TAB-08** (확인 · They Are Billions · 메커닉) They Are Billions에서는 맵에 남은 감염체가 마지막 대군(final swarm)과 함께 몰려오므로, 플레이어는 마지막 웨이브 전에 맵을 청소하라고 조언한다. — [They Are Billions Steam discussion (final swarm)](https://steamcommunity.com/app/644930/discussions/0/1642044369652533252)
- **TAB-09** (정정 · They Are Billions · 반응) 2019년 콘솔판 리뷰 하나는 They Are Billions를 좋게 보면서도 기지 건설이 번거롭고 미세 관리로 늘어진다고 비판했다. — [They Are Billions Review (TheSixthAxis)](https://www.thesixthaxis.com/2019/07/10/they-are-billions-review/)
  - 정정: 이 글귀는 Gamereactor의 They Are Billions 앞서 해보기(PC) 인상기에 나온다. 2019년 콘솔판 리뷰들(Screen Rant, The Pixels 등)은 PC용으로 설계된 UI와 패드 조작 때문에 미세 관리가 어렵다고 비판했다. TheSixthAxis 글과 짝을 짓는 근거는 찾지 못했다. / «번거로운 기지 건설이 미세 관리로 늘어진다»는 평은 2019년 콘솔판 리뷰가 아니라 Gamereactor의 PC 앞서 해보기 체험기에서 나왔다. 2019년 콘솔판 리뷰(The Pixels·Screen Rant·God is a Geek)는 패드로 정밀하게 조작하기 어렵고 유닛 미세 관리가 거의 불가능하다고 비판했다.
- **TAB-10** (정정 · They Are Billions · 반응) PS4판 리뷰들은 They Are Billions가 한 번의 실수를 가혹하게 벌하고, 아이언맨 저장이라 일이 꼬여도 되돌릴 수 없다고 지적했다. — [Stop The Horde – They Are Billions PS4 review (The Review Geek)](https://www.thereviewgeek.com/theyarebillions-ps4gamereview/)
  - 정정: PS4판 리뷰 여럿이 난도가 가혹하다고 했다(방어선의 틈 하나로 감염이 퍼짐, 사령부가 뚫려 몇 시간 진행을 잃음, «시간을 존중하지 않는다»). 아이언맨 저장이라 되돌릴 수 없다는 점과 가벼운 플레이어에게 문제라는 점은 한 리뷰(The Review Geek)의 말로만 남아 있다. 다른 리뷰로는 확인되지 않았다.
- **TAB-11** (확인 · Age of Darkness: Final Stand · 메커닉) Age of Darkness: Final Stand에서 주민이 대부분의 일을 하며, 집을 짓고 자원을 모으고 병력 목록을 채우고, 농장은 인구가 있어야 식량을 낸다. — [How to survive in Age of Darkness: Final Stand (PC Gamer)](https://www.pcgamer.com/how-to-survive-in-age-of-darkness-final-stand)
- **TAB-12** (확인 · Age of Darkness: Final Stand · 메커닉) Age of Darkness: Final Stand의 건물은 유지비가 있고 인구를 묶으며, 한 패치는 농장의 금 유지비를 20에서 16으로 낮췄다. — [Age of Darkness: Final Stand patch notes (SteamDB)](https://steamdb.info/patchnotes/8990486)
- **TAB-13** (확인 · Age of Darkness: Final Stand · 메커닉) Age of Darkness: Final Stand 커뮤니티 조언은 집을 2단계(Lodge)로 올리면 금이 크게 늘고, 3단계 전에 빈 땅을 2단계 집으로 채우라고 권한다. — [Age of Darkness Final Stand: Basic Guide (GamePretty)](https://gamepretty.com/age-of-darkness-final-stand-basic-guide/)
- **TAB-14** (확인 · Age of Darkness: Final Stand · 메커닉) Age of Darkness: Final Stand에서 Death Night가 끝나면 무작위로 뽑힌 축복(Blessing) 셋 가운데 하나를 고른다. — [What are Blessings – How to get them in Age of Darkness: Final Stand (Pro Game Guides)](https://progameguides.com/age-of-darkness-final-stand/what-are-blessings-how-to-get-them-in-age-of-darkness-final-stand/)
- **TAB-15** (정정 · Age of Darkness: Final Stand · 메커닉) Age of Darkness: Final Stand의 Death Night에는 Malice라는 무작위 벌칙이 붙어, 방어탑 사거리를 줄이거나 훈련소에서 훈련한 병력이 Nightmare가 되어 떠나게 한다. — [In survival RTS Age of Darkness, thousands of enemies aren't the only threat (PC Gamer)](https://www.pcgamer.com/in-survival-rts-age-of-darkness-thousands-of-enemies-arent-the-only-threat)
  - 정정: Malice는 Death Night마다 붙어 플레이어 쪽에 불리한 효과를 주는 무작위 저주이고, Nightmare도 매번 다른 보너스를 받는다. 예시로 든 탑 사거리 감소와 «훈련소에서 Nightmare가 나옴»은 원문으로 다시 확인해야 한다.
- **TAB-16** (확인 · Age of Darkness: Final Stand · 반응) Player2 리뷰는 Age of Darkness: Final Stand 캠페인에서 기지 건설 기회가 매우 적고 자원이 빠듯한 점을 실망스럽다고 했다. — [Age of Darkness: Final Stand Review – Real Time Survival (Player2)](https://www.player2.net.au/2025/03/age-of-darkness-final-stand-review-real-time-survival/)

### DS — Diplomacy is Not an Option / Stronghold / Manor Lords

- **DS-01** (확인 · Diplomacy is Not an Option · 메커닉) DINO에서는 집이 인구 상한을 정하고, 일에 배정되지 않은 인구를 일꾼 건물과 새 병력이 함께 나눠 쓴다. — [Diplomacy is Not an Option Guide for Beginners (TechRaptor)](https://techraptor.net/gaming/guides/diplomacy-is-not-option-guide-for-beginners)
- **DS-02** (확인 · Diplomacy is Not an Option · 실패 사례) 한 Steam 토론은 DINO의 반복감 가운데 일부를 생선 오두막과 제재소를 계속 옮겨 지어야 하는 데서 찾았다. — [Diplomacy is Not an Option :: Steam Community discussion](https://steamcommunity.com/app/1272320/discussions/0/603021130830228044)
- **DS-03** (확인 · Diplomacy is Not an Option · 반응) Cubed3 리뷰는 DINO를 미세 관리가 매우 많은 게임이라고 평했다. — [Diplomacy is Not an Option review (Cubed3)](https://www.cubed3.com/games/reviews/pc/diplomacy-is-not-an-option)
- **DS-04** (정정 · Stronghold: Definitive Edition · 메커닉) Stronghold는 0~100 인기도에서 50을 기준으로 농민이 들어오거나 떠나게 한다. — [Stronghold Definitive Edition: Economy Guide (Stronghold Wiki)](https://stronghold.fandom.com/wiki/Stronghold_Definitive_Edition:_Economy_Guide)
  - 정정: Stronghold Definitive Edition 경제 가이드 기준으로 인기도가 50 이상이면 농민이 인기도와 상관없이 일정한 속도로 들어온다. 50 미만이면 일정한 속도로 떠난다. 50에서 멀어져도 들어오고 나가는 속도는 바뀌지 않는다. 인기도 값은 비상 수단(배급 축소·증세)을 쓸 여유로만 작동한다. / 인기도 50 이상이면 농민이 들어오고 50 미만이면 떠난다는 것까지만 확실하다. 50에서 얼마나 위·아래인지가 들고 나는 속도를 바꾸는지는 출처끼리 갈린다(Stronghold Nation 계열 가이드: «The extent of your Popularity above or below 50 doesn't affect the rate»). 그러니 «높을수록 더 빨리»는 빼거나 미확인으로 둔다.
- **DS-05** (확인 · Stronghold (series) · 메커닉) Stronghold에서는 모닥불에서 놀던 농민을 모집하면 병사가 되고, 병사가 된 뒤에는 식량을 먹지 않고 세금을 내지 않으며 인구로 세지 않는다. — [Peasant (Stronghold Wiki)](https://stronghold.fandom.com/wiki/Peasant)
- **DS-06** (확인 · Stronghold: Definitive Edition · 메커닉) Stronghold: Definitive Edition에서 놀고 있는 농민은 모닥불에 최대 24명까지 모이고, 그 자리가 차고 새 일자리가 없으면 인구 증가가 멈춘다. — [Stronghold Definitive Edition: Economy Guide (Stronghold Wiki)](https://stronghold.fandom.com/wiki/Stronghold_Definitive_Edition:_Economy_Guide)
- **DS-07** (확인 · Stronghold (series) · 메커닉) Stronghold의 세금은 단계가 오를수록 수입이 늘고 인기도가 깎이며, 반대로 뇌물(bribe)은 금고 돈으로 인기도를 산다. — [Popularity (Stronghold Wiki)](https://stronghold.fandom.com/wiki/Popularity)
- **DS-08** (정정 · Stronghold Crusader · 메커닉) Stronghold Crusader의 배급은 없음 -8부터 두 배 +8까지 인기도를 바꾸고, 식량 종류가 많으면 최대 +3이 더 붙는다. — [Granary (Stronghold Crusader) (Stronghold Wiki)](https://stronghold.fandom.com/wiki/Granary_(Stronghold_Crusader))
  - 정정: 확인된 것은 Crusader의 반 배급 -4(플레이어 보고)와 식량 종류 보너스가 있다는 사실뿐이다. -8·+4·+8과 종류 보너스 최대 +3은 게임 안 곡물창고 화면이나 Crusader 위키로 다시 봐야 한다. Crusader 2 값(없음 -30, 1/4 -20, 반 -10, 두 배 +15, 종류 2/3/4가지 +4/+9/+15)과 섞으면 안 된다.
- **DS-09** (미검증 · Stronghold Crusader: Definitive Edition · 반응) Checkpoint Gaming은 Stronghold Crusader: Definitive Edition의 경제와 방어 루프가 원작처럼 여전히 만족스럽고 중독적이라고 칭찬했다. — [Stronghold Crusader: Definitive Edition Review – Your popularity is falling (Checkpoint G…](https://checkpointgaming.net/reviews/2025/07/stronghold-crusader-definitive-edition-review-your-popularity-is-falling)
- **DS-10** (정정 · Manor Lords · 메커닉) Manor Lords의 버제스 구획은 집 뒤에 땅이 충분할 때만 뒷마당 확장을 붙일 수 있고, 텃밭은 구획 크기에 따라 수확이 늘지만 닭장은 크기와 상관없다. — [Burgage Plot (Manor Lords Wiki, Hooded Horse)](https://hoodedhorse.com/wiki/Manor_Lords/Burgage_Plot)
  - 정정: 확인된 것은 둘이다. 버제스 구획은 뒤쪽 공간이 충분해야 뒷마당 확장을 붙인다(크기 기준치는 없다). 텃밭은 레벨 1 확장이고 심는 비용이 크기에 따라 늘어난다. 텃밭 수확이 크기에 비례한다는 것과 닭장 생산이 크기와 무관하다는 것은 확인하지 못했다.
- **DS-11** (확인 · Manor Lords · 메커닉) Manor Lords에서 버제스 구획 레벨 2가 필요한 뒷마당 확장(대장장이·제화공·재단사 공방 등)을 지으면 그 집에 사는 가족이 모두 장인이 된다. — [Manor Lords guide (Game8)](https://game8.co/games/Manor-Lords/archives/451055)
- **DS-12** (정정 · Manor Lords · 메커닉) Manor Lords의 버제스 구획을 레벨 1에서 2로 올리려면 지역에 교회와 우물이 있어야 하고, 일부 조건은 거리로 채워져 구획마다 남은 조건이 다르다. — [How to upgrade Manor Lords burgage plots (PCGamesN)](https://www.pcgamesn.com/manor-lords/burgage-plots-upgrade)
  - 정정: 레벨 1→2: 우물, 목조 교회, 시장의 연료 공급, 서로 다른 식량 두 가지, 아마포·가죽·실 가운데 하나, 구획마다 목재 4개. 레벨 2→3: 우물, 에일이 공급되는 선술집, 작은 석조 교회(레벨 2 교회), 시장의 연료 공급. 거리 조건이 있는지는 확인하지 못했다. 얼리 액세스 시기 자료라 지금 판과 다를 수 있다.
- **DS-13** (확인 · Manor Lords · 메커닉) Manor Lords의 민병은 공짜지만 복무하는 동안 경제에서 일꾼을 빼 가고, 호위대와 용병은 돈이 드는 대신 경제를 흔들지 않는다. — [Combat Guide: Militia, Retinue, and Tactics (Casual Game Guides)](https://www.casualgameguides.com/walkthroughs/manor-lords/combat-militia-retinue-tactics)
- **DS-14** (확인 · Manor Lords · 반응) Gamegeeker 리뷰는 Manor Lords에 뚜렷한 중후반이 없고, 건물과 업그레이드가 빨리 바닥나 일정 크기를 넘으면 «새것 없음» 정체에 빠진다고 비판했다. — [Manor Lords review (Gamegeeker)](https://gamegeeker.com/games/manor-lords/review?market=FR)
- **DS-15** (확인 · Manor Lords · 개발자 의도) Manor Lords 개발자 Greg Styczeń은 자유로운 구획 시스템이 범위 효과, 특히 원형 범위와 잘 맞지 않는다고 말했다. — [Runaway city building success Manor Lords is getting a major overhaul to its systems (PC …](https://www.pcgamer.com/games/strategy/runaway-city-building-success-manor-lords-is-getting-a-major-overhaul-to-its-systems-its-not-just-a-new-feature-or-two-its-a-full-rework/)

### RD — Bad North / Kingdoms and Castles / Farthest Frontier / Cataclismo / RimWorld

- **RD-01** (확인 · Bad North · 메커닉) Bad North에서는 바이킹이 집에 불을 지르고, 다 타 버린 집은 동전을 주지 않는다. — [Bad North (Wikiwand, Wikipedia 미러)](https://www.wikiwand.com/en/articles/Bad_North)
- **RD-02** (확인 · Bad North · 메커닉) Bad North에서 섬을 버리고 물러나면 새 섬은 열리지만 동전은 받지 못한다. — [Bad North review (Nintendo Life)](https://www.nintendolife.com/reviews/switch-eshop/bad_north)
- **RD-03** (확인 · Kingdoms and Castles · 메커닉) Kingdoms and Castles의 바이킹 약탈자는 성이 아니라 주민 납치·살해, 자원 약탈, 마을 방화를 노린다. — [Kingdoms and Castles (Steam 상점)](https://store.steampowered.com/app/569480/Kingdoms and Castles)
- **RD-04** (정정 · Kingdoms and Castles · 메커닉) Kingdoms and Castles의 우물은 물을 주고 행복을 올리며, 주변의 화재 위험을 낮춘다. — [Kingdoms and Castles Buildings (Bloxodes wiki)](https://bloxodes.com/wiki/kingdoms-and-castles/buildings)
  - 정정: 출처가 그렇게 적은 것은 맞다. 우물과 화재 위험의 관계는 Steam 토론(장원 둘레에 우물이 몇 개 있어야 불이 안 나는지)으로 따로 뒷받침된다. 그러나 우물의 행복 효과, Hovel 5명, Cottage 12명에 가사 일꾼 2명은 집계 사이트 한 곳에서만 나왔고 공식 자료로 확인하지 못했다. 같은 검색에서 12라는 수치는 모드 변경 기록의 Fancy house(12침대에서 8침대로 줄임)로만 나왔다. 수치는 '집계 사이트 기준, 확인되지 않음'으로 남겨야 한다.
- **RD-05** (확인 · Kingdoms and Castles · 설계론) Kingdoms and Castles 공략은 행복을 올리는 시설을 주거 구역 가까이에 두라고 권한다. — [Kingdoms and Castles: 90+ Hours Guide 2021 (Tips & Tricks)](https://kosgames.com/?p=2786)
- **RD-06** (확인 · Kingdoms and Castles · 반응) Kingdoms and Castles의 Steam 리뷰 요약은 초반은 재미있지만 중후반 콘텐츠가 반복적이거나 빈약해 재미가 떨어진다고 정리한다. — [Kingdoms and Castles Review Summary (Vaporlens)](https://vaporlens.app/app/569480/kingdoms_and_castles)
- **RD-07** (확인 · Farthest Frontier · 메커닉) Farthest Frontier의 선호도(desirability)는 그 지역이 얼마나 살기 좋은지를 재며, 주거에만 영향을 주고 주거를 올리려면 높은 점수가 필요하다. — [Farthest Frontier 공식 사이트 글](https://www.farthestfrontier.com/?p=1754)
- **RD-08** (확인 · Farthest Frontier · 개발자 의도) Farthest Frontier 개발사는 선호도가 세수를 올리고 더 높은 마을 등급을 여는 데 도움이 된다고 밝혔다. — [The State of Early Access - Update #02 (Crate Entertainment forums)](https://forums.crateentertainment.com/t/the-state-of-early-access-update-02/122168)
- **RD-09** (확인 · Farthest Frontier · 설계론) Farthest Frontier 공략은 장식과 시장·학교 같은 서비스 건물을 집 가까이 두고, 무두질 작업장·퇴비장은 집에서 떨어뜨리라고 권한다. — [Farthest Frontier Desirability Guide (TechRaptor)](https://techraptor.net/gaming/guides/farthest-frontier-desirability-guide)
- **RD-10** (확인 · Farthest Frontier · 메커닉) Farthest Frontier의 Steam 상점 페이지는 마을이 번영할수록 약탈자와 외국 군대가 끌려온다고 소개한다. — [Farthest Frontier (Steam 상점)](https://store.steampowered.com/app/1044720/Farthest_Frontier/)
- **RD-11** (정정 · Farthest Frontier · 개발자 의도) Farthest Frontier 개발 일지 #04는 탑을 정해진 범위만 지키는 방어로 설명하고, 약탈자가 탑이 덮지 않는 빈틈을 찾을 수 있다고 경고한다. — [Journey Log #04 - Battle for Survival (Crate Entertainment forums)](https://forums.crateentertainment.com/t/journey-log-04-battle-for-survival/114702)
  - 정정: 일지 #04에서 확인된 것은 네 가지다. 성벽·탑의 돌 업그레이드. '약탈자가 수와 공성 무기로 성벽과 탑을 압도할 수 있다'. 병영이 마지막 방어선이라는 점. 전투를 끌 수 있다는 점. 탑의 경비병이 가까운 적을 쏜다는 내용은 공식 가이드(전투 항목)에 있다. 빈틈 경고는 일지 원문에서 확인되지 않았고, 빈틈을 말하는 곳은 신뢰하기 어려운 팬 위키(shapes.inc)의 '킬존' 설명뿐이었다. 빈틈 경고는 빼거나 '확인되지 않음'으로 표시해야 한다.
- **RD-12** (확인 · Farthest Frontier · 메커닉) Farthest Frontier v0.9.3부터 약탈자는 마을로 곧장 달려오지 않고, 유효한 표적을 본 뒤에 돌격한다. — [Farthest Frontier v0.9.3 + Hotfixes (Crate Entertainment forums)](https://forums.crateentertainment.com/t/farthest-frontier-v0-9-3-hotfixes/137612)
- **RD-13** (확인 · Cataclismo · 메커닉) Cataclismo의 원자재 건물은 일꾼을 내보내 가장 가까운 창고나 성채로 자재를 나르게 하고, 거리가 짧을수록 채집이 빠르다. — [Cataclismo Buildings (Hooded Horse wiki)](https://hoodedhorse.com/wiki/Cataclismo/Buildings)
- **RD-14** (정정 · Cataclismo · 반응) PC Gamer는 Cataclismo 리뷰에서 건설 메커닉은 뛰어나지만 게임이 때때로 고역처럼 느껴진다고 평했다. — [Cataclismo review (PC Gamer)](https://pcgamer.com/games/strategy/cataclismo-review)
  - 정정: PC Gamer 리뷰의 '건설 메커닉은 뛰어나지만 때때로 고역' 평가는 확인된다(79점). Vaporlens의 Steam 요약은 '블록 단위 건설이 지루하고 시간이 걸린다'를 마찰 요인 가운데 하나로 들 뿐이다. 이것이 가장 많은 불만이라는 점, 자원 채집도 함께 느리다는 불만이 있다는 점은 확인되지 않았다. 리뷰가 2024년 얼리 액세스 판을 다뤘다는 점도 검색으로 확인하지 못했다.
- **RD-15** (확인 · RimWorld · 메커닉) RimWorld 습격 점수는 정착지 부와 정착민 수로 정해지며, 바닥에 지은 건물은 부의 절반만 친다. — [Raid points (RimWorld Wiki)](https://rimworldwiki.com/wiki/Raid_points)
- **RD-16** (확인 · RimWorld · 반응) RimWorld 위키는 부가 습격 점수의 핵심 입력이지만, 그 영향은 흔히 과장되고 엉뚱한 부의 원인이 탓을 듣는다고 적는다. — [Wealth management (RimWorld Wiki)](https://mail.rimworldwiki.com/wiki/Wealth_management)

### CS — Frostpunk / Against the Storm / Northgard

- **CS-01** (정정 · Against the Storm · 메커닉) Against the Storm의 적대도(Hostility)는 공터를 열고, 주민이 늘고, 나무꾼을 배정할수록 난이도별로 정해진 만큼 오른다. — [Hostility – Against the Storm Wiki (Hooded Horse)](https://hoodedhorse.com/wiki/Against_the_Storm/Hostility)
  - 정정: 표의 수치는 위키(1.9.8 기준)의 것이고, 같은 위키에는 «나무꾼 수가 아니라 벤 나무 10그루마다 적대도 +2»라는 다른 설명도 있다. 지금 판에서 나무꾼 쪽 적대도가 어떻게 매겨지는지는 패치 노트로 다시 봐야 한다. 금지 이벤트를 끝내면 위험·금지 공터 적대도가 2, 작은 공터가 1 줄고 이 효과는 소급된다. / 일반 지도에서는 맞지만 Sealed Forest에서는 나무꾼 배정이 적대도를 올리지 않고 벤 나무 10그루마다 +2다. 위키 표는 옛 판 수치일 수 있다. 그 뒤 업데이트에서 나무꾼 적대도가 올랐으므로 지금 판 수치는 표와 다를 수 있다. 공터 적대도를 고정값으로 바꿨다는 부분은 확인하지 못했다.
- **CS-02** (확인 · Against the Storm · 개발자 의도) Eremite Games는 devlog 7에서 해금 건물이 적은 초반에는 청사진 드래프트를 써도 정착지 배치가 매우 비슷해질 수 있다고 인정했다. — [Devlog 7 – Blueprint drafting system and more (Eremite Games)](https://eremitegames.com/devlog-7-blueprint-drafting-system-and-more/page/2/?et_blog)
- **CS-03** (확인 · Against the Storm · 개발자 의도) Eremite Games는 Update 1.4 미리보기에서 청사진이 너무 많아지는 것(blueprint bloat)이 게임에 해롭다고 보고 이를 줄이는 장치를 여럿 넣었다고 밝혔다. — [Yet another sneak peek of Update 1.4 (Eremite Games)](https://eremitegames.com/yet-another-sneak-peek-update-1/)
- **CS-04** (확인 · Against the Storm · 메커닉) Against the Storm의 메타 도시 Smoldering City에서는 Citadel 자원(Food Stockpiles, Machinery, Artifacts)을 써서 great works를 짓고 업그레이드한다. — [The Smoldering City – Against the Storm Wiki (Hooded Horse)](https://wiki.hoodedhorse.com/Against_the_Storm/The_Smoldering_City)
- **CS-05** (확인 · Against the Storm · 메커닉) Against the Storm에서는 한 종족의 결의(Resolve)가 결의 문턱(Resolve Threshold)에 이르면 그 종족이 평판(Reputation)을 만들기 시작한다. — [Reputation – Against the Storm Wiki (Hooded Horse)](https://wiki.hoodedhorse.com/Against_the_Storm/Reputation)
- **CS-06** (확인 · Against the Storm · 메커닉) 개발자 패치 노트에 따르면 Against the Storm 주민은 현재 결의가 0 이하일 때만 떠난다. — [Eremite Games patch notes (eremitegames.com)](https://eremitegames.com/?p=236213)
- **CS-07** (확인 · Against the Storm · 반응) Destructoid 리뷰는 Against the Storm이 정착지마다 다른 과제를 줘서 쉽게 질리지 않는다고 평했다. — [Review: Against the Storm (Destructoid)](https://www.destructoid.com/review-against-the-storm/)
- **CS-08** (확인 · Against the Storm · 반응) Steam 사용자 리뷰를 모은 Vaporlens 요약은 Against the Storm이 늘 새 도시로 던져 넣어 지루한 후반을 없앤다고 정리한다. — [Against the Storm – Vaporlens stats (Steam review aggregate)](https://vaporlens.app/app/1336490/against_the_storm/stats)
- **CS-09** (확인 · Frostpunk · 메커닉) Frostpunk 플레이어들은 발전기 열 범위를 넓힐지 증기 허브를 세울지 저울질하고, 허브 범위 사이 빈틈에는 난방이 필요 없는 건물을 끼워 넣는다. — [steam hub vs generator range upgrade (GOG Frostpunk forum)](https://www.gog.com/forum/frostpunk/steam_hub_vs_generator_range_upgrade)
- **CS-10** (확인 · Frostpunk · 개발자 의도) Frostpunk 개발진은 PC Gamer 인터뷰에서 법전(book of laws)으로 결정을 차례로 늘어놓아 «점진적 정상화(끓는 개구리 효과)»를 다루려 했다고 말했다. — [Frostpunk developers on hope, misery, and the ultimately terrifying book of laws (PC Game…](https://www.pcgamer.com/frostpunk-developers-on-hope-misery-and-the-ultimately-terrifying-book-of-laws)
- **CS-11** (확인 · Frostpunk · 메커닉) PC Gamer는 Frostpunk에서 주민의 요구와 불평을 무시하면 불만(discontent)이 쌓이고, 불만이 희망과 함께 가장 중요한 두 자원 가운데 하나라고 설명했다. — [You can't please everyone in survival city builder Frostpunk (PC Gamer)](https://www.pcgamer.com/you-cant-please-everyone-in-survival-city-builder-frostpunk)
- **CS-12** (정정 · Frostpunk · 메커닉) Frostpunk 본편 시나리오의 마지막 폭풍은 기온을 섭씨 -150도까지 떨어뜨리고, 정점에서는 모두 집으로 돌려보내 추위를 버티게 해야 한다고 Fandom 가이드가 설명한다. — [Frostpunk laws: surviving the storm (Fandom)](https://www.fandom.com/articles/frostpunk-laws-surviving-storm)
  - 정정: -150°C는 플레이어 증언과 TV Tropes가 받치는 수치다. -120°C는 Steam 토론의 수치가 아니라 위키의 수치다. Steam 토론은 오히려 «-150은 New Home, -120은 Endless 모드»라고 갈라 말한다. «모두 집으로 보내 버티게 한다»는 조언은 출처를 확인하지 못했다. / 마지막 폭풍의 최저 기온은 출처마다 다르다. Hard 난이도에서는 -150도라는 보고가 있고, 팬 위키와 일부 Steam 글은 폭풍 정점을 -120도로 적는다. 정점에 바깥 활동(정찰대 등)을 거두고 버티게 하라는 조언은 다른 공략에도 나온다.
- **CS-13** (확인 · Frostpunk 2 · 반응) indie-games.eu 리뷰는 Frostpunk 2가 처음에는 재밌지만 중반과 후반에 너무 반복된다고 비판했다. — [Frostpunk 2 – Bold Sequel with Imperfect Edges (indie-games.eu)](https://www.indie-games.eu/?p=22689)
- **CS-14** (확인 · Northgard · 메커닉) Northgard에서는 영토마다 지을 수 있는 건물 수에 한도가 있고, 영토 정보에 «1-5»처럼 표시된다. — [Construction and Expansion of Territory – Northgard Guide (gamepressure)](https://www.gamepressure.com/northgard-game-guide/construction-and-expansion-of-territory/z7aacb)
- **CS-15** (확인 · Northgard · 반응) PC Gamer 리뷰(84/100)는 Northgard에서 겨울이 커 가는 정착지의 가장 큰 위협이고, 일꾼 배치와 준비로 넘길 수 있다고 평했다. — [Northgard review (PC Gamer)](https://pcgamer.com/northgard-review)
- **CS-16** (확인 · Northgard · 메커닉) Northgard Wolf 클랜 위키는 군사 유닛이 주는 행복이 100% 늘어난다고 적는다. 군사 유닛이 원래 행복을 준다는 뜻이다. — [Wolf Clan – Northgard Wiki (Fandom)](https://northgard.fandom.com/wiki/Category:Wolf_Clan)

### TD — 경제·지원 타워가 있는 타워 디펜스 (Bloons TD 6, Plants vs. Zombies, Mindustry, The Riftbreaker, Dome Keeper)

- **TD-01** (확인 · Bloons TD 6 · 메커닉) Banana Farm의 3번 갈래 3단계 Marketplace를 사면 바나나를 줍지 않아도 라운드마다 돈이 자동으로 들어온다. — [Marketplace (BTD6)](https://www.bloonswiki.com/Marketplace_(BTD6))
- **TD-02** (확인 · Bloons TD 6 · 메커닉) 업그레이드하지 않은 Monkey Village도 자기 범위 안의 모든 원숭이 타워 사거리를 10% 늘린다. — [Monkey Village (BTD6)](https://bloons.fandom.com/wiki/Monkey_Village_(BTD6))
- **TD-03** (확인 · Bloons TD 6 · 메커닉) Monkey Village의 2번 갈래 2단계 Radar Scanner는 범위 안의 모든 타워가 Camo 풍선을 노리고 맞힐 수 있게 해 준다. — [Radar Scanner (BTD6)](https://www.bloonswiki.com/Radar_Scanner_(BTD6))
- **TD-04** (정정 · Bloons TD 6 · 메커닉) Monkey Village의 3번 갈래 Monkey City는 Village 사거리를 늘리고 라운드마다 Dart Monkey 하나를 공짜로 준다. — [Monkey City (BTD6)](https://www.bloonswiki.com/Monkey_City_(BTD6))
  - 정정: Monkey City는 3번 갈래 4단계다. Village 사거리 +10, 라운드마다 무료 Dart Monkey에 더해 범위 안 수입 타워 대부분의 수입을 +20% 올린다(예전 판에서는 15%). 따라서 돈 대신 방어 유닛을 주는 단계가 아니라, 돈 버프와 방어 유닛을 함께 주는 단계다.
- **TD-05** (확인 · Bloons TD 6 · 메커닉) Monkey Village 5단계 Monkeyopolis는 범위 안 Banana Farm을 희생시키고, 희생한 농장의 가치만큼 수입을 낸다. — [Monkeyopolis (BTD6)](https://www.bloonswiki.com/Monkeyopolis_(BTD6))
- **TD-06** (확인 · Bloons TD 6 · 반응) r/btd6 이용자는 라운드를 끌며 능력 수입을 모으는 «stall income»을 지루하다고 했다. — [r/btd6: should Monkey City buff the Monkeynomics ability](https://redlib.andus.dev/r/btd6/comments/1i3ad19/should_monkey_city_buff_the_monkeynomics_ability)
- **TD-07** (확인 · Plants vs. Zombies · 메커닉) Sunflower는 sun 50이 들고 피해를 주지 않으며, 가끔 sun 25를 만든다. — [plant vs zombies list plant](https://buffetwarz.blogspot.com/2011/07/plant-vs-zombies-list-plant.html)
- **TD-08** (확인 · Plants vs. Zombies · 설계론) TechRadar 공략은 싼 Potato Mine으로 시간을 벌어 그 사이 Sunflower를 늘리라고 권한다. — [How to win at Plants vs Zombies](https://www.techradar.com/news/gaming/how-to-win-at-plants-vs-zombies-1100259)
- **TD-09** (확인 · Mindustry · 메커닉) Mindustry 스팀 상점 소개는 컨베이어 벨트로 공급망을 짜 타워에 탄약을 대는 것을 핵심 기능으로 든다. — [Mindustry on Steam](https://store.steampowered.com/app/1127400?l=italian)
- **TD-10** (확인 · Mindustry · 메커닉) Mindustry에서 드릴처럼 출력이 있는 건물은 맞닿은 면의 타워에 직접 아이템을 넣어 준다. — [r/Mindustry: new to the game](https://cal1.lr.ggtyler.dev/r/Mindustry/comments/1ihqkri/new_to_the_game)
- **TD-11** (정정 · The Riftbreaker · 개발자 의도) EXOR Studios COO Pawel Lekki는 The Riftbreaker를 기지를 직접 짓는 동시에 적과 직접 싸우는 플레이로 설명했다. — [EXOR Studios and The Riftbreaker (Tencent GWB, Medium)](https://medium.com/tencentgwb/exor-studios-and-the-riftbreaker-c29f00f3ac8a)
  - 정정: Lekki는 기지 건설과 직접 전투를 함께 하는 게임으로 설명했지만, 다른 인터뷰(GamingBolt)에서는 직접 전투를 피하고 기지 건설·방어 연구에 집중하는 플레이도 가능하다고 했다. 직함은 매체마다 COO 또는 producer and designer로 다르고, 인용 글귀는 원 기사에서만 확인된다.
- **TD-12** (확인 · The Riftbreaker · 실패 사례) xxlgamer.sk 리뷰는 바이옴마다 기지를 세울수록 기지 건설과 자원 관리가 기하급수로 복잡해진다고 평했다. — [The Riftbreaker recenzia (xxlgamer.sk)](https://xxlgamer.sk/recenzie/exit/597)
- **TD-13** (정정 · Dome Keeper · 메커닉) Dome Keeper는 웨이브 사이에 돔 아래에서 Iron·Water·Cobalt를 캐고, 그 자원으로 keeper·돔·gadget을 업그레이드한다. — [Dome Keeper (Dome Keeper Wiki)](https://domekeeper.wiki.gg/wiki/Dome_Keeper)
  - 정정: Iron이 주 업그레이드 재화이고 Cobalt는 보조 재화로 gadget 업그레이드에도 든다. Water는 primary gadget을 overcharge하거나 supplement chamber를 여는 데 쓴다. «Water=gadget 재화, Cobalt=돔 수리 재화»라는 구분은 근거가 없다.
- **TD-14** (확인 · Dome Keeper · 메커닉) Dome Keeper의 primary gadget은 Water로 overcharge할 수 있고, 그 버프는 다음 웨이브(사이클) 한 번에만 걸린다. — [Primary (Dome Keeper Wiki)](https://domekeeper.wiki.gg/wiki/Primary)
- **TD-15** (확인 · Dome Keeper · 메커닉) Dome Keeper의 gadget은 정해진 자리(돔 primary, 돔 표면, 돔 뒷면, 지하실, 갱도, keeper 옷)에만 들어간다. — [Gadgets (Dome Keeper Wiki)](https://domekeeper.wiki.gg/wiki/Gadgets)
- **TD-16** (확인 · Dome Keeper · 반응) Shacknews 리뷰는 Dome Keeper가 짧게 웨이브를 즐기기에는 좋지만 오래 할 거리는 범위가 좁다고 평했다. — [Dome Keeper review: Dig Dug it (Shacknews)](https://shacknews.com/article/132448/dome-keeper-review)

### HB — 판 사이 허브·마을 (Darkest Dungeon, Loop Hero, Arknights, Wildfrost)

- **HB-01** (정정 · Darkest Dungeon · 메커닉) Darkest Dungeon은 던전에서 얻는 가보 4종이 각각 정해진 햄릿 건물만 올린다. — [Darkest Dungeon - Restored to its former glory (Trophies Hunter)](https://trophieshunter.com/games/darkest-dungeon-xbox/achievements/restored-to-its-former-glory)
  - 정정: 기본 짝은 맞다. 다만 Stage Coach 총비용을 적은 가이드 두 곳에 흉상이 들어 있고(한 곳은 흉상 54·초상화 36), Nomad Wagon과 Survivalist는 문장만 쓴다. 그러니 «가보마다 정해진 건물만 올린다»가 아니라 «슬롯마다 주로 쓰는 가보가 정해져 있고, 문장은 모든 슬롯에 공통으로 든다»가 맞다. Crimson Court 구역 설계도 이야기는 이번 검색에서 확인하지 않았다.
- **HB-02** (확인 · Darkest Dungeon · 메커닉) Darkest Dungeon의 Stage Coach는 업그레이드 갈래가 셋이고, 그중 하나가 영웅 보유 상한을 올린다. — [Darkest Dungeon Wiki - Stage Coach (fandom)](https://darkestdungeon.fandom.com/wiki/File:Stage_coach.numrecruits.icon.png)
- **HB-03** (정정 · Darkest Dungeon · 실패 사례) Darkest Dungeon 스팀 이용자들은 햄릿을 다 올린 뒤에는 골드·가보를 쓸 곳이 없다고 말했다. — [Darkest Dungeon Steam Community discussions (late-game gold/heirlooms)](https://steamcommunity.com/app/262060/discussions/0/618459405717382198)
  - 정정: 문장 1,000개 남음·가보 소비처 요청·꾸밈 소비처 요청은 확인된다. 은행 철거 불가 글귀와 구역 관련 글은 확인하지 못했으므로 근거로 쓰지 않는다. 결과에 나온 글은 2015~2019년 것이다. / 얼리 액세스(2015년 무렵) 스팀 글 몇 개에서 햄릿을 다 올린 뒤 골드·가보를 쓸 곳이 없다는 불만이 나왔다(문장 1,000개 넘게 남음, 꾸밈 소비처 요청). 구역(district)은 2017년 Crimson Court DLC로 들어왔으므로 구역 관련 글(은행 철거 불가·구역 안 지음)은 얼리 액세스 시기 글일 수 없다. 이 글귀들은 재확인되지 않았다.
- **HB-04** (확인 · Darkest Dungeon II · 개발자 의도) Red Hook은 Darkest Dungeon II의 판 사이 성장이 진짜 선택을 주지 못했다고 보고, 햄릿을 닮은 Altar of Hope로 바꿨다. — [Darkest Dungeon 2's metagame reboot was expected and necessary (Epic Games Store News)](https://store.epicgames.com/news/darkest-dungeon-2s-metagame-reboot-was-expected-and-necessary)
- **HB-05** (확인 · Loop Hero · 메커닉) Loop Hero 캠프에서는 Mud Hut를 지어 House로 올리면 보급 상한이 오른다. — [Loop Hero – How to Get Maximum Camp Supply (gameplay.tips)](https://gameplay.tips/guides/10308-loop-hero.html)
- **HB-06** (확인 · Loop Hero · 메커닉) Loop Hero 캠프 건물은 여러 자원을 함께 요구하고, 앞 건물을 먼저 지어야 한다. — [Camp Buildings Guide In Loop Hero (Xfire)](https://www.xfire.com/camp-buildings-guide-in-loop-hero)
- **HB-07** (확인 · Loop Hero · 메커닉) Loop Hero에서는 Meadow를 다른 종류 타일 옆에 놓으면 Blooming Meadow가 되어 회복이 늘어난다. — [Loop Hero – Tile Combinations & Resources Guide (MGW)](https://guides.magicgameworld.com/loop-hero-tile-combinations-resources-guide/)
- **HB-08** (확인 · Loop Hero · 메커닉) Loop Hero에서 Vampire Mansion을 Village 옆에 놓으면 Ransacked Village가 되어 Ghoul을 낸다. — [The Loop Hero card combinations you need to know (PC Gamer)](https://www.pcgamer.com/loop-hero-combos-cards-tile)
- **HB-09** (정정 · Loop Hero · 반응) Loop Hero 리뷰들은 캠프 업그레이드에 드는 자원 반복 수집을 가장 큰 약점으로 꼽았다. — [Loop Hero Switch review (Pocket Tactics)](https://www.pockettactics.com/loop-hero/switch-review)
  - 정정: 여러 리뷰가 캠프 업그레이드 자원 수집을 약점(대개 유일하거나 주된 불만)으로 들었지만, 모든 리뷰가 «가장 큰 약점»으로 꼽은 것은 아니고 괴롭지 않다는 리뷰도 있다. 근거 글귀는 Pocket Tactics가 아니라 Nintendo Life Switch 리뷰의 «처음 몇 시간이 지나면 요구량이 크게 늘어 본격적인 반복 수집이 된다»로 대신해야 한다.
- **HB-10** (확인 · Arknights · 메커닉) Arknights 기반 시설(RIIC)에서는 일하는 오퍼레이터의 사기가 줄고, 0이 되면 기지 스킬이 꺼지며, 숙소에서 쉬어야 회복한다. — [Morale: One For All or All for One? (GamePress Arknights)](https://ak.gamepress.gg/node/16911)
- **HB-11** (확인 · Arknights · 메커닉) Arknights 공장에 배정한 오퍼레이터는 각자 기지 스킬로 저장 상한을 올리거나 사기 소모를 줄인다. — [Factory/Base skills (Arknights Terra Wiki)](https://arknights.wiki.gg/wiki/Factory/Base_skills)
- **HB-12** (확인 · Arknights: Endfield · 반응) PC Gamer는 Arknights: Endfield에서 전투를 보러 온 플레이어들이 공장 기지 운영에 빠졌다고 보도했다. — [Came for the combat, stayed to be a factory worker (PC Gamer)](https://pcgamer.com/games/action/came-for-the-combat-stayed-to-be-a-factory-worker-anime-gacha-game-players-are-discovering-they-were-born-to-be-factory-builders-in-arknights-endfield)
- **HB-13** (정정 · Wildfrost · 메커닉) Wildfrost의 Snowdwell은 작은 마을로 시작하고, 도전을 정해진 순서대로 깨면 건물이 지어져 카드가 더 열린다. — [Snowdwell (Wildfrost Wiki)](https://wildfrostwiki.com/Snowdwell)
  - 정정: 건물을 지어 카드를 연다는 점과, 건물 안의 해금(Icebreaker Cabin·Inventor's Hut)을 차례로 깨야 한다는 점은 맞다. Challenge Shrine 도전은 순서 없이 아무 때나 깰 수 있다. Tribe Hall은 튜토리얼을 마치고 Snowdwell로 돌아오면 열린다. Pet House가 첫 건물이라는 순서는 확인하지 못했다.
- **HB-14** (확인 · Wildfrost · 메커닉) Wildfrost의 Inventor's Hut은 전투 중 Redraw Bell을 10번 울리면 열린다. — [Wildfrost: How to unlock every item in the Inventor's Hut (Gameranx)](https://gameranx.com/features/id/464675/article/wildfrost-how-to-unlock-every-item-in-the-inventors-hut-unlock-guide/)
- **HB-15** (확인 · Wildfrost · 반응) GGRecon 리뷰는 Snowdwell의 성장과 해금이 실제 판에는 별 영향을 주지 않는다고 비판했다. — [Wildfrost review: Beautiful, yet devilishly challenging (GGRecon)](https://www.ggrecon.com/reviews/wildfrost-review/)
- **HB-16** (확인 · Wildfrost · 반응) Dexerto 리뷰는 Snowdwell이 자라는 모습이 계속 플레이할 큰 동기라고 칭찬했다. — [Wildfrost review – Adorable cards bring crushing difficulty (Dexerto)](https://jamtest.dexerto.com/gaming/wildfrost-review-adorable-cards-bring-crushing-difficultly-2110451)

### ML — 주민이 전투에 끼는 구조 (Age of Empires 마을 종, Warcraft III, 피신·민병)

- **ML-01** (확인 · Age of Empires II (Definitive Edition) · 메커닉) AoE II의 Town Bell은 마을 회관 둘레 23칸 안의 주민을 가장 가까운 피신 건물로 들여보내고, 다시 누르면 그 건물의 주민이 일터로 돌아간다. — [Town Center (Age of Empires II) - Age of Empires Series Wiki](https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_II))
- **ML-02** (정정 · Age of Empires II (HD, 2013) · 메커닉) AoE II에서 건물에 들어간 주민은 그 건물의 화살 수를 늘리고, 건물 하나가 쏘는 화살은 10발이 상한이라고 스팀 토론에 적혀 있다. — [Age of Empires II (2013) - Steam Community discussion](https://steamcommunity.com/app/221380/discussions/0/144512942754600558)
  - 정정: 10발 상한은 마을 회관(기본 공격 5) 기준이다. 성은 최대 20~21발(출처마다 다름)이고, Teutons 마을 회관은 최대 화살이 +5 늘어난다. «건물 하나가 10발 상한»으로 넓히면 틀린다. / «10발 상한»은 모든 건물이 아니라 마을 회관(대장간 업그레이드 없을 때 주민 1명당 화살 1발, 최대 10발)의 값이다. 성은 기본 5발에 들어간 유닛만큼 늘어 최대 약 20~21발이다(openage 문서는 20발). 공식 자료가 아니라 커뮤니티와 역공학 자료다.
- **ML-03** (확인 · Age of Empires (공식 포럼, AoE II·IV 공통 논의) · 반응) Age of Empires 공식 포럼 글은 Town Bell이 경제 전체를 놀리게 해 득보다 실이 크다며, 공격받는 주민만 피신시키라고 권한다. — [Question about "don't ring the townbell" - Age of Empires Forum](https://forums.ageofempires.com/t/question-about-dont-ring-the-townbell/219723)
- **ML-04** (확인 · Age of Empires IV · 개발자 의도) AoE IV는 출시 뒤 Update 9.1.109(2023-11-14, The Sultans Ascend와 함께)에서 마을 회관에 Town Bell을 넣어, 근처 주민을 버튼 한 번으로 안전한 곳에 부르게 했다. — [Age of Empires IV Update 9.1.109 (official patch notes)](https://ageofempires.com/news/age-of-empires-iv-update-9-1-109)
- **ML-05** (확인 · Age of Empires IV · 메커닉) aoe4world의 마을 회관 항목은 Ring the Town Bell을 «근처 주민 모두에게 알려 가장 가까운 피신 가능 건물로 자동으로 숨게 하는 것»으로 적는다. — [Town Center (Abbasid) - Ring the Town Bell - aoe4world explorer](https://aoe4world.com/explorer/civs/abbasid/buildings/town-center)
- **ML-06** (확인 · Warcraft III · 메커닉) Warcraft III Human은 Town Hall에서 Call to Arms를 울려 근처 Peasant를 한꺼번에 Militia로 바꾸고, 시간이 다 되면 Peasant로 돌아간다. — [Militia (Warcraft III) - Warcraft Wiki](https://warcraft.wiki.gg:443/wiki/Militia_(Warcraft_III))
- **ML-07** (정정 · Warcraft III · 메커닉) Liquipedia의 Town Hall 문서는 Militia 지속 시간을 패치 1.13(2003)에서 45초→40초로 줄이고, 2018년 패치에서 40초→42.5초로 늘린 기록을 남긴다. — [Town Hall - Liquipedia Warcraft Wiki](https://liquipedia.net/warcraft/Town_Hall)
  - 정정: 45초→40초는 패치 1.30.0(2018), 40초→42.5초는 패치 1.36.1(2023)이다. 지금 값은 42.5초(Blizzard 1.36.1 패치 노트, Wowpedia). 1.36.1 PTR 노트 한 판에는 «45→42.5»라는 어긋난 줄도 있다. / Militia 지속 시간: 처음 45초 → 패치 1.30.0(2018-08-08)에서 40초 → 1.36.1(2023년 11월 20일 배포, PTR 노트 기준)에서 42.5초. 정식 패치 노트로 42.5초가 실제 적용됐는지는 확인하지 못했지만, Wowpedia는 42.5초를 적는다.
- **ML-08** (정정 · Warcraft III · 메커닉) Warcraft III 플레이어는 Militia를 방어뿐 아니라 중립 몹(creep) 사냥에 쓰고, Militia는 Peasant보다 경험치를 더 받는다. — [Militia (Warcraft III) - Warcraft Wiki](https://warcraft.wiki.gg:443/wiki/Militia_(Warcraft_III))
  - 정정: 위키는 «Militia also provide more experience compared to Peasants»라고 적는다. 전투 유닛이 되었으니 죽었을 때 상대 영웅에게 Peasant보다 경험치를 더 준다는 뜻이고, Militia 자신이 경험치를 얻는 것이 아니다. / Militia가 Peasant보다 경험치를 더 «받는» 것이 아니다. 전투 유닛이 되었기 때문에 죽었을 때 적에게 경험치를 더 «준다»(WC3에서 경험치는 영웅만 받는다). 크립 사냥에 쓴다는 앞 절은 맞다.
- **ML-09** (확인 · Warcraft III · 메커닉) Warcraft III Orc의 Burrow는 Peon만 최대 4명 들어가고, 들어간 수가 많을수록 공격 간격이 짧아진다(1명 2초→4명 0.8초). — [Burrow (Warcraft III) - Warcraft Wiki](https://warcraft.wiki.gg/wiki/Burrow_(Warcraft_III))
- **ML-10** (확인 · Warcraft III · 메커닉) Hive Workshop의 Orc 기초 안내서는 Burrow를 평소 비워 두었다가 공격받을 때 채우고, Peon 하나는 밖에 두어 Burrow를 고치라고 권한다. — [Warcraft III Orc Basics - classic.hiveworkshop.com](https://classic.hiveworkshop.com/war3/orc/basics.shtml)
- **ML-11** (확인 · Manor Lords · 메커닉) Manor Lords의 민병은 가구의 남편·아들로 채워지고, 징집되면 그들은 하던 일을 멈춘다. — [Family - Manor Lords Wiki (Hooded Horse)](https://wiki.hoodedhorse.com/Manor_Lords/Special:MyLanguage/family)
- **ML-12** (확인 · Manor Lords · 메커닉) GameSpot의 Manor Lords 군대 안내서(초기 앞서 해보기 판)는 전투 뒤 민병과 호위대를 자기 영지로 옮겨야만 해산할 수 있다고 적는다. — [Manor Lords: Army Combat Guide - Militias, Retinues, And Mercenaries (GameSpot)](https://Gamespot.com/articles/manor-lords-army-militia-retinue-mercenary-guide/1100-6523016/)
- **ML-13** (확인 · Farthest Frontier · 메커닉) Farthest Frontier는 마을 회관 위 종 버튼을 눌러 주민을 마을 회관 안으로 피신시키고, 그렇게 들어간 주민은 근처 적에게 자동으로 화살을 쏜다. — [Farthest Frontier official site](https://www.farthestfrontier.com/?p=1210)
- **ML-14** (미검증 · Farthest Frontier · 개발자 의도) Farthest Frontier 개발 일지(Journey Log #04)는 습격자가 커지는 마을을 이득 볼 기회로 보고, 마을이 클수록 습격도 커진다고 설명한다. — [Journey Log #04 - Battle for Survival (Crate Entertainment forums)](https://forums.crateentertainment.com/t/journey-log-04-battle-for-survival/114702)
- **ML-15** (확인 · Dwarf Fortress · 메커닉) Dwarf Fortress의 civilian alert는 모든 민간인(과 동물)을 지정한 burrow 안에 묶고, 밖에 있던 드워프는 하던 일을 바로 취소하고 burrow로 돌아간다. — [Civilian alert - Dwarf Fortress Wiki](https://dwarffortresswiki.org/index.php/Civilian_alert)
- **ML-16** (확인 · Bad North · 메커닉) Bad North에서는 바이킹이 집을 완전히 태우면 그 집에서 금화를 받지 못하고, 금화는 유닛 업그레이드와 지휘관 강화에 쓴다. — [Bad North - Wikipedia](https://en.wikipedia.org/wiki/Bad_North)

### EM — «다 지은 뒤 공허» 문제와 해법

- **EM-01** (정정 · RimWorld · 메커닉) RimWorld은 습격 규모(raid points)를 정착지의 부(storyteller wealth)로 정하고, 지은 건물은 그 부를 절반만 친다. — [Raid points (RimWorld Wiki)](https://rimworldwiki.com/wiki/Raid_points)
  - 정정: 위키 공식은 습격 점수 = (부 점수 + 정착민 점수) × 난이도(threat scale) × 시작 계수 × 적응 계수다. 부만으로 정하지 않는다. 정착민 점수는 부 0~10,000에서 정착민 1명당 15점이고, 부 400,000에서는 1명당 140점이다. 나머지 수치(건물 절반, 14,000/0, 1,000,000/4,200 상한, 최소 35, 최대 10,000)는 위키 그대로다.
- **EM-02** (정정 · Factorio · 메커닉) Factorio에서 적의 진화는 기계가 만든 오염 총량으로 오르고, 습격 무리는 생성기가 흡수한 오염으로 꾸려진다. — [Pollution (Official Factorio Wiki)](https://wiki.factorio.com/Pollution)
  - 정정: 진화 요인은 셋이다. 시간(초당 증가), 생성기 파괴(하나 부술 때마다 증가), 오염(생산량 기준)이다(Lua API의 MapGenPresetEnemyEvolutionSettings). 오염을 가둬도 오염 몫의 진화는 줄지 않는다는 말은 맞다. 하지만 시간과 생성기 파괴 몫은 따로 쌓인다. 옛 판 비용 표 가운데 small 200·medium 1,000은 검색에 나왔지만 behemoth 20,000은 확인하지 못했다.
- **EM-03** (확인 · (장르 전반) Banished 등 city builder · 설계론) Flash of Steel의 2015년 글은 도시 건설 게임이 핵심 퍼즐을 앞에 몰아 두는 것(front-loading)을 큰 문제로 꼽는다. — [a few thoughts on city builders and end games (Flash of Steel)](https://flashofsteel.com/index.php/2015/01/14/a-few-thoughts-on-city-builders-and-end-games)
- **EM-04** (확인 · Banished · 반응) New Game Network 리뷰는 Banished 후반이 농사·건설의 평온한 반복이 되고, 초반 고비를 넘기면 재난이 너무 드물어 의미가 없다고 비판했다. — [Banished review (New Game Network)](https://www.newgamenetwork.com/?p=80545)
- **EM-05** (정정 · Anno 1800 · 개발자 의도) Anno 1800 개발 블로그는 주거 등급을 진행 문턱으로 두고, 주거 건물이 생산 라인과 섬 공간을 다투게 한 것을 고전적 Anno 퍼즐로 설명한다. — [DevBlog: Residential Tiers (Anno Union)](https://www.anno-union.com/en/devblog-residential-tiers/)
  - 정정: 7등급(구세계 5: Farmers·Workers·Artisans·Engineers·Investors, 신세계 2: Jornaleros·Obreros)은 기본판 기준이다. DLC(북극의 Explorers·Technicians, Enbesa의 Shepherds·Elders 등)가 등급을 더 늘린다. 이 DLC 등급 목록은 이번 검색으로 확인하지 못했다.
- **EM-06** (확인 · Anno 1800 · 개발자 의도) Anno 1800은 주민 필요를 인구용과 행복용으로 나누어, 사치품은 인구가 아니라 행복도만 올리는 선택 과제로 두었다. — [DevBlog: Happiness (Anno Union)](https://www.anno-union.com/en/devblog-happiness/)
- **EM-07** (확인 · Against the Storm · 개발자 의도) Against the Storm 공동 창업자 Łukasz Korzanowski는 도시 건설 게임의 가장 좋은 부분인 초반 몇 시간을 잡으려고 설계했다고 밝혔다. — [Against the Storm: Don't sink under the challenge of roguelike city building (Epic Games …](https://store.epicgames.com/en-US/news/against-the-storm-don-t-sink-under-the-challenge-of-roguelike-city-building)
- **EM-08** (확인 · Against the Storm · 메커닉) Against the Storm은 숲 공터(glade)를 열수록 적대도(Hostility)가 쌓이고, 적대도 1레벨마다 전체 결의(Resolve)가 2 떨어진다. — [Hostility (Against the Storm Wiki, Hooded Horse)](https://hoodedhorse.com/wiki/Against_the_Storm/Hostility)
- **EM-09** (확인 · Against the Storm · 실패 사례) Eremite Games는 Devlog 7에서 무작위 건물 드래프트가 생산 사슬을 미완성으로 남길 수 있다는 플레이어 우려를 다루며, 해금이 적은 초반에는 정착지 배치가 매우 비슷해질 수 있다고 인정했다. — [Devlog 7 – Blueprint drafting system and more (Eremite Games)](https://eremitegames.com/devlog-7-blueprint-drafting-system-and-more/)
- **EM-10** (확인 · Thronefall · 개발자 의도) Thronefall은 부서진 건물을 매일 아침 공짜로 되살리지만, 막 되살아난 경제 건물은 그날 골드를 주지 않는다. — [Mastering minimalism and layering complexity with strategy game Thronefall (Game Develope…](https://gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- **EM-11** (확인 · Thronefall · 개발자 의도) Jonas Tyroller는 전략 게임의 눈덩이 효과를 누르려고 적이 골드를 떨구게 해 경제 곡선을 매끄럽게 했다. — [Building a best-selling game with a tiny team – with Jonas Tyroller (The Pragmatic Engine…](https://newsletter.pragmaticengineer.com/p/thronefall)
- **EM-12** (확인 · Kingdom Two Crowns · 반응) GameGeeker 리뷰는 Kingdom Two Crowns가 콘텐츠 양으로 장기 플레이를 버티지 못해 후반에 반복이 드러난다고 비판했다. — [Kingdom Two Crowns review (GameGeeker)](https://gamegeeker.com/games/kingdom-two-crowns-701160/review?market=DE)
- **EM-13** (정정 · Manor Lords · 반응) Twinfinite 리뷰는 Manor Lords 얼리 액세스판에서 정착지가 일정 규모에 이르면 더 할 일이 없다고 비판했다. — [Manor Lords review (Twinfinite)](https://twinfinite.net/reviews/manor-lords-review/)
  - 정정: Windows Central의 글은 Trade Logistics(무역로 가격 상한 25)와 Better Deals(관세 제거)를 중후반 무역을 크게 키우는 업그레이드로 소개한다. 무역이 가장 큰 성장 가속기라는 표현은 확인되지 않았다. Twinfinite 리뷰는 처음 30시간쯤 재미있다고 했고, 플레이어가 무역 금지 같은 제약을 스스로 걸어야 새 판을 시작했다고 했다.
- **EM-14** (확인 · ISLANDERS · 메커닉) ISLANDERS는 점수 문턱을 넘으면 새 섬으로 옮길 수 있고, 건물이 없거나 놓을 자리가 없으면 판이 끝난다. — [Islanders (video game) (Wikipedia)](https://wikipedia.com/wiki/Islanders_(game))
- **EM-15** (확인 · Rise to Ruins · 실패 사례) GameBrain의 사용자 평 요약은 마을 건설·타워 디펜스 하이브리드 Rise to Ruins가 만족스러운 진행 체계가 없어 특히 후반에 목적을 잃고 지친다고 정리했다. — [Rise to Ruins (GameBrain)](https://gamebrain.co/game/rise-to-ruins)

### SP — 공간 퍼즐·인접 보너스와 그 실패

- **SP-01** (확인 · Islanders · 메커닉) Islanders는 건물을 놓을 때 주변에 어떤 건물이 있느냐로 그 건물의 점수가 정해진다. — [Islanders: Console Edition Is Not A Title To Leave Deserted](https://goombastomp.com/islanders-console-edition-review/)
- **SP-02** (확인 · Islanders · 메커닉) Islanders는 배치 점수로 섬 게이지를 채우면 다음 섬으로 넘어가고, 필요한 점수는 해금할 때마다 늘어난다. — [Islanders (video game) - Wikipedia](https://en.wikipedia.org/wiki/Islanders_(video_game))
- **SP-03** (정정 · Islanders · 개발자 의도) Islanders 개발자는 한 번에 업그레이드 선택지가 두 개뿐인 미니멀 도시 건설로 게임을 설명했다. — [A chilled and exclusive interview with ISLANDERS developer GrizzlyGames](https://www.thexboxhub.com/a-chilled-and-exclusive-interview-with-islanders-developer-grizzlygames/)
  - 정정: 미니멀 도시 건설이라는 소개는 공식 상점 소개문(개발사·퍼블리셔 문구)이다. '선택지 두 개'는 개발자 말로 확인되지 않는다. 게임 안에서 그것은 업그레이드가 아니라 다음 건물 팩 두 개 가운데 하나를 고르는 구조로 보인다. 이 표현은 인터뷰어의 소개 글일 수 있다. '두 가지 중 선택'은 오히려 후속작 Islanders: New Shores 리뷰(Siliconera)에 나온다.
- **SP-04** (확인 · Islanders · 반응) Edge는 Islanders에서 점수 때문에 보기 좋은 배치 욕구를 눌러야 할 때가 있다고 평했다. — [Islanders (Edge, via Magzter)](https://magzter.com/ja/stories/Entertainment/Edge/Islanders)
- **SP-05** (확인 · Civilization VI · 메커닉) Civilization VI의 Campus 구역은 옆 산 하나당 과학 +1, 옆 열대우림과 구역 하나당 +½을 받는다. — [Civilization VI City Layout Guide – Best Placements for Districts](https://segmentnext.com/civilization-vi-city-layout-guide-best-placements-for-districts-planning-wonders-building-improvements-tile)
- **SP-06** (확인 · Civilization VI · 개발자 의도) Ed Beach는 Civ VI에서 맵의 역할을 키우려고 도시를 여러 타일로 펼쳤다고 말했다. — [Why Firaxis decided to make drastic changes to cities in Civilization VI - GamesBeat](https://gamesbeat.com/why-firaxis-decided-to-make-drastic-changes-to-cities-in-civilization-vi/)
- **SP-07** (미검증 · Civilization VI · 실패 사례) GamesBeat 체험기는 Civ VI의 펼친 도시가 서로 엉켜 맵이 어수선해졌다고 비판했다. — [Civilization VI hands-on: Empire building is addictive and beautiful, but combat is messy…](https://gamesbeat.com/civilization-vi-impressions-empire-building-is-addictive-and-beautiful-but-combat-is-messy/)
- **SP-08** (확인 · Civilization VI · 반응) PC Gamer는 Civ VI 인접 보너스가 매우 중요한데 잘 드러나지 않는다고 비판했다. — [14 tiny things that drive me crazy about Civ 6 - PC Gamer](https://www.pcgamer.com/14-tiny-things-that-drive-me-crazy-about-civ-6)
- **SP-09** (확인 · Civilization VI · 실패 사례) CivFanatics의 한 이용자는 Civ VI 구역 배치 규칙이 결정론적 최적해를 허락한다고 썼다. — [Where does the AI go wrong with districts? - CivFanatics Forums](https://forums.civfanatics.com/threads/where-does-the-ai-go-wrong-with-districts.648444)
- **SP-10** (확인 · Civilization VI · 설계론) PC Gamer는 인접 보너스의 매력을 완벽한 배치에 대한 유혹으로 설명했다. — [Why I love adjacency bonuses - PC Gamer](https://www.pcgamer.com/why-i-love-adjacency-bonuses)
- **SP-11** (확인 · Anno 1800 · 개발자 의도) Anno 1800 개발진은 다음 주민 등급으로 오르는 데 주민 행복이 필요 없게 바꿨다고 밝혔다. — [Union Update (Anno Union)](https://anno-union.com/?p=9904)
- **SP-12** (정정 · Anno 1800 · 메커닉) Anno 1800의 소방서는 주변의 화재 안전도를 높이는 버프 건물이며 불이 나면 진화를 돕는다. — [DevBlog: Attributes & Buff Buildings (Ubi-Thorlof, via devtrackers)](https://devtrackers.gg/anno-1800/p/775cc63c-devblog-attributes-buff-buildings)
  - 정정: 소방서가 주변 화재 안전도를 높이는 버프 건물이라는 문장은 Anno 117 DevBlog(2025)의 설명이고, «화재 안전도» 속성도 Anno 117의 용어다. Anno 1800에서는 소방서·병원·경찰서가 영향 범위 안의 화재·질병·폭동 사고에 대응한다. 이 짝은 팬 사이트 출처로 달아야 한다. / Anno 117 DevBlog는 'Anno 1800에도 있던 소방서는 주변 화재 안전도를 높이고 불이 나면 진화를 돕는다'고 앞선 사례로 언급한다. Anno 117에서는 소방서(Vigiles)가 반경 안에 버프를 주는 건물로 정해졌다. Anno 1800 위키의 Emergency services 문서는 소방서가 영향 반경 안에서 불을 끈다고 적는다. 소방서·병원·경찰서를 화재·질병·폭동에 대응시키는 설명은 Anno 1800 위키 쪽 내용이고, 이 DevBlog의 내용이 아니다.
- **SP-13** (확인 · Anno 1800 · 실패 사례) GameSpot은 Anno 1800이 몇 시간 뒤 수십 개의 얽힌 생산 사슬로 커져 물류 악몽이 된다고 평했다. — [Anno 1800 Review - Hidden Figures (GameSpot)](https://www.gamespot.com/reviews/anno-1800-review-hidden-figures/1900-6417131/)
- **SP-14** (확인 · Clash of Clans · 메커닉) Clash of Clans에서 약탈 가능한 자원은 Town Hall과 창고에 나뉘어 있고, 공격자는 부순 만큼만 가져간다. — [Clash of Clans Available Loot Calculator (pixelcrux)](https://pixelcrux.com/Clash_of_Clans/Available_Loot/Calculator)
- **SP-15** (미검증 · Clash of Clans · 메커닉) Clash of Clans Town Hall 9 배치 안내는 창고를 고르게 나눠 방어로 덮고, 약한 창고를 적 병력의 장애물로 쓴다. — [Clash of Clans Town Hall 9 base layouts (High Ground Gaming)](https://www.highgroundgaming.com/?p=96866)
- **SP-16** (확인 · Dorfromantik · 개발자 의도) Toukana는 Dorfromantik에서 10만 점을 넘긴 플레이어가 다시 쉬워진 게임으로 끝없이 플레이하는 것을 예상하지 못했다고 했다. — [Toukana Interactive: Berlin is a network of support and inspiration - Berlin.de](https://www.berlin.de/gamescapital/interviews/toukana-interactive-berlin-is-a-network-of-support-and-inspiration-1578184.en.php)

### RV — 마을·기지 요소에 대한 플레이어·평론 반응

- **RV-01** (확인 · Thronefall · 반응) Gameluster는 Thronefall의 고정 건설 위치와 맵당 건물 수 제한을 결점이 아니라 손으로 짠 맵과 맞물린 장치로 평했다. — [Thronefall Review – Holding On For One Last Night (Gameluster)](https://gameluster.com/thronefall-review-holding-on-for-one-last-night/)
- **RV-02** (정정 · Thronefall · 실패 사례) Thronefall 스팀 부정 리뷰에는 고정 건설 위치 때문에 매번 같은 기지 배치를 하게 되어 다시 할 가치가 크게 준다는 비판이 있다. — [Steam Community :: Thronefall (negative reviews, top rated)](https://steamcommunity.com/app/2239150/negativereviews/?l=english&browsefilter=toprated)
  - 정정: 확인된 것은 «건설 위치가 미리 정해져 있어 맵마다 건물 종류별 개수가 정해진다»는 사용자 불만까지다. 이를 다시 할 가치 감소와 직접 이은 스팀 부정 리뷰 원문은 찾지 못했다. 다시 하는 재미는 Geekly Grind 리뷰와 Gamebrain 집계에서 오히려 장점으로 꼽혔다.
- **RV-03** (미검증 · Thronefall · 실패 사례) Thronefall 개발자는 스팀 토론에서 경제가 눈덩이처럼 불어나 레벨이 너무 쉽거나 너무 어렵게 느껴질 수 있다고 인정했다. — [Economy of this game is wack. :: Thronefall General Discussions](https://steamcommunity.com/app/2239150/discussions/0/5971271658111960813/?l=bulgarian)
- **RV-04** (확인 · Thronefall · 메커닉) New Game Network는 Thronefall 후반 레벨에서 두 건물이 열린다고 썼다. 근처에서 적이 충분히 죽으면 골드를 주고 적을 공격하는 사당, 그리고 위험과 보상이 걸린 일회성 수정치를 주는 신전이다. — [Thronefall Review - New Game Network](https://www.newgamenetwork.com/article/2820/thronefall-review/)
- **RV-05** (정정 · Kingdom Two Crowns · 반응) 2019년 Kingdom Two Crowns 리뷰 하나는 바뀐 죽음 벌칙이 초반을 다시 쌓는 귀찮음을 일부 줄였다고 평했다. — [Kingdom Two Crowns Review (The Sixth Axis)](https://www.thesixthaxis.com/2019/01/07/kingdom-two-crowns-review/)
  - 정정: 검색 발췌 기준으로 The Sixth Axis는 줄어든 죽음 벌칙이 난이도를 일부 누그러뜨렸다고 했다. 초반을 다시 쌓는 귀찮음을 줄인 공은 더 분명해진 방향 제시에 돌렸다. 바뀐 죽음 규칙은, 첫 섬을 넘긴 뒤라면 죽어도 진행이 모두 초기화되지 않고 이전 섬에서 이어 가는 것이다.
- **RV-06** (정정 · Kingdom Two Crowns · 반응) Kingdom Two Crowns의 Xbox 판 리뷰 하나는 말을 타고 왕국을 오가는 이동을 게임에서 가장 재미없는 일로 꼽았다. — [Kingdom Two Crowns Review (TheXboxHub)](https://www.thexboxhub.com/kingdom-two-crowns-review/)
  - 정정: thexboxhub 리뷰에 «게임에서 가장 재미없는 일»이라는 문장이 있는 것까지는 확인된다. 그 대상이 왕국을 오가는 이동(탐험)인지는 검색 발췌로 확인되지 않았다.
- **RV-07** (미검증 · They Are Billions · 메커닉) They Are Billions 리뷰는 건물마다 일할 주민이 필요해서, 새 자원 건물을 지으려면 집을 계속 늘려야 한다고 설명했다. — [They Are Billions review (God is a Geek)](https://godisageek.com/reviews/billions-review)
- **RV-08** (확인 · They Are Billions · 실패 사례) They Are Billions 앞서 해보기 인상기 하나는 손이 많이 가는 기지 건설의 미세 관리 때문에 경험이 늘어진다고 비판했다. — [They Are Billions – Early Access Impressions (Gamereactor)](https://msn.gamereactor.eu/they-are-billions-early-access-impressions/)
- **RV-09** (확인 · Diplomacy is Not an Option · 반응) NoobFeed는 Diplomacy is Not an Option의 경제가 대부분 나무에 기대고, 도시 건설보다 직접 싸우는 것이 더 중요하다고 평했다. — [Diplomacy is Not an Option Review (NoobFeed)](https://noobfeed.com/reviews/diplomacy-is-not-an-option-review)
- **RV-10** (확인 · Diplomacy is Not an Option · 실패 사례) Gamebrain에 모인 Diplomacy is Not an Option 플레이어 리뷰에는 매번 0에서 다시 시작해 같은 구성을 다시 짓는다는 불만이 있다. — [Diplomacy is Not an Option (Gamebrain)](https://gamebrain.co/game/diplomacy-is-not-an-option)
- **RV-11** (정정 · Farthest Frontier · 실패 사례) Farthest Frontier 공식 포럼의 한 플레이어 글은 최고 난도(Vanquisher)에서도 후반 침략자가 약하다며, 침략자 챔피언 수를 늘려야 한다고 했다. — [The raiders in Vanquisher mode are pathetically weak (Crate Entertainment forums)](https://forums.crateentertainment.com/t/the-raiders-in-vanquisher-mode-are-pathetically-weak/144155)
  - 정정: Vanquisher 글은 99년차 공격(침략자 244명, 공성추·투석기 없음)이 너무 약하다는 내용이다. «침략자 챔피언 수가 조금 적다»는 지적은 별도 글 'Not a fan of arrow immunity'에서 나왔다. 그 글의 한 댓글이 화살 면역을 옹호하면서, 남은 불만은 챔피언 수가 적은 것뿐이라고 했다. / 'The raiders in Vanquisher mode are pathetically weak' 글은 99년차 공격이 공성 무기 없이 244명이었다며 후반 침략자가 약하다고 한 글이다. 챔피언 수를 늘리자는 제안은 같은 포럼의 'Not a fan of arrow immunity' 글(155294) 답글에서 확인되며, 이 글에 있는지는 확인되지 않았다. 침략자 강도는 패치마다 너프와 버프가 오갔다.
- **RV-12** (확인 · Against the Storm · 설계론) Sports Illustrated(videogames.si.com) 리뷰는 Against the Storm을 흥미로운 시작 국면을 거듭 겪고 후반은 가끔만 맛보는 도시 건설 게임이라고 했다. — [Against the Storm review: A perfect storm (Sports Illustrated)](https://videogames.si.com/reviews/against-the-storm)
- **RV-13** (미검증 · Against the Storm · 반응) VaporLens의 Against the Storm 스팀 리뷰 분석에서 추천 비율은 플레이 0~2시간 52%, 10~20시간 91%, 20시간 이상 96%다. — [Against the Storm (VaporLens stats)](https://vaporlens.app/app/1336490/against_the_storm/stats/details)
- **RV-14** (확인 · Cataclismo · 실패 사례) Ginx는 Cataclismo의 경제가 금방 좋은 상태가 되지만, 그 뒤로는 개선 포인트가 조금씩 쌓이기를 기다리게 된다고 지적했다. — [Cataclismo Review: Possible the Best Base Building Ever in an RTS (Ginx)](https://www.ginx.tv/en/?p=65873)
- **RV-15** (미검증 · Cataclismo · 반응) PC Gamer는 Cataclismo의 Endless 모드가 자원을 가혹하게 제한해 창의적인 결정을 끌어낸다고 평했다. — [Cataclismo review (PC Gamer)](https://www.pcgamer.com/games/strategy/cataclismo-review)
- **RV-16** (확인 · Age of Darkness: Final Stand · 반응) Age of Darkness: Final Stand 리뷰 하나는 캠페인에서 기지 건설이 매우 제한된 점을 실망스러운 점으로 꼽았다. — [Age of Darkness: Final Stand Review – Real Time Survival (Player2)](https://www.player2.net.au/2025/03/age-of-darkness-final-stand-review-real-time-survival/)

### GV — 보충: 마을 건물이 곧 방어선

- **GV-01** (확인 · Age of Empires II: Definitive Edition · 메커닉) Age of Empires II 상위 플레이어는 집을 병목 사이에 지어 돌벽 없이 적을 막는다. — [Age of Empires II: Definitive Edition 'Fast Castle' strategy guide](https://www.windowscentral.com/age-empires-ii-definitive-edition-fast-castle)
- **GV-02** (확인 · Age of Empires II · 실패 사례) Age of Empires II 공식 포럼에서 집·대장간·시장이 벽 노릇을 해서 기지 모습이 우스꽝스럽다는 불만이 나왔다. — [Why are the buildings so spread out?](https://forums.ageofempires.com/t/why-are-the-buildings-so-spread-out/166412?page=2)
- **GV-03** (정정 · Age of Empires II · 반응) Age of Empires II 포럼에서 건물 벽이 너무 싸고 쉬워서 유닛끼리 싸우는 전략을 가린다는 불만과, 그래도 있는 편이 낫다는 반론이 맞섰다. — [Why is walling the meta for aoe2, and only aoe2?](https://forums.ageofempires.com/t/why-is-walling-the-meta-for-aoe2-and-only-aoe2/261975?page=2)
  - 정정: 이 글타래는 '건물로 쌓은 벽'이 아니라 팰리세이드·돌벽을 포함한 벽 쌓기 전반(walling meta)을 두고 다툰다. 벽 쌓기가 지루하다는 불만과, 벽이 레이드를 막아 게임을 낫게 한다는 반론이 맞선 것은 맞다. 다만 «walling in aoe2 is so annoying», «way too cheap and easy», «gameplay is better with it than without it» 같은 글귀는 검색 결과에서 직접 확인되지 않았다. / 논쟁의 대상은 주로 팔리세이드·돌벽 같은 벽 비용과 벽 쌓기 메타다. «way too cheap and easy»는 'Suggestion: Increase the price of palisades' 스레드에 나온 말로, 팔리세이드 벽 비용을 올리자는 의견이다. 집도 싼 건물이라 벽을 대신할 수 있다는 말은 별도 스레드('Palisade Walls gives too much value for its cost')에 나온다. 여러 스레드의 개별 의견을 묶은 것이지 한 스레드의 찬반이 아니다.
- **GV-04** (정정 · Clash of Clans · 메커닉) Clash of Clans에서 공격 유닛은 가장 가까운 건물로 가므로, 바깥 건물 배치가 적의 진입로(funnel)를 정한다. — [clash of clans base design guide](https://trophycoach.com/clash-of-clans/guides/clash-of-clans-base-design-guide)
  - 정정: 성벽 밖 건물이 공격자의 funnel 도구가 된다는 내용은 다른 2026년 배치 공략(URL은 결과에서 짝지어지지 않음)에 있다. 하지만 trophycoach 공략에서 '바깥 모서리 건물을 부숴 funnel을 만든다'는 글귀는 확인되지 않았다. 또 모든 공격 유닛이 가장 가까운 건물로 가는 것은 아니다. Giant·Goblin처럼 우선 목표가 있는 유닛은 그 범주의 건물을 먼저 노린다(GV-06 참고).
- **GV-05** (확인 · Clash of Clans · 메커닉) Clash of Clans 전쟁 기지 공략은 HP가 높은 저장소를 앞에 두어 고기 방패로 쓰라고 한다. — [best th17 war base layout 2026 anti 3 star cwl](https://cocbasedrop.com/blog/best-th17-war-base-layout-2026-anti-3-star-cwl)
- **GV-06** (확인 · Clash of Clans · 메커닉) Clash of Clans의 Goblin은 자원 건물이 남아 있는 동안 다른 건물과 유닛을 모두 무시하고 자원 건물만 친다. — [clash-of-clans.1337wiki.com Goblin](https://clash-of-clans.1337wiki.com/goblin)
- **GV-07** (확인 · Stronghold 2 · 메커닉) Stronghold 2 미리보기 기사는 3D 전환 덕분에 성을 전쟁 기계로 쓰고 살상 구역을 공들여 짤 수 있게 됐다고 썼다. — [Stronghold 2](https://www.gamesradar.com/stronghold-2-10)
- **GV-08** (정정 · They Are Billions · 메커닉) They Are Billions에서는 기지 안으로 샌 좀비 하나가 건물을 공격하면 그 건물이 새 좀비가 나오는 곳이 된다. — [‘They Are Billions’ Guide: Tips and Tricks to Cleanse the Horde](https://www.fandom.com/articles/they-are-billions-guide-tips-tricks)
  - 정정: 감염된 건물이 새 좀비가 나오는 곳이 되는 것은 맞다. 다만 나오는 좀비 수는 그 건물 안의 일꾼(주민) 수와 같다. 일꾼이 없는 벽·빈 탑은 같은 식으로 좀비를 낳는 곳이 아니다. 단 출처인 fandom.com 공략 기사는 결과에 나오지 않아 그 글귀를 확인하지 못했다.
- **GV-09** (정정 · They Are Billions · 메커닉) They Are Billions 스팀 토론에서 벽이 아닌 건물로 입구를 막으면 좀비 웨이브가 다른 길로 돈다는 보고가 나왔다. — [They Are Billions (Steam Community discussion)](https://steamcommunity.com/app/644930/discussions/0/1694922526915031822)
  - 정정: 2018년 스팀 스레드 한 곳에 나온 일화적 보고다. 건물로 길을 «완전히» 막았을 때의 이야기이고(발리스타·타워로 막았을 때 돌아갔다는 다른 보고도 있다), 스레드 안에서 «패치된 글리치»라는 의문이 나왔다. 현재 판에서 되는지는 확인되지 않았다.
- **GV-10** (확인 · Diplomacy is Not an Option · 반응) GamesCreed 리뷰는 Diplomacy is Not an Option의 적 AI가 똑똑하지 않아 벽으로 길을 막기만 해도 쉽게 속는다고 비판했다. — [diplomacy is not an option review](https://gamescreed.com/pc/diplomacy-is-not-an-option-review)
- **GV-11** (확인 · Diplomacy is Not an Option · 메커닉) 한 리뷰에 따르면 Diplomacy is Not an Option의 건물은 맵에 비해 크고, 적어도 한 면이 열려 있어야 해서 배치를 신중하게 해야 한다. — [Diplomacy is not an Option](https://www.jannekeparrish.com/game/diplomacy-is-not-an-option)
- **GV-12** (확인 · Cataclismo · 반응) PC Gamer는 Cataclismo에 79점을 주고, 짓기 메커닉은 뛰어나지만 게임이 때때로 노동처럼 느껴진다고 평했다. — [cataclismo review](https://www.pcgamer.com/games/strategy/cataclismo-review)
- **GV-13** (확인 · Thronefall · 개발자 의도) Thronefall 개발자 Jonas Tyroller는 건물을 미리 정한 자리에만 짓게 한 것이 레벨 디자인 가능성을 크게 열었다고 말했다. — [Mastering minimalism and layering complexity with strategy game Thronefall](https://gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- **GV-14** (정정 · Thronefall · 개발자 의도) Thronefall에서는 건물이 매일 아침 공짜로 다시 서지만, 막 다시 선 경제 건물은 그날 골드를 주지 않는다. 플레이어가 건물을 지키게 하려는 설계다. — [Mastering minimalism and layering complexity with strategy game Thronefall](https://gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
  - 정정: 확인된 것은 '부서진 경제 건물은 그 회차에 골드를 주지 않는다'는 팬 공략 수준의 내용이다(이 글귀와 URL의 짝은 추정). 매일 아침 공짜로 다시 선다는 부분과 Game Developer 인터뷰의 해당 문장(«economic buildings don't give any gold when they have only just respawned»), '건물을 지키게 하려는 설계'라는 의도는 이번 검색에서 확인하지 못했다. / 확인된 것은 «부서진 경제 건물은 다음 아침 골드를 주지 않는다»는 점이다(경제 건물 수입은 'if they survive'). 'Resilient Residences' 퍼크를 고르면 부서진 집도 골드를 준다는 예외가 있다. 이것이 Tyroller의 인터뷰 발언이자 설계 의도라는 점은 미확인으로 남긴다.
- **GV-15** (확인 · Bad North · 메커닉) Bad North에서는 바이킹을 다 물리친 뒤 버틴 집의 수와 피해 여부에 따라 동전을 받고, 다 탄 집은 동전을 주지 않는다. — [Bad North Review](https://www.xboxtavern.com/bad-north-review)
- **GV-16** (확인 · Bad North · 메커닉) Bad North에서 부대가 집에서 재보급하는 중에 그 집이 부서지면 그 부대를 영구히 잃는다. — [Bad North review](https://www.godisageek.com/reviews/bad-north-review)

### GT — 보충: 준비 단계의 결정 템포와 설계 이론

- **GT-01** (확인 · Thronefall · 개발자 의도) Thronefall 개발자는 밤(공격) 동안 할 일 없이 기다리는 구조가 싫어서 다르게 만들려 했다. — [Mastering minimalism and layering complexity with strategy game Thronefall (Game Develope…](https://gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- **GT-02** (확인 · Thronefall · 개발자 의도) Thronefall 팀은 시작부는 그대로 두고, 뒤쪽 레벨로 갈수록 기존 시스템에 깊이를 조금씩 더하는 방식으로 복잡도를 올렸다. — [Mastering minimalism and layering complexity with strategy game Thronefall (Game Develope…](https://gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)
- **GT-03** (확인 · Thronefall · 메커닉) Thronefall의 Castle Center는 두 번 업그레이드할 수 있고, 파괴되면 패배한다. — [Castle Center (Thronefall wiki)](https://throne-fall.github.io/game-content/buildings/castle-center.html)
- **GT-04** (정정 · Thronefall · 실패 사례) Steam 토론의 한 플레이어는 성 2레벨 선택지 Builder's Guild(밤마다 집 한 채 레벨업)가 너무 좋아서 안 고를 수 없다고 했다. — [Thronefall Steam community discussion](https://steamcommunity.com/app/2239150/discussions/0/4308326918580849935)
  - 정정: 위키 설명은 «밤마다 아무 집이나 레벨업»이 아니다. 아침마다 1레벨 집 하나를 2레벨로 올린다(올릴 집이 있을 때만). 다른 공략(SteamAH)은 «대체로 좋다», «4~5채만 맡기고 나머지는 직접 올려라» 정도로 평가한다. 꼭 골라야 한다는 합의는 확인되지 않는다.
- **GT-05** (확인 · Thronefall · 메커닉) Thronefall에서 타워를 3레벨로 올릴 때 업그레이드 4개 중 하나를 고른다. — [Tower (Thronefall wiki)](https://throne-fall.github.io/game-content/buildings/tower.html)
- **GT-06** (미검증 · Thronefall · 메커닉) Thronefall 공략 글은 골드 수입이 제한되어 있어서 수입용 집을 지을지 방어용 성벽을 지을지가 무거운 결정이 된다고 설명한다. — [thronefall guide (shapes.inc)](https://shapes.inc/guides/thronefall-guide)
- **GT-07** (정정 · Thronefall · 반응) Start Menu 리뷰는 Thronefall이 지나치게 미니멀한 타워 디펜스라며 쓸 만한 전략이 적다고 비판했다. — [Review | Thronefall - The Emperor's New Tower Defence (Start Menu)](https://www.startmenu.co.uk/home/review-thronefall)
  - 정정: Start Menu 리뷰(6/10)는 Thronefall이 지나치게 미니멀하다고 비판했다. 결과에 나온 근거는 플레이어 도구가 적다는 점, 건물 위치를 정할 수 없어 경제와 방어의 균형이 까다롭다는 점, 선택 퀘스트가 가혹해진다는 점이다. «쓸 만한 전략이 적다»는 문구 자체는 확인되지 않았다. / Start Menu의 비판은 «미니멀 TD 말고는 별것이 없다», «플레이어 도구가 제한적이다»(6/10)로 확인된다. 이를 «쓸 만한 전략 부족»이라고 옮기는 것은 확인되지 않은 의역이다. 다른 리뷰들은 대체로 호평이고 다양성·반복성 정도만 지적한다.
- **GT-08** (확인 · (design theory) Sid Meier · 설계론) Sid Meier는 GDC 2012 강연 «Interesting Decisions»에서 흥미로운 선택의 네 성질을 트레이드오프·상황 의존·개인 취향·지속성으로 들었다. — [Sid Meier's Interesting Decisions (notes)](https://dandylyons.github.io/notes/Clippings/Sid-Meier's-Interesting-Decisions)
- **GT-09** (정정 · (design theory) Sid Meier / Civilization · 설계론) Sid Meier는 Civilization에서 보조 기술 트리를 뺀 이유를 들며, 한 번 하면 흥미로운 것이 열 번 해도 흥미롭지는 않다고 했다. — [GDC 2012: Sid Meier on how to see games as sets of interesting decisions (Game Developer)](https://gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions)
  - 정정: Sid Meier는 GDC 2012 강연에서 «something that's interesting you do once doesn't mean it's something interesting to do ten times»라고 말했다. 이 말이 Civilization의 보조 기술 트리를 뺀 일과 이어진다는 맥락은 확인되지 않았다.
- **GT-10** (정정 · (design theory) · 설계론) Game Developer 블로그 글 «Designing interesting decisions in games and when not to» 계열 글들은 흥미로운 결정에는 트레이드오프가 있어야 하고, 선택지나 결정이 너무 많으면 플레이어가 지친다고 정리한다. — [Designing interesting decisions in games (and when not to) (Game Developer)](https://www.gamedeveloper.com/design/designing-interesting-decisions-in-games-and-when-not-to-)
  - 정정: 원칙 자체는 여러 글에서 확인된다. 다만 글귀 출처는 «Designing interesting decisions…» 한 글로 확정할 수 없다. 선택지가 많은 것의 비용과 적정선은 «When choice is bad: finding the sweet spot for player agency»(Soren Johnson)가 직접 말한다.
- **GT-11** (미검증 · (design theory) tower defense economy · 설계론) Summer Engine의 타워 디펜스 제작 가이드는 웨이브 사이에 보통 의미 있는 구매를 다섯 개도 영 개도 아닌 하나 할 수 있어야 한다고 주장한다. — [How to Make a Tower Defense Game with AI (Step by Step) (Summer Engine)](https://www.summerengine.com/ja/blog/how-to-make-a-tower-defense-game-with-ai.md)
- **GT-12** (정정 · Dome Keeper · 개발자 의도) Dome Keeper 개발자 René Habermann은 업그레이드가 매우 강하게 느껴지고 서로 확실히 다르며 효과가 바로 눈에 띄어야 한다고 했다. — [How Dome Keeper focuses on systems that feed into one another (Game Developer)](https://www.gamedeveloper.com/road-to-igf-2023/how-dome-keeper-focuses-on-systems-that-feed-into-one-another)
  - 정정: 확인된 개발자 발언은 이렇다. 업그레이드가 게임을 시각적·청각적으로 바꾸게 했다(파워 업그레이드로 레이저가 커지고 소리가 달라진다). 너무 강한(OP) 업그레이드와 가젯이 있어도 계속 도전이 되도록 밸런스를 잡아야 했다. 업그레이드는 채굴 성공을 강하게 드러내는 표현이다. «업그레이드끼리 확실히 달라야 한다», «채굴을 일부러 단순화했다»는 부분은 확인되지 않은 요약이다.
- **GT-13** (확인 · Dome Keeper · 메커닉) Dome Keeper에서는 웨이브를 막은 뒤 돔 아래를 채굴할 시간이 정해져 있고, 다음 웨이브 전에 돔으로 돌아와야 한다. — [Dome Keeper (Wikipedia)](https://Www.Wikipedia.org/wiki/Dome_Keeper)
- **GT-14** (정정 · Dome Keeper · 실패 사례) Gideon's Gaming 리뷰는 Dome Keeper의 아늑한 채굴과 정신없는 웨이브 방어의 조합을 칭찬했지만, 최적의 채굴 방법이 꽤 뻔해서 반복적으로 느껴질 수 있다고 지적했다. — [Dome Keeper review (Gideon's Gaming)](https://gideonsgaming.com/dome-keeper-review/)
  - 정정: 확인되는 것은 «여러 리뷰가 반복성을 지적했다»는 수준이다. Shacknews는 짧은 웨이브 재미에는 좋지만 오래 하기에는 범위가 좁다고 했다. Escapist는 12시간 넘게 하면 다양성 부족으로 지루해진다고 했다. Gideon's Gaming의 «최적 채굴법이 뻔하다»는 발언은 확인되지 않았다.
- **GT-15** (미검증 · Cataclismo · 반응) Cataclismo 앞서 해보기 리뷰 하나는 12시간 플레이 가운데 6~7시간을 멈춰 놓고 짓는 데 썼다고 했다. — [Cataclismo review - An RTS built on solid stone (Early Access) (Sportskeeda)](https://sportskeeda.com/esports/cataclismo-review-an-rts-built-solid-stone-early-access)
- **GT-16** (확인 · Cataclismo · 메커닉) Cataclismo에는 준비가 됐다고 느끼면 남은 낮을 건너뛰는 «trigger next wave» 버튼이 있다. — [Cataclismo: the first preview (sameteem)](https://sameteem.com/threads/cataclismo-the-first-preview.26325/)
