extends Node2D
# 전투 상태를 칸 단위로 그린다. 바닥은 타일(4.1b), 영웅은 도트 스프라이트(S165), 용병·적은 4방향 스프라이트(4.1d), 시설은 그림(4.1e), 나머지는 아직 도형이다(그레이박스, 아트는 WBS 4.1).

const CELL := 16
const Camera := preload("res://src/ui/camera.gd")
const Settings := preload("res://src/settings.gd")
const Folk := preload("res://src/sim/folk.gd")
const COLORS := {
	"grid": Color(0, 0, 0, 0.15), "spawn": Color("c03030"), "merc": Color("50a0f0"),
	"engineer": Color("f0a030"), "archer": Color("60d0a0"),
}
const ENEMY_COLORS := {  # 적 종류마다 다른 색(I81)
	"basic": Color("d04040"), "fast": Color("f08030"), "armored": Color("807070"), "flying": Color("e050c0"), "boss": Color("801010"),
	"slime": Color("50b050"), "slimelet": Color("98e070"), "big_slime": Color("2f7a3a"), "slime_king": Color("3aa0a0"),
	"wolf": Color("8a7a68"), "leap_wolf": Color("b08850"), "night_wolf": Color("3a3a58"), "alpha_wolf": Color("d8d8d0"),
	"sapper": Color("c05828"), "ram": Color("6a4a30"), "catapult": Color("a08048"), "glider": Color("c8b868"),
	"siege_tower": Color("586068"), "balloon": Color("e8d0a0"), "airship": Color("7090b0"), "war_machine": Color("4a4038"),
	"chief": Color("a02838"), "shieldbearer": Color("4a6a8a"), "fire_archer": Color("f0b020"),
	"feather_harpy": Color("70c8e8"), "dive_harpy": Color("e88850"), "song_harpy": Color("b890f0"),
}
# 그림이 아직 없어 다른 종류의 그림을 빌리는 종류 → [빌리는 종류, 곱하는 색](I250 ⑤). 4라운드 하피 셋은 비행(하피) 그림이다
const LOOKS := {"feather_harpy": ["flying", Color(0.75, 1.2, 1.7)], "dive_harpy": ["flying", Color(1.7, 1.0, 0.6)], "song_harpy": ["flying", Color(1.45, 0.85, 1.75)]}  # 하피 그림이 어두워 1을 넘겨 밝힌다
const NOTE := Color("d8b0ff")  # 노래(S306)로 공격 속도가 느려진 아군 머리 위 음표와 노래 반경 고리의 색(I252 ④)
const FEATHER := Color("f4f0e8")  # 날아가는 깃털(I250 ④)
const HERO_COLORS := {  # 영웅 종류마다 다른 색(S56, S157, I101)
	"aias": Color("b060f0"), "sylvia": Color("a0ff40"), "seraphina": Color("f0f0f0"), "vesper": Color("40c060"), "ignis": Color("ff5020"), "chronos": Color("ffd020"),
}
# 구조물·성곽 칸에 걸린 효과의 테두리 색(I101): 받는 피해 감소·공격 속도. 에너지 성벽 칸은 벽 조각이다(_wards, fx-2).
# 유닛에 걸린 효과는 테두리 대신 효과마다 조각 하나다(status_marks, I101 2026-10-27 변경)
const MARKS := {"dr": Color("80c0ff"), "haste": Color.ORANGE}
const EYES := Color("f0e060")  # 어둠 속에 숨은 밤 늑대의 눈빛(S240, I193 ④)

const UNITS := preload("res://art/units/heroes.png")  # 영웅 6명과 용병·적 시트를 한 장에 모은 아틀라스(tools/art/atlas.py)
static var ART: Dictionary = _art()  # 종류 → 캔버스·발밑·시트 y
const LUNGE := 6.0  # 근접 돌진 거리(px). 대상 몸까지의 틈을 더한다(_lunge). 림월드 0.35칸을 16px 칸으로 옮겼다(06 §4)
const CONTACT := 0.08  # 근접 공격이 대상에 닿는 때(친 뒤 초). 돌진(_lunge)이 가장 멀리 나간 때다
const FLASH := 0.1  # 피격 흰 번쩍임 길이(초, S177)
const FLINCH := 3.0  # 피격 밀림(px, S177). 림월드 0.17칸을 16px 칸으로 옮겼다(06 §4)
const FLINCH_BACK := 0.17  # 밀린 몸이 돌아오는 시간(초, 06 §4 약 10프레임)
const HITSTOP := 3.0 / 60.0  # 영웅이 치거나 맞은 타격에서 두 유닛의 그림만 멈추는 시간(초, S177). 시뮬레이션은 멈추지 않는다
const MUZZLE := {"tower": Vector2(0, -15), "magic": Vector2(0, -24), "cannon": Vector2(0, -6)}  # 칸 가운데에서 쏘는 곳(px, 4.1e 그림): 지붕 밑 발판, 수정, 포신
const BALL_ARC := 12.0  # 대포알 포물선 꼭대기 높이(px)
const BLAST := 0.25  # 대포알이 떨어진 곳의 범위 피해 고리가 퍼지는 시간(초)
# 원거리 착탄(S178 2026-10-28). 시간은 초다
const STUCK := 0.15  # 화살이 맞은 몸에 박힌 꼬리와 크림색 «ㅅ»이 남는 시간
const MARK := 0.1  # 구슬이 닿은 자리의 쏜 쪽 색 십자가 남는 시간
const MUZZLE_FLASH := 0.05  # 타워가 쏠 때 쏘는 곳의 금·크림 십자 섬광
const RECOIL := 0.1  # 대포를 쏜 뒤 그림이 대상 반대쪽으로 1px 물러나 있는 시간
const PUFFS := 4  # 대포를 쏠 때 포신 끝에서 피어오르는 포연 점 수
const FX := 0.3  # 즉시 스킬 흔적(S179)이 퍼지고 사라지는 시간(초). 범위 원(S72)의 0.3초를 이었다
const MISSABLE := ["shield_bash", "war_cry", "burst", "fireball", "frost_ring", "meteor", "piercing_gale", "enfeeble", "aging"]  # 적을 노리는 즉시 스킬(S179 2026-10-29)
const MISS_FADE := 0.5  # 그 스킬이 아무도 못 맞힌 흔적의 불투명도
const FX_TEX := preload("res://art/fx/fx.png")  # 이펙트 도트 조각 아틀라스(tools/art/fx.py, 4.1s)
static var FX_ART: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/fx/fx.json"))  # 조각 → [x, y, 폭, 높이, 프레임 수]
# 이펙트 색(4.1s): F24+와 이펙트 확장 램프(보라·연두)만 쓴다(tools/art/palettes.json f24p·fx)
const PX := {
	"cream": Color("efd8a1"), "gold": Color("efac28"), "orange": Color("ef692f"), "red": Color("ef3a0c"), "blood": Color("9b1a0a"), "maroon": Color("550f0a"),
	"soot": Color("2a1d0d"), "dark": Color("392a1c"), "smoke": Color("684c3c"), "ash": Color("927e6a"), "teal": Color("3c9f9c"), "midteal": Color("276468"), "deepteal": Color("183f39"),
	"tan": Color("efb775"), "bronze": Color("ab5c1c"),
	"ice0": Color("d0d6e0"), "ice1": Color("a4aec2"), "ice2": Color("7a86a0"), "ice3": Color("4f78ad"), "ice4": Color("3a4357"), "navy": Color("262d3d"), "night": Color("151a26"),
	"vio0": Color("e0c8f8"), "vio1": Color("b080e0"), "vio2": Color("8040c0"), "vio3": Color("4a2878"), "vio4": Color("2a1840"),
	"lime0": Color("e6f7a8"), "lime1": Color("b6e357"), "lime2": Color("7fbf3b"), "lime3": Color("4a8c2a"), "lime4": Color("28561e"),
}
const EMBER := ["gold", "orange", "red", "blood"]  # 불티가 식는 차례
const ZONE_OPEN := 0.2  # 장판이 펼쳐지는 시간(초, 4.1s)
const ZONE_CLOSE := 0.3  # 장판이 사라지며 줄어드는 시간(초, 4.1s)
const BOOM_STEP := 4.0 / 60.0  # 폭발 조각 한 프레임(초). Saint11 예시 80ms에 가깝게(vfx_research/02)
# 이그니스(I229, fx-11). 값은 시안 값이다(insights/2026-11-04_ignis_new_fx.md)
const WALL_GAP := 9.0  # 불길 장판 경계 안쪽 불꽃 줄의 불꽃 사이(아트 px)
const ICE_FLASH := 0.1  # 서리 고리를 쓴 뒤 빙결한 적의 얼음 테가 크림인 시간(초)
const FLOWER_GROW := 0.2  # 서리꽃이 반경까지 뻗는 시간(초)
const FLOWER_COOL := 1.0  # 서리꽃이 밝은 얼음에서 어두운 얼음으로 식는 시간(초)
const HOLE_CORE := 0.28  # 블랙홀 검은 심 반지름(반경에 곱한다)
const STREAKS := 4  # 블랙홀에 감겨 드는 줄 수
const STREAK_STEPS := 12  # 감겨 드는 줄 하나의 마디 수
const SUCK_FLAMES := 6  # 불타는 블랙홀의 줄을 따라 빨려 드는 불꽃 수
const OVERLOAD_RING := 9  # 과부하 차례에 발 둘레 고리 반지름(아트 px)
# 아이아스·실비아(fx-2). 시간은 초다
const SWEEP := 0.18  # 방패 강타 베기가 반경까지 퍼지는 시간. 그 뒤 FX까지 가는 호가 남는다
const CRY_ECHO := 0.08  # 전장의 포효 둘째 충격파가 늦게 나오는 시간
const SPARK_STEP := 3.0 / 60.0  # 스킬에 맞은 섬광 한 프레임
const GALE_REACH := 0.06  # 관통의 바람살이 맵 끝까지 뻗는 시간
const WIND_FLOW := 40.0  # 순풍 장판 바람 줄이 흐르는 빠르기(맵 px/초, I215)
const WIND_RUSH := 120.0  # 바람의 길 나선이 표적 쪽으로 흐르는 빠르기(맵 px/초)
const WIND_WAVE := 22.0  # 바람의 길 나선 한 바퀴 길이(맵 px)
const SNIPE_MARK := 0.6  # 저격 표적 괄호·화면 밖 꺾쇠가 남는 시간
const SNIPE_EDGE := 12.0  # 화면 밖 표적 꺾쇠를 화면 가장자리에서 이만큼(맵 px) 안쪽에 그린다
const HUD_BAND := 30.0  # 화면 위 HUD 띠 높이(기준 해상도 px, hud.gd TOP과 같다)
const WALL_RISE := 0.2  # 에너지 성벽 칸이 아래에서부터 드러나는 시간
# 아이아스 fx-10(I228). 시간은 초이고, 값은 사용자가 고른 시안 A·B의 값이다(insights/2026-11-04_aias_new_fx.md)
const BASH_SLAM := 0.12  # 방패 강타의 방패 조각이 부채꼴 쪽으로 밀려 나가는 시간
const BASH_TAIL := FX + 0.1  # 방패 강타의 2px 호가 남는 때
const SHOVE := 0.45  # 방패 강타에 밀린 적의 흙먼지가 퍼지는 시간
const FORT_RISE := 0.25  # 요새화 돌담이 솟는 시간
const BLOCK_FLASH := 0.12  # 태세가 피해를 막은 뒤 방패 조각이 희게 번쩍이는 시간
const BRACE_FULL := 0.2  # 태세 둘레 테가 다 차는 받은 피해(최대 체력 비율). 사용자 2026-11-04 «최대 체력 20% (시안 값)»
# 세라피나(크림·금)·베스퍼(청록)(fx-3). 시간은 초다
const BEAM_HOP := 0.08  # 성스러운 빛줄기의 빛 구슬이 대상 하나를 건너는 시간(I227 ①). 마디가 많으면 BEAM_SPAN을 나눈다(beam_hop)
const BEAM_SPAN := 0.56  # 구슬이 마지막 대상에 닿기까지의 상한. 성역 공명(S262) 14마디도 흔적 수명(1초) 안에 다 식는다
const BEAM_COOL := 0.3  # 마디가 다 그어진 뒤 금 → 모래 → 구리로 식는 시간
const ORB_FADE := 0.12  # 마지막 대상에 닿은 구슬이 줄며 사라지는 시간
const MEND_STEP := 4.0 / 60.0  # 회복 반짝 한 프레임
const PILLAR := 0.12  # 기적의 강림 빛기둥이 내려오는 시간
const PILLAR_H := 40  # 빛기둥 높이(px)
const MOTES := 6  # 성역 장판 하나에서 떠오르는 빛 점 수
const HEX_CLOSE := 0.25  # 쇠약의 저주 고리가 반경에서 조여드는 시간
const FOGS := 4  # 독안개 장판 하나에 떠도는 안개 조각 수
const FIZZ := 5  # 독안개 장판 하나에서 오르는 거품 수
const FIZZ_CYCLE := 1.1  # 거품 하나가 다시 오르는 주기
# 크로노스(금·얼음)(fx-4). 시간은 초다
const CHARGE_STEP := 4.0 / 60.0  # 과충전 번개 조각 한 프레임
const HAND_TURN := 2.4  # 시간의 문 긴 바늘이 반시계 방향으로 한 바퀴 도는 시간. 짧은 바늘은 HAND_RATIO배 느리다
const HAND_RATIO := 4.0
# 크로노스 새 칸(fx-7, I199 2026-11-04 변경). 시간은 초다
const SAND_GRAINS := 16  # 노화 흔적 안에서 떨어지는 모래알 수
const LOOP_CLOSE := 0.2  # 되돌림 고리가 반경에서 0.25배로 조여드는 시간. 이어서 LOOP_FLASH초 동안 가운데가 번쩍인다
const LOOP_FLASH := 0.08
const GHOSTS := 4  # 옛 자리 → 되돌아간 자리 잔상 수
const GATE_BLINK := 0.5  # 문에 든 적의 남은 시간 고리가 깜박이기 시작하는 남은 시간
const COGS := 28  # 태엽 감기 둘레 바깥 톱니 수
const COG_SPIN := 0.25  # 톱니가 시계 방향으로 도는 빠르기(라디안/초)
const WIND_KICK := 1.5  # 쓴 순간부터 WIND_KICK_T초 동안 톱니가 더 도는 각(라디안)
const WIND_KICK_T := 0.6
const KEY_FLIP := 0.12  # 태엽 열쇠 손잡이가 정면 ↔ 옆으로 뒤집히는 간격
# 세라피나(fx-8, I227). 시간은 초다
const CLEANSE_RISE := 0.45  # 정화된 아군 몸 양옆 빛 점 두 줄기가 발에서 머리 위로 솟는 시간(점 넷이 0.05초씩 늦게 0.3초에 솟는다)
const HEAL_TICK := 0.6  # 성역 안 아군의 금 십자가 오르는 주기
const SAVE_FLASH := 0.12  # 불사가 된 순간 크림 원판이 번쩍이는 시간
const FEATHERS := 6  # 그때 흩어지는 깃털 수
const FEATHER_FALL := 0.6
const BLESS_BLINK := 0.15  # 축복 마름모 빛 맺힘의 밝기가 바뀌는 간격
const BLESS_BURST := 0.2  # 축복 터짐 조각이 반경까지 튀는 시간
const FOLD := {-10: 1, -9: 2, -8: 3, -7: 3, -6: 4, -5: 4, -4: 4, -3: 3, -2: 3, -1: 2, 0: 2, 1: 1}  # 접힌 날개 한쪽: 어깨 기준 줄 y → 몸 가운데 4px 밖부터의 폭
# 베스퍼(fx-9, I226). 시간은 초다
const HEX_WISPS := 10  # 쇠약의 저주 고리에서 안으로 끌려 드는 검은 연기 가닥 수
const CHAIN_HOP := 0.1  # 피해 나누기 빛이 사슬 한 마디를 흐르는 시간
const CHAIN_RING := 0.15  # 빛이 닿은 적 가슴 고리가 작아지는 시간
const PLAGUE := 0.3  # 전염 고리가 죽은 자리에서 전염 반경까지 퍼지는 시간
const SKULL_IN := 0.15  # 옮은 적 머리 위 해골이 보이는 때(전염 뒤 초). SKULL_OUT까지 4px 떠오르고 마지막 SKULL_BLINK초는 깜박인다
const SKULL_OUT := 0.8
const SKULL_BLINK := 0.15
const SKULL := [".###.", "#.#.#", "#####", ".###.", ".#.#."]  # 해골 5×5(#이 크림, 둘레가 그을음)
const BOG_WAVES := 2  # 늪 가운데서 퍼지는 물결 고리 수
const BOG_WAVE_T := 1.8  # 물결 하나가 반경의 0.85배까지 퍼지는 주기
const HEX_SEGS := 12  # 쇠약의 저주 고리를 끊는 마디 수(마디마다 앞쪽 0.45~0.8만 그린다)
const HEX_SPIN := 1.0  # 저주 고리가 조여드는 동안 반시계로 도는 각(라디안)
const PLAGUE_DASH := 6  # 전염 고리 점선 한 주기(px). 앞쪽 반만 그린다
const BOG_DASH := 2  # 늪 물결 점선의 그린 칸·틈 길이(px)
const TELL_FILL := 5  # 보스 스킬 예고 안쪽 성긴 칠의 밀도(/16, fx-4)
const ALLY_FX := ["dr", "haste", "shield", "invuln", "stun", "bleed", "lag"]  # 아군에 걸린 효과(I101, 기절은 I192, 출혈은 I193 ③, 노래의 공격 속도 감소는 I252 ④)
const FOE_FX := ["stun", "root", "expose", "taunt", "seal", "chain", "dot"]  # 적에 걸린 효과(I101). 둔화는 능력치 감소 줄(DEBUFFS)이다
const DEBUFFS := ["slow", "weaken", "armor", "mr"]  # 적 능력치 감소 줄의 왼쪽부터 차례(I101 2026-11-04 변경). fx 아틀라스 «down» 프레임 차례와 같다(tools/art/fx.py)
const FOE_TELL := Color("ef692f")  # 일반 적 예고(S279): F24+ 주황 1px 테가 BLINK초마다 켜졌다 꺼진다. 안쪽은 칠하지 않는다
const BLINK := 0.25
const UNSEEN_TELLS := ["pounce", "throw", "bomb", "drop", "cannon", "bombs", "flame", "dive"]  # 적이 어둠 속에 숨어도 그리는 예고: 덮치기(S242)·던지기·폭탄·투하 표식(S279·S285·S286)·전쟁 기계 대포(S287)·대장 폭탄(S288)·불화살(I249 ①)·박치기(I251 ⑦). 덮개 위 층에 그린다
const FLAME_RING := 0.5  # 불화살 예고 원 반경(칸, S302). 판정에 쓰지 않는 그림 값이라 flame 데이터에 없다
const TELL := Color("ef3a0c")  # 보스 스킬 예고(S194): F24+ 빨강 테(바깥 어두운 테는 PX.maroon), 안쪽 성긴 칠이 차오른다(S198 fx-4)
const RAGE := Color(1.5, 0.55, 0.55)  # 분노한 보스(S195)를 붉게 그리는 modulate
const CROUCH := Vector2(1.15, 0.75)  # 슬라임 킹이 웅크림 끝에 납작해지는 배율(가로·세로, S198). 임시값
const LEAP_UP := 10.0  # 뜬 슬라임 킹을 한가운데에서 들어 올리는 높이(px, S198). 임시값
const FALL := 0.5  # 운석이 보이며 떨어지는 시간(초). 이그니스 R의 첫 운석 지연(delay)과 같다
const CORPSE_FADE := 0.5  # 쓰러진 적·용병의 몸이 시뮬레이션에서 지워지기(battle.FALLEN) 전에 흐려지는 시간(초, S180)
const FALL_STEP := 0.08  # 영웅 쓰러짐 5프레임의 한 프레임 길이(초, S180)
const FALL_RING := 5 * FALL_STEP  # 쓰러진 영웅을 덧그리고 고리가 퍼지는 시간 = 쓰러짐 5프레임(S180 2026-10-29)
const FALL_REACH := 1.5  # 그 고리가 퍼지는 반경(칸)
const HEAVY := 6.0  # 보스가 친 타격·보스 스킬에 맞은 아군의 밀림(px, S198)
const HEAVY_BACK := 0.25  # 그 밀림이 돌아오는 시간(초, S198)
const KILL_PUSH := 6.0  # 막타가 닿은 쓰러진 몸이 번쩍이는 동안 밀리는 거리(px, S197). 밀린 자리에 눕는다
const SIDE := 4.0  # 대포 범위 곁 대상의 밀림(px, S178 2026-10-28). HEAVY_BACK에 돌아온다
const ARMOR := 1.0  # 장갑이 기본 공격·타워 사격의 물리 피해에 맞은 밀림(px, S177 2026-10-28)
const ARMORED := 10.0  # 장갑으로 보는 지금 방어력(battle.armor_of, 시안 V5 값)
const STEEL := 0.2  # 장갑이 물리로 맞은 면의 강철 점이 남는 시간(초). 번쩍임(FLASH)이 끝난 뒤 0.1초 더 보인다
const STEEL_COLS := [Color("d0d6e0"), Color("4f78ad")]  # 강철 점 윗줄·아랫줄(F24+): 흰 번쩍임 위에서도 장갑 몸(807070) 위에서도 보이게
const LIFT := 0.4  # 보스 스킬 예고의 마지막 이만큼 그림을 들어 올린다(초, S198)
const VAULT_RISE := 0.15  # 도약 늑대가 웅크림을 끝내고 성벽 위로 올라서는 시간(초, S244). 임시값
const SLAM_POSE := 0.15  # 보스 스킬이 발동한 뒤 공격 자세(초, S198)
# 스킬 이름의 시트가 있는 보스(전쟁 기계 S172 2026-11-03 셋째 변경, 대장 2026-11-05 변경): 예고 끝 준비 열, 발동 뒤 SLAM_POSE마다 넘기는 정점 열, 기관총 왼·오른 자세로 넘어가는 각(도)
const READY := {"mgun": 1}  # 없으면 0열
const STILL_TELL := ["fling"]  # 예고 끝에도 정지 그림인 스킬 시트(대장 집게 던지기)
const PEAK := {"grab": [1, 2], "fling": [0, 1]}  # 없으면 [1]. 집어 던지기는 집음 → 놓음, 집게 던지기는 집음 → 치켜듦
const LANDING := "leap"  # 착지 흔적(slam)의 시트가 없는 보스가 착지 뒤 그리는 시트(대장 착지 웅크림)
const WRECK_FADE := 0.5  # 수레 잔해가 지워지기(battle.WRECK) 전에 흐려지는 시간(초, S172 2026-11-05 변경 ⑥)
const FAN_TURN := 20.0  # 시트 자세 ±40°의 가운데
const BLOW := {"war_machine": ["slam", 1]}  # 공격 칸이 없는 종류의 기본 공격 키 포즈 [시트, 열](S172 2026-11-03 셋째 변경 ④)
const GROW := {"slime_king": [3.0, 5.0]}  # 몸이 큰 종류(S236 2026-10-29 변경: 킹 몸 반지름 2칸)의 [그림 배율, 배율 전 그림을 내리는 px]. 정수배라 도트가 고르고, 내리면 그림 가운데가 몸 가운데에 온다
const POP := 0.3  # 갈라져 나온 적이 죽은 자리에서 제자리로 튀어나오는 시간(초, S234 2026-10-29 변경)
const POP_UP := 6.0  # 그동안 포물선으로 뛰는 높이(px)
const POP_FROM := 0.5  # 튀어나오기 시작할 때의 그림 배율. POP초에 1이 된다
const FILL := 2  # 발동한 처음 이만큼의 프레임은 예고 모양을 채운다(S198). 시간이 아니라 프레임으로 세어 프레임률과 상관없이 2프레임이다
const SLIDE := 400.0  # 넉백·끌어옴 미끄러짐: 거리/SLIDE초, 0.12~0.3초(S198)
const DUST := Color("927e6a")  # 먼지(F24+)
const CRACK := [Color("1f240a"), Color("a56243")]  # 바닥 균열의 어두운 금과 그 아래 밝은 가장자리(F24+). 어두운 금만으로는 풀 위에서 안 보였다(시안 V2)
const JOLT := 0.05  # 맞은 구조물·성곽 칸·거점 그림을 1px 옮겨 그리는 시간(초, 3프레임, S199)
const DEBRIS := Color("efd8a1")  # 구조물 부스러기(S199): 돌 회청색·나무 갈색과 다른 밝은 모래색(F24+). 시안의 재질 색은 거의 안 보였다
const HERO_LOW := 0.5  # 영웅 체력이 이 비율 밑이면 V와 상관없이 막대를 그린다(S73 2026-10-29)
const HP_BAR_DROP := 8  # 영웅·용병·적(보스 빼고) 체력바 윗변이 발 자리보다 아래인 px(S276 Claude 임시값)
const GUARD_BAR := Color("a0a0a0")  # 남은 방패 막대(I248 ④): 체력 막대 바로 위 회색
const BAR_TIERS := [Color("ef3a0c"), Color("e0c040"), Color("7cc85a")]  # 구조물·성곽·거점 막대(S199): 25% 밑·50% 밑·그 위. 위 띠 거점 막대(S190)의 HudTheme.DANGER·HudBuild.WARN·HudTheme.GOOD와 같은 값
const SOFT_FLASH := Color(255, 255, 255, 0.4)  # 번쩍임 줄이기(S184): 같은 그림을 255배·알파 0.4로 덧그리면 흰 40%다(S177, S197)
const STONE := Color("7a86a0")  # 무너진 성곽 칸에서 떨어지는 돌 조각(S200, F24+ 성벽 돌색)
const DROP := 0.15  # 무너진 성곽 칸 위 유닛이 땅으로 내려오는 시간(초, S200)
const STEP := 0.15  # 땅↔성벽을 오르내리거나 기어오르기를 마친 스텝이 미끄러지는 시간(초, S198 2026-10-28)
const RIM := 8  # 맵 둘레에 맵 밖 바닥색으로 칠하는 폭(px, S200). 화면 흔들림(최대 3 기준 화면 px)이 가장자리에서 빈 곳을 보이지 않게
const PIXEL_FONT := preload("res://art/fonts/Galmuri7.ttf")  # 맵 위 숫자(S167). 맵은 640×360을 정수배로 키우므로 벡터 글자는 뭉개진다
const GROUND_TILES := preload("res://art/tiles/ground.png")  # 0행 풀↔흙 꼭짓점 16꼴, 1행 풀·흙 변종과 깃발, 2·3행 전환 꼴 변종(tools/art/tiles.py)
const DECOR := preload("res://art/tiles/decor.png")  # 들판·마을 장식(S201·S202, tools/art/decor.py): 0행 16×16 바위 3·그루터기 2·구덩이 2·자갈 2·풀 2·풀꽃·우물, 1행 48×32 그을음 3, 2행 48×48 마른 나무 4, 3행 16×16 마당 소품(S215)
const YARD_ROW := 96  # decor.png 3행(마당 소품)의 y: 텃밭 2·울타리 2·장작더미·목재 더미·톱밥·판석. 그림은 칸 왼쪽 위에 붙어 있다
const YARDS := {"house": 0, "church": -4, "barracks": 10, "workshop": 0, "archery": 0}  # 터가 있는 시설(S215) → 터 가로 반지름에 더하는 px(yard_radius)
# 다 지은 시설의 마당 소품(S215): 변형마다 [decor.png 3행 열, 구조물의 칸 왼쪽 위에서 본 그림 자리(px)]. 칸 x+y로 변형을 고른다.
# 자리는 지금 크기(S216: 집 2×2·작업장 3×2·교회 2×3)에 맞춘 것이다. 크기를 바꾸면 다시 정한다
const YARD_PROPS := {
	"house": [[[0, Vector2(33, 3)], [2, Vector2(-14, 12)], [4, Vector2(-6, 9)]], [[1, Vector2(-15, 3)], [3, Vector2(32, 12)], [4, Vector2(31, 9)]]],
	"workshop": [[[5, Vector2(47, 9)], [6, Vector2(-4, 15)]]],
	"church": [[[7, Vector2(9, 16)]]],
}
const PAVE := Color("56607a")  # 돌길·광장 박석 색(S202)
# 수로·연못(S220, tools/art/water.py): 바닥 위 물 덮개와 북벽 수문 덮개, 얹는 맵 px 왼쪽 위.
# ponytail: 자리는 _plan의 물 칸(45열 수로·44~49열 연못)에 맞춘 지금 판 값이다. 판이 늘면 _plan과 함께 옮긴다
const WATER := preload("res://art/tiles/water.png")
const WATER_AT := Vector2i(704, 32)  # tools/art/water.py 덮개 왼쪽 위(옛 마을 (3,3) 기준 맵 px (672, 0))를 PLAN_SHIFT칸만큼 옮긴 자리
const CULVERT := preload("res://art/castle/culvert.png")
const CULVERT_AT := Vector2i(744, 48)  # 수문 덮개 자리(옛 (712, 16) + PLAN_SHIFT칸). 그림은 아래 24px에 있어 높아진 북벽 안쪽 앞면(48~80) 아래에 앉는다
const FOREST_FLOOR := Color("2a1d0d")  # 맵 아래 맵 밖 띠(I50)의 바닥(S201): 마른 나무가 선 그을린 흙
const CASTLE := preload("res://art/castle/walls.png")  # 성곽 조각(두께 5칸, S217 2026-11-03 변경): 행 단계 1~3마다 몸체·앞층, 통로 그늘, 잔해. 열 성벽 한 열·열린 문·닫힌 문·문 양옆 탑(tools/art/atlas.py castle)
const WALL_PIECE_H := 145  # 성곽 조각 높이(px, tools/art/wall.py PIECE_H). 맨 아랫줄이 앞줄 바닥선 바로 위 줄이고 윗줄은 양옆 탑 뒤 모서리다
const WALL_COLS := {"castle_wall": [0, 16], "open": [16, 48], "closed": [64, 48], "tower_l": [112, 16], "tower_r": [128, 16],
	"n_wall": [144, 16], "n_closed": [160, 48], "n_tower_l": [208, 16], "n_tower_r": [224, 16], "sc_l": [240, 80], "sc_r": [320, 80],
	"nc_l": [400, 80], "nc_r": [480, 80], "w_strip": [560, 80], "e_strip": [640, 80], "w_gate": [720, 80], "e_gate": [800, 80]}  # 조각 열 [x, 폭](px). 모서리·동서 조각은 두께 5칸(80px)
const WALL_TOP_UP := 33  # 성벽 그림 윗변이 성곽 윗줄 위끝보다 높은 px(S175, S170 2026-11-03 변경: 앞면 32px)
const GATE_RISE := 17  # 문루 바닥이 성벽 통로보다 높은 px(S170, tools/art/wall.py와 같다)
const TOWER_RISE := 27  # 문 양옆 탑 바닥이 성벽 통로보다 높은 px(S170, tools/art/wall.py와 같다)
const SIDE_GATE_RISE := 8  # 동·서 닫힌 문루 바닥이 통로보다 높은 px(S219, tools/art/wall.py와 같다)
const CORNER_RISE := 12  # 모서리 탑 바닥이 통로보다 높은 px(S219, tools/art/wall.py와 같다)
const TOP_BAND := 92  # 맵 위 맵 밖 띠 높이(맵 px): 카메라가 위로 보이는 최대(1배 줌, I50 2026-10-26 변경). 4의 배수라 밤 덮개 디더가 맵 칸과 맞는다
const RING := 4  # 문루·탑 둘레 난간 높이(px). 그 그림 윗변은 바닥보다 이만큼 더 높다(wall.py ph 0.32 = 3.6px)
const LADDER := preload("res://art/castle/ladder.png")  # 공성탑 사다리 띠(S172 2026-11-03 둘째 변경 ④): 성벽 열 한 칸(16px)씩 3칸. 사다리 먼 끝부터 이어 자른다(tools/art/raid.py ladder)
const TOWER_TOP := 59  # 공성탑 다리판 자세 북쪽 그림 맨 윗줄이 발밑보다 높은 px(heroes.png 공격 칸에서 잼). 사다리가 여기서 성벽 위로 걸친다(S172 2026-11-03 넷째 변경 ①)
const KEEP := preload("res://art/castle/keep.png")  # 거점 망루 80×80, 마을 레벨 1·2. 칸 앞쪽 아래 왼쪽 모서리가 그림의 (32, 72)다(tools/art/keep.py)
const KEEP_AT := Vector2(-32, CELL - 72)  # 거점 칸 왼쪽 위에서 본 망루 그림 왼쪽 위
const KEEP_BODY := [Rect2(29, 23, 22, 49), Rect2(21, 13, 38, 59)]  # 마을 레벨 1·2 망루 그림의 불투명 사각형(keep.png를 잼). 그림을 바꾸면 다시 잰다
const FACILITY := preload("res://art/castle/facility.png")  # 시설 96×96: 0행 그림, 1행 청사진 바탕. 구조물의 칸(차지 칸의 앞 왼쪽 칸, S216) 앞쪽 아래 왼쪽 모서리가 그림의 FAC_FOOT다(tools/art/facility.py)
const FAC_N := 96  # 시설 그림 한 칸의 크기(px)
const FAC_FOOT := Vector2(16, 92)
static var TUNNEL := []  # 터널 입구 그늘을 깔기 전 바닥 조각 [그림, 맵 px 왼쪽 위](S219 2026-10-28). 바닥을 구울 때(_wall_shade) 뜬다
static var FAC: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/castle/facility.json"))  # 종류 → [열, 그림 맨 윗줄, 맨 아랫줄 + 1]
# 금(S199)을 구운 성곽·시설·망루 아틀라스(I172). 원본 대신 이것으로 그려서 금이 생겨도 텍스처가 바뀌지 않는다. 성곽은 앞층(바깥 벽면)에만 긋는다
static var CASTLE_K: ImageTexture = crack_atlas(CASTLE, _wall_pieces())
static var FACILITY_K: ImageTexture = crack_atlas(FACILITY, FAC.values().map(func(f): return Rect2i(FAC_N * int(f[0]), int(f[1]), FAC_N, int(f[2] - f[1]))))
static var KEEP_K: ImageTexture = crack_atlas(KEEP, [Rect2i(0, 0, 80, 80), Rect2i(80, 0, 80, 80)])
const BLUEPRINT := Color(0.55, 0.78, 1.0, 0.6)  # 청사진 색(사용자 2026-10-20, 림월드 설계도). 회색 바탕에 곱한다
const GHOST := Color(1, 1, 1, 0.4)  # 거점에 가려진 유닛·시설을 덧그리는 색(C1, 사용자 2026-10-20)
const SHADE := Color(0, 0, 0, 0.55)  # 성벽에 가려진 부분의 실루엣 색(S175). 55%는 사용자가 고른 시안의 합성 색에 맞춘 Claude 값
const WALL_H := 32  # 성벽 앞면 높이(px). S170 2026-11-03 변경(사용자 «성벽 높이도 조금더 키우자» → «32px», 옛 4.0 확정값 24)
const TEAM := [Color("3c9f9c"), Color("ef3a0c")]  # 발밑 팀 색(S166): 아군 청록, 적 빨강(F24+ 팔레트)
const ORDER_MARK := 0.4  # 명령 표식이 보이는 시간(초, S205)
const ORDER_COLORS := [Color("40ff80"), Color("ef3a0c")]  # 명령 표식(S205): 이동 초록, 공격 빨강(적 발밑 색)
const SELECT_GLOW := 1.9  # 고른 것의 발밑 타원 밝기 배율(S207)
const SELECT_LINES := [Color("d8fff6"), Color("ffb0a0")]  # 발밑 선택 테두리(S207): 고른 유닛, 선택 패널의 적
const GHOST_OK := Color.WHITE  # 놓기 미리보기(S216): 지을 수 있음
const GHOST_NO := Color("ef3a0c")  # 지을 수 없음(적 발밑 빨강)
static var FEET: ImageTexture = _feet()  # 발밑 채운 타원 14×6px. 아군·적을 한 장에 나란히 둬서 draw call이 끊기지 않는다
const NIGHT_COLOR := Color("0b1030")  # 어둠 덮개 색(S212)
const TORCH := Color("ffb060")  # 불빛 가장자리에 엷게 비치는 횃불 색(S212)
const NIGHT_ALPHA := 0.85  # 불빛 밖 덮개 불투명도 = 이 값 × 어둠(S212)
const TORCH_ALPHA := 0.25  # 횃불 색이 가장 짙은 곳(불빛 단계의 가운데)의 불투명도 × 어둠(S212)
const NIGHT_LIGHTS := 128  # 덮개 셰이더에 넘기는 불빛 수 상한. 넘으면 앞의 것만 그린다. 적이 보이는지는 시뮬레이션이 모든 불빛으로 본다(S213)
# 어둠 덮개(S212): 맵 px마다 가장 밝은 불빛을 고르고(반경의 절반까지 1, 반경에서 0), 4×4 바이어 디더로 4단계로 끊는다.
# 화면 px마다 돌지만 맵 px(UV × 덮개 크기의 내림)로 끊어 도트처럼 보인다
const NIGHT_SHADER := """shader_type canvas_item;
uniform float dark = 0.0;
uniform float alpha;
uniform float torch_alpha;
uniform int count = 0;
uniform vec4 lights[%d];
uniform vec2 px_size = vec2(1.0);
uniform vec2 origin = vec2(0.0);
uniform vec4 night_color : source_color;
uniform vec4 torch_color : source_color;
const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	vec2 local = floor(UV * px_size) + 0.5;
	vec2 p = local + origin;
	float lit = 0.0;
	for (int i = 0; i < count; i++) {
		lit = max(lit, 1.0 - smoothstep(0.5, 1.0, distance(p, lights[i].xy) / lights[i].z));
	}
	ivec2 q = ivec2(local) %% 4;
	float s = clamp(floor(lit * 4.0 + BAYER[q.y * 4 + q.x] / 16.0) / 4.0, 0.0, 1.0);
	float a = alpha * dark * (1.0 - s);
	float g = torch_alpha * dark * 4.0 * s * (1.0 - s);
	COLOR = vec4((night_color.rgb * a + torch_color.rgb * g) / max(a + g, 0.0001), a + g);
}
""" % NIGHT_LIGHTS

var battle
var controls  # 고른 유닛에 테두리를 그린다
var _seen := {}  # 영웅·용병·적 → [지난 위치, 방향]
var _wreck_dirs := {}  # 수레 잔해를 남긴 몸 → 잔해가 보는 쪽(처음 그릴 때 그 몸의 _seen 방향, S172 2026-11-05 변경 ⑥)
var _hits := {}  # 방금 맞은 영웅·용병·적 id → [맞은 뒤 지난 시간(초), 공격자 → 대상 방향, 밀림(px), 돌아오는 시간(초), 강철 점](S177, S198, hit_table). _bodies마다 다시 구한다
var ground: ImageTexture  # 바닥을 한 장으로 구운 것. 마을·출현 지점은 도전 내내 같아서(I91) 처음 한 번만 굽는다
var _decor := []  # 바닥 소품(S201·S202): [칸, decor.png 0행 열]. 바닥과 함께 처음 한 번만 정한다
var _under: Image  # 구운 바닥. 터(bake_yard)가 돌 위를 피하려고 읽는다
var _yards := {}  # [칸, 종류] → bake_yard 결과. 시설이 처음 보일 때 한 번 굽고, 없어지면 버린다(S215)
var _clip := -INF  # 덧그릴 때 이 화면 y보다 위 줄은 그리지 않는다(_shade)
var clock := 0.0  # 화면 시계(I170): 시뮬레이션 step과 같은 delta를 더한다(tick). ESC 메뉴면 main이 멈춰 같이 멈춘다
var events := []  # 이번 프레임에 새로 생긴 사건(I171): {kind, at, dir, src, dst, n, heavy}. 연출과 효과음(WBS 5.3)이 읽는다
var _n := 0  # 사건 번호. 효과 모양의 무작위 씨앗이다(I170)
var _live := false  # 이번 프레임에 사건을 내나(I171)
var _primed := false  # 첫 tick은 이미 있던 흔적·잔해·쓰러짐을 사건으로 내지 않고 기억만 한다
var _from_battle := false  # 전투에서 결과 단계로 넘어왔다(I171)
var _atk := {}  # 공격자 id → [지난 친 뒤 시간, 그 공격이 닿았나]. 공격 하나에 닿음은 한 번이다(I171)
var _dead := {}  # 처치 사건을 기다리는 쓰러진 대상 id → [대상, 처음 본 시각, 쓰러질 때 보던 방향]. 그동안 선 자세로 그린다(S197)
var _killed := {}  # 막타가 닿은 쓰러진 대상 id → [닿은 시각, 밀리는 방향(없으면 0), 대상, 보던 방향](S197). 몸이 남은 동안만 둔다
var _gone := {}  # 지난 프레임까지 본 쓰러짐(fallen) id
var _known := []  # 본 흔적. traces는 step마다 새 배열이라 is_same으로 견준다
var _rubble := {}  # 본 잔해 칸
var _tell := {}  # 보스 id → [예고 가운데(맵 px), 반경(px)]. 예고가 끊기면 둘레에 조각을 흩는다(S198)
var _dots := []  # 효과 점(I172): {p0, p1, rise, t0, life, fade, col, size, ground}
var _fade := 1.0  # 지금 그리는 흔적의 불투명도(S179 2026-10-29). 아트 px 도우미가 색 알파에 곱한다
var _slides := {}  # id → [지난 화면 자리, 시작 시각, 길이](S198 미끄러짐)
var _pops := {}  # 갈라져 나온 적 id → 나온 시각(S234 2026-10-29 변경)
var _fills := []  # [보스 스킬 흔적, 남은 프레임](S198 발동 채움). tick마다 하나씩 줄인다. 기관총은 흔적 대신 {at, dir, range, arc}다
var _firing := {}  # 발사 중으로 본 기관총 적(S198 발동 채움). tick이 처음 본 발사에 채움을 넣는다
var _zone_t0 := []  # [장판, 처음 본 화면 시각](4.1s 펼침). 장판은 Dictionary라 is_same으로 찾는다
var _ghost := []  # 놓기 미리보기 [종류, 칸, 구조물 수, 구한 시각(ms), ghost]. 공병 길찾기(I125)가 한 번에 10~25ms라 이것이 바뀌거나 0.5초 지나야 다시 구한다
static var _cells := {}  # Vector3i(반지름, 굵기, 0 고리 · 1 원판) → 아트 px 칸 오프셋
static var _runs := {}  # 같은 열쇠 → 줄마다 이은 Rect2i(draw_rect 수를 줄인다)
static var _noise := {}  # Vector3i(반지름, 밀도, 변형) → 성긴 칠 흰 마스크 텍스처
var _caps := {}  # 절대 방어선 둘레(fx-2): 칸 배치 + 반지름 → capsule_cells. 둘레가 없으면 비운다
var _last := {}  # id → [지난 프레임 화면 자리, 성벽 위·기어오르기 상태]
var _order := {}  # 마지막으로 본 명령(controls.order, S205)
var _order_t0 := 0.0  # 그 명령을 처음 본 화면 시각
var _shots := {}  # 날고 있는 투사체 id → 출발 자리(맵 px). 처음 그릴 때 쏜 쪽의 쏘는 곳이다
var _landed := {}  # 지난 프레임까지 본 닿은 투사체(battle.landed) id. 닿음·처치는 투사체 하나에 한 번이다(I171)
var night: ColorRect  # 어둠 덮개(S212): 바닥 그림(맵 밖 아래 띠까지)을 덮는 사각형 하나에 셰이더를 바른다. 맵의 자식이라 맵 그림 다음에 그린다
var _top: Node2D  # 덮개 위 층: 조준 미리보기·출현 배지·체력 막대·명령 표식·드래그 사각형(_draw_top). 덮개 다음 자식이다
var _cv: CanvasItem = self  # _draw_top의 그리기 함수가 그리는 곳. 층이 없으면(트리 밖에서 만든 맵) 맵 자신이다
var _foes := []  # 이번 프레임에 보이는 적(S213). 숨은 적은 몸·발밑·막대·효과 테두리·예고를 그리지 않는다
var _folk_now := []  # 이번 프레임의 주민 [주민 몸(battle.people), folk_of]. 덮개 위 층이 야경꾼 등불을 그 자리에 그린다(S223)
var _hammer: Texture2D  # 자동 수리 표식(I210). 처음 그릴 때 만든다(_fix_mark)

func _ready() -> void:
	if battle:
		_night_layer()

# 어둠 덮개(S212)와 그 위 층. 덮개는 클릭을 받지 않고, 낮에는 숨는다
func _night_layer() -> void:
	night = ColorRect.new()
	night.position = Vector2(0, -TOP_BAND)  # 맵 위 띠(I50)까지 덮는다
	night.size = Vector2(battle.size.x * CELL, TOP_BAND + battle.size.y * CELL + int(Camera.BOTTOM))
	night.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night.visible = false
	var sh := Shader.new()
	sh.code = NIGHT_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("px_size", night.size)
	mat.set_shader_parameter("origin", night.position)
	mat.set_shader_parameter("alpha", NIGHT_ALPHA)
	mat.set_shader_parameter("torch_alpha", TORCH_ALPHA)
	mat.set_shader_parameter("night_color", NIGHT_COLOR)
	mat.set_shader_parameter("torch_color", TORCH)
	night.material = mat
	add_child(night)
	_top = Node2D.new()
	_top.draw.connect(func():
		_cv = _top
		_draw_top()
		_cv = self)
	add_child(_top)

# 눈빛만 그리는 적(S240): 어둠 속에 숨은 밤 늑대
func eyes() -> Array:
	return [] if battle.dark <= 0.0 else battle.enemies.filter(func(e): return not e.night.is_empty() and not battle.seen(e.pos))

# 맵에 그리는 적(S213): 어둠 속에 숨은 적은 뺀다
func foes() -> Array:
	return battle.enemies if battle.dark <= 0.0 else battle.enemies.filter(func(e): return battle.seen(e.pos))

# 예고를 그리는 적(S194): 예고 중인 보이는 적. UNSEEN_TELLS(덮치기 S242, 던지기·폭탄·투하 S279, 대포 S287, 불화살 I249)는 적이 어둠 속에 숨어도 그린다(S213)
func tellers(shown = null) -> Array:
	var vis: Array = foes() if shown == null else shown
	return battle.enemies.filter(func(e): return e.cast != null and e.cast.id != "ladder" and (e.cast.id in UNSEEN_TELLS or e in vis))  # 사다리 내리기는 예고가 없다(S284)

# 적 e의 예고 색: 보스 스킬(S194)은 빨강, 일반 적 행동(S279)은 주황
func tell_color(e) -> Color:
	return TELL if e.cast != null and e.skills.has(e.cast.id) else FOE_TELL

# 덮개 셰이더에 지금 어둠과 불빛(맵 px 가운데·지금 반경 px)을 넘긴다. 낮이면 그리지 않는다
func night_params() -> Dictionary:
	var pts := PackedVector4Array()
	pts.resize(NIGHT_LIGHTS)
	var n := 0
	if battle.dark > 0.0:
		for l in battle.lights.slice(0, NIGHT_LIGHTS):
			var c: Vector2 = l[0] * CELL + Vector2(CELL, CELL) / 2.0
			pts[n] = Vector4(c.x, c.y, minf(l[1] / battle.dark, 4096.0) * CELL, 0.0)
			n += 1
	return {"dark": battle.dark, "count": n, "lights": pts}

func _draw() -> void:
	if ground == null:
		ground = bake_ground(battle)
		_decor = ground_props(battle)
		_under = ground.get_image()
	_foes = foes()
	# 맵 위 맵 밖 띠(I50): 사방 성곽의 북벽 그림이 맵 위로 솟는다(S219). 둘레 RIM까지 칠해 화면이 흔들려도(S200) 빈 곳이 안 보인다. 바닥 그림이 그 위를 덮는다
	draw_rect(Rect2(-RIM, -TOP_BAND - RIM, battle.size.x * CELL + 2 * RIM, TOP_BAND + battle.size.y * CELL + int(Camera.BOTTOM) + 2 * RIM), FOREST_FLOOR)
	draw_texture(ground, Vector2.ZERO)  # 카메라가 아래로 보이는 맵 밖(I50)까지 한 장이다
	var tp := tunnel_patch()
	if not tp.is_empty():  # 정문이 잔해면 터널 입구 그늘을 덮는다(S219 2026-10-28)
		draw_texture(tp[0], tp[1])
	var yards := {}
	for s in battle.structures.values():  # 시설 터(S215). 바닥을 다시 구우면 75ms라 시설마다 따로 구운 그림을 얹는다
		if YARDS.has(s.kind):
			var k := [s.cell, s.kind]
			yards[k] = _yards[k] if _yards.has(k) else bake_yard(battle, s, _under)
			draw_texture(yards[k][0], yards[k][1])
	_yards = yards
	for p in _decor:  # 시설이 선 칸의 소품은 감춘다(S201)
		if not battle.footprint.has(p[0]):
			draw_texture_rect_region(DECOR, Rect2(Vector2(p[0]) * CELL, Vector2(CELL, CELL)), Rect2(p[1] * CELL, 0, CELL, CELL))
	for s in battle.structures.values():
		for p in yard_props(s):
			if not battle.water.has(Vector2i((p[1] + Vector2(CELL, CELL) / 2.0) / CELL)):  # 소품 가운데가 물 칸이면 그리지 않는다(I181)
				draw_texture_rect_region(DECOR, Rect2(p[1], Vector2(CELL, CELL)), Rect2(p[0] * CELL, YARD_ROW, CELL, CELL))
	for r in battle.rubble.values():  # 잔해(I88)는 바닥 층: 몸통과 정렬하지 않고 장판·발밑·쓰러진 몸보다 먼저 깐다(S170 2026-10-28)
		_wall_piece(r, 0)
	if controls.placing != "":  # 격자선은 놓기 모드에서만(4.1b, 사용자 2026-10-20)
		var map := Vector2(battle.size) * CELL
		for x in battle.size.x + 1:
			draw_line(Vector2(x * CELL, 0), Vector2(x * CELL, map.y), COLORS.grid)
		for y in battle.size.y + 1:
			draw_line(Vector2(0, y * CELL), Vector2(map.x, y * CELL), COLORS.grid)
	for s in battle.structures.values():  # 시설 그림은 _bodies가 유닛과 함께 정렬해 그린다(4.1e)
		if s.dest != null:  # 옮겨 갈 칸(S44): 청사진 색 테두리와 대포에서 이어지는 점선. 칸의 대포 청사진은 _bodies가 그린다(S176)
			draw_rect(_rect(s.dest), Color(BLUEPRINT, 1.0), false, 1.0)
			draw_dashed_line(_center(Vector2(s.cell)), _center(Vector2(s.dest)), Color(1, 1, 1, 0.7), 1.0, 3.0)
	_zones()
	_wards()  # 에너지 성벽 칸(S151, fx-2): 장판 다음, 몸통 아래
	_tells()  # 보스 스킬 예고와 발동 채움(S194·S198)
	_fx_dots(true)  # 바닥 균열(S198)은 몸통 아래
	_traces(false)  # 폭발 연기·운석 그림자는 몸통 아래(4.1s, Gemini 고칠 점 2)
	_folded_wings()  # 수호 천사·불사의 등 뒤 날개(I227 ③)
	for p in battle.forecast:  # 기본 적의 예상 경로(S142): 엷은 빨간 선, 유닛 아래에. 너비 1이면 1배 줌에서 칸 중심을 지나는 가로·세로 구간이 안 그려진다
		draw_polyline(PackedVector2Array(p.map(func(c): return _center(Vector2(c)))), Color(COLORS.spawn, 0.5), 1.5)
	for h in battle.heroes:  # 오라 반경(S113): 오라가 있는 살아 있는 영웅마다 둘레에 늘 엷게, 유닛 아래에(I101)
		if h.alive and not h.aura.is_empty():
			_aura_ring(h)
	_bodies()
	_marks()
	_chrono_marks()
	_sera_marks()
	_mire_marks()
	_ignis_marks()
	_burning()
	for u in battle.units:
		var at := _spot(u) + _slip(u)  # 넉백으로 미끄러지는 몸을 테두리·숫자가 따라간다(S198)
		if u.is_hero:  # 영웅 레벨(I117): 오른쪽 위에 작게
			draw_string(PIXEL_FONT, at + Vector2(CELL * 0.3, -CELL * 0.3), str(u.level), HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		if u.auto_fix:  # 자동 수리가 켜진 공병(I210): 오른쪽 위에 작은 망치
			draw_texture(_fix_mark(), (at + Vector2(CELL * 0.3, -CELL * 0.75)).floor())
		if u in controls.selected and u.hold:  # 고른 유닛의 표시는 발밑(_feet_mark, S207). 홀드면 기준 반경을 그린다(S36)
			_pring(Vector2i((u.anchor * CELL + Vector2(CELL, CELL) / 2).floor()), int(CELL * u.hold_radius), 1, Color(1, 1, 1, 0.4))
		_status(u, true)  # 걸린 효과(I101 2026-10-27 변경): 효과마다 수단 하나
	for e in _foes:
		_status(e, false)
	for h in battle.heroes:  # 쓰러진 영웅: 복귀할 때까지 쓰러진 자리에 그 영웅 색의 X(I130). 누운 몸(S180) 위에, 막타가 닿은 때부터 밀린 자리에(S197)
		var at = _cross_at(h)
		if at != null:
			var c: Vector2 = at
			var r := Vector2(CELL, CELL) * 0.3
			draw_line(c - r, c + r, HERO_COLORS[h.kind], 2.0)
			draw_line(c + Vector2(-r.x, r.y), c + Vector2(r.x, -r.y), HERO_COLORS[h.kind], 2.0)
		var rg := fall_ring(h)
		if not rg.is_empty():
			_pring(Vector2i(rg[0].floor()), rg[1], rg[2], Color(HERO_COLORS[h.kind], rg[3]))
	# 원거리 공격은 시뮬레이션 투사체(S178). 근접 공격은 선을 그리지 않는다(S71 변경). 선(화살)과 원(구슬·대포알)이 번갈아 그려지면 배치가 끊겨서 모양끼리 모아 그린다
	var shots: Array = battle.missiles.filter(func(m): return m.wait <= 0.0)
	shots.sort_custom(func(a, b): return a.look < b.look)
	var starts := {}
	for m in shots:
		_missile(m, starts)
	_shots = starts
	_feathers()
	_impacts()  # 사각형이라 구슬·대포알과 한 배치다. 대포알 고리도 아트 px 사각형이라 이어진다
	for m in battle.landed:  # 대포알이 떨어진 곳에 범위 피해 반경까지 퍼지는 2px 주황 고리(S178 2026-10-28, I101 2026-10-28 셋째 변경)
		if m.look == "ball" and m.age < BLAST:
			_pring(Vector2i(_drop_at(m).floor()), int(CELL * m.splash * m.age / BLAST), 2, Color(PX.orange, 1.0 - m.age / BLAST))
	_fx_dots(false)  # 먼지·조각(I172): 투사체 다음 층에 모아서
	_traces(true)
	# 어둠 덮개(S212)는 맵의 자식이라 여기까지(효과) 위에 그려진다. 그 위 층(_top)이 조준 미리보기·체력 막대·명령 표식·드래그 사각형이다
	if _top:
		_top.queue_redraw()
	else:
		_draw_top()

# 덮개 위 층(S212). 그리기는 _cv(층 또는 맵 자신)에 한다
func _draw_top() -> void:
	_aim_preview()
	_pounce_tells()
	_foe_tells()
	_snipe_pointers()
	if battle.state == "prep":
		_spawn_badges()
	for u in battle.units + _foes:  # 영웅·용병·적 막대는 hp_bar_rect 자리에(S276)
		var bar := hp_bar_size(u, controls.show_hp)
		if bar != Vector2.ZERO:
			var r := hp_bar_rect(u, bar)
			_bar_in(r, u)
			if u.get("guard"):  # 남은 방패(I248 ④): 체력 막대 바로 위에 같은 크기 회색 막대
				var top := Rect2(r.position - Vector2(0, r.size.y), r.size)
				_cv.draw_rect(top, Color.BLACK)
				_cv.draw_rect(Rect2(top.position, Vector2(top.size.x * u.guard / u.max_guard, top.size.y)), GUARD_BAR)
	for v in battle.people:  # 다친 주민(S227)은 V와 상관없이 막대를 그린다
		if v.hp < v.max_hp and not v.inside:
			_hp_bar(v.pos, v)
	if battle.dark > 0.0 and not _folk_now.is_empty():  # 야경꾼 등불(S223): 덮개 위 그림이라 불빛·숨긴 적은 그대로다
		for k in _folk_now[1].size():
			if _folk_now[1][k].job == "watchman" and not _folk_now[0][k].inside:
				var lamp := _center(_folk_now[0][k].pos) + LAMP
				_cv.draw_rect(Rect2(lamp - Vector2.ONE, Vector2(3, 3)), Color(TORCH, 0.6))
				_cv.draw_rect(Rect2(lamp, Vector2.ONE), Color("efd8a1"))
	for e in eyes():  # 숨은 밤 늑대의 눈빛(S240, I193 ④): 덮개 위라 어둠 속에서도 보인다. 몸 가운데보다 조금 위, 2px 간격 두 점
		var at := _spot(e) - Vector2(0, CELL * e.radius * 0.5)
		_cv.draw_rect(Rect2(at + Vector2(-2, 0), Vector2.ONE), EYES)
		_cv.draw_rect(Rect2(at + Vector2(1, 0), Vector2.ONE), EYES)
	var cue := order_ring()
	if not cue.is_empty():
		_pring(Vector2i(cue[0].floor()), int(cue[1]), 1, cue[2])  # 아트 px(I101 2026-10-28 셋째 변경)
	if controls.drag_rect.has_area():
		_cv.draw_rect(controls.drag_rect, Color.WHITE, false, 1.0)

# 명령 표식(S205): [가운데(맵 px), 반경(px), 색]. 새 명령을 처음 본 때부터 ORDER_MARK초 동안 줄어든다. 대상 공격은 그 적의 발밑을 따라간다. 없으면 []
func order_ring() -> Array:
	if not is_same(controls.order, _order):
		_order = controls.order
		_order_t0 = clock
	var age := clock - _order_t0
	if _order.is_empty() or age >= ORDER_MARK:
		return []
	var at: Vector2 = _spot(_order.foe) + _slip(_order.foe) if _order.foe else _order.at
	return [at, CELL * lerpf(0.6, 0.2, age / ORDER_MARK), ORDER_COLORS[int(_order.attack)]]

# 곧 부를 웨이브에서 출현 지점마다 나올 적 수(S188): 깃발 칸 바로 위, 풀밭에 묻히지 않게 검은 바탕에 Galmuri7 8px(S167)
func _spawn_badges() -> void:
	var counts: Array = battle.spawn_counts(battle.round_index, battle.wave_index)
	for i in battle.spawns.size():
		var text := str(counts[i].values().reduce(func(n, x): return n + x, 0))
		var w: float = PIXEL_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var box := Rect2((Vector2(battle.spawns[i]) * CELL + Vector2(CELL / 2.0 - w / 2.0 - 2.0, -10.0)).round(), Vector2(w + 4.0, 9.0).round())
		_cv.draw_rect(box, Color.BLACK)
		_cv.draw_string(PIXEL_FONT, box.position + Vector2(2, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)

# 날아가는 깃털(S304, I250 ④): 깃털 자리에서 가슴 높이(6px 위)에 대상 쪽을 향한 흰 깃 7px 선
func _feathers() -> void:
	for f in battle.feathers:
		var p: Vector2 = _center(f.pos) + Vector2(0, -6)
		var d: Vector2 = (f.target.pos - f.pos).normalized()
		_pline(Vector2i((p - d * 6.0).round()), Vector2i(p.round()), FEATHER)

# 날고 있는 투사체 하나(S178). 출발 자리(처음 그릴 때 쏜 쪽의 쏘는 곳 _muzzle, starts에 남긴다)에서 대상 가슴까지, 시뮬레이션에서 날아간 비율만큼 간 자리에 그린다.
# 화살은 짧은 선, 마법은 쏜 쪽 색 구슬, 대포알은 포물선이다. 대상이 쓰러져 마지막 자리로 가는 대포알은 쓰러진 몸 쪽으로 간다.
# 논타겟팅 투사체(S178 2026-11-04 변경)는 대상 대신 조준점의 노린 적 가슴 높이로 간다. 화살은 조준점 너머로 그 높이를 지키며 사거리 끝까지 난다(I224 ⑤)
func _missile(m, starts: Dictionary) -> void:
	var id: int = m.get_instance_id()
	var from: Vector2 = _shots.get(id, _muzzle(m.src))
	starts[id] = from
	var ground: Vector2 = _center(m.mark) - Vector2(0, _lift(m.target)) if m.free else _spot(m.target)
	var to := ground + Vector2(0, -6)  # 가슴(_chest)
	var gone: float = m.from.distance_to(m.pos)
	var k := gone / maxf(gone + m.pos.distance_to(m.at), 1e-6)
	var d := (to - from).normalized()
	var p := from.lerp(to, k)
	if m.free and m.look == "arrow":
		var f := minf(gone / maxf(m.from.distance_to(m.mark), 0.01), 1.0)
		p = _center(m.pos) + Vector2(0, lerpf(from.y - _center(m.from).y, to.y - _center(m.mark).y, f))
	match m.look:
		"arrow":
			draw_line(p - d * 7, p, Color("e8dcc0"), 1.0)
			_arrow_wind(m, p, d)
		"bolt":
			var col: Color = HERO_COLORS.get(m.src.kind, Color("80b0ff"))
			_blob(p - d * 3, 1, Color(col, 0.5))
			_blob(p, 2, col)
			_blob(p, 0, Color.WHITE)
		"ball":
			_blob(_spot(m.src).lerp(ground, k), 1, Color(0, 0, 0, 0.35))
			_blob(p - Vector2(0, 4.0 * BALL_ARC * k * (1.0 - k)), 2, Color("2a2a30"))

# 실비아 바람을 지난 화살(I215 2026-11-01 변경). p는 화살촉, d는 나는 방향이다.
# 순풍·바람의 길을 지난 화살과 실비아 화살(정조준 비율만큼)은 연두 꼬리를 달되 쏜 자리 뒤로는 내지 않는다.
# 렌즈를 지난 화살은 촉 쪽이 굵고 밝으며, 렌즈 관문 경계에서 10px 안이면(막 지났을 때) 촉 둘레에 번쩍 고리가 난다
func _arrow_wind(m, p: Vector2, d: Vector2) -> void:
	var srcs: Array = m.passed.map(func(z): return z.src)
	var tail := 0.0
	if "sylvia_w" in srcs:
		tail = 8.0
	if m.src.kind == "sylvia":
		tail = maxf(tail, 4.0 + 8.0 * m.aim)
	if "sylvia_r" in srcs:
		tail = 16.0
	tail = minf(tail, p.distance_to(_muzzle(m.src)) - 7.0)
	if tail > 0.0:
		_pline(Vector2i((p - d * (7.0 + tail)).round()), Vector2i((p - d * 7.0).round()), PX.lime3)
		_pline(Vector2i((p - d * (7.0 + tail * 0.5)).round()), Vector2i((p - d * 4.0).round()), PX.lime2)
	if not m.lensed:
		return
	_pline(Vector2i((p - d * 6.0).round()), Vector2i(p.round()), PX.lime1, 2)
	_pline(Vector2i((p - d * 2.0).round()), Vector2i(p.round()), PX.lime0, 2)
	for z in m.passed:
		if z.src == "sylvia_e" and Geometry2D.get_closest_point_to_segment(p, _center(z.pos), _center(z.to)).distance_to(p) < CELL * z.radius + 10.0:
			_pring(Vector2i(p.round()), 4, 1, PX.lime0)
			break

# 착탄 표시(S178 2026-10-28)와 장갑의 강철 점(S177 2026-10-28). 사각형만 쓴다.
# 화살은 맞은 몸에 박힌 꼬리와 닿은 자리의 크림색 «ㅅ», 구슬은 쏜 쪽 색 십자, 대포알은 BOOM_STEP마다 주황 → 크림 덩어리다
func _impacts() -> void:
	for m in battle.landed:
		var t = m.target
		match m.look:
			"arrow":
				if m.age < STUCK and (t.alive or m.age < FLASH):  # 쓰러진 몸은 눕기 전(막타 번쩍임)까지
					var at: Vector2 = (_chest(t) + (_flinch(t) if t.alive else _last_blow(t)[2])).round()
					var d: Vector2 = (t.pos - m.from).normalized()
					_pline(Vector2i((at - d).round()), Vector2i((at - d * 4.0).round()), Color("e8dcc0"))
					for c in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(2, 1)]:
						_px(Vector2i(at) + c, PX.cream)
			"bolt":
				if m.age < MARK:
					var at := Vector2i(_chest(t).round())
					var col: Color = HERO_COLORS.get(m.src.kind, Color("80b0ff"))
					_px(at - Vector2i(2, 0), col, Vector2i(5, 1))
					_px(at - Vector2i(0, 2), col, Vector2i(1, 5))
			"ball":
				if m.age < 2.0 * BOOM_STEP:
					var first: bool = m.age < BOOM_STEP
					_blob(_drop_at(m) - Vector2(0, 3), 3 if first else 2, PX.orange if first else PX.cream)
	for x in battle.units + _foes:  # 강철 점: 맞은 면(공격자 쪽) 2px, 윗줄 밝게 아랫줄 어둡게
		var h = _hits.get(x.get_instance_id())
		if h != null and h[4] and h[0] < STEEL:
			var p := Vector2i((_chest(x) + _flinch(x) - h[1] * 3.0).round()) - Vector2i.ONE
			_px(p, STEEL_COLS[0], Vector2i(2, 1))
			_px(p + Vector2i(0, 1), STEEL_COLS[1], Vector2i(2, 1))

# 가운데 c, 반지름 r px의 십자형 도트 덩어리(r 0이면 1px). draw_circle은 원마다 draw call이 하나씩 늘어 사각형 둘로 그린다
func _blob(c: Vector2, r: int, col: Color) -> void:
	draw_rect(Rect2(c - Vector2(r, r - 1 if r > 0 else 0), Vector2(2 * r + 1, maxi(2 * r - 1, 1))), col)
	if r > 0:
		draw_rect(Rect2(c - Vector2(r - 1, r), Vector2(2 * r - 1, 2 * r + 1)), col)

# 쏘는 곳(맵 px). 타워는 그림 위의 쏘는 자리, 유닛은 손 높이다
func _muzzle(x) -> Vector2:
	return _spot(x) + MUZZLE.get(x.kind, Vector2(0, -10))

# 투사체가 닿는 곳: 몸통 가운데(발밑에서 6px 위)
func _chest(x) -> Vector2:
	return _spot(x) + Vector2(0, -6)

# 대포알이 떨어진 곳(맵 px): 시뮬레이션이 떨어뜨린 자리(at)에 노린 적의 높이(성벽 위면 성벽 위)를 준다
func _drop_at(m) -> Vector2:
	return _center(m.at) - Vector2(0, _lift(m.target))

# 원거리: 타워, 사거리 2칸을 넘는 영웅·용병, 깃털을 쏘는 깃털 사수 하피(S304). 나머지는 근접이다
func _ranged(x) -> bool:
	return x.get("pos") == null or (x.get("range") != null and x.range > 2.0) or (x.get("feather") is Dictionary and not x.feather.is_empty())

# 흔적의 스킬 이름: 칸(Q·W·E·R)이면 그 칸 스킬, 아니면(운석 착탄·태세 터뜨림·보스 스킬) slot 그대로
func _skill(c) -> String:
	return c.hero.get(c.slot).id if c.slot in battle.SLOTS else c.slot

# 적을 노린 즉시 스킬이 아무도 못 맞혔나(S179 2026-10-29): 피해·회복을 받은 대상(hits)도 효과를 건 대상(marked)도 없다
func missed(c) -> bool:
	return _skill(c) in MISSABLE and c.hits.is_empty() and not c.marked

# 즉시 스킬 흔적(S179): 쓴 뒤 영웅 색으로. 범위 스킬은 반경까지 퍼지는 고리, 방향·대상 스킬은 영웅에서 잇는 선이다.
# 이그니스의 화염구 작렬·운석 착탄은 단계 있는 폭발, 서리 고리는 결정과 서리꽃이다(4.1s fx-1, I229). 실비아는 바람이다(fx-2). 아이아스는 밀려 나가는 방패·베기·충격파·팔각 충격파·공명 고리다(I228).
# 세라피나는 빛 구슬이 건너가는 빛줄기·날개·빛기둥과, 정화 빛 점·불사 깃털·축복 터짐 조각이다(fx-3, I227). 베스퍼는 조여드는 검은 연기 고리·사슬 거는 줄·전염 고리와 해골이다(I226). 크로노스는 금 번개 줄(fx-4)과, 노화의 모래빛 점선 테·모래시계, 되돌림의 조여드는 얼음 고리·잔상이다(I199 2026-11-04 변경).
# 보스 스킬 흔적은 예고색 램프 고리다(S198). 모두 아트 px로 그리고, 적을 노린 스킬이 아무도 못 맞혔으면 MISS_FADE로 그린다(S179 2026-10-29).
# top이 아니면 몸통 아래 층(폭발 연기·운석 그림자·포효 먼지·밀린 적 흙먼지·터뜨림 균열·요새화 돌담·꽂힌 화살·천사 날개·되돌림 잔상·되돌아갈 자리)만 그린다. 떨어지는 운석·화살과 영혼 사슬도 그린다. 무엇을 어디에 썼는지는 시뮬레이션이 남긴 흔적(traces)이 준다
func _traces(top: bool) -> void:
	for c in battle.traces:
		var h = c.hero
		var id := _skill(c)
		var at := Vector2i(_center(c.at).floor())
		if _boss(h) and not battle.seen(c.at):  # 숨은 보스(S213)의 흔적은 그리지 않는다
			continue
		_fade = MISS_FADE if missed(c) else 1.0
		var seed := hash(str(c.at) + c.slot)
		match id:
			"fireball", "meteor":
				_boom(at, CELL * c.radius, c.age, seed, id == "meteor", top)
				continue
			"frost_ring":
				if top:
					_frost(at, CELL * c.radius, c.age, seed)
				continue
			"shield_bash":
				if top:
					_bash(at, CELL * c.radius, (c.aim - c.at).angle(), deg_to_rad(h.q.arc) / 2.0, c.age, c.hits)
				else:
					_shove(at, c.hits, c.age)
				continue
			"war_cry":
				_cry(at, CELL * c.radius, c.age, seed, h, top)
				continue
			"brace":
				if top and c.age < FX:
					_spr("aegis", 0 if c.age < 0.05 else (1 if c.age < 0.2 else 2), Vector2i((_spot(h) + _slip(h) - Vector2(0, _head(h) * 0.5)).floor()))
				continue
			"burst":
				_burst(at, CELL * c.radius, c.age, seed, c.hits, top)
				continue
			"resonate":  # 성벽 공명(S257, I228 ⑥): 성벽 칸마다
				if top:
					_resonate(at, c.age)
				continue
			"piercing_gale":
				if top:
					_gale(at, (c.aim - c.at).normalized(), c.age, seed, c.hits)
				continue
			"wind_path":
				if top:
					_snipe(at, Vector2i(_center(c.aim).floor()), c.age, c.hits)
				continue
			"holy_beam":
				if top:
					_beam(h, c.hits, c.age)
				continue
			"guardian":
				_angel(h, c.aim, c.age, top)
				continue
			"miracle":
				if top:
					_miracle(c.hits, c.age)
				continue
			"cleanse":
				if top:
					_cleanse(c.aim, c.age)
				continue
			"saved":
				if top:
					_rescue(c.aim, c.age)
				continue
			"bless":
				if top and battle.seen(c.at):
					_bless_burst(at - Vector2i(0, 6), CELL * c.radius, c.age)
				continue
			"enfeeble":
				if top:
					_hex(at, CELL * c.radius, c.age, seed)
				continue
			"soul_chain":
				if top:
					_shackle(h, c.aim, c.age)
				continue
			"spread":
				if top:
					_plague(at - Vector2i(0, 2), c)
				continue
			"share":  # 피해 나누기 빛은 사슬과 함께 끝에서 그린다
				continue
			"overcharge":
				if top:
					_charge(h, c.aim, c.age)
				continue
			"aging":
				if top:
					_aging(at, int(CELL * c.radius), c, seed)
				continue
			"loop":
				_rewind(at, int(CELL * c.radius), c, top)
				continue
		var k: float = c.age / FX
		if top and k < 1.0 and _boss(h) and c.radius > 0.0:  # 보스 스킬(S198): 원 모양 스킬의 고리가 반경의 절반에서 1.1배까지 퍼진다. 예고색 램프(F24+, fx-4). 부채꼴·직선(대장 철퇴·돌진, S288)은 반경 0이라 고리가 없다
			_pring(at, int(CELL * c.radius * (0.5 + 0.6 * _out(k))), 2 if k < 0.5 else 1, _ramp(["orange", "red", "blood"], k))
	_fade = 1.0
	for z in battle.zones:  # 떨어지는 운석(이그니스 R): 마지막 FALL초 동안 오른쪽 위에서 내려온다
		var d: float = z.get("delay", 0.0)
		if d > 0.0 and d < FALL:
			_fall(z, d, top)
	if not top:
		for l in battle.loops:  # 문에 든 적(I199 2026-11-04 변경): 되돌아갈 자리 점과, 적에서 그 자리 쪽으로 흐르는 흐린 얼음 점선. 숨은 적(S213)은 그리지 않는다
			if l.e in _foes:
				var p := Vector2i(_center(l.at).floor())
				_dash_line(Vector2((_spot(l.e) + _slip(l.e)).floor()), Vector2(p), PX.ice3, 2, 2, -clock * 8.0)
				_pring(p, 3, 1, PX.ice1)
				_px(p, PX.ice0)
		for h in battle.heroes:  # 요새화 돌담(I228 ①)
			_fort_wall(h)
		return
	var links := {}  # 영혼 사슬(I226 ②): 같은 사슬에 묶인 적을 E 대상(hub)에서 시작하는 나무로 잇는 쇠사슬. 숨은 적(S213)은 잇지 않는다
	for e in _foes:
		var v = e.fx.get("vesper_e")
		if v:
			if not links.has(v.chain):
				links[v.chain] = []
			links[v.chain].append(e)
	for ch in links:
		var es: Array = links[ch]
		var hub = es[0].fx.vesper_e.get("hub")
		var edges := chain_tree(hub if hub in es else es[0], es)
		for ed in edges:
			_chain(_chest(ed[0]), _chest(ed[1]))
		for c in battle.traces:  # 피해 나누기(I226 ③)
			if c.slot == "share" and c.chain == ch and c.aim in es:
				_chain_flow(c.aim, edges, c.age)

# 사슬 나무(I226 ②): root에서 시작해, 이은 적과 아직 안 이은 적 가운데 가슴이 가장 가까운 쌍부터 잇는다(프림). 돌려주는 것: [부모, 자식] 목록
func chain_tree(root, es: Array) -> Array:
	var rest := es.filter(func(e): return e != root)
	var best := rest.map(func(e): return _chest(root).distance_squared_to(_chest(e)))
	var par := rest.map(func(_e): return root)
	var edges := []
	while not rest.is_empty():
		var j := 0
		for i in rest.size():
			if best[i] < best[j]:
				j = i
		var x = rest[j]
		edges.append([par[j], x])
		rest.remove_at(j)
		best.remove_at(j)
		par.remove_at(j)
		for i in rest.size():
			var d := _chest(x).distance_squared_to(_chest(rest[i]))
			if d < best[i]:
				best[i] = d
				par[i] = x
	return edges

# 쇠사슬 한 마디(I226 ②): 굵기 2px, 4px마다 크림 1 · 재 2 · 검정 틈 1. 아래 1px 검은 그림자를 먼저 깐다
func _chain(p: Vector2, q: Vector2) -> void:
	var n := maxi(int(p.distance_to(q)), 1)
	for j in n + 1:
		_px(Vector2i(p.lerp(q, float(j) / n).floor()) + Vector2i(0, 1), PX.night, Vector2i(2, 1))
	for j in n + 1:
		var ph := j % 4
		_px(Vector2i(p.lerp(q, float(j) / n).floor()), PX.night if ph == 3 else (PX.cream if ph == 0 else PX.ash), Vector2i(2, 1))

# 피해 나누기 빛(I226 ③): 맞은 적 가슴에서 CHAIN_RING초 동안 반지름 3 → 7px로 퍼지는 크림 고리(바깥 검정 1px)와, 맞은 적에서 나무를 따라
# 마디마다 CHAIN_HOP초에 흐르는 크림 빛(5×3px, 가운데 청록 3×1px, 바깥 검정 1px). 빛이 닿은 적 가슴에 CHAIN_RING초 동안 반지름 6 → 3px로 작아지는 청록 고리
func _chain_flow(origin, edges: Array, t: float) -> void:
	if t < CHAIN_RING:
		var o := Vector2i(_chest(origin).floor())
		var rr := 3 + int(4.0 * t / CHAIN_RING)
		_pring(o, rr + 1, 1, PX.night)
		_pring(o, rr, 1, PX.cream)
	var lvl := {origin: 0}
	var par := {}
	var order := [origin]
	var i := 0
	while i < order.size():  # 나무에서 맞은 적부터 몇 마디째인지
		var x = order[i]
		for ed in edges:
			for s in 2:
				var y = ed[1 - s]
				if ed[s] == x and not lvl.has(y):
					lvl[y] = lvl[x] + 1
					par[y] = x
					order.append(y)
		i += 1
	for y in order.slice(1):
		var a = par[y]
		var k: float = (t - CHAIN_HOP * lvl[a]) / CHAIN_HOP
		if k >= 0.0 and k <= 1.0:
			var p := Vector2i(_chest(a).lerp(_chest(y), k).floor())
			_px(p - Vector2i(3, 2), PX.night, Vector2i(7, 5))
			_px(p - Vector2i(2, 1), PX.cream, Vector2i(5, 3))
			_px(p - Vector2i(1, 0), PX.teal, Vector2i(3, 1))
		var k2: float = (t - CHAIN_HOP * lvl[y]) / CHAIN_RING
		if k2 >= 0.0 and k2 < 1.0:
			_pring(Vector2i(_chest(y).floor()), 6 - int(3.0 * k2), 1, PX.teal if k2 < 0.5 else PX.midteal)

# 전염(I226 ④): 죽은 적 자리에서 전염 반경까지 PLAGUE초에 퍼지는 점선 고리(청록 → 짙은 청록 → 깊은 청록, 굵기 2 → 1, 바깥 검정 1px, 약 PLAGUE_DASH px 주기)와,
# 옮은 적마다 머리 위 해골(SKULL_IN~SKULL_OUT초에 4px 떠오르고 마지막 SKULL_BLINK초 깜박)
func _plague(at: Vector2i, c) -> void:
	var t: float = c.age
	if t < PLAGUE:
		var k := t / PLAGUE
		var r := int(4.0 + (CELL * c.radius - 4.0) * _out(k))
		_seg_ring(at, r, 2 if k < 0.5 else 1, _ramp(["teal", "midteal", "deepteal"], k), maxi(4, int(TAU * r / PLAGUE_DASH)), 0.0)
	var k2 := (t - SKULL_IN) / (SKULL_OUT - SKULL_IN)
	if k2 < 0.0 or k2 >= 1.0 or (t > SKULL_OUT - SKULL_BLINK and fmod(t, 0.1) < 0.05):
		return
	for e in c.foes:
		if e.alive and e in _foes:
			_skull(_crown(e) - Vector2i(0, int(4.0 * k2)))

# 해골(SKULL 5×5, p가 가운데): 그을음 테두리를 먼저 깔고 크림 몸을 얹는다
func _skull(p: Vector2i) -> void:
	for body in [false, true]:
		for y in 5:
			for x in 5:
				if SKULL[y][x] != "#":
					continue
				var q := p + Vector2i(x - 2, y - 2)
				if body:
					_px(q, PX.cream)
				else:
					for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						_px(q + d, PX.soot)

# 범위 폭발(4.1s, 화염구 작렬·운석 착탄): 폭발 조각 6프레임(흰 섬광 → 날카로운 터짐 → 불 덩어리 → 초승달) + 앞 0.2초 고리(굵기 3 → 0) + 불티 방사선.
# 고리는 하나만 그리고 섬광은 밝게 채운다(Gemini 고칠 점 1). 연기는 몸통 아래 층(top = false)에 그린다(고칠 점 2). 운석은 돌 조각이 튄다
func _boom(c: Vector2i, rad: float, t: float, seed: int, big: bool, top: bool) -> void:
	if not top:
		var k := (t - 0.2) / 0.45
		if k >= 0.0 and k < 1.0:
			for i in 4:
				_spr("puff", int(k * 3.0), c + Vector2i(int((_hf(seed, i) - 0.5) * rad), int((_hf(seed, i + 5) - 0.5) * rad * 0.6) - int(8.0 * k)))
		return
	var fr := int(t / BOOM_STEP)
	if fr < int(FX_ART.boom[4]):
		_spr("boom", fr, c)
	if t < 0.2:
		var k := t / 0.2
		_pring(c, int(rad * (0.25 + 0.85 * _pow3(k))), int(ceil(3.0 * (1.0 - k))), _ramp(["cream", "gold", "orange"], k))
	var n := 12 if big else 8
	for i in n:  # 불티: 바깥으로 눕힌 짧은 선, 길이가 줄고 식는다
		var life := 0.32 + 0.16 * _hf(seed, i)
		if t >= life:
			continue
		var k := t / life
		var dir := Vector2.from_angle(TAU * i / n + _hf(seed, i + 20) * 0.6)
		var p0 := c + Vector2i(dir * rad * (0.2 + _pow3(k)) * (0.7 + 0.4 * _hf(seed, i + 40)))
		_pline(p0, p0 - Vector2i((dir * (4.0 * (1.0 - k) + 1.0)).round()), _ramp(EMBER, k))
	if big and t < 0.55:  # 운석: 튀는 돌 조각(중력)
		for i in 6:
			var dir := Vector2.from_angle(-PI * (0.15 + 0.7 * _hf(seed, i + 60)))
			var v := 70.0 + 50.0 * _hf(seed, i + 61)
			_spr("rock", i, c + Vector2i(Vector2(dir.x * v * t, dir.y * v * t + 160.0 * t * t)))

# 서리 고리(4.1s, I229 ④): 앞 0.25초 고리(굵기 2 → 1, 얼음 램프) + 바닥 서리꽃(지점에서 반경 0.95배까지 FLOWER_GROW초에 뻗는 여섯 갈래,
# 갈래마다 반경 0.45·0.7배 자리에 양쪽 잔가지, FLOWER_COOL초에 걸쳐 밝은 얼음 → 어두운 얼음) + 고리 자리에 솟는 얼음 결정 10개(자람 · 다 자람 · 금 감)
func _frost(c: Vector2i, rad: float, t: float, seed: int) -> void:
	if t < 0.25:
		var k := t / 0.25
		_pring(c, int(rad * (0.2 + 0.9 * _pow3(k))), 2 if k < 0.5 else 1, _ramp(["ice0", "ice1", "ice2"], k))
	if t < FLOWER_COOL:
		var grow := _pow3(t / FLOWER_GROW)
		var col := _ramp(["ice0", "ice0", "ice1", "ice2"], t / FLOWER_COOL)
		for i in 6:
			var a := TAU * i / 6.0 + _hf(seed, 0) * TAU
			var d := Vector2.from_angle(a)
			_pline(c, c + Vector2i((d * rad * 0.95 * grow).round()), col)
			for j in 2:
				var at := d * rad * (0.45 + 0.25 * j) * grow
				for sgn: float in [-1.0, 1.0]:
					_pline(c + Vector2i(at.round()), c + Vector2i((at + Vector2.from_angle(a + sgn * 0.7) * 5.0 * grow).round()), col)
	for i in 10:
		var k := (t - 0.06 - 0.12 * _hf(seed, i)) / 0.55
		if k >= 0.0 and k < 1.0:
			var p := c + Vector2i(Vector2.from_angle(TAU * i / 10.0 + _hf(seed, i + 30) * 0.5) * rad * (0.8 + 0.2 * _hf(seed, i + 31)))
			_spr("shard", 0 if k < 0.15 else (1 if k < 0.7 else 2), p, true)

# 떨어지는 운석(4.1s, I229 ⑥): 몸통 아래 층은 땅 그림자(성긴 칠이 짙어지고 커짐), 위 층은 꼬리 여덟과 불 원판(빨강 4 · 주황 3 · 금 2px) 위의 운석 조각.
# 떨어질 자리는 _meteor_tell이 그린다
func _fall(z: Dictionary, d: float, top: bool) -> void:
	var k := 1.0 - d / FALL
	var g := Vector2i(_center(z.pos).floor())
	if not top:
		_pnoise(g, 2 + int(6.0 * k), PX.soot, 4 + int(8.0 * k))
		return
	var dir := Vector2(0.5, -1.0).normalized()
	var p := g + Vector2i(Vector2(0.5, -1.0) * 80.0 * d / FALL)
	for i in range(8, 0, -1):  # 꼬리: 뒤로 갈수록 작고 어둡다
		_pdisc(p + Vector2i(dir * i * 4.0), maxi(3 - i / 2, 0), _ramp(["orange", "red", "blood", "smoke", "dark"], i / 8.0))
	_pdisc(p, 4, PX.red)
	_pdisc(p, 3, PX.orange)
	_pdisc(p - Vector2i(1, 1), 2, PX.gold)
	_spr("meteor", int(clock * 12.0), p)

# 아직 떨어지지 않은 운석 자리(I229 ⑥, 몸통 아래 층): 반경 자리를 도는 주황 점선 테 + 가운데에서 차오르는 주황 칠(3/16, 반지름 = 반경 × 지연이 지나간 몫)
func _meteor_tell(z: Dictionary) -> void:
	var g := Vector2i(_center(z.pos).floor())
	var r := int(CELL * z.radius)
	var k: float = 1.0 - z.delay / z.fall if z.get("fall", 0.0) > 0.0 else 0.0
	_pring(g, r, 1, PX.orange, 3, clock * 2.0)
	_pnoise(g, maxi(int(r * k), 1), PX.orange, 3, 1)

# 스킬에 맞은 적마다 작은 섬광(fx-2, 방패 강타·관통의 바람살): spark 3프레임. 숨은 적(S213)에는 그리지 않는다
func _sparks(hits: Array, t: float) -> void:
	var f := int(t / SPARK_STEP)
	if f >= int(FX_ART.spark[4]):
		return
	for e in hits:
		if battle.seen(e.pos):
			_spr("spark", f, Vector2i(_chest(e).floor()))

# 방패 강타(아이아스 Q, I228 ③): BASH_SLAM초 동안 방패 조각(흰 번쩍 → 보라 방패)이 영웅에서 부채꼴 쪽으로 반경의 0.2배 → 0.7배 밀려 나간다.
# 베기는 부채꼴 끝을 따라 SWEEP초에 반경까지 퍼지는 초승달(앞 가장자리 크림 두 겹, 안쪽 보라, 겹 수 4 → 2)이고, 그 뒤 BASH_TAIL초까지 반경 자리의 2px 호가 어두워진다. 맞은 적마다 작은 섬광
func _bash(c: Vector2i, rad: float, d: float, half: float, t: float, hits: Array) -> void:
	if t < BASH_SLAM:
		_spr("aegis", 0 if t < 0.04 else 1, c + Vector2i((Vector2.from_angle(d) * rad * (0.2 + 0.5 * _pow3(t / BASH_SLAM))).round()) - Vector2i(0, 4))
	if t < SWEEP:
		var k := t / SWEEP
		var r := int(rad * (0.3 + 0.7 * _pow3(k)))
		var cols := ["cream", "cream", "vio0", "vio1"]
		for i in maxi(int(ceil(4.0 * (1.0 - k))), 2):
			_parc(c, r - i, 1, d - half, d + half, PX[cols[i]])
	elif t < BASH_TAIL:
		_parc(c, int(rad), 2, d - half, d + half, _ramp(["vio1", "vio2", "vio3"], (t - SWEEP) / (BASH_TAIL - SWEEP)))
	_sparks(hits, t)

# 방패 강타에 밀린 적(I228 ③, 몸통 아래 층): 요새화 중 방패 강타의 둔화(aias_q_slow)가 걸린 맞은 적마다, 발 양옆으로 흙먼지 셋씩이 SHOVE초에 퍼진다.
# c는 흔적 가운데(쓴 때 영웅 자리). 끌린 자국은 몸에 가려 그리지 않는다(시안 B)
func _shove(c: Vector2i, hits: Array, t: float) -> void:
	if t >= SHOVE:
		return
	var k := t / SHOVE
	for e in hits:
		if not (e in _foes) or not e.fx.has("aias_q_slow"):
			continue
		var f := Vector2((_spot(e) + _slip(e)).floor())
		var dir := (f - Vector2(c)).normalized()
		var n := Vector2(-dir.y, dir.x)
		for s in [-1.0, 1.0]:
			for i in 3:
				var p: Vector2 = f + n * s * (5.0 + 3.0 * i + 4.0 * _pow3(k)) - dir * (i - 1) * 2.0 + Vector2(0, 1)
				_px(Vector2i(p.round()), _ramp(["cream", "ash", "smoke"], k), Vector2i(2, 2))

# 전장의 포효(아이아스 W, fx-2·I228 ④): 충격파 고리 둘(둘째는 CRY_ECHO초 늦게, 굵기 3·2 → 0, 보라 램프)과 영웅 머리 위로 부채꼴로 뻗는 외침 선 다섯(0.3초, 굵기 2 → 1, 크림 → 금).
# 몸통 아래 층에는 바닥 먼지가 바깥으로 퍼진다
func _cry(c: Vector2i, rad: float, t: float, seed: int, h, top: bool) -> void:
	if not top:
		if t < 0.4:
			var k := t / 0.4
			for i in 10:
				var dir := Vector2.from_angle(TAU * i / 10.0 + _hf(seed, i) * 0.5)
				var p := c + Vector2i((dir * rad * (0.25 + 0.6 * _pow3(k)) * (0.8 + 0.3 * _hf(seed, i + 10))).round())
				_px(p, _ramp(["ash", "smoke", "dark"], k), Vector2i(2, 1))
		return
	for j in 2:
		var tt := t - j * CRY_ECHO
		if tt >= 0.0 and tt < 0.25:
			var k := tt / 0.25
			_pring(c, int(rad * (0.15 + 0.85 * _pow3(k))), int(ceil((3 - j) * (1.0 - k))), _ramp(["vio0", "vio1", "vio2"], k))
	if t < 0.3:
		var head := Vector2i((_spot(h) + _slip(h)).floor()) - Vector2i(0, int(_head(h)) - 6)  # 몸 높이보다 6px 아래에서 뻗는다(fx-10 시안 A 값)
		var k := t / 0.3
		for i in 5:
			var dir := Vector2.from_angle(-PI * (0.85 - 0.175 * i))
			var p0 := head + Vector2i((dir * (3.0 + 8.0 * _pow3(k))).round())
			_pline(p0, p0 + Vector2i((dir * 5.0).round()), PX.cream if k < 0.4 else PX.gold, 2 if k < 0.5 else 1)

# 반격의 태세 터뜨림(아이아스 E, I228 ⑥): 0.25초 동안 납작한 팔각 충격파(크림 → 보라, 굵기 2 → 1, 앞 절반은 안쪽 팔각 하나 더)와 맞은 적 섬광.
# 몸통 아래 층에는 바닥 균열 여덟(꺾인 줄, 그을음 → 어두움)이 0.6초 남는다
func _burst(c: Vector2i, rad: float, t: float, seed: int, hits: Array, top: bool) -> void:
	if not top:
		if t >= 0.6:
			return
		var col := PX.soot if t < 0.35 else PX.dark
		for i in 8:
			var dir := Vector2.from_angle(TAU * i / 8.0 + _hf(seed, i) * 0.5)
			var ln := rad * (0.45 + 0.25 * _hf(seed, i + 8))
			var mid := Vector2(c) + dir * ln * 0.5 + Vector2(-dir.y, dir.x) * (2.0 * _hf(seed, i + 16) - 1.0) * 2.0
			_pline(Vector2i((Vector2(c) + dir * 4.0).round()), Vector2i(mid.round()), col)
			_pline(Vector2i(mid.round()), Vector2i((Vector2(c) + dir * ln).round()), col)
		return
	if t < 0.25:
		var k := t / 0.25
		var r := rad * (0.2 + 0.9 * _pow3(k))
		_octa(c, r, _ramp(["cream", "vio0", "vio1", "vio2"], k), 2 if k < 0.5 else 1)
		if k < 0.5:
			_octa(c, r * 0.6, PX.vio0, 1)
	_sparks(hits, t)

# 납작한 팔각(세로 0.75배) 둘레 선 여덟. 꼭짓점은 22.5°에서 시작한다
func _octa(c: Vector2i, r: float, col: Color, w: int) -> void:
	for i in 8:
		var a := Vector2(c) + Vector2.from_angle(TAU * i / 8.0 + PI / 8.0) * r * Vector2(1.0, 0.75)
		var b := Vector2(c) + Vector2.from_angle(TAU * (i + 1) / 8.0 + PI / 8.0) * r * Vector2(1.0, 0.75)
		_pline(Vector2i(a.round()), Vector2i(b.round()), col, w)

# 성벽 공명(S257, I228 ⑥): c는 성벽 칸 가운데. 앞 0.12초 벽 조각 위끝·아래끝 줄이 크림 → 밝은 보라로 번쩍이고, 0.3초 동안 벽 위로 떠오르며 퍼지는 보라 고리(반지름 3 → 11)
func _resonate(c: Vector2i, t: float) -> void:
	var tall := int(FX_ART.ward[3])
	if t < 0.12:
		var top := Vector2i((Vector2(c) / CELL).floor()) * CELL - Vector2i(0, tall - CELL)  # _wards의 그림 왼쪽 위
		var col: Color = PX.cream if t < 0.06 else PX.vio0
		_px(top, col, Vector2i(CELL, 1))
		_px(top + Vector2i(0, tall - 1), col, Vector2i(CELL, 1))
	if t < 0.3:
		var k := t / 0.3
		_pring(c - Vector2i(0, 6 + int(6.0 * k)), int(3.0 + 8.0 * _pow3(k)), 1, _ramp(["vio0", "vio1", "vio2"], k))

# 요새화 돌담(아이아스 패시브, I228 ①, 몸통 아래 층): 요새화가 켜진 동안 발 앞 반원(오른쪽 → 아래 → 왼쪽)에 돌 다섯(4×3, 위 1px 재 · 몸 연기 · 아래 그을음 그림자).
# 켜진 때(still이 passive.still을 넘은 때)부터 FORT_RISE초에 솟고, 0.4초 동안 먼지 여섯이 튄다
func _fort_wall(h) -> void:
	if not h.alive or not h.get("fort"):
		return
	var age: float = h.still - h.passive.still
	var f := Vector2i((_spot(h) + _slip(h)).floor())
	var tall := int(round(3.0 * clampf(age / FORT_RISE, 0.0, 1.0)))
	for i in 5:
		var a := PI * i / 4.0
		var b := f + Vector2i(int(round(cos(a) * 11.0)) - 2, int(round(sin(a) * 5.0)) + 1)
		_px(b + Vector2i(0, 1), PX.soot, Vector2i(4, 1))
		if tall > 0:
			_px(b - Vector2i(0, tall - 1), PX.smoke, Vector2i(4, tall))
			_px(b - Vector2i(0, tall - 1), PX.ash, Vector2i(4, 1))
	if age < 0.4:
		for i in 6:
			var dir := Vector2.from_angle(PI * (0.1 + 0.8 * _hf(i, 3)))
			_px(f + Vector2i((dir * Vector2(14.0, 7.0) * (0.6 + age)).round()), PX.ash if age < 0.2 else PX.smoke)

# 관통의 바람살(실비아 Q, fx-2): GALE_REACH초에 맵 끝까지 뻗는 연두 몸통(굵기 3 → 1, 앞 절반은 밝은 심 1px)과 몸통 옆에서 앞으로 흐르는 바람 줄. 맞은 적마다 작은 섬광
func _gale(c: Vector2i, dir: Vector2, t: float, seed: int, hits: Array) -> void:
	if t < FX:
		var k := t / FX
		var far := CELL * 64.0 * _pow3(t / GALE_REACH)
		var end := c + Vector2i((dir * far).round())
		_pline(c, end, _ramp(["lime1", "lime2", "lime3"], k), 3 if k < 0.3 else (2 if k < 0.6 else 1))
		if k < 0.5:
			_pline(c, end, PX.lime0)
		var side := dir.orthogonal()
		for i in 8:
			var s := (0.1 + 0.8 * _hf(seed, i) + 0.5 * k) * CELL * 8.0
			if s + 6.0 > far:
				continue
			var p0 := c + Vector2i((dir * s + side * (3.0 if i % 2 == 0 else -3.0)).round())
			_pline(p0, p0 + Vector2i((dir * 6.0).round()), PX.lime0 if k < 0.5 else PX.lime2)
	_sparks(hits, t)

# 폭풍의 대동맥 저격(실비아 R, I215 2026-11-01 변경): 0.05초 동안 총구 섬광(크림 원판 + 고리)과 가는 조준선 →
# FX까지 굵은 탄도(굵기 3 → 1, 앞쪽은 밝은 심, 양옆 충격 줄이 벌어지며 사라짐) → 0.35초 동안 착탄 바람 터짐(고리 + 방사 줄 8) →
# 표적 가슴 둘레의 괄호 넷이 SNIPE_MARK초 동안 조여든다. 맞은 적 섬광
func _snipe(c: Vector2i, end: Vector2i, t: float, hits: Array) -> void:
	var side := Vector2(end - c).normalized().orthogonal()
	if t < 0.05:
		_pline(c, end, PX.lime0)
		_pdisc(c, 3, PX.cream)
		_pring(c, 5, 1, PX.lime0)
	elif t < FX:
		var k := (t - 0.05) / (FX - 0.05)
		_pline(c, end, _ramp(["lime1", "lime2", "lime3"], k), 3 if k < 0.3 else (2 if k < 0.6 else 1))
		if k < 0.5:
			_pline(c, end, PX.cream if k < 0.15 else PX.lime0)
		if k < 0.4:
			for sgn: float in [-1.0, 1.0]:
				var off := side * (3.0 + 4.0 * k) * sgn
				_pline(Vector2i((Vector2(c) + off).round()), Vector2i((Vector2(end) + off).round()), PX.lime2)
	if t < 0.35:
		var k := t / 0.35
		if t < 0.08:
			_pdisc(end, 3, PX.cream)
		_pring(end, int(3.0 + 11.0 * _pow3(k)), 2 if k < 0.5 else 1, _ramp(["cream", "lime0", "lime1", "lime2"], k))
		for i in 8:
			var d := Vector2.from_angle(TAU * i / 8.0 + 0.4)
			var p0 := Vector2(end) + d * (4.0 + 12.0 * _pow3(k))
			_pline(Vector2i(p0.round()), Vector2i((p0 - d * (4.0 * (1.0 - k) + 1.0)).round()), _ramp(["lime0", "lime1", "lime2"], k))
	if t < SNIPE_MARK:
		var k := t / SNIPE_MARK
		var g := int(12.0 - 5.0 * _pow3(k))
		var col: Color = PX.lime0 if k < 0.6 else PX.lime2
		for sx: int in [-1, 1]:
			for sy: int in [-1, 1]:
				var corner := end + Vector2i(g * sx, g * sy - 6)
				_pline(corner, corner - Vector2i(3 * sx, 0), col)
				_pline(corner, corner - Vector2i(0, 3 * sy), col)
	_sparks(hits, t)

# 화면 밖 저격 표적(I215 2026-11-01 변경): 저격 뒤 SNIPE_MARK초 동안, 표적 자리가 화면 밖이면 화면 가장자리(SNIPE_EDGE 안쪽)에
# 표적 쪽을 가리키는 연두 꺾쇠 둘(어두운 테두리). 덮개 위 층(_cv)에 그린다
func _snipe_pointers() -> void:
	var view := shown_rect()
	if view.size == Vector2.ZERO:
		return
	var inner := view.grow(-SNIPE_EDGE)
	for c in battle.traces:
		if c.age >= SNIPE_MARK or _skill(c) != "wind_path":
			continue
		var at := _center(c.aim)
		if view.has_point(at):
			continue
		var tip := at.clamp(inner.position, inner.end)
		var d := (at - tip).normalized()
		var side := d.orthogonal()
		var col: Color = PX.lime0 if c.age < SNIPE_MARK * 0.6 else PX.lime2
		for layer in 2:  # 어두운 3px 테두리를 먼저 깔아 연두 길·탄도 위에서도 보이게
			for j in 2:
				var p := tip - d * 6.0 * j
				for sgn: float in [-1.0, 1.0]:
					var wing := Vector2i((p - d * 5.0 + side * 5.0 * sgn).round())
					if layer == 0:
						_pline(wing, Vector2i(p.round()), PX.soot, 3)
					else:
						_pline(wing, Vector2i(p.round()), col if j == 0 else PX.lime1)

# 화면에서 위 HUD 띠(HUD_BAND, 화면 폭 전체)에 가리지 않는 맵 영역(맵 px). 오른쪽 아래 건설 격자(S186)는 모서리라 빼지 않는다. 트리 밖(시험의 기록 화면)이면 빈 사각형이다
func shown_rect() -> Rect2:
	if not is_inside_tree():
		return Rect2()
	var s := get_viewport_rect().size
	return get_canvas_transform().affine_inverse() * Rect2(0.0, HUD_BAND, s.x, s.y - HUD_BAND)

# 적인가(흔적의 hits에는 영웅·용병·구조물·적이 섞인다). 벽 오르기 배율은 적만 가졌다
func _is_foe(x) -> bool:
	return x.get("wall_k") != null

# 빛줄기 한 마디를 건너는 시간(I227 ①): BEAM_HOP, 마디가 많아 BEAM_SPAN을 넘으면 BEAM_SPAN을 마디 수로 나눈다
static func beam_hop(n: int) -> float:
	return minf(BEAM_HOP, BEAM_SPAN / maxf(n, 1))

# 성스러운 빛줄기(세라피나 Q, I227 ①): 영웅 손에서 빛 구슬이 맞은 차례대로 한 마디씩 건너가며 금빛 줄(굵기 2 + 크림 심)을 남긴다.
# 마디는 다 그어진 때부터 BEAM_COOL초에 금 → 모래 → 구리로 식어(굵기 2 → 1) 먼저 지난 마디가 먼저 흐려진다. 마지막 대상에 닿은 구슬은 ORB_FADE초에 준다.
# 닿은 아군에는 회복 반짝이 오르고, 적에는 크림 빛살 여덟과 원판이 난다. 숨은 적(S213)에는 그리지 않는다
func _beam(h, hits: Array, t: float) -> void:
	var n := hits.size()
	var hop := beam_hop(n)
	if n == 0 or t >= n * hop + BEAM_COOL:
		return
	var p0 := Vector2i(_muzzle(h).floor())
	for i in n:
		var x = hits[i]
		var g := (t - i * hop) / hop  # 구슬이 이 마디를 건넌 정도
		if g <= 0.0:
			return
		var p1 := Vector2i(_chest(x).floor())
		if g < 1.0:
			var end := p0 + Vector2i((Vector2(p1 - p0) * g).round())
			_pline(p0, end, PX.gold, 2)
			_pline(p0, end, PX.cream)
			_orb(end, 0.0)
			return
		var age := t - (i + 1) * hop  # 이 마디가 다 그어진 뒤
		if age < BEAM_COOL:
			var k := age / BEAM_COOL
			_pline(p0, p1, _ramp(["gold", "tan", "bronze"], k), 2 if k < 0.5 else 1)
			if k < 0.25:
				_pline(p0, p1, PX.cream)
		if not _is_foe(x):
			var f := int(age / MEND_STEP)
			if f < int(FX_ART.mend[4]):
				_spr("mend", f, p1 - Vector2i(0, 2 * f))
		elif age < 0.25 and battle.seen(x.pos):
			var kk := age / 0.25
			_rays(p1, 2.0 + 3.0 * kk, 5.0 + 5.0 * kk, PX.cream if kk < 0.4 else PX.gold)
			if kk < 0.4:
				_pdisc(p1, 2, PX.cream)
		p0 = p1
	var last := (t - n * hop) / ORB_FADE
	if last < 1.0:
		_orb(p0, last)

# 빛 구슬(I227 ①): 크림 원판 반지름 2 + 금 고리 반지름 3. k(0 → 1) 뒤 절반은 작아지며 모래빛
func _orb(p: Vector2i, k: float) -> void:
	_pring(p, 3, 1, PX.gold if k < 0.5 else PX.tan)
	_pdisc(p, 2 if k < 0.5 else 1, PX.cream)

# 여덟 갈래 빛살: 반지름 r0 ~ r1, 12시부터
func _rays(p: Vector2i, r0: float, r1: float, col: Color) -> void:
	for i in 8:
		var d := Vector2.from_angle(i * TAU / 8.0 - PI / 2.0)
		_pline(p + Vector2i((d * r0).round()), p + Vector2i((d * r1).round()), col)

# 3×3 금 십자 + 그을음 1px 테두리(성역 회복, I227 ②)
func _plus(p: Vector2i, col: Color, rim: Color) -> void:
	_px(p + Vector2i(-1, -2), rim, Vector2i(3, 5))
	_px(p + Vector2i(-2, -1), rim, Vector2i(5, 3))
	_px(p + Vector2i(0, -1), col, Vector2i(1, 3))
	_px(p + Vector2i(-1, 0), col, Vector2i(3, 1))

# 정화(I227 ②): 아군 u 몸 양옆(가운데에서 4~5px)에서 크림 → 금 빛 점 넷씩이 0.05초씩 늦게 발에서 머리 위로 솟는다. 몸 가운데는 비운다
func _cleanse(u, t: float) -> void:
	if t >= CLEANSE_RISE:
		return
	var feet := Vector2i((_spot(u) + _slip(u)).floor())
	var top := int(_head(u) * 0.75) + 6
	for side in [-1, 1]:
		for i in 4:
			var k := (t - i * 0.05) / (CLEANSE_RISE - 0.15)
			if k >= 0.0 and k < 1.0:
				_px(feet + Vector2i(side * (4 + i % 2), -int(top * _out(k))), PX.cream if k < 0.5 else PX.gold, Vector2i(1, 2))

# 불사가 된 순간(I227 ③): 몸 가운데 크림 원판(반지름 6) SAVE_FLASH초 + 위로 부채꼴로 흩어지며 떨어지는 깃털(1×2 크림 + 모래 끝)
func _rescue(u, t: float) -> void:
	if t >= FEATHER_FALL:
		return
	var c := Vector2i((_spot(u) + _slip(u)).floor()) - Vector2i(0, int(_head(u) * 0.5))
	if t < SAVE_FLASH:
		_pdisc(c, 6, PX.cream)
	for i in FEATHERS:
		var d := Vector2.from_angle(deg_to_rad(-160.0 + i * 28.0))
		var p := c + Vector2i((d * (4.0 + 14.0 * _pow3(t / FEATHER_FALL))).round()) + Vector2i(0, int(10.0 * t))
		_px(p, PX.cream, Vector2i(1, 2))
		_px(p + Vector2i(0, 2), PX.tan)

# 축복 터짐(I227 ④): 가운데 크림 십자 섬광(팔 2 → 1 → 없음) + 대각선으로 반지름 rad까지 튀는 2×2 조각 넷(크림 → 금)
func _bless_burst(c: Vector2i, rad: float, t: float) -> void:
	if t >= BLESS_BURST:
		return
	var k := t / BLESS_BURST
	var arm := 2 if k < 0.4 else (1 if k < 0.7 else 0)
	if arm > 0:
		_px(c - Vector2i(arm, 0), PX.cream, Vector2i(2 * arm + 1, 1))
		_px(c - Vector2i(0, arm), PX.cream, Vector2i(1, 2 * arm + 1))
	for i in 4:
		var d := Vector2.from_angle(PI / 4.0 + i * PI / 2.0)
		_px(c + Vector2i((d * (3.0 + (rad - 3.0) * _out(k))).round()) - Vector2i.ONE, PX.cream if k < 0.5 else PX.gold, Vector2i(2, 2))

# 축복 마름모 빛 맺힘(I227 ④, 5×5): 크림 안 + 금 테 + 그을음 1px. BLESS_BLINK초마다 금 안 + 모래 테로 어두워진다
func _bless_mark(p: Vector2i) -> void:
	var lit := fmod(clock, 2.0 * BLESS_BLINK) < BLESS_BLINK
	for r in [3, 2, 1]:
		var col: Color = PX.soot if r == 3 else ((PX.gold if lit else PX.tan) if r == 2 else (PX.cream if lit else PX.gold))
		for y in range(-r, r + 1):
			var w: int = r - absi(y)
			_px(p + Vector2i(-w, y), col, Vector2i(2 * w + 1, 1))

# 세라피나 표시(I227 ②·④): 성역 안 아군의 오르는 금 십자, 축복이 걸린 영웅 머리 위·쏘는 구조물 쏘는 곳 옆의 마름모 빛 맺힘. _marks 다음(몸통 위)에 그린다
func _sera_marks() -> void:
	var inside := {}
	for z in battle.zones:
		if z.src == "seraphina_w":
			for u in battle.units:
				if u.alive and u.pos.distance_to(z.pos) <= z.radius:
					inside[u] = true
	for u in inside:
		var ph := fmod(clock + _hf(u.get_instance_id(), 3) * HEAL_TICK, HEAL_TICK) / HEAL_TICK
		if ph < 0.8:
			_plus(Vector2i(_chest(u).floor()) - Vector2i(4, int(10.0 * ph / 0.8)), PX.gold, PX.soot)
	for h in battle.heroes:
		if h.alive and h.fx.has("seraphina_r"):
			_bless_mark(bless_spot(h))
	for s in battle.structures.values():
		if s.fx.has("seraphina_r"):
			_bless_mark(bless_spot(s))

# 축복 빛 맺힘 자리(I227 ④): 영웅은 머리 위(시트에 머리 위 여백이 있어 몸 높이의 3/4 + 4px. 손 옆은 받는 피해 감소 방패 조각과 겹친다), 쏘는 구조물은 쏘는 곳 왼쪽
func bless_spot(x) -> Vector2i:
	if x.get("pos") == null:
		return Vector2i(_muzzle(x).floor()) + Vector2i(-7, -2)
	return Vector2i((_spot(x) + _slip(x)).floor()) - Vector2i(0, int(_head(x) * 0.75) + 4)

# 등 뒤 날개(I227 ③, 몸통 아래 층): 수호 천사가 걸린 동안은 어깨 위로 솟는 접힌 날개 둘(FOLD, 위 줄 크림·아래 줄 모래·안쪽 금, 바깥 그을음 1px),
# 불사 동안은 날개 조각(불사 흔적 나이로 펼침 → 날개 → 테만, 테만은 0.5초에 0.35초 보임)
func _folded_wings() -> void:
	for u in battle.units:
		if not u.alive:
			continue
		var feet := Vector2i((_spot(u) + _slip(u)).floor())
		if u.fx.has("seraphina_e"):
			var s := feet - Vector2i(0, int(_head(u) * 0.45))
			for side in [-1, 1]:
				_px(s + Vector2i(4 * side, -11), PX.soot)
				for y in FOLD:
					var w: int = FOLD[y]
					_px(s + Vector2i((4 + w) * side, y), PX.soot)
					for i in w:
						_px(s + Vector2i((4 + i) * side, y), PX.gold if i == 0 else (PX.cream if y <= -5 else PX.tan))
		elif u.fx.has("seraphina_e_saved"):
			var t := 1.0
			for c in battle.traces:
				if c.slot == "saved" and is_same(c.aim, u):
					t = c.age
			var f := 0 if t < 0.05 else (1 if t < 0.25 else 2)
			if f < 2 or fmod(clock, 0.5) < 0.35:
				_spr("wing", f, feet - Vector2i(0, int(_head(u) * 0.5) + 2))

# 수호 천사의 날개(세라피나 E, fx-3): 영웅에서 대상까지 금빛 줄(굵기 2 → 1)과 대상 몸 둘레 고리 하나(앞 0.2초, 굵기 2 → 0).
# 몸통 아래 층에는 대상 등 뒤로 날개 조각(크림 번쩍 → 날개 → 테만)이 펼쳐져 몸이 가운데를 가린다
func _angel(h, x, t: float, top: bool) -> void:
	if t >= FX:
		return
	var mid := Vector2i((_spot(x) + _slip(x)).floor()) - Vector2i(0, int(_head(x) * 0.5))
	if not top:
		_spr("wing", 0 if t < 0.05 else (1 if t < 0.2 else 2), mid - Vector2i(0, 2))
		return
	var k := t / FX
	_pline(Vector2i(_muzzle(h).floor()), mid, _ramp(["cream", "gold", "tan"], k), 2 if k < 0.5 else 1)
	if t < 0.2:
		var kk := t / 0.2
		_pring(mid, int(4.0 + 8.0 * _pow3(kk)), int(ceil(2.0 * (1.0 - kk))), _ramp(["cream", "gold"], kk))

# 기적의 강림(세라피나 R, fx-3): 회복받은 아군마다 위에서 PILLAR초에 내려오는 빛기둥(크림 심 + 금 가장자리, 폭 5 → 1)과,
# 내려온 뒤 발밑에서 퍼지는 고리 하나와 오르는 회복 반짝이다
func _miracle(hits: Array, t: float) -> void:
	if t >= FX:
		return
	var k := t / FX
	var w := 5 if k < 0.3 else (3 if k < 0.6 else 1)
	for x in hits:
		var feet := Vector2i((_spot(x) + _slip(x)).floor())
		var top := feet.y - PILLAR_H
		var drop := int(PILLAR_H * _pow3(t / PILLAR))
		_px(Vector2i(feet.x - w / 2, top), PX.gold if k < 0.6 else PX.tan, Vector2i(w, drop))
		if w > 1:
			_px(Vector2i(feet.x, top), PX.cream, Vector2i(1, drop))
		if t >= PILLAR:
			var kk := (t - PILLAR) / (FX - PILLAR)
			_pring(feet, int(3.0 + 7.0 * _pow3(kk)), 1, _ramp(["cream", "gold", "tan"], kk))
			var f := int((t - PILLAR) / MEND_STEP)
			if f < int(FX_ART.mend[4]):
				_spr("mend", f, Vector2i(_chest(x).floor()) - Vector2i(0, 2 * f))

# 쇠약의 저주(베스퍼 W, I226 ①): 그림자. 반경 자리에 나타난 그을음 → 어둠 → 연기 고리(굵기 2 → 1, 바깥 검정 1px)가 HEX_CLOSE초에 반경의 0.6배까지 조여들며
# 반시계로 HEX_SPIN 돌고, 고리는 HEX_SEGS마디로 들쭉날쭉 끊긴 연기 테두리다. 고리에서 검은 연기 가닥 HEX_WISPS개(2px + 꼬리)가 안으로 끌려 든다.
# 저주가 걸린 반경 안 적마다 머리 위로 아래 겹화살이 가라앉는다
func _hex(c: Vector2i, rad: float, t: float, seed: int) -> void:
	if t < HEX_CLOSE:
		var k := t / HEX_CLOSE
		var r := int(rad * (1.0 - 0.4 * _pow3(k)))
		_seg_ring(c, r, 2 if k < 0.5 else 1, _ramp(["soot", "dark", "smoke"], k), HEX_SEGS, -HEX_SPIN * k, absi(seed))
		for i in HEX_WISPS:
			var dir := Vector2.from_angle(TAU * i / HEX_WISPS + _hf(seed, i) * 0.5)
			var p := c + Vector2i((dir * rad * (1.0 - 0.75 * _pow3(k))).round())
			_px(p, PX.night, Vector2i(2, 2))
			_px(p - Vector2i((dir * 2.0).round()), PX.dark)
	if t >= FX:
		return
	for e in _foes:
		if e.fx.has("vesper_w") and _center(e.pos).distance_to(Vector2(c)) <= rad + CELL * e.radius:
			var head := Vector2i((_spot(e) + _slip(e)).floor()) - Vector2i(0, int(_head(e)) + 6 - int(5.0 * t / FX))
			_spr("hex", int(t / FX * 3.0), head)

# 영혼 사슬을 거는 순간(베스퍼 E, fx-3): 영웅에서 대상까지 청록 줄(굵기 2 → 1)과 대상 둘레 고리 하나(앞 0.2초, 굵기 2 → 0).
# 묶인 적끼리 잇는 사슬은 _traces 끝에서 그린다. 숨은 대상(S213)에는 그리지 않는다
func _shackle(h, x, t: float) -> void:
	if t >= FX or not battle.seen(x.pos):
		return
	var k := t / FX
	var p := Vector2i(_chest(x).floor())
	_pline(Vector2i(_muzzle(h).floor()), p, _ramp(["teal", "midteal", "deepteal"], k), 2 if k < 0.5 else 1)
	if t < 0.2:
		var kk := t / 0.2
		_pring(p, int(3.0 + 7.0 * _pow3(kk)), int(ceil(2.0 * (1.0 - kk))), _ramp(["teal", "midteal"], kk))

# 무기 과충전(크로노스 Q, fx-4): 영웅 손에서 대상의 쏘는 곳까지 금 줄(굵기 2 → 1, 앞 절반은 크림 심 1px)과, 그 자리에서 떠오르는 번개 조각
# (크림 번쩍 → 금 번개 → 식은 테), 앞 0.2초 고리 하나. 대상은 영웅이나 쏘는 구조물이라 몸 높이(_head) 대신 쏘는 곳(_muzzle)에 그린다
func _charge(h, x, t: float) -> void:
	if t >= FX:
		return
	var k := t / FX
	var p0 := Vector2i(_muzzle(h).floor())
	var p := Vector2i(_muzzle(x).floor())
	_pline(p0, p, _ramp(["gold", "tan", "bronze"], k), 2 if k < 0.5 else 1)
	if k < 0.5:
		_pline(p0, p, PX.cream)
	var f := int(t / CHARGE_STEP)
	if f < int(FX_ART.charge[4]):
		_spr("charge", f, p - Vector2i(0, 2 * f))
	if t < 0.2:
		var kk := t / 0.2
		_pring(p, int(3.0 + 7.0 * _pow3(kk)), int(ceil(2.0 * (1.0 - kk))), _ramp(["cream", "gold"], kk))

# 노화(크로노스 W, I199 2026-11-04 변경): 앞으로 감기. 반경 자리 점선 테가 FX초에 두 바퀴 시계 방향으로 돌고, 안에서 모래알이 떨어진다.
# 반경 안 노화 걸린 적 머리 위에는 위 칸 모래가 빠지는 모래시계가 뜬다
func _aging(at: Vector2i, r: int, c, seed: int) -> void:
	var k: float = c.age / FX
	if k >= 1.0:
		return
	var col := _ramp(["cream", "tan", "ash"], k)
	_pring(at, r, 1, col, 2, TAU * 2.0 * k)
	for i in SAND_GRAINS:
		var o := Vector2.from_angle(_hf(seed, i) * TAU) * sqrt(_hf(seed, i + 30)) * (r - 3)
		var p := at + Vector2i((o + Vector2(0, 14.0 * k * k + 3.0 * k - 6.0)).round())
		_px(p, col)
		_px(p - Vector2i(0, 1), Color(col, 0.5))
	for e in _foes:
		if e.fx.has("chronos_w") and e.pos.distance_to(c.at) <= c.radius + 0.5:  # 쓴 뒤 FX초 동안 반경 밖으로 걸어 나간 적도 잡게 반 칸 여유
			_hourglass(_crown(e), 1.0 - k, PX.tan, PX.cream, PX.soot)

# 타임 루프 되돌림 충격파(크로노스 E, I199 2026-11-04 변경): 되감기. 반경 자리 반시계 얼음 점선이 LOOP_CLOSE초에 0.25배로 조여든 뒤 가운데가 번쩍인다.
# 몸통 아래 층에는 옛 자리(aim) → 되돌아간 자리 잔상이 옛 자리 쪽부터 사라진다. 노화 되감기(S266)로 피해가 커졌으면(aged) 조여든 뒤 금 고리가 반경 너머로 터진다
func _rewind(at: Vector2i, r: int, c, top: bool) -> void:
	var t: float = c.age
	if not top:
		if c.foe in _foes:  # 숨은 적(S213)의 잔상은 그리지 않는다
			var a := _center(c.aim)
			var b := _center(c.at)
			var tall := int(_head(c.foe) * 0.8)
			for i in GHOSTS:
				var u := float(i) / GHOSTS
				var life := 0.15 + 0.25 * u
				if t < life:
					var p := Vector2i(a.lerp(b, u).round())
					var col := _ramp(["ice1", "ice2", "ice3"], t / life)
					_px(p + Vector2i(-1, -tall), col, Vector2i(3, tall))
					_px(p + Vector2i(-2, -tall + 2), col, Vector2i(5, tall - 4))
		return
	if t < LOOP_CLOSE:
		var k := t / LOOP_CLOSE
		_pring(at, int(r * (1.0 - 0.75 * _pow3(k))), 2 if k < 0.5 else 1, _ramp(["ice0", "ice1", "ice2"], k), 3, -PI * k)
	elif t < LOOP_CLOSE + LOOP_FLASH:
		_pdisc(at, 3, PX.ice0)
	var k2 := (t - 0.18) / 0.22
	if c.aged and k2 >= 0.0 and k2 < 1.0:
		_pring(at, int(r * (0.25 + 0.9 * _out(k2))), 2 if k2 < 0.5 else 1, _ramp(["cream", "gold", "tan"], k2))
		for i in 10:
			var d := Vector2.from_angle(TAU * i / 10 + 0.2)
			_px(at + Vector2i((d * r * (0.3 + 0.9 * _out(k2))).round()), PX.tan if k2 < 0.5 else PX.ash, Vector2i(2, 2))

# 머리 바로 위 표시(모래시계·남은 시간 고리)의 가운데: 발에서 몸 높이 + 5px 위
func _crown(x) -> Vector2i:
	return Vector2i((_spot(x) + _slip(x)).floor()) - Vector2i(0, int(_head(x)) + 5)

# 아트 px 점선: on px 켜고 off px 끈다. shift가 줄면 무늬가 b 쪽으로 흐른다
func _dash_line(a: Vector2, b: Vector2, col: Color, on := 2, off := 2, shift := 0.0) -> void:
	var n := int(a.distance_to(b))
	for i in n + 1:
		if fposmod(i + shift, on + off) < on:
			_px(Vector2i(a.lerp(b, float(i) / maxf(n, 1)).round()), col)

# 모래시계(5×7px, p가 가운데): k = 위 칸에 남은 모래 비율
func _hourglass(p: Vector2i, k: float, glass: Color, sand: Color, dark: Color) -> void:
	_px(p + Vector2i(-2, -3), dark, Vector2i(5, 1))
	_px(p + Vector2i(-2, 3), dark, Vector2i(5, 1))
	for q in [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-2, 2), Vector2i(2, 2)]:
		_px(p + q, glass)
	var up := [Vector2i(0, -1), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2)]
	var down := [Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 1)]
	var n := int(round(4.0 * clampf(k, 0.0, 1.0)))
	for i in n:
		_px(p + up[i], sand)
	for i in 4 - n:
		_px(p + down[i], sand)
	_px(p, sand if k > 0.0 and k < 1.0 else glass)

# 태엽 열쇠(p = 축 아래 끝): f 0이면 손잡이가 정면(7×3px), 1이면 옆(3×3px). 탑 지붕·주황 테두리 위에서도 보이게 어두운 1px 테두리를 두른다(fx-7 Gemini 고칠 점 3)
func _wind_key(p: Vector2i, f: int) -> void:
	var w := 7 if f == 0 else 3
	_px(p + Vector2i(-w / 2 - 1, -6), PX.night, Vector2i(w + 2, 5))
	_px(p + Vector2i(-1, -2), PX.night, Vector2i(3, 3))
	_px(p + Vector2i(0, -2), PX.bronze, Vector2i(1, 2))
	_px(p + Vector2i(-w / 2, -5), PX.soot, Vector2i(w, 3))
	if f == 1:
		_px(p + Vector2i(0, -5), PX.gold, Vector2i(1, 3))
		return
	for q in [Vector2i(-2, -5), Vector2i(-1, -5), Vector2i(1, -5), Vector2i(2, -5), Vector2i(-3, -4), Vector2i(0, -4), Vector2i(3, -4), Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(1, -3), Vector2i(2, -3)]:
		_px(p + q, PX.gold)

# 크로노스 표시(I199 2026-11-04 변경): 문에 든 적 머리 위 남은 시간 고리(어두운 원판 위 얼음 호가 12시에서 반시계로 줄어든다, 마지막 GATE_BLINK초는 깜박),
# 태엽 감기 둘레 안 아군 영웅·쏘는 구조물의 태엽 열쇠. _marks 다음(몸통 위)에 그린다. 숨은 적(S213)에는 그리지 않는다
func _chrono_marks() -> void:
	for l in battle.loops:
		if l.e in _foes and not (l.left < GATE_BLINK and fmod(l.left, 0.2) < 0.1):
			var p := _crown(l.e)
			_pdisc(p, 3, PX.night)
			_parc(p, 3, 1, -PI / 2.0 - TAU * clampf(l.left / l.owner.e.delay, 0.0, 1.0), -PI / 2.0, PX.ice0)
			_px(p, PX.ice0)
	var f := int(clock / KEY_FLIP) % 2
	for h in battle.heroes:
		if h.alive and h.fx.has("chronos_r"):
			_wind_key(Vector2i((_spot(h) + _slip(h)).floor()) + Vector2i(6, -int(_head(h) * 0.6)), f)
	for s in battle.structures.values():
		if s.fx.has("chronos_r"):
			_wind_key(Vector2i(_muzzle(s).floor()) + Vector2i(7, 3), f)

# 장판(I101, S168, 4.1s): 처음 본 때부터 ZONE_OPEN초에 펼쳐지고 마지막 ZONE_CLOSE초에 줄어든다. 판정 경계는 밝은 1px + 바깥 어두운 1px이고,
# 같은 종류 장판끼리 겹친 곳은 빼서 바깥 테두리만 남는다. 장판은 모두 무늬 대신 재질이다(이그니스 4.1s, 실비아 fx-2, 세라피나·베스퍼 fx-3, 크로노스 fx-4, S168).
# 떨어지는 중인 운석은 _fall, 아직 안 떨어진 운석 자리는 _meteor_tell, 절대 방어선 둘레는 _capsule, 바람의 길(실비아 R)은 _path_zone이 그린다
func _zones() -> void:
	_zone_t0 = _zone_t0.filter(func(e): return battle.zones.any(func(z): return is_same(z, e[0])))
	var caps := false
	for z in battle.zones:
		if z.has("cells"):
			_capsule(z)
			caps = true
			continue
		if z.has("to"):
			if z.src == "sylvia_e":
				_gate_zone(z, _zone_age(z))
			else:
				_path_zone(z, _zone_age(z))
			continue
		if z.get("delay", 0.0) > 0.0:
			if z.src == "ignis_r":
				_meteor_tell(z)
			continue
		var age := _zone_age(z)
		var r := zone_r(z, age)
		if r < 2:
			continue
		var c := Vector2i(_center(z.pos).floor())
		var seed := hash(str(z.pos) + z.src)
		var others := []
		for o in battle.zones:
			if not is_same(o, z) and o.src == z.src and o.get("delay", 0.0) <= 0.0 and not o.has("cells"):
				others.append([_center(o.pos), CELL * o.radius])
		match z.src:
			"ignis_q":
				_fire_zone(c, r, seed, others, _in_lit_hole(z.pos))
			"ignis_e":
				_hole_zone(c, r, age, seed, others, z.has("lit"))  # 불타는 블랙홀(S250, I229 ⑤)
			"ignis_r":
				_lava_zone(c, r, z.left, seed, others)
			"sylvia_w":
				_tail_zone(z, c, r, seed, others)
			"seraphina_w":
				_sanctum_zone(c, r, seed, others)
			"vesper_q":
				_fog_zone(c, r, seed, others)
			"vesper_r":
				_swamp_zone(c, r, seed, others)
			"chronos_e":
				_law_zone(c, r, age, seed, others)
			"chronos_r":
				_warp_zone(c, r, age, seed, others)
			_:  # 재질을 정하지 않은 장판: 판정 경계만
				_edge(c, r, PX.cream, PX.soot, others)
	if not caps:
		_caps.clear()

# 순풍 장판(실비아 W, I215 2026-11-01 변경): 엷은 연두 성긴 칠 위로, 실비아에서 장판 쪽으로 흐르는 바람 줄 12개(길이 10, 머리가 밝다.
# 경계 가까이 30%에서는 어둡게 들고 난다)와 판정 경계
func _tail_zone(z: Dictionary, c: Vector2i, r: int, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.lime3, 1, posmod(seed, 4))
	var dir: Vector2 = (z.pos - z.owner.pos).normalized() if z.pos != z.owner.pos else Vector2.DOWN
	var side := dir.orthogonal()
	for i in 12:
		var u := (_hf(seed, i) * 2.0 - 1.0) * (r - 4)
		var half := sqrt(maxf(float(r * r) - u * u, 0.0)) - 3.0
		if half < 8.0:
			continue
		var s := fposmod(_hf(seed, i + 20) * 2.0 * half + clock * WIND_FLOW * (0.8 + 0.4 * _hf(seed, i + 40)), 2.0 * half) - half
		var tail := minf(10.0, s + half)
		var head := Vector2(c) + side * u + dir * s
		var dim := absf(s) > half * 0.7
		_pline(Vector2i((head - dir * tail).round()), Vector2i((head - dir * 4.0).round()), PX.lime3 if dim else PX.lime2)
		_pline(Vector2i((head - dir * 3.0).round()), Vector2i(head.round()), PX.lime2 if dim else PX.lime0)
	_edge(c, r, PX.lime1, PX.soot, others)

# 바람의 렌즈 관문(실비아 E, S153·I215 2026-11-01 변경): 가운데에서 양 끝으로 ZONE_OPEN초에 펼쳐지고 마지막 ZONE_CLOSE초에 줄어든다.
# 양옆 판정 경계(관문 선에서 폭의 절반, 순풍보다 밝은 1px + 바깥 어두운 1px), 그 사이를 따라 흐르는 연두 막(엷은 칠 + 흐르는 토막),
# 실비아 → 지점 쪽(face)을 가리키며 차례로 밝아지는 꺾쇠 셋, 양 끝의 바람 기둥
func _gate_zone(z: Dictionary, age: float) -> void:
	var a := _center(z.pos)
	var b := _center(z.to)
	var along := (b - a).normalized()
	var face := -along.orthogonal()  # 렌즈를 깔 때 관문 방향은 (실비아 → 지점).orthogonal()이라 그 반대 회전이 실비아 → 지점이다(battle.lens_gate)
	var mid := (a + b) / 2.0
	var half_len := a.distance_to(b) / 2.0 * _pow3(age / ZONE_OPEN) * clampf(z.left / ZONE_CLOSE, 0.0, 1.0)
	if half_len < 1.0:
		return
	var w := maxf(CELL * z.radius, 2.0)
	var p0 := mid - along * half_len
	var p1 := mid + along * half_len
	var seed := hash(str(z.pos) + z.src)
	for i in int(half_len * w / 4.0):
		_px(Vector2i((mid + along * (_hf(seed, i) * 2.0 - 1.0) * half_len + face * (_hf(seed + 1, i) * 2.0 - 1.0) * w).floor()), PX.lime2)
	for lane in 3:  # 흐르는 막: 관문을 따라 흐르는 밝은 토막
		var u := (lane - 1) * w * 0.5
		var s := fposmod(clock * WIND_FLOW * 1.5 + lane * 7.0, 12.0)
		while s < 2.0 * half_len:
			var q := p0 + along * s + face * u
			_pline(Vector2i(q.round()), Vector2i((q + along * minf(3.0, 2.0 * half_len - s)).round()), PX.lime0 if lane == 1 else PX.lime1)
			s += 12.0
	if half_len >= 8.0:
		for j in 3:  # 꺾쇠: 뒤에서 앞으로 차례로 밝아진다
			var tip := mid + along * (j - 1) * half_len * 0.5 + face * 2.0
			var col: Color = PX.lime0 if fmod(clock * 2.0 + j / 3.0, 1.0) < 0.5 else PX.lime2
			for sgn: float in [-1.0, 1.0]:
				_pline(Vector2i((tip - face * 3.0 + along * 3.0 * sgn).round()), Vector2i(tip.round()), col)
	for sgn: float in [-1.0, 1.0]:
		_pline(Vector2i((p0 + face * (w + 1.0) * sgn).round()), Vector2i((p1 + face * (w + 1.0) * sgn).round()), PX.soot)
		_pline(Vector2i((p0 + face * w * sgn).round()), Vector2i((p1 + face * w * sgn).round()), PX.lime0)
	for p in [p0, p1]:  # 바람 기둥: 어두운 테 안의 연두 기둥, 머리가 깜박인다
		var q := Vector2i(p.round())
		_px(q - Vector2i(2, 7), PX.soot, Vector2i(5, 9))
		_px(q - Vector2i(1, 6), PX.lime2, Vector2i(3, 7))
		_px(q - Vector2i(0, 6), PX.lime1, Vector2i(1, 6))
		_px(q - Vector2i(0, 6), PX.lime0 if fmod(clock, 0.8) < 0.5 else PX.cream)

# 바람의 길(실비아 R, I215 2026-11-01 변경): 길 선분을 따라 엷은 연두 성긴 칠, 표적 쪽으로 감겨 흐르는 두 가닥 나선(WIND_WAVE마다 한 바퀴,
# 앞 가닥 밝음·뒤 가닥 어두움), 양옆 판정 경계(밝은 1px + 바깥 어두운 1px). 폭은 원 장판처럼 펼쳐지고 줄어든다
func _path_zone(z: Dictionary, age: float) -> void:
	var a := _center(z.pos)
	var b := _center(z.to)
	var half: float = CELL * z.radius * _pow3(age / ZONE_OPEN) * clampf(z.left / ZONE_CLOSE, 0.0, 1.0)
	var length := a.distance_to(b)
	if half < 1.0 or length < 1.0:
		return
	var dir := (b - a) / length
	var side := dir.orthogonal()
	var seed := hash(str(z.pos) + z.src)
	for i in int(length * half / 12.0):
		_px(Vector2i((a + dir * _hf(seed, i) * length + side * (_hf(seed + 1, i) * 2.0 - 1.0) * half).floor()), PX.lime3)
	var amp := maxf(half - 2.0, 0.0)
	for strand in 2:
		var prev := a + side * sin(-clock * WIND_RUSH / WIND_WAVE * TAU + strand * PI) * amp
		var s := 3.0
		while s < length + 3.0:
			var ph := (minf(s, length) - clock * WIND_RUSH) / WIND_WAVE * TAU + strand * PI
			var q := a + dir * minf(s, length) + side * sin(ph) * amp
			_pline(Vector2i(prev.round()), Vector2i(q.round()), PX.lime1 if cos(ph) > 0.0 else PX.lime3)
			prev = q
			s += 3.0
	for sgn in [-1.0, 1.0]:
		_pline(Vector2i((a + side * (half + 1.0) * sgn).round()), Vector2i((b + side * (half + 1.0) * sgn).round()), PX.soot)
		_pline(Vector2i((a + side * half * sgn).round()), Vector2i((b + side * half * sgn).round()), PX.lime1)

# 그릴 장판 반지름(아트 px): 처음 본 뒤 age초 동안 ZONE_OPEN초에 걸쳐 빠르게 펼쳐지고, 남은 시간이 ZONE_CLOSE초 밑이면 줄어든다
static func zone_r(z, age: float) -> int:
	return int(CELL * z.radius * _pow3(age / ZONE_OPEN) * clampf(z.left / ZONE_CLOSE, 0.0, 1.0))

func _zone_age(z) -> float:
	for e in _zone_t0:
		if is_same(e[0], z):
			return clock - e[1]
	_zone_t0.append([z, clock])
	return 0.0

# 불길(이그니스 Q, I229 ③): 판정 경계 안쪽 3px 고리를 따라 WALL_GAP px마다 선 불꽃 줄(셋에 하나는 큰 불꽃) + 가운데 깜박이는 빨강·그을음 칠 1/16 +
# 떠오르는 불티 넷. bare(불타는 블랙홀 안)면 가운데 칠과 불티를 뺀다(블랙홀 칠과 섞여 탁해진다, 시안 fx-11)
func _fire_zone(c: Vector2i, r: int, seed: int, others: Array, bare := false) -> void:
	if not bare:
		_pnoise(c, r - 3, PX.red, 1, posmod(seed + int(clock * 5.0), 4))
		_pnoise(c, r - 3, PX.soot, 1, posmod(seed + 2, 4))
	var n := maxi(int(TAU * (r - 3) / WALL_GAP), 6)
	for i in n:
		var p := c + Vector2i((Vector2.from_angle(TAU * i / n + _hf(seed, i) * 0.2) * (r - 3)).round())
		_spr("flame" if i % 3 == 0 else "flame_s", int(clock * 10.0) + i, p + Vector2i(0, 2), true)
	if not bare:
		for i in 4:
			var ph := fmod(clock + _hf(seed, i + 90) * 0.7, 0.7) / 0.7
			var p := c + Vector2i(Vector2.from_angle(_hf(seed, i + 70) * TAU) * _hf(seed, i + 80) * (r - 6)) + Vector2i(0, -int(10.0 * ph))
			_px(p, _ramp(EMBER, ph))
	_edge(c, r, PX.orange, PX.soot, others)

# p가 불타는 블랙홀(S250) 안인가
func _in_lit_hole(p: Vector2) -> bool:
	return battle.zones.any(func(o): return o.src == "ignis_e" and o.has("lit") and o.get("delay", 0.0) <= 0.0 and p.distance_to(o.pos) <= o.radius)

# 블랙홀(이그니스 E, I229 ⑤): 바깥 엷은 보라 칠 2/16 + 가장자리에서 검은 심까지 감겨 드는 줄 STREAKS개(바깥 어두운 보라 → 안 밝음) +
# 검은 심(반경 × HOLE_CORE)과 그 둘레를 도는 밝은 보라 점선 테·안쪽 보라 테. lit(불타는 블랙홀, S250)이면 줄이 핏빛 → 금, 테가 크림·금이고
# 불꽃 SUCK_FLAMES개가 줄을 따라 빨려 들며 경계가 빨강이다
func _hole_zone(c: Vector2i, r: int, age: float, seed: int, others: Array, lit := false) -> void:
	_pnoise(c, r, PX.vio4, 2, posmod(seed, 4))
	var cols := ["blood", "red", "orange", "gold"] if lit else ["vio3", "vio2", "vio1", "vio0"]
	var core := int(r * HOLE_CORE)
	for arm in STREAKS:
		var prev := c + _streak(arm, 0.0, r, core, age)
		for j in range(1, STREAK_STEPS + 1):
			var s := float(j) / STREAK_STEPS
			var q := c + _streak(arm, s, r, core, age)
			_pline(prev, q, _ramp(cols, s))
			prev = q
	_pdisc(c, core, PX.night)
	_pring(c, core + 1, 1, PX.cream if lit else PX.vio0, 3, age * 4.0)
	_pring(c, core, 1, PX.gold if lit else PX.vio2)
	if lit:
		for i in SUCK_FLAMES:
			var ph := fmod(age * 0.7 + float(i) / SUCK_FLAMES, 1.0)
			_spr("flame_s" if ph > 0.5 else "flame", int(clock * 10.0) + i, c + _streak(i, ph, r, core, age, SUCK_FLAMES), true)
	_edge(c, r, PX.red if lit else PX.vio2, PX.soot if lit else PX.night, others)

# 감겨 드는 줄(n개 가운데 arm번째)의 s 자리(0 = 가장자리 안쪽 2px, 1 = 심). 시계 방향으로 감기며 돈다
func _streak(arm: int, s: float, r: int, core: int, age: float, n := STREAKS) -> Vector2i:
	return Vector2i((Vector2.from_angle(arm * TAU / n + s * 2.6 + age * 2.6) * (core + (r - 2 - core) * (1.0 - s))).round())

# 용암(이그니스 R): 굳은 껍질과 가지 친 균열 자국 + 솟았다 터지는 거품. 마지막 0.8초는 식어 어두워진다
func _lava_zone(c: Vector2i, r: int, left: float, seed: int, others: Array) -> void:
	if left < 0.8:
		_pnoise(c, r - 2, PX.soot, int(4.0 + 6.0 * left / 0.8), posmod(seed, 4))
	else:
		_spr("lava", seed, c)
		for i in 3:
			var ph := fmod(clock + _hf(seed, i + 40) * 0.6, 0.6) / 0.6
			_spr("pop", int(ph * 3.0), c + Vector2i(Vector2.from_angle(_hf(seed, i + 41) * TAU) * _hf(seed, i + 42) * r * 0.6))
	_edge(c, r, PX.red if left >= 0.8 else PX.blood, PX.soot, others)

# 성역(세라피나 W, fx-3): 엷은 모래빛 칠 + 바닥 문양(안쪽 금 점선 고리, 네 방위의 짧은 금 획, 가운데 성휘 조각) + 떠오르는 빛 점.
# 같은 금빛인 시간의 문(크로노스 E)과는 이 바닥 문양으로 갈린다
func _sanctum_zone(c: Vector2i, r: int, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.tan, 2, posmod(seed, 4))
	_pring(c, int(r * 0.65), 1, PX.gold, 2)
	for i in 4:
		var d := Vector2.from_angle(i * PI / 2.0)
		_pline(c + Vector2i((d * r * 0.72).round()), c + Vector2i((d * r * 0.88).round()), PX.gold)
	_spr("glyph", 1 if fmod(clock + _hf(seed, 1) * 1.5, 1.5) < 0.15 else 0, c)
	for i in MOTES:
		var ph := fmod(clock * 0.7 + _hf(seed, i), 1.0)
		_px(c + Vector2i((Vector2.from_angle(_hf(seed, i + 10) * TAU) * _hf(seed, i + 20) * r * 0.8).round()) - Vector2i(0, int(10.0 * ph)), PX.cream if ph < 0.5 else PX.gold)
	_edge(c, r, PX.cream, PX.soot, others)

# 독안개(베스퍼 Q, fx-3): 청록 성긴 칠 + 바닥에 낮게 일렁이는 안개 조각 + 바닥에서 부풀어 오르다 터지는 거품. 실비아 장판(연두)과는 색으로 갈린다
func _fog_zone(c: Vector2i, r: int, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.midteal, 4, posmod(seed, 4))
	for i in FOGS:
		var o := Vector2.from_angle(_hf(seed, i + 10) * TAU) * sqrt(_hf(seed, i + 20)) * (r - 6) + Vector2(3.0 * sin(clock * 0.8 + i * 1.7), 0.0)
		_spr("fog", int(clock * 2.0) + i, c + Vector2i(o.round()))
	for i in FIZZ:
		var u := clock + _hf(seed, i + 30) * FIZZ_CYCLE
		var n := int(u / FIZZ_CYCLE)
		var p := c + Vector2i((Vector2.from_angle(_hf(seed + n, i + 40) * TAU) * sqrt(_hf(seed + n, i + 50)) * (r - 3)).round())
		_spr("fizz", int(fmod(u, FIZZ_CYCLE) / FIZZ_CYCLE * 4.0), p, true)
	_edge(c, r, PX.teal, PX.soot, others)

# 늪(베스퍼 R, I226 ⑥): 짙은 진흙 성긴 칠(어둠 7/16, 0.75배 안 그을음 7/16) + 0.55배 안 깊은 청록 물(8/16)과 0.4배 안 짙은 청록(3/16) +
# 가운데서 반경의 0.85배까지 BOG_WAVE_T초 주기로 엇갈려 퍼지는 1px 물결 고리 BOG_WAVES개(BOG_DASH px마다 끊긴 점선). 보라를 쓰지 않아 블랙홀(이그니스 E)과 갈린다
func _swamp_zone(c: Vector2i, r: int, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.dark, 7, posmod(seed, 4))
	_pnoise(c, int(r * 0.75), PX.soot, 7, posmod(seed + 1, 4))
	_pnoise(c, int(r * 0.55), PX.deepteal, 8, posmod(seed + 2, 4))
	_pnoise(c, int(r * 0.4), PX.midteal, 3, posmod(seed + 3, 4))
	for i in BOG_WAVES:
		var ph := fmod(clock / BOG_WAVE_T + float(i) / BOG_WAVES, 1.0)
		_pring(c, int(r * (0.15 + 0.7 * ph)), 1, PX.teal if ph < 0.4 else PX.midteal, BOG_DASH)
	_edge(c, r, PX.teal, PX.soot, others)

# 늪에 든 적(I226 ⑥): 발이 진흙에 잠긴다. 발 −2~+1px를 덮는 진흙 띠(그을음·어둠, 폭 11~13px)와 띠에서 오르다 터지는 거품 하나(초당 1.3번).
# 몸통 위 층이라 _draw가 _marks 다음에 부른다
func _mire_marks() -> void:
	for e in _foes:
		if not e.fx.has("vesper_r"):
			continue
		var f := Vector2i((_spot(e) + _slip(e)).floor())
		var n: int = e.get_instance_id()
		_px(f + Vector2i(-5, -2), PX.soot, Vector2i(11, 1))
		_px(f + Vector2i(-6, -1), PX.dark, Vector2i(13, 2))
		_px(f + Vector2i(-4, 1), PX.dark, Vector2i(9, 1))
		var ph := fmod(clock * 1.3 + _hf(n, 3), 1.0)
		var bx := int(_hf(n, 4) * 8.0) - 4
		if ph < 0.7:
			_px(f + Vector2i(bx, -2 - int(3.0 * ph / 0.7)), PX.midteal)
		else:
			_px(f + Vector2i(bx - 1, -5), PX.teal)
			_px(f + Vector2i(bx + 1, -5), PX.teal)

# 이그니스(I229 ①②): 빙결한 적의 얼음 판과 과부하 영웅 발밑 세 점. 몸통 위 층이라 _draw가 _marks 다음에 부른다
func _ignis_marks() -> void:
	for e in _foes:
		if e.fx.has("ignis_w_freeze"):
			_ice_plate(e)
	for u in battle.units:
		if u.is_hero and u.alive and u.passive.get("id") == "overload":
			_overload_pips(u)

# 불붙은 구조물(I249 ⑦): 칸 아래쪽에 이그니스 불길과 같은 불꽃 조각 셋(가운데는 큰 불꽃)과, 쏘는 곳 높이까지 떠오르며 식는 불티 넷. 몸통 위 층이다
func _burning() -> void:
	for s in battle.structures.values():
		if not s.fx.has("flame"):
			continue
		var c := Vector2i(_spot(s).floor())
		var rise := 4 - int(MUZZLE.get(s.kind, Vector2(0, -10)).y)
		var seed: int = s.get_instance_id()
		for i in 3:
			_spr("flame" if i == 1 else "flame_s", int(clock * 10.0) + i, c + Vector2i(5 * i - 5, 6 if i != 1 else 3), true)
		for i in 4:
			var ph := fmod(clock + _hf(seed, i) * 0.7, 0.7) / 0.7
			_px(c + Vector2i(int(_hf(seed, i + 10) * 10.0) - 5, 2 - int(rise * ph)), _ramp(EMBER, ph))

# 기절이 서리 고리 빙결 하나뿐인가(그때는 머리 위 별을 그리지 않는다, I229 ①)
func _ice_only(x) -> bool:
	if not x.fx.has("ignis_w_freeze"):
		return false
	for src in x.fx:
		if src != "ignis_w_freeze" and x.fx[src].get("stun", false):
			return false
	return true

# 빙결한 적: 몸 아래 4/5(폭 12)를 덮는 엷은 얼음 판과 비낀 빛 줄, 얼음 테(왼쪽·위 밝음, 오른쪽 어두움, 아래 남빛). 그 적을 맞힌 서리 고리 뒤 ICE_FLASH초는 테가 크림
func _ice_plate(e) -> void:
	var o := Vector2i((_spot(e) + _slip(e)).floor())
	var h := int(_head(e) * 0.8)
	o -= Vector2i(6, h - 1)
	var flash: bool = battle.traces.any(func(c): return c.age < ICE_FLASH and e in c.hits and _skill(c) == "frost_ring")
	var hi: Color = PX.cream if flash else PX.ice0
	_px(o, Color(PX.ice0, 0.4), Vector2i(12, h))
	_pline(o + Vector2i(2, h - 3), o + Vector2i(6, 1), Color(PX.cream, 0.6))
	_px(o - Vector2i(1, 1), hi, Vector2i(13, 1))
	_px(o - Vector2i(1, 0), hi, Vector2i(1, h))
	_px(o + Vector2i(12, 0), PX.ice2, Vector2i(1, h))
	_px(o + Vector2i(0, h), PX.ice3, Vector2i(13, 1))

# 과부하 영웅: 발밑 팀 타원 아래 점 every개(3×3, 검은 테)가 쓴 스킬 수를 센다(금 = 쓴 것). 차례면 모두 금으로 깜박이고(0.5초에 0.35초) 발 둘레에 주황 고리
func _overload_pips(h) -> void:
	var f := Vector2i((_spot(h) + _slip(h)).floor())
	var every := int(h.passive.every)
	var n: int = every if h.charged else h.casts % every
	var dim: bool = h.charged and fmod(clock, 0.5) >= 0.35
	if h.charged:
		_pring(f - Vector2i(0, 1), OVERLOAD_RING, 1, PX.orange)
	for i in every:
		var p := f + Vector2i(-(5 * every - 2) / 2 + 5 * i, 5)
		_px(p - Vector2i(1, 1), PX.soot, Vector2i(5, 5))
		_px(p, PX.gold if i < n and not dim else PX.dark, Vector2i(3, 3))

# 시간의 문(크로노스 E 타임 루프, I199 2026-11-04 변경): 되감기. 얼음 성긴 칠(2/16) + 12·3·6·9시 눈금 + 12시에서 반시계로 도는 짧은 바늘(얼음 2px)·긴 바늘(크림 1px) +
# 가운데 어두운 축 + 얼음 테두리
func _law_zone(c: Vector2i, r: int, age: float, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.ice3, 2, posmod(seed, 4))
	for i in 4:
		var d := Vector2.from_angle(i * PI / 2.0)
		_pline(c + Vector2i((d * (r - 1)).round()), c + Vector2i((d * (r - 4)).round()), PX.ice1)
	var turn := -TAU * age / HAND_TURN  # 12시(-PI/2)에서 잰 긴 바늘 각. 화면 y가 아래라 각이 줄면 반시계 방향
	_pline(c, c + Vector2i((Vector2.from_angle(turn / HAND_RATIO - PI / 2.0) * r * 0.5).round()), PX.ice1, 2)
	_pline(c, c + Vector2i((Vector2.from_angle(turn - PI / 2.0) * r * 0.8).round()), PX.cream)
	_px(c - Vector2i(1, 1), PX.night, Vector2i(3, 3))
	_px(c, PX.cream)
	_edge(c, r, PX.ice0, PX.night, others)

# 태엽 감기 둘레(크로노스 R, I199 2026-11-04 변경): 놋쇠 태엽. 구리 성긴 칠(1/16) + 금 테두리 + 바깥 톱니 COGS개(금 2×2px + 그을음 그림자 3×3px)가
# 시계 방향으로 COG_SPIN rad/s 돌고, 쓴 순간부터 WIND_KICK_T초 동안 WIND_KICK rad를 더 돈다
func _warp_zone(c: Vector2i, r: int, age: float, seed: int, others: Array) -> void:
	_pnoise(c, r - 1, PX.bronze, 1, posmod(seed, 4))
	_edge(c, r, PX.gold, PX.soot, others)
	var rot := clock * COG_SPIN + WIND_KICK * _pow3(age / WIND_KICK_T)
	for i in COGS:
		var p := c + Vector2i((Vector2.from_angle(TAU * i / COGS + rot) * (r + 2.5)).round())
		_px(p - Vector2i(1, 1), PX.soot, Vector2i(3, 3))
		_px(p - Vector2i(1, 1), PX.gold, Vector2i(2, 2))

# 걸린 효과(I101 2026-10-27 변경): 효과마다 수단 하나로, 고리를 겹쳐 쌓지 않는다.
# 1차(기절·도발·봉인·속박·불사)는 머리 위 기호나 몸에 감긴 밧줄, 2차(받는 피해 증가·초당 피해·받는 피해 감소·공격 속도·보호막)는 몸·발의 작은 조각이다.
# 적의 둔화·공격력·방어력·마법 저항 감소는 능력치 감소 줄(_debuff_row)이다.
# 사슬은 적끼리 잇는 쇠사슬(_traces, I226 ②)이, 늪에 든 적은 잠긴 발(_mire_marks)이 보인다. 돌려주는 것: {k 조각 이름 또는 "px"·"ring", p 아트 px 자리, f 프레임, c 색, r 반지름}
func status_marks(x, ally: bool) -> Array:
	var feet := Vector2i((_spot(x) + _slip(x)).floor())
	var tall := _head(x)
	var head := feet - Vector2i(0, int(tall))
	var n: int = x.get_instance_id()
	var out := []
	var icons := []
	for key in ALLY_FX if ally else FOE_FX:
		var on: bool
		if ally:
			on = (not x.shields.is_empty()) if key == "shield" else (battle.effect(x, key) != null if key in ["invuln", "stun"] else battle.effect_sum(x, key) > 0.0)
		else:
			on = battle.effect(x, key) != null
		if not on:
			continue
		match key:
			"stun":  # 머리 위를 도는 별 둘. 서리 고리 빙결만으로 기절한 적은 별 대신 얼음 판이다(_ignis_marks, I229 ①)
				if not ally and _ice_only(x):
					continue
				for i in 2:
					var a := clock * 5.0 + i * PI + _hf(n, 1) * TAU
					out.append({k = "star", p = head + Vector2i(int(cos(a) * 5.0), -3 + int(sin(a) * 2.0)), f = int(clock * 8.0) + i})
			"taunt", "seal":
				icons.append(key)
			"root":  # 몸 아래쪽에 감긴 밧줄 띠(fx-5 판정: 발밑 고리는 팀 타원에 묻혔다)
				out.append({k = "bind", p = feet - Vector2i(0, 5), f = 0})
			"expose":  # 몸 옆 금 간 방패, 1초에 0.7초 보임
				if fmod(clock + _hf(n, 2), 1.0) < 0.7:
					out.append({k = "expose", p = feet + Vector2i(7, -int(tall * 0.55)), f = 0})
			"dot":  # 발화(이그니스)는 작은 불꽃과 불티, 그 밖(독)은 머리 높이에서 몸 가운데까지 떨어지는 방울 둘(fx-5 판정: 독안개에 묻혔다)
				var burn: bool = x.fx.has("ignis_q")
				if burn:
					out.append({k = "flame_s", p = feet + Vector2i(posmod(n, 5) - 2, -4), f = int(clock * 10.0) + n})
				for i in (4 if burn else 2):
					var ph := fmod(clock + _hf(n, i + 3) * 0.5, 0.5) / 0.5
					var dx := int(_hf(n, i + 9) * 10.0) - 5
					if burn:
						out.append({k = "px", p = feet + Vector2i(dx, -4 - int(14.0 * ph)), c = _ramp(EMBER, ph)})
					else:
						out.append({k = "venom", p = feet + Vector2i(dx, -int(tall * (1.0 - 0.5 * ph))), f = 0})
			"dr":  # 몸 양옆 작은 방패가 오르내린다. 아이아스 자기 것(요새화·태세)은 이 방패를 빼고, 태세는 몸 앞 방패로 그린다(I228 ②·⑤)
				if x.kind == "aias":
					out.append_array(_brace_marks(x))
					var other := 0.0
					for src in x.fx:
						if src != "aias_p" and src != "aias_e":
							other += x.fx[src].get("dr", 0.0)
					if other <= 0.0:
						continue
				var bob := int(round(sin(clock * 3.0 + _hf(n, 4) * TAU)))
				for sx in [-7, 7]:
					out.append({k = "guard", p = feet + Vector2i(sx, -int(tall * 0.5) + bob), f = 0})
			"haste":  # 발에서 오르는 작은 사각형. 실비아 순풍에서 온 공격 속도는 발 둘레를 도는 바람 줄 조각이다(I215 2026-11-01 변경)
				var wind: float = x.fx.sylvia_w.get("haste", 0.0) if x.fx.has("sylvia_w") else 0.0
				if wind > 0.0:
					out.append({k = "gust", p = feet + Vector2i(0, 1), f = int(clock * 12.0)})
					if battle.effect_sum(x, "haste") <= wind:
						continue
				for i in 3:
					var ph := fmod(clock * 1.5 + i / 3.0 + _hf(n, 5), 1.0)
					out.append({k = "px", p = feet + Vector2i(-4 + i * 4, -int(10.0 * ph)), c = PX.gold if ph < 0.5 else PX.orange})
			"shield":  # 몸 둘레 테 하나. 세라피나 빛의 보호막은 같은 자리 금 점선 테이고, 다른 보호막도 있을 때만 얼음 테를 함께 그린다(I227 ⑤). 전장의 포효 보호막만 있으면 머리 위 지붕 호 셋(바깥 밝은 보라 · 보라 · 안쪽 어두운 보라, I228 ④)
				var c := feet - Vector2i(0, int(tall * 0.45))
				var r := int(tall * 0.55)
				if x.shields.size() == 1 and x.shields.has("aias_w"):
					out.append({k = "arc", p = c, r = r + 1, th = 1, a0 = -PI * 0.8, a1 = -PI * 0.2, c = PX.vio0})
					out.append({k = "arc", p = c, r = r, th = 1, a0 = -PI * 0.85, a1 = -PI * 0.15, c = PX.vio1})
					out.append({k = "arc", p = c, r = r - 1, th = 1, a0 = -PI * 0.8, a1 = -PI * 0.2, c = PX.vio3})
				else:
					var sera: bool = x.shields.has("seraphina")
					if sera:
						out.append({k = "ring", p = c, r = int(tall * 0.6), c = PX.gold, dash = 2})
					if x.shields.size() > (1 if sera else 0):
						out.append({k = "ring", p = c, r = int(tall * 0.6), c = PX.ice0})
			"bleed":  # 출혈(I193 ③): 몸에서 떨어지는 핏방울
				for i in 3:
					var ph := fmod(clock + _hf(n, i + 7) * 0.6, 0.6) / 0.6
					out.append({k = "px", p = feet + Vector2i(int(_hf(n, i + 11) * 8.0) - 4, -int(tall * 0.5) + int(8.0 * ph)), c = PX.blood if ph < 0.6 else PX.maroon})
			"lag":  # 노래(I252 ④): 머리 오른쪽 위에서 오르내리는 음표 하나(대 4px, 깃발 2px, 머리 3px)
				var at := head + Vector2i(5, int(round(sin(clock * 4.0 + _hf(n, 8) * TAU))))
				for d in [Vector2i(0, -4), Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i(1, -4), Vector2i(1, -3), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
					out.append({k = "px", p = at + d, c = NOTE})
			"invuln":  # 금 테가 맥동하고 별 하나가 돈다
				var a := clock * 3.0 + _hf(n, 6) * TAU
				out.append({k = "ring", p = feet - Vector2i(0, int(tall * 0.45)), r = int(tall * 0.6) + 1, c = PX.gold if fmod(clock * 2.0, 1.0) < 0.5 else PX.cream})
				out.append({k = "star", p = feet + Vector2i(int(cos(a) * tall * 0.6), -int(tall * 0.45) + int(sin(a) * tall * 0.3)), f = 0})
	for i in icons.size():  # 머리 위 기호는 별(기절) 위로 한 줄에
		out.append({k = icons[i], p = head + Vector2i(int((i - (icons.size() - 1) / 2.0) * 8.0), -9), f = 0})
	if not ally:
		out.append_array(_debuff_row(x))
	return out

# 적 능력치 감소 줄(I101 2026-11-04 변경): 걸린 것만 DEBUFFS 차례로 5×4px 아래 화살표를 이웃과 테두리 1px 겹쳐(4px 간격) 가운데 맞춘다.
# 자리는 체력바가 보이면 막대 바로 아래(보스·성벽 위는 머리 위 막대 바로 위), 안 보이면 발밑 팀 타원(발 −2~+3px) 바로 아래다
func _debuff_row(x) -> Array:
	var on := []
	for i in DEBUFFS.size():
		var key: String = DEBUFFS[i]
		var sum: float = battle.effect_sum(x, key)
		if (battle.effect(x, key) != null) if key == "slow" else (sum > 0.0 if key == "weaken" else sum < 0.0):
			on.append(i)
	if on.is_empty():
		return []
	var size := hp_bar_size(x, controls != null and controls.show_hp)
	var cx: int
	var top: int
	if size != Vector2.ZERO:
		var bar := hp_bar_rect(x, size)
		cx = int(bar.position.x + bar.size.x / 2)
		top = int(bar.position.y) - 5 if x.get("boss") or x.on_wall else int(bar.end.y) + 1
	else:
		var ft := _foot(x)
		cx = int(ft.x)
		top = int(ft.y) + 4
	var left := cx - 2 * on.size()  # 줄 폭 4n + 1의 절반
	var out := []
	for j in on.size():
		out.append({k = "down", p = Vector2i(left + 4 * j + 2, top + 2), f = on[j]})  # p는 조각 가운데(_spr)
	return out

func _status(x, ally: bool) -> void:
	for m in status_marks(x, ally):
		match m.k:
			"px":
				draw_rect(Rect2(Vector2(m.p), Vector2.ONE), m.c)
			"ring":
				_pring(m.p, m.r, 1, m.c, m.get("dash", 0))
			"arc":
				_parc(m.p, m.r, m.th, m.a0, m.a1, m.c)
			_:
				_spr(m.k, m.f, m.p, m.k == "flame_s")

# 반격의 태세가 걸린 동안(I228 ⑤): 쓸 때의 방패 조각(흔적, FX초) 뒤부터 몸 앞에 방패 조각의 테두리 프레임과 그 둘레 테.
# 테는 태세 동안 받은 피해가 최대 체력의 BRACE_FULL배에 가까울수록 반지름 8 → 11, 어두운 보라 → 크림이다.
# 막은 뒤 BLOCK_FLASH초는 방패 조각이 흰 번쩍(첫 프레임)이고, 남은 시간 0.5초부터 0.2초에 0.12초만 보인다
func _brace_marks(h) -> Array:
	if h.brace <= 0.0 or h.e.time - h.brace < FX or (h.brace < 0.5 and fmod(clock, 0.2) >= 0.12):
		return []
	var at := Vector2i((_spot(h) + _slip(h) - Vector2(0, _head(h) * 0.5)).floor())  # 쓸 때의 방패 조각(_traces "brace")과 같은 자리
	var k := clampf(h.braced / (BRACE_FULL * h.max_hp), 0.0, 1.0)
	var hit: bool = battle.traces.any(func(c): return c.slot == "block" and c.hero == h and c.age < BLOCK_FLASH)
	return [{k = "ring", p = at, r = 8 + int(round(3.0 * k)), c = _ramp(["vio2", "vio1", "vio0", "cream"], k)}, {k = "aegis", p = at, f = 0 if hit else 2}]

# 몸의 높이(px): 발밑에서 머리까지. 그림이 있으면 시트의 발밑 기준점, 없으면 반지름으로
func _head(x) -> float:
	var a = ART.get(x.kind)
	return float(a.anchor[1]) if a else CELL * x.radius * 2.0 + 6.0

# ── 아트 px 그리기(4.1s): 맵을 창 해상도로 그려도(S30) 원·선이 도트 그림과 같은 격자에 찍힌다. 그리는 곳은 _cv다(덮개 위 층의 조준 미리보기, fx-4) ──

static func _hf(n: int, k: int) -> float:
	return _h(n, k, 0, 9999) / 9999.0

static func _pow3(k: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)

static func _ramp(names: Array, k: float) -> Color:
	return PX[names[clampi(int(k * names.size()), 0, names.size() - 1)]]

# 가운데가 칸 모서리 c인 아트 px 칸: 고리(반지름 r, 안쪽으로 굵기 th)나 원판(th = 0)
static func px_cells(r: int, th: int) -> Array:
	var key := Vector3i(r, th, 0)
	if not _cells.has(key):
		var out := []
		for y in range(-r - 1, r + 1):
			for x in range(-r - 1, r + 1):
				var d := Vector2(x + 0.5, y + 0.5).length()
				if d <= r + 0.5 and (th == 0 or d > r + 0.5 - th):
					out.append(Vector2i(x, y))
		_cells[key] = out
		var runs := []
		for o in out:  # 칸이 y·x 차례라 줄마다 이어 붙인다
			if not runs.is_empty() and runs[-1].position.y == o.y and runs[-1].end.x == o.x:
				runs[-1].size.x += 1
			else:
				runs.append(Rect2i(o, Vector2i.ONE))
		_runs[key] = runs
	return _cells[key]

func _pring(c: Vector2i, r: int, th: int, col: Color, dash := 0, spin := 0.0) -> void:
	if r < 1 or th < 1:
		return
	col.a *= _fade
	if dash == 0:
		px_cells(r, th)
		for run in _runs[Vector3i(r, th, 0)]:
			_cv.draw_rect(Rect2(Vector2(c + run.position), Vector2(run.size)), col)
		return
	for o in px_cells(r, th):  # 둘레를 dash px 길이로 끊어 하나 걸러. 끊는 자리를 spin(라디안)만큼 시계 방향으로 돌린다(왜곡장, fx-4)
		if int(floor(fposmod(atan2(o.y + 0.5, o.x + 0.5) + PI - spin, TAU) * r / dash)) % 2 == 0:
			_cv.draw_rect(Rect2(Vector2(c + o), Vector2.ONE), col)

# 끊긴 고리(I226 ①·④): 둘레를 n 마디로 나눠 마디마다 앞쪽만 그리고, 바깥 1px 검정도 같은 각에서 끊는다(_pring 점선은 반지름마다 끊는 자리가 달라 테두리가 어긋난다).
# seed가 0 이상이면 마디마다 그리는 몫이 0.45~0.8로 들쭉날쭉하다(연기), 아니면 반이다(점선). spin(라디안)만큼 시계 방향으로 돌린다
func _seg_ring(c: Vector2i, r: int, th: int, col: Color, n: int, spin: float, seed := -1) -> void:
	for ring in [[r + 1, 1, PX.night], [r, th, col]]:
		for o in px_cells(ring[0], ring[1]):
			var u := fposmod(atan2(o.y + 0.5, o.x + 0.5) - spin, TAU) / TAU * n
			var i := int(u)
			if u - i < (0.5 if seed < 0 else 0.45 + 0.35 * _hf(seed, i)):
				_px(c + o, ring[2])

# 고리에서 각 a0~a1(라디안) 사이 칸만
func _parc(c: Vector2i, r: int, th: int, a0: float, a1: float, col: Color) -> void:
	if r < 1:
		return
	col.a *= _fade
	var mid := (a0 + a1) / 2.0
	var half := (a1 - a0) / 2.0
	for o in px_cells(r, th):
		if absf(angle_difference(mid, atan2(o.y + 0.5, o.x + 0.5))) <= half:
			_cv.draw_rect(Rect2(Vector2(c + o), Vector2.ONE), col)

func _pdisc(c: Vector2i, r: int, col: Color) -> void:
	if r < 0:
		return
	col.a *= _fade
	px_cells(r, 0)
	for run in _runs[Vector3i(r, 0, 0)]:
		_cv.draw_rect(Rect2(Vector2(c + run.position), Vector2(run.size)), col)

# 성긴 칠: 반투명 원판 대신 원 안 칸의 lim/16만 칠한다. 칸마다 그리지 않게 반지름·밀도·변형별 흰 마스크를 구워 색을 곱한다
func _pnoise(c: Vector2i, r: int, col: Color, lim: int, salt := 0) -> void:
	if r < 1:
		return
	var key := Vector3i(r, lim, salt)
	if not _noise.has(key):
		var img := Image.create(2 * r + 2, 2 * r + 2, false, Image.FORMAT_RGBA8)
		for o in px_cells(r, 0):
			if posmod(hash(Vector3i(o.x, o.y, salt)), 16) < lim:
				img.set_pixel(o.x + r + 1, o.y + r + 1, Color.WHITE)
		_noise[key] = ImageTexture.create_from_image(img)
	_cv.draw_texture(_noise[key], Vector2(c - Vector2i(r + 1, r + 1)), Color(col, col.a * _fade))

# 아트 px 선(브레젠험). w > 1이면 w×w 칸으로 찍는다
func _pline(a: Vector2i, b: Vector2i, col: Color, w := 1) -> void:
	var d := (b - a).abs()
	var s := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var err := d.x - d.y
	var p := a
	var o := Vector2i(w / 2, w / 2)
	col.a *= _fade
	for i in d.x + d.y + 1:
		_cv.draw_rect(Rect2(Vector2(p - o), Vector2(w, w)), col)
		if p == b:
			return
		var e2 := 2 * err
		if e2 > -d.y:
			err -= d.y
			p.x += s.x
		if e2 < d.x:
			err += d.x
			p.y += s.y

# 판정 경계(4.1s 1차 요소): 고리 r(밝은 색)과 그 바깥 r + 1(어두운 색). others([가운데 맵 px, 반지름 px])와 겹친 칸은 뺀다
static func edge_cells(c: Vector2i, r: int, others: Array) -> Array:
	var out := []
	for rr in [r + 1, r]:
		var cells := []
		for o in px_cells(rr, 1):
			var q := Vector2(c + o) + Vector2(0.5, 0.5)
			if not others.any(func(z): return q.distance_to(z[0]) < z[1] - 0.5):
				cells.append(c + o)
		out.append(cells)
	return out

func _edge(c: Vector2i, r: int, light: Color, dark: Color, others := []) -> void:
	var cells := edge_cells(c, r, others)
	for i in 2:
		for p in cells[i]:
			_cv.draw_rect(Rect2(Vector2(p), Vector2.ONE), dark if i == 0 else light)

# 이펙트 조각 한 프레임(art/fx/fx.png). bottom이면 at이 아래 가운데, 아니면 가운데
func _spr(name: String, frame: int, at: Vector2i, bottom := false) -> void:
	var m: Array = FX_ART[name]
	var w := int(m[2])
	var h := int(m[3])
	var pos := at - (Vector2i(w / 2, h) if bottom else Vector2i(w / 2, h / 2))
	_cv.draw_texture_rect_region(FX_TEX, Rect2(Vector2(pos), Vector2(w, h)), Rect2(m[0] + posmod(frame, int(m[4])) * w, m[1], w, h), Color(1, 1, 1, _fade))

# 아트 px 칸 하나(또는 size 칸) 칠하기(fx-2). 시험의 기록 화면이 가로챈다
func _px(p: Vector2i, col: Color, size := Vector2i.ONE) -> void:
	_cv.draw_rect(Rect2(Vector2(p), Vector2(size)), Color(col, col.a * _fade))

func _out(k: float) -> float:
	return 1.0 - (1.0 - k) * (1.0 - k)

# 아이아스 R 둘레(S179, I142, fx-2): 에너지 성벽 칸 가운데마다 반경 radius 원을 합친 모양(칸 줄을 감싼 캡슐)이다.
# 다른 장판처럼 펼쳐지고 줄어들며(zone_r), 얼음색 성긴 칠 + 밝은 1px + 바깥 어두운 1px 테두리다. 안에서 얼음색 점이 천천히 떠오른다.
# 모양은 칸 배치·반지름마다 한 번 굽는다(capsule_cells). 둘레가 없으면 _zones가 버린다
func _capsule(z) -> void:
	var r := zone_r(z, _zone_age(z))
	if r < 2:
		return
	var c := Vector2i(_center(Vector2(z.cells[0])).floor())
	var offs: Array = z.cells.map(func(q): return (q - z.cells[0]) * CELL)
	var key := str(offs) + str(r)
	if not _caps.has(key):
		_caps[key] = capsule_cells(offs, r)
	var m: Array = _caps[key]
	draw_texture(m[0], Vector2(c + m[1]), PX.ice3)
	for i in 2:
		for p in m[2 + i]:
			_px(c + p, PX.ice0 if i == 0 else PX.navy)
	var seed := hash(str(z.pos) + z.src)
	for i in 6:
		var ph := fmod(clock * 0.6 + _hf(seed, i), 1.0)
		var o: Vector2i = offs[i % offs.size()]
		var p := c + o + Vector2i((Vector2.from_angle(_hf(seed, i + 10) * TAU) * _hf(seed, i + 20) * r * 0.7).round()) - Vector2i(0, int(8.0 * ph))
		_px(p, PX.ice0 if ph < 0.5 else PX.ice1)

# 칸 가운데 offs(첫 칸 가운데에서 본 맵 px)마다 반지름 r 원을 합친 모양의 아트 px.
# 돌려주는 것: [안쪽 성긴 칠(1/16, I228 ⑦) 흰 마스크 텍스처, 그 왼쪽 위, 밝은 테두리 칸(반경 r), 어두운 테두리 칸(그 바깥 한 칸)]. 칸 판정은 px_cells와 같다(가운데가 칸 모서리)
static func capsule_cells(offs: Array, r: int) -> Array:
	var lo := Vector2i(offs[0])
	var hi := Vector2i(offs[0])
	for o in offs:
		lo = lo.min(o)
		hi = hi.max(o)
	lo -= Vector2i(r + 2, r + 2)
	hi += Vector2i(r + 2, r + 2)
	var img := Image.create(hi.x - lo.x, hi.y - lo.y, false, Image.FORMAT_RGBA8)
	var light := []
	var dark := []
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			var q := Vector2(x + 0.5, y + 0.5)
			var d := INF
			for o in offs:
				d = minf(d, q.distance_to(Vector2(o)))
			if d <= r - 0.5:
				if posmod(hash(Vector2i(x, y)), 16) < 1:
					img.set_pixel(x - lo.x, y - lo.y, Color.WHITE)
			elif d <= r + 0.5:
				light.append(Vector2i(x, y))
			elif d <= r + 1.5:
				dark.append(Vector2i(x, y))
	return [ImageTexture.create_from_image(img), lo, light, dark]

# 에너지 성벽 칸(아이아스 R, S151·I101, fx-2): 칸 위에 선 얼음색 벽 조각(칸 윗면 + 앞면 6px, 성기게 칠해 비침). 이웃 칸과 한 벽으로 이어진다(ward_edges).
# 처음 WALL_RISE초는 아래에서부터 드러나고, 옅은 줄이 아래에서 위로 지나가며, 남은 시간이 ZONE_CLOSE초 밑이면 금 간 그림이다.
# 다 드러난 북쪽 끝 칸은 윗면 뒤끝에 흉벽 이빨 셋이 선다(I228 ⑦). 장판 다음, 몸통 아래 층이라 유닛을 가리지 않는다
func _wards() -> void:
	var of := {}
	for z in battle.zones:
		if z.has("cells"):
			for q in z.cells:
				of[q] = z
	var cells: Array = battle.barriers.keys()
	cells.sort_custom(func(p, q): return p.y < q.y)
	var m: Array = FX_ART.ward
	var w := int(m[2])
	var tall := float(m[3])
	for q in cells:
		var z = of.get(q)
		var f := 3 if z and z.left < ZONE_CLOSE else posmod(int(clock * 6.0) - q.y, 3)  # 줄은 남쪽 칸부터 북쪽 칸으로 이어 오른다
		var top := Vector2(q) * CELL - Vector2(0, tall - CELL)  # 그림 왼쪽 위(앞면 아래끝이 칸 아래끝)
		var shown := top.y + tall * (1.0 - (clampf(_zone_age(z) / WALL_RISE, 0.0, 1.0) if z else 1.0))  # 드러난 윗끝
		var e := ward_edges(battle.barriers, q)
		var end := top.y + (tall if e[0] else float(CELL))
		if shown < end:
			draw_texture_rect_region(FX_TEX, Rect2(top.x, shown, w, end - shown), Rect2(m[0] + f * w, m[1] + shown - top.y, w, end - shown))
		for i in 2:  # 윗면 뒤끝(그림 0줄)·앞끝(15줄)의 밝은 선
			if e[1 + i] and top.y + i * (CELL - 1) >= shown:
				_px(Vector2i(top) + Vector2i(0, i * (CELL - 1)), PX.ice0, Vector2i(w, 1))
		if e[1] and top.y >= shown:
			_merlons(Vector2i(top))

# 흉벽 이빨 셋(I228 ⑦): top은 벽 조각 그림의 왼쪽 위. 윗면 뒤끝 바로 위 x 1·7·13에 2×3 얼음(위 1px 밝은 얼음)과 양옆 남색 1px
func _merlons(top: Vector2i) -> void:
	for x in [1, 7, 13]:
		_px(top + Vector2i(x - 1, -3), PX.navy, Vector2i(4, 3))
		_px(top + Vector2i(x, -3), PX.ice1, Vector2i(2, 3))
		_px(top + Vector2i(x, -3), PX.ice0, Vector2i(2, 1))

# 에너지 성벽 칸 q를 어떻게 그리나(fx-2): [앞면, 윗면 뒤끝 밝은 선, 윗면 앞끝 밝은 선]. 북쪽·남쪽에 벽 칸이 있으면 그쪽 끝은 이어지므로 긋지 않고,
# 남쪽 벽 칸의 윗면이 덮을 자리라 앞면도 그리지 않는다. 동서로는 그림에 옆 테두리가 없어 그대로 이어진다
static func ward_edges(walls: Dictionary, q: Vector2i) -> Array:
	var south := walls.has(q + Vector2i(0, 1))
	return [not south, not walls.has(q - Vector2i(0, 1)), not south]

# 칸에 붙는 표시: 놓기 모드 칸, 효과 테두리, 고른 것 테두리, 집결 지점, 체력 막대. 성벽 그림에 가리지 않게 몸통 뒤에 그린다(4.1c)
func _marks() -> void:
	if controls.placing in battle.STRUCTURE_KINDS:  # 구조물 놓기: 커서 칸에 차지 칸 미리보기를 지어질 그림 자리에(S216 2026-10-28, I138)
		var c := Vector2i((controls.mouse / CELL).floor())  # 클릭이 짓는 칸과 같은 좌표
		var key := [controls.placing, c, battle.structures.size()]
		var now := Time.get_ticks_msec()
		if _ghost.slice(0, 3) != key or now - _ghost[3] > 500:
			_ghost = key + [now, ghost(battle, controls.placing, c)]
		var g: Array = _ghost[4]
		var col: Color = GHOST_OK if g[1] else GHOST_NO
		var s := {"kind": controls.placing, "cell": c, "dest": null, "razed": 0.0, "complete": false, "progress": 0.0}  # 지을 구조물의 청사진(S176)
		var area := Rect2(Vector2(g[0].position * CELL) - Vector2(0, _lift(s)), Vector2(g[0].size * CELL))  # 성벽 위 대포는 지은 대포처럼 올린다
		draw_rect(area, Color(col, 0.25))
		_facility(s, col)
		draw_rect(area, col, false, 1.0)
	elif controls.placing != "":  # 용병 놓기: 지금 놓을 수 있는 칸을 엷게(S45, I138)
		for c in battle.placeable_cells(controls.placing):
			draw_rect(_rect(c), Color(1, 1, 1, 0.25))
	for s in battle.structures.values() + battle.castle.values():  # 받는 피해 감소·공격 속도가 걸린 칸(I101)
		var ring := 1
		for key in ["dr", "haste"]:
			if battle.effect_sum(s, key) > 0.0:
				draw_rect(_box(s).grow(-ring), MARKS[key], false, 1.0)
				ring += 2
	for s in controls.picked + ([controls.fort] if controls.fort else []) + ([battle.base] if controls.village else []):  # 전투 단계에 고른 구조물(S74, S83)·고른 성곽 칸(S85)·고른 거점(S100)
		draw_rect(_box(s), Color.WHITE, false, 1.0)
	var f = controls.facility  # 고른 생산 시설: 테두리와 집결 지점 깃발(S82)
	if f and f.alive:
		draw_rect(_box(f), Color.WHITE, false, 1.0)
		draw_line(_center(battle.middle(f)), _center(Vector2(f.rally)), Color(1, 1, 1, 0.4), 1.0)
		draw_rect(_rect(f.rally).grow(-5), Color.WHITE)
	_hp_bar(Vector2(battle.base.cell) - Vector2(0, 1.75), battle.base, Vector2(CELL, 2), true)  # 망루 흉벽 위(칸 위 1.75칸). 칸 위에 그리면 앞면 휘장을 가로질렀다
	# 구조물·성곽은 깎였을 때만 체력 막대를 그린다(성곽 칸이 많아서). V로 켜면 구조물은 늘 그린다(S73, I59). 막대 색은 3단(S199)
	for b in battle.castle.values() + battle.structures.values():
		if b.hp < b.max_hp or (controls.show_hp and b.kind in battle.STRUCTURE_KINDS):
			var top: float = FAC_FOOT.y - CELL - FAC[b.kind][1] if FAC.has(b.kind) else 0.0  # 시설은 그림 위에(4.1e). 칸 위에 그리면 그림을 가로질렀다
			if battle.castle.get(b.cell) == b:
				top += rise_at(battle, b.cell)  # 문루·탑은 앞면이 높아진 만큼 위에(S170). 성벽과 같은 자리(흉벽 바로 아래)다
			_hp_bar(Vector2(battle.middle(b).x, b.cell.y) - Vector2(0, (_lift(b) + top) / CELL), b, Vector2(CELL, 2), true)  # 차지 칸 가운데 위(S173)

# 유닛·적·주민 몸통(S165, S172)과 성곽·거점(4.1c)·시설(4.1e). 잔해는 _draw가 바닥 층으로 먼저 깐다(S170). 땅의 쓰러진 몸(S180), 발밑 팀 색(S166)과 비행 적 그림자(I81)를 먼저 깔고, (층, 바닥선 y, 목록 순서)로 정렬해 그린다.
# 성곽 칸은 몸체(바닥선)와 앞층(바닥선 + 2) 두 조각이고, 성벽 위 유닛·대포와 기어오르는 적은 그 사이(바닥선 + 1)에 올려 그려 앞층이 발을 가린다(05 §2).
# 성벽 위 유닛의 발밑 팀 색만은 앞층 다음(바닥선 + 3)에 올려 그려 흉벽에 가리지 않게 한다(사용자 2026-10-20).
# 성벽·거점 그림에 가려진 땅 유닛과 시설은 끝에 한 번 더 그린다(_shade). 레벨·선택·효과 테두리는 _draw가 모든 몸통 뒤에 그린다
func _bodies() -> void:
	var all: Array = battle.units + _foes  # 숨은 적(S213)은 몸·발밑을 그리지 않는다
	var walls: Array = battle.castle.values()
	var blds: Array = battle.structures.values()
	for s in battle.structures.values():  # 옮겨 갈 칸의 대포 청사진(S176): 진행률 0인 미완성 대포로 그린다
		if s.dest != null:
			blds.append({"kind": s.kind, "cell": s.dest, "dest": null, "razed": 0.0, "complete": false, "progress": 0.0})
	_hits = hit_table(all + blds)
	var now := Time.get_ticks_msec() / 1000.0
	var day: Array = battle.people  # 주민(S223): 판이 스텝마다 구한 자리. 걷는 쪽은 지난 스텝 자리(was)와의 차다
	_folk_now = [day, day.map(func(v): return v.f)]
	var pl := _prop_list()
	var n := all.size()
	var m := n + 2 * walls.size()  # 이 번호부터 시설, 그다음 거점
	var feet := m + blds.size() + 1  # 이 번호부터 성벽 위 유닛의 발밑 표시
	var folk := feet + n  # 이 번호부터 주민
	var grave := folk + day.size()  # 이 번호부터 성벽 위의 쓰러진 몸
	var keys := PackedInt64Array()
	for w in battle.wrecks:  # 수레 잔해(S172 2026-11-05 변경 ⑥)는 땅의 쓰러진 몸처럼 모든 몸통 아래. 어둠 속이면 그리지 않는다(S213)
		if ART.has("wreck") and battle.seen(w.at):
			_wreck(w)
	var dead := _fallen()
	for k in dead.size():
		var x = dead[k][0]
		var stand: bool = _last_blow(x)[0]
		if x.get("flying") == true and (stand or not ART[x.kind].has("fall")):  # 날던 자리의 몸(S180 2026-11-03 변경)은 나는 몸의 층: 망루·시설 뒤에 가리지 않는다
			keys.append((2 << 44) | ((int(_center(x.pos).y) + 64) << 20) | (grave + k))
		elif stand:  # 막타를 기다리거나 번쩍이는 선 몸은 산 몸과 같은 차례(S197)
			keys.append((1 << 44) | ((int(_wall_line(Vector2i(x.pos.round())) if x.on_wall else _center(x.pos).y) + 64) << 20) | (grave + k))
		elif x.on_wall:  # 성벽 위의 쓰러진 몸은 낮아서 흉벽에 다 가리므로, 성벽 위 발밑 표시처럼 앞층 다음(바닥선 + 3)에
			keys.append((1 << 44) | ((_wall_line(Vector2i(x.pos.round())) + 5 + 64) << 20) | (grave + k))
		else:
			_corpse(dead[k])
	for i in n:
		var x = all[i]
		var fly: bool = x.get("flying") == true
		if not x.on_wall:
			_feet_mark(x, i)
		else:
			keys.append((1 << 44) | ((_wall_line(Vector2i(x.pos.round())) + 5 + 64) << 20) | (feet + i))
		if fly:
			draw_circle(_center(x.pos) + Vector2(0, CELL * 0.4), CELL * x.radius * 0.8, Color(0, 0, 0, 0.35))
		var y: float = _wall_line(Vector2i(x.pos.round())) if x.on_wall else ((roundf(x.pos.y) + 1) * CELL + 1 if x.get("climbed") else _center(x.pos).y)
		keys.append(((2 if fly else 1) << 44) | ((int(y) + 64) << 20) | i)
	for j in walls.size():
		var line: int = (walls[j].cell.y + 1) * CELL
		keys.append((1 << 44) | ((line - 3 + 64) << 20) | (n + 2 * j))
		keys.append((1 << 44) | ((line + 2 + 64) << 20) | (n + 2 * j + 1))
	for j in blds.size():  # 시설은 바닥선, 성벽 위 대포는 성곽 몸체와 앞층 사이(바닥선 + 1)
		var on: bool = battle.walls.has(blds[j].cell)
		keys.append((1 << 44) | (((_wall_line(blds[j].cell) if on else (blds[j].cell.y + 1) * CELL) + 64) << 20) | (m + j))
	keys.append((1 << 44) | (((battle.base.cell.y + 1) * CELL + 64) << 20) | (m + blds.size()))
	for k in day.size():
		if not day[k].inside:  # 집 안이면 그리지 않는다(S223)
			keys.append((1 << 44) | ((int(_center(day[k].pos).y) + 64) << 20) | (folk + k))
	var prop0 := grave + dead.size()  # 이 번호부터 일터 소품(S224)
	for k in pl.size():
		keys.append((1 << 44) | ((pl[k][2] + 64) << 20) | (prop0 + k))
	var grow := _ladder_grow()
	var lads: Array = grow.keys()
	var lad0 := prop0 + pl.size()  # 이 번호부터 사다리: 그 성벽 열 몸체 다음, 성벽 위 몸·공성탑 전
	for k in lads.size():
		keys.append((1 << 44) | (((lads[k].col.cell.y + 1) * CELL - 3 + 64) << 20) | (lad0 + k))
	keys.sort()
	var next := {}
	for k in keys:
		var i: int = k & 0xFFFFF
		if i >= lad0:
			_ladder(lads[i - lad0], grow[lads[i - lad0]])
		elif i >= prop0:
			_prop(pl[i - prop0], now)
		elif i >= grave:
			_corpse(dead[i - grave])
		elif i >= folk:
			_folk_body(day[i - folk], now)
		elif i >= feet:
			_feet_mark(all[i - feet], i - feet)
		elif i == m + blds.size():  # 거점 망루: 마을 레벨(S99)마다 한 장. 맞으면 흔들리고 깎이면 금(S199)
			var at := Vector2(battle.base.cell * CELL) + KEEP_AT + _jolt(battle.base)
			draw_texture_rect_region(KEEP_K, Rect2(at, Vector2(80, 80)), Rect2(80 * (clampi(battle.village_level, 1, 2) - 1), crack_y(battle.base, KEEP.get_height()), 80, 80))
		elif i >= m:
			_facility(blds[i - m])
		elif i >= n:
			_wall_piece(walls[(i - n) / 2], (i - n) % 2)
		else:
			_body(all[i], i, next)
	for i in n:
		var t := _shade(all[i])
		if t.a > 0.0:
			_body(all[i], i, next, t)
	for s in blds:  # 시설도 같은 규칙으로 덧그린다(사용자 2026-10-20)
		var t := _shade(s)
		if t.a > 0.0:
			_facility(s, t)
	_clip = -INF
	for h in battle.heroes:  # 보스 그림에 가린 영웅(S198): S171처럼 40%로 덧그리되, 보스가 맞은 것처럼 보이지 않게 번쩍임은 곱하지 않는다
		if h.alive and _under_boss(h):
			_body(h, battle.units.find(h), next, GHOST, false)
	for d in dead:  # 쓰러지는 영웅(S180 2026-10-29): 적에 가려도 보이게 쓰러짐 5프레임 동안 다른 몸통 위에 40%로 덧그린다
		if d[0].get("is_hero") == true and not fall_ring(d[0]).is_empty():
			_corpse(d, GHOST)
	_seen = next

# 가려진 몸통을 덧그릴 색. 성곽 그림이 발(칸 가운데)을 4px 넘게 덮는 줄은 그림 윗변(_clip)보다 아래만 어두운 실루엣이고(S175),
# 그보다 적게(발만) 덮는 줄은 덧그리지 않는다(투명). 성벽은 뒤 두 줄, 문루는 뒤 세 줄, 문 양옆 탑은 뒤 네 줄이 실루엣이다(S175 2026-11-03 변경). 거점 뒤는 통째로 40%다(S171)
func _shade(x) -> Color:
	_clip = -INF
	if not _behind(x):
		return Color.TRANSPARENT
	var c := Vector2i(_pos_of(x).round())
	var cover := _cover(c)
	if cover > CELL / 4.0:
		_clip = (c.y + 0.5) * CELL - cover  # 그 열 성곽 그림 윗변
		return SHADE
	return Color.TRANSPARENT if cover > 0 else GHOST

# 땅 칸 c 앞(아래) 네 줄 안의 첫 성곽 칸 그림이 c의 발(칸 가운데)보다 위로 덮는 px. 앞에 성곽이 없으면 -INF.
# 네 줄은 가장 높은 탑 열 그림이 닿는 줄 수다(S175 2026-11-03 변경)
func _cover(c: Vector2i) -> float:
	for k in range(1, 5):
		if battle.walls.has(c + Vector2i(0, k)):
			var r := rise_at(battle, c + Vector2i(0, k))
			return WALL_TOP_UP + (r + RING if r > 0 else 0) - CELL / 2.0 - CELL * (k - 1)
	return -INF

# 성곽 두께(줄, S217 2026-11-03 변경): 사방 성곽 판(마을이 맵 가장자리에서 떨어진 판)은 마을 왼끝 열이다.
# 사방 성곽이 아닌 평가 판은 두께 3 시절 값 3을 그대로 써서 그 판의 모서리·동서 판정이 바뀌지 않는다
static func depth(bt) -> int:
	return bt.village.position.x if bt.village.position.x > 0 else 3

# 성곽 칸 c에 선 유닛·대포를 성벽 통로보다 더 올리는 px(S170): 문루는 GATE_RISE, 문 양옆 탑 열은 TOWER_RISE, 그 밖은 0
static func rise_at(bt, c: Vector2i) -> int:
	var k = bt.walls.get(c)
	if k == null:
		return 0
	var t := depth(bt)
	if k.kind == "gate":
		return SIDE_GATE_RISE if k.size == Vector2i(t, 3) and (k.cell.x == 0 or k.cell.x + t == bt.size.x) else GATE_RISE
	if k.size == Vector2i(1, t) and (k.cell.x < t or k.cell.x >= bt.size.x - t):  # 모서리 탑(S219)
		return CORNER_RISE
	return TOWER_RISE if tower_of(bt, k) != "" else 0

# 성벽 열 k가 성문 바로 옆이면 그 탑 조각 이름(문 왼쪽 «tower_l», 오른쪽 «tower_r»), 아니면 «». 성문이 잔해여도 탑이다
static func tower_of(bt, k) -> String:
	for d in [1, -1]:
		var g = bt.walls.get(k.cell + Vector2i(d, 0))
		if g == null:
			g = bt.debris.get(k.cell + Vector2i(d, 0))
		if g != null and g.kind == "gate":
			return "tower_l" if d == 1 else "tower_r"
	return ""

# 맵 px p가 문루·문 양옆 탑 그림 가운데 성곽 뒤 땅 칸 쪽으로 솟은 부분이면 그 성곽 Block, 아니면 null(S218). 보통 성벽 열은 null이다
static func raised_at(bt, p: Vector2):
	var c := Vector2i((p / CELL).floor())
	for k in range(1, 5):  # 성곽 윗줄 뒤 네 줄 안(S218 2026-11-03 변경)
		var w = bt.walls.get(c + Vector2i(0, k))
		if w != null:
			var r := rise_at(bt, c + Vector2i(0, k))
			return w if r > 0 and p.y >= (c.y + k) * CELL - WALL_TOP_UP - r - RING else null  # 그 열 그림 윗변 아래
	return null

# 맵 px p가 동·서 성벽·닫힌 문루·모서리 탑 그림(통로 앞면 높이 + 그 바닥 높이만큼 올려 그림, S219) 안이면 그 성곽 Block, 아니면 null.
# 남·북 성벽 열은 null이다(문루·탑은 raised_at)
static func side_at(bt, p: Vector2):
	var x := int(floor(p.x / CELL))
	var t := depth(bt)
	if x >= t and x < bt.size.x - t:
		return null
	for up in [WALL_H + CORNER_RISE, WALL_H + SIDE_GATE_RISE, WALL_H]:
		var c := Vector2i(x, int(floor((p.y + up) / CELL)))
		if bt.walls.has(c) and WALL_H + rise_at(bt, c) == up:
			return bt.walls[c]
	return null

# 그림 한 장을 대상 사각형에 그린다(보통 원본과 같은 크기, 슬라임 킹은 늘이고 줄인다). _clip보다 위 줄은 뺀다
func _region(tex: Texture2D, dst: Rect2, src: Rect2, tint: Color) -> void:
	var cut := clampf(_clip - dst.position.y, 0.0, dst.size.y)
	if cut < dst.size.y:  # 덮개 위 층(_draw_top)에서 불러도 그 층에 그리도록 _cv에 그린다
		_cv.draw_texture_rect_region(tex, dst.grow_side(SIDE_TOP, -cut), src.grow_side(SIDE_TOP, -cut * src.size.y / dst.size.y), tint)

# 다각형 하나를 칠한다(기관총 부채꼴 예고의 차오름·발동 채움)
func _poly(pts: PackedVector2Array, col: Color) -> void:
	_cv.draw_colored_polygon(pts, col)

# 시설 하나(4.1e, 사용자 2026-10-20). 미완성은 청사진 위에 진행률만큼 아래부터 그림을 채우고, 철거 중은 거꾸로 위부터 청사진으로 돌아간다.
# 다 접힌 대포는 접힌 그림이다(I74). 성벽 위 대포(I44)는 올려 그린다
func _facility(s, tint := Color.WHITE) -> void:
	var folded: bool = s.dest != null and s.razed >= 1.0
	var f: Array = FAC["cannon_folded" if folded else s.kind]
	var t: float = 1.0 if folded else (1.0 - s.razed if s.complete else s.progress)
	var cut := roundi(f[2] - t * (f[2] - f[1]))  # 이 줄부터 아래는 그림, 위는 청사진
	var at := Vector2(s.cell * CELL) + Vector2(-FAC_FOOT.x, CELL - FAC_FOOT.y - _lift(s)) + _jolt(s) + _recoil(s)  # 맞으면 흔들린다(S199)
	var x: float = FAC_N * f[0]
	if cut > 0:
		_region(FACILITY_K, Rect2(at, Vector2(FAC_N, cut)), Rect2(x, FAC_N, FAC_N, cut), BLUEPRINT * tint)
	if cut < FAC_N:  # 다 지은 시설이 깎이면 금(S199)
		_region(FACILITY_K, Rect2(at + Vector2(0, cut), Vector2(FAC_N, FAC_N - cut)), Rect2(x, cut + crack_y(s, FACILITY.get_height()), FAC_N, FAC_N - cut), tint)

# 유닛·적 몸통 하나. 영웅은 8방향 시트, 그림이 있는 용병·적은 4방향 시트, 나머지는 원으로
func _body(x, i: int, next: Dictionary, tint := Color.WHITE, flash := true) -> void:
	if x.get("skills") and battle.raging(x):  # 분노(S195)
		tint *= RAGE
	var white: bool = flash and _hits.get(x.get_instance_id(), [INF])[0] < FLASH  # 피격 번쩍임(S177): 255배 modulate가 그림을 흰 실루엣으로 만든다(유닛 그림에 0인 채널이 없다). 배치는 끊기지 않는다
	if white and not Settings.soft_flash:
		tint *= Color(255, 255, 255)
	_paint(x, i, next, tint)
	if white and Settings.soft_flash:  # 번쩍임 줄이기(S184): 원래 그림 위에 같은 그림을 흰 40%로 한 번 더(S177)
		_paint(x, i, next, tint * SOFT_FLASH)

# 그림 칸 표(heroes.json, tools/art/atlas.py). 그림이 아직 없는 종류(LOOKS)는 빌리는 종류의 칸을 함께 쓴다(I250 ⑤)
static func _art() -> Dictionary:
	var a: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/units/heroes.json"))
	for k in LOOKS:
		if a.has(LOOKS[k][0]):
			a[k] = a[LOOKS[k][0]]
	return a

func _paint(x, i: int, next: Dictionary, tint: Color) -> void:
	if ART.has(x.kind) and not x.get("is_hero"):
		_four_sprite(x, next, tint * (LOOKS[x.kind][1] if LOOKS.has(x.kind) else Color.WHITE))  # 빌린 그림은 종류마다 색을 곱한다(I250 ⑤)
	elif i >= battle.units.size():  # 그림이 없는 적은 색 원(I81)
		draw_circle(_spot(x), CELL * x.radius, ENEMY_COLORS.get(x.kind, ENEMY_COLORS.basic) * tint)
	elif x.is_hero and ART.has(x.kind):
		_sprite(x, next, tint)
	else:
		draw_circle(_spot(x), CELL * x.radius, (HERO_COLORS.get(x.kind, COLORS.merc) if x.is_hero else COLORS.get(x.kind, COLORS.merc)) * tint)

# 몸의 그림 배율: 지금 반지름 ÷ 나온 때 반지름(줄어듦, S236)에 몸이 큰 종류의 배율(GROW)을 곱한다. 보통 몸은 1
func _shrunk(x) -> float:
	return (x.radius / x.girth if x.get("girth") else 1.0) * GROW.get(x.kind, [1.0])[0]

# 몸통 그림의 [발밑 기준 배율, 들어 올림 px](S198 2026-10-27 둘째 변경). 방향 없는 그림의 보스(슬라임 킹)는 점프(S236) 웅크림 동안
# CROUCH까지 점점 납작해지고, 뜬 동안 포물선으로 한가운데 LEAP_UP(× 큰 몸 배율)까지 오르며, 착지한 뒤 SLAM_POSE 동안 CROUCH에서 돌아온다.
# 큰 몸(GROW)은 그만큼 내려 그리고(음수 들어 올림), 갈라져 나오는 몸(S234 2026-10-29 변경)은 POP초 동안 POP_FROM배에서 커지며 POP_UP 포물선으로 뛴다
func _look(x) -> Array:
	var s := Vector2.ONE * _shrunk(x)
	var g: Array = GROW.get(x.kind, [1.0, 0.0])
	var up: float = -g[1] * s.y
	var t: float = clock - _pops.get(x.get_instance_id(), -INF)
	if t < POP:
		var k := t / POP
		s *= lerpf(POP_FROM, 1.0, k)
		up += POP_UP * 4.0 * k * (1.0 - k)
	if not (_boss(x) and ART.has(x.kind) and ART[x.kind].get("one", false)):
		return [s, up]
	var c = x.cast
	if c != null and c.has("at"):
		var sk: Dictionary = x.skills[c.id]
		if c.get("air", false):
			var a: float = 1.0 - c.left / sk.air
			return [s, up + LEAP_UP * g[0] * 4.0 * a * (1.0 - a)]
		return [s * Vector2.ONE.lerp(CROUCH, 1.0 - c.left / sk.windup), up]
	var tr = _boss_trace(x)
	if tr != null:
		return [s * CROUCH.lerp(Vector2.ONE, tr.age / SLAM_POSE), up]
	return [s, up]

# 뜬 몸의 그림자(S198): 땅 자리에 납작한 반투명 타원
func _shadow(at: Vector2, r: float) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# 성벽·거점 그림이 덮는 자리에 선 땅 유닛이나 시설: 성곽 그림이 발을 덮는 뒤 줄(성벽 두 줄, 문루 세 줄, 탑 네 줄), 거점 칸 뒤 두 줄과 그 양옆(C1, 사용자 2026-10-20)
func _behind(x) -> bool:
	if x.get("on_wall") == true or x.get("flying") == true or x.get("climbed"):
		return false
	var c := Vector2i(_pos_of(x).round())
	if not battle.walls.has(c) and _cover(c) > 0:  # 문루 통로 안(성곽 칸)은 뒤가 아니다
		return true
	var d: Vector2i = c - battle.base.cell
	return absi(d.x) <= 1 and d.y >= -2 and d.y < 0

# 발 자리(맵 px, S166): 성벽 위면 올린 자리, 비행 적은 그림자 자리. 돌진·움찔·미끄러짐을 따른다. 발밑 타원과 체력바(S276)가 같이 쓴다
func _foot(x) -> Vector2:
	return (_spot(x) if x.on_wall else _center(x.pos)) + (Vector2(0, CELL * 0.4) if x.get("flying") == true else Vector2.ZERO) + _lunge(x) + _flinch(x) + _slip(x)

# 자동 수리 표식(I210): HUD 팝업 망치(I58) 그림 7×6을 1배로. hud.gd가 이 파일을 preload하므로 거꾸로는 그릴 때 load한다
func _fix_mark() -> Texture2D:
	if _hammer == null:
		var hud = load("res://src/ui/hud.gd")
		_hammer = hud.HudBuild.dots(hud.HAMMER, {"#": hud.HudTheme.TEXT})
	return _hammer

# 발밑 팀 색(S166). i는 battle.units + battle.enemies 안의 번호다. 비행 적은 그림자 자리에 그린다
func _feet_mark(x, i: int) -> void:
	var foot := _foot(x)
	var rect := Rect2(foot + Vector2(-7, -2), Vector2(14, 6))
	var region := Rect2(14 * int(i >= battle.units.size()), 0, 14, 6)
	draw_texture_rect_region(FEET, rect, region)
	var mark := foot_mark(x)
	if mark != "":  # 고른 유닛·패널의 적(S207): 타원을 밝게 덧그리고 테두리를 두른다
		draw_texture_rect_region(FEET, rect, region, Color(SELECT_GLOW, SELECT_GLOW, SELECT_GLOW))
		_ellipse(foot + Vector2(0, 1), Vector2(8.5, 4.5), SELECT_LINES[int(mark == "foe")])

# 발밑 선택 표시(S207): 고른 영웅·용병은 «pick», 선택 패널에 보인 적(S206)은 «foe», 그 밖은 «»
func foot_mark(x) -> String:
	if x in controls.selected:
		return "pick"
	return "foe" if x == controls.shown else ""

# 맵 px 타원 테두리 1px(S207). 점을 반 px 옮겨 1px 선이 그 점에서 시작하는 도트 칸을 덮게 한다
func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 33:
		pts.append(c + Vector2(cos(TAU * k / 32.0) * r.x, sin(TAU * k / 32.0) * r.y) + Vector2(0.5, 0.5))
	draw_polyline(pts, col, 1.0)

# 성곽 칸 조각 하나(front 0 몸체, 1 앞층). 조각 맨 아랫줄이 바닥선 바로 아래 줄이다. 단계(S86)마다 그림이 다르고(사용자 2026-10-20),
# 열린 성문은 몸체 위에 통로 그늘을 겹친다(I67). 잔해(I88)는 몸체 자리에 돌무더기 하나이고 바닥 층이다(S170). 맞은 칸은 흔들리고 깎이면 금(S199)
func _wall_piece(b, front: int) -> void:
	var at := Vector2(b.cell.x * CELL, (b.cell.y + 1) * CELL - (WALL_PIECE_H - 1)) + _jolt(b)
	if battle.rubble.get(b.cell) == b:
		if front == 0:
			for i in b.size.x:  # 문루 잔해는 성벽 잔해 조각을 폭만큼 잇는다
				draw_texture_rect_region(CASTLE_K, Rect2(at + Vector2(i * CELL, 0), Vector2(16, WALL_PIECE_H)), Rect2(0, 7 * WALL_PIECE_H, 16, WALL_PIECE_H))
		return
	var col: Array = wall_col(battle, b)
	var dst := Rect2(at, Vector2(col[1], WALL_PIECE_H))
	draw_texture_rect_region(CASTLE_K, dst, Rect2(col[0], (2 * (b.level - 1) + front) * WALL_PIECE_H + crack_y(b, CASTLE.get_height()), col[1], WALL_PIECE_H))
	if front == 1 and not battle.water.is_empty() and b.size == Vector2i(1, depth(battle)) and b.cell.y < battle.base.cell.y:  # 수로 수문(S220): 북벽은 앞층이 마을 쪽 벽면이라 그 위에, 그 열 폭만큼
		var x0 := maxi(b.cell.x * CELL, CULVERT_AT.x)
		var x1 := mini((b.cell.x + 1) * CELL, CULVERT_AT.x + CULVERT.get_width())
		if x1 > x0:
			draw_texture_rect_region(CULVERT, Rect2(x0, CULVERT_AT.y, x1 - x0, CULVERT.get_height()), Rect2(x0 - CULVERT_AT.x, 0, x1 - x0, CULVERT.get_height()))
	if front == 0 and b.kind == "gate" and b.open:
		draw_texture_rect_region(CASTLE_K, dst, Rect2(col[0], 6 * WALL_PIECE_H, col[1], WALL_PIECE_H))

# 성곽 Block의 조각 열 [x, 폭](S219). 북벽(거점보다 위)은 흉벽이 뒤인 열, 동·서는 행 띠·닫힌 문루, 네 모서리 열(두께만큼)은 모서리 탑을 열마다 자른다
static func wall_col(bt, b) -> Array:
	var n: bool = b.cell.y < bt.base.cell.y
	var d := depth(bt)
	if b.size == Vector2i(d, 1):
		return WALL_COLS["w_strip" if b.cell.x == 0 else "e_strip"]
	if b.kind == "gate" and b.cell.x == 0:
		return WALL_COLS.w_gate
	if b.kind == "gate" and b.cell.x + d == bt.size.x:
		return WALL_COLS.e_gate
	if b.kind == "gate":
		return WALL_COLS["n_closed"] if n else WALL_COLS["open" if b.open else "closed"]
	if b.cell.x < d or b.cell.x >= bt.size.x - d:
		var c: Array = WALL_COLS[("nc" if n else "sc") + ("_l" if b.cell.x < d else "_r")]
		return [c[0] + (b.cell.x if b.cell.x < d else b.cell.x - (bt.size.x - d)) * CELL, CELL]
	var t := tower_of(bt, b)
	if n:
		return WALL_COLS["n_wall" if t == "" else "n_" + t]
	return WALL_COLS["castle_wall" if t == "" else t]

# 성벽 위 유닛·대포·쓰러진 몸을 정렬할 바닥선(S217): 그 성곽 Block 앞줄 바닥선 − 2에서 앞줄로 올수록 1씩 뒤다.
# 몸체(바닥선 − 3)와 앞층(바닥선 + 2) 사이라서, 통로 뒤 줄에 선 유닛도 몸체에 가리지 않고 앞층이 앞줄 유닛의 발을 가린다
func _wall_line(c: Vector2i) -> int:
	var k = battle.walls.get(c)
	if k == null:
		return (c.y + 1) * CELL + 1
	return (k.cell.y + 1) * CELL - 2 + c.y - (k.cell.y - k.size.y + 1)

# 위로 올려 그리는 정도(맵 px). 성벽 위 유닛·대포는 흉벽 바로 뒤(앞면에서 바닥 3px)에 서고, 기어오르는 적은 오른 만큼 오른다(4.1c, 05 §2).
# 문루·문 양옆 탑 칸은 그 바닥 높이만큼 더 올린다(S170). 성벽 위는 선 자리대로 그려 칸 경계에서 튀지 않는다(S170 2026-10-28)
func _lift(x) -> float:
	var p := _pos_of(x)
	var top: bool = x.on_wall if x.get("pos") != null else (x.kind in battle.STRUCTURE_KINDS and battle.walls.has(x.cell))
	if top:
		return 3 + WALL_H - CELL / 2.0 + _rise(p)
	if x.get("climbed"):
		var r: float = x.climbed / x.climb
		if x.get("vault"):  # 도약 늑대는 마지막 VAULT_RISE초에만 그만큼의 비율로 오른다(S244 ①)
			r = clampf((x.climbed - x.climb + VAULT_RISE) / VAULT_RISE, 0.0, 1.0)
		return (3 + WALL_H + rise_at(battle, Vector2i(p.round()) + Vector2i.UP)) * r
	return 0.0

# 성벽 위 자리 p의 바닥 높이(px, S170 2026-10-28): 둘레 네 칸 가운데의 rise_at을 이어 칸 사이를 비탈로 만든다. 성곽이 아닌 이웃은 선 칸 높이로 본다
func _rise(p: Vector2) -> float:
	var c := Vector2i(p.floor())
	var f := p - Vector2(c)
	var own := float(rise_at(battle, Vector2i(p.round())))
	var h := func(d: Vector2i) -> float: return float(rise_at(battle, c + d)) if battle.walls.has(c + d) else own
	return lerpf(lerpf(h.call(Vector2i(0, 0)), h.call(Vector2i(1, 0)), f.x), lerpf(h.call(Vector2i(0, 1)), h.call(Vector2i(1, 1)), f.x), f.y)

# 유닛·적·칸을 그릴 자리(맵 px, 칸 가운데)와 칸 사각형. 성벽 위에 있으면 올린다
func _spot(x) -> Vector2:
	return _center(_pos_of(x)) - Vector2(0, _lift(x))

func _box(s) -> Rect2:
	var r: Rect2i = battle.area_of(s)
	return Rect2(Vector2(r.position * CELL) - Vector2(0, _lift(s)), Vector2(r.size * CELL))  # 차지 칸(S216)

# 영웅 한 명(S165): 움직이면 그쪽으로 걷기 4프레임(초당 8), 친 뒤 0.3초는 대상 쪽으로 공격 3프레임, 아니면 정지.
# 서 있으면 대상 쪽, 대상도 없으면 마지막 방향을 본다. 위치는 화면 픽셀로 반올림한다(insights/2026-10-20_render_spike.md X1)
func _sprite(x, next: Dictionary, tint := Color.WHITE) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	var t := _ago(x)
	var pose: bool = x.target != null and t < battle.HERO_POSE and (x.path.is_empty() or t < CONTACT)  # 걷기 명령은 닿은 뒤의 공격 자세를 끊는다(S196)
	var sk = _cast_of(x)  # 시전 자세(S165 2026-10-29): 스킬을 쓴 뒤도 공격 3프레임. 기본 공격 자세와 겹치면 나중 것이다
	if sk != null and sk.age < battle.HERO_POSE and (x.path.is_empty() or sk.age < CONTACT) and not (pose and t < sk.age):
		pose = true
		t = sk.age
		if sk.aim != null:  # 자기 스킬은 보던 쪽 그대로
			dir = _dir_of((sk.aim if sk.aim is Vector2 else _pos_of(sk.aim)) - x.pos)
	elif pose or (x.target and not moving):  # 공격 자세는 밀려도 대상 쪽을 친다(S165)
		dir = _dir_of(_pos_of(x.target) - x.pos)
	elif moving:
		dir = _dir_of(v)
	next[id] = [x.pos, dir]
	var a: Dictionary = ART[x.kind]
	var c := int(a.c)
	var anim := "idle"
	var col := 0
	if pose:
		anim = "attack"
		col = clampi(int(t / 0.1), 0, 2)
	elif moving:
		anim = "walk"
		col = int(Time.get_ticks_msec() / 125.0) % 4
	var size := c * (2 if anim == "attack" else 1)  # 공격은 2배 캔버스(tools/art/hero.py)
	var at := _spot(x) + _flinch(x) + _slip(x) - Vector2(a.anchor[0], a.anchor[1]) - Vector2.ONE * (size - c) / 2.0
	_region(UNITS, Rect2(at, Vector2(size, size)), Rect2(col * size, a[anim] + dir * size, size, size), tint)

# 이 영웅이 가장 최근에 쓴 스킬의 흔적(Q·W·E·R·반격의 태세 터뜨림, S165 2026-10-29). 운석 착탄은 쓴 때가 아니라서 뺀다. 없으면 null
func _cast_of(h):
	var out = null
	for c in battle.traces:
		if c.hero == h and (c.slot in battle.SLOTS or c.slot == "burst") and (out == null or c.age < out.age):
			out = c
	return out

# 용병·적 하나(C 절충안, 4.1d. 4.1a M1·M6에서 C만 통과했다): 4방향 정지, 움직이면 걷기 2위상(초당 8), 친 뒤 0.08~0.22초는 공격 키 포즈.
# 근접은 그동안 대상 쪽으로 돌진한다(_lunge). 방향 고르기는 _sprite와 같다(tools/bench/view_draw.gd C). 기어오르는 적은 성벽 쪽(N)을 보고 걷기 2위상으로 오른다(S180)
func _four_sprite(x, next: Dictionary, tint := Color.WHITE) -> void:
	var id: int = x.get_instance_id()
	var seen = _seen.get(id)
	var v: Vector2 = x.pos - seen[0] if seen else Vector2.ZERO
	var dir: int = seen[1] if seen else 0
	var moving := v.length_squared() > 1e-8
	var a := _ago(x)  # 친 뒤 지난 시간(초)
	var pose: bool = x.target != null and a >= CONTACT and a < battle.POSE
	var cast = x.get("cast")
	var thrown: float = -1.0 if cast == null or cast.id != "throw" else x.throw.windup - cast.left  # 투석기 던지기 예고가 시작된 뒤 초
	var drops: bool = x.get("loosed") != null and (not x.bomb.is_empty() or not x.drop.is_empty())  # 열기구·비행선
	var raised: bool = x.get("col") != null and ((cast != null and cast.id == "ladder") or battle.ladders.values().has(x))  # 사다리를 내리거나 놓은 공성탑
	if drops:  # 열기구·비행선(S172 2026-11-03 둘째 변경 ②): 폭탄·투하 뒤 0.08~0.22초만 공격 키 포즈다. 기본 공격에는 쓰지 않는다
		pose = x.loosed >= CONTACT and x.loosed < battle.POSE
	if thrown >= CONTACT and thrown < battle.POSE:  # 투석기(S172 2026-11-03 변경 ②): 예고가 시작되면 원 가운데 쪽으로 던진다
		pose = true
		dir = _four(cast.at - x.pos)
	elif raised:  # 공성탑(S172 2026-11-03 둘째 변경 ①): 사다리를 내리기 시작한 때부터 부서질 때까지 성벽 열 쪽으로 다리판을 건다
		pose = true
		dir = _four(battle.nearest(x.col, x.pos) - x.pos)
	elif (pose and not drops) or (x.target and not moving):  # 공격 자세는 밀려도 대상 쪽을 친다(S172)
		dir = _four(_pos_of(x.target) - x.pos)
	elif moving:
		dir = _four(v)
	if x.get("climbed"):
		dir = 2
	var land: bool = ART[x.kind].has("land_idle") and not x.flying  # 내려앉은 글라이더(S172 2026-11-03 변경 ③): 날개를 접은 정지·걷기
	var anim := "land_idle" if land else "idle"
	var col := 0
	if pose or (cast != null and cast.id == "fuse"):  # 폭파병(S172 2026-11-03 변경 ①): 도화선이 타는 동안 내내 공격 키 포즈
		anim = "attack"
	elif x.get("climbed") and x.get("vault"):  # 도약 늑대(S244 ①): 성벽 밑에서 웅크리다 마지막 VAULT_RISE초에 정지 그림으로 올라선다
		anim = "crouch" if x.climb - x.climbed > VAULT_RISE else "idle"
	elif moving or x.get("climbed"):
		anim = "land_walk" if land else "walk"
		col = int(Time.get_ticks_msec() / 125.0) % 2
	var off := Vector2.ZERO
	var hop := 0.0  # 그림자는 그대로 두고 그림만 드는 높이(px)
	if _boss(x):  # 보스 스킬(S198): 예고 끝에 들어 올렸다가 발동하면 내리찍는다. 원 모양 스킬은 화면 쪽(S)을, 방향 스킬은 그쪽을 본다
		var c = _boss_trace(x, SLAM_POSE * 2.0)
		var sheet: String = "" if c == null else c.slot
		if sheet == "slam" and not ART[x.kind].has("slam") and ART[x.kind].has(LANDING):  # 대장 착지 뒤 착지 웅크림(S172 2026-11-05 변경 ③)
			sheet = LANDING
		var rig: bool = c != null and ART[x.kind].has(sheet)
		if c != null and c.age >= SLAM_POSE * (PEAK.get(sheet, [1]).size() if rig else 1):
			c = null
		if ART[x.kind].get("one", false):  # 방향 없는 그림(슬라임 킹, S198 2026-10-27 둘째 변경)은 웅크림·뜸·착지를 정지 그림으로 하고 모양은 _look이 정한다
			if c != null or x.cast:
				anim = "idle"
				col = 0
		elif rig and c != null:  # 스킬 시트의 정점 열(S172 2026-11-03 셋째 변경 ②③, 2026-11-05 변경 ②): 대포는 원 가운데 쪽을 본다. 정점 열을 다 보였으면(c를 비웠으면) 흔적이 없을 때처럼 그린다
			anim = sheet
			col = PEAK.get(sheet, [1])[int(c.age / SLAM_POSE)]
			if c.slot == "cannon":
				dir = _four(c.at - x.pos)
			elif c.has("dir"):  # 철퇴: 부채꼴 가운데 쪽(S198)
				dir = _four(Vector2.from_angle(c.dir))
			elif c.has("from"):  # 돌진: 내달린 쪽(S198)
				dir = _four(c.at - c.from)
			else:
				dir = 0 if c.aim == null else _four(Vector2(c.aim) - c.at)
			off.y = 1.0 if c.age < SLAM_POSE else 0.0
		elif c != null:
			anim = "attack"
			col = 0  # 4방향 시트의 공격은 키 포즈 한 칸이다. 밀려 걷는 위상이 남으면 빈 칸을 그린다
			dir = 0 if c.aim == null else _four(Vector2(c.aim) - c.at)
			off.y = 1.0
		elif x.cast and x.cast.get("air", false) and ART[x.kind].has(x.cast.id):  # 대장 등장 착지(S172 2026-11-05 변경 ③): 뜬 동안 내내 공중 자세를 한가운데 LEAP_UP까지 포물선으로 든다. 화면 쪽을 본다
			var t: float = 1.0 - x.cast.left / x.skills[x.cast.id].air
			anim = x.cast.id
			col = 0
			dir = 0
			hop = LEAP_UP * 4.0 * t * (1.0 - t)
		elif x.cast and ART[x.kind].has(x.cast.id):  # 스킬 시트의 예고·발사(S172 2026-11-03 셋째 변경 ①③): 대포는 원 가운데, 기관총은 부채꼴 가운데 쪽을 본다
			var k: Dictionary = x.cast
			dir = _four(k.at - x.pos) if k.has("at") else (_four(Vector2.from_angle(k.dir)) if k.has("dir") else 0)
			anim = "idle"
			col = 0
			if k.get("fire", false):  # 기관총 발사: 총구(S287)가 보는 쪽에서 FAN_TURN° 넘게 돌았으면 그쪽 자세. 0열이 기계의 왼쪽이다
				var sk: Dictionary = x.skills[k.id]
				var turn := rad_to_deg(angle_difference(deg_to_rad(90.0 - 90.0 * dir), battle.muzzle(k.dir, sk, sk.fire - k.left)))
				anim = k.id
				col = 0 if turn < -FAN_TURN else (2 if turn > FAN_TURN else 1)
			elif k.left < LIFT:
				if not STILL_TELL.has(k.id):
					anim = k.id
					col = READY.get(k.id, 0)
				off.y = -2.0
		elif x.cast and x.cast.id == "pounce":  # 덮치기(S244 ②): 예고는 대상 쪽 웅크림, 뜬 동안은 뜀. S198의 들어 올림은 쓰지 않는다
			anim = "air" if x.cast.get("air", false) else "crouch"
			col = 0
			dir = _four(x.cast.at - x.pos)
		elif x.cast and x.cast.left < LIFT:
			anim = "idle"
			col = 0
			dir = 0
			off.y = -2.0
		if x.fx.has("stagger"):  # 비틀거리는 동안 8프레임마다 좌우로 1px 떤다
			off.x = 1.0 if int(clock * 60.0 / 8.0) % 2 == 0 else -1.0
	if anim == "attack" and BLOW.has(x.kind):
		anim = BLOW[x.kind][0]
		col = BLOW[x.kind][1]
	if (anim == "idle" or anim == "walk") and ART[x.kind].has("rage_" + anim) and battle.raging(x):  # 분노 중 정지·걷기는 망토를 찢어 던진 몸(S172 2026-11-05 변경 ④)
		anim = "rage_" + anim
	next[id] = [x.pos, dir]
	var p := _spot(x) + _lunge(x) + _flinch(x) + _slip(x) + off
	var lk := _look(x)
	if x.get("cast") and x.cast.get("air", false):
		_shadow(p, CELL * x.radius)
	_frame(ART[x.kind], anim, dir, col, p - Vector2(0, lk[1] + hop), tint, lk[0])

# 그릴 쓰러진 몸(S180) [몸, 쓰러진 뒤 초]: 시뮬레이션이 아직 지우지 않은 적·용병과 복귀 전 영웅. 영웅은 지워진 뒤에도 마지막 자세로 남는다
func _fallen() -> Array:
	var out := []
	for f in battle.fallen:  # 어둠 속에서 쓰러진 적(S213)은 그리지 않는다. 적에게는 is_hero가 없다
		if f.who.get("is_hero") != true and ART.has(f.who.kind) and (f.who.get("is_hero") != null or battle.seen(f.who.pos)):
			out.append([f.who, f.age])
	for h in battle.heroes:
		if not h.alive and ART.has(h.kind):
			var f: Array = battle.fallen.filter(func(e): return e.who == h)
			out.append([h, f[0].age if f else battle.FALLEN])
	return out

# 수레 잔해 하나(S172 2026-11-05 변경 ⑥): 부서질 때 기계가 보던 쪽의 잔해 그림을 그 자리에 두고, 지워지기(battle.WRECK) 전 WRECK_FADE 동안 흐린다
func _wreck(w: Dictionary) -> void:
	var id: int = w.who.get_instance_id()
	if not _wreck_dirs.has(id):
		var seen = _seen.get(id)
		_wreck_dirs[id] = seen[1] if seen else 0
	var a := clampf((battle.WRECK - w.age) / WRECK_FADE, 0.0, 1.0)
	_frame(ART.wreck, "idle", _wreck_dirs[id], 0, _center(w.at), Color(1, 1, 1, a))

# 쓰러진 몸 하나(S180): 4.1d 누운 자세. 영웅은 쓰러짐 5프레임을 지나 누운 채 남고, 적·용병은 바로 누워 지워지기 전 CORPSE_FADE 동안 흐려진다.
# 성벽 위에서 쓰러지면 성벽 위에, 오르던 적은 성벽 밑에, 비행 적은 그림자 자리에 눕는다. 막타를 기다리거나 번쩍이는 동안은 선 자세다(S197)
func _corpse(d: Array, tint := Color.WHITE) -> void:
	var x = d[0]
	var hero: bool = x.get("is_hero") == true
	var s := _last_blow(x, d[1])
	var k := _shrunk(x)
	var down := Vector2(0, GROW.get(x.kind, [1.0, 0.0])[1] * k)  # 큰 몸은 선 몸처럼 내려 그린다(_look)
	if s[0]:
		var soft: bool = s[1] and Settings.soft_flash  # 번쩍임 줄이기(S184)면 선 자세 위에 흰 40%를 덧그린다(S197)
		_frame(ART[x.kind], "idle", s[4], 0, _spot(x) + s[2] + down, Color(255, 255, 255) if s[1] and not soft else Color.WHITE, Vector2.ONE * k)  # 흰 실루엣은 _body의 피격 번쩍임과 같은 255배 modulate
		if soft:
			_frame(ART[x.kind], "idle", s[4], 0, _spot(x) + s[2] + down, SOFT_FLASH, Vector2.ONE * k)
		return
	var p: Vector2 = (_spot(x) if x.on_wall else _center(x.pos) + (Vector2(0, CELL * 0.4) if x.get("flying") == true else Vector2.ZERO)) + s[2] + down
	var a := 1.0 if hero else clampf((battle.FALLEN - d[1]) / CORPSE_FADE, 0.0, 1.0)
	if not ART[x.kind].has("fall"):  # 망치·투석기(S172 2026-11-03 변경 ④): 누운 그림 없이 쓰러질 때 보던 쪽의 정지 그림이 흐려진다
		_frame(ART[x.kind], "idle", s[4], 0, _spot(x) + s[2] + down, Color(1, 1, 1, a) * tint, Vector2.ONE * k)
		return
	_frame(ART[x.kind], "fall", 0, mini(int(s[3] / FALL_STEP), 4) if hero else 0, p, Color(1, 1, 1, a) * tint, Vector2.ONE * k)

# 쓰러지는 영웅의 고리(S180 2026-10-29): [가운데(맵 px, X 자리), 반경(px), 굵기, 불투명도]. 누운 때부터 쓰러짐 5프레임(FALL_RING) 동안
# 몸에서 FALL_REACH칸까지 퍼지며 굵기 2 → 1로 옅어진다. 그동안 몸은 다른 몸통 위에 덧그린다(_bodies). 아니면 []
func fall_ring(h) -> Array:
	var at = _cross_at(h)
	var f: Array = battle.fallen.filter(func(e): return e.who == h)
	if at == null or f.is_empty():
		return []
	var t: float = _last_blow(h, f[0].age)[3]
	if t < 0.0 or t >= FALL_RING:  # 막타 번쩍임 동안은 아직 서 있다(S197)
		return []
	var k := t / FALL_RING
	return [at, int(CELL * FALL_REACH * k), 2 if k < 0.5 else 1, 1.0 - k]

# 4방향 시트(tools/art/atlas.py FOUR)의 한 칸을 발밑 p에 그린다. 행은 S·E·N·W, 공격·쓰러짐은 2배 캔버스. 방향 없는 칸(one, I189)은 늘 0행이다.
# scale은 발밑 기준 배율이다(슬라임 킹 웅크림·줄어듦, S198)
func _frame(a: Dictionary, anim: String, dir: int, col: int, p: Vector2, tint := Color.WHITE, scale := Vector2.ONE) -> void:
	var c := int(a.c)
	var size := c * (2 if anim == "attack" or anim == "fall" else 1)
	var at := p - (Vector2(a.anchor[0], a.anchor[1]) + Vector2.ONE * (size - c) / 2.0) * scale
	var row := 0 if a.get("one", false) else dir
	_region(UNITS, Rect2(at, Vector2(size, size) * scale), Rect2(a.get("x", 0) + col * size, a[anim] + row * size, size, size), tint)  # 주민 칸(S221)·방향 없는 칸(I189)은 x가 있다

# 화면 방향 v → 4방향 시트 행(S·E·N·W)
func _four(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 90.0), 4)

# 주민 몸(S172·S223). 걷기·놀기는 움직이는 쪽을 보고 걷기 2위상, 들고 걷기도 같은 4방향 시트다. 제자리 일 자세는 일터 쪽(동·서)을
# 숙련에 따른 간격(Folk.frame_gap, S231)마다 2프레임 번갈고, 그 자세 그림이 없는 칸이면 정지·걷기로 그린다
func _folk_body(x, now: float) -> void:
	var a: Dictionary = ART["folk_%s_%d" % [x.f.body, x.f.look]]
	var v: Vector2 = x.pos - x.was
	var moving := v.length_squared() > 1e-8
	var at := _center(x.pos)
	if x.pose.begins_with("carry") and a.has(x.pose):
		_frame(a, x.pose, _four(v) if moving else 0, int(now * 8.0) % 2 if moving else 0, at)
	elif x.dir >= 0 and a.has(x.pose):
		_frame(a, x.pose, x.dir, int(now / Folk.frame_gap(x.m)) % 2, at)
	else:
		_frame(a, "walk" if moving else "idle", _four(v), int(now * 8.0) % 2 if moving else 0, at)

# 이번 판의 일터 소품(S224): [종류, 칸, 정렬 바닥선 y(px)]. 여관 간판은 집 앞줄 바닥선 바로 뒤에 그려 집 그림 위에 얹는다
func _prop_list() -> Array:
	var pr := props(battle)
	var out := []
	if not pr.mill.is_empty():
		out.append(["mill", pr.mill[0], (pr.mill[1].y + 1) * CELL])
	for c in pr.oven:
		out.append(["oven", c, (c.y + 1) * CELL])
	for k in pr.stalls.size():
		out.append(["stall%d" % k, pr.stalls[k], (pr.stalls[k].y + 1) * CELL])
	for c in pr.inn:
		out.append(["inn", c, (c.y + 1) * CELL + 1])
	return out

# 소품 하나(art/tiles/props.png, tools/art/props.py). 물레방아 바퀴는 PROP_WHEEL_FPS로 네 장을 돈다
func _prop(p: Array, now: float) -> void:
	var r: Rect2 = PROP_ART[p[0]]
	var at: Vector2 = Vector2(p[1]) * CELL + PROP_AT[p[0]]
	draw_texture_rect_region(PROPS, Rect2(at, r.size), r)
	if p[0] == "mill":
		var w: Rect2 = PROP_ART.wheel
		draw_texture_rect_region(PROPS, Rect2(Vector2(Folk.MILL[1]) * CELL + PROP_AT.wheel, w.size), Rect2(w.position + Vector2(w.size.x * (int(now * PROP_WHEEL_FPS) % 4), 0), w.size))

# 근접 용병·적의 돌진(px): 친 뒤 0.08초에 대상 쪽으로 LUNGE + 대상 몸까지의 틈만큼 나가고 0.32초에 걸쳐 돌아온다. 발밑 표시도 함께 옮긴다.
# 영웅(8방향 공격 프레임, S165)과 원거리(사거리 2칸 초과)는 돌진하지 않는다. 몸 반지름이 없는 구조물은 틈이 0이다(S172 2026-10-30 변경)
func _lunge(x) -> Vector2:
	var a := _ago(x)
	if x.get("is_hero") or (x.get("range") != null and x.range > 2.0) or not x.target or a >= 0.4:
		return Vector2.ZERO
	var to: Vector2 = _pos_of(x.target) - x.pos
	var gap: float = maxf(to.length() - x.radius - x.target.radius, 0.0) * CELL if x.target.get("radius") != null else 0.0
	return to.normalized() * (LUNGE + gap) * (a / CONTACT if a < CONTACT else 1.0 - (a - CONTACT) / 0.32)

# 공격자 xs 가운데 방금 친 것의 대상 → [맞은 뒤 지난 시간(초), 공격자 → 대상 방향, 밀림(px), 돌아오는 시간(초), 강철 점](S177). 여럿에게 맞으면 가장 최근 타격이다.
# 근접 기본 공격은 시뮬레이션에 상태를 두지 않고 공격자의 친 뒤 시간에서 구한다(06 §4). 원거리는 시뮬레이션 투사체가 닿은 때부터다(battle.landed, S178).
# 즉시 스킬은 시뮬레이션이 남긴 흔적(traces)의 맞은 대상이다(S179). 보스가 친 타격과 보스 스킬에 맞은 것은 무겁다(S198): 더 멀리 밀리고 늦게 돌아온다.
# 대포알의 주 대상도 무겁고, 범위 곁 대상은 떨어진 곳 반대쪽으로 SIDE만큼이다(S178 2026-10-28). 장갑은 _weight
func hit_table(xs: Array) -> Dictionary:
	var hits := {}
	for x in xs:
		if x.get("target") != null and not _ranged(x):
			var t: float = _ago(x) - _contact(x)
			var id: int = x.target.get_instance_id()
			var w := _weight(x.target, "phys", HEAVY, HEAVY_BACK) if _boss(x) else _weight(x.target, "phys")  # 근접 기본 공격은 물리다
			if t >= 0.0 and t < _keep(w) and t < hits.get(id, [INF])[0]:
				hits[id] = [t, (_pos_of(x.target) - _pos_of(x)).normalized()] + w
	for m in battle.landed:  # 투사체에 맞은 적: 날아온 쪽 반대로 밀린다. 영웅이 쏜 것은 닿은 때 HITSTOP만큼 멈춘다(S177)
		var t: float = maxf(m.age - HITSTOP, 0.0) if m.src.get("is_hero") == true else m.age
		var id: int = m.target.get_instance_id()
		var w := _weight(m.target, m.kind, HEAVY, HEAVY_BACK) if m.src.kind == "cannon" else _weight(m.target, m.kind)
		if not m.missed and t < _keep(w) and t < hits.get(id, [INF])[0]:  # 놓친 대포알의 노린 적은 맞지 않았다(I224 ⑤)
			hits[id] = [t, (m.target.pos - m.from).normalized()] + w
		for s in m.side:
			w = _weight(s, m.kind, SIDE, HEAVY_BACK)
			id = s.get_instance_id()
			if t < _keep(w) and t < hits.get(id, [INF])[0]:
				hits[id] = [t, (s.pos - m.at).normalized()] + w
	for c in battle.traces:  # 즉시 스킬에 맞은 적(S179): 쓴 때(운석은 떨어진 때)부터, 흔적 가운데의 반대쪽으로 밀린다. 강철 점은 없다
		var boss := _boss(c.hero)
		for t in c.hits if c.age < (HEAVY_BACK if boss else FLINCH_BACK) else []:
			var id: int = t.get_instance_id()
			if (t in battle.enemies or boss) and c.age < hits.get(id, [INF])[0]:  # 보스 스킬(S198)은 맞은 아군·구조물
				hits[id] = [c.age, (_pos_of(t) - c.at).normalized()] + ([HEAVY, HEAVY_BACK, false] if boss else [FLINCH, FLINCH_BACK, false])
	return hits

# 맞은 몸 t의 [밀림(px), 돌아오는 시간(초), 강철 점](S177 2026-10-28). 장갑(지금 방어력 ARMORED 이상)인 몸이 물리 피해에 맞으면 강철 점이 붙고,
# 보통 밀림(FLINCH)이면 ARMOR로 준다. 무거운 타격(보스·대포)의 밀림은 그대로다. 구조물(pos 없음)은 장갑으로 보지 않는다
func _weight(t, kind: String, px := FLINCH, back := FLINCH_BACK) -> Array:
	var steel: bool = kind == "phys" and t.get("pos") != null and battle.armor_of(t) >= ARMORED
	return [ARMOR if steel and px == FLINCH else px, back, steel]

# 표에 남기는 시간(초): 밀림이 돌아오는 동안, 강철 점이 있으면 STEEL까지
func _keep(w: Array) -> float:
	return maxf(w[1], STEEL if w[2] else 0.0)

# 친 뒤 보일 시간(초). 영웅이 치거나 맞은 근접 타격은 닿은 때(_contact)에서 HITSTOP만큼 멈췄다가 늦게 흐른다(S177). 원거리는 쏜 쪽이 멈추지 않는다
func _ago(x) -> float:
	var a: float = (x.attack_gap if x.get("attack_gap") != null else x.fire_gap) - x.cooldown
	var c := _contact(x)
	if a >= c and x.target != null and not _ranged(x) and (x.get("is_hero") == true or x.target.get("is_hero") == true):
		return maxf(a - HITSTOP, c)
	return a

# 근접 공격이 대상에 닿는 때(친 뒤 초)는 돌진 끝이다. 원거리는 투사체가 나가는 때(유닛 CONTACT, 타워 0)이고, 닿는 때는 시뮬레이션 투사체가 정한다(battle.landed, S178)
func _contact(x) -> float:
	return 0.0 if x.get("pos") == null else CONTACT

# 맞은 몸의 밀림(px, S177): 공격자 반대쪽으로 FLINCH만큼 밀렸다가 FLINCH_BACK에 걸쳐 돌아온다. 무거운 타격은 HEAVY·HEAVY_BACK(S198), 장갑·곁 대상은 _weight. 발밑 표시도 함께 옮긴다
func _flinch(x) -> Vector2:
	var h = _hits.get(x.get_instance_id())
	if h == null:
		return Vector2.ZERO
	return h[1] * h[2] * maxf(1.0 - h[0] / h[3], 0.0)

# 맞은 구조물·성곽 칸·거점 그림의 흔들림(S199): 닿은 뒤 JOLT초 동안 공격자 반대쪽 주축으로 1px. 옮겨 갈 칸의 청사진(사전)은 맞지 않는다
func _jolt(x) -> Vector2:
	var h = _hits.get(x.get_instance_id()) if x is Object else null
	if h == null or h[0] >= JOLT:
		return Vector2.ZERO
	var d: Vector2 = h[1]
	return Vector2(signf(d.x), 0.0) if absf(d.x) >= absf(d.y) else Vector2(0.0, signf(d.y))

# 대포 포신 반동(S178 2026-10-28): 쏜 뒤 RECOIL초 동안 대상 반대쪽 주축으로 1px. 쏜 뒤 시간은 시뮬레이션 쿨다운에서 구한다(저장되는 구조물에 상태를 두지 않는다)
func _recoil(s) -> Vector2:
	if not (s is Object) or s.kind != "cannon" or s.target == null or s.fire_gap - s.cooldown >= RECOIL:
		return Vector2.ZERO
	var d: Vector2 = _pos_of(s) - _pos_of(s.target)
	return Vector2(signf(d.x), 0.0) if absf(d.x) >= absf(d.y) else Vector2(0.0, signf(d.y))

# 금 단계(S199): 다 지은 구조물·성곽 칸·거점의 체력이 75·50·25% 밑이면 1·2·3줄. 미완성·청사진(사전)은 0
static func crack_stage(b) -> int:
	if not b is Object or not b.complete:
		return 0
	var r: float = b.hp / b.max_hp
	return 3 if r < 0.25 else 2 if r < 0.5 else 1 if r < 0.75 else 0

# 금 단계와 무늬(칸 좌표 해시)가 고르는 crack_atlas 사본의 y. h는 원본 아틀라스 높이다. 금이 없으면 0(원본)
static func crack_y(b, h: int) -> int:
	var s := crack_stage(b)
	return 0 if s == 0 else ((s - 1) * 2 + _h(b.cell.x * 131 + b.cell.y, 0, 0, 1) + 1) * h

# 화면 시계와 사건 목록(I170, I171). main이 battle.step(delta) 바로 뒤에 같은 delta로 부른다. 그리기만 바꾸고 시뮬레이션은 건드리지 않는다
func tick(dt: float) -> void:
	clock += dt
	if night:  # 어둠 덮개(S212): 지금 어둠·불빛을 셰이더에 넘기고, 낮이면 숨긴다
		var mat: ShaderMaterial = night.material
		var params := night_params()
		for k in params:
			mat.set_shader_parameter(k, params[k])
		night.visible = battle.dark > 0.0
	events = []
	_fills = _fills.map(func(f): return [f[0], f[1] - 1]).filter(func(f): return f[1] > 0)
	var firing := {}
	for e in battle.enemies:  # 기관총(S287)은 발사를 시작한 때가 발동이다. 보스 스킬 흔적을 남기지 않아서 여기서 채움을 넣는다(S198)
		if e.cast != null and e.cast.id == "mgun" and e.cast.get("fire", false):
			firing[e] = true
			if not _firing.has(e):
				_fills.append([{"at": e.pos, "dir": e.cast.dir, "range": e.skills.mgun.range, "arc": e.skills.mgun.arc}, FILL])
	_firing = firing
	_scan()
	for e in events:
		_react(e)
	_dots = _dots.filter(func(d): return clock - d.t0 < d.life)
	_slide_scan()

# 이번 프레임에 새로 생긴 사건(I171). 판 단계가 준비·전투일 때와, 전투에서 넘어온 라운드 사이·도전 성공·패배에서 낸다.
# 근접의 닿음·처치는 공격자의 친 뒤 시간이 닿는 때(_contact)를 넘은 프레임에 공격 하나에 한 번이고, 처치는 쓰러진 대상을 노린 마지막 공격이 닿을 때다(S197).
# 원거리는 시뮬레이션 투사체가 닿은 프레임에 투사체 하나에 한 번이다. 피해와 닿음이 같은 때라 처치가 기다리지 않는다(S178)
func _scan() -> void:
	var s: String = battle.state
	if s == "battle":
		_from_battle = true
	elif not s in ["cleared", "won", "lost"]:
		_from_battle = false
	_live = _primed and (s == "prep" or _from_battle)
	var gone := {}
	for f in battle.fallen:  # 쓰러진 대상은 마지막 공격이 닿을 때까지 처치 사건을 기다린다(한 번만)
		var id: int = f.who.get_instance_id()
		gone[id] = true
		if not _gone.has(id):
			_dead[id] = [f.who, clock, _seen.get(id, [null, 0])[1]]
	_gone = gone
	for id in _killed.keys():  # 몸이 지워졌거나 일어난 영웅의 막타 기록은 버린다
		var w = _killed[id][2]
		if w.alive or not (gone.has(id) or w.get("is_hero") == true):
			_killed.erase(id)
	var pend := {}  # 쓰러진 대상 id → 아직 닿지 않은 공격 수
	var found := []  # [공격자, 새 공격인가, 이번 프레임에 닿았나]
	var atk := {}  # 이번 프레임의 공격자만 남긴다(쓰러지거나 팔린 공격자는 지워진다)
	for x in battle.units + battle.enemies + battle.structures.values():
		var id: int = x.get_instance_id()
		if x.get("target") == null:  # 대상이 없으면 다음 공격이 첫 공격이어도 «쏨»이 나게 한다
			atk[id] = [INF, true]
			continue
		var raw: float = (x.attack_gap if x.get("attack_gap") != null else x.fire_gap) - x.cooldown  # 히트스톱으로 멈추지 않은 친 뒤 시간
		var near := not _ranged(x)  # 원거리의 닿음은 아래 battle.landed에서 낸다
		var hit: bool = near and _ago(x) >= _contact(x)
		var was = _atk.get(id)
		var fresh: bool = was != null and raw < was[0]  # 친 뒤 시간이 줄면 새 공격이다
		var landed: bool = hit if was == null else (false if fresh else was[1])
		var now: bool = hit and not landed
		atk[id] = [raw, landed or now]
		if near and not (landed or now) and _dead.has(x.target.get_instance_id()):
			pend[x.target.get_instance_id()] = true
		found.append([x, fresh, now])
	_atk = atk
	for f in found:
		var x = f[0]
		var t = x.target
		if f[1]:
			_emit("fire", _muzzle(x) if _ranged(x) else _spot(x), Vector2.ZERO, x, t)
		if f[2]:
			var kind := "struct" if t.get("pos") == null else "hit"
			var tid: int = t.get_instance_id()
			var dir: Vector2 = (_pos_of(t) - _pos_of(x)).normalized()
			if _dead.has(tid) and not pend.has(tid):
				kind = "kill"
				_kill(t, dir)
			_emit(kind, _chest(t) if t.get("pos") != null else _spot(t), dir, x, t, {"heavy": _boss(x)})
	var shots := {}
	for m in battle.landed:  # 원거리: 새로 닿은 투사체마다 닿음, 그 투사체에 쓰러졌으면 처치. 먼저 쓰러진 대상의 빈 자리에 떨어진 대포알은 내지 않는다
		var mid: int = m.get_instance_id()
		shots[mid] = true
		if _landed.has(mid):
			continue
		if m.look == "ball":  # 대포알(S178 2026-10-28): 빈 자리에 떨어져도 먼지 6점. 범위 곁 대상이 이것에 쓰러졌으면 떨어진 곳 반대쪽으로 막타(S197)
			var foot: Vector2 = _drop_at(m).floor()
			for i in (6 if _live else 0):
				var d := Vector2.from_angle(deg_to_rad(i * 60.0 + _h(mid, i, -15, 15)))
				_dot({"p0": foot, "p1": foot + Vector2(d.x, d.y * 0.5) * _h(mid, 10 + i, 6, 10), "rise": _h(mid, 20 + i, 1, 3), "col": DUST, "size": Vector2(2, 2), "life": 0.35, "fade": 0.15})
			for o in m.side:
				var sid: int = o.get_instance_id()
				if _dead.has(sid) and not pend.has(sid):
					var away: Vector2 = (o.pos - m.at).normalized()
					_kill(o, away)
					_emit("kill", _chest(o), away, m.src, o, {"heavy": true})
		if m.missed:  # 노린 적을 놓친 대포알(I224 ⑤)은 주 대상 사건을 내지 않는다
			continue
		var t = m.target
		var tid: int = t.get_instance_id()
		var kind := "hit"
		var dir: Vector2 = (t.pos - m.from).normalized()
		if _dead.has(tid) and not pend.has(tid):
			kind = "kill"
			_kill(t, dir)
		elif not t.alive and not _dead.has(tid):
			continue
		_emit(kind, _chest(t), dir, m.src, t, {"heavy": m.src.kind == "cannon"})
	_landed = shots
	for tid in _dead.keys():  # 기다릴 공격이 없는 죽음(지속 피해·장판, 쏜 쪽이 먼저 쓰러짐)과 1초 넘게 기다린 것. 대포 범위 곁 대상은 위 착탄에서 막타를 받았다
		if not pend.has(tid) or clock - _dead[tid][1] >= 1.0:
			var t = _dead[tid][0]
			var dir := Vector2.ZERO  # 바로 눕는다. 즉시 스킬·보스 스킬에 쓰러졌으면 이번 흔적 가운데의 반대쪽으로 밀린다(S197)
			if not pend.has(tid):
				for c in battle.traces:
					if c.hits.has(t) and not _known.any(func(k): return is_same(k, c)):
						dir = (t.pos - c.at).normalized()
			_kill(t, dir)
			_emit("kill", _spot(t), dir, null, t)
	for c in battle.traces:  # 새 흔적: 영웅 스킬 또는 보스 스킬 발동
		if not _known.any(func(k): return is_same(k, c)):
			_emit("boss" if _boss(c.hero) else "cast", _center(c.at), Vector2.ZERO, c.hero, null, {"ref": c, "slot": c.slot})
	_known = battle.traces.duplicate()
	var tell := {}
	for e in battle.enemies:  # 보스 스킬 예고가 기절·빙결로 끊김(S194, S198)
		var id: int = e.get_instance_id()
		if e.cast:
			tell[id] = [_center(e.cast.get("at", e.pos)), CELL * battle.deed(e, e.cast.id).get("radius", 6.0 / CELL)]  # 조각은 예고 원 둘레에(점프는 착지 자리, S198). 덮치기(S242)는 대상 발밑 표식 6px
		elif _tell.has(id) and e.fx.has("stagger") and e.fx.stagger.left > battle.STAGGER - 0.25:  # 이번에 막 걸린 비틀거림만
			_emit("interrupt", _tell[id][0], Vector2.ZERO, e, null, {"radius": _tell[id][1]})
	_tell = tell
	for c in battle.rubble:  # 성곽 칸 붕괴
		if not _rubble.has(c):
			_emit("collapse", _center(battle.middle(battle.rubble[c])), Vector2.ZERO, null, battle.rubble[c], {"cell": c})
	_rubble = battle.rubble.duplicate()
	_primed = true

# 막타가 닿았다(S197): dir이 있으면 그 몸이 번쩍이며 밀려 눕고, 없으면 바로 눕는다
func _kill(t, dir: Vector2) -> void:
	var id: int = t.get_instance_id()
	_killed[id] = [clock, dir, t, _dead[id][2] if _dead.has(id) else 0]
	_dead.erase(id)

# 쓰러진 몸의 막타 단계(S197) [선 자세인가, 흰 번쩍임인가, 밀린 px, 누운 뒤 초, 보던 방향]. 막타 기록이 없으면 쓰러진 때(age) 바로 누운 것이다
func _last_blow(x, age := 0.0) -> Array:
	var id: int = x.get_instance_id()
	if _dead.has(id):  # 막타를 기다린다
		return [true, false, Vector2.ZERO, 0.0, _dead[id][2]]
	var k = _killed.get(id)
	if k == null:
		return [false, false, Vector2.ZERO, age, 0]
	var t: float = clock - k[0]
	var hit: bool = k[1] != Vector2.ZERO
	var up: bool = hit and t < FLASH
	return [up, up, k[1] * KILL_PUSH * minf(t / FLASH, 1.0), t - FLASH if hit else t, k[3]]

# 쓰러진 영웅의 X 자리(I130, S197): 막타가 닿은 때부터 밀린 자리에. 살아 있거나 막타를 기다리면 null
func _cross_at(h):
	if h.alive or _dead.has(h.get_instance_id()):
		return null
	return _spot(h) + _last_blow(h)[2]

func _emit(kind: String, at: Vector2, dir: Vector2, src, dst, more := {}) -> void:
	if not _live:
		return
	_n += 1
	var e := {"kind": kind, "at": at, "dir": dir, "src": src, "dst": dst, "n": _n, "heavy": false}
	e.merge(more, true)
	events.append(e)

# 사건에 붙는 그림(S198~S200): 보스 스킬 발동은 바닥 균열과 먼지, 끊김은 예고 둘레의 조각, 구조물이 맞으면 부스러기, 성곽 칸이 무너지면 먼지와 돌 조각
func _react(e: Dictionary) -> void:
	match e.kind:
		"fire":  # 타워가 쏘면 쏘는 곳에 금·크림 십자 섬광, 대포는 포신 끝에서 포연도 피어오른다(S178 2026-10-28)
			if e.src.get("pos") == null:
				var p: Vector2 = e.at.floor()
				_dot({"p0": p + Vector2(0.5, 0.5), "col": PX.cream, "life": MUZZLE_FLASH})
				for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
					for k in [1, 2]:
						_dot({"p0": p + Vector2(0.5, 0.5) + d * k, "col": PX.gold, "life": MUZZLE_FLASH})
				if e.src.kind == "cannon":
					for i in PUFFS:
						_dot({"p0": p, "p1": p + Vector2(_h(e.n, i, -3, 3), -_h(e.n, 10 + i, 4, 7)), "col": PX.smoke, "to": PX.ash, "size": Vector2(2, 2), "life": 0.4, "fade": 0.2, "wait": i * 0.03})
		"struct":  # 근접 공격이 닿은 면(공격자 쪽)에서
			_debris(e.at - e.dir * CELL * 0.4, e.n)
		"collapse":  # 칸 아래(앞줄 바닥선)에서 먼지 12점이 퍼지고, 성벽 꼭대기에서 돌 조각 4개가 0.25초 안에 때를 엇갈려 떨어진다
			var k = e.dst
			var x0: float = k.cell.x * CELL
			var w: float = k.size.x * CELL
			var floor_y: float = (k.cell.y + 1) * CELL - 1
			for i in 12:
				var p := Vector2(roundf(x0 + w * (i + 0.5) / 12.0), floor_y)
				var d := Vector2.from_angle(deg_to_rad(i * 30.0 + _h(e.n, i, -12, 12)))
				_dot({"p0": p, "p1": p + Vector2(d.x, d.y * 0.5) * _h(e.n, 20 + i, 8, 16), "rise": _h(e.n, 40 + i, 2, 4), "col": DUST, "size": Vector2(2, 2), "life": 0.45, "fade": 0.2})
			var top: float = floor_y - 3 - WALL_H - rise_at(battle, k.cell)
			for i in 4:
				var wait := i * 0.03 + _h(e.n, 60 + i, 0, 2) * 0.01
				var p := Vector2(roundf(x0 + 2 + (w - 4) * (i + 0.5) / 4.0), top + _h(e.n, 70 + i, -3, 3))
				_dot({"p0": p, "p1": Vector2(p.x + _h(e.n, 80 + i, -3, 3), floor_y), "col": STONE, "size": Vector2(3, 3), "life": 0.25 - wait, "fade": 0.05, "wait": wait, "fall": true})
		"boss":
			for t in e.ref.hits:  # 보스 스킬에 맞은 구조물·성곽 칸·거점(Block에는 pos가 없다)
				if t.get("pos") == null:
					_debris(_spot(t), e.n * 31 + t.get_instance_id())
			_fills.append([e.ref, FILL])
			var foot: Vector2 = _center(e.ref.at)
			for i in 5:  # 균열 5줄: 발밑에서 바깥으로 8~14px, 1px 걸음마다 어두운 금과 그 아래 밝은 가장자리
				var d := Vector2.from_angle(deg_to_rad(i * 72.0 + _h(e.n, i, -17, 17)))
				for j in _h(e.n, 10 + i, 8, 14):
					var p := (foot + d * (j + 2)).round()
					_dot({"p0": p + Vector2(0, 1), "col": CRACK[1], "life": 1.3, "fade": 0.3, "ground": true})
					_dot({"p0": p, "col": CRACK[0], "life": 1.3, "fade": 0.3, "ground": true})
			for i in 8:  # 먼지 8점이 바깥으로 퍼진다
				var d := Vector2.from_angle(deg_to_rad(i * 45.0 + _h(e.n, 20 + i, -10, 10)))
				_dot({"p0": foot, "p1": foot + d * _h(e.n, 30 + i, 10, 18), "rise": _h(e.n, 40 + i, 1, 3), "col": DUST, "size": Vector2(2, 2), "life": 0.35, "fade": 0.15})
		"interrupt":  # 끊긴 예고 둘레에서 조각 12개가 바깥으로 흩어진다
			for i in 12:
				var d := Vector2.from_angle(deg_to_rad(i * 30.0 + _h(e.n, i, -5, 5)))
				var p: Vector2 = e.at + d * (e.radius + 1.0)
				_dot({"p0": p, "p1": p + d * _h(e.n, 20 + i, 6, 9), "col": TELL, "to": Color("efac28"), "size": Vector2(3, 3), "life": 0.3, "fade": 0.15})

# 부스러기 2점(S199): 좌우로 하나씩 4~7px 튀어 올랐다가 떨어진다
func _debris(at: Vector2, n: int) -> void:
	var p := at.round()
	for i in 2:
		_dot({"p0": p, "p1": p + Vector2((1 - 2 * i) * _h(n, 60 + i, 4, 7), _h(n, 62 + i, 2, 4)), "rise": _h(n, 64 + i, 3, 5), "col": DEBRIS, "size": Vector2(2, 2), "life": 0.35, "fade": 0.1})

# 효과 점 하나(I172). p1까지 _out으로 움직이며 가운데에서 rise만큼 솟는다. to가 있으면 그 색으로 바뀐다. 마지막 fade초에 흐려진다.
# wait초 뒤에 나타나고, fall이면 떨어지는 것처럼 점점 빨리 움직인다(S200 돌 조각)
func _dot(d: Dictionary) -> void:
	var p0: Vector2 = d.p0
	_dots.append({"p0": p0, "p1": d.get("p1", p0), "rise": float(d.get("rise", 0.0)), "t0": clock + d.get("wait", 0.0), "life": d.life, "fade": d.get("fade", 0.0),
		"col": d.col, "to": d.get("to", d.col), "size": d.get("size", Vector2.ONE), "ground": d.get("ground", false), "fall": d.get("fall", false)})

# 효과 점을 그린다(I172). 사각형만 써서 점이 몇 개든 배치 하나다. ground면 몸통 아래 바닥 점(균열)
func _fx_dots(ground: bool) -> void:
	for d in _dots:
		if d.ground != ground:
			continue
		var t: float = clock - d.t0
		if t < 0.0:  # 아직 나타나지 않았다(wait)
			continue
		var k := clampf(t / d.life, 0.0, 1.0)
		var p: Vector2 = d.p0 + (d.p1 - d.p0) * (k * k if d.fall else _out(k)) + Vector2(0, -d.rise * sin(PI * k))
		var a: float = 1.0 if t < d.life - d.fade else (d.life - t) / d.fade
		var col: Color = d.col
		draw_rect(Rect2(p - d.size / 2.0, d.size), Color(col.lerp(d.to, k), a))

# 사건 번호 n과 칸 k로 lo~hi 정수를 고른다. 모양의 무작위는 이것만 쓴다(시뮬레이션 난수는 저장되므로 쓰지 않는다, I170)
static func _h(n: int, k: int, lo: int, hi: int) -> int:
	return lo + posmod(hash(n * 7919 + k), hi - lo + 1)

# 넉백·끌어옴처럼 한 스텝에 8px 넘게 옮겨진 몸은 지난 자리에서 미끄러지게 그린다(S198). 보스 스킬에 맞은 것은 160px, 그 밖은 48px까지.
# 옮겨진 거리는 시뮬레이션 자리로 잰다(성벽 위 몸은 그리는 높이가 칸마다 바뀌어서 화면 자리로 재면 걷기도 튄다).
# 성벽을 오르내리거나 기어오르기를 마친 스텝(성벽 위·기어오르기 상태가 바뀜)은 STEP초에 걸쳐 미끄러진다(S198 2026-10-28).
# 다만 성곽 칸이 무너져 그 위에서 땅으로 내려온 몸은 DROP초에 걸쳐 내려온다(S200)
func _slide_scan() -> void:
	var far := {}
	var fell := {}  # 이번 프레임에 무너진 성곽 칸
	for e in events:
		if e.kind == "boss":
			for t in e.ref.hits:
				far[t.get_instance_id()] = true
		elif e.kind == "collapse":
			for c in battle.cells_in(battle.area_of(e.dst)):
				fell[c] = true
	var next := {}
	for x in battle.units + battle.enemies:
		var id: int = x.get_instance_id()
		var c := _center(x.pos)
		var state := [x.on_wall, x.get("climbed") != null and x.climbed > 0.0]
		var was = _last.get(id)  # [지난 그린 자리(미끄러짐 빼고), 지난 시뮬레이션 자리, 상태]
		if was != null and was[2] == state:
			var d: float = c.distance_to(was[1])
			if d > 8.0 and d <= (160.0 if far.has(id) else 48.0):
				var from: Vector2 = was[0]
				var s = _slides.get(id)
				if s != null:  # 미끄러지는 중에 또 옮겨지면 지금 그려진 자리에서 다시 미끄러진다
					from = s[0].lerp(was[0], _out(clampf((clock - s[1]) / s[2], 0.0, 1.0)))
				_slides[id] = [from, clock, clampf(d / SLIDE, 0.12, 0.3)]
		elif was != null and was[2][0] and not x.on_wall and fell.has(Vector2i(x.pos.round())):
			_slides[id] = [was[0], clock, DROP]
		elif was != null:  # 상태가 바뀐 스텝: 성벽 오르내리기·기어오르기 끝
			_slides[id] = [was[0], clock, STEP]
		elif x.get("split_from") != null:  # 막 갈라져 나온 적(S234 2026-10-29 변경): 죽은 자리에서 POP초에 걸쳐 튀어나온다(_look)
			_slides[id] = [_center(x.split_from), clock, POP]
			_pops[id] = clock
		next[id] = [_spot(x), c, state]
	_last = next
	for id in _slides.keys():
		if clock - _slides[id][1] >= _slides[id][2]:
			_slides.erase(id)
	for id in _pops.keys():
		if clock - _pops[id] >= POP:
			_pops.erase(id)

# 미끄러지는 몸을 그릴 자리와 시뮬레이션 자리의 차(S198)
func _slip(x) -> Vector2:
	var s = _slides.get(x.get_instance_id())
	if s == null:
		return Vector2.ZERO
	var p := _spot(x)
	return s[0].lerp(p, _out(clampf((clock - s[1]) / s[2], 0.0, 1.0))) - p

# 보스 스킬 예고(S194, S198 fx-4): 예고 원은 F24+ 빨강 밝은 1px과 바깥 어두운 1px 테이고, 안쪽 성긴 칠이 남은 시간만큼 가운데에서 차오른다.
# 발동하면(S198) 처음 FILL프레임은 예고 모양(원, 기관총은 부채꼴) 안을 예고색 60%로 채운다. 숨은 보스(S213)의 예고와 안 보이는 자리의 채움은 그리지 않는다
func _tells() -> void:
	for e in _foes:  # 울부짖음(S242): 알파 둘레 반경 고리를 옅게. 노래(S306, I252 ④): 노래하는 동안 하피 둘레 반경 고리를 옅은 음표 색으로
		if e.skills.has("howl") and battle.effect(e, "seal") == null:
			_pring(Vector2i(_center(e.pos).floor()), int(CELL * e.skills.howl.radius), 1, Color(PX.ash, 0.5))
		if battle.sings(e):
			_pring(Vector2i(_center(e.pos).floor()), int(CELL * e.song.radius), 1, Color(NOTE, 0.5))
	for e in tellers(_foes):
		if e.cast.id in UNSEEN_TELLS:  # 덮치기(S242)·던지기(S279)는 덮개 위 층에 그린다(_pounce_tells·_foe_tells)
			continue
		if not e.skills.has(e.cast.id):  # 일반 적 예고(S279): 폭파병 도화선
			_foe_tell(e)
			continue
		if e.cast.id == "mgun" or e.cast.id == "cleave":  # 전쟁 기계 기관총(S287)·대장 철퇴(S288)는 부채꼴
			_fan_tell(e)
			continue
		if e.cast.id == "charge":  # 대장 돌진(S288)은 직선
			_line_tell(e)
			continue
		_boss_tell(e)
	for f in _fills.filter(func(f): return battle.seen(f[0].at)):
		if f[0].has("arc"):
			var c := _center(f[0].at)
			_poly(PackedVector2Array([c]) + _fan_rim(c, CELL * f[0].range, f[0].dir, f[0].arc), Color(TELL, 0.6))
		elif f[0].has("from"):  # 대장 돌진(S288): 지나간 길
			_poly(_strip(_center(f[0].from), _center(f[0].at), CELL * f[0].width), Color(TELL, 0.6))
		else:
			_pdisc(Vector2i(_center(f[0].at).floor()), int(CELL * f[0].radius), Color(TELL, 0.6))

# 보스 원 예고(S194): 빨강 테와 차오르는 성긴 칠. 대장 폭탄(S288)은 자리(spots)마다 하나씩
func _boss_tell(e) -> void:
	var sk: Dictionary = e.skills[e.cast.id]
	var k: float = 1.0 if e.cast.get("air", false) else 1.0 - e.cast.left / sk.windup
	var r := int(CELL * sk.radius)
	for p in e.cast.get("spots", [e.cast.get("at", e.pos)]):  # 점프(S236)·착지(S288)는 착지 자리에, 뜬 동안은 가득 찬 채로(S198)
		var at := Vector2i(_center(p).floor())
		_pnoise(at, int(r * k), TELL, TELL_FILL)
		_edge(at, r, TELL, PX.maroon)

# 기관총 예고(S287)·대장 철퇴 예고(S288): 부채꼴(반경 range, 각 arc) 빨강 테와 차오르는 안쪽. 기관총 발사 동안은 테와 지금 총구 방향의 선(I223)
func _fan_tell(e) -> void:
	var sk: Dictionary = e.skills[e.cast.id]
	var c := _center(e.pos)
	var r: float = CELL * sk.range
	var rim := _fan_rim(c, r, e.cast.dir, sk.arc)
	var n := rim.size() - 1
	if e.cast.get("fire", false):
		var to := c + Vector2.from_angle(battle.muzzle(e.cast.dir, sk, sk.fire - e.cast.left)) * r
		_pline(Vector2i(c.floor()), Vector2i(to.floor()), TELL, 2)
	else:
		var k: float = clampf(1.0 - e.cast.left / sk.windup, 0.0, 1.0)
		if k > 0.05:
			var fill := PackedVector2Array([c])
			for p in rim:
				fill.append(c + (p - c) * k)
			_poly(fill, Color(TELL, 0.25 * _fade))
	_pline(Vector2i(c.floor()), Vector2i(rim[0].floor()), TELL)
	_pline(Vector2i(c.floor()), Vector2i(rim[n].floor()), TELL)
	for i in n:
		_pline(Vector2i(rim[i].floor()), Vector2i(rim[i + 1].floor()), TELL)

# 대장 돌진 예고(S288): 대장에서 멈출 자리(to, I230 ④)까지 폭 width 띠의 빨강 테와, 대장 쪽에서 남은 시간만큼 차오르는 안쪽
func _line_tell(e) -> void:
	var sk: Dictionary = e.skills[e.cast.id]
	var a := _center(e.pos)
	var b := _center(e.cast.to)
	var w: float = CELL * sk.width
	var k: float = clampf(1.0 - e.cast.left / sk.windup, 0.0, 1.0)
	if k > 0.05:
		_poly(_strip(a, a.lerp(b, k), w), Color(TELL, 0.25 * _fade))
	var rim := _strip(a, b, w)
	for i in 4:
		_pline(Vector2i(rim[i].floor()), Vector2i(rim[(i + 1) % 4].floor()), TELL)

# a에서 b까지(px) 폭 w px 띠의 네 모서리
func _strip(a: Vector2, b: Vector2, w: float) -> PackedVector2Array:
	var n := (b - a).normalized().orthogonal() * w / 2.0
	return PackedVector2Array([a + n, b + n, b - n, a - n])

# 부채꼴(가운데 c, 반경 r px, 가운데 방향 dir, 각 arc도)의 테 점 n + 1개
func _fan_rim(c: Vector2, r: float, dir: float, arc: float, n := 24) -> PackedVector2Array:
	var a := deg_to_rad(arc)
	var rim := PackedVector2Array()
	for i in n + 1:
		rim.append(c + Vector2.from_angle(dir - a / 2.0 + a * i / n) * r)
	return rim

# 덮치기 예고(S242): 알파에서 대상까지 곧은 선(폭 1)과 대상 발밑 표식이 차오른다. 성벽 위 대상의 올려 그린 발밑에 닿고,
# 숨은 알파의 예고도 보이게(S213 2026-10-28 변경) 성곽·어둠 덮개 위 층에 그린다
func _pounce_tells() -> void:
	for e in tellers(_foes):
		if e.cast.id != "pounce":
			continue
		var k: float = 1.0 if e.cast.get("air", false) else 1.0 - e.cast.left / e.skills.pounce.windup
		var to := Vector2i(_spot(e.cast.who).floor())
		_pline(Vector2i(_spot(e).floor()), to, TELL, 1)
		_pnoise(to, int(6 * k), TELL, TELL_FILL)
		_edge(to, 6, TELL, PX.maroon)

# 일반 적 예고(S279): 예고 원을 주황 1px 테로 BLINK초마다 켜고 끈다. 던지기(S282)는 예고 동안 돌이 투석기에서 원 가운데로 포물선을 그리며 난다.
# 불화살(I249 ②)은 예고 동안 고블린에서 구조물 칸 가운데로 낮은 포물선을 그리며 나는 화살이고, 촉에 불꽃이 붙어 있다.
# 박치기(S305, I251 ⑦)는 하피에서 대상 발밑까지 곧은 선과 발밑 고리다. 활강하는 동안은 그리지 않는다
func _foe_tell(e) -> void:
	if e.cast.id == "dive":
		if not e.cast.get("air", false) and int(clock / BLINK) % 2 == 0:
			var to := Vector2i(_spot(e.cast.who).floor())
			_pline(Vector2i(_spot(e).floor()), to, FOE_TELL)
			_pring(to, 5, 1, FOE_TELL)
		return
	var sk: Dictionary = battle.deed(e, e.cast.id)
	var at: Vector2 = e.cast.get("at", e.pos)
	if int(clock / BLINK) % 2 == 0:
		if e.cast.id == "drop":  # 투하 표식(S286): 투하 칸에 아래를 가리키는 화살표
			var c := Vector2i(_center(at).floor())
			_pline(c + Vector2i(0, -12), c + Vector2i(0, -2), FOE_TELL)
			_pline(c + Vector2i(-4, -6), c + Vector2i(0, -2), FOE_TELL)
			_pline(c + Vector2i(4, -6), c + Vector2i(0, -2), FOE_TELL)
		else:
			_pring(Vector2i(_center(at).floor()), int(CELL * (FLAME_RING if e.cast.id == "flame" else sk.radius)), 1, FOE_TELL)
	if e.cast.id == "throw":
		var k: float = clampf(1.0 - e.cast.left / sk.windup, 0.0, 1.0)
		var p: Vector2 = _center(e.pos).lerp(_center(at), k) + Vector2(0, -sin(k * PI) * CELL * 1.5)
		_pdisc(Vector2i(p.floor()), 2, PX.dark)
	elif e.cast.id == "flame":
		var k: float = clampf(1.0 - e.cast.left / sk.windup, 0.0, 1.0)
		var arc := CELL * 0.75
		var p: Vector2 = _center(e.pos).lerp(_center(at), k) + Vector2(0, -sin(k * PI) * arc)
		var d: Vector2 = (_center(at) - _center(e.pos) + Vector2(0, -cos(k * PI) * PI * arc)).normalized()  # 포물선의 접선: 나는 쪽을 향한다
		_pline(Vector2i((p - d * 6.0).round()), Vector2i(p.round()), Color("e8dcc0"))
		_spr("flame_s", int(clock * 10.0), Vector2i(p.round()), true)

# 사다리(S284)를 놓았거나 내리는 공성탑 → 자란 비율(0~1)
func _ladder_grow() -> Dictionary:
	var grow := {}
	for t in battle.ladders.values():
		grow[t] = 1.0
	for e in battle.enemies:
		if e.cast != null and e.cast.id == "ladder" and e.col != null:
			grow[e] = clampf(1.0 - e.cast.left / e.ladder.windup, 0.0, 1.0)
	return grow

# 공성탑 t의 사다리 하나(S172 2026-11-03 넷째 변경 ①): 성벽 열 가운데에 성벽 위 몸 높이로 올려, 열의 먼 끝에서 공성탑 그림 꼭대기까지
# 사다리 띠(LADDER)를 잇는다. 내리는 동안은 공성탑 쪽 끝에서 자란 길이만큼만 그린다. 몸 층(_bodies)에서 그 열 몸체 다음에 그린다
func _ladder(t, grow: float) -> void:
	var w := LADDER.get_width()
	var h := LADDER.get_height()
	var r: Rect2i = battle.area_of(t.col)
	var x := int((r.position.x + r.size.x / 2.0) * CELL - w / 2.0)
	var lift := int(roundf(3 + WALL_H - CELL / 2.0 + rise_at(battle, t.col.cell)))
	var top := r.position.y * CELL - lift
	var bottom := r.end.y * CELL - lift
	var south: bool = t.pos.y >= r.position.y
	if south:
		bottom = mini(bottom, int(_spot(t).y) - TOWER_TOP)
	if bottom <= top:
		return
	var reach := int(roundf((bottom - top) * grow))
	var lo := bottom - reach if south else top  # 그릴 줄 [lo, hi)
	var hi := bottom if south else top + reach
	var y := lo
	while y < hi:
		var sy := posmod(y - top, h)
		var n := mini(hi - y, h - sy)
		_region(LADDER, Rect2(x, y, w, n), Rect2(0, sy, w, n), Color.WHITE)
		y += n

# 숨어도 그리는 예고: 일반 적(S279)의 던지기·폭탄·투하·불화살과 전쟁 기계 대포(S287, S213 2026-11-03 변경)·대장 폭탄(S288)은 성곽·어둠 덮개 위 층에 그린다
func _foe_tells() -> void:
	for e in tellers(_foes):
		if e.cast.id in UNSEEN_TELLS and not e.skills.has(e.cast.id):
			_foe_tell(e)
		elif e.cast.id == "cannon" or e.cast.id == "bombs":  # 대장 폭탄(S288)도 대포처럼 숨어도 그린다
			_boss_tell(e)

# 보스: 스킬(S194)이 있는 적
func _boss(x) -> bool:
	return x != null and x.get("skills") is Dictionary and not x.skills.is_empty()

# 보스 x가 keep초 안에 남긴 가장 최근 스킬 흔적. 없으면 null
func _boss_trace(x, keep := SLAM_POSE):
	for i in range(battle.traces.size() - 1, -1, -1):
		var c = battle.traces[i]
		if c.hero == x and c.age < keep:
			return c
	return null

# 보스 그림이 이 영웅 그림의 25% 넘게 덮나(S198). 보스가 정렬상 나중(바닥선이 같거나 아래)일 때만이다
func _under_boss(h) -> bool:
	if h.on_wall or not ART.has(h.kind):
		return false
	var a: Dictionary = ART[h.kind]
	var r := Rect2(_spot(h) - Vector2(a.anchor[0], a.anchor[1]), Vector2(a.c, a.c))
	for e in battle.enemies:  # 정렬 키는 바닥선 y의 정수다(_bodies)
		if _boss(e) and ART.has(e.kind) and int(_center(e.pos).y) >= int(_center(h.pos).y):
			var b: Dictionary = ART[e.kind]
			var lk := _look(e)  # 줄이고 늘이고 들어 올린 그대로 잰다(S198 2026-10-27 둘째 변경)
			var at: Vector2 = _spot(e) - Vector2(0, lk[1]) - Vector2(b.anchor[0], b.anchor[1]) * lk[0]
			if r.intersection(Rect2(at, Vector2(b.c, b.c) * lk[0])).get_area() > 0.25 * r.get_area():
				return true
	return false

static func _feet() -> ImageTexture:
	var im := Image.create_empty(28, 6, false, Image.FORMAT_RGBA8)
	for t in 2:
		for y in 6:
			for x in 14:
				if pow((x + 0.5 - 7.0) / 7.0, 2) + pow((y + 0.5 - 3.0) / 3.0, 2) <= 1.0:
					im.set_pixel(14 * t + x, y, TEAM[t])
	return ImageTexture.create_from_image(im)

# 바닥(4.1b, 사용자 2026-10-20): 풀 바탕에 마을 칸의 꼭짓점 일부와 들판 길이 흙이다. 마을 아래 변의 흙은 들판 쪽으로 꼭짓점 0~2개만큼 불규칙하게 번진다.
# 칸마다 네 꼭짓점으로 16꼴 가운데 하나를 고르고, 변종(풀·흙 한 가지인 칸은 넷, 전환 칸은 셋) 가운데 하나를 고른다. 출현 지점에는 깃발을 얹는다.
# 들판(S201)은 길(_road) 꼭짓점도 흙이고, 빈 들판 칸에 그을음·구덩이·자갈·풀을 찍는다. 맵 아래 맵 밖 띠(I50)에는 숲 바닥을 깔고 마른 나무를 세운다.
# 마을(S169·S202 2026-10-26 둘째·셋째 변경)은 길 골격(_plan)의 꼭짓점과 성곽 줄 꼭짓점만 흙이다. 박석(_pave)을 깔고, 텃밭과
# 우물 밑 판석·자갈 마당을 찍고, 풀꽃 무더기(_clusters)를 모은 뒤 성 안 풀을 바랜다(_worn). 물 칸이 있는 판은 그 위에 수로·연못 덮개를 섞는다(S220)
static func bake_ground(b) -> ImageTexture:
	var src := GROUND_TILES.get_image()
	var deco := DECOR.get_image()
	var img := Image.create_empty(b.size.x * CELL, b.size.y * CELL + int(Camera.BOTTOM), false, src.get_format())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var spill := range(b.size.x + 1).map(func(_x): return rng.randi_range(0, 2))
	var vil: Rect2i = b.village
	var road := _road(b)
	var plan := _plan()
	var dirt := func(x: int, y: int) -> int:
		var inv: bool = vil.has_area() and x >= 0 and x <= b.size.x and y >= vil.position.y and y <= b.field_y - 1 + spill[x]  # 성곽(S217) 아래끝에서 들판 쪽으로 번진다
		return int(inv and (y >= vil.end.y or plan.dirt.has(Vector2i(x, y))) or road.has(Vector2i(x, y)))
	var vsrc := _village_tiles()
	for y in b.size.y:
		for x in b.size.x:
			var k: int = dirt.call(x, y) + 2 * dirt.call(x + 1, y) + 4 * dirt.call(x, y + 1) + 8 * dirt.call(x + 1, y + 1)
			var whole := k == 0 or k == 15
			var v := rng.randi_range(0, 3 if whole else 2)
			var at := Vector2i(k, 0)
			if v > 0:
				at = Vector2i(v - 1 + (3 if k == 15 else 0), 1) if whole else Vector2i(k, 1 + v)
			img.blit_rect(vsrc if vil.has_point(Vector2i(x, y)) else src, Rect2i(at * CELL, Vector2i(CELL, CELL)), Vector2i(x, y) * CELL)
	var open := _open_cells(b, road)
	var f := _field_scale(b)
	for i in roundi(9 * f):  # 그을음 48×32는 가운데 칸 둘레 3×3이 모두 빈 들판일 때만
		var c: Vector2i = open[rng.randi() % open.size()]
		if range(9).all(func(k): return open.has(c + Vector2i(k % 3 - 1, k / 3 - 1))):
			img.blend_rect(deco, Rect2i(48 * (i % 3), 16, 48, 32), c * CELL - Vector2i(16, 8))
	for k in [[5, 7], [7, 30], [9, 25]]:  # 구덩이 7·자갈 30·풀 25(40×22 들판 기준). 자갈·풀은 칸 안에서 조금씩 비낀다
		for i in roundi(k[1] * f):
			var off := Vector2i.ZERO if k[0] == 5 else Vector2i(rng.randi_range(-3, 3), rng.randi_range(-3, 3))
			img.blend_rect(deco, Rect2i(CELL * (k[0] + i % 2), 0, CELL, CELL), open[rng.randi() % open.size()] * CELL + off)
	var edge: int = b.size.y * CELL
	img.fill_rect(Rect2i(0, edge, img.get_width(), int(Camera.BOTTOM)), FOREST_FLOOR)
	for row in [14, 26, 40, 56]:  # 마른 나무 네 줄을 뒤에서 앞으로. row는 맵 아래끝에서 밑동까지(px), 그림의 밑동은 (24, 44)
		var x := rng.randf_range(-8.0, 4.0)
		while x < img.get_width():
			if rng.randf() < 0.6:
				img.blend_rect(deco, Rect2i(48 * rng.randi_range(0, 3), 48, 48, 48), Vector2i(int(x) - 24, edge + row + rng.randi_range(-3, 3) - 44))
			x += rng.randf_range(14.0, 24.0)
	if vil.has_area():
		_pave(b, img, rng, plan.pave)
		for c in plan.garden:  # 텃밭: 집 마당 텃밭 그림 두 가지를 번갈아
			img.blend_rect(deco, Rect2i(CELL * ((c.x + c.y) % 2), YARD_ROW, CELL, CELL), c * CELL)
		img.blend_rect(deco, Rect2i(CELL * 7, YARD_ROW, CELL, CELL), _well(b) * CELL + Vector2i(-2, 13))  # 우물 밑 판석
		for c in plan.slabs:  # 자갈 마당: 판석과 자갈 두 가지
			img.blend_rect(deco, Rect2i(CELL * 7, YARD_ROW, CELL, CELL), c * CELL + Vector2i(-2, 2))
		for c in plan.gravel:
			img.blend_rect(deco, Rect2i(CELL * (7 + c.x % 2), 0, CELL, CELL), c * CELL)
		_clusters(b, img, deco)
		_worn(b, img)
		_wall_shade(b, img)
	if not b.water.is_empty():
		var w := WATER.get_image()
		w.convert(img.get_format())
		img.blend_rect(w, Rect2i(Vector2i.ZERO, w.get_size()), WATER_AT)
	for c in (b.spawns if b.spawn_spread == 0 else []):  # 흩어져 나오는 스테이지는 깃발이 없다(I177). ponytail: 깃발도 바닥에 구워서 막 나온 적이 깃발 위에 그려진다. 거슬리면 깃발만 바닥선 정렬로 옮긴다
		img.blend_rect(src, Rect2i(Vector2i(6, 1) * CELL, Vector2i(CELL, CELL)), c * CELL)
	return ImageTexture.create_from_image(img)

# 들판 길(S201)의 흙 꼭짓점. 정문(거점 열)에서 맵 아래끝까지 두 꼭짓점 폭 큰길이고, 성곽 바로 앞 세 줄은 네 꼭짓점 폭이다.
# 다른 출현 지점에서는 한 꼭짓점 폭 오솔길이 여섯 줄 올라간 뒤, 옆으로 두 칸 갈 때마다 한 줄씩 올라 큰길에 닿는다
static func _road(b) -> Dictionary:
	var out := {}
	var gx: int = b.base.cell.x
	var top: int = b.field_y - 1  # 성곽 맨 아랫줄(S217)
	for y in range(top + 1, b.size.y + 1):
		for x in ([gx - 1, gx, gx + 1, gx + 2] if y <= top + 3 else [gx, gx + 1]):
			out[Vector2i(x, y)] = true
	for s in b.spawns:
		if s.x == gx:
			continue
		var dx := 1 if s.x < gx else -1
		var p := Vector2i(s.x if dx > 0 else s.x + 1, b.size.y)
		var start := p.x
		while p.y > b.size.y - 6:
			out[p] = true
			p.y -= 1
		while p.x != (gx if dx > 0 else gx + 1):
			out[p] = true
			p.x += dx
			out[p] = true
			if (p.x - start) % 2 == 0:
				p.y -= 1
				out[p] = true
	return out

# 장식을 놓을 빈 들판 칸(S201): 성곽 아래 둘째 줄부터 맨 아래 줄 전까지(맵 밖 마른 나무가 걸친다), 길 꼭짓점에 닿지 않고 출현 지점 둘레 1칸 밖이다
static func _open_cells(b, road: Dictionary) -> Array:
	var out := []
	for y in range(b.field_y + 1, b.size.y - 1):
		for x in b.size.x:
			var c := Vector2i(x, y)
			if not [c, c + Vector2i.RIGHT, c + Vector2i.DOWN, c + Vector2i.ONE].any(func(v): return road.has(v)) \
					and not b.spawns.any(func(s): return absi(s.x - x) <= 1 and absi(s.y - y) <= 1):
				out.append(c)
	return out

# 바닥 소품: 들판(S201)에는 바위 9·그루터기 6(40×22 들판 기준, 넓이에 비례)을 서로 한 칸 넘게 띄워 빈 들판 칸에, 마을(S202)에는 광장 모서리(_well)에 우물. [칸, decor.png 0행 열]
static func ground_props(b) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var open := _open_cells(b, _road(b))
	var out := []
	var f := _field_scale(b)
	for k in roundi(15 * f):
		for _try in 50:
			var c: Vector2i = open[rng.randi() % open.size()]
			if out.all(func(p): return absi(p[0].x - c.x) > 1 or absi(p[0].y - c.y) > 1):
				out.append([c, rng.randi_range(0, 2) if k < roundi(9 * f) else rng.randi_range(3, 4)])
				break
	if b.village.has_area():
		out.append([_well(b), 12])
	return out

# 들판 장식 수의 배율: 수는 40×22 들판 기준이고 넓이에 비례한다(S203). 맵이 커져도 같은 밀도로 보인다
static func _field_scale(b) -> float:
	return b.size.x * (b.size.y - b.field_y) / 880.0

# 우물 칸(S202 2026-10-26 둘째 변경): 거점에서 오른쪽 5칸·아래 3칸, 광장 오른쪽 아래 모서리
static func _well(b) -> Vector2i:
	return Folk.well(b)

# 마을 길 골격(S202·S169 2026-10-26 넷째 변경, 사방 성곽): 박석 칸·흙 꼭짓점·텃밭 칸·자갈 마당, 짓지 못하는 길 칸(S43 2026-10-26 둘째 변경).
# 북동 두 고리 사이 블록(44~49열, 13~19행)은 연못, 그 북쪽 45열(4~12행)은 수로의 물 칸(S220)이다. 수로가 성벽 안쪽 길·바깥 고리 길과 만나는 다리 칸은 길 칸이다.
# 표의 칸은 옛 마을 왼쪽 위 (3,3)·거점 (30,30) 기준이고, 돌려줄 때 PLAN_SHIFT만큼 옮긴다(S217 2026-11-03 변경: 성곽 다섯 줄, 마을은 (5,5)부터).
# ponytail: 자리는 지금 판(main.gd stage) 하나에 맞춘 칸 값이다. 판이 늘면 거점 칸 기준 상대값으로 옮긴다
const PLAN_SHIFT := Vector2i(2, 2)  # main.gd WALL_T − 3

static func _plan() -> Dictionary:
	var pave := {}
	var dirt := {}
	var roads := {}
	var spans := {27: [27, 33], 28: [25, 35], 29: [24, 36], 30: [24, 36], 31: [24, 36], 32: [24, 36], 33: [24, 36], 34: [25, 35],  # 거점 광장(시장)
		53: [28, 32], 54: [27, 33], 55: [26, 34], 56: [26, 34],  # 남문 안 공터
		3: [27, 33], 4: [27, 33], 5: [28, 32]}  # 북문 안 공터
	for y in spans:
		for x in range(spans[y][0], spans[y][1] + 1):
			pave[Vector2i(x, y)] = true
	for y in range(28, 33):  # 서문·동문 안 공터
		for x in [3, 4, 55, 56] + ([5, 54] if y >= 29 and y <= 31 else []):
			pave[Vector2i(x, y)] = true
	for y in range(35, 53):  # 남쪽 큰길: 박석-흙-박석
		pave[Vector2i(29, y)] = true
		pave[Vector2i(31, y)] = true
		roads[Vector2i(30, y)] = true
		_cell4(dirt, Vector2i(30, y))
	for l in [[30, 6, 30, 26], [6, 30, 23, 30], [37, 30, 53, 30]]:  # 북·서·동 큰길 칸
		for y in range(l[1], l[3] + 1):
			for x in range(l[0], l[2] + 1):
				roads[Vector2i(x, y)] = true
				_cell4(dirt, Vector2i(x, y))
	for c in pave:
		roads[c] = true
		_cell4(dirt, c)
	for l in [  # 흙 꼭짓점 선 [x0, y0, x1, y1]
			[19, 21, 29, 21], [32, 20, 41, 20], [18, 22, 18, 29], [17, 32, 17, 38],  # 안 고리
			[42, 21, 42, 29], [43, 32, 43, 38], [18, 39, 28, 39], [33, 38, 42, 38],
			[11, 12, 29, 12], [32, 11, 49, 11], [10, 13, 10, 29], [9, 32, 9, 47],  # 바깥 고리
			[50, 12, 50, 29], [51, 32, 51, 47], [10, 48, 28, 48], [33, 47, 50, 47],
			[24, 12, 24, 21], [42, 25, 50, 25], [38, 38, 38, 47], [9, 35, 17, 35],  # 두 고리 사이 골목
			[40, 4, 40, 11], [4, 20, 10, 20], [20, 48, 20, 55], [51, 41, 56, 41],  # 바깥 고리 → 성벽 안쪽 길
			[3, 3, 57, 4], [3, 3, 4, 57], [56, 3, 57, 57], [3, 55, 57, 56]]:  # 성벽 안쪽 길(사방)
		for y in range(l[1], l[3] + 1):
			for x in range(l[0], l[2] + 1):
				dirt[Vector2i(x, y)] = true
	var garden := []
	for y in [5, 6, 7, 8, 49, 50, 51, 52]:  # 네 모서리 텃밭
		for x in [5, 6, 7, 8, 51, 52, 53, 54]:
			garden.append(Vector2i(x, y))
	for g in [[13, 6, 18, 7, 14, 17], [12, 15, 16, 16, 13, 15], [11, 40, 15, 41, 12, 14], [45, 40, 49, 41, 46, 48], [22, 50, 26, 51, 23, 25]]:  # 빈 블록 텃밭 북서·서·남서·남동·남: 사각형 [x0, y0, x1, y1] 아래에 짧은 줄 [x0, x1]
		for y in range(g[1], g[3] + 1):
			for x in range(g[0], g[2] + 1):
				garden.append(Vector2i(x, y))
		for x in range(g[4], g[5] + 1):
			garden.append(Vector2i(x, g[3] + 1))
	for c in garden:
		_cell4(dirt, c)
	var slabs := [Vector2i(34, 7), Vector2i(35, 7), Vector2i(35, 8), Vector2i(39, 50), Vector2i(40, 51)]  # 자갈 마당(북·남동 블록)
	var gravel := [Vector2i(33, 8), Vector2i(36, 6), Vector2i(37, 8), Vector2i(41, 50), Vector2i(38, 51)]
	var water := {}
	for y in [4, 5, 6, 7, 8, 9, 12]:  # 수로. 3행은 박석 덮개, 10·11행은 나무 다리
		water[Vector2i(45, y)] = true
	for y in range(13, 20):  # 연못
		for x in range(44, 50):
			water[Vector2i(x, y)] = true
	for c in [Vector2i(45, 3), Vector2i(45, 10), Vector2i(45, 11)]:  # 다리 칸: 집이 다리를 막지 못하게 길 칸으로 둔다
		roads[c] = true
	return {"pave": _moved(pave), "dirt": _moved(dirt), "garden": _moved(garden), "slabs": _moved(slabs), "gravel": _moved(gravel), "roads": _moved(roads), "water": _moved(water)}

# 표의 칸·꼭짓점을 PLAN_SHIFT만큼 옮긴다(사전은 키, 배열은 원소)
static func _moved(d):
	if d is Dictionary:
		var o := {}
		for k in d:
			o[k + PLAN_SHIFT] = d[k]
		return o
	return d.map(func(c): return c + PLAN_SHIFT)

# 사방 성곽 안쪽 그늘(S219). 동·서 성벽은 마을 쪽에 남벽 앞면 벽돌색 벽면 띠 6px(원근 속임)과 그 바깥 땅 그늘 3px을, 통로처럼 앞면 높이(WALL_H)만큼 올린 자리에 그린다.
# 닫힌 문루 행은 그 높이만큼 더 올리고 띠 자리에 나무 문짝을 넣는다. 남벽 통로 뒤 모서리 위 마을 땅에는 4px 그늘을, 정문 문루 뒤(박석 길 위)에는 터널 입구 그늘을 깐다.
# 사방 성곽(마을이 맵 가장자리에서 떨어진 판)에서만 그린다
static func _wall_shade(b, img: Image) -> void:
	var v: Rect2i = b.village
	TUNNEL = []
	if v.position.x < 3:
		return
	var face := [Color("56607a"), Color("3a4357"), Color("151a26")]  # 앞면·줄눈·외곽(walls.png 남벽 앞면 색)
	for west in [true, false]:
		var xe: int = v.position.x * CELL if west else v.end.x * CELL - 1  # 띠가 시작하는 마을 쪽 경계 픽셀
		var d := 1 if west else -1
		for y in range(v.position.y * CELL - WALL_H, v.end.y * CELL - WALL_H):
			var gate: bool = y >= (b.base.cell.y - 1) * CELL - WALL_H - SIDE_GATE_RISE and y < (b.base.cell.y + 2) * CELL - WALL_H  # 문루 행(거점 줄 ±1)
			for k in 6:
				var c: Color = face[1] if y % 4 == 0 or (k + (y / 4 % 2) * 3) % 6 == 0 else face[0]
				if k == 5:
					c = face[2]
				if gate and k >= 1 and k <= 4 and y >= (b.base.cell.y + 2) * CELL - WALL_H - 30:  # 문짝: 나무 2px + 테두리
					c = Color("6b3f22") if k == 2 or k == 3 else face[2]
				img.set_pixel(xe + d * k, y, c)
			for k in 3:
				var x := xe + d * (6 + k)
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.3 * (1.0 - k / 3.0)))
	var y1 := v.end.y * CELL - WALL_H  # 남벽 통로 뒤 모서리
	for x in range(v.position.x * CELL, v.end.x * CELL):
		for k in 4:
			img.set_pixel(x, y1 - 1 - k, img.get_pixel(x, y1 - 1 - k).darkened(0.26 * (1.0 - k / 4.0)))
	var gx: int = b.base.cell.x * CELL + CELL / 2  # 정문 문루 가운데(거점 열)
	var gy := y1 - GATE_RISE  # 문루 뒤 모서리
	TUNNEL = [ImageTexture.create_from_image(img.get_region(Rect2i(gx - 20, gy - 10, 41, 10))), Vector2(gx - 20, gy - 10)]
	for y in range(gy - 10, gy):
		for x in range(gx - 20, gx + 21):
			var t := float(gy - y) / 10.0 + pow(float(x - gx) / 20.0, 2.0)  # 아래가 넓은 반타원
			if t < 1.0:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.45 * (1.0 - t)))

# 정문 문루(거점 열의 남쪽 문루)가 잔해(I88)면 터널 입구 그늘을 덮을 [그늘 없는 바닥 조각, 자리](S219 2026-10-28), 아니면 []
func tunnel_patch() -> Array:
	var c: Vector2i = battle.base.cell
	var gone: bool = battle.rubble.values().any(func(k): return k.kind == "gate" and k.cell.y > c.y and k.cell.x <= c.x and c.x < k.cell.x + k.size.x)
	return TUNNEL if gone else []

# 시험 스테이지의 길 칸(S43 2026-10-26 변경). main.gd stage가 읽는다
static func roads() -> Dictionary:
	return _plan().roads

# 시험 스테이지의 물 칸(S220). main.gd stage가 읽는다
static func water() -> Dictionary:
	return _plan().water

# 시험 스테이지의 텃밭 칸(I182 ⑥). main.gd stage가 읽는다
static func garden() -> Array:
	return _plan().garden

# 시험 스테이지의 자갈 마당 칸(I182 ⑥). main.gd stage가 읽는다
static func yards() -> Array:
	var plan := _plan()
	return plan.slabs + plan.gravel

# 칸 c의 네 꼭짓점을 d에 넣는다
static func _cell4(d: Dictionary, c: Vector2i) -> void:
	for k in 4:
		d[c + Vector2i(k % 2, k / 2)] = true

static var _vtiles: Image
# 마을 칸 타일: 흙 타일의 어두운 점 2/3를 흙색으로 지운 사본(S202). 픽셀마다 지우면 큰 마을(S203)에서 느려 타일에서 한 번 지운다. 터(bake_yard)도 이 흙을 쓴다
static func _village_tiles() -> Image:
	if _vtiles == null:
		_vtiles = GROUND_TILES.get_image()
		var vrng := RandomNumberGenerator.new()
		vrng.seed = 3
		for y in _vtiles.get_height():
			for x in _vtiles.get_width():
				if _vtiles.get_pixel(x, y).is_equal_approx(Color("392a1c")) and vrng.randf() < 0.67:
					_vtiles.set_pixel(x, y, Color("684c3c"))
	return _vtiles

# 풀꽃 무더기(S202 2026-10-26 둘째·넷째 변경): 작은 풀·자갈·풀꽃을 성벽 밑 띠·광장 양 가장자리·갈림목·우물 둘레에 무더기로 모으고 넓은 안쪽은 비운다
static func _clusters(b, img: Image, deco: Image) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 11
	var y1: int = b.village.end.y * CELL
	var cx: int = b.base.cell.x * CELL + CELL / 2
	var spots := []
	var x := r.randi_range(1, 4)
	while x < b.size.x - 1:  # 남벽 밑 띠: 성벽 안쪽 길 위끝 둘레. 정문 안 공터와 모서리 텃밭은 비운다
		if absi(x - b.base.cell.x) > 6 and x > 5 + PLAN_SHIFT.x and x < 54 + PLAN_SHIFT.x:
			spots.append(Vector2(x * CELL + 8, r.randf_range(y1 - 76, y1 - 60)))
		x += r.randi_range(5, 9)
	for side in [-1, 1]:  # 광장 양 가장자리: 광장 반폭 104px(6.5칸)보다 8~18px 바깥
		for y in [28 + PLAN_SHIFT.y, 33 + PLAN_SHIFT.y]:
			spots.append(Vector2(cx + side * r.randf_range(112, 122), y * CELL + r.randf_range(-6, 6)))
	for c in [Vector2i(24, 12), Vector2i(42, 25), Vector2i(38, 38), Vector2i(9, 35), Vector2i(18, 22), Vector2i(43, 33), Vector2i(10, 28), Vector2i(50, 32), Vector2i(40, 5), Vector2i(20, 54)]:  # 고리 길·골목 갈림목(_plan)
		spots.append(Vector2((c + PLAN_SHIFT) * CELL) + Vector2(12, 4))
	spots.append(Vector2(_well(b) * CELL) + Vector2(18, 4))
	spots.append(Vector2(_well(b) * CELL) + Vector2(-4, 10))
	for s in spots:
		for k in r.randi_range(3, 5):  # 한 무더기 3~5포기. 70%는 작은 풀·자갈, 나머지는 풀꽃
			var c := r.randi_range(7, 10) if r.randf() < 0.7 else 11
			img.blend_rect(deco, Rect2i(CELL * c, 0, CELL, CELL), Vector2i(s) - Vector2i(8, 8) + Vector2i(r.randi_range(-7, 7), r.randi_range(-4, 4)))

# 2026-10-26
# [동작] 성 안 풀(성곽 위 세 줄 위)에서 잡음 가중치 w = clamp(잡음 × 2, 0, 1)인 자리의 풀 바탕 픽셀을 w × 14%는 짙은 갈색, w × 8%는 흙색으로 바꾼다
# [의도] 성 안 풀을 덩어리진 자리만 바래게 해 성 밖 들판 풀과 가른다
# [이유] Gemini가 시안 B에서 «성 안팎 풀색이 같다»를 고칠 점으로 꼽았고, 고르게 흩은 첫 B′는 확대하면 자글자글해서 덩어리로 바꿨다.
#        사용자가 이 B′를 골랐다(insights/2026-10-25_village_research_mockup.md)
static func _worn(b, img: Image) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = 5
	nz.frequency = 0.04
	var r := RandomNumberGenerator.new()
	r.seed = 21
	var g := Color("2d472d")
	for y in range(b.village.position.y * CELL, (b.village.end.y - 3) * CELL):
		for x in range(b.village.position.x * CELL, b.village.end.x * CELL):
			if img.get_pixel(x, y).is_equal_approx(g):
				var w := clampf(nz.get_noise_2d(x, y) * 2.0, 0.0, 1.0)
				var k := r.randf()
				if k < 0.14 * w:
					img.set_pixel(x, y, Color("392a1c"))
				elif k < 0.22 * w:
					img.set_pixel(x, y, Color("684c3c"))

# 시설 터(S215): 차지 칸(S216) 가운데보다 3px 아래를 중심으로 한 타원 얼룩에 흙 타일 무늬를 깐다. 가장자리는 칸마다 씨앗이 다른 잡음으로 흔들고,
# 거리 0.85~1.15 띠는 바깥으로 갈수록 성기게 풀과 섞는다. 외곽선은 없다. 바닥(under)의 박석 위·물 칸(S220)과 성벽 그늘 줄부터 아래에는 깔지 않는다. [그림, 맵 px 왼쪽 위]
static func bake_yard(b, s, under: Image) -> Array:
	var r: Rect2i = b.area_of(s)
	var center := (Vector2(r.position) + Vector2(r.size) / 2.0) * CELL + Vector2(0, 3)
	var radius := yard_radius(s)
	var blobs := [[center, radius]]
	if s.kind == "archery":
		blobs.append([center + Vector2(0, radius.y + 10), Vector2(8, 22)])  # 터 아래끝에서 아래로 난 밟힌 줄
	var box := Rect2i(Vector2i(center), Vector2i.ZERO)
	for bl in blobs:
		box = box.merge(Rect2i(Vector2i(bl[0] - bl[1]) - Vector2i(8, 8), Vector2i(bl[1] * 2) + Vector2i(17, 17)))
	box = box.intersection(Rect2i(0, 0, under.get_width(), b.village.end.y * CELL - 27))
	var nz := FastNoiseLite.new()
	nz.seed = s.cell.x * 31 + s.cell.y
	nz.frequency = 0.1
	var tile := _village_tiles().get_region(Rect2i(Vector2i(15, 0) * CELL, Vector2i(CELL, CELL)))  # 흙 한 가지 칸(16꼴의 15)
	var img := Image.create_empty(box.size.x, box.size.y, false, Image.FORMAT_RGBA8)
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			if under.get_pixel(x, y).is_equal_approx(PAVE) or b.water.has(Vector2i(x, y) / CELL):
				continue
			var h := fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)
			for bl in blobs:
				var d: float = pow((x + 0.5 - bl[0].x) / bl[1].x, 2) + pow((y + 0.5 - bl[0].y) / bl[1].y, 2) - nz.get_noise_2d(x, y) * 0.5
				if d < 0.85 or d < 1.15 and h < (1.15 - d) / 0.3:
					img.set_pixel(x - box.position.x, y - box.position.y, tile.get_pixel(posmod(x, CELL), posmod(y, CELL)))
					break
	return [ImageTexture.create_from_image(img), Vector2(box.position)]

# 놓기 미리보기(S216): [커서 칸을 구조물의 칸으로 한 차지 칸, 지을 수 있나]. 실시간 단계에는 닿는 공병(I125)도 본다(I138 2026-10-28)
static func ghost(b, kind: String, cell: Vector2i) -> Array:
	return [b.area_at(cell, b.STRUCTURE_KINDS[kind].size), b.can_build(kind, cell) and (not b.crewed() or b.engineer_gap([cell]) == "")]

# 터 반지름(S215 2026-10-26 변경): (가로 칸 × 8 + 18 + 종류 보탬, 깊이 칸 × 8 + 12)px
static func yard_radius(s) -> Vector2:
	return Vector2(s.size.x * 8 + 18 + YARDS[s.kind], s.size.y * 8 + 12)

# 다 지은 시설의 마당 소품(S215): [decor.png 3행 열, 맵 px 왼쪽 위]. 짓는 중이면 없다
static func yard_props(s) -> Array:
	if not s.complete or not YARD_PROPS.has(s.kind):
		return []
	var v: Array = YARD_PROPS[s.kind]
	return v[(s.cell.x + s.cell.y) % v.size()].map(func(p): return [p[0], Vector2(s.cell * CELL) + p[1]])

# 마을 박석(S202 2026-10-26 둘째 변경): 박석 칸(_plan의 광장·남쪽 큰길·정문 안 공터)에만 깐다. 성벽 그림 위끝(성곽 줄 위끝에서 27px 위)
# 아래는 성벽 그림이 덮는다. 성벽 그림 바로 위 2px은 흙 1px과 그늘 1px로 남겨 성벽과 가른다.
# 2026-10-23
# [동작] 9×7px 격자를 흔든 점마다 박석 하나(보로노이). 점이 박석 칸 안인 돌만 통째로 깔고, 줄눈은 칠하지 않아 흙이 비친다
# [의도] 돌길·광장이 성벽의 일부나 높은 기단으로 읽히지 않게 한다
# [이유] Gemini가 5×4px 엇갈린 벽돌과 밝은 돌을 성벽과 같은 쌓은 벽돌로 읽었고, 사용자가 시안 «조합 1a + 2 + 3a»를 골랐다(insights/2026-10-23_village_decor.md)
static func _pave(b, img: Image, rng: RandomNumberGenerator, cells: Dictionary) -> void:
	var w := img.get_width()
	var y1: int = b.village.end.y * CELL
	var rows := y1 - 27  # 줄눈 판정에 아래 한 줄이 필요해서, 칠할 줄보다 한 줄 더 돌 번호를 매긴다
	var near := {}  # 박석 칸과 그 둘레 한 칸만 센다. 점이 칸 밖인 돌은 어차피 깔지 않는다
	for c in cells:
		for k in 9:
			near[c + Vector2i(k % 3 - 1, k / 3 - 1)] = true
	var gw := w / 9 + 3
	var gh := rows / 7 + 3
	var pts := []
	for j in gh:
		for i in gw:
			pts.append(Vector2(i * 9 + rng.randf_range(1.5, 7.5), j * 7 + rng.randf_range(1.0, 6.0)))
	var id := PackedInt32Array()
	id.resize(w * rows)
	for y in rows:
		for x in w:
			if not near.has(Vector2i(x / CELL, y / CELL)):
				continue
			var best := INF
			for j in range(maxi(y / 7 - 1, 0), mini(y / 7 + 2, gh)):
				for i in range(maxi(x / 9 - 1, 0), mini(x / 9 + 2, gw)):
					var d: float = pts[j * gw + i].distance_squared_to(Vector2(x + 0.5, y + 0.5))
					if d < best:
						best = d
						id[y * w + x] = j * gw + i
	for y in rows - 1:
		for x in w:
			if not near.has(Vector2i(x / CELL, y / CELL)):
				continue
			var k := id[y * w + x]
			var p: Vector2 = pts[k]
			if cells.has(Vector2i(int(p.x) / CELL, int(p.y) / CELL)) and (x == w - 1 or id[y * w + x + 1] == k) and id[(y + 1) * w + x] == k:
				img.set_pixel(x, y, PAVE)
	img.fill_rect(Rect2i(0, y1 - 27, w, 1), Color("392a1c"))

# 화면 방향 v(y가 아래)의 시트 행: S, SE, E, NE, N, NW, W, SW(tools/art/render.py DIRS)
static func _dir_of(v: Vector2) -> int:
	return posmod(roundi((90.0 - rad_to_deg(v.angle())) / 45.0), 8)

# 조준 중(S147): 영웅 둘레에 시전 사거리(엷은 고리. 점선인 오라 원과 갈린다), 커서에 범위(지점·범위), 영웅에서 커서 쪽으로 길이(방향)나 부채꼴(아이아스 Q), 에너지 성벽이 설 칸.
# 덮개 위 층(_cv)에 아트 px로 그린다(I101 fx-4). 이펙트가 아니라 조작 표시라 색은 흰색이다
func _aim_preview() -> void:
	if controls.aiming == "" or not controls.aim_hero:
		return
	var h = controls.aim_hero
	var sk: Dictionary = h.get(controls.aiming)
	var at: Vector2 = controls.mouse / CELL - Vector2(0.5, 0.5)
	var o := Vector2i(_center(h.pos).floor())
	_pring(o, int(CELL * battle.CAST_RANGE), 1, Color(1, 1, 1, 0.3))
	match sk.aim:
		"dir":
			var d: Vector2 = battle._toward(h, at)
			if sk.has("arc"):  # 아이아스 Q: 반경 radius·각도 arc의 부채꼴(S151)
				var half := deg_to_rad(sk.arc) / 2.0
				_parc(o, int(CELL * sk.radius), 1, d.angle() - half, d.angle() + half, Color.WHITE)
				for side in [-half, half]:
					_pline(o, o + Vector2i((d.rotated(side) * CELL * sk.radius).round()), Color.WHITE)
			else:
				_pline(o, o + Vector2i((d * CELL * sk.get("radius", 40.0)).round()), Color.WHITE)  # 실비아 Q는 맵 끝까지
		"point":
			if sk.id == "bulwark":
				for wc in wall_preview(battle, h, at):  # 칸 안쪽 1px 테두리 네 변
					var q: Vector2i = wc * CELL
					for e in [[Vector2i.ZERO, Vector2i(CELL, 1)], [Vector2i(0, CELL - 1), Vector2i(CELL, 1)], [Vector2i.ZERO, Vector2i(1, CELL)], [Vector2i(CELL - 1, 0), Vector2i(1, CELL)]]:
						_px(q + e[0], Color.WHITE, e[1])
			elif sk.id == "wind_lens":  # 렌즈 관문(S153): 지점을 가운데로 영웅 → 지점에 수직인 선. 깔 때(battle.lens_gate)와 같은 선이다
				var ends: Array = battle.lens_gate(h, at, sk.length * battle.grow_of(h, controls.aiming))
				_pline(Vector2i(_center(ends[0]).floor()), Vector2i(_center(ends[1]).floor()), Color.WHITE)
			elif sk.id == "meteor_swarm":  # 운석이 떨어질 자리마다 원(S268)
				for p in battle.meteor_spots(h, at):
					_pring(Vector2i(_center(p).floor()), aim_r(battle, h, controls.aiming), 1, Color.WHITE)
			else:
				_pring(Vector2i(_center(at).floor()), aim_r(battle, h, controls.aiming), 1, Color.WHITE)
		_:
			_pring(Vector2i(_center(at).floor()), int(CELL * 0.7), 1, Color.WHITE)

# 절대 방어선(아이아스 R) 조준 미리보기 칸(S256): 지점 칸을 가운데로 영웅 → 지점에 수직인 length칸 줄. 세울 때(_cast_bulwark)와 같은 줄이다
static func wall_preview(b, h, at: Vector2) -> Array:
	var d: Vector2 = b._toward(h, at)
	var side := Vector2i(0, 1) if absf(d.x) > absf(d.y) else Vector2i(1, 0)
	var n := int(h.r.length)
	var out := []
	for i in range(-(n / 2), n - n / 2):
		out.append(Vector2i(at.round()) + side * i)
	return out

# 지점 스킬 조준 원 반지름(아트 px, S251): 스킬 반경 × 과부하 배율(battle.grow_of). 반경이 없으면 0.5칸
static func aim_r(b, h, slot: String) -> int:
	return int(CELL * h.get(slot).get("radius", 0.5) * b.grow_of(h, slot))

# at: 칸 단위 위치(칸 (x,y)의 중심 = Vector2(x,y)). 그 칸 위쪽 가운데에 그린다. tiers면 구조물·성곽·거점 막대의 3단 색(S199)
func _hp_bar(at: Vector2, b, size := Vector2(CELL, 2), tiers := false) -> void:
	_bar_in(_bar_over(at, size), b, tiers)

# 칸 단위 위치 at 위쪽 가운데의 막대 사각형(맵 px)
static func _bar_over(at: Vector2, size: Vector2) -> Rect2:
	return Rect2(at * CELL + Vector2((CELL - size.x) / 2, -2 - size.y), size)

# 막대 사각형 bar(맵 px)에 검은 바탕과 체력만큼의 색을 그린다
func _bar_in(bar: Rect2, b, tiers := false) -> void:
	_cv.draw_rect(bar, Color.BLACK)
	_cv.draw_rect(Rect2(bar.position, Vector2(bar.size.x * b.hp / b.max_hp, bar.size.y)), bar_color(b, tiers))

# 체력 막대 색(S73, S199): 구조물·성곽·거점(tiers)은 50% 밑 노랑·25% 밑 빨강, 영웅·용병·적·보스는 늘 초록
static func bar_color(b, tiers: bool) -> Color:
	if not tiers:
		return Color.GREEN
	var r: float = b.hp / b.max_hp
	return BAR_TIERS[0] if r < 0.25 else BAR_TIERS[1] if r < 0.5 else BAR_TIERS[2]

# 금 구운 아틀라스(S199, I172): 원본 아래에 금 단계 1~3 × 무늬 0·1 사본 여섯을 그 차례로 잇는다(crack_y가 고르는 행).
# pieces는 금을 긋는 원본 조각 사각형이다. 조각마다 금 i(0~2)는 무늬와 i만으로 정해, 단계가 오르면 앞 금은 그대로 두고 한 줄을 더한다
static func crack_atlas(tex: Texture2D, pieces: Array) -> ImageTexture:
	var src := tex.get_image()
	src.convert(Image.FORMAT_RGBA8)
	var h := src.get_height()
	var img := Image.create_empty(src.get_width(), h * 7, false, Image.FORMAT_RGBA8)
	for v in 7:
		img.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(0, h * v))
	for r in pieces:
		var spans := {}  # 불투명한 열 x → [맨 위 y, 맨 아래 y]. 6px보다 짧은 열은 뺀다
		for x in range(r.position.x + 1, r.end.x - 2):
			var top: int = r.position.y
			while top < r.end.y and src.get_pixel(x, top).a < 0.5:
				top += 1
			var bot: int = r.end.y - 1
			while bot > top and src.get_pixel(x, bot).a < 0.5:
				bot -= 1
			if bot - top >= 6:
				spans[x] = [top, bot]
		if spans.is_empty():
			continue
		var xs: Array = spans.keys()
		for v in 6:
			var n: int = r.position.x * 977 + r.position.y * 31 + (v % 2) * 7919
			for i in v / 2 + 1:  # 금 i는 불투명한 열의 3할·7할·5할 언저리에서, 그 열 아래쪽 절반에서 아래로 7~11px
				var x: int = xs[clampi(int(xs.size() * [0.3, 0.7, 0.5][i]) + _h(n, i, -1, 1), 0, xs.size() - 1)]
				var y: int = spans[x][0] + (spans[x][1] - spans[x][0]) * _h(n, 10 + i, 50, 70) / 100
				for j in _h(n, 20 + i, 7, 11):
					if j > 0:
						x = clampi(x + _h(n, 30 + 16 * i + j, -1, 1), r.position.x, r.end.x - 2)
					if y + j >= r.end.y:
						break
					var c := src.get_pixel(x, y + j)
					if c.a >= 0.5:  # 어두운 1px 줄과 그 오른쪽 밝은 1px 가장자리. 그림 밖(투명)에는 긋지 않는다
						img.set_pixel(x, y + j + h * (v + 1), c.darkened(0.6))
						var e := src.get_pixel(x + 1, y + j)
						if e.a >= 0.5:
							img.set_pixel(x + 1, y + j + h * (v + 1), e.lightened(0.35))
	return ImageTexture.create_from_image(img)

# 금을 긋는 성곽 조각(S199): 단계 1~3의 앞층 행(바깥 벽면)에서 조각 열마다. 모서리 탑은 칸마다 잘라 그리므로 16px씩
static func _wall_pieces() -> Array:
	var out := []
	for name in WALL_COLS:
		var c: Array = WALL_COLS[name]
		var w: int = CELL if name.begins_with("sc_") or name.begins_with("nc_") else c[1]
		for x in range(c[0], c[0] + c[1], w):
			for row in [1, 3, 5]:
				out.append(Rect2i(x, row * WALL_PIECE_H, w, WALL_PIECE_H))
	return out

# 거점 망루 그림의 불투명 사각형(맵 px). 이 안을 누르면 거점을 고른다(S100)
static func keep_rect(b) -> Rect2:
	var body: Rect2 = KEEP_BODY[clampi(b.village_level, 1, 2) - 1]
	return Rect2(Vector2(b.base.cell * CELL) + KEEP_AT + body.position, body.size)

# 머리 위 체력바 자리(칸, 보스 막대가 쓴다): 성벽 위와 미끄러짐을 따른다. 보스(I185) 그림은 기본 적보다 키가 커서 막대를 그만큼 올린다(머리 위).
# 줄어들고 늘고 뜬 보스 그림(S198 2026-10-27 둘째 변경)은 그린 그림의 머리를 따른다
func hp_bar_at(u) -> Vector2:
	var head := 0.0
	if u.get("boss") and ART.has(u.kind):
		var lk := _look(u)
		head = (ART[u.kind].anchor[1] * lk[0].y + lk[1] - ART.basic.anchor[1]) / CELL
	return u.pos - Vector2(0, _lift(u) / CELL + head) + _slip(u) / CELL

# 유닛·적 체력바를 그리는 사각형(맵 px). 보스와 성벽 위는 머리 위(hp_bar_at), 나머지는 발 자리 아래 HP_BAR_DROP px에 가운데 맞춤(S276)
# 성벽 위가 머리 위인 까닭: 발 아래면 그 성곽 칸 막대(I59·S173)와 1px 차이로 겹쳐 덮는다
func hp_bar_rect(u, size: Vector2) -> Rect2:
	if u.get("boss") or u.on_wall:
		return _bar_over(hp_bar_at(u), size)
	return Rect2(_foot(u) + Vector2(-size.x / 2, HP_BAR_DROP), size)

# 유닛·적 체력바 크기(S73). 보스(I185 boss 칸)는 V 표시와 상관없이 늘 크게, 체력 HERO_LOW 밑 영웅도 V와 상관없이, 나머지는 켰을 때만. 그리지 않으면 Vector2.ZERO
static func hp_bar_size(u, show_all: bool) -> Vector2:
	if u.get("boss"):
		return Vector2(24, 3)
	return Vector2(CELL, 2) if show_all or (u.get("is_hero") == true and u.hp < HERO_LOW * u.max_hp) else Vector2.ZERO

# 주민(S223·S225~S229)의 일과·자리는 판(src/sim/folk.gd)이 구하고, 화면은 판의 people을 그린다
const PROPS := preload("res://art/tiles/props.png")  # 일터 소품(S224, tools/art/props.py)
const PROP_ART := {"mill": Rect2(0, 0, 24, 28), "wheel": Rect2(24, 0, 16, 16), "oven": Rect2(88, 0, 16, 16), "stall0": Rect2(104, 0, 16, 16),
	"stall1": Rect2(120, 0, 16, 16), "inn": Rect2(136, 0, 10, 12)}  # props.png 안 자리. 바퀴는 오른쪽으로 네 장
const PROP_AT := {"mill": Vector2(-4, -12), "wheel": Vector2.ZERO, "oven": Vector2.ZERO, "stall0": Vector2(0, -4), "stall1": Vector2(0, -4),
	"inn": Vector2(26, -10)}  # 소품 칸(여관은 집의 칸) 왼쪽 위에서 그림 왼쪽 위까지(px). 방앗간은 수로 칸 (45,5) 위로 솟고, 바퀴는 그 아래 (45,6) 물 위다
const PROP_WHEEL_FPS := 4.0  # 물레방아 바퀴 네 장을 넘기는 빠르기(장/초)
const LAMP := Vector2(3, -6)  # 야경꾼 발밑에서 등불까지(px)

# 평가가 부르는 주민 일과(Folk 그대로): t초 때 자리 · 하는 일 · 주민 차례 · 고정 소품
static func residents(b, t: float) -> Array:
	return Folk.residents(b, t)

static func chores(b, t: float) -> Array:
	return Folk.chores(b, t)

static func folk_of(b) -> Array:
	return Folk.folk_of(b)

static func props(b) -> Dictionary:
	return Folk.props(b)

# 유닛·적은 pos, 구조물·성곽·거점은 cell로 자리를 갖는다
func _pos_of(x) -> Vector2:
	var p = x.get("pos")
	return p if p != null else Vector2(x.cell)

func _center(p: Vector2) -> Vector2:
	return p * CELL + Vector2(CELL, CELL) / 2

func _rect(c: Vector2i) -> Rect2:
	return Rect2(Vector2(c) * CELL, Vector2(CELL, CELL))

# 오라 반경 원(S113). 크로노스는 원 안쪽에 시계 문자판 눈금 12개를 더 그린다(S160). 컨셉 아트의 광륜(등 뒤 천문시계 고리)은
# 24px 스프라이트에서 뺐고 여기서 이펙트로 살린다(I152). 눈금은 크로노스 색(금)이고 12·3·6·9시가 길다. 불투명도 0.5·짧은 눈금 3px는
# 들판 위에서 흐리고 대각 눈금이 점으로 보였다. 원은 다른 영웅과 같은 하늘색이다. 금색으로 하면 반경이 같은 E 결계(S158 황금의 율법)와 테두리가 겹친다
# 2026-10-27: 원은 아트 px 점선(3px 간격, F24+ 하늘색 계열 a4aec2), 눈금은 아트 px 선(F24+ 금 efac28)이다(4.1s, S113 변경)
func _aura_ring(h) -> void:
	var c := Vector2i(_center(h.pos).floor())
	var r := int(CELL * h.aura.radius)
	_pring(c, r, 1, PX.ice1, 3)
	if h.kind != "chronos":
		return
	for k in 12:  # k = 0이 3시. 화면 y가 아래라 k가 늘면 시계 방향으로 돈다
		var d := Vector2.from_angle(k * TAU / 12)
		_pline(c + Vector2i((d * r).round()), c + Vector2i((d * (r - (7.0 if k % 3 == 0 else 4.0))).round()), PX.gold)
