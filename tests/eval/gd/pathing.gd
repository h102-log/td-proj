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
