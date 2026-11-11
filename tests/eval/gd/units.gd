extends "res://tests/eval/gd/lib.gd"
# WBS 3.1 적 5종·마법 타워(S11·S106~S111·I43·I76~I78·I81). lib.gd·wall.gd 머리의 계약에 더하는 API:
#   적 kind "fast"(빠름, 성벽 등반) · "armored"(장갑) · "flying"(비행) · "boss"(보스)
#   ENEMY_KINDS[kind] 키: armor(방어력, S149) · flying(비행) · climb(성벽 오르는 시간, 초. 0이면 오르지 않는다)
#   구조물 kind "magic"(마법 타워, 장갑 무시) · 단축키: - 마법 타워 놓기
#   BattleView(res://src/ui/battle_view.gd).ENEMY_COLORS — 적 kind → 색
#   적 kind "shieldbearer"(방패 고블린, S301) · "fire_archer"(불화살 고블린, S302). ENEMY_KINDS 키: guard(방패 내구도) · escort({kind, count}, 호위) · flame(불화살 {windup, cd, hit, dps, time, spread}) · range(I216)
#   적 kind "feather_harpy"·"dive_harpy"·"song_harpy"(하피 셋, S304~S306). ENEMY_KINDS 키: feather({range, speed}) · dive({windup, air, cd, damage, radius, push, stun, shields}) · song({radius, heal, lag})
#   적 kind "shield_orc"·"berserker"·"drummer"(오크 셋, S319~S321). ENEMY_KINDS 키: wall({near, cover, cut}) · frenzy({haste, stride}) · drum({radius, haste, stride, keep})
#   적 kind "ogre_thrower"·"chain_orc"(오크 둘, S324·S325). ENEMY_KINDS 키: hurl({range, min, ranged, reach, kinds, windup, air, radius, hit, cd}) · hook({range, min, width, windup, hit, gap, cd})
#   적 kind "wolf_rider"(늑대 기수, S335). ENEMY_KINDS 키: flank({ranged}) · mount(내릴 때 쓰러진 몸으로 남는 종류) · phase2
#   적 kind "warguard"(대족장 근위대, S339) · "warchief"(오크 대족장, S340) · "warchief_foot"(내린 대족장, S341). ENEMY_KINDS 키: rooted(밀리지 않음) · escort · skills
#   적 kind "storm_harpy"·"snatch_harpy"(하피 둘, S307·S308). ENEMY_KINDS 키: gust({range, reach, arc, windup, cd}) · snatch({range, reach, toss, windup, radius, hit, structure, fall, pick, cd})
# 성곽 맵은 wall.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판

const TOP := Vector2i(12, 9)  # 성벽 칸
const IN := Vector2i(10, 4)  # 마을 칸
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]

