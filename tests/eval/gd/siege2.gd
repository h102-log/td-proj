extends "res://tests/eval/gd/lib.gd"
# 3라운드 고블린 약탈단 묶음 ②-a: 공성탑(S284·I221), 폭탄 열기구(S285), 수송 비행선(S286·I222).
# lib.gd·siege.gd 머리의 계약에 더하는 API:
#   적 kind "siege_tower"(공성탑) · "balloon"(폭탄 열기구) · "airship"(수송 비행선) · 적 on_wall(성벽 위의 적인가)
#   Battle.ladders(사다리 칸 → 그 사다리를 놓은 공성탑) · Battle.forecast(출현 지점마다 예상 경로 칸 배열, S142)
#   적 cast: 열기구 폭탄 {id "bomb", left, at(원 가운데)} · 비행선 투하 표식 {id "drop", left, at(투하 칸 가운데)}
#   Battle.area_of(구조물) -> Rect2i · Battle.nearest(구조물, 자리) -> 가장 가까운 차지 칸 가운데

const GATE := Vector2i(12, 9)
const QUIET := {"damage": 0, "range": 0, "sight": 0}  # 치지도 쫓지도 않는 병사
const VILLAGE := Rect2i(0, 0, 30, 9)

# 9행 성곽(성문은 GATE 하나, 나머지 열은 성벽), 마을 0~8행, 거점 (12,2). 3라운드 준비 단계로 간다(siege.gd _siege와 같고 출현 지점만 고른다)
func _raid(spawn := Vector2i(12, 19)):
	var walls := []
	for x in 30:
		if x != GATE.x:
			walls.append(Vector2i(x, 9))
	var w := [[{"kind": "basic", "count": 1}]]
	var b = battle({"size": Vector2i(30, 20), "base": Vector2i(12, 2), "base_hp": BIG, "spawns": [spawn],
		"village": VILLAGE, "castle": {"walls": walls, "gates": [GATE], "wall_hp": 300, "gate_hp": 150}, "rounds": [w, w, w]})
	for i in 2:
		b.start_battle()
		if not clear_wave(b) or not b.next_round():
			return null
	return b if b.round_index == 2 and b.state == "prep" else null

# 성곽 없는 1라운드 판: 마을 0~8행, 거점 (12,2), 출현 지점 (12,19)
func _town():
	return battle({"base": Vector2i(12, 2), "spawns": [Vector2i(12, 19)], "village": VILLAGE, "base_hp": BIG})

func _need(b, kind: String) -> String:
	if b == null:
		return "3라운드 준비 단계로 가지 못했다"
	return "" if b.ENEMY_KINDS.has(kind) else "적 종류 %s가 없다" % kind

func _casting(e, id: String) -> bool:
	return e.cast != null and e.cast.get("id") == id

func _ladder(b, cell: Vector2i) -> bool:
	return b.get("ladders") != null and b.ladders.has(cell)

func _basics(b) -> Array:
	return b.enemies.filter(func(e): return e.alive and e.kind == "basic")

# 공성탑 t가 성벽 열 col에서 1칸 안에 들 때까지 돌린다
func _arrive(b, t, col: Vector2i, secs := 15.0) -> bool:
	return run(b, secs, func(): return t.pos.distance_to(Vector2(col)) <= 1.01)

# 내린 넷이 모두 p에서 tol칸 안이다. 적끼리 밀어내기(S13)로 0.25칸 둘레에서 곧 0.4칸 넘게 벌어지고 걸어가기도 해서 1칸이다
func _near_all(es: Array, p: Vector2, tol := 1.0) -> bool:
	return es.size() == 4 and es.all(func(e): return e.pos.distance_to(p) <= tol)

# 가운데 at(칸 가운데)가 구조물 s의 차지 칸 가운데 하나인가
func _on(b, s, at) -> bool:
	if at == null:
		return false
	var c := Vector2i(Vector2(at).round())
	return Vector2(at).distance_to(Vector2(c)) < 0.01 and b.area_of(s).has_point(c)

