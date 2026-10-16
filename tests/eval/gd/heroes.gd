extends "res://tests/eval/gd/lib.gd"
# WBS 3.7 영웅 6명(S97·S118~S121·I95~I102). lib.gd·buff.gd·aura.gd 머리의 계약에 더하는 API:
#   stage 키 heroes: [{kind, cell}, …] — 영웅 목록. 첫 영웅이 Battle.hero다. 없으면 hero_start가 기사 하나다
#   Battle.HERO_KINDS — 종류 → 수치(data/heroes/<종류>.tres, 스크립트 변수 사전) · Battle.heroes
#   Battle.use_skill(영웅 = 첫 영웅) · Battle.use_buff(영웅 = 첫 영웅)
#   영웅: kind · grade · skill_damage·skill_stun·skill_heal·skill_mend·skill_radius·skill_gap
#         · buff_mult·buff_expose·buff_guard·buff_ward·buff_slow·buff_radius·buff_time·buff_gap
#         · aura_radius·aura_guard·aura_haste·aura_work·aura_regen·aura_might·aura_stride·aura_gunnery
#   용병 kind "archer"(궁수)·"engineer"(공병) · 적 kind "flying"(나는 적) · 적 overrides 키 armor
# 수치는 영웅 필드에서 읽는다. 임시값이라(S97·S121) 밸런스를 바꿔도 효과를 재는 평가는 깨지지 않게. EV172·EV173만 표를 대조한다
# 성곽 맵은 repair.gd와 같다: 9행이 가로 성곽(성문 5·15·25열, 모두 닫힘), 위쪽(0~8행)이 마을, 아래쪽이 들판
# Q·W와 그 대기, 사제 오라 회복은 전투 단계에만 돈다(S136). 그래서 그것을 재는 평가는 _start로 전투 단계를 연 뒤 잰다

const H := Vector2i(10, 10)
const GATES := [Vector2i(5, 9), Vector2i(15, 9), Vector2i(25, 9)]
const ONE := [{"kind": "basic", "count": 1}]  # 적 하나짜리 웨이브
const EFFECTS := ["skill_damage", "skill_stun", "skill_heal", "skill_mend", "buff_mult", "buff_expose", "buff_guard", "buff_ward", "buff_slow",
	"aura_guard", "aura_haste", "aura_work", "aura_regen", "aura_might", "aura_stride", "aura_gunnery"]