# S106 표: kind → [체력, 속도, 피해, 공격 간격, 몸 반지름, 인식 범위, 처치 보상, wall_k(비행은 null)]
const TABLE := {
	"basic": [10, 2, 5, 1, 0.3, 3, 5, 1],
	"fast": [6, 3.5, 3, 0.8, 0.25, 3, 4, 1],
	"armored": [18, 1.5, 6, 1.2, 0.35, 3, 8, 1],
	"flying": [8, 2.5, 4, 1, 0.3, 3, 6, null],
	"boss": [160, 1.2, 20, 2, 0.45, 4, 50, 0.3],
	"slime": [14, 1.25, 4, 1, 0.3, 3, 15, 1],  # 1라운드 슬라임 테마(S106 2026-10-27 변경). 킹을 뺀 셋은 속도 ÷1.2(S106 2026-10-30 변경)
	"slimelet": [5, 1.67, 2, 0.8, 0.18, 3, 0, 1],
	"big_slime": [30, 0.92, 8, 1.4, 0.45, 3, 35, 1],
	"slime_king": [160, 1, 20, 2, 2.0, 4, 50, 0.3],  # 몸 반지름 2(S236 2026-10-29 변경)
	"wolf": [9, 3, 3, 0.8, 0.25, 3, 5, 1],  # 2라운드 늑대 테마(S106 2026-10-27 변경)
	"leap_wolf": [12, 3, 3, 0.8, 0.25, 3, 7, 1],
	"night_wolf": [12, 2.8, 4, 1, 0.28, 3, 7, 1],
	"alpha_wolf": [160, 2, 20, 1.5, 0.45, 4, 50, 0.3],
	"sapper": [12, 2.2, 0, 1, 0.25, 0, 6, 1],  # 3라운드 고블린 묶음 ①(S106 2026-11-03 변경)
	"ram": [80, 1, 40, 2, 0.45, 0, 40, 1],
	"catapult": [40, 1, 0, 1, 0.5, 0, 20, 1],
	"glider": [8, 3, 4, 1, 0.25, 3, 4, 1],
	"siege_tower": [120, 0.8, 0, 1, 0.6, 0, 60, 1],  # 3라운드 고블린 묶음 ②-a(S106 2026-11-03 둘째 변경)
	"balloon": [60, 0.8, 0, 1, 0.6, 0, 30, null],
	"airship": [100, 0.9, 5, 1.5, 0.7, 0, 50, null],
	"war_machine": [200, 0.8, 40, 2.5, 0.7, 0, 0, 0.3],  # 3라운드 고블린 묶음 ②-b(S106 2026-11-03 셋째 변경). 처치 보상은 대장으로(2026-11-05 변경)
	"chief": [200, 1.2, 30, 1.5, 0.9, 4, 50, 0.3],  # 3라운드 고블린 묶음 ②-c(S106 2026-11-05 변경)
	"shieldbearer": [15, 2, 5, 1, 0.4, 3, 10, 1],  # 방패 고블린·불화살 고블린(S106 2026-11-07 변경)
	"fire_archer": [10, 2, 3, 1, 0.25, 0, 8, 1],
	"feather_harpy": [8, 2.2, 3, 1.5, 0.3, 0, 8, null],  # 4라운드 하늘 둥지 묶음 ①(S106 2026-11-09 변경)
	"dive_harpy": [10, 2.8, 4, 1, 0.3, 4, 8, null],
	"song_harpy": [12, 2.2, 3, 1, 0.3, 3, 10, null],
	"storm_harpy": [14, 2.2, 3, 1, 0.3, 0, 10, null],  # 4라운드 하늘 둥지 묶음 ②(S106 2026-11-10 변경)
	"snatch_harpy": [12, 2.6, 3, 1, 0.3, 0, 12, null],
	"nest_harpy": [12, 2.4, 3, 1, 0.3, 0, 10, null],  # 4라운드 하늘 둥지 묶음 ③(S106 2026-11-10 둘째 변경)
	"nest": [40, 0, 0, 1, 0.4, 0, 10, null],
	"harpy_chick": [4, 3, 2, 1, 0.2, 3, 0, null],
	"wyvern": [160, 1.6, 15, 1.5, 0.9, 4, 0, null],
	"wyvern_fallen": [200, 1.2, 25, 1.5, 0.9, 4, 50, 0.3],
	"shield_orc": [22, 1.4, 5, 1.2, 0.35, 3, 10, 1],  # 5라운드 오크 전쟁패 묶음 ①(S106 2026-11-10 셋째 변경)
	"berserker": [20, 1.8, 7, 1, 0.35, 4, 8, 1],
	"drummer": [14, 1.5, 3, 1.2, 0.3, 0, 12, 1],
	"ogre_thrower": [60, 1.3, 12, 2, 0.45, 4, 20, 1],  # 5라운드 오크 전쟁패 묶음 ②(S106 2026-11-10 넷째 변경)
	"chain_orc": [20, 1.5, 6, 1.2, 0.35, 4, 10, 1],
	"troll": [60, 1.3, 10, 1.6, 0.45, 4, 18, 1],  # 5라운드 오크 전쟁패 묶음 ③(S106 2026-11-10 다섯째 변경)
	"twin_troll": [160, 1.2, 20, 2, 0.9, 4, 50, 0.3],
	"wolf_rider": [14, 3, 5, 0.8, 0.35, 5, 0, 1],  # 6라운드 대족장 군단 묶음 ①(S106 2026-11-11 변경)
	"warguard": [40, 1.6, 10, 1.2, 0.4, 4, 15, 1],  # 6라운드 대족장 군단 묶음 ③(S106 2026-11-11 둘째 변경)
	"warchief": [160, 1.6, 18, 1.5, 0.9, 5, 0, 0.3],
	"warchief_foot": [240, 1.2, 25, 1.5, 0.9, 4, 50, 0.3],
}
# 오크 대족장 skills(S340): 직선 돌진 · 사슬 갈고리. 내린 대족장 skills(S341): 군단 호출 · 균열
const WARCHIEF := {"charge": {"length": 7.0, "min": 2.0, "width": 1.0, "side": 1.0, "windup": 1.0, "cd": 10.0, "unit": 30.0, "structure": 60.0},
	"chain": {"range": 6.0, "min": 1.5, "width": 0.8, "windup": 1.0, "hit": 15.0, "gap": 1.2, "stun": 1.5, "cd": 9.0}}
const SQUADS := [{"kind": "wolf", "count": 8}, {"kind": "armored", "count": 4}, {"kind": "flying", "count": 8}]
const WARFOOT := {"horn": {"windup": 2.5, "cd": 30.0, "max": 3, "radius": 1.5, "color": "gold", "squads": SQUADS},
	"rift": {"range": 6.0, "count": 4, "gap": 1.5, "radius": 1.2, "windup": 1.2, "cd": 8.0, "unit": 30.0}}
