extends RefCounted
# 적끼리 겹치지 않고 밀어내며, 서로를 멈춰 세우지 않는지 본다(WBS 2.4).
# 지키는 요구:
#   I51. 같은 편끼리(적끼리, 아군끼리)는 서로 밀어내며 비켜 가고, 서로를 멈춰 세우지 않는다.
#        몸 크기(반지름)는 유닛·적 종류마다 데이터 값이다.
#   I5. 전투 중에도 구조물이 놓이거나 파괴되면 적의 경로를 다시 계산한다.
# 밀려난 적은 경로의 칸 중심에 정확히 닿지 못할 수 있다. 칸 중심에 닿아야 다음 칸으로 가면
# 같은 칸 중심을 노리는 적들이 서로 밀어내며 그 자리에 멈춘다(W1 정문에서 실제로 났다).

func _battle(size: Vector2i, base: Vector2i, spawn: Vector2i):
	return load("res://src/sim/battle.gd").new({"size": size, "base": base, "base_hp": 1000000, "gold": 1000000, "spawns": [spawn]})

func _steps(b, n: int) -> void:
	for i in n:
		b.step(0.05)

# 같은 칸의 두 적이 서로 밀어낸 뒤 경로를 다시 구해도 둘 다 거점 쪽으로 나아간다
func test_two_enemies_on_one_cell_push_apart_and_keep_going():
	var b = _battle(Vector2i(10, 10), Vector2i(6, 5), Vector2i(0, 5))
	var e1 = b.spawn_enemy("basic", Vector2i(0, 5))
	var e2 = b.spawn_enemy("basic", Vector2i(0, 5))
	b.step(0.05)
	b.build("wall", Vector2i(9, 0))  # 경로 밖 방벽 → 다음 step에서 두 적 모두 경로를 다시 구한다
	_steps(b, 20)
	var d: float = e1.pos.distance_to(e2.pos)
	if d < e1.radius + e2.radius - 0.01:
		return "1초 뒤에도 겹쳐 있다: 거리 %.2f" % d
	_steps(b, 200)
	return "" if e1.pos.x >= 3 and e2.pos.x >= 3 else "10초 뒤에도 거점 쪽으로 나아가지 못했다: %s, %s" % [e1.pos, e2.pos]

# 한 칸 틈으로 몰려든 적 다섯이 모두 틈을 지나간다
func test_crowd_passes_one_cell_gap():
	var b = _battle(Vector2i(11, 14), Vector2i(5, 1), Vector2i(5, 13))
	for x in 11:
		if x != 5:
			b.build("wall", Vector2i(x, 6))
	var es := []
	for i in 5:
		es.append(b.spawn_enemy("basic", Vector2i(5, 13)))
	_steps(b, 400)
	var stuck := es.filter(func(e): return e.pos.y > 5.5)
	return "" if stuck.is_empty() else "20초 뒤에도 틈 아래에 남은 적: %s" % [stuck.map(func(e): return e.pos)]
