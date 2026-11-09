extends "res://tests/eval/gd/sky.gd"
# 4라운드 하늘 둥지 묶음 ②(S303 2026-11-10 변경·S307·S308·I253·I254). lib.gd·sky.gd 머리의 계약에 더하는 API:
#   적 kind "storm_harpy"(폭풍날개 하피, S307) · "snatch_harpy"(낚아채기 하피, S308)
#   적 cast {id "gust", dir(부채꼴 방향, 라디안), blow(뿜는 중이면 참)} — 돌풍 예고·뿜기(S307)
#   적 cast {id "snatch", at(떨어뜨릴 자리)} — 떨어뜨릴 예고 · {id "snatch", pick 참} — 돌 줍기(S308)
#   적 carry — 든 것: 용병(Unit)·주민(Villager)·"stone", 없으면 null(S308) · effect(용병, "lift") — 들림 · effect(하피, "down") — 내려앉음
#   Battle.missiles — 날아가는 투사체(Missile: src 쏜 쪽, look "arrow"·"ball"·"shell")(S178) · Battle.walls — 성곽 차지 칸 → 성곽 Block
#   Battle.people — 주민(Villager: pos·inside·hp·alive·home·m)(evac.gd와 같다) · 구조물 lost — 죽은 식구 수
#   BattleView: _foe_tells() — 어둠에 숨어도 그리는 일반 적 예고(S279)

const ST := "storm_harpy"
const SN := "snatch_harpy"

# 성곽 판(sky.gd _castle과 같다)에 over를 더한다
func _fort(over := {}):
	var walls := []
	for x in 30:
		if Vector2i(x, 9) not in GATES:
			walls.append(Vector2i(x, 9))
	var st := {"base": Vector2i(15, 4), "spawns": [Vector2i(15, 19)], "village": Rect2i(0, 0, 30, 9), "base_hp": BIG,
		"castle": {"walls": walls, "gates": GATES, "wall_hp": 300, "gate_hp": 150}}
	st.merge(over, true)
	return battle(st)

# p에서 가장 가까운 서 있는 성곽 칸까지의 [거리, 그 칸 가운데](I253 ①)
func _wall_near(b, p: Vector2) -> Array:
	var best := INF
	var at := Vector2.ZERO
	for c in b.walls:
		if b.walls[c].alive and p.distance_to(Vector2(c)) < best:
			best = p.distance_to(Vector2(c))
			at = Vector2(c)
	return [best, at]

func _gust(e) -> bool:
	return e.cast != null and e.cast.id == "gust"

func _blowing(e) -> bool:
	return _gust(e) and e.cast.get("blow", false)

func _picking(e) -> bool:
	return e.cast != null and e.cast.id == "snatch" and e.cast.get("pick", false)

# 성곽 판 b에 폭풍날개 하피(체력 큼)를 (15,19)에 내보내 뿜기 시작할 때까지 돌린다. 하피, 못 하면 까닭(글)
func _storm(b):
	var why := _need(b, [ST])
	if why != "":
		return why
	var e = b.spawn_enemy(ST, Vector2i(15, 19), {"hp": BIG})
	if not run(b, 15.0, func(): return _blowing(e)):
		return "15초 안에 돌풍을 뿜지 않았다(자리 %s · cast %s)" % [e.pos, e.cast]
	return e

# 성곽 판의 성벽 위 cell에 영웅 kind(레벨 5)를 올린다. [판, 영웅], 못 하면 까닭(글)
func _up_hero(kind: String, cell: Vector2i):
	var b = _fort({"heroes": [{"kind": kind, "cell": IN, "level": 5}]})
	var h = b.heroes[0]
	b.order_move([h], cell)
	if not run(b, 30.0, func(): return h.on_wall and near(h.pos, cell)):
		return "%s를 성벽 위 %s에 올리지 못했다" % [kind, cell]
	return [b, h]

# EV853 판: 궁수 (10,10), 병사 둘 (13,12)·(13,12.7)(모두 체력 100, 공격력 0)과 (3,10)에서 내보낸 낚아채기 하피(체력 큼). [판, 궁수, 병사1, 병사2, 하피]
func _snatch_board(stage := {}):
	var r := _one("archer", Vector2i(10, 10), {"hp": 100.0, "damage": 0}, stage)
	var b = r[0]
	var why := _need(b, [SN])
	if why != "":
		return why
	var s1 = b.place_merc("soldier", Vector2i(13, 12), {"hp": 100.0, "damage": 0})
	var s2 = b.place_merc("soldier", Vector2i(13, 13), {"hp": 100.0, "damage": 0})
	s2.pos = Vector2(13, 12.7)
	return [b, r[1], s1, s2]