const PACK := {"wolf": 4, "leap_wolf": 2, "night_wolf": 2, "flying": 4, "armored": 4, "shield_orc": 2, "twin_troll": 2, "wolf_rider": 2}  # 무리(S238). 비행은 2026-11-09 변경, 장갑·방패벽 오크는 2026-11-10 셋째 변경, 늑대 기수는 2026-11-11 변경. 나머지 종류는 1
const KEYS := ["hp", "speed", "damage", "attack_gap", "radius", "sight", "reward", "wall_k"]
const FLAME := {"windup": 1.0, "cd": 6.0, "hit": 5.0, "dps": 4.0, "time": 9.0, "spread": 3.0}  # 불화살 고블린 flame(S302)
const FEATHER := {"range": 5.0, "speed": 12.0}  # 깃털 사수 하피 feather(S304)
const DIVE := {"windup": 1.0, "air": 0.4, "cd": 6.0, "damage": 8.0, "radius": 1.0, "push": 1.0, "stun": 2.0, "shields": ["soldier", "aias"]}  # 박치기 하피 dive(S305)
const SONG := {"radius": 3.0, "heal": 0.03, "lag": 0.3}  # 노래하는 하피 song(S306)
const GUST := {"range": 4.0, "reach": 6.0, "arc": 60.0, "windup": 1.0, "cd": 4.0}  # 폭풍날개 하피 gust(S307)
const SNATCH := {"range": 5.0, "reach": 0.5, "toss": 5.0, "windup": 2.0, "radius": 1.0, "hit": 10.0, "structure": 15.0, "fall": 12.0, "pick": 1.5, "cd": 5.0}  # 낚아채기 하피 snatch(S308)
const WALL := {"near": 1.5, "cover": 2.0, "cut": 0.5}  # 방패벽 오크 wall(S319)
const FRENZY := {"haste": 1.0, "stride": 0.5}  # 광전사 오크 frenzy(S320)
const DRUM := {"radius": 3.0, "haste": 0.3, "stride": 0.25, "keep": 2.0}  # 전쟁 북 고수 drum(S321)
const HURL := {"range": 6.0, "min": 2.0, "ranged": 2.0, "reach": 1.5, "kinds": ["armored", "shield_orc", "berserker", "slime", "wolf"], "windup": 1.2, "air": 0.6, "radius": 1.0, "hit": 12.0, "cd": 8.0}  # 오우거 투척꾼 hurl(S324, kinds는 2026-11-11 변경)
const HOOK := {"range": 5.0, "min": 1.5, "width": 0.6, "windup": 1.0, "hit": 8.0, "gap": 1.0, "cd": 7.0}  # 사슬 오크 hook(S325)
const SWAT := {"range": 1.5, "arc": 120.0, "windup": 0.8, "hit": 8.0, "knock": 1.5, "cd": 6.0}  # 트롤 싸움꾼 swat(S328)
const TWIN := {"devour": {"below": 0.5, "radius": 2.0, "kinds": ["armored", "shield_orc", "berserker", "troll"], "windup": 1.5, "heal": 0.25, "cd": 12.0},
	"twin": {"reach": 1.5, "range": 8.0, "radius": 2.0, "windup": 1.5, "air": 0.6, "hit": 40.0, "cd": 6.0},
	"lob": {"range": 7.0, "min": 2.0, "reach": 2.0, "kinds": ["armored", "shield_orc", "berserker"], "windup": 1.2, "air": 0.6, "radius": 1.5, "hit": 15.0, "rock": 25.0, "cd": 9.0}}  # 쌍둥이 트롤 skills(S329), 키 차례가 스킬 차례다
const NEST := {"build": 3.0, "cd": 4.0, "kind": "nest"}  # 둥지 하피 nest(S309)
const BROOD := {"kind": "harpy_chick", "every": 4.0, "cap": 3}  # 둥지 brood(S309)
const WYVERN := {"plunge": {"range": 6.0, "radius": 1.5, "windup": 1.0, "air": 0.5, "cd": 10.0, "damage": 30.0, "knock": 1.0, "down": 2.0},
	"carpet": {"length": 8.0, "width": 1.0, "count": 2, "windup": 1.2, "pass": 0.8, "cd": 14.0, "dps": 5.0, "time": 4.0, "flame_dps": 4.0, "flame_time": 9.0, "spread": 3.0}}  # 와이번 skills(S310)
const FALLEN := {"breath": {"range": 3.0, "arc": 60.0, "windup": 0.8, "cd": 8.0, "dps": 5.0, "time": 4.0},
	"rush": {"length": 6.0, "min": 2.0, "width": 1.0, "side": 1.0, "windup": 1.0, "cd": 12.0, "dps": 5.0, "time": 4.0, "shields": ["soldier", "aias"]},
	"tail": {"range": 2.0, "arc": 120.0, "windup": 0.6, "cd": 6.0, "knock": 1.5}}  # 떨어진 와이번 skills(S311)

