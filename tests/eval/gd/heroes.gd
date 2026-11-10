extends "res://tests/eval/gd/lib.gd"
# 영웅 6명(S97·S118~S121·S157·I95~I102). 2026-10-18 영웅 개편으로 옛 영웅의 효과를 재던 평가(EV176~EV190)는 기각했다(EVAL.md ## 기각).
# 새 영웅의 칸을 재는 평가는 kits.gd에 있다. lib.gd 머리의 계약에 더하는 API:
#   stage 키 heroes: [{kind, cell, level?}, …] — 영웅 목록. 첫 영웅이 Battle.hero다. 없으면 hero_start가 아이아스 하나다
#   Battle.HERO_KINDS — 종류 → 수치(data/heroes/<종류>.tres, 스크립트 변수 사전) · Battle.heroes · Battle.SLOTS ["q","w","e","r"]
#   Battle.cast(영웅, 칸, aim = null) -> bool · Battle.can_cast(영웅, 칸) · Battle.toggle_auto(영웅, 칸)
#   영웅: kind · grade · cd[칸] · skill_uses · passive · aura · q·w·e·r(사전: id·aim·gap·수치)
#   Controls.skill_key(칸, shift = false) · Controls.aiming · Q·W·E·R 키(KEY_Q…)
# 수치는 영웅 필드에서 읽는다. 임시값이라 밸런스를 바꿔도 효과를 재는 평가는 깨지지 않게. EV172·EV173만 표를 대조한다
# 스킬과 그 대기는 전투 단계에만 돈다(S136). 그래서 그것을 재는 평가는 _start로 전투 단계를 연 뒤 잰다

const H := Vector2i(10, 10)
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const ONE := [{"kind": "basic", "count": 1}]  # 적 하나짜리 웨이브
const S151_158 := {  # 종류 → [패시브 id, 오라 키들, [Q·W·E·R마다 id, 조준, 대기]]
	"aias": ["fortress", [], [["shield_bash", "dir", 6], ["war_cry", "self", 12], ["brace", "self", 14], ["bulwark", "point", 60]]],
	"sylvia": ["true_aim", ["reach"], [["piercing_gale", "dir", 7], ["tailwind", "point", 12], ["wind_lens", "point", 14], ["wind_path", "self", 55]]],
	"seraphina": ["overflow", ["armor"], [["holy_beam", "ally", 6], ["sanctum", "point", 12], ["guardian", "ally", 16], ["miracle", "self", 70]]],
	"vesper": ["contagion", ["foe_armor"], [["corrosion", "point", 8], ["enfeeble", "point", 11], ["soul_chain", "enemy", 15], ["abyss", "point", 60]]],
	"ignis": ["overload", ["cdr"], [["fireball", "point", 6], ["frost_ring", "point", 9], ["black_hole", "point", 14], ["meteor_swarm", "point", 65]]],
	"chronos": ["", ["haste", "stride"], [["overcharge", "ally", 4], ["aging", "point", 14], ["time_loop", "point", 18], ["wind_up", "self", 80]]],
}
const S121 := {  # 등급, 체력, 공격력, 사거리, 공격 간격, 속도
	"aias": [3, 100, 3, 1.5, 1.0, 3], "sylvia": [3, 70, 3, 6, 1.0, 3], "seraphina": [3, 90, 2, 3, 1.0, 3],
	"vesper": [3, 90, 3, 3.5, 1.0, 3], "ignis": [3, 90, 5, 4, 1.2, 3], "chronos": [3, 110, 4, 3, 1.0, 3],
}

func _hero(kind: String, cell: Vector2i) -> Dictionary:
	return {"kind": kind, "cell": cell}

func _heroes(team: Array, over := {}):
	var stage := {"heroes": team, "base_hp": BIG, "waves": [ONE]}
	stage.merge(over, true)
	return battle(stage)

