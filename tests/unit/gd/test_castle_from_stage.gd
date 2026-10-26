extends RefCounted
# 성곽이 스테이지 데이터로 미리 놓이는지 본다(WBS 2.2).
# 지키는 요구:
#   S37. 성곽(성벽과 성문)은 스테이지가 시작될 때부터 있고 플레이어가 짓지 않는다.
#   S39. 성문은 정문 1개와 성곽 양 끝의 쪽문 2개다. → 2026-10-26 변경: 성문은 정문 하나다(좌우 쪽문을 없앴다).
#   I41. 성문의 최대 체력은 같은 업그레이드 단계의 성벽보다 낮다.

func test_castle_cells_come_from_stage_data():
	var b = load("res://src/sim/battle.gd").new({
		"size": Vector2i(10, 10), "base": Vector2i(5, 5), "base_hp": 100, "spawns": [Vector2i(0, 5)],
		"castle": {"walls": [Vector2i(3, 4), Vector2i(3, 6)], "gates": [Vector2i(3, 5)], "wall_hp": 300, "gate_hp": 150},
	})
	var w = b.castle.get(Vector2i(3, 4))
	var g = b.castle.get(Vector2i(3, 5))
	if b.castle.size() != 3 or w == null or g == null:
		return "성곽 칸이 데이터와 다르다: %s" % [b.castle.keys()]
	if w.kind != "castle_wall" or w.hp != 300.0:
		return "성벽 칸이 %s·체력 %s다" % [w.kind, w.hp]
	if g.kind != "gate" or g.hp != 150.0:
		return "성문 칸이 %s·체력 %s다" % [g.kind, g.hp]
	return ""

func test_w1_stage_has_one_gate_weaker_than_walls():
	var b = load("res://src/sim/battle.gd").new(load("res://src/main.gd").stage())
	var gates = b.castle.values().filter(func(p): return p.kind == "gate")
	var walls = b.castle.values().filter(func(p): return p.kind == "castle_wall")
	if gates.size() != 1:
		return "성문이 %d개다" % gates.size()
	if not gates.all(func(g): return walls.all(func(w): return g.max_hp < w.max_hp)):
		return "성벽보다 약하지 않은 성문이 있다"
	return ""