func _castle(gates := GATES, walls = null):
	if walls == null:
		walls = []
		for x in 30:
			if Vector2i(x, 9) not in gates:
				walls.append(Vector2i(x, 9))
	return battle({"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": gates, "wall_hp": 300, "gate_hp": 150}})

func _full(b) -> bool:
	return b.castle.values().all(func(k): return k.hp == k.max_hp)

func _on_wall(b, e) -> bool:
	var k = b.castle.get(cell_of(e))
	return k != null and k.kind == "castle_wall"

# 마을에 놓은 용병을 성벽 위 그 칸에 올린다. 못 오르면 null
func _up(b, kind: String, cell: Vector2i):
	var m = b.place_merc(kind, IN)
	b.order_move([m], cell)
	return m if run(b, 30.0, func(): return m.on_wall and near(m.pos, cell)) else null

# 움직이지 않는 과녁
func _still(b, kind: String, cell: Vector2i, over := {}):
	return b.spawn_enemy(kind, cell, ({"speed": 0, "sight": 0, "damage": 0, "hp": BIG} as Dictionary).merged(over, true))

# 첫 번째로 깎인 체력. 깎이지 않으면 -1
func _first_hit(b, e, secs := 5.0) -> float:
	return BIG - e.hp if run(b, secs, func(): return e.hp < e.max_hp) else -1.0

# EV53 · S11: 적 정의마다 무시하는 판정 층은 0개나 1개다(비행·성벽 등반은 경로 층, I80)
func ev53():
	var b = battle()
	for k in b.ENEMY_KINDS:
		var d: Dictionary = b.ENEMY_KINDS[k]
		var n := int(d.get("flying", false)) + int(d.get("climb", 0.0) > 0.0)
		if n > 1:
			return "%s가 판정 층 %d개를 무시한다" % [k, n]
	return ""

