extends RefCounted
# 대각선으로 붙은 두 방벽 사이로 빠져나가지 않는지 본다(WBS 2.4).
# 지키는 요구:
#   S9. 거점까지 가는 길을 성벽으로 완전히 막으면 적은 비용이 가장 싼 성벽을 부순다.
# 막힌 칸이 solid였을 때는 옆 칸이 막히면 대각선으로 못 갔다(DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES).
# 비용 칸으로 바꾼 뒤에도 이 동작을 유지해야 대각선 방벽 줄이 «완전히 막은 길»이 된다.

func test_diagonal_wall_line_forces_breaking_a_wall():
	var b = load("res://src/sim/battle.gd").new({
		"size": Vector2i(10, 10), "base": Vector2i(9, 9), "base_hp": 100, "spawns": [Vector2i(0, 0)],
	})
	var walls := []
	for x in 10:
		walls.append(Vector2i(x, 9 - x))
		b.build("wall", walls.back())
	var e = b.spawn_enemy("basic", Vector2i(0, 0))
	var through: Array = e.path.filter(func(c): return c in walls)
	return "" if through.size() > 0 else "방벽 칸 없이 지나갔다: %s" % [e.path]