# EV853 판에서 하피가 궁수를 든 지 0.5초까지 돌린다. [판, 궁수, 하피], 못 하면 까닭(글)
func _lifted():
	var x = _snatch_board()
	if x is String:
		return x
	var b = x[0]
	var e = b.spawn_enemy(SN, Vector2i(3, 10), {"hp": BIG})
	if not run(b, 10.0, func(): return e.get("carry") != null):
		return "10초 안에 아무것도 들지 않았다(자리 %s)" % e.pos
	if e.carry != x[1]:
		return "든 것이 (10,10) 궁수가 아니다(%s)" % [e.carry]
	run(b, 0.5)
	return [b, x[1], e]

# EV850 · S307: 성곽에서 4칸 앞에 멈추고, 1초 예고 뒤 성곽 칸 쪽 부채꼴로 돌풍을 계속 뿜으며 움직이지 않는다
func ev850():
	var b = _fort()
	var why := _need(b, [ST])
	if why != "":
		return why
	var e = b.spawn_enemy(ST, Vector2i(15, 19), {"hp": BIG})
	var t := 0.0
	var stop_t := -1.0
	var at := Vector2.ZERO
	var tell_t := -1.0
	var blow_t := -1.0
	while t < 12.0 and blow_t < 0.0:
		var p0: Vector2 = e.pos
		b.step(DT)
		t += DT
		if stop_t < 0.0 and e.pos == p0:
			stop_t = t
			at = e.pos
		if tell_t < 0.0 and _gust(e) and not e.cast.get("blow", false):
			tell_t = t
		if blow_t < 0.0 and _blowing(e):
			blow_t = t
	if stop_t < 0.0 or stop_t > 10.0:
		return "10초 안에 멈추지 않았다(자리 %s)" % e.pos
	var near_wall := _wall_near(b, at)
	if near_wall[0] < 3.8 or near_wall[0] > 4.0 + 0.001:
		return "멈춘 자리 %s에서 가장 가까운 성곽 칸까지 %.2f칸(3.8~4)" % [at, near_wall[0]]
	if tell_t < 0.0 or tell_t - stop_t > 0.1 + 0.001:
		return "멈춘 뒤 0.1초 안에 돌풍 예고를 시작하지 않았다(멈춤 %.2f초 · 예고 %.2f초)" % [stop_t, tell_t]
	if blow_t < 0.0 or blow_t - tell_t < 0.9 - 0.001 or blow_t - tell_t > 1.1 + 0.001:
		return "예고를 시작한 뒤 %.2f초에 뿜었다(0.9~1.1)" % (blow_t - tell_t)
	var dir: float = e.cast.get("dir", INF)
	var want: float = (near_wall[1] - at).angle()
	if absf(angle_difference(dir, want)) > deg_to_rad(1.0):
		return "부채꼴 방향 %.1f°(성곽 칸 쪽 %.1f°여야 한다)" % [rad_to_deg(dir), rad_to_deg(want)]
	var moved := 0.0
	var kept := true
	for i in int(5.0 / DT):
		b.step(DT)
		moved = maxf(moved, e.pos.distance_to(at))
		kept = kept and _blowing(e)
	return check(kept and moved <= 0.05, "뿜기 5초: 이어짐 %s · 움직임 %.2f칸" % [kept, moved])