# EV683 · S284: 공성탑은 가장 가까운 성벽 열 앞에 멈추고 2초 뒤 사다리를 놓는다. 내리다 기절하면 처음부터. 아군 몸에 막힌다
func ev683():
	var b = _raid()
	var why := _need(b, "siege_tower")
	if why != "":
		return why
	var col := Vector2i(20, 9)
	var t = b.spawn_enemy("siege_tower", Vector2i(20, 16), {"hp": BIG})
	if not _arrive(b, t, col):
		return "15초 안에 성벽 열 %s에서 1칸 안에 들지 않았다(자리 %s)" % [col, t.pos]
	var at: Vector2 = t.pos
	var moved := [0.0]
	run(b, 1.0, func():
		moved[0] = maxf(moved[0], t.pos.distance_to(at))
		return false)
	run(b, 0.9)
	var early: bool = not _ladder(b, col)
	run(b, 0.2)
	var laid: bool = _ladder(b, col)
	var c = _raid()
	var u = c.spawn_enemy("siege_tower", Vector2i(20, 16), {"hp": BIG})
	if not _arrive(c, u, col):
		return "둘째 판: 15초 안에 성벽 열에 닿지 않았다(자리 %s)" % u.pos
	run(c, 1.0)
	u.fx["test_stun"] = {"stun": true, "left": 1.0}
	var held := [false]
	var freed := run(c, 1.5, func():
		held[0] = held[0] or _ladder(c, col)
		return c.effect(u, "stun") == null)
	run(c, 1.9)
	var late: bool = not _ladder(c, col)
	run(c, 0.2)
	var relaid: bool = _ladder(c, col)
	var d = _raid()
	var m = d.place_merc("soldier", Vector2i(20, 13), QUIET.merged({"hp": 100}))
	var v = d.spawn_enemy("siege_tower", Vector2i(20, 16), {"hp": BIG})
	var closest := [INF]
	run(d, 10.0, func():
		closest[0] = minf(closest[0], v.pos.distance_to(Vector2(col)))
		return false)
	return check(moved[0] <= 0.05 and early and laid and not held[0] and freed and late and relaid and closest[0] > 2.0 and m != null and m.hp == 100.0,
		"멈춘 뒤 움직임 %.2f · 1.9초 사다리 없음 %s · 2.1초 사다리 %s · 기절 중 사다리 %s · 기절 풀림 %s · 풀린 뒤 1.9초 없음 %s · 2.1초 있음 %s · 막힌 탑의 가장 가까운 거리 %.2f(>2) · 병사 체력 %s" % [
			moved[0], early, laid, held[0], freed, late, relaid, closest[0], m.hp if m else null])

