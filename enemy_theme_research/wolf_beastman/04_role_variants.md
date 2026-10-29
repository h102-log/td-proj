# 변종마다 하나만 크게 바꾸고 웅크림은 덮치는 둘에게만 준다

잘 읽히는 짐승 진영은 역할마다 **크기·자세·손에 든 것** 가운데 하나를 바꾼다. 졸개는 가장 수수하고, 특수병은 든 소품이 능력을 말하며, 우두머리는 크기에 목둘레 덩어리(갈기·뿔·어깨 갑옷)를 얹는다. 색만 바꾼 변종은 같은 역할 안의 하위 변형에만 쓰였다. 덮치는 적은 약 1초 낮게 웅크려 예고한다. 원 노트: [evidence/role_variants.md](evidence/role_variants.md). 그 노트의 «밤 늑대 눈빛 예외는 미정»은 틀렸다(아래 «밤 늑대의 눈 두 점은 이미 정해졌다»).

## 원칙 셋: 편은 공통 꼴, 종류는 1차 특징 하나, 행동은 예고

[사실] Valve의 읽기 순서는 편(아군·적)을 색으로, 병과를 실루엣·몸 비례·무기·모자와 옷으로 읽는다. 든 무기는 가슴 높이에 대비를 가장 세게 둔다 ([Valve MIGS08 PDF](https://cdn.fastly.steamstatic.com/apps/valve/2008/MIGS08_ConnectingVisualsToGameplay.pdf)). Riot은 좋은 실루엣이 그 챔피언만의 «1차 특징»을 가지며, 1차는 어떤 스킨에서도 빼지 않고 2·3차는 융통한다고 한다. 애니메이션은 주된 차별점이 아니라 덤이다 ([Riot: Clarity in League](https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/)). Mike Stout는 공격 전에 짧은 지연을 두고 애니메이션·효과음으로 예고하라고 한다 ([Game Developer: Enemy Attacks and Telegraphing](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing)).

[추론] td-proj로 옮기면 «편» 층은 색 대신 **머리 꼴**(선 귀 둘·주둥이·꼬리)이 맡는다. «종류» 층은 정지 실루엣의 1차 특징 하나가 맡는다. 털색은 셋째 층 보조다. 걷기·정지 그림만 보고도 갈려야 하고, 웅크림 한 장을 1차 특징으로 삼지 않는다.

## 사례에서 반복되는 세 층

| 층 | 사례 [사실] | 늑대 4종 [추론] |
|---|---|---|
| 졸개: 작고 수수하며 많다 | Kingdom Rush Gnoll Reaver는 가장 약하고 빠른 선봉 졸개다 ([KR Gnoll Reaver](https://kingdomrushtd.fandom.com/wiki/Gnoll_Reaver)). Monster Hunter Jagras는 우두머리 둘레에 몰린다 ([Jagras](https://monsterhunter.fandom.com/wiki/Jagras)) | 늑대. 4마리가 똑같은 «제식» 차림 |
| 특수병: 든 소품이 능력을 말한다 | Gnoll Burner의 횃불 → 화상 ([KR Gnoll Burner](https://kingdomrushtd.fandom.com/wiki/Gnoll_Burner)). Swine Chopper의 톱니 식칼 → 출혈 ([DD Swine Chopper](https://darkestdungeon.wiki.gg/wiki/Swine_Chopper)). Swine Drummer의 북 → 지원·약화 ([DD Swine Drummer](https://darkestdungeon.wiki.gg/wiki/Swine_Drummer)) | 도약 늑대(자세), 밤 늑대(두건·망토) |
| 우두머리: 크기 + 목둘레 덩어리 | Gnoll Gnawer는 «크고 흉터 있고 갑옷 입은» 놀이고 둘레 아군이 있으면 피해가 오른다 ([KR Gnoll Gnawer](https://kingdomrushtd.fandom.com/wiki/Gnoll_Gnawer)). Great Jagras는 졸개보다 훨씬 크고 갈기를 가졌다 ([Great Jagras](https://monsterhunter.fandom.com/wiki/Great_Jagras)). 짐승인간은 뿔 크기가 지위다 ([Lexicanum Gor](https://whfb.lexicanum.com/wiki/Gor)) | 알파. 1.8배 + 흰 갈기 |

[사실] 색만 바꾼 변종의 예는 Diablo 1·2 팔레트 스왑과 SPD 주술사의 가면 색이다. SPD는 그마저 설명 글로 보충했다 ([PureDiablo](https://www.purediablo.com/?p=26146), [SPD actors.properties](https://raw.githubusercontent.com/00-Evan/shattered-pixel-dungeon/master/core/src/main/assets/messages/actors/actors.properties)). 프로젝트 조사도 «위협이 다른 변종이면 색에 실루엣·장비·자세·행동을 짝지으라»는 가이드를 인용했다(`enemy_theme_research/06_readability.md:26`).

[추론] 규칙이 서로 다른 4종을 털색으로만 가르는 것은 사례로 받쳐지지 않는다. 지금 네발 늑대 시안은 크기·비례·털색·덧붙임을 바꾸지만 늑대와 밤 늑대는 크기(1.12배)와 색만 다르다(`tools/art/wolf.py:16-19`). 사람형으로 옮길 때 밤 늑대에 두건·망토를 주는 까닭이다.

## 웅크림은 «곧 덮친다»는 전용 신호다

[사실] Left 4 Dead의 Hunter는 일정 거리에 들면 웅크리고 으르렁거리며, 실제로 붙잡기까지 약 1초가 걸린다. 뛰는 도중에는 방향을 못 바꾼다 ([L4D Wiki: The Hunter](https://left4dead.fandom.com/wiki/The_Hunter)). Vermintide Gutter Runner는 적에게 뛰어올라 쓰러뜨리고, 때맞춰 옆으로 피하면 피할 수 있다 ([Vermintide Wiki: Gutter Runner](https://vermintide.fandom.com/wiki/Gutter_Runner)). Bloodborne Scourge Beast는 돌진이 붙잡기로 이어진다 ([Fextralife Scourge Beast](https://bloodborne.wiki.fextralife.com/Scourge+Beast)).

[추론] 도약 늑대의 0.8초 웅크림과 알파의 1초 웅크림(`insights/2026-10-27_round2_wolf.md:76`, `:101`)은 이 범위에 든다. 둘만 웅크리고 늑대·밤 늑대는 낮춤 자세를 쓰지 않으면 «웅크림 = 곧 뛴다»가 한 가족이 된다.

[추론] Hunter는 일부러 졸개와 헷갈리게 만든 매복형이다. 도약 늑대는 반대다. 플레이어가 성벽 수비를 미리 바꿀 수 있어야 하므로 걸어올 때부터 졸개와 갈려야 한다. 그래서 도약 늑대의 1차 특징은 웅크림이 아니라 **평소 걷는 자세**(무릎을 접은 낮고 넓은 꼴)에 둔다.

## 밤 늑대의 눈 두 점은 이미 정해졌다

[사실] 은신형은 두건·망토로 머리 윤곽을 지우고 그늘 속에 빛나는 점을 남긴다. Gutter Runner는 검은 망토에 녹색으로 빛나는 발톱을 낀다 ([Vermintide Wiki: Gutter Runner](https://vermintide.fandom.com/wiki/Gutter_Runner)). Hunter는 두건이 늘 얼굴을 덮고 남은 눈이 어둠 속에서 흰 반사광을 낸다 ([L4D Wiki: The Hunter](https://left4dead.fandom.com/wiki/The_Hunter)).

[사실] td-proj는 이 «그늘 속 두 점»을 이미 넣었다. 사용자가 2026-10-27 «1번 ㅇㅇ»로 정했고, SPEC S240은 «어둠 속에 숨은 밤 늑대는 눈빛 두 점만 그린다»고 적는다(`SPEC.md:469`). I193 ④는 그 점을 «몸 가운데보다 조금 위에 2px 간격으로 찍는 밝은 노랑 점 둘»로 정했다(`SPEC.md:762`). EV564가 이를 잰다(`EVAL.md:574`). 원 노트 4·5장의 «아직 사용자 확인 전»은 낡은 문서(`insights/2026-10-27_round2_wolf.md:207`)를 읽은 것이다.

[추론] 남은 일은 그림 쪽 연결뿐이다. 낮에도 두건과 밝은 눈 두 점이 함께 보이면, 밤에 점만 남았을 때 같은 적이라는 연결이 선다. 두건이 귀를 덮으면 머리 윤곽이 «뾰족 하나»로 바뀌어 낮의 1차 특징도 된다(D4).

## 출혈은 무기가 아니어도 이미 보인다

[사실] 출혈은 휘거나 톱니 진 날로 보이는 것이 관례다. Swine Chopper는 «피 묻은 톱니 식칼», Elden Ring Bloodhound Knight는 큰 곡도로 출혈을 건다 ([DD Swine Chopper](https://darkestdungeon.wiki.gg/wiki/Swine_Chopper), [Elden Ring Wiki: Bloodhound Knight](https://eldenring.wiki.fextralife.com/Bloodhound+Knight)). td-proj는 출혈한 아군 몸에서 떨어지는 어두운 빨강 핏방울 셋을 그린다(I193 ③ 2026-10-27 변경, `SPEC.md:762`, `src/ui/battle_view.gd:1159-1162`).

[추론] 출혈을 «말하는» 일은 피해자 쪽 핏방울이 이미 한다. 밤 늑대 무기는 출혈을 알릴 필요가 줄고, 코볼트·도약 늑대와 꼴이 갈리는 것을 고르면 된다. 휜 날 관례와 맞으면서 쌍단검(도약 늑대)과 겹치지 않는 것이 **짧은 낫 하나**다. 게임의 출혈은 «물면» 걸리므로 공격 키 포즈는 물기로 둔다(`insights/2026-10-27_round2_wolf.md:89`).

## 우두머리는 목둘레가 부풀어야 우두머리다

[사실] Warcraft III Gnoll Overseer는 둘레 아군 피해를 올리는 Command Aura를 가진 가장 강한 놀이다 ([Warcraft Wiki: Gnoll Overseer](https://warcraft.wiki.gg/wiki/Gnoll_Overseer)). Darkest Dungeon Swine Prince는 크기 3이고 공격할 때 눈에 붉은 빛이 돈다 ([DD Swine Prince](https://darkestdungeon.wiki.gg/wiki/Swine_Prince)). Riot은 덩치 크고 갑옷 두꺼우면 탱커·전사로 읽힌다고 한다 ([Riot](https://www.leagueoflegends.com/en-gb/news/dev/clarity-in-league/)).

[추론] 크기만 키우면 «큰 늑대»로만 읽힌다. 목·어깨 둘레 덩어리를 더해야 «우두머리»가 된다. 알파의 오라도 크기·갈기와 묶는 것이 사례와 맞다. 흉터는 가까이서만 보이는 3차 특징이다. 붉은 눈(D6)은 Swine Prince·Scourge Beast의 «강화 상태» 관례와 맞는다.

[추론] 알파는 덮쳐서 누르고 문다(`insights/2026-10-27_round2_wolf.md:101`). 붙잡는 수단이 몸 밖으로 보이는 것이 붙잡기형의 관례다(Vermintide Packmaster의 장대 올가미, [Packmaster](https://vermintide.fandom.com/wiki/Packmaster)). 기본안의 큰 도끼는 한 손에 들고, 다른 손을 비워 누르기에 쓰면 무장과 붙잡기가 함께 읽힌다.

## 원 노트의 «도약 늑대 팔방패» 안은 권하지 않는다

[사실] 원 노트는 도약 늑대에 밀치기 도구로 둥근 팔방패를 권했다([evidence/role_variants.md](evidence/role_variants.md) 5장). 사용자 기본안은 쌍단검이다. 아군 기사는 왼손 방패, 아군 병사는 왼손 나무 방패를 든다(`tools/art/hero.py:1`, `tools/art/soldier.py:1`).

[추론] 도약 늑대는 아군이 선 성벽 칸 위에 내린다(`insights/2026-10-27_round2_wolf.md:77`). 방패는 바로 그 자리의 아군과 꼴이 겹친다. 그래서 쌍단검을 유지한다. 대신 두 날을 앞으로 내밀면 코볼트의 «앞으로 든 두 팔»과 겹치므로 역수로 낮게 쥐어 날이 팔꿈치 뒤·허리 옆으로 나오게 한다.

## 빈 곳

- 사례 대부분이 3D 1인칭·3인칭이다. 45° 탑다운 24px에서 같은 효과가 나는지는 출처가 없다.
- «24px에서 몸 밖 덧붙임 1~2개가 한계»는 출처 없는 추론이다.
- «진영 변종»만 다룬 GDC 발표·개발 블로그 원문은 찾지 못했다. Riot의 «1차 특징»이 가장 가깝다.
- 게임에 효과음 채널이 있는지는 확인하지 않았다. 울부짖음 같은 소리 예고는 소리가 있을 때만 해당한다.