# EV851 · S307: 돌풍을 지나는 아군 화살은 날려 사라지고(부채꼴 밖 화살은 맞힌다), 구슬은 지나가며, 봉인하면 화살이 다시 맞는다
func ev851():
	var b = _fort()
	var a = _up(b, "archer", Vector2i(14, 9), {"hp": BIG, "damage": 0, "accuracy": 1.0})
	if a == null:
		return "궁수를 성벽 위 (14,9)에 올리지 못했다"
	var e = _storm(b)
	if e is String:
		return e
	a.damage = 2.0
	var shot := false
	var h0: float = e.hp
	for i in int(5.0 / DT):
		b.step(DT)
		shot = shot or b.missiles.any(func(m): return m.src == a and m.look == "arrow")
	if not shot or e.hp != h0:
		return "뿜는 동안 (14,9) 궁수: 화살이 나감 %s · 하피 체력 %.0f → %.0f(그대로여야 한다)" % [shot, h0, e.hp]
	e.fx["test_seal"] = {"seal": true, "left": 30.0}
	if not run(b, 5.0, func(): return e.hp < h0):
		return "봉인된 하피를 (14,9) 궁수 화살이 5초 동안 깎지 못했다"
	var c = _fort()
	var f = c.place_merc("archer", Vector2i(19, 13), {"hp": BIG, "damage": 0, "accuracy": 1.0})
	var g = _storm(c)
	if g is String:
		return g
	f.damage = 2.0
	var g0: float = g.hp
	if not run(c, 5.0, func(): return g.hp < g0):
		return "부채꼴 밖 (19,13) 궁수가 뿜는 하피를 5초 동안 깎지 못했다(궁수 %s · 하피 %s)" % [f.pos, g.pos]
	var r = _up_hero("ignis", Vector2i(14, 9))
	if r is String:
		return r
	r[1].range = 6.0
	var q = _storm(r[0])
	if q is String:
		return q
	var q0: float = q.hp
	return check(run(r[0], 5.0, func(): return q.hp < q0), "성벽 위 (14,9) 이그니스의 구슬이 뿜는 하피를 5초 동안 깎지 못했다")

# EV852 · S307: 기절하면 돌풍이 끊기고(비틀거리지 않음) 끊긴 때부터 4초 뒤 다시 예고한다. 봉인되면 뿜지 않는다
func ev852():
	var b = _fort()
	var e = _storm(b)
	if e is String:
		return e
	e.fx["test_stun"] = {"stun": true, "left": 0.5}
	b.step(DT)
	var off: bool = e.cast == null
	var reel: bool = b.effect(e, "expose") != null
	var t := DT
	var tell_t := -1.0
	var blow_t := -1.0
	while t < 8.0 and blow_t < 0.0:
		b.step(DT)
		t += DT
		if tell_t < 0.0 and _gust(e):
			tell_t = t
		if blow_t < 0.0 and _blowing(e):
			blow_t = t
	if not off or reel or tell_t < 3.9 - 0.001 or tell_t > 4.3 + 0.001 or blow_t - tell_t < 0.9 - 0.001 or blow_t - tell_t > 1.1 + 0.001:
		return "기절: 돌풍 꺼짐 %s · 비틀거림 %s · 다시 예고 %.2f초 뒤(3.9~4.3) · 그 뒤 뿜기 %.2f초(0.9~1.1)" % [off, reel, tell_t, blow_t - tell_t]
	var c = _fort()
	var q = c.spawn_enemy(ST, Vector2i(15, 19), {"hp": BIG})
	q.fx["test_seal"] = {"seal": true, "left": 30.0}
	var never := true
	for i in int(10.0 / DT):
		c.step(DT)
		never = never and not _gust(q)
	return check(never, "봉인된 하피가 10초 안에 돌풍 예고를 시작했다(cast %s)" % [q.cast])

