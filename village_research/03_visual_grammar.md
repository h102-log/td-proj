# 03. 장식이 실패한 원인은 양이 아니라 빌려 쓴 시각 문법이었다

[README](README.md)로 돌아가기. 수치 표기((계산)·(눈대중)·(픽셀 집계)·(검색 요약))는 README 1장에 있다.


이전 Gemini 평가가 짚은 함정 여섯은 게슈탈트 원리로 한 줄씩 설명된다. 시설과 같은 짙은 외곽선을 쓰면 **유사성** 때문에 그 장식이 «클릭할 물건» 무리에 들어가고, 성벽과 같은 청회 돌은 성벽 무리에 들어간다. 반듯한 네모 테두리는 **공통 영역**이 되어 «여기에 무언가 들어간다»는 슬롯 문법을 만든다. NN/g는 경계가 «a strong visual cue that can overpower other grouping principles»라고 쓴다 ([NN/g](https://www.nngroup.com/articles/common-region/)). 솟은 벽이 장애물로 읽히는 것은 탑다운 관습 때문이다. 이 관습에서 대비와 높이는 벽·나무 같은 장애물 몫이다. «For top-down games, avoid too much contrast on the ground» ([nesdev](https://nesdev.nes.science/f21/t6892.xhtml)). 나무 울타리·말뚝이 아군 방벽으로, 건초·수레가 아이템으로 읽힌 것도 같은 구조다. Rise to Ruins 개발자는 땅에 떨어진 자원이 진짜 아이템이라고 밝혔다 ([Steam 토론](https://steamcommunity.com/app/328080/discussions/0/133256758579816127)). 장르 관습에서 «땅 위의 낱개 물체 = 줍는 것»이라는 뜻이다. Thronefall 화면에서도 목책·망루처럼 군사로 보이는 것은 모두 실제 시설이다(관찰). 대형 스튜디오의 처방은 하나로 모인다. Riot은 환경을 위계 맨 아래에 두고 «controlling color and level of detail, clamping value ranges»를 했다 ([Riot 데브 블로그 전재](https://www.surrenderat20.net/2014/06/update-to-summoners-rift-headed-to-pbe.html?m=1)). Lospec은 «an outline should always increase contrast»라며 외곽선을 대비 도구로 본다 ([Lospec](https://lospec.com/articles/pixel-art-outlines-part-2-using-color)). Foundation은 흰 외곽선을 선택한 건물에만 띄우고, 통·벤치·울타리 같은 소품에는 외곽선을 쓰지 않는다 ([스크린샷](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/690830/ss_dbc1c23ffd249f0c8b07aae6312f33aa63a0e8eb.1920x1080.jpg)). Kingdom Two Crowns는 반대 사례다. 떠돌이 캠프 그림 속 장식 나무가 진짜 나무를 흉내 내는 바람에 플레이어가 마지막 진짜 나무를 베었고, 개발사는 1.1.14에서 그 장식을 지웠다 ([Kingdom wiki](https://kingdomthegame.fandom.com/wiki/Vagrant_camp)).

결론은 «장식을 줄여라»가 아니다. **마을 조직(터·마당·길)을 시설과 다른 문법으로 그려라**는 것이다. 아래 규칙은 위 출처에서 끌어낸 Claude 해석이다.

| 속성 | 시설·유닛(읽혀야 하는 것) | 마을 조직(배경) |
|---|---|---|
| 외곽선 | 1px 짙은 남색 | 없음. 서 있는 소품만 자기 색보다 한 단계 어두운 색 |
| 높이·그림자 | 위로 솟음(48px) | 땅에 붙음. 울타리는 유닛 키의 1/3 이하, 땅 데칼은 그림자 없음 |
| 명도 | 땅과 크게 다름 | 땅과 조금 다름(Riot «명도 범위 묶기») |
| 색 | 강조색 허용 | 흙 계열(회갈·탁한 초록). 성벽 청회는 쓰지 않음 |
| 형태 | 또렷한 실루엣 | 불규칙한 얼룩, 열린 L자. 닫힌 네모는 쓰지 않음 |
| 분포 | 플레이어가 둠 | 건물이 있을 때만, 건물에 붙은 묶음 하나(소품 2~4개) |

마지막 «분포» 줄이 10/23 기각 시안과 갈리는 핵심이다. `art/trial/preview/village_decor_zoom.png`를 다시 보면, «생활 마을»의 텃밭은 짙은 테두리를 두른 독립 직사각형이었다. 통·장작은 빈 흙 위에 낱개로 놓였고, 흙길은 건물과 상관없는 고정 직선 두 줄이었다. «전시 보급»의 보급품 더미·수레·무기 받침도 건물에서 떨어져 맨땅에 흩어져 있었다.

| 기각 시안의 요소 | 실패 원인(관찰·평가) | 이번 제안에서 다른 점 | 근거 |
|---|---|---|---|
| 생활 마을 — 텃밭 블록 | 테두리 친 독립 직사각형이라 «지은 것·지을 자리»로 읽힌다. 장르에서 밭은 짓는 경제 건물이다(AoE II·Thronefall·Stronghold·K&C) | 집 마당 안에 붙은 1×2칸 이하 이랑 데칼. 외곽선 없음. 집이 있을 때만 그림 | Thronefall «Houses, … Mills and Fields» ([Steam](https://store.steampowered.com/app/2239150/Thronefall/)), Manor Lords 뒷마당 텃밭 |
| 생활 마을 — 흙길 두 줄 | 성벽과 나란한 가로 띠(성벽 일부로 읽히는 함정)와 정문→거점 세로선(적 예상 경로 S142와 같은 축). 같은 흙 위의 가는 점선이라 대비도 약함 | 건물마다 하나씩 생기고 그 건물 문에서 끝나는 가지. 정문→거점 축·성벽과 나란한 띠·성문에 닿는 길은 만들지 않음. 명도·질감으로 대비 | 길이 활동과 묶임: Foundation «Paths are made by your villagers» ([PCGamesN](https://www.pcgamesn.com/foundation/medieval-city-builder-out-now)), Settlers IV dusty path ([wiki](https://docs.settlers-united.com/v/settler-iv-wiki-en/basics/terrain-and-roads)). 성문으로 가는 흙길 = 적의 길(Kingdom Rush [스크린샷](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/246420/ss_502205852350bfd8d64070adf4c38f2ffdf86772.1920x1080.jpg)) |
| 생활 마을 통·상자·장작, 전시 보급 더미·수레·장작 | 빈 흙 위 낱개 + 짙은 외곽선 → 아이템 | 건물 실루엣에 닿는 묶음 하나만. 외곽선 없음. 땅 명도 범위 안 | Rise to Ruins 개발자 «땅 위 자원 = 아이템», Northgard 소품은 건물 패치 안에 2~5개(관찰) |
| 전시 보급 — 무기 받침·말뚝 | 아군 방벽으로 읽힘 | 마당 울타리는 유닛 키의 1/3 이하로 낮게, 한두 면만 짧게, 성벽 안쪽에만, 집 벽에 닿아 끝남. 전시 분위기는 건물·성벽에 붙은 표식(깃발·화로)으로 | Thronefall «방어처럼 보이면 방어»(관찰), Northgard 건물 깃발(관찰) |

10/25 시안에서 Gemini가 통과시킨 청록 현수막·화로는 모두 «성벽에 붙은 표식»이었다. 이 원칙과 맞는 결과다. 다만 이 조사로도 배제하지 못한 위험이 하나 남는다. 10/23 결정 기록에는 «돌길·광장을 고름»만 있다(`WBS.md:228`). 사용자가 «다져진 흙길»이나 «텃밭»이라는 재질 자체를 싫어했을 수도 있다. 시안을 띄울 때 이것을 따로 묻는다.
