extends "res://tests/eval/gd/lib.gd"

# EV1 · S1: 구조물 없는 맵의 네 가장자리에서 나온 적이 모두 거점에 닿는다
func ev1():
	var edges := [Vector2i(0, 10), Vector2i(29, 10), Vector2i(15, 0), Vector2i(15, 19)]
	var b = battle({"base": Vector2i(15, 10), "base_hp": BIG, "spawns": edges})
	var es := edges.map(func(c): return b.spawn_enemy("basic", c))
	var ok := run(b, 120, func(): return es.all(func(e): return at_base(b, e)))
	return check(ok, "가장자리 네 곳의 적이 모두 거점에 닿지 못했다")

# EV2 · S2: 거점 체력이 0이 되면 패배
func ev2():
	var b = battle()
	b.damage(b.base, b.base.max_hp)
	return check(b.state == "lost", "거점 체력 0인데 판 상태가 %s다" % b.state)

# EV3 · S3: 웨이브의 적은 모두 맵 가장자리 칸에서 처음 나타난다
func ev3():
	var b = battle({"base_hp": BIG, "spawns": [Vector2i(0, 5), Vector2i(29, 15)], "waves": [[{"kind": "basic", "count": 6}]]})
	var firsts := []
	b.enemy_spawned.connect(func(e): firsts.append(cell_of(e)))
	b.start_battle()
	run(b, 120, func(): return firsts.size() >= 6)
	if firsts.size() < 6:
		return "적 6마리가 다 나오지 않았다 (%d마리)" % firsts.size()
	var inner := firsts.filter(func(c): return c.x > 0 and c.y > 0 and c.x < 29 and c.y < 19)
	return check(inner.is_empty(), "가장자리가 아닌 칸에서 나온 적: %s" % [inner])

# EV4 · S30: 화면 확대 방식이 정수배다
func ev4():
	var mode = ProjectSettings.get_setting("display/window/stretch/scale_mode", "fractional")
	return check(mode == "integer", "확대 방식이 %s다" % mode)