# EV853 · S308: 가장 가까운 용병을 들고, 아군이 가장 몰린 곳에 2초 예고 뒤 떨어뜨려 원 안 아군과 떨어진 용병에 피해를 준다. 대기 5초
func ev853():
	var x = _snatch_board()
	if x is String:
		return x
	var b = x[0]
	var a = x[1]
	var s1 = x[2]
	var s2 = x[3]
	var e = b.spawn_enemy(SN, Vector2i(3, 10), {"hp": BIG})
	if not run(b, 10.0, func(): return e.get("carry") != null):
		return "10초 안에 아무것도 들지 않았다(자리 %s)" % e.pos
	if e.carry != a:
		return "든 것이 (10,10) 궁수가 아니다(%s)" % [e.carry]
	if e.cast == null or e.cast.id != "snatch" or not e.cast.has("at"):
		return "든 스텝에 떨어뜨릴 예고가 없다(cast %s)" % [e.cast]
	var spot: Vector2 = e.cast.at
	if spot.distance_to(s1.pos) > 0.01:
		return "떨어뜨릴 자리 %s((13,12) 병사 자리 %s여야 한다)" % [spot, s1.pos]
	var want_s: float = 100.0 - 10.0 * b.armor_mult(b.armor_of(s1))
	var want_a: float = 100.0 - 12.0 * b.armor_mult(b.armor_of(a))
	var t := 0.0
	var drop_t := -1.0
	var stuck := true
	var lifted := true
	while t < 3.0 and drop_t < 0.0:
		b.step(DT)
		t += DT
		if e.get("carry") == a:
			stuck = stuck and a.pos.distance_to(e.pos) <= 0.001
			lifted = lifted and b.effect(a, "lift") != null
		else:
			drop_t = t
	if not stuck or not lifted:
		return "든 동안: 궁수가 하피 자리에 붙어 있음 %s · 들림 %s" % [stuck, lifted]
	if drop_t < 1.9 - 0.001 or drop_t > 2.1 + 0.001:
		return "든 뒤 %.2f초에 떨어뜨렸다(1.9~2.1)" % drop_t
	if a.pos.distance_to(spot) > 0.6 or b.effect(a, "lift") != null:
		return "떨어진 궁수 자리 %s(예고 자리 %s에서 0.6칸 안) · 들림 남음 %s" % [a.pos, spot, b.effect(a, "lift") != null]
	if not (is_equal_approx(s1.hp, want_s) and is_equal_approx(s2.hp, want_s) and is_equal_approx(a.hp, want_a)):
		return "떨어진 뒤 체력: 병사 %s(%.2f여야 한다) · 궁수 %.2f(%.2f여야 한다)" % [[s1.hp, s2.hp], want_s, a.hp, want_a]
	var again := false
	for i in int(4.8 / DT):
		b.step(DT)
		again = again or e.get("carry") != null
	return check(not again, "떨어뜨린 뒤 4.8초 안에 다시 들었다(%s)" % [e.get("carry")])

# EV854 · S308: 들 수 있는 것이 없고 영웅만 있으면 땅에 내려앉아 1.5초 돌을 줍고, 영웅 자리에 떨어뜨린다. 줍는 동안은 근접도 친다
func ev854():
	var r := _one("sylvia", Vector2i(10, 10))
	var b = r[0]
	var why := _need(b, [SN])
	if why != "":
		return why
	var h = r[1]
	var e = b.spawn_enemy(SN, Vector2i(6, 10), {"hp": BIG})
	if not run(b, 1.0, func(): return _picking(e)):
		return "1초 안에 돌 줍기를 시작하지 않았다(자리 %s · cast %s)" % [e.pos, e.cast]
	if b.effect(e, "down") == null:
		return "돌을 줍는 하피가 땅에 내려앉지 않았다(effect down 없음)"
	var at: Vector2 = e.pos
	var t := 0.0
	var moved := 0.0
	while t < 2.0 and _picking(e):
		b.step(DT)
		t += DT
		moved = maxf(moved, e.pos.distance_to(at))
	if t < 1.4 - 0.001 or t > 1.6 + 0.001 or moved > 0.05:
		return "줍기 %.2f초(1.4~1.6) · 줍는 동안 %.2f칸 움직임" % [t, moved]
	if e.get("carry") != "stone" or e.cast == null or e.cast.id != "snatch" or e.cast.get("pick", false) or Vector2(e.cast.get("at", Vector2(INF, INF))).distance_to(h.pos) > 0.01:
		return "줍기가 끝난 스텝: 든 것 %s · 예고 %s(실비아 자리 %s)" % [e.get("carry"), e.cast, h.pos]
	var hp0: float = h.hp
	var want: float = 10.0 * b.armor_mult(b.armor_of(h))
	t = 0.0
	var hit_t := -1.0
	while t < 3.0 and hit_t < 0.0:
		b.step(DT)
		t += DT
		if h.hp < hp0:
			hit_t = t
	if hit_t < 1.9 - 0.001 or hit_t > 2.1 + 0.001 or not is_equal_approx(hp0 - h.hp, want):
		return "돌: %.2f초 뒤(1.9~2.1) 실비아 체력이 %.2f 줄었다(%.2f여야 한다)" % [hit_t, hp0 - h.hp, want]
	var s := _one("aias", Vector2i(10, 10))
	var c = s[0]
	var q = c.spawn_enemy(SN, Vector2i(9, 10), {"hp": BIG})
	if not run(c, 1.0, func(): return _picking(q)):
		return "아이아스 옆 하피가 1초 안에 돌 줍기를 시작하지 않았다(cast %s)" % [q.cast]
	var q0: float = q.hp
	run(c, 1.6, func(): return q.hp < q0 or not _picking(q))
	return check(q.hp < q0, "돌을 줍는 동안 아이아스가 하피 체력을 깎지 못했다")