# EV684 · S284: 공성탑에 탄 고블린 넷이 멈출 때 내려, 사다리 전엔 성벽을 치지 않고 기다렸다 오른다(보상 0). 도착 전에 부서지면 체력 그대로 내린다
func ev684():
	var b = _raid()
	var why := _need(b, "siege_tower")
	if why != "":
		return why
	var col := Vector2i(20, 9)
	var t = b.spawn_enemy("siege_tower", Vector2i(20, 16), {"hp": BIG})
	var before := [0]
	var came := run(b, 15.0, func():
		before[0] = maxi(before[0], _basics(b).size())
		return t.pos.distance_to(Vector2(col)) <= 1.01)
	if not came:
		return "15초 안에 성벽 열에 닿지 않았다(자리 %s)" % t.pos
	run(b, 0.1, func(): return _basics(b).size() >= 4)
	var crew: Array = _basics(b)
	var off := _near_all(crew, t.pos)
	var wall = b.castle[col]
	var w0: float = wall.hp
	var kept := [true]
	var laid := run(b, 2.5, func():
		kept[0] = kept[0] and wall.hp == w0
		return _ladder(b, col))
	var g = b.castle[GATE]
	var g0: float = g.hp
	var up := {}
	run(b, 6.0, func():
		for e in crew:
			if e.on_wall:
				up[e] = true
		return up.size() == 4)
	var gate_kept: bool = g.hp == g0
	var gold0: int = b.gold
	if not crew.is_empty():
		b.damage(crew[0], BIG)
	var paid: bool = b.gold != gold0
	var c = _raid()
	var u = c.spawn_enemy("siege_tower", Vector2i(20, 18))
	run(c, 1.0)
	var spot: Vector2 = u.pos
	c.damage(u, BIG * 2, "magic")
	run(c, 0.1, func(): return _basics(c).size() >= 4)
	var fell: Array = _basics(c)
	var full: bool = fell.size() == 4 and fell.all(func(e): return e.hp == e.max_hp)
	return check(before[0] == 0 and off and laid and kept[0] and up.size() == 4 and gate_kept and not paid and not u.alive and _near_all(fell, spot) and full,
		"멈추기 전 basic %d · 내린 넷 %d(탑 곁 %s) · 사다리 %s · 그 전 성벽 그대로 %s · 오른 수 %d · 성문 그대로 %s · 죽인 고블린 골드 %s · 부서진 탑 둘레 %d(곁 %s) · 체력 가득 %s" % [
			before[0], crew.size(), off, laid, kept[0], up.size(), gate_kept, paid, fell.size(), _near_all(fell, spot), full])

# EV685 · I221: 사다리가 성문보다 가까운 고블린은 사다리로 1초 만에 오르고, 성문이 가까운 고블린은 성문으로 간다. 예상 경로도 사다리를 지난다
func ev685():
	var b = _raid(Vector2i(24, 19))
	var why := _need(b, "siege_tower")
	if why != "":
		return why
	var col := Vector2i(24, 9)
	var t = b.spawn_enemy("siege_tower", Vector2i(24, 16), {"hp": BIG})
	if not run(b, 20.0, func(): return _ladder(b, col)):
		return "20초 안에 %s에 사다리가 놓이지 않았다(탑 %s)" % [col, t.pos]
	var path: Array = b.forecast[0] if not b.forecast.is_empty() else []
	var a = b.spawn_enemy("basic", Vector2i(22, 16), {"hp": BIG})
	var z = b.spawn_enemy("basic", Vector2i(13, 16), {"hp": BIG})
	var g = b.castle[GATE]
	var g0: float = g.hp
	var clock := [0.0, -1.0, -1.0, false, false]  # 지난 초 · 사다리 1칸 안에 든 때 · 성벽 위가 된 때 · 마을에 들어섬 · B가 성벽 위
	run(b, 15.0, func():
		clock[0] += DT
		if clock[1] < 0.0 and a.pos.distance_to(Vector2(col)) <= 1.0:
			clock[1] = clock[0]
		if clock[2] < 0.0 and a.on_wall:
			clock[2] = clock[0]
		clock[3] = clock[3] or Vector2i(a.pos.round()).y <= 8
		clock[4] = clock[4] or z.on_wall
		return false)
	var climb: float = clock[2] - clock[1]
	var hit: bool = g.hp < g0
	var c = _raid(Vector2i(24, 19))
	var y = c.spawn_enemy("basic", Vector2i(22, 16), {"hp": BIG})
	var h = c.castle[GATE]
	var h0: float = h.hp
	var rose := [false]
	run(c, 15.0, func():
		rose[0] = rose[0] or y.on_wall
		return false)
	return check(clock[1] >= 0.0 and clock[2] >= 0.0 and climb >= 0.9 and climb <= 1.3 and clock[3] and not clock[4] and hit
		and path.has(col) and not path.has(GATE) and not rose[0] and h.hp < h0,
		"A: 사다리 1칸 안 %.2f초 · 성벽 위 %.2f초(차 %.2f, 0.9~1.3) · 마을 %s · B 성벽 위 %s · 성문 %.1f→%.1f · 예상 경로에 사다리 %s · 성문 %s · 탑 없는 판: 오름 %s · 성문 %.1f→%.1f" % [
			clock[1], clock[2], climb, clock[3], clock[4], g0, g.hp, path.has(col), path.has(GATE), rose[0], h0, h.hp])

