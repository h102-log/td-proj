extends RefCounted
# 건설할 수 있는 칸과 때를 본다(WBS 2.3).
# 지키는 요구:
#   I24. 구조물은 격자 한 칸을 차지하고(거점은 예외), 비어 있는 칸(구조물·유닛·적이 없는 칸)에만 지을 수 있다.
#   S18. 준비 단계에서는 유닛 배치와 구조물 건설이 그 자리에서 바로 완성된다.
# 놀고 있는 공병이 없으면 전투 중 건설은 거부한다(I39). 공병이 있을 때는 tests/eval/gd/engineer.gd가 본다.

func _battle():
	return load("res://src/sim/battle.gd").new({
		"size": Vector2i(10, 10), "base": Vector2i(5, 5), "base_hp": 100, "gold": 1000000, "spawns": [Vector2i(0, 5)],
		"waves": [[{"kind": "basic", "count": 1}]],
		"castle": {"walls": [Vector2i(3, 4)], "gates": [Vector2i(3, 5)], "wall_hp": 300, "gate_hp": 150},
	})

func test_build_rejected_on_occupied_or_outside_cells():
	var b = _battle()
	b.build("wall", Vector2i(7, 7))
	for c in [Vector2i(7, 7), Vector2i(5, 5), Vector2i(3, 4), Vector2i(3, 5), Vector2i(-1, 0), Vector2i(10, 3)]:
		if b.build("wall", c) != null:
			return "%s에 지어졌다" % [c]
	return "" if b.structures.size() == 1 else "구조물이 %d개다" % b.structures.size()

func test_build_rejected_on_merc_cell():
	var b = _battle()
	b.place_merc("soldier", Vector2i(7, 2))
	return "" if b.build("wall", Vector2i(7, 2)) == null else "용병이 선 칸에 지어졌다"

func test_build_rejected_during_battle():
	var b = _battle()
	b.start_battle()
	return "" if b.build("wall", Vector2i(7, 7)) == null else "전투 중에 지어졌다"
