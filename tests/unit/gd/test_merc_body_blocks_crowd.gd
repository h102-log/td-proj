extends RefCounted
# 용병 하나가 한 칸 틈을 몸으로 막을 때 몰려든 적들이 지나가지 못하고 그 용병을 치는지 본다(WBS 2.5).
# 지키는 요구:
#   S13. 영웅·용병·적은 같은 편이든 아니든 서로 겹치지 않는다. 아군 유닛은 적의 길을 몸으로 막을 수 있고,
#        몸으로 길이 막힌 적은 돌아가지 않고 막은 유닛을 공격한다.
#   I2. 경로 계산에는 구조물과 성곽만 넣고 유닛은 넣지 않는다.
# 뒤에서 미는 적들(적끼리 밀어내기, I51)에 떠밀려 앞의 적이 용병을 뚫고 지나가면 안 된다.

func test_crowd_cannot_pass_merc_in_one_cell_gap():
	var b = load("res://src/sim/battle.gd").new({"size": Vector2i(11, 14), "base": Vector2i(5, 1), "base_hp": 1000000, "spawns": [Vector2i(5, 13)]})
	var walls := []
	for x in 11:
		if x != 5:
			walls.append(b.build("wall", Vector2i(x, 6)))
	var m = b.place_merc("soldier", Vector2i(5, 6), {"hp": 1000000, "damage": 0, "sight": 0})  # 치거나 쫓아가 틈을 비우지 않게
	var es := []
	for i in 5:
		es.append(b.spawn_enemy("basic", Vector2i(5, 13), {"sight": 0}))
	for i in 400:
		b.step(0.05)
	var passed := es.filter(func(e): return e.pos.y < 6.0)
	if not passed.is_empty():
		return "용병을 지나간 적: %s" % [passed.map(func(e): return e.pos)]
	var inside := es.filter(func(e): return e.pos.distance_to(m.pos) < e.radius + m.radius - 0.01)
	if not inside.is_empty():
		return "용병과 겹친 적: %s" % [inside.map(func(e): return e.pos)]
	if walls.any(func(w): return w.hp < w.max_hp):
		return "용병을 치지 않고 성벽을 쳤다"
	return "" if m.hp < m.max_hp else "막힌 적이 용병을 치지 않았다"