# EV686 · S284: 공성탑이 죽으면 사다리가 바로 없어지고 가던 고블린은 성문으로 간다. 성벽 열이 잔해가 되면 이웃 열에 새 사다리를 놓는다
func ev686():
	var b = _raid(Vector2i(24, 19))
	var why := _need(b, "siege_tower")
	if why != "":
		return why
	var col := Vector2i(24, 9)
	var t = b.spawn_enemy("siege_tower", Vector2i(24, 16), {"hp": BIG})
	if not run(b, 20.0, func(): return _ladder(b, col)):
		return "20초 안에 %s에 사다리가 놓이지 않았다(탑 %s)" % [col, t.pos]
	run(b, 4.0)  # 탄 고블린이 먼저 오른다
	var k = b.spawn_enemy("basic", Vector2i(24, 16), {"hp": BIG})
	run(b, 1.0)
	b.damage(t, BIG * 2, "magic")
	var gone: bool = not t.alive and not _ladder(b, col)
	var g = b.castle[GATE]
	var g0: float = g.hp
	var rose := [false]
	run(b, 15.0, func():
		rose[0] = rose[0] or k.on_wall
		return false)
	var hit: bool = g.hp < g0
	var c = _raid(Vector2i(24, 19))
	var u = c.spawn_enemy("siege_tower", Vector2i(24, 16), {"hp": BIG})
	if not run(c, 20.0, func(): return _ladder(c, col)):
		return "둘째 판: 20초 안에 사다리가 놓이지 않았다(탑 %s)" % u.pos
	var wall = c.castle[col]
	c.damage(wall, BIG)
	var dropped: bool = not _ladder(c, col)
	var next := run(c, 10.0, func(): return _ladder(c, Vector2i(23, 9)) or _ladder(c, Vector2i(25, 9)))
	return check(gone and not rose[0] and hit and dropped and next,
		"탑을 죽인 스텝에 사다리 없음 %s · 고블린 성벽 위 %s · 성문 %.1f→%.1f · 열이 잔해가 된 스텝에 사다리 없음 %s · 이웃 열 새 사다리 %s(탑 %s)" % [
			gone, rose[0], g0, g.hp, dropped, next, u.pos])

# EV687 · S285: 열기구는 들판 타워를 지나 가장 가까운 마을 시설 위에서 1.5초 예고 뒤 구조물 −50·아군 −20. 다음은 다른 시설, 시설이 없으면 거점
func ev687():
	var b = _town()
	var why := _need(b, "balloon")
	if why != "":
		return why
	var house = b.build("house", Vector2i(11, 5))
	var shop = b.build("workshop", Vector2i(20, 3))
	var tower = b.build("tower", Vector2i(14, 14))
	if house == null or shop == null or tower == null:
		return "집·작업장·타워를 짓지 못했다(%s · %s · %s)" % [house, shop, tower]
	var e = b.spawn_enemy("balloon", Vector2i(12, 18), {"hp": BIG})
	if not run(b, 20.0, func(): return _casting(e, "bomb")):
		return "20초 안에 폭탄 예고를 시작하지 않았다(자리 %s)" % e.pos
	var over: bool = e.pos.distance_to(b.nearest(house, e.pos)) <= 1.01
	var aim = e.cast.get("at")
	var first: bool = _on(b, house, aim)
	var m = null
	if aim != null:
		for d in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
			var cell: Vector2i = Vector2i(Vector2(aim).round()) + d
			if b.structure_at(cell) == null and cell != b.base.cell:
				m = b.place_merc("soldier", cell, QUIET.merged({"hp": 100}))
				if m != null:
					break
	if m == null:
		return "예고 가운데 %s 곁에 병사를 세우지 못했다" % [aim]
	var h0: float = house.hp
	var s0: float = shop.hp
	var t0: float = tower.hp
	run(b, 1.4)
	var early: bool = house.hp == h0 and m.hp == 100.0
	run(b, 0.2)
	var hit: bool = is_equal_approx(h0 - house.hp, 50.0) and is_equal_approx(m.hp, 80.0) and shop.hp == s0 and tower.hp == t0
	var h1: float = house.hp
	var again := run(b, 30.0, func(): return _casting(e, "bomb"))
	var second: bool = again and _on(b, shop, e.cast.get("at")) and house.hp == h1
	var c = _town()
	var f = c.spawn_enemy("balloon", Vector2i(12, 18), {"hp": BIG})
	var b0: float = c.base.hp
	var struck := run(c, 30.0, func(): return c.base.hp < b0)
	return check(over and first and early and hit and second and struck and is_equal_approx(b0 - c.base.hp, 50.0),
		"집 위에 멈춤 %s · 가운데가 집 %s(%s) · 1.4초 그대로 %s · 1.6초 집 %.1f→%.1f·병사 %.1f·작업장 그대로 %s·타워 그대로 %s · 다음 예고 %s(작업장 %s) · 시설 없는 판 거점 −%.1f" % [
			over, first, aim, early, h0, house.hp, m.hp, shop.hp == s0, tower.hp == t0, again, second, b0 - c.base.hp])

