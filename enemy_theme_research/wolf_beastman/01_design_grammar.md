# 무기를 쥐면 늑대인간이 무사가 된다

장르의 늑대 수인은 세 갈래다. 훈련된 무사·군대형, 저주받은 야수형, 변신 클래스형이다. 무기를 실제로 드는 쪽은 거의 무사·군대형이다. 야수형과 변신형은 대개 맨손 발톱과 이빨로 싸운다. 사용자가 원한 «무장한 수인»은 무사·군대형에 든다. 이 문서는 그 갈래의 반복 문법과 위협 등급 신호를 모으고, 피할 클리셰를 적는다. 원 노트: [evidence/design_grammar.md](evidence/design_grammar.md). 위키 본문 글만 읽었고 이미지는 보지 않았다.

## 무장 여부가 «문명»과 «저주»를 가른다

[사실] MTG의 Tovolar는 «변신한 뒤에도 인간성을 일부 지키고 무기를 쥘 수 있는 첫 늑대인간»으로 소개된다. 무기를 쥐는 것 자체가 이례적인 지능·지위다 ([MTG Wiki Tovolar](https://mtg.fandom.com/wiki/Tovolar)). D&D 늑대인간도 창은 인간 형태에서만 쓰고, 혼종 형태는 물기와 발톱이다 ([Open5e Werewolf](https://api.open5e.com/monsters/werewolf/)).

[사실] 무기를 든 쪽은 모두 어떤 집단의 직업인이다. Elden Ring의 Blaidd는 낡은 검은 갑옷에 모피 망토를 두르고 대검을 든다 ([Fextralife Blaidd](https://eldenring.wiki.fextralife.com/Blaidd)). Farum Azula 수인은 곡도·투척 낫·토기 항아리 방패를 들고, 대형은 판금에 큰 식칼검을 든다 ([Fandom Beastman of Farum Azula](https://eldenring.fandom.com/wiki/Beastman_of_Farum_Azula)). Armello Wolf Clan은 «Pack Strong»을 내건 산악 무사 씨족이다 ([Armello Wiki Wolf Clan](https://armello.fandom.com/wiki/Wolf_Clan)). FFXIV Lupin은 Doma 사무라이를 800년 섬긴 늑대 머리 무사다 ([Consolegameswiki Lupin](https://ffxiv.consolegameswiki.com/wiki/Lupin)). 검은 신화: 오공의 늑대 요괴는 호위(장병 도끼)·졸병(방패+무딘 칼)·자객(회전 칼날)·궁수 같은 **계급·병과 이름**을 단다 ([Wolf Sentinel](https://blackmythwukong.fandom.com/wiki/Wolf_Sentinel), [Wolf Soldier](https://blackmythwukong.fandom.com/wiki/Wolf_Soldier), [Wolf Assassin](https://blackmythwukong.fandom.com/wiki/Wolf_Assassin)).

[사실] 맨손 쪽은 «한때 전사, 지금은 피에 미친 짐승»이라는 서술을 되풀이한다. Kingdom Rush Werewolf가 그렇고 ([KR Werewolf](https://kingdomrushtd.fandom.com/wiki/Werewolf)), Total War의 Skin Wolves는 찢고 나온 사람 살가죽을 걸친다 ([Skin Wolves](https://totalwarwarhammer.fandom.com/wiki/Skin_Wolves)). WoW worgen은 변신하면 옷이 찢어진다 ([warcraft.wiki.gg Worgen](https://warcraft.wiki.gg/wiki/Worgen)).

[추론] td-proj에 가장 가까운 선례는 검은 신화 늑대 요괴와 Farum Azula 수인이다. 같은 종족 안에서 **병과마다 무기를 바꿔** 한 가족으로 묶었다. 다만 둘 다 3D 근접전이라 24px에서 무엇이 남는지는 [03](03_pixel_readability.md)에서 따로 본다.

## 다섯 가지 반복 문법

| 문법 | 사례 [사실] | td-proj에 주는 뜻 [추론] |
|---|---|---|
| 머리는 드러내고 방어구는 몸통에 | Blaidd의 장비는 갑옷·건틀릿·그리브다 ([Fextralife](https://eldenring.wiki.fextralife.com/Blaidd)). Armello Thane·River 묘사에 투구가 없다 ([Thane](https://armello.fandom.com/wiki/Thane), [River](https://armello.fandom.com/wiki/River)) | 오크가 이미 뿔 투구를 쓴다(`tools/art/orc.py:1`). 늑대는 맨머리로 둔다 |
| 모피 망토·모피 깃 | Blaidd «The pelt serves as a cape», River의 모피 깃 망토 | 목 갈기와 같은 자리다. 24px에서는 갈기 하나로 합친다 |
| «베고 찢는» 무기 | 곡도·큰 식칼검·투척 낫(Farum Azula), 장병 도끼·방패+칼(검은 신화), 냉기 발톱·대도끼([Zatu Wulfen](https://zatu.com/products/space-wolves-wulfen-2)), 발톱형 무기([Shining Wiki Wolfling](https://shining.fandom.com/wiki/Wolfling)) | 고블린·오우거=몽둥이, 오크=넓은 칼과 꼴이 다른 것을 고른다: 휜 칼, 단검, 낫, 도끼 |
| 꼬리는 넣어도 빼도 된다 | worgen은 꼬리가 없다는 개발자 정정이 있다([Worgen](https://warcraft.wiki.gg/wiki/Worgen)). Lupin은 털이 두꺼운 꼬리다([Lupin](https://ffxiv.consolegameswiki.com/wiki/Lupin)) | 뒷모습(N) 단서가 모자라므로 넣는다([03](03_pixel_readability.md)) |
| 야만 대 규율 | 야만: 찢긴 옷, 살가죽, 신체 전리품(gnoll 손가락 목걸이, [Gnoll](https://warcraft.wiki.gg/wiki/Gnoll)). 규율: 씨족 위계(Lupin), 단일 족장과 문장(Armello), 계급명(검은 신화) | 4마리가 같은 차림이면 «한 씨족 무리»로 읽힌다. 넝마·전리품은 고블린·오크 «부족» 문법과 겹친다 |

## 위협 등급은 몸집·흰 털·빛나는 눈으로 신호한다

[사실] 사례들은 다섯 신호를 겹쳐 쓴다. 몸집: Farum Azula 대형 수인은 «훨씬 크고 판금에 거대한 곡선 식칼검»이다 ([Fandom](https://eldenring.fandom.com/wiki/Beastman_of_Farum_Azula)). Diablo의 Whitefur Howler는 «훨씬 크고 드물다» ([Diablo Wiki Night Howler](https://diablo.fandom.com/wiki/Night_Howler)). 흰·은빛 털: Tovolar는 은빛 털의 alpha이고, Wolf Sentinel은 «눈처럼 흰 머리»의 늙은 친위대다. 방어구 단계: Farum Azula는 금 장신구 경장 → 판금 → 번개 깃든 무기로 오른다. 무기의 격: Wolf Soldier의 «낡은 방패와 무딘 칼» 대 Wolf Swornsword의 보석 박힌 검 ([Wolf Swornsword](https://blackmythwukong.fandom.com/wiki/Wolf_Swornsword)). 빛나는 눈·발톱: Bloodborne Scourge Beast의 붉은 눈은 버프 상태이고 ([Fextralife Scourge Beast](https://bloodborne.wiki.fextralife.com/Scourge+Beast)), Diablo Immortal에서 울음으로 강화된 개체는 발톱이 붉게 빛난다 ([Night Howler](https://diablo.fandom.com/wiki/Night_Howler)).

[사실] 우두머리는 행동도 겹친다. Lingxuzi는 건물 위로 뛰었다가 덮치고 울음으로 범위 공격을 한다 ([Lingxuzi](https://blackmythwukong.fandom.com/wiki/Lingxuzi)). Farum Azula 수인의 도약 내려찍기는 도약 전 지연이 길다 ([Fextralife Beastman](https://eldenring.wiki.fextralife.com/Beastman+of+Farum+Azula)). Night Howler의 울음은 자신과 주변 동족을 강화한다.

[추론] 24px에서 확실히 남는 등급 신호는 **몸집·흰 색 덩어리·빛나는 점** 셋이다. 방어구 단계와 무기의 격은 한두 픽셀이라 약하다. 그래서 등급은 몸집과 색 덩어리에 싣고, 무기는 «종류 구분»에 쓴다. 흰 털은 알파 하나에만 쓴다. 다른 셋에 흰 털을 쓰면 등급 신호가 흐려진다.

[추론] 게임 규칙과 장르 문법이 잘 맞는다. 도약 늑대의 0.8초 웅크림은 Farum Azula의 «도약 전 긴 지연»이다. 알파의 울부짖음 오라는 Night Howler의 울음 강화다. 밤 늑대의 «어둠에 세짐»은 보름달·낮밤 문법([Forgotten Realms Werewolf](https://forgottenrealms.fandom.com/wiki/Werewolf), [MTG Werewolf](https://mtg.fandom.com/wiki/Werewolf))에 기대므로 설명 없이 읽힌다.

## 피할 클리셰와 신선하게 만드는 길

[추론] 피할 것은 넷이다. (a) 찢긴 바지에 맨상체인 회색 늑대인간. Kingdom Rush·worgen과 바로 겹치고, 회색 피부 고블린과 색도 겹친다. (b) 맨손 발톱을 주된 인상으로 삼기. 코볼트와 겹치고 «무장» 요구와도 어긋난다. (c) 늑대 머리 투구·뿔 투구. 오크와 겹친다. (d) 한 작품의 고유 조합을 통째로 가져오기. 예: Blaidd의 «검은 갑옷+모피 망토+대검», Wulfen의 «파워아머+냉기 발톱».

[사실] 신선해 보인 사례는 늑대를 **특정 문화의 직업인**으로 못 박았다. Lupin은 사무라이 가신이고, Farum Azula 수인은 토기 항아리를 방패로 쓴다 ([Fextralife Beastman](https://eldenring.wiki.fextralife.com/Beastman+of+Farum+Azula)). Armello Magna는 허리띠에 여우 꼬리를 전리품으로 단다 ([Magna](https://armello.fandom.com/wiki/Magna)).

[추론] td-proj 늑대를 «성을 노리는 사냥꾼 씨족»으로 정하면 소품이 따라 나온다. 사냥칼, 짧은 낫, 다리 감개, 씨족 공통 허리 가죽띠다. 다만 24px에서 몸 밖으로 튀어나오는 덧붙임은 1~2개가 한계로 보인다([04](04_role_variants.md)). 소품은 종마다 하나만 고른다.

## 빈 곳

- 사용자가 예로 든 Tactics Ogre·Granblue Fantasy·Lost Ark·Lineage·Monster Hunter·Darkest Dungeon의 늑대 수인은 출처를 확인하지 못했다. Path of Exile 2는 위키가 봇 차단으로 열리지 않았다.
- Blaidd·Kingdom Rush 늑대인간·Wulfen·Lupin의 털색과 실루엣은 위키 글에 없다. 이미지를 보지 않아 모른다.
- 투구를 쓴 늑대 수인이 귀를 어떻게 처리하는지 다룬 출처는 찾지 못했다. 장르가 «투구를 씌우지 않는 쪽»으로 피해 온 것으로 보인다[추론].
- 디지티그레이드(발끝으로 서는) 다리와 굽은 척추를 권하는 출처는 질 낮은 튜토리얼 검색 요약뿐이다 ([Autodesk Exchange](https://origin-exchange.autodesk.com/werewolf-sketch)).
- 졸병 대비 족장 몸집 배율을 수치로 다룬 출처는 없다. 알파 1.8배는 게임 몸 반지름(0.45 ÷ 0.25)에서 온 값이다(`insights/2026-10-27_round2_wolf.md:58-61`).