# EV855 · S308: 든 동안 하피가 쓰러지거나 기절하거나 들림이 풀리면 든 용병을 하피 자리에 다치지 않게 내려놓는다
func ev855():
	for how in ["kill", "stun", "unlift"]:
		var x = _lifted()
		if x is String:
			return x
		var b = x[0]
		var a = x[1]
		var e = x[2]
		var at: Vector2 = e.pos
		match how:
			"kill":
				b.damage(e, BIG)
			"stun":
				e.fx["test_stun"] = {"stun": true, "left": 0.5}
			"unlift":
				for k in a.fx.keys():
					if a.fx[k].has("lift"):
						a.fx.erase(k)
		b.step(DT)
		var ok: bool = a.pos.distance_to(at) <= 0.05 and a.hp == 100.0 and b.effect(a, "lift") == null and (how == "kill" or e.cast == null)
		if not ok:
			return "%s: 궁수 자리 %s(하피 자리 %s) · 체력 %.1f · 들림 %s · 하피 예고 %s" % [how, a.pos, at, a.hp, b.effect(a, "lift") != null, e.cast]
	return ""

# EV856 · S308: 도발된 동안은 들지 않고, 들린 용병은 적이 노리지 않는다(깃털을 새로 쏘지 않는다)
func ev856():
	var x = _snatch_board({"heroes": [{"kind": "aias", "cell": Vector2i(5, 12), "level": 5}]})
	if x is String:
		return x
	var b = x[0]
	_start(b)
	var h = b.heroes[0]
	var e = b.spawn_enemy(SN, Vector2i(5, 10), {"hp": BIG})
	if not b.cast(h, "w"):
		return "아이아스가 W를 쓰지 못했다"
	if b.effect(e, "taunt") != h:
		return "하피가 도발되지 않았다"
	var grabbed := false
	for i in int(3.9 / DT):
		b.step(DT)
		grabbed = grabbed or e.get("carry") != null
	if grabbed:
		return "도발된 4초 안에 들었다(%s)" % [e.get("carry")]
	var y = _snatch_board()
	if y is String:
		return y
	var c = y[0]
	var a = y[1]
	var f = _still(c, FH, Vector2(10, 13))
	var q = c.spawn_enemy(SN, Vector2i(3, 10), {"hp": BIG})
	if not run(c, 10.0, func(): return q.get("carry") != null):
		return "10초 안에 아무것도 들지 않았다(자리 %s)" % q.pos
	if q.carry != a:
		return "든 것이 (10,10) 궁수가 아니다(%s)" % [q.carry]
	var fresh := 0
	while q.get("carry") == a:
		var before: Array = c.feathers.duplicate()
		c.step(DT)
		for k in c.feathers:
			if k.target == a and not before.any(func(o): return is_same(o, k)):
				fresh += 1
	return check(fresh == 0 and f.alive, "궁수가 들린 동안 궁수를 노린 깃털이 %d개 새로 나갔다" % fresh)

