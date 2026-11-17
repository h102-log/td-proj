extends "res://tests/eval/gd/lib.gd"

# 세로 성벽 줄(x=3, y=0..38)에 틈은 y=39 하나. 거점 (6,5), 출현 (0,5) — 우회하면 60칸 넘게 더 걷는다.
func _barrier(weak_hp: int):
	var b = battle({"size": Vector2i(10, 40), "base": Vector2i(6, 5), "base_hp": BIG, "spawns": [Vector2i(0, 5)]})
	for y in 39:
		b.build("wall", Vector2i(3, y))
	b.structure_at(Vector2i(3, 5)).hp = weak_hp
	return b

# EV5 · S7: 계수 1인 적은 체력 1 성벽을 부수는 쪽이 싸면 부순다
func ev5():
	var b = _barrier(1)
	var e = b.spawn_enemy("basic", Vector2i(0, 5), {"wall_k": 1.0})
	var ok := run(b, 120, func(): return at_base(b, e))
	return check(ok and b.structure_at(Vector2i(3, 5)) == null, "체력 1 성벽을 부수지 않고 돌아갔다")

# EV6 · S8: 길이 열린 미로에서는 기본 성향 적이 성벽을 부수지 않는다
func ev6():
	var b = battle({"base_hp": BIG})
	var walls := []
	for y in 18:
		walls.append(Vector2i(10, y))
	for y in range(2, 20):
		walls.append(Vector2i(18, y))
	for c in walls:
		b.build("wall", c)
	var e = b.spawn_enemy("basic", Vector2i(0, 10))
	var ok := run(b, 300, func(): return at_base(b, e))
	return check(ok and intact(b, walls), "미로를 돌지 않고 성벽을 건드렸다")

# EV7 · S9: 완전히 막으면 가장 싼 성벽(출현 지점 반대편의 약한 성벽)을 부순다
func ev7():
	var b = battle({"base": Vector2i(15, 10), "base_hp": BIG})
	var walls := ring(Vector2i(15, 10))
	for c in walls:
		b.build("wall", c)
	var weak := Vector2i(16, 10)
	b.structure_at(weak).hp = 1
	b.spawn_enemy("basic", Vector2i(0, 10))
	var ok := run(b, 300, func(): return b.base.hp < b.base.max_hp)
	walls.erase(weak)
	return check(ok and b.structure_at(weak) == null and intact(b, walls), "가장 싼 성벽만 부수고 거점에 닿지 않았다")

# EV8 · S10: 준비 단계에 기존 경로 위에 성벽을 놓으면 다음 전투의 적은 그 칸을 지나지 않는다
func ev8():
	var one := [{"kind": "basic", "count": 1}]
	var b = battle({"base_hp": BIG, "rounds": [[one], [one]]})  # 다음 준비 단계는 다음 라운드의 첫 준비다(S17 2026-11-17 변경)
	var got := []
	b.enemy_spawned.connect(func(e): got.append(e))
	b.start_battle()
	var path1 := {}
	run(b, 300, func():
		if got.size() > 0:
			path1[cell_of(got[0])] = true
		return got.size() > 0 and at_base(b, got[0]))
	if not clear_round(b) or not b.next_round() or b.state != "prep":
		return "1라운드가 끝나 다음 라운드 첫 준비가 되지 않았다(%s)" % b.state
	var keys := path1.keys()
	var block: Vector2i = Vector2i(12, 10) if path1.has(Vector2i(12, 10)) else keys[keys.size() / 2]
	if b.build("wall", block) == null:
		return "준비 단계에 성벽을 짓지 못했다"
	b.start_battle()
	# 칸 반올림은 대각선으로 모서리를 스칠 때 막힌 칸을 잘못 세므로, 성벽 중심까지의 최소 거리로 본다
	var closest := [INF]
	var ok := run(b, 300, func():
		if got.size() > 1:
			closest[0] = minf(closest[0], got[1].pos.distance_to(Vector2(block)))
		return got.size() > 1 and at_base(b, got[1]))
	return check(ok and closest[0] > 0.5 and intact(b, [block]), "새 성벽 칸 %s을 지나거나 부쉈다" % [block])