# EV130 · S106: 적 5종의 수치가 표와 같다
func ev130():
	var b = battle()
	for k in TABLE:
		if not b.ENEMY_KINDS.has(k):
			return "적 종류 %s가 없다" % k
		for i in KEYS.size():
			var want = TABLE[k][i]
			var got = b.ENEMY_KINDS[k][KEYS[i]]
			if want != null and not is_equal_approx(got, want):
				return "%s.%s = %s, 표는 %s" % [k, KEYS[i], got, want]
	var d: Dictionary = b.ENEMY_KINDS
	var plain: Array = TABLE.keys().filter(func(k): return k != "slime" and k != "big_slime")
	var sb: Dictionary = d.get("shieldbearer", {})
	var fa: Dictionary = d.get("fire_archer", {})
	var esc = sb.get("escort", {})
	var fl = fa.get("flame", {})
	var shield: bool = is_equal_approx(float(sb.get("guard", 0.0)), 40.0) and esc is Dictionary and esc.get("kind") == "basic" and int(esc.get("count", 0)) == 4
	var archer: bool = is_equal_approx(float(fa.get("range", 0.0)), 9.0) and fl is Dictionary and FLAME.keys().all(func(k): return fl.has(k) and is_equal_approx(float(fl[k]), FLAME[k]))
	var harpies: Array = ["feather_harpy", "dive_harpy", "song_harpy"].map(func(k): return d.get(k, {}))
	var gifts: Array = [harpies[0].get("feather", {}), harpies[1].get("dive", {}), harpies[2].get("song", {})]
	var sky: bool = harpies.all(func(x): return x.get("flying") == true) and _same(gifts[0], FEATHER) and _same(gifts[1], DIVE) and _same(gifts[2], SONG)
	if not sky:
		return "하피 셋(S106 2026-11-09 변경): 비행 %s · feather %s(%s) · dive %s(%s) · song %s(%s)" % [harpies.map(func(x): return x.get("flying")), gifts[0], FEATHER, gifts[1], DIVE, gifts[2], SONG]
	var two: Array = ["storm_harpy", "snatch_harpy"].map(func(k): return d.get(k, {}))
	var gifts2: Array = [two[0].get("gust", {}), two[1].get("snatch", {})]
	if not (two.all(func(x): return x.get("flying") == true) and _same(gifts2[0], GUST) and _same(gifts2[1], SNATCH)):
		return "하피 둘(S106 2026-11-10 변경): 비행 %s · gust %s(%s) · snatch %s(%s)" % [two.map(func(x): return x.get("flying")), gifts2[0], GUST, gifts2[1], SNATCH]
	var nh: Dictionary = d.get("nest_harpy", {})
	var ch: Dictionary = d.get("harpy_chick", {})
	var wy: Dictionary = d.get("wyvern", {})
	var wf: Dictionary = d.get("wyvern_fallen", {})
	var skw = wy.get("skills", {})
	var skf = wf.get("skills", {})
	var nest_ok: bool = _same(nh.get("nest", {}), NEST) and _same(d.get("nest", {}).get("brood", {}), BROOD)
	var fly_ok: bool = [nh, ch, wy].all(func(x): return x.get("flying") == true) and wf.get("flying") == false
	var boss_ok: bool = wy.get("boss") == true and wf.get("boss") == true and ch.get("xp") == 0 and wy.get("xp") == 0 and wy.get("phase2") == "wyvern_fallen"
	var skill_ok: bool = (skw is Dictionary and skf is Dictionary and skw.keys() == WYVERN.keys() and skf.keys() == FALLEN.keys()
		and WYVERN.keys().all(func(k): return _same(skw[k], WYVERN[k])) and FALLEN.keys().all(func(k): return _same(skf[k], FALLEN[k])))
	if not (nest_ok and fly_ok and boss_ok and skill_ok):
		return "묶음 ③(S106 2026-11-10 둘째 변경): nest %s(%s) · brood %s(%s) · 비행 %s · boss·xp·phase2 %s · skills %s / %s" % [nh.get("nest"), NEST, d.get("nest", {}).get("brood"), BROOD,
			[nh.get("flying"), ch.get("flying"), wy.get("flying"), wf.get("flying")], [wy.get("boss"), wf.get("boss"), ch.get("xp"), wy.get("xp"), wy.get("phase2")], skw, skf]
	var orcs: Array = [d.get("shield_orc", {}), d.get("berserker", {}), d.get("drummer", {})]
	if not (_same(orcs[0].get("wall", {}), WALL) and _same(orcs[1].get("frenzy", {}), FRENZY) and _same(orcs[2].get("drum", {}), DRUM) and orcs[0].get("armor") == 15.0):
		return "오크 셋(S106 2026-11-10 셋째 변경): wall %s(%s) · frenzy %s(%s) · drum %s(%s) · shield_orc.armor %s(15)" % [orcs[0].get("wall"), WALL, orcs[1].get("frenzy"), FRENZY, orcs[2].get("drum"), DRUM, orcs[0].get("armor")]
	var pair: Array = [d.get("ogre_thrower", {}), d.get("chain_orc", {})]
	if not (_same(pair[0].get("hurl", {}), HURL) and _same(pair[1].get("hook", {}), HOOK) and pair[1].get("armor") == 15.0):
		return "오크 둘(S106 2026-11-10 넷째 변경): hurl %s(%s) · hook %s(%s) · chain_orc.armor %s(15)" % [pair[0].get("hurl"), HURL, pair[1].get("hook"), HOOK, pair[1].get("armor")]
	var trolls: Array = [d.get("troll", {}), d.get("twin_troll", {})]
	var tsk = trolls[1].get("skills", {})
	if not (trolls[0].get("regen") == 0.03 and _same(trolls[0].get("swat", {}), SWAT) and trolls[1].get("regen") == 0.01 and trolls[1].get("boss") == true
		and tsk is Dictionary and tsk.keys() == TWIN.keys() and TWIN.keys().all(func(k): return _same(tsk[k], TWIN[k]))):
		return "트롤 둘(S106 2026-11-10 다섯째 변경): troll regen %s(0.03) · swat %s(%s) · twin_troll regen %s(0.01) · boss %s · skills %s(%s)" % [trolls[0].get("regen"), trolls[0].get("swat"), SWAT, trolls[1].get("regen"), trolls[1].get("boss"), tsk, TWIN]
	var wr: Dictionary = d.get("wolf_rider", {})
	if not (_same(wr.get("flank", {}), {"ranged": 2.0}) and wr.get("phase2") == "armored" and wr.get("mount") == "wolf" and wr.get("xp") == 0):
		return "늑대 기수(S106 2026-11-11 변경): flank %s({ranged 2}) · phase2 %s(armored) · mount %s(wolf) · xp %s(0)" % [wr.get("flank"), wr.get("phase2"), wr.get("mount"), wr.get("xp")]
	var wg: Dictionary = d.get("warguard", {})
	var wc: Dictionary = d.get("warchief", {})
	var wt: Dictionary = d.get("warchief_foot", {})
	if not (wg.get("armor") == 20.0 and wg.get("rooted") == true and TABLE.keys().all(func(k): return k == "warguard" or d[k].get("rooted", false) == false)):
		return "대족장 근위대(S106 2026-11-11 둘째 변경): armor %s(20) · rooted %s(참, 나머지 종류는 거짓)" % [wg.get("armor"), wg.get("rooted")]
	var csk = wc.get("skills", {})
	if not (wc.get("boss") == true and wc.get("xp") == 0 and wc.get("phase2") == "warchief_foot" and wc.get("mount") == "wolf" and wc.get("escort") == {"kind": "warguard", "count": 4}
		and csk is Dictionary and csk.keys() == WARCHIEF.keys() and WARCHIEF.keys().all(func(k): return _same(csk[k], WARCHIEF[k]))):
		return "오크 대족장: boss %s · xp %s(0) · phase2 %s(warchief_foot) · mount %s(wolf) · escort %s(warguard 4) · skills %s(%s)" % [wc.get("boss"), wc.get("xp"), wc.get("phase2"), wc.get("mount"), wc.get("escort"), csk, WARCHIEF]
	var fsk = wt.get("skills", {})
	var horn: Dictionary = fsk.get("horn", {}) if fsk is Dictionary else {}
	if not (wt.get("boss") == true and wt.get("armor") == 10.0 and fsk is Dictionary and fsk.keys() == WARFOOT.keys() and _same(fsk.rift, WARFOOT.rift)
		and horn.get("squads") == SQUADS and horn.get("color") == "gold" and ["windup", "cd", "max", "radius"].all(func(k): return is_equal_approx(horn.get(k, -1.0), WARFOOT.horn[k]))):
		return "내린 대족장: boss %s · armor %s(10) · skills %s(%s)" % [wt.get("boss"), wt.get("armor"), fsk, WARFOOT]
	return check(d.fast.climb == 3.0 and d.armored.armor == 15.0 and d.flying.flying and not d.basic.flying and d.basic.climb == 0.0
		and d.slime.get("split") == {"kind": "slimelet", "count": 2} and d.big_slime.get("split") == {"kind": "slime", "count": 2}
		and plain.all(func(k): return d[k].get("split", {}).is_empty()) and d.slime_king.get("boss") == true and d.alpha_wolf.get("boss") == true
		and TABLE.keys().all(func(k): return d[k].get("pack", 1) == PACK.get(k, 1)) and is_equal_approx(d.leap_wolf.climb, 0.8) and d.glider.flying
		and d.balloon.flying and d.airship.flying and d.siege_tower.armor == 15.0 and d.war_machine.get("boss") == true and d.war_machine.armor == 15.0
		and d.chief.get("boss") == true and d.chief.armor == 10.0 and shield and archer,
		"특수: fast.climb %s · armored.armor %s · flying.flying %s · 갈라짐 %s · boss %s · 무리 %s · leap_wolf.climb %s · glider.flying %s · balloon·airship.flying %s · siege_tower.armor %s · war_machine boss·armor %s · chief boss·armor %s" % [d.fast.climb, d.armored.armor, d.flying.flying,
			TABLE.keys().map(func(k): return [k, d[k].get("split")]), [d.slime_king.get("boss"), d.alpha_wolf.get("boss")],
			TABLE.keys().map(func(k): return [k, d[k].get("pack")]), d.leap_wolf.climb, d.get("glider", {}).get("flying"),
			[d.get("balloon", {}).get("flying"), d.get("airship", {}).get("flying")], d.get("siege_tower", {}).get("armor"),
			[d.get("war_machine", {}).get("boss"), d.get("war_machine", {}).get("armor")], [d.get("chief", {}).get("boss"), d.get("chief", {}).get("armor")]]
			+ " · shieldbearer guard·escort %s(40, basic 4) · fire_archer range·flame %s(9, %s)" % [[sb.get("guard"), esc], [fa.get("range"), fl], FLAME])

