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
	var b = battle({"base_hp": BIG, "waves": [one, one]})
	var got := []
	b.enemy_spawned.connect(func(e): got.append(e))
	b.start_battle()
	var path1 := {}
	run(b, 300, func():
		if got.size() > 0:
			path1[cell_of(got[0])] = true
		return got.size() > 0 and at_base(b, got[0]))
	if not clear_wave(b) or b.state != "prep":
		return "1웨이브가 끝나지 않았다"
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