# EV9 · S34: 맵 안에서 가장 긴 ㄹ자 미로에서도 기본 성향 적은 가득 찬 성벽을 부수지 않는다
func ev9():
	var b = battle({"base": Vector2i(29, 10), "base_hp": BIG})
	var walls := []
	for i in 14:
		var gap := 19 if i % 2 == 0 else 0
		for y in 20:
			if y != gap:
				walls.append(Vector2i(2 + i * 2, y))
	for c in walls:
		b.build("wall", c)
	var e = b.spawn_enemy("basic", Vector2i(0, 10))
	var ok := run(b, 3000, func(): return at_base(b, e))
	return check(ok and intact(b, walls), "긴 미로에서 성벽을 부쉈다")

# EV10 · S34: 계수가 작은 적은 약한 성벽을 부수고, 큰 적은 같은 맵에서 돌아간다
func ev10():
	var small := _ev10_route(0.1)
	var large := _ev10_route(100.0)
	return check(small == "broke" and large == "detour", "계수 0.1 → %s, 계수 100 → %s" % [small, large])

func _ev10_route(k: float) -> String:
	var b = _barrier(10)
	var e = b.spawn_enemy("basic", Vector2i(0, 5), {"wall_k": k})
	if not run(b, 300, func(): return at_base(b, e)):
		return "stuck"
	return "broke" if b.structure_at(Vector2i(3, 5)) == null else "detour"

# EV247 · S142: 예상 경로는 출현 지점마다 거점까지 이어지고, 막힌 칸이 바뀌면 다시 구하며, 나온 기본 적은 그 길로 간다
# Battle.forecast — 출현 지점마다 기본 적의 예상 경로(칸 배열, 출현 지점부터 거점까지)
func ev247():
	var b = battle({"base_hp": BIG, "spawns": [Vector2i(0, 5), Vector2i(0, 15)], "waves": [[{"kind": "basic", "count": 1}]]})
	var paths: Array = b.forecast
	if paths.size() != 2 or paths.any(func(p): return p.is_empty() or p[-1] != b.base.cell) or paths[0][0] != Vector2i(0, 5) or paths[1][0] != Vector2i(0, 15):
		return "예상 경로가 출현 지점마다 거점까지 이어지지 않는다(%s)" % [paths]
	var mid: Vector2i = paths[0][paths[0].size() / 2]
	if b.build("wall", mid) == null:
		return "예상 경로 가운데 칸 %s에 방벽을 짓지 못했다" % mid
	b.step(DT)
	var path: Array = b.forecast[0]
	if mid in path:
		return "방벽을 지은 뒤에도 예상 경로가 %s를 지난다" % mid
	b.start_battle()
	run(b, 5.0, func(): return not b.enemies.is_empty())
	var e = b.enemies[0]
	var worst := [0.0]
	var ok := run(b, 60.0, func():
		worst[0] = maxf(worst[0], path.map(func(c): return e.pos.distance_to(Vector2(c))).min())
		return at_base(b, e))
	return check(ok and worst[0] <= 0.75, "거점에 닿음 %s · 예상 경로에서 가장 멀어진 거리 %.2f칸(0.75 이하여야 한다)" % [ok, worst[0]])

# EV305 · I155: 막힌 칸이 바뀌어 적 경로를 다시 구할 때 한 스텝에 8명까지만 새 경로를 받고, 나머지는 다음 스텝부터 받는다
func ev305():
	var b = battle({"base_hp": BIG})
	var foes := []
	for y in 20:
		foes.append(b.spawn_enemy("basic", Vector2i(0, y), {"speed": 0.0}))  # 서 있게 해서 경로가 줄지 않는다
	b.step(DT)
	var old: Array = foes.map(func(e): return e.path)
	if b.build("wall", Vector2i(12, 3)) == null:
		return "방벽을 짓지 못했다"
	var got := []
	for i in 3:
		b.step(DT)
		got.append(range(foes.size()).filter(func(k): return not is_same(old[k], foes[k].path)).size())
	return check(got == [8, 16, 20], "스텝마다 새 경로를 받은 적의 누적 수가 %s다([8, 16, 20]이어야 한다)" % [got])