# 수치 사전 got이 want와 같은 키를 갖고 값이 같다(수는 근사, 배열은 그대로)
func _same(got, want: Dictionary) -> bool:
	if not got is Dictionary or got.size() != want.size():
		return false
	for k in want:
		if not got.has(k):
			return false
		if want[k] is Array or want[k] is String:
			if got[k] != want[k]:
				return false
		elif not is_equal_approx(float(got[k]), want[k]):
			return false
	return true

# 방어력 a의 물리 피해 배율(S149, 워크3식): a ≥ 0이면 1 − 0.06a ÷ (1 + 0.06a)
func _armor(a: float) -> float:
	return 1.0 - 0.06 * a / (1.0 + 0.06 * a)

# EV131 · S108: 방어력 15인 장갑 적은 물리 피해를 워크3식 비율만큼 덜 받는다(최소 1 규칙은 없다). 방어력 0인 적은 그대로 받는다
func ev131():
	var b = battle()
	var a = _still(b, "armored", Vector2i(5, 5))
	for amount in [2.0, 6.0, 0.5]:
		var hp0: float = a.hp
		b.damage(a, amount)
		if not is_equal_approx(hp0 - a.hp, amount * _armor(15.0)):
			return "장갑 적이 피해 %s에 %s 깎였다(%s이어야 한다)" % [amount, hp0 - a.hp, amount * _armor(15.0)]
	var n = _still(b, "basic", Vector2i(5, 8))
	b.damage(n, 2.0)
	return check(is_equal_approx(BIG - n.hp, 2.0), "방어력 0인 적이 피해 2에 %s 깎였다" % (BIG - n.hp))