# EV688 · S285: 봉인된 열기구는 폭탄 예고를 시작하지 않고, 풀리면 시작한다
func ev688():
	var b = _town()
	var why := _need(b, "balloon")
	if why != "":
		return why
	var house = b.build("house", Vector2i(11, 5))
	if house == null:
		return "집을 짓지 못했다"
	var e = b.spawn_enemy("balloon", Vector2i(12, 18), {"hp": BIG})
	e.fx["test_seal"] = {"seal": true, "left": 25.0}
	var h0: float = house.hp
	var quiet := not run(b, 25.0 - DT, func(): return e.cast != null)
	var kept: bool = house.hp == h0
	var later := run(b, 20.0 + DT, func(): return _casting(e, "bomb"))
	return check(quiet and kept and later, "봉인 동안 예고 없음 %s · 집 그대로 %s · 풀린 뒤 20초 안에 예고 %s(자리 %s)" % [quiet, kept, later, e.pos])

# EV690 · S286·I222: 집이 멀면 거점 옆 칸(병사가 선 칸 빼고, 동점이면 y·x가 작은 칸)에 표식 2초 뒤 고블린 넷(보상 0). 그 뒤 비행선은 거점을 친다
func ev690():
	var b = _town()
	var why := _need(b, "airship")
	if why != "":
		return why
	if b.build("house", Vector2i(24, 5)) == null:
		return "먼 집을 짓지 못했다"
	if b.place_merc("soldier", Vector2i(12, 1), QUIET.merged({"hp": BIG})) == null:
		return "(12,1)에 병사를 세우지 못했다"
	var a = b.spawn_enemy("airship", Vector2i(12, 18), {"hp": BIG})
	if not run(b, 25.0, func(): return _casting(a, "drop")):
		return "25초 안에 투하 표식을 띄우지 않았다(자리 %s)" % a.pos
	var spot := Vector2(11, 2)
	var aim = a.cast.get("at")
	var placed: bool = aim != null and Vector2(aim).distance_to(spot) < 0.01 and a.pos.distance_to(spot) <= 1.0
	run(b, 1.9)
	var none: bool = _basics(b).is_empty()
	run(b, 0.2)
	var crew: Array = _basics(b)
	var landed := _near_all(crew, spot)
	var gold0: int = b.gold
	for e in crew:
		b.damage(e, BIG)
	var paid: bool = b.gold != gold0
	var b0: float = b.base.hp
	var struck := run(b, 10.0, func(): return b.base.hp < b0)
	return check(placed and none and landed and not paid and struck,
		"표식 자리 %s(11,2)·비행선 %s · 1.9초 basic 없음 %s · 2.1초 넷 %d(곁 %s) · 죽인 골드 %s · 비행선이 거점을 침 %s" % [aim, a.pos, none, crew.size(), landed, paid, struck])