const BRIDGE := Vector2i(10, 3)

# 10열 0~19행이 물 칸이고 (10,3)만 다리다. 거점 (25,10), 출현 (0,10)
func _canal():
	var w := {}
	for y in 20:
		if y != BRIDGE.y:
			w[Vector2i(10, y)] = true
	return battle({"base_hp": BIG, "water": w})

# u가 cond를 이룰 때까지 돌며 스텝마다 반올림한 칸을 모은다. 이루지 못하면 null
func _walk(b, u, secs: float, cond: Callable):
	var seen := {}
	var ok := run(b, secs, func():
		seen[cell_of(u)] = true
		return cond.call())
	return seen if ok else null

# EV469 · S220: 물 칸은 아무도 지나가지 않고 다리 칸으로만 건넌다(예상 경로·땅 적·병사)
func ev469():
	var b = _canal()
	var w = b.get("water")
	if not w is Dictionary or w.is_empty():
		return "판에 물 칸이 없다"
	if b.forecast.is_empty() or not BRIDGE in b.forecast[0] or b.forecast[0].any(func(c): return w.has(c)):
		return "예상 경로가 다리로 가지 않는다: %s" % [b.forecast]
	var e = b.spawn_enemy("basic", Vector2i(0, 10))
	var seen = _walk(b, e, 300, func(): return at_base(b, e))
	if seen == null or not seen.has(BRIDGE) or seen.keys().any(func(c): return w.has(c)):
		return "땅 적이 다리로만 건너 거점에 닿지 않았다(지난 칸 %s)" % [seen.keys() if seen else seen]
	b = _canal()
	var s = b.place_merc("soldier", Vector2i(5, 10))
	b.order_move([s], Vector2i(15, 10))
	seen = _walk(b, s, 60, func(): return near(s.pos, Vector2i(15, 10)))
	return check(seen != null and seen.has(BRIDGE) and not seen.keys().any(func(c): return w.has(c)),
		"병사가 다리로만 건너 (15,10)에 닿지 않았다(지난 칸 %s)" % [seen.keys() if seen else seen])

# EV472 · I181: 물 칸으로 보낸 병사는 물가에서 멈추고, 물 칸에 놓을 수 없고, 밀려도 물 칸에 들어가지 않는다
func ev472():
	var b = _canal()
	var w = b.get("water")
	if not w is Dictionary or w.is_empty():
		return "판에 물 칸이 없다"
	var to := Vector2i(10, 12)
	var s = b.place_merc("soldier", Vector2i(5, 10))
	b.order_move([s], to)
	if not run(b, 30, func(): return s.path.is_empty()) or w.has(cell_of(s)) or s.pos.distance_to(Vector2(to)) > 1.5:
		return "물 칸으로 보낸 병사가 물가에서 멈추지 않았다(%s, 걷는 칸 %d)" % [s.pos, s.path.size()]
	if b.place_merc("soldier", to) != null:
		return "물 칸에 병사가 놓였다"
	var e = b.spawn_enemy("basic", Vector2i(9, 12), {"speed": 0.0})
	b._shove(e, Vector2(1, 0), [])
	return check(cell_of(e) == Vector2i(9, 12), "동쪽으로 민 적이 %s에 있다((9,12)여야 한다)" % [e.pos])

