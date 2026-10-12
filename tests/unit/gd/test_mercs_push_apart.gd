extends RefCounted
# 용병끼리 겹치지 않고 밀어내며, 서로를 멈춰 세우지 않는지 본다(WBS 2.8).
# 지키는 요구:
#   I51. 같은 편끼리(적끼리, 아군끼리)는 서로 밀어내며 비켜 가고, 서로를 멈춰 세우지 않는다.
# 드래그로 고른 무리는 한 칸으로 이동 지시를 받는다. 모두 그 칸 중심에 닿아야 도착이면
# 서로 밀어내며 끝없이 걷는다(도착하지 못하면 I36의 추적도 시작하지 않는다).

func _battle():
	return load("res://src/sim/battle.gd").new({"size": Vector2i(20, 20), "base": Vector2i(19, 19), "base_hp": 1000000, "gold": 1000000, "spawns": [Vector2i(0, 0)]})

func _steps(b, n: int) -> void:
	for i in n:
		b.step(0.05)

func _overlapping(ms: Array) -> bool:
	for i in ms.size():
		for j in range(i + 1, ms.size()):
			if ms[i].pos.distance_to(ms[j].pos) < ms[i].radius + ms[j].radius - 0.01:
				return true
	return false

# 한 칸에 놓인 둘이 떨어진다
func test_two_mercs_on_one_cell_push_apart():
	var b = _battle()
	var ms := [b.place_merc("soldier", Vector2i(5, 5)), b.place_merc("soldier", Vector2i(5, 5))]
	_steps(b, 20)
	return "1초 뒤에도 겹쳐 있다: %s" % [ms.map(func(m): return m.pos)] if _overlapping(ms) else ""

# 네 방향에서 같은 칸으로 보낸 무리가 모두 도착해 서고, 겹치지 않는다
func test_group_sent_to_one_cell_all_arrive():
	var b = _battle()
	var ms := [Vector2i(5, 10), Vector2i(15, 10), Vector2i(10, 5), Vector2i(10, 15)].map(func(c): return b.place_merc("soldier", c))
	b.order_move(ms, Vector2i(10, 10))
	_steps(b, 200)
	var walking := ms.filter(func(m): return not m.path.is_empty())
	if not walking.is_empty():
		return "10초 뒤에도 걷는 용병: %s" % [walking.map(func(m): return m.pos)]
	if ms.any(func(m): return m.pos.distance_to(Vector2(10, 10)) > 1.0):
		return "목적지에서 1칸보다 멀리 섰다: %s" % [ms.map(func(m): return m.pos)]
	return "겹쳐 있다: %s" % [ms.map(func(m): return m.pos)] if _overlapping(ms) else ""
