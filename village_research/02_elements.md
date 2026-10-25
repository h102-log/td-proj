# 02. 비교작은 열세 가지 장치로 적은 건물을 마을로 만든다 — (a) 요소 목록

[README](README.md)로 돌아가기. 수치 표기((계산)·(눈대중)·(픽셀 집계)·(검색 요약))는 README 1장에 있다.


| # | 요소 | 비교작이 하는 방식 | 우리 지금 |
|---|---|---|---|
| 1 | 건물 스케일 | 집·생산 건물은 2×2 이상이고 1×1에는 벽·길·포탑이 들어간다. 사람 대비 2~8배 ([War1gus](https://github.com/Wargus/war1gus/blob/master/scripts/buildings.lua), [OpenDUNE](https://github.com/OpenDUNE/OpenDUNE/blob/master/src/table/structureinfo.c)) | 전부 1칸, 주민의 약 1.8배 |
| 2 | 모으기·작은 영역 | 이웃 2칸 보너스(K&C), 반경 10칸(TAB), 타일당 2~4채(Northgard), 섬 하나(Bad North) | 1,620칸에 흩어짐 |
| 3 | 건물 발밑 «터» | 모든 지상 건물이 흙을 깖([AoE II](https://forums.ageofempires.com/t/i-need-help-with-making-a-map/244274)), Northgard 맨땅 얼룩, WC3 건물별 ubersplat(검색 요약) | 없음 |
| 4 | 마당·필지 = 건물의 일부 | Foundation 경계 울타리, Manor Lords 뒷마당, Rise to Ruins 작업 마당. 소품은 벽에서 1칸 안(관찰) | 없음 |
| 5 | 길망 | 다니면 생김(Settlers IV·Foundation), 플레이어가 놓음(K&C), 길이 집 배치를 정함(Manor Lords) | 정문~거점 광장과 성벽 안쪽 돌길뿐 |
| 6 | 바닥 재질 위계 | 광장 돌 > 길 > 마당 흙 > 밭 이랑 > 바깥 풀(관찰) | 흙 93.5% |
| 7 | 광장 가장자리의 활동, 가운데의 무언가 | «too large … deserted», 가장자리 활동 거점([APL 61](https://www.iwritewordsgood.com/apl/patterns/apl061.htm)), «resist … exactly in the middle»([APL 126](https://www.iwritewordsgood.com/apl/patterns/apl126.htm)) | 광장 양옆이 맨흙이고 우물은 따로 떠 있음 |
| 8 | 사람이 아닌 생활 신호 | 굴뚝 연기(7편 중 6편), 창 불빛·가로등(They Are Billions), 중립 동물(WC3 critter) | 없음 |
| 9 | 목적 있는 움직임·모임 | «we wanted the settlement to feel alive by having its inhabitants gather in one place»([Against the Storm](https://eremitegames.com/villager-routines/)), Stronghold 모닥불 앞 농민 | 저마다 혼자 배회 |
| 10 | 단계 반응 | Town Bell 피신(AoE II), Shelter Inside(Farthest Frontier), 밤이면 푸른 톤(Thronefall) | 없음 |
| 11 | 미리 깔린 집·폐허 | 지킬 집(Bad North), 옛 왕국 폐허·캠프(Kingdom), 장식 오두막(WC3 hut) | 시안 C′만 있음(게임에는 없음) |
| 12 | 레벨 따라 자라는 둘레 | 3·5·7단계에 벽·탑을 공짜로, 장식 텐트(Kingdom), 시대마다 지붕 재질(AoM) | 거점 그림만 레벨 1·2 |
| 13 | 경계·관문 | «The strength of the boundary is essential»([APL 15](https://www.iwritewordsgood.com/apl/patterns/apl015.htm)), Thronefall 울타리 + 흙길 하나 | 아래 성벽만 있음. 상하좌우 성벽은 나중(S203) |

이 목록에서 «아무 빈 땅에나 짓는» 우리 구조에 가장 중요한 줄은 2·3·4·5다. 이유는 정해진 자리를 쓰는 게임이 직접 말했다. Thronefall의 Jonas Tyroller는 미리 정한 슬롯에만 짓게 한 덕분에 «We can choose how the finished castle should look like»라고 했다 ([Game Developer](https://www.gamedeveloper.com/design/mastering-minimalism-and-layering-complexity-with-strategy-game-thronefall)). 그 대가로 리뷰에서는 판마다 «최적 빌드 순서가 굳는다»는 비판을 받았다 ([GameGeeker](https://gamegeeker.com/games/thronefall?market=GB), 검색 요약). 자유 배치로 마을다움을 낸 게임들은 모두 **«게임이 대신 메워 주는 층»**을 두었다. Manor Lords는 플레이어가 정한 구역을 «subdivided based on your roads and the allotted space» 한다 ([Steam](https://store.steampowered.com/app/1363080/)). Townscaper는 놓은 블록을 «cute little houses, arches, stairways, bridges, and lush backyards»로 바꾼다 ([Steam](https://store.steampowered.com/app/1291340/)). Clash of Clans는 나무·바위 장애물 약 40개를 깔고 시작한다 ([CoC wiki](https://clashofclans.fandom.com/wiki/Obstacles/Home_Village)). 우리 게임에는 디자이너가 고른 배치도, 게임이 메우는 층도 없다. 그래서 이 보고서 제안의 중심은 «건물이 자기 마당과 길을 데리고 온다»는 층이다. 플레이어가 어디에 짓든 그 둘레에 마을 조직이 따라붙게 하는 것이다.

11·12번의 사례는 무거운 사건을 가볍게 보여 줄 재료다. Kingdom의 폐허는 «leftover from a previous Kingdom long past»로 설명되고, 수리도 상호작용도 안 되며 건설을 막지도 않는다. 앞에 상자 하나만 놓여 있다 ([Kingdom wiki Ruins](https://kingdomthegame.fandom.com/wiki/Ruins)). Kingdom Rush의 일부 탑 자리는 «무너진 집(ruined homes)» 잔해로 막힌 채 시작하고, 150금을 내야 치운다 ([Kingdom Rush wiki](https://kingdomrushtd.fandom.com/wiki/Strategic_Point)). Clash of Clans는 무너진 Clan Castle을 재건하면서 시작한다 ([CoC wiki](https://clashofclans.fandom.com/wiki/Clan_Castle)). Bad North에서는 지붕 없는 흰 돌담이 지형처럼 쓰이고, 지붕 있는 집은 «지킬 대상»으로 갈려 보인다 ([스크린샷](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_66e84cd65125d74fcad538bdc4c1585be8a957f1.1920x1080.jpg), 해석). 개발자는 전투 뒤 섬을 «We want to give that feeling of, you won, but it's still a sad victory»로 설계했다고 말했다 ([GamesBeat](https://gamesbeat.com/bad-north-shows-that-even-bloody-viking-battles-can-be-artsy-and-cute/)). 이 사례들을 우리 집터에 대 보면, 그림보다 먼저 정할 것이 있다. 집터를 «위에 지을 수 있는 바닥 장식»(Kingdom형), «못 짓는 지형»(Bad North형), «다시 세울 자리»(Kingdom Rush·CoC형) 가운데 무엇으로 둘지다. 못 짓는 지형으로 둔다면 이전 평가의 «솟은 벽 = 장애물» 읽힘은 오해가 아니라 맞는 신호가 된다. C′는 첫째 길을 택한 그림이다. 자라는 둘레의 대표는 Kingdom이다. 마을 단계 3에서 가장 안쪽 가시 울타리를, 5에서 돌벽과 감시탑을 공짜로 세운다. 1.1.13에서는 3단계부터 작은 텐트가 나오는 순수 장식(COSMETIC)을 더했다 ([Kingdom wiki Town center](https://kingdomthegame.fandom.com/wiki/Town_center)). 우리 마을 레벨은 지금 최대 2라(S99) 자라는 단계가 하나뿐이다. 그래서 12번은 효과가 작다.
