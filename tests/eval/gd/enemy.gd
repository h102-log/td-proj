extends "res://tests/eval/gd/lib.gd"

# EV11 · S4 ①: 인식 범위 안의 용병을 공격하고 거점은 건드리지 않는다
func ev11():
	var b = battle({"base_hp": BIG})
	var m = b.place_merc("soldier", Vector2i(8, 12), {"hp": BIG, "damage": 0})
	b.spawn_enemy("basic", Vector2i(0, 10), {"sight": 4})
	var ok := run(b, 60, func(): return m.hp < m.max_hp)
	return check(ok and b.base.hp == b.base.max_hp, "인식 범위의 용병을 공격하지 않았다")

# EV12 · S4 ①>②: 타워에 반격하러 가던 적은 인식 범위에 들어온 용병을 먼저 공격한다
func ev12():
	var b = battle({"base": Vector2i(28, 10), "base_hp": BIG})
	var tower := Vector2i(8, 16)
	var t = b.build("tower", tower, {"range": 8, "damage": 1})
	var e = b.spawn_enemy("basic", Vector2i(0, 10), {"sight": 3, "hp": BIG})
	if not run(b, 60, func(): return e.hp < e.max_hp):
		return "타워가 적을 쏘지 않았다"
	var d0: float = e.pos.distance_to(Vector2(tower))
	run(b, 1)
	if e.pos.distance_to(Vector2(tower)) >= d0:
		return "타워에 맞은 적이 타워로 향하지 않았다"
	var m = b.place_merc("soldier", cell_of(e) + Vector2i(1, 0), {"hp": BIG, "damage": 0})
	if m == null:
		return "적 옆에 용병을 놓지 못했다"
	var ok := run(b, 10, func(): return m.hp < m.max_hp)
	return check(ok and t.hp == t.max_hp, "반격 중 들어온 용병보다 타워를 우선했다")

# EV13 · S4 ③④: 막는 것이 없으면 거점까지 가서 거점을 깎는다
func ev13():
	var b = battle({"base_hp": BIG})
	b.spawn_enemy("basic", Vector2i(0, 10))
	var ok := run(b, 120, func(): return b.base.hp < b.base.max_hp)
	return check(ok, "적이 거점을 공격하지 않았다")

# EV14 · S5: 인식 범위 밖에서 쏜 타워 쪽으로 적이 다가간다
func ev14():
	var b = battle({"base_hp": BIG})
	var tower := Vector2i(1, 10)
	b.build("tower", tower, {"range": 6, "damage": 1})
	var e = b.spawn_enemy("basic", Vector2i(5, 10), {"sight": 2, "hp": BIG})
	if not run(b, 30, func(): return e.hp < e.max_hp):
		return "타워가 적을 쏘지 않았다"
	var d0: float = e.pos.distance_to(Vector2(tower))
	run(b, 3)
	return check(e.pos.distance_to(Vector2(tower)) < d0, "타워에 맞은 적이 타워로 향하지 않았다")

# EV15 · S6: 성벽에 둘러싸인 타워에 반격하려고 성벽을 부순다
func ev15():
	var b = battle({"base_hp": BIG})
	var tower := Vector2i(10, 10)
	var t = b.build("tower", tower, {"range": 6, "damage": 1})
	var walls := ring(tower)
	for c in walls:
		b.build("wall", c)
	b.spawn_enemy("basic", Vector2i(5, 10), {"sight": 2, "hp": BIG})
	var ok := run(b, 120, func(): return t.hp < t.max_hp)
	var broken := walls.filter(func(c): return b.structure_at(c) == null)
	return check(ok and broken.size() >= 1, "성벽을 뚫고 타워를 공격하지 않았다")

# EV16 · S13: 아군 유닛은 적의 길을 몸으로 막고, 막힌 적은 그 유닛을 공격한다 (2026-10-12 개정)
func ev16():
	var b = battle({"base_hp": BIG})
	var m = b.place_merc("soldier", Vector2i(10, 10), {"damage": 0, "range": 0, "sight": 0, "hp": BIG})
	var e = b.spawn_enemy("basic", Vector2i(0, 10), {"sight": 0})
	run(b, 30)
	var ok: bool = e.pos.x < m.pos.x and m.hp < m.max_hp and b.base.hp == b.base.max_hp
	return check(ok, "적 x %.2f, 용병 x %.2f, 용병 체력 %s/%s, 거점 체력 %s/%s" % [e.pos.x, m.pos.x, m.hp, m.max_hp, b.base.hp, b.base.max_hp])

# EV17 · I7: 쏘지 않는 타워는 인식 범위 안에 있어도 공격 대상이 아니다
func ev17():
	var b = battle({"base_hp": BIG})
	var t = b.build("tower", Vector2i(10, 11), {"range": 0})
	var e = b.spawn_enemy("basic", Vector2i(0, 10), {"sight": 5})
	var ok := run(b, 120, func(): return at_base(b, e))
	return check(ok and t.hp == t.max_hp, "쏘지 않는 타워를 공격했다")

# EV18 · I8: 반격 대상이 파괴되면 거점으로 이동을 다시 시작한다
func ev18():
	var b = battle({"base_hp": BIG})
	var t = b.build("tower", Vector2i(1, 10), {"range": 6, "damage": 1})
	var e = b.spawn_enemy("basic", Vector2i(5, 10), {"sight": 2, "hp": BIG})
	if not run(b, 30, func(): return e.hp < e.max_hp):
		return "타워가 적을 쏘지 않았다"
	run(b, 1)
	b.damage(t, t.max_hp)
	var ok := run(b, 120, func(): return at_base(b, e))
	return check(ok, "반격 대상이 사라진 뒤 거점으로 가지 않았다")