func _castle(over := {}):
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	var stage := {"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}, "waves": [ONE]}
	stage.merge(over, true)
	return battle(stage)

# 움직이지도 반격하지도 않는 과녁
func _dummy(b, cell: Vector2i, over := {}):
	return b.spawn_enemy("basic", cell, {"speed": 0, "sight": 0, "damage": 0, "hp": BIG}.merged(over, true))

# x가 다음에 맞는 한 방의 피해. secs 안에 안 맞으면 0
func _next_hit(b, x, secs := 5.0) -> float:
	var h0: float = x.hp
	run(b, secs, func(): return x.hp < h0)
	return h0 - x.hp

# damage 한 번에 깎인 양
func _hit(b, x, amount: float) -> float:
	var h0: float = x.hp
	b.damage(x, amount)
	return h0 - x.hp

# secs초 동안 간 거리들
func _moved(b, things: Array, secs: float) -> Array:
	var at := things.map(func(x): return x.pos)
	run(b, secs)
	var out := []
	for i in things.size():
		out.append(things[i].pos.distance_to(at[i]))
	return out

func _key(c, key: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	c.handle(ev)

# 전투 단계를 연다. 웨이브 적은 처치하고, 움직이지도 치지도 않는 적 하나를 구석에 남겨 전투 단계가 이어지게 한다
func _start(b) -> void:
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var idle = b.spawn_enemy("basic", Vector2i(0, 19), {"speed": 0, "sight": 0, "damage": 0})
	for x in b.enemies.duplicate():
		if x != idle:
			b.damage(x, BIG)

# EV172 · S97: 6명의 패시브·오라·Q·W·E·R(id·조준·대기)이 S151~S158 표와 같고, 오라 반경은 3이다
func ev172():
	var kinds: Dictionary = battle().HERO_KINDS
	for k in S151_158:
		if not kinds.has(k):
			return "영웅 %s가 없다(%s)" % [k, kinds.keys()]
		var want: Array = S151_158[k]
		var got: Dictionary = kinds[k]
		if got.passive.get("id", "") != want[0]:
			return "%s의 패시브가 %s다(%s여야 한다)" % [k, got.passive.get("id", ""), want[0]]
		var keys: Array = got.aura.keys().filter(func(x): return x != "radius")
		if keys != want[1] or (not got.aura.is_empty() and not is_equal_approx(float(got.aura.radius), 3.0)):
			return "%s의 오라가 %s다(%s, 반경 3이어야 한다)" % [k, got.aura, want[1]]
		for i in 4:
			var sk: Dictionary = got[["q", "w", "e", "r"][i]]
			var row := [sk.id, sk.aim, sk.gap]
			if row[0] != want[2][i][0] or row[1] != want[2][i][1] or not is_equal_approx(float(row[2]), float(want[2][i][2])):
				return "%s의 %s가 %s다(%s여야 한다)" % [k, ["Q", "W", "E", "R"][i], row, want[2][i]]
	return ""

# EV173 · S121: 6종의 파일이 있고 등급·기본 능력치가 표와 같다. hero_start로 낸 영웅은 아이아스다
func ev173():
	var files := Array(ResourceLoader.list_directory("res://data/heroes/")).filter(func(f): return f.ends_with(".tres")).map(func(f): return f.get_basename())
	var want := S121.keys()
	files.sort()
	want.sort()
	if files != want:
		return "data/heroes의 영웅이 %s다(%s여야 한다)" % [files, want]
	var kinds: Dictionary = battle().HERO_KINDS
	for k in S121:
		var got := [kinds[k].grade, kinds[k].hp, kinds[k].damage, kinds[k].range, kinds[k].attack_gap, kinds[k].speed]
		for i in got.size():
			if not is_equal_approx(float(got[i]), float(S121[k][i])):
				return "%s의 등급·기본 능력치가 %s다(%s여야 한다)" % [k, got, S121[k]]
	var b = battle({"hero_start": Vector2i(5, 5)})
	return check(b.hero != null and b.hero.kind == "aias", "hero_start로 낸 영웅이 %s다(aias이어야 한다)" % (b.hero.kind if b.hero else "없음"))

# EV175 · S119: 스킬은 고른 영웅이, 고른 영웅이 없으면 첫 영웅이 쓴다
func ev175():
	var b = _heroes([_hero("aias", Vector2i(5, 5)), _hero("chronos", Vector2i(10, 5))])
	var c = controls(b)
	_start(b)
	var k = b.heroes[0]
	var m = b.heroes[1]
	_key(c, KEY_W)
	var first := [k.skill_uses, m.skill_uses]
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 5)))
	if c.selected != [m]:
		return "크로노스를 고르지 못했다(%s)" % [c.selected]
	_key(c, KEY_E)
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(m.pos.round())))  # 크로노스 E는 지점 칸이다(S158 2026-10-30)
	return check(first == [1, 0] and k.skill_uses == 1 and m.skill_uses == 1 and k.cd.e <= 0.0 and m.cd.e > 0.0,
		"고르지 않고 W: 아이아스·크로노스 %s · 크로노스를 고르고 E: 아이아스 %d·크로노스 %d, E 대기 아이아스 %s·크로노스 %s" % [first, k.skill_uses, m.skill_uses, k.cd.e, m.cd.e])

