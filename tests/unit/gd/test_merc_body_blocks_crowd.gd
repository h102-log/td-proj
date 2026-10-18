extends RefCounted
# 용병 하나가 한 칸 틈을 몸으로 막을 때, 블록 수만큼만 적을 붙잡고 나머지는 지나가는지 본다(WBS 2.5, 2026-10-18 블록 수).
# 지키는 요구:
#   S13. 영웅·용병·적은 서로 겹치지 않는다. 아군 유닛은 적의 길을 몸으로 막을 수 있고, 몸으로 길이 막힌 적은 막은 유닛을 공격한다.
#   S159. 유닛은 블록 수만큼만 적을 붙잡는다. 자리가 찬 유닛은 다른 적을 노리지도 몸으로 막지도 않고, 그 적은 지나간다.
#   I2. 경로 계산에는 구조물과 성곽만 넣고 유닛은 넣지 않는다.
# 뒤에서 미는 적들(적끼리 밀어내기, I51)에 떠밀려 붙잡힌 적이 용병을 뚫고 지나가면 안 된다.

func _gap(block: int) -> Array:
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(11, 14), "base": Vector2i(5, 1), "base_hp": 1000000, "gold": 1000000, "spawns": [Vector2i(5, 13)]})
	var walls := []
	for x in 11:
		if x != 5:
			walls.append(b.build("wall", Vector2i(x, 6)))
	var m = b.place_merc("soldier", Vector2i(5, 6), {"hp": 1000000, "damage": 0, "sight": 0, "block": block})  # 치거나 쫓아가 틈을 비우지 않게
	var es := []
	for i in 5:
		es.append(b.spawn_enemy("basic", Vector2i(5, 13), {"sight": 0}))
	for i in 400:
		b.step(0.05)
	return [b, walls, m, es]

func test_merc_holds_only_its_block_count():
	var r := _gap(1)
	var m = r[2]
	var es: Array = r[3]
	var held := es.filter(func(e): return e.alive and e.engaged == m)
	var passed := es.filter(func(e): return e.pos.y < 6.0)
	if held.size() != 1:
		return "붙잡힌 적이 %d명이다(블록 1)" % held.size()
	if held[0].pos.y < 6.0 or held[0].pos.distance_to(m.pos) < held[0].radius + m.radius - 0.01:
		return "붙잡힌 적이 용병을 뚫거나 겹쳤다: %s" % held[0].pos
	if passed.size() != 4:
		return "지나간 적이 %d명이다(4명이어야 한다)" % passed.size()
	if r[1].any(func(w): return w.hp < w.max_hp):
		return "용병을 치지 않고 성벽을 쳤다"
	return "" if m.hp < m.max_hp else "붙잡힌 적이 용병을 치지 않았다"

func test_crowd_cannot_pass_merc_with_enough_block():
	var r := _gap(5)
	var m = r[2]
	var es: Array = r[3]
	var passed := es.filter(func(e): return e.pos.y < 6.0)
	if not passed.is_empty():
		return "용병을 지나간 적: %s" % [passed.map(func(e): return e.pos)]
	var inside := es.filter(func(e): return e.pos.distance_to(m.pos) < e.radius + m.radius - 0.01)
	if not inside.is_empty():
		return "용병과 겹친 적: %s" % [inside.map(func(e): return e.pos)]
	return "" if m.hp < m.max_hp else "막힌 적이 용병을 치지 않았다"