# EV857 · I254: 성벽 위에서 들린 용병은 성벽 위가 아니게 되고, 성벽 칸에 떨어진 용병은 성벽 위에 선다. 떨어진 원은 성벽 칸도 친다
func ev857():
	var b = _fort()
	var why := _need(b, [SN])
	if why != "":
		return why
	var a = _up(b, "archer", TOP, {"hp": 100.0, "damage": 0})
	if a == null:
		return "궁수를 성벽 위 %s에 올리지 못했다" % [TOP]
	a.pos = Vector2(TOP)
	var s1 = b.place_merc("soldier", Vector2i(12, 6), {"hp": 100.0, "damage": 0})
	var s2 = b.place_merc("soldier", Vector2i(12, 7), {"hp": 100.0, "damage": 0})
	s2.pos = Vector2(12, 6.7)
	var e = b.spawn_enemy(SN, Vector2i(12, 15), {"hp": BIG})
	if not run(b, 10.0, func(): return e.get("carry") != null):
		return "10초 안에 아무것도 들지 않았다(자리 %s)" % e.pos
	if e.carry != a:
		return "든 것이 성벽 위 궁수가 아니다(%s)" % [e.carry]
	var off := true
	while e.get("carry") == a:
		b.step(DT)
		off = off and not a.on_wall
	if not off or a.on_wall or a.pos.distance_to(s1.pos) > 0.6:
		return "성벽에서 들린 궁수: 든 동안 성벽 위가 아님 %s · 떨어진 뒤 성벽 위 %s · 자리 %s((12,6) 병사 %s에서 0.6칸 안)" % [off, a.on_wall, a.pos, s1.pos]
	var c = _fort()
	var a1 = _up(c, "archer", TOP, {"hp": 100.0, "damage": 0})
	var a2 = _up(c, "archer", Vector2i(13, 9), {"hp": 100.0, "damage": 0})
	if a1 == null or a2 == null:
		return "궁수 둘을 성벽 위 (12,9)·(13,9)에 올리지 못했다"
	a1.pos = Vector2(TOP)
	a2.pos = Vector2(13, 9)
	var m = c.place_merc("soldier", Vector2i(12, 13), {"hp": 100.0, "damage": 0})
	var w0: float = c.walls[TOP].hp
	var want: float = 15.0 * c.armor_mult(c.armor_of(c.walls[TOP]))
	var q = c.spawn_enemy(SN, Vector2i(12, 17), {"hp": BIG})
	if not run(c, 10.0, func(): return q.get("carry") != null):
		return "10초 안에 아무것도 들지 않았다(자리 %s)" % q.pos
	if q.carry != m:
		return "든 것이 들판 (12,13) 병사가 아니다(%s)" % [q.carry]
	run(c, 3.0, func(): return q.get("carry") == null)
	return check(m.on_wall and m.pos.distance_to(Vector2(TOP)) <= 0.001 and is_equal_approx(w0 - c.walls[TOP].hp, want),
		"성벽 칸에 떨어진 병사: 성벽 위 %s · 자리 %s((12,9)여야 한다) · (12,9) 성벽 체력 %.1f 줄었다(%.1f여야 한다)" % [m.on_wall, m.pos, w0 - c.walls[TOP].hp, want])

# 마을(0~5행) 들판 판에 집 (10,3)을 지은 판. 어둠 dark. 주민이 없으면 까닭(글)
func _folk_board(dark := 0.0):
	var b = battle({"village": Rect2i(0, 0, 30, 6), "base_hp": BIG, "waves": [[{"kind": "basic", "count": 1}]]})
	if b.build("house", Vector2i(10, 3)) == null:
		return "집 (10,3)을 짓지 못했다"
	b.dark = dark
	b.step(DT)
	if b.get("people") == null or b.people.is_empty():
		return "집에 주민이 없다"
	return b

# 밖에 나와 있는 첫 주민 둘레 3칸 옆에 낚아채기 하피(체력 큼)를 내보내 주민을 들 때까지 돌린다. [판, 하피, 주민], 못 하면 까닭(글). hurt면 그 주민 체력을 먼저 그만큼 깎는다
func _folk_lift(hurt := 0.0):
	var b = _folk_board()
	if b is String:
		return b
	var why := _need(b, [SN])
	if why != "":
		return why
	var v = null
	for x in b.people:
		if not x.inside:
			v = x
			break
	if v == null:
		return "밖에 나와 있는 주민이 없다"
	var e = b.spawn_enemy(SN, Vector2i(v.pos.round()) + Vector2i(3, 0), {"hp": BIG})
	if hurt > 0.0:
		for x in b.people:
			x.m.hp = x.max_hp - hurt
	if not run(b, 5.0, func(): return e.get("carry") != null):
		return "5초 안에 주민을 들지 않았다(하피 %s · 주민 %s)" % [e.pos, v.pos]
	if not e.carry in b.people:
		return "든 것이 주민이 아니다(%s)" % [e.carry]
	return [b, e, e.carry]