# EV191 · I102: 영웅마다 자기 시작 칸으로 돌아오고, 배치 상한에 들지 않는다
func ev191():
	var one := [{"kind": "basic", "count": 1}]
	var ka := Vector2i(5, 5)
	var pa := Vector2i(8, 5)
	var b = _heroes([_hero("aias", ka), _hero("seraphina", pa)], {"waves": [one, one], "merc_cap": 1})
	b.start_battle()
	run(b, 1.0)
	for h in b.heroes:
		b.damage(h, BIG)
	clear_wave(b)
	var back: bool = b.state == "prep" and b.heroes.all(func(h): return h.present and h.hp == 1.0) and near(b.heroes[0].pos, ka, 0.01) and near(b.heroes[1].pos, pa, 0.01)  # 체력 1로 돌아온다(S138)
	var m = b.place_merc("soldier", Vector2i(12, 5))
	return check(back and m != null, "돌아옴 %s(%s) · 상한 1에서 용병 %s" % [back, b.heroes.map(func(h): return [h.kind, h.pos, h.hp]), m])

# 아이아스(첫 영웅)·크로노스를 낸 판의 전투 단계와 그 컨트롤
func _pair_in_battle() -> Array:
	var b = _heroes([_hero("aias", Vector2i(5, 5)), _hero("chronos", Vector2i(10, 5))],
		{"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})
	var c = controls(b)
	_start(b)
	return [b, c]

# EV231 · I126: 첫 영웅이 쓰러지면 고르지 않고 누른 키는 살아 있는 다음 영웅이 쓴다. 쓰러진 영웅을 골라 둔 채 누른 키도 그렇다
func ev231():
	var bc := _pair_in_battle()
	_down_first_then_e(bc)
	var free_e: int = bc[0].heroes[1].skill_uses
	var de := _pair_in_battle()
	_key(de[1], KEY_1)
	var picked: bool = de[1].selected == [de[0].heroes[0]]
	_down_first_then_e(de)
	return check(free_e == 1 and picked and de[0].heroes[1].skill_uses == 1,
		"고르지 않고 E: 크로노스 %d번 · 아이아스를 고른 채(%s) 아이아스가 쓰러진 뒤 E: 크로노스 %d번" % [free_e, picked, de[0].heroes[1].skill_uses])

# 첫 영웅(아이아스)을 쓰러뜨린 뒤 E를 누르고 크로노스 칸을 누른다(크로노스 E는 지점 칸, S158 2026-10-30)
func _down_first_then_e(bc: Array) -> void:
	bc[0].damage(bc[0].heroes[0], BIG)
	_key(bc[1], KEY_E)
	click(bc[1], MOUSE_BUTTON_LEFT, px(Vector2i(bc[0].heroes[1].pos.round())))

# EV238 · S136: 준비 단계의 스킬 키는 아무 일도 하지 않고 재사용 대기도 시작하지 않는다. 전투 단계에는 쓴다
func ev238():
	var b = _heroes([_hero("aias", H)])
	var c = controls(b)
	var k = b.hero
	_key(c, KEY_W)
	_key(c, KEY_E)
	var idle: bool = k.skill_uses == 0 and k.cd.w == 0.0 and k.cd.e == 0.0
	b.start_battle()
	_key(c, KEY_W)
	_key(c, KEY_E)
	return check(idle and k.skill_uses == 2 and is_equal_approx(k.cd.w, k.w.gap) and is_equal_approx(k.cd.e, k.e.gap),
		"준비 단계 W·E 뒤 그대로 %s · 전투 단계: %d번, W 대기 %s, E 대기 %s" % [idle, k.skill_uses, k.cd.w, k.cd.e])

# EV239 · S136: 전투 단계가 아닐 때(준비 단계·라운드 사이)는 스킬 대기가 줄지 않는다
func ev239():
	var b = _heroes([_hero("aias", H)], {"rounds": [[ONE, ONE], [ONE]]})
	var k = b.hero
	_start(b)
	b.cast(k, "w")
	b.cast(k, "e")
	clear_wave(b)
	var now := func(): return [k.cd.w, k.cd.e]
	var at: Array = now.call()
	run(b, 10.0)
	var prep: bool = b.state == "prep" and now.call() == at
	var after_prep: Array = now.call()
	_start(b)
	run(b, 1.0)
	var fight: bool = k.cd.w < at[0]
	clear_wave(b)
	var between: Array = now.call()
	run(b, 10.0)
	var cleared: bool = b.state == "cleared" and now.call() == between
	return check(prep and fight and cleared,
		"준비 단계 10초 [W 대기, E 대기] %s → %s · 전투 단계 1초에 줄고 참 %s · 라운드 사이(%s) 10초 %s → %s" % [at, after_prep, fight, b.state, between, now.call()])

# EV881 · S314·I260: ` 키는 살아 있는 출전 영웅을 출전 순서대로 모두 고른다(쓰러진 영웅·용병은 빠진다). 영입 단계에는 듣지 않는다
func ev881():
	var b = _heroes([_hero("aias", H), _hero("ignis", H + Vector2i(0, 2)), _hero("seraphina", H + Vector2i(0, 4))], {"merc_cap": 2})
	b.gold = BIG
	var team: Array = b.heroes
	team[1].alive = false
	var m = b.place_merc("soldier", Vector2i(14, 10))
	var c = controls(b)
	c.selected = [m]
	_key(c, KEY_QUOTELEFT)
	var picked: Array = c.selected.duplicate()
	b.begin_hiring()
	c.selected = [m]
	_key(c, KEY_QUOTELEFT)
	var kept: Array = c.selected.duplicate()
	return check(m != null and team.size() == 3 and picked == [team[0], team[2]] and kept == [m],
		"용병 %s · 준비 단계에 고른 것 %s(기대 [아이아스, 세라피나]) · 영입 단계에 고른 것 %s(기대 [병사])" % [m, picked.map(func(x): return x.kind), kept.map(func(x): return x.kind)])

# 대시 손잡이(S315). 아직 없으면 빈 사전
func _dash_cfg() -> Dictionary:
	return load("res://src/sim/battle.gd").get_script_constant_map().get("DASH", {})

# 고른 것을 group으로 두고 커서를 칸 at 가운데에 둔 채 Space를 누른다
func _dash_key(c, group: Array, at: Vector2) -> void:
	c.selected = group
	c.mouse = (at + Vector2(0.5, 0.5)) * CELL_PX
	_key(c, KEY_SPACE)

# from에서 at 쪽으로 n칸 간 자리
func _toward(from: Vector2, at: Vector2, n: float) -> Vector2:
	return from + (at - from).normalized() * n

# EV882 · S315: 전투 단계 Space — 고른 출전 영웅만 저마다 커서 쪽으로 DASH.length칸, 대기 DASH.cd초. 대기 중엔 그대로, 대기가 끝나면 다시.
# 고른 것에 영웅이 없으면 살아 있는 첫 영웅이 대시한다
func ev882():
	var dash := _dash_cfg()
	if dash.is_empty():
		return "Battle.DASH가 없다"
	var team3 := [_hero("aias", H), _hero("ignis", H + Vector2i(0, 2)), _hero("seraphina", H + Vector2i(0, 4))]
	var b = _heroes(team3, {"merc_cap": 2})
	b.gold = BIG
	var t: Array = b.heroes
	var m = b.place_merc("soldier", Vector2i(14, 10))
	_start(b)
	var c = controls(b)
	var at := Vector2(20, 10)
	var p0: Array = [t[0].pos, t[1].pos, t[2].pos, m.pos]
	_dash_key(c, [t[0], t[1], m], at)
	var went: bool = t[0].pos.distance_to(_toward(p0[0], at, dash.length)) < 0.01 and t[1].pos.distance_to(_toward(p0[1], at, dash.length)) < 0.01
	var still: bool = t[2].pos.distance_to(p0[2]) < 0.01 and m.pos.distance_to(p0[3]) < 0.01
	var cds := [t[0].get("dash_cd"), t[1].get("dash_cd"), t[2].get("dash_cd")]
	var cd_ok: bool = cds[0] == dash.cd and cds[1] == dash.cd and cds[2] == 0.0
	var p1: Array = [t[0].pos, t[1].pos]
	_key(c, KEY_SPACE)
	var waited: bool = t[0].pos.distance_to(p1[0]) < 0.01 and t[1].pos.distance_to(p1[1]) < 0.01
	run(b, dash.cd + 0.1)
	var p2: Array = [t[0].pos, t[1].pos]
	_key(c, KEY_SPACE)
	var again: bool = absf(t[0].pos.distance_to(p2[0]) - dash.length) < 0.01 and absf(t[1].pos.distance_to(p2[1]) - dash.length) < 0.01
	var b2 = _heroes(team3, {"merc_cap": 2})
	b2.gold = BIG
	var u: Array = b2.heroes
	var m2 = b2.place_merc("soldier", Vector2i(14, 10))
	_start(b2)
	u[0].alive = false
	var c2 = controls(b2)
	var q0: Array = [u[1].pos, u[2].pos]
	_dash_key(c2, [m2], at)
	var first: bool = u[1].pos.distance_to(_toward(q0[0], at, dash.length)) < 0.01 and u[2].pos.distance_to(q0[1]) < 0.01
	return check(went and still and cd_ok and waited and again and first,
		"고른 둘 %s · 안 고른 둘 그대로 %s · dash_cd %s(기대 %s, %s, 0) · 대기 중 그대로 %s · 대기 뒤 다시 %s · 병사만 고르면 살아 있는 첫 영웅 %s"
		% [went, still, cds, dash.cd, dash.cd, waited, again, first])

# EV883 · I261 ④: 대시 길은 막힌 칸(타워) 바로 앞에서 멈추고, 에너지 성벽·몸은 지나간다. 한 걸음도 못 나가면 대기를 쓰지 않는다
func ev883():
	var dash := _dash_cfg()
	if dash.is_empty():
		return "Battle.DASH가 없다"
	var at := Vector2(20, 10)
	var out := []
	for case in ["tower", "barrier", "body", "stuck"]:
		var b = _heroes([_hero("aias", H)])
		b.gold = BIG
		if case == "tower":
			b.build("tower", Vector2i(12, 10))
		elif case == "stuck":
			b.build("tower", Vector2i(11, 10))
		_start(b)
		var h = b.heroes[0]
		h.pos = Vector2(10.3, 10) if case == "stuck" else Vector2(H)
		if case == "barrier":
			b.barriers[Vector2i(12, 10)] = load("res://src/sim/battle.gd").Block.new(Vector2i(12, 10), "barrier", 1e6)
		elif case == "body":
			_dummy(b, Vector2i(11, 10))
		_dash_key(controls(b), [h], at)
		var ok: bool
		match case:
			"tower":
				ok = h.pos.x >= 11.0 and h.pos.x < 11.5 and absf(h.pos.y - 10.0) < 0.01
			"stuck":
				ok = h.pos.distance_to(Vector2(10.3, 10)) < 0.01 and h.get("dash_cd") == 0.0
			_:
				ok = h.pos.distance_to(Vector2(12, 10)) < 0.01
		if not ok:
			out.append("%s: 자리 %s · dash_cd %s" % [case, h.pos, h.get("dash_cd")])
	return check(out.is_empty(), " / ".join(out))

# EV884 · I261 ①②⑤: 준비 단계엔 대시하지 않는다. 기절·성벽 위 영웅은 빼고 나머지만 대시한다. 대시하면 이동 명령이 지워지고, 요새화가 풀린다
func ev884():
	var dash := _dash_cfg()
	if dash.is_empty():
		return "Battle.DASH가 없다"
	var team3 := [_hero("aias", H), _hero("ignis", H + Vector2i(0, 2)), _hero("seraphina", H + Vector2i(0, 4))]
	var at := Vector2(20, 12)
	var b = _heroes(team3)
	var t: Array = b.heroes
	var c = controls(b)
	var p0: Array = t.map(func(h): return h.pos)
	_dash_key(c, t.duplicate(), at)
	var prep: bool = range(3).all(func(i): return t[i].pos.distance_to(p0[i]) < 0.01 and t[i].get("dash_cd") == 0.0)
	_start(b)
	b._fx(t[0], "ev884", {"stun": true}, 3.0)
	t[2].on_wall = true
	var p1: Array = t.map(func(h): return h.pos)
	_key(c, KEY_SPACE)
	var some: bool = t[0].pos.distance_to(p1[0]) < 0.01 and t[2].pos.distance_to(p1[2]) < 0.01 \
		and t[1].pos.distance_to(_toward(p1[1], at, dash.length)) < 0.01
	var b2 = _heroes(team3)
	_start(b2)
	var ig = b2.heroes[1]
	b2.order_move([ig], Vector2i(25, 18))
	run(b2, 0.3)
	_dash_key(controls(b2), [ig], Vector2(2, 12))
	var land: Vector2 = ig.pos
	var cleared: bool = ig.path.is_empty() and ig.after.is_empty()
	run(b2, 1.0)
	var stood: bool = ig.pos.distance_to(land) < 0.05
	var b3 = _heroes(team3)
	_start(b3)
	var ai = b3.heroes[0]
	run(b3, ai.passive.still + 1.0)
	var fort0: bool = ai.fort
	_dash_key(controls(b3), [ai], at)
	b3.step(DT)
	return check(prep and some and cleared and stood and fort0 and not ai.fort,
		"준비 단계 그대로 %s · 기절·성벽 위 빼고 이그니스만 %s · 길 지움 %s · 1초 뒤 그 자리 %s(%s → %s) · 요새화 %s → %s"
		% [prep, some, cleared, stood, land, ig.pos, fort0, ai.fort])