# EV132 · S110: 마법 타워는 마법 피해라 방어력을 무시하고, 타워는 방어력만큼 덜 깎는다
func ev132():
	var got := {}
	for kind in ["magic", "tower"]:
		var b = battle()
		var c := Vector2i(10, 10)
		if b.build(kind, c) == null:
			return "%s를 짓지 못했다" % kind
		got[kind] = _first_hit(b, _still(b, "armored", c + Vector2i(2, 0)))
	return check(is_equal_approx(got.magic, 6.0) and is_equal_approx(got.tower, 2.0 * _armor(15.0)), "한 발에 깎인 체력: 마법 타워 %s(6), 타워 %s(%s)" % [got.magic, got.tower, 2.0 * _armor(15.0)])

# EV133 · S110: - 키 뒤 좌클릭한 들판 칸에 마법 타워가 지어진다
func ev133():
	var b = battle()
	var c = controls(b)
	var ev := InputEventKey.new()
	ev.keycode = KEY_MINUS
	ev.pressed = true
	c.handle(ev)
	var gold0: int = b.gold
	var cell := Vector2i(10, 10)
	click(c, MOUSE_BUTTON_LEFT, px(cell))
	var s = b.structure_at(cell)
	return check(s != null and s.kind == "magic" and gold0 - b.gold == b.STRUCTURE_KINDS.magic.cost, "- 키 뒤 좌클릭: %s, 골드 %d 줄었다(마법 타워 값 %d, 놓기 모드 %s)" % [s, gold0 - b.gold, b.STRUCTURE_KINDS.magic.cost, c.placing])

# EV134 · S109: 비행 적은 닫힌 성곽을 부수지 않고 넘어 거점을 친다
func ev134():
	var b = _castle()
	b.spawn_enemy("flying", Vector2i(12, 19), {"hp": BIG})
	if not run(b, 30.0, func(): return b.base.hp < b.base.max_hp):
		return "비행 적이 거점을 치지 못했다"
	return check(_full(b), "비행 적이 성곽을 깎았다")

# EV135 · S109: 비행 적은 경로 위 용병에 막히지 않는다
func ev135():
	var b = battle()
	var m = b.place_merc("soldier", Vector2i(12, 10), {"damage": 0})
	b.spawn_enemy("flying", Vector2i(5, 10), {"sight": 0, "hp": BIG})
	if not run(b, 30.0, func(): return b.base.hp < b.base.max_hp):
		return "비행 적이 거점에 닿지 못했다(용병 %s)" % m.pos
	return check(m.hp == m.max_hp, "비행 적이 길 위 용병을 쳤다(체력 %s)" % m.hp)

# EV136 · S109: 비행 적도 궁수 용병·타워·대포 범위 피해에 맞고, 근접 용병(병사)에게는 맞지 않는다(S109 2026-11-09 변경)
func ev136():
	var b = battle()
	b.place_merc("soldier", Vector2i(10, 10))
	if _first_hit(b, _still(b, "flying", Vector2i(11, 10))) > 0.0:
		return "근접 용병이 5초 안에 날고 있는 비행 적을 쳤다"
	b = battle()
	b.place_merc("archer", Vector2i(10, 10))
	if _first_hit(b, _still(b, "flying", Vector2i(12, 10))) <= 0.0:
		return "궁수 용병이 비행 적을 쏘지 못했다"
	b = battle()
	b.build("tower", Vector2i(10, 8))
	if _first_hit(b, _still(b, "flying", Vector2i(10, 10))) <= 0.0:
		return "타워가 비행 적을 쏘지 못했다"
	b = battle()
	b.build("cannon", Vector2i(10, 8))
	_still(b, "basic", Vector2i(10, 11))  # 대포가 노리는 더 가까운 적
	return check(_first_hit(b, _still(b, "flying", Vector2i(11, 11))) > 0.0, "대포 범위 피해가 비행 적에 닿지 않았다")

# EV137 · I77: 비행 적은 인식 범위 안 성벽 위 궁수를 친다
func ev137():
	var b = _castle()
	var m = _up(b, "archer", TOP)
	if m == null:
		return "궁수가 성벽에 오르지 못했다"
	b.spawn_enemy("flying", TOP + Vector2i(0, 3), {"hp": BIG})
	return check(run(b, 15.0, func(): return m.hp < m.max_hp), "비행 적이 성벽 위 궁수를 치지 않았다")