# EV691 · I222: 비행선 길에서 2칸 떨어진 마을 집이 있으면 거점 둘레가 아니라 그 집 옆에 떨군다
func ev691():
	var b = _town()
	var why := _need(b, "airship")
	if why != "":
		return why
	var house = b.build("house", Vector2i(14, 6))
	if house == null:
		return "집을 짓지 못했다"
	var a = b.spawn_enemy("airship", Vector2i(12, 18), {"hp": BIG})
	if not run(b, 25.0, func(): return _casting(a, "drop")):
		return "25초 안에 투하 표식을 띄우지 않았다(자리 %s)" % a.pos
	var aim = a.cast.get("at")
	if aim == null:
		return "투하 표식에 자리(at)가 없다"
	var at := Vector2(aim)
	var by: bool = at.distance_to(b.nearest(house, at)) <= 1.01
	var away: bool = at.distance_to(Vector2(b.base.cell)) > 2.0
	run(b, 2.1)
	var crew: Array = _basics(b)
	return check(by and away and _near_all(crew, at), "표식 자리 %s · 집 곁 %s · 거점에서 2칸 넘음 %s · 2.1초 넷 %d(곁 %s)" % [at, by, away, crew.size(), _near_all(crew, at)])

# EV692 · S286: 투하 전에 격추되면 체력 절반인 고블린 넷(보상 0). 표식 중 기절이면 취소되고, 풀린 뒤 표식부터 다시 띄운다
func ev692():
	var b = _town()
	var why := _need(b, "airship")
	if why != "":
		return why
	var a = b.spawn_enemy("airship", Vector2i(12, 18), {"hp": BIG})
	run(b, 1.0)
	var spot: Vector2 = a.pos
	b.damage(a, BIG * 2, "magic")
	run(b, 0.1, func(): return _basics(b).size() >= 4)
	var crew: Array = _basics(b)
	var half: float = b.ENEMY_KINDS.basic.hp * 0.5
	var hurt: bool = crew.size() == 4 and crew.all(func(e): return is_equal_approx(e.hp, half) and is_equal_approx(e.max_hp, half))
	var gold0: int = b.gold
	if not crew.is_empty():
		b.damage(crew[0], BIG)
	var paid: bool = b.gold != gold0
	var c = _town()
	var s = c.spawn_enemy("airship", Vector2i(12, 18), {"hp": BIG})
	if not run(c, 25.0, func(): return _casting(s, "drop")):
		return "둘째 판: 25초 안에 투하 표식을 띄우지 않았다(자리 %s)" % s.pos
	run(c, 1.0)
	s.fx["test_stun"] = {"stun": true, "left": 1.0}
	c.step(DT)
	var off: bool = s.cast == null
	var early := [true]
	var freed := run(c, 1.5, func():
		early[0] = early[0] and _basics(c).is_empty()
		return c.effect(s, "stun") == null)
	var relit := run(c, 0.5, func(): return _casting(s, "drop"))
	early[0] = early[0] and _basics(c).is_empty()
	run(c, 1.9)
	var none: bool = _basics(c).is_empty()
	run(c, 0.2)
	var later: int = _basics(c).size()
	return check(not a.alive and _near_all(crew, spot) and hurt and not paid and off and early[0] and freed and relit and none and later == 4,
		"격추 자리 둘레 넷 %d(곁 %s) · 체력 절반(%.1f) %s · 죽인 골드 %s · 기절에 꺼짐 %s · 그동안 basic 없음 %s · 풀림 %s · 다시 표식 %s · 1.9초 없음 %s · 2.1초 %d" % [
			crew.size(), _near_all(crew, spot), half, hurt, paid, off, early[0], freed, relit, none, later])