# EV1149 · I309 ①②: 지시 한 번에 16명(UNIT_ROUTES_PER_STEP)까지는 그 자리에서 길을 구하고, 나머지는 줄에 서서 스텝마다 16명씩 받는다
func ev1149():
	var b = battle({"merc_cap": 40})
	if b.get("UNIT_ROUTES_PER_STEP") != 16:
		return "UNIT_ROUTES_PER_STEP이 %s다(I309는 16)" % [b.get("UNIT_ROUTES_PER_STEP")]
	var us := squad(b, "soldier", 40)
	if us.size() != 40:
		return "병사 40명을 놓지 못했다"
	b.order_move(us, Vector2i(20, 15))
	var got := [in_line(us).size()]
	for i in 2:
		b.step(DT)
		got.append(in_line(us).size())
	var idle := us.filter(func(u): return u.path.is_empty()).size()
	if got != [24, 8, 0] or idle > 0:
		return "40명: 지시 직후·한 스텝·두 스텝 뒤 기다리는 병사 %s(기대 [24, 8, 0]) · 두 스텝 뒤 걷는 길이 빈 병사 %d(0)" % [got, idle]
	for n in [16, 1]:
		b = battle({"merc_cap": 40})
		us = squad(b, "soldier", n)
		b.order_move(us, Vector2i(20, 15))
		idle = us.filter(func(u): return u.path.is_empty()).size()
		if us.size() != n or not in_line(us).is_empty() or idle > 0:
			return "%d명: 지시 직후 기다리는 병사 %d(0) · 걷는 길이 빈 병사 %d(0)" % [n, in_line(us).size(), idle]
	return ""

# 시험 스테이지(씨앗 7) 판. kind 0: 준비 단계에 타워 둘·방벽·집을 짓고 정문을 연 판 · 1: 같은 판에서 정문을 닫은 판 ·
# 2: 0의 판에서 전투 단계를 시작하고 공병이 있는 채 정문 앞 들판 길목 (32,66)에 방벽 하나를 놓은 판(미완성이라 체력 0. 스텝은 돌리지 않는다).
# [판, 길을 구할 병사] 또는 [null, 까닭]
func _town(kind: int) -> Array:
	var stage: Dictionary = load("res://src/main.gd").stage()
	stage.merge({"seed": 7, "gold": BIG}, true)
	var b = load("res://src/sim/battle.gd").new(stage)
	for pair in [["tower", Vector2i(26, 70)], ["tower", Vector2i(40, 72)], ["wall", Vector2i(36, 68)], ["house", Vector2i(20, 24)]]:
		if b.build(pair[0], _spot(b, pair[0], pair[1])) == null:
			return [null, "준비 단계에 %s를 짓지 못했다" % pair[0]]
	b.set_gate(b.castle[stage.castle.gates[0]], kind != 1)
	var s = b.place_merc("soldier", _spot(b, "soldier", Vector2i(20, 90)))
	if s == null:
		return [null, "병사를 놓지 못했다"]
	if kind == 2:
		var eng = b.place_merc("engineer", _spot(b, "engineer", Vector2i(30, 70)))
		b.start_battle()
		var w = b.build("wall", Vector2i(32, 66)) if eng and b.state == "battle" else null
		if w == null or w.hp != 0.0:
			return [null, "전투 단계에 (32,66)에 체력 0인 방벽을 놓지 못했다(%s)" % [w.hp if w else null]]
	return [b, s]

# 그 종류를 놓을 수 있는 칸 가운데 want에 가장 가까운 칸
func _spot(b, kind: String, want: Vector2i) -> Vector2i:
	var cells: Array = b.placeable_cells(kind)
	var best: Vector2i = cells[0]
	for c in cells:
		if Vector2(c - want).length() < Vector2(best - want).length():
			best = c
	return best

# 유닛이 설 수 있는 땅 칸(성곽·구조물·물·거점·바위가 아닌 맵 안 칸)
func _ground_cell(b, c: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, b.size).has_point(c) and not (b.walls.has(c) or b.footprint.has(c) or b.water.has(c) or c == b.base.cell or b.rock.has(c))

