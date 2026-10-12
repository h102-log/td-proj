extends RefCounted
# 준비 단계 용병 배치도 골드를 낸다(WBS 2.10, 사용자 2026-10-12).
# 지키는 요구:
#   I16. 골드가 모자라면 구매·건설 명령은 거부되고, 아무것도 바뀌지 않는다.

func _battle(gold: int):
	return load("res://src/sim/battle.gd").new({"size": Vector2i(10, 10), "base": Vector2i(9, 9), "base_hp": 100, "gold": gold, "spawns": [Vector2i(0, 0)]})

func test_merc_rejected_without_gold():
	var b = _battle(0)
	var m = b.place_merc("soldier", Vector2i(5, 5))
	return "" if m == null and b.gold == 0 and b.units.is_empty() else "골드 0인데 배치됐다(골드 %d, 유닛 %d)" % [b.gold, b.units.size()]

func test_merc_costs_gold():
	var b = _battle(100)
	var m = b.place_merc("soldier", Vector2i(5, 5))
	var cost: int = b.MERC_KINDS.soldier.cost
	return "" if m != null and b.gold == 100 - cost else "배치 뒤 골드 %d(비용 %d)" % [b.gold, cost]