# EV138 · S107: 빠름 적은 닫힌 성곽을 부수지 않고 넘어 거점을 친다
func ev138():
	var b = _castle()
	var e = b.spawn_enemy("fast", Vector2i(12, 19), {"hp": BIG})
	if not run(b, 40.0, func(): return b.base.hp < b.base.max_hp):
		return "빠름 적이 거점을 치지 못했다(%s)" % e.pos
	return check(_full(b), "빠름 적이 성곽을 깎았다")

# EV139 · S107: 성벽 앞의 빠름 적은 3초를 들여 성벽 칸 위에 올라선다
func ev139():
	var b = _castle()
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 1), {"hp": BIG, "sight": 0})
	if run(b, 2.5, func(): return _on_wall(b, e)):
		return "2.5초 안에 성벽 칸 위에 올라섰다"
	return check(run(b, 2.0, func(): return _on_wall(b, e)), "4.5초가 지나도 성벽 칸 위에 올라서지 않았다(%s)" % e.pos)

# EV140 · I76: 닫힌 성문은 기어오르지 않고 부순다
func ev140():
	var gates := []
	for x in 30:
		gates.append(Vector2i(x, 9))
	var b = _castle(gates, [])
	b.spawn_enemy("fast", Vector2i(15, 15), {"hp": BIG, "sight": 0})
	if not run(b, 20.0, func(): return not _full(b)):
		return "빠름 적이 닫힌 성문을 부수지 않았다"
	return check(b.base.hp == b.base.max_hp, "성문을 부수기 전에 거점에 닿았다")

# EV141 · I43: 들판의 방벽은 기어오르지 않고 부순다
func ev141():
	var b = battle()
	var cells := ring(b.base.cell)
	for c in cells:
		b.build("wall", c)
	b.spawn_enemy("fast", Vector2i(0, 10), {"hp": BIG, "sight": 0})
	return check(run(b, 30.0, func(): return not intact(b, cells)), "빠름 적이 방벽을 부수지 않았다")

# EV142 · I77: 빠름 적은 성벽에 올라 인식 범위 안 성벽 위 궁수를 친다
func ev142():
	var b = _castle()
	var m = _up(b, "archer", TOP)
	if m == null:
		return "궁수가 성벽에 오르지 못했다"
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 3), {"hp": BIG})
	if not run(b, 15.0, func(): return m.hp < m.max_hp):
		return "빠름 적이 성벽 위 궁수를 치지 않았다(%s)" % e.pos
	return check(_on_wall(b, e), "빠름 적이 성벽에 오르지 않고 궁수를 쳤다(%s)" % e.pos)

# EV143 · I78: 성벽 위의 적은 성벽 위 근접 용병이 친다
func ev143():
	var b = _castle()
	var m = _up(b, "soldier", TOP)
	if m == null:
		return "용병이 성벽에 오르지 못했다"
	var e = b.spawn_enemy("fast", TOP + Vector2i(0, 3), {"hp": BIG, "damage": 0})
	var ground_hp := [e.hp]  # 성벽 위로 올라서기 직전 프레임의 체력. 올라선 프레임 안에서 바로 맞을 수 있다
	if not run(b, 15.0, func():
		if not _on_wall(b, e):
			ground_hp[0] = e.hp
		return _on_wall(b, e)):
		return "빠름 적이 성벽에 오르지 않았다(%s)" % e.pos
	if ground_hp[0] < e.max_hp:
		return "성벽 위 근접 용병이 땅의 적을 쳤다(S88)"
	return check(run(b, 3.0, func(): return e.hp < e.max_hp), "성벽 위 근접 용병이 성벽 위 적을 치지 않았다")

# EV144 · S111: 시험 스테이지의 시작 골드와 웨이브
func ev144():
	var stage: Dictionary = load("res://src/main.gd").stage()
	var want := [{"slime": 36}, {"slime": 24, "big_slime": 10}, {"slime": 36, "big_slime": 14, "slime_king": 1}]  # S111 2026-10-30 변경: 1라운드 슬라임 테마, 보스 빼고 1.2배 반올림
	var got := []
	for w in stage.waves:
		var d := {}
		for entry in w:
			d[entry.kind] = d.get(entry.kind, 0) + entry.count
		got.append(d)
	return check(stage.gold == 1000 and got == want, "시작 골드 %s, 웨이브 %s" % [stage.gold, got])

# EV145 · I81: 적 종류(TABLE, S106)의 색이 모두 있고 서로 다르다
func ev145():
	var colors: Dictionary = load("res://src/ui/battle_view.gd").ENEMY_COLORS
	var seen := []
	for k in TABLE:
		if not colors.has(k):
			return "적 %s의 색이 없다" % k
		if colors[k] in seen:
			return "적 %s의 색이 다른 적과 같다" % k
		seen.append(colors[k])
	return ""