const S97 := {
	"knight": {"skill_damage": 30, "skill_radius": 1.5, "skill_gap": 10, "buff_mult": 1.5, "buff_radius": 3, "buff_time": 5, "buff_gap": 20, "aura_guard": 0.15},
	"bowman": {"skill_damage": 20, "skill_radius": 2, "skill_gap": 12, "buff_expose": 0.3, "buff_radius": 3, "buff_time": 6, "buff_gap": 15, "aura_haste": 0.15},
	"mason": {"skill_mend": 50, "skill_radius": 2, "skill_gap": 15, "buff_ward": 0.5, "buff_radius": 3, "buff_time": 8, "buff_gap": 20, "aura_work": 0.3},
	"priest": {"skill_heal": 25, "skill_radius": 2, "skill_gap": 12, "buff_guard": 0.3, "buff_radius": 3, "buff_time": 6, "buff_gap": 25, "aura_regen": 1},
	"general": {"skill_damage": 20, "skill_stun": 2, "skill_radius": 2, "skill_gap": 14, "buff_mult": 1.3, "buff_radius": 4, "buff_time": 6, "buff_gap": 30, "aura_might": 0.15, "aura_stride": 0.1},
	"mage": {"skill_damage": 50, "skill_radius": 2, "skill_gap": 12, "buff_slow": 0.5, "buff_radius": 3, "buff_time": 5, "buff_gap": 20, "aura_gunnery": 0.15},
}
const S121 := {  # 등급, 체력, 공격력, 사거리, 공격 간격, 속도
	"knight": [1, 100, 3, 1.5, 1.0, 3], "bowman": [1, 70, 3, 4, 1.0, 3], "mason": [2, 120, 3, 1.5, 1.0, 3],
	"priest": [2, 90, 2, 3, 1.0, 3], "general": [3, 150, 5, 1.5, 1.0, 3], "mage": [3, 90, 5, 4, 1.2, 3],
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

# EV172 · S97: 6명의 Q·W·오라 수치가 표와 같고, 표에 없는 효과는 없다
func ev172():
	var kinds: Dictionary = battle().HERO_KINDS
	for k in S97:
		if not kinds.has(k):
			return "영웅 %s가 없다(%s)" % [k, kinds.keys()]
		var want: Dictionary = S97[k].merged({"aura_radius": 3})
		for key in EFFECTS + want.keys():
			var w: float = want.get(key, 1.0 if key == "buff_mult" else 0.0)
			if not is_equal_approx(float(kinds[k].get(key, -1.0)), w):
				return "%s의 %s가 %s다(%s여야 한다)" % [k, key, kinds[k].get(key), w]
	return ""

# EV173 · S121: 6종의 파일이 있고 등급·기본 능력치가 표와 같다. hero_start로 낸 영웅은 기사다
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
	return check(b.hero != null and b.hero.kind == "knight", "hero_start로 낸 영웅이 %s다(knight여야 한다)" % (b.hero.kind if b.hero else "없음"))

# EV174 · S118: 시험 스테이지의 영웅은 기사 하나다
func ev174():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	return check(b.heroes.size() == 1 and b.hero.kind == "knight", "시험 스테이지 영웅이 %s다(기사 하나여야 한다)" % [b.heroes.map(func(h): return h.kind)])

# EV175 · S119: Q·W는 고른 영웅이, 고른 영웅이 없으면 첫 영웅이 쓴다
func ev175():
	var b = _heroes([_hero("knight", Vector2i(5, 5)), _hero("mage", Vector2i(10, 5))])
	var c = controls(b)
	_start(b)
	var k = b.heroes[0]
	var m = b.heroes[1]
	_key(c, KEY_Q)
	var first := [k.skill_uses, m.skill_uses]
	click(c, MOUSE_BUTTON_LEFT, px(Vector2i(10, 5)))
	if c.selected != [m]:
		return "마도사를 고르지 못했다(%s)" % [c.selected]
	_key(c, KEY_Q)
	_key(c, KEY_W)
	return check(first == [1, 0] and k.skill_uses == 1 and m.skill_uses == 1 and k.buff_ready() and not m.buff_ready(),
		"고르지 않고 Q: 기사·마도사 %s · 마도사를 고르고 Q: 기사 %d·마도사 %d · W 뒤 다시 쓸 수 있나: 기사 %s·마도사 %s" % [first, k.skill_uses, m.skill_uses, k.buff_ready(), m.buff_ready()])

# EV176 · I98: 궁수·장군·마도사의 Q는 2칸 안 적에게 피해를 주고, 장갑을 받는다
func ev176():
	for kind in ["bowman", "general", "mage"]:
		var b = _heroes([_hero(kind, H)])
		_start(b)
		var near = _dummy(b, H + Vector2i(2, 0))
		var hard = _dummy(b, H + Vector2i(0, 2), {"armor": 2.0})
		var far = _dummy(b, H + Vector2i(3, 0))
		var hurt: float = b.hero.skill_damage
		b.use_skill()
		var got := [near.max_hp - near.hp, hard.max_hp - hard.hp, far.max_hp - far.hp]
		if not (is_equal_approx(got[0], hurt) and is_equal_approx(got[1], hurt - 2.0) and got[2] == 0.0):
			return "%s의 Q 피해(2칸 안·장갑 2·3칸 밖)가 %s다(%s·%s·0이어야 한다)" % [kind, got, hurt, hurt - 2.0]
	return ""

# EV177 · I98: 장군 Q에 맞은 적은 기절해 움직이지도 치지도 않는다
func ev177():
	var b = _heroes([_hero("general", H)])
	var m = b.place_merc("soldier", H + Vector2i(2, 1))
	_start(b)
	b.spawn_enemy("basic", H + Vector2i(1, 1), {"hp": BIG, "damage": 5.0})  # 옆 용병을 친다
	var walker = b.spawn_enemy("basic", H + Vector2i(0, -2), {"hp": BIG, "sight": 0, "damage": 0})  # 거점으로 걷는다
	b.use_skill()
	var at: Vector2 = walker.pos
	var hp0: float = m.hp
	run(b, 1.8)
	var still: bool = m.hp == hp0 and walker.pos.distance_to(at) < 0.01
	var back := run(b, 3.0, func(): return m.hp < hp0)
	run(b, 1.0)
	return check(still and back and walker.pos.distance_to(at) > 0.5,
		"기절 동안 용병 체력 %s → %s · 걷는 적 %s → %s · 그 뒤 다시 침 %s" % [hp0, m.hp, at, walker.pos, back])

# EV178 · I98: 사제 Q는 2칸 안의 사제 자신과 용병을 회복하고, 최대 체력을 넘지 않는다
func ev178():
	var b = _heroes([_hero("priest", H)])
	var p = b.hero
	var a = b.place_merc("soldier", H + Vector2i(1, 0))
	var full = b.place_merc("soldier", H + Vector2i(0, 2))
	var far = b.place_merc("soldier", H + Vector2i(3, 0))
	_start(b)
	b.damage(p, 40)
	b.damage(a, 30)
	b.damage(full, 10)
	b.damage(far, 30)
	var heal: float = p.skill_heal
	b.use_skill()
	var got := [p.max_hp - p.hp, a.max_hp - a.hp, full.max_hp - full.hp, far.max_hp - far.hp]
	var want := [maxf(40 - heal, 0), maxf(30 - heal, 0), maxf(10 - heal, 0), 30.0]
	for i in 4:
		if not is_equal_approx(got[i], want[i]):
			return "Q 뒤 잃은 체력(사제·옆 용병·거의 찬 용병·먼 용병)이 %s다(%s여야 한다)" % [got, want]
	return ""

# EV179 · S120: 축성가 Q는 2칸 안의 구조물·성곽 칸을 회복하고, 거점은 회복하지 않는다
func ev179():
	var b = _castle({"heroes": [_hero("mason", Vector2i(12, 8))], "base": Vector2i(12, 7), "base_hp": 100})
	var t = b.build("tower", Vector2i(12, 10))
	if t == null:
		return "타워를 짓지 못했다"
	_start(b)
	var k = b.castle[Vector2i(11, 9)]
	var far = b.castle[Vector2i(20, 9)]
	b.damage(t, 60)
	b.damage(k, 100)
	b.damage(b.base, 30)
	b.damage(far, 100)
	var mend: float = b.hero.skill_mend
	b.use_skill()
	var got := [t.max_hp - t.hp, k.max_hp - k.hp, b.base.max_hp - b.base.hp, far.max_hp - far.hp]
	var want := [maxf(60 - mend, 0), maxf(100 - mend, 0), 30.0, 100.0]
	for i in 4:
		if not is_equal_approx(got[i], want[i]):
			return "Q 뒤 잃은 체력(타워·옆 성벽 칸·거점·먼 성벽 칸)이 %s다(%s여야 한다)" % [got, want]
	return ""

# EV180 · I99: 궁수 W를 받은 적은 장갑을 뺀 피해에 배율만큼 더 다친다
func ev180():
	var b = _heroes([_hero("bowman", H)])
	_start(b)
	var near = _dummy(b, H + Vector2i(3, 0), {"armor": 2.0})
	var far = _dummy(b, H + Vector2i(4, 0), {"armor": 2.0})
	var x: float = b.hero.buff_expose
	b.use_buff()
	var got := [_hit(b, near, 10.0), _hit(b, far, 10.0)]
	run(b, b.hero.buff_time + 0.1)
	var after := _hit(b, near, 10.0)
	return check(is_equal_approx(got[0], 8.0 * (1.0 + x)) and is_equal_approx(got[1], 8.0) and is_equal_approx(after, 8.0),
		"피해 10에 깎인 양: 3칸 안 %s · 4칸 밖 %s · 지속 시간 뒤 %s (%s·8·8이어야 한다)" % [got[0], got[1], after, 8.0 * (1.0 + x)])

# EV181 · S120: 축성가 W를 받은 구조물·성곽 칸은 덜 다치고, 거점은 그대로다
func ev181():
	var b = _castle({"heroes": [_hero("mason", Vector2i(12, 8))], "base": Vector2i(12, 7), "base_hp": 100})
	var t = b.build("tower", Vector2i(12, 10))
	if t == null:
		return "타워를 짓지 못했다"
	_start(b)
	var k = b.castle[Vector2i(11, 9)]
	var w: float = b.hero.buff_ward
	b.use_buff()
	var got := [_hit(b, t, 20.0), _hit(b, k, 20.0), _hit(b, b.base, 20.0)]
	run(b, b.hero.buff_time + 0.1)
	var after := _hit(b, t, 20.0)
	var want := [20.0 * (1.0 - w), 20.0 * (1.0 - w), 20.0]
	return check(is_equal_approx(got[0], want[0]) and is_equal_approx(got[1], want[1]) and is_equal_approx(got[2], want[2]) and is_equal_approx(after, 20.0),
		"피해 20에 깎인 양(타워·성벽 칸·거점) %s · 지속 시간 뒤 타워 %s (%s·20이어야 한다)" % [got, after, want])

# EV182 · I99: 사제 W를 받은 영웅·용병은 덜 다친다
func ev182():
	var b = _heroes([_hero("priest", H)])
	var p = b.hero
	var a = b.place_merc("soldier", H + Vector2i(1, 0))
	var far = b.place_merc("soldier", H + Vector2i(4, 0))
	_start(b)
	var g: float = p.buff_guard
	b.use_buff()
	var got := [_hit(b, p, 10.0), _hit(b, a, 10.0), _hit(b, far, 10.0)]
	run(b, p.buff_time + 0.1)
	var after := _hit(b, a, 10.0)
	var want := 10.0 * (1.0 - g)
	return check(is_equal_approx(got[0], want) and is_equal_approx(got[1], want) and is_equal_approx(got[2], 10.0) and is_equal_approx(after, 10.0),
		"피해 10에 깎인 양(사제·옆 용병·먼 용병) %s · 지속 시간 뒤 옆 용병 %s (%s·%s·10·10이어야 한다)" % [got, after, want, want])

# EV183 · I99: 마도사 W를 받은 걷는 적·나는 적은 느려진다
func ev183():
	var b = _heroes([_hero("mage", H)])
	_start(b)
	var walk = b.spawn_enemy("basic", H + Vector2i(1, 0), {"hp": BIG, "sight": 0, "damage": 0})
	var fly = b.spawn_enemy("flying", H + Vector2i(0, 1), {"hp": BIG, "sight": 0, "damage": 0})
	var far = b.spawn_enemy("basic", H + Vector2i(0, -5), {"hp": BIG, "sight": 0, "damage": 0})
	var s: float = b.hero.buff_slow
	b.use_buff()
	var got := _moved(b, [walk, fly, far], 1.0)
	run(b, b.hero.buff_time)
	var again: float = _moved(b, [walk], 1.0)[0]
	var want := [walk.speed * (1.0 - s), fly.speed * (1.0 - s), far.speed]
	for i in 3:
		if absf(got[i] - want[i]) > 0.1:
			return "W 뒤 1초에 간 거리(걷는 적·나는 적·먼 적)가 %s다(%s여야 한다)" % [got, want]
	return check(absf(again - walk.speed) <= 0.1, "지속 시간 뒤 걷는 적이 1초에 %s칸 갔다(%s여야 한다)" % [again, walk.speed])

# EV184 · I100: 궁수 오라 안의 원거리 용병은 더 자주 친다
func ev184():
	var b = _heroes([_hero("bowman", Vector2i(5, 10))])
	var near = b.place_merc("archer", Vector2i(6, 10))
	var far = b.place_merc("archer", Vector2i(20, 10))
	_dummy(b, Vector2i(6, 5))  # near의 과녁. 궁수 영웅(사거리 4)에게서 5칸 넘게 떨어졌다
	_dummy(b, Vector2i(20, 5))
	var n := [0, 0]
	var last := [near.cooldown, far.cooldown]
	run(b, 20.0, func():
		for i in 2:
			var u = [near, far][i]
			if u.cooldown > last[i]:
				n[i] += 1
			last[i] = u.cooldown
		return false)
	var ratio := float(n[0]) / maxf(n[1], 1)
	return check(ratio >= 1.08 and ratio <= 1.22, "20초 동안 친 횟수: 오라 안 %d · 밖 %d (비 %.2f, 1.08~1.22여야 한다)" % [n[0], n[1], ratio])

# EV185 · I100: 축성가 오라 안의 공병은 더 빨리 짓는다
func ev185():
	var b = _heroes([_hero("mason", H)], {"waves": [[{"kind": "basic", "count": 1}]]})
	var near = b.place_merc("engineer", H + Vector2i(1, 0))
	var far = b.place_merc("engineer", H + Vector2i(0, 8))
	_start(b)
	var t1 = b.build("tower", H + Vector2i(2, 0))
	var t2 = b.build("tower", H + Vector2i(1, 8))
	if t1 == null or t2 == null or t1.worker != near or t2.worker != far:
		return "공병이 각자 옆 타워를 맡지 않았다"
	var done := [-1.0, -1.0]
	var t := [0.0]
	run(b, 10.0, func():
		for i in 2:
			if done[i] < 0.0 and [t1, t2][i].complete:
				done[i] = t[0]
		t[0] += DT
		return done[0] >= 0.0 and done[1] >= 0.0)
	var bt: float = b.STRUCTURE_KINDS.tower.build_time
	var w: float = b.hero.aura_work
	return check(absf(done[0] - bt / (1.0 + w)) <= 0.3 and absf(done[1] - bt) <= 0.3,
		"다 짓는 데 걸린 시간: 오라 안 %.2f초 · 밖 %.2f초 (%.2f·%.2f여야 한다)" % [done[0], done[1], bt / (1.0 + w), bt])

# EV186 · I100: 사제 오라 안의 용병은 체력이 차오르고, 영웅과 오라 밖 용병은 그대로다
func ev186():
	var b = _heroes([_hero("priest", H), _hero("knight", H + Vector2i(0, 1))])
	var near = b.place_merc("soldier", H + Vector2i(1, 0))
	var far = b.place_merc("soldier", H + Vector2i(5, 0))
	var k = b.heroes[1]
	_start(b)
	for x in [near, far, k]:
		b.damage(x, 20)
	var hp := [near.hp, far.hp, k.hp]
	run(b, 5.0)
	var got := [near.hp - hp[0], far.hp - hp[1], k.hp - hp[2]]
	var r: float = b.hero.aura_regen
	return check(absf(got[0] - 5.0 * r) <= 0.11 and got[1] == 0.0 and got[2] == 0.0, "5초 동안 오른 체력(오라 안 용병·밖 용병·오라 안 기사) %s (%s·0·0이어야 한다)" % [got, 5.0 * r])

# EV187 · I100: 장군 오라 안의 용병은 더 세게 치고 더 빨리 걷는다
func ev187():
	var b = _heroes([_hero("general", H)])
	var a = b.place_merc("soldier", H + Vector2i(2, 0))
	var o = b.place_merc("soldier", H + Vector2i(10, 0))
	var da = _dummy(b, H + Vector2i(3, 0))  # 장군(사거리 1.5)에게서 3칸
	var do = _dummy(b, H + Vector2i(11, 0))
	var g = b.hero
	var hits := [_next_hit(b, da), _next_hit(b, do)]
	b.damage(da, BIG)
	b.damage(do, BIG)
	b.order_move([a], H + Vector2i(2, 3))
	b.order_move([o], H + Vector2i(10, 3))
	var at := [a.pos, o.pos]
	for i in 10:  # 0.5초. run(b, 0.5)는 DT를 더해 가다 오차로 한 번 더 돌 수 있어 걸음 수를 정해 둔다
		b.step(DT)
	var walked := [a.pos.distance_to(at[0]), o.pos.distance_to(at[1])]
	var want := [a.damage * (1.0 + g.aura_might), o.damage, a.speed * (1.0 + g.aura_stride) * 0.5, o.speed * 0.5]
	return check(is_equal_approx(hits[0], want[0]) and is_equal_approx(hits[1], want[1]) and absf(walked[0] - want[2]) <= 0.03 and absf(walked[1] - want[3]) <= 0.03,
		"한 방(오라 안·밖) %s · 0.5초에 걸은 거리 %s (%s여야 한다)" % [hits, walked, want])

# EV188 · I100: 마도사 오라 안의 타워는 더 세게 쏜다
func ev188():
	var b = _heroes([_hero("mage", H)])
	var t1 = b.build("tower", H + Vector2i(2, 0))
	var t2 = b.build("tower", H + Vector2i(12, 0))
	if t1 == null or t2 == null:
		return "타워를 짓지 못했다"
	var d1 = _dummy(b, H + Vector2i(4, 3))  # t1에서 3.6칸, 마도사(사거리 4)에게서 5칸
	var d2 = _dummy(b, H + Vector2i(14, 3))
	var hits := [_next_hit(b, d1), _next_hit(b, d2)]
	var want := [t1.damage * (1.0 + b.hero.aura_gunnery), t2.damage]
	return check(is_equal_approx(hits[0], want[0]) and is_equal_approx(hits[1], want[1]), "타워 한 방(오라 안·밖) %s (%s여야 한다)" % [hits, want])

# EV189 · I96: 같은 종류의 효과는 오라와 W를 가리지 않고 가장 큰 값 하나만 걸린다
func ev189():
	var b = _heroes([_hero("knight", H), _hero("general", H + Vector2i(0, 2)), _hero("priest", H + Vector2i(0, -2))])
	var m = b.place_merc("soldier", H + Vector2i(2, 0))  # 기사 오라·W, 장군 오라, 사제 W 안
	_start(b)
	var d = _dummy(b, H + Vector2i(3, 0))  # 세 영웅의 사거리 밖
	b.use_buff(b.heroes[0])
	b.use_buff(b.heroes[2])
	var hit := _next_hit(b, d)
	var hurt := _hit(b, m, 10.0)
	var mult: float = b.heroes[0].buff_mult
	var guard: float = maxf(b.heroes[0].aura_guard, b.heroes[2].buff_guard)
	return check(is_equal_approx(hit, m.damage * mult) and is_equal_approx(hurt, 10.0 * (1.0 - guard)),
		"한 방 %s(%s여야 한다) · 피해 10에 깎인 양 %s(%s여야 한다)" % [hit, m.damage * mult, hurt, 10.0 * (1.0 - guard)])

# EV190 · I97: 약한 W는 강한 W가 걸린 대상에 걸리지 않는다
func ev190():
	var b = _heroes([_hero("knight", H), _hero("general", H + Vector2i(0, 3))])
	var m = b.place_merc("soldier", H + Vector2i(2, 0))  # 기사 W 안, 장군 W 안, 장군 오라 밖
	_start(b)
	var d = _dummy(b, H + Vector2i(3, 0))
	var k = b.heroes[0]
	b.use_buff(k)
	b.use_buff(b.heroes[1])
	var strong := _next_hit(b, d)
	run(b, k.buff_time + 0.2)
	var plain := _next_hit(b, d)
	return check(is_equal_approx(strong, m.damage * k.buff_mult) and is_equal_approx(plain, m.damage),
		"한 방: 두 W 뒤 %s(%s여야 한다) · 기사 W가 끝난 뒤 %s(%s여야 한다)" % [strong, m.damage * k.buff_mult, plain, m.damage])

# EV191 · I102: 영웅마다 자기 시작 칸으로 돌아오고, 배치 상한은 영웅을 세지 않는다
func ev191():
	var one := [{"kind": "basic", "count": 1}]
	var ka := Vector2i(5, 5)
	var pa := Vector2i(8, 5)
	var b = _heroes([_hero("knight", ka), _hero("priest", pa)], {"waves": [one, one], "merc_cap": 1})
	b.start_battle()
	run(b, 1.0)
	for h in b.heroes:
		b.damage(h, BIG)
	clear_wave(b)
	var back: bool = b.state == "prep" and b.heroes.all(func(h): return h.present and h.hp == 1.0) and near(b.heroes[0].pos, ka, 0.01) and near(b.heroes[1].pos, pa, 0.01)  # 체력 1로 돌아온다(S138)
	var m = b.place_merc("soldier", Vector2i(12, 5))
	return check(back and m != null, "돌아옴 %s(%s) · 상한 1에서 용병 %s" % [back, b.heroes.map(func(h): return [h.kind, h.pos, h.hp]), m])

# 기사(첫 영웅)·마도사를 낸 판의 전투 단계와 그 컨트롤
func _pair_in_battle() -> Array:
	var b = _heroes([_hero("knight", Vector2i(5, 5)), _hero("mage", Vector2i(10, 5))],
		{"waves": [[{"kind": "basic", "count": 1}], [{"kind": "basic", "count": 1}]]})
	var c = controls(b)
	_start(b)
	return [b, c]

# EV231 · I126: 첫 영웅이 쓰러지면 고르지 않고 누른 Q는 살아 있는 다음 영웅이 쓴다. 쓰러진 영웅을 골라 둔 채 누른 Q도 그렇다
func ev231():
	var bc := _pair_in_battle()
	_down_first_then_q(bc)
	var free_q: int = bc[0].heroes[1].skill_uses
	var de := _pair_in_battle()
	_key(de[1], KEY_F1)
	var picked: bool = de[1].selected == [de[0].heroes[0]]
	_down_first_then_q(de)
	return check(free_q == 1 and picked and de[0].heroes[1].skill_uses == 1,
		"고르지 않고 Q: 마도사 %d번 · 기사를 고른 채(%s) 기사가 쓰러진 뒤 Q: 마도사 %d번" % [free_q, picked, de[0].heroes[1].skill_uses])

# 첫 영웅(기사)을 쓰러뜨린 뒤 Q를 누른다
func _down_first_then_q(bc: Array) -> void:
	bc[0].damage(bc[0].heroes[0], BIG)
	_key(bc[1], KEY_Q)

# EV238 · S136: 준비 단계의 Q·W 키는 아무 일도 하지 않고 재사용 대기도 시작하지 않는다. 전투 단계에는 쓴다
func ev238():
	var b = _heroes([_hero("knight", H)])
	var c = controls(b)
	var d = _dummy(b, H + Vector2i(1, 0))
	var k = b.hero
	_key(c, KEY_Q)
	_key(c, KEY_W)
	var idle: bool = k.skill_uses == 0 and k.skill_ready() and k.buff_ready() and d.hp == d.max_hp
	b.start_battle()
	_key(c, KEY_Q)
	_key(c, KEY_W)
	return check(idle and k.skill_uses == 1 and d.hp < d.max_hp and not k.buff_ready(),
		"준비 단계 Q·W 뒤 그대로 %s · 전투 단계: Q %d번, 과녁 체력 %s/%s, W 대기 시작 %s" % [idle, k.skill_uses, d.hp, d.max_hp, not k.buff_ready()])

# EV239 · S136: 전투 단계가 아닐 때(준비 단계·라운드 사이)는 Q·W 대기가 줄지 않고 사제 오라 회복도 멈춘다
func ev239():
	var b = _heroes([_hero("knight", H), _hero("priest", H + Vector2i(0, 2))], {"rounds": [[ONE, ONE], [ONE]]})
	var k = b.hero
	var m = b.place_merc("soldier", H + Vector2i(1, 0))  # 사제 오라 안
	_start(b)
	b.use_skill(k)
	b.use_buff(k)
	b.damage(m, 20)
	clear_wave(b)
	var now := func(): return [k.skill_cooldown, k.buff_cooldown, m.hp]
	var at: Array = now.call()
	run(b, 10.0)
	var prep: bool = b.state == "prep" and now.call() == at
	var after_prep: Array = now.call()
	_start(b)
	run(b, 1.0)
	var fight: bool = k.skill_cooldown < at[0] and m.hp > at[2]
	clear_wave(b)
	var between: Array = now.call()
	run(b, 10.0)
	var cleared: bool = b.state == "cleared" and now.call() == between
	return check(prep and fight and cleared,
		"준비 단계 10초 [Q 대기, W 대기, 용병 체력] %s → %s · 전투 단계 1초에 줄고 오름 %s · 라운드 사이(%s) 10초 %s → %s" % [at, after_prep, fight, b.state, between, now.call()])