# 칸 배열의 길 비용(grid._compute_cost의 합). 바로 앞에 grid.path를 불러 둔 판에서 잰다
func _path_cost(b, p: Array) -> float:
	var sum := 0.0
	for i in range(1, p.size()):
		sum += b.grid._compute_cost(p[i - 1], p[i])
	return sum

func _same_cells(p: Array, q: Array) -> bool:
	if p.size() != q.size():
		return false
	for i in p.size():
		if p[i] != q[i]:
			return false
	return true

# EV1153 · I309 ⑦: 아군 땅 길은 비용 격자의 길과 끝 칸·비용이 같다. 닫힌 성곽을 지나야 하는 길은 칸 차례까지 같고,
# 막힌 칸 없이 목적지에 닿는 길은 네이티브 격자에서 나온다(_slow 거짓). 목적지가 구조물·물·거점 칸이면 비용 격자다(_slow 참)
func ev1153():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1153
	var clean := 0
	for kind in 3:
		var made := _town(kind)
		if made[0] == null:
			return "판 %d: %s" % [kind, made[1]]
		var b = made[0]
		var s = made[1]
		var pairs := []
		var fixed := []
		if kind == 2:  # 체력 0 방벽 (32,66)을 세로로 곧게 지나는 두 쌍: 비용 격자는 그 칸을 지나는 길이 가장 싸다(I309 ⑦의 싼 막힌 칸)
			fixed = [[Vector2i(32, 50), Vector2i(32, 90)], [Vector2i(32, 90), Vector2i(32, 50)]]
			if not fixed.all(func(p): return _ground_cell(b, p[0]) and _ground_cell(b, p[1])):
				return "판 2: (32,50)·(32,90)이 설 수 있는 땅 칸이 아니다"
		while pairs.size() < 100 - fixed.size():
			var a := Vector2i(rng.randi_range(0, b.size.x - 1), rng.randi_range(0, b.size.y - 1))
			var z := Vector2i(rng.randi_range(0, b.size.x - 1), rng.randi_range(0, b.size.y - 1))
			if pairs.size() >= 98 - fixed.size():
				z = b.base.cell  # 판마다 마지막 두 쌍은 거점 칸 목적지
			if _ground_cell(b, a) and not b.walls.has(z):
				pairs.append([a, z])
		pairs = fixed + pairs
		for p in pairs:
			var a: Vector2i = p[0]
			var z: Vector2i = p[1]
			s.pos = Vector2(a)
			s.on_wall = false
			b.order_move([s], z)
			var slow = b.get("_slow")
			var mine: Array = [a] + s.path
			var old: Array = b._short(b.grid.path(a, z))
			var cm := _path_cost(b, mine)
			var co := _path_cost(b, old)
			if mine.back() != old.back() or absf(cm - co) > 0.001:
				return "판 %d %s → %s: 끝 칸 %s / 비용 격자 %s · 비용 %.4f / %.4f" % [kind, a, z, mine.back(), old.back(), cm, co]
			if kind == 1 and b.village.has_point(a) and z.y >= b.field_y and not _same_cells(mine, old):
				return "판 1(정문 닫힘) %s → %s: 닫힌 성곽을 지나는 길의 칸이 비용 격자와 다르다(%d칸 / %d칸)" % [a, z, mine.size(), old.size()]
			if (b.footprint.has(z) or b.water.has(z) or z == b.base.cell) and slow != true:
				return "판 %d %s → %s: 목적지가 구조물·물·거점 칸인데 _slow가 %s다(참이어야 한다)" % [kind, a, z, slow]
			if z != b.base.cell and old.back() == z and old.all(func(c): return b.grid.block_at(c) == null):
				clean += 1
				if kind < 2 and slow != false:
					return "판 %d %s → %s: 막힌 칸 없이 닿는 길인데 _slow가 %s다(네이티브 격자면 거짓)" % [kind, a, z, slow]
	return check(clean >= 50, "300쌍 가운데 막힌 칸 없이 목적지에 닿는 쌍 %d(50 이상)" % clean)