# EV858 · S308: 밖에 나온 주민을 들어 2초 뒤 떨어뜨리면 주민이 12 다쳐 교회·집으로 가고, 죽으면 그 집 죽은 식구 수가 는다. 집 안 주민은 들지 않는다
func ev858():
	var x = _folk_lift()
	if x is String:
		return x
	var b = x[0]
	var e = x[1]
	var v = x[2]
	var t := 0.0
	var stuck := true
	while t < 3.0 and e.get("carry") == v:
		b.step(DT)
		t += DT
		stuck = stuck and (e.get("carry") != v or v.pos.distance_to(e.pos) <= 0.001)
	if not stuck or t < 1.9 - 0.001 or t > 2.1 + 0.001:
		return "주민: 든 동안 하피 자리에 붙어 있음 %s · 든 뒤 %.2f초에 떨어뜨림(1.9~2.1)" % [stuck, t]
	var to = v.m.get("away", {}).get("to") if v.m.get("away") != null else null
	if not (v.alive and is_equal_approx(v.hp, 3.0) and to in ["church", "home"]):
		return "떨어진 주민: 살아 있음 %s · 체력 %.2f(3이어야 한다) · 가는 곳 %s" % [v.alive, v.hp, to]
	var y = _folk_lift(5.0)
	if y is String:
		return y
	var c = y[0]
	var u = y[2]
	var home = u.home
	var lost0: int = home.lost
	run(c, 3.0, func(): return y[1].get("carry") == null)
	if u.alive or home.lost != lost0 + 1:
		return "체력 10인 주민: 떨어진 뒤 살아 있음 %s · 죽은 식구 수 %d → %d" % [u.alive, lost0, home.lost]
	var d = _folk_board(1.0)
	if d is String:
		return d
	if not d.people.all(func(p): return p.inside):
		return "어둠 1인 판에 밖에 나와 있는 주민이 있다"
	var q = d.spawn_enemy(SN, Vector2i(13, 3), {"hp": BIG})
	var grabbed := false
	for i in int(5.0 / DT):
		d.step(DT)
		grabbed = grabbed or q.get("carry") != null
	return check(not grabbed, "어둠 1인 판(모두 집 안)에서 하피가 들었다(%s)" % [q.get("carry")])

# 선 l([가, 나])이 한 끝은 o에서 2px 안이고 길이가 len(±3)px이다
func _edge(l: Array, o: Vector2, length: float) -> bool:
	var a := Vector2(l[0])
	var z := Vector2(l[1])
	return (a.distance_to(o) <= 2.0 or z.distance_to(o) <= 2.0) and absf(a.distance_to(z) - length) <= 3.0

# EV859 · I253: 하피 둘은 비행 그림에 색을 곱해 그리고, 뿜는 돌풍은 부채꼴 두 변을 그리며, 들린 용병은 하피 아래로 들어 올려 그린다
func ev859():
	var b = battle()
	var why := _need(b, [FH, DH, SH, ST, SN])
	if why != "":
		return why
	var v = _rec(b)
	var got := []
	for k in ["flying", FH, DH, SH, ST, SN]:
		var e = _still(b, k, Vector2(3 + got.size() * 3, 5))
		var one = _cut(v, e)
		if one == null:
			v.free()
			return "%s 몸통이 그림 한 장이 아니다(%d장)" % [k, v.cuts.size()]
		got.append(one)
	v.free()
	var srcs: Array = got.map(func(x): return x[1])
	if srcs.any(func(x): return x != srcs[0]):
		return "원본 사각형이 비행과 다르다: %s" % [srcs]
	var tints: Array = got.map(func(x): return x[2])
	for i in tints.size():
		for j in range(i + 1, tints.size()):
			if tints[i] == tints[j]:
				return "색이 같다: %s" % [tints]
	var c = _fort()
	var g = _storm(c)
	if g is String:
		return g
	var w = _rec(c)
	w._foes = w.foes()
	w.lines = []
	w._foe_tells()
	var o: Vector2 = w._center(g.pos)
	var edges: Array = w.lines.filter(func(l): return _edge(l, o, 96.0))
	var all: Array = w.lines.duplicate()
	w.free()
	if edges.size() < 2:
		return "뿜는 돌풍의 부채꼴 변(하피 %s에서 길이 96px)이 %d개다(선 %s)" % [o, edges.size(), all]
	var x = _lifted()
	if x is String:
		return x
	var a = x[1]
	var u = _rec(x[0])
	var up = _cut(u, a)
	var ref = x[0].place_merc("archer", Vector2i(20, 15))
	ref.pos = a.pos
	var stand = _cut(u, ref)
	u.free()
	if up == null or stand == null:
		return "든 궁수나 견줄 궁수가 그림 한 장이 아니다"
	return check(up[0].position.y < stand[0].position.y - 8.0, "든 궁수 그림 y %.1f · 같은 자리에 선 궁수 y %.1f(8px 넘게 위여야 한다)" % [up[0].position.y, stand[0].position.y])
